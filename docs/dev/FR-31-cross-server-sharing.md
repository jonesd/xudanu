# FR-31: Cross-Server Document Sharing

## Overview

Servers in the Xudanu docuverse can discover, browse, view, copy, link,
and search documents on other trusted servers. This is the network layer
that Gold/Udanax never implemented — the "docuverse" vision made real.

## Design Principles

- **Each server is sovereign** — no central registry, no shared state
- **Publication = permission** — published works are fetchable by anyone (Nelson's Rule 8)
- **Content lives in one place** — transclusion references, doesn't copy
- **Verification is cryptographic** — every fetch is signature-verified and hash-checked
- **Trust grows through use** — servers accumulate trust metrics over time

## Feature Areas

### 31.1 Server Directory

Each server maintains its own directory of known servers.

**Operations:**
- `server_directory_add` — fetch identity from `/.well-known/xudanu-server.json`, verify, store
- `server_directory_set_trust` — mark server as trusted (enables browse/fetch)
- `server_directory_remove` — remove from directory
- `server_directory_list` — list all known servers with trust metrics

**Per-server metadata tracked:**
- `verifying_key` — Ed25519 public key (from well-known endpoint)
- `pinned_key` — TOFU-pinned key (set on first verified interaction)
- `first_seen` — timestamp when server was added
- `last_seen` — timestamp of last successful interaction
- `last_success` / `last_failure` — availability tracking
- `consecutive_failures` — for health indicators
- `successful_resolutions` — count of verified content fetches
- `quarantined` / `quarantined_at` — security quarantine state
- `trusted` — user-controlled trust flag

**Availability indicators:**
- Green (healthy): 0 consecutive failures
- Yellow (degraded): 1-2 consecutive failures
- Red (likely offline): 3+ consecutive failures
- Blocked (quarantined): security violation detected

### 31.2 Server Discovery via Introductions

Servers discover new peers through signed introductions from servers they already trust.

**Flow:**
1. Server A trusts Server B → A signs B's identity (Ed25519)
2. Published at `GET /api/introductions` (rate-limited)
3. Server C trusts A → fetches A's introductions
4. C sees "A vouches for B" → can add B to its directory
5. B enters C's directory as untrusted, `discovered=introduction`, `referred_by=A`
6. C must manually trust B before browsing

**Introduction payload (signed):**
```
target_server_id | target_verifying_key | target_address | introduced_by | timestamp
```

**Verification:** C verifies A's signature on the introduction using A's pinned key.

**Signed introduction includes trust metrics:**
- `known_since` — how long A has known B
- `successful_resolutions` — A's successful interaction count with B

### 31.3 Browse Remote Works

List published works on a trusted server.

**Wire op:** `cross_server_list_works`
- Takes `server_id`
- Server fetches `GET /api/public/works` from remote server
- Goes through SSRF guard (DNS resolution verification)
- Returns works list with titles, char counts, revision numbers

**Search:** `GET /api/public/works?q=searchterm` filters by title + full text

### 31.4 View Remote Work

Fetch a single work with full cryptographic verification.

**Wire op:** `cross_server_fetch_work`
- Takes `server_id` + `work_id`
- Server fetches `GET /api/public/work/{id}` from remote server
- Verifies Ed25519 signature (signature enforcement)
- Checks TOFU key pin (rejects if key changed without rotation proof)
- Verifies BLAKE3 content hash
- Caches permanently in blob_store
- Increments `successful_resolutions` on the directory entry
- Updates `last_seen` and `last_success`

**Returns:** text, title, revision, content_hash, origin_server_id,
origin_server_name, license, tumbler, cached flag

**Frontend:** opens as read-only overlay in main editor with:
- Amber REMOTE badge + origin server name + license
- Full document text in serif typography
- Tumbler + work ID in footer

### 31.5 Copy Document (Import)

Copy a remote work to your local server with provenance.

**Frontend:** "Copy to my server" button on remote work viewer
- Creates new local work via `work_create`
- Prepends provenance header: origin server, tumbler, license
- Auto-titles: "Title (from Alice)"
- Fully editable — user owns their copy
- License inherited from source

### 31.6 Transclude Passage (MVP)

Insert a passage from a remote work into your local work with citation.

**Frontend:** "Insert selected text" button
- User selects text in remote work viewer
- Inserts as blockquote with citation: title, server name, tumbler
- Future: proper element-level transclusion (Phase 4)

### 31.7 Cross-Server Links

Create typed links from local work to remote work.

**Wire op:** `cross_server_link_create`
- Stores link metadata: local_work_id, remote_tumbler, remote_title,
  remote_server_name, link_type, timestamp
- Sends backlink notification to remote server (fire-and-forget POST)
- Links persisted in SocialSection chunk (survives restart)

**Wire op:** `cross_server_link_list`
- Lists all cross-server links for a given local work

### 31.8 Federated Search

Search across all trusted servers simultaneously.

**Wire op:** `federated_search`
- Takes query string
- Searches local published works (title + full text)
- Broadcasts to all trusted, non-quarantined servers via `GET /api/public/works?q=`
- Aggregates results with server origin labels
- Each result tagged: `local: true/false`, `server_name`, `server_id`

**Frontend:** search box at top of Servers tab ("Search all servers...")

## HTTP Endpoints (Public API)

All endpoints are unauthenticated, rate-limited, CORS-enabled:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/.well-known/xudanu-server.json` | GET | Server identity (name, verifying key, namespace ID) |
| `/api/public/works` | GET | List published works (optional `?q=search`) |
| `/api/public/work/{id}` | GET | Fetch single work (signed, hash-verified) |
| `/api/public/work/{id}/range/{start}/{end}` | GET | Fetch work range |
| `/api/introductions` | GET | Signed introductions from this server |
| `/api/backlink-notify` | POST | Backlink notification from another server |

## Wire Ops

| Op | Code | Auth | Purpose |
|----|------|------|---------|
| `server_directory_list` | 0x0F01 | session | List known servers |
| `server_directory_add` | 0x0F02 | logged_in | Add server to directory |
| `server_directory_remove` | 0x0F03 | logged_in | Remove server |
| `server_directory_set_trust` | 0x0F04 | logged_in | Trust/untrust server |
| `cross_server_resolve` | 0x0F05 | session | Resolve tumbler + hash (transclusion) |
| `cross_server_fetch_work` | 0x0F06 | session | Fetch work by server_id + work_id |
| `cross_server_list_works` | 0x0F07 | session | List works on remote server |
| `federated_search` | 0x0F08 | session | Search across all trusted servers |
| `fetch_introductions` | 0x0F09 | session | Fetch signed intros from server |
| `add_discovered_server` | 0x0F0A | logged_in | Add server discovered via intro |
| `cross_server_link_create` | 0x0F0B | logged_in | Create link to remote work |
| `cross_server_link_list` | 0x0F0C | session | List cross-server links |
| `fetch_remote_identity` | 0x0F0D | session | Fetch user identity attestation |

## Security

All cross-server operations go through:
1. **SSRF prevention** — DNS resolution guard blocks private/loopback IPs
2. **Signature enforcement** — Ed25519 signature verified on every response
3. **TOFU key pinning** — pinned key checked; mismatch triggers rotation verification
4. **Key rotation chain** — multi-hop chain walked from pinned key to current key
5. **Quarantine** — 5 consecutive failures → server quarantined, all operations blocked
6. **Rate limiting** — rotation attempts limited to 3/hour/server
7. **Brute-force detection** — consecutive signature failures tracked and alerted

See FR-32 (Security Model) for details.

## What Gold Had vs What We Built

Gold had tumblers, transclusion concepts, and bilateral links — but **no
cross-server transport**. The open-sourced code was a single-server system.

Xudanu adds:
- HTTP public API for content exchange
- Cryptographic content verification (BLAKE3 + Ed25519)
- Server directory with trust management
- Server discovery via signed introductions
- Federated search
- Permanent content caching (survives server disappearance)
- Attack detection and quarantine

This is genuinely new work — the network layer that Nelson envisioned but
Gold never implemented.
