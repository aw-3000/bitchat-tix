# Ticket Transfer Harness Design

## Overview

This document describes the unified ticket transfer mechanism for the BitChat ticket marketplace. The system provides seamless load/verify/list/transfer operations inspired by Apple's AirDrop, making ticket exchanges as effortless as sharing files between devices.

## Problem Statement

Traditional ticket marketplaces have fragmented workflows:
- **Loading**: Tickets come from multiple sources (purchases, transfers, imports)
- **Verification**: Authenticity checks are manual and error-prone
- **Listing**: Creating listings requires multiple steps
- **Transfer**: Moving tickets between users is complex and risky

We need a unified harness that makes these operations seamless, secure, and user-friendly.

## Use Cases

### 1. Buyer Receiving a Ticket (Airdrop-style)

**Scenario**: Alice buys a ticket from Bob through the marketplace.

**Flow**:
1. Bob initiates transfer via Bluetooth or Nostr
2. Alice receives a transfer request notification
3. Alice previews ticket details (event, seat, price paid)
4. Alice accepts the transfer
5. Ticket is cryptographically signed and transferred
6. Bob's ticket is marked as transferred
7. Alice's ticket is added to her wallet

**Implementation**: `TicketTransferService.initiateTransfer()` + `acceptTransfer()`

### 2. Gate Verification (Host Device)

**Scenario**: Alice arrives at the venue with her digital ticket.

**Flow**:
1. Alice opens her ticket wallet and selects the ticket
2. Alice shows QR code or initiates Bluetooth transfer to gate reader
3. Gate device (host) scans/receives the ticket
4. Gate device verifies:
   - Ticket signature is valid
   - Ticket hasn't been used before (check used ticket list)
   - Ticket is for this event
   - Current time is within event window
5. If valid, gate device marks ticket as used and admits entry
6. Gate device can optionally sync used tickets over internet to prevent double-entry

**Implementation**: `GateVerificationHarness` with offline-first verification

### 3. Quick Listing from Wallet

**Scenario**: Bob has tickets in his wallet but can't attend.

**Flow**:
1. Bob opens his ticket wallet
2. Bob selects a ticket and taps "List for Sale"
3. Pre-filled listing form (event details auto-populated)
4. Bob sets price and optional companion preferences
5. Listing broadcasts to network
6. When sold, ticket transfers automatically

**Implementation**: `TicketMarketplaceService.createListingFromWallet()`

### 4. Importing Tickets from External Sources

**Scenario**: Alice has a ticket from Ticketmaster that she wants to resell.

**Flow**:
1. Alice scans ticket QR code or imports PDF
2. System extracts event details, barcode, seat info
3. Ticket is wrapped in BitChat ticket format with signature
4. Ticket added to wallet
5. Alice can now list or transfer using BitChat

**Implementation**: `TicketImportService` (supports QR, PDF, mobile wallet URLs)

## Architecture

### Core Components

```
┌─────────────────────────────────────────────────┐
│          Ticket Transfer Harness                │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────────┐    ┌──────────────────┐  │
│  │ Ticket Wallet    │    │ Transfer Service │  │
│  │ - My Tickets     │───▶│ - Send/Receive   │  │
│  │ - Load/Import    │    │ - AirDrop-style  │  │
│  │ - Verify         │    │ - Bluetooth/Nostr│  │
│  └──────────────────┘    └──────────────────┘  │
│           │                        │            │
│           ▼                        ▼            │
│  ┌──────────────────┐    ┌──────────────────┐  │
│  │ Verification     │    │ Gate Harness     │  │
│  │ Service          │    │ - Scan/Receive   │  │
│  │ - Crypto Verify  │◀───│ - Offline Verify │  │
│  │ - Used Tracking  │    │ - Admit/Deny     │  │
│  └──────────────────┘    └──────────────────┘  │
│           │                                     │
│           ▼                                     │
│  ┌──────────────────────────────────────────┐  │
│  │       Marketplace Service                │  │
│  │  - Browse Listings                       │  │
│  │  - Quick List from Wallet                │  │
│  │  - Transaction Coordination              │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### Data Models

#### TicketWallet
Manages user's owned tickets:
- Active tickets (not transferred, not used)
- Historical tickets (completed events)
- Tickets awaiting transfer completion

#### TicketTransferRequest
Represents an in-flight transfer:
- From peer ID, to peer ID
- Ticket data + cryptographic proof
- Transfer status (pending/accepted/rejected/completed)
- Transport method (Bluetooth/Nostr)

#### TicketVerificationProof
Cryptographic proof of authenticity:
- Issuer signature (original ticket source)
- Chain of custody (transfers)
- Validation timestamp
- Verification nonce (prevents replay)

## Transfer Protocol

### P2P Transfer (Airdrop-style)

Uses existing Noise Protocol encrypted channels:

```
Sender                          Receiver
  │                                │
  │  TICKET_TRANSFER_REQUEST       │
  │──────────────────────────────▶│
  │  {ticket, proof, metadata}     │
  │                                │
  │  TRANSFER_PREVIEW_ACCEPTED     │
  │◀──────────────────────────────│
  │                                │
  │  TRANSFER_COMPLETE             │
  │──────────────────────────────▶│
  │  {signature, timestamp}        │
  │                                │
  │  TRANSFER_ACKNOWLEDGED         │
  │◀──────────────────────────────│
  │                                │
