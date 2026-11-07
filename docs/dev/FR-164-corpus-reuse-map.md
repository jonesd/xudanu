# FR-164: Corpus-Wide Reuse Map — Making the Two Graphs Visible

- **ID:** FR-164
- **Status:** Implemented (2026-11-07)
- **Parent:** FR-161 (reuse graph index); absorbs the FR-161
  follow-up `find_transclusions` sketch

## Problem

The reuse graph was traversable per work but had no corpus-wide
viewport. The docuverse map drew link edges only; reuse edges (the
second xanalogical connection system) were invisible as structure.

## What shipped

Three surfaces over the FR-161 index, no new storage:

1. **Wire op `reuse_graph` (0x080b)** — inverts the index into
   work-to-work edges `{reuser, source, is_direct, span_count,
   origin_server?}`. Filterable by `source`, `reuser`,
   `direct_only`; paginated (`offset`/`limit`, default 200, cap
   1000); `total` reports the filtered count. Deterministic order
   (source, reuser, origin) so pages are stable.
2. **MCP tool `find_transclusions`** — same edges as tool results,
   on both paths (local data-dir and remote WebSocket). The remote
   arm rides the new wire op; JSON shapes are identical either way.
3. **Frontend** — `work_graph` (0x0338) now emits `transclusion`
   edges alongside `link` and `similarity` (directed reuser →
   source, weight = span count clamped to 100, deduped per pair
   separately from links so a pair can carry both). DocumentMapPanel
   renders the three kinds distinctly via the tested
   `graph-scoring.ts` visuals: reuse blue/solid/thick, links grey
   solid, similarity grey dashed. Legend and stats name reuse.

## How the inversion works

The FR-161 registration keys are the trick: every transclusion
element registers not only under its content fingerprint but also
under the work-granular key `fp(work(S))` of its SOURCE work. So
for each key of `content_map()` that equals `fp(work(S))` for a
known work S, every entry `(owner, is_direct)` is one placed span
of S inside the owner's work — counting entries per owner yields
`span_count` directly, and `is_direct` is the AND of entry flags.
No fingerprint inversion is needed: the reverse map
`fp(work(id)) → id` is built from the live work table in one pass.

Federated entries under the same work keys carry remote reusers:
the edge's `reuser` names a work on `origin_server`. A peer holding
different content cannot produce an edge — only exact key matches
count (equality verified, never assumed).

## Permissions

`reuse_graph_for_session` hides local edges whose reuser OR source
work is unreadable for the session (mirrors the FindTranscluders
dispatch filter). Remote-origin edges require only the local source
to be readable — the reuser is a foreign id no local policy can
judge.

## Tests

- Lib: index inversion (span_count, filters, pagination), session
  hiding (read + edit club moved under PublicSandbox — the public
  edit club would otherwise grant read via the edit fall-through),
  work_graph transclusion edge emission.
- Dispatch: read-path roundtrip on a fresh server.
- MCP: local `find_transclusions` corpus mapping; remote roundtrip
  over a live Axum server places a transclusion then reads the edge
  back through the wire op (this caught the missing JSON codec arm
  — see below).
- Contracts: `wire_contract` PINNED 0x080b, `transport_sweep` name.

## Hard-won notes

- The JSON codec's `build_wire_request` is an exhaustive per-op
  match with NO generic fallback — a new op without an arm decodes
  as a protocol violation, and violations accumulate security
  strikes and DISCONNECT the socket. Symptom: the MCP remote test
  hung ~60s then reset without a server-side panic trace. Any new
  op needs: protocol enum + table + request/response + `is_readonly`
  + dispatch arm(s) + **codec arm** + contract pins.
- `remote_read_tools_roundtrip` had a pre-existing flake: it picked
  `results[0]` from a two-match search whose order is not
  guaranteed. Fixed by selecting via a single-match query ("gamma").
- WorkspaceShell's concept link-count loop now counts only
  `edge_type === "link"` edges — previously similarity (and now
  reuse) edges would have inflated citation counts.
