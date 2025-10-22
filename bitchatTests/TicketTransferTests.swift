//
// TicketTransferTests.swift
// bitchatTests
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import XCTest
@testable import bitchat

@MainActor
final class TicketTransferTests: XCTestCase {
    
    var walletService: TicketWalletService!
    var transferService: TicketTransferService!
    var verificationService: TicketVerificationService!
    var gateHarness: GateVerificationHarness!
    
    var testPeerID: PeerID!
    var otherPeerID: PeerID!
    
    override func setUp() async throws {
        walletService = TicketWalletService.shared
        transferService = TicketTransferService.shared
        verificationService = TicketVerificationService.shared
        gateHarness = GateVerificationHarness.shared
        
        // Clear state
        walletService.activeTickets.removeAll()
        walletService.historicalTickets.removeAll()
        walletService.pendingIncoming.removeAll()
        walletService.pendingOutgoing.removeAll()
        transferService.activeTransfers.removeAll()
        gateHarness.clearConfiguration()
        
        testPeerID = PeerID(str: "test-peer-123")
        otherPeerID = PeerID(str: "other-peer-456")
    }
    
    // MARK: - Wallet Tests
    
    func testAddTicketToWallet() {
        let ticket = createTestTicket()
        let proof = createTestProof()
        
        let owned = walletService.addTicket(
            ticket,
            source: .purchased(from: otherPeerID),
            proof: proof
        )
        
        XCTAssertEqual(walletService.activeTickets.count, 1)
        XCTAssertEqual(owned.ticket.eventName, "Test Concert")
        XCTAssertEqual(owned.status, .active)
    }
    
    func testMarkTicketUsed() {
        let ticket = createTestTicket()
        let proof = createTestProof()
        let owned = walletService.addTicket(ticket, source: .original, proof: proof)
        
        walletService.markTicketUsed(owned.ticket.id)
        
        XCTAssertEqual(walletService.activeTickets.count, 0)
        XCTAssertEqual(walletService.historicalTickets.count, 1)
        XCTAssertEqual(walletService.historicalTickets.first?.status, .archived(.used))
    }
    
    func testMarkTicketTransferred() {
        let ticket = createTestTicket()
        let proof = createTestProof()
        let owned = walletService.addTicket(ticket, source: .original, proof: proof)
        
        walletService.markTicketTransferred(owned.ticket.id, toPeer: otherPeerID)
        
        XCTAssertEqual(walletService.activeTickets.count, 0)
        XCTAssertEqual(walletService.historicalTickets.count, 1)
        
        if case .archived(let reason) = walletService.historicalTickets.first?.status {
            if case .transferred(let toPeer) = reason {
                XCTAssertEqual(toPeer, otherPeerID)
            } else {
                XCTFail("Expected transferred reason")
            }
        } else {
            XCTFail("Expected archived status")
        }
    }
    
    func testUpcomingTickets() {
        // Future ticket (tomorrow)
        let futureTicket = Ticket(
            eventName: "Future Event",
            eventDate: Date().addingTimeInterval(86400),
            venue: "Venue",
            askingPrice: Decimal(50)
        )
        
        // Past ticket
        let pastTicket = Ticket(
            eventName: "Past Event",
            eventDate: Date().addingTimeInterval(-86400),
            venue: "Venue",
            askingPrice: Decimal(50)
        )
        
        let proof = createTestProof()
        walletService.addTicket(futureTicket, source: .original, proof: proof)
        walletService.addTicket(pastTicket, source: .original, proof: proof)
        
        let upcoming = walletService.upcomingTickets()
        
        XCTAssertEqual(upcoming.count, 1)
        XCTAssertEqual(upcoming.first?.ticket.eventName, "Future Event")
    }
    
    // MARK: - Transfer Tests
    
    func testInitiateTransfer() throws {
        let ticket = createTestTicket()
        let proof = createTestProof()
        walletService.addTicket(ticket, source: .original, proof: proof)
        
        let request = try transferService.initiateTransfer(
            ticket: ticket,
            proof: proof,
            toPeer: otherPeerID,
            toNickname: "Buyer",
            fromPeer: testPeerID,
            fromNickname: "Seller",
            method: .bluetooth
        )
        
        XCTAssertEqual(request.status, .pending)
        XCTAssertEqual(request.fromPeer, testPeerID)
        XCTAssertEqual(request.toPeer, otherPeerID)
        XCTAssertEqual(transferService.activeTransfers.count, 1)
        XCTAssertEqual(walletService.pendingOutgoing.count, 1)
    }
    
