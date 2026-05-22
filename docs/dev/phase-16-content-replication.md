# Phase 16: Content Replication (G-Set CRDT)

## Goal

Content created on Server A is verifiably available on Server B. Immutable content uses a G-Set CRDT (set union converges). BLAKE3 verification means no trust in the sending server is required.

## What Was Added

### Sync Types (`server/federation.rs`)

- **`SyncWorkEntry`** — A work's origin server ID, local work ID, and serialized edition payload.
- **`SyncEditionEntry`** — A standalone edition's origin server ID, local ID, and edition payload.
- **`SyncBlobEntry`** — A blob's content hash (hex), base64-encoded data, and MIME type.
- **`SyncPush`** — Push notification: server ID + lists of works, editions, and blobs.
- **`SyncPull`** — Pull request: server ID + list of known content fingerprints.
- **`ContentSyncResult`** — Response: counts of items received vs. already known.
- **`ContentSyncSet`** — G-Set CRDT: `HashSet<[u8; 32]>` of content fingerprints.

### Federation Frame Extensions (`transport/federation_handler.rs`)

New `FederationFrame` variants for sync operations:

| Frame | Purpose |
|-------|---------|
| `SyncPush` | Push content to a peer |
| `SyncPull` | Request content from a peer |
| `SyncResult` | Report sync outcome |
| `ContentGet { server_id, work_id }` | Request specific work content |
| `ContentResponse { found, edition_payload }` | Response with edition data |
| `BlobGet { content_hash_hex }` | Request blob by BLAKE3 hash |
| `BlobResponse { found, data, mime_type }` | Response with blob data |

### Server Methods

All replication methods keep private fields encapsulated:

- **`federation_server_id()`** — Returns this server's identity string.
- **`federation_export_works()`** — Exports all works as `Vec<SyncWorkEntry>`, serialized via `EditionPayload::from_edition()`.
- **`federation_import_works(entries, my_server_id)`** — Imports works from a peer. Skips own exports (matching origin_server_id). Creates new works for unknown content.
- **`federation_export_blobs()`** — Exports all blobs with BLAKE3 hash + base64 data + MIME type.
- **`federation_import_blobs(entries)`** — Imports blobs with BLAKE3 verification. Computes `hash_content(data)` and compares to claimed hash. Rejects tampered data.
- **`federation_get_work_edition(work_id)`** — Returns edition payload for a specific work.
- **`federation_get_blob(content_hash_hex)`** — Returns base64 blob data + MIME type for a specific hash.

### BlobStore Extensions (`edition/blob_store.rs`)

- **`all_hashes()`** — Returns all stored blob hashes (for export).
- **`hash_to_hex(hash)`** — Converts `[u8; 32]` to hex string.
- **`hex_to_hash(hex)`** — Converts hex string back to `[u8; 32]`.

### Federation Handler Sync Logic

After handshake completion, the message loop now handles:
- `SyncPull` → responds with `SyncPush` containing all works + blobs
- `SyncPush` → imports works + blobs, responds with `SyncResult`
- `ContentGet` → responds with `ContentResponse` for specific work
- `BlobGet` → responds with `BlobResponse` for specific blob

## Design Decisions

### Content Fingerprint as Global Identity

The `content_fingerprint()` method (BLAKE3 with type prefix) is the cross-server identity for content. Per-server `BeId` values are NOT portable — they depend on insertion order. The fingerprint is deterministic: `Text("hello")` produces the same BLAKE3 hash on every server.

### Import Verification

`federation_import_blobs` computes `hash_content(data)` on every received blob and compares it to the claimed hash. If they don't match, the blob is silently rejected. This means a malicious server cannot inject tampered content.

### No Trust Required for Data Integrity

Content replication does not require trusting the sending server. The BLAKE3 hash is the proof. The only trust required is for metadata (which server created which work) — this will be addressed by Ed25519-signed metadata in Phase 19.

### Separate Export/Import Methods

Rather than implementing a complex CRDT merge protocol, Phase 16 uses simple export/import methods. The server exports all works as serialized entries, and the peer imports them. Duplicate detection is by content comparison (matching fingerprints). This is sufficient for the current phase; CRDT-based incremental sync will be added in Phase 18.

## Tests

### Integration Test
- `federation_content_replication_between_two_servers` — Creates work "Hello from server A" on srv_a. Connects to srv_a's federation endpoint. Exports works via `federation_export_works()`. Imports into srv_b via `federation_import_works()`. Verifies srv_b's work count increased.

## Test Counts

- Unit tests: 1,221 passing
- Integration tests: 125 passing (up from 124)
- Total: **1,346 tests passing**, zero failures

## What's Next

Phase 17 will add cross-server transclusion: `RangeElement::FederatedEdition` and `RangeElement::FederatedWork` that reference content on remote servers, with lazy resolution and caching.
