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

### Phase 2: Server Directory UI (Day 2)

**Goal:** Users can manage known servers from the UI.

5. **Settings panel** — "Network" section in the settings dialog
   - List of known servers (from `server_directory.json`)
   - Add server by address (fetches `/.well-known/xudanu-server.json`)
   - Remove server
   - Toggle trust (trusted vs untrusted)
   - Show server name, description, verifying key, work count

6. **Server directory wire ops** — already implemented:
   - `ServerDirectoryAdd` (0x0F01)
   - `ServerDirectoryRemove` (0x0F02)
   - `ServerDirectoryList` (0x0F03)
   - `ServerDirectoryTrust` (0x0F04)
   - `ServerDirectoryResolve` (0x0F05)

7. **Frontend client methods** — add to `crdt_sync.ts`:
   - `serverDirectoryAdd(address, port?)`
   - `serverDirectoryRemove(serverId)`
   - `serverDirectoryList()`
   - `serverDirectoryTrust(serverId, trusted)`

### Phase 3: Content Discovery (Day 3)

**Goal:** Users can browse content on other servers.

8. **Remote content browser** — in the library panel
   - Select a trusted server from the directory
   - Fetch `/api/public/work/{id}` for each public work
   - Display remote works in a "Remote" section
   - Click a remote work to view its content (read-only)

9. **Cross-server search** — search across trusted servers
   - Query each trusted server's text search endpoint
   - Merge results, tagged with origin server

10. **Content import** — from remote browser
    - Transclude remote content into a local document
    - Automatically creates `CrossServerRef` with fetched hash

### Phase 4: Byte Tracking & Royalties (Day 4)

**Goal:** Track cross-server traffic for monitoring and future micropayments.

11. **Hook `record_royalty` into `resolve_cross_server_ref`**
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

12. **Traffic dashboard** — in settings panel
    - Per-server byte counts (sent/received)
    - Per-content-fingerprint access counts
    - Timeline of cross-server fetches

### Phase 5: Referral Discovery (Day 5)

**Goal:** Network grows organically through references.

13. **Referral propagation** — when resolving a cross-server ref
    - If the origin server's `/.well-known/xudanu-server.json` lists other known servers
    - Add them to the local directory with `discovered: "referral"` and `referred_by: origin_server_id`
    - User sees them in the directory UI as "Discovered via Server A"

14. **Server graph visualization** — force-directed graph
    - Nodes = servers in directory
    - Edges = cross-server references between them
    - Click a server to browse its content

---

## Security Model

### Three-Layer Verification (already implemented)

| Layer | What | How | Status |
|-------|------|-----|--------|
| Tumbler | WHERE content lives | Domain-based global address | Done |
| BLAKE3 | WHAT the content is | Hash verified on every fetch | Done |
| Ed25519 | WHO authored it | Server signature on well-known endpoint | Done |

### Threats & Mitigations

| Threat | Mitigation | Status |
|--------|-----------|--------|
| **Man-in-the-middle** during fetch | HTTPS (rustls + webpki-roots) | Done |
| **Content tampering** on origin server | BLAKE3 hash mismatch → reject | Done |
| **Spoofed server** (fake well-known) | Ed25519 verifying key in directory | Done |
| **Untrusted server** in directory | UI shows "UNVERIFIED" warning | Needs impl |
| **DDoS via cross-server refs** | Rate limit fetches per server; blob cache prevents re-fetch | Cache done, rate limit needed |
| **Stale content** (origin updated after link created) | Hash pins exact version; user sees "content has been updated" if hash differs | Hash check done; update notification needed |
| **Privacy leak** (server A sees who's fetching) | Fetch via server-to-server, not client-to-server; no user identity sent | Architecture supports this |
| **Malicious content** (large payloads, binary blobs) | Size limit on public API responses; text-only for now | Needs size limit |

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
| **Server goes offline** — content unreachable | Medium | Medium | Blob cache retains last-known-good copy; excerpt in link metadata is permanent proof |
| **Hash collision** (BLAKE3) | Negligible | High | BLAKE3 has no known collisions; 256-bit hash space |
| **Network partition** — servers can't reach each other | Medium | Low | Cached content still available; links show "origin offline" |
| **Large content fetch** — 100K+ word document | Medium | Medium | Range API (`/api/public/work/{id}/range/{start}/{end}`) already implemented; fetch only needed span |
| **Byte accumulation** for bandwidth tracking | High (pessimistic) | Low | `RoyaltyEntry` stores amounts; operator can monitor and set limits |
| **Server directory poisoning** — malicious entries | Low | Medium | Operator approves each entry; referral entries marked as untrusted |

---

## What We Need From Operators

To join the Xudanu network, a server operator needs:

1. **Public address** — a domain name or IP accessible from the network
   ```sh
   --public-address alice.xudanu.com
   ```

2. **Published content** — works in the public club (read_club = public)

3. **Server identity** — name and description for the well-known endpoint
   ```sh
   --server-name "Alice's Literature Server"
   --server-description "Essays and annotations"
   ```

4. **HTTPS** (recommended) — TLS certificate for the domain

That's it. No registration, no central authority, no federation setup. The server is discoverable by anyone who knows its address.

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

1. **Day 1:** Docker test network + manual cross-server link + resolution verify
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
