//
// TicketMarketplaceTests.swift
// bitchatTests
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import XCTest
@testable import bitchat

@MainActor
final class TicketMarketplaceTests: XCTestCase {
    
    var marketplace: TicketMarketplaceService!
    var testPeerID: PeerID!
    
    override func setUp() async throws {
        marketplace = TicketMarketplaceService.shared
        // Clear any existing state
        marketplace.listings.removeAll()
        marketplace.myListings.removeAll()
        marketplace.activeTransactions.removeAll()
        marketplace.completedTransactions.removeAll()
        
        testPeerID = PeerID(str: "test-peer-123")
    }
    
    // MARK: - Ticket Creation Tests
    
    func testTicketCreation() {
        let ticket = Ticket(
            eventName: "Test Concert",
            eventDate: Date().addingTimeInterval(86400 * 7),
            venue: "Test Venue",
            section: "A",
            row: "5",
            seat: "12",
            quantity: 2,
            askingPrice: Decimal(50),
            currency: "USD",
            eventType: .concert
        )
        
        XCTAssertEqual(ticket.eventName, "Test Concert")
        XCTAssertEqual(ticket.venue, "Test Venue")
        XCTAssertEqual(ticket.quantity, 2)
        XCTAssertEqual(ticket.askingPrice, Decimal(50))
        XCTAssertEqual(ticket.currency, "USD")
        XCTAssertEqual(ticket.eventType, .concert)
        XCTAssertEqual(ticket.displayLocation, "Sec A, Row 5, Seat 12")
    }
    
    func testTicketDisplayLocation() {
        var ticket = Ticket(
            eventName: "Test",
            eventDate: Date(),
            venue: "Venue",
            askingPrice: Decimal(50)
        )
        XCTAssertEqual(ticket.displayLocation, "General Admission")
        
        ticket = Ticket(
            eventName: "Test",
            eventDate: Date(),
            venue: "Venue",
            section: "VIP",
            askingPrice: Decimal(100)
        )
        XCTAssertEqual(ticket.displayLocation, "Sec VIP")
    }
    
    // MARK: - Listing Tests
    
    func testCreateListing() {
        let ticket = Ticket(
            eventName: "Rock Concert",
            eventDate: Date().addingTimeInterval(86400 * 14),
            venue: "Stadium",
            askingPrice: Decimal(75),
            eventType: .concert
        )
        
        let listing = marketplace.createListing(
            ticket: ticket,
            listingType: .sell,
            myPeerID: testPeerID,
            myNickname: "TestUser"
        )
        
        XCTAssertEqual(listing.ticket.eventName, "Rock Concert")
        XCTAssertEqual(listing.listingType, .sell)
        XCTAssertEqual(listing.sellerPeerID, testPeerID)
        XCTAssertEqual(listing.sellerNickname, "TestUser")
        XCTAssertEqual(listing.status, .active)
        XCTAssertEqual(marketplace.myListings.count, 1)
        XCTAssertEqual(marketplace.listings.count, 1)
    }
    
    func testUpdateListingStatus() {
        let ticket = Ticket(
            eventName: "Sports Game",
            eventDate: Date().addingTimeInterval(86400),
            venue: "Arena",
            askingPrice: Decimal(100),
            eventType: .sports
        )
        
        let listing = marketplace.createListing(
            ticket: ticket,
            listingType: .sell,
            myPeerID: testPeerID,
            myNickname: "TestUser"
        )
        
        marketplace.updateListingStatus(listing.id, status: .sold)
        
        XCTAssertEqual(marketplace.listings.first?.status, .sold)
        XCTAssertEqual(marketplace.myListings.first?.status, .sold)
    }
    
    func testRemoveListing() {
        let ticket = Ticket(
            eventName: "Theater Show",
            eventDate: Date().addingTimeInterval(86400 * 3),
            venue: "Playhouse",
            askingPrice: Decimal(60),
            eventType: .theater
        )
        
        let listing = marketplace.createListing(
            ticket: ticket,
            listingType: .sell,
            myPeerID: testPeerID,
            myNickname: "TestUser"
        )
        
        XCTAssertEqual(marketplace.listings.count, 1)
        
        marketplace.removeListing(listing.id)
        
        XCTAssertEqual(marketplace.listings.count, 0)
        XCTAssertEqual(marketplace.myListings.count, 0)
    }
    
    // MARK: - Transaction Tests
    
