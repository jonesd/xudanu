# Storage Cost, the Utility Meter, and Micropayments in Xudanu

## The Original Xanadu Vision

Ted Nelson coined the term "micropayment" decades before the World Wide Web. His vision for Xanadu was always a **for-profit publishing system** where:

1. **Authors get paid** when their content is read or transcluded
2. **Readers pay fractions of a cent** to access content
3. **The system tracks every byte** of storage and every act of transclusion
4. **Copyright is automatic** and royalties flow to the right holders

The `cost()` method in the Udanax Gold codebase is not an afterthought — it is a core architectural feature designed to support this vision.

## What `cost()` Actually Measures

The `cost()` method on `FeEdition` answers one question: **"How much disk space is this Edition consuming, and who owns it?"**

In our Rust implementation (`src/edition/bundle.rs`), this is:

```rust
pub struct StorageCost {
    pub total_bytes: u64,      // Raw bytes this Edition occupies
    pub unique_bytes: u64,     // Bytes unique to this Edition
    pub shared_bytes: u64,     // Bytes shared via transclusion
    pub share_count: u64,      // How many Editions share those bytes
    pub method: CostMethod,    // How to account for sharing
}
```

### The Utility Meter Analogy

Think of it like a water meter on an apartment building:

- Each apartment (Edition) has a meter
- Shared infrastructure (pipes, water heater) has a cost
- The landlord (server operator) needs to know total consumption
- The tenants (Edition owners) need to know their fair share
- If two apartments share a water line (transcluded content), how do you split the bill?

The C++ code even has a comment: *"No permissions are required to obtain this information, even though it exposes sharing by Editions you can't read to traffic analysis."* The meter is transparent by design — like a utility, not a secret.

## The Three Cost Methods

The Udanax Gold system defined three ways to account for shared (transcluded) material:

### 1. `TotalShared` (default)

Every Edition pays full price for all the bytes it references, even if those bytes are shared.

**Analogy**: Every apartment in the building pays for the full water heater, not just their share.

**When to use**: Simple billing, when you want to encourage Editions to be self-contained. Also useful for capacity planning — "if every Edition needed its own copy, how much disk would we need?"

**In the live demo**: "Hello World!" (12 chars) = 780 bytes. This is the full cost.

### 2. `ProrateShared`

Shared bytes are divided equally among all Editions that reference them.

**Analogy**: The water heater cost is split equally among all apartments connected to it.

**When to use**: Fair billing. If 5 Editions transclude the same paragraph, each pays 1/5 of that paragraph's storage cost.

**In practice**: This is the "Xanadu micropayment" method — it's how transclusion royalties would be calculated. The more your content is transcluded by others, the smaller each sharer's prorated cost becomes, but the original author accumulates micropayments from all sharers.

### 3. `OmitShared`

Shared bytes cost nothing to the Edition referencing them. Someone else pays.

**Analogy**: If your neighbor already paid for the water heater, you get hot water for free.

**When to use**: Encouraging transclusion. You want people to reuse existing content rather than create duplicates. The original author (or the server operator) absorbs the cost.

## How This Would Work in Practice

### Scenario: A Collaborative Document Server

```
Server has 3 Editions:

Edition A (Alice's essay):     "The quick brown fox jumps over the lazy dog"
                                total_bytes: 4160  (64 chars × 65 bytes/element)

Edition B (Bob's commentary):  "The quick brown fox is a classic pangram"
                                shares "The quick brown fox" with Edition A

Edition C (Carol's analysis):  "The lazy dog represents patience in literature"
                                shares "The lazy dog" with Edition A
```

**TotalShared billing:**
- Alice pays: 4160 bytes (her full essay)
- Bob pays: 3770 bytes (his full commentary)
- Carol pays: 4095 bytes (her full analysis)
- Server bills: 12,025 bytes total

