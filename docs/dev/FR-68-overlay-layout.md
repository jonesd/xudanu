# FR-68 — Overlay layout engine

## Problem

Link decorations (ribbons, pills, margin bars, badges, descriptor
boxes, connectors) are placed by scattered per-element code with
hand-tuned offsets. Each overlap fixed individually (desc text under
borders 2026-09-16, canvas clipping below container height
2026-09-16, lanes vs wrapped text) reveals the same root cause:
there is no single place that knows the size of everything.

## Principle

Components have known metrics. The page has known channels. A
single pure layout pass places every decoration from the metrics
and the channel geometry; drawing consumes placements only. Overlap
becomes impossible by construction, and the line/box budgets become
explicit numbers we can reason about.

## Channels

Vertical strips of the editor area, fixed by geometry:

| Channel | x-range | Contents |
|---|---|---|
| LEFT_GUTTER | [0, 84) | margin bars (pitch 4), composition pill, end-set badges |
| TEXT | [84, W-246) | passage text; ribbons in the corridor below each line |
| RIGHT_GUTTER | [W-246, W) | descriptor boxes (width 210 + margins), connectors' far end |

Vertical corridors inside TEXT: the leading below each text line is
the ribbon corridor (budget from line metrics). Ribbons exceeding
the corridor budget collapse to the pill in LEFT_GUTTER — the
density threshold becomes a layout rule, not just a count.

## Component registry (the only place sizes live)

```
RIBBON     h=4  rowGap=2  maxRows=5     (row pitch 6)
PILL       h=18 w<=74     (7 segments x 6 + count text)
BAR        w=3  pitch=4   (stacks by lane)
BADGE_END  22x14
DESC_BOX   w=210 h=max(46, span+10, DESC_CONTENT_H=52)  vGap=10
CONNECTOR  stroke 1.5     draw only during hover (focus)
SAFE_MARGIN              8px between any placement and channel edge
```

DESC_TEXT metrics (label chip, line height, wrap budget 2) already
exist — they generalize into this registry.

## Layout pass

Pure function, extracted to `web/app/src/link-overlay-layout.ts`:

```
layoutOverlay(geometry, spans, links) -> { placements, canvas }
Placement = { kind, x, y, w, h, ref }
```

Placement rules:
1. Channel membership fixes the x-range of a placement class;
   classes cannot overlap across channels by geometry.
2. Within a channel, pack top-to-bottom (descriptor boxes already
   do this via placeDescBoxes — generalize it to all classes).
3. Corridor budgets: ribbon rows must fit the line's leading;
   overflow collapses to the pill.
4. Canvas dimensions = union of all placements + SAFE_MARGIN.
   Nothing draws outside the canvas because nothing is placed
   outside it (kills the container-height clipping class of bugs).

## Invariants (property tests, pure — no browser)

1. No two blocking placements intersect.
2. Every placement lies inside its channel and inside the canvas,
   respecting SAFE_MARGIN.
3. Canvas height >= max placement bottom + pad.
4. TEXT-channel placements touch text glyph boxes only inside
   ribbon corridors.
5. Wrap budget respected: a desc box with 2-line content is never
   sized below DESC_CONTENT_H.

## Implementation approach

### Module shape

`web/app/src/link-overlay-layout.ts` — pure functions, no DOM, no
React imports. Everything the layout needs arrives as data.

```ts
export type ComponentKind =
  | "ribbon" | "pill" | "bar" | "badge_end" | "desc_box" | "connector";

export interface Geometry {
  width: number;          // overlay width (CSS px)
  channelGutterL: number; // LEFT_GUTTER right edge (84)
  channelGutterR: number; // RIGHT_GUTTER left edge (width - 246)
  safeMargin: number;     // 8
}

export interface Anchor {          // measured in the component (DOM)
  markerId: string;                // link id + end disambiguator
  kind: ComponentKind;
  lineRects: Array<{ x: number; y: number; w: number; h: number }>;
  leadingPx: number;               // corridor budget for this line
  content?: { text: string; typeColor: string; typeOrder: number };
}

export interface Placement {
  kind: ComponentKind;
  x: number; y: number; w: number; h: number;
  markerId: string;
  meta?: Record<string, unknown>;  // segments, counts, dim flags
}

export interface LayoutResult {
  placements: Placement[];
  canvas: { w: number; h: number };
  collapsed: string[];             // markerIds folded into pills
}

export function layoutOverlay(g: Geometry, anchors: Anchor[]): LayoutResult;
```

### Data flow (one direction)

```
links (useTransclusion)
  -> component measures DOM range rects  (the ONLY DOM step)
  -> anchors[]
  -> layoutOverlay()                     (pure, testable)
  -> placements + canvas
  -> drawOverlay paints placements only
  -> hitZones derived from the SAME placements
```

Two consequences worth naming:
- **Hit zones and paint can no longer diverge** — both come from
  placements. (The pill-visual-vs-hitzone mismatch class of bug
  disappears.)
- **The canvas sizes from the layout output** — clipping becomes
  structurally impossible, not patched.

### Layout sub-passes (inside layoutOverlay)

1. **Assign channels** by kind: bars/pills/badges -> LEFT_GUTTER,
   desc boxes -> RIGHT_GUTTER, ribbons -> TEXT corridors.
2. **Corridor budgeting**: group ribbons by line; rows at pitch 6
   must fit the line's `leadingPx` budget; overflow rows collapse
   their markers into a pill (the collapse rule moves here from
   DENSITY_THRESHOLD-only counting).
3. **Within-channel packing**: sort by y, place top-to-bottom with
   per-kind gaps (desc boxes: existing placeDescBoxes algorithm,
   generalized; bars/badges: fixed pitches; pill: one per cluster).
4. **Canvas union**: max bottom/right of all placements + margins.

Complexity target: O(n log n) per redraw (sort per channel). The
redraw already runs on every marker/state change; measurement
(DOM ranges) remains the expensive step and stays in the component,
cached per text state.

### Testing

- **Property tests** (vitest, pure): the five invariants above,
  run against randomized anchor sets (fast-check style loops).
- **Golden fixture**: the Connection Atlas S1-S5 spans as a frozen
  anchor set; layout snapshot asserts exact placements — changes to
  metrics or rules must update the golden consciously.
- **Component smoke**: existing tests keep passing; one new test
  asserts hit zones equal paint placements for a simple fixture.

### Migration (each step ships green)

| Step | Change | Acceptance |
|---|---|---|
| 1 | Extract DESC_TEXT metrics + placeDescBoxes into module; desc boxes drawn from placements | identical rendering; tests move |
| 2 | Bars, badges, pill through the pass | identical rendering; pill hitzone == placement |
| 3 | Ribbons through corridors; collapse rule relocated | density demo + Atlas render correctly; corridor budget test |
| 4 | Canvas sized from layout output | long-document clipping gone (Atlas S5 pill visible at any scroll) |
| 5 | Delete migrated magic numbers from CollaborativeEditor | only registry holds sizes |

Estimated size: module ~300 lines + ~200 test lines; component
diff is deletions plus anchor-gathering. No backend changes.
