# FR-25: Rich Text Editing (TipTap Integration)

> Replaces the contentEditable + manual innerHTML approach with
> TipTap (ProseMirror-based) for rich text editing. Adds headings,
> lists, blockquotes, code blocks, typography controls, and proper
> block-level formatting — while preserving the O-tree CRDT sync,
> transclusion rendering, and link overlays.

## Decision Question

How does Xudanu support rich text (headings, lists, blockquotes, code
blocks, typography) without rebuilding a fragile contentEditable
editor, while keeping the CRDT, transclusions, and custom rendering?

## Decision

**Use TipTap** (headless wrapper around ProseMirror) as the editing
surface, bridged to the existing O-tree CRDT via a serialization layer.

```
TipTap document tree  ←→  serializer  ←→  plain text + annotations (CRDT)
     (editing UX)                        (sync + storage)
```

The CRDT stays as-is (plain text + char-range annotations). TipTap
manages the editing surface. On every local edit, serialize to plain
text + annotations. On remote changes, deserialize back into TipTap.

## Why TipTap

| Requirement | TipTap | Status |
|---|---|---|
| Rich blocks (headings, lists, code) | 100+ extensions | Ready |
| Custom nodes (transclusions, images) | NodeView + React | Proven |
| Custom marks (links, annotations) | Mark API | Proven |
| Headless (we control UI) | Yes | Core design |
| MIT licensed | Yes | Compatible with Apache 2.0 |
| React 19 | @tiptap/react | Supported |
| CRDT bridge | Custom (~300 lines) | Documented pattern |
| Large documents (~100K chars) | Surgical DOM updates | Better than current innerHTML |

Alternatives considered: Lexical (Meta), Slate, Quill, CKEditor, Editor.js.
See "Editor comparison" appendix.

## What's Wrong Today

Current editing (contentEditable + innerHTML rebuild):
- Bold/italic work but are hacky — `buildStyledText` injects `<strong>`/`<em>` tags manually
- No block concept — can't do headings, lists, blockquotes, code blocks
- Every style change rebuilds entire innerHTML → cursor jumps, performance issues
- contentEditable behavior is browser-dependent and fragile
- Typography (font size, alignment, line spacing) not supported

## Architecture

### Layers

```
┌──────────────────────────────────────────┐
│           Toolbar (React)                │  ← our UI, unchanged
├──────────────────────────────────────────┤
│         TipTap Editor (React)            │  ← replaces contentEditable
│  ┌─────────┐ ┌──────────┐ ┌───────────┐ │
│  │ Doc tree│ │ Marks    │ │ NodeViews │ │
│  └─────────┘ └──────────┘ └───────────┘ │
├──────────────────────────────────────────┤
│        CRDT Bridge (~300 lines)          │  ← new: sync layer
├──────────────────────────────────────────┤
│     O-tree CRDT + Annotations            │  ← unchanged
│  (plain text + char-range marks)         │
├──────────────────────────────────────────┤
│        WebSocket / Server                │  ← unchanged
└──────────────────────────────────────────┘
```

### CRDT Bridge

The bridge translates between TipTap's document model and Xudanu's
flat text + annotations.

**Local edit → CRDT:**
1. TipTap emits a transaction (doc changed)
2. Bridge serializes the new doc to plain text
3. Bridge extracts block/inline marks as annotations (char ranges)
4. Bridge calls `setText(plainText)` + creates/updates/deletes annotations
5. CRDT syncs to server

**Remote edit → TipTap:**
1. CRDT receives new text from server
2. Bridge deserializes plain text + annotations into a TipTap document
3. Bridge applies the change as a TipTap transaction
4. TipTap updates the DOM surgically (no innerHTML rebuild)
5. Cursor position is preserved

**Key insight:** The text is always the source of truth. TipTap's
document is a *view* of the text + annotations, not a separate copy.

### Annotation mapping

