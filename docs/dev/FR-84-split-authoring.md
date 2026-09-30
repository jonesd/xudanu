# FR-84 — Split Authoring: both ends visible while connecting

**Status:** specified, not started (September 2026)
**Tradition:** Nelson's parallel documents — but as a deliberate
AUTHORING mode, not a default reading posture (the Gwern critique of
side-by-side-everything is accepted; side-by-side is what making a
connection deserves, not what reading deserves).
**Related:** FR-40 (end-sets/gathered ends — gets its authoring UI
here), FR-59 (multi-compare — supplies pane scaffolding), FR-66
(link-creation onboarding), FR-79 (overlay marks reuse the margin
conventions).

## Why

Making a connection is the core action, and today it is done blind:
select text → hold → resolve the far end through a library picker or
a jump-away navigation. The author never sees both passages at once.
Every downstream feature (typed disputes, transclusions, gathers)
inherits this blindness. The held-selection machinery and the
multi-work compare panes already exist — the gap is exactly that the
second pane is not live and connections cannot complete across it.

## What already exists (build on, don't rebuild)

- `selectionRange` + `transclusion.holdSelection/holdLinkSelection`
  — holding one end of a pending cross-document operation
- `multiCompareWorkIds` + compare panel — N works side-by-side with
  pick/remove/fullscreen (read-only, revision-oriented)
- Per-work CRDT sessions (`openSyncSession(workId, …)`) — a second
  live editor mount is plausible without server changes
- `jump_target` payloads — span+work as one unit (the bar and deep
  links already speak it)
- Tablet drawer / phone sheet CSS — responsive split layouts
- `link_create` with both endpoint refs; transclusion placement ops
  — the server needs NOTHING new for slices 1–3

## Design

### Slice 1 — Live split view

A second work pinned beside the current one: `splitWorkId` state
feeding a second `CollaborativeEditor` mount (its own CRDT session,
its own save state indicator). Entry points: "Open beside" from the
library rows and the links-panel far-end groups; exit collapses back
to single-doc. Desktop: half/half split; tablet: stacked sheets;
phone: unchanged (jump flow remains).

Client audit list (single-work assumptions to lift):
`openWorkTitle`, `currentStarred`, offline-mirror pinning, autosave
guards, marker/tooltip color maps (per-pane contexts), the editor's
global listeners (hotkeys, hash navigation) — second instance must
not fight the first.

### Slice 2 — Two-ended linking across the panes

Select in pane A → "Hold as end" (existing hold). Select in pane B →
the **pending-connection bar** wakes showing BOTH ends live: two
excerpt chips with direction arrows (A → B), the type picker inline,
create on confirm. No modal picker, no navigation away. The bar is
the two-ended twin of the existing single-end hold bar.

Connection start with no split open: **auto-open heuristic** — if a
far candidate exists (the work you last connected with, the far end
of the link you're inspecting, a compare pane member), open it
beside automatically; otherwise fall back to the library picker.
(Open question below.)

### Slice 3 — Transclusion authoring

Hold a passage in A; place the caret (or select a span) in B →
"Transclude held passage here" with a live preview chip of the
resolved span (source title + license badge per FR-38 egress rules).
Reuse the range ops; preview resolves server-side.

### Slice 4 — Read pins and gathers

- "Open beside" as READ pin (cheaper than a live editor; the
  multi-compare renderer graduates into the pin renderer)
- Gather mode: hold selections from multiple panes (and multiple
  pages via FR-79 shadows later) → one link with a gathered end-set
  — FR-40's wire capability finally gets its authoring gesture

## Exit criteria

- [ ] S1: two live editors, independent sessions, both save safely;
      collapse/expand preserves each pane's state
- [ ] S1: "Open beside" from library row + links-panel far end
- [ ] S2: two-ended bar creates a typed link whose both ends are the
      held selections (verified by opening the link panel + jump
      from both directions)
- [ ] S2: auto-open heuristic or picker fallback never dead-ends
- [ ] S3: transclusion placed from held passage renders live in the
      target pane; provenance chain visible
- [ ] S4: gathered end-set link created from ≥3 held selections
      across panes
- [ ] Responsive: tablet stacked, phone unchanged
- [ ] Existing single-doc flows untouched (suite green)

## Out of scope

- Server changes (none needed for 1–3)
- Default-reading-mode split (deliberately not the posture)
- Overlay-extension authoring (Stage 3 of FR-79 — separate)

## Open questions

1. Auto-open far candidate vs always-ask? (Recommendation:
   auto-open when a candidate exists, remembered as a setting.)
2. Do both panes keep independent right-panel tabs (provenance/
   connections) or share one right rail scoped to the ACTIVE pane?
   (Recommendation: one rail, active-pane scoped — less chrome.)
3. Should the pending-connection bar survive pane collapse (parking
   a half-made connection)? (Recommendation: yes — held selections
   already survive; parity for the two-ended bar.)

## Session notes (Sep 30, 2026 — user-tested slice 1)

First cross-pane link created end-to-end. Issues found in testing,
for the next session:

- [ ] Pane link markers: panes render plain text with no underlines
      — the far document's connection landscape is invisible. One
      color per KIND (the spectrum-sentence language), visible from
      both ends. This is the top priority.
- [ ] Marker tooltip "Go to" overlaps the link below (positioning
      grows downward into the next marker)
- [ ] Held end should survive work switches (verify: does mainHeld
      persist across selectWork?)
- [ ] Pane WebSocket error handling: clientRef.current can go stale
      during reconnection; retry should re-resolve the client
- [ ] Small-screen layout: connect bar + hold chip + Aa button
      compete for bottom space on laptop screens
