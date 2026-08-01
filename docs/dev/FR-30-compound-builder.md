# FR-30: Professional Compound Builder

## Status: Planning

## Motivation

The Compound Builder is Xudanu's tool for assembling documents from
transcluded passages across multiple source works. The current implementation
provides basic functionality (add sources, select text, include passages,
export EDL) but lacks the polish and capability needed for professional use.

Roger Gregory and other Xanadu veterans will evaluate transclusion by its
**utility for building documents**, not just its technical correctness. The
Compound Builder is where that utility is demonstrated.

## Current State

- Three-panel layout: Source Pool (left), Compound Document (center), Structure (right)
- Add sources from work list dropdown
- Select text in source → "Include passage" → places transclusion inline
- Colored transclusion spans in compound document
- Structure outline showing original vs transclusion sections
- Export as EDL (Edit Decision List) JSON
- Full-screen overlay (dark theme only)

## Limitations

1. **No drag-and-drop** — can't reorder sections by dragging
2. **No inline editing** — can't write original text between transclusions
3. **No search** — can't search within source documents
4. **No preview** — no "what will this look like?" before placing
5. **No undo** — placing is immediate, no undo within builder
6. **No keyboard shortcuts** — all mouse-driven
7. **No template/starter** — starts empty, new users don't know what to do
8. **Single placement mode** — no inline vs block choice
9. **No source preview thumbnails** — sources are text-only
10. **No mobile/responsive layout**
11. **Dark theme only** — doesn't respect user's theme preference
12. **10M char source limit** — large sources not paginated

## Proposed Features

### Phase 1: Core UX Improvements (1-2 weeks)

#### 1.1 Guided Onboarding
- First-time users see a welcome panel: "Select a source document from the
  list, then highlight text and click 'Include passage' to build your
  compound document."
- Empty state with example workflow illustration
- "Try a demo" button that loads sample sources

#### 1.2 Inline Text Editing
- The compound document area is editable (contentEditable)
- Users can type original text between transclusion blocks
- Transclusion blocks remain non-editable (contenteditable=false)
- Keyboard: Enter creates new paragraph, Backspace at start of transclusion
  offers to remove it

#### 1.3 Drag-and-Drop Reordering
- Each section in the structure panel is draggable
- Drag a transclusion block to reposition it within the document
- Visual drop indicators (blue line between sections)
- Original text flows around repositioned blocks

#### 1.4 Search Within Sources
- Search bar above the source text panel
- Highlights matching passages in the active source
- "Include all matches" option for batch transclusion

#### 1.5 Placement Mode Toggle
- Inline (default for short passages) — places within paragraph flow
- Block (default for long passages or multi-line) — places on its own line
- Auto-detect: passages with newlines or >100 chars default to block
- Toggle in the "Include passage" button area

#### 1.6 Undo/Redo Within Builder
- Cmd/Ctrl+Z undoes last placement
- Cmd/Ctrl+Shift+Z redoes
- Undo stack persists for the builder session
- Visual undo/redo buttons in toolbar

### Phase 2: Professional Features (2-3 weeks)

#### 2.1 Multi-Source Comparison View
- Split-screen mode showing two sources side-by-side
- Shared scroll for comparison
- Highlight overlapping content between sources
- "Include from both" merge action

#### 2.2 Bridge Visualization
- Visual connection lines between source passages and compound sections
- Hover a source passage → corresponding compound section highlights
- Hover a compound section → source passage scrolls into view
- Color-coded per source work

#### 2.3 Version-Aware Transclusion
- When placing from a source, show its revision count
- Option to pin to current revision (FR-26 Phase 2)
- Warning badge if source was edited after placement
- "Update to latest" action to refresh transclusion content

#### 2.4 Section Templates
- Pre-built document structures: "Essay", "Anthology", "Literature Review",
  "Annotated Bibliography"
- Templates pre-populate placeholder sections with instructions
- Users fill in by selecting sources and including passages

#### 2.5 Outline Navigation
- Clickable structure panel — jump to any section
- Collapse/expand sections in the compound view
- Section numbering and automatic heading detection
- Export outline as Markdown table of contents

#### 2.6 Batch Operations
- Select multiple passages from a source (Shift+click)
- "Include all" button for batch placement
- Drag multiple selections to compound document
- Bulk re-apply placement mode (inline/block) to selected sections

### Phase 3: Advanced Capabilities (3-4 weeks)

#### 3.1 Nested Compound Documents
- A compound document can be a source for another compound
- Recursive transclusion resolution (already supported server-side)
- Visual depth indicator in the structure panel
- Provenance chain display per section

#### 3.2 Collaborative Building
- Multiple users editing the same compound document simultaneously
- Real-time cursor positions and selections from collaborators
- Conflict-free merging (CRDT handles this)
- "Who placed this?" attribution on each section

#### 3.3 Export Formats
- **EDL JSON** (current) — machine-readable edit decision list
- **Markdown** — with transclusion markers as blockquotes with source links
- **HTML** — with styled transclusion spans and source tooltips
- **PDF** — print-ready with proper attribution footnotes
- **Xanadu tumblers** — full tumbler addresses for each transclusion

#### 3.4 Source Recommendations
- "Works that share content with your current sources" suggestions
- Content-similarity-based recommendations (Jaccard index)
- Backfollow index: "These works also transclude from your sources"
- Visual graph of source relationships

#### 3.5 Responsive Layout
- Desktop: three-panel (source | compound | structure)
- Tablet: two-panel with tabbed structure/source
- Mobile: single-panel with swipe navigation
- Touch-friendly source selection and placement

## Technical Considerations

### Performance
- Source text loading should be paginated (load first 10K chars, lazy load rest)
- Compound document rendering should handle 100+ transclusion spans
- Virtual scrolling for large compound documents
- Debounced text selection handling

### Data Model
- Compound elements are `RangeElement::Transclusion` in the O-tree CRDT
- Compound state is loaded via `resolveInlineTransclusions`
- Placement uses `elementInsert` wire operation
- No separate "compound" data structure — it's inline in the edition

### Theme Support
- Respect user's theme preference (dark/light/palette)
- Use CSS variables from theme.css
- Compound document area always has white/light background for readability

### Accessibility
- Keyboard navigation between panels (Tab/Shift+Tab)
- Screen reader announcements for placement actions
- ARIA labels on all interactive elements
- High contrast mode support

## Success Criteria

- [ ] New user can build a compound document within 2 minutes of first use
- [ ] Professional user can assemble a 20+ section document efficiently
- [ ] Compound documents render correctly with 100+ transclusion spans
- [ ] Export produces valid output in at least 3 formats
- [ ] Works on tablet (iPad) with touch input
- [ ] Theme-aware (not dark-only)
- [ ] Keyboard shortcuts for all primary actions

## Dependencies

- FR-26 (Content-Addressed Transclusion) — hash verification, version pinning
- FR-11 (Compound Documents) — inline transclusion resolution
- FR-27 (Link Filtering) — filter connections by type
- FR-25 (Trail Links) — curated document trails from compound sections

## References

- Current implementation: `web/app/src/components/CompoundBuilder.tsx`
- Server-side: `src/server/server.rs::resolve_inline_transclusions()`
- Wire protocol: `SpanRangePayload` in `src/server/transport/protocol.rs`
- Gold parallel: `winfe/stage/` compound/variant editing (Win32 MDI)
