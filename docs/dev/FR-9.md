# FR-9: Perspective Document Comparison (Spatial Intercomparison)

> Inspired by OpenXanadu (Nicholas Levin, 2014-2025) and Ted Nelson's
> "parallel pages, visibly connected" concept. Implements Xanadu pattern #10
> (Multiple Views and Spatial Arrangements) from Maggie Appleton's pattern
> language.

## Goal

Display a central readable document flanked by related documents receding
into perspective, with colored connection lines between linked passages.
Clicking a connection zooms into a side-by-side comparison view.

Primary connections are **human-authored links** (the author deliberately
connected these passages). Content fingerprint matches (identical text shared
between documents) are a secondary, optional layer.

## What We Learned from OpenXanadu

The OpenXanadu demo (xanadu.com/xanademos/MoeJusteOrigins.html) uses
non-minified JavaScript. Its architecture is:

### Scaling: CSS transforms, not canvas
```javascript
// DocumentView.zoomIn(3) produces:
transform: scale(0.125) translateY(-Y%)
```
The browser handles all text scaling. No pre-rendering, no canvas text.
Maximum safe zoom across browsers: level 3 (1/8 scale).

### Positioning: percentage left values
```
Center document: left: 30%
Right neighbors: left: 55%, 62%, 69% ... (increment 6.66%)
Left neighbors:  left: 4%, -3%, -10% ... (decrement 6.66%)
```
Horizontal overflow handled by scrolling the container.

### Connections: canvas overlay with DOM span endpoints
Each transclusion has `<span>` markers in both documents. A canvas overlay
reads `getBoundingClientRect()` on these spans and draws filled bezier paths
between them. Redrawn on every scroll event.

### Three view modes (cycled with Shift+Spacebar)
1. **Lonesome View** — center document only, no connections
2. **Stub View** — center document with stub markers showing where connections exist
3. **All Bridges** — full perspective view with all connected documents visible

### Navigation: click-based
- Click a connection line on the canvas → side-by-side view of the two endpoints
- Click a neighbor document → makes it the new center
- Spacebar + Arrow keys → navigate between connections

### Performance hack
Instead of `removeChild` (slow for large DOMs), hidden documents are moved to
`top: Number.MAX_VALUE`. This avoids triggering DOM reflow.

### Weaknesses we should fix
- Connection lines have no visual affordance — users don't know they're clickable
- Keyboard shortcuts are completely hidden (no UI hints)
- No way to see WHERE a connection leads without clicking it
- No zoom gesture — must use hidden Shift+Spacebar to toggle modes

## Visual Design

```
                          ┌───────────────────────┐
                          │                       │
    ┌──┐  ┌────┐  ┌───────┴───────┐  ┌────┐  ┌──┐
    │  │  │    │  │               │  │    │  │  │
    │ D5│  │ D3 │  │      D1       │  │ D2 │  │D4│
    │  │  │    │  │   (readable)   │  │    │  │  │
    │  ▓│  │  ▓ │  │      ▓        │  │ ▓  │  │▓ │
    │  │  │    │  │               │  │    │  │  │
    │  │  │  ▓ │  │      ▓        │  │▓   │  │  │
    │  │  │    │  │               │  │    │  │  │
    └──┘  └────┘  └───────────────┘  └────┘  └──┘
   scale: 0.2   0.4        1.0         0.4    0.2
```

- **Center column**: Full-size readable text, ~40% viewport width
- **Near columns** (left-1, right-1): CSS `scale(0.5)`, text shapes visible
- **Mid columns** (left-2, right-2): CSS `scale(0.25)`, colored blocks visible
- **Far columns** (left-3, right-3): CSS `scale(0.125)`, colored slivers
- **Colored blocks**: Linked passages — each link gets a consistent color
- **Connection lines**: Filled bezier curves on canvas overlay between linked spans
- **Zoom**: Pinch / scroll wheel / button — changes scale of non-center columns

## Connection Colors

Colors indicate **which link** connects the passages, not the link type:

