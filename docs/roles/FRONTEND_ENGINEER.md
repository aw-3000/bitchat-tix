# Frontend Engineer - Decentralized Ticket Exchange Project

## Role Overview
As Frontend Engineer, you are responsible for building the SwiftUI user interface for the ticket marketplace, creating an intuitive and delightful user experience that enables fans to buy and sell tickets directly without platform fees.

## Primary Responsibilities
1. **UI Components** - Build SwiftUI views for marketplace, listing details, and creation forms
2. **User Experience** - Create intuitive flows for browsing, searching, and transacting
3. **Integration** - Connect UI to TicketMarketplaceService and ChatViewModel
4. **Accessibility** - Ensure UI is accessible and follows iOS/macOS guidelines
5. **Performance** - Keep UI responsive with large datasets

## Key Technical Context

### Existing UI Patterns to Follow
- **SwiftUI Architecture**: All views use SwiftUI (no UIKit)
- **MVVM Pattern**: Views bind to ViewModels via `@EnvironmentObject` and `@StateObject`
- **Color Scheme**: Dark/light mode support with custom color scheme
- **Typography**: Custom `.bitchatSystem` font modifier
- **Navigation**: Sheet presentations for modals, NavigationView for hierarchies

### Existing Components to Reference
- `ContentView.swift`: Main app structure, header design patterns
- `MeshPeerList.swift`: List view patterns
- `LocationChannelsSheet.swift`: Sheet presentation patterns
- `VerificationViews.swift`: Form input patterns

## Tasks & Deliverables

### Phase 1: Main Marketplace View (Days 1-3)

#### Task 1.1: TicketMarketplaceView
Create `bitchat/Views/TicketMarketplaceView.swift`

**Requirements:**
```swift
struct TicketMarketplaceView: View {
    @StateObject private var marketplace = TicketMarketplaceService.shared
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    // Three-tab interface:
    // 1. Browse - View all available tickets
    // 2. My Listings - User's active listings
    // 3. Transactions - Active and completed transactions
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab picker
                Picker("Section", selection: $selectedTab) {
                    Text("Browse").tag(Tab.browse)
                    Text("My Listings").tag(Tab.myListings)
                    Text("Transactions").tag(Tab.transactions)
                }
                .pickerStyle(.segmented)
                
                // Content based on tab
                // ... implement each tab view
            }
            .navigationTitle("🎟️ Ticket Exchange")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showCreateListing = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
}
```

**Browse Tab Features:**
- Search bar for event name/venue
- Event type filter chips (Concerts, Sports, Theater, etc.)
- List of available tickets with:
  - Event name and venue
  - Date and time
  - Price and seat info
  - Seller nickname
  - Connection status icon (📻/📡)
- Empty state when no tickets available
- Pull to refresh

**My Listings Tab Features:**
- List of user's active listings
- Status badges (Active, Pending, Sold, Cancelled)
- Tap to view details or cancel
- Empty state with CTA to create listing

**Transactions Tab Features:**
- Separate sections for Active and Completed
- Transaction status indicators
- Buyer/seller info
- Agreed price and meetup details

**Deliverables:**
- [ ] `TicketMarketplaceView.swift` with all three tabs
- [ ] FilterChip component for event types
- [ ] TicketListingRow component
- [ ] TransactionRow component
- [ ] Empty state views
- [ ] Preview with sample data

#### Task 1.2: Integration with ContentView
Modify `bitchat/Views/ContentView.swift`

**Requirements:**
- Add 🎟️ button to header (next to unread messages icon)
- Add state variable: `@State private var showTicketMarketplace = false`
- Add sheet presentation:
```swift
.sheet(isPresented: $showTicketMarketplace) {
    TicketMarketplaceView()
        .environmentObject(viewModel)
}
```

**Visual Placement:**
- Place button between unread messages icon and notes icon
- Use same font size and styling as other header buttons
- Add accessibility label: "Ticket Marketplace"

**Deliverables:**
- [ ] ContentView.swift updated
- [ ] Header button integrated
- [ ] Sheet presentation working
- [ ] No breaking changes to existing UI

### Phase 2: Ticket Details View (Days 4-5)

#### Task 2.1: TicketDetailsView
Create `bitchat/Views/TicketDetailsView.swift`

