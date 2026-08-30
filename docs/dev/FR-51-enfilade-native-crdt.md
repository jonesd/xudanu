# FR-51: Enfilade-Native CRDT Substrate

Status: draft (research/exploration) · Date: 2026-08-30
Builds on: FR-34 (enfilade-native: crums, chunk diff, tumbler↔Sequence
bridge, DocumentArrangement), FR-48 (tumbler alignment, deferred
hybrid-vs-native decision), FR-50 (the audit that localized every
performance finding to the CRDT↔enfilade seams), findings 1–7.

## Why

FR-50's audit produced a structural result: **every measured defect
lives at the seam between our CRDT layer and the Gold-inherited
document model** — span migration over char offsets (findings 1, 5),
edition materialization per op (finding 4), content-fingerprint
reconciliation where structure already knew the answer (findings 6,
7). Each was patched by re-importing a Gold invariant — locality,
memoized identity, index-don't-scan. The patches work; the pattern
says the seam itself is the recurring cost.

Meanwhile FR-48 already contains the unresolved fork: hybrid (CRDT +
stable tumbler views) vs native (tumbler-addressed storage). FR-48
scoped the *addressing* question. This FR scopes the deeper one:
**can the enfilade's write-once substrate BE the replication layer?**

## The thesis

Write-once, content-addressed I-space is convergent **by
construction**: concurrent writers mint new tumblers; nobody
overwrites; replicas synchronize by exchanging crum diffs (O(changes),
already implemented in FR-34's subtree crums). No three-way merge
exists to garble (finding 6's class dies structurally), no position
migration exists to go quadratic (finding 5's class dies), no
materialization churn per op (finding 4's class dies). Gold's
single-writer world never needed these guarantees; the claim to test
is that its data model provides them to a multi-writer world nearly
free.

The hard problem is not convergence — it is the **view**. Users
experience a mutable document. Under write-once, "the document" is a
projection over the address space: a set of live tumblers plus
tombstones, with an ordering. Concurrent edits then require a
view-reconciliation rule — a lattice over tumbler sets (add-wins /
remove-wins with per-author precedence) is the leading candidate.
The Sequence algebra (space/sequence.rs, currently dormant, bridged
in FR-34) is the natural language for expressing that rule.

## Questions this FR must answer (research phase)

1. **View lattice.** What reconciliation rule over tumbler
   sets/tombstones yields the interactive behavior users expect —
   including our existing guarantees (attribution per span, link
   survival, transclusion liveness)? Does per-author precedence
   reproduce today's CRDT outcomes for the cases users have seen?
2. **Edit cost under write-once.** A keystroke mints a tumbler; a
   backspace tombstones one. Retyping a paragraph churns addresses.
   What is the steady-state garbage rate, and does crum-diff sync
   remain O(changes) under churn? (Bench: keystroke, delete-run,
   paste, undo.)
3. **The projection API.** Can `DocumentArrangement` (position ↔
   tumbler, both directions) carry the full consumer API — including
   span anchoring for links/annotations/transclusions — such that
   external records store tumblers instead of char offsets? This is
   FR-48's bridge, now load-bearing.
4. **Coexistence.** Can the O-tree CRDT and the tumbler substrate
   run side-by-side per work (migration per document, not per
   server), the way compound documents moved to inline transclusions?
5. **Federation dividend.** Crum-diff sync vs delta replay for
   cross-server replication — does the substrate collapse FR-3's
   sync problem to chunk-diff exchange?

## Phase 0 execution plan (2026-08-30)

Three sessions, each with a committed artifact. The audit map is the
question set — every Gold file is read asking "what answers finding
N?" Nothing is read for heritage; everything is read for mechanism.

### Session A — read the Gold source with the findings as questions

| Gold piece (in-tree) | Read asking | Findings it should answer |
|---|---|---|
| `original-code/xanadugold/src/server/z` (the kernel) | How are node crums maintained bottom-up? How are tumblers allocated and widened on insert? | 1, 4 (locality; edit cost) |
| `wrapperx.hxx` (`iDSpace` at :313, wrapper layer) | What exactly is the V-to-I mapping (poomfilade)? What does it cost to route a position to I-space? | The whole migration family (1, 5, 8, 8b) |
| `src/image/st.dir/*.st` (`SequenceRegion`, `XuRealPos`, `XuReal`, `BeforeReal`, `IEEE32Pos`) | What is the Real/Sequence duality — the position/tumbler split — as the original frontend used it? | Lattice ordering; sequence.rs activation |
| `urdit.cxx/hxx` | Backend entity/disk model: how are immutable units stored and addressed? | Element granularity; tombstone storage |

Artifact: **mechanism-transfer table** — Gold mechanism ↔ our finding
↔ what adopting it means ↔ cost. One row per answer found; blanks are
findings Gold does NOT answer (those stay ours).

### Session A results (2026-08-30, first pass — the z "file" is a
concatenated index; the kernel is the server/*.cxx collection)

**Mechanism-transfer table (opening rows):**

| Gold mechanism | Citation | Answers | What it means for us |
|---|---|---|---|
| **IDSpace: distributed unique ID minting** — `newID()` "guaranteed different from every other newID... on any Server"; `newIDs(count)` bulk form; server-scoped allocation regions (`iDsFromServer`) | `idx.hxx:555-620` | Lattice element identity (FR-51 Q1) | Concurrent writers on different servers **cannot collide** — uniqueness without vector clocks, by space/counter allocation. Our server_id-prefixed tumblers already mirror this shape |
| **ID : Position** — the immutable unit IS an address in a coordinate space | `idx.hxx:114` | Write-once addressing is real, not aspirational | Elements are positions; ordering comes from the space, not from a list |
| **SequenceRegion: prefix regions** — "unions of intervals... or a match with all sequences **prefixed by some sequence up to some index**" | `st.dir/SequenceRegion.st` (category 'Xanadu-tumbler') | Lattice ordering (FR-51 Q2); the migration family | The hierarchical-prefix property IS the widening arithmetic. Our `xn_region.rs` is the port of the underlying XnRegion; `space/sequence.rs` is the Sequence algebra sitting dormant |
| **Per-element triple crums, bottom-up** — every range element carries bert/sensor/history crums; `updateBCrumTo`; observer-parents chain upward; identity = `contentsHash ^ hCrum ^ sensorCrum ^ owner` | `z:102-121` (BeRangeElement), `brange1x.hxx` | Finding 9 (view-independent identity) | The crum-based transclusion identity we planned is literally Gold's element-identity pattern. The working StructuralTransclusion variant already matches it |
| **Authority as ID regions** — `actualAuthority() → IDRegion`, `hasAuthority(ID)`, `incorporate(other)` | `nkernelx.hxx:357-420` | Federation/permissions join semantics | Authority merge is already region-join shaped in Gold — the lattice pattern appears here too, for permissions |
| **`again()` — re-fetch protocol** | `nkernelx.hxx:488` | Our AgainHop (transclusion re-resolution) | Our again-hop machinery is the direct descendant; interop vocabulary confirmed |

**Blanks (Gold does NOT answer — stays ours):**
- The reconciliation rule for concurrent edits (single-writer design)
- Churn economics under interactive retyping
- Causal-context bookkeeping ("delete of unseen insert")

**Initial confidence: HIGH for the substrate direction.** The three
load-bearing mechanisms — unique minting, immutable positioning,
prefix region algebra — all verified present with citations, plus the
crum-identity pattern for finding 9's unification. The genuinely new
work is confirmed to be exactly where FR-51 said it was: the lattice
rule and churn economics. Nothing found so far closes the FR.

### Session B — inventory our own pieces (what's already built)

| Piece | State | Role in the substrate |
|---|---|---|
| `space/sequence.rs` (1248 lines) | dormant; FR-34 bridged to/from tumblers | Candidate native ordering for the lattice |
| `edition/tumbler.rs` (`XudanuTumbler`, `DocumentArrangement`) | live, position↔tumbler both ways | The projection API consumers keep |
| FR-34 subtree crums + chunk diff | live, tested | Unit identity and O(diff) sync |
| `edition.rs` entries cache (entries/starts/fingerprints/flag) | live, armor-locked | The consumer-side view machinery |
| `element_insert`/resolution (finding 9) | live, view-consistent pin fix pending | Transclusion identity unification point (crum-based) |
| O-tree CRDT + bench op streams | live; bench records edit patterns | **The acceptance oracle**: record real op streams, replay through the lattice |

Artifact: **readiness matrix** — ready / adaptable / missing, per
substrate component. The missing column is Phase 1's worklist.

### Session B results (2026-08-30)

**Readiness matrix:**

| Component | State | Citation | Role in substrate |
|---|---|---|---|
| **Sequence algebra** | READY — complete & tested: `compare_to` (total order), `compare_prefix` (widening), `SequenceRegion.prefixed_by` (prefix regions — Gold's st.dir property), `SequenceDsp` (displacements), `from_dotted` (wire format) | `space/sequence.rs` (1,248 lines) | **Native lattice ordering** — the Session C hypothesis has its engine |
| **Tumbler bridge** | READY — lossless both ways; `DocumentArrangement.to_tumbler(position)` / `from_tumbler` bidirectional | `edition/tumbler.rs:253-262, 325-360` | The projection API consumers keep |
| **Gap-allocated stable positions** | LIVE — `DEFAULT_SPACING = 1<<16`, `allocate_between(prev,next)` — the O-tree fast path already inserts into gaps without renumbering | `space/position_allocator.rs:24-111` | **The interpolation point**: flat gap addresses and hierarchical tumblers are the same design family; concurrent neighbors allocate distinct addresses |
| **Edition crums** | READY | `edition.rs:879` (`orgl.crum()`), FR-34 | Unit identity; finding-9 unification |
| **Entries cache** | READY, armor-locked (this week) | `edition.rs` build_entries_cache | Consumer-side view |
| **apply_edits tree path** | EXISTS with the code's own signpost: *"When tumbler positions arrive (Phase I), the renumbering step is eliminated, making this O(k log n)"* | `edition.rs:884-901` | The edit-substrate hook — FR-34's roadmap already pointed here |
| **Full coordinate-space framework** | PRESENT — `real.rs` (RealSpace), `sequence.rs`, `arrangement.rs`, `cross.rs`/`cross_n.rs` (cross products), `filter.rs`, `order.rs`, `mapping.rs` — the port of Gold's CoordinateSpace hierarchy; the Real/Sequence duality from st.dir lives here | `space/` module | The algebra vocabulary already imported |
| **Op-stream recorder/replayer** | MISSING — bench emits fixed patterns only | — | Acceptance oracle: record real streams, replay through lattice |
| **Live-set + tombstone store** | MISSING | — | The substrate's state |
| **Causal contexts (dotted vv)** | MISSING | — | "Delete of unseen insert" bookkeeping |

**Confidence update: the substrate is more assembled than designed.**
The Sequence algebra, the bridge, the allocator, and the crums are
not prototypes — they are tested code, some of it load-bearing in
production paths today. And `edition.rs:884`'s own comment shows the
codebase was already pointed at tumbler positions as its next step.
The missing column is exactly three items: the store, the contexts,
and the recorder. Session C's ordering hypothesis strengthens
correspondingly: `Sequence.compare_to` gives the total order,
`prefixed_by` gives regions, gap allocation gives concurrent-neighbor
minting — native ordering without RGA anchors looks plausible.

### Session C — the lattice design note

Decisions to make, in order (A+B feed each):

1. **Element granularity** — per-character tumblers vs span-units.
   Gold's z answers this for storage; our edit patterns (bench
   streams) answer it for interactivity.
2. **Ordering rule** — neighbor-anchoring (RGA-style) vs Sequence
   algebra as native fractional order. If sequence.rs gives
   deterministic order for concurrent inserts *without* extra
   bookkeeping, that is the largest single simplification available.
3. **Add/remove semantics** — tombstone-wins for text (matches
   O-tree today); causal context via dotted version vectors; the
   "delete of unseen insert" rule must be explicit.
4. **Acceptance protocol** — the gate: recorded O-tree op streams
   replayed through the lattice; rendered outcomes compared; every
   divergence is either a lattice fix or a documented acceptable
   difference. The FR-50 armor tests (six, growing) are the behavior
   spec.
5. **Edit-cost model under churn** — retype = mint+tombstone storms;
   estimate address-space growth and GC story BEFORE building. Gold
   never had interactive churn; this pressure is new and ours.

Artifact: **the design note with verdict** — proceed to Phase 1, or
close FR-51 with the recorded reason. Either outcome commits.

### Standing rules (from the audit, now binding here)

- Read Gold source before analysis of it (FR-48 checklist rule).
- Every claim in the transfer table carries a file:line citation.
- The acceptance oracle is op streams from the LIVE system, never
  synthetic happy paths.
- Nothing is rewritten during Phase 0 — reading, tables, and one
  design note. Code stays on the finding-9 fix and the audit queue.

## Phasing (decision gates, not commitments)

- **Phase 0 — research (1–2 sessions):** answer questions 1–3 on
  paper + spike benches against the existing enfilade; produce the
  view-lattice design note. Gate: if no lattice reproduces CRDT
  acceptable behavior, close this FR and FR-48 goes hybrid.
- **Phase 1 — storage substrate:** tumbler-set + tombstone store with
  crum roots per work; read-only projection renders a document
  (consume via DocumentArrangement). No editor.
- **Phase 2 — single-writer edits through tumblers:** edit ops mint/
  tombstone; measure against the FR-50 matrix (keystroke curve must
  be flat, not merely better).
- **Phase 3 — multi-writer views:** the lattice; concurrent sessions
  on one document; behavioral armor comparing outcomes against the
  O-tree CRDT for the same op streams (today's six armor tests are
  the template).
- **Phase 4 — migration:** per-work dual-write, then cutover; the
  compound-inline migration is the precedent.

## Non-goals

- No change to the O-tree CRDT's role before Phase 3 proves the
  lattice — the CRDT remains the live system throughout.
- No wire-protocol redesign; XCP compatibility is a constraint.

## Success criteria

- Phase 0 either closes this FR with a recorded verdict, or produces
  a lattice design that reproduces CRDT outcomes on the recorded op
  streams.
- If it proceeds: the FR-50 matrix run on the substrate shows
  keystroke/link-edit curves flat at every N, and finding-classes
  1/4/5/6 structurally impossible (no migration code exists to
  regress).

## Standing note

This FR is the formal version of the pattern FR-50 kept finding:
Gold's design made our bug classes impossible; we re-imported its
invariants as patches. The question is whether the last patch is
behind us — or whether the substrate is one bridge away.
