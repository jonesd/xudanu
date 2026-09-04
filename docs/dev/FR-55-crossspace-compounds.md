# FR-55: CrossSpace Compound Documents

- **ID:** FR-55
- **Status:** Specification
- **Supersedes:** FR-34 Phase H (dormant) — activated with a concrete
  architecture grounded in what actually landed since (FR-37 crums,
  FR-38 span keys)
- **Depends on:** FR-38 S1/S2 (span keys — landed), FR-37 (crum
  comparison — landed), FR-34 F/G (tumbler bridge, splay — landed)
- **Gold reference:** the mapping subsystem — `CrossSpace`,
  `ActualCrossSpace`, `XuCrossSpace`, `Arrangement`, `ExplicitArrangement`,
  `Mapping`/`CrossMapping`/`SequenceMapping`/`CompositeMapping`/
  `ConstantMapping` (17 classes, `src/image/st.dir/`)
- **Effort:** ~5–6 days across H1–H4

## 1. The problem with compounds today

`CompoundEdition` (compound.rs:350) is `Vec<CompoundElement>` — text
runs and `Span { source_work_id, char_start, char_end }`. Three
structural weaknesses:

1. **Offsets rot.** A source edit shifts `char_start/char_end`; the
   compound silently points at the wrong text (the exact problem
   FR-38 solved for links — unsolved here).
2. **No structure.** A flat list has no crums, no tree, no sharing:
   compounds can't be crum-diffed (FR-37 blind), two compounds
   quoting the same source share nothing, section identity doesn't
   exist.
3. **Follow-back is guesswork.** The Origin panel locates a quote by
   excerpt search; Gold did it by *walking a mapping*.

Meanwhile `space/` already contains the ported Gold algebra —
`CrossSpace2` + `Tuple2` + `CrossRegion2` (cross.rs), the Mapping
family (mapping.rs), `Arrangement` (arrangement.rs), the N-dim
generalization (cross_n.rs) — all unwired to real documents.

## 2. Design

### The architecture in one picture

```
Compound document (a first-class Edition, CRDT-editable)
┌─────────────────────────────────────────────────────────┐
│ local orgl (i64 local positions — FR-37 diffable,      │
│   crum-identified, splayable — all machinery intact)    │
│                                                         │
│ Segments table (the Arrangement):                       │
│   local span key ──► (source work, source span key)     │
│        │                                  │             │
│        ▼                                  ▼             │
│   local char range              source resolves via      │
│   (stable, FR-38)               the source's OWN map    │
└─────────────────────────────────────────────────────────┘
        follow-back = walk the segment entry → exact
        source range, current offsets — never excerpt search
```

**Key decision (deliberate):** the compound's enfilade stays in
**local i64 space** — we do NOT generalize `OrglRoot`/`Loaf` over
arbitrary position types. Cross-space identity lives in the
*Arrangement*, not in the tree. This keeps FR-37/FR-52 machinery
(crums, OwnerSet, splay, diff) untouched and compounds fully
first-class Editions. Gold put cross-positions inside the enfilade
(`CrossSpace2<SequenceSpace, IntegerSpace>`); we put them in the
mapping layer — same algebra, different placement, because our
orgl carries responsibilities Gold's didn't (CRDT convergence).

### H1 — Compound v2: orgl + span-keyed segments (~2 days)

```rust
pub struct CompoundSegment {
    /// Local identity in the compound (FR-38 key space of the
    /// compound work itself).
    pub local_key: SpanKey,
    /// What this segment IS.
    pub source: SegmentSource,
}

pub enum SegmentSource {
    /// Native compound text (authored here).
    Authored,
    /// Transcluded from a source work — identified by SPAN KEY,
    /// never char offset. Survives every source edit.
    Transcluded {
        source_work: BeId,
        source_key: SpanKey,      // resolved via the source's map
        crum_at_assembly: Crum,   // what it was when placed
    },
}
```