**Requirements:**
```swift
struct TicketDetailsView: View {
    let listing: TicketListing
    var isOwn: Bool = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Event header with name, date, venue
                    // Ticket details (section, row, seat, quantity)
                    // Pricing info (original price, asking price)
                    // Description (if provided)
                    // Seller info (nickname, connection status)
                    // Action buttons
                }
            }
            .navigationTitle("Ticket Details")
        }
    }
}
```

**UI Components:**
- **Event Header**: Large title, date/time, venue with icons
- **Ticket Details Section**: Structured list of seat info, quantity
- **Pricing Section**: Original price (if provided) with asking price highlighted
- **Description Section**: Text block with seller's notes
- **Seller Section**: Avatar, nickname, connection status
- **Action Buttons**:
  - For buyers: "Contact Seller" (primary), "I'm Interested" (secondary)
  - For sellers: "Cancel Listing" (destructive)

**Interaction Flow:**
1. **Contact Seller**: Opens private chat with seller
2. **I'm Interested**: Creates transaction and opens chat with pre-filled message
3. **Cancel Listing**: Confirms, then marks listing as cancelled

**Deliverables:**
- [ ] `TicketDetailsView.swift` fully implemented
- [ ] DetailRow helper component
- [ ] Action button logic
- [ ] Preview with sample listing

### Phase 3: Create Listing Form (Days 6-7)

#### Task 3.1: CreateTicketListingView
Create `bitchat/Views/CreateTicketListingView.swift`

**Requirements:**
```swift
struct CreateTicketListingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var chatViewModel: ChatViewModel
    @StateObject private var marketplace = TicketMarketplaceService.shared
    
    // Form state variables
    @State private var listingType: TicketListing.ListingType = .sell
    @State private var eventName = ""
    @State private var venue = ""
    @State private var eventDate = Date()
    // ... more fields
    
    var body: some View {
        NavigationView {
            Form {
                // Sections for:
                // - Listing type (Sell/Buy toggle)
                // - Event information
                // - Ticket details
                // - Pricing
                // - Description
            }
            .navigationTitle("Create Listing")
        }
    }
}
```

**Form Sections:**

1. **Listing Type**
   - Segmented picker: "Sell Tickets" / "Buy Tickets"
   - Changes UI labels based on selection

2. **Event Information**
   - Event name (TextField, required)
   - Venue (TextField, required)
   - Event date (DatePicker, must be future)
   - Event type (Picker: Concert, Sports, Theater, Festival, Conference, Other)

3. **Ticket Details**
   - Section (TextField, optional)
   - Row (TextField, optional)
   - Seat (TextField, optional)
   - Quantity (Stepper, 1-10)

4. **Pricing**
   - Asking price (TextField with decimal keyboard, required)
   - Currency (Picker: USD, EUR, GBP, CAD)
   - Original price (TextField, optional, for sellers only)

5. **Description**
   - TextEditor for additional notes
   - 100-500 character limit

**Validation:**
- Event name and venue required
- Asking price must be valid Decimal
- Event date must be in future
- Show error states inline

**Deliverables:**
- [ ] `CreateTicketListingView.swift` with full form
- [ ] Validation logic
- [ ] Create listing action
- [ ] Broadcast listing to network
- [ ] Preview with mock data

### Phase 4: Polish & UX Improvements (Days 8-9)

#### Task 4.1: Search & Filtering
- Implement search bar with debouncing
- Add event type filter chips
- Show active filter count
- Smooth animations for filter changes

#### Task 4.2: Loading States
- Skeleton screens while loading
- Pull-to-refresh on lists
- Loading spinners for actions
- Optimistic UI updates

#### Task 4.3: Error Handling
- Toast notifications for errors
- Alert dialogs for destructive actions
- Retry mechanisms for failed operations
- Clear error messages

#### Task 4.4: Accessibility
- VoiceOver labels for all buttons and images
- Dynamic type support
- High contrast mode support
- Keyboard navigation (macOS)

**Deliverables:**
- [ ] All loading states implemented
- [ ] Error handling throughout
- [ ] Accessibility audit complete
- [ ] VoiceOver testing done

### Phase 5: Testing & Documentation (Day 10)