    func testExpressInterest() {
        let ticket = Ticket(
            eventName: "Festival",
            eventDate: Date().addingTimeInterval(86400 * 30),
            venue: "Park",
            askingPrice: Decimal(150),
            eventType: .festival
        )
        
        let listing = marketplace.createListing(
            ticket: ticket,
            listingType: .sell,
            myPeerID: testPeerID,
            myNickname: "Seller"
        )
        
        let buyerPeerID = PeerID(str: "buyer-456")
        let transaction = marketplace.expressInterest(
            in: listing,
            buyerPeerID: buyerPeerID,
            buyerNickname: "Buyer"
        )
        
        XCTAssertEqual(transaction.listing.id, listing.id)
        XCTAssertEqual(transaction.buyerPeerID, buyerPeerID)
        XCTAssertEqual(transaction.buyerNickname, "Buyer")
        XCTAssertEqual(transaction.status, .proposed)
        XCTAssertEqual(marketplace.activeTransactions.count, 1)
    }
    
    func testUpdateTransactionStatus() {
        let ticket = Ticket(
            eventName: "Concert",
            eventDate: Date().addingTimeInterval(86400 * 7),
            venue: "Hall",
            askingPrice: Decimal(80),
            eventType: .concert
        )
        
        let listing = marketplace.createListing(
            ticket: ticket,
            listingType: .sell,
            myPeerID: testPeerID,
            myNickname: "Seller"
        )
        
        let buyerPeerID = PeerID(str: "buyer-789")
        let transaction = marketplace.expressInterest(
            in: listing,
            buyerPeerID: buyerPeerID,
            buyerNickname: "Buyer"
        )
        
        marketplace.updateTransactionStatus(
            transaction.id,
            status: .agreed,
            meetupLocation: "Main Gate",
            meetupTime: Date().addingTimeInterval(3600)
        )
        
        XCTAssertEqual(marketplace.activeTransactions.first?.status, .agreed)
        XCTAssertEqual(marketplace.activeTransactions.first?.meetupLocation, "Main Gate")
    }
    
    func testCompleteTransaction() {
        let ticket = Ticket(
            eventName: "Match",
            eventDate: Date().addingTimeInterval(86400 * 2),
            venue: "Stadium",
            askingPrice: Decimal(120),
            eventType: .sports
        )
        
        let listing = marketplace.createListing(
            ticket: ticket,
            listingType: .sell,
            myPeerID: testPeerID,
            myNickname: "Seller"
        )
        
        let buyerPeerID = PeerID(str: "buyer-complete")
        let transaction = marketplace.expressInterest(
            in: listing,
            buyerPeerID: buyerPeerID,
            buyerNickname: "Buyer"
        )
        
        marketplace.updateTransactionStatus(transaction.id, status: .completed)
        
        XCTAssertEqual(marketplace.activeTransactions.count, 0)
        XCTAssertEqual(marketplace.completedTransactions.count, 1)
        XCTAssertEqual(marketplace.completedTransactions.first?.status, .completed)
    }
    
    // MARK: - Search and Filter Tests
    
