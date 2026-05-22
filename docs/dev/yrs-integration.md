# Yrs Integration

## Overview

Xudanu uses [yrs](https://crates.io/crates/yrs) v0.25.0 — the official Rust port of [Yjs](https://yjs.dev/) by Kevin Jahns — as its CRDT engine. This replaces our original custom CRDT implementation, which had 21 test failures due to fundamental algorithmic bugs in concurrent delete handling and out-of-order delivery.

The integration is a thin wrapper: `xudanu-core::Document` wraps `yrs::Doc` and `yrs::TextRef`, translating between our public API and yrs's internal operations. Xudanu adds cryptographic signing, provenance tracking, and royalty computation on top.

## Architecture

```
┌──────────────────────────────────────────┐
│  xudanu-wasm (editor bindings)           │
├──────────────────────────────────────────┤
│  SignedDocument (sign + verify layer)    │
├──────────────────────────────────────────┤
│  Document (yrs::Doc wrapper)             │
│   ├── yrs::TextRef ("main")              │
│   ├── authorship via __author attribute  │
│   ├── StateVector (our SiteId-keyed)     │
│   └── change_dag (ChangeHash → Change)   │
├──────────────────────────────────────────┤
│  yrs 0.25.0 (CRDT engine, MIT license)  │
│   ├── YATA algorithm (char-level clocks) │
│   ├── out-of-order update buffering      │
│   ├── sync protocol (extensible)         │
│   └── awareness / presence               │
└──────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Random Client IDs (not derived from author identity)

**Decision**: Each `Document` instance uses `yrs::Doc::new()` which generates a random `u64` client ID.

**Why**: yrs requires unique client IDs per active replica. The docs state: *"potential concurrent changes made by different peers sharing the same ClientID will cause a document state corruption."* Our original approach of deriving client IDs from Ed25519 public keys would cause corruption when two documents from the same author sync with each other.

**Implication**: Author identity is tracked separately via a `client_author_map: HashMap<u64, AuthorId>` and via `__author` formatting attributes on text. The Change object carries `sender_client_id: u64` so receivers can build this mapping.

### 2. Author Attribution via Formatting Attributes

**Decision**: Every text insertion uses `TextRef::insert_with_attributes()` with an `__author` attribute containing the hex-encoded Ed25519 public key.

**Why**: yrs's `diff()` method merges adjacent text blocks that have the same formatting attributes, even if they're from different clients. Without a distinguishing attribute, `diff()` would return "Hello World" as a single chunk, making multi-author attribution impossible. With the `__author` attribute, `diff()` separates blocks by author, returning ["Hello " (Alice), "World" (Bob)].

**Fallback**: If a chunk's `__author` attribute is missing (e.g., from a client that doesn't set it), we fall back to looking up the client ID in `client_author_map`, then to the local document's author.

### 3. Update-Level Sync (not operation-level)

**Decision**: `commit_change()` captures a serialized yrs update blob (`Vec<u8>`) via `txn.encode_diff_v1()`. `integrate_change()` applies it via `txn.apply_update(Update::decode_v1(&bytes)?)`.

**Why**: yrs's internal representation is a compressed binary format. Exposing individual operations would require decoding and re-encoding, losing yrs's optimizations (pending update buffering, block merging, garbage collection). The update blob is opaque but self-contained.

**Implication**: Our `Change.operations` field is empty when using yrs. The `Change.update_bytes` field carries the actual sync data. The signing layer signs the full `update_bytes` blob, ensuring non-repudiation of the complete change.

### 4. State Vector Compatibility

**Decision**: We maintain our own `StateVector` (keyed by `SiteId`, which is `[u8; 32]`) alongside yrs's internal `StateVector` (keyed by `u64` client ID).

**Why**: The sync layer (`xudanu-sync`) uses our `StateVector` type. Changing it would require rewriting the sync crate. The two state vectors serve different purposes:
- yrs's SV: drives `encode_diff_v1()` for computing incremental updates
- Our SV: tracks which sites/clocks we've seen, used by the sync protocol

### 5. Deep-Copy Branches

**Decision**: `create_branch()` serializes the full document state via `encode_state_as_update_v1()`, creates a new `yrs::Doc`, and applies the serialized state.

**Why**: `yrs::Doc` uses `Arc<DocInner>` internally — `clone()` gives a second reference to the same document. Editing a branch would edit the main document. Deep copy via serialize/deserialize creates a truly independent replica.

## Position Handling

yrs uses UTF-16 code unit offsets by default (for JavaScript compatibility). Our API uses Unicode character (code point) positions. The `Document` converts between them:

```rust
fn char_to_byte_offset(&self, char_index: usize) -> u32 {
    // Walk the string to find the byte offset for a given char position
    let s = self.text.get_string(&txn);
    s.char_indices().nth(char_index).map(|(i, _)| i).unwrap_or(s.len())
}
```

For `len()`, we return `s.chars().count()` rather than `text.len(&txn)` which returns UTF-16 code unit count.

**Limitation**: This approach works correctly for all current tests (ASCII, Chinese characters, emoji at position 0). Inserting at a position *within* a multi-UTF-16-unit character (e.g., inside an emoji) would need additional handling. This is a known limitation that should be addressed when integrating with real editors.

## Out-of-Order Delivery

yrs handles out-of-order delivery internally. When an update references blocks that don't exist yet (because earlier updates haven't arrived), yrs buffers it and applies it when the dependencies arrive. This means our `pending_changes` buffering in `Document` is mostly redundant for the simple case, but we keep it as a safety net for malformed updates that fail to decode.

## Files

| File | Purpose |
|------|---------|
| `crates/core/src/doc.rs` | `Document` struct wrapping `yrs::Doc` |
| `crates/core/src/signed_doc.rs` | `SignedDocument` adding sign/verify on top |
| `crates/core/src/state_vector.rs` | Our `StateVector` type (SiteId-keyed) |
| `crates/core/src/lib.rs` | Module declarations and re-exports |
| `crates/core/tests/convergence.rs` | 30 convergence tests (all passing) |
| `crates/core/tests/integration.rs` | 26 integration tests (all passing) |
| `crates/core/tests/signing_integration.rs` | 7 signing tests (all passing) |

## Dependencies

```toml
[dependencies]
yrs = "0.25"           # CRDT engine
xudanu-types = ...     # Shared types
xudanu-signing = ...   # Ed25519 signing
ed25519-dalek = ...    # Signature primitives
sha2 = ...             # Hashing for client_id derivation
hex = ...              # Encoding for author attributes
```

## References

- [yrs crate](https://crates.io/crates/yrs) — Rust implementation
- [y-crdt GitHub](https://github.com/y-crdt/y-crdt) — Source and documentation
- [Yjs](https://yjs.dev/) — JavaScript original
- [YATA paper](https://www.researchgate.net/publication/310212186_Nuno_Preguiça) — The CRDT algorithm behind Yjs
