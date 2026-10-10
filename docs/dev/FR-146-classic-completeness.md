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

| Model state | '72 idiom | Status |
|---|---|---|
| Documents & text | parallel pages | done |
| Typed two-way links | colored underlines + beams | done |
| Whole-work ends | beam to page head | done |
| Gathered ends | same-color marks, i-of-N ordinals, gather picker | done |
| Transclusion identity | boxes with source tabs, resolved text | done |
| Trails | sidebar | done |
| Editing (CRDT path) | in-place revision, column jumps | done |
| Link origin from any column | per-column connect button | done (2026-10-10) |
| **Multi-ends beyond visible columns** | no gestalt for "one connection, N ends" when ends live in unopened works | open |
| **Versions / time** | *no native time dimension in the '72 drawings* | open |
| **Per-span provenance** | author density would drown the page | open |
| **Link-about-link** | inspector exists; no mark-on-line for annotations of connections | open |

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

## Acceptance sketch

- Every state a work can hold is either visible in classic or
  reachable through an inspector with one click — no dimension
  requires switching to the workspace.
- The matrix table above, kept current, is the checklist.
