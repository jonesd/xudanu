# FR-145 — Ted-fidelity gaps: many columns, transclusion identity, the beam as an object

> **Status:** Proposed (2026-10-08). Deferred by decision: ship the
> initial classic-first release first, then close these three gaps.
> Related: FR-144 (the classic client), the release decision note in
> FR-144's amendment.

## Motivation

The classic client draws from the full Xanadu arc — the '72 posture
(parallel pages, visible connections), the '80 vocabulary
(transclusion boxes, Literary Machines), and our own contributions
(cryptographic provenance, CRDT). The posture is '72; the
vocabulary spans three decades. See FR-146 for the era-attributed
completeness matrix.

The two-column reading surface matches the 1972 *As We Will Think*
figure and Yee's Pyxi (1999):
parallel pages, many visible connections drawn at once, span-to-span
anchoring, paper/ink skins, in-view authoring. Three gaps remain
between us and the canonical images:

1. **Many columns.** The 1972 figure shows several parallel pages with
   lines criss-crossing; we are strictly two. A third (fourth…)
   column makes the "parallel literature" literal.

2. **Transclusion identity.** Nelson's transclusion diagram *boxes*
   the same passage wherever it appears — "not a copy; the same
   content." The server already transcludes live, but the classic
   view does not mark same-content passages differently from linked
   ones. This is arguably the most Xanadu visualization we lack.

3. **The beam as an object.** Connection lines cannot themselves be
   clicked, inspected, or annotated. The model supports links about
   links (the Gallery's Room 5); the view should expose it.

## Non-goals

- 3D space, whole-docuverse flight, ZigZag spatial generality
  (unchanged from FR-144).

## Sketch of acceptance

- **Columns:** "open beside" from any context menu or connection adds
  a column (to a sane cap); every connection between any two visible
  columns draws; paper and ink skins both honor it.
- **Identity:** passages that are transclusions of the same content
  carry a shared box/bracket style and a tooltip naming the source;
  visually distinct from link underlines in both skins.
- **Beam-as-object:** clicking a beam selects the connection; an
  inspector names its type, ends, and provenance; a link about that
  link can be authored from the inspector (Room 5's move).