    func testListingsForEvent() {
        let ticket1 = Ticket(
            eventName: "Taylor Swift Concert",
            eventDate: Date().addingTimeInterval(86400 * 10),
            venue: "Arena",
            askingPrice: Decimal(200),
            eventType: .concert
        )
        
        let ticket2 = Ticket(
            eventName: "Lakers Game",
            eventDate: Date().addingTimeInterval(86400 * 5),
            venue: "Staples Center",
            askingPrice: Decimal(150),
            eventType: .sports
        )
        
        marketplace.createListing(
            ticket: ticket1,
            listingType: .sell,
            myPeerID: testPeerID,
            myNickname: "User1"
        )
        
        marketplace.createListing(
            ticket: ticket2,
            listingType: .sell,
            myPeerID: testPeerID,
            myNickname: "User2"
        )
        
        let results = marketplace.listings(forEvent: "Taylor Swift")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.ticket.eventName, "Taylor Swift Concert")
    }
    
    func testListingsByType() {
        let concert = Ticket(
            eventName: "Concert",
            eventDate: Date().addingTimeInterval(86400),
            venue: "Venue1",
            askingPrice: Decimal(50),
            eventType: .concert
        )
        
        let sports = Ticket(
            eventName: "Game",
            eventDate: Date().addingTimeInterval(86400 * 2),
            venue: "Venue2",
            askingPrice: Decimal(100),
            eventType: .sports
        )
        
        marketplace.createListing(
            ticket: concert,
            listingType: .sell,
            myPeerID: testPeerID,
            myNickname: "User1"
        )
        
        marketplace.createListing(
            ticket: sports,
            listingType: .sell,
            myPeerID: testPeerID,
            myNickname: "User2"
        )
        
        let concertListings = marketplace.listings(ofType: .concert)
        XCTAssertEqual(concertListings.count, 1)
        XCTAssertEqual(concertListings.first?.ticket.eventType, .concert)
        
        let sportsListings = marketplace.listings(ofType: .sports)
        XCTAssertEqual(sportsListings.count, 1)
        XCTAssertEqual(sportsListings.first?.ticket.eventType, .sports)
    }
    
    // MARK: - Ticket Message Tests
    
    func testTicketMessageEncoding() {
        let ticket = Ticket(
            eventName: "Test Event",
            eventDate: Date(),
            venue: "Test Venue",
            askingPrice: Decimal(50)
        )
        
        let listing = TicketListing(
            ticket: ticket,
            listingType: .sell,
            sellerPeerID: testPeerID,
            sellerNickname: "TestUser"
        )
        
        let message = TicketMessage(
            type: .listingBroadcast,
            listing: listing
        )
        
        XCTAssertNotNil(message.toData())
    }
    
    func testTicketMessageDecoding() {
        let ticket = Ticket(
            eventName: "Test Event",
            eventDate: Date(),
            venue: "Test Venue",
            askingPrice: Decimal(50)
        )
        
        let listing = TicketListing(
            ticket: ticket,
            listingType: .sell,
            sellerPeerID: testPeerID,
            sellerNickname: "TestUser"
        )
        
        let message = TicketMessage(
            type: .listingBroadcast,
            listing: listing
        )
        
        guard let data = message.toData() else {
            XCTFail("Failed to encode message")
            return
        }
        
        let decoded = TicketMessage.from(data)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.type, .listingBroadcast)
        XCTAssertEqual(decoded?.listing?.ticket.eventName, "Test Event")
    }
    
    // MARK: - Companion Seating Tests
    
    func testCompanionTicketCreation() {
        let ticket = Ticket(
            eventName: "Indie Rock Concert",
            eventDate: Date().addingTimeInterval(86400 * 10),
            venue: "Club Venue",
            section: "GA",
            quantity: 1,
            askingPrice: Decimal(45),
            currency: "USD",
            eventType: .concert,
            attendingTogether: true,
            companionPreferences: "20s-30s, love indie rock, chill vibe"
        )
        
        XCTAssertTrue(ticket.attendingTogether)
        XCTAssertEqual(ticket.companionPreferences, "20s-30s, love indie rock, chill vibe")
        XCTAssertEqual(ticket.eventName, "Indie Rock Concert")
    }
    
    func testCompanionListingWithoutPreferences() {
        let ticket = Ticket(
            eventName: "Sports Game",
            eventDate: Date().addingTimeInterval(86400 * 5),
            venue: "Stadium",
            quantity: 1,
            askingPrice: Decimal(80),
            eventType: .sports,
            attendingTogether: true
        )
        
        XCTAssertTrue(ticket.attendingTogether)
        XCTAssertNil(ticket.companionPreferences)
    }
    
    func testRegularTicketDefaults() {
        let ticket = Ticket(
            eventName: "Regular Event",
            eventDate: Date().addingTimeInterval(86400),
            venue: "Venue",
            askingPrice: Decimal(50)
        )
        
        XCTAssertFalse(ticket.attendingTogether)
        XCTAssertNil(ticket.companionPreferences)
    }
    
    func testCompanionListingCodable() {
        let ticket = Ticket(
            eventName: "Festival",
            eventDate: Date().addingTimeInterval(86400 * 30),
            venue: "Festival Grounds",
            quantity: 2,
            askingPrice: Decimal(120),
            eventType: .festival,
            attendingTogether: true,
            companionPreferences: "Music lovers, good vibes only"
        )
        
        let listing = TicketListing(
            ticket: ticket,
            listingType: .sell,
            sellerPeerID: testPeerID,
            sellerNickname: "FestivalFan"
        )
        
        // Test encoding/decoding
        guard let encoded = try? JSONEncoder().encode(listing) else {
            XCTFail("Failed to encode listing")
            return
        }
        
        guard let decoded = try? JSONDecoder().decode(TicketListing.self, from: encoded) else {
            XCTFail("Failed to decode listing")
            return
        }
        
        XCTAssertEqual(decoded.ticket.attendingTogether, ticket.attendingTogether)
        XCTAssertEqual(decoded.ticket.companionPreferences, ticket.companionPreferences)
    }
}
