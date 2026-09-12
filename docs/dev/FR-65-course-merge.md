# FR-65: Merge the Interactive Demo into the Links Course

Status: **PROPOSED** — stage 1 (welcome-screen button gating) shipped
2026-09-12 in `8777a0b6`; the content merge is unwritten.

## Problem

Two onboarding artifacts coexist by accretion: the boot-seeded
"Xudanu Interactive Demo" work (a feature tour: transclusion,
provenance, comparison, CRDT — the old generation) and the seeded
Links Course (five lessons, live demos, one task each, trail-wired —
the newer, better pedagogy). The tour is the predecessor the course
superseded but never retired, which surfaced as a UX finding: two
similar CTAs on the welcome screen competing for one job.

## Approach

One corpus, one pedagogy, one door:

1. **Fold tour content into the course as lessons 6–8:**
   - Lesson 6 — Transclusion: quote by reference; edit the source,
     watch the quotation update (the two-window demo lives here)
   - Lesson 7 — Provenance: who wrote what, character by character;
     the signed record and what it proves
   - Lesson 8 — Comparison/reading at scale: the compare view across
     multi-ended links (extends Lesson 5's compare introduction)
2. **Retire the tour work** from the boot seed once the course
   covers its content
3. **Promote `--seed-links-demo` to the default boot seed** so every
   fresh server gets the merged course automatically
4. Welcome screen keeps a single learning door (already gated:
   course button when seeded, tour button as unseeded fallback —
   after the merge, the fallback disappears)

## Acceptance

- A fresh server with no flags starts with the 8-lesson course
- The "Xudanu Interactive Demo" work no longer exists in any seed
- Lesson 6–8 tasks are doable in the sandbox and read-only demos
  work under owner-only policy (same constraints as L1–L5)

## Relationship

- Companion: FR-66 (link-creation onboarding) — the course is the
  curriculum half of that spec's ladder
- The auto-open first-visit behavior (shipped) targets Lesson 1
  and is unaffected by the merge
