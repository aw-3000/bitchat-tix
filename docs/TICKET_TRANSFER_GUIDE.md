# Ticket Transfer Guide

## Quick Start

The ticket transfer harness provides four main workflows:

1. **Load** - Import tickets into your wallet
2. **Verify** - Confirm ticket authenticity  
3. **List** - Sell tickets on the marketplace
4. **Transfer** - Send tickets to others

## Use Case 1: Buying and Receiving Tickets

### Alice buys a ticket from Bob

**Bob's steps (Seller)**:
```swift
// 1. Bob has ticket in wallet
let myTicket = walletService.activeTickets.first!

// 2. Bob initiates transfer after agreeing on price
let transferRequest = try await transferService.initiateTransfer(
    ticket: myTicket.ticket,
    proof: myTicket.proof,
    toPeer: alicePeerID,
    toNickname: "Alice",
    fromPeer: myPeerID,
    fromNickname: "Bob",
    method: .bluetooth  // or .nostr for internet
)

// Transfer sent! Bob waits for Alice to accept
```

**Alice's steps (Buyer)**:
```swift
// 1. Alice receives notification of incoming transfer
// UI shows: "Bob wants to send you a ticket"
// Preview: Taylor Swift - Aug 15, Sec 104, $75

// 2. Alice reviews and accepts
try await transferService.acceptTransfer(requestID: transferRequest.id)

// 3. Ticket automatically added to Alice's wallet
let receivedTicket = walletService.activeTickets.last!
print("Received: \(receivedTicket.ticket.eventName)")
```

**Result**: 
- Alice has ticket in her wallet
- Bob's ticket moved to history (transferred)
- Transaction complete! 🎉

## Use Case 2: Using Tickets at Venue Gate

### Alice arrives at the concert venue

**Setup Gate (one-time)**:
```swift
// Venue staff configures gate iPad
gateHarness.configureGate(
    eventID: "taylor-swift-aug15",
    eventName: "Taylor Swift Eras Tour",
    venue: "SoFi Stadium",
    eventDate: eventDate,
    gateID: "gate-a3",
    trustedIssuerKeys: ["venue-issuer-public-key"]
)
```

**Alice shows ticket (Option 1: QR Code)**:
```swift
// 1. Alice opens her wallet and selects ticket
let ticket = walletService.todaysTickets().first!

// 2. Generate QR code
let qrPayload = TicketQRPayload(
    ticket: ticket.ticket,
    proof: ticket.proof,
    signature: mySignature
)
let qrString = qrPayload.toURLString()

// 3. Display QR code (full screen)
// Gate attendant scans...
```

**Gate attendant verifies**:
```swift
// Scan QR code
let scannedData = scanQRCode()

// Verify ticket
let result = gateHarness.verifyTicket(qrData: scannedData)

switch result.status {
case .valid:
    // ✅ ADMIT
    print("✅ \(result.message)")
    gateHarness.markTicketUsed(result.ticket!.id)
    // Show green checkmark, open turnstile
    
case .alreadyUsed:
    // ❌ DENY - Already scanned
    print("❌ Ticket already used")
    // Show red X, alert security
    
case .invalid:
    // ❌ DENY - Fake/invalid
    print("❌ Invalid ticket: \(result.message)")
    // Show red X, alert security
    
case .expired:
    // ❌ DENY - Event passed
    print("❌ Event time has passed")
    
case .wrongEvent:
    // ❌ DENY - Wrong event
    print("❌ This ticket is for a different event")
}
```

**Alice shows ticket (Option 2: Bluetooth)**:
```swift
// 1. Alice enables Bluetooth transfer mode
// 2. Holds phone near gate reader

// Gate receives via Bluetooth
let receivedTicket = receiveBluetoothTransfer()
let result = gateHarness.verifyTransferredTicket(
    receivedTicket.ticket,
    proof: receivedTicket.proof
)

// Same verification flow as QR code
if result.status == .valid {
    gateHarness.markTicketUsed(receivedTicket.ticket.id)
    // ✅ ADMIT
}
```