#### Task 5.1: SwiftUI Previews
- Add previews for all views
- Include different states (empty, populated, error)
- Dark/light mode previews
- Different device sizes

#### Task 5.2: UI Testing
- Test happy paths for all flows
- Test error states
- Test edge cases (long text, many listings)
- Cross-device testing (iPhone, iPad, Mac)

#### Task 5.3: Documentation
- Document all custom components
- Create UI component guide
- Document accessibility features
- Create design system documentation

**Deliverables:**
- [ ] SwiftUI previews for all views
- [ ] UI test coverage for critical flows
- [ ] Component documentation
- [ ] Screenshots for documentation

## Design Guidelines

### Color Scheme
```swift
// Match existing app colors
private var textColor: Color {
    colorScheme == .dark ? Color.green : Color(red: 0, green: 0.5, blue: 0)
}

private var backgroundColor: Color {
    colorScheme == .dark ? Color.black : Color.white
}

private var secondaryTextColor: Color {
    textColor.opacity(0.8)
}
```

### Typography
```swift
// Use existing custom fonts
.font(.bitchatSystem(size: 18, weight: .medium, design: .monospaced))
.font(.bitchatSystem(size: 14, design: .monospaced))
```

### Icons
- Use SF Symbols for consistency
- Event types: 🎵 (concert), ⚽ (sports), 🎭 (theater), 🎪 (festival)
- Status icons: 📻 (Bluetooth), 📡 (Nostr), 🌐 (internet)

### Spacing
- Section padding: 16-20pt
- Element spacing: 8-12pt
- Card corners: 12pt radius
- Follow iOS Human Interface Guidelines

## UI Components Reference

### Existing Patterns to Follow

1. **Header Button Style** (from ContentView):
```swift
Button(action: { showTicketMarketplace = true }) {
    Image(systemName: "ticket.fill")
        .font(.bitchatSystem(size: 12))
        .foregroundColor(textColor)
}
.buttonStyle(.plain)
```

2. **List Row Style** (from MeshPeerList):
```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Title").font(.headline)
    Text("Subtitle").font(.subheadline).foregroundColor(.gray)
}
.padding(.vertical, 4)
```

3. **Form Section Style**:
```swift
Section("Section Title") {
    TextField("Placeholder", text: $value)
}
.headerProminence(.increased)
```

## Performance Considerations

### List Optimization
- Use `LazyVStack` for large lists
- Implement pagination if needed
- Cache computed properties
- Avoid expensive operations in body

### State Management
- Use `@Published` properties efficiently
- Avoid unnecessary re-renders
- Use `@State` for local UI state
- Use `@StateObject` for owned objects

## Common Pitfalls to Avoid

1. **Retain Cycles**: Use `[weak self]` in closures
2. **Main Thread**: Keep UI updates on main thread
3. **Force Unwrapping**: Use optional binding
4. **Large Images**: Optimize image sizes
5. **Complex Body**: Break into smaller components

## Testing Checklist

### Functional Testing
- [ ] Browse tickets works
- [ ] Search filters correctly
- [ ] Create listing succeeds
- [ ] View details shows correct info
- [ ] Contact seller opens chat
- [ ] Cancel listing works
- [ ] Transaction flow complete

### Visual Testing
- [ ] Dark mode looks good
- [ ] Light mode looks good
- [ ] iPad layout works
- [ ] Mac layout works
- [ ] Dynamic type scales properly
- [ ] Long text doesn't overflow

### Accessibility Testing
- [ ] VoiceOver navigation works
- [ ] All buttons have labels
- [ ] Color contrast meets WCAG
- [ ] Keyboard navigation works (Mac)

## Resources & References
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- Existing views: `ContentView.swift`, `MeshPeerList.swift`, `LocationChannelsSheet.swift`
- [SF Symbols](https://developer.apple.com/sf-symbols/)

## Success Criteria
- [ ] All views implemented and functional
- [ ] UI matches design guidelines
- [ ] No performance issues with 1000+ listings
- [ ] Accessibility requirements met
- [ ] All tests pass
- [ ] Code review approved

---

**Timeline**: 10 working days
**Dependencies**: Backend models and service (can start UI mockups independently)
**Parallel Work**: Backend Engineer builds data layer while you build UI with mock data
