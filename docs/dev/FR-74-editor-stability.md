# FR-74: Editor Stability — Model-Truth Architecture

**Status:** next session (top priority)
**Created:** 2026-09-19
**Problem:** the contenteditable editor corrupts text during structural
operations — 5+ incidents in one session (heading merges, character loss,
## artifacts, transclusion insertion breaking lines, link creation eating
text). Each patch fixed a symptom; the root cause is architectural.

## The diagnosis

The editor uses a raw `contenteditable` div as both the editing surface
AND the source of truth. Structural operations (link create, transclusion
insert, annotation, heading format) modify the DOM surgically via
`document.execCommand("insertText")` or direct DOM manipulation. Any race,
edge case, or unexpected contenteditable state corrupts the text.

The server-side model is ALWAYS correct — the corruption is purely in the
editor's DOM state. This is why the Connections panel (which reads from
the model) works fine while the editor shows garbage.

## The fix: three phases

### Phase A: Model-truth rebuild (~half day)

**The rule: after any structural operation, rebuild the editor DOM from
the server model. No surgical DOM edits for structural changes.**

Implementation:
1. Extract a `rebuildFromModel(text: string)` method on
   CollaborativeEditor that:
   - Saves the caret position (character offset)
   - Sets the contenteditable's innerHTML from the model text (via
     `buildStyledText` for formatting)
   - Restores the caret
   - Triggers the marker overlay redraw
2. Every structural operation calls it after the server round-trip:
   - Link create/delete/retype → rebuild
   - Transclusion insert/remove → rebuild
   - Annotation create/delete → rebuild
   - Heading/format change → rebuild
   - Work set_text → rebuild
3. Plain typing stays native contenteditable (no rebuild — that would
   destroy the caret on every keystroke)
4. The rebuild is debounced (100ms) if multiple structural operations
   arrive in quick succession

**Exit criteria:** create a link, insert a transclusion, format a
heading, and annotate — text is byte-identical to the server model
after each operation. No character loss. No line merging. No ##
artifacts.

### Phase B: Annotation-based headings (~half day)

Stop storing `## `, `### ` etc. as text prefixes. Store heading level
as a block annotation. The renderer already supports this
(`buildStyledText` handles `annBlockMarks`).

Implementation:
1. The heading/list/blockquote buttons create annotations instead of
   text prefixes:
   ```json
   { "kind": "heading", "char_start": 0, "char_end": 15,
     "payload": "{\"level\": 2}" }
   ```
2. `buildStyledText` already renders from annotations — no renderer
   changes needed
3. Text-prefix headings keep working (backward compat — both paths
   coexist)
4. Migration tool: a one-time "normalize formatting" command that
   converts text-prefix headings to annotations (for existing docs)

**Exit criteria:** heading formatting survives any text edit, any
deletion, any insertion. `##` characters never appear in the text
model unless the user literally typed them.

### Phase C: TipTap migration (future session, 2-3 days)

Replace the raw contenteditable with TipTap (ProseMirror wrapper).
The document becomes a formal model (tree of nodes); the DOM is a
projection that updates atomically. DOM corruption becomes impossible
by construction.

This is the production-grade answer — what Obsidian, Notion, and every
serious collaborative editor uses. The codebase already has
`tiptap-editor-content` CSS classes and a `?mde` flag suggesting
prior exploration.

Prerequisites for Phase C:
- Phase A and B shipped (proves the model-truth concept)
- The overlay-canvas utility (shipped) integrates with TipTap's
  DOM updates
- The CRDT delta path sends ProseMirror-compatible steps

**Not urgent** — Phase A + B make the editor stable for daily use.
Phase C makes it production-grade.

## What Phase A does NOT fix

- Typing latency (already fast — the lattice write-switch)
- Marker overlay rendering (already fixed — double-buffered)
- Span migration correctness (already fixed — work_set_text migrates)
- The heading ## eating bug (Phase B's job)

## What Phase A DOES fix

- Character loss during link creation
- Line merging during transclusion insertion
- Text corruption during any structural operation
- The "editor shows different text than the server" class of bugs
- Every symptom we've seen today

## Test plan

1. **Link stability:** create 5 links on a document, verify text is
   unchanged after each creation
2. **Transclusion stability:** insert 3 transclusions at different
   positions, verify text integrity
3. **Heading stability:** format 5 headings via the buttons, then edit
   text around them, verify headings survive
4. **Mixed operations:** create a link, then format a heading, then
   insert a transclusion — all on the same document
5. **Rapid operations:** create and delete links quickly (stress the
   debounce)
6. **Caret preservation:** type, then create a link at the caret,
   verify the caret returns to the correct position
7. **Undo/redo:** verify undo after structural operations doesn't
   corrupt text
