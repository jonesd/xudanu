# Performance Investigation: Document Loading

## Goal
Identify which operations are slow when opening a document, and defer
non-critical rendering until after the document text is visible.

## Priority Order (what the user sees first)

1. **Document text** (center panel) — must be instant
2. **Format bar** — must be instant (already rendered)
3. **Related footer** (bottom bar) — can wait 100ms
4. **Right panel** (Prov/Links/Trails) — can wait 500ms
5. **Graph** (left rail) — can wait 1-2s
6. **Transclusion resolution** — can be lazy

## Instrumentation Plan

### What to measure

| Operation | Where | Expected |
|---|---|---|
| CRDT open (text fetch) | useCrdtSync | <100ms cached, <300ms cold |
| buildStyledText (DOM rebuild) | CollaborativeEditor | <50ms small, <200ms large |
| Attribution query | server round-trip | <100ms |
| Annotation list | server round-trip | <100ms small, <500ms large |
| Links/backlinks | server round-trip | <200ms |
| Transclusion resolution | server round-trip | <100ms shallow, <1s deep |
| Graph query | server round-trip | <200ms filtered |
| Canvas overlay redraw | CollaborativeEditor | <50ms |

### How to measure

Add `performance.now()` markers in:
- useCrdtSync (switchWork, tryOpenWork)
- WorkspaceShell (useEffect chains on workBeId change)
- CollaborativeEditor (buildStyledText, overlay redraw)

### What to optimize

1. **Defer graph query** — don't fetch until after text is visible
2. **Defer transclusion resolution** — show plain text first, then resolve
3. **Defer links/backlinks** — RelatedFooter can populate after 200ms
4. **Batch server requests** — attribution + annotations in parallel
5. **Lazy-load right panel** — only fetch data for active tab
