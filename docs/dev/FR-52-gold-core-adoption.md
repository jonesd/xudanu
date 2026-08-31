# FR-52: Gold Core Adoption — completing the Gold functionality inclusion

> **Status:** Planning (breakdown complete, sequencing ready)
> **Created:** 2026-08-31
> **Principle:** Adopt remaining Gold functionality unless it causes
> issues. Where a piece fights the current architecture, armor-first
> integration proves equivalence before adoption; honest rejection
> with rationale otherwise. Every step lands documented.

## Goal

Xudanu has matched Gold's complexity classes on shared operations
(FR-34: perf pipeline, crums, recorders, sync, notarization). This
FR completes the map: every Gold concept that is dormant or missing
in Xudanu gets an explicit decision — adopt, adapt, or reject with
rationale. The outcome is a **capability parity table** where every
Gold row says what Xudanu does and why.

## Inventory: what exists but is dormant vs. missing entirely

| Gold concept | Xudanu state | Location | Tests | Decision |
|---|---|---|---|---|
| Ent/Fulltrace (entity hierarchy) | **Dormant** — 4,422 lines, 68 dagwood + 64 content tests green | `src/ent/` | 479 module tests green | **A-1** |
| DagWood (versioned trace DAG) | **Dormant** — used inside backfollow only for trace positions | `src/ent/dagwood.rs` | 68 tests | **A-1** |
| Htree/HUpperCrum (crum tree) | **Dormant** — HPart trait, parents, partial crums | `src/ent/htree.rs` | 13 tests | **A-1** |
| Stubble/Wrappers (type system) | **Partial** — wrapper.rs has endorsement tokens; links consume them; notarize.rs builds on this lineage | `src/edition/wrapper.rs`, `links.rs` | 23 wrapper tests | **A-2** |
| Canopy (crum propagation tree) | **Dormant** — 1,092 lines; bert/sensor crums, flags, PropFinder used in backfollow | `src/edition/canopy.rs` | 32 tests | **A-3** |
| Props (permissions algebra) | **Dormant** — BertProp, flags, permissions_flags computed in backfollow | `src/edition/props.rs` | 30 tests | **A-3** |
| Hoist (recorder promotion) | **Dormant** — promotes crums up the tree | `src/edition/hoist.rs` | 20 tests | **A-3** |
| CrossSpace2 (product spaces) | **Dormant** — full Space impl, cross_n extension | `src/space/cross.rs`, `cross_n.rs` | 14 + phase3 tests | **A-4** |
| Arrangement (space mapping) | **Dormant** — index<->position mapping | `src/space/arrangement.rs` | 8 tests | **A-4** |
| FilterSpace (stepper filters) | **Dormant** — FilterRegion used in transclusion.rs | `src/space/filter.rs` | 20 tests | **A-4** |
| RealSpace (real-valued positions) | **Dormant** — used in phase3 tests | `src/space/real.rs` | 29 tests | **A-5** |
| Sequence as native ordering | **Active on lattice** — lattice uses Sequence directly | `src/space/sequence.rs` | in lattice tests | **Done** |
| GrandMap (ID allocation) | **Dormant** — 324 lines | `src/edition/grandmap.rs` | 12 tests | **A-5** |
| Pool (object pooling) | **Dormant** — 219 lines | `src/edition/pool.rs` | 13 tests | **A-5** |
| Label system | **Active** — used in edition construction | `src/edition/label.rs` | 52 tests | **Done** |
| Snarf (fixed storage segments) | **Active** — persist layer uses SnarfStore | `src/persist/snarf.rs` | packer tests | **Done** |
| Widdershin update | **Missing** — Gold's bottom-up recompute protocol | — | — | **A-6** |
| Fullsm (complete enfilade ops) | **Missing** — Gold's full ops set on orgls | — | — | **A-6** |
| Istm (frontend tree mgmt) | **N/A** — we have a web frontend, not Gold's frontend tree | — | — | **Reject** |

## Breakdown

### A-1: Ent/Fulltrace activation (largest single adoption)