    func testCannotTransferUnownedTicket() {
        let ticket = createTestTicket()
        let proof = createTestProof()
        
        // Don't add to wallet
        
        XCTAssertThrowsError(
            try transferService.initiateTransfer(
                ticket: ticket,
                proof: proof,
                toPeer: otherPeerID,
                toNickname: "Buyer",
                fromPeer: testPeerID,
                fromNickname: "Seller",
                method: .bluetooth
            )
        ) { error in
            XCTAssertEqual(
                error as? TicketTransferService.TransferError,
                .ticketNotOwned
            )
        }
    }
    
    func testReceiveTransferRequest() {
        let ticket = createTestTicket()
        let proof = createTestProof()
        
        let request = TicketTransferRequest(
            ticket: ticket,
            proof: proof,
            fromPeer: otherPeerID,
            fromNickname: "Sender",
            toPeer: testPeerID,
            toNickname: "Receiver",
            method: .bluetooth
        )
        
        // Mock verification to always pass
        verificationService.addTrustedIssuer("test-issuer-key")
        
        transferService.receiveTransferRequest(request)
        
        XCTAssertEqual(walletService.pendingIncoming.count, 1)
        XCTAssertEqual(transferService.activeTransfers.count, 1)
    }
    
    // MARK: - Verification Tests
    
    func testVerificationProofCreation() {
        let proof = TicketVerificationProof(
            issuerPublicKey: "test-key",
            issuerSignature: "test-sig",
            chainOfCustody: [],
            timestamp: Date(),
            nonce: "test-nonce"
        )
        
        XCTAssertEqual(proof.issuerPublicKey, "test-key")
        XCTAssertEqual(proof.chainOfCustody.count, 0)
    }
    
    func testVerificationProofWithTransfer() {
        let proof = TicketVerificationProof(
            issuerPublicKey: "issuer-key",
            issuerSignature: "issuer-sig"
        )
        
        let withTransfer = proof.withTransfer(
            from: "from-key",
            to: "to-key",
            signature: "transfer-sig"
        )
        
        XCTAssertEqual(withTransfer.chainOfCustody.count, 1)
        XCTAssertEqual(withTransfer.chainOfCustody.first?.fromPeerPublicKey, "from-key")
        XCTAssertEqual(withTransfer.chainOfCustody.first?.toPeerPublicKey, "to-key")
    }
    
    func testTrustedIssuerManagement() {
        verificationService.addTrustedIssuer("issuer-1")
        verificationService.addTrustedIssuer("issuer-2")
        
        XCTAssertTrue(verificationService.isIssuerTrusted("issuer-1"))
        XCTAssertTrue(verificationService.isIssuerTrusted("issuer-2"))
        XCTAssertFalse(verificationService.isIssuerTrusted("issuer-3"))
        
        verificationService.removeTrustedIssuer("issuer-1")
        XCTAssertFalse(verificationService.isIssuerTrusted("issuer-1"))
    }
    
    // MARK: - Gate Verification Tests
    
    func testGateConfiguration() {
        let eventDate = Date().addingTimeInterval(3600)
        
        gateHarness.configureGate(
            eventID: "event-123",
            eventName: "Test Concert",
            venue: "Test Venue",
            eventDate: eventDate,
            gateID: "gate-1",
            trustedIssuerKeys: ["issuer-key-1"]
        )
        
        XCTAssertNotNil(gateHarness.configuration)
        XCTAssertEqual(gateHarness.configuration?.eventName, "Test Concert")
        XCTAssertEqual(gateHarness.configuration?.gateID, "gate-1")
    }
    