**ProrateShared billing:**
- "The quick brown fox" (19 chars × 65 = 1235 bytes) shared by A and B → each pays 617.5
- "The lazy dog" (12 chars × 65 = 780 bytes) shared by A and C → each pays 390
- Alice pays: 4160 - 1235 + 617.5 + 780 - 390 = 3932.5 bytes
- Bob pays: 3770 - 1235 + 617.5 = 3152.5 bytes
- Carol pays: 4095 - 780 + 390 = 3705 bytes

**OmitShared billing:**
- Alice pays: 4160 bytes (she's the original author)
- Bob pays: 3770 - 1235 = 2535 bytes (free transclusion from Alice)
- Carol pays: 4095 - 780 = 3315 bytes (free transclusion from Alice)

## Ownership at the Element Level

The original C++ system tracks ownership at the individual `RangeElement` level through `rangeOwners()` and `setRangeOwners()`. This means:

- Position 0-19 of Edition A is "owned" by Alice
- When Bob transcludes positions 0-19 into Edition B, the system knows Alice is the original author
- The `separate_owners` flag on `retrieve()` can split bundles at ownership boundaries
- This enables per-author accounting and royalty distribution

In our Rust implementation, the `Club` system (identity/authorization groups) serves as the owner identity. The `edit_club` and `read_club` on each Work determine who can modify and who can read the content.

## The Xanadu Micropayment Flow (Design Intent)

The original vision was:

```
1. Alice writes content → stores it on a Xanadu server
   → Server records: Alice owns these bytes, cost = X bytes

2. Bob transcludes Alice's content into his document
   → Server records: Bob references Alice's bytes
   → Server calculates: Bob's cost (ProrateShared) = X/2

3. Reader accesses Bob's document
   → Server charges Reader: micropayment for access
   → Server distributes: portion to Bob, portion to Alice (royalty)
   → Server keeps: small transaction fee

4. Monthly settlement:
   → Alice receives: sum of all royalties from transclusions of her work
   → Bob receives: sum of all access fees for his document (minus Alice's royalty)
   → Server receives: transaction fees + storage fees
```

This is why the cost system was designed to be transparent — the server operator, the content owners, and the readers all need to verify the accounting.

## Current Payment Platform Landscape (2026)

### Platforms Suitable for Integration

| Platform | Min Transaction | Fees | Settlement | Best For | Integration |
|----------|----------------|------|------------|----------|-------------|
| **Dropp** | $0.01 | ~1% + $0.05 (>$5), flat $0.05 (<$1) | Instant (RTP via Truist) | Pay-per-use, micropurchases | REST API, SDK, WordPress/Shopify plugins |
| **OpenNode** | ~$0.001 (1 sat) | 1% | Instant (Lightning) or ~10min (on-chain) | Bitcoin micropayments, streaming | REST API, hosted checkout, payment button |
| **Stripe** | $0.50 | 2.9% + $0.30 (standard), 5% + $0.05 (micropayment) | 2-day | General e-commerce | Full API ecosystem |
| **PayPal Micropayments** | $0.01 | 5% + $0.05 | 1-3 day | Digital goods | PayPal API |
| **Lightning Network (direct)** | ~$0.001 (1 sat) | Near zero | Instant | Streaming payments, machine-to-machine | LND/CLN node, LNURL, Lightning addresses |
| **Hedera (HBAR)** | ~$0.001 | $0.0001 per transaction | 3-5 sec | Micropayments, stablecoins (USDC) | Hedera SDK, Dropp integration |

### Assessment for Xudanu

**Tier 1 — Best fit:**

1. **Lightning Network (direct integration)** — The closest thing to Ted Nelson's original vision. Transactions can be as small as 1 millisatoshi. Streaming payments (pay-per-byte-read) are native. Rust has excellent LDK (Lightning Dev Kit) support. Would enable "pay as you read" for transcluded content. **This is the most Xanadu-aligned option.**

2. **Dropp** — Purpose-built micropayment platform. Supports USD, USDC, and HBAR. Has a "streaming media" white paper. Instant settlement via RTP. Their pay-per-use model maps directly to our `cost()` + `retrieve()` flow. REST API is straightforward.

**Tier 2 — Good fit for specific use cases:**

3. **OpenNode** — If you want Bitcoin-only. Lightning-fast settlement. Good API. But limited to BTC — no fiat micropayments. Best for a "bitcoin-native Xanadu node."

4. **Hedera + USDC** — Stablecoin micropayments with sub-penny precision. Hedera's consensus mechanism is energy-efficient. USDC provides price stability. Could be integrated via Dropp's platform.

**Tier 3 — Possible but not ideal:**

5. **Stripe** — Great API, but their micropayment pricing (5% + $0.05) makes sub-$1 transactions expensive. Better for larger transactions (article purchases, subscriptions) than per-byte billing.

6. **PayPal Micropayments** — Similar fee structure to Stripe. Not designed for streaming or programmatic micropayments at scale.

### The "Pay Per Transclusion" Architecture

For a future integration, the flow would be:

```
                    ┌──────────────┐
                    │  Xudanu Node │
                    │  (Server)    │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼─────┐ ┌───▼────┐ ┌────▼──────┐
        │ cost()    │ │retrieve│ │ Transcl.  │
        │ accounting│ │ bundles│ │ Index     │
        └─────┬─────┘ └───┬────┘ └────┬──────┘
              │            │            │
              └────────────┼────────────┘
                           │
                  ┌────────▼─────────┐
                  │ Payment Gateway  │
                  │ (Lightning/Dropp)│
                  └────────┬─────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼─────┐      │      ┌────▼────┐
        │ Reader's  │      │      │ Author's│
        │ wallet    │      │      │ wallet  │
        └───────────┘      │      └─────────┘
                    ┌──────▼──────┐
                    │ Server fee  │
                    │ (hosting)   │
                    └─────────────┘
```

## Practical Next Steps

If we wanted to implement billing:

1. **Phase A: Accounting** (already done) — `cost()` with 3 methods, `retrieve()` for content access tracking, ownership tracking via Clubs
2. **Phase B: Quota System** — Per-Club storage quotas, usage dashboards, overage detection
3. **Phase C: Payment Integration** — Lightning Network or Dropp for micropayment settlement
4. **Phase D: Royalty Distribution** — Transclusion tracking → automatic royalty splits when content is accessed

The beauty of the Udanax Gold design is that Phase A (the hard part — tracking cost and ownership at the element level) is already built. The payment integration is "just" connecting a gateway to the accounting system.

## Historical Context

The term "micropayment" was coined by Ted Nelson in the 1960s as part of the Xanadu project. His original concept was specifically designed to:

- Pay the various copyright holders of a compound work (a document that transcludes from multiple sources)
- Enable fractions of a cent (as little as $0.0001)
- Provide an alternative to advertising revenue for content creators
- Make copyright automatic and royalty distribution transparent

The W3C even worked on incorporating micropayments into HTML in the late 1990s, going as far as suggesting embedding payment-request information in HTTP error codes. Those efforts were abandoned, and micropayments never became a web standard.

The irony is that Ted Nelson's 1960s vision for micropayments in hypertext is now technologically feasible (Lightning Network, stablecoins, instant bank settlement) but the market has moved on — advertising, subscriptions, and creator platforms (Patreon, Substack) have become the dominant monetization models instead.

However, for a system like Xudanu where **transclusion is the fundamental operation**, micropayments remain the only model that correctly incentives content creation and sharing. If your paragraph appears in 10,000 documents, you should receive 10,000 micro-royalties. No subscription or advertising model captures that.

---

## Deep Dive: Lightning Network via LDK

### Why Lightning is the Best Fit

The Lightning Network was designed for exactly the problem Xanadu has: **millions of tiny transactions that would be uneconomical on any traditional payment rail.** Key properties:

| Property | Lightning | Traditional (Stripe/PayPal) |
|----------|-----------|---------------------------|
| Minimum payment | 1 millisatoshi (~$0.0001) | $0.01–$0.50 |
| Settlement speed | Milliseconds to seconds | 1–3 days |
| Fee per transaction | Near zero (typically < 1 sat) | $0.05–$0.30 + percentage |
| Streaming payments | Native (hold invoices, keysend) | Not supported |
| Trust model | Trustless (cryptographic contracts) | Trusted intermediary |
| Privacy | Onion-routed, not linked to identity | Linked to identity/email |

### rust-lightning (LDK) — The Integration Path

**LDK (Lightning Dev Kit)** is a full Lightning Network implementation written in Rust. It is not a standalone node — it is a library that you embed in your application. This is exactly our architecture.

**Key facts:**
- Crate: `lightning` v0.2.2 on crates.io
- Repository: github.com/lightningdevkit/rust-lightning
- 11,291 commits, production-used since 2021
- Trusted by Cash App, Alby, Bitkit, Muun, and others
- MIT or Apache-2.0 dual license
- Supports `no_std` (embedded/WASM possible)

**Crate ecosystem:**

| Crate | Purpose |
|-------|---------|
| `lightning` | Core protocol, channel state machine, on-chain logic |
| `lightning-net-tokio` | Networking using Tokio async runtime (we already use Tokio) |
| `lightning-invoice` | BOLT11 invoice parsing/serialization |
| `lightning-persister` | Channel state persistence |
| `lightning-background-processor` | Background task management |
| `lightning-block-sync` | Blockchain data fetching |
| `ldk-node` | Higher-level wrapper that handles boilerplate |

**Recommended approach:** Use `ldk-node` rather than raw `lightning` crate. It handles channel management, chain synchronization, networking, and storage — letting us focus on the payment logic rather than Lightning internals.

### Concrete Integration Design

```
Cargo.toml:
  [features]
  lightning = ["ldk-node", "lightning-invoice"]

New module: src/server/payment/
  mod.rs          — PaymentGateway trait
  lightning.rs    — LDK-based implementation
  ledger.rs       — Internal accounting (who owes what)
  royalty.rs      — Transclusion royalty splitting

New protocol ops (0x0d01–0x0d08):
  0x0d01  wallet_balance        — Check node's Lightning balance
  0x0d02  create_invoice        — Generate BOLT11 invoice for payment
  0x0d03  pay_invoice           — Pay a Lightning invoice
  0x0d04  streaming_start       — Begin streaming payment for content access
  0x0d05  streaming_stop        — End streaming payment
  0x0d06  payment_history       — List payments sent/received
  0x0d07  set_lightning_address — Associate a Lightning address with a Club
  0x0d08  withdraw              — Withdraw earned funds to external wallet
```

### Pay-Per-Retrieve Flow with Lightning

```
1. Client connects, authenticates (existing flow)

2. Client requests edition_retrieve for a work:
   → Server calculates cost: 780 bytes
   → Server converts to millisatoshis: 780 msat (~$0.08 at $100k BTC)
   → Server checks: does client have a pre-funded channel?
     YES: deduct from channel balance, return bundles
     NO:  return a BOLT11 invoice for 780 msat

3. Client pays invoice (via their Lightning wallet):
   → Payment arrives at server's LDK node
   → Server releases bundles to client
   → Server records: reader paid 780 msat for work X

4. Royalty settlement (periodic):
   → Server looks up transclusion chain for work X
   → Original author Alice owns 60% of content
   → Server sends 468 msat to Alice's Lightning address
   → Server keeps 312 msat (40% hosting fee)
```

### Streaming Payments

Lightning supports **streaming payments** — continuous small payments over an open channel. This enables "pay as you read":

```
1. Client opens connection, requests streaming_start
2. Server begins sending bundles one at a time
3. After each bundle, server sends a payment request for that bundle's cost
4. Client pays (automatically via their wallet)
5. Server sends next bundle
6. When client disconnects or sends streaming_stop, session ends
```

This maps perfectly to our `retrieve()` + `cost()` system. Each Bundle has a byte cost, which maps to a millisatoshi price.

### Estimated Costs of Running an LDK Node

| Item | Cost | Notes |
|------|------|-------|
| Channel opening (on-chain tx) | ~$0.50–$5.00 | One-time per channel, pays Bitcoin miner fee |
| Channel capacity | Variable | You lock BTC in channels. 1 channel = 1M sats capacity (~$100) |
| Routing fees (receiving) | ~0.001% per payment | Near zero for receiving |
| Routing fees (sending) | ~1–10 sats per hop | Depends on route, typically negligible for micropayments |
| LSP (Lightning Service Provider) | $0–$5/month | Optional: provides inbound liquidity |
| Server infrastructure | Existing | LDK runs alongside the Xudanu server, no extra hardware |

**Minimum to start experimenting:** ~$50–$100 in BTC for channel capacity. Can use testnet (free) during development.

---

## Deep Dive: Stablecoins

### USDC on Lightning (Taproot Assets)

Since 2024, USDC can be transmitted over Lightning using the Taproot Assets protocol. This gives dollar-denominated micropayments with Lightning's speed and low fees.

**Status:** Functional but early ecosystem. Wallet support is limited (primarily Lightning wallets that have opted in). Not yet "send USDC to any Lightning address" seamless.

**Integration complexity:** Higher than pure BTC Lightning. Requires Taproot Assets daemon alongside LDK.

### Hedera (HBAR) + USDC

Hedera Hashgraph is purpose-built for high-frequency micropayments:

| Property | Value |
|----------|-------|
| Transaction fee | $0.0001 fixed |
| Settlement | 3–5 seconds finality |
| Throughput | 10,000+ TPS |
| Smart contracts | Solidity-compatible (Ethereum-like) |
| USDC support | Native (issued by Circle) |
| Rust SDK | Available (hedera-sdk-rust) |

**Integration path:** Dropp already built on Hedera. Their REST API could be our fiat/stablecoin gateway without us needing to run any blockchain infrastructure ourselves.

**Cost to try:** Free — Hedera has a testnet with free test HBAR. Dropp has a sandbox environment.

### Circle USDC API (direct)

Circle (USDC issuer) provides direct APIs for programmable wallets and payments. Could be used for server-to-server USDC transfers without any blockchain node:

| Property | Value |
|----------|-------|
| Minimum transfer | $0.01 |
| Fee | Free (Circle subsidizes gas on supported chains) |
| Settlement | Seconds (on Solana, Polygon, Base) |
| API | REST, well-documented |
| Rust SDK | No official Rust SDK; use REST directly via reqwest |

---

## Comparative Cost Analysis: Trying Each Option

### Option A: Lightning Network (LDK)

**Setup effort:** Medium (2–3 weeks for basic integration)
**Ongoing cost:** ~$50–$100 in locked BTC for channels
**Development cost:** Free (testnet)
**User requirements:** Lightning wallet (Phoenix, Mutiny, Alby, Cash App)

**Prototype path:**
1. Add `ldk-node` as optional dependency (1 day)
2. Implement `PaymentGateway` trait with LDK backend (1 week)
3. Add `create_invoice` + `pay_invoice` server ops (2 days)
4. Wire into `edition_retrieve` with paywall (2 days)
5. Test on Bitcoin testnet (ongoing)

### Option B: Dropp (fiat/stablecoin micropayments)

**Setup effort:** Low (1 week for basic integration)
**Ongoing cost:** Transaction fees only (~1% + $0.05)
**Development cost:** Free (sandbox)
**User requirements:** Dropp wallet (mobile app or web)

**Prototype path:**
1. Register as Dropp merchant (1 hour)
2. Implement REST client for Dropp API (2 days)
3. Add payment ops to server protocol (1 day)
4. Wire into `edition_retrieve` with paywall (2 days)
5. Test in sandbox environment (ongoing)

### Option C: OpenNode (Bitcoin-only, simpler than LDK)

**Setup effort:** Low (3–5 days)
**Ongoing cost:** 1% transaction fee
**Development cost:** Free (test mode)
**User requirements:** Any Bitcoin wallet

**Prototype path:**
1. Register as OpenNode merchant (1 hour)
2. Implement REST client (1 day)
3. Add payment ops (1 day)
4. Wire paywall (2 days)
5. Test in development mode

### Option D: Stripe (fallback, not true micropayments)

**Setup effort:** Low (2–3 days, most documentation)
**Ongoing cost:** 5% + $0.05 per micropayment
**Development cost:** Free (test mode)
**User requirements:** Credit card or bank account

**Trade-off:** Works for per-article payments ($0.50–$5.00) but not for per-byte or per-bundle micropayments. The $0.05 floor makes a 780-byte bundle cost at least $0.05 regardless of content value.

### Recommendation: Start with LDK on Testnet

LDK gives us the most Xanadu-aligned capabilities (streaming payments, millisatoshi precision) and the best Rust integration story. Testnet is free. We can always add Dropp or OpenNode as alternative gateways later.

---

## Security Considerations

### Lightning Network Security

| Risk | Mitigation |
|------|------------|
| **Channel force-close** — counterparty broadcasts old state | LDK stores revocation data; honest nodes always win on-chain. Persist channel state reliably. |
| **Private key exposure** — keys in server memory | LDK supports external key management (VSS/HSM). For production, use a hardware signer or at minimum encrypted at-rest storage. |
| **Routing attacks** — payment intercepted or delayed | Lightning uses onion routing; payments are atomic (HTLC). Either the full payment arrives or none does. |
| **Channel exhaustion (griefing)** — attacker opens many channels to drain liquidity | Implement rate limiting on channel opens. Use LSP for inbound liquidity management. |
| **Invoice replay** — same invoice paid twice | BOLT11 invoices include payment hash + expiry. Each invoice is single-use by design. |
| **Node uptime requirements** — channel monitoring | LDK's `lightning-background-processor` watches for fraudulent channel closes. Server must have reliable uptime, or outsource watchtower service. |

### Server-Side Security

| Risk | Mitigation |
|------|------------|
| **Payment bypass** — client retrieves content without paying | Gate `edition_retrieve` behind payment verification. Server tracks paid vs. unpaid sessions. Never release bundles before payment confirms. |
| **Account manipulation** — client spoofs balance | Server maintains authoritative ledger. Payment state comes from LDK node, not from client claims. |
| **Royalty theft** — server operator doesn't distribute royalties | Royalty distribution must be auditable. Consider publishing a royalty report (transparent by design, per Xanadu principles). |
| **Cost manipulation** — server inflates byte costs | Cost calculation is deterministic and auditable. Client can independently verify `cost()` output against `retrieve()` bundle sizes. |
| **Double-spend on content** — pay once, redistribute content | This is the content redistribution problem. Mitigations: watermarks, rate limits, or accept that content once released can't be recalled (Xanadu's original stance). |

