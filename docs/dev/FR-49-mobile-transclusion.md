# FR-49: Mobile Transclusion Flow

Status: draft · Date: 2026-08-28
Builds on: mobile editor enablement (2026-08-28 — the plain-text
reader overlay was retired; the real CollaborativeEditor renders on
phone), the bottom-sheet panels (sheet renders the desktop panel
body), CompoundBuilder full-screen sheet, LinkCreator wizard
(guided-step pattern), TransclusionBadge placement bar
(onPlace / onPlacePinned / onSwitchWork / onPlaceAtEnd).

## Why

Transclusion is the signature Xanadu capability — "the one Roger
would evaluate first-hand" — and mobile is now a first-class client:
real editing, real panels, PWA install. But the two halves of the
transclusion story are desktop-shaped:

- **Receiving:** transcluded passages render with hover-revealed
  source details and margin-bar markers that consume width that a
  390px viewport does not have.
- **Creating:** the placement flow assumes a cursor in a second
  visible pane and a floating badge anchored to it. On touch there
  is no hover, no persistent cursor, and one visible document.

The mobile constraints are also an opportunity. AGENTS.md names
transclusion placement UX "the hardest open problem" (cursor
position tracking, padding newlines, CRDT delta coordination,
overlapping regions). Forcing the flow through touch constraints
produces **tap-to-place**, which maps one-to-one onto
click-to-place on desktop — solving mobile may finally solve the
desktop placement problem too.

## Principle

**One interaction grammar across surfaces.** Selection → intent →
destination → placement → confirm/undo. The wizard runs in the
bottom sheet (the pattern the phone shell already uses for panels);
placement is an explicit mode, never a guess; every transclusion is
reversible in one tap (the existing undo toast). Reuse the editor,
the sheet, and the existing wizard components — no parallel mobile
implementation of transclusion logic.

## Part A — Receiving (display)

### A1. Phone marker styling (replace margin bars under 768px)

Desktop: margin bars + colour coding per source document.
Phone: **tinted background** (source colour, low alpha) + a compact
**source chip** at the passage start (source-initial glyph or doc
kind icon). Margin bars remain at tablet width and above.

- Tint keeps full text width; the chip is tappable.
- Overlapping/nested transclusions: stack tints (screen blend);
  the chip shows the top-level source; the sheet (A2) lists all.

### A2. Tap → source sheet

Tapping a transcluded passage opens the bottom sheet with the
source card: title, author(s), licence badge (with ARR warning if
applicable), tumbler address (XCP-shareable), verification state,
and actions: **Open source**, **Copy tumbler link**, **Detach**
(owner-only, replaces with plain text — existing op).

### A3. Live-update affordance

When a source edit updates a transclusion in view, flash the tint
once (400ms) — "this quote just changed." No banner, no toast;
the change itself is the signal. (PWA offline: updates arrive on
reconnect; no special handling.)

## Part B — Creating (the wizard)

Trigger: text selection in any readable document → toolbar shows
**Quote** (alongside Link/Annotate). Tapping it starts the wizard
in the sheet. Steps are skippable when the answer is obvious
(single-document server skips step 2's picker, etc.).

### Step 1 — Confirm span
The selected range with a few chars of context; adjust handles
(native selection controls); options: exact selection (default) or
whole document.

### Step 2 — Destination
Cards: **This document**, **Choose document** (searchable picker
over the works list, most-recent first, kind icons), **New
document** (creates untitled, then continues). Remote-server
sources are out of scope here (FR-6 cross-server handles the
remote *source* side; remote *destination* is a later extension).

### Step 3 — Placement
- **At end** (default; one tap, matches existing onPlaceAtEnd)
- **Tap-to-place:** enters placement mode — sheet closes, content
  dims slightly, a floating hint bar shows "Tap where the quote
  goes · Cancel". The tap sets the caret and inserts immediately
  (padding newlines per the existing placement rules). If the
  destination is a different document, navigate to it first with
  placement mode armed.
- **Pinned** (existing onPlacePinned semantics) as an advanced
  choice on the same step.

Placement mode is a first-class editor mode: it must survive a
navigation (destination switch), be cancellable from the hint bar
or by tapping an inert region, and never leave the document in a
half-placed state (insert is atomic; undo toast on success).

### Step 4 — Confirm/undo
Existing toast: "Transclusion placed · Undo". The placed passage
renders per Part A immediately (source chip in the user's own doc).

## Part C — Cross-cutting

- **Editing around transclusions:** the editor already treats
  inline transclusions as atomic ranges; touch selection must not
  split them (existing behaviour — regression-test on touch).
- **Licence compliance:** the existing compliance badges (✓
  Licensed / ⚠ ARR) surface in step 1 of the wizard when the
  source is ARR — before the quote is placed, not after.
- **Provenance:** placed passages appear in the Attribution panel
  (and ledger) with source_work_id intact — already wire-complete;
  verify on phone after the 2026-08-28 materialization fix.

## Phasing

1. **A1 + A2** (display: tints, chips, source sheet) — self-
   contained CSS + one sheet route; no protocol work.
2. **B steps 1–2 + at-end placement** — wizard scaffold reusing
   LinkCreator step components; covers the 80% case (quote → this
   doc / picker → at end).
3. **B step 3 tap-to-place** — the placement mode; land here only
   after 1–2 are stable. Then port the same mode to desktop as
   click-to-place (its own small FR if scope grows).
4. **A3 + C polish** — update flash, touch selection regression
   tests, remote-destination extension notes.

## Success criteria

- A quote can be placed from any document into any other document
  on a phone in ≤ 4 taps beyond the selection.
- Source details are one tap away on any transcluded passage;
  nothing on phone requires hover.
- Margin bars never appear under 768px; text width is never
  reduced by a marker.
- Placement mode is always cancellable and never corrupts text
  (atomic insert + undo).
- The same wizard flow, minus placement mode, still works on
  desktop unchanged.

## Open questions

- Pinned transclusion semantics on a scrolling touch document
  (does the pin follow the source anchor through edits the way
  owners expect?) — needs a design note before phase 3.
- Multi-source overlap: is one tint + chip enough, or do we need a
  cycle affordance when ≥ 3 sources overlap?
- VoiceOver/live-region announcements for placement mode — audit
  during phase 1.
