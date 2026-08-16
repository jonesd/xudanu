# FR-34: Enfilade-Native CRDT

## Overview

The enfilade (orgl.rs) is Xudanu's core data structure, ported from the
Udanax Gold C++ codebase. It is a balanced tree (Loaf/Split/Dsp) that
supports efficient point lookup, region extraction, lazy displacement,
and content-addressed subtree hashing.

This document tracks the multi-phase plan to make the CRDT operate ON
the tree directly, progressively approaching the original Gold enfilade
design while retaining modern features (CRDT convergence, cryptographic
provenance, federation, web platform).

## Design Principles

- **Crum-first** -- use subtree hashes (crums) to skip identical regions
- **Tumbler-native** -- migrate toward SequenceSpace positions
- **Incremental delivery** -- each phase is independently shippable
- **Non-breaking** -- existing serialized data continues to work
- **Gold-inspired, not Gold-limited** -- adopt Gold concepts where they
  add value, add modern features (CRDT, crypto, federation) that Gold
  never had

## Current State (August 2025)

### Completed

| Phase | What | Impact |
|---|---|---|
| Enfilade-merge 1-5 | Entry-level CRDT, provenance lifecycle | Foundation |
| P0 | Subtree crums (BLAKE3 Merkle) | O(1) equality, 24 tests |
| P1 | Inline coalesce in delta path | ~40% faster deltas |
| Phase A | Crum fast-path in diff | O(1) merge, no concurrent edits |
| Phase B | Alignment skip via crum | Skip O(n) when one side unchanged |
| Phase C | Assembly skip for single-sided | No tree rebuild |
| Phase D | Tumbler <-> Sequence bridge | Typed accessors on CrossServerRef |
| Phase E | Eliminate Vec clone in delta | Remove O(n) allocation per edit |
| Phase F | DocumentArrangement, chunk crums | Section-level comparison, tumbler queries |
| Phase G | Splay exposed at Edition level | Locality optimization available |
| Phase H | Compound span tumbler addressing | Transclusion coordinates via tumblers |
| Phase J | Overlapping-domain combine | Structural merge without flatten |
| Tumbler resolve | Wire op 0x0F0E + paste-to-navigate UI | Resolve tumbler to local work |
| Tumbler search | Server::search_by_tumbler_prefix | Find works by tumbler prefix |
| Tumbler listing | Server::list_work_tumblers | All works with typed tumbler addresses |
| Tumbler resolve | Wire op 0x0F0E + paste-to-navigate | Resolve tumbler to local work |
| Tumbler permalink | URL hash routing + copy link button | Shareable document links |
| Crum in metadata | WorkListEntry + RevisionMetaEntry | O(1) change detection |
| Playwright E2E | 8 browser tests | Real UI flow testing |
| Transclusion fix | Metadata preserved through migration | placed_at/by, content_hash survive |
| Depth limit fix | 32 → 1000 (cycle detection is real protection) | No arbitrary limits |
| Structural transclusion | RangeElement::StructuralTransclusion | Enfilade subtree references, live content |
| Provenance | Span migration, non-text preservation | Attribution survives merges |
| Blob hash | u64 -> String migration | JS precision fix |
| Property tests | 17 properties x 256 cases | Correctness verification |
| PERF-PLAN S0 | Instrumentation + benchmark harness | Measured baselines (`0f79c8b`) |
| PERF-PLAN S1 | Sliced non-blocking checkpoint (#90) | Dispatch no longer stalls in prepare (`8135474`) |
| PERF-PLAN S2 | Per-node crum/domain caches (Gold OCs) | `with()` flat: 363ms -> 9ms @100k (`f71e98a`) |
| PERF-PLAN S6 | Linear merge mapping (cursors + from_parts) | 87x @9k entries (`29e7743`) |

### Test counts: ~3115 Rust lib (incl. 4 perf benchmarks + cache-equivalence property tests) + 282 integration + frontend/E2E unchanged

### Performance comparison (measured)

| Operation | Before (v1.3) | After (v1.4) | Gold | How measured |
|---|---|---|---|---|
| Merge (no concurrent edits) | O(n) | **O(1)** — 250ns | O(1) | `benchmark_merge_no_concurrent` |
| Merge (one side unchanged) | O(n) | **O(n/2)** | O(log n × k) | `benchmark_merge_single_sided` |
| Merge (both sides changed) | O(n) | O(n) | O(log n × k) | `benchmark_merge_both_sides` |
| Delta (single char edit) | ~4× O(n) | **~1× O(n)** | O(log n) | Inline coalesce eliminates rebuild pass |
| Crum equality check | O(n) tree walk | **O(1)** — 250ns cached | O(1) | `benchmark_crum_comparison` |
| Transclusion resolve | O(n) per level | O(1) cached_content | O(1) structural ref | Cached on stamp |
| Transclusion migration | Drops metadata | **Preserves metadata** | N/A (single-user) | 12 edge case tests |
| Bloom filter check | N/A | O(k) per item (k=7) | N/A | 33 bloom tests |
| Bloom filter exchange | N/A | O(n_bits/8) bytes | N/A | 3-node Docker test |
| Tree op (with) | O(n) eager rehash | **O(log n)** — 9ms @100k (was 363ms) | O(log n) | `benchmark_tree_op_on_large_editions` |
| Merge mapping build | O(n^2) rescan + refold | **O(n log n)** — 74-109ms @9k (was 6.4s) | N/A | `benchmark_build_merge_mapping_scale` |
| Checkpoint prepare | full lock hold | sliced lock bursts, dispatch interleaves | N/A | `sliced_checkpoint_*` tests |

### Enfilade feature activation

| Capability | Status | Gold equivalent |
|---|---|---|
| Crums on OrglRoot | **Active** (cached, O(1)) | OCs (original crums) |
| Crums on Loaf nodes | **Active** — per-node caches + per-entry fingerprints, incrementally maintained (S2) | OCs on every node |
| with/without | Available | Primary edit path |
| copy | Available | Transclusion extraction |
| combine | Available (disjoint only) | Compound assembly |
| combine_overlapping | **Active** (LWW) | Structural merge |
| Dsp | Working | Position management |
| Splay | **Exposed** at Edition level | Active in Gold |
| Tumbler bridge | **Connected** (Sequence algebra) | Native |
| CrossSpace | Dormant | Compound documents |
| Arrangement | Dormant | Transclusion mapping |
| Structural transclusion | **Active** (cached_content) | Tree references |
| Bloom filter federation | **Active** (33 tests) | N/A (trust-based) |

## Roadmap: Approaching Gold

### Phase F: Tumbler Position Layer

**Goal**: Make tumblers the primary addressing model for cross-document
operations, while keeping i64 for document-level editing.

**What Gold had**: Tumbler positions everywhere. Inserting between
positions 3 and 4 creates 3.1 -- no renumbering. Cross-document
addressing via tumbler hierarchy.

**What we do now**: i64 positions within a document, string-based
tumblers for cross-server references.

**Phase F delivers**:

1. **Arrangement mapping** -- connect IntegerSpace to SequenceSpace
   - `space/arrangement.rs` (115 lines) maps between spaces
   - A document arrangement maps i64 char positions to tumblers
   - Enables "what tumbler addresses char 42 of work 5?"

2. **Section-level crums** -- compare documents at section granularity
   - Partition an edition's entries by tumbler prefix (e.g., sections)
   - Compute crum per section
   - Two documents compared section-by-section, not entry-by-entry
   - "Section 1.2 is identical" --> skip in diff

3. **Typed tumbler in HyperRef** -- replace string positions with typed
   - `HyperRef.start_position` / `end_position` become `Option<i64>`
     (document-local) but gain a `tumbler_address: Option<XudanuTumbler>`
     for cross-document references
   - Links reference content by tumbler, not just work_id + char offset

4. **Tumbler-based region queries**
   - `edition.entries_under_prefix(prefix)` -- all entries in a section
   - `edition.section_crum(prefix)` -- crum for one section
   - Enables outline-aware operations

**Estimated effort**: 3-4 days

**Depends on**: Phase D (done)

### Phase G: Splay Activation

**Goal**: Activate the dormant splay code (140 lines, tested) in the
CRDT path for locality optimization.

**What Gold had**: Splay reorganizes the enfilade tree so that edited
regions are co-located under a single subtree. After splaying around
a changed region, the diff only needs to descend into one branch.

**What we do now**: The tree structure is determined by bulk-build and
never reorganized for locality.

**Phase G delivers**:

1. **Pre-merge splay** -- before three-way diff, splay base/A/B trees
   around the changed region (identified by crum divergence)
   - Changed entries co-located under one subtree
   - Diff descends into only that subtree

2. **Post-edit splay** -- after `apply_text_delta_to_edition`, splay
   the result tree around the edited region
   - Next edit in the same region hits a shallow subtree
   - Repeated edits to the same paragraph are O(log k) not O(log n)

3. **Splay + crum synergy** -- splayed subtrees have their own crums
   - Compare two splayed subtrees in O(1)
   - Only the "changed" subtree needs detailed comparison

**Estimated effort**: 2-3 days

**Depends on**: Phase F (for section-level splay targets)

### Phase H: Compound Documents via CrossSpace

**Goal**: Enable compound documents where sections come from different
source works, addressed via CrossSpace tumblers.

**What Gold had**: CrossSpace(DocumentSpace, CharacterSpace) for
addressing content across document boundaries. Compound documents
assembled from tumbler-addressed spans of multiple works.

**What we do now**: Inline `RangeElement::Transclusion` elements that
reference source works by ID + char range. No structural composition.

**Phase H delivers**:

1. **CrossSpace enfilade** -- an enfilade instantiated with
   `CrossSpace2<SequenceSpace, IntegerSpace>` for compound documents
   - Positions are `Tuple2(doc_tumbler, char_position)`
   - A compound document contains spans from multiple source works
   - Each span retains its source document identity in the position

2. **Compound assembly via combine** -- use `OrglRoot::combine()` to
   merge content from multiple works into a compound enfilade
   - Each source work contributes a subtree
   - The compound enfilade shares tree structure with sources

3. **Arrangement-based transclusion mapping**
   - An arrangement maps compound positions to source positions
   - "Compound doc position 5 = Source doc B, chars 10-20"
   - Enables following a transclusion back to its source

**Estimated effort**: 4-5 days

**Depends on**: Phase F (tumbler layer)

### Phase I: O(log n) Delta Application

> **Status (2026-08-16): NOT implemented.** The delta path remains
> flatten-walk-rebuild in `apply_text_delta_to_edition`. Prerequisite
> work has landed: tree ops are now O(log n) with incrementally
> maintained crums (PERF-PLAN S2), and the per-edit merge-mapping cost
> is linear (S6). The remaining blocker is unchanged: contiguous i64
> positions force renumbering after every insert, capping tree-native
> edits at O(n). See PERF-PLAN Stage 4 (gap-based stable positions) —
> Phase I (Stage 5) depends on it.

**Goal**: Replace flatten-walk-rebuild with direct tree operations.

**What Gold had**: All edits were O(log n) tree operations.
Insert/delete operate on the tree directly, no flattening.

**What we do now**: Flatten to Vec, walk, rebuild. O(n) per edit.

**Phase I delivers**:

1. **Character-to-entry mapping** -- walk only the touched entries
   to map character delta positions to entry positions
   - O(k) where k = entries in the edited region
   - Not O(n) for all entries

2. **Tree-native insert/delete**
   - For each deleted entry: `orgl.without(pos)` -- O(log n)
   - For each inserted entry: `orgl.with(pos, carrier)` -- O(log n)
   - For splits: `without` + two `with` calls

3. **Tumbler position management** (requires Phase F)
   - Insertions create new tumbler positions (e.g., 3.1 between 3 and 4)
   - No renumbering of existing positions
   - No Dsp chains needed

4. **Batch fallback for large edits**
   - Detect when delta touches > threshold entries (e.g., > 20% of doc)
   - Fall back to batch `from_bulk_entries` for efficiency
   - Best of both worlds: O(log n) for small edits, O(n) for large

**Estimated effort**: 3-5 days (after Phase F)

**Depends on**: Phase F (tumbler positions for O(1) insertions)

### Phase J: Overlapping-Domain Combine

**Goal**: Enable `OrglRoot::combine()` for overlapping domains,
unlocking structural merge.

**What Gold had**: Combine worked for any two enfilades, including
overlapping positions (with conflict resolution).

**What we do now**: Combine fails for overlapping domains ("not yet
supported"). The merge assembles from a flattened Vec instead.

**Phase J delivers**:

1. **LWW combine** -- when two enfilades overlap, combine with
   last-writer-wins resolution at each position
   - Uses crums to identify matching subtrees
   - Only overlapping regions need conflict resolution

2. **Structural merge via combine** -- replace `assemble_merge_lww`
   with `combine` + `copy` operations
   - Unchanged regions: `orgl.copy(region)` -- shares subtree
   - Changed regions: build small replacement subtree
   - Combine all pieces structurally

**Estimated effort**: 2-3 days

**Depends on**: Phase G (splay for region isolation), Phase I (tree-native ops)

## Modern Features Beyond Gold

These features have no Gold equivalent but are essential for Xudanu:

### CRDT Convergence
The three-way merge with LWW conflict resolution provides CRDT
convergence. Gold was single-user only.

### Cryptographic Provenance
Ed25519-signed span provenance with tamper-evident attribution log.
Gold had unsigned revision history.

### Federation
Cross-server content sharing with TOFU trust, Ed25519 signature
verification, key rotation, attack detection. Gold had no networking.

### Collaborative Editing
Real-time multi-user editing via WebSocket with O-tree CRDT.
Gold was offline single-user.

### Transcopyright
Per-work license metadata with transclusion compliance badges.
Gold predated modern licensing concerns.

## Priority Order

```
Phase F (Tumbler Layer)     ████████████░░░░  FOUNDATION (3-4d)
Phase G (Splay Activation)  ████████░░░░░░░░  LOCALITY (2-3d)
Phase I (O(log n) Edits)    ██████████████░░  PERFORMANCE (3-5d)
Phase H (Compound Docs)     ████████████████  XANADU VISION (4-5d)
Phase J (Overlap Combine)   ██████████░░░░░░  STRUCTURAL MERGE (2-3d)
```

**Recommended next step**: Phase F (Tumbler Position Layer).

This is the foundation that unlocks everything else:
- Phase I needs tumblers for O(1) insertions
- Phase G needs section-level splay targets
- Phase H needs cross-document addressing
- Phase J needs tumbler positions for overlap resolution

## Relationship to Original Xanadu Concepts

| Xanadu concept | Our implementation | Status |
|---|---|---|
| Enfilade (Loaf/Split/Dsp) | `orgl.rs` (1595 lines) | Ported, active |
| Crum / OC (subtree hash) | `compute_crum()` BLAKE3 | Active, 24 tests |
| Tumbler (hierarchical address) | `XudanuTumbler` + `Sequence` | Bridged |
| Splay (locality restructuring) | `splay()` 140 lines | Tested, dormant |
| CrossSpace (multi-space) | `space/cross.rs` 413 lines | Dormant |
| Arrangement (space mapping) | `space/arrangement.rs` 115 lines | Dormant |
| Transclusion | `RangeElement::Transclusion` | Active |
| Compound document | CrossSpace enfilade | Planned (Phase H) |
| Backlinks | `HyperLink` bidirectional | Active |
| Docuverse (federated) | Cross-server refs + trust | Active |

## Completed Work Log

| Date | Commit | Phase | Description |
|---|---|---|---|
| 2025-08-11 | `47404c7` | EM-1 | Eliminate text flattening from hot paths |
| 2025-08-11 | `6c66d4b` | EM-2 | Provenance preservation through merges |
| 2025-08-11 | `f289ad2` | EM-3 | Span provenance migration through deltas |
| 2025-08-11 | `e62cc7f` | EM-4 | Provenance lifecycle verification tests |
| 2025-08-11 | `f12b850` | EM-5 | Property tests + merge fuzzing |
| 2025-08-11 | `1ff205b` | P0 | Subtree crums (Merkle hashing) |
| 2025-08-11 | `2892265` | P0 | Expanded crum test coverage (24 tests) |
| 2025-08-11 | `9d819f1` | P1 | Inline coalesce during delta application |
| 2025-08-11 | `945f01a` | A | Crum fast-path for three-way diff |
| 2025-08-11 | `8d79f4c` | B | Crum-based alignment skip |
| 2025-08-11 | `202856e` | C | Skip merge assembly for single-sided edits |
| 2025-08-11 | `b730ee4` | D | Tumbler enhancements + Sequence bridge |
| 2025-08-11 | `ff16f50` | D | Typed tumbler accessors on CrossServerRef |
| 2025-08-11 | `16fd000` | E | Eliminate Vec clone in delta hot path |
| 2025-08-11 | `b6bac71` | fix | Attribution spans use provenance display name |
| 2025-08-11 | `9163469` | fix | Backlink notification non-blocking |
| 2025-08-11 | `04b4ae8` | fix | Blob hash u64->String migration |
| 2026-08-16 | `bf67abc` | docs | PERF-PLAN: staged Gold-performance pipeline |
| 2026-08-16 | `0f79c8b` | S0 | Instrumentation + benchmark harness (measured baselines) |
| 2026-08-16 | `8135474` | S1 | Sliced non-blocking checkpoint prepare (#90) |
| 2026-08-16 | `f71e98a` | S2 | Per-node crum/domain caches; MAX_LEAF_SIZE 16384->1024 |
| 2026-08-16 | `29e7743` | S6 | Linear merge mapping (cursor match + from_parts) |
