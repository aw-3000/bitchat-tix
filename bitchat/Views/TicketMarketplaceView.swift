//
// TicketMarketplaceView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

/// Main view for the decentralized ticket marketplace
struct TicketMarketplaceView: View {
    @StateObject private var marketplace = TicketMarketplaceService.shared
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    @State private var selectedTab: MarketplaceTab = .browse
    @State private var searchText = ""
    @State private var showCreateListing = false
    @State private var selectedEventType: Ticket.EventType?
    
    enum MarketplaceTab {
        case browse
        case myListings
        case transactions
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Marketplace Section", selection: $selectedTab) {
                    Text("Browse").tag(MarketplaceTab.browse)
                    Text("My Listings").tag(MarketplaceTab.myListings)
                    Text("Transactions").tag(MarketplaceTab.transactions)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case .browse:
                    browseListingsView
                case .myListings:
                    myListingsView
                case .transactions:
                    transactionsView
                }
            }
            .navigationTitle("🎟️ Ticket Exchange")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if selectedTab == .browse || selectedTab == .myListings {
                        Button {
                            showCreateListing = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateListing) {
                CreateTicketListingView()
                    .environmentObject(chatViewModel)
            }
        }
    }
    
    // MARK: - Browse View
    
    var browseListingsView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search events, venues...", text: $searchText)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Event type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(title: "All", isSelected: selectedEventType == nil) {
                        selectedEventType = nil
                    }
                    FilterChip(title: "🎵 Concerts", isSelected: selectedEventType == .concert) {
                        selectedEventType = .concert
                    }
                    FilterChip(title: "⚽ Sports", isSelected: selectedEventType == .sports) {
                        selectedEventType = .sports
                    }
                    FilterChip(title: "🎭 Theater", isSelected: selectedEventType == .theater) {
                        selectedEventType = .theater
                    }
                    FilterChip(title: "🎪 Festivals", isSelected: selectedEventType == .festival) {
                        selectedEventType = .festival
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Listings
            if filteredListings.isEmpty {
                emptyStateView
            } else {
                List(filteredListings) { listing in
                    TicketListingRow(listing: listing)
                        .environmentObject(chatViewModel)
                }
            }
        }
    }
    
    var filteredListings: [TicketListing] {
        var result = marketplace.availableListings(excludingPeerID: chatViewModel.myPeerID)
        
        if let eventType = selectedEventType {
            result = result.filter { $0.ticket.eventType == eventType }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.ticket.eventName.localizedCaseInsensitiveContains(searchText) ||
                $0.ticket.venue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result.sorted { $0.ticket.eventDate < $1.ticket.eventDate }
    }
    
    // MARK: - My Listings View
    
    var myListingsView: some View {
        Group {
            if marketplace.myListings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "ticket")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No listings yet")
                        .font(.headline)
                    Text("List tickets you want to sell or tickets you're looking to buy")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Create Listing") {
                        showCreateListing = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(marketplace.myListings) { listing in
                    TicketListingRow(listing: listing, isOwn: true)
                        .environmentObject(chatViewModel)
                }
            }
        }
    }
    
    // MARK: - Transactions View
    
    var transactionsView: some View {
        Group {
            if marketplace.activeTransactions.isEmpty && marketplace.completedTransactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No transactions yet")
                        .font(.headline)
                    Text("When you buy or sell tickets, they'll appear here")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !marketplace.activeTransactions.isEmpty {
                        Section("Active") {
                            ForEach(marketplace.activeTransactions) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                    
                    if !marketplace.completedTransactions.isEmpty {
                        Section("Completed") {
                            ForEach(marketplace.completedTransactions) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                }
            }
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No tickets available")
                .font(.headline)
            Text("Check back later or create a wanted listing")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Ticket Listing Row

struct TicketListingRow: View {
    let listing: TicketListing
    var isOwn: Bool = false
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var showDetails = false
    
    var body: some View {
        Button {
            showDetails = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(listing.ticket.eventName)
                        .font(.headline)
                    Spacer()
                    if listing.listingType == .buy {
                        Text("WANTED")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(listing.ticket.eventDate, style: .date)
                        .font(.subheadline)
                }
                .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "mappin.circle")
                        .font(.caption)
                    Text(listing.ticket.venue)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                .foregroundColor(.gray)
                
                HStack {
                    Text(listing.ticket.displayLocation)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(listing.ticket.priceDisplay)
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                
                if !isOwn {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text(listing.sellerNickname)
                            .font(.caption)
                        Spacer()
                        statusBadge
                    }
                    .foregroundColor(.gray)
                } else {
                    statusBadge
                }
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showDetails) {
            TicketDetailsView(listing: listing, isOwn: isOwn)
                .environmentObject(chatViewModel)
        }
    }
    
    var statusBadge: some View {
        Text(listing.status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    var statusColor: Color {
        switch listing.status {
        case .active: return .green
        case .pending: return .orange
        case .sold: return .gray
        case .cancelled: return .red
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: TicketTransaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transaction.listing.ticket.eventName)
                .font(.headline)
            HStack {
                Text("With: \(transaction.buyerNickname)")
                    .font(.subheadline)
                Spacer()
                Text(transaction.agreedPrice.description)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            Text(transaction.status.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    TicketMarketplaceView()
        .environmentObject(ChatViewModel(
            keychain: KeychainManager(),
            idBridge: NostrIdentityBridge(),
            identityManager: SecureIdentityStateManager(KeychainManager())
        ))
}