Block and inline styles map to annotations with `kind` and `payload`:

| Style | Annotation kind | Payload | Scope |
|---|---|---|---|
| Bold | `bold` | `""` | Inline (char range) |
| Italic | `italic` | `""` | Inline (char range) |
| Code | `code` | `""` | Inline (char range) |
| Heading | `heading` | `{"level":1\|2\|3}` | Block (line range) |
| List item | `list_item` | `{"type":"bullet"\|"ordered"}` | Block (line range) |
| Blockquote | `blockquote` | `""` | Block (line range) |
| Code block | `code_block` | `{"language":"rust"}` | Block (line range) |
| Font size | `font_size` | `{"px":14}` | Inline (char range) |
| Text align | `text_align` | `{"align":"left"\|"center"\|"right"}` | Block (line range) |

Block annotations cover the character range from the start of the first
line to the end of the last line (including trailing newline). This
means span migration (which already works for bold/italic) handles
block annotations correctly for free.

### Transclusion rendering

Transclusions become a **custom TipTap NodeView**:
- `TransclusionNode` — an atomic node (no editable content inside)
- Renders the existing transclusion UI (purple bar, attribution text,
  click-to-navigate)
- Positioned in the document tree at the transclusion's char offset
- Not part of the plain text serialization (transclusions are
  `RangeElement::Transclusion` in the edition, not text)

### Link rendering

Links become a **custom TipTap Mark**:
- `LinkMark` — wraps a text range with link metadata
- Renders as the existing colored underline + description box
- Canvas overlay continues to draw the connecting lines

### Image rendering

Images become a **custom TipTap NodeView**:
- `ImageNode` — renders blob content from the blob store
- Supports the existing resize handle, crop, caption
- Positioned in the document tree at the blob's char offset

## Phases

### Phase 1: TipTap foundation (replace editing surface)

**Goal:** Replace contentEditable with TipTap, keeping current features
working (plain text editing, bold/italic).

- Install `@tiptap/react`, `@tiptap/pm`, `@tiptap/starter-kit`
- Create `TipTapEditor.tsx` replacing `CollaborativeEditor.tsx`
- Implement CRDT bridge (text ↔ annotations ↔ TipTap doc)
- Migrate bold/italic from custom annotations to TipTap marks
- Verify transclusion placement still works
- Verify cursor sync on remote edits

**Acceptance:** User can edit text, apply bold/italic, and CRDT sync
works. No regressions vs current editor.

### Phase 2: Block formatting

**Goal:** Add headings, lists, blockquotes, code blocks.

- Enable TipTap extensions: Heading, BulletList, OrderedList,
  ListItem, Blockquote, CodeBlock
