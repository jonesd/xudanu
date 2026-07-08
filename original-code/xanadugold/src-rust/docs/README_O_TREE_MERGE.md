# Xudanu: The "u" Is For New

**Hypertext infrastructure for documents that outlive their authors.**

Xudanu (pronounced *zoo-dah-noo*) is a reinterpretation of Ted Nelson's Xanadu vision — not a faithful recreation, but an engineering-first approach that keeps what works and replaces what doesn't. The name has history: Xanadu was reversed to Udanax Gold (the 1999 codebase), and a collaborator reversed it again to Xudanu — where the "u" sounds like "new". Hypertext for today, built on the principles that were right all along.

## What Xanadu Got Right

Before the web broke hypertext, Nelson identified principles that still matter:

- **Content is identity** — the same text in multiple documents is the *same* text, not copies. Transclusion, not copy-paste.
- **Links are bidirectional** — you can see what points to your document, not just what your document points to.
- **Nothing is deleted** — every revision is preserved. Documents are append-only histories.
- **Attribution is cryptographic** — who wrote what is signed, not social convention.

The web abandoned all of these. URLs rot. Links are one-way. Git rewrites history. Attribution is a metadata field anyone can edit. Xudanu restores these as first-class engineering constraints.

## The Problem We're Solving Now

Existing collaborative editors (Google Docs, Notion, Confluence) treat documents as flat text. Rich structure — embedded references, layered media, cross-document links — is either lost during concurrent editing or frozen into a single-author mode. You can have real-time collaboration *or* rich hypertext, but not both.

This is because they use CRDTs that operate on plain text sequences. When two people edit the same paragraph, the CRDT merges their keystrokes character-by-character. Any structural meaning (this is a transclusion, this is an overlay, this is a data binding) is destroyed in the merge.

## The O-Tree Merge

Xudanu's core data structure is the **O-tree** (originally "orgl" in Udanax Gold — "organism, not mechanism"). An O-tree is a hierarchical content-addressed tree where:

- Each node is content-addressed via BLAKE3 fingerprint
- Leaf elements carry typed payloads (text, data, blob references, transclusions, overlays)
- Structural sharing means identical subtrees are stored once
- Editions are snapshots of the tree, not diffs

The O-tree merge algorithm operates directly on this structure, not on flattened text. It's a **three-way merge** (like `git merge`, but for rich documents):

```
three_way_diff(base, alice, bob) → ThreeWayDiff
three_way_merge(base, alice, bob, strategy) → MergeResult
```

### How It Works

1. **Fingerprint alignment** — Each element has a 256-bit BLAKE3 content fingerprint. The algorithm finds the longest matching subsequences between base↔alice and base↔bob, establishing which elements survived in each branch.

2. **Segment classification** — Base positions are classified as:
   - **Unchanged** — matched in both alice and bob
   - **OnlyA** — changed only in alice's branch
   - **OnlyB** — changed only in bob's branch
   - **Conflict** — changed in both branches
   - **InsertA/B** — new elements in alice/bob with no corresponding base position

3. **Merge assembly** — Segments are sorted by base position and assembled into the merged edition. For conflicts, the LastWriterWins strategy takes the branch with more content. Each source position gets a mapping to its merged position.

4. **Position mapping** — The merge returns `a_to_merged` and `b_to_merged` mappings that track where every element in alice and bob ended up in the merged result. These are composable: `alice_map.compose(merge_map)` gives alice→final.

### Why This Matters

Because the merge operates on O-tree elements (not text characters), it preserves:

- **Transclusions** — a reference to another document's content is an element with its own identity. When alice inserts a paragraph and bob reorders sections, the transclusion survives the merge.
- **Overlays** — layered annotations on media (imagine Figma comments that survive concurrent editing)
- **Data bindings** — structured elements (a spreadsheet cell, a form field) are first-class merge participants, not text ranges that can be split mid-character
- **Attribution** — each element carries provenance, not just "who edited this text span"

