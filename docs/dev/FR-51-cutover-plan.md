# FR-51 Cutover Plan: Migrating from the O-Tree to the Lattice

> **Status:** design note (not scheduled — this is the roadmap for
> WHEN the cutover is pursued, not a commitment to start now)
> **Created:** 2026-09-05
> **Parent:** FR-51-enfilade-native-crdt.md (Phases 0-4.2 complete)
> **Principle:** the shadow proves correctness first; features port
> next; the switch is last and reversible.

## Where we are

The lattice runs inside the server as a dual-write shadow (P4.1/4.2):
default-off, ephemeral, enrolled per-work, mirroring production edit
traffic. It is the correctness oracle (caught F6/F10) and the
performance target (~80-150µs/op vs O-tree's flat ~50ms/op @16k
under interleaving). Both engines produce length-exact results.

The O-tree remains the live engine. It carries the full content
model: provenance, transclusion, span migration, annotations,
structural elements, crums/OwnerSets, federation.

## What the lattice lacks (the port worklist)

| # | Feature | O-tree location | Lattice gap | Effort | Phase |
|---|---|---|---|---|---|
| 1 | **Provenance** (Ed25519 per element) | `ElementProvenance` on every Carrier | Dots carry author+timestamp but not signatures, author types, source works, derived_by chains | Medium | C-1 |
| 2 | **Transclusion** (inline references) | `RangeElement::Transclusion/StructuralTransclusion/Virtual` | Lattice has no element model — pure text insert/delete | Large | C-2 |
| 3 | **Span migration** (links follow edits) | `positional_delta_mapping` + three-way merge | Lattice needs its own position mapping for link/annotation span migration | Medium | C-3 |
| 4 | **Annotations** (char ranges) | `OtreeAnnotation` on O-tree sessions | Range tracking; no annotation storage on lattice | Small | C-3 |
| 5 | **Structural elements** (blobs, sets, paths, link elements) | `RangeElement` enum variants | No element model | Medium | C-2 |
| 6 | **Crums/OwnerSet** (canopy, license queries) | Per-node on Loaf tree | Lattice nodes need equivalent aggregation | Medium | C-4 |
| 7 | **Federation** (anti-entropy, replication) | Edition-level wire payloads | Lattice wire payloads exist (lattice_wire.rs) but not integrated with federation | Small | C-4 |

## The phases

### C-0: Adjudication (precondition for everything)

**Before porting anything, every shadow-vs-O-tree divergence must be
adjudicated.** The FR-51 doc records: "divergence may be the SHADOW
being right." We need to:

- Collect divergences from the soak period (shadow vs live text)
- For each, determine which engine's answer is correct
- Document the correct semantics as the SPEC for both engines
- Fix whichever engine is wrong

**Exit criterion:** zero unadjudicated divergences; the spec says
which engine is normative for each divergence class.

**Estimated:** 1 week soak + adjudication.

### C-1: Provenance on the lattice

The lattice's dots carry `(author_id, timestamp)`. The full
provenance model carries:
- Ed25519 signature over the element fingerprint
- Author type (Human | Llm | Historical)
- Source work (for transclusions)
- Transcluded_by / derived_by chains
- Server ID

**Design:** lattice units gain an optional provenance block. Since
the lattice is a CRDT (append-only dots), provenance attaches at
dot-creation time and is immutable — simpler than the O-tree's
merge-time provenance reconstruction.

