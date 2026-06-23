# AGENTS.md — xudanu

**GitHub:** https://github.com/jonesd/xudanu

Conflict-preserving hypertext document store with a collaborative CRDT editing
frontend. The project is split across two trees:

- **Backend (Rust):** `original-code/xanadugold/src-rust/`  *(this directory)*
- **Frontend (Vite/React):** `web/app/`  *(sibling of `original-code/` under the workspace root)*

## Technology

**Backend** — Rust (edition 2021). Crate name `xudanu` (v0.7.9).
- Async runtime: `tokio`; web framework: `axum` 0.8 (HTTP + WebSocket).
- TLS: `rustls` / `axum-server`; crypto: `chacha20poly1305`, `x25519-dalek`,
  `ed25519-dalek`, `argon2`, `ring`, `blake3`.
- Serialization: `postcard` (wire) + `serde_json` (manifests/API).
- Auth: OAuth2 (GitHub, Google), CSRF tokens, passphrase-protected server keys.
- Federation between server peers over WebSocket.
- Optional `wasm` target (`crate-type = ["cdylib", "rlib"]`) for in-browser use.

**Frontend** — React 19 + TypeScript, Vite 8, Vitest. Single-page app that
talks to the backend over HTTP (`/api`, `/auth`, `/health`, `/csrf-token`) and
WebSocket (`/xudanu`).

## Feature flags

```
default = []
server  # enables tokio/axum/persistence/crypto — required for binaries & tests
wasm    # browser build via wasm-bindgen
```
The `server` feature is required to build either binary and to run the test suite.

## Build

```sh
# Backend release binary (from src-rust/)
cargo build --release --features server --bin xudanu-server

# Also available: xudanu-cli, and the wasm crate
cargo build --release --features server --bin xudanu-cli
cargo build --features wasm --target wasm32-unknown-unknown

# Frontend (from web/app/)
npm install
npm run build        # tsc -b && vite build -> dist/
```

## Run (development)

Run **both** servers; the Vite dev server proxies API/WS calls to the backend.

```sh
# 1. Backend on 127.0.0.1:8080, data dir at ./data  (from src-rust/)
cargo run --release --features server --bin xudanu-server -- run 127.0.0.1:8080 data
#   - `run [addr] [data-dir]`  (addr defaults 127.0.0.1:8080; data-dir optional)
#   - data dir: if manifest.json exists it restores; otherwise initializes fresh
#   - other subcommands: init | verify | rebuild-manifest | verify-security-log | preflight

# 2. Frontend dev server on :5173  (from web/app/)
npm run dev
```

Open `http://localhost:5173/`. Health check: `curl http://127.0.0.1:8080/health`.

Notable `run` flags: `--static-dir <dir>` (serve built frontend instead of
embedded HTML), `--tls-cert/--tls-key`, `--peer <addr>` (federation),
`--csrf-token`, `--key-passphrase`, `--github-*-id/--google-*-id` (OAuth).

## Test & lint

```sh
# Backend (from src-rust/) — integration & tls tests need the server feature
cargo test --features server
cargo clippy --features server --all-targets

# Frontend (from web/app/)
npm test       # vitest run
npm run lint   # eslint
```

## Backend structure (`src/`)

```
lib.rs, wasm.rs           crate roots (rlib + wasm cdylib)
bin/
  xudanu-server.rs        HTTP/WS server, CLI dispatch, tracing, shutdown/autosave
  xudanu-cli.rs           command-line WebSocket client (repl, create-work, ...)
edition/                  the CRDT document model & content-addressed storage
  edition.rs, orgl.rs, bundle*.rs, canopy.rs, blob_store.rs,
  three_way.rs, endorsement.rs, content_address.rs, ...
space/                    position / region / displacement algebra (the o-tree)
crypto/                   KDF, domain separation labels
ent/                      entities
persist/                  durable storage: urdi engine, chunk_store, wal,
                          manifest, migrations, verify, packer, snapshot
server/
  server.rs               core Server state, restore/checkpoint, recovery stats
  transport/              HTTP/WS layer: handler, dispatch, codec, protocol,
                          channel, snapshot, oauth, chained_log (security audit),
                          federation_handler, audit, attribution_log
  federation.rs           peer mesh + governance/endorsements
  identity.rs, keymaster.rs, session.rs, club.rs, admin.rs, otree_crdt.rs,
  detector.rs, lock.rs, wait_barrier.rs, historical_author.rs, source_matcher.rs
```

Data directory layout (`data/` by default): `manifest.json` (+ numbered
`manifest_v*.json` history), `chunks/`, `blobs/`, `key_history.json`,
`attribution/`, and chained `security.log.*` files (tamper-evident audit trail,
seeded by `security.log.seed`).

## Frontend structure (`web/app/src/`)

```
main.tsx, App.tsx                entry + root component
api/                             client.ts, crdt_sync.ts, text_buffer.ts
                                  (HTTP + WebSocket transport, CRDT integration)
components/                       CollaborativeEditor, DocumentRenderer,
                                  WorkspacePage, panels (Annotation, Attribution,
                                  Branch, Compare, Diff, Identity, Outline,
                                  Search, Share, Trails, VersionGenealogy, ...)
hooks/, types/, reading/         supporting modules
__tests__/                        vitest specs
```

Vite proxy config (`vite.config.ts`): `/api`, `/xudanu` (WS), `/csrf-token`,
`/health`, `/auth` → `http://localhost:8080`.

## Conventions

- Rust: keep new code under the `server` feature-gated modules if it needs
  tokio/axum/crypto; the library must still build with `default = []`.
- No emoji or extraneous comments in source.
- Match existing style: `tracing::` for logging, postcard for binary wire
  formats, serde_json for human-facing manifests.
- After backend changes, run `cargo build --features server` and
  `cargo test --features server` before considering work done.
- After frontend changes, run `npm run build` (typecheck + build) and
  `npm test` from `web/app/`.
