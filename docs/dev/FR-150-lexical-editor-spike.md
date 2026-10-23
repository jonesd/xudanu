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

## Root cause isolated (2026-10-23, human-typed on device)

Human typing on the spike with ~350ms commit batching: **mixed
forward/corrupted fragments** — batched single inserts land correctly;
interleaved batches misapply offsets. Combined with earlier evidence
(per-keystroke = fully mirrored text on BOTH editors; single batched
insert = correct), the bug is definitively in the SHARED client
diff→CRDT-op pipeline (crdt_sync.ts area), triggered by op cadence —
NOT the editor surface, NOT Lexical, NOT iOS rendering. Fix target:
insert-offset computation in the diff/op generator (suspect: base
text staleness between consecutive diffs — each op's position
computed against a pre-batch baseline).

## VERDICT (2026-10-22, automation-verified on-device)

**Lexical spike PASSES where the incumbent failed catastrophically.**
Typed on iPhone via safaridriver (real device Safari): "Hello there"
→ server stored "Hello there" → survives reload. Old editor under
identical conditions stored MIRRORED text (finding 0). The focus
flakiness that blocked manual testing resolved into four separate
environment bugs (editability deadlock; blocked-storage boot crash;
sticky-flag fallback; stale LAN origin) — all fixed on this branch.
Remaining before merge: one HUMAN IME pass (autocorrect/dictation by
finger) — automation cannot exercise the real keyboard pipeline.

## Device findings (2026-10-20/21, iPhone iOS 18.7, WebKit)

0. **Old surface: typing writes MIRRORED text to the server** —
   typing "Hello there" on iPhone stored "ereht olleH" (persists
   across reload; attribution colors the reversed span, so storage
   is definitively reversed). Mechanism consistent with per-char
   inserts all landing at offset 0 — the iOS offset/coordinate path
   is broken in the old editor's diff pipeline. Repro: new doc,
   type two words. This is disqualifying on its own.
1. **Spike on iPhone (iOS 18.7 Safari): focus/keyboard failure —
   UNRESOLVED, needs Web Inspector.** Five iterations: editability
   deadlock fixed (EditableGate); probe shows e=1 consistently;
   focus oscillates f=0<->f=1 across gesture-focus patches
   (pointerdown, click, user-select insurance) — keyboard never
   reliably opens. Next step: USB + Web Inspector (or safaridriver,
   the v1.8.0 approach) to watch events/DOM live. NOT a Lexical
   verdict yet — the OLD-surface verdict is already decisive
   (finding 0).)

1. **Old surface: text vanishes after link-create** — after
   attempting a link to another document, the editor rendered only
   link-marker underlines; all glyphs invisible until refresh.
   Data intact server-side (render-state corruption in the
   post-link structural rebuild on iOS WebKit). This is criterion-1
   class evidence: the contentEditable surface fails on device
   without IME even being involved. (Lexical surface unaffected by
   construction — it has no link-marker rebuild path.)
2. Mobile chrome feedback (fixed on branch): selection+format bars
   now single scrollable rows; LAN origin + 16px-font + storage
   guards ported from v1.8.0 lessons.

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
