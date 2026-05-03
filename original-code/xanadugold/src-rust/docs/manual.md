# Xudanu System Manual

## What is Xudanu

Xudanu is a conflict-preserving content-addressed document store with bidirectional links, transclusion, and fine-grained access control. It is a modern Rust implementation of the Udanax Gold hypertext system.

**Core concepts:**
- **Works** — versioned containers that hold Editions. Think of a Work as a document that evolves over time.
- **Editions** — immutable snapshots of content (text, structured data, links to other editions). Each revision of a Work creates a new Edition.
- **Clubs** — groups with authority. Clubs control who can read, revise, endorse, and manage content.
- **Endorsements** — typed stamps of approval from clubs. `(club_id, token_id)` pairs that any client can verify.
- **Links** — bidirectional connections between Works with typed origins and destinations.
- **Transclusion** — live inclusion of content from one Edition inside another. Changes to the source appear in all transcluding documents.
- **Blobs** — binary large objects (images, files) stored alongside text content.

---

## Getting Started

### Starting the Server

```bash
# Build
cargo build --features server

# Run with in-memory storage
./target/debug/xudanu-server run

# Run with persistent storage
./target/debug/xudanu-server run --data-dir /path/to/data

# The server listens on port 8080 by default
```

### Connecting

Clients connect via WebSocket. Two codec formats are supported:

- **JSON** — human-readable, good for debugging and simple clients
- **Binary** — efficient, using postcard serialization

All requests follow this frame format:
```json
{"id": 1, "op": "operation_name", "v": 2, ...payload}
```

Responses:
```json
{"id": 1, "type": "response", "v": 2, "value": {...}}
{"id": 1, "type": "error", "v": 2, "code": "error_code", "message": "..."}
```

### Production Deployment

For HTTPS/WSS, put Xudanu behind a reverse proxy:

