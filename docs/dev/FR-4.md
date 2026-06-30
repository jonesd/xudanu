# FR-4: Typed Bidirectional Content Links

- **ID:** FR-4
- **Status:** Draft
- **Date:** 2026-06-30
- **Owner:** frontend
- **Depends on:** Link data model (phases 7–8, already merged), transclusion UI (phase H, already merged), CollaborativeEditor canvas overlay.

## 1. Overview

Nelson's content links are one of the defining features of Xanadu: **typed, profuse, bidirectional, and unbreakable** connections between specific passages in different documents. Unlike transclusion (which shows *the same* content in multiple places), links connect *different* content with a typed relationship — a comment, a reference, a disagreement, a quotation.

The data model is complete and merged: `HyperLink` with typed `link_types`, span migration (links survive edits), `LinkTypeRegister`/`LinkSetTypes` wire ops, and `findBacklinks` on both server and client. What does **not** exist is the frontend UI to create, visualize, and navigate these links from within the document.

> "A link can apply to any content, wherever the content may be re-used."
> "Thousands of overlapping links on the same body of content, created without coordination by many users around the world."
> — Ted Nelson, "Xanalogical Structure"

## 2. Goals / Non-goals

**Goals**
- Users can create typed links between specific text passages in different documents.
- Link endpoints are visible in the document body as styled markers (colour-coded by type).
- Links are bidirectional: clicking an incoming-link marker navigates to the source.
- Multiple overlapping links in the same region are displayed clearly.
- All link creation and visualization works within the existing `AppShell` + `CollaborativeEditor` architecture.

