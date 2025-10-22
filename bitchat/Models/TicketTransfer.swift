//
// TicketTransfer.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation

/// Represents a ticket transfer request between peers
struct TicketTransferRequest: Codable, Equatable, Identifiable {
    let id: String
    let ticket: Ticket
    let proof: TicketVerificationProof
    let fromPeer: PeerID
    let fromNickname: String
    let toPeer: PeerID
    let toNickname: String
    let method: TransferMethod
    let status: TransferStatus
    let requestedAt: Date
    let completedAt: Date?
    
    enum TransferMethod: String, Codable {
        case bluetooth  // Direct Bluetooth LE transfer
        case nostr      // Transfer via Nostr relay
    }
    
    enum TransferStatus: String, Codable {
        case pending    // Awaiting receiver acceptance
        case accepted   // Receiver accepted, finalizing
        case completed  // Transfer complete
        case rejected   // Receiver declined
        case cancelled  // Sender cancelled
        case failed     // Transfer failed
    }
    
    init(
        id: String = UUID().uuidString,
        ticket: Ticket,
        proof: TicketVerificationProof,
        fromPeer: PeerID,
        fromNickname: String,
        toPeer: PeerID,
        toNickname: String,
        method: TransferMethod,
        status: TransferStatus = .pending,
        requestedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.ticket = ticket
        self.proof = proof
        self.fromPeer = fromPeer
        self.fromNickname = fromNickname
        self.toPeer = toPeer
        self.toNickname = toNickname
        self.method = method
        self.status = status
        self.requestedAt = requestedAt
        self.completedAt = completedAt
    }
}

/// Cryptographic proof of ticket authenticity and chain of custody
struct TicketVerificationProof: Codable, Equatable {
    /// Original issuer's Ed25519 public key
    let issuerPublicKey: String
    
    /// Signature by issuer over ticket data
    let issuerSignature: String
    
    /// Chain of transfer signatures (each transfer adds one)
    let chainOfCustody: [TransferSignature]
    
    /// When this proof was created
    let timestamp: Date
    
    /// Nonce to prevent replay attacks
    let nonce: String
    
    struct TransferSignature: Codable, Equatable {
        let fromPeerPublicKey: String
        let toPeerPublicKey: String
        let signature: String
        let timestamp: Date
    }
    
    init(
        issuerPublicKey: String,
        issuerSignature: String,
        chainOfCustody: [TransferSignature] = [],
        timestamp: Date = Date(),
        nonce: String = UUID().uuidString
    ) {
        self.issuerPublicKey = issuerPublicKey
        self.issuerSignature = issuerSignature
        self.chainOfCustody = chainOfCustody
        self.timestamp = timestamp
        self.nonce = nonce
    }
    
    /// Add a transfer signature to the chain of custody
    func withTransfer(
        from fromPublicKey: String,
        to toPublicKey: String,
        signature: String
    ) -> TicketVerificationProof {
        var newChain = chainOfCustody
        newChain.append(TransferSignature(
            fromPeerPublicKey: fromPublicKey,
            toPeerPublicKey: toPublicKey,
            signature: signature,
            timestamp: Date()
        ))
        
        return TicketVerificationProof(
            issuerPublicKey: issuerPublicKey,
            issuerSignature: issuerSignature,
            chainOfCustody: newChain,
            timestamp: timestamp,
            nonce: nonce
        )
    }
}

/// Message payload for ticket transfer operations
struct TicketTransferMessage: Codable {
    let type: MessageType
    let transferRequestID: String
    let ticket: Ticket?
    let proof: TicketVerificationProof?
    let fromPeer: PeerID
    let toPeer: PeerID
    let timestamp: Date
    let signature: String?
    
    enum MessageType: String, Codable {
        case transferRequest   // Sender initiates transfer
        case transferAccept    // Receiver accepts
        case transferReject    // Receiver declines
        case transferComplete  // Final confirmation
        case transferAck       // Acknowledgment
    }
    
    init(
        type: MessageType,
        transferRequestID: String,
        ticket: Ticket? = nil,
        proof: TicketVerificationProof? = nil,
        fromPeer: PeerID,
        toPeer: PeerID,
        timestamp: Date = Date(),
        signature: String? = nil
    ) {
        self.type = type
        self.transferRequestID = transferRequestID
        self.ticket = ticket
        self.proof = proof
        self.fromPeer = fromPeer
        self.toPeer = toPeer
        self.timestamp = timestamp
        self.signature = signature
    }
    
    /// Encode message to JSON data
    func toData() -> Data? {
        try? JSONEncoder().encode(self)
    }
    
    /// Decode message from JSON data
    static func from(_ data: Data) -> TicketTransferMessage? {
        try? JSONDecoder().decode(TicketTransferMessage.self, from: data)
    }
}

/// QR code payload for ticket scanning/import
struct TicketQRPayload: Codable {
    let version: Int
    let type: String  // "ticket"
    let ticket: Ticket
    let proof: TicketVerificationProof
    let barcode: String?  // Original barcode/QR from external source
    let signature: String
    
    init(
        version: Int = 1,
        type: String = "ticket",
        ticket: Ticket,
        proof: TicketVerificationProof,
        barcode: String? = nil,
        signature: String
    ) {
        self.version = version
        self.type = type
        self.ticket = ticket
        self.proof = proof
        self.barcode = barcode
        self.signature = signature
    }
    
    /// Create URL string for QR code
    func toURLString() -> String? {
        guard let jsonData = try? JSONEncoder().encode(self),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        // Base64 encode and make URL-safe
        let base64 = jsonString.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        return "bitchat://ticket?v=\(version)&data=\(base64 ?? "")"
    }
    
    /// Parse from URL string
    static func fromURLString(_ urlString: String) -> TicketQRPayload? {
        guard let url = URL(string: urlString),
              url.scheme == "bitchat",
              url.host == "ticket",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let dataParam = components.queryItems?.first(where: { $0.name == "data" })?.value else {
            return nil
        }
        
        // Base64 decode
        let base64 = dataParam
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let paddingLength = (4 - base64.count % 4) % 4
        let paddedBase64 = base64 + String(repeating: "=", count: paddingLength)
        
        guard let data = Data(base64Encoded: paddedBase64),
              let jsonString = String(data: data, encoding: .utf8),
              let jsonData = jsonString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(TicketQRPayload.self, from: jsonData) else {
            return nil
        }
        
        return payload
    }
}
