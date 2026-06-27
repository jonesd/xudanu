# TipTap Migration Plan

## Goal

Replace the contentEditable div with TipTap (ProseMirror) as the document editor, while keeping our existing O-tree CRDT, wire protocol, and Rust backend untouched.

## Architecture: Philosophy B (Editor as View)

```
O-tree CRDT (Rust)           ← canonical truth, stays unchanged
    ↕ retain/insert/delete ↕
Flat text string              ← what gets synced
    ↕ bridge ↕
TipTap editor (React)         ← rendering + editing surface
    ↕ side channels ↕
Attribution, transclusions    ← overlays/decorations/custom nodes
```

The editor receives a flat text string + side channels. On edit, it produces a flat text string back. The CRDT diff (`sendTextDelta`) stays exactly as-is. **Zero backend changes.**

## Key Decisions

1. **Not Yjs** — Yjs is an opt-in TipTap extension we simply don't install
2. **Flat text remains source of truth** — editor.getText() diffed → sendTextDelta
3. **Keep canvas overlay initially** — it's DOM-agnostic, lowest risk
4. **Transclusion as custom NodeView** — replaces contenteditable=false spans
5. **TipTap History replaces custom undo** — remove undoStack/redoStack

## Phase 1: Basic TipTap Editor (Week 1)

### 1.1 Install Dependencies

```
npm install @tiptap/react @tiptap/starter-kit @tiptap/core @tiptap/pm
```

### 1.2 Minimal Editor Component

Create `TiptapEditor.tsx` alongside existing `CollaborativeEditor.tsx`:

```typescript
// Schema: single paragraph containing text (flat model)
// No headings, lists, or block quotes initially

import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";

function TiptapEditor({ text, onTextChange }: Props) {
  const editor = useEditor({
    extensions: [StarterKit.configure({ history: { depth: 200 } })],
    content: text,
    onUpdate: ({ editor }) => {
      const newText = editor.getText();
      onTextChange(newText);
    },
  });

  // Inbound: when `text` prop changes (remote CRDT delta), update editor
  useEffect(() => {
    if (!editor) return;
    const currentText = editor.getText();
    if (text !== currentText) {
      // Remote change — update editor content
      editor.commands.setContent(text);
    }
  }, [text, editor]);

  return <EditorContent editor={editor} />;
}
```

### 1.3 Wire to CRDT

| Direction | Current (contentEditable) | TipTap |
|-----------|--------------------------|--------|
| Outbound | `handleInput` → `getTextContent(el)` → `onTextChange` | `onUpdate` → `editor.getText()` → `onTextChange` |
| Inbound | `useEffect([displayText])` → `el.textContent = displayText` | `useEffect([text])` → `editor.commands.setContent(text)` |
| Delta | `sendTextDelta(old, new)` via `commonPrefix/commonSuffix` | Same — diff `editor.getText()` old vs new |

### 1.4 Toggle Between Editors

Add a feature flag or URL param to switch between CollaborativeEditor and TiptapEditor during migration. This allows parallel testing without losing the working editor.

### 1.5 Acceptance Criteria

- [ ] Type text → appears in editor → syncs to server → appears in other sessions
- [ ] Remote edits → appear in editor
- [ ] Undo/redo works (TipTap History extension)
- [ ] Paste works
- [ ] CRDT disconnect/reconnect works
- [ ] Text survives page refresh

## Phase 2: Port Overlays (Week 2)

### 2.1 Attribution Spans

**Option A: Keep canvas overlay (recommended for initial migration)**

The existing `drawOverlay` function works on any DOM. Pass TipTap's editor DOM ref instead of the contentEditable ref. The `findTextNodeAt` TreeWalker and `createRange` logic is DOM-agnostic.

```typescript
// Pass editor.view.dom to the overlay
const editorDom = editor?.view.dom;
drawOverlay(editorDom, canvas, attributionSpans, ...);
```

**Option B: ProseMirror Decorations (future enhancement)**

```typescript
const attributionPlugin = new Plugin({
  state: {
    init: () => DecorationSet.empty,
    apply(tr, set) {
      set = set.map(tr.mapping, tr.doc);
      const spans = tr.getMeta(attributionMeta);
      if (spans) {
        const decos = spans.map(s => Decoration.inline(s.start, s.end, {
          class: 'attribution-span',
          style: `background: ${s.color}25`,
        }));
        set = DecorationSet.create(tr.doc, decos);
      }
      return set;
    },
  },
  props: { decorations: (state) => attributionPlugin.getState(state) },
});
```

