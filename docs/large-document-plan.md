# Xudanu Large Document Support Plan

## Document Information
- **Version**: 1.0
- **Date**: 2026-05-28
- **Branch**: `o-tree-merge`
- **Status**: Planning

---

## 1. Executive Summary

Xudanu currently loads entire documents as single strings over a WebSocket, renders them in a single `contentEditable` div, and re-broadcasts full text on every keystroke. This plan adds incremental loading, virtualized rendering, in-document search, and structured edition ("spaces") support in five phases over the `o-tree-merge` branch.

---

## 2. Current Architecture Constraints

### Server
- `Edition::to_text()` is O(N log N) -- iterates all positions with per-position splay-tree fetch
- Called on every CRDT open and on every edit broadcast
- Single `Mutex<Server>` guards all state -- text materialization blocks all sessions
- Delta relay re-materializes full text after every edit, sends to all peers

### Wire Protocol
- `crdt_sync_open` response contains full text as one JSON string field
- `CrdtTextUpdate` event sends full text to each subscriber per edit
- No chunking, no streaming, no range reads

### Frontend
- Entire document rendered in one `contentEditable` div
- `getTextContent()` walks all DOM nodes on every keystroke
- Attribution overlay creates one Range per span (already optimized from per-character)
- No in-document search
- No virtualization

### Edition Model
- `RangeElement::Edition { edition_id }` exists but is not rendered or editable
- `Path::follow_with_resolver()` already navigates nested editions
- `EditionResolver` trait resolves edition IDs
- No server API to insert or edit nested editions

---

## 3. Phase 1: Server-Side Text Cache + Delta Relay

**Goal**: Eliminate the two biggest bottlenecks -- full text re-materialization and full text broadcast -- with no frontend changes.

**Estimated effort**: 1-2 days

### 1a. Cache `to_text()` Result

**File**: `src/server/otree_crdt.rs`

Add a `cached_text: Option<String>` field to the per-document CRDT state struct.

```rust
struct OtreeDoc {
    current_edition: Edition,
    base_edition: Edition,
    cached_text: Option<String>,    // NEW
    // ...
}
```

- Set on first `to_text()` call
- Invalidate (set to `None`) on any edit (`apply_text_delta`)
- `current_text()` returns cached value or materializes + caches
- Impact: O(N log N) on first read, O(1) on subsequent reads until next edit

### 1b. Relay Deltas Instead of Full Text

**File**: `src/server/transport/dispatch.rs` -- `WorkReviseDelta` handler

Current flow:
1. Apply delta to edition
2. Call `crdt_current_text()` -- O(N log N) re-materialization
3. Send full text to each subscriber

New flow:
1. Apply delta to edition
2. Forward the same delta ops to other subscribers via new event `CrdtTextDelta { work_id, ops, author }`
3. Subscribers apply delta locally
4. Only send full text on session open or reconnection

**New event**: `CrdtTextDelta`
```rust
EventPayload::CrdtTextDelta {
    work_id: BeId,
    ops: Vec<TextDeltaOp>,
    author_session: Option<SessionId>,
}
```

**Frontend handler** (in `crdt_sync.ts`):
- Receive `crdt_text_delta` event
- Apply ops to local `this.text` string (retain/delete/insert logic already exists in `applyTextDelta`)
- Fire text listeners

**Fallback**: On any error or desync, send `crdt_sync_full_state` to re-sync.

### 1c. Move Heavy Work Outside Mutex

**File**: `src/server/transport/shared.rs`

Pattern: snapshot under mutex, process outside.
```rust
let snapshot = state.server.with_server(|srv| {
    srv.snapshot_for_text_read(work_id)  // Arc<Edition> clone
});
let text = snapshot.to_text();  // Outside mutex
```

This prevents text materialization from blocking all other sessions.

### Success Criteria
- `to_text()` called at most once per edit cycle (not once per subscriber)
- Wire traffic per keystroke drops from O(document_size * subscribers) to O(delta_size * subscribers)
- Server mutex hold time during edits reduced to O(delta_application) only

---

## 4. Phase 2: Incremental Loading

**Goal**: Load documents in chunks so the browser never freezes on large documents.

**Estimated effort**: 2-3 days

### 2a. Chunked Open Protocol

