# FR-146 — The '72 completeness matrix: can the classic posture model all state?

> **Status:** Proposed (2026-10-10). Follows FR-145 (Ted-fidelity gaps,
> now complete). Related: FR-144 (the classic client).

## Motivation

The classic client now implements the core of the '72 idiom — parallel
pages, underlines, beams, identity boxes, beam-as-object. The open
question this FR names: **can the parallel-pages posture express every
dimension the data model holds, or does some state structurally require
the workspace shell?** The answer determines whether "classic-first" is
a full client or a reading view with a hidden ceiling.

## The matrix

The classic client draws from **three decades of Nelson's visual
vocabulary**, not just the 1972 figure. The era column below
attributes each idiom honestly:

- **'72** — *As We Will Think*: parallel pages, visible connections
- **'80** — *Literary Machines*: transclusion, the boxed-passage diagram
- **Ours** — cryptographic provenance, CRDT, the wire contract

| Model state | Idiom | Era | Status |
|---|---|---|---|
| Documents & text | parallel pages | '72 | done |
| Typed two-way links | colored underlines + beams | '72 | done |
| Whole-work ends | beam to page head | '72 | done |
| Trails | sidebar | '72 | done |
| **Editing (CRDT path)** | in-place revision, column jumps | **ours** | done |
| Link origin from any column | per-column connect button | **ours** | done |
| Gathered ends | same-color marks, i-of-N ordinals | **'80** | done |
| Transclusion identity | boxes with source tabs, resolved text | **'80** | done |
| **Per-span provenance (the lens)** | hover marginalia: author + validity | **ours** | done |
| Multi-ends beyond visible columns | inspector enumerates all ends | **'72** | done |
| Versions / time (the page-stack) | ghost edges + step-back scrubber | **ours** | done (MVP) |
| Link-about-link (the bead) | annotation marks on the beam line | **'80** | done |

The '72 posture is the *frame* — parallel pages, visible connections,
the reading stance. Within that frame, idioms from all three eras
coexist: the '72 beams, the '80 identity boxes, and our own
provenance lens. The frame is '72; the vocabulary spans the full
Xanadu arc.

## Design directions for the open cells

- **Arity beyond the row:** the connection inspector enumerates all
  ends (title + chip per end, click opens in the next free column).
  Optionally a scrollable page row beyond three columns.
- **Time:** a '72-native versioning idiom — the leading sketch is a
  *stack of pages*, slightly offset, connections threading through the
  stack; a scrubber steps the whole row backward through revisions.
  What Nelson would have drawn for "the same page, earlier."
- **Provenance:** a lens, not a panel — hover or focus reveals
  authorship chains per passage as marginalia; the resting page stays
  clean. Density is the enemy; disclosure on demand is the idiom.
- **Link-about-link:** a bead on the beam — annotations of a
  connection render as a mark on the line itself, clickable to the
  annotation passage. Room 5 made flesh.

## Non-goals

- Replacing the workspace shell for authoring-heavy flows (provenance
  inspection, gathers at scale, admin) — classic aims for *sufficiency
  in the reading posture*, not parity in every panel.

- **Redesigning the posture for work-density.** The '72 figure and
  Pyxi show a reading posture: a few pages, visible connections,
  the eye moving between them. Limitations of that posture — too
  few visible documents, column-chain navigation, no visited-state
  — are properties of the reading posture itself, not defects to
  design around. For actual work, the workspace exists; the
  two-postures split is the design. Classic is the invitation;
  the workspace is the desk.

## Acceptance sketch

- Every state a work can hold is either visible in classic or
  reachable through an inspector with one click — no dimension
  requires switching to the workspace.
- The matrix table above, kept current, is the checklist.
