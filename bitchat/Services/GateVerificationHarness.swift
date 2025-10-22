//
// GateVerificationHarness.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import Combine

/// Service for venue gate ticket verification (offline-first)
@MainActor
final class GateVerificationHarness: ObservableObject {
    static let shared = GateVerificationHarness()
    
    /// Gate configuration
    @Published var configuration: GateConfiguration?
    
    /// Tickets that have been scanned and used
    @Published var usedTickets: Set<String> = []
    
    /// Verification statistics
    @Published var stats = VerificationStats()
    
    /// Gate operation mode
    @Published var mode: GateMode = .offline
    
    private var cancellables = Set<AnyCancellable>()
    private var verificationService: TicketVerificationService { TicketVerificationService.shared }
    
    // MARK: - Gate Setup
    
    /// Configure gate for an event
    func configureGate(
        eventID: String,
        eventName: String,
        venue: String,
        eventDate: Date,
        gateID: String,
        trustedIssuerKeys: [String]
    ) {
        configuration = GateConfiguration(
            eventID: eventID,
            eventName: eventName,
            venue: venue,
            eventDate: eventDate,
            gateID: gateID,
            trustedIssuerKeys: trustedIssuerKeys
        )
        
        // Add trusted issuers to verification service
        for key in trustedIssuerKeys {
            verificationService.addTrustedIssuer(key)
        }
        
        // Reset stats for this gate session
        stats = VerificationStats()
        
        saveConfiguration()
    }
    
    /// Clear gate configuration
    func clearConfiguration() {
        configuration = nil
        usedTickets.removeAll()
        stats = VerificationStats()
        saveConfiguration()
    }
    
    // MARK: - Ticket Verification
    
    /// Verify a ticket from QR code data
    func verifyTicket(qrData: String) -> GateVerificationResult {
        guard let config = configuration else {
            return GateVerificationResult(
                status: .error,
                ticket: nil,
                message: "Gate not configured"
            )
        }
        
        // Parse QR code
        guard let payload = TicketQRPayload.fromURLString(qrData) else {
            stats.invalidTickets += 1
            return GateVerificationResult(
                status: .invalid,
                ticket: nil,
                message: "Invalid QR code format"
            )
        }
        
        let ticket = payload.ticket
        
        // Verify ticket belongs to this event
        guard matchesEvent(ticket, config: config) else {
            stats.wrongEvent += 1
            return GateVerificationResult(
                status: .wrongEvent,
                ticket: ticket,
                message: "Ticket is for a different event"
            )
        }
        
        // Verify ticket hasn't been used
        if usedTickets.contains(ticket.id) {
            stats.duplicateScans += 1
            return GateVerificationResult(
                status: .alreadyUsed,
                ticket: ticket,
                message: "Ticket has already been scanned"
            )
        }
        
        // Verify cryptographic authenticity
        let verificationResult = verificationService.verifyTicket(ticket, proof: payload.proof)
        guard verificationResult.isValid else {
            stats.invalidTickets += 1
            return GateVerificationResult(
                status: .invalid,
                ticket: ticket,
                message: verificationResult.details ?? "Signature verification failed"
            )
        }
        
        // Verify event time window
        if !isWithinEventWindow(config: config) {
            stats.expired += 1
            return GateVerificationResult(
                status: .expired,
                ticket: ticket,
                message: "Event time window has passed"
            )
        }
        
        // All checks passed - ticket is valid!
        stats.successfulScans += 1
        return GateVerificationResult(
            status: .valid,
            ticket: ticket,
            message: "✅ Valid ticket - Admit entry"
        )
    }
    
    /// Mark a ticket as used after successful verification
    func markTicketUsed(_ ticketID: String) {
        usedTickets.insert(ticketID)
        saveUsedTickets()
        
        // TODO: Sync to relay if online
        if mode == .online {
            syncUsedTicketsToRelay()
        }
    }
    
    // MARK: - Bluetooth Transfer Verification
    
