# Phase 15: Server-to-Server Transport

## Goal

Two servers can authenticate and establish an encrypted channel via the `/federation` WebSocket endpoint. The handshake is mutual Ed25519 with X25519 key exchange, reusing the existing crypto stack.

## What Was Added

### Peer-to-Peer Key Exchange (`crypto/kex.rs`)

- **`peer_key_exchange(my_static, peer_static_public, my_ephemeral, peer_ephemeral)`** — Symmetric key derivation for equal peers. Uses X25519 static-static DH + canonical transcript of ephemeral keys. Both sides compute the same shared secret regardless of connection direction.
- **`canonical_transcript(eph_a, eph_b)`** — Deterministic ordering: lower public key first. Ensures both sides compute the same transcript hash.
- 2 new tests: `peer_key_exchange_symmetric` (both sides get same secret), `peer_key_exchange_differs_for_different_peers`.

### Federation Session Keys (`crypto/kdf.rs`)

- **`FederationSessionKeys { outbound, inbound }`** — Separate keys for each direction, zeroized on drop.
- **`derive_federation_session_keys(shared_secret, handshake_hash)`** — Uses domain labels `xudanu/v1/federation/aead/server-to-server` and `xudanu/v1/federation/aead/server-from-server`.
- 3 new domain labels added to `DomainLabel`.

### Federation WebSocket Handler (`transport/federation_handler.rs`)

New module handling the `/federation` WebSocket route:

**Handshake protocol (4 messages, no round-trip waste):**

```
Server A                              Server B
    │──── Hello {ephemeral, server_id} ──→│
    │←─── Hello {ephemeral, server_id} ───│
    │                                     │
    │──── Signature {sig, signing_key, ──→│
    │      kex_key}                       │
    │←─── Signature {sig, signing_key, ───│
    │      kex_key}                       │
    │                                     │
    │  Both verify peer signature against │
    │  Ed25519 signing key                │
    │  Both derive session keys via       │
    │  peer_key_exchange + HKDF           │
    │                                     │
    │──── Ready {server_id, "connected"} ─→│
    │←─── Ready {server_id, "connected"} ─│
    │                                     │
    │═══════ encrypted channel ═══════════│
    │    (heartbeat/ack keepalive)        │
```

**Frame types:**
- `FederationFrame::Hello` — protocol version, ephemeral public key, server ID
- `FederationFrame::Signature` — Ed25519 signature, signing key, KEX key
- `FederationFrame::Ready` — server ID, connection status
- `FederationFrame::Heartbeat` / `FederationFrame::Ack` — keepalive

### Server Integration

Three new methods on `Server` that keep private keys encapsulated:
- `federation_handshake_init()` — generates ephemeral keypair, returns server ID and public bytes
- `federation_sign_handshake(my_eph, peer_eph)` — signs the handshake transcript with the server's Ed25519 key
- `federation_derive_session_keys(peer_kex, my_eph, peer_eph)` — derives `FederationSessionKeys` using `peer_key_exchange`

The server binary now merges both routers:
```rust
let client_router = build_router(state.clone());
let federation_router = build_federation_router(state.clone());
let app = merge_routers(client_router, federation_router);
```

### Single Port

Both client (`/xudanu`) and federation (`/federation`) endpoints share the same port. No separate listener needed.

## Design Decisions

### Same Port, Different Route

Adding `/federation` as a route on the existing axum router is simpler than running a separate listener. Deployment stays one-port. The federation handler has its own auth flow (mutual Ed25519 handshake) completely independent of client sessions.

### Private Keys Stay in Server

The `Server` struct keeps `server_keypair` private. Three new methods (`federation_handshake_init`, `federation_sign_handshake`, `federation_derive_session_keys`) perform all crypto operations inside the `with_server` closure. The federation handler never sees private keys.

### Canonical Transcript Ordering

`canonical_transcript(eph_a, eph_b)` uses lexicographic ordering (lower public key first) so both sides compute the same hash regardless of who initiated the connection. This is critical for the symmetric `peer_key_exchange`.

### Static-Static DH + Ephemeral Transcript

`peer_key_exchange` uses static-static X25519 DH for the shared secret, with ephemeral keys mixed in via the transcript hash. This provides:
- **Authentication**: bound to long-term static keys (verified via Ed25519 signature)
- **Forward secrecy**: ephemeral keys change per-connection, mixed into the key derivation
- **Simplicity**: no need for ephemeral-ephemeral DH (which x25519-dalek's `EphemeralSecret` makes awkward since it consumes self)

## Tests

### Unit Tests
- 2 new KEX tests (peer_key_exchange_symmetric, peer_key_exchange_differs_for_different_peers)
- 4 new federation handler tests (Hello, Signature, Heartbeat, Ready roundtrip serialization)

### Integration Test
- `federation_handshake_between_two_servers` — Creates 2 `FederationTestServer` instances on random ports. Both connect to each other's `/federation` endpoint. Performs full 4-message handshake (Hello + Signature exchange). Verifies both sides reach `Ready { status: "connected" }`. Tests heartbeat/ack keepalive.

## Test Counts

- Unit tests: 1,221 passing (up from 1,215)
- Integration tests: 124 passing (up from 123)
- Total: **1,345 tests passing**, zero failures

## What's Next

Phase 16 will add content replication: G-Set CRDT for immutable content, push/pull sync between servers, blake3 verification on receipt.