Gold's document store was an **Ent** — a hierarchical namespace of
works, versions, and links managed through the fulltrace DagWood.
Xudanu currently uses DagWood only for trace-position allocation in
backfollow (crum metadata registration). The other 4,300 lines —
branch, content, htree — are tested but unwired.

**What activation delivers:**
- Htree as a second crum-propagation tree (parallel to canopy):
  typed crums (BertCrum, SensorCrum, HistoryCrum, CanopyCrum) that
  carry semantic identity, not just content hashes. This is where
  Gold's crums were *richer* than ours — ours prove content; Gold's
  carried **permissions, history, and sensor state**.
- Content tree as a typed content hierarchy: text/set/path/hyperlink
  wrappers, IS-A relationships (the DAG in DagWood).
- The Ent as the join point: document = one position in the fulltrace,
  linked to its crum tree and content tree.

**Path to integration (not immediate):** the Ent model is
server-internal; the lattice (FR-51) is already the tumbler-native
store. Fulltrace activation means giving the **server a fulltrace** —
replacing today's flat `HashMap<BeId, WorkState>` with a hierarchical
namespace: works organized under clubs/accounts. This is architectural
and needs a design note before code. Deliverable A-1.1: design note.

**Risk:** medium — it replaces the work-lookup path. Armor-first: the
fulltrace is a super-keyed index (BeId → position), so lookup
equivalence is provable by construction if BeId remains the primary
key internally.

### A-2: Wrapper/Stubble completion

Wrapper tokens exist (TEXT/SET/PATH/HYPERLINK/HYPERREF endorsements).
Gold's stubble was richer: **type constructors** building structured
values (sets of positions, paths through documents, links with
context). Our links.rs consumes HYPERREF_TOKEN, but there is no
general value-construction mechanism.

**What activation delivers:**
- `RangeElement::Set(Vec<Position>)` and `RangeElement::Path(Vec<Position>)`
  as first-class content types — structured quoting (quote these five
  ranges as one logical quote), path citations.
- Typed endorsements: EndorsementSet as a **type signature** on
  content — FR-38's license classes become one consumer of a general
  endorsement-dispatch system.

**Path to integration:** extend RangeElement enum + wrapper tokens
into the existing endorsement machinery. Moderate; isolated.

**Risk:** low — additive to RangeElement. No existing behavior
changes.

### A-3: Canopy/Props/Hoist activation — typed crum trees

These three are one unit: **the permission-bearing crum tree**.
Gold's CanopyCrum carried flag words "widded by ORing up the
canopy" — Club/endorsement bits propagated bottom-up, so
permission queries pruned whole subtrees. FR-38's license overlay
was the first consumer of this pattern (run-length index instead
of tree — the flat-accelerator choice we made there).

**What activation delivers:**
- The canonical Gold design: per-node OR-bits on a tree parallel
  to the enfilade, maintained by fix() (hoist.py is the promotion
  mechanism: new crum → promote up through o_parents).
- The **permission query path**: "may club X read positions [a,b)?"
  answered by a single tree descent. The backfollow index already
  computes permission flags via props::permissions_flags — this
  activates the tree-based version.
- Endorsement dispatch: SensorCrum as a reactive "sensor" — content
  matching a criteria gets detected and flagged up the tree. Gold's
  sensors detected content reuse; ours has the same concept wired
  into backfollow's flag computation.

**Path to integration:** the trees are in backfollow, already
computing flags. The step is **making the canopy tree live on the
enfilade, not on the backfollow index** — Htree nodes attached to
Loaf nodes via Arc (structural sharing). FR-38's overlay is the
flat version; this upgrades to the tree version and retires the
flat one (armor: same query results).

**Risk:** low-medium — the tree version already passes 32 tests;
integration point is "attach to Loaf" which touches orgl.rs
construction paths (S2's territory — but S2's machinery is proven
stable).

### A-4: CrossSpace2/Arrangement/FilterSpace activation

CrossSpace2 is complete: full `Space` impl over (A×B) with cross
regions and Dsps. Phase H (compound documents) was the original
consumer. The lattice is now the tumbler-native store; a CrossSpace
over (lattice × lattice) gives compound documents a native position
type: `Tuple2(Sequence, Sequence)` — this is exactly what Gold used
for compound docs.

