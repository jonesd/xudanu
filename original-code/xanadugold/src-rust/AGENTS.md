# AGENTS.md — xudanu

**GitHub:** https://github.com/jonesd/xudanu
**Canonical local path:** `~/code/xu-gold-2026/original-code/xanadugold/src-rust/`

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
  **Enfilade-native optimizations (FR-34)**: subtree crums (BLAKE3 Merkle
  hashes) for O(1) equality checks, chunk-level diff, inline coalesce,
  splay exposure at Edition level, and tumbler ↔ Sequence bridge. See
  `docs/dev/FR-34-enfilade-native.md` for the full roadmap.
- **Tumbler addressing (FR-34 Phase D-F)**: `XudanuTumbler` provides typed
  hierarchical addresses (`"alice.com".5.3.10.7`). `DocumentArrangement`
  bridges i64 document positions to global tumbler addresses. **Phase F
  (active)**: the `space/sequence.rs` (1294 lines) Sequence algebra is
  load-bearing — `Sequence::between` (Gold's never-renumber allocation),
  `Ord` on tumblers via Sequence ordering, region containment via
  `SequenceRegion::prefixed_by`, region members returned in sequence order.
  Typed accessors on `CrossServerRef`
  (`work_id()`, `char_range()`, `parent_tumbler()`, `same_server_as()`).
  `HyperLink::tumbler_address()` and `for_tumbler_span()` enable tumbler-based
  link addressing. `CompoundSpan::to_tumbler()` / `from_tumbler()` for
  transclusion coordinates.
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

**One-liner** from workspace root — ALWAYS prefer this over
manually backgrounding servers (it handles graceful stop with
checkpoint flush, port cleanup, health-wait, and Ctrl+C teardown):

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

## Scripts (workspace `./scripts/` — prefer these over ad-hoc commands)

| Script | Use |
|---|---|
| `restart.sh` | Dev servers (backend :8080 + Vite :5173) — graceful stop, port cleanup, health-wait. **The default way to run anything live.** |
| `clear-build-cache.sh` | Reclaim disk: drops target/debug/incremental (the usual multi-GB hog), llvm-cov, stale release. **Run this when builds fail with 'No space left on device'** |
| `rebuild.sh` | Clean rebuild of backend + frontend |
| `pre-push.sh` | Fast pre-push static checks (CI runs the full suites) |
| `demo-links-seed.mjs` | Seed a live server with the FR-40 links demo corpus (gathered end-sets, three-ended, comment-on-link, descriptor). `node scripts/demo-links-seed.mjs [ws-url]` against a `--edit-policy public-sandbox` server |
| `--seed-links-demo` (server flag) | **Ships with the binary**: `xudanu-server run <addr> <dir> --edit-policy public-sandbox --seed-links-demo` seeds the Links Course (5 lessons, sandbox, companions, published trail) natively — no Node, no scripts; end users with a release tarball recreate the demo by wiping the dir and restarting. Idempotent |
| `demo-links-reset.sh` | **One command to a fresh links demo** — wipes the demo data dir, restarts :8081 (public-sandbox), runs every seed (corpus, course, playground, gallery works) |
| `demo-links-course.mjs` | The progressive Links COURSE: five lessons simple→complex (two-ended, three-ended, gathered sets, comment-on-link, reading toolkit) + sandbox, each with a live demo and one task — wired as a trail. Same usage |
| `demo-links-playground.mjs` | Seed the INTERACTIVE Links Playground work — the document's own text walks the reader through gather/link/describe/comment/compare on the real editor. Same usage as demo-links-seed |
| `demo-network.sh` | FR-41: bring up the seeded 3-node federation demo network + story smoke test |
| `ws-link-probe.mjs` | Drive one cross-server link_create against a node, report notify outcome + timing as JSON |
| `screenshot-capture.mjs` | Headless screenshot capture (docs/screenshots/) |
| `create-test-data.js` | Bulk test data generation |
| `debug-ws.cjs` | Raw WebSocket debugging against a running server |
| `deploy.sh` / `deploy-aws.sh` | Update xudanu.com / AWS deployment |
| `backup-offsite.sh` / `restore-offsite.sh` | Offsite data-dir backup + restore |
| `gen-wire-doc.py` | Regenerate wire-protocol docs |

Notes for ad-hoc servers (when a script doesn't fit, e.g. a second
instance on another port): use `nohup ... & disown` — plain
`(cmd &)` subshells get reaped when the spawning shell exits.

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

## Releases (multi-platform)

Release = tag push. The `Release` workflow (`.github/workflows/release.yml`)
builds all platforms and attaches binaries to a GitHub Release. Full
procedure, learned the hard way during the v1.7.0 five-fix saga:

### Steps

1. **Bump version** in THREE places: `Cargo.toml` (`version =`),
   `web/app/package.json`, and a new `CHANGELOG.md` entry (workspace
   root). They must agree.
2. **Merge the feature branch to `main`** via PR (CI must be green:
   Format, Clippy, Test, all three Builds).
3. **Tag**: `git tag vX.Y.Z main && git push github vX.Y.Z` — the
   tag push triggers the Release workflow automatically.
4. **Create the Release object**: `gh release create vX.Y.Z --target
   main --title ... --notes ...` (or let the workflow do it and edit
   notes after). Binaries attach as each build job finishes.
5. **Watch**: `gh run watch` or poll `gh run list --limit 1`. macOS
   runner backlog can queue jobs 30+ min — queued ≠ failed.

### Platform matrix (as of v1.7.0)

| Target | Runner | Artifact | Notes |
|---|---|---|---|
| `aarch64-apple-darwin` | macos-latest | `*-aarch64-macos.tar.gz` | primary Mac (Apple Silicon) |
| `x86_64-apple-darwin` | macos-latest | `*-x86_64-macos.tar.gz` | Intel Mac (Rosetta runs aarch64 fine) |
| `x86_64-unknown-linux-musl` | ubuntu-latest | `*-x86_64-linux-musl.tar.gz` | static, runs anywhere |
| `aarch64-unknown-linux-gnu` | ubuntu-latest | `*-aarch64-linux-gnu.tar.gz` | ARM Linux, glibc |
| `x86_64-pc-windows-msvc` | windows-latest | `*-x86_64-windows.zip` | |

### Hard-won platform gotchas (do not regress)

- **ARM Linux**: MUST use `aarch64-unknown-linux-gnu` (glibc), NOT
  musl — `aws-lc-sys` (via rustls) hard-requires a musl-named gcc
  for musl targets and musl.cc mirrors 503 intermittently. GNU
  cross-toolchain comes from Ubuntu: `apt-get install
  gcc-aarch64-linux-gnu`.
- **ARM Linux linker**: MUST be set via env vars, NOT `.cargo/
  config.toml` — config files under the crate dir are unreliably
  read when building with `--manifest-path` from the repo root.
  The workflow exports `CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER`
  and `..._RUSTFLAGS="-C link-arg=-fuse-ld=bfd"` (bfd avoids the
  rust-lld `--fix-cortex-a53-843419` flag clash).
- **TOML in workflows**: heredocs inside YAML `run:` blocks write
  INDENTED content — cargo TOML needs column-0. Use printf-per-line
  or env vars instead.
- **Deletions/re-tags**: to re-cut a release, cancel the run, delete
  tag (`git push github :refs/tags/vX.Y.Z`) AND release (`gh release
  delete`), re-tag, re-create. Forgetting the release delete leaves
  an orphaned release object pointing at the old commit.
- **Branch vs main**: development happens on feature branches; the
  GitHub landing page shows `main`. If work seems "missing," check
  the branch. Merge via PR so CI runs on the merge result too.

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
- Terminology: "xanalogical" (lowercase, adjective) for the general
  class of systems (Nelson's own coinage — like "hypertext"); "Xanadu"
  only as the proper noun for Ted Nelson's specific project and its
  artifacts (Project Xanadu, Xanadu 92.1, trademark disclaimer). See
  XCP repo terminology note.
- Match existing style: `tracing::` for logging, postcard for binary wire
  formats, serde_json for human-facing manifests.
- **Postcard serialization rule**: NEVER use `skip_serializing_if` on structs
  that go through postcard (wire ops, chunks, federation entries). Postcard is
  positional — skipping bytes on serialize misaligns deserialize (surfaces as
  `Found a bool that wasn't 0 or 1`). The safe additive-field pattern is
  `#[cfg_attr(feature = "serde", serde(default))]` alone (see
  `WorkChunkRef.tumbler_server`, edition_chunks.rs). `skip_serializing_if` is
  fine for serde_json-only structs (manifests, HTTP JSON).
- Test passwords: use the fn-return pattern (`fn test_x_credential() -> &'static [u8] { b"..." }`),
  never a `const` — CodeQL flags const-declared password literals as
  hard-coded crypto but not function returns (alerts #263-#266, #325;
  see `test_club_password()` in server.rs tests).
- After backend changes, run `cargo build --features server` and
  `cargo test --features server` before considering work done.
- After frontend changes, run `npm run build` (typecheck + build) and
  `npm test` from `web/app/`.
- `WorkspacePage.tsx` is dead code (not imported by App.tsx). The live UI is
  `AppShell.tsx`. Do not add features to WorkspacePage.
- Pre-push hook runs 6 checks. If it fails, fix the issue and re-push.
- **Docs site (dgjones.info) deployment**:
  **Pipeline**: push to main (docs/** changed) → GitHub Actions
  (deploy-docs.yml) → `render_docs.py` converts every `docs/**/*.md`
  to `<name>.html` (dark theme, Pygments syntax highlighting), rewrites
  .md links to .html in existing HTML files, deletes the .md sources
  from the deployed tree, uploads docs/ to GitHub Pages.

  **THE CRITICAL RULE**: if a hand-crafted HTML doc has the SAME NAME
  as a .md file, the markdown conversion OVERWRITES the fancy HTML.
  Two kinds of docs, never both for the same name:
  - **Fancy HTML docs** (styled, SVG diagrams, callout boxes):
    create `<name>.html` ONLY — never create a matching `<name>.md`
  - **Markdown docs** (plain reference): create `<name>.md` ONLY —
    the pipeline generates the HTML automatically

  **Creating a fancy doc — step by step**:
  1. Copy the CSS from an existing fancy doc (e.g., ent-dagwood-trace-dag.html)
  2. Create `docs/<name>.html` — self-contained (CSS inline, SVG inline)
  3. Verify NO `docs/<name>.md` exists (it would clobber the HTML)
  4. Commit and push to main
  5. Wait ~3 min for the GitHub Actions deploy-docs workflow
  6. Verify at `https://dgjones.info/xudanu/<name>.html`
  7. If it shows the markdown template instead of your styled version,
     you have a name collision — delete the .md and push again

  **Existing fancy docs that work** (use as templates):
  ent-dagwood-trace-dag, architecture, crdt-evolution, cryptography,
  transclusion-engine, gold-link-model, and others in docs/*.html


- Git remotes: `origin` (self-hosted), `github` (github.com/jonesd/xudanu).
  GitHub Pages deploys from `github` remote.

