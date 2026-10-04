# 60-Second Demo Video — Shot Script

The one-video pitch: bidirectional links, live, in a minute. Record at
1280×720+ (or 2× for retina), terminal font large, browser zoom ~125%.
Setup before recording: fresh demo instance
(`docker compose -f docker-compose.demo.yml up`, or the release-binary
one-liner), an empty "claim" and "criticism" work already created but
blank, so typing is short.

| # | Time | Screen | Action | Narration |
|---|------|--------|--------|-----------|
| 1 | 0:00–0:05 | Terminal | Type the one command; server starts | "One binary. One command." |
| 2 | 0:05–0:10 | Browser | Open localhost:8080; work list visible (Links Course seeded) | "A docuverse — with a demo corpus already connected." |
| 3 | 0:10–0:20 | Lesson 1 open | Hover the connections panel; point out backlinks arriving FROM other lessons | "Every document knows what points at it. These lessons were never edited to contain these links." |
| 4 | 0:20–0:35 | Two blank works | In work A type: "The funculator must be titanalum." In work B type: "Titanalum is too expensive." | "A claim. And a criticism — in a completely different document." |
| 5 | 0:35–0:45 | Work B | Select text → create link → target A → type: **disagreement** | "One typed link. A disagrees-with B. And crucially — B is never touched." |
| 6 | 0:45–0:55 | Work A | Open the claim. The criticism sits in its connections panel, typed, clickable. Click it → jumps to B. | "Open the claim: the criticism is already here. Nobody edited it. Both ends see the same connection." |
| 7 | 0:55–1:00 | Title card | Text on dark background | "Xudanu. Connections visible from both ends. github.com/jonesd/xudanu" |

## Rules for the cut

- Show the *moment* in shot 6 twice if needed — it is the whole video
- Never cut away while a link is being created; the click → panel
  update is the proof
- No feature tour: no compare, no provenance, no federation. One idea
- End card 5 seconds minimum for the URL to register

## Recording notes

- `scripts/capture-reel.mjs` exists for scripted Playwright capture if
  a fully programmatic version is wanted (screenshot frames →
  `assemble-reel.sh`); the seeded demo is deterministic enough for it
- Upload target order: the release page, the README quick-start, and
  whatever the Hacker News / Roger-release thread becomes