- Assembly: `compound.assemble()` renders through each source's
  span-key map (exact ranges, current offsets) into the local orgl;
  a missing/retired source key renders a visible placeholder
  (Gold's async-fill seam — see issue #9, naturally integrated here)
- `crum_at_assembly` enables drift detection: if the source span's
  content crum differs today, the segment is *marked* (source moved
  on) — displayed, never silently wrong

### H2 — The Arrangement: local ⇄ cross-position (~1–2 days)

- Build on `space::cross::CrossSpace2<DocTumbler, CharPos>` +
  `space::mapping`: an `ExplicitArrangement` backed by the segments
  table
- API: `arrangement.at(local_pos) -> Option<CrossPosition>` —
  *"compound char 540 = docB.2.1, chars 10–90"* — the Gold mapping
  walk, one lookup
- Wire Origin panel: exact mode (walk) with excerpt-search as
  fallback only for legacy un-keyed content
- Inverse: `arrangement.place(source_ref) -> local range` — where
  in this compound does that source passage appear (feeds beams)

### H3 — Structural comparison of compounds (~1 day)

- Compounds diff via FR-37 `crum_diff` like any Edition
- Segment-level identity: two compounds quoting the same source
  span produce equal `source_key`-derived crums — shared sections
  detectable in O(1), the "Section 1.2 is identical" of the FR-34
  vision
- `shared_regions_nway` works across compounds unchanged (they ARE
  editions)

### H4 — Persistence, migration, UI (~1 day)

- Segments persist in the WorkState chunk tree (a
  `segments_hash` section, FR-36 GC checklist applies)
- Legacy migration: existing `CompoundEdition` inline entries get
  keys derived from current offsets (same one-time-derivation
  pattern as FR-38 link migration; imperfect once, exact forever
  after)
- CompoundBuilder UI binds to real segments (its shell already
  exists); beams view gains compound columns

## 3. What this unlocks (why it's the foundation piece)

- **The Xanadu publishing form**: books assembled from tumblers
  spanning many sources, every quote live and followable — the demo
  artifact for the Roger relationship
- **Application substrate** (your framing): cross-referenced
  editions, annotated readers, parallel translations, casebooks —
  all "ordered keyed segments + mapping" on the same engine
- **Issue #9 seam**: segments render placeholders when a source
  hasn't arrived — async fill becomes a compound feature, not a
  separate mechanism
- **Overlays later**: a layer is a compound whose segments key into
  a base work — FR-55 builds its engine half without intending to

## 4. Test plan

1. `compound_survives_source_edits` — source text edited before and
   after segment placement; compound renders the right content both
   times (the rot fix, pinned)
2. `drift_marked_not_silent` — source span content changes; segment
   renders + flags, never silently wrong
3. `arrangement_walk_exact` — local→cross-position for every
   segment; inverse lookup
4. `placeholder_for_missing_source` — retired/unarrived source key
   renders a placeholder span
5. `compound_crum_diff_sections` — two compounds sharing a source
   section: FR-37 reports the shared region O(1)
6. Migration: legacy inline compound → keyed segments, rendered
   output byte-identical
7. Persistence round-trip through the checkpoint tree (FR-36 GC
   protection included)

## 5. Out of scope (recorded, not forgotten)

- Generalizing OrglRoot over position types (Gold's placement) —
  revisit only if a consumer needs cross-positions *inside* the tree
- Overlays (issue #15) — layer-on-base via segments; separate FR
  after review
- Federated compounds (source on a peer server) — needs cross-server
  key exchange first (FR-38 S3 remainder)

## 6. T2 mechanics — how the server core actually works (the anti-magic doc)

### The four key spaces (who owns which keys)

| Key space | Owner | Lifetime | Stability rule |
|---|---|---|---|
| **Source map keys** | each source work's `SpanKeyMap` (Server.span_key_maps) | from work birth (eager init), forever | allocated ONCE at placement; reused across re-sets; never re-derived |
| **Local segment keys** | the compound derivation (fresh `SpanKeyMap` per derive) | one derivation | EPHEMERAL — freshly allocated every `derive_compound_segments`; identity within one derive only |
| **Placement crum** | the segment (BLAKE3 of placed content) | frozen at placement | drift detector — compared against current source content at every resolve |
| **Placed len** | the segment | frozen at placement | extent metadata; rides with the source key anchor |

**The invariant the reuse test caught:** on re-set with the same
span, the SOURCE key + crum + placed_len are reused (stable), but
the LOCAL key is always freshly allocated. Skipping local
allocation on the reuse path produced duplicate local keys — now
pinned by `compound_segments_reused_across_sets`.

### The derive path (set_compound_edition → segments)

```
set_compound_edition(work, elements)
  └─ derive_compound_segments(work, elements)
       for each element:
         Text   → fresh local key (insert_span at running total)
                  → Authored segment
         Span   → REUSE match? (same source + same range + source
                  key still resolves) → stable source fields +
                  FRESH local key
                → else PLACEMENT: insert_span(cs, len) into the
                  SOURCE's live map (the dedicated key — never a
                  borrowed granularity key) + crum of current
                  content → Transcluded segment
```

### The resolve path (compound_resolve_segments)

1. Clone each referenced source's map once (mutex → owned; maps
   are small)
2. `resolve_segments_owned` over live (map, text) pairs
3. Per segment: key anchors position (range start), placed_len
   carries extent, crum comparison yields the trichotomy —
   Text / Drifted (flagged) / Placeholder (async-fill seam)

### Persistence

- `Server.compound_segments: HashMap<BeId, Vec<CompoundSegment>>`
- Checkpoint: into the Manifest → **SocialSection**
  (`compound_segments`, serde-default → old checkpoints restore
  empty and re-derive on first set — self-healing)
- Restore: social chunk → server map (same path as compounds)
- **Self-healing property**: segments are DERIVED state — losing
  them costs nothing but a re-derivation; the source-map placement
  keys (the truly stable identity) live in the source works' own
  maps, checkpointed with FR-38

### What is deliberately NOT magic

- No offset stored anywhere in a segment — offsets are computed
  fresh at every resolve from the key anchor
- No silent wrongness possible: content change ⇒ crum mismatch ⇒
  Drifted flag; key retirement ⇒ visible Placeholder
- Drift test pins the honest edge: a shorter replacement renders
  the placed extent (trailing newline included) — the flag, not
  the slice, is the contract

