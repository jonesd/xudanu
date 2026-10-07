# FR-143 — Visible links, completed: span previews and transpointing windows

> **Status:** Proposed (2026-10-07). Sequenced first in the
> pattern-completion roadmap; rungs A–B are robust to outside
> input on what transpointing "should" mean — they build the two
> halves Nelson named regardless.
>
> **Related:** the pattern map (`docs/pattern-language.html`),
> FR-85 (beams already exist in compare view), FR-38 (span license
> overlays — same span-resolution machinery), FR-40 (link model),
> FR-6 (cross-server — explicitly out of scope here).

## Motivation

The pattern map marks Pattern 1 (visible links) *partial* — hover
names the connection's type and far end, but shows none of the
destination — and Pattern 3 (transpointing) *barely started* —
beams exist only inside version-compare. Nelson's formulation
requires both halves: a **visible pointer at the origin** and a
**live window at the destination**. This FR completes them in
three independently shippable rungs.

## Phase A — span hover preview (completes Pattern 1)

Hovering a link underline (or a connections-panel entry) shows a
floating card containing:

- the **destination passage itself** — the current text of the far
  end's span (≈200 chars around it when whole-work), not metadata
  about it
- the connection **type** (colour and name) and **authorship** of
  the far-end passage (per-span attribution, already computed)
- a degraded card ("destination not readable") when read gates
  apply — never an empty hover

**Acceptance:** all six link types produce cards; web-type links
show the URL and title; the Spectrum Sentence's six underlines
each preview their distinct far ends.

## Phase B — transpointing v0: "open as window"

From the hover card (or links panel), **open the far end as a
window**: a small pane rendering the destination span *live* —

- re-renders when its source work revises (the transclusion
  machinery's resolve-on-read, pointed at a link end)
- a **beam connects** origin underline ↔ window whenever both are
  visible, reusing the compare-view beam geometry
- read-only; provenance and license badge rendered in the pane
  header; closing the window closes the beam

**Acceptance:** a window opened on a passage updates within a
revision of its source; the beam tracks scroll on both sides; the
Live Window gallery room can be reproduced by a reader using only
link → open-as-window (no seeding required).

## Phase C — multiple windows

Several live windows may be open simultaneously; beams redraw;
layout is tiled (free arrangement is out of scope — see below).

**Acceptance:** the Spectrum Sentence demo becomes *six windows on
one sentence*; performance holds at ≥8 open windows on the demo
corpus.

## Deliberately out of scope

- Free-form window arrangement / zigzag spatial model
- Cross-server windows (FR-6 federation makes this a future rung,
  not a design change: a window's source is an address, and
  addresses can be remote)
- Write-through from windows (a window is a view; editing stays in
  the source work's own editor)

## Sequencing note

This FR is rung one of the pattern-completion arc. Follow-ons,
each their own FR when taken up: modular block authoring UX
(Pattern 7), perspective-view polish (Pattern 10). The internal
queue (selection-scoped Find/Trace, recovery manager, concurrent
chaos) proceeds in parallel and touches none of this.
