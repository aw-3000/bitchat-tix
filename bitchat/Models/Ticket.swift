//
// Ticket.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation

/// Represents a ticket for an event that can be exchanged on the P2P marketplace
struct Ticket: Codable, Equatable, Identifiable {
    let id: String
    let eventName: String
    let eventDate: Date
    let venue: String
    let section: String?
    let row: String?
    let seat: String?
    let quantity: Int
    let originalPrice: Decimal?
    let askingPrice: Decimal
    let currency: String
    
    /// Additional event details
    let eventType: EventType
    let description: String?
    
    /// Location for discovery (geohash)
    let geohash: String?
    
    /// Verification data (QR code, barcode, etc.)
    let verificationData: String?
    
    enum EventType: String, Codable {
        case concert
        case sports
        case theater
        case festival
        case conference
        case other
    }
    
    init(
        id: String = UUID().uuidString,
        eventName: String,
        eventDate: Date,
        venue: String,
        section: String? = nil,
        row: String? = nil,
        seat: String? = nil,
        quantity: Int = 1,
        originalPrice: Decimal? = nil,
        askingPrice: Decimal,
        currency: String = "USD",
        eventType: EventType = .other,
        description: String? = nil,
        geohash: String? = nil,
        verificationData: String? = nil
    ) {
        self.id = id
        self.eventName = eventName
        self.eventDate = eventDate
        self.venue = venue
        self.section = section
        self.row = row
        self.seat = seat
        self.quantity = quantity
        self.originalPrice = originalPrice
        self.askingPrice = askingPrice
        self.currency = currency
        self.eventType = eventType
        self.description = description
        self.geohash = geohash
        self.verificationData = verificationData
    }
    
    var displayLocation: String {
        var parts: [String] = []
        if let section = section {
            parts.append("Sec \(section)")
        }
        if let row = row {
            parts.append("Row \(row)")
        }
        if let seat = seat {
            parts.append("Seat \(seat)")
        }
        return parts.isEmpty ? "General Admission" : parts.joined(separator: ", ")
    }
    
    var priceDisplay: String {
        "\(currency) \(askingPrice)"
    }
}

/// Represents a ticket listing on the marketplace (sell or buy request)
struct TicketListing: Codable, Equatable, Identifiable {
    let id: String
    let ticket: Ticket
    let listingType: ListingType
    let sellerPeerID: PeerID
    let sellerNickname: String
    let timestamp: Date
    let status: ListingStatus
    
    enum ListingType: String, Codable {
        case sell  // Selling tickets
        case buy   // Looking to buy tickets (wanted)
    }
    
    enum ListingStatus: String, Codable {
        case active
        case pending    // Transaction in progress
        case sold
        case cancelled
    }
    
    init(
        id: String = UUID().uuidString,
        ticket: Ticket,
        listingType: ListingType,
        sellerPeerID: PeerID,
        sellerNickname: String,
        timestamp: Date = Date(),
        status: ListingStatus = .active
    ) {
        self.id = id
        self.ticket = ticket
        self.listingType = listingType
        self.sellerPeerID = sellerPeerID
        self.sellerNickname = sellerNickname
        self.timestamp = timestamp
        self.status = status
    }
}

/// Transaction state for ticket exchange
struct TicketTransaction: Codable, Equatable, Identifiable {
    let id: String
    let listing: TicketListing
    let buyerPeerID: PeerID
    let buyerNickname: String
    let status: TransactionStatus
    let timestamp: Date
    let agreedPrice: Decimal
    let meetupLocation: String?
    let meetupTime: Date?
    
    enum TransactionStatus: String, Codable {
        case proposed      // Buyer expressed interest
        case negotiating   // Price/terms being discussed
        case agreed        // Both parties agreed, meeting pending
        case completed     // Ticket transferred
        case cancelled     // Transaction cancelled
    }
    
    init(
        id: String = UUID().uuidString,
        listing: TicketListing,
        buyerPeerID: PeerID,
        buyerNickname: String,
        status: TransactionStatus = .proposed,
        timestamp: Date = Date(),
        agreedPrice: Decimal,
        meetupLocation: String? = nil,
        meetupTime: Date? = nil
    ) {
        self.id = id
        self.listing = listing
        self.buyerPeerID = buyerPeerID
        self.buyerNickname = buyerNickname
        self.status = status
        self.timestamp = timestamp
        self.agreedPrice = agreedPrice
        self.meetupLocation = meetupLocation
        self.meetupTime = meetupTime
    }
}
