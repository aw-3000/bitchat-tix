# Tech Lead - Decentralized Ticket Exchange Project

## Role Overview
As Tech Lead, you are responsible for the overall technical architecture, coordinating between teams, and ensuring the decentralized ticket exchange integrates seamlessly with BitChat's existing P2P infrastructure.

## Primary Responsibilities
1. **Architecture Oversight** - Ensure the ticket marketplace leverages existing P2P infrastructure without breaking core protocols
2. **Team Coordination** - Sync between Backend, Frontend, Security, and QA teams
3. **Technical Decisions** - Make final calls on technical trade-offs and implementation approaches
4. **Code Review** - Review critical PRs from all team members
5. **Risk Management** - Identify and mitigate technical risks early

## Key Technical Context

### Existing Infrastructure to Leverage
- **Bluetooth LE Mesh Network**: Multi-hop P2P communication (max 7 hops)
- **Nostr Protocol**: Internet-based messaging with 290+ relay network
- **Noise Protocol (XX pattern)**: End-to-end encryption with forward secrecy
- **Geohash Channels**: Location-based discovery system
- **SwiftUI Architecture**: Native iOS/macOS app with MVVM pattern

### Project Goals
- Zero platform fees (vs. 20-35% on Ticketmaster/StubHub)
- Decentralized P2P ticket exchange
- Privacy-first (no accounts, no tracking)
- Local (Bluetooth) and global (Nostr) discovery

## Tasks & Deliverables

### Phase 1: Architecture & Design (Week 1)
- [ ] Review existing codebase architecture (BLEService, NostrTransport, ChatViewModel)
- [ ] Design data models (Ticket, TicketListing, TicketTransaction)
- [ ] Define service layer interfaces (TicketMarketplaceService)
- [ ] Design P2P protocol for listing broadcasts (TicketMessage)
- [ ] Document integration points with existing services
- [ ] Create technical specification document

**Deliverables:**
- Architecture decision records (ADRs)
- Technical specification document
- Integration diagram showing all components

### Phase 2: Team Coordination (Ongoing)
- [ ] Daily standups with all teams (15 mins)
- [ ] Weekly architecture review sessions
- [ ] Coordinate dependencies between teams
- [ ] Unblock team members on technical challenges
- [ ] Review and approve all design documents

**Deliverables:**
- Meeting notes and action items
- Updated project timeline
- Risk register

### Phase 3: Code Review & Quality (Ongoing)
- [ ] Review all PRs for architectural consistency
- [ ] Ensure code follows existing patterns (BitchatDelegate, @Published properties, etc.)
- [ ] Verify proper thread safety (@MainActor usage)
- [ ] Check integration with ChatViewModel and LocationChannelManager
- [ ] Validate error handling and edge cases

**Deliverables:**
- Code review feedback
- Architecture compliance checklist

### Phase 4: Integration & Testing (Week 3-4)
- [ ] Oversee integration of all components
- [ ] Coordinate E2E testing scenarios
- [ ] Review security audit findings
- [ ] Validate performance benchmarks
- [ ] Sign off on production readiness

**Deliverables:**
- Integration test results
- Performance analysis report
- Production readiness checklist

## Key Technical Decisions to Make

### Data Persistence
- **Decision Needed**: UserDefaults vs. Core Data vs. SQLite
- **Recommendation**: UserDefaults for MVP (lightweight, matches existing patterns)
- **Rationale**: Tickets are ephemeral, no need for complex DB

### Message Broadcasting
- **Decision Needed**: How to broadcast listings efficiently
- **Options**: 
  1. Embed JSON in regular chat messages (simple, works immediately)
  2. New message type in BitchatPacket (cleaner, requires protocol change)
- **Recommendation**: Option 1 for MVP, migrate to Option 2 later
- **Rationale**: Faster time to market, no breaking changes

### Listing Expiry
- **Decision Needed**: When to purge old listings
- **Recommendation**: Filter out past events on-the-fly, background cleanup daily
- **Rationale**: Keeps UI responsive, minimal storage impact

## Integration Points to Validate

### ChatViewModel Integration
```swift
// Must verify these work correctly:
- chatViewModel.meshService.myPeerID (peer identity)
- chatViewModel.nickname (user nickname)
- chatViewModel.startPrivateChat(with:) (buyer-seller communication)
- chatViewModel.sendMessage(_:) (broadcast listings)
```

### LocationChannelManager Integration
```swift
// Must verify these work correctly:
- LocationChannelManager.shared.selectedChannel (current channel)
- Extract geohash from .location(GeohashChannel)
- Listings filtered by geohash prefix matching
```

### Transport Layer
```swift
// No changes needed, just verify:
- BLEService handles Bluetooth mesh (existing)
- NostrTransport handles internet relay (existing)
- MessageRouter handles transport selection (existing)
```

## Risk Management

### Technical Risks
1. **Performance**: Large number of listings may impact UI performance
   - **Mitigation**: Implement pagination, lazy loading
   
2. **Discovery**: Listings may not propagate efficiently
   - **Mitigation**: Use existing gossip protocol, test with multiple peers
   
3. **Storage**: Listings accumulate over time
   - **Mitigation**: Implement automatic cleanup of past events

4. **Concurrency**: Race conditions in marketplace state
   - **Mitigation**: Use @MainActor for all UI state, proper locking for shared state

### Security Risks
1. **Spam**: Users could flood network with fake listings
   - **Mitigation**: Rate limiting, block functionality already exists
   
2. **Scams**: Users could post fake tickets
   - **Mitigation**: Buyer verification process, education in UI

## Success Criteria
- [ ] All tests pass (unit, integration, E2E)
- [ ] No security vulnerabilities (CodeQL scan clean)
- [ ] Performance benchmarks met (UI stays responsive with 1000+ listings)
- [ ] Zero breaking changes to existing chat functionality
- [ ] Clean integration with existing services
- [ ] Documentation complete (user guide, technical docs, API docs)

## Communication Protocols

### Daily Standup Format (async in chat)
1. What did you complete yesterday?
2. What will you work on today?
3. Any blockers or questions?

### Weekly Review Format (1 hour meeting)
1. Demo completed features (15 mins)
2. Architecture review (20 mins)
3. Risk review (10 mins)
4. Planning next week (15 mins)

## Resources & References
- [BitChat Whitepaper](../WHITEPAPER.md)
- [Noise Protocol Spec](https://noiseprotocol.org/)
- [Nostr Protocol NIPs](https://github.com/nostr-protocol/nips)
- [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui)

## Escalation Path
- Technical blockers → Make decision and document in ADR
- Cross-team conflicts → Facilitate discussion, align on solution
- Timeline risks → Adjust scope, communicate to stakeholders
- Security issues → Immediately involve Security Engineer, pause deployment if needed

---

**Remember**: This is a transformation of existing infrastructure, not a greenfield project. Preserve the existing chat functionality while adding ticket exchange capabilities.
