//
// TicketTransferService.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import Combine

/// Service for managing peer-to-peer ticket transfers (AirDrop-style)
@MainActor
final class TicketTransferService: ObservableObject {
    static let shared = TicketTransferService()
    
    /// Active transfer requests
    @Published var activeTransfers: [TicketTransferRequest] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // Injected services
    private var walletService: TicketWalletService { TicketWalletService.shared }
    private var verificationService: TicketVerificationService { TicketVerificationService.shared }
    
    // MARK: - Initiating Transfers
    
    /// Initiate a ticket transfer to another peer
    func initiateTransfer(
        ticket: Ticket,
        proof: TicketVerificationProof,
        toPeer: PeerID,
        toNickname: String,
        fromPeer: PeerID,
        fromNickname: String,
        method: TicketTransferRequest.TransferMethod
    ) throws -> TicketTransferRequest {
        // Verify we own this ticket
        guard walletService.activeTickets.contains(where: { $0.ticket.id == ticket.id }) else {
            throw TransferError.ticketNotOwned
        }
        
        // Verify ticket is not already being transferred
        guard !activeTransfers.contains(where: { $0.ticket.id == ticket.id }) else {
            throw TransferError.transferAlreadyPending
        }
        
        // Create transfer request
        let request = TicketTransferRequest(
            ticket: ticket,
            proof: proof,
            fromPeer: fromPeer,
            fromNickname: fromNickname,
            toPeer: toPeer,
            toNickname: toNickname,
            method: method
        )
        
        // Add to active transfers
        activeTransfers.append(request)
        
        // Mark ticket as transfer-pending in wallet
        walletService.addPendingOutgoingTransfer(request)
        
        // TODO: Send transfer request message via transport
        // sendTransferRequestMessage(request)
        
        return request
    }
    
    // MARK: - Receiving Transfers
    
    /// Handle incoming transfer request
    func receiveTransferRequest(_ request: TicketTransferRequest) {
        // Verify the request
        guard verificationService.verifyTransferRequest(request) else {
            // Invalid request, ignore
            return
        }
        
        // Add to pending incoming transfers
        walletService.addPendingIncomingTransfer(request)
        activeTransfers.append(request)
        
        // Notify user of incoming transfer
        // TODO: Show notification/alert
    }
    
    /// Accept an incoming transfer request
    func acceptTransfer(requestID: String) throws {
        guard let index = activeTransfers.firstIndex(where: { $0.id == requestID }) else {
            throw TransferError.transferNotFound
        }
        
        var request = activeTransfers[index]
        guard request.status == .pending else {
            throw TransferError.invalidTransferState
        }
        
        // Update status
        request.status = .accepted
        activeTransfers[index] = request
        
        // TODO: Send accept message to sender
        // sendTransferAcceptMessage(request)
        
        // Complete the transfer
        try completeIncomingTransfer(requestID: requestID)
    }
    
    /// Reject an incoming transfer request
    func rejectTransfer(requestID: String) throws {
        guard let index = activeTransfers.firstIndex(where: { $0.id == requestID }) else {
            throw TransferError.transferNotFound
        }
        
        var request = activeTransfers[index]
        request.status = .rejected
        activeTransfers[index] = request
        
        // Remove from pending
        walletService.removePendingTransfer(requestID)
        activeTransfers.remove(at: index)
        
        // TODO: Send reject message to sender
        // sendTransferRejectMessage(request)
    }
    
    // MARK: - Completing Transfers
    
    /// Complete an incoming transfer (receiver side)
    private func completeIncomingTransfer(requestID: String) throws {
        guard let index = activeTransfers.firstIndex(where: { $0.id == requestID }) else {
            throw TransferError.transferNotFound
        }
        
        var request = activeTransfers[index]
        
        // Add signature to chain of custody
        // TODO: Get current peer's public key and sign the transfer
        let updatedProof = request.proof  // Would add signature here
        
        // Add ticket to wallet
        let ownedTicket = walletService.addTicket(
            request.ticket,
            source: .received(from: request.fromPeer),
            proof: updatedProof
        )
        
        // Update request status
        request.status = .completed
        request.completedAt = Date()
        activeTransfers[index] = request
        
        // Remove from pending
        walletService.removePendingTransfer(requestID)
        
        // TODO: Send completion acknowledgment to sender
        // sendTransferCompleteMessage(request)
        
        // Remove from active transfers after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.activeTransfers.removeAll { $0.id == requestID }
        }
    }
    
    /// Handle transfer completion acknowledgment (sender side)
    func handleTransferAcknowledgment(requestID: String) {
        guard let index = activeTransfers.firstIndex(where: { $0.id == requestID }) else {
            return
        }
        
        var request = activeTransfers[index]
        request.status = .completed
        request.completedAt = Date()
        activeTransfers[index] = request
        
        // Mark ticket as transferred in wallet
        walletService.markTicketTransferred(request.ticket.id, toPeer: request.toPeer)
        
        // Remove from pending
        walletService.removePendingTransfer(requestID)
        
        // Remove from active transfers
        activeTransfers.remove(at: index)
    }
    
    // MARK: - Cancel Transfer
    
    /// Cancel an outgoing transfer (sender side)
    func cancelTransfer(requestID: String) throws {
        guard let index = activeTransfers.firstIndex(where: { $0.id == requestID }) else {
            throw TransferError.transferNotFound
        }
        
        var request = activeTransfers[index]
        guard request.status == .pending else {
            throw TransferError.cannotCancelAfterAccepted
        }
        
        request.status = .cancelled
        activeTransfers[index] = request
        
        // Remove from pending
        walletService.removePendingTransfer(requestID)
        
        // Restore ticket to active in wallet
        if let ticketIndex = walletService.activeTickets.firstIndex(where: { $0.ticket.id == request.ticket.id }) {
            walletService.activeTickets[ticketIndex].status = .active
        }
        
        // Remove from active transfers
        activeTransfers.remove(at: index)
        
        // TODO: Send cancel message to receiver
        // sendTransferCancelMessage(request)
    }
    
    // MARK: - Error Handling
    
    enum TransferError: LocalizedError {
        case ticketNotOwned
        case transferAlreadyPending
        case transferNotFound
        case invalidTransferState
        case cannotCancelAfterAccepted
        case verificationFailed
        
        var errorDescription: String? {
            switch self {
            case .ticketNotOwned:
                return "You don't own this ticket"
            case .transferAlreadyPending:
                return "This ticket is already being transferred"
            case .transferNotFound:
                return "Transfer request not found"
            case .invalidTransferState:
                return "Transfer is in an invalid state"
            case .cannotCancelAfterAccepted:
                return "Cannot cancel transfer after it has been accepted"
            case .verificationFailed:
                return "Transfer verification failed"
            }
        }
    }
    
    private init() {}
}
