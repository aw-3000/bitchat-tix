//
// TicketDetailsView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

/// Detailed view of a ticket listing with purchase/contact options
struct TicketDetailsView: View {
    let listing: TicketListing
    var isOwn: Bool = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var chatViewModel: ChatViewModel
    @StateObject private var marketplace = TicketMarketplaceService.shared
    @State private var showContactSeller = false
    @State private var offerPrice: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(listing.ticket.eventName)
                            .font(.largeTitle)
                            .bold()
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text(listing.ticket.eventDate, style: .date)
                            Text("at")
                            Text(listing.ticket.eventDate, style: .time)
                        }
                        .font(.headline)
                        .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                            Text(listing.ticket.venue)
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Ticket Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Section", value: listing.ticket.section ?? "N/A")
                        if let row = listing.ticket.row {
                            DetailRow(label: "Row", value: row)
                        }
                        if let seat = listing.ticket.seat {
                            DetailRow(label: "Seat", value: seat)
                        }
                        DetailRow(label: "Quantity", value: "\(listing.ticket.quantity)")
                        
                        Divider()
                        
                        if let originalPrice = listing.ticket.originalPrice {
                            DetailRow(label: "Original Price", value: "\(listing.ticket.currency) \(originalPrice)")
                        }
                        DetailRow(
                            label: "Asking Price",
                            value: listing.ticket.priceDisplay,
                            valueColor: .accentColor,
                            bold: true
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Description
                    if let description = listing.ticket.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details")
                                .font(.headline)
                            Text(description)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Seller Info
                    if !isOwn {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Seller")
                                .font(.headline)
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                Text(listing.sellerNickname)
                                    .font(.body)
                                Spacer()
                                // Connection status
                                if let peer = chatViewModel.peers.first(where: { $0.peerID == listing.sellerPeerID }) {
                                    Text(peer.statusIcon)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Action Buttons
                    if !isOwn && listing.status == .active {
                        VStack(spacing: 12) {
                            Button {
                                contactSeller()
                            } label: {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Contact Seller")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            Button {
                                expressInterest()
                            } label: {
                                HStack {
                                    Image(systemName: "hand.raised.fill")
                                    Text(listing.listingType == .sell ? "I'm Interested" : "I Have This Ticket")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if isOwn {
                        VStack(spacing: 12) {
                            Button(role: .destructive) {
                                cancelListing()
                            } label: {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Cancel Listing")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Ticket Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func contactSeller() {
        // Open private chat with seller
        chatViewModel.startPrivateChat(with: listing.sellerPeerID)
        dismiss()
    }
    
    private func expressInterest() {
        let transaction = marketplace.expressInterest(
            in: listing,
            buyerPeerID: chatViewModel.meshService.myPeerID,
            buyerNickname: chatViewModel.nickname
        )
        
        // Send message to seller
        let message = "Hi! I'm interested in your ticket for \(listing.ticket.eventName). Let's discuss!"
        chatViewModel.startPrivateChat(with: listing.sellerPeerID)
        chatViewModel.sendMessage(message)
        
        dismiss()
    }
    
    private func cancelListing() {
        marketplace.updateListingStatus(listing.id, status: .cancelled)
        dismiss()
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var bold: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .bold(bold)
        }
    }
}