**Armor:** provenance equivalence — for every edit, the lattice's
provenance attribution matches the O-tree's (`materialize_with_
provenance` comparison).

**Estimated:** 1 week.

### C-2: Element model on the lattice

The hardest phase. The lattice needs to represent non-text elements
(transclusions, blobs, sets, paths, link elements) inline in its
unit stream.

**Design options (decide before starting):**
- **Option A: Typed units.** Lattice units carry an element type.
  Insert/delete works the same; rendering/resolution is typed.
  Simpler but pollutes the pure-text lattice.
- **Option B: Overlay layer.** Elements live in a side-table keyed
  by lattice position. The lattice stays pure text. Elements migrate
  via position mappings (C-3's mechanism).
- **Option C: Dual substrate.** The lattice for text; the enfilade
  for elements. A bridge layer coordinates positions between them.

**Recommendation:** Option B (overlay) — keeps the lattice clean,
reuses the span-migration machinery from C-3, and the O-tree's
element model serves as the reference implementation.

**Armor:** element round-trip — every RangeElement type survives a
lattice edit sequence and resolves identically to the O-tree path.

**Estimated:** 2-3 weeks.

### C-3: Span migration + annotations

Links and annotations reference char ranges. When text is inserted
or deleted, these ranges must shift (migrate) to stay attached to
the right characters.

**Design:** the lattice already produces position deltas internally
(dot-based ordering). Expose these as a `LatticeMapping` — the
lattice equivalent of the O-tree's `positional_delta_mapping`. Link
and annotation endpoints migrate through this mapping.

**Armor:** span-migration equivalence — for the same edit sequence,
links and annotations land on the same characters in both engines.

**Estimated:** 1 week.

### C-4: Crums, federation, and parity

- **Crums/OwnerSet:** per-node aggregation on the lattice's
  weight-balanced tree. The lattice already maintains crums for
  anti-entropy; extend to OwnerSets (same pattern as the enfilade).
- **Federation:** lattice wire payloads exist; integrate with the
  federation transport's anti-entropy cycle.
- **Full parity:** the FR-50 matrix on the lattice must match or
  beat the O-tree on every row.

**Estimated:** 1 week.

### C-5: The switch (per-work, reversible)

**Not a flag flip.** The cutover is per-work, gradual, and always
reversible:

1. **Enroll** a work in dual-write (existing P4 mechanism).
2. **Soak** — shadow tracks live text continuously; divergences
   logged and adjudicated.
3. **Read-switch** — reads served from the lattice; writes still
   dual. Compare read results.
4. **Write-switch** — writes go to the lattice; O-tree mirrors
   (reverse dual-write). Any anomaly → flip back.
5. **Retire** the O-tree mirror for that work.

**Rollback at every step:** drop the lattice state and resume from
the O-tree (or vice versa). No data loss; the enfilade remains the
persistence layer throughout (both engines serialize to chunks).

**Estimated:** 1 week per batch of works (roll out gradually).

## Sequencing summary

```
C-0 (adjudication)     → 1 week
C-1 (provenance)       → 1 week
C-2 (elements)         → 2-3 weeks (design decision first)
C-3 (migration)        → 1 week (after C-2)
C-4 (crums/federation) → 1 week (parallel with C-3)
C-5 (switch)           → 1 week per batch
                            ─────────
                       ~6-8 weeks total
```

## What we do NOT do

- **Do not rewrite the O-tree.** It stays as the fallback engine
  and the reference implementation throughout.
- **Do not rush C-2.** The element model design (Option A/B/C) is
  the most consequential decision — get it right.
- **Do not cutover without C-0.** Unadjudicated divergences mean
  we don't know which engine is right; switching blind risks
  shipping the wrong semantics.

## Relationship to other FRs

| FR | Relationship |
|---|---|
| FR-51 | This is FR-51's continuation — the "port and switch" that follows the shadow phases |
| FR-34 | The lattice serves crums natively (C-4 activates the full enfilade-native path) |
| FR-40 A-4 | CrossSpace2 compounds want the lattice as the primary substrate |
| FR-52 A-1 | The fulltrace is engine-agnostic (TracePositions ride on either) |
| FR-54 | Post-cutover, FR-54's span-migration bottleneck (S3) becomes the lattice's O(log n) position mapping |

## Success criteria

At cutover completion:
- All works on the lattice; O-tree retired for those works
- Provenance, transclusion, migration, annotations work identically
- The FR-50 matrix matches or beats O-tree on every row
- Rollback path exists and has been tested
- The enfilade (persistence) is unchanged — chunks, WAL, manifest
