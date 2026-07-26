# AGENTS.md — xudanu

**GitHub:** https://github.com/jonesd/xudanu

> **Disclaimer:** Xudanu is an independent, open-source project (Apache 2.0).
> It is not affiliated with, endorsed by, or sponsored by Ted Nelson,
> Project Xanadu™, the Xanadu Operating Company, Autodesk Inc., or the
> Udanax development team. Xudanu implements concepts from the open-sourced
> Udanax-Gold codebase (released 1999 under the Xanadu X11 license) using
> original code. All trademarks belong to their respective owners.

Hypertext document store with collaborative CRDT editing
frontend. The project is split across two trees:

- **Backend (Rust):** `original-code/xanadugold/src-rust/`  *(this directory)*
- **Frontend (Vite/React):** `web/app/`  *(sibling of `original-code/` under the workspace root)*

## Technology

**Backend** — Rust (edition 2021). Crate name `xudanu` (v1.0.1).
- Async runtime: `tokio`; web framework: `axum` 0.8 (HTTP + WebSocket).
- TLS: `rustls` / `axum-server`; crypto: `chacha20poly1305`, `x25519-dalek`,
  `ed25519-dalek`, `argon2`, `ring`, `blake3`, `hex`.
- Serialization: `postcard` (wire) + `serde_json` (manifests/API).
- Auth: OAuth2 (GitHub, Google), CSRF tokens, passphrase-protected server keys.
- **FR-6 Linked independent servers**: cross-server links via domain-based
  tumblers (`"alice.example.com".5.3.10.7`), BLAKE3 content hash verification,
  `CrossServerRef` persisted in `HyperRefPayload`, public content read API
  (`/api/public/work/{id}`), server directory, `/.well-known/xudanu-server.json`.
- **FR-3 Cluster federation** (optional, behind `--enable-cluster`): outbound
  dialer, PeerPool, periodic sync/heartbeat, PBFT broadcast — see
  `federation_active.rs`.
- Collaborative editing: Xudanu's own **O-tree CRDT** (`server/otree_crdt.rs`)
  — a custom position-based CRDT using the space algebra (region/displacement).
  Not Yjs/Yrs; the O-tree is purpose-built for Xudanu's content model and
  integrates with span migration, attribution, and federation sync.
- **Compound documents**: inline `RangeElement::Transclusion` in the O-tree
  (single source of truth — no side-table drift). 32-level recursive resolution
  with cycle detection. Span migration through arbitrary deltas.
- **Links & backlinks**: typed, bidirectional, unbreakable connections between
  passages. Five built-in types (Comment, Reference, Disagreement, Quotation,
  See Also). Span migration survives edits.
- **Annotations**: per-user, optionally private. Private annotations only
  visible to the creator (enforced server-side in `annotation_list`).
- **Licensing (FR-24)**: per-work license metadata — 5 options (All Rights
  Reserved, Transcopyright, CC-BY, CC-BY-SA, Public Domain). Transclusion
  compliance badges, ARR warnings, source license stamping in attribution
  log. Server never handles money (hard design rule).
- **Persistent connection pins**: per-user pins stored in `SocialSection`
  chunk (same pattern as `starred_works`), WAL recovery, wire ops
  `0x0349-0x034B`.
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

**One-liner** from workspace root:

```sh
./scripts/restart.sh    # kills :8080 and :5173, starts both servers, Ctrl+C stops
```

Or manually:

```sh
# 1. Backend on 127.0.0.1:8080, data dir at ./data  (from src-rust/)
cargo run --release --features server --bin xudanu-server -- run 127.0.0.1:8080 data

# 2. Frontend dev server on :5173  (from web/app/)
npm run dev
```

Open `http://localhost:5173/`. Health check: `curl http://127.0.0.1:8080/health`.

Notable `run` flags: `--static-dir <dir>` (serve built frontend instead of
embedded HTML), `--tls-cert/--tls-key`, `--peer <addr>` (federation),
`--csrf-token`, `--key-passphrase`, `--github-*-id/--google-*-id` (OAuth),
`--server-name <name>`, `--server-description <desc>`,
`--server-namespace-id <id>`, `--public-address <domain>` (FR-6 cross-server).

Other subcommands: `init | verify | rebuild-manifest | verify-security-log | preflight`.

## Test & lint

```sh
# Backend (from src-rust/) — integration & tls tests need the server feature
cargo test --features server --lib     # 2444 tests
cargo clippy --features server --all-targets

# Frontend (from web/app/)
npm test       # vitest run — 360 tests
npm run lint   # eslint
```