- Each link gets a unique hue (HSL color wheel)
- Same link = same color in both documents
- Link type is shown by the line style (dashed, solid, dotted) matching our
  existing link type styles from CollaborativeEditor

This matches OpenXanadu's approach and makes it visually obvious which
passages are connected to which.

## Scrolling Model: Independent with Live Connections

Each column scrolls independently. This is simpler than focus-locked
scrolling and matches OpenXanadu's approach:

1. User scrolls any column normally
2. Connection lines redraw on every scroll frame
3. Lines connect wherever the linked passages happen to be vertically
4. Long lines that span large vertical distances are drawn thinner/faded

**Why not focus-locked?** Focus-locked scrolling (auto-aligning neighbors to
match center) sounds nice in theory but:
- Adds algorithmic complexity
- Can feel jerky when no good match exists
- OpenXanadu doesn't use it and feels responsive
- Users can manually scroll to find connections

## Implementation: DOM + CSS Transforms + Canvas Overlay

Following OpenXanadu's proven architecture:

### Document columns (DOM)
Each column is a `<div>` containing the document text:
```tsx
<div className="perspective-column" style={{
  transform: `scale(${scale})`,
  left: `${leftPercent}%`,
  width: '40%',
}}>
  <div ref={docRef} className="perspective-doc-text">
    {renderTextWithLinkSpans(text, links)}
  </div>
</div>
```

### Link span markers (DOM)
Each linked passage is wrapped in a `<span>` with a unique ID:
```tsx
<span id={`link-${linkId}-start`} className="link-span" style={{ background: color + '30' }}>
  {text.slice(start, end)}
</span>
```

### Connection overlay (Canvas)
A single transparent canvas spanning the full viewport:
```tsx
function drawConnections(canvas, linkSpans) {
  for (const span of linkSpans) {
    const startRect = span.startEl.getBoundingClientRect();
    const endRect = span.endEl.getBoundingClientRect();
    drawBezierPath(ctx, startRect, endRect, span.color);
  }
}
// Redrawn on every scroll event (throttled to rAF)
```

## Navigation UX (Fixing OpenXanadu's Mistakes)

| Action | Trigger | Visual affordance |
|---|---|---|
| Follow connection | Click connection line OR click colored block in text | Lines thicken on hover; cursor changes to pointer |
| Zoom in/out | Scroll wheel, pinch, or zoom buttons (− / +) | Visible buttons in toolbar |
| Make neighbor center | Double-click neighbor column | Tooltip on hover: "Click to focus" |
| Side-by-side view | Click connection line | Smooth transition animation |
| Return to perspective | Click "Back" button or press Escape | Always-visible back button |
| Toggle connection types | Filter dropdown (All, Links only, Content matches) | Visible dropdown |

Every action has a visible UI element. No hidden keyboard shortcuts for
primary operations.

## Implementation Plan

### Phase 1: Perspective view prototype — DONE

**Status**: Prototype working. Center document + neighbors with full text,
CSS-scaled columns, colored highlights, connection legend.

What we built:
- `PerspectiveView.tsx` — full component with perspective layout
- Neighbor text fetched via `crdt_sync_open` (field: `current_text`)
- Whole-work links use full-document span (0 to text.length)
- Text-specific links use actual span positions
- Connection legend at bottom showing link types with colors
- Zoom controls (+/−) adjusting visible neighbor count
- Double-click neighbor to focus (swap to center)
- Connection lines via canvas overlay (bezier curves between spans)
- Wired into AppShell via "Perspective" button in doc-toolbar

Lessons learned:
- Text fetch takes ~10-20s for multiple neighbors (sequential WebSocket).
  Phase 2 should parallelize or add a dedicated text-fetch endpoint.
- Whole-work links highlight entire document — visually heavy. Phase 2
  should add a subtle "document-level connection" indicator instead.
- Explicit colors required: neighbor text needs `color: #1a1a24` to be
  visible (dark theme cascades otherwise).
- Single-click navigation too aggressive — changed to double-click so
  users can scroll/select text in neighbor columns.

### Phase 1.5: Polish and fix (1-2 days)