    /// Verify a ticket received via Bluetooth transfer
    func verifyTransferredTicket(
        _ ticket: Ticket,
        proof: TicketVerificationProof
    ) -> GateVerificationResult {
        guard let config = configuration else {
            return GateVerificationResult(
                status: .error,
                ticket: nil,
                message: "Gate not configured"
            )
        }
        
        // Similar verification as QR but from transfer
        guard matchesEvent(ticket, config: config) else {
            stats.wrongEvent += 1
            return GateVerificationResult(
                status: .wrongEvent,
                ticket: ticket,
                message: "Ticket is for a different event"
            )
        }
        
        if usedTickets.contains(ticket.id) {
            stats.duplicateScans += 1
            return GateVerificationResult(
                status: .alreadyUsed,
                ticket: ticket,
                message: "Ticket has already been used"
            )
        }
        
        let verificationResult = verificationService.verifyTicket(ticket, proof: proof)
        guard verificationResult.isValid else {
            stats.invalidTickets += 1
            return GateVerificationResult(
                status: .invalid,
                ticket: ticket,
                message: verificationResult.details ?? "Verification failed"
            )
        }
        
        if !isWithinEventWindow(config: config) {
            stats.expired += 1
            return GateVerificationResult(
                status: .expired,
                ticket: ticket,
                message: "Event time window has passed"
            )
        }
        
        stats.successfulScans += 1
        return GateVerificationResult(
            status: .valid,
            ticket: ticket,
            message: "✅ Valid ticket - Admit entry"
        )
    }
    
    // MARK: - Helper Methods
    
    private func matchesEvent(_ ticket: Ticket, config: GateConfiguration) -> Bool {
        // Check if ticket matches event configuration
        // For now, match by event name and venue
        return ticket.eventName == config.eventName &&
               ticket.venue == config.venue
    }
    
    private func isWithinEventWindow(config: GateConfiguration) -> Bool {
        let now = Date()
        let eventDate = config.eventDate
        
        // Allow entry 4 hours before and 2 hours after event start
        let entryWindowStart = eventDate.addingTimeInterval(-4 * 60 * 60)
        let entryWindowEnd = eventDate.addingTimeInterval(2 * 60 * 60)
        
        return now >= entryWindowStart && now <= entryWindowEnd
    }
    
    // MARK: - Sync Operations
    
    /// Sync used tickets to relay (when online)
    private func syncUsedTicketsToRelay() {
        // TODO: Implement relay sync
        // Upload current used tickets list to Nostr relay
        // Download any tickets used at other gates
    }
    
    /// Download used tickets from relay
    func fetchUsedTicketsFromRelay() async {
        // TODO: Implement
        // Query relay for used tickets for this event
        // Merge with local used tickets set
    }
    
    // MARK: - Bluetooth Mesh Sync
    
    /// Share used tickets with nearby gates via Bluetooth
    func syncWithNearbyGates() {
        // TODO: Implement Bluetooth mesh sync
        // Broadcast used tickets to nearby gate devices
        // Receive and merge used tickets from other gates
    }
    
    // MARK: - Persistence
    
    private let configKey = "gateVerification.configuration"
    private let usedTicketsKey = "gateVerification.usedTickets"
    private let statsKey = "gateVerification.stats"
    
    private func saveConfiguration() {
        if let encoded = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(encoded, forKey: configKey)
        } else {
            UserDefaults.standard.removeObject(forKey: configKey)
        }
    }
    
    private func saveUsedTickets() {
        let array = Array(usedTickets)
        UserDefaults.standard.set(array, forKey: usedTicketsKey)
        
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }
    
    private func loadState() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let decoded = try? JSONDecoder().decode(GateConfiguration.self, from: data) {
            configuration = decoded
        }
        
        if let array = UserDefaults.standard.array(forKey: usedTicketsKey) as? [String] {
            usedTickets = Set(array)
        }
        
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(VerificationStats.self, from: data) {
            stats = decoded
        }
    }
    
    private init() {
        loadState()
    }
}

/// Gate configuration for an event
struct GateConfiguration: Codable {
    let eventID: String
    let eventName: String
    let venue: String
    let eventDate: Date
    let gateID: String
    let trustedIssuerKeys: [String]
}

/// Gate operation mode
enum GateMode {
    case offline       // No internet, use local DB only
    case online        // Connected, sync with relay
    case mesh          // Bluetooth mesh sync with nearby gates
}

/// Result of gate verification
struct GateVerificationResult {
    let status: VerificationStatus
    let ticket: Ticket?
    let message: String
    
    enum VerificationStatus {
        case valid
        case alreadyUsed
        case invalid
        case expired
        case wrongEvent
        case error
    }
}

/// Statistics for gate operations
struct VerificationStats: Codable {
    var successfulScans: Int = 0
    var duplicateScans: Int = 0
    var invalidTickets: Int = 0
    var expired: Int = 0
    var wrongEvent: Int = 0
    
    var totalScans: Int {
        successfulScans + duplicateScans + invalidTickets + expired + wrongEvent
    }
}
