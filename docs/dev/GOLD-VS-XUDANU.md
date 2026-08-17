# Gold and Xudanu: Two Implementations of the Enfilade Idea

A structural and algorithmic comparison of the original Udanax Gold
backend (C++, 1992) and Xudanu (Rust, 2026), for readers new to either.

Sources compared:
- Gold: `original-code/xanadugold/src/` — `server/loavesx.hxx` (Loaf),
  `server/orootx.hxx` (OrglRoot), `server/canopyx.hxx` (CanopyCrum),
  `server/htreex.hxx` (Htree/crums), `server/entx.hxx` (Ent server),
  `server/tcludex.hxx` (transclusion), `xlatexpp/sequencp.hxx`
  (Sequence edges)
- Xudanu: `src-rust/src/edition/` — `orgl.rs`, `edition.rs`,
  `three_way.rs`, `range_element.rs`; `src-rust/src/space/`

Both systems solve the same problem: mutable, connected documents
where content is shared, addressed, and compared structurally. They
arrive at strikingly similar cores and deliberately different edges.
This document maps the overlap, explains where and why they diverge,
and compares measured complexity. It is written to be fair to both:
in several places the Gold team's choices look prescient, and their
reasoning survives in the code comments thirty years later.

---

## 1. The shared core: nearly identical

The 1989–92 Smalltalk-to-C++ translation left Gold with a typed,
message-passing style. Xudanu's Rust reads like a spiritual port:

| Concept | Gold (C++) | Xudanu (Rust) | Notes |
|---|---|---|---|
| Tree node | `class Loaf : public OPart` with `InnerLoaf`/`OExpandingLoaf` (`loavesx.hxx`) | `enum Loaf { Leaf, Split, Dsp }` (`orgl.rs`) | Gold splits Inner/Expanding (disk-backed vs in-memory expansion); Xudanu's enum unifies them |
| Document root | `OrglRoot` with `transformedBy(Dsp)` / `unTransformedBy` (`orootx.hxx`) | `OrglRoot` with `transformed_by(i64)` | Same lazy-shift idea: Gold's Dsp is a full algebraic displacement; Xudanu's is a single i64 offset |
| Region algebra | `XnRegion` everywhere (arguments to nearly every Loaf method) | `XnRegion` (transition-list) | Direct port; Gold's is generic over Space, Xudanu's is i64-specialized |
| Subtree hashes | `CanopyCrum` binary trees (`canopyx.hxx`) | per-node `crum: [u8; 32]` BLAKE3 | Both exist to answer "are these subtrees equal?" in O(1) |
| Iteration | `Stepper` of `Bundle`s (`loavesx.hxx: bundleStepper`) | `bundle_stepper.rs` | Run-length iteration over the tree |
| Content values | `BeRangeElement` / `FeRangeElement` (Back-end/Front-end) | `RangeElement` + `Carrier` | Gold splits Be/Fe by trust boundary; Xudanu has one type with server-side enforcement |
| Fill/extract | `Loaf::fill(keys, arrangement, array, dsp, edition)` | `Edition::fetch_range` + entries cache | Same "give me this region as flat data" operation |

The overlap is not accidental — Xudanu ported the enfilade design
deliberately (AGENTS.md documents the lineage), then rebuilt everything
around it.

---

## 2. Where they diverge, and why

### 2.1 Positions: tumbler-native vs integer-native + bridge

This is the deepest difference and it shapes everything downstream.

**Gold**: positions ARE tumblers (hierarchical rationals — 3.1 fits
between 3 and 4; nothing ever renumbers). The Sequence/edge machinery
(`sequencp.hxx`: `AfterSequence`, `BeforeSequence`,
`BeforeSequencePrefix`) implements the total order. Insertion between
neighbors is O(1) position allocation, forever stable, and global
addresses (doc.account.stream.char) fall out for free.

**Xudanu**: the enfilade, regions, wire protocol, and persistence are
all i64-native. Stable positions are provided by a gap allocator
(`space/position_allocator.rs`): new entries take the midpoint of the
surrounding gap; dense layouts pay one re-space and "heal" to spaced.
Tumbler addresses exist as a typed layer (`XudanuTumbler`,
`DocumentArrangement`) bridged over the i64s — names, not storage.

**Trade-offs**: Gold's choice is cleaner but forced everything to be
tumbler-aware (compare, fill, disk layout all carry Sequence algebra).
Xudanu's choice keeps the hot paths as integer arithmetic and lets
regions stay interval-transition lists, but re-introduces occasional
local relabeling (amortized O(1) per insert — classic list-labeling)
where Gold has none. Xudanu also caches a flat (entries, char-starts)
Vec alongside the tree — a deliberate "tree for structure, Vec for
scan" hybrid Gold never needed because it never left the tree.

### 2.2 Concurrency model: single-grab Ent vs CRDT merge

