# FR-59: Provenance-Based Revision Compare

- **ID:** FR-59
- **Status:** Proposed — spec complete, not scheduled. Natural
  follow-on to the compare-clarity work (the "aligned diff" tier
  shipped as the labeled fallback; this FR is the xanalogical
  primary).
- **Depends on:** FR-37 (edition crums — already used by
  `find_shared_regions`), FR-23 (revision metadata), FR-34
  (recorders/fossils — deleted-content identity), span provenance
  (already stamped by `revise_work`)
- **Does not depend on:** FR-51/FR-57 (lattice state is not
  required; editions are the persistent truth)

## 1. Why this FR exists

"Compare two versions of the same work" is the diff-tool use case —
and the system already knows the answer structurally. Every
revision's edition is persisted (`work_ref.history` chunk refs),
every changed span carries cryptographic provenance
(`edition.span_provenance`, the chained attribution log), and
edition crums identify shared subtrees by hash, not by text
scanning. Alignment algorithms (the Myers fallback) are for text
with *no* relationship to the system; revisions have nothing but
relationship. Diffing them by alignment throws away everything
Xudanu knows and re-derives it approximately.

The payoff beyond correctness: **diff hunks that carry
attribution**. "This passage was inserted in revision 5 by Alice,
signed, at 14:02" — a diff where every hunk is a claim with an
author. No diff tool has that; Xudanu has it in the data model
already.

## 2. The query

```
revision_compare(work_id, rev_a, rev_b)   // rev_a < rev_b
  → inserted: [(start, end, text, author_club, timestamp)]
    deleted:  [(start_in_a, end_in_a, text, author_club, timestamp)]
    unchanged_ratio: f32
    source: "crum" | "fingerprint" | "alignment-fallback"
```

**Tier 1 — crum diff (primary):** `edition@revA.crum_diff(&edition@revB)`
— the FR-37 structural match already powering `find_shared_regions`
(server.rs:16434), pointed at two revisions of one work instead of
two works. Matched subtrees = unchanged; divergent subtrees = the
hunks. O(depth × divergences), exact, no text scanning.

**Tier 2 — provenance decoration:** for each divergent span, resolve
author + timestamp from span provenance and the attribution log
(revision sequence already recorded per entry). This is display
data riding existing records — no new bookkeeping.

**Tier 3 — fossil recovery (optional, FR-34):** deleted spans whose
content is needed for display can be recovered from recorder
fossils; the edition text at revA already suffices for v1.

**Fallback:** revisions whose editions were compacted out of
history (if history caps apply) degrade to fingerprint matching,
then to the Myers alignment tier — always labeled with `source`
so the UI never presents a fallback as structural truth.

## 3. UI

- History panel gains "compare" affordance: pick two revisions →
  side-by-side rendering reusing the compare components.
- Left = revA (deletions washed red, attribution chip per hunk),
  right = revB (insertions green, same chips). Unchanged runs
  collapse with the existing `⋯ N matched words ⋯` markers.
- Chip content: author display name (historical-authors registry),
  revision number, timestamp; click → the provenance panel for the
  full chain.
- The verdict banner style carries over: "revision 3 → 7: 4% of
  characters changed across 3 hunks · 2 authors".

## 4. Stories

| # | Story | Notes |
|---|---|---|
| S1 | `revision_compare` server op + wire code | crum_diff between historical editions; provenance join |
| S2 | Armor: scripted edit sequence → exact hunks | insert/delete/move patterns vs known ground truth |
| S3 | History panel two-revision picker | works with ≥2 revisions |
| S4 | Side-by-side rendering with attribution chips | reuses compare components |
| S5 | Fallback chain + `source` labeling | compacted history degrades visibly |

## 5. Acceptance criteria

- Hunks are exact for revisions with stored editions — a scripted
  sequence of edits produces precisely those edits as hunks, with
  correct author and revision attribution per hunk.
- No alignment algorithm runs when both editions exist (`source`
  never reports the fallback in that case).
- Response computes in O(divergences), not O(text) — a large work
  with one changed paragraph compares in milliseconds.
- The UI renders every hunk with its author chip; clicking a chip
  opens provenance for that span.

## 6. Non-goals

- No three-way merge UI (endorsements/three_way.rs is a separate
  concern).
- No cross-work comparison changes — this FR is strictly
  revisions-of-one-work; the works-pair compare keeps its layering
  (transclusion/crum → alignment fallback).
- No new persistence: existing history chunk refs and the
  attribution log are the source of truth.

## 7. Relationship to other FRs

| FR | Relationship |
|---|---|
| FR-37 | crum_diff is the engine; this FR is its most natural consumer |
| FR-23 | RevisionMeta provides the picker list; attribution log provides decoration |
| FR-34 | Fossils recover deleted-span display text (optional tier) |
| FR-51 | Post-cutover, lattice dots make the in-memory query O(log n) — but editions remain the persistent truth, so this FR does not gate on the lattice |
| FR-58 | None (suggestions are read-path reuse, not revision history) |

## 8. The principle

Layered identity, best-first: declared (transclusion) → hashed
(crums) → recorded (provenance) → inferred (alignment, labeled as
such). Every tier exists somewhere in the codebase today except
the query that ties revisions together — which is what this FR
adds.
