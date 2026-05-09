# xudanu

Conflict-preserving hypertext document store. A Rust implementation of the Udanax Gold model with server, web frontend, and federation support.

## What It Is

xudanu implements the Udanax Gold hypertext model, where content is identity. Documents are content-addressed O-trees stored in a GrandMap that deduplicates at the byte level. The same text appearing in multiple documents shares a single `BeId`, making transclusion automatic rather than manual.

The core data structure is a partially ordered trace history (DagWood) that preserves all revisions and their relationships. Editions build on previous editions with structural sharing, so nothing is overwritten or lost. Bidirectional links connect documents without embedding, and every link is tracked in both directions.

## Prerequisites

- **Rust** 1.56 or later (edition 2021). Latest stable recommended. Install via [rustup](https://rustup.rs):
  ```
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```
- **A browser** — Firefox recommended (Safari has WebSocket restrictions with HTTP)

## Quick Start

**1. Build the server:**
```
cd original-code/xanadugold/src-rust
cargo build --features server
```

**2. Initialize a data directory and start the server:**
```
./target/debug/xudanu-server init /tmp/xudanu-data
./target/debug/xudanu-server run 127.0.0.1:8090 /tmp/xudanu-data --static-dir ./static
```

**3. Open in your browser:**
```
http://127.0.0.1:8090
```

The `--static-dir` flag serves frontend files directly from disk, so HTML/JS changes take effect on refresh without rebuilding.

### First Steps

1. **Create a document** — click the **+** button in the sidebar. A new empty document opens in edit mode. Type some text and click **Save**.
2. **Edit and revise** — click **Edit** to grab the document, make changes, then **Save**. Use the revision slider to browse history.
3. **Upload images** — paste an image or drag-and-drop a file into the editor. Images are content-addressed and deduplicated via BLAKE3 fingerprints.
4. **Compare two documents** — create a second document with some overlapping text. Select the first document, click **Compare**, choose the second document, and click **Open**. You'll see:
   - **Amber underlines** = shared content (transclusions), with bridge curves connecting them across panes
   - **Blue tint** = content unique to the left document
   - **Orange tint** = content unique to the right document
5. **Edit in compare view** — each pane has its own **Edit/Save/Cancel** buttons. Edits update the highlighting live.

### From the workspace root

```
cargo run --features server --bin xudanu-server --manifest-path original-code/xanadugold/src-rust/Cargo.toml -- run 127.0.0.1:8090 /tmp/xudanu-data --static-dir original-code/xanadugold/src-rust/static
```

### Presentations and Diagrams

- **[slides.html](static/slides.html)** — 10-slide presentation covering Xanadu history, architecture, optimizations, and demo (arrow keys to navigate)
- **[diagram.html](static/diagram.html)** — interactive architecture diagram showing O-tree / H-tree / Canopy layering with Big-O performance table

Both can be opened directly in a browser while the server is running.

## CLI Reference

```
xudanu-server init <data-dir>              Initialize a new data directory
xudanu-server run [addr] [data-dir]        Run the server (default: 127.0.0.1:8080)
xudanu-server verify <data-dir>            Verify snapshot integrity
```

Run options:

```
--static-dir <dir>    Serve frontend from a custom directory instead of embedded HTML
--peer <addr>         Connect to a federated peer server
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

This Rust implementation is licensed under **Apache 2.0** (Copyright 2026 David G Jones and contributors).

The original Udanax Gold C++ codebase (in `../src/`) is licensed under the **MIT/X11 license** (Copyright 1979-1999 Udanax.com, released open-source August 23, 1999). See [udanax.xanadu.com](http://udanax.xanadu.com/) for the original announcement and license details.
