# xudanu

Conflict-preserving hypertext document store. A Rust implementation of the Udanax Gold model with server, web frontend, and federation support.

## What It Is

xudanu implements the Udanax Gold hypertext model, where content is identity. Documents are content-addressed O-trees stored in a GrandMap that deduplicates at the byte level. The same text appearing in multiple documents shares a single `BeId`, making transclusion automatic rather than manual.

The core data structure is a partially ordered trace history (DagWood) that preserves all revisions and their relationships. Editions build on previous editions with structural sharing, so nothing is overwritten or lost. Bidirectional links connect documents without embedding, and every link is tracked in both directions.

## Features

- **Content-addressed blob storage** with BLAKE3 fingerprints and deduplication via a global GrandMap
- **Edition-based document revision** with structural sharing across versions
- **Transclusion tracking** — find where any content element is reused across all documents
- **Three-plane architecture** — Content (CRDT), Reconciliation (DagWood partial ordering), Governance (PBFT)
- **Web-of-trust membership** with Ed25519 endorsements and membership proofs
- **PBFT consensus** for governance operations (admit/expel members, key rotation, royalty)
- **WebSocket API** with JSON and binary (postcard) wire protocols
- **Embedded web frontend** with document editing, revision browsing, link management, and image upload
- **Federation** with encrypted peer channels (X25519 key exchange, ChaCha20-Poly1305)
- **WASM support** for browser-side library use via `wasm-bindgen`

## Quick Start

```
cargo build --features server
./target/debug/xudanu-server run
```

Open http://127.0.0.1:8080 in a browser.

## CLI Reference

```
xudanu-server init <data-dir>              Initialize a new data directory
xudanu-server run [addr] [data-dir]        Run the server (default: 127.0.0.1:8080)
xudanu-server verify <data-dir>            Verify snapshot integrity
```

Run options:

```
--static-dir <dir>    Serve frontend from a custom directory instead of embedded HTML
```

Data is checkpointed to `server.json` in the data directory on graceful shutdown (Ctrl-C).

## Feature Flags

| Flag | Enables |
|---|---|
| `server` | Tokio async runtime, Axum HTTP/WebSocket server, federation transport, cryptography, admin CLI |
| `wasm` | `wasm-bindgen` bindings, browser panic hook, JS interop types |
| `serde` | Serialize/deserialize derives on core types |
| `serde_json` | JSON serialization support |

The `server` flag implies `serde` and `serde_json`. The `wasm` flag also implies `serde` and `serde_json`.

Default features: none. The library core (edition, ent, space, persist) builds with no features enabled.

## Building

**Server binary:**
```
cargo build --features server
```

**WASM library:**
```
cargo check --features wasm --target wasm32-unknown-unknown
```

**Library only** (edition, ent, space, persist modules, no server or WASM):
```
cargo build
```

## Testing

**Full suite (includes integration tests):**
```
cargo test --features server
```

**Library only:**
```
cargo test --features "serde,serde_json"
```

Integration tests are gated behind the `server` feature and require `tokio`, `tokio-tungstenite`, and `reqwest` (listed in `[dev-dependencies]`).

## Architecture

```
src/
  lib.rs          Top-level module re-exports
  edition/        Document revision model (O-tree, GrandMap, editions)
  ent/            Entity store (DagWood, BranchStore, TracePosition)
  space/          Assertion store and materialization
  persist/        Snapshot serialization and checkpointing
  crypto/         Ed25519, X25519, ChaCha20-Poly1305, BLAKE3, Argon2
  server/         Server implementation
    admin/        Club-based permissions
    club/         Named permission groups
    detector/     Event detection on document changes
    federation/   Peer state, PBFT consensus, membership, governance
    keymaster/    Key management
    lock/         Document locking (shared, exclusive, challenge)
    server/       Core server state and operations
    session/      Client session tracking
    transport/    HTTP/WebSocket handlers, federation wire protocol
  wasm/           WASM bindings for browser use
```

The three-plane model separates concerns:

- **Content plane** — CRDT-based assertions about document content (create node, set text, create span)
- **Reconciliation plane** — DagWood partial ordering determines how concurrent edits relate
- **Governance plane** — PBFT consensus for membership and policy decisions across federated peers

## Custom Frontend

Pass `--static-dir <path>` to serve static files from a directory. The server serves `index.html` at `/` and other files at their relative paths. Connect to the server via WebSocket at `/xudanu?format=json&version=2`. See [docs/custom-frontend.md](docs/custom-frontend.md) for a complete guide and minimal example.

## License

Research and educational project based on the original Udanax Gold code.
