# Xudanu Network Plan: Tumbler-Based Cross-Server Content Sharing

## Vision

A docuverse of independent Xudanu servers connected by permanent, cryptographically verified, attribution-preserving references — using the tumbler addressing system inherited from Udanax-Gold.

Each server is sovereign. Content stays on its origin server. References (tumblers) travel between servers. When a user opens a cross-server reference, their server fetches the content from the origin, verifies it cryptographically, and caches it locally.

This is NOT federation (shared database). This is the Xanadu model: independent servers, global addresses, pull-based resolution.

---

## Tumbler Format

```
"server.domain".work.edition.position.element
```

| Part | Meaning | Example |
|------|---------|---------|
| `"server.domain"` | Domain name of the origin server (DNS-routable) | `"alice.xudanu.com"` |
| work | Work ID on that server (hex) | `5` |
| edition | Edition/revision number | `3` |
| position | Character offset within the edition | `10` |
| element | Element within a multi-element position | `7` |

**Example:** `"alice.xudanu.com".5.3.10.7`

The domain replaces the original numeric server ID. DNS provides self-routing — no central registry needed. Numeric IDs still supported for private networks via the server directory.

**Already implemented:** `parse_tumbler_server()` and `tumbler_local_path()` in `edition/links.rs:331-360`.

---

## What's Already Built

| Component | Status | Location |
|-----------|--------|----------|
| Tumbler parsing (domain + numeric) | Done | `edition/links.rs:331-360` |
| `CrossServerRef` struct (12 fields) | Done | `edition/links.rs:311-324` |
| `CrossServerRefPayload` (wire format, hex-encoded) | Done | `transport/protocol.rs:2854-2874` |
| Persistence through checkpoint/WAL/restore | Done | `HyperRefPayload.cross_server_ref` |
| Well-known endpoint (`/.well-known/xudanu-server.json`) | Done | `transport/handler.rs:115-129` |
| Public content API (`/api/public/work/{id}`) | Done | `transport/handler.rs:131-157` |
| Server directory (add/remove/trust/persist) | Done | `server/server_directory.rs` |
| Cross-server resolution (fetch + BLAKE3 verify + cache) | Done | `server/server.rs:1126-1227` |
| HTTPS support for fetches | Done | `server/server.rs:27673-27744` |
| CLI flags (`--public-address`, `--server-name`, etc.) | Done | `bin/xudanu-server.rs` |
| Frontend: cross-server link creation | Done | `LinkCreator.tsx` |
| Frontend: `CrossServerRefPayload` types | Done | `crdt_sync.ts` |

---

## What's Missing (the plan)

### Phase 1: End-to-End Testing (Day 1)

**Goal:** Prove two servers can reference each other's content.

1. **Docker test network** — two Xudanu servers on separate ports with separate data dirs
   - Server A: `--public-address alice.local --server-name "Alice's Server" --server-namespace-id 1`
   - Server B: `--public-address bob.local --server-name "Bob's Server" --server-namespace-id 2`
   - Each publishes content via the public API

