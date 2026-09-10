# Representative Content Generation — design

## The problem

Our current corpus is test/demo data: seeded lessons, a compare pair,
a navigation tour. Fine for demos, wrong for H(G) measurement. The
paper needs profiles from corpora that represent REAL usage patterns
— different kinds of knowledge work, each producing a characteristic
link/transclusion structure. Then H(G) shows how one system (Xudanu)
supports multiple hypertext genres, occupying different corners of
profile-space.

## What the HT papers taught us about structures

| Source | Pattern | H(G) signature |
|---|---|---|
| Anderson (TfT) | Zettelkasten: atomic notes + hubs + MOCs | moderate d, high η (typed links), low θ (wiki = links not transclusion), moderate γ |
| Millard | AI-augmented vault: suggest-only, #human-tagged, maturity model | high η (provenance typing), low θ, high γ (constant revision), high D (no hub domination) |
| Seed Hypermedia | Federated conference proceedings: papers + anchored discussions + cross-node transclusion | high θ (transclusion between papers), ρrt=1, moderate d, moderate Q |
| H(G) paper | IRA social media (the contrast case) | sparse d, ρrt≈0, hub-dominated, high γ but low θ |
| Anderson (TfT) | Literary hypertext (Storyspace lineage) | moderate d, high S (branching), low η (untyped), γ=0 (finished works) |

## Four representative corpora to generate

### 1. Research Seminar (Zettelkasten-style)
**Models:** a researcher's working notes over a semester.
- 30-40 atomic works (200-400 words each, per Ahrens/Luhmann)
- 5-6 hub works aggregating themes
- 2-3 trail/MOC works sequencing the atoms into arguments
- Links: mostly Reference + See Also between atoms and hubs
- 2-3 transclusions (the researcher quotes their own earlier notes)
- Revisions: atoms stable; hubs/trails revised (the MOC evolves)
- **Expected profile:** moderate d, high η, low-moderate θ, high γ (trails revised), high D

### 2. Policy Debate (legal/compliance-style)
**Models:** opposing position papers + evidence chains.
- 3-4 position papers (long, multi-section)
- 10-15 evidence/source works (short, factual)
- Links: Disagreement (position↔position), Quotation (position→evidence), Comment (reader notes)
- Transclusions: positions include evidence passages by reference
- Revisions: positions revised; evidence immutable
- **Expected profile:** moderate d, very high η (all 5 types), high θ (evidence transcluded), moderate γ, lower D (evidence works are hubs)

### 3. Edition & Translation (literary/scholarly)
**Models:** a source text + translations + commentary.
- 1 source text (long, original)
- 2 translations (different translators, same structure)
- 5-8 commentary works (per-section annotations)
- Links: Quotation (commentary→source), See Also (translation↔translation)
- Transclusions: translations include source passages inline for alignment
- Revisions: source stable; translations revised; commentary grows
- **Expected profile:** high d (dense alignment links), high θ (alignment transclusions), low η (mostly Quotation), low γ (stable works)

### 4. Project Retrospective (Millard-style AI-augmented vault)
**Models:** a team's project log co-constructed with AI assistance.
- 40-50 daily/atomic works (short, timestamped, some AI-authored)
- 5-6 synthesis works (aggregating themes)
- Links: Comment + Reference (AI proposals + human curation)
- Transclusions: synthesis works include passages from dailies
- Revisions: dailies mostly stable; synthesis heavily revised
- **Expected profile:** low d (sparse connections), high γ (synthesis evolves), moderate θ, high D

## Implementation

`scripts/generate-representative.mjs <corpus-type> [ws-url]` —
generates a named corpus using the existing WS ops (work_create,
link_create, element_insert for transclusions, work_revise for
version history). Each corpus is deterministic (seeded RNG or fixed
content) so profiles are reproducible.

Then: `xudanu-server hg-profile` on each → four H(G) vectors → the
paper's comparative table: "one system, four genres, four corners of
hypertextuality space."

## Why this matters for the paper

The H(G) paper measured ONE system (IRA tweets). We can show H(G)
across FOUR genres within one system — demonstrating that Xudanu
doesn't just implement one hypertext ideology, it supports the full
gradient. That's the "complete model" claim, measured.

Also: corpus 4 (AI-augmented) directly engages their open Q4 —
H(G_AI) vs H(G_human) on AuthorType-labeled spans. The first
supervised comparison in existence.
