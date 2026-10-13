# FR-88: Engine Extraction — the Core Crate and Embedder Guarantees

- **ID:** FR-88
- **Status:** Proposed (2026-10-12) — post-launch sequencing, see §6
- **Depends on:** nothing technically; strategically after the
  launch beat (essay → video → HN)
- **Closes:** the "library as asset" question (backlog 0b); the
  unused-scaffold-crate confusion; makes UI-agnosticism a
  guarantee rather than a claim

## 1. Why

The most valuable long-term asset is not the server or the web UI —
it is the model layer: the migrated Udanax Gold innards (enfilades,
tumblers, canopy, typed multi-ended links, transclusion) with our
enhancements woven in (per-span provenance, content addressing,
the lattice CRDT, reference-over-copy). Today that fabric lives
inside the monolithic `xudanu` crate beside an 84.7k-line
`server/` module, with three back-edges where the model depends
on the application (`edition/three_way.rs`, `edition/mapping.rs`,
`space/lattice_sim.rs` → `crate::server`), and six unused scaffold
crates (`crates/{types,core,signing,provenance,sync,wasm}`, ~2k
lines, consumed by nothing — only `Cargo.lock` and
`docs/dev/yrs-integration.md` reference them) misleading anyone
who reads the workspace.

Goal, stated as three consumption modes for third parties:

1. **Out-of-process, any language** — the wire protocol (xcp,
   140+ ops, versioned) + `xudanu-mcp`. Works today.
2. **In-process Rust** — an engine crate with no sockets, no
   HTTP, no async runtime. This FR.
3. **In-browser (future, out of scope here)** — WASM engine +
   the lattice sync protocol (`space/lattice_wire.rs`,
   `lattice_sync.rs`, already separable from the transport).

## 2. What moves, what stays

**Moves to the engine crate** (working name `xudanu-core`; the
server binary keeps the name `xudanu`):

- `edition/` — the model + provenance + content addressing +
  `three_way.rs` (O-tree baseline engine)
- `space/` — the Gold space algebra (integer, real, sequence,
  cross) + the lattice CRDT files
- `ent/`, `persist/`
- `crypto/` — minus `server_identity.rs`
- Promoted from `server/` (engine-grade, misfiled):
  `otree_crdt.rs`, `crdt_manager.rs`, `reuse_match.rs` (FR-58 is
  model-level)

**Stays with the server:** `federation.rs`, `ots_anchor.rs`
(calendar/Bitcoin I/O), `identity.rs`/`club.rs`, `mcp.rs`/
`mcp_ws.rs`, `seed_*.rs`, `ollama.rs`, `transport/`,
`rate_limiter.rs`, `detectors.rs`, static-file serving.

**Scaffold crates:** delete `crates/{types,core,signing,
provenance,sync,wasm}` (default) or fold any piece that earns its
place during the split. Git history preserves them.

## 3. Hard guarantees (acceptance criteria)

- **G1 — Dependency firewall:** the engine crate compiles with
  zero async/network dependencies (no tokio, no axum, no
  tungstenite). This is the tripwire that prevents future
  entanglement.
- **G2 — Protocol unchanged:** the 140 xcp operations keep their
  semantics and encoding; `xcp-spec` version does not bump.
  Dispatch handlers become thin (de)serialization over engine
  methods. Existing clients (web UI, `xudanu-cli`, MCP) run
  unmodified.
- **G3 — Back-edges severed:** no `crate::server` reference from
  edition/, space/, ent/, crypto/, persist/.
- **G4 — Second renderer exists:** a demo binary drives the
  engine **in-process, no server** end-to-end: create work →
  type text → create a typed link → place a transclusion → dump
  provenance — all rendered as terminal text. This is the minimal
  proof that "bring your own UI" is real. (The wire-protocol
  equivalent already exists: `xudanu-cli` is the reference
  third-party client and should be documented as such.)
- **G5 — Tests move, not shrink:** the 3,700+ test suite relocates
  with the engine; count does not drop; server tests keep
  covering transport/federation/anchoring.
- **G6 — Crates.io:** engine publishes at 0.x (see §4).

## 4. Semver and migrations

- Publish **0.x** — breaking changes permitted in minor bumps,
  stated in the README. Later, freeze a surface behind an
  `unstable` feature flag (off by default).
- The server is consumer #1 — dogfooding catches breakage before
  any external embedder.
- Stored data: content addressing + deep versioning mean old
  versions stay addressable forever; persist loaders keep
  loading old formats; `migrate_manifest` continues to work.
  The migration discipline already exists (bug-pattern lints in
  `Cargo.toml`); extraction makes it visible, not new.
- Client contract: `xcp-spec-v1.1.md` remains the versioned
  surface; protocol evolution is a separate process from crate
  semver.

## 5. Stages

| Stage | Work | Size |
|---|---|---|
| S1 | Sever the three back-edges; promote `otree_crdt`/`crdt_manager`/`reuse_match` out of `server/` (in-crate move, paths stable) | small, safe anytime |
| S2 | Crate split: `xudanu-core` (or absorb scaffold names); facade re-exports keep internal import churn bounded | large but mechanical |
| S3 | G1 dependency firewall enforced in CI (deny network deps on the engine crate) | small |
| S4 | Demo binary (G4) + "build your own client" docs page: wire protocol (any language) → CLI (wire) → demo (in-process) as the three ladders | small |
| S5 | crates.io publish: engine at 0.x; supersedes/completes the v0.1.2 `xudanu` crate publish TODO | small |

S6 (separate FR if pursued): WASM build of the engine for
browser-side embedding and offline-first clients syncing over the
lattice protocol.

## 6. Sequencing

Strategy stands: **after the launch beat.** The essay/video/HN
window logic is untouched by this work; a refactor now would
spend exactly the weeks that matter. Post-launch, the extraction
is the build-in-public arc — each stage is a demonstrable beat.
Exception: S1 is safe pre-launch if a session has spare cycles
(it changes no behavior).
