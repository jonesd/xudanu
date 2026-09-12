# FR-66: Link Creation Onboarding — the Competence Ladder

Status: **PROPOSED** (from the 2026-09-12 links UX walkthrough — the
first-user testimony that motivated it: "I need help with links, and
I expect most people will also have this problem. In practice it's
very different from what people would expect.")

## Problem

The web trained everyone on `select → paste URL → done`: one-way,
untyped, no consequences. The xanalogical link asks decisions the
web never asked — what kind of connection (the type is a verb),
where it lives (passages, not pages), and — for the advanced shapes
— how many places one claim involves, and whether several passages
fill one blank jointly. The current LinkCreator presents this
machinery structure-first, all at once. Users arrive with intent
("react / back up / call out / compare") and vocabulary they don't
have.

## The core insight

There is a progression from simple to powerful, and each rung is
exactly one new idea. Everything — curriculum, wizard, coaching —
should follow the same ladder:

| Rung | Link | The one new idea | Builds on |
|---|---|---|---|
| 0 | Web URL | none — behaves like the web link everyone knows | web prior |
| 1 | Two-ended, typed | the connection has a *verb* | rung 0 mechanics |
| 2 | Multi-ended | one claim can involve several places | sentence-with-blanks |
| 3 | Gathered end-set | one blank filled jointly by several passages | rung 2 plurality |
| 4 | Comment-on-link | connections are themselves addressable | all below |
| 5 | Reading toolkit | compare / navigate / follow | consuming what you built |

Rung 0 is the front door precisely because it is familiar: the
moment a web link is made, it appears in the Connections panel as a
row with a type — teaching rung 1's vocabulary by showing it.

## Reading model (the vocabulary everything uses)

**A link is a sentence with blanks: the type is the verb, each end
fills a blank.** Multi-ended = several blanks. Gathered end = one
blank filled jointly.

## The four layers

1. **Intent-first entry** — the wizard opens with "What are you
   trying to do?" (react / back up / call out / relate / compare /
   link a URL) and pre-configures type + end structure. Task-first,
   not structure-first. The recipes:

   | Intent | Pre-configured |
   |---|---|
   | react to a passage | Comment, two-ended |
   | back up a claim | Reference, two-ended |
   | call out something wrong | Disagreement, two-ended (exact span) |
   | relate material | See Also, two-ended |
   | compare several passages | See Also, multi-ended (advanced fold open) |
   | body of evidence | gathered end (advanced) |
   | link a URL | Web type |

2. **Per-rung coaching copy** — one contextual sentence per wizard
   step, in the reading-model vocabulary: "Most links have two ends.
   Add a third only when one claim involves several places."

3. **Experience-gated disclosure** — rungs 2–3 ("Additional ends",
   "Gather") hidden behind an Advanced fold until the user has made
   N successful simpler links (count from the server or local
   storage). Unlock by doing, not by reading.

4. **The course as conceptual companion** — the seeded Links Course
   already implements the ladder as curriculum (L1–L5); the wizard
   links into it contextually ("stuck? Lesson 2 covers three-ended
   links").

## Implementation slices

- **S1 (cheap, immediate):** coaching copy in the LinkCreator +
  Advanced fold for multi-end/gather. One session.
- **S2:** live sentence preview while building ("This [disagrees
  with] 'the ferry schedule' in Companion B").
- **S3:** intent-first entry (wizard restructure).
- **S4:** experience gating (unlock counts).
- **S5:** contextual course links per step.

## Acceptance

- A first-time user can make a typed two-ended link without docs
- Multi-end/gather never appear for the first three links a user
  makes
- Every wizard step carries one coaching sentence
- The walkthrough user (who reported the problem) can make a
  three-ended gathered link unaided after the course + wizard

## Relationship to other work

- The Links Course (FR-40-era seed) is the curriculum half; this FR
  is the doing-context half
- FR-65 (candidate): merge the Interactive Demo into the course as
  lessons 6–8 and make the course the default boot seed
- Trails discoverability (backlog) shares the same principle: help
  must exist in the doing context, not the browsing context
