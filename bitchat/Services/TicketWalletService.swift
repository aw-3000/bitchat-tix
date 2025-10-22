//
// TicketWalletService.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import Combine

/// Manages user's ticket wallet - owned tickets that can be used, transferred, or listed
@MainActor
final class TicketWalletService: ObservableObject {
    static let shared = TicketWalletService()
    
    /// Active tickets the user owns (not transferred, not used)
    @Published var activeTickets: [OwnedTicket] = []
    
    /// Historical tickets (events completed or tickets transferred)
    @Published var historicalTickets: [OwnedTicket] = []
    
    /// Tickets pending incoming transfer
    @Published var pendingIncoming: [TicketTransferRequest] = []
    
    /// Tickets pending outgoing transfer
    @Published var pendingOutgoing: [TicketTransferRequest] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Wallet Management
    
    /// Add a ticket to the wallet (from purchase, transfer, or import)
    func addTicket(
        _ ticket: Ticket,
        source: TicketSource,
        proof: TicketVerificationProof
    ) -> OwnedTicket {
        let owned = OwnedTicket(
            ticket: ticket,
            source: source,
            proof: proof,
            status: .active,
            acquiredDate: Date()
        )
        
        activeTickets.append(owned)
        saveState()
        return owned
    }
    
    /// Remove a ticket from active wallet (when transferred or used)
    func archiveTicket(_ ticketID: String, reason: ArchiveReason) {
        guard let index = activeTickets.firstIndex(where: { $0.ticket.id == ticketID }) else { return }
        
        var archived = activeTickets[index]
        archived.status = .archived(reason)
        
        activeTickets.remove(at: index)
        historicalTickets.append(archived)
        saveState()
    }
    
    /// Mark ticket as used (scanned at gate)
    func markTicketUsed(_ ticketID: String) {
        archiveTicket(ticketID, reason: .used)
    }
    
    /// Mark ticket as transferred
    func markTicketTransferred(_ ticketID: String, toPeer: PeerID) {
        archiveTicket(ticketID, reason: .transferred(to: toPeer))
    }
    
    /// Get all tickets for a specific event
    func tickets(forEvent eventName: String) -> [OwnedTicket] {
        activeTickets.filter {
            $0.ticket.eventName.localizedCaseInsensitiveContains(eventName)
        }
    }
    
    /// Get tickets for upcoming events (next 30 days)
    func upcomingTickets() -> [OwnedTicket] {
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return activeTickets.filter {
            $0.ticket.eventDate > Date() && $0.ticket.eventDate <= thirtyDaysFromNow
        }.sorted { $0.ticket.eventDate < $1.ticket.eventDate }
    }
    
    /// Get tickets for today's events
    func todaysTickets() -> [OwnedTicket] {
        let calendar = Calendar.current
        return activeTickets.filter {
            calendar.isDateInToday($0.ticket.eventDate)
        }.sorted { $0.ticket.eventDate < $1.ticket.eventDate }
    }
    
    // MARK: - Transfer Management
    
    /// Add pending incoming transfer request
    func addPendingIncomingTransfer(_ request: TicketTransferRequest) {
        pendingIncoming.append(request)
        saveState()
    }
    
    /// Add pending outgoing transfer request
    func addPendingOutgoingTransfer(_ request: TicketTransferRequest) {
        // Mark ticket as transfer-pending
        if let index = activeTickets.firstIndex(where: { $0.ticket.id == request.ticket.id }) {
            activeTickets[index].status = .transferPending
        }
        
        pendingOutgoing.append(request)
        saveState()
    }
    
    /// Remove transfer request (completed or rejected)
    func removePendingTransfer(_ requestID: String) {
        pendingIncoming.removeAll { $0.id == requestID }
        pendingOutgoing.removeAll { $0.id == requestID }
        saveState()
    }
    
    // MARK: - Persistence
    
    private let activeTicketsKey = "ticketWallet.activeTickets"
    private let historicalTicketsKey = "ticketWallet.historicalTickets"
    private let pendingIncomingKey = "ticketWallet.pendingIncoming"
    private let pendingOutgoingKey = "ticketWallet.pendingOutgoing"
    
    func saveState() {
        if let encoded = try? JSONEncoder().encode(activeTickets) {
            UserDefaults.standard.set(encoded, forKey: activeTicketsKey)
        }
        if let encoded = try? JSONEncoder().encode(historicalTickets) {
            UserDefaults.standard.set(encoded, forKey: historicalTicketsKey)
        }
        if let encoded = try? JSONEncoder().encode(pendingIncoming) {
            UserDefaults.standard.set(encoded, forKey: pendingIncomingKey)
        }
        if let encoded = try? JSONEncoder().encode(pendingOutgoing) {
            UserDefaults.standard.set(encoded, forKey: pendingOutgoingKey)
        }
    }
    
    func loadState() {
        if let data = UserDefaults.standard.data(forKey: activeTicketsKey),
           let decoded = try? JSONDecoder().decode([OwnedTicket].self, from: data) {
            activeTickets = decoded
        }
        if let data = UserDefaults.standard.data(forKey: historicalTicketsKey),
           let decoded = try? JSONDecoder().decode([OwnedTicket].self, from: data) {
            historicalTickets = decoded
        }
        if let data = UserDefaults.standard.data(forKey: pendingIncomingKey),
           let decoded = try? JSONDecoder().decode([TicketTransferRequest].self, from: data) {
            pendingIncoming = decoded
        }
        if let data = UserDefaults.standard.data(forKey: pendingOutgoingKey),
           let decoded = try? JSONDecoder().decode([TicketTransferRequest].self, from: data) {
            pendingOutgoing = decoded
        }
    }
    
    private init() {
        loadState()
    }
}

/// Represents a ticket owned by the user in their wallet
struct OwnedTicket: Codable, Equatable, Identifiable {
    let id: String
    let ticket: Ticket
    let source: TicketSource
    let proof: TicketVerificationProof
    var status: TicketStatus
    let acquiredDate: Date
    
    init(
        id: String = UUID().uuidString,
        ticket: Ticket,
        source: TicketSource,
        proof: TicketVerificationProof,
        status: TicketStatus = .active,
        acquiredDate: Date = Date()
    ) {
        self.id = id
        self.ticket = ticket
        self.source = source
        self.proof = proof
        self.status = status
        self.acquiredDate = acquiredDate
    }
    
    enum TicketStatus: Codable, Equatable {
        case active
        case transferPending
        case archived(ArchiveReason)
    }
}

/// How the ticket was acquired
enum TicketSource: Codable, Equatable {
    case purchased(from: PeerID)
    case received(from: PeerID)
    case imported(source: String)
    case original  // User created/issued this ticket
}

/// Why a ticket was archived
enum ArchiveReason: Codable, Equatable {
    case used
    case transferred(to: PeerID)
    case expired
    case refunded
    case cancelled
}
