<img width="256" height="256" alt="icon_128x128@2x" src="https://github.com/user-attachments/assets/90133f83-b4f6-41c6-aab9-25d0859d2a47" />

## bitchat → TicketExchange

A decentralized peer-to-peer ticket marketplace with dual transport architecture: local Bluetooth mesh networks for in-person ticket exchanges and internet-based Nostr protocol for global reach. No middlemen, no massive fees. It's the modern "no scalping zone."

[bitchat.free](http://bitchat.free)

📲 [App Store](https://apps.apple.com/us/app/bitchat-mesh/id6748219622)

> [!WARNING]
> Private messages have not received external security review and may contain vulnerabilities. Do not use for sensitive use cases, and do not rely on its security until it has been reviewed. Now uses the [Noise Protocol](https://www.noiseprotocol.org) for identity and encryption. Public local chat (the main feature) has no security concerns.

## License

This project is released into the public domain. See the [LICENSE](LICENSE) file for details.

## Features

### 🎟️ Decentralized Ticket Marketplace
- **P2P Ticket Exchange**: Buy and sell event tickets directly without intermediaries
- **No Platform Fees**: Keep 100% of your money - no Ticketmaster or StubHub cuts
- **Companion Seating**: Find compatible people to sit with - never sit next to a stranger again
- **Location-Based Discovery**: Find tickets for events near you using geohash channels
- **Modern "No Scalping Zone"**: Like the old stadium meetup spots, but decentralized
- **Secure Transactions**: Coordinate exchanges over encrypted P2P channels
- **Multiple Event Types**: Concerts, sports, theater, festivals, conferences, and more

### 💬 Built on Proven P2P Technology
- **Dual Transport Architecture**: Bluetooth mesh for offline + Nostr protocol for internet-based messaging
- **Location-Based Channels**: Geographic chat rooms using geohash coordinates over global Nostr relays
- **Intelligent Message Routing**: Automatically chooses best transport (Bluetooth → Nostr fallback)
- **Decentralized Mesh Network**: Automatic peer discovery and multi-hop message relay over Bluetooth LE
- **Privacy First**: No accounts, no phone numbers, no persistent identifiers
- **Private Message End-to-End Encryption**: [Noise Protocol](https://noiseprotocol.org) for mesh, NIP-17 for Nostr
- **IRC-Style Commands**: Familiar `/slap`, `/msg`, `/who` style interface
- **Universal App**: Native support for iOS and macOS
- **Emergency Wipe**: Triple-tap to instantly clear all data
- **Performance Optimizations**: LZ4 message compression, adaptive battery modes, and optimized networking

## [Technical Architecture](https://deepwiki.com/permissionlesstech/bitchat)

BitChat uses a **hybrid messaging architecture** with two complementary transport layers:

### Bluetooth Mesh Network (Offline)

- **Local Communication**: Direct peer-to-peer within Bluetooth range
- **Multi-hop Relay**: Messages route through nearby devices (max 7 hops)
- **No Internet Required**: Works completely offline in disaster scenarios
- **Noise Protocol Encryption**: End-to-end encryption with forward secrecy
- **Binary Protocol**: Compact packet format optimized for Bluetooth LE constraints
- **Automatic Discovery**: Peer discovery and connection management
- **Adaptive Power**: Battery-optimized duty cycling

### Nostr Protocol (Internet)

- **Global Reach**: Connect with users worldwide via internet relays
- **Location Channels**: Geographic chat rooms using geohash coordinates
- **290+ Relay Network**: Distributed across the globe for reliability
- **NIP-17 Encryption**: Gift-wrapped private messages for internet privacy
- **Ephemeral Keys**: Fresh cryptographic identity per geohash area

### Channel Types

#### `mesh #bluetooth`

- **Transport**: Bluetooth Low Energy mesh network
- **Scope**: Local devices within multi-hop range
- **Internet**: Not required
- **Use Case**: Offline communication, protests, disasters, remote areas

#### Location Channels (`block #dr5rsj7`, `neighborhood #dr5rs`, `country #dr`)

- **Transport**: Nostr protocol over internet
- **Scope**: Geographic areas defined by geohash precision
  - `block` (7 chars): City block level
  - `neighborhood` (6 chars): District/neighborhood
  - `city` (5 chars): City level
  - `province` (4 chars): State/province
  - `region` (2 chars): Country/large region
- **Internet**: Required (connects to Nostr relays)
- **Use Case**: Location-based community chat, local events, regional discussions

### Direct Message Routing

Private messages use **intelligent transport selection**:

1. **Bluetooth First** (preferred when available)

   - Direct connection with established Noise session
   - Fastest and most private option

2. **Nostr Fallback** (when Bluetooth unavailable)

   - Uses recipient's Nostr public key
   - NIP-17 gift-wrapping for privacy
   - Routes through global relay network

3. **Smart Queuing** (when neither available)
   - Messages queued until transport becomes available
   - Automatic delivery when connection established

For detailed protocol documentation, see the [Technical Whitepaper](WHITEPAPER.md).

## How the Ticket Marketplace Works

The decentralized ticket exchange leverages the same P2P infrastructure as the messaging app:

### Listing Tickets
1. **Create a Listing**: Sellers create listings with event details (name, date, venue, section, price)
2. **Optional Companion Seating**: Indicate if you're attending and want a compatible companion (not a stranger!)
3. **Broadcast to Network**: Listings are shared over the current channel (Bluetooth mesh or Nostr geohash)
4. **Location-Based Discovery**: Buyers discover listings in their area through geohash channels

### Finding and Buying Tickets
1. **Browse Available Tickets**: Filter by event type, location, or search by name
2. **Filter for Companions**: Look for sellers seeking compatible company - marked with 👥 badge
3. **Contact Seller**: Initiate a private P2P chat (Bluetooth or Nostr) with the seller
4. **Vet & Chat**: For companion listings, get to know each other to ensure compatibility
5. **Negotiate Terms**: Discuss price, meetup location, and payment method
6. **Complete Exchange**: Meet in person or coordinate remote transfer

### Key Advantages
- **No Platform Fees**: Unlike Ticketmaster/StubHub (20-30% fees), keep 100% of your money
- **Companion Seating**: Solve the "extra ticket but don't want a stranger" problem
- **Direct Communication**: Chat directly with buyers/sellers using encrypted P2P messaging
- **Social Vetting**: Get to know your seatmate before committing
- **Local & Global**: Find tickets locally (Bluetooth mesh) or worldwide (Nostr)
- **Privacy First**: No accounts, no tracking, no data mining
- **Community-Driven**: Like the original "no scalping zones" outside stadiums, but decentralized

## Setup

### Option 1: Using Xcode

   ```bash
   cd bitchat
   open bitchat.xcodeproj
   ```

   To run on a device there're a few steps to prepare the code:
   - Clone the local configs: `cp Configs/Local.xcconfig.example Configs/Local.xcconfig`
   - Add your Developer Team ID into the newly created `Configs/Local.xcconfig`
      - Bundle ID would be set to `chat.bitchat.<team_id>` (unless you set to something else)
   - Entitlements need to be updated manually (TODO: Automate):
      - Search and replace `group.chat.bitchat` with `group.<your_bundle_id>` (e.g. `group.chat.bitchat.ABC123`)

### Option 2: Using `just`

   ```bash
   brew install just
   ```

Want to try this on macos: `just run` will set it up and run from source.
Run `just clean` afterwards to restore things to original state for mobile app building and development.

## Localization

- Base app resources live under `bitchat/Localization/Base.lproj/`. Add new copy to `Localizable.strings` and plural rules to `Localizable.stringsdict`.
- Share extension strings are separate in `bitchatShareExtension/Localization/Base.lproj/Localizable.strings`.
- Prefer keys that describe intent (`app_info.features.offline.title`) and reuse existing ones where possible.
- Run `xcodebuild -project bitchat.xcodeproj -scheme "bitchat (macOS)" -configuration Debug CODE_SIGNING_ALLOWED=NO build` to compile-check any localization updates.