**Non-goals (for v1)**
- Transpointing windows (synchronized multi-pane link view — see #59).
- Link versioning UI (showing how links looked in past editions — the data survives, but no viewer).
- Federated link creation (links between documents on different federation peers — the data model supports it, but no cross-peer selection UX).
- Rich-text DOM `<a>` elements inside the contentEditable (links remain canvas-painted markers, consistent with transclusion markers).

## 3. Current state — what's already there

### Backend (DONE)
- `HyperLink` with `origin_ref` / `destination_ref` (each a `HyperRef` with span positions).
- `link_types: Vec<u64>` — typed links.
- Wire ops: `LinkCreate` (0x0706), `LinkAddEnd` (0x0707), `LinkRemoveEnd` (0x0708), `LinkSetTypes` (0x0709), `LinkTypeRegister` (0x070A), `LinkTypeList` (0x070B).
- Span migration: links survive version changes (positions tracked through edits).
- `WorkBacklinks` op: returns `BacklinkEntry[]` for incoming links.
- Persistence: links in manifest `links_hash` chunk + dual-slot round-trip.

### Frontend — active in `AppShell` (PARTIAL)
- `useTransclusion` hook: `loadLinks`, `deleteLink`, `linkCreate` — but `linkCreate` is hardcoded to `kind: "single"` excerpt transclusion. No link-type selection.
- `CollaborativeEditor` canvas overlay (`drawOverlay`): paints **transclusion** margin markers (coloured bars + provenance stacking). No link-type markers.
- `ConnectionsSection` (ContextPanel): lists transclusion spans + existing links, with pinning/filter. Declares `"backlink"` type but **never populates it**.
- `CrdtSyncClient.findBacklinks(workId)`: fully implemented, returns `BacklinkEntry[]`. **Never called** from the active UI.
- `CrdtSyncClient.linkCreate`: takes `origin`, `destination`, `origin_ref?`, `destination_ref?` — the parameters for typed span links exist but are unused.

### Frontend — dead code (orphaned `WorkspacePage.tsx`)
- `renderLinkItem` with outgoing/incoming split and delete buttons.
- `findBacklinks` → "Referenced by (N)" sidebar.
- `DocumentMapPanel` graph view.
- These are not wired into `AppShell` and serve as reference implementations.

### What is NOT built
- No link creation UI (select text → choose type → select target → create).
- No link type selector or palette.
- No link overlay markers in the document body (only transclusion markers exist).
- No type-based styling (colour/style by link type).
- No bidirectional link navigation from within the document body.
- No profuse overlapping link display.
- No backlinks display in the active UI.

## 4. Nelson's two-connection model

Xudanu implements Nelson's fundamental distinction between two kinds of connections:

| | **Transclusion** | **Content Link** |
|---|---|---|
| **Connects** | The *same* content in multiple places | *Different* content with a typed relationship |
| **Example** | A quotation appears in 3 documents | A comment on a passage; a cross-reference |
| **Data** | `HyperLink` with matching content fingerprint | `HyperLink` with typed `link_types` |
| **UI today** | Margin markers, compound inline spans, placement badge | *(missing — this FR)* |
| **Survives edits** | Yes (span migration) | Yes (span migration) |

A single document can have both: transcluded content + links commenting on it. They are orthogonal systems that share the same `HyperLink` data model but serve different purposes.

## 5. Functional requirements

### FR-4.1 Link creation flow

**Two-part selection (the core UX challenge):**
Creating a link requires specifying two text ranges (source + target) in potentially different documents. The flow mirrors the existing transclusion hold-and-place pattern:

1. User selects text in document A → a **"Create Link"** action appears (alongside the existing "Transclude" button).
2. `holdLinkSelection()` stores the source range (work ID, start/end char offset, excerpt).
3. A **LinkBadge** appears (similar to `TransclusionBadge`): "Select target text to link".
4. User navigates to document B, selects target text.
5. A **link type palette** appears: Comment, Reference, Disagreement, Quotation, See Also (or custom registered types).
6. User picks a type → `client.linkCreate(origin_ref, destination_ref)` + `client.linkSetTypes(linkId, [typeId])`.
7. Link is created; markers appear in both documents on next render.

**Quick link variants:**
- **Quick comment:** Select text → type a comment in an inline field → creates a comment link (target = the typed comment as a new work or inline annotation).
- **Link to document:** Select text → "Link to…" → document picker (no target text selection needed, links to the whole document).

**Wire to existing ops:**
- `LinkCreate` with `origin_ref` (source span) and `destination_ref` (target span).
- `LinkSetTypes` to assign the chosen type.
- No new backend ops needed.

### FR-4.2 Link type system

- **Default types** (pre-registered at server startup or seeded by the client):
  - Comment (blue)
  - Reference (green)
  - Disagreement (red)
  - Quotation (purple)
  - See Also (amber)

- **Custom types:** Users can register new types via `LinkTypeRegister` (already implemented). The type palette reads from `LinkTypeList` and shows all registered types.

- **Type metadata:** Each type needs a display name, colour, and line-style (solid, dashed, dotted). This can be stored client-side (type ID → style mapping) or extended on the server via `LinkTypeRegister` metadata.

### FR-4.3 Link visualization in the document body

The `CollaborativeEditor` canvas overlay already paints transclusion markers. Link markers are a **new layer** in `drawOverlay()`:

- **Endpoint markers:** Small coloured brackets/dots at the start and end of each linked span, drawn on the canvas overlay.
- **Underline/overline styling:** A coloured line beneath (or above) the linked text, style determined by link type:
  - Comment: blue dashed
  - Reference: green solid
  - Disagreement: red underline
  - Quotation: purple dotted
  - See Also: amber dashed

- **Margin markers:** Similar to transclusion markers (left-margin coloured bars) but with link-type-specific colours and a distinct visual indicator (e.g. a small type icon or letter: C for Comment, R for Reference, D for Disagreement).

- **Hover tooltip:** Shows link type label, destination work title, excerpt preview, and a "Go to" button. Reuses the existing `marker-tooltip` pattern.

- **Click to navigate:** Single-click on an endpoint or margin marker → navigate to the linked document and scroll to the target span.

- **Hit zones:** Each marker registers a `MarkerHitZone` in the existing hit-test system (same pattern as transclusion markers).

### FR-4.4 Bidirectional display (backlinks)

Links are bidirectional in the data model. The UI must show both directions:

- **Outgoing links** (this document links to others): shown as endpoint markers + margin markers in the document body (FR-4.3).

- **Incoming links** (other documents link into this one): shown as **right-margin markers** (distinct from left-margin outgoing markers). Calling `findBacklinks(workId)` on work switch populates these.

- **Backlinks in ContextPanel:** `ConnectionsSection` already declares a `"backlink"` type but never populates it. Wire `findBacklinks` results into the connections list with a distinct icon (← for incoming vs → for outgoing).

- **Backlink count badge:** Per-section or per-document indicator showing total incoming link count.

### FR-4.5 Profuse overlapping links

Nelson's vision includes "thousands of overlapping links on the same body of content." When multiple links cover the same text region:

- **Stacked margin markers:** Outgoing markers stack on the left margin (like transclusion provenance chains). Incoming markers stack on the right margin.
- **Layered underlines:** If two links overlap the same text, draw underlines at slightly different vertical offsets (1px apart) so both are visible.
- **Filter by type:** A dropdown in the ContextPanel or a floating control: "Show: All / Comments / References / Disagreements / …" Toggles marker visibility by type.
- **Density indicator:** When the link count in a region exceeds a threshold (e.g. 5+), show a summary marker ("5 links") instead of individual markers. Click to expand.

## 6. Relationship to existing systems

### Transclusion (compound documents)
Links and transclusions share the `HyperLink` data model but serve different purposes:
- **Transclusion** = same content shown in multiple places (copy).
- **Link** = different content connected by a typed relationship (reference).
- A document can have both. The canvas overlay already has layers for transclusion; link markers are an additional layer.
- The existing `useTransclusion` hook manages both links and transclusion data. A new `useContentLinks` hook (or extension of the existing hook) would manage typed links specifically.

### Annotations
Annotations are position-attached metadata (comments, labels). Links are connections between spans. They are complementary:
- An annotation says something *about* a position.
- A link connects a position to *another position*.

### CRDT collaborative editing
Link creation/visualization must work correctly during live multi-user editing:
- Span migration already handles position shifts from concurrent edits.
- New markers should be drawn from link data on each render cycle (not cached as DOM state).
- Link creation by one user should be visible to others (via the existing WS notification or CRDT sync).

## 7. Implementation details (frontend)

### New hook: `useContentLinks`

```
useContentLinks(workId) → {
  outgoingLinks: LinkMarker[],    // links from this work to others
  incomingLinks: BacklinkMarker[], // links from others into this work
  linkTypes: LinkTypeInfo[],       // registered types with display metadata
  createLink: (source, target, typeId) => Promise<void>,
  deleteLink: (linkId) => Promise<void>,
  linkTypeStyles: Map<u64, {color, lineStyle, label}>,
}
```

- `loadOutgoing`: calls `linkListForWork(workId)`, filters to typed links (excludes pure transclusion links).
- `loadIncoming`: calls `findBacklinks(workId)`.
- `loadTypes`: calls `LinkTypeList`, merges with client-side style defaults.
- `createLink`: calls `linkCreate` + `linkSetTypes`.

### Canvas overlay extensions

In `CollaborativeEditor.drawOverlay()`, add a new pass after transclusion markers:

```
// Pass 5: Content link markers
for (const link of outgoingLinks) {
  drawLinkUnderline(ctx, link, textBuffer, linkTypeStyles);
  drawLinkMarginMarker(ctx, link, 'left', linkTypeStyles);
}
for (const backlink of incomingLinks) {
  drawLinkMarginMarker(ctx, backlink, 'right', linkTypeStyles);
}
```

### LinkBadge component

Similar to `TransclusionBadge`, but for the link creation flow:
- Appears after `holdLinkSelection()`.
- Shows: source excerpt preview, "Select target text in another document" instruction.
- On target selection: shows link type palette.
- On type selection: calls `createLink()` and dismisses.

### Default link type styles (client-side)

| Type ID | Name | Colour | Line style | Margin icon |
|---------|------|--------|------------|-------------|
| 1 | Comment | `#58a6ff` (blue) | dashed | C |
| 2 | Reference | `#3fb950` (green) | solid | R |
| 3 | Disagreement | `#f85149` (red) | underline | D |
| 4 | Quotation | `#a371f7` (purple) | dotted | Q |
| 5 | See Also | `#d29922` (amber) | dashed | S |

Custom types registered via `LinkTypeRegister` get auto-assigned colours from a palette hash (same pattern as `markerColorForWork`).

## 8. What this unlocks

- **Scholarly annotation:** Comment links on specific passages that survive version changes (unlike browser annotations or margin notes).
- **Structured disagreement:** "Disagreement" links mark contested passages — readers see all sides.
- **Cross-reference networks:** "See Also" links create reading paths through a document corpus.
- **Collaborative review:** Multiple reviewers add overlapping typed links; filter by type to see different perspectives.
- **Legal/contract analysis:** Link specific clauses to commentary, case law, or counterarguments.
- **Federated linking:** Links between documents on different federation peers (data model supports it; cross-peer selection UX is a future enhancement).

## 9. Build order

Each step is independently useful and deployable. Steps 1-2 can be done in
parallel; step 3 depends on both.

### Step 1 — Backlinks display (FR-4.4)
**Goal:** Users see who links into their documents.

**Deliverables:**
- Call `findBacklinks(workId)` on work switch in `AppShell` (it's implemented in `CrdtSyncClient` but never called).
- Populate `ConnectionsSection` with backlink items (the `"backlink"` type is already declared but unused).
- Add right-margin markers in `CollaborativeEditor.drawOverlay()` for incoming links (mirror of the left-margin transclusion markers).
- Backlink count badge in the document header or ContextPanel.

**Touches:** `AppShell.tsx`, `ConnectionsSection.tsx`, `CollaborativeEditor.tsx`, `useTransclusion.ts` (or new `useContentLinks` hook).
**Backend:** None (all ops exist).
**Review:** Visual — check right-margin markers render and navigate correctly.

### Step 2 — Link creation flow (FR-4.1 + FR-4.2)
**Goal:** Users can create typed links between passages.

**Deliverables:**
- "Create Link" button alongside the existing "Transclude" button on text selection.
- `holdLinkSelection()` in a new `useContentLinks` hook (parallel to `holdSelection` in `useTransclusion`).
- `LinkBadge` component (parallel to `TransclusionBadge`): "Select target text to link".
- Link type palette: dropdown of default types (Comment, Reference, Disagreement, Quotation, See Also).
- On type selection: `client.linkCreate(origin_ref, destination_ref)` + `client.linkSetTypes(linkId, [typeId])`.
- Default link type styles table (colour + line style per type, client-side).

**Touches:** New `useContentLinks.ts` hook, new `LinkBadge.tsx`, `AppShell.tsx` (add button + badge), `crdt_sync.ts` (verify `linkCreate` params).
**Backend:** None (all ops exist).
**Review:** Visual — test the full flow: select source → badge → navigate → select target → pick type → verify link created.

### Step 3 — Link visualization (FR-4.3)
**Goal:** Link endpoints are visible in the document body with type-based styling.

**Deliverables:**
- New canvas overlay pass in `drawOverlay()`: link endpoint markers (coloured brackets/dots at span boundaries).
- Type-based underline styling (dashed/solid/dotted per type).
- Hover tooltip on link markers (type label, destination title, excerpt, "Go to" button).
- Click-to-navigate (reuse existing marker hit-zone system).
- Outgoing markers on left margin; incoming markers on right margin (from Step 1).

**Touches:** `CollaborativeEditor.tsx` (canvas overlay), `useContentLinks.ts` (marker computation).
**Review:** Visual — this is the key visual review step. Need to verify: colours, line styles, stacking, hover, navigation.

### Step 4 — Profuse overlapping links (FR-4.5)
**Goal:** Multiple links in the same region are clearly displayed.

**Deliverables:**
- Stacked margin markers (outgoing left, incoming right).
- Layered underlines for overlapping spans (1px vertical offset per link).
- Filter-by-type control in ContextPanel or floating toolbar.
- Density indicator ("5 links") for high-link regions.

**Touches:** `CollaborativeEditor.tsx`, `ConnectionsSection.tsx`, new filter control component.
**Review:** Visual — stress test with many overlapping links.

**Parallel work:** Custom link type registration UI (via existing `LinkTypeRegister` op) can be done anytime after Step 2.

## 10. Acceptance criteria

1. User can select text in document A, navigate to document B, select text, and create a typed link between them.
2. Link endpoints appear as coloured markers in the document body (left margin for outgoing, right margin for incoming).
3. Hovering a marker shows the link type, destination/source title, and excerpt preview.
4. Clicking a marker navigates to the linked document and scrolls to the target span.
5. `ConnectionsSection` shows incoming links (backlinks) with source work title and excerpt.
6. Multiple links in the same region are visually distinguishable (stacked or layered).
7. Links survive text edits (span migration — already tested at the backend level).
8. Creating a link as one user is visible to another user on the same work (live update).

## 11. Out of scope / future

- **Transpointing windows** (#59): synchronized multi-pane view where linked documents scroll together.
- **Link graph visualization**: interactive node-edge graph of the entire link network (exists as dead code in `DocumentMapPanel`).
- **Federated link creation**: selecting text on a remote peer's document as a link target. The data model and backend already support cross-peer links (`HyperRef` + `BeId` with server component, `federated_content_fetch`, `federated_transclusion_query`). What's missing is a cross-server document browser UI — a future story.
- **Link versioning viewer**: showing how links looked in past editions (data survives, no viewer).
- **Link-based micropayments**: royalty distribution based on link traversal (data model exists via `RoyaltyEntry`).
- **AI-assisted link suggestions**: suggest links between passages based on content similarity (the `content_watch` + Jaccard similarity infrastructure exists).

## 12. Related

- **Issue #60** — the original issue for this feature.
- **Issue #18** — compound documents (transclusion).
- **Issue #35** — collaborative editing (links must work during live editing).
- **Issue #59** — transpointing windows (future multi-pane link view).
- `docs/dev/phase-7-label-system.md` — label system (related position-attached metadata).
- `docs/dev/phase-8-transclusion-queries.md` — transclusion query infrastructure.
