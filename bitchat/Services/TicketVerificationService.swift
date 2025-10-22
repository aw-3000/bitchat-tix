//
// TicketVerificationService.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import Combine

/// Service for verifying ticket authenticity and managing verification proofs
@MainActor
final class TicketVerificationService: ObservableObject {
    static let shared = TicketVerificationService()
    
    /// Trusted issuer public keys (for verifying tickets)
    @Published var trustedIssuers: Set<String> = []
    
    /// Cache of verification results
    private var verificationCache: [String: VerificationResult] = [:]
    
    // Injected Noise service for cryptographic operations
    private var noise: NoiseEncryptionService?
    func configure(with noise: NoiseEncryptionService) {
        self.noise = noise
    }
    
    // MARK: - Verification
    
    /// Verify a ticket's authenticity
    func verifyTicket(
        _ ticket: Ticket,
        proof: TicketVerificationProof
    ) -> VerificationResult {
        // Check cache first
        let cacheKey = ticket.id + proof.nonce
        if let cached = verificationCache[cacheKey] {
            return cached
        }
        
        // Verify issuer is trusted
        guard trustedIssuers.contains(proof.issuerPublicKey) else {
            let result = VerificationResult(
                isValid: false,
                reason: .untrustedIssuer,
                details: "Issuer public key not in trusted list"
            )
            verificationCache[cacheKey] = result
            return result
        }
        
        // Verify issuer signature
        guard verifyIssuerSignature(ticket, proof: proof) else {
            let result = VerificationResult(
                isValid: false,
                reason: .invalidSignature,
                details: "Issuer signature verification failed"
            )
            verificationCache[cacheKey] = result
            return result
        }
        
        // Verify chain of custody
        if !proof.chainOfCustody.isEmpty {
            guard verifyChainOfCustody(ticket, proof: proof) else {
                let result = VerificationResult(
                    isValid: false,
                    reason: .invalidChainOfCustody,
                    details: "Transfer chain verification failed"
                )
                verificationCache[cacheKey] = result
                return result
            }
        }
        
        // Verify timestamp freshness (prevent replay attacks)
        let age = Date().timeIntervalSince(proof.timestamp)
        guard age < TransportConfig.ticketProofMaxAgeSeconds else {
            let result = VerificationResult(
                isValid: false,
                reason: .expired,
                details: "Proof timestamp too old"
            )
            verificationCache[cacheKey] = result
            return result
        }
        
        // All checks passed
        let result = VerificationResult(isValid: true, reason: .valid)
        verificationCache[cacheKey] = result
        return result
    }
    
    /// Verify a transfer request
    func verifyTransferRequest(_ request: TicketTransferRequest) -> Bool {
        let result = verifyTicket(request.ticket, proof: request.proof)
        return result.isValid
    }
    
    // MARK: - Signature Verification
    
    private func verifyIssuerSignature(
        _ ticket: Ticket,
        proof: TicketVerificationProof
    ) -> Bool {
        guard let noise = noise,
              let sigData = Data(hexString: proof.issuerSignature),
              let pubKeyData = Data(hexString: proof.issuerPublicKey) else {
            return false
        }
        
        // Canonical representation of ticket for signing
        let ticketData = canonicalTicketData(ticket)
        
        return noise.verifySignature(sigData, for: ticketData, publicKey: pubKeyData)
    }
    
