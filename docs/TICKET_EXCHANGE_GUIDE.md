# Ticket Exchange User Guide

## Overview

The decentralized ticket marketplace transforms BitChat into a peer-to-peer ticket exchange platform, eliminating the need for centralized intermediaries like Ticketmaster and StubHub. Built on the same secure P2P infrastructure as the messaging app, it enables direct buyer-seller connections without platform fees.

## Key Advantages

### 💰 Zero Platform Fees
- **Keep 100% of your money** - unlike Ticketmaster/StubHub which take 20-30% in fees
- No service charges, no convenience fees, no hidden costs
- Buyers and sellers negotiate directly

### 🔒 Privacy & Security
- End-to-end encrypted communications using the Noise Protocol
- No accounts required - no tracking or data mining
- Direct P2P transactions without middlemen

### 📍 Local & Global Discovery
- **Bluetooth Mesh**: Find tickets from people nearby (concerts, sports games)
- **Nostr Geohash Channels**: Discover tickets worldwide in specific locations
- Location-based filtering for events in your area

### 🤝 Direct Communication
- Chat directly with buyers/sellers over encrypted channels
- Negotiate price, meetup location, and payment method
- Build trust through conversation before meeting

## How to Use

### Selling Tickets

1. **Create a Listing**
   - Tap the 🎟️ ticket icon in the header
   - Select "My Listings" tab
   - Tap the + button
   - Choose "Sell Tickets"

2. **Fill in Event Details**
   - Event name (e.g., "Taylor Swift Eras Tour")
   - Venue (e.g., "SoFi Stadium")
   - Date and time
   - Event type (Concert, Sports, Theater, etc.)