**New opcode**: `crdt_sync_open_streaming`

**Request**: `{ work_id }` (same as before)

**Response**: `{ total_chars, chunk_size, first_chunk }` -- metadata + first 64KB of text

**Follow-up events** (server to client):
```
crdt_text_chunk { offset: 65536, text: "...", seq: 1 }
crdt_text_chunk { offset: 131072, text: "...", seq: 2, final: true }
```

**Server side**: `to_text_range(start_char, end_char)` on Edition.

### 2b. Server-Side Range Read

**File**: `src/edition/edition.rs`

Add method:
```rust
pub fn to_text_range(&self, start_char: usize, end_char: usize) -> String
```

Implementation:
1. Build cumulative char offsets from `all_entries()` (or use cached entry list)
2. Binary search for the entry containing `start_char`
3. Iterate entries from that point, collecting text until `end_char`
4. O(K log N) where K = entries in range, N = total entries

For batched editions: ~15,000 entries for 1MB, binary search finds the start in O(log 15000) = ~14 steps.

### 2c. Progressive Frontend Rendering

**File**: `src/components/CollaborativeEditor.tsx`

- As chunks arrive, append to in-memory text buffer
- Render visible portion immediately
- Show loading indicator at top/bottom for unloaded portions
- Document becomes editable once all chunks received

### Success Criteria
- Documents up to 10MB load without browser freeze
- Visible text renders within 200ms of open
- User sees progress indicator during load

---

## 5. Phase 3: Virtualized Editor

**Goal**: Only render visible text in the DOM, regardless of document size.

**Estimated effort**: 3-5 days

### Decision Point: CodeMirror 6 vs Custom

Before implementing Phase 3, we need to make an editor choice. Research findings:

| Aspect | CodeMirror 6 | Custom Virtual Scroll |
|--------|-------------|----------------------|
| Virtual rendering | Built-in | Must build from scratch |
| Large doc performance | Excellent (rope data structure) | Depends on implementation |
| Collaborative editing | Built-in OT + Yjs support | Must wire manually |
| Per-char attribution | Decoration system | Canvas overlay (current approach) |
| Structured documents | Flat text model -- nested regions are widgets only | Full control -- can build any model |
| Search | Built-in | Must build |
| Migration effort | Moderate (paradigm shift) | Low (extend current code) |
| Licensing | MIT | N/A |
| Risk for Phase 5 (spaces) | High -- nested docs fight the flat model | Low -- full control |

**Recommendation**: Build a custom virtual scroll for now. It's lower risk, extends the current architecture, and preserves full control for structured documents (Phase 5). If performance becomes an issue, we can migrate specific components to CM6 later.

### 3a. Virtual Scroll Architecture

**Core concept**: Maintain full text in JS memory. Only render visible lines in the DOM.

```
+---------------------------+
|  Spacer div (height X)    |  <- represents lines above viewport
+---------------------------+
|  Visible contentEditable  |  <- ~40-80 lines, actual DOM nodes
+---------------------------+
|  Spacer div (height Y)    |  <- represents lines below viewport
+---------------------------+
```

**Components**:
1. **TextBuffer**: In-memory string with line-offset index. O(1) line lookup.
2. **VirtualScroller**: Tracks scroll position, calculates visible line range.
3. **VisibleEditor**: contentEditable div for the visible ~80 lines only.
4. **ScrollContainer**: Outer div with spacer elements for scrollbar accuracy.

**TextBuffer** (new class in `src/api/text_buffer.ts`):
```typescript
class TextBuffer {
    text: string;
    lineOffsets: number[];  // char offset of each line start

    constructor(text: string) { /* ... */ }
    getLine(index: number): string
    getLineCount(): number
    getCharOffset(line: number): number
    getLineForChar(charOffset: number): number
    applyDelta(ops: TextDeltaOp[]): void  // update in-memory text
    getTextRange(startChar: number, endChar: number): string
}
```

### 3b. Scroll Synchronization

- Listen to scroll events on the container
- Calculate which lines are visible: `firstLine = scrollOffset / lineHeight`, `lastLine = firstLine + viewportLines`
- Update visible editor content on scroll (debounced via rAF)
- Preserve cursor position during scroll updates
- Preserve scroll position during external text updates (deltas from other users)

