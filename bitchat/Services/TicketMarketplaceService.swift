//
// TicketMarketplaceService.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import Combine

/// Service to manage the decentralized ticket marketplace
/// Handles listing discovery, transaction coordination, and P2P ticket exchange
@MainActor
final class TicketMarketplaceService: ObservableObject {
    static let shared = TicketMarketplaceService()
    
    /// All active ticket listings discovered on the network
    @Published var listings: [TicketListing] = []
    
    /// User's own listings
    @Published var myListings: [TicketListing] = []
    
    /// Active transactions
    @Published var activeTransactions: [TicketTransaction] = []
    
    /// Completed transactions
    @Published var completedTransactions: [TicketTransaction] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Listing Management
    
    /// Create a new ticket listing
    func createListing(
        ticket: Ticket,
        listingType: TicketListing.ListingType,
        myPeerID: PeerID,
        myNickname: String
    ) -> TicketListing {
        let listing = TicketListing(
            ticket: ticket,
            listingType: listingType,
            sellerPeerID: myPeerID,
            sellerNickname: myNickname
        )
        
        myListings.append(listing)
        listings.append(listing)
        
        return listing
    }
    
    /// Create a listing from a ticket in the wallet (quick list)
    func createListingFromWallet(
        ticketID: String,
        askingPrice: Decimal,
        myPeerID: PeerID,
        myNickname: String,
        companionPreferences: String? = nil
    ) -> TicketListing? {
        // Get ticket from wallet
        let wallet = TicketWalletService.shared
        guard let ownedTicket = wallet.activeTickets.first(where: { $0.ticket.id == ticketID }) else {
            return nil
        }
        
        // Create updated ticket with new price
        var updatedTicket = ownedTicket.ticket
        updatedTicket = Ticket(
            id: updatedTicket.id,
            eventName: updatedTicket.eventName,
            eventDate: updatedTicket.eventDate,
            venue: updatedTicket.venue,
            section: updatedTicket.section,
            row: updatedTicket.row,
            seat: updatedTicket.seat,
            quantity: updatedTicket.quantity,
            originalPrice: updatedTicket.originalPrice,
            askingPrice: askingPrice,
            currency: updatedTicket.currency,
            eventType: updatedTicket.eventType,
            description: updatedTicket.description,
            geohash: updatedTicket.geohash,
            verificationData: updatedTicket.verificationData,
            attendingTogether: companionPreferences != nil,
            companionPreferences: companionPreferences
        )
        
        return createListing(
            ticket: updatedTicket,
            listingType: .sell,
            myPeerID: myPeerID,
            myNickname: myNickname
        )
    }
    
    /// Update the status of a listing
    func updateListingStatus(_ listingID: String, status: TicketListing.ListingStatus) {
        if let index = listings.firstIndex(where: { $0.id == listingID }) {
            var updated = listings[index]
            var newListing = TicketListing(
                id: updated.id,
                ticket: updated.ticket,
                listingType: updated.listingType,
                sellerPeerID: updated.sellerPeerID,
                sellerNickname: updated.sellerNickname,
                timestamp: updated.timestamp,
                status: status
            )
            listings[index] = newListing
        }
        
        if let index = myListings.firstIndex(where: { $0.id == listingID }) {
            var updated = myListings[index]
            var newListing = TicketListing(
                id: updated.id,
                ticket: updated.ticket,
                listingType: updated.listingType,
                sellerPeerID: updated.sellerPeerID,
                sellerNickname: updated.sellerNickname,
                timestamp: updated.timestamp,
                status: status
            )
            myListings[index] = newListing
        }
    }
    
    /// Remove a listing
    func removeListing(_ listingID: String) {
        listings.removeAll { $0.id == listingID }
        myListings.removeAll { $0.id == listingID }
    }
    
    /// Add a listing discovered from the network
    func addDiscoveredListing(_ listing: TicketListing) {
        // Avoid duplicates
        guard !listings.contains(where: { $0.id == listing.id }) else { return }
        
        // Filter out expired events
        guard listing.ticket.eventDate > Date() else { return }
        
        listings.append(listing)
    }
    
    // MARK: - Transaction Management
    
    /// Express interest in buying a ticket
    func expressInterest(
        in listing: TicketListing,
        buyerPeerID: PeerID,
        buyerNickname: String,
        offerPrice: Decimal? = nil
    ) -> TicketTransaction {
        let transaction = TicketTransaction(
            listing: listing,
            buyerPeerID: buyerPeerID,
            buyerNickname: buyerNickname,
            agreedPrice: offerPrice ?? listing.ticket.askingPrice
        )
        
        activeTransactions.append(transaction)
        return transaction
    }
    
    /// Update transaction status
    func updateTransactionStatus(
        _ transactionID: String,
        status: TicketTransaction.TransactionStatus,
        meetupLocation: String? = nil,
        meetupTime: Date? = nil
    ) {
        if let index = activeTransactions.firstIndex(where: { $0.id == transactionID }) {
            let existing = activeTransactions[index]
            let updated = TicketTransaction(
                id: existing.id,
                listing: existing.listing,
                buyerPeerID: existing.buyerPeerID,
                buyerNickname: existing.buyerNickname,
                status: status,
                timestamp: existing.timestamp,
                agreedPrice: existing.agreedPrice,
                meetupLocation: meetupLocation ?? existing.meetupLocation,
                meetupTime: meetupTime ?? existing.meetupTime
            )
            activeTransactions[index] = updated
            
            // Move to completed if done
            if status == .completed || status == .cancelled {
                activeTransactions.remove(at: index)
                completedTransactions.append(updated)
            }
        }
    }
    
    // MARK: - Search and Filter
    
    /// Get listings for a specific event
    func listings(forEvent eventName: String) -> [TicketListing] {
        listings.filter {
            $0.ticket.eventName.localizedCaseInsensitiveContains(eventName)
        }
    }
    
    /// Get listings by location (geohash)
    func listings(nearGeohash geohash: String) -> [TicketListing] {
        let prefix = String(geohash.prefix(min(4, geohash.count)))
        return listings.filter {
            guard let ticketGeohash = $0.ticket.geohash else { return false }
            return ticketGeohash.hasPrefix(prefix)
        }
    }
    
    /// Get listings by event type
    func listings(ofType type: Ticket.EventType) -> [TicketListing] {
        listings.filter { $0.ticket.eventType == type }
    }
    
    /// Get active sell listings (excluding user's own)
    func availableListings(excludingPeerID: PeerID) -> [TicketListing] {
        listings.filter {
            $0.listingType == .sell &&
            $0.status == .active &&
            $0.sellerPeerID != excludingPeerID
        }
    }
    
    // MARK: - Persistence
    
    private var listingsKey = "ticketMarketplace.myListings"
    private var transactionsKey = "ticketMarketplace.completedTransactions"
    
    func saveState() {
        if let encoded = try? JSONEncoder().encode(myListings) {
            UserDefaults.standard.set(encoded, forKey: listingsKey)
        }
        if let encoded = try? JSONEncoder().encode(completedTransactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
    }
    
    func loadState() {
        if let data = UserDefaults.standard.data(forKey: listingsKey),
           let decoded = try? JSONDecoder().decode([TicketListing].self, from: data) {
            myListings = decoded
            listings.append(contentsOf: decoded)
        }
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let decoded = try? JSONDecoder().decode([TicketTransaction].self, from: data) {
            completedTransactions = decoded
        }
    }
    
    private init() {
        loadState()
    }
}
