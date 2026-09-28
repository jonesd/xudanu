# Wiki draft: system map (how the Gold mechanisms fit together)

> Target: a "Design" / "Architecture" section. Compact, factual,
> sourced to the 1988–92 sources and design literature. The map is
> the contribution: one place a general developer can see the parts
> and their interactions.

## Design: the mechanisms and how they interact

Udanax Gold's engine is organized around one dual-purpose data
structure and a small set of mechanisms built on it:

| Part | Role |
|---|---|
| **Enfilade (Orgl)** | Balanced tree holding both content and structure; edits touch one root-to-leaf path, O(log n) |
| **Crums** | Per-subtree content hashes; equal crums prove identical subtrees, so comparison descends only where hashes diverge |
| **Tumblers** | Hierarchical addresses; a new address can always be allocated *between* two existing ones, so nothing is ever renumbered |
| **Displacements (wids/ispans)** | Edits stored as relative corrections at tree nodes; stored positions below stay valid without fix-up |
| **End-sets (links)** | A link is stored once with its complete set of ends; every end knows the link, making backlinks O(1) from either side |
| **Transclusion** | Quotation as live reference by address; content exists once in the docuverse (the basis of the proposed copyright/micropayment model) |
| **Chunk store** | Append-only, content-addressed storage; history, checkpointing, and audit are the same mechanism |

Interaction sketch:

- A document edit becomes a displacement in the enfilade; crums
  recompute up one path; tumbler addresses of untouched content are
  unchanged by construction.
- A link end references a tumbler span; because links carry complete
  end-sets, both directions of navigation are local lookups.
- Comparison or synchronization of two documents walks crums from the
  root down, visiting only differing subtrees — cost proportional to
  the difference, not the documents.
- Identity is content-derived (hashes), so replication deduplicates
  for free and "same passage?" is answered by the address itself.

The unifying idea attributed to the design: never fix up data that
structure can make unnecessary — renumbering, copying, re-diffing,
and pointer-chasing are eliminated by the tree, the hashes, the
hierarchy, and the references carrying the work [src: sources +
"Gold's Optimizations — Coles Notes", 2026].
