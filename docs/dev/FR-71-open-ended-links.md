# FR-71: Open-Ended Links (Links to Nowhere)

**Status:** queued (design sketch, not yet scheduled)
**Created:** 2026-09-17
**Prior art:** "Links to Nowhere" — everything-abridged.com (`memetic_note_taking`,
`tools_for_thought_should_highlight_links_to_nowhere`, April 2022)
**Related:** FR-40 (links model), FR-6 (cross-server refs), tumblers (FR-34 D-F)

## The idea

A link tethered to one passage with its other end left OPEN — a
reservation for a future connection, completable later with one or
more places. The wiki world calls these "Links to Nowhere" and treats
them as first-class constructs: "markers for later exploration."

Their thesis (adopted here):

- Open links let you resume exploration easily — seeing them is the
  point, not a broken state.
- Knowing a link has no target yet makes arriving at the empty end
  LESS disorienting, not more.
- Tools should call open links out separately from normal links.
  (His own wiki implements this as a CSS class on dead-end links —
  `internal isDeadEnd`.)

Further prior art from the same site, sharpening the design:

- **"Interlinked Notes Self Organize"**: "topics can be defined by
  Links to Nowhere and then perusing the backlinks to that 'empty
  note.' This creates an implicit index of notes surrounding a topic
  without any organizational effort." The real payoff of an open end
  is not just future completion — its backlinks ARE the topic. An
  open end with many tethers converges with concept works (FR-22):
  the connection-set is a living index before the target exists.
- **Friction lessons** ("Proper Noun References Reduce Friction",
  "Naming Evergreen Notes is a source of Friction"): creating an
  open end must not demand a perfect name. Rough label at creation,
  refine at completion.
- **The differentiator, from their weakness**: "Namespace Collision
  is Wikilogging's Most Obvious Problem" — title-based open links
  collide. Tumbler-addressed open ends never do: two identities can
  reserve "the same topic" and the addresses stay distinct.

Xudanu's version is stronger than the wiki's because it is
address-based, not title-based: an open end can carry a reserved
identity (tumbler / cross-server ref) for a document that does not
exist yet. The connection precedes the target.

## What exists today

- `create_link` takes `Option<HyperRef>` for BOTH ends — a passage on
  one side and `None` on the other already works (server.rs:14918).
- Gathered end-sets: each side is a SET of references;
  `LinkAddEnd` (0x0707) / `LinkRemoveEnd` mutate ends post-creation;
  the demo corpus seeds a three-passage gathered disagreement link.
- What is missing: creation requires both WORK ids to exist — no
  fully-open destination, no surfacing of the open state, no resume
  affordance.

## Design

### 1. Dangling creation

- `create_link` accepts `destination: None` → an open-ended link.
- The link is visible from the origin side immediately (connections
  panel; editor marker).
- WAL: `link_create_open` entry; replay restores the open state.

### 2. Surfacing (the prior art's core ask)

- **Rendering grammar (acceptance criterion):** an open end must be
  recognizable at a glance as NOT-YET-CONNECTED, and must never be
  mistakable for a normal rendered link. Concretely: dashed/dotted
  underline (vs solid for live links), hollow endpoint glyph (vs
  filled), reduced-opacity label, tooltip "open — complete this
  connection". The panel section styles open ends as invitations
  (e.g. "Open ends (2) — complete" affordance), never as errors.
  Naming homage to the prior art: the `isDeadEnd` class name.
- Editor: open ends render distinctly from live links — ghost/dotted
  marker, never a broken-link style.
- Connections panel: an "Open ends" section with the pending count.
- Docuverse graph: open ends as boundary nodes (invitation shape).

### 3. Resume exploration

- Clicking an open end offers: "Create the target here" — new work
  creation pre-wired to complete the link (`LinkAddEnd` on creation),
  or "Attach an existing work" via the work picker.
- Completing with MULTIPLE places uses the existing gathered end-set
  path unchanged.

### 4. Non-disorienting arrival

- Navigating to an unresolved end shows the origin context — which
  passage tethers it, when, by whom — never a 404.

### 5. Stretch: reserved addresses

- The open end may name a tumbler (or `CrossServerRef`) for a target
  that does not exist yet; when a work with that identity appears
  (created locally or resolved cross-server), the link completes or
  flags for confirmation.
- This is the full Nelson form: the connection is a place you can
  later fill.

## Tests

- Create open → visible from origin, absent from any destination.
- Complete with one work → ordinary two-ended link; backlinks appear.
- Complete with gathered set (3 passages) → existing end-set armor.
- Two open ends from different origins complete to the SAME new work
  → both resolve; backlink panel shows both tethers.
- WAL replay restores open state; restore round-trip.
- Cancellation: delete an open link (already covered by link delete).

## Effort

Core (1-4): ~1 day. Reserved addresses (5): +1-2 days, depends on
tumbler allocation ergonomics.