    private func verifyChainOfCustody(
        _ ticket: Ticket,
        proof: TicketVerificationProof
    ) -> Bool {
        guard let noise = noise else { return false }
        
        // Verify each transfer signature in the chain
        for transfer in proof.chainOfCustody {
            guard let sigData = Data(hexString: transfer.signature),
                  let fromKey = Data(hexString: transfer.fromPeerPublicKey),
                  let toKey = Data(hexString: transfer.toPeerPublicKey) else {
                return false
            }
            
            // Build transfer message: ticket_id | from | to | timestamp
            var msg = Data()
            msg.append(ticket.id.data(using: .utf8) ?? Data())
            msg.append(fromKey)
            msg.append(toKey)
            msg.append(withUnsafeBytes(of: transfer.timestamp.timeIntervalSince1970) { Data($0) })
            
            // Verify signature using from peer's public key
            if !noise.verifySignature(sigData, for: msg, publicKey: fromKey) {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Signing
    
    /// Create a verification proof for a ticket (issuer side)
    func createProof(
        for ticket: Ticket,
        issuerPrivateKey: Data
    ) -> TicketVerificationProof? {
        guard let noise = noise else { return nil }
        
        let ticketData = canonicalTicketData(ticket)
        guard let signature = noise.signData(ticketData) else {
            return nil
        }
        
        // Get issuer public key
        let publicKey = noise.getSigningPublicKeyData()
        
        return TicketVerificationProof(
            issuerPublicKey: publicKey.hexEncodedString(),
            issuerSignature: signature.hexEncodedString()
        )
    }
    
    /// Sign a transfer (add to chain of custody)
    func signTransfer(
        ticket: Ticket,
        currentProof: TicketVerificationProof,
        fromPublicKey: String,
        toPublicKey: String
    ) -> TicketVerificationProof? {
        guard let noise = noise,
              let fromKey = Data(hexString: fromPublicKey),
              let toKey = Data(hexString: toPublicKey) else {
            return nil
        }
        
        // Build transfer message
        var msg = Data()
        msg.append(ticket.id.data(using: .utf8) ?? Data())
        msg.append(fromKey)
        msg.append(toKey)
        msg.append(withUnsafeBytes(of: Date().timeIntervalSince1970) { Data($0) })
        
        // Sign with current peer's private key
        guard let signature = noise.signData(msg) else {
            return nil
        }
        
        // Add to chain
        return currentProof.withTransfer(
            from: fromPublicKey,
            to: toPublicKey,
            signature: signature.hexEncodedString()
        )
    }
    
    // MARK: - Helpers
    
    private func canonicalTicketData(_ ticket: Ticket) -> Data {
        // Create deterministic representation of ticket for signing
        var data = Data()
        
        func append(_ string: String) {
            if let d = string.data(using: .utf8) {
                data.append(UInt8(min(d.count, 255)))
                data.append(d.prefix(255))
            }
        }
        
        append(ticket.id)
        append(ticket.eventName)
        append(ticket.venue)
        data.append(withUnsafeBytes(of: ticket.eventDate.timeIntervalSince1970) { Data($0) })
        append(ticket.section ?? "")
        append(ticket.row ?? "")
        append(ticket.seat ?? "")
        
        return data
    }
    
    // MARK: - Trust Management
    
    /// Add a trusted issuer public key
    func addTrustedIssuer(_ publicKey: String) {
        trustedIssuers.insert(publicKey)
        saveTrustedIssuers()
    }
    
    /// Remove a trusted issuer
    func removeTrustedIssuer(_ publicKey: String) {
        trustedIssuers.remove(publicKey)
        saveTrustedIssuers()
    }
    
    /// Check if an issuer is trusted
    func isIssuerTrusted(_ publicKey: String) -> Bool {
        trustedIssuers.contains(publicKey)
    }
    
    // MARK: - Persistence
    
    private let trustedIssuersKey = "ticketVerification.trustedIssuers"
    
    private func saveTrustedIssuers() {
        let array = Array(trustedIssuers)
        UserDefaults.standard.set(array, forKey: trustedIssuersKey)
    }
    
    private func loadTrustedIssuers() {
        if let array = UserDefaults.standard.array(forKey: trustedIssuersKey) as? [String] {
            trustedIssuers = Set(array)
        }
    }
    
    private init() {
        loadTrustedIssuers()
    }
}

/// Result of ticket verification
struct VerificationResult {
    let isValid: Bool
    let reason: VerificationReason
    let details: String?
    
    init(isValid: Bool, reason: VerificationReason, details: String? = nil) {
        self.isValid = isValid
        self.reason = reason
        self.details = details
    }
    
    enum VerificationReason {
        case valid
        case untrustedIssuer
        case invalidSignature
        case invalidChainOfCustody
        case expired
        case alreadyUsed
        case eventNotFound
        case invalidFormat
    }
}

extension TransportConfig {
    /// Maximum age for ticket proofs (24 hours)
    static let ticketProofMaxAgeSeconds: TimeInterval = 24 * 60 * 60
}