### Data Exposure Risks

| Risk | Mitigation |
|------|------------|
| **Traffic analysis via cost()** — an observer learns which Editions share content by watching billing patterns | The C++ code explicitly notes this risk. Consider adding noise to cost reports, or batching settlements. |
| **Payment metadata** — Lightning invoices reveal amount and (potentially) recipient | Use BOLT12 offers (supported by LDK) for recipient privacy. Amounts can be masked with hold invoices. |
| **Transclusion graph exposure** — royalty distribution reveals who transcluded whom | Aggregate royalties before distribution. Don't reveal individual transclusion events; only reveal total earned per period. |

### Operational Security

| Risk | Mitigation |
|------|------------|
| **Hot wallet on server** — server compromise drains Lightning funds | Keep minimal balance in hot wallet. Use cold storage for accumulated earnings. Implement withdrawal thresholds. |
| **Channel backup failure** — lost channel state = lost funds | LDK provides `lightning-persister` for encrypted channel state backups. Must back up on every state change. Consider cloud backup (S3) with encryption. |
| **Fee spikes** — Bitcoin network fees spike, making channel operations expensive | Monitor mempool fee rates. Batch channel opens/closes. Use fee estimation in LDK. |
| **Regulatory exposure** — operating a payment service has legal implications | Lightning is peer-to-peer, not custodial (if implemented correctly). Don't custody user funds — payments go directly between Lightning wallets. Consult a lawyer for your jurisdiction. |