```

**Message Types**:
- `ticketTransferRequest`: Initial transfer proposal
- `ticketTransferAccept`: Receiver accepts transfer
- `ticketTransferReject`: Receiver declines transfer
- `ticketTransferComplete`: Final confirmation with signatures
- `ticketTransferAck`: Acknowledgment of completion

### QR Code Transfer (Gate/Import)

For one-way transfers (gates, imports):

**QR Payload**:
```json
{
  "v": 1,
  "type": "ticket",
  "ticket": {
    "id": "...",
    "eventName": "...",
    "eventDate": "...",
    "venue": "...",
    "seat": "...",
    // ... other ticket fields
  },
  "proof": {
    "issuerSig": "hex...",
    "chainSigs": ["hex...", "hex..."],
    "timestamp": 1234567890
  },
  "barcode": "original_barcode_data",
  "sig": "hex..."
}
```

**Verification**:
1. Decode QR payload
2. Verify JSON structure
3. Check signature against known public key
4. Verify chain of custody signatures
5. Check against used ticket database
6. Validate event date/time

## Gate Verification Harness

### Requirements

**Hardware**: iPad or iPhone with:
- Camera for QR scanning
- Bluetooth for proximity verification
- Optional: Internet for used ticket sync

**Software**: Dedicated gate reader mode in BitChat app

### Offline-First Operation

The gate device maintains a local database of:
- **Used tickets**: Tickets that have been scanned and admitted
- **Event configuration**: Valid event IDs, time windows, venue
- **Trusted issuer keys**: Public keys for signature verification

**Operation modes**:
1. **Fully offline**: No internet, relies on local used-ticket db
   - Risk: Can't detect tickets used at other gates
   - Mitigation: Periodic sync when internet available

2. **Online with fallback**: Syncs used tickets to/from central relay
   - Primary: Check central database for used tickets
   - Fallback: Use local db if network unavailable

3. **Bluetooth mesh sync**: Multiple gate devices sync used tickets
   - Gates form local mesh network
   - Share used ticket list in real-time
   - No internet required

### Gate Device Setup

1. **Configuration**:
   - Event ID and name
   - Valid entry time window
   - Gate ID (for multi-gate events)
   - Trusted issuer public keys

2. **Operation**:
   - Scan ticket QR codes
   - Receive Bluetooth transfers
   - Verify signatures and freshness
   - Check against used ticket list
   - Admit or deny entry
   - Log all attempts (for audit)

3. **Sync** (when online):
   - Upload used tickets to relay
   - Download used tickets from other gates
   - Report gate statistics

## Security Considerations

### Ticket Authenticity

**Chain of Custody**:
- Original ticket issued with issuer signature
- Each transfer adds a signature to the chain
- Receiver can verify entire chain back to issuer

**Replay Prevention**:
- Each ticket has unique ID + nonce
- Gate devices track used ticket IDs
- Cannot reuse same ticket at gate

**Forgery Prevention**:
- All tickets signed with Ed25519
- Public keys distributed through trusted channels
- Gate devices only accept known issuer keys

### Transfer Security

**Man-in-the-Middle Protection**:
- Transfers use Noise Protocol encrypted channels
- Mutual authentication before transfer
- Forward secrecy for each session

**Double-Spend Prevention**:
- Sender marks ticket as "transfer pending"
- On completion, sender marks as "transferred"
- Sender cannot initiate multiple transfers of same ticket

**Revocation**:
- Tickets can be invalidated by issuer (fraud, refund)
- Revocation list distributed via Nostr relays
- Gate devices check revocation before admitting

## User Experience

### Sending a Ticket (Seller)

**From Chat**:
1. In private chat with buyer
2. Tap 📎 attachment button
3. Select "Send Ticket"
4. Choose ticket from wallet
5. Confirm transfer → Sent!

**From Wallet**:
1. Open ticket wallet
2. Select ticket
3. Tap "Transfer"
4. Choose recipient (recent chats or scan QR)
5. Confirm → Sent!

### Receiving a Ticket (Buyer)

**Notification**:
- "Bob wants to send you a ticket"
- Preview: "Taylor Swift - Aug 15, Sec 104, Row 12"
- [View Details] [Accept] [Decline]

**Accepting**:
- Tap "Accept"
- Ticket added to wallet
- Confirmation message sent to seller

### Using Ticket at Gate

**Show Ticket**:
1. Open wallet
2. Select ticket for today's event
3. Ticket displayed full-screen with QR code
4. Gate attendant scans
5. ✅ "Admitted" confirmation

**Alternative (Bluetooth)**:
1. Enable Bluetooth transfer mode
2. Hold phone near gate reader
3. Gate receives ticket wirelessly
4. ✅ "Admitted" confirmation

## Implementation Plan

### Phase 1: Core Transfer Service (Minimal)
- [x] Design document (this)
- [ ] `TicketWalletService` - Manage owned tickets
- [ ] `TicketTransferService` - P2P transfers
- [ ] `TicketVerificationService` - Crypto verification
- [ ] Tests for core services

### Phase 2: QR Code Support
- [ ] QR code generation for tickets
- [ ] QR code scanning for import/verification
- [ ] Ticket import from external sources
- [ ] Tests for QR workflows

### Phase 3: Gate Verification
- [ ] `GateVerificationHarness` service
- [ ] Gate reader UI mode
- [ ] Used ticket tracking
- [ ] Offline verification
- [ ] Tests for gate operations

### Phase 4: Advanced Features
- [ ] Bluetooth mesh sync for gates
- [ ] Central used-ticket relay (optional)
- [ ] Ticket revocation support
- [ ] Bulk import/export
- [ ] Analytics and reporting

## API Examples

### Transfer a Ticket

```swift
// Sender initiates transfer
let request = try await TicketTransferService.shared.initiateTransfer(
    ticket: myTicket,
    toPeer: buyerPeerID,
    method: .bluetooth
)

