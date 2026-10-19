# FR-150: Editor Spike — Lexical Authoring Surface (Mobile-First)

- **ID:** FR-150
- **Status:** Approved for spike (2026-10-19). Two-week timebox.
- **Context:** the current authoring surface fights raw contentEditable
  (caret loss, Enter/coordinate bugs, rebuild churn — generic
  contentEditable failure modes, amplified on mobile by Android IME
  composition and keyboard viewport math). Mobile (FR-148e light
  authoring) makes fixing this once, on the hardest devices, the
  right sequencing — desktop inherits the result.
- **Choice:** Lexical (Meta, MIT) — React-first, decorator nodes for
  attribution/transclusion overlays, production mobile investment.
  Fallback: ProseMirror/TipTap if Lexical's structure-editing ceiling
  shows during the spike.

## Scope

IN: plain-text editing surface behind a feature flag
(`web/app`), author-span decorators (colored attribution), minimal
O-tree CRDT adapter (positions in → CRDT ops out, server
authoritative), running on desktop browser + one real Android and
one real iPhone.

OUT: reading experience (stays ours), link-marker overlays,
annotations, transclusion placement, any visual redesign.

## Success criteria (all must pass)

1. IME torture on real devices: Android composition, autocorrect,
   predictive bar; iOS quicktype, dictation — zero caret/sync anomalies
2. Author spans render and survive edits (decorator mapping)
3. CRDT adapter round-trips: two clients (one mobile) converge via the
   existing O-tree server; no position drift
4. visualViewport handled — keyboard never covers the caret
5. Existing vitest suite green; no regression to current editor
   (flag-off paths untouched)

## Kill criteria

- IME edge cases require DOM-scraping hacks to work around → fail,
  evaluate ProseMirror before proceeding
- CRDT adapter cannot be expressed cleanly against Lexical's
  transaction model → document why, reassess

## Notes

- Do NOT integrate Yjs — the server CRDT stays authoritative
- Reuse Playwright multi-engine plan for IME regression automation
- Spike branch, not main, until criteria 1–3 pass