**Caddy** (recommended — built-in Let's Encrypt):
```
xudanu.example.com {
    reverse_proxy localhost:8080
}
```

**Nginx** (requires certbot for Let's Encrypt):
```
server {
    listen 443 ssl;
    server_name xudanu.example.com;
    ssl_certificate /etc/letsencrypt/live/xudanu.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/xudanu.example.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

---

## Sessions and Authentication

### Connecting Anonymously

```json
→ {"id": 1, "op": "session_connect", "v": 2}
← {"id": 1, "type": "response", "v": 2, "value": {"type": "id", "value": 1}}
```

This creates a session with no authority. You can still read public content.

### Logging In

**Public login** (read-only access to public content):
```json
→ {"id": 2, "op": "session_login_public", "v": 2}
← {"id": 2, "type": "response", "v": 2, "value": {"type": "ids", "value": [0]}}
```

**Club login** (access to a specific club's content):
```json
→ {"id": 2, "op": "session_login", "v": 2, "club_id": 3}
← {"id": 2, "type": "response", "v": 2, "value": {"type": "ids", "value": [3]}}
```

**Named club login** (by club name):
```json
→ {"id": 2, "op": "session_login_by_name", "v": 2, "name": "admin"}
```

### Authenticating with Credentials

After logging in, authenticate with a credential to prove identity:

**Boo credential** (development/testing — always succeeds):
```json
→ {"id": 3, "op": "session_authenticate", "v": 2,
   "club_id": 3, "credential": "Boo"}
```

**Password credential** (uses Argon2id hashing):
```json
→ {"id": 3, "op": "session_authenticate", "v": 2,
   "club_id": 3, "credential": {"password": [115, 101, 99, 114, 101, 116]}}
```

The password is sent as a byte array. The server verifies it against an Argon2id hash using constant-time comparison.

**Challenge-response credential** (X25519 ECDH + ChaCha20-Poly1305):
```json
→ {"id": 3, "op": "session_authenticate", "v": 2,
   "club_id": 3, "credential": {"challenge_response": [...bytes...]}}
```

The server encrypts a challenge using the client's X25519 public key. The client decrypts and returns the plaintext.

### Disconnecting

```json
→ {"id": 99, "op": "session_disconnect", "v": 2}
```

---

## Works

### Creating a Work

```json
→ {"id": 1, "op": "work_create", "v": 2, "edition": {"text": "Hello world"}}
← {"id": 1, "type": "response", "v": 2, "value": {"type": "id", "value": 1004}}
```

The `edition` field accepts:
- `{"text": "content"}` — text content
- `"empty"` — empty edition
- `{"entries": [[0, {"text": "a"}], [1, {"text": "b"}]]}` — explicit position/element pairs

### Grabbing and Releasing

Works must be "grabbed" (locked) before revision. Only one session can grab a work at a time.

```json
→ {"id": 1, "op": "work_grab", "v": 2, "work_id": 1004}
→ {"id": 2, "op": "work_release", "v": 2, "work_id": 1004}
```

### Revising Content

**Full replacement:**
```json
→ {"id": 1, "op": "work_revise", "v": 2,
   "work_id": 1004, "edition": {"text": "Updated content"}}
```

**Delta-based revision** (text operations):
```json
→ {"id": 1, "op": "work_revise_delta", "v": 2,
   "work_id": 1004, "base_revision": 3,
   "ops": [
     {"retain": {"count": 5}},
     {"insert": {"text": "new"}},
     {"delete": {"count": 3}}
   ]}
```

### Reading Content

```json
→ {"id": 1, "op": "work_get_edition", "v": 2, "work_id": 1004}
← {"id": 1, "type": "response", "v": 2,
   "value": {"type": "edition", "value": {"entries": [[0, {"text": "H"}], ...]}}}
```

### Querying Works

```json
→ {"id": 1, "op": "work_list", "v": 2}                    // all works
→ {"id": 1, "op": "work_list_by_owner", "v": 2, "club_id": 3}  // owned by club 3
→ {"id": 1, "op": "work_owner", "v": 2, "work_id": 1004}   // who owns this work
→ {"id": 1, "op": "work_sponsors", "v": 2, "work_id": 1004} // who sponsors this work
```

---

## Clubs and Access Control

### How Clubs Work

Clubs are groups that control access. Every Work has:
- **Read club** — who can read the content
- **Revise club** — who can modify the content
- **Owner** — the club that created the Work

Clubs form a hierarchy. If club A is a member of club B, authority over B includes authority over A.

### Creating Clubs

```json
→ {"id": 1, "op": "club_create", "v": 2}
← {"id": 1, "type": "response", "v": 2, "value": {"type": "id", "value": 5}}
```

**Named club** (accessible by name):
```json
→ {"id": 1, "op": "club_create_named", "v": 2,
   "name": "science", "edition": {"text": "Science Club"}}
```

### Looking Up Clubs

```json
→ {"id": 1, "op": "club_names", "v": 2}                    // all named clubs
→ {"id": 1, "op": "club_id_by_name", "v": 2, "name": "admin"} // get ID
→ {"id": 1, "op": "club_get", "v": 2, "club_id": 3}        // full info
```

### Built-in Clubs

Every Xudanu server starts with:
- **public** (id varies) — everyone has access, content is world-readable
- **admin** (id varies) — server administrators, full access
- **access** — manages administrative permissions
- **empty** — no content, used as a placeholder

---

## Endorsements

### What Endorsements Are

An endorsement is a `(club_id, token_id)` pair — a typed stamp of approval. Each club defines its own vocabulary of token_ids:

| Club | Token | Meaning (example) |
|------|-------|-------------------|
| Science | 1 | Peer-reviewed |
| Science | 2 | Retracted |
| Legal | 1 | Compliant |
| Legal | 2 | Under review |
| Admin | 1 | Featured |
| Admin | 2 | Archived |

The system stores and queries endorsements but does not interpret them. Applications assign meaning.

### Authority Rules

- **To endorse/retract:** Session must have signature authority for every `club_id` in the endorsement set
- **To query:** No authority required — endorsements are publicly visible

Signature authority works through the club hierarchy: each club has a `signature_club` (typically its owner). Your session needs authority over that signature_club.

### Endorsing a Work

```json
→ {"id": 1, "op": "work_endorse", "v": 2,
   "work_id": 1004, "endorsements": [[3, 10], [3, 20]]}
```

This stamps "club 3, token 10" and "club 3, token 20" onto the work. The session must have signature authority for club 3.

### Querying Endorsements

```json
→ {"id": 1, "op": "work_endorsements", "v": 2, "work_id": 1004}
← {"id": 1, "type": "response", "v": 2,
   "value": {"type": "endorsement_result", "value": {"endorsements": [[3, 10], [3, 20]]}}}
```

### Retracting an Endorsement

```json
→ {"id": 1, "op": "work_retract", "v": 2,
   "work_id": 1004, "endorsements": [[3, 10]]}
```

Requires the same signature authority as endorsing. Retracting a non-existent endorsement is a no-op.

### Edition Endorsements

Same operations for standalone editions:

```json
→ {"id": 1, "op": "edition_endorse", "v": 2,
   "edition_id": 5001, "endorsements": [[3, 5]]}
→ {"id": 2, "op": "edition_endorsements", "v": 2, "edition_id": 5001}
→ {"id": 3, "op": "edition_retract", "v": 2,
   "edition_id": 5001, "endorsements": [[3, 5]]}
```

### Visible vs Total Endorsements

- **edition_endorsements** — just the edition's own endorsements
- **edition_visible_endorsements** — edition's endorsements + endorsements from Works that the session can read
- **edition_total_endorsements** — edition's endorsements + all Works' endorsements (no read check)

### Idempotency

Endorsing with the same `(club_id, token_id)` twice is a no-op. The endorsement set is a set — duplicates are ignored.

---

## Sponsorship

Sponsorship is a simpler relationship than endorsement — a club "sponsors" a Work to indicate endorsement of its existence.

```json
→ {"id": 1, "op": "work_sponsor", "v": 2, "work_id": 1004, "club_id": 3}
→ {"id": 2, "op": "work_sponsors", "v": 2, "work_id": 1004}
→ {"id": 3, "op": "work_unsponsor", "v": 2, "work_id": 1004, "club_id": 3}
```

Requires signature authority for the sponsoring club.

---

## Links

### Creating Links

Links connect Works bidirectionally — every link is automatically visible from both ends.

```json
→ {"id": 1, "op": "link_create", "v": 2,
   "origin_work_id": 1004,
   "destination_work_id": 2001,
   "link_type": "reference"}
← {"id": 1, "type": "response", "v": 2, "value": {"type": "id", "value": 3001}}
```

### Querying Links

```json
→ {"id": 1, "op": "link_list_for_work", "v": 2, "work_id": 1004}
→ {"id": 2, "op": "link_get", "v": 2, "link_id": 3001}
```

### Updating and Deleting

```json
→ {"id": 1, "op": "link_update", "v": 2, "link_id": 3001, ...fields}
→ {"id": 2, "op": "link_delete", "v": 2, "link_id": 3001}
```

---

## Transclusion

Transclusion includes content from one Edition inside another. Unlike copy-paste, transcluded content remains linked — changes to the source appear in all transcluding documents.

### Finding Transcluders

Find all Editions that transclude content from a given Work:
```json
→ {"id": 1, "op": "find_transcluders", "v": 2, "work_id": 1004}
```

Find transcluders of specific text content:
```json
→ {"id": 1, "op": "find_text_transcluders", "v": 2, "text": "quantum"}
```

### Finding Shared Regions

Find content regions shared between Editions:
```json
→ {"id": 1, "op": "find_shared_regions", "v": 2,
   "edition_id": 5001, "filter_text": "introduction"}
```

### Depth and Bundle Queries

```json
→ {"id": 1, "op": "transclusion_depth", "v": 2, "work_id": 1004}
→ {"id": 2, "op": "range_transcluders", "v": 2, ...}
→ {"id": 3, "op": "ordered_bundles", "v": 2, ...}
```

---

## Blobs (Binary Data)

### Uploading

```json
→ {"id": 1, "op": "blob_upload", "v": 2,
   "data": [...base64...], "content_type": "image/png"}
← {"id": 1, "type": "response", "v": 2, "value": {"type": "id", "value": 7001}}
```

### Retrieving

```json
→ {"id": 1, "op": "blob_get", "v": 2, "blob_id": 7001}
→ {"id": 2, "op": "blob_info", "v": 2, "blob_id": 7001}
→ {"id": 3, "op": "blob_stats", "v": 2}
```

---

## Cryptography and Key Management

### Server Identity

Each server has a unique Ed25519 signing key and X25519 key exchange key, generated on first startup.

```json
→ {"id": 1, "op": "crypto_get_public_key", "v": 2}
← {"id": 1, "type": "response", "v": 2,
   "value": {"type": "crypto_public_key_result", "value": {
     "key_id": 12345678,
     "signing_key": [...32 bytes...],
     "kex_key": [...32 bytes...],
     "server_id": "a1b2c3d4"}}}
```

### Signing Data

Requires admin authority:
```json
→ {"id": 1, "op": "crypto_sign_data", "v": 2, "data": [1, 2, 3]}
← {"id": 1, "type": "response", "v": 2,
   "value": {"type": "crypto_sign_result", "value": {
     "signature": [...64 bytes...], "key_id": 12345678}}}
```

### Verifying Signatures

No authority required:
```json
→ {"id": 1, "op": "crypto_verify_signature", "v": 2,
   "data": [1, 2, 3], "signature": [...64 bytes...]}
← {"id": 1, "type": "response", "v": 2,
   "value": {"type": "crypto_verify_result", "value": {"valid": true}}}
```

### Key Rotation

Rotates the server's signing and key exchange keys. The old key signs the new key, creating a verifiable chain. Requires admin authority:

```json
→ {"id": 1, "op": "crypto_key_rotation", "v": 2}
← {"id": 1, "type": "response", "v": 2,
   "value": {"type": "crypto_key_rotation_result", "value": {"new_key_id": 87654321}}}
```

After rotation, signatures from the old key can still be verified using the key history:
```json
→ {"id": 1, "op": "crypto_key_history", "v": 2}
```

### Security Notes

- All passwords are hashed with Argon2id (OWASP parameters: 19 MiB, 2 iterations, 1 lane)
- Challenge-response uses X25519 ECDH + HKDF + ChaCha20-Poly1305
- All secret material is zeroized on drop
- Key history is signed from day one — the chain can be verified from genesis
- Content addressing uses BLAKE3 for fingerprints
- `cargo audit` reports zero known vulnerabilities in dependencies

---

## Administration

### Admin Login

```json
// Connect
→ {"id": 1, "op": "session_connect", "v": 2}
// Find admin club
→ {"id": 2, "op": "club_id_by_name", "v": 2, "name": "admin"}
// Login
→ {"id": 3, "op": "session_login", "v": 2, "club_id": <admin_club_id>}
// Authenticate
→ {"id": 4, "op": "session_authenticate", "v": 2,
   "club_id": <admin_club_id>, "credential": "Boo"}
```

### Server Health

```json
→ {"id": 1, "op": "admin_server_health", "v": 2}
← {"id": 1, "type": "response", "v": 2,
   "value": {"type": "server_health_result", "value": {
     "operation_count": 1523,
     "active_recorders": 3,
     "total_recorded": 47,
     "blob_count": 12,
     "link_count": 89,
     "uptime_secs": 3600}}}
```

### Recorder System

Recorders are persistent queries that accumulate results over time:

```json
→ {"id": 1, "op": "admin_recorder_create", "v": 2, "kind": "transcluders"}
← {"id": 1, "type": "response", "v": 2,
   "value": {"type": "recorder_create_result", "value": {"recorder_id": 1}}}

→ {"id": 2, "op": "admin_recorder_record", "v": 2,
   "recorder_id": 1, "element": {"Edition": {"edition_id": 42}}}

→ {"id": 3, "op": "admin_recorder_list", "v": 2}
→ {"id": 4, "op": "admin_recorder_get", "v": 2, "recorder_id": 1}
```

### Grant/Revoke Admin Access

```json
→ {"id": 1, "op": "admin_grant", "v": 2, "session_id": 5}
→ {"id": 2, "op": "admin_revoke_grant", "v": 2, "session_id": 5}
→ {"id": 3, "op": "admin_grants", "v": 2}
```

### Server Management

```json
→ {"id": 1, "op": "admin_server_info", "v": 2}
→ {"id": 2, "op": "admin_active_sessions", "v": 2}
→ {"id": 3, "op": "admin_is_accepting_connections", "v": 2}
→ {"id": 4, "op": "admin_accept_connections", "v": 2, "accept": true}
→ {"id": 5, "op": "admin_shutdown", "v": 2}
```

---

## Security Architecture

### Encryption Stack

| Component | Algorithm | Purpose |
|-----------|-----------|---------|
| Signing | Ed25519 | Server identity, data signing, key rotation proofs |
| Key Exchange | X25519 | ECDH shared secret derivation |
| Encryption | ChaCha20-Poly1305 | AEAD for challenges, documents, session keys |
| Key Derivation | HKDF-SHA256 | Domain-separated key derivation |
| Password Hashing | Argon2id | Password storage and verification |
| Content Addressing | BLAKE3 | Content fingerprints (existing) |

### Domain Separation

All HKDF derivations use `xudanu/v1/` prefixed labels:
- `xudanu/v1/handshake`
- `xudanu/v1/aead/client-to-server`
- `xudanu/v1/aead/server-to-client`
- `xudanu/v1/document-key`
- `xudanu/v1/challenge-key`

### Key Rotation

- Key rotation is admin-triggered
- Old key signs the new key, creating a verifiable chain from genesis
- `verify_server_signature_with_key(key_id, ...)` verifies against any historical key
- Keys have `not_before`/`not_after` timestamps for validity checking

### What to Put Behind TLS

The wire protocol is plaintext WebSocket. In production, always use TLS (Caddy or nginx with Let's Encrypt). The crypto layer protects sensitive operations (passwords, challenges, signatures) but transport encryption prevents eavesdropping.

---

## Error Codes

| Code | Meaning |
|------|---------|
| `not_authorized` | Session lacks required authority |
| `not_found` | Requested resource doesn't exist |
| `already_exists` | Resource already exists |
| `not_grabbed` | Work must be grabbed before revision |
| `already_grabbed` | Work is locked by another session |
| `session_required` | Operation requires an active session |
| `invalid_argument` | Bad request parameters |
| `type_mismatch` | Wrong data type in request |
| `lock_failed` | Credential didn't match the lock |
| `session_not_found` | Unknown session ID |
| `work_not_found` | Unknown work ID |
| `club_not_found` | Unknown club ID |
| `edition_not_found` | Unknown edition ID |
| `admin_required` | Admin authority required |
| `unauthorized` | No signature authority for endorsement |
| `internal` | Server error |
| `protocol_error` | Malformed request |

---

## Operation Reference

### Session Operations (0x00xx)
`session_connect`, `session_disconnect`, `session_login_public`, `session_login`, `session_login_by_name`, `session_authenticate`

### Work Operations (0x03xx)
`work_create`, `work_grab`, `work_release`, `work_is_grabbed`, `work_grabber`, `work_can_read`, `work_can_revise`, `work_revision_count`, `work_sponsors`, `work_owner`, `work_get_edition`, `work_revise`, `work_revise_delta`, `work_list`, `work_list_by_owner`, `work_sponsor`, `work_unsponsor`

### Club Operations (0x03xx)
`club_get`, `club_names`, `club_id_by_name`, `club_name_by_id`, `club_create`, `club_create_named`

### Link Operations (0x04xx)
`link_create`, `link_get`, `link_update`, `link_delete`, `link_list_for_work`

### Edition Operations (0x05xx)
`edition_store`, `edition_get`, `edition_retrieve`, `edition_relabel`, `edition_rebind`, `edition_cost`

### Blob Operations (0x06xx)
`blob_upload`, `blob_get`, `blob_get_preview`, `blob_info`, `blob_stats`, `blob_exists`

### Content Operations (0x0exx)
`content_shared_region`, `content_map_shared_to`, `content_map_shared_onto`, `positions_of`

### Transclusion Operations (0x0fxx)
`range_transcluders`, `range_works`, `ordered_bundles`, `transclusion_depth`

### Admin Operations (0x11xx)
`admin_server_info`, `admin_active_sessions`, `admin_grant`, `admin_grants`, `admin_revoke_grant`, `admin_shutdown`, `admin_accept_connections`, `admin_is_accepting_connections`, `admin_recorder_create`, `admin_recorder_record`, `admin_recorder_list`, `admin_recorder_get`, `admin_server_health`

### Crypto Operations (0x12xx)
`crypto_get_public_key`, `crypto_sign_data`, `crypto_verify_signature`, `crypto_key_rotation`, `crypto_key_history`

### Endorsement Operations (0x13xx)
`work_endorse`, `work_retract`, `work_endorsements`, `edition_endorse`, `edition_retract`, `edition_endorsements`, `edition_visible_endorsements`, `edition_total_endorsements`

### Federation Operations (0x14xx) — Planned
`federation_info`, `federation_peers`, `federation_sync_push`, `federation_sync_pull`, `federation_content_get`, `federation_blob_get`, `federation_resolve_edition`, `federation_resolve_work`, `federation_find_transcluders`, `federation_transclusion_depth`, `federation_endorsement_sync`, `federation_state_sync`, `federation_join_request`, `federation_endorse_server`, `federation_expel`, `federation_bft_propose`, `federation_bft_vote`, `federation_record_royalty`

---

## Federation

### What is Federation

Xudanu federation connects multiple Xudanu servers into a cooperative network where content created on any server can be referenced, transcluded, and verified across the entire federation. The system preserves Xanadu's original vision: a world-wide hypertext system where documents on different servers can transclude each other's content through stable, content-addressed references.

In a federated Xudanu deployment, servers are not replicas or mirrors. Each server owns its own content and coordinate space. Federation makes those spaces visible to each other. When Server A transcludes content from Server B, it does not make a copy — it creates a reference into the same coordinate space that Server B holds. The content fingerprint (BLAKE3 hash) is the global identity. The same bytes have the same fingerprint everywhere, regardless of which server stores them.

**Key principle**: There are not multiple copies of content. There are multiple embeddings of the same coordinate space.

### Design Philosophy: Three Planes of Consensus

Federation introduces the problem of agreement across independent servers. Xudanu solves this with a layered architecture that applies the minimum necessary consensus at each layer:

| Plane | What | Mechanism | Consensus |
|-------|------|-----------|-----------|
| **Content** | Immutable blobs, editions, text spans | G-Set CRDT + BLAKE3 verification | None — the hash IS the consensus |
| **Reconciliation** | Endorsements, branch heads, mutable metadata | OR-Set CRDT + DagWood `AlternativeSet` | None — DagWood preserves coexisting truths |
| **Governance** | Server membership, key ownership, royalty accounting | Lightweight PBFT (3–10 nodes) | Byzantine agreement — one truth, no forks |

#### Content Plane

Content-addressed data (text, binary blobs, edition elements) is inherently self-verifying. When Server A sends a blob to Server B, Server B computes `blake3(blob)` and compares it to the claimed hash. If they match, the data is correct. No trust in Server A is required — only trust in the hash function.

Because immutable content can only be added, never modified, replication is a G-Set CRDT (grow-only set). The merge operation is set union: `local_content ∪ remote_content`. This converges automatically without coordination, works completely offline, and requires no consensus protocol.

This sidesteps the CAP theorem for the data plane. An immutable blob referenced by its BLAKE3 hash is the same everywhere — there are no consistency conflicts for the data itself.

#### Reconciliation Plane

Mutable state — endorsement sets, branch head pointers, work metadata — requires coordination but not strong agreement. Xudanu uses CRDTs (OR-Set, LWW-Register) for eventual consistency, combined with DagWood's merge semantics.

When Server A and Server B both revise the same work concurrently, DagWood preserves both revisions as an `AlternativeSet`. Neither is silently discarded. Both are visible through different `TraceView`s. This is pure Xanadu: multiple coexisting truths with structured reconciliation, not winner-takes-all conflict resolution.

This is fundamentally different from systems that assume there must be one agreed truth (Byzantine Fault Tolerance, Raft, blockchain consensus). Xudanu's DagWood model allows multiple valid histories to coexist, which is the natural model for a system designed around transclusion and bidirectional links.

#### Governance Plane

Some operations genuinely require one agreed truth with no forks: server membership (which servers are in the federation), key ownership (which server owns which identity), and royalty accounting (who owes what to whom). For these, Xudanu uses a lightweight PBFT (Practical Byzantine Fault Tolerance) protocol.

PBFT is invoked only for governance operations — admitting a new server, expelling a malicious one, recording a royalty obligation. It is never used for content operations. With 3–10 nodes, PBFT's O(n²) messaging is trivially fast (approximately 100 messages per round at 10 nodes, sub-second latency).

### Rationale: Why This Architecture

#### What Xanadu Needed (That Most Systems Fail to Provide)

Transclusion requires three guarantees:

1. **Stable identity of content** — a span must mean the same thing everywhere, forever
2. **Addressable spans within that content** — you must be able to point to a specific range
3. **Persistence across edits and merges** — references must survive document evolution

Most systems fail at #2 and #3. Xanadu's insight was that you cannot build transclusion on top of mutable text buffers. Xudanu's content-addressing (BLAKE3 fingerprints) and DagWood version control solve all three.

#### What We Learned From Other Systems

| System | Key Insight | What We Adopted |
|--------|-------------|-----------------|
| **Matrix** | Content-addressed events with Ed25519 signatures; key rotation chains; notary-based key corroboration | Server identity publication, signed key rotation, key history |
| **ActivityPub** | Inbox/outbox delivery; HTTP Signatures; WebFinger discovery | Separation of client and federation endpoints; server-to-server authentication |
| **Secure Scuttlebutt** | Ed25519 identity as feed ID; append-only logs; follow-graph trust; offline-first with eventual consistency | Content identity via BLAKE3 (analogous to SSB's SHA-256 message IDs); web-of-trust for server endorsement; offline operation |
| **IPFS** | Content addressing (CIDs, multihash); DHT for routing; self-certifying IPNS records | BLAKE3 as content identity (analogous to CIDs); content verification independent of transport trust |
| **Git/Fossil** | Content-addressed objects; hash verification on receipt; G-Set CRDT for artifact exchange (Fossil) | Content verification on replication; G-Set CRDT for immutable content sync |

#### Why Not Use BFT Everywhere

BFT consensus (PBFT, Tendermint) assumes there must be one agreed truth for every operation. This is appropriate for financial ledgers but wasteful for content storage where:

- The hash IS the truth — blake3(content) is the same on every server
- DagWood allows coexisting truths — concurrent edits are preserved, not resolved
- Requiring 2f+1 nodes online for every write kills offline operation
- O(n²) messaging for every content store operation is wasteful when the data is self-verifying

BFT is reserved for operations that genuinely need one truth: who is a member, who owns a key, what royalties are owed.

#### Why Not Use Raft

Raft provides crash fault tolerance but not Byzantine fault tolerance. A malicious leader can serve different views to different followers. For a closed federation of trusted operators, Raft would be sufficient. But since the federation may eventually include less-trusted participants, PBFT provides the necessary protection against Byzantine behavior.

#### Why Trusted Operators First

A system this complex will have bugs and unexpected behaviors. Starting with a closed federation of trusted operators means:

- Problems are found in a controlled environment
- There is no adversarial pressure during early operation
- The trust model (config-based peer list) is simple and well-understood
- The system can be stabilized before opening to external participants

Once the federation protocol is proven stable, endorsement-based open federation can be enabled, allowing new servers to join through a web-of-trust mechanism.

### Content Identity Across Servers

#### Federated IDs

In a single-server deployment, all IDs are local (`BeId = u64`). Federation introduces `FederatedId`:

```
FederatedId {
    server_id: String,    // hex of first 8 bytes of origin server's Ed25519 verifying key
    local_id: u64,        // the BeId on the origin server
}
```

This provides globally unique identification without a central ID authority. The server_id is derived from the server's cryptographic identity, which is stable across restarts (published via the key history chain).

#### Content Fingerprints as Global Identity

`RangeElement::content_fingerprint()` produces a BLAKE3 hash with a type prefix (`b"text:"`, `b"data:"`, etc.). Two pieces of text that are byte-identical produce the same fingerprint regardless of which server holds them. The `ContentAddressIndex` ensures identical content maps to the same canonical `BeId` within a server.

For federation, this means:

- Content verification is local: compute blake3(received_bytes) and compare to the claimed hash
- No trust in the sending server is required for data integrity
- Transclusion detection works across servers: a fingerprint query finds the same content regardless of location
- Storage is naturally deduplicated: the same content stored on multiple servers is the same entry in the content plane

#### Transclusion Across Servers

A transclusion is a projection of a span through a DagWood view:

```
transclude(span: SpanId, view: ViewId) -> MaterializedContent
```

In a federated deployment, the span can live on any server. Resolution works as:

1. Encounter `RangeElement::FederatedEdition { federated_id }` in a local edition
2. Check local cache for the remote edition
3. If not cached, query the origin server (identified by `federated_id.server_id`)
4. Origin server responds with the serialized edition
5. Verify: for each element, `blake3(element) == expected_fingerprint`
6. Cache locally, indexed by `FederatedId`
7. Materialize the content through the current `TraceView`

The content fingerprint is the global identity. The `FederatedId` tells you where to find it. The combination enables the Xanadu vision: any span on any server can be transcluded into any document on any other server.

### Server Identity and Discovery

#### Server Identity

Each Xudanu server has a unique Ed25519 signing key and X25519 key exchange key (established in Phase 12). The `ServerIdentity` struct contains:

| Field | Type | Purpose |
|-------|------|---------|
| `server_id` | `String` | Hex of first 8 bytes of verifying key (stable identifier) |
| `signing_key` | `[u8; 32]` | Ed25519 public key for verifying signatures |
| `kex_public` | `[u8; 32]` | X25519 public key for key exchange |
| `federation_domain` | `String` | Federation domain (default: `"xudanu"`) |

The key history (`KeyHistory`) maintains a signed chain from genesis, enabling key rotation without losing the ability to verify historical signatures.

#### Server-to-Server Handshake

When two servers connect, they perform a mutual authentication handshake that reuses the existing crypto stack:

```
Server A                              Server B
    │                                     │
    │──── ephemeral X25519 public key ───→│
    │←─── ephemeral X25519 public key ────│
    │                                     │
    │  Both derive shared secret via       │
    │  X25519 ECDH (double-DH:            │
    │  static-static + ephemeral-static)   │
    │                                     │
    │──── Ed25519 signature over ────────→│
    │     handshake transcript             │
    │←─── Ed25519 signature over ─────────│
    │     handshake transcript             │
    │                                     │
    │  Both verify peer signature against  │
    │  published ServerIdentity            │
    │                                     │
    │  Both derive session keys via HKDF   │
    │  (xudanu/v1/federation/...)          │
    │                                     │
    │════════ encrypted channel ═══════════│
    │        (ChaCha20-Poly1305)           │
```

The handshake binds ephemeral keys to long-term identity via the Ed25519 signature, preventing man-in-the-middle attacks. The session keys provide forward secrecy for the encrypted channel.

#### Federation Endpoints

| Endpoint | Purpose |
|----------|---------|
| `ws://host:port/xudanu` | Client WebSocket (existing) |
| `ws://host:port/federation` | Server-to-server WebSocket (new) |
| `GET /federation/info` | Server identity, capabilities, peer list |

The federation endpoint uses a separate WebSocket connection with different authentication (mutual Ed25519 handshake vs. session-based login), different rate limits (servers get higher quotas), and a different protocol (CRDT sync vs. request-response).

#### Peer Configuration

For closed federation (Phases 14–18), peers are configured at startup:

```toml
[federation]
enabled = true
peers = [
    "server2.example.com:8081",
    "server3.example.com:8082"
]
```

For open federation (Phase 19+), peers can also be discovered through the endorsement chain and federation membership CRDT.

### Federation Threat Model

| Attack | Vector | Defense |
|--------|--------|---------|
| **Content injection** | Malicious server sends fake content | BLAKE3 verification rejects content that doesn't match claimed hash |
| **Content omission** | Server claims to have content it doesn't | Challenge-response: server must produce content matching a known hash |
| **Metadata tampering** | Server modifies endorsements or permissions | All mutations signed with origin server's Ed25519 key; signature verified on receipt |
| **Sybil attack** | Attacker creates many server identities | Closed federation: config whitelist. Open federation: requires N endorsements from existing members |
| **Eclipse attack** | Attacker controls all peers a victim sees | Multi-source bootstrap from trusted config; cross-validation of peer data |
| **Replay attack** | Attacker replays old sync messages | Monotonic counters in `SessionCipher` reject messages with counter ≤ last seen |
| **Man-in-the-middle** | Attacker intercepts server-to-server traffic | Ed25519 handshake binds ephemeral keys to long-term identity |
| **Denial of service** | Server floods peers with requests | Per-peer rate limiting (bytes/sec, ops/sec); connection limits; message size caps |
| **Resource exhaustion** | Server stores excessive data on peers | Per-server storage quotas |
| **Partition abuse** | Server exploits network split | CRDTs converge on reconnect; DagWood preserves all alternatives; governance ops require PBFT majority |
| **Key compromise** | Server's signing key stolen | Key rotation via `KeyHistory` + `SignedKeyRotation`; PBFT agreement on new key; old key valid for historical signatures only |
| **Transclusion hijacking** | Server claims origin of content it didn't create | Content fingerprints are deterministic; provenance tracked via `FederatedId`; first-seen recorded in governance registry |

### Federation Phases and Milestones

The federation protocol is implemented incrementally across eight phases. Each phase is fully integrated (library code, server protocol, dispatch, server methods, codec, integration tests, documentation) before proceeding to the next.

#### Phase 14: Federation Foundation

**Goal**: Types, identity, and addressing for a multi-server world. No cross-server communication yet.

**Key deliverables**:
- `FederatedId { server_id, local_id }` — globally unique content identification
- `FederatedRangeElement` — `RangeElement` variants that reference remote servers (`FederatedEdition`, `FederatedWork`)
- `RoyaltyEntry` type — origin server, content fingerprint, royalty type, amount (hook for future use)
- Server identity publication endpoint (`GET /federation/info`)
- Federation configuration (trusted peer list)
- Snapshot extension for federation state
- Wire operations: `0x1401 federation_info`, `0x1402 federation_peers`

**Tests**: Single server publishes identity; client fetches it.

**Servers tested**: 1

---

#### Phase 15: Server-to-Server Transport

**Goal**: Two servers can authenticate and establish an encrypted channel.

**Key deliverables**:
- `/federation` WebSocket endpoint (separate from `/xudanu`)
- Mutual Ed25519 handshake (reuses `sign_handshake` / `verify_handshake_signature` from `crypto/kex.rs`)
- Encrypted channel (reuses `derive_session_keys` + `SessionCipher`)
- Federation connection manager (active peer tracking, reconnect, heartbeat)
- Federation codec (wire format for server-to-server frames)
- Server binary: `--federation-port` or config section
- Each server instance has its own data directory and snapshot file

**Tests**: 2 servers on localhost (ports 8080 + 8081); establish federation connection; exchange heartbeat.

**Servers tested**: 2

---

#### Phase 16: Content Replication (G-Set CRDT)

**Goal**: Content on Server A is verifiably available on Server B.

**Key deliverables**:
- `ContentSync` CRDT: G-Set of `(FederatedId, BLAKE3 hash, serialized content)`
- Push sync: notify peers when new content stored
- Pull sync: request missing content (fingerprint bloom filters for efficiency)
- Blob replication: fetch by BLAKE3 hash, verify on receipt
- Edition replication: transmit as `Vec<(i64, RangeElement)>`, verify each element's fingerprint
- Local caching: remote content in local BlobStore/edition cache, indexed by `FederatedId`
- Wire operations: `0x1403 sync_push`, `0x1404 sync_pull`, `0x1405 content_get`, `0x1406 blob_get`

**Key invariant**: `blake3(content_on_A) == blake3(content_on_B)`. No trust needed — just hash verification.

**Tests**: 2 servers; create work on A; replicate to B; verify B reads identical content. Tamper test: modify a byte in transit, verify rejection.

**Servers tested**: 2

---

#### Phase 17: Cross-Server Transclusion

**Goal**: The Xanadu vision — a span on Server A transcludes content from Server B.

**Key deliverables**:
- `RangeElement::FederatedEdition { federated_id }` in editions
- `RangeElement::FederatedWork { federated_id }` in editions
- Lazy resolution: local cache → origin server query → cache result
- Cross-server `TransclusionIndex`: fingerprint → `Vec<FederatedId>` across federation
- Cross-server `find_transcluders`: query peers for content matching a fingerprint
- Wire operations: `0x1407 resolve_edition`, `0x1408 resolve_work`, `0x1409 find_transcluders`, `0x140a transclusion_depth`

**This is the core Xanadu moment**: `transclude(span, view)` where the span can live on any server. The content fingerprint is the global identity.

**Tests**: 2 servers; work on A contains `FederatedEdition` pointing to edition on B; resolve and materialize on A.

**Servers tested**: 2

---

#### Phase 18: DagWood Reconciliation and Mutable State ✅

**Goal**: Concurrent edits from different servers coexist as alternatives. Endorsements propagate.

**Key deliverables**:
- OR-Set CRDT for endorsement propagation: `(endorsement, unique_tag)` — adds and removes are independent
- LWW-Register for mutable pointers (work current edition, branch heads)
- DagWood merge across servers: concurrent revisions preserved as `AlternativeSet`, never silently resolved
- Endorsement propagation via CRDT
- Wire operations: `0x1801 endorsement_sync`, `0x1802 endorsement_add`, `0x1803 endorsement_retract`, `0x1804 endorsement_query`, `0x1805 state_sync`, `0x1806 state_alternatives`
- Server-to-server frames: `EndorsementSyncPush/Result`, `StateSyncPush/Result`

**Key invariant**: DagWood's `AlternativeSet` means concurrent edits from different servers are always preserved. No silent resolution. Pure Xanadu.

**Tests**: 1,306 unit tests + 137 integration tests = 1,443 total, zero failures. Includes 29 new CRDT unit tests, 12 reconcile state tests, 7 server method tests, 5 integration tests.

**Documentation**: `docs/phase-18-dagwood-reconciliation.md`

**Servers tested**: 2 (3-server test deferred to Phase 19 federation transport improvements)

---

#### Phase 19: Trust, Governance and BFT

**Goal**: Federation membership is managed. Critical operations have Byzantine agreement. Royalty hooks activated.

**Key deliverables**:
- Endorsement-based web-of-trust: existing members sign new server's identity with Ed25519
- Federation membership: OR-Set CRDT of `(ServerIdentity, endorsement_chain)`
- Join protocol: new server obtains N endorsements, submits join request
- Custom lightweight PBFT for governance (~500–800 lines):
  - `federation/admit` — add server to federation
  - `federation/expel` — remove server
  - `federation/register_key` — register key ownership
  - `federation/record_royalty` — record royalty obligation (hook activated)
- Server scoring: trust metric from endorsements, uptime, correct behavior
- Wire operations: `0x140d join_request`, `0x140e endorse_server`, `0x140f expel`, `0x1410 bft_propose`, `0x1411 bft_vote`, `0x1412 record_royalty`

**BFT scope**: identity, key ownership, membership, royalty recording. Everything else uses CRDTs.

**Tests**: 3 servers; 4th requests join; endorsed by 2 of 3; admitted via PBFT. Test expulsion of misbehaving server.

**Servers tested**: 3 → 4 (join)

---

#### Phase 20: Attack Hardening

**Goal**: Federation survives malicious participants and network failures.

**Key deliverables**:
- Malicious server simulator (tampered content, replays, floods)
- Byzantine detection: hash mismatch logging, signature failure alerts, counter gap detection
- Rate limiting per peer (bytes/sec, ops/sec)
- Storage quotas per remote server
- Partition test: disconnect C from A+B; concurrent changes; reconnect; verify convergence
- Key rotation in federation: rotate keys, propagate via PBFT, old key valid for historical signatures
- Replay protection: reject messages with counter ≤ last seen
- Connection limits, message size limits, slow-loris protection
- Integration tests for each attack vector

**Tests**: Byzantine server simulation; partition tolerance; resource exhaustion; replay attacks.

**Servers tested**: 3 (one Byzantine)

---

#### Phase 21: Production Rollout

**Goal**: Run 3+ servers reliably with monitoring.

**Key deliverables**:
- Federation monitoring: peer status, sync lag, content count per server
- Operational runbook: add/remove server, key rotation, partition recovery
- Config validation at startup
- Graceful federation shutdown: notify peers before disconnecting
- Multi-machine deployment (separate machines, not just localhost)
- Performance benchmarks: sync throughput, cross-server transclusion latency
- Updated documentation

**Tests**: 3+ servers on separate machines; full cross-server transclusion; monitoring verified.

**Servers tested**: 3+ (separate machines)

---

#### Phase Dependency Graph

```
Phase 14 (Types/Identity)
    │
    ▼
Phase 15 (S2S Transport)
    │
    ▼
Phase 16 (Content Replication)
    │
    ▼
Phase 17 (Cross-Server Transclusion)  ← the Xanadu moment
    │
    ├──────────────────┐
    ▼                  ▼
Phase 18 (DagWood    Phase 19 (Trust/
  Reconciliation)      Governance/BFT)
    │                  │
    └────────┬─────────┘
             ▼
Phase 20 (Attack Hardening)
             │
             ▼
Phase 21 (Production Rollout)
```

Phases 18 and 19 address different concerns (reconciliation vs. trust) and can be partially parallelized.

#### Summary

| Phase | Key Milestone | Servers Tested |
|-------|--------------|---------------|
| 14 | Types and identity | 1 |
| 15 | Two servers talk | 2 |
| 16 | Content replicates | 2 |
| 17 | Cross-server transclusion | 2 |
| 18 | Concurrent edits reconcile | 3 |
| 19 | Governance and membership | 3→4 (join) |
| 20 | Survives attacks | 3 (Byzantine) |
| 21 | Production-ready | 3+ (separate machines) |

**Estimated scope**: ~3,000–4,000 lines of new code across Phases 14–19, plus ~1,500 lines of tests. The architecture heavily reuses existing crypto (Ed25519, X25519, ChaCha20-Poly1305, HKDF) and data structures (DagWood, ContentAddressIndex, TransclusionIndex).

### Federation Configuration

#### Closed Federation (Phases 14–18)

```toml
[federation]
enabled = true
peers = [
    "10.0.1.10:8081",
    "10.0.1.11:8081"
]
```

All listed peers are trusted. No endorsement chain required. Authentication is mutual Ed25519 handshake.

#### Open Federation (Phase 19+)

```toml
[federation]
enabled = true
mode = "open"
min_endorsements = 2
peers = [...]
```

New servers can join by obtaining endorsements from existing members. The `min_endorsements` parameter controls how many existing members must vouch for a new server.

#### Testing Locally

To test a 3-node federation on a single machine:

```bash
# Terminal 1: Server A
./target/debug/xudanu-server run 127.0.0.1:8080 --data-dir /tmp/xudanu-a

# Terminal 2: Server B
./target/debug/xudanu-server run 127.0.0.1:8081 --data-dir /tmp/xudanu-b

# Terminal 3: Server C
./target/debug/xudanu-server run 127.0.0.1:8082 --data-dir /tmp/xudanu-c
```

Each server gets its own data directory, snapshot file, Ed25519 identity, and key history. Federation connections are established between the separate `/federation` WebSocket endpoints.

### Federation Wire Protocol

Server-to-server communication uses the same codec infrastructure as the client protocol (JSON or binary), with federation-specific operation codes:

| Code | Operation | Phase | Purpose |
|------|-----------|-------|---------|
| `0x1401` | `federation_info` | 14 | Query server identity and capabilities |
| `0x1402` | `federation_peers` | 14 | List known federation peers |
| `0x1403` | `federation_sync_push` | 16 | Push new content to peers |
| `0x1404` | `federation_sync_pull` | 16 | Pull missing content from peers |
| `0x1405` | `federation_content_get` | 16 | Fetch specific content by FederatedId |
| `0x1406` | `federation_blob_get` | 16 | Fetch blob by BLAKE3 hash |
| `0x1407` | `federation_resolve_edition` | 17 | Resolve federated edition reference |
| `0x1408` | `federation_resolve_work` | 17 | Resolve federated work reference |
| `0x1409` | `federation_find_transcluders` | 17 | Find transcluders across federation |
| `0x140a` | `federation_transclusion_depth` | 17 | Query transclusion depth across servers |
| `0x140b` | `federation_endorsement_sync` | 18 | Propagate endorsement CRDT state |
| `0x140c` | `federation_state_sync` | 18 | Sync mutable state (branch heads, metadata) |
| `0x140d` | `federation_join_request` | 19 | Request to join the federation |
| `0x140e` | `federation_endorse_server` | 19 | Endorse a new server's identity |
| `0x140f` | `federation_expel` | 19 | PBFT proposal to expel a server |
| `0x1410` | `federation_bft_propose` | 19 | PBFT pre-prepare (propose governance op) |
| `0x1411` | `federation_bft_vote` | 19 | PBFT prepare/commit (vote on governance op) |
| `0x1412` | `federation_record_royalty` | 19 | Record royalty obligation via PBFT |

### Federation Domain Separation

Federation HKDF derivations extend the existing domain label scheme:

| Label | Purpose |
|-------|---------|
| `xudanu/v1/federation/handshake` | Federation handshake key derivation |
| `xudanu/v1/federation/aeed/server-to-server` | AEAD key for server-to-server frames (direction A→B) |
| `xudanu/v1/federation/aead/server-from-server` | AEAD key for server-to-server frames (direction B→A) |
| `xudanu/v1/federation/sync` | Content sync protocol key material |

These are separate from the client-server domain labels (`xudanu/v1/aead/client-to-server`, etc.), ensuring that a compromise of client-server session keys cannot affect server-to-server channels and vice versa.