// Receiver gets notification, accepts
let result = try await TicketTransferService.shared.acceptTransfer(
    requestID: request.id
)

// Ticket now in receiver's wallet
print("Received ticket: \(result.ticket.eventName)")
```

### Verify at Gate

```swift
// Gate device scans QR code
let qrData = scanQRCode()

// Verify ticket
let verification = try await GateVerificationHarness.shared.verifyTicket(
    qrData: qrData,
    eventID: currentEventID
)

switch verification.result {
case .valid:
    print("✅ ADMIT - Ticket valid")
    // Mark as used
    try await GateVerificationHarness.shared.markTicketUsed(
        ticketID: verification.ticket.id
    )
    
case .alreadyUsed:
    print("❌ DENY - Ticket already scanned")
    
case .invalid:
    print("❌ DENY - Invalid ticket")
    
case .expired:
    print("❌ DENY - Event time passed")
}
```

### Quick List from Wallet

```swift
// User selects ticket in wallet, taps "List"
let listing = try await TicketMarketplaceService.shared.createListingFromWallet(
    ticket: selectedTicket,
    askingPrice: 75.00,
    companionPreferences: "20s-30s, love indie rock"
)

print("Listed: \(listing.ticket.eventName) for $\(listing.ticket.askingPrice)")
```

## Conclusion

This unified transfer harness provides:

✅ **Seamless transfers** - AirDrop-style simplicity
✅ **Secure verification** - Cryptographic proof of authenticity
✅ **Offline-first gates** - Works without internet
✅ **Easy listing** - One-tap from wallet to marketplace
✅ **Import/export** - Bridge external tickets into ecosystem

The design leverages existing BitChat P2P infrastructure while adding ticket-specific workflows optimized for real-world use cases at venues and marketplaces.
