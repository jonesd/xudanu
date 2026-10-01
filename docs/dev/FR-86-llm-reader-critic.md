# FR-86 — LLM as Reader-Critic: machine participation in the argument marketplace

**Status:** specified, not started (October 2026)
**Source:** Miller's model extended — "every reader is a potential
author" includes machine readers. The LLM is not a judge above the
system; it is a participant within it.
**Design lineage:** Hybrid LLM-symbolic approaches (Vasileiou &
Derendiaeva 2026) — LLM for natural-language extraction, formal
system for structural guarantees. Karacapilidis et al. (2024)
"LLM-Augmented Public Deliberation" — LLM as participant, not
arbiter.
**Related:** FR-81 (ingress provenance — machine authorship
stamping), FR-85 (argument structure — LLM connections enter the
same chains), FR-40 (typed links — LLM uses the same vocabulary),
FR-46 (endorsement — social filtering applies equally), FR-80
(detectors — the LLM can be watched).

## Why

The research landscape (2024–2026) shows LLMs can generate
counter-arguments, map argument structures, and evaluate debates —
but always as a **black box separate from the knowledge base**. No
system has put LLM-generated connections into the same fine-grained
bidirectional hypertext graph as human connections, subject to the
same social filtering. That gap is the opportunity:

- **Miller's model already has the slot**: every reader is a
  potential author. An LLM reading a work and proposing
  Disagreements is just another reader.
- **The substrate already carries the machinery**: typed links,
  endorsement, provenance, bidirectional visibility. An LLM's
  contributions need zero special infrastructure.
- **Social filtering is the safety mechanism**: bad LLM arguments
  get no endorsements and sink. Good ones rise. No platform-level
  censorship needed — the community judges, not the system.

## The design principle

**No special treatment.** The LLM's arguments compete in the same
marketplace of ideas as human arguments:

| Property | Human critic | LLM critic |
|---|---|---|
| Attribution | personal club | model identifier (stamped) |
| Link types | Disagreement, Reference, … | same vocabulary |
| Span-level precision | drag-select | excerpt matching (same resolver) |
| Endorsement | earned by reputation | earned by quality |
| Bidirectional visibility | ✓ | ✓ (same wire ops) |
| Detector-watchable | ✓ | ✓ (same detector surface) |
| Provenance | signed by author club | signed + model ID (FR-81) |

## Architecture

### Stage 1 — LLM extraction (propose)

The LLM reads a work's text and identifies **claimable passages** —
the passages a critical reader would flag. For each, it proposes a
typed connection:

```
Input: work text + far-end works (the connected corpus)
Output: [
  {
    span: { start: 42, end: 67 },
    excerpt: "the funculator must be duralum",
    proposed_type: 3,  // Disagreement
    reasoning: "The cost analysis in Ruth's Rebuttal contradicts
                this claim — duralum is $12.40 vs titanalum $28.70",
    confidence: 0.87,
    far_end: { work_id: 0x654, span: { start: 15, end: 32 } }
  },
  ...
]
```

The LLM does NOT create the link. It **proposes** it — the
connection enters the same pending-authoring flow a human would
see.

### Stage 2 — Human oversight (confirm/edit/reject)

Proposed connections appear in the same connection-authoring UI as
human-created ones:
- The author (or any authorized reader) sees the proposed
  Disagreement with the LLM's reasoning
- They can **confirm** (the link is created, attributed to the LLM
  with its model ID in the provenance chain), **edit** (adjust the
  span or reasoning before confirming), or **reject** (dismissed,
  logged for model improvement)

This is the critical safety layer: a human decides which LLM
proposals enter the graph. The LLM is a **research assistant**, not
an autonomous author.

### Stage 3 — Argument chain participation

Once confirmed, LLM connections are indistinguishable from human
ones in the argument structure:
- They appear in **argument chains** (FR-85)
- They carry **endorsement counts** (rise and fall by quality)
- They are **visible from both ends** (bidirectional)
- They show their **provenance** (the tooltip displays "by
  [model-name]" alongside the excerpt — transparency without
  segregation)

### Stage 4 — Detector integration

An LLM critic can be **watched** like any other author:
- A detector on a work can filter for LLM-originated Disagreements
  specifically (if you want to see only machine analysis)
- Or filter them out (if you want human-only discourse)
- Or treat them identically (the default — quality is quality)

## Implementation

### Server (minimal — the substrate already supports everything)

1. **FR-81 interlock**: the `author_type` field on provenance
   already distinguishes machine from human. The model identifier
   (`llm_model` on AttributionSpanPayload) already stamps which
   model generated the content. No new wire ops needed for the
   connections themselves.