### 3c. Delta Application to TextBuffer

When a delta arrives (from local edit or remote):
1. Apply to TextBuffer in memory -- O(delta_size)
2. Update line offsets (rebuild affected portion)
3. If visible lines changed, re-render visible portion
4. Do NOT walk DOM to extract text -- use TextBuffer as source of truth

### Success Criteria
- Documents of any size render at constant memory/CPU
- Scroll is smooth (60fps)
- Typing latency < 16ms (one frame)
- Memory usage bounded by viewport size, not document size

---

## 6. Phase 4: Navigation + Search

**Goal**: Find and move around within large documents.

**Estimated effort**: 2-3 days

### 4a. Document Outline

**Server side**: Extract structure from edition entries.

The edition already has entries. Lines matching heading patterns can be extracted:
```
# Title          -> H1
## Section       -> H2
Chapter 1:       -> Chapter heading
```

Or use `RangeElement::Label` boundaries as explicit section markers.

**API**: New opcode `work_outline` returning `Vec<OutlineEntry { char_offset, level, text }>`.

**Frontend**: Sidebar panel showing clickable outline tree. Click scrolls to position.

### 4b. In-Document Search

**Client-side** (for loaded text):
- Search the TextBuffer in memory -- instant for any loaded portion
- Highlight matches with CM6-style decorations or canvas overlay
- Navigate next/previous with keyboard shortcuts (Ctrl+G / Ctrl+Shift+G)
- Show match count and current match index

**Server-side** (for partially loaded text):
- Extend `find_text_transcluders` (already exists at `server.rs:3300`) for within-document search
- New opcode: `work_search { work_id, query, max_results }` returning `Vec<SearchResult { char_offset, context }>`
- Load context around matches on demand

### 4c. Jump-to-Position Navigation

**URL fragments**: `?work=42#L1204` (line) or `?work=42#C58321` (character)

**API**: `work_goto { work_id, line?, char? }` returns context around the position.

**Scroll-to**: On load or navigation, scroll the virtual editor to the target line/character.

### Success Criteria
- Search is instant for loaded text, < 500ms for server-side search
- Outline renders for any document
- Jump-to-position works with URL sharing

---

## 7. Phase 5: Structured Editions / Spaces

**Goal**: Support nested, navigable, independently editable sub-documents.

**Estimated effort**: 5-10 days

### Research Summary

The codebase already has the foundation:

| Component | Status | Location |
|-----------|--------|----------|
| `RangeElement::Edition { edition_id }` | Implemented, not rendered | `range_element.rs:22` |
| `Path::follow_with_resolver()` | Implemented | `links.rs:141` |
| `EditionResolver` trait | Implemented | `links.rs` |
| `CrossSpace2` / `SequenceSpace` | Implemented | `space/cross.rs`, `space/sequence.rs` |
| Space-aware delta protocol | Not implemented | -- |
| Nested rendering | Not implemented | -- |
| Nested editing | Not implemented | -- |

### Recommended Model: Independent CRDT Sessions Per Space

Each space is a separate Work with its own CRDT session. Benefits:
- Aligns with existing per-Work CRDT management
- No changes to delta protocol (same ops, different work_id)
- Sub-documents can be independently shared, permissioned, federated
- Provenance tracking works per sub-document
- No changes to three-way merge logic

The parent document contains `RangeElement::Edition` elements as "embed slots." When the user navigates into a space, the UI switches to a different CRDT session (different work_id).

### 5a. Rendering Nested Editions (Read-Only First)

**Detection**: When iterating edition entries, detect `RangeElement::Edition` elements.

**Rendering options**:
1. **Collapsed**: Show `[Chapter 1 - click to expand]` placeholder
2. **Inline**: Render sub-edition content with visual boundary (border, indentation)
3. **Navigation**: Click opens sub-document as the active editing context

**Frontend**: The virtual editor's TextBuffer treats `RangeElement::Edition` entries as special markers. When rendering, they become expandable/collapsible regions.

### 5b. Space Navigation

**Breadcrumb bar**: `Document > Chapter 3 > Section 3.2`

Each step is a work_id with a path. Navigation stack:
```
[
  { work_id: 42, char_offset: 580 },
  { work_id: 100, char_offset: 0 },   <- entered Chapter 3
  { work_id: 207, char_offset: 0 },   <- entered Section 3.2
]
```