7. **Connection line rendering**
   - Fix bezier paths between center spans (`plink-` IDs) and neighbor
     spans (`nplink-` IDs)
   - Lines should anchor to span centers, redraw on scroll
   - Add hover detection on canvas (thicken line on hover)

8. **Whole-work link visualization**
   - Instead of highlighting entire document, show a colored border or
     tinted background on the column
   - Connection line goes from column edge to center document edge
   - Text-specific links still use precise span highlights

9. **Loading indicators**
   - Show spinner or "(loading...)" placeholder while neighbor text
     fetches
   - Fade-in animation when text arrives
   - Stagger fetches to avoid blocking

10. **Text fetch optimization**
    - Add a dedicated server endpoint: `GET /api/work/{id}/text`
    - Returns plain text without opening a CRDT session
    - Parallel HTTP fetches (faster than sequential WebSocket)
    - Fallback to `crdt_sync_open` if endpoint unavailable

11. **Responsive layout**
    - Minimum viewport width check (hide on mobile, show message)
    - Neighbor count auto-adjusts to screen width
    - Columns shrink proportionally on narrower screens

### Phase 2: Interaction (3-5 days)

12. **Click passage to navigate**
    - Single-click colored passage in center → highlight matching
      passage in neighbor (scroll neighbor to show it)
    - Single-click colored passage in neighbor → scroll center to show
      matching passage
    - Connection line thickens between the two active passages

13. **Smooth focus transitions**
    - Double-click neighbor → animate scale/position swap
    - Former center shrinks and moves to opposite side
    - Connection lines redraw with transition

14. **Hover effects**
    - Hover connection line → thickens, shows tooltip with link type
      and excerpt text
    - Hover neighbor column → subtle highlight, title tooltip
    - Hover colored passage → shows link type badge

15. **View mode toggle**
    - Three modes (visible buttons, not hidden shortcuts):
      - Full text (all columns readable)
      - Highlights only (hide text, show colored blocks)
      - Connections only (hide columns, show just the lines)

16. **Manual neighbor management**
    - "Add document" button: search and pin a document to a column
    - "Remove" button on each neighbor column
    - Drag-to-reorder columns
    - Persist layout in localStorage

17. **Depth control**
    - Slider: 2, 4, 6, 8 columns visible
    - Dynamically add/remove columns with CSS transition
    - "Show all" button for maximum depth

18. **Keyboard navigation**
    - Left/Right arrows: cycle focus between columns
    - Up/Down arrows: jump to next/previous connection
    - Enter: follow connection to neighbor
    - Escape: close perspective view

### Phase 3: Content matching layer (future)

11. **Optional content fingerprint connections**
    - Toggle to show `find_shared_regions` matches alongside human links
    - Different visual style (thinner lines, different dash pattern)
    - Tooltip: "Identical text — quotation or derivation?"

12. **Semantic zoom**
    - Zoom out far enough → text becomes colored blocks only
    - Zoom in far enough → readable text with connection details

13. **Manual authoring**
    - In perspective view: select text in center, select text in neighbor,
      create link directly (no need to exit to LinkCreator wizard)

### Phase 4: Trail overlay (future)

