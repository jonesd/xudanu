# Phase 14: Federation Foundation

## Goal

Establish types, identity, and addressing for a multi-server world. No cross-server communication yet — this phase creates the foundation that all subsequent federation phases build on.

## What Was Added

### Federation Types (`src/server/federation.rs`)

A new module behind the `server` feature containing all federation types:

- **`FederatedId { server_id, local_id }`** — Globally unique content identification combining an origin server's identity with a local BeId. Display format: `server_id:local_id`.
- **`PeerAddress { host, port }`** — Network address of a federation peer.
- **`FederationConfig`** — Configuration for federation mode (closed/open), peer list, and minimum endorsements.
- **`FederationMode`** — Enum: `Closed` (trusted peers only) or `Open` (endorsement-based joining).
- **`FederationState`** — Runtime state: config, known peers, royalty ledger.
- **`FederationInfo`** — Response type for `federation_info` operation: server identity, capabilities, peers.
- **`FederationPeerInfo`** — Per-peer info: server_id, address, connection status.
- **`RoyaltyEntry`** — Hook for future royalty accounting: origin server, content fingerprint, royalty type, amount, timestamp.
- **`RoyaltyType`** — Enum: Transclusion, Reference, Access, Custom(String).

### Server Integration

- `Server.federation: FederationState` — New field, defaults to disabled.
- `Server.federation_info()` — Returns server identity, federation config, and peer list.
- `Server.federation_peers()` — Returns configured peer addresses.
- `Server.set_federation_config()` — Configures federation at runtime.
- `Server.federation_is_enabled()` — Checks if federation is active.

### Wire Operations (0x14xx)

| Code | Operation | Payload | Response |
|------|-----------|---------|----------|
| `0x1401` | `federation_info` | None | `FederationInfoResult` |
| `0x1402` | `federation_peers` | None | `FederationPeersResult` |

Both operations require **no authentication** — federation info is publicly visible, consistent with the pattern that identity and server metadata are public.

### Codec Entries

Full support in both JSON and binary codecs for `federation_info` and `federation_peers`.

## Design Decisions

### Federation as a Separate Module

All federation types and logic live in `src/server/federation.rs`. The Server struct has a single `federation: FederationState` field that encapsulates all state. Small delegation methods on Server keep the integration clean.

### Closed Federation First

The default `FederationConfig` has `enabled: false`. Phase 14-18 use config-based trusted peers. Phase 19 adds endorsement-based open joining.

### Royalty Hooks

`RoyaltyEntry` and `RoyaltyType` are defined now as hooks. They are not processed by any business logic yet. Phase 19 will activate them through the BFT governance layer.

### FederatedId Derives Hash, Eq, PartialEq

This enables FederatedId to be used as a HashMap key and in HashSets, which will be needed for content indexing and deduplication in Phase 16.

## Tests

### Unit Tests (13 in `federation.rs`)
- FederatedId: display, is_local, equality, hashable, serialize roundtrip
- PeerAddress: display, equality
- FederationConfig: default disabled, closed constructor, serialize roundtrip
- FederationState: add/remove peer, royalty ledger
- RoyaltyType: serialization

### Integration Tests (3 in `integration.rs`)
- `federation_info_returns_server_identity` — Verifies all fields in the response
- `federation_peers_returns_empty_when_unconfigured` — Empty peer list by default
- `federation_info_no_auth_required` — Works without login

## Test Counts

- Unit tests: 1,215 passing (up from 1,202)
- Integration tests: 123 passing (up from 120)
- Total: **1,338 tests passing**, zero failures

## What's Next

Phase 15 will add server-to-server transport: the `/federation` WebSocket endpoint, mutual Ed25519 handshake, and encrypted channel between servers. It will reuse the existing crypto stack (`sign_handshake`, `derive_session_keys`, `SessionCipher`).
