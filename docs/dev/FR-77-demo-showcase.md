# FR-77: Demo Showcase — Gallery-First Landing Experience

**Status:** Phase 1 in progress (showcase card)
**Created:** 2026-09-22
**Problem:** a first-time visitor (HN traffic, curiosity click, conference
demo) lands on the welcome screen and must understand the library, open
it, find the right work, and know what to click — three decisions before
the first "wow". The Gallery of Unusual Connections is the strongest
demonstration the system has, but it is buried one library-browse away.
Meanwhile demo deployments run read-only (FR: museum mode), where the
primary actions (New Document, Import) are unavailable — the landing
page's calls to action are actively wrong for those visitors.

## The proposal

The welcome screen grows a **showcase card**, rendered when the Gallery
is seeded, sitting above the feature grid:

```
┌──────────────────────────────────────────────────────────────┐
│ ▤  THE GALLERY OF UNUSUAL CONNECTIONS                        │
│    Nine rooms of live link structures — every exhibit is     │
│    the thing itself, not a picture of it.                    │
│                                                              │
│    [Enter the Lobby]  [Spectrum Sentence]  [Live Window]     │
│    [Five-Way Compare]           (read-only demo notice)      │
└──────────────────────────────────────────────────────────────┘
```

- **One click to the first wow**: Lobby and Spectrum Sentence are
  direct work navigations. Live Window (transclusion room) and
  Five-Way Junction (compare room) likewise.
- **Graceful absence**: unseeded servers render nothing new — same
  convention as the Links Course detection (`hasCourse`).
- **Read-only aware**: when the server runs the Frozen edit policy,
  the card shows the read-only notice inline and the primary
  New Document / Import actions de-emphasize (the top-bar pill and
  toast from museum mode already exist).
- **No new server machinery**: detection is by seeded title
  prefixes in the works list (precedent: course detection). The
  showcase is a client concern.

## Phase 1 (this FR)

1. `WelcomeScreen` props: `showcase` (the four entry work ids +
   title) and `onOpenShowcaseWork(id)`. Rendered only when present.
2. `WorkspaceShell`: derive the showcase from `works` (title
   prefix `Gallery — Lobby`, `…Room 1`, `…Room 7`, `…Room 9`),
   pass `selectWork` as the handler.
3. Visual: a single bordered card, gallery-orange accent, four
   entry buttons; keyboard accessible (native buttons).

## Phase 2 (future, out of scope now)

- **Showcase registry**: any exhibition cover can advertise entry
  points (gathered members flagged as "featured"), generalizing
  this beyond the seeded gallery — the exhibition model (cover +
  gathers links) already carries the data.
- **Tour mode**: enter the Curator's Tour with a progress affordance
  on the landing page (trails API already exists).
- **Server-side showcase**: a public HTTP field advertising the
  showcase works (pairs with the public content API).

## Exit criteria (Phase 1)

- Seeded server: landing page shows the card; each entry lands in
  the named room in one click; Lobby entry lands scrolled to top.
- Unseeded server: no card, no layout shift, existing actions
  unchanged.
- Frozen server: card + read-only notice coexist; New Document
  still present for owners (policy is per-session, the card is not
  the policy).
