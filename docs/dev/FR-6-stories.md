# FR-6 Implementation Stories

Ordered for progressive learning — each story builds on the previous one.

---

## Story 1: Server Identity Endpoint

**As a** server operator
**I want** my server to publish its identity at a standard URL
**So that** other servers can discover and verify it

### Acceptance Criteria
- `GET /.well-known/xudanu-server.json` returns a JSON document with:
  - `server_id` (the local server's number in the tumbler namespace)
  - `address` and `port`
  - `verifying_key_ed25519` (the server's public signing key)
  - `name` (operator-configurable display name)
  - `description` (operator-configurable)
  - `public_content: true`
  - `started_at` timestamp
  - `stats` (work count, revision count)
- The endpoint requires no authentication (it's public)
- Server ID is assigned at init time (stored in manifest)
- If no server ID is set, one is generated from the first 4 bytes of the verifying key

### What you learn
- How Ed25519 server identity works
- The well-known endpoint pattern (like `robots.txt`)
- That identity is just a published public key — no central authority

### Files touched
- `server/transport/handler.rs` — add route
- `server/server.rs` — expose identity data

---

## Story 2: Server Directory

**As a** server operator
**I want** to maintain a local list of known servers
**So that** I can resolve tumbler addresses and reference external content

### Acceptance Criteria
- A `server_directory.json` file in the data directory stores known servers
- Each entry has: `server_id`, `address`, `port`, `verifying_key`, `name`, `trusted` (bool), `discovered` (method), `last_seen`
- Wire protocol operations:
  - `server_directory_list` — returns all known servers
  - `server_directory_add` — manually add a server by URL (fetches well-known endpoint)
  - `server_directory_remove` — remove a server entry
  - `server_directory_set_trust` — toggle trust on/off
- Adding a server by URL triggers a fetch of `/.well-known/xudanu-server.json`
- The directory is checkpointed to disk (like clubs and works)

### What you learn
- The local-state model: each server has its own view of the network
- That "joining" is just adding an entry to a local file — no protocol, no consensus
- How trust is a binary per-server decision, not a global property

### Files touched
- `server/server.rs` — ServerDirectory struct + persistence
- `server/transport/protocol.rs` — wire operations
- `server/transport/dispatch.rs` — handlers
- `persist/manifest.rs` — checkpoint directory entries

---

## Story 3: Public Content Read API

**As a** client on another server
**I want** to fetch public content from this server via HTTP
**So that** I can resolve tumbler references to content hosted here

### Acceptance Criteria
- `GET /api/public/work/<work_id>` returns the current edition of a public work as JSON
- `GET /api/public/work/<work_id>/edition/<n>` returns a specific revision
- `GET /api/public/work/<work_id>/range/<start>/<end>` returns a text range
- Response includes:
  - Edition text (or range)
  - BLAKE3 content hash
  - Span provenance (signed)
  - Server signature over the response payload
- Non-public works return 404 (no information leak)
- No authentication required (public content only)
- Rate-limited per IP

### What you learn
- The read-only boundary: other servers can only see public content
- That content is always served with its signature — verifiable offline
- How BLAKE3 hashes enable content verification without trust

### Files touched
- `server/transport/handler.rs` — public read routes
- `server/server.rs` — public edition accessor

---

## Story 4: Reference Manifest in Links

**As a** user creating a transclusion from external content
**I want** the link to store the full reference data
**So that** the reference survives even if the origin server goes offline

### Acceptance Criteria
- When creating a link/transclusion to content from another server, the `HyperRef` stores:
  - `tumbler: String` — full tumbler address (e.g., `"2.5.3.10.7"`)
  - `origin_server_id: u64` — the server number (extracted from tumbler)
  - `content_hash: [u8; 32]` — BLAKE3 of the referenced content
  - `excerpt: String` — the text at time of reference (permanent cache)
  - `origin_author: String` — author display name on origin server
  - `origin_author_key: [u8; 32]` — author's public key
  - `origin_server_sig: Vec<u8>` — origin server's Ed25519 signature
  - `fetched_at: u64` — timestamp of fetch
- These fields are persisted in the manifest and link metadata
- Existing link creation flow is extended (not replaced)

### What you learn
- The reference manifest is the "proof" that content existed at a point in time
- How BLAKE3 hashes create permanent, verifiable references
- That excerpts are permanent caches, not temporary data

### Files touched
- `edition/links.rs` — extend HyperRef with reference manifest fields
- `server/server.rs` — populate fields during link creation
- `persist/manifest.rs` — persist new fields

---

## Story 5: Cross-Server Content Resolution

**As a** user opening a document with a cross-server transclusion
**I want** the transclusion to resolve and display inline
**So that** I can read the referenced content seamlessly

### Acceptance Criteria
- Client detects when a link/transclusion has a tumbler with a non-local server ID
- Resolution order:
  1. Check local content cache (blob store by BLAKE3 hash)
  2. If not cached, fetch from origin server via public API
  3. Verify BLAKE3 hash of fetched content matches stored hash
  4. Verify origin server's Ed25519 signature
  5. Cache in blob store
  6. Render inline
- If fetch fails (network error, 404), fall back to stored excerpt
- Display a visual indicator on cross-server transclusions (e.g., subtle border)
- Tooltip shows: origin server name, tumbler address, author, fetch status

### What you learn
- The fetch → verify → cache → render loop
- That every step has a fallback (cache, excerpt, placeholder)
- How BLAKE3 + Ed25519 create trustless verification

### Files touched
- `web/app/src/api/crdt_sync.ts` — cross-server fetch client
- `web/app/src/hooks/useTransclusion.ts` — resolution logic
- `web/app/src/components/CollaborativeEditor.tsx` — rendering
- `server/server.rs` — content cache lookup

---

## Story 6: Offline Resilience

**As a** user reading a document when the origin server is offline
**I want** the transclusion to still display
**So that** my document remains readable

### Acceptance Criteria
- When origin server is unreachable:
  - Cached content in blob store renders with "cached from Server N (offline)" indicator
  - If no cache: stored excerpt renders with "cached excerpt (Server N offline)" indicator
  - If no excerpt: placeholder shows metadata (title, author, tumbler)
- When origin server comes back online:
  - Client re-fetches on next document open
  - If content hash matches: silently update cache (no visible change)
  - If content hash differs: show "original version cached, newer edition available on Server N"
- Background retry: every 5 minutes while document is open, attempt re-fetch
- Visual states: green (live), amber (cached/offline), red (unavailable)

### What you learn
- How the three-tier cache (excerpt → content cache → session) provides layered resilience
- That cached excerpts are permanent proof of content existence
- How content-addressed storage enables offline-first design

### Files touched
- `web/app/src/hooks/useTransclusion.ts` — offline fallback logic
- `web/app/src/components/CollaborativeEditor.tsx` — visual indicators
- `web/app/src/components/TransclusionBadge.tsx` — status display

---

## Story 7: Cross-Server Provenance Chain

**As a** reader examining a cross-server transclusion
**I want** to see the full provenance chain
**So that** I can verify who wrote the original content and who transcluded it

### Acceptance Criteria
- Attribution panel shows the full chain for cross-server content:
  ```
  Span [100, 150): "The whale represents..."
  ├─ Transcluded by: Alice (Server 1, key efdf23c4...)
  ├─ Origin: tumbler 2.5.3.10.7
  ├─ Author: Bob (Server 2, key 9a8b7c6d...)
  ├─ Signed: Server 2 Ed25519 ✓ verified
  └─ Fetched: 2026-07-05, cached
  ```
- `signature_valid` is computed independently:
  - Verify origin server's signature against stored content hash
  - Verify local server's signature on the transclusion action
- PROV-JSON export includes `wasDerivedFrom` with tumbler address
- Clicking "verify" runs `xudanu-cli verify-report` logic inline

### What you learn
- How per-server provenance chains compose across boundaries
- That verification is independent of trust — you check math, not reputation
- How PROV-JSON's `wasDerivedFrom` represents cross-server derivation

### Files touched
- `web/app/src/components/AttributionPanel.tsx` — provenance chain display
- `web/app/src/components/panels/AttributionSection.tsx` — compact view
- `server/server.rs` — provenance chain resolution

---

## Story 8: Trust Management

**As a** server operator
**I want** to manage which servers I trust
**So that** I can control whether cross-server content is verified or flagged

### Acceptance Criteria
- Settings panel in the UI: "Known Servers" section
  - Lists all servers in the directory
  - Each row: name, address, trust toggle, last seen, work count
  - "Add Server" button: enter URL, fetches well-known endpoint, adds to directory
  - "Remove" button per server
  - "Trust" toggle per server (default: untrusted for new servers)
- Content from untrusted servers displays with a warning banner:
  ```
  ⚠ UNVERIFIED: Content from Server 99 (unknown.example.com)
  This server is not in your trusted registry.
  [Trust this server]  [Show anyway]  [Hide]
  ```
- Content from trusted servers: verified silently, green indicator
- TrustedServerRegistry is updated when trust is toggled

### What you learn
- That trust is a local, reversible decision — not a global property
- How the TrustedServerRegistry (already built) connects to the UI
- That untrusted content is still visible — just flagged

### Files touched
- `web/app/src/components/shell/AppShell.tsx` — settings modal
- `web/app/src/components/ServerDirectoryPanel.tsx` — new component
- `server/server.rs` — trust toggle API
- `crypto/server_identity.rs` — registry integration

---

## Story 9: Discovery via Referral

**As a** user following a transclusion chain
**I want** to automatically discover new servers
**So that** I don't have to manually add every server in the network

### Acceptance Criteria
- When resolving a transclusion, if the origin server is not in the local directory:
  1. If the referencing server (the one that created the link) is in the directory, fetch its well-known endpoint
  2. Check if it references the origin server in its directory
  3. Add the origin server to the local directory with `discovered: "referral"` and `trusted: false`
  4. Attempt to fetch the origin server's well-known endpoint for verification
- Referral chains: Server 1 → Server 2 → Server 3 (follow up to 2 hops)
- Discovered servers are untrusted by default (operator must approve)
- Settings panel shows a "Pending Discovery" section for newly discovered servers
- Clicking a discovered server shows: who referred it, when, what content triggered it

### What you learn
- How organic network growth works (like the web — you discover by following links)
- That referral ≠ trust (referrals help discovery, not verification)
- How the network scales to hundreds of servers without a central directory

### Files touched
- `web/app/src/hooks/useTransclusion.ts` — referral logic
- `server/server.rs` — referral recording
- `web/app/src/components/ServerDirectoryPanel.tsx` — pending section

---

## Story 10: Mothball FR-3 Cluster

**As a** server operator
**I want** the cluster federation mechanism disabled by default
**So that** I don't accidentally expose my server to cluster security risks

### Acceptance Criteria
- Federation cluster (FR-3) is behind a `--enable-cluster` CLI flag (default: off)
- When cluster is disabled:
  - `/federation` WebSocket endpoint returns 404
  - No outbound dialer tasks are spawned
  - No federation frames are processed
  - `federation_is_peer_known` always returns `false`
  - All federation sync/import methods return `Err(ServerError::FeatureDisabled)`
- When cluster is enabled (`--enable-cluster`):
  - Existing FR-3 behavior works as before
  - Startup log shows: "WARNING: Cluster federation enabled. See federation-trust-analysis.html for security risks."
- Documentation updated:
  - FR-3 marked as "Advanced — not recommended for most deployments"
  - FR-6 is the default multi-server model
  - AGENTS.md updated to reflect the new default
- The `/federation` route is not registered unless cluster is enabled

### What you learn
- How to safely deprecate a subsystem without removing it
- Feature flags as a security boundary (opt-in for dangerous features)
- That defaults matter: secure-by-default vs. feature-available

### Files touched
- `bin/xudanu-server.rs` — CLI flag, conditional route registration
- `server/transport/handler.rs` — conditional `/federation` route
- `server/server.rs` — feature gate on federation methods
- `server/federation.rs` — feature gate on state
- `AGENTS.md` — update documentation

---

## Implementation Order Summary

| # | Story | Effort | Depends on | User-visible? |
|---|-------|--------|------------|---------------|
| 1 | Server Identity Endpoint | ~2h | — | No (infrastructure) |
| 2 | Server Directory | ~4h | 1 | No (infrastructure) |
| 3 | Public Content Read API | ~3h | — | No (infrastructure) |
| 4 | Reference Manifest in Links | ~4h | 2 | No (data model) |
| 5 | Cross-Server Resolution | ~6h | 2, 3, 4 | **Yes — first cross-server transclusion** |
| 6 | Offline Resilience | ~4h | 5 | Yes — offline indicators |
| 7 | Provenance Chain | ~4h | 5 | Yes — provenance display |
| 8 | Trust Management UI | ~4h | 2 | Yes — settings panel |
| 9 | Discovery via Referral | ~4h | 5, 8 | Yes — auto-discovery |
| 10 | Mothball FR-3 | ~3h | 5 | Yes — `/federation` gone |

**Total: ~38 hours** (roughly 1 week of focused work)

### Milestones

- **Milestone 1 (Stories 1-3):** Foundation — servers can identify themselves and serve public content. No user-visible change yet, but the infrastructure is in place.
- **Milestone 2 (Stories 4-5):** First cross-server transclusion — the "aha" moment. Alice on Server 1 can transclude content from Bob on Server 2.
- **Milestone 3 (Stories 6-7):** Production-ready — works offline, shows full provenance chains. Ready for real use.
- **Milestone 4 (Stories 8-9):** Security & scale — trust management, auto-discovery. Handles hostile servers and hundreds of machines.
- **Milestone 5 (Story 10):** Cleanup — mothball the cluster. FR-6 is the default.