**Gold**: `entx.hxx` implements the Ent protocol — documents are
grabbed (exclusive write), edited, released. Front-ends speak a
structured protocol (`winfe/fe.h` command codes: CM_GRAB, CM_RELEASE,
CM_STARTLINK...). Two writers cannot conflict because one of them is
locked out. Simple, correct, single-server.

**Xudanu**: concurrent editing is the product. Edits arrive as
character deltas, get applied to a session base, and divergent bases
merge via a three-way, fingerprint-aligned merge with LWW conflict
resolution (`three_way.rs`) — a CRDT-flavored layer Gold never had.
The price: Xudanu needs diff/align/merge machinery (alignment,
mappings, span migration) that Gold does not need at all. Roughly a
third of `three_way.rs` exists only because there is no grab lock.

### 2.3 Crums: accreting canopy vs hash-chained nodes

**Gold**: CanopyCrums "form binary trees that accrete in a balanced
fashion. No rebalancing ever happens" (`canopyx.hxx`, Ravi's comment).
They also carry community metadata — endorsement/Club flag bits
"widded by ORing up the canopy", so permission checks prune the search.
A crum is simultaneously a content hash AND a permission summary.

**Xudanu**: crums are pure BLAKE3 content hashes chained bottom-up
(`leaf:`/`split:`/`dsp:` domain-separated), incrementally maintained
per node (PERF-PLAN S2), with per-entry fingerprint caches in leaves.
Permission checks are separate (clubs, enforced at the server API).
The dual-use trick is elegant but couples concerns Xudanu keeps apart;
the pure hash makes crum equality trivially sound for O(1) merge
fast-paths, which Xudanu leans on heavily (three_way.rs crum skips).

### 2.4 Persistence: image/scavenger vs chunk store + WAL

**Gold**: a persistent object image with a scavenging GC
(`scavx.cxx`, `xpp/garbagex.*`, 45K+ lines of memory/disk machinery).
Objects live in an image; the scavenger walks and reclaims.

**Xudanu**: content-addressed chunk store + manifest + WAL
(`persist/`), with typed snapshots and (since PERF-PLAN S1) sliced
non-blocking checkpoints. No object image — chunks are plain
serialized data, immutable once written, GC'd by reachability from the
root chunk. Modern, auditable, and crash-safe by construction, at the
cost of Xudanu never gaining Gold's "everything persists
transparently" behavior.

### 2.5 Trust and identity: baked into types vs composed at the edge

Gold's Be/Fe split (Back-end/Front-end RangeElements, `BeEdition`
arguments in Loaf methods) encodes the trust boundary in the type
system. Xudanu has one `RangeElement`, with Ed25519 provenance per
element, club-based permissions, and a tamper-evident audit log —
identity composed at the API layer rather than the data layer. Gold's
approach is leaner; Xudanu's carries cryptographic attribution through
merges (span provenance migration), which Gold had no mechanism for.

---

## 3. Complexity comparison (measured Xudanu, debug build)

| Operation | Gold (design intent) | Xudanu before pipeline | Xudanu now | Xudanu test |
|---|---|---|---|---|
| Point lookup (fetch) | O(log n) | O(log n) | O(log n) | orgl tests |
| Tree edit (with/without) | O(log n) | O(n) eager rehash | **O(log n)**, flat 1.8ms @100k | `benchmark_tree_op_on_large_editions` |
| Insert position alloc | O(1) (tumbler) | O(n) renumber | **O(1) amortized** (gap alloc; one heal for dense) | `tree_ops_preserve_unrelated_positions` |
| Single-char delta | O(log n) | O(n) flatten-rebuild | **~O(log n)**: 4.8ms steady @100k frag, 0.45ms @9k batched | `benchmark_apply_delta_at_scale` |
| Equality/compare | O(1) crum | O(1) crum | O(1) crum (byte-identical, incrementally maintained) | `benchmark_crum_comparison`, prop test |
| Three-way merge (no concurrent edits) | n/a (grab lock) | O(1) via crum skip | O(1) via crum skip | `benchmark_merge_no_concurrent_edits` |
| Three-way merge (both changed) | n/a | O(n²) alignment | **O(n)** patience-style: 3.87s @100k (was 207s) | `benchmark_merge_both_sides_scale` |
| Merge-mapping build | n/a | O(n²) | **O(n log n)**: ~100ms @9k (was 6.4s) | `benchmark_build_merge_mapping_scale` |
| Region copy/extract | O(log n) shared | O(n) clone | **O(1)-shared** via Arc subtrees | orgl copy tests |
| Checkpoint impact on dispatch | n/a (single-user) | full lock stall | sliced bursts, interleaves | `sliced_checkpoint_*` |

Reading this honestly: where the two systems share operations (fetch,
edit, compare, copy), Xudanu now matches Gold's complexity class. Where
Xudanu does things Gold never did (concurrent merge, non-blocking
checkpoint, federation), there is no Gold baseline — those rows are
Xudanu-specific features, paid for by the machinery in §2.2.

