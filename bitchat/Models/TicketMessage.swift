//
// TicketMessage.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation

/// Message payload for ticket exchange operations over the P2P network
struct TicketMessage: Codable {
    let type: TicketMessageType
    let listingID: String?
    let listing: TicketListing?
    let transaction: TicketTransaction?
    let action: TicketAction?
    
    enum TicketMessageType: String, Codable {
        case listingBroadcast    // Broadcast a new listing to the network
        case listingUpdate       // Update an existing listing
        case buyerInterest       // Buyer expresses interest
        case priceOffer          // Counter-offer on price
        case transactionProposal // Propose meeting details
        case transactionAccept   // Accept transaction terms
        case transactionComplete // Mark transaction as complete
        case transactionCancel   // Cancel transaction
    }
    
    enum TicketAction: String, Codable {
        case list      // List a ticket for sale
        case unlist    // Remove listing
        case offer     // Make an offer
        case accept    // Accept offer/terms
        case decline   // Decline offer
        case confirm   // Confirm completion
        case cancel    // Cancel
    }
    
    init(
        type: TicketMessageType,
        listingID: String? = nil,
        listing: TicketListing? = nil,
        transaction: TicketTransaction? = nil,
        action: TicketAction? = nil
    ) {
        self.type = type
        self.listingID = listingID
        self.listing = listing
        self.transaction = transaction
        self.action = action
    }
    
    /// Encode ticket message to JSON data for transmission
    func toData() -> Data? {
        try? JSONEncoder().encode(self)
    }
    
    /// Decode ticket message from JSON data
    static func from(_ data: Data) -> TicketMessage? {
        try? JSONDecoder().decode(TicketMessage.self, from: data)
    }
}
