# xudanu

Conflict-preserving hypertext document store. A Rust implementation of the Udanax Gold model with server, web frontend, and federation support.

## What It Is

**One-line summary:** xudanu is a document server where content is identity — the same text in multiple documents is automatically shared (transcluded), every revision is preserved, and bidirectional links connect everything.

xudanu implements the Udanax Gold hypertext model, where content is identity. Documents are content-addressed O-trees stored in a GrandMap that deduplicates at the byte level. The same text appearing in multiple documents shares a single `BeId`, making transclusion automatic rather than manual.

The core data structure is a partially ordered trace history (DagWood) that preserves all revisions and their relationships. Editions build on previous editions with structural sharing, so nothing is overwritten or lost. Bidirectional links connect documents without embedding, and every link is tracked in both directions.

## Prerequisites

- **Rust** 1.56 or later (edition 2021). Latest stable recommended. Install via [rustup](https://rustup.rs):
  ```
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```
- **A browser** — Firefox, Safari, or Chrome. Use `./scripts/caddy.sh` for HTTPS if needed (Safari requires HTTPS for WebSocket)

## Quick Start

```bash
git clone <repo-url> xudanu
cd xudanu
cargo build --features server -p xudanu
./target/debug/xudanu-server run 127.0.0.1:8090
```

Then open **http://127.0.0.1:8090** in your browser. Documents are stored in memory and lost on restart — see below for persistent storage options.

### Persistent Storage

```bash
# Initialize a data directory (creates manifest.json, blobs/, server.key)
./target/debug/xudanu-server init /tmp/xudanu-data

# Run with persistent storage
./target/debug/xudanu-server run 127.0.0.1:8090 /tmp/xudanu-data --static-dir original-code/xanadugold/src-rust/static
```

Data is saved to `manifest.json` on graceful shutdown (Ctrl-C) and restored on next start. The server's identity key (`server.key`) is generated automatically on first init.

### Encrypted Server Keys

By default, the server key file (`server.key`) is stored as plaintext JSON. To encrypt it with a passphrase:

```bash
# Initialize with an encrypted key
XUDANU_KEY_PASSPHRASE="your-secret" ./target/debug/xudanu-server init /tmp/xudanu-data

# Run with the same passphrase to decrypt the key
XUDANU_KEY_PASSPHRASE="your-secret" ./target/debug/xudanu-server run 127.0.0.1:8090 /tmp/xudanu-data
```

Or use the CLI flag (note: visible in `ps aux`, prefer the env var for production):

```bash
./target/debug/xudanu-server run 127.0.0.1:8090 /tmp/xudanu-data --key-passphrase "your-secret"
```

The encrypted key file uses Argon2id key derivation + ChaCha20-Poly1305 AEAD encryption with a BLAKE3 integrity check — the same scheme used for club keys. Old plaintext key files are still loaded for backward compatibility (a warning is logged).

### Using `./scripts/single.sh`

```bash
# From the repo root:
cd original-code/xanadugold/src-rust
./scripts/single.sh 8090
```

### Using the Web UI

The web interface has a document list on the left and an editor on the right:

- **Sidebar** — lists all documents. Click to open. Click **+** to create a new document.
- **Editor** — displays document content. Click **Edit** to grab the document for editing, make changes, then **Save** (or **Cancel** to discard). Only one person can edit a document at a time.
- **Revision history** — after saving, use the slider above the editor to browse previous versions.
- **Compare view** — click **Compare** to open a second document side-by-side. Shared content is highlighted:
  - **Amber underlines** = transclusions (shared text), with bridge curves connecting them
  - **Blue tint** = content unique to the left document
  - **Orange tint** = content unique to the right document
- **Images** — paste an image or drag-and-drop a file into the editor. Images are content-addressed and deduplicated via BLAKE3 fingerprints.
- **Links** — click **Links** to see bidirectional connections between documents.
- **Find refs** — click **Find Refs** to discover other documents that share content with the current document.
- **Theme** — toggle between dark and light mode with the theme button in the header.
- **Command bar** — type commands in the URL-style bar at the top:
  - `help` — list available commands
  - `create <text>` — create a new document with optional text
  - `list` — refresh the document list
  - `open <id>` — open a document by ID
  - `grab <id>` — grab a document for editing
  - `revise <id> <text>` — revise a document with new text
  - `release <id>` — release a grabbed document
  - `info` — show server statistics

### From the workspace root

```
cargo run --features server --bin xudanu-server --manifest-path original-code/xanadugold/src-rust/Cargo.toml -- run 127.0.0.1:8090 /tmp/xudanu-data --static-dir original-code/xanadugold/src-rust/static
```

### Presentations and Diagrams

- **[Technical Architecture](../../docs/technical-architecture.html)** — comprehensive walkthrough of core mechanisms: O-trees, GrandMap deduplication, Canopy flag-bit pruning, H-tree version ancestry, transclusion queries at O(log n), DagWood concurrent edits, and Big-O analysis with worked examples. Recommended for all developers and architects.
- **[slides.html](static/slides.html)** — 10-slide presentation covering Xanadu history, architecture, optimizations, and demo (arrow keys to navigate)
- **[diagram.html](static/diagram.html)** — interactive architecture diagram showing O-tree / H-tree / Canopy layering with Big-O performance table

All can be opened directly in a browser.

## Security Warning

**Do not expose this server directly to the internet without additional protection.**

The server's built-in Club-based access control system (clubs, read/edit permissions, admin roles) is **not yet fully implemented** for production use. Currently:

- All documents are readable and editable by anyone who connects
- The admin API has no authentication gate
- There is no user account or login system wired up for general use

If you are making the service available beyond your local machine, **you must add your own security layer**. The recommended approach is to run a reverse proxy with authentication in front of the server (see "Caddy Reverse Proxy" below). Options include:

- **Caddy** with HTTP Basic Auth (see below -- easiest)
- **nginx** with HTTP Basic Auth or OAuth2 proxy
- **Cloudflare Tunnel** with Access policies
- **Tailscale / WireGuard** for private network access

The Club and KeyMaster security infrastructure exists in the codebase and will be activated in a future release.

## CLI Reference

```
xudanu-server init <data-dir>              Initialize a new data directory
xudanu-server run [addr] [data-dir]        Run the server (default: 127.0.0.1:8080)
xudanu-server verify <data-dir>            Verify snapshot integrity
```

Run options:

```
--static-dir <dir>       Serve frontend from a custom directory instead of embedded HTML
--tls-cert <path>        TLS certificate PEM file (enables HTTPS)
--tls-key <path>         TLS private key PEM file (enables HTTPS)
--peer <addr>            Connect to a federated peer server
--federation-mode <mode> Federation mode: closed (default) or open
--key-passphrase <pw>    Passphrase for encrypted server key file (env: XUDANU_KEY_PASSPHRASE)
```

Data is checkpointed to `manifest.json` in the data directory on graceful shutdown (Ctrl-C).

### HTTPS / TLS Setup

For local development, plain HTTP on localhost works fine. For remote access or production use, you need TLS. There are two approaches:

**Self-signed certificate (testing):**

```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj '/CN=localhost' -addext 'subjectAltName=DNS:localhost,IP:127.0.0.1'

./target/debug/xudanu-server run 0.0.0.0:443 /tmp/xudanu-data --tls-cert cert.pem --tls-key key.pem
```

**Let's Encrypt (production) — automated with certbot:**

```bash
sudo apt install certbot
sudo certbot certonly --standalone -d yourdomain.com

./target/debug/xudanu-server run 0.0.0.0:443 /path/to/data \
  --tls-cert /etc/letsencrypt/live/yourdomain.com/fullchain.pem \
  --tls-key /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

Certbot will renew certs automatically. Add a cron job to restart the server after renewal:

```bash
echo '0 3 * * * root certbot renew --quiet --deploy-hook "systemctl restart xudanu"' | sudo tee /etc/cron.d/xudanu-renew
```

See [docs/tls-setup.md](docs/tls-setup.md) for detailed instructions including DNS setup, firewall config, and multi-domain certificates.

### Caddy Reverse Proxy (Auth + HTTPS)

**Recommended if exposing the server beyond localhost.** Caddy provides password protection, HTTPS, and WebSocket proxying in a single binary.

**1. Install Caddy:**
```bash
brew install caddy                    # macOS
sudo apt install caddy                # Ubuntu/Debian
```

**2. Start Xudanu + Caddy together:**
```bash
./scripts/caddy.sh                    # local dev: https://localhost:8443
./scripts/caddy.sh production         # production: https://yourdomain.com
```

This starts Xudanu on port 8090 (no TLS) and Caddy on port 8443 with self-signed HTTPS and HTTP Basic Auth in front.

**3. Change the default password:**
```bash
caddy hash-password --plaintext 'your-new-password'
# Edit the hash in Caddyfile
```

Default credentials: `admin` / `changeme` -- **change this before exposing to the internet.**

For production, uncomment the production block in `Caddyfile` and set your domain. Caddy will automatically provision a Let's Encrypt certificate. See [docs/tls-setup.md](docs/tls-setup.md) for full details.

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