    func testGateClearConfiguration() {
        let eventDate = Date().addingTimeInterval(3600)
        
        gateHarness.configureGate(
            eventID: "event-123",
            eventName: "Test Concert",
            venue: "Test Venue",
            eventDate: eventDate,
            gateID: "gate-1",
            trustedIssuerKeys: ["issuer-key-1"]
        )
        
        gateHarness.clearConfiguration()
        
        XCTAssertNil(gateHarness.configuration)
        XCTAssertEqual(gateHarness.usedTickets.count, 0)
    }
    
    func testMarkTicketUsedAtGate() {
        gateHarness.markTicketUsed("ticket-123")
        
        XCTAssertTrue(gateHarness.usedTickets.contains("ticket-123"))
    }
    
    func testGateStatistics() {
        var stats = VerificationStats()
        
        stats.successfulScans = 10
        stats.duplicateScans = 2
        stats.invalidTickets = 1
        
        XCTAssertEqual(stats.totalScans, 13)
    }
    
    // MARK: - QR Code Tests
    
    func testTicketQRPayloadCreation() {
        let ticket = createTestTicket()
        let proof = createTestProof()
        
        let payload = TicketQRPayload(
            ticket: ticket,
            proof: proof,
            signature: "test-sig"
        )
        
        XCTAssertEqual(payload.type, "ticket")
        XCTAssertEqual(payload.version, 1)
        XCTAssertEqual(payload.ticket.eventName, "Test Concert")
    }
    
    func testTicketQRPayloadURLEncoding() {
        let ticket = createTestTicket()
        let proof = createTestProof()
        
        let payload = TicketQRPayload(
            ticket: ticket,
            proof: proof,
            signature: "test-sig"
        )
        
        let urlString = payload.toURLString()
        XCTAssertNotNil(urlString)
        XCTAssertTrue(urlString!.hasPrefix("bitchat://ticket?"))
    }
    
    func testTicketQRPayloadURLDecoding() {
        let ticket = createTestTicket()
        let proof = createTestProof()
        
        let originalPayload = TicketQRPayload(
            ticket: ticket,
            proof: proof,
            signature: "test-sig"
        )
        
        guard let urlString = originalPayload.toURLString() else {
            XCTFail("Failed to create URL string")
            return
        }
        
        let decodedPayload = TicketQRPayload.fromURLString(urlString)
        XCTAssertNotNil(decodedPayload)
        XCTAssertEqual(decodedPayload?.ticket.eventName, "Test Concert")
        XCTAssertEqual(decodedPayload?.version, 1)
    }
    
    // MARK: - Transfer Message Tests
    
    func testTransferMessageEncoding() {
        let ticket = createTestTicket()
        let proof = createTestProof()
        
        let message = TicketTransferMessage(
            type: .transferRequest,
            transferRequestID: "request-123",
            ticket: ticket,
            proof: proof,
            fromPeer: testPeerID,
            toPeer: otherPeerID
        )
        
        let data = message.toData()
        XCTAssertNotNil(data)
    }
    
    func testTransferMessageDecoding() {
        let ticket = createTestTicket()
        let proof = createTestProof()
        
        let originalMessage = TicketTransferMessage(
            type: .transferRequest,
            transferRequestID: "request-123",
            ticket: ticket,
            proof: proof,
            fromPeer: testPeerID,
            toPeer: otherPeerID
        )
        
        guard let data = originalMessage.toData() else {
            XCTFail("Failed to encode message")
            return
        }
        
        let decodedMessage = TicketTransferMessage.from(data)
        XCTAssertNotNil(decodedMessage)
        XCTAssertEqual(decodedMessage?.type, .transferRequest)
        XCTAssertEqual(decodedMessage?.transferRequestID, "request-123")
    }
    
    // MARK: - Helper Methods
    
    private func createTestTicket() -> Ticket {
        Ticket(
            eventName: "Test Concert",
            eventDate: Date().addingTimeInterval(86400 * 7),
            venue: "Test Venue",
            section: "A",
            row: "5",
            seat: "12",
            quantity: 1,
            askingPrice: Decimal(50),
            currency: "USD",
            eventType: .concert
        )
    }
    
    private func createTestProof() -> TicketVerificationProof {
        TicketVerificationProof(
            issuerPublicKey: "test-issuer-key",
            issuerSignature: "test-issuer-signature"
        )
    }
}
