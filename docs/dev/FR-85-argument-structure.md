# FR-85 — Argument Structure: the shape of criticism, not just its existence

**Status:** specified, not started (September 2026)
**Source:** Mark Miller, "The Open Society and its Media" (1995) —
the argumentation layer the substrate was always meant to carry.
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

And the pathological failure mode he warns against:

> "Students occasionally will follow these criticism links forward.
> The result is that they will see the parts of the other school's
> literature that is most soundly criticized by their own school,
> immunizing them more and more against the foreign ideas."

The fix is not more links — it's making the *shape* of the link
graph legible: chains, not lists; status, not just existence;
absence as signal.

## Miller's key insights (from the chapter)

1. **The recursive question**: "What is the best argument against
   the thing I am reading right now?" and then "What is the best
   argument against *that*, in turn?" — an argument CHAIN, not a
   flat collection.

2. **Absence as signal**: the most conversationally obvious,
   electronically invisible fact. When a passage is disputed and the
   dispute has no rebuttal, THAT is the news. When a passage has
   never been disputed, that is also the news.

3. **School-division prevention**: bidirectional links exist, but
   the UI must surface cross-school criticism, not bury it in a
   list. Unidirectional *reading* (following criticism forward
   only) immunizes you against the other side's best arguments.

4. **Reputation-based filtering**: on important documents, the junk
   problem makes commentary useless without filtering by endorsement
   and type. "One can rely on documents such as a Guide to the
   Citations to the Bill of Rights, endorsed by a reputable
   publishing house."

5. **The WidgetPerfect pattern**: the logic of the system is not
   any individual link — it is the CHAIN of causation across them
   (requirement → detector fires → plan changes → budget changes).
   Detectors + argument chains = the machinery of distributed
   reasoning.

6. **Popper's evolutionary epistemology**: knowledge evolves by
   variation (conjecture), replication (publication), and selection
   (criticism). The system's job is to make the selection pressure
   visible — "criticism of criticism" — so ideas that survive are
   demonstrably better.

## Design

### 1. Dispute status (derived, not stored)

A passage's argumentative state is computed from its link graph:

| Status | Meaning | Visual |
|---|---|---|
| **uncontested** | No Disagreement links | No badge (absence is the default) |
| **disputed** | Disagreement exists, no rebuttal | Open red badge |
| **rebutted** | A response link exists to the disagreement | Badge with response count |
| **standing dispute** | Both sides have had their say | Contested badge (split color) |

Computed by: for each Disagreement link to a span, check if any
non-Disagreement link's origin work contains a passage responding
to the disagreement's far-end span. Heuristic initially; a proper
`responds_to` link property later.

### 2. Argument chains (the Links panel reorganized)

Disagreements render as **threads** in the Links panel:

```
▼ Disputed: "the funculator passage" (2 chains)
  ├─ ← Dan: requirement → titanalum (3 endorsements)
  │   └─ → Ruth: rebuttal — cost analysis (2 endorsements)
  │       └─ ← Dan: counter — market sectors justify cost (1)
  └─ ← Mark: quality concern (0 endorsements)
      └─ (no response — standing dispute)
```

Each chain is a tree: Disagreement → responses → counter-responses.
Sorted by endorsement count (best-against first). Chains without
responses show a subtle "awaiting response" indicator.

### 3. Best-against sorting

The existing endorsement system ranks links. For incoming
Disagreements, sort by total endorsement weight (author + named
endorsers). This answers Miller's recursive question directly:
the top chain IS the best argument against, and within each chain,
the top response IS the best argument against that.

### 4. Absence detection

When a work has ZERO incoming Disagreement links, its header (or
the library row) shows a quiet "uncontested" indicator. When a
DISPUTED passage has no response after a configurable time, the
dispute-status badge pulses (or darkens) — the electronic analogue
of a silence in conversation.

### 5. Argument-aware Beams

The Beams view (already showing connections as colored rays)
graduates into an argument landscape:
- Disagreement chains rendered as connected threads (not separate
  rays), so the argument's SHAPE is visible
- Dispute status encoded in the ray's weight or animation
- Cross-school criticism highlighted (links from works with no
  shared endorsement pool — "diverse origin" indicator)

### 6. Guides (Miller's "decentralized consumer reports")

A Guide is a curated view of the connections to a work or passage,
endorsed by a trusted source. Implementation: a work of kind
`guide` that contains transclusions of the disputed passages +
typed links to the best arguments. The existing compound-builder
machinery supports the composition; endorsement makes it findable.

## Implementation notes

- **Phase 1** (pure client): dispute status computation + argument
  chains in the Links panel + best-against sorting. No server
  changes — the link graph already has everything needed.
- **Phase 2**: absence indicators + Beams argument view.
- **Phase 3**: Guide composition + the `responds_to` link property
  for precise chain resolution (replacing the heuristic).
- The heuristic for "is this a response to that dispute": a link
  whose origin work was created AFTER the Disagreement link, whose
  origin span semantically references the dispute's far-end
  content, and whose type is not itself Disagreement. Initially:
  just check type ≠ Disagreement + temporal ordering + origin work
  ≠ the disputed work.

## Exit criteria

- [ ] Dispute status visible on marked passages (4 states)
- [ ] Links panel renders Disagreements as argument chains (trees)
- [ ] Chains sorted by endorsement (best-against first)
- [ ] Uncontested works identifiable at a glance (library + header)
- [ ] "No response" state visible on standing disputes
- [ ] Beams view shows chains as connected threads, not isolated rays
- [ ] One seeded gallery room demonstrating the full pattern
      (a work with resolved + standing disputes)

## Out of scope

- Formal logic / argument mapping (Toulmin model, etc.) — the
  social process first, formalization later if ever
- Automated argument evaluation (the SYSTEM judges nothing; the
  community's endorsements are the judgment)
- Real-time debate moderation

## The Miller quote this FR turns on

> "Electronic media can make these absences obvious as well, but in
> a context where the absence will be much more telling, because
> the missing argument could have come from a much larger audience
> over a more extended period of time."
