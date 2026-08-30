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
