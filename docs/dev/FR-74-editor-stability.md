# FR-74: Editor Stability — Model-Truth Architecture

**Status:** Phase A shipped (split display/edit states) · Phase B shipped
2026-09-19 (annotation-based block toggles) · Phase C future
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

### Phase A: Model-truth rebuild (~half day) — SHIPPED (evolved)

Shipped as the split display/edit states (commit 0a7c786f): the
contenteditable is only alive during active editing; display mode is
React-owned and always rendered from the server model. Stronger than
the original rebuild-on-structural-op design — corruption can never
persist past the edit session.

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

### Phase B: Annotation-based headings (~half day) — SHIPPED 2026-09-19

Stop storing `## `, `### ` etc. as text prefixes. Store heading level
as a block annotation. The renderer already supports this
(`buildStyledText` handles `annBlockMarks`).

**Implementation (as shipped):**

- `planBlockToggle()` in `styled-text.ts` — pure planner returning the
  annotation ops (create / delete / replace) for a line toggle. Uses
  the same line-overlap rule as the renderer. 11 unit tests in
  `block-formatting.test.ts`.
- `handleToggleBlock` (WorkspaceShell) — unmarked lines take the
  annotation path: **no text change, no caret move**. Formatting is an
  annotation; the server's span migration (FR-50 A1 armor) carries it
  through every subsequent edit.
- Legacy coexistence: lines that already carry a text marker (`# `,
  `- `, `> `, ` ``` `) keep the text-prefix path. Two reasons:
  1. the marker wins renderer precedence, so an annotation on a marked
     line would be invisible;
  2. converting mid-toggle would race the debounced text save against
     annotation char positions (delete-at-span-start maps differently
     than the desired post-strip span).
- After annotation ops: `refreshAnnotations()` +
  `bumpStructuralVersion()` — the display rebuilds from the model with
  the new block marks.

**Deferred:** the "normalize formatting" one-time migration (converts
legacy text-prefix lines to annotations). Needs either an awaitable
text-save path or a server-side op to avoid the position race.

**E2E:** `web/app/e2e/block-formatting.spec.ts` (backend-gated) —
identity → Compose → type → H1 → assert styled span + no `#` in the
model → append at line end (migration) → toggle off.

## Session finding (2026-09-20): the WS 1006 reconnect loop

The editor e2e kept losing its connection (browser: code 1006, no
close frame). Root cause chain, traced via frame capture + security
log:

1. The CompoundBuilder live-preview sends `compound_resolve_segments`
   on every load — but the op was never wired into the transport
   (engine method shipped in FR-55 T5; protocol/dispatch arms did not)
2. Every send decoded as "unknown variant" → `protocol_error` → a
   protocol violation strike in the security layer
3. Strikes accumulate → `should_disconnect` → the server kills the
   socket (abrupt = 1006) → client reconnects → builder sends the op
   again → loop. Editors lost in-flight typing whenever the socket
   dropped mid-save.

Fix: full transport wiring (op 0x080a, codec arm, dispatch arm calling
`compound_resolve_segments`, JSON response `{renders:[{kind,text}]}`),
pinned by codec + dispatch tests. The op-code soundness gate caught
0x0809 colliding with ProvenanceAncestry — use 0x080a.

**Follow-up bug exposed (not yet fixed):** typing during a work switch
is silently discarded when the server text arrives (the switch calls
`setText(serverText)` unconditionally). The reconnect path already
diffs-and-pushes local edits; the switch path needs the same. Also
`deleteAnnotation` silently no-ops while disconnected.

**Exit criteria:** heading formatting survives any text edit, any
deletion, any insertion. `##` characters never appear in the text
model unless the user literally typed them. ✔ (annotation path; legacy
marker lines unchanged until normalize ships)

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