3. **Add Ticket Information**
   - Section, Row, Seat (if applicable)
   - Quantity of tickets
   - Asking price and currency
   - Original price (optional - shows buyers you're not scalping)

4. **Add Description** (Optional)
   - Include any relevant details
   - Transfer method (mobile transfer, paper tickets, etc.)
   - Special conditions

5. **Post the Listing**
   - Your listing broadcasts to the current channel
   - Available on both Bluetooth mesh and Nostr channels

### Buying Tickets

1. **Browse Available Tickets**
   - Tap the 🎟️ ticket icon
   - Browse listings in the "Browse" tab
   - Use search to find specific events
   - Filter by event type (concerts, sports, etc.)

2. **Find What You Want**
   - Search by event name or venue
   - Check location, date, and price
   - See section/seat details
   - View seller's nickname

3. **Contact the Seller**
   - Tap a listing to see details
   - Tap "Contact Seller" to start a private chat
   - Or tap "I'm Interested" to express interest

4. **Negotiate and Arrange**
   - Discuss price if needed
   - Agree on meetup location and time
   - Coordinate payment method (cash, Venmo, etc.)
   - Confirm ticket transfer method

5. **Complete the Exchange**
   - Meet in person at agreed location
   - Verify tickets are legitimate
   - Complete payment
   - Transfer tickets

### Creating "Wanted" Listings

Looking for tickets to a sold-out show? Create a buy listing:

1. Create a new listing
2. Select "Buy Tickets" instead of "Sell"
3. Fill in event details and your offer price
4. Post the listing
5. Sellers with available tickets can contact you

## Best Practices

### For Sellers

- **Be Honest**: Post accurate ticket details and pricing
- **Show Original Price**: Builds trust and shows you're not price gouging
- **Respond Quickly**: Fast responses help close deals
- **Meet Safely**: Choose public locations for meetups
- **Verify Transfer**: Ensure ticket transfer completes successfully

### For Buyers

- **Verify Tickets**: Check barcodes/QR codes before paying
- **Meet in Public**: Stadium entrances, coffee shops, etc.
- **Be Prompt**: Show up on time for meetups
- **Bring Exact Change**: Makes transactions smoother
- **Leave Feedback**: Share your experience in the community

## Safety Tips

### Meeting in Person

- **Public Locations**: Stadium gates, coffee shops, busy areas
- **Daytime Preferred**: Better visibility and more people around
- **Bring a Friend**: Extra safety and witness to transaction
- **Trust Your Instincts**: If something feels off, walk away

### Verifying Tickets

- **Check Barcodes**: Ensure they scan properly
- **Mobile Transfers**: Complete transfer before payment
- **Paper Tickets**: Check for watermarks and security features
- **Seller History**: Chat with seller to build trust

### Payment

- **Cash is King**: Safest for in-person transactions
- **Digital Payments**: Venmo, PayPal, etc. (know the risks)
- **Never Wire Money**: Scammers love wire transfers
- **Get Receipt**: Screenshot transactions for records

## Technical Details

### How Listings are Shared

1. **Channel Broadcasting**: Listings broadcast to your current channel
   - In #mesh: Shared via Bluetooth to nearby devices
   - In geohash channels (e.g., #dr5rsj7): Shared via Nostr relays to that location

2. **Peer-to-Peer Discovery**: Other users discover your listing
   - Bluetooth mesh: Direct peer discovery within range
   - Nostr: Location-based discovery through geohash channels

3. **Private Negotiation**: Buyers contact you via encrypted P2P chat
   - Bluetooth: Direct encrypted connection using Noise Protocol
   - Nostr: NIP-17 gift-wrapped private messages

### Data Privacy

- **No Central Database**: Listings are distributed across the P2P network
- **No Account Required**: No registration, no email, no phone number
- **Ephemeral by Design**: Listings expire when events pass
- **Encrypted Communications**: All buyer-seller chats are end-to-end encrypted

## Comparison with Traditional Platforms

| Feature | Ticket Exchange | Ticketmaster/StubHub |
|---------|----------------|---------------------|
| **Seller Fees** | 0% | 10-15% |
| **Buyer Fees** | 0% | 10-20% |
| **Total Fees** | **0%** | **20-35%** |
| **Account Required** | No | Yes |
| **Data Collection** | None | Extensive |
| **Direct Communication** | Yes | No |
| **Local Discovery** | Bluetooth mesh | Not available |
| **Privacy** | End-to-end encrypted | Centralized tracking |

## Reviving the "No Scalping Zone"

Remember the informal marketplaces outside stadiums in the 90s? Where people would hold up signs saying "Need an extra!" or "Selling one!"? This is the digital, decentralized version of that community-driven ticket exchange:

- **Self-Organizing**: No platform controlling access or extracting fees
- **Community Trust**: Face-to-face interaction builds accountability
- **Fair Pricing**: Market-driven prices without artificial markups
- **Local Focus**: Connect with fans in your area attending the same event

## Troubleshooting

### "No tickets available"

- Try different channels (switch between #mesh and geohash channels)
- Search for the specific event name
- Create a "wanted" listing to let sellers know you're looking

### "Can't contact seller"

- Check connection status (Bluetooth or Nostr)
- Ensure you're in the same geohash channel for Nostr discovery
- Try sending a public message mentioning their nickname

### "Listing not appearing"

- Verify you're broadcasting to the correct channel
- Check that event date is in the future (past events filter out)
- Ensure you have Bluetooth or internet connectivity

## Future Enhancements

The ticket exchange is built on extensible P2P infrastructure. Potential future features:

- **Reputation System**: Track successful exchanges
- **Escrow Integration**: Optional crypto/lightning escrow
- **Verified Tickets**: Integration with venue APIs
- **Rating System**: Buyer/seller ratings
- **Group Purchases**: Split ticket packages among friends

## Community Guidelines

To keep the marketplace healthy and trustworthy:

1. **Price Fairly**: Don't gouge fans for sold-out shows
2. **Be Honest**: Accurate ticket details and availability
3. **Communicate Clearly**: Respond to inquiries promptly
4. **Complete Transactions**: Honor your commitments
5. **Report Issues**: Block bad actors using the app's block feature

---

## Get Started

Ready to revolutionize ticket sales? 

1. Tap the 🎟️ icon in the app header
2. Create your first listing or browse available tickets
3. Connect with real fans, not faceless corporations
4. Keep 100% of your money where it belongs - with you!

Welcome to the future of peer-to-peer ticket exchange. 🎟️