**Result**:
- Alice admitted to venue
- Ticket marked as used (can't be reused)
- Gate statistics updated

## Use Case 3: Quick Listing from Wallet

### Bob can't attend and wants to sell

**Bob's steps**:
```swift
// 1. Bob opens wallet
let myTickets = walletService.activeTickets

// 2. Selects ticket he can't use
let ticketToSell = myTickets.first!

// 3. Creates listing (one tap!)
let listing = try await marketplaceService.createListingFromWallet(
    ticket: ticketToSell.ticket,
    askingPrice: Decimal(75),
    companionPreferences: "20s-30s, love pop music"
)

// Listing automatically broadcast to network
print("Listed: \(listing.ticket.eventName) for $\(listing.ticket.askingPrice)")
```

**What happens**:
- Listing created with pre-filled event details
- Broadcast to current channel (Bluetooth or Nostr)
- Other users see listing in marketplace
- When sold, ticket transfers automatically

## Use Case 4: Importing External Tickets

### Alice has a Ticketmaster ticket to resell

**Import from QR code**:
```swift
// 1. Alice scans Ticketmaster QR code
let externalQR = scanTicketmasterQR()

// 2. Extract ticket details
let importedTicket = extractTicketDetails(from: externalQR)

// 3. Wrap in BitChat format with proof
let proof = verificationService.createProof(
    for: importedTicket,
    issuerPrivateKey: myPrivateKey
)

// 4. Add to wallet
let ownedTicket = walletService.addTicket(
    importedTicket,
    source: .imported(source: "Ticketmaster"),
    proof: proof
)

// 5. Now can list or transfer using BitChat
```

**Import from PDF**:
```swift
// Similar flow for PDF tickets
let pdfData = loadTicketPDF()
let extractedTicket = parsePDFTicket(pdfData)
// ... wrap and add to wallet
```

**Result**:
- External ticket now in BitChat wallet
- Can list on marketplace
- Can transfer to others
- Original barcode preserved for venue entry

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│              User's Wallet                      │
│  ┌──────────────────────────────────────────┐   │
│  │  Active Tickets                          │   │
│  │  • Taylor Swift - Aug 15                 │   │
│  │  • Lakers Game - Aug 20                  │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  Actions:                                        │
│  • Transfer → Send to buyer                      │
│  • List → Create marketplace listing             │
│  • Show → Display QR for gate                    │
│  • Import → Add from external source             │
└─────────────────────────────────────────────────┘
           │              │              │
           ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ Transfer │   │   List   │   │   Gate   │
    │ Service  │   │ Service  │   │ Harness  │
    └──────────┘   └──────────┘   └──────────┘
           │              │              │
           └──────────────┴──────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │   Verification   │
              │     Service      │
              │ • Crypto checks  │
              │ • Chain verify   │
              └──────────────────┘
```

## Key Features

### 1. Wallet Management
- **Active tickets**: Ready to use/transfer
- **Historical tickets**: Past events or transferred
- **Pending transfers**: Incoming/outgoing
- **Smart organization**: Today's events, upcoming, etc.

### 2. Transfer Protocol
- **P2P encrypted**: Uses Noise Protocol
- **Multi-transport**: Bluetooth or Nostr
- **Chain of custody**: Every transfer signed
- **Replay protection**: Unique nonces

### 3. Gate Verification
- **Offline-first**: Works without internet
- **Cryptographic**: Verify signatures
- **Used tracking**: Prevent double-entry
- **Multi-gate sync**: Share used tickets

### 4. Security
- **Ed25519 signatures**: All tickets signed
- **Trusted issuers**: Only accept known sources
- **Chain verification**: Track every transfer
- **Revocation support**: Cancel fraudulent tickets

## API Reference

### TicketWalletService

```swift
// Add ticket to wallet
func addTicket(_ ticket: Ticket, source: TicketSource, proof: TicketVerificationProof) -> OwnedTicket

// Get today's tickets
func todaysTickets() -> [OwnedTicket]

// Get upcoming tickets
func upcomingTickets() -> [OwnedTicket]

// Mark as used
func markTicketUsed(_ ticketID: String)

// Mark as transferred
func markTicketTransferred(_ ticketID: String, toPeer: PeerID)
```

### TicketTransferService

```swift
// Initiate transfer (sender)
func initiateTransfer(
    ticket: Ticket,
    proof: TicketVerificationProof,
    toPeer: PeerID,
    toNickname: String,
    fromPeer: PeerID,
    fromNickname: String,
    method: TransferMethod
) throws -> TicketTransferRequest

// Accept transfer (receiver)
func acceptTransfer(requestID: String) throws

// Reject transfer
func rejectTransfer(requestID: String) throws

// Cancel transfer (sender)
func cancelTransfer(requestID: String) throws
```

### TicketVerificationService

```swift
// Verify ticket authenticity
func verifyTicket(_ ticket: Ticket, proof: TicketVerificationProof) -> VerificationResult

// Create proof (issuer)
func createProof(for ticket: Ticket, issuerPrivateKey: Data) -> TicketVerificationProof?

// Sign transfer
func signTransfer(
    ticket: Ticket,
    currentProof: TicketVerificationProof,
    fromPublicKey: String,
    toPublicKey: String
) -> TicketVerificationProof?

// Manage trusted issuers
func addTrustedIssuer(_ publicKey: String)
func removeTrustedIssuer(_ publicKey: String)
```

### GateVerificationHarness

```swift
// Configure gate
func configureGate(
    eventID: String,
    eventName: String,
    venue: String,
    eventDate: Date,
    gateID: String,
    trustedIssuerKeys: [String]
)

// Verify ticket from QR
func verifyTicket(qrData: String) -> GateVerificationResult

// Verify ticket from Bluetooth
func verifyTransferredTicket(_ ticket: Ticket, proof: TicketVerificationProof) -> GateVerificationResult

// Mark as used
func markTicketUsed(_ ticketID: String)

// Sync operations
func syncWithNearbyGates()
func fetchUsedTicketsFromRelay() async
```

## Comparison with Traditional Systems

| Feature | BitChat Transfer Harness | Ticketmaster/StubHub |
|---------|-------------------------|----------------------|
| **Transfer Method** | P2P (Bluetooth/Nostr) | Centralized API |
| **Transfer Speed** | Instant | Minutes to hours |
| **Transfer Fees** | $0 | $5-15 |
| **Offline Support** | Yes (Bluetooth) | No |
| **Gate Verification** | Offline-first | Requires internet |
| **Chain of Custody** | Cryptographic proof | Database records |
| **Privacy** | End-to-end encrypted | Centralized tracking |
| **Revocation** | Distributed relay | Central server |

## Advanced Scenarios

### Multi-Gate Events

For large venues with multiple gates:

```swift
// Configure all gates with same event
let gates = ["A1", "A2", "A3", "B1", "B2"]
for gateID in gates {
    gateHarness.configureGate(
        eventID: eventID,
        eventName: eventName,
        venue: venue,
        eventDate: eventDate,
        gateID: gateID,
        trustedIssuerKeys: trustedKeys
    )
}

// Enable Bluetooth mesh sync
gateHarness.mode = .mesh
gateHarness.syncWithNearbyGates()

// Gates share used-ticket list in real-time
// Prevents double-entry across different gates
```

### Group Ticket Transfer

Transfer multiple tickets at once:

```swift
let tickets = walletService.activeTickets.filter { 
    $0.ticket.eventName == "Concert"
}

for ticketOwned in tickets {
    try await transferService.initiateTransfer(
        ticket: ticketOwned.ticket,
        proof: ticketOwned.proof,
        toPeer: friendPeerID,
        toNickname: "Friend",
        fromPeer: myPeerID,
        fromNickname: "Me",
        method: .bluetooth
    )
}
```

### Refund Handling

When event is cancelled:

```swift
// Mark tickets as refunded
for ticket in affectedTickets {
    walletService.archiveTicket(ticket.id, reason: .refunded)
}

// Issuer can revoke tickets
// (prevents use at rescheduled event)
```

## Troubleshooting

### Transfer not completing?

**Check**:
- Both peers online (for Nostr)
- Bluetooth enabled (for BLE)
- Sender has ticket in wallet
- Ticket not already transferred

### Gate verification failing?

**Check**:
- Gate configured correctly
- Event date/time correct
- Trusted issuer keys added
- Ticket signature valid
- Ticket not already used

### QR code won't scan?

**Check**:
- Screen brightness
- Camera permissions
- QR code size (should be large)
- URL format correct

## Next Steps

1. **UI Integration**: Connect services to SwiftUI views
2. **Transport Layer**: Wire up Bluetooth/Nostr messaging
3. **Relay Sync**: Implement used-ticket relay
4. **Import Tooling**: Add PDF/QR parsers for external tickets
5. **Analytics**: Track marketplace metrics

## Conclusion

The ticket transfer harness provides a complete solution for:

✅ **Seamless transfers** - As easy as AirDrop
✅ **Secure verification** - Cryptographic proofs
✅ **Offline gates** - No internet required
✅ **Easy listing** - One-tap from wallet
✅ **Import/export** - Bridge external tickets

All built on the existing P2P infrastructure with minimal changes to the codebase.