Back button pops the stack and restores the previous CRDT session.

**URL support**: `?work=42&space=100&space=207#L15` -- deep link into nested space.

### 5c. Space-Aware Editing

When the user types inside a space:
1. Delta is sent with the active space's `work_id`
2. Server applies to that work's CRDT session
3. Other subscribers to that space receive the delta
4. Parent document is unaffected

When the user modifies the parent (e.g., reorder spaces):
1. Delta operates on the parent edition
2. `RangeElement::Edition` entries are atomic units -- moved, inserted, deleted as whole blocks
3. Child works are not modified

### 5d. Server API Additions

**New opcodes**:
- `work_insert_space { parent_work_id, position, child_work_id }` -- inserts a RangeElement::Edition at position
- `work_list_spaces { work_id }` -- returns child edition IDs embedded in a work
- `work_outline { work_id }` -- returns structured outline with space boundaries

### Success Criteria
- Nested editions render as expandable regions
- Clicking into a space switches CRDT session
- Each space has independent attribution and edit history
- Breadcrumb navigation works
- Cross-space transclusion queries work

---

## 8. Implementation Timeline

| Phase | Description | Effort | Dependencies |
|-------|-------------|--------|-------------|
| **1a** | Cache `to_text()` | 0.5 day | None |
| **1b** | Delta relay | 1 day | None |
| **1c** | Mutex optimization | 0.5 day | None |
| **2a** | Chunked open protocol | 1 day | 1a |
| **2b** | Server range reads | 1 day | None |
| **2c** | Progressive frontend rendering | 1 day | 2a, 2b |
| **3a** | TextBuffer + virtual scroll | 2 days | 2c |
| **3b** | Scroll sync + cursor preservation | 1 day | 3a |
| **3c** | Delta application to TextBuffer | 1 day | 3a |
| **4a** | Document outline | 1 day | 3a |
| **4b** | In-document search | 1 day | 3a |
| **4c** | Jump-to-position navigation | 0.5 day | 3a, 4a |
| **5a** | Nested edition rendering | 2 days | 3a, Phase 4 |
| **5b** | Space navigation | 2 days | 5a |
| **5c** | Space-aware editing | 3 days | 5b |
| **5d** | Server API for spaces | 2 days | 5a |

**Total estimate**: 20-25 days of focused work

---

## 9. Risks and Open Questions

### Risks
1. **Virtual scroll + contentEditable**: contentEditable wasn't designed for virtual rendering. Cursor position preservation across scroll updates is tricky. Mitigation: only the visible ~80 lines are contentEditable; the rest is invisible.
2. **Delta relay desync**: If a client misses a delta, the text diverges. Mitigation: periodic checksum verification + full text re-sync fallback.
3. **Editor choice lock-in**: If we build a custom virtual scroll and later need CM6 features, migration is expensive. Mitigation: keep the TextBuffer as a separate abstraction so the rendering layer can be swapped.

### Open Questions
1. **Line height calculation**: Virtual scroll needs accurate line height. Variable-width fonts + wrapping make this non-trivial. May need measurement-based approach.
2. **Collaborative cursor display**: Phase 1b delta relay should include cursor position for other users. Current awareness system (`crdt_awareness`) may need to be updated.
3. **Spaces granularity**: Should every paragraph/section be a separate space, or only top-level chapters? Too fine-grained = too many CRDT sessions. Too coarse = no benefit.
4. **ProseMirror vs custom**: If Phase 5 reveals that a hierarchical document model is essential, ProseMirror (not CodeMirror) would be the better library choice. We should evaluate this during Phase 5 design.

---

## 10. Quick Wins for Tomorrow

Start with these immediately -- no design decisions needed:

1. **`to_text()` caching** -- add `cached_text: Option<String>` to OtreeDoc, ~20 lines of Rust
2. **Delta relay** -- change `WorkReviseDelta` handler to forward ops instead of full text, ~50 lines of Rust + ~30 lines TypeScript
3. **Mutex optimization** -- snapshot edition under mutex, process outside, ~30 lines of Rust

These three changes eliminate the worst bottlenecks without any frontend architecture changes.