2. **Manual cross-server link** — from Server B, create a link to content on Server A
   - User enters tumbler: `"alice.local".5.3.0.0`
   - User enters BLAKE3 hash (from Server A's public API)
   - Link created with `CrossServerRef`

3. **Content resolution** — when user on Server B opens the link
   - Server B fetches `http://alice.local:8080/api/public/work/5`
   - Verifies BLAKE3 hash matches stored hash
   - Caches in blob store
   - Displays resolved text with provenance

4. **Verify** — content from A appears on B, with attribution to A's author

### Phase 1.5: Cross-Server Backlinks (Day 1.5)

**Goal:** When Server B links to content on Server A, Server A automatically knows. Makes the network bidirectional — every connection visible from both ends, as Ted Nelson designed.

11. **Backlink notification endpoint** — new public API on every server:
    ```
    POST /api/backlink-notify
    Content-Type: application/json
    
    {
        "target_tumbler": "\"127.0.0.1:8081\".03ed.1.0.0",
        "origin_server_address": "127.0.0.1:8082",
        "origin_server_name": "Bob's Server",
        "origin_work_id": "03ee",
        "origin_work_title": "server 8082",
        "excerpt": "server 8082",
        "link_type": "cross-server",
        "origin_server_signature": "<Ed25519 signature of the notification JSON>"
    }
    ```

12. **Server B sends notification** — after `linkCreateCrossServer` succeeds:
    - Server B signs the notification with its Ed25519 server key
    - POSTs to `{target_server}/api/backlink-notify`
    - Fire-and-forget (best effort) — if Server A is offline, skip
    - Log the attempt for retry/diagnostics

13. **Server A receives and stores** — on receiving a backlink notification:
    - Verify Ed25519 signature against the origin server's known key (TOFU)
    - If origin server unknown: fetch `/.well-known/xudanu-server.json`, add to directory as untrusted
    - Store in a `cross_server_backlinks: Vec<CrossServerBacklink>` on the Server struct
    - Persist in the SocialSection chunk (survives checkpoint/restore)
    - Rate limit: max 100 backlinks per origin server per hour

14. **Display incoming cross-server references** — on Server A's work:
    - Right-margin bar indicating incoming cross-server reference
    - Connections panel: "← Referenced by Bob's Server" with cyan border
    - Tooltip: shows origin server name, address, excerpt
    - Click: opens a modal showing the remote server's work (via public API fetch)

15. **Frontend: trigger cross-server resolution** — when user clicks a cross-server link marker:
    - Send `cross_server_resolve { tumbler, content_hash_hex }` to the server
    - Server fetches from origin, verifies BLAKE3, returns text
    - Display resolved text in a read-only modal or inline view

### Phase 2: Server Directory UI (Day 2)

**Goal:** Users can manage known servers from the UI.

16. **Settings panel** — "Network" section in the settings dialog
   - List of known servers (from `server_directory.json`)
   - Add server by address (fetches `/.well-known/xudanu-server.json`)
   - Remove server
   - Toggle trust (trusted vs untrusted)
   - Show server name, description, verifying key, work count

17. **Server directory wire ops** — already implemented:
   - `ServerDirectoryAdd` (0x0F01)
   - `ServerDirectoryRemove` (0x0F02)
   - `ServerDirectoryList` (0x0F03)
   - `ServerDirectoryTrust` (0x0F04)
   - `ServerDirectoryResolve` (0x0F05)

18. **Frontend client methods** — add to `crdt_sync.ts`:
   - `serverDirectoryAdd(address, port?)`
   - `serverDirectoryRemove(serverId)`
   - `serverDirectoryList()`
   - `serverDirectoryTrust(serverId, trusted)`

### Phase 3: Content Discovery (Day 3)

**Goal:** Users can browse content on other servers.

19. **Remote content browser** — in the library panel
   - Select a trusted server from the directory
   - Fetch `/api/public/work/{id}` for each public work
   - Display remote works in a "Remote" section
   - Click a remote work to view its content (read-only)

20. **Cross-server search** — search across trusted servers
   - Query each trusted server's text search endpoint
   - Merge results, tagged with origin server

21. **Content import** — from remote browser
    - Transclude remote content into a local document
    - Automatically creates `CrossServerRef` with fetched hash

### Phase 4: Byte Tracking & Royalties (Day 4)

**Goal:** Track cross-server traffic for monitoring and future micropayments.

22. **Hook `record_royalty` into `resolve_cross_server_ref`**
    - When content is fetched from a remote server, record:
      ```
      RoyaltyEntry {
          origin_server_id: remote_server_id,
          content_fingerprint: blake3_hash,
          royalty_type: RoyaltyType::Access,
          amount: byte_size,
          timestamp: now(),
      }
      ```
    - Already persisted in `FederationSection` chunk via `royalty_ledger`

23. **Traffic dashboard** — in settings panel
    - Per-server byte counts (sent/received)
    - Per-content-fingerprint access counts
    - Timeline of cross-server fetches

### Phase 5: Referral Discovery (Day 5)

**Goal:** Network grows organically through references.

24. **Referral propagation** — when resolving a cross-server ref
    - If the origin server's `/.well-known/xudanu-server.json` lists other known servers
    - Add them to the local directory with `discovered: "referral"` and `referred_by: origin_server_id`
    - User sees them in the directory UI as "Discovered via Server A"

25. **Server graph visualization** — force-directed graph
    - Nodes = servers in directory
    - Edges = cross-server references between them
    - Click a server to browse its content

---

## Security Model

### Three-Layer Verification (designed, partially implemented)

| Layer | What | How | Status |
|-------|------|-----|--------|
| Tumbler | WHERE content lives | Domain-based global address | Done |
| BLAKE3 | WHAT the content is | Hash verified on every fetch | Done |
| Ed25519 | WHO authored it | Server signature on well-known endpoint | **NOT ENFORCED** — signature field exists but `resolve_cross_server_ref` does not verify it |

### Security Fixes Required (before Phase 1 testing)

These must be fixed before any real cross-server testing:

1. **Enforce Ed25519 in resolution path** — `resolve_cross_server_ref` must call `is_server_trusted` / `verify_server_identity` before fetching, and reject if the server is not in the trusted directory.

2. **HTTPS-only for trust material** — `server_directory_add` must fetch `/.well-known/xudanu-server.json` over HTTPS only. HTTP is self-defeating for trust anchor transport. Add `--allow-insecure-discovery` flag for LAN testing.

3. **HTTPS default for content fetches** — `resolve_cross_server_ref` must default to HTTPS. Add `--allow-insecure-cross-server` flag for private/LAN test networks only.

4. **SSRF protection** — `resolve_cross_server_ref` must reject tumblers pointing to loopback (127.0.0.0/8, ::1), link-local (169.254.0.0/16), private ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16), and hostnames not in the trusted server directory.

