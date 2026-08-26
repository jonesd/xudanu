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
  bridges i64 document positions to global tumbler addresses. Connected to
  the dormant `space/sequence.rs` (1248 lines) Sequence algebra via
  `to_sequence()` / `from_sequence()`. Typed accessors on `CrossServerRef`
  (`work_id()`, `char_range()`, `parent_tumbler()`, `same_server_as()`).
  `HyperRef::tumbler_address()` and `for_tumbler_span()` enable tumbler-based
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
- Match existing style: `tracing::` for logging, postcard for binary wire
  formats, serde_json for human-facing manifests.
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
- Git remotes: `origin` (self-hosted), `github` (github.com/jonesd/xudanu).
  GitHub Pages deploys from `github` remote.

## Strategic Context

### Current Priorities (as of v1.4.0, Aug 2026)

1. **Stabilize read-only structural transclusion** — Highest priority. Active
   development with 30+ commits in Aug 2026. Edge cases remain: padding
   newlines, position migration on source edit, overlapping regions in DOM
   builder. Must be solid for Roger Gregory engagement (see below).

2. **Storage architecture refactoring** — Move JSON pseudo-pointers (indirection
   from manifest into chunk store) so that all pointer references live in the
   chunk store itself. This would clean up the architecture and make
   non-blocking checkpoint feasible (flush chunks instead of serializing a
   giant JSON state graph).

3. **Cross-server network (federation) toward production** — Prototype exists
   (Docker 3-node cluster, Ed25519/X25519 handshake, PBFT consensus, BLAKE3
   content replication, FR-35 Bloom filter layer). Needs hardening to move from
   promising prototype to production-grade. Scaling beyond ~10 nodes needs
   gossip relay and incremental sync. Resource-constrained: testing on small
   Docker clusters on available hardware, not hiring lots of machines.

4. **Enfilade-native optimizations** — Increasing use of the enfilade data
   structures where the Gold variant had its most important optimizations.
   FR-34 covers subtree crums (BLAKE3 Merkle hashes for O(1) equality),
   chunk-level diff, inline coalesce, splay exposure, tumbler-to-Sequence
   bridge. See `docs/dev/FR-34-enfilade-native.md`.

5. **Non-blocking checkpoint + backend perf** (issue #90, PERF_BACKLOG B6/B7)
   — Auto-checkpoint blocks request dispatch. Background thread checkpoint
   is prerequisite for real multi-user deployment.

6. **Frontend polish** — The editor and overall UX are functional but not
   consumer-ready. Transclusion placement UX is the hardest open problem
   (placing content at arbitrary positions in a document). Active
   improvement work underway.

7. **Consumer-ready collaborative editing UX** (issue #35) — CRDT works
   technically but needs polish: cursor presence, conflict visibility,
   awareness, reconnection.

### Key Relationships

- **Roger Gregory** (original Xanadu / Udanax Gold team, working with Ted
  Nelson). Roger is the foremost expert on the original Xanadu implementation.
  He is working to bring the old Xanadu/Udanax-Gold variant back up. We have
  a developing collaborative relationship with him. **Getting structural
  transclusion right is important for this relationship** — it is the most
  distinctive Xanadu feature and the one Roger would evaluate first-hand.

- Xudanu imported some open-source Udanax Gold code but has built significant
  functionality that is architecturally different from Xanadu (custom O-tree
  CRDT, modern crypto, React frontend, Docker federation, Transcopyright
  licensing, etc.).
- The original Udanax Gold (early 90s) is text-based with no web frontend.
  Xudanu benefits from building on modern tech (Rust, React, WASM, WebSockets,
  CRDTs, modern crypto) that wasn't available to the original team.
- Roger Gregory is working to bring the old Xanadu/Udanax-Gold variant back
  up; as of last contact he had not started on a web-based frontend.

### The Xanadu Model

- Core principle: **no duplication** across the system. Transclusions are shared
  content blocks — a passage exists once and is *included by reference* in any
  number of documents. Editing the original updates all transclusions
  automatically.
- Xudanu has built a large portion of the Xanadu network model (documents,
  transclusions, links, compound documents, tumbler addressing, enfilade-native
  structures). Earlier Xanadu teams never reached production; Xudanu is farther
  along but has incomplete knowledge of the underlying academic models.
- **Transclusion placement UX is a major open problem.** Users should be able to
  place transclusions anywhere on a page, not just appended. This has proven
  technically difficult (cursor position tracking, padding newlines, CRDT
  delta coordination, position migration on source edits, overlapping
  transclusions in the DOM builder).

### Deployment & Frontend

- **Production server:** https://xudanu.com — small deployment, updated on each
  release. Currently low traffic (bots only).
- **Frontend needs significant polish.** The editor, panels, and overall UX
  are functional but not yet consumer-ready. Active improvement work underway.
- The user-facing app is a single-page React app served by the Rust server
  (or behind a reverse proxy in production).

### Quality Approach

- **Tests are a first-class concern.** The codebase is still growing rapidly
  (~10 commits/day). Every new feature and every bug fix must include thorough
  test coverage. Tests serve as documentation, regression guards, and
  architectural feedback. When in doubt, write the test first.
- Existing: 2,500+ backend tests, 412+ frontend tests, integration tests
  (two-server federation, 3-node Docker cluster, adversarial Bloom filter
  network).
- **Documentation is at https://dgjones.info/xudanu/** — includes both
  user guides and visual/technical documents. Feature requirements (FR-1
  through FR-24+) describe what we intend to build and are the design
  authority for each feature. Consult the FR docs before implementing any
  feature. Most FRs are now implemented; remaining work is refinement,
  hardening, and closing gaps.
- **Don't let knowledge slip away.** The project has moved fast with limited
  documentation of design decisions and architectural rationale. When
  implementing features, capture the "why" in comments, commit messages, and
  FR docs. If something is tricky or non-obvious, document it — the team's
  knowledge of the Xanadu model is incomplete and future contributors will
  need the trail.

### Project Status

- v1.4.0, 35 releases, 893 commits on main. ~10 commits/day sustained
  since April 2026.
- 2,500+ backend tests, 412+ frontend tests.
- 22 open GitHub issues.
- Still actively developed.
- **Time-sensitive:** The project needs to make a visible splash reasonably
  soon or the window of opportunity will close. Prioritize work that is
  user-visible and demonstrable over internal plumbing. Frontend polish,
  stable transclusion, and the production deployment at xudanu.com are the
  highest-leverage paths to this.
- **Rollout uncertainty:** Ted Nelson and Roger Gregory are the prime movers
  of the Xanadu narrative. Xudanu's story and timing relative to their work
  is still being figured out. The project needs to be ready regardless of
  how the broader narrative plays out.
