# FR-161: The Reuse Graph Made Real — Work-Granular Transclusion Index

- **ID:** FR-161
- **Status:** Shipped (2026-11-07)
- **Parent:** FR-141 (Docuverse MCP server); replaces the FR-160 sketch of
  this number (corpus-wide `find_transclusions` remains a follow-up)

## Problem

`who_transcluded` returned zero everywhere — on xudanu.com and on fresh
servers with live transclusions in them. Not "nobody transcluded
anything": the reuse index could not answer the question.

Root cause, structural: registration and query used different keys.

- **Registration**: a transclusion of (work W, span [s, e)) was keyed
  `blake3("transclusion:"|W|s|e)` — per exact span.
- **Query**: `who_transcluded(W)` looked up `blake3("edition:"|W)`.

Different prefixes, different keys — the query could never match. Found
live while demoing the FR-160 tools: `read_work.span_ranges` showed a
healthy transclusion while `who_transcluded` on the same work returned
empty, before and after checkpoint/restore.

## What shipped

1. **Work-granular registration** (`edition/transclusion.rs`): new
   `registration_keys()` — every element still registers under its exact
   fingerprint key, and Transclusion/StructuralTransclusion elements
   additionally register under `element_key(Work(source_work_id))`.
   Applied symmetrically: `register_work`, `unregister_work`, and the
   crum-guided delta path in `BackfollowEngine::update_work_delta` (so
   incremental edits stay consistent — no stale work-key entries).
2. **Dual query, merged** (`server/server.rs`): `find_transcluders`,
   `find_transcluders_for_session`, and `find_works_for_content` query
   both the work-granular and the edition key, merge, and dedupe.
   Recorder-path exact-element queries are unaffected.
3. **CLI**: new `who-transcluded <work-id>` command printing
   kind/id/URI/direct — the scripting surface for the reuse graph.
   (`find-content` also starts answering, via the same server fix.)
4. **Shape parity fix** (`server/mcp_ws.rs`): the remote
   `who_transcluded` arm reshapes wire triples into the data-dir
   `kind/id/uri/is_direct` shape — "identical results either way" is the
   stated contract of the remote path.
5. **Remote `transclude` wire fix** (`server/mcp_ws.rs`, found during
   live verification): the arm sent `work_id`/`char_start`/`char_end`;
   `RangeElementPayload` expects `transclusion_source`/
   `transclusion_start`/`transclusion_end`. Every remote transclude
   failed with "cannot convert payload to RangeElement" before this.

## Who benefits

All four access mechanisms at once — the fix is below all of them:
web app (`findWorksForContent`), CLI (`find-content`, `who-transcluded`),
MCP (`who_transcluded`), raw wire (`find_transcluders`).

## Verification

- New tests: index-level (`transclusion_registers_under_source_work_key`
  — register, work-key hit, exact-span hit, unregister removes) and
  functional (`who_transcluded_returns_reuser_after_transclude` over
  MCP, first functional test this query ever had).
- Full lib suite: 3853 passed, 0 failed.
- Live: restart of the demo server (restore rebuilds the index) —
  `who_transcluded(1004)` returns work 1005 direct via MCP remote and
  `xudanu-cli who-transcluded 1004` prints `work 0x3ed ... direct`.

## Follow-ups

- Corpus-wide `find_transclusions` MCP tool over the same index
  (by span, direct vs nested, paginated) — the original FR-161 sketch.
- ~~Seed example transclusions~~ — done differently than sketched: the
  Gallery already seeds them (Room 9 "The Live Window", the Genealogy
  rooms); what was missing was the index. A seed test now locks the
  reuse graph in (`seed_gallery_makes_reuse_graph_answer`). Production
  servers pick the answers up on restart under the new binary (restore
  re-registers with work-granular keys).
- ~~Access guide doc~~ — shipped as `docs/access-guide.html`: the
  operation-by-mechanism matrix (app / CLI / MCP / raw wire) with real
  commands and an honest gaps section feeding this roadmap.
