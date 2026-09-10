# H(G) Profiling — design and implementation plan

Feature: compute the Adamski/Błocki/Pisarski/Szewczyk ten-dimensional
hypertextuality profile (HT '26, "Hypertext as the Native
Architecture of Reality") over a Xudanu data dir, as an
`xudanu-server hg-profile <data-dir>` subcommand. First measured θ
(transclusion) > 0 in existence; the figure nobody else can produce.
Paper hook: their §5.4 invites validation against real corpora; our
docuverse realises ρrt→1, θ>0, η high — the corner they only
theorised.

## Graph extraction (from a restored Server)

- **Nodes V**: every work (by BeId). Self-edges skipped (counted
  separately as `self_edges`).
- **Edges E**, each with a type label:
  - **Link edges**: for each link, for each end, an edge
    origin→end-target. Label = first link type id mapped through
    built-ins (1=Comment, 2=Reference, 3=Disagreement, 4=Quotation,
    5=See Also, 6=Web, else "custom"). Ends from
    `HyperLink::ends()` (each attachment's target work).
  - **Transclusion edges**: for each work's edition entries, each
    `RangeElement::Transclusion { source_work_id }` gives an edge
    includer→source, label "transclusion".
- Multigraph kept as weighted adjacency (parallel edges counted,
  η uses per-edge labels).

## The ten coordinates (formulas chosen; methodology strings ship
in the output JSON so the paper can cite them exactly)

1. **d relation density** = |E| / (|V|·(|V|−1)), directed, no self
   loops.
2. **ρrt reverse-traversability** — SYSTEMIC (the paper's phrase:
   "the degree to which 'what links here?' is answerable"):
   fraction of edges whose reverse query the DATA MODEL answers.
   Xudanu links store both ends + backlink index (`work_to_links`);
   transclusions carry backfollow. → ρrt = 1.0 by construction
   (reported honestly as such). ALSO report ρrt_mutual = fraction
   of ordered pairs with edges both directions (the structural
   reading their IRA number likely used — comparable to their
   8.99e-5).
3. **D decentralisation** = 1 − HHI(degree), where HHI =
   Σᵢ sᵢ², sᵢ = degreeᵢ/Σdegrees (in+out, undirected view).
   Hub-dominated → HHI high → D low. (Their IRA: 0.543.)
4. **Q modularity** = label-propagation communities (deterministic:
   iterate nodes in id order, tie-break smallest label; 20 passes
   or until stable) on the undirected projection, then
   Q = Σ_c [ e_c/m − (deg_c/(2m))² ].
5. **η relation-type heterogeneity** = H(label distribution) /
   ln(k), k = distinct labels present on edges.
6. **θ transclusion / multi-contextuality** = (works that are the
   SOURCE of ≥1 inline transclusion) / |V|. Plus raw counts:
   transclusion count, mean contexts per transcluded source.
   (Their IRA: 0.119. Web: "limited". Xanadu: ideal 1.0, never
   measured.)
7. **S structural entropy** = H(frequency distribution of degree
   values) / ln(K), K = distinct degree values.
8. **P path compactness** = 1/(1+L̄), L̄ = mean shortest-path length
   over reachable ordered pairs (exact BFS — docuverse sizes are
   small; note sampled-BFS upgrade path for large dirs).
9. **κ robustness** = giant-component size after targeted removal
   of the top 1% by degree / giant size before (undirected).
   (Their IRA: 2.32e-5 — collapse.)
10. **γ generative capacity** = fraction of nodes with version
    history (work.revision_count() > 1) — a static-corpus LOWER
    BOUND on the live property; a running server with CRDT traffic
    exceeds it. (Their IRA: 0.928.)

Also emitted: node/edge counts, label histogram, self-edge count,
xudanu version, and per-coordinate methodology strings.

## Code layout

- `src/server/hg_profile.rs` — `HgProfile` (serde Serialize, all
  ten + counts + methodology map) and `pub fn hg_profile(&Server)
  -> HgProfile`. Pure — no IO; restores happen in the bin.
- `src/bin/xudanu-server.rs` — subcommand `hg-profile <data-dir>`:
  `Server::new()` + `restore_from_data_dir(path, None)` + profile +
  pretty JSON to stdout (pattern: same restore the run path and
  tests use).
- Register module in `src/server/mod.rs`.

## Armor tests (offline, synthetic servers)

- two works + one Comment link → d exact, ρrt=1.0, η=0.0 (one
  label), θ=0.0 (no transclusions)
- add a second link of a different type → η > 0
- insert one inline transclusion work A→B → θ = 1/|V| exact,
  "transclusion" label appears in histogram
- star graph (one hub, 4 spokes) → D low, κ collapses after hub
  removal (κ < 1)
- deterministic: same dir twice → identical JSON

## First real measurement

Run against `data-link-demo` (the navigation-tour corpus: 4 works
with every link shape + 2 real transclusions + the seeded course).
Result goes into the paper skeleton as the H(Xudanu) table. ALSO
answers their open Q4 directionally: authorship-typed edges (via
AuthorType) enable H(G_AI) vs H(G_human) as a follow-up.

## Follow-ups (parked)

- H(G_AI) vs H(G_human) on authorship-labeled spans (their Q4,
  supervised by AuthorType — unique to us)
- Consolidated "paper ideas → Xudanu extensions" doc (user request,
  queued after this build)