---

## Feature Flag Architecture

To keep the core Xudanu server unencumbered, all payment functionality should be behind feature flags:

```toml
# Cargo.toml

[features]
default = []
serde = ["dep:serde", "dep:serde_json"]
server = ["dep:tokio", "dep:axum", "dep:tower-http"]
wasm = ["dep:wasm-bindgen"]

# Payment features (independent, can combine)
lightning = ["dep:ldk-node", "dep:lightning-invoice"]
dropp = ["dep:reqwest", "dep:hmac", "dep:sha2"]
stripe = ["dep:reqwest"]
```

This means:
- `cargo build` — core library only (no server, no payments)
- `cargo build --features server` — server without payments
- `cargo build --features "server,lightning"` — server with Lightning payments
- `cargo build --features "server,lightning,dropp"` — server with multiple payment gateways
- `cargo test --features "serde,serde_json,server,lightning"` — full test suite including payment tests

### Payment Gateway Trait

```rust
// src/server/payment/mod.rs

pub trait PaymentGateway: Send + Sync {
    fn create_invoice(&self, amount_msat: u64, description: &str) -> Result<Invoice, PaymentError>;
    fn check_payment(&self, payment_hash: &str) -> Result<PaymentStatus, PaymentError>;
    fn send_payment(&self, invoice: &str, max_fee_msat: u64) -> Result<PaymentResult, PaymentError>;
    fn get_balance(&self) -> Result<BalanceInfo, PaymentError>;
    fn get_new_address(&self) -> Result<String, PaymentError>;
    fn withdraw(&self, address: &str, amount_msat: u64) -> Result<(), PaymentError>;
}
```