- Implement block annotation serialization (line-range → annotation)
- Add block type dropdown to toolbar
- Markdown shortcuts (type `#`, `-`, `>`, `` ` `` at line start)
- Keyboard shortcuts (Ctrl+Alt+1/2/3 for headings)
- CSS for each block type

**Acceptance:** User can create headings, lists, blockquotes, and code
blocks. Styles persist through CRDT sync and server restart.

### Phase 3: Typography controls

**Goal:** Font size, text alignment, font family.

- Enable TipTap typography extensions (TextStyle, TextAlign,
  FontFamily — or custom)
- Add typography controls to toolbar (font size dropdown, alignment
  buttons, font family picker)
- Persist as annotations with JSON payload
- Reading mode applies typography

**Acceptance:** User can change font size, alignment, and family on
text ranges and blocks.

### Phase 4: Custom nodes (transclusions, images, links)

**Goal:** Migrate transclusion/image/link rendering to TipTap node views.

- `TransclusionNode` as TipTap NodeView (React component)
- `ImageNode` as TipTap NodeView (with resize/crop/caption)
- `LinkMark` as TipTap Mark (with canvas overlay)
- Remove old canvas overlay logic for link descriptions
- Remove old innerHTML-based transclusion rendering

**Acceptance:** Transclusions, images, and links render inside TipTap
with the same visual appearance and interaction as today.

### Phase 5: Polish

- Performance optimization for large documents
- Copy/paste handling (rich text clipboard)
- Drag and drop blocks
- Slash command menu (`/heading`, `/list`, `/code`)
- Print/PDF export

## Migration

**Backward compatible.** Existing documents (plain text + bold/italic
annotations) work unchanged. TipTap renders them as paragraphs with
inline marks. No data migration needed.

The old `CollaborativeEditor.tsx` is kept as fallback until Phase 4
is complete. A feature flag (`?editor=tiptap` URL param or settings)
allows switching between old and new editors during development.

## Dependencies

```json
"@tiptap/react": "^2.x",
"@tiptap/pm": "^2.x",
"@tiptap/starter-kit": "^2.x",
"@tiptap/extension-heading": "^2.x",
"@tiptap/extension-placeholder": "^2.x",
"@tiptap/extension-text-align": "^2.x",
"@tiptap/extensionTextStyle": "^2.x",
"@tiptap/extension-code-block-lowlight": "^2.x"
```

Bundle impact: ~50KB gzipped with common extensions.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| CRDT bridge cursor jump on remote edit | High | ProseMirror's transaction system preserves selection; test with concurrent edits |
| ProseMirror schema rejects legacy content | Medium | Define permissive schema; fallback to plain text on parse failure |
| React + ProseMirror DOM ownership conflict | Medium | Use NodeView API for React components; let ProseMirror own the editor div |
| Bundle size increase | Low | ~50KB gzipped; tree-shake unused extensions |
| TipTap breaking changes | Low | ProseMirror API stable since 2016; TipTap follows semver |
| Virtualized editor divergence | Low | Migrate VirtualizedEditor after Phase 1 |

## Files to Create

- `web/app/src/components/TipTapEditor.tsx` — new editor component
- `web/app/src/tiptap-bridge.ts` — CRDT bridge (serialize/deserialize)
- `web/app/src/tiptap-extensions/transclusion-node.tsx` — custom node
- `web/app/src/tiptap-extensions/image-node.tsx` — custom node
- `web/app/src/tiptap-extensions/link-mark.tsx` — custom mark

## Files to Modify

- `web/app/src/styled-text.ts` — deprecate (replaced by TipTap)
- `web/app/src/components/CollaborativeEditor.tsx` — keep as fallback
- `web/app/src/components/workspace/WorkspaceShell.tsx` — swap editor
- `web/app/src/hooks/useCrdtSync.ts` — add block annotation support
- `web/app/src/workspace.css` — add rich text CSS
- `web/app/package.json` — add TipTap dependencies

## Appendix: Editor Comparison

| Editor | Verdict | Reason |
|---|---|---|
| **TipTap** | **Chosen** | Mature, headless, huge extension ecosystem, proven custom nodes |
| Lexical | Strong runner-up | Designed for concurrent mutations, smaller bundle, but less mature |
| Slate | Rejected | 5+ major rewrites with breaking API changes |
| Quill 2 | Rejected | Flat delta model, no tree, not headless |
| CKEditor 5 | Rejected | GPL license incompatible with Apache 2.0 |
| Editor.js | Rejected | Block model doesn't fit continuous-text CRDT |
| ProseMirror (direct) | Rejected | Same as TipTap but more boilerplate |

## References

- TipTap docs: <https://tiptap.dev/docs/editor/introduction>
- ProseMirror docs: <https://prosemirror.net/docs/>
- Issue #93: Support rich text (headings, lists, blockquotes, code blocks)
- Current styling: `web/app/src/styled-text.ts`
- Current editor: `web/app/src/components/CollaborativeEditor.tsx`
- CRDT sync: `web/app/src/hooks/useCrdtSync.ts`
- O-tree annotations: `src/server/otree_crdt.rs` (span migration at line 651)