The residual gaps in constant factors (milliseconds in debug builds)
are dominated by blake3 hashing and Vec splices that a release build
and fingerprint memoization would compress further.

---

## 4. What each system taught the other (2026 pipeline retrospect)

Several PERF-PLAN stages were, in effect, Xudanu re-learning Gold:

- **S2 (per-node crum caches)** is Gold's OC-on-every-node design,
  recovered. Gold never had the eager-rehash bug because crums were
  always node-local and incrementally widded.
- **S4 (stable positions)** is Gold's never-renumber property,
  re-derived pragmatically. The gap allocator delivers the same
  amortized guarantee over integers that tumblers give absolutely.
- **S5-0 (Arc structural sharing)** matches Gold's pointer-identity
  model, where sharing subtrees is free because objects are
  reference-counted in the image. Rust's Arc made the same semantics
  expressible with compile-time safety.
- **S3 (splay) inverted**: Gold needed splay because all access
  descends the tree; Xudanu's flat-cache + localized-assembly access
  pattern made it redundant — an honest measurement said no. But that
  same measurement caught a latent content-loss bug in the splay
  terminal arms, which is now fixed and regression-tested. The lesson:
  measure before porting; the access pattern decides the optimization.

Conversely, Xudanu holds lessons for a Gold revival: the flat entries
cache (tree for structure, Vec for scan) is a very effective hybrid;
patience-style fingerprint alignment gives linear three-way merges
that a collaborative Gold would need; and chunk-store persistence with
content-addressed crums maps naturally onto Gold's content-hash
instincts.

---

## 5. Remaining known gaps (Xudanu backlog)

1. **Persistent layouts are still dense in old data** — gap layouts
   appear through the S5 fast path; a bulk migration/compaction option
   could make spacing a storage invariant.
2. **Release-build benchmarking** — all numbers above are debug-build;
   release profiles will shift constants (not classes).
3. **Virtual structures / OExpandingLoaf** — **FR-37, in progress**:
   Phase 1-2 landed (unified resolution + generation-checked caches —
   no staleness window); Phase 3 core landed (`RangeElement::Virtual`
   with spec-fingerprint determinism and edit-time revision pinning;
   remaining: wire-payload registration); Phase 4 (virtual enfilades
   for derived documents) pending.
4. **License summary overlays (dual-use permission crums)** — **FR-38,
   Phases 1-3 landed**: run-length ownership overlay (licenses resolve
   at query time — re-licensing never rebuilds, an improvement on
   Gold's baked-in flag bits), span-level badges at transclusion
   attribution, egress badges on the public content API. Federation
   hard-block deliberately left as operator policy.
5. **CrossSpace/Sequence as storage** — `space/sequence.rs` (1248
   lines) and `space/cross.rs` remain dormant as anything but naming;
   activating them is the Phase H compound-document path (overlaps
   FR-26 Phase 4 spanfilade; FR-37 Phase 4 is the on-ramp).
6. **Tumbler-addressed federation at scale** — cross-server tumblers
   exist; routing and caching across servers is future work (FR-6+).
   The public content API now carries span license classes (FR-38
   P3), so peers can compliance-check without provencence round trips.
7. **Pre-existing infra debt** (from before the pipeline): 10
   integration-test failures and a broken default-features build,
   both root-chunk-migration fallout; tracked on the branch.

## 6. Combination opportunities (pipeline enhancements × features)

Unplanned capabilities that fall out of combining the 2026 pipeline
work with existing Xudanu features — candidates for future FRs:

- **Section-level federation sync** — O(1) crum equality + chunk
  crums let FR-35's Bloom-filter exchange skip whole identical
  sections instead of whole works: "sections 1-3 match, sync only 4".
  Replication granularity drops from document to section with no new
  machinery beyond a crum-walk diff.
- **Never-breaking permalinks through merges** — stable positions +
  the tumbler bridge mean a tumbler address into a document survives
  concurrent-edit merges that would have renumbered it under dense
  layouts. Merge history becomes addressable without a redirect map.
- **Cheap document branching** — Arc structural sharing makes
  snapshotting an edition O(1)-ish; version timelines (FR-23) could
  offer branch/fork with shared history the way Gold's image
  persistence did implicitly.
- **Alignment-powered source detection** — the S7 patience alignment
  is a general "find matching runs between two documents" primitive;
  `source_matcher.rs`/`detector.rs` (copy detection) and backfollow
  could reuse it for near-duplicate detection at scale.
- **License-filtered views** — FR-38 overlays composed with virtual
  enfilades (FR-37 Phase 4): "this document as visible to club X" or
  "quotable-only spans" become computed documents. Gold's
  permission-pruned canopy searches, reborn as first-class views.
