//
// CreateTicketListingView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

/// Form to create a new ticket listing
struct CreateTicketListingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var chatViewModel: ChatViewModel
    @StateObject private var marketplace = TicketMarketplaceService.shared
    
    @State private var listingType: TicketListing.ListingType = .sell
    @State private var eventName = ""
    @State private var venue = ""
    @State private var eventDate = Date().addingTimeInterval(86400 * 7) // Default to 1 week from now
    @State private var eventType: Ticket.EventType = .concert
    @State private var section = ""
    @State private var row = ""
    @State private var seat = ""
    @State private var quantity = 1
    @State private var askingPrice = ""
    @State private var originalPrice = ""
    @State private var description = ""
    @State private var currency = "USD"
    
    private var currentGeohash: String? {
        if case .location(let channel) = LocationChannelManager.shared.selectedChannel {
            return channel.geohash
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Listing Type") {
                    Picker("I want to", selection: $listingType) {
                        Text("Sell Tickets").tag(TicketListing.ListingType.sell)
                        Text("Buy Tickets").tag(TicketListing.ListingType.buy)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Event Information") {
                    TextField("Event Name", text: $eventName)
                    TextField("Venue", text: $venue)
                    DatePicker("Event Date", selection: $eventDate, in: Date()...)
                    
                    Picker("Event Type", selection: $eventType) {
                        Text("🎵 Concert").tag(Ticket.EventType.concert)
                        Text("⚽ Sports").tag(Ticket.EventType.sports)
                        Text("🎭 Theater").tag(Ticket.EventType.theater)
                        Text("🎪 Festival").tag(Ticket.EventType.festival)
                        Text("📊 Conference").tag(Ticket.EventType.conference)
                        Text("Other").tag(Ticket.EventType.other)
                    }
                }
                
                Section("Ticket Details") {
                    TextField("Section (optional)", text: $section)
                    TextField("Row (optional)", text: $row)
                    TextField("Seat (optional)", text: $seat)
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...10)
                }
                
                Section("Pricing") {
                    HStack {
                        TextField("Asking Price", text: $askingPrice)
                            .keyboardType(.decimalPad)
                        Picker("", selection: $currency) {
                            Text("USD").tag("USD")
                            Text("EUR").tag("EUR")
                            Text("GBP").tag("GBP")
                            Text("CAD").tag("CAD")
                        }
                        .frame(width: 80)
                    }
                    
                    if listingType == .sell {
                        TextField("Original Price (optional)", text: $originalPrice)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Additional Details") {
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                .headerProminence(.increased)
            }
            .navigationTitle("Create Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        createListing()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !eventName.isEmpty &&
        !venue.isEmpty &&
        !askingPrice.isEmpty &&
        Decimal(string: askingPrice) != nil
    }
    
    private func createListing() {
        guard let price = Decimal(string: askingPrice) else { return }
        let origPrice = Decimal(string: originalPrice)
        
        let ticket = Ticket(
            eventName: eventName,
            eventDate: eventDate,
            venue: venue,
            section: section.isEmpty ? nil : section,
            row: row.isEmpty ? nil : row,
            seat: seat.isEmpty ? nil : seat,
            quantity: quantity,
            originalPrice: origPrice,
            askingPrice: price,
            currency: currency,
            eventType: eventType,
            description: description.isEmpty ? nil : description,
            geohash: currentGeohash
        )
        
        let listing = marketplace.createListing(
            ticket: ticket,
            listingType: listingType,
            myPeerID: chatViewModel.meshService.myPeerID,
            myNickname: chatViewModel.nickname
        )
        
        // Broadcast to network
        broadcastListing(listing)
        
        // Save state
        marketplace.saveState()
        
        dismiss()
    }
    
    private func broadcastListing(_ listing: TicketListing) {
        let ticketMessage = TicketMessage(
            type: .listingBroadcast,
            listing: listing
        )
        
        if let data = ticketMessage.toData(),
           let jsonString = String(data: data, encoding: .utf8) {
            // Send as broadcast message to current channel
            chatViewModel.sendMessage("🎟️ TICKET: \(jsonString)")
        }
    }
}

#Preview {
    CreateTicketListingView()
        .environmentObject(ChatViewModel(
            keychain: KeychainManager(),
            idBridge: NostrIdentityBridge(),
            identityManager: SecureIdentityStateManager(KeychainManager())
        ))
}