A trail is a curated reading path through specific passages across documents
(Bush's Memex concept). In the perspective view, a trail is visualized as a
highlighted route through the connection lines.

14. **Trail visualization in perspective view**
    - Trail connections rendered bright/thick with sequential numbers (1->2->3)
    - Non-trail connections dimmed to 20% opacity
    - Next/Previous buttons guide reader along the path
    - Trail overlay can be toggled on/off without leaving perspective view

15. **Passage-level trails** (extends existing TrailsPanel)
    - Current trails are document-level ("visit doc A, then doc B")
    - Extend to passage-level: each stop includes a text span + link ID
    - When viewing a trail, the perspective auto-centers on each passage
    - Shared trails become guided tours through the docuverse

16. **Same-document trails**
    - A trail within a single document traces an argument's structure
    - Perspective view shows the same document in center, with trail stops
      as numbered markers in the margin
    - User sees the whole argument shape at a glance

## Trail Concept

Trails are optional curated paths through the connection graph. They layer
ON TOP of the perspective view without changing the underlying layout:

```
Without trail:               With trail overlay:
                             
  D3 ----link---- D1           D3 ====1==== D1
       \                        \    (dim)
        link                      \--
         \                           2
          D2                        D2
                             
All connections equal         Trail path highlighted + numbered
```

Trail data model (extends existing TrailPayload):
```typescript
interface TrailStop {
  work_id: number;       // existing
  note?: string;         // existing
  // New fields for passage-level trails:
  link_id?: number;      // which link connects to the next stop
  char_start?: number;   // passage start in this work
  char_end?: number;     // passage end in this work
}
```

This is backward-compatible: existing document-level trails have undefined
link_id/char_start/char_end, and the perspective view just highlights stops
without passage-level precision.

## Data Flow

```
User clicks "Perspective" button for work W
  |
  +-- 1. Discover neighbors:
  |     linkListForWork(W) + findBacklinks(W)
  |     -> rank works by connection count
  |     -> take top 4-8 as neighbors
  |
  +-- 2. Load neighbor text:
  |     for each neighbor N: fetch work text (read-only GET)
  |     (can use public API or crdt_sync_open in read-only mode)
  |
  +-- 3. Load links between center and each neighbor:
  |     for each neighbor N: linkListForWork(W) filtered to links touching N
  |
  +-- 4. Render:
  |     center column: full-size text with link spans
  |     neighbor columns: scaled text with link spans
  |     canvas overlay: bezier connections between matching spans
  |
  +-- 5. On interaction:
        scroll -> redraw connections (rAF throttled)
        click connection -> side-by-side view
        click neighbor -> re-center
        zoom -> adjust scales
```

## Existing Code to Reuse

| Component | Location | What it provides |
|---|---|---|
| `linkListForWork` | `crdt_sync.ts` | Links for neighbor discovery + span data |
| `findBacklinks` | `crdt_sync.ts` | Backlinks for neighbor discovery |
| `CompareSplitView` | `ComparePanel.tsx` | Side-by-side comparison (target for zoom-in) |
| `BRIDGE_COLORS` | `ComparePanel.tsx` | Color palette for connection lines |
| `LINK_TYPE_STYLES` | `CollaborativeEditor.tsx` | Dash patterns per link type |
| `escapeHtml` | `ComparePanel.tsx` | HTML escaping for text rendering |
| `find_shared_regions` | `server.rs:9644` | Content match (Phase 3 only) |

## Performance Notes

OpenXanadu handles large documents with these techniques:
- CSS transforms (GPU-composited, no layout cost)
- `position: absolute` for all columns (no reflow on scroll)
- Canvas redraw on scroll throttled to rAF
- Hidden documents moved off-screen (not removed from DOM)

We should use the same approach. If performance is an issue with many
columns:
- Virtualize: only render columns that are visible
- Debounce canvas redraw (OpenXanadu draws on every scroll, which works
  because modern browsers handle it well)
- Consider `will-change: transform` on columns for GPU hint

## Comparison with OpenXanadu

| Aspect | OpenXanadu | Xudanu (planned) |
|---|---|---|
| Scaling | CSS `transform: scale()` | Same |
| Connection rendering | Canvas bezier paths | Same |
| Span markers | DOM `<span>` elements | Same |
| Scrolling | Independent per column | Same |
| View modes | 3 (Lonesome/Stub/All) hidden behind Shift+Space | 3 modes with visible buttons |
| Navigation | Click canvas line (no affordance) | Click line (hover highlight) + click colored block |
| Zoom | Hidden keyboard shortcut | Visible buttons + scroll wheel |
| Connection types | Single type (transclusion) | 5 typed links with distinct dash patterns |
| Authoring | External EDL files | In-app link creation (Phase 3) |
| Content matching | No | Optional Phase 3 layer |
| Data source | Static text files fetched by URL | Live CRDT-backed documents |
| Collaboration | No | Real-time (future) |
