# TextFold — Reference for Reading UX

- **Repo:** https://github.com/chenxiachan/textfold
- **Status:** Noted 2026-10-23. Revisit during FR-148b (viewer) and
  any reading-experience work.
- **License:** Apache 2.0 (compatible for conceptual borrowing; check
  if any code-level integration is desired)

## What it does
Five-level semantic zoom for reading: Full → Brief (author's key
sentences) → Key (AI: point + reason) → Takeaway (AI: one line) →
Topic (AI: card map). Words that survive each level animate to
their new position; the rest fade.

## Ideas worth revisiting for Xudanu

1. **Zoom interaction** — pinch/scroll to change detail level, with
   surviving words sliding to position. Better than a binary
   expand/collapse toggle for reading long works.
2. **Anchored AI summaries** — AI-generated content always links to
   the specific author passages it derives from. Applies to Xudanu's
   optional LLM features (every AI line traceable to its source).
3. **Notes that persist across zoom levels** — highlights made at
   full detail remain visible at summary levels.
4. **Claude Code plugin approach** — thin in-place enhancement of
   agent output; relevant to how Xudanu's LLM features ship.

## Where they'd meet Xudanu
A docuverse where each work can be folded — a transclusion at level
2 (brief) instead of full text; a compound showing its sources at
level 5 (topic cards). TextFold's folding is the reading layer;
Xudanu's transclusion is the structure layer. Complementary.

## What NOT to take
- TextFold's provenance model is binary (author vs AI); Xudanu's is
  per-character cryptographic. Don't downgrade.
- TextFold documents fold independently; Xudanu works are connected.
  Folding should respect the link/transclusion graph, not ignore it.
