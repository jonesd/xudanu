# Gold's Optimizations — Coles Notes

The Udanax Gold optimizations, as naive → Gold contrasts. One or two
sentences each. Where each lives in Xudanu as of September 2026.

| # | Optimization | Naive → Gold | In Xudanu |
|---|---|---|---|
| 1 | **Enfilade (dual-purpose tree)** | Naive: text as an array — every insert shifts everything after it, O(n). Gold: a balanced tree holding content *and* structure, so edits touch only one path down, O(log n). The whole system is this one data structure wearing different hats. | `edition/orgl.rs` — the enfilade (FR-34 A-3) |
| 2 | **Crums (subtree summaries)** | Naive: comparing two documents means walking every element, O(n). Gold: each subtree carries a content hash; equal crums mean identical subtrees — equality in O(1), diff descends only where crums diverge, O(size-of-difference). | BLAKE3 subtree crums (FR-34); measured in the paper's compare benchmarks |
| 3 | **Tumbler addressing + between-allocation** | Naive: positions are offsets; inserting early renumbers everything downstream. Gold: hierarchical addresses where a new address can always be *allocated between* two existing ones — nothing ever renumbers, forever. | Tumbler arc A–F (2026): stamps, `xan://` navigation, prefix regions, link targets, `?rev=` versioning, `Sequence::between` |
| 4 | **Displacements (wids/ispans)** | Naive: an insertion means finding and adjusting every stored pointer after it. Gold: edits become *displacements* stored once at a tree node; positions below stay valid because they're relative — the correction propagates lazily, and displacements compose. | Partial: `space/mapping.rs` composition + span migration; lazy propagation is not full wid semantics |
| 5 | **Prefix scoping** | Naive: "everything in this collection/project" = filter the whole store. Gold: a region *is* a tumbler prefix, so the hierarchy prunes the search — you only walk the branch you're in. | Regions Phase C: clubs carry prefixes; `SequenceRegion::prefixed_by` containment |
| 6 | **Transclusion (store once)** | Naive: quoting copies content — O(n) space per quote, and copies drift from their source. Gold: a quotation is a live reference; content exists once in the whole docuverse and is included by address. This is the economic thesis, not just an optimization. | Inline `RangeElement::Transclusion`; cross-server with BLAKE3 verification (FR-6/FR-41) |
| 7 | **End-sets (bidirectional links)** | Naive: "who links to this?" requires scanning all documents, O(N). Gold: a link is stored once with its complete end-set, and every end knows the link — connection lookup is O(1) from either side, in either direction. | FR-40 gathered end-sets; five built-in link types |
| 8 | **Inline coalescing** | Naive: one element per character — a page is thousands of nodes. Gold: adjacent same-kind elements merge into runs, so steady-state text is a handful of nodes; splits happen only at edit boundaries. | Inline coalesce (FR-34) |
| 9 | **Chunk-level diff** | Naive: sync/compare ships or scans whole documents. Gold: compare crums at coarse granularity first, descend only into mismatched chunks — bandwidth and time proportional to what actually changed. | Chunk-level diff + FR-59 revision compare |
| 10 | **Content addressing for identity** | Naive: identity by ID number or location — fragile, forgeable. Gold: identity *is* content (the hash), so "is this the same passage?" is answered by the address itself, and replication dedupes for free. | BLAKE3 content-addressed store; blob store; OTS anchoring on top |
| 11 | **Splay exposure** | Naive: uniform access cost no matter what you're working on. Gold: frequently-touched nodes migrate toward the root, so the working set gets amortized near-constant access while cold text stays deep. | Partial: splay exposure at Edition level (FR-34) |
| 12 | **Append-only storage** | Naive: rewrite files in place — history is lost or expensive. Gold-lineage: chunks are written once, never mutated; history, checkpoints, and audit are the *same* mechanism. | Chunk store + WAL + chained security log + hash-chain manifest history |

## The unifying idea

Gold never fixes up data it can make structurally unnecessary —
renumbering, copying, re-diffing, and pointer-chasing are all eliminated
by making the *structure* (trees, hashes, hierarchy, references) carry
the work.

## Attribution

For the full expanded version — every problem worked through with
diagrams and where a modern engine takes each further — see [The
Twelve Problems](https://dgjones.info/xudanu/gold-twelve-problems.html).

The mechanisms are inherited from the 1988–92 Udanax Gold implementation
(open-sourced 1999) and its design literature; the descriptions and the
naive-vs-Gold framing are ours. See FR-34 (`docs/dev/FR-34-enfilade-native.md`)
for the full enfilade-native roadmap and status.