### 2.2 Remote Cursors

Replace `RemoteCursors.tsx` with ProseMirror `Decoration.widget`:

```typescript
// Remote cursor as a widget decoration
Decoration.widget(pos, () => {
  const caret = document.createElement('span');
  caret.className = 'remote-cursor';
  caret.style.borderColor = authorColor(name);
  // ... label, etc.
  return caret;
}, { side: -1 });
```

This uses `editor.view.coordsAtPos(pos)` instead of our hand-rolled `charIndexToPos`.

### 2.3 Annotations

Keep as canvas overlay initially. The yellow rectangles map the same way as attribution spans.

### 2.4 Transclusion Markers (gutter bars)

Keep as canvas overlay. The gutter bars are drawn outside the text area and don't need ProseMirror integration.

### 2.5 Acceptance Criteria

- [ ] Attribution colors appear correctly per author
- [ ] Remote cursors track accurately
- [ ] Annotations display and are clickable
- [ ] Transclusion gutter bars render
- [ ] Recent change highlights (green fade) work

## Phase 3: Custom Transclusion Node (Week 3)

### 3.1 Define Transclusion Extension

```typescript
import { Node, mergeAttributes } from "@tiptap/core";
import { ReactNodeViewRenderer, NodeViewWrapper } from "@tiptap/react";

export const TransclusionNode = Node.create({
  name: 'transclusion',
  group: 'inline',
  inline: true,
  atom: true,          // non-editable, selected as a unit
  selectable: true,
  draggable: false,

  addAttributes() {
    return {
      sourceWorkId: { default: null },
      charStart: { default: 0 },
      charEnd: { default: 0 },
      resolvedContent: { default: '' },
      sourceTitle: { default: '' },
    };
  },

  parseHTML() {
    return [{ tag: 'span[data-transclusion]' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['span', mergeAttributes(HTMLAttributes, {
      'data-transclusion': '',
      contenteditable: 'false',
    })];
  },

  addNodeView() {
    return ReactNodeViewRenderer(TransclusionView);
  },
});
```

### 3.2 React NodeView Component

```typescript
function TransclusionView({ node }) {
  const { sourceWorkId, charStart, charEnd, resolvedContent, sourceTitle } =
    node.attrs;

  return (
    <NodeViewWrapper
      className="inline-transclusion"
      contentEditable={false}
      onClick={() => onNavigateToWork(sourceWorkId)}
      title={`Transclusion from: ${sourceTitle} (click to navigate)`}
    >
      {resolvedContent}
    </NodeViewWrapper>
  );
}
```

### 3.3 Placement Flow

```typescript
// When user clicks to place transclusion:
const pos = editor.view.posAtCoords({ left: e.clientX, top: e.clientY });
editor.chain()
  .insertContentAt(pos, {
    type: 'transclusion',
    attrs: {
      sourceWorkId,
      charStart,
      charEnd,
      resolvedContent: excerpt,
      sourceTitle,
    }
  })
  .run();
```

No more `caretRangeFromPoint`, no more `computePlacementPosition`, no more `getEditableText` — TipTap handles position mapping natively.

### 3.4 Serializer (getText without transclusion content)

```typescript
// editor.getText() already excludes atom nodes by default
// But we need to ensure transclusion content isn't counted:

const customSerializer = () => {
  let text = '';
  editor.state.doc.descendants((node) => {
    if (node.isText) {
      text += node.text;
    }
    // transclusion nodes (atom) contribute nothing
    return true;
  });
  return text;
};
```

### 3.5 Resolve Content

When the editor renders, transclusion nodes need resolved content from the server:

```typescript
// On inbound compoundSpanRanges update:
editor.state.doc.descendants((node, pos) => {
  if (node.type.name === 'transclusion') {
    const sr = spanRanges.find(s => s.source_work_id === node.attrs.sourceWorkId);
    if (sr && sr.content !== node.attrs.resolvedContent) {
      editor.chain()
        .setNodeSelection(pos)
        .updateAttributes('transclusion', { resolvedContent: sr.content })
        .run();
    }
  }
});
```

### 3.6 Acceptance Criteria

- [ ] Transclusion appears as amber inline block with resolved content
- [ ] Click navigates to source work
- [ ] Placement is precise (posAtCoords)
- [ ] Transclusion is zero-width in getText()
- [ ] Undo removes transclusion placement
- [ ] Delete key removes selected transclusion
- [ ] Multiple transclusions work in same document