Pre-push hook (`.git/hooks/pre-push`) runs 6 checks: cargo fmt, cargo test --lib,
cargo test --test integration, tsc, vite build, vitest.

## Backend structure (`src/`)

```
lib.rs, wasm.rs           crate roots (rlib + wasm cdylib)
bin/
  xudanu-server.rs        HTTP/WS server, CLI dispatch, tracing, shutdown/autosave
  xudanu-cli.rs           command-line WebSocket client (repl, create-work, ...)
edition/                  the CRDT document model & content-addressed storage
  edition.rs, orgl.rs, bundle*.rs, canopy.rs, blob_store.rs,
  three_way.rs, endorsement.rs, content_address.rs, compound.rs,
  range_element.rs (Transclusion inline element), transclusion.rs,
  backfollow.rs (content reuse index), links.rs (HyperLink, HyperRef,
  CrossServerRef, tumblers), provenance.rs, wrapper.rs, ...
space/                    position / region / displacement algebra (the o-tree)
crypto/                   KDF, domain separation labels, key history
ent/                      entities
persist/                  durable storage: chunk_store, wal, manifest
  (SocialSection, FederationSection, LinkEntry), migrations, verify,
  packer, snapshot
server/
  server.rs               core Server state, restore/checkpoint, recovery stats,
                          link create/delete/backlinks, annotation CRUD,
                          pin CRUD, cross-server resolution, http_get_json
  server_directory.rs     server directory (FR-6: add/remove/trust/persist)
  transport/              HTTP/WS layer: handler, dispatch, codec, protocol,
                          channel, snapshot, oauth, chained_log (security audit),
                          federation_handler, federation_active, audit,
                          attribution_log
  federation.rs           peer mesh + governance/endorsements/royalties
  identity.rs, keymaster.rs, session.rs, club.rs, admin.rs, otree_crdt.rs,
  detector.rs, lock.rs, wait_barrier.rs, historical_author.rs, source_matcher.rs
```

Data directory layout (`data/` by default): `manifest.json` (+ numbered
`manifest_v*.json` history), `chunks/`, `blobs/`, `key_history.json`,
`attribution/`, and chained `security.log.*` files (tamper-evident audit trail,
seeded by `security.log.seed`).

## Frontend structure (`web/app/src/`)

```
main.tsx, App.tsx                entry + root component (renders AppShell only)
api/                             client.ts, crdt_sync.ts, text_buffer.ts
                                  (HTTP + WebSocket transport, CRDT integration)
components/
  shell/
    AppShell.tsx                 live UI: editor, links, annotations, compounds,
                                  trails, provenance, identity, settings
    ContextPanel.tsx             right panel: presence, docuverse, connections,
                                  attribution
    LeftRail.tsx, TopBar.tsx, BottomBar.tsx
    LibrarySlideOut.tsx, SearchOverlay.tsx
  panels/
    ConnectionsSection.tsx       links + backlinks + transclusions (filter,
                                  pin, delete, retype)
    DocuverseSection.tsx         mini graph of work connections
    AttributionSection.tsx       authorship spans
    PresenceSection.tsx          collaborator awareness
  CollaborativeEditor.tsx        canvas overlay: attribution, link markers,
                                  compound colour-coding, annotations, tooltips
  VirtualizedEditor.tsx          virtualized viewport variant
  LinkCreator.tsx                guided link creation wizard (whole-work,
                                  specific-text, same-doc, remote-server)
  AnnotationDialog.tsx           annotation modal with private checkbox
  AnnotationPanel.tsx            annotation list (collapsible)
  CompoundPanel.tsx              compound structure viewer
  TransclusionBadge.tsx          floating transclusion placement bar
  TrailsPanel.tsx                curated document trails
  DocumentMapPanel.tsx           force-directed work graph
  ImportWizard.tsx, IdentityPanel.tsx, PermissionBadge.tsx, ...
hooks/                           useCrdtSync, useTransclusion, useCompoundEdition
link-markers.ts                  pure helpers: lanes, clusters, density pills
prov-validator.ts                PROV-JSON validator HTML builder
__tests__/                        vitest specs (246 tests)
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
- `WorkspacePage.tsx` is dead code (not imported by App.tsx). The live UI is
  `AppShell.tsx`. Do not add features to WorkspacePage.
- Pre-push hook runs 6 checks. If it fails, fix the issue and re-push.
- Git remotes: `origin` (self-hosted), `github` (github.com/jonesd/xudanu).
  GitHub Pages deploys from `github` remote.
