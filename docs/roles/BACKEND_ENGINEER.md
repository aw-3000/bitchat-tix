# Backend Engineer - Decentralized Ticket Exchange Project

## Role Overview
As Backend Engineer, you are responsible for implementing the data models, service layer, and business logic for the decentralized ticket marketplace. Your work forms the foundation that Frontend and other teams will build upon.

## Primary Responsibilities
1. **Data Models** - Design and implement Ticket, TicketListing, TicketTransaction models
2. **Service Layer** - Build TicketMarketplaceService for managing marketplace state
3. **P2P Protocol** - Implement TicketMessage for broadcasting over the network
4. **Business Logic** - Search, filtering, matching logic for ticket discovery
5. **Data Persistence** - Lightweight storage for user's listings and transaction history

## Key Technical Context

### Existing Patterns to Follow
- **Models**: Use `struct` with `Codable` for serialization (see `BitchatMessage.swift`, `BitchatPeer.swift`)
- **Services**: Use `@MainActor` classes with `@Published` properties (see `LocationChannelManager.swift`)
- **State Management**: Use `ObservableObject` protocol for reactive state
- **Persistence**: Use `UserDefaults` for lightweight storage (matches existing pattern)

### Critical Dependencies
- `PeerID`: Existing type for peer identification
- `ChatViewModel`: Provides access to peers, messaging, nickname
- `LocationChannelManager`: Provides geohash for location-based discovery

## Tasks & Deliverables

### Phase 1: Data Models (Days 1-2)

#### Task 1.1: Ticket Model
Create `bitchat/Models/Ticket.swift`

```swift
struct Ticket: Codable, Equatable, Identifiable {
    let id: String  // UUID
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
    let eventType: EventType
    let description: String?
    let geohash: String?  // For location-based discovery
    let verificationData: String?  // QR code, barcode, etc.
    
    enum EventType: String, Codable {
        case concert, sports, theater, festival, conference, other
    }
}
```

**Requirements:**
- All properties must be `Codable` for JSON serialization
- Include computed properties for display (e.g., `displayLocation`, `priceDisplay`)
- Validate that `eventDate` is in the future
- Support multiple currencies (USD, EUR, GBP, CAD)

**Tests to Write:**
- Test ticket creation with all fields
- Test computed properties
- Test JSON encoding/decoding
- Test validation logic

#### Task 1.2: TicketListing Model
Create `bitchat/Models/TicketListing.swift` (combined in Ticket.swift)

```swift
struct TicketListing: Codable, Equatable, Identifiable {
    let id: String
    let ticket: Ticket
    let listingType: ListingType  // sell or buy (wanted)
    let sellerPeerID: PeerID
    let sellerNickname: String
    let timestamp: Date
    let status: ListingStatus
    
    enum ListingType: String, Codable {
        case sell, buy
    }
    
    enum ListingStatus: String, Codable {
        case active, pending, sold, cancelled
    }
}
```

**Requirements:**
- Support both sell and buy (wanted) listings
- Track listing status throughout lifecycle
- Store seller identity for contact
- Timestamp for sorting and expiry

**Tests to Write:**
- Test listing creation
- Test status transitions
- Test equality and identification

#### Task 1.3: TicketTransaction Model
Create in same file as TicketListing

```swift
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
        case proposed, negotiating, agreed, completed, cancelled
    }
}
```

**Requirements:**
- Track transaction lifecycle from proposal to completion
- Store meetup coordination details
- Link to original listing
- Track both buyer and seller identities

**Deliverables:**
- [ ] `Ticket.swift` with all models and tests
- [ ] Documentation comments for all models
- [ ] Unit tests with 90%+ coverage

### Phase 2: P2P Protocol (Days 3-4)

#### Task 2.1: TicketMessage Protocol
Create `bitchat/Models/TicketMessage.swift`

```swift
struct TicketMessage: Codable {
    let type: TicketMessageType
    let listingID: String?
    let listing: TicketListing?
    let transaction: TicketTransaction?
    let action: TicketAction?
    
    enum TicketMessageType: String, Codable {
        case listingBroadcast
        case listingUpdate
        case buyerInterest
        case priceOffer
        case transactionProposal
        case transactionAccept
        case transactionComplete
        case transactionCancel
    }
    
    func toData() -> Data?
    static func from(_ data: Data) -> TicketMessage?
}
```

**Requirements:**
- Encode/decode to JSON for transmission
- Support all message types in transaction lifecycle
- Include helper methods: `toData()` and `from(Data)`
- Keep message size small for network efficiency

**Tests to Write:**
- Test encoding/decoding for each message type
- Test round-trip serialization
- Test handling of missing optional fields

**Deliverables:**
- [ ] `TicketMessage.swift` with encoding/decoding
- [ ] Unit tests for all message types
- [ ] Documentation on message flow

### Phase 3: Service Layer (Days 5-8)

#### Task 3.1: TicketMarketplaceService
Create `bitchat/Services/TicketMarketplaceService.swift`

```swift
@MainActor
final class TicketMarketplaceService: ObservableObject {
    static let shared = TicketMarketplaceService()
    
    @Published var listings: [TicketListing] = []
    @Published var myListings: [TicketListing] = []
    @Published var activeTransactions: [TicketTransaction] = []
    @Published var completedTransactions: [TicketTransaction] = []
    
    // Core methods to implement
    func createListing(...) -> TicketListing
    func updateListingStatus(...)
    func removeListing(...)
    func expressInterest(...) -> TicketTransaction
    func listings(forEvent:) -> [TicketListing]
    func listings(nearGeohash:) -> [TicketListing]
    func saveState()
    func loadState()
}
```

**Implementation Details:**

1. **Listing Management**
   - Filter out expired events (past `eventDate`)
   - Deduplicate listings by ID
   - Sort by date and relevance
   - Track user's own listings separately

2. **Search & Filtering**
   - Case-insensitive search on event name and venue
   - Geohash prefix matching for location
   - Event type filtering
   - Exclude user's own listings from browse

3. **Persistence**
   - Use `UserDefaults` for storage
   - JSON encode listings and transactions
   - Load on init, save after mutations

**Tests to Write:**
- Test listing CRUD operations
- Test transaction lifecycle
- Test all search/filter methods
- Test persistence (save/load cycle)
- Test concurrent access safety

**Deliverables:**
- [ ] `TicketMarketplaceService.swift` fully implemented
- [ ] Comprehensive unit tests (80%+ coverage)
- [ ] Performance test with 1000+ listings
- [ ] Documentation

### Phase 4: Integration (Days 9-10)

Work with Frontend team on:
- ChatViewModel integration
- LocationChannelManager integration
- End-to-end message flow testing

**Deliverables:**
- [ ] Integration tests
- [ ] E2E test scenarios
- [ ] Integration documentation

## Code Quality Standards

### Swift Best Practices
- Use `struct` for value types
- Use `let` over `var` where possible
- Use guard statements for early returns
- Add documentation comments for public APIs
- No force unwrapping (`!`)

### Testing Standards
- Unit test coverage > 80%
- Test happy path and edge cases
- Use descriptive test names
- Use XCTest framework

## Resources
- Existing models: `BitchatMessage.swift`, `BitchatPeer.swift`
- Existing services: `LocationChannelManager.swift`
- [Swift Codable Guide](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types)

## Success Criteria
- [ ] All models implemented with tests
- [ ] Service layer fully functional
- [ ] Integration tests pass
- [ ] Performance benchmarks met
- [ ] Code review approved

---

**Timeline**: 10 working days
**Dependencies**: None (can start immediately)
**Parallel Work**: Frontend can start UI mockups while you build models