## Phase 4: Feature Parity (Week 4)

### 4.1 Search Panel

Keep existing SearchPanel — it operates on flat text via TextBuffer, which still works.

### 4.2 Outline Panel

Keep existing OutlinePanel — same reasoning.

### 4.3 Keyboard Shortcuts

| Shortcut | Implementation |
|----------|---------------|---|
| Cmd+Z / Cmd+Shift+Z | TipTap History extension (built-in) |
| Cmd+K | Custom TipTap keymap extension |
| Tab | TipTap keymap → insert "\t" |
| Cmd+Alt+A | Custom keymap → annotation creation |
| Enter | TipTap handles natively |

### 4.4 Paste Handling

```typescript
editor.props.handlePaste = (view, event) => {
  const text = event.clipboardData?.getData('text/plain') || '';
  if (text.length > 50) {
    const pos = view.state.selection.from;
    onPasteText(text, pos);
  }
  return false; // let TipTap handle the actual paste
};
```

### 4.5 Content Range (boilerplate filtering)

Port `bodyRange` / `showBoilerplate` logic. The line/char calculations work the same way on flat text.

### 4.6 Large Document Support

TipTap handles large documents better than contentEditable out of the box. Remove `chunkedSetTextContent` and `LARGE_DOC_THRESHOLD`.

### 4.7 Acceptance Criteria

- [ ] Search finds text within document
- [ ] Outline shows headings/sections
- [ ] All keyboard shortcuts work
- [ ] Paste >50 chars triggers attribution detection
- [ ] Large documents (100K+ chars) perform well

## Phase 5: Cleanup (Week 5)

### 5.1 Remove Legacy Code

- Delete `CollaborativeEditor.tsx` (replaced by TipTap)
- Delete `getTextContent`, `getEditableText`, `isReadonlyNode`, `buildTransclusionDom`
- Delete `chunkedSetTextContent`
- Delete `findTextNodeAt`
- Delete ZWSP management (`\u200B`)
- Delete `RemoteCursors.tsx` (replaced by ProseMirror decorations)
- Delete custom undo/redo stacks

### 5.2 Update Documentation

- Update `AGENTS.md` with TipTap dependencies
- Update `collaborative-editing.html` with TipTap architecture
- Update `udanax-to-xudanu.html` with editor upgrade

### 5.3 Acceptance Criteria

- [ ] No contentEditable references remain
- [ ] No ZWSP references remain
- [ ] No custom undo stack
- [ ] All features from CollaborativeEditor are in TipTap version
- [ ] Test suite passes

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| CRDT delta mismatch | Keep `sendTextDelta` string-diff approach (don't use TipTap transactions for sync) |
| Position mapping errors | TipTap's `posAtCoords` / `coordsAtPos` are battle-tested |
| Attribution canvas breaks | Keep canvas initially — it's DOM-agnostic |
| Undo conflicts | Replace custom undo with TipTap History (don't mix) |
| Remote cursor drift | Use ProseMirror Decorations (precise positioning) |
| Performance regression | TipTap is faster than raw contentEditable for large docs |
| IME/paste issues | TipTap handles these natively and correctly |

## What Stays Unchanged

- Rust backend (server.rs, dispatch.rs, protocol.rs, codec.rs)
- Wire protocol (retain/insert/delete deltas)
- CRDT (otree_crdt.rs, crdt_sync.ts)
- Attribution system (Ed25519 signatures, attribution_query_resolved)
- Compound document system (RangeElement::Transclusion, resolve_inline_transclusions)
- ChunkStore, manifest, WAL
- All tests (2261 backend + 138 frontend)

## Dependencies to Install

```
@tiptap/react         — React integration
@tiptap/starter-kit   — Paragraph, history, keymap, etc.
@tiptap/core          — Core editor
@tiptap/pm            — ProseMirror utilities
```

No Yjs. No y-prosemirror. No y-tiptap.

## Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 1. Basic editor | Week 1 | TipTap renders text, syncs via CRDT |
| 2. Overlays | Week 2 | Attribution, cursors, annotations |
| 3. Transclusion nodes | Week 3 | Custom NodeView for transclusions |
| 4. Feature parity | Week 4 | Search, outline, shortcuts, paste |
| 5. Cleanup | Week 5 | Remove legacy code, update docs |