5. **Hard byte caps** — Add a max size limit (e.g., 5MB) on both the public API response (`public_work_edition`) and the fetch read buffer in `http_get_json`.

6. **Trust gate** — `resolve_cross_server_ref` must check `directory_entry.trusted` and reject/warn for untrusted servers. Untrusted servers should not auto-resolve.

7. **API version field** — Add `api_version: 1` to the public work JSON response so future format changes are detectable.

8. **Async resolution** — Move `resolve_cross_server_ref` to `spawn_blocking` or async to avoid blocking the dispatch path for up to 15s.

### Threats & Mitigations (updated)

| Threat | Mitigation | Status |
|--------|-----------|--------|
| **Man-in-the-middle** during fetch | HTTPS default (rustls + webpki-roots); HTTP opt-in only for LAN | **Needs fix** (currently HTTP default) |
| **Content tampering** on origin server | BLAKE3 hash mismatch → reject | Done |
| **Spoofed server** (fake well-known) | Ed25519 verifying key fetched over HTTPS; key pinned in directory | **Needs fix** (currently HTTP, key not verified) |
| **SSRF** (server fetches internal endpoints) | Reject private/loopback IPs; require directory membership | **Needs fix** (no validation currently) |
| **Untrusted server** in directory | Resolution blocked; UI shows "UNVERIFIED" warning | **Needs fix** (trust not enforced) |
| **DDoS via cross-server refs** | Rate limit fetches per server; blob cache; byte caps; async resolution | Cache done, rest needs impl |
| **Stale content** (origin updated) | Hash pins exact version; user sees "content updated" notification | Hash check done; notification needed |
| **Memory exhaustion** (large payloads) | Hard byte cap on fetches (5MB default) | **Needs fix** (no cap currently) |
| **Blocking dispatch** (slow origins) | `spawn_blocking` for cross-server fetches | **Needs fix** (currently synchronous) |
| **Privacy leak** (origin sees requester IP) | Server-to-server fetch; no user identity sent; consider relay/proxy for future | Architecture supports this |
| **Copyright** (operator hosts cached copies) | Public club = implicit redistribution grant; operator responsible for published content; cached blobs subject to takedown | Needs documentation + abuse contact in well-known |

### Trust Model

- **Per-server, independent** — no global trust state, no consensus
- **Operator-controlled** — server operator decides which servers to trust
- **Default: untrusted** — new servers appear with "UNVERIFIED" until operator trusts them
- **No automatic trust** — trust is a deliberate act by the operator

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **DNS hijacking** of domain tumblers | Low (HTTPS + Ed25519) | High | Certificate transparency + key pinning in directory |
| **Server goes offline** — content unreachable | Medium | Medium | Blob cache retains last-known-good copy; excerpt in link metadata is permanent proof. Cache only populated after successful first resolve — if origin is down on first access, only excerpt available. |
| **Cache eviction** — cross-server blobs GC'd | Medium | Medium | Define retention contract: cross-server blobs should not be GC'd (they are permanent proof of the reference). Needs explicit GC protection. |
| **Hash collision** (BLAKE3) | Negligible | High | BLAKE3 has no known collisions; 256-bit hash space |
| **Network partition** — servers can't reach each other | Medium | Low | Cached content still available; links show "origin offline" |
| **Large content fetch** — 100K+ word document | Medium | Medium | Range API already implemented; fetch only needed span; 5MB byte cap |
| **Byte accumulation** for bandwidth tracking | High (pessimistic) | Low | `RoyaltyEntry` stores amounts; operator can monitor and set limits |
| **Server directory poisoning** — malicious entries | Low | Medium | Operator approves each entry; referral entries marked as untrusted; HTTPS for discovery |
| **SSRF** — tumbler points to internal network | High (if exposed) | High | Reject private/loopback IPs; require directory membership (Phase 0 fix) |
| **Memory exhaustion** — hostile large payloads | Medium | High | 5MB byte cap on fetches (Phase 0 fix) |
| **Blocking dispatch** — slow origins tie up server | Medium | Medium | `spawn_blocking` for cross-server fetches (Phase 0 fix) |
| **Retroactive signature enforcement** | Low (planned) | Medium | Existing refs with empty sigs get "unverified" status; re-fetch-and-sign migration when enabled |
| **Public API format change** | Low (future) | Medium | `api_version` field allows graceful degradation |

---

## Operator Requirements

To join the Xudanu network, a server operator needs:

1. **Public address** — a domain name accessible from the network
   ```sh
   --public-address alice.xudanu.com
   ```