### Technical Details

| Component | File | Lines |
|-----------|------|-------|
| Three-way diff/merge engine | `src/edition/three_way.rs` | ~1700 |
| Position mapping (compose, inverse, restrict) | `src/edition/mapping.rs` | ~400 |
| O-tree (Loaf nodes, bulk build, transform) | `src/edition/orgl.rs` | ~2000 |
| Typed elements (9 types, fingerprints) | `src/edition/range_element.rs` | ~800 |
| Content-addressed storage (GrandMap) | `src/edition/grandmap.rs` | ~1500 |

Key public API:

```rust
pub fn three_way_diff(base: &Edition, a: &Edition, b: &Edition) -> ThreeWayDiff;
pub fn three_way_merge(base: &Edition, a: &Edition, b: &Edition, strategy: MergeStrategy) -> Result<MergeResult, MergeConflict>;
pub fn build_merge_mapping(source: &Edition, merged: &Edition) -> Mapping;
```

Types:

```rust
pub struct ThreeWayDiff {
    pub unchanged: Vec<AlignedRun>,
    pub only_a: Vec<DiffRegion>,
    pub only_b: Vec<DiffRegion>,
    pub conflict: Vec<ConflictRegion>,
}

pub struct MergeResult {
    pub merged: Edition,
    pub a_to_merged: Mapping,   // alice position → merged position
    pub b_to_merged: Mapping,   // bob position → merged position
}

pub enum MergeStrategy { LastWriterWins }
```

Mapping operations:

```rust
mapping.of(pos)          // source → target position
mapping.inverse()        // target → source
mapping.compose(&other)  // chain two mappings
mapping.restricted(...)  // narrow to a region
```

### Test Coverage

49 dedicated tests in `three_way.rs`, plus 12 property-based tests in `proptest_crates.rs`. Coverage includes:

- Identity merges (no changes from either side)
- Single-branch edits (insert, delete, replace)
- Concurrent non-overlapping edits
- Concurrent insertions at same position
- Deletions with concurrent inserts in deleted region
- Both sides making identical changes
- Empty base with inserts from both sides
- Insert at start/end of document
- Rich element preservation (Data, Edition refs, not just text)
- Mapping inverse roundtrips (source → merged → source)
- Mapping composition roundtrips
- Order preservation (merged positions respect source ordering)
- No duplicate merged positions

Total test suite: **1939 tests passing** (1701 lib + 219 integration + 12 proptest + 7 TLS).

## Roadmap

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Three-way diff engine | Done |
| 2 | Mapping-based position transforms | Done |
| 3 | Replace yrs CRDT with O-tree merge | Done |
| 4 | Per-element attribution (ElementProvenance on Carrier) | Done |
| 5 | Multi-user relay (push edits to concurrent sessions) | Next |
| 6 | LLM integration — semantic zoom, auto-transclusion | Planned |

Phase 3 is the visible milestone: swap out the Yjs-based CRDT so the server uses O-tree merge for all collaborative edits. After that, rich structure (transclusions, overlays, data bindings) survives concurrent editing — which no existing collaborative editor does.

## What Exists Today (main branch)

The `main` branch has a working document server with:

- Content-addressed O-tree storage with GrandMap deduplication
- WebSocket-based real-time collaborative editing (via yrs/Yjs CRDT)
- React web frontend with document editing, revision history, and transclusion visualization
- Cryptographic identity (Ed25519 signing, X25519 key exchange)
- Club-based access controls
- Federation transport with PBFT consensus
- TLS support

The `o-tree-merge` branch (this branch) adds the merge engine on top.

## Building

```bash
cargo build --features server
cargo test --features server     # full suite (1939 tests)
cargo test --lib three_way       # merge engine only (49 tests)
```

## License

Apache 2.0 (Copyright 2026 David G Jones and contributors). The original Udanax Gold C++ codebase is MIT/X11 (Copyright 1979-1999 Udanax.com).
