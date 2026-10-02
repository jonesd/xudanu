# FR-85 — Argument Structure: the shape of criticism, not just its existence

**Status:** Phase 1 in progress (September 2026)
**Source:** Mark Miller, "The Open Society and its Media" (1995) —
the argumentation layer the substrate was always meant to carry.
**Design lineage:** Buckingham Shum's ClaiMaker/Cohere (2002–2010)
— the closest published continuation of Miller's argumentation
vision. Key papers: "Cohere: Towards web 2.0 argumentation" (2008,
189 citations), "Hypermedia Discourse: Contesting networks of ideas
and arguments" (2007), "Modeling naturalistic argumentation in
research literatures" (2007).
**Related:** FR-40 (typed links), FR-46 (endorsement), FR-80
(detectors), FR-59 (revision compare), FR-84 (split authoring —
disputes are made in panes), Beams view.

## Why

The substrate ships: fine-grained bidirectional extrinsic typed
links, transclusion, versioning, detectors, endorsements. But the
*argument structure* — the thing Miller's chapter is actually about —
is invisible. The Links panel lists connections flatly; you cannot
see whether a dispute has been answered, what the strongest
criticism is, or whether the absence of criticism is itself the
signal. Miller's core insight:

> "A reader not only can see what the most compelling arguments are
> against some statement, but also see when there are none, or when
> all the seemingly compelling arguments have been successfully
> refuted. Such absences are quite obvious in conversation."

## Design lineage (Buckingham Shum's lessons)

Nobody combined Miller's substrate with the argument visibility
layer. The closest attempts:

| | ClaiMaker/Cohere | IBIS tools | Xudanu |
|---|---|---|---|
| Fine-grained | approximated | node-level | ✓ |
| Bidirectional | partial | partial | ✓ |
| Extrinsic | partial | partial | ✓ |
| Transclusion | ✗ | ✗ | ✓ |
| Federated | ✗ centralized | ✗ | ✓ |
| Social filtering | partial | ✗ | ✓ |
| Argument chains visible | ✓ centralized | ✓ formal | **this FR** |

Buckingham Shum's design guidance (from 8 years of user studies):

1. **Keep the argument vocabulary small** — 5–7 relation types was
   the sweet spot; more confused users. Our 7 builtins fit.
2. **Social filtering > formal logic** — endorsement-based ranking
   outperformed argument-scheme classification (IBIS). Miller chose
   the same: reputation, not formal schemas.
3. **The argument network wants to be visualized as a network** —
   Cohere's graph view was the most-used feature. Not a flat list.
4. **"Contested" is the right word** — not "resolved" or "proven."
   The system shows the state of the contest, not a verdict.
5. **Claims are addressable, connections are typed** — ClaiMaker's
   core data model, identical to our link + type system.

## Miller's key insights (from the chapter)

1. **The recursive question**: "What is the best argument against
   the thing I am reading right now?" and then "What is the best
   argument against *that*, in turn?"

2. **Absence as signal**: when a passage is disputed and the
   dispute has no rebuttal, THAT is the news. When a passage has
   never been disputed, that is also the news.

3. **School-division prevention**: bidirectional links exist, but
   the UI must surface cross-school criticism. Unidirectional
   *reading* immunizes you against the other side's best arguments.

4. **The WidgetPerfect pattern**: the logic is not any individual
   link — it is the CHAIN of causation across them.

## Design

### 1. Dispute status (derived, not stored)

| Status | Meaning | Visual |
|---|---|---|
| **uncontested** | No Disagreement links | No badge |
| **disputed** | Disagreement exists, no response | Open red badge |
| **rebutted** | Response link exists | Badge with count |
| **standing** | Both sides have had their say | Split-color badge |

### 2. Argument chains in the Links panel

Disagreements render as threads (dispute → response → counter),
sorted by endorsement weight (best-against first). "Awaiting
response" indicator on standing disputes.

### 3. Best-against sorting

Sort incoming Disagreements by total endorsement weight. The top
chain IS the best argument against; within each chain, the top
response IS the best argument against that.

### 4. Absence detection

Uncontested works show a quiet indicator. Disputed passages with
no response after a time threshold signal the absence.

### 5. Argument-aware Beams

Disagreement chains as connected threads in the Beams view, not
isolated rays. Cross-school criticism highlighted.

### 6. Guides (Miller's "decentralized consumer reports")

Curated views of the connections to a work, endorsed by a trusted
source. Built on compound-builder machinery + endorsement.

## Implementation

- **Phase 1** (pure client): dispute status computation + argument
  chains in the Links panel + best-against sorting. ✅
- **Phase 2**: absence indicators + Beams argument view. ✅
- **Phase 3a**: `responds_to` link property — exact chain semantics. ✅
  Wire op `link_set_responds_to` (0x0f2b); persisted on LinkEntry +
  LinkSnapshot; exposed in LinkPayload; the client chain computation
  prefers the exact property and keeps the heuristic only for legacy
  links; "↩ respond" affordance on awaiting-response chains creates
  the response link (current selection rides as the excerpt).
- **Phase 3b**: Guide composition — remaining.

## Seeded demo scenarios

### Scenario A: The WidgetPerfect Saga (Miller/Stiegler)

Recreate the full chain from the chapter:
- Ruth's Technical Plan (the contested work)
- Dan's Requirement: titanalum funculator (Disagreement to a passage)
- Ruth's Rebuttal: cost analysis (Reference to Dan's criticism)
- John's Budget Note: cost impact (Reference to Ruth's plan)
- Ruth's detector fires → the chain is visible end-to-end

Demonstrates: argument chain, dispute status transitions
(uncontested → disputed → rebutted), detector integration.

### Scenario B: The Cross-School Debate (Miller's school-division)

Two "schools" disagreeing about the same passage:
- School A's Paper (the contested work, passage-level)
- School A's Critic #1: strong Disagreement (3 endorsements)
- School B's Response: rebuttal to Critic #1 (2 endorsements)
- School A's Counter: response to B's response (1 endorsement)
- School B's Critic #2: separate Disagreement on same passage
  (0 endorsements — low-ranked, shown last)

Demonstrates: multiple chains on one passage, best-against sorting
(Critic #1 first, Critic #2 last), cross-school visibility, the
school-division prevention Miller describes.

### Scenario C: The Absence (uncontested vs standing dispute)

Two works side by side in the library:
- Work A: heavily disputed, all disputes rebutted (status: "standing")
- Work B: never disputed (status: "uncontested")

The visual contrast IS the demo: absence as signal.

## Exit criteria

- [ ] Dispute status visible on marked passages (4 states)
- [ ] Links panel renders Disagreements as argument chains
- [ ] Chains sorted by endorsement (best-against first)
- [ ] Uncontested works identifiable at a glance
- [ ] "No response" state visible on standing disputes
- [ ] Seeded scenarios A + B demonstrable in the gallery
- [ ] Beams view shows chains as connected threads

## Out of scope

- Formal logic / argument mapping (Toulmin, IBIS schemas)
- Automated argument evaluation
- Real-time debate moderation