**What activation delivers:**
- Compound documents as lattice editions over CrossSpace2 — spans
  from multiple works unified under one position space.
- The Arrangement: mapping i64 char positions to cross-space
  positions for transclusion management (the original Phase 3 goal).
- FilterSpace for filtered steppers over compound structure.

**Path to integration:** FR-37 Phase 4 (derived documents) is the
current consumer path — a derived work IS a compound of pinned
spans. The next compound iteration should use CrossSpace2(lattice,
lattice) as its backing positions. This requires FR-51 cutover
first (the lattice must be primary before compound editions use
cross-space lattice positions).

**Risk:** low — the algebra is complete and tested; the risk is
compound-document UX (the existing frontend has compound panels;
adding cross-space positions is an edition-level change).

### A-5: GrandMap/Pool/RealSpace — infrastructure adoption

- **GrandMap** (12 tests): Gold's global ID allocator with club-based
  partitioning. Xudanu's ID allocation is flat u64 counters on
  Server. GrandMap activation is a drop-in upgrade: ID allocation
  becomes hierarchical (club-scoped ranges, namespace isolation).
  **Low risk, low urgency** — the flat allocator works.
- **Pool** (13 tests): object pooling for allocation-heavy paths.
  Performance-only; adopt when a profiler says allocation is hot.
- **RealSpace** (29 tests): complete but no consumer identified.
  Gold used real positions for the frontend tree. **No action**
  unless a use case emerges.

### A-6: Widdershin and Fullsm — the two Gold protocols we lack

**Widdershin** ("bottom-up, against the grain") is Gold's protocol
for updating crums after an edit: the edit site computes a new
bottom crum, then widdershins up through o_parents to the root,
updating each ancestor. This is how Gold maintained its typed crum
trees incrementally (what A-3 activates). Our per-node crum
maintenance in `fix()` and `split_from` already does this for
content crums — widdershin for **typed** crums (canopy crums) is
the A-3 deliverable.

**Fullsm** (full structure manager): the complete set of enfilade
operations Gold ran (retrieve, store, copy, combine, regrid).
Xudanu has retrieve/fetch, store/with, copy — but not regrid
(tree rebalancing without content change) and not the full
operations manager that coordinated them. With S2 per-node crums
and Arc sharing, we have most of what fullsm coordinated — but
not regrid.

**Deliverable A-6.1:** implement regrid (rebalance enfilade by
tumbler partition boundaries — partitions sections into subtrees).
This is the splay concept done Gold's way. Deliverable A-6.2:
operations inventory vs. Gold's fullsm — any gap gets a decision.

### Rejected: Istm (frontend tree management)

Gold's Istm managed the frontend document tree (retrieval cache,
front-end state). We have a React SPA; an Istm would be building
Gold's frontend inside ours. **Reject** — the frontend already
serves this role.

## Sequencing

```
A-2 (Wrapper/Set/Path types)     LOW RISK — additive, do first
A-3 (Canopy tree on enfilade)    LOW-MED — replaces FR-38 flat overlay
A-1 (Fulltrace activation)       MED — design note first
A-6 (Widdershin for typed crums) follows A-3 naturally
A-4 (CrossSpace compound docs)   after FR-51 cutover
A-5 (GrandMap, Pool)             when needed, low priority
```

Each adoption lands with:
- An armor suite proving behavioral equivalence where it replaces
  an existing path (A-3 replaces the flat overlay)
- A work-log row in FR-34's activation table
- Honest rejection notes where Gold's approach fights ours

## Success Criteria

Every row in the inventory table above reads **Done**, **Rejected
(with rationale)**, or has a linked FR with a live plan. No row
says "dormant" at FR close.

## Relationship to Prior Work

| FR | Relationship |
|---|---|
| FR-34 | This is FR-34's successor — the activation column completed |
| FR-38 | A-3 upgrades FR-38's flat overlay to the tree version |
| FR-51 | A-4 (CrossSpace compounds) depends on lattice cutover |
| FR-37 | A-2 enriches the derived-document / quotation types |
| GOLD-VS-XUDANU.md | Updated at FR close with the parity verdict |