2. **HTTPS certificate** — TLS is required for cross-server resolution. Self-signed certs work for testing but won't be trusted by default by other servers.

3. **Published content** — works in the public club (read_club = public). Publishing to the public club is an implicit redistribution grant: other servers may cache and serve this content via cross-server references.

4. **Server identity** — name and description for the well-known endpoint
   ```sh
   --server-name "Alice's Literature Server"
   --server-description "Essays and annotations"
   ```

5. **Abuse contact** (recommended) — an email or URL in the well-known endpoint for takedown requests. Operators are responsible for content they publish.

6. **Rights to redistribute** — operators must have the rights to any content they mark public, since cross-server transclusion reproduces and caches it on other servers.

### Legal Considerations

- **Copyright**: Cross-server caching means the fetching operator hosts a copy of the origin's content. The public club is an implicit "redistribute me" grant. Operators should only publish content they have rights to.
- **Cached blobs**: Cross-server cached content is subject to takedown. The blob store should support deletion by hash for DMCA compliance.
- **Jurisdiction**: Content crosses jurisdictional boundaries. Operators should be aware of their local laws regarding hosting cached copies.
- **Royalties**: The `RoyaltyEntry` ledger tracks byte usage but does not constitute a license or payment. It is monitoring data only.

---

## Relationship to Udanax-Gold

| Gold concept | Xudanu implementation | Difference |
|---|---|---|
| Tumblers (numeric server IDs) | Domain-based tumblers (`"alice.com".5.3.10.7`) | DNS replaces central registry |
| Enfilade (content storage) | O-tree CRDT + chunk store | Modern data structure |
| Cross-server transclusion | `CrossServerRef` + public content API + BLAKE3 verify | Pull-based (Gold was push-based) |
| Royalties (Rule 9) | `RoyaltyEntry` ledger (byte tracking, no payments yet) | Monitoring only, no micropayments |
| Server-to-server protocol | HTTPS + JSON (Gold had custom binary) | Standard web protocols |

---

## Implementation Priority

### Phase 0: Security Fixes (before any cross-server testing) — DONE

0. **Enforce trust gate** — `resolve_cross_server_ref` rejects untrusted/unregistered servers
0. **SSRF protection** — reject private/loopback IPs in tumblers; require directory membership
0. **HTTPS defaults** — HTTPS for well-known + content fetches; `--allow-insecure-*` flags for LAN
0. **Byte caps** — 5MB max on fetch buffer + public API response
0. **API version** — add `api_version: 1` to public work JSON
0. **Async resolution** — `spawn_blocking` for cross-server fetches (deferred)

### Phase 1: End-to-End Testing (Day 1) — DONE

1. **Docker/local test network** — two servers with fresh data dirs
2. **Manual cross-server link** — tumbler + hash entered via LinkCreator
3. **Content resolution** — backend fetch + BLAKE3 verify + cache works
4. **Byte tracking** — `record_royalty()` fires on every fetch

### Phase 1.5: Cross-Server Backlinks (Day 1.5) — NEXT

5. **Backlink notification** — `POST /api/backlink-notify` endpoint
6. **Origin server notification** — send on link creation
7. **Remote backlink storage** — persist in SocialSection chunk
8. **Display incoming references** — right margin + Connections panel
9. **Frontend resolution trigger** — click cross-server marker → fetch + display

**Security issue #105**: harden all cross-server public API endpoints (rate limiting, authentication, audit logging, CORS)
2. **Day 2:** Server directory UI (add/remove/trust servers from settings)
3. **Day 3:** Remote content browser + cross-server transclusion
4. **Day 4:** Byte tracking (hook `record_royalty` into `resolve_cross_server_ref`)
5. **Day 5:** Referral discovery + server graph visualization

Each day produces a testable, demoable feature. By end of Day 1, we can show two servers sharing content via tumblers — the core Xanadu vision.

---

## Key Files

| File | Role |
|------|------|
| `edition/links.rs:311-360` | `CrossServerRef` struct, tumbler parsing |
| `server/server.rs:1126-1227` | `resolve_cross_server_ref` (fetch + verify + cache) |
| `server/server.rs:972-1060` | Well-known endpoint, server directory add |
| `server/server_directory.rs` | Server directory (add/remove/trust/persist) |
| `server/transport/handler.rs:48-157` | HTTP routes: well-known, public work, public range |
| `server/transport/protocol.rs:2854-2874` | `CrossServerRefPayload` (wire format) |
| `server/federation.rs:160-176` | `RoyaltyEntry`, `RoyaltyType` (byte tracking) |
| `bin/xudanu-server.rs` | CLI flags: `--public-address`, `--server-name`, `--server-description`, `--server-namespace-id` |
| `web/app/src/components/LinkCreator.tsx` | Cross-server link creation UI |
| `web/app/src/api/crdt_sync.ts` | `linkCreateCrossServer` client method |
