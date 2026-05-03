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
