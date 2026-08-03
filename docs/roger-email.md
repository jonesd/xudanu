Subject: Xudanu — transclusion demos and architecture

Hi Roger,

David Jones here from the Xudanu project. Following up on your
interest in how we're implementing transclusion — I wanted to share
some working demos and point you to the technical documentation.

Xudanu is an independent, Apache-2.0 implementation of the Xanadu
document model, built in Rust with a web frontend. It's not
affiliated with Project Xanadu or the Udanax team, but builds on
concepts from the open-sourced Udanax Gold codebase (1999, X11
license).

## Where to start

**Documentation entry point**: https://dgjones.info/xudanu/
**Source code**: https://github.com/jonesd/xudanu

## What's working — screenshots

Attached are 6 screenshots showing the transclusion workflow:

1. **t-95** — Source document with original content
2. **t-96** — Selecting a passage, clicking Transclude
3. **t-97** — Placed transclusion inline (blue border, arrow, italic
   text) + Connections panel showing source, excerpt, and range
4. **t-99** — Connections panel detail: source title, excerpt preview,
   character range. "⚠ changed" badge appears when source is edited
   after transclusion (BLAKE3 hash mismatch)
5. **t-inline** — Authoring mode: transclusion markers visible
   (border, arrow, attribution colors)
6. **t-reading** — Reading mode: all markers hidden, text flows
   seamlessly. This matches the principle that transcluded content
   should read naturally

## Architecture — how it differs from Gold

Rather than reproduce it here, the full comparison with diagrams is
in the architecture document:

**Transclusion Architecture** (with SVG diagrams):
https://github.com/jonesd/xudanu/blob/main/docs/transclusion-architecture.html

Key design choices that may interest you:

### Range-based vs I-stream

We use character-range references `(source_work_id, char_start,
char_end)` rather than enfilade/I-stream positions. This was a
deliberate trade-off — simpler to implement, but transclusions don't
survive arbitrary restructuring of the source. The 5-layer pipeline
from Gold (TransclusionIndex → Bert Canopy → Recorder → Recorder
Hoist → BackfollowEngine) is reimagined as:

- **BLAKE3 content registry** — replaces the tumbler-based lookup
- **O-tree CRDT** — replaces the enfilade for collaborative editing
- **Span migration** — delta-based position updates when source text
  is edited (insert/delete shifts transclusion ranges)
- **Backfollow engine** — cross-document query index, preserved from
  Gold's design

The `ent/` module has the crum/HTree machinery for spanfilade if we
go that direction. The spanfilade analysis is documented in:
`docs/dev/FR-26-phase4-spanfilade-plan.md`

### What Gold did differently (that we respect)

- Gold's enfilade preserves ALL versions simultaneously — we use
  revision history + blob snapshots
- Gold's spanfilade inserts at the I-stream level — we insert at
  character positions with hash verification
- Gold uses crum-based provenance — we use Ed25519 signatures +
  span provenance chains
- Gold's frontend showed plain text with side-window link lists —
  we added inline visual markers (toggleable via reading/authoring
  mode), which goes beyond what Gold shipped

### FR-26: Content-Addressed Transclusion

Three phases complete:

- **Phase 1**: BLAKE3 hash stored at creation, verified on resolution.
  Detects source edits. (4 tests)
- **Phase 2**: Source revision pinned. Original content retrievable
  from revision history on hash mismatch. (1 test)
- **Phase 3**: Immutable blob snapshot at creation time. Transclusion
  survives source deletion. (1 test)

Full spec: `docs/dev/FR-26-content-addressed-transclusion.md`

### Transclusion engine internals

For the deep technical view of our 5-layer pipeline:

**Transclusion Engine document** (with Gold parity annotations):
https://github.com/jonesd/xudanu/blob/main/docs/transclusion-engine.html

This covers: TransclusionIndex (BLAKE3 registry), Bert Canopy
(hierarchical property tree), Recorder System (persistent pub/sub),
Recorder Hoist (incremental propagation), BackfollowEngine
(cross-document queries). Each section has a "Modern Enhancements
Over Udanax-Gold" comparison.

Implementation details with C++ file cross-references:
`original-code/xanadugold/src-rust/docs/transclusion-implementation.md`

### Xanadu's 17 Rules coverage

Mapping of Nelson's 17 rules to our implementation:
`original-code/xanadugold/src-rust/docs/xanadu-17-rules.md`

### Compound documents

Transclusions can be assembled into compound documents via the
Compound Builder. A compound document is simply a work whose edition
contains multiple RangeElement::Transclusion elements. The server
resolves them recursively (32-level depth, cycle detection).

Compound Builder guide with screenshots:
https://github.com/jonesd/xudanu/blob/main/docs/compound-builder-guide.html

## What we don't have (yet)

- **Spanfilade**: Range-based transclusion doesn't survive arbitrary
  restructuring of the source (only insert/delete via span migration).
  Full spanfilade analysis done (3 options compared), deferred until
  we have your input on whether the effort is warranted.
- **Cross-server transclusion via XCP**: Protocol spec written
  (github.com/jonesd/xcp), not yet implemented. DNS-anchored tumblers,
  content gateway API, BLAKE3 hash verification across servers.
- **Live push notifications for source changes**: Currently detected
  via 30-second poll. Server-side push events planned.

## Build and try it

```
git clone https://github.com/jonesd/xudanu.git
cd xudanu
cargo build --features server --bin xudanu-server
./target/debug/xudanu-server run 127.0.0.1:8080 data
# Open http://localhost:5173 (or :8080 with --static-dir)
```

Happy to discuss any of this — especially the spanfilade question
and whether our range-based approach is sufficient or if we should
invest in the I-stream model.

Best,
David

---
David Jones
david@dgjones.info
https://dgjones.info/xudanu/
https://github.com/jonesd/xudanu