Each backend (`lightning.rs`, `dropp.rs`, `stripe.rs`) implements this trait. The server dispatches to whichever gateway(s) are compiled in.

---

## Summary: The Case for Lightning + LDK

1. **Technically perfect match** — millisatoshi precision, streaming payments, instant settlement, Rust-native library
2. **Philosophically aligned** — Ted Nelson envisioned exactly this: fractions of a cent flowing automatically to content creators
3. **Architecturally clean** — feature-flagged, trait-based, no coupling to core server
4. **Free to develop** — Bitcoin testnet, LDK is open source
5. **Low ongoing cost** — near-zero transaction fees, ~$50–$100 in locked BTC to start
6. **Privacy-preserving** — onion-routed payments, no identity required to pay
7. **Extensible** — can add Dropp/Stripe as fiat on-ramps later for users who don't want BTC

**The main barriers:**
- Users need a Lightning wallet (but adoption is growing rapidly)
- Channel management adds operational complexity
- BTC price volatility affects pricing (can be mitigated with real-time sat/byte conversion)
- Regulatory uncertainty in some jurisdictions

**Next concrete step:** Add `ldk-node` as an optional dependency, implement the `PaymentGateway` trait on testnet, wire up `create_invoice` + `check_payment` into the server protocol, and test the pay-per-retrieve flow end-to-end.