2. **New op: `llm_propose_connections`** (optional, for servers
   that want server-side LLM integration):
   ```
   LlmProposeConnections { work_id, model? }
   → { proposals: [{ span, type, reasoning, confidence, far_end? }] }
   ```
   The server runs the LLM (local Ollama or remote API), returns
   proposals. The CLIENT renders them in the authoring UI. The
   link creation uses the existing `link_create` op.

3. **Alternative: client-side LLM** — the client can call the LLM
   directly (no server op needed), get proposals, and present them
   in the authoring UI. The link creation is standard.

### Client

1. **Proposals panel**: a "Suggest connections" button on works
   that triggers the LLM analysis. Proposals render as
   pre-populated connection-authoring cards.
2. **Provenance display**: the marker tooltip and Links panel show
   the model identifier when `author_type` is machine.
3. **Filter**: a toggle in the Links panel + Beams view to
   show/hide LLM-originated connections.

### The prompt strategy (the real design work)

The LLM needs context to make good proposals. The prompt should
include:
- The work's full text
- The far-end works' texts (the connected corpus)
- The existing connection graph (what's already connected)
- The type vocabulary with definitions

```
You are reading a document in a hypertext system that supports
fine-grained bidirectional typed connections.

Document: [work text]
Connected works: [far-end texts]
Existing connections: [link summaries]
Available connection types:
  1. Comment — a note about the passage
  2. Reference — points to related content
  3. Disagreement — disputes the passage's claim
  4. Quotation — cites this passage elsewhere
  5. See Also — suggests related reading

Identify passages in this document that a critical reader would
connect to other content. For each, propose a typed connection
with a brief reasoning. Only propose connections you are confident
about — quality over quantity.
```

## What the research tells us about prompt design

From the 2024–2026 literature:

1. **LLMs are better at identifying weaknesses than suggesting
   fixes** (Saqr 2025) — so Disagreements will be their strongest
   contribution; References less so
2. **LLM arguments are linguistically different** (Dönmez 2025) —
   more formal, less personal. The system should NOT try to
   disguise this — transparency is the design
3. **Hybrid LLM-symbolic outperforms pure LLM** (Vasileiou 2026) —
   the LLM proposes, the formal system validates (our link
   vocabulary + span validation is the formal layer)
4. **Confidence scores are unreliable** (Sanayei 2025) — LLMs
   overestimate their certainty. The human-confirmation step is
   not optional
5. **Style matters for reception** (Verma 2025) — LLM
   counter-arguments with measured, evidence-focused style are
   endorsed more than aggressive ones. Prompt for restraint.

## Seeded demo scenario

### The WidgetPerfect LLM Review

Ruth posts her Technical Plan. She clicks "Suggest connections" —
the LLM reads it, sees Dan's already-posted Requirement, and
proposes:

1. **Disagreement** on "duralum funculator" → connects to Dan's
   cost data (high confidence: the cost analysis directly
   contradicts this choice)
2. **Reference** on "thermoplastic coupler" → connects to a
   materials work in the corpus (medium confidence: related but
   not contradictory)
3. **Comment** on the budget section → notes that the prototype
   volume assumption may be outdated

Ruth reviews the proposals:
- Confirms #1 (it's a real connection she hadn't made)
- Edits #2 to target a more specific passage
- Rejects #3 (she has newer data)

The confirmed connections enter the argument chain alongside Dan's
human-created Disagreement. Both carry endorsement counts. Both
are visible in Beams. Both are bidirectional. The LLM's
contribution is attributed with the model name in the tooltip.

## Exit criteria

- [ ] "Suggest connections" produces LLM proposals for a work
- [ ] Proposals render in the connection-authoring UI with
      type/reasoning/confidence
- [ ] Human can confirm/edit/reject each proposal
- [ ] Confirmed LLM links carry model-ID provenance
- [ ] LLM links appear in argument chains + Beams view
- [ ] LLM links are endorsement-filterable (same as human)
- [ ] Filter toggle: show/hide machine-originated connections
- [ ] Seeded demo: the WidgetPerfect LLM Review scenario

## Out of scope

- Fully autonomous LLM authoring (no human confirmation)
- LLM as judge/arbitrator (the community judges, not the model)
- LLM-generated content creation (only connection proposals)
- Real-time debate moderation
- Multiple LLM models debating each other (interesting but not
  the first step)

## The Miller quote this FR turns on

> "All readers of the system are potential authors."

The LLM is a reader. It reads, it connects, it participates. The
community decides whether its contributions are worth reading.
