# FR-37: Virtual Enfilade Resolution

> **Status:** Phases 1-2 landed; Phase 3 core landed (element,
> pinning, determinism, placement/materialize APIs, read-flow
> integration, wire-payload registration). Follow-up: Phase 4 virtual
> enfilades.
> **Estimated effort:** 3-4 weeks (Phases 1-2), 2-3 months (full)
> **Risk:** Medium-High — touches transclusion resolution and CRDT paths
> **Prerequisite:** FR-34 Phase I (done: tree-native deltas, stable
> positions); close coordination with FR-26 Phase 4 (spanfilade)
> **Gold lineage:** `OExpandingLoaf` / virtual range elements
> (`src/server/loavesx.hxx` — `fetch` "makes a virtual range element
> using the edition and globalKey")

## Decision Question

How does Xudanu make transclusion *live by construction* — the
transcluded content always reflects its source at read time — instead
of *live by cache invalidation* (re-stamping `cached_content` whenever
sources change)?

The answer shapes:
- Whether "edit the original, watch every quotation update" holds
  with no staleness window (the demo Roger Gregory would run first)
- Whether derived documents (trails, search views, backlink views,
  compounds) can be first-class, addressable enfilades
- How much of FR-26 Phase 4 (spanfilade) can be reached incrementally

## Background: What We Have Today

`RangeElement::StructuralTransclusion` references a source work by
ID + char range + `source_crum`, with `cached_content: Option<String>`
materialized by resolve paths (`Server::resolve_inline_recursive`,
`ensure_transclusion_caches`). Correctness mechanisms already in
place:

- `source_crum` — BLAKE3 of the referenced source span, so staleness
  is *detectable* (FR-26 Phase 1)
- Revision pinning + blob snapshots (FR-26 Phases 2-3) — deleted or
  edited sources remain retrievable
- Per-node crum caches maintained incrementally (FR-34 S2) — O(1)
  subtree equality anywhere in the tree

The gap: resolution *materializes* strings into the element. Every
source edit must trigger re-stamping; readers between re-stamps see
stale content; and derived views (trails, search) cannot be enfilades
at all — they are JSON built per request.

## What Gold Did

Gold's loaves compute content on demand. `Loaf::fetch` (loavesx.hxx)
returns a *virtual* range element "using the edition and globalKey"
when the content lives in another structure; `OExpandingLoaf` covers
regions whose content is derived rather than stored. Nothing is
re-stamped because nothing is cached — reading IS resolving.

Gold could do this because there was one user, one server, no CRDT.
Xudanu must additionally guarantee that virtual resolution is
**deterministic across replicas** (CRDT convergence) and cheap under
concurrent edits.

## Decision

Four phases, each independently shippable. Phases 1-2 are cache
discipline and unify resolution behind one API — low risk, immediate
robustness wins. Phases 3-4 introduce true virtual structures.

### Phase 1 — Resolution API unification (groundwork, landed with this FR)

- `Edition::resolve_span(work_id, char_start, char_end) -> ResolvedSpan`
  as the single entry point for "what is the content of this range,
  following transclusions to depth d" — today the logic is spread
  across `resolve_inline_recursive`, cache-stamping paths, and diff
  narration
- Span-ownership query (`span_owner_license`) — see FR-38 groundwork;
  virtual resolution needs an authoritative "who controls this span"
  for license checks at resolve time
- All existing callers migrate to the unified API (no behavior change;
  regression tests pin outputs)

### Phase 2 — Generation-checked resolution cache (LANDED, commit b16a4eb)

Delivered as specified; plus a pre-existing gap it exposed: plain
work_revise (full-edition replace) never migrated dependents — fixed.


- Extend `StructuralTransclusion` with `source_generation: Option<u64>`
  (monotonic per source work, bumped on every revise)
- `cached_content` becomes valid iff `source_generation` matches the
  source's current generation OR `source_crum` matches (crum check
  stays the cross-restart authority; generation is the cheap in-memory
  check)
- Read paths: on mismatch, resolve lazily *at read time* rather than
  waiting for the background re-stamp — eliminates the staleness
  window without Phase 3
- Effort: ~1 week. This alone makes transclusion observably live.

### Phase 3 — Virtual elements (CORE LANDED)

Landed: `RangeElement::Virtual { spec: VirtualSpec, cached_content }`
with spec-fingerprint determinism (fingerprints cover the spec, never
the cache — replicas align without resolution); edit-time revision
pinning at placement (`place_virtual_transclusion`); pinned-resolution
materialization (`materialize_virtual_elements`, wired into
work_text_fresh — one pass per element, ever, since pinned revisions
are immutable); zero-char-until-materialized reader contract (same
precedent as unstamped StructuralTransclusion). Tests: pin stability
across source edits, survival through unrelated delta edits,
fingerprint determinism. Wire-payload registration landed:
RangeElementPayload carries `virtual` elements with mandatory
`virtual_revision` (unpinned virtuals are rejected on the wire —
replica determinism enforced at decode); spec fingerprints survive
the JSON round trip; placed_at/by stay placement-side metadata.
Delta-path neighborhood materialization remains bulk-fallback
(adequate today).

- `RangeElement::Virtual { source: VirtualSpec, span_len }` where
  `VirtualSpec` names (source work, tumbler address, revision pin)
  and content is computed through `resolve_span` on `char_len`/`as_text`
  — the Rust analogue of Gold's virtual range element
- Materialization happens only where the CRDT requires fingerprints
  (merge alignment, diff): the delta path materializes the touched
  neighborhood, never the whole document
- Determinism rule: a `Virtual` element's resolved bytes are a pure
  function of (source revision id, span). Revision pinning (FR-26
  Phase 2) guarantees replicas converge; a `Virtual` element pointing
  at "latest" is resolved to a concrete revision at *edit* time
  (edit-time pinning), keeping replicas deterministic
- Effort: 3-6 weeks. Risk: the S5 fast path must treat `Virtual`
  like zero-char structural elements during assembly (splitting a
  virtual span = two narrower virtual spans)

### Phase 4 — Virtual enfilades (derived documents)

- Infinite-domain leaves already exist (`from_all(above(0), default)`);
  generalize `default` from a constant element to a computed
  resolution over another edition — trails (FR-20/25), search results,
  and backlink views become real, tumbler-addressable enfilades
- Compound documents (Phase H territory) assemble naturally as
  virtual enfilades over multiple sources
- This is where FR-37 and FR-26 Phase 4 (spanfilade) meet: spanfilade
  stores history at the I-stream level; virtual enfilades read through
  it. Full spanfilade remains optional — Phases 1-3 deliver the
  user-visible value without it

## Phase 4 Design Note — Virtual Enfilades (decided Aug 2026)

### The fork

Phase 4 can mean two different depths of "derived documents become
real enfilades." The decision below was taken before implementation,
per the project rule that design rationale gets captured where future
contributors will find it.

**Path A — Composition (CHOSEN for 4a-4d).** A derived document is an
`Edition` whose entries are Phase 3 `Virtual` elements: a trail is a
sequence of pinned spans from multiple works; a search view is
matching spans; a backlink view is quoting spans. Everything deep
already exists and is tested — spec determinism, edit-time pinning,
pinned-revision resolution, zero-char-until-materialized, delta-path
splitting. New work is a serializable `DerivedSpec`, a spec->edition
builder, and server plumbing so trails/search/backlinks produce
WORKS (addressable, linkable, transcludable-from) instead of JSON
responses.

**Path B — Enfilade-native (deferred; separate arc if ever).**
Generalize `Edition::from_all`'s constant default into computed
resolution: content with no entries until touched, Gold's true
OExpandingLoaf structure. Deep: touches the Loaf type, region
semantics over unresolved content, crum discipline for computed
subtrees. Path A is its natural prerequisite either way — the spec
algebra and resolver semantics get proven in A before B inherits them.

**Rationale**: A delivers the user-visible Xanadu property ("derived
views are first-class documents in the docuverse") on proven
machinery in ~1-2 weeks; B is weeks of enfilade-internals work whose
payoff (memory for enormous derived views) matters only at scales
nothing currently reaches. If profiling later justifies B, the
decision point is documented here.

### Slices (each independently shippable)

- **4a — `DerivedSpec` + determinism.** Serializable spec:
  `kind (Trail|Search|Backlinks)`, ordered `VirtualSpec` list,
  presentation metadata (titles, stops). Property test: same spec ->
  same edition (byte-identical entry sequence, same crums), always.
- **4b — Resolver + equivalence.** `build_derived_edition(spec)`:
  one Virtual element per stop at spaced positions (Stage 4 allocator
  spacing). Equivalence gate: a trail rendered as a derived edition
  yields the SAME TEXT as today's trail JSON rendering — the
  migration pin.
- **4c — Trails as derived works.** Server: `trail_create` /
  `trail_add_stop` build/refresh a derived work whose edition comes
  from the spec; the existing trail JSON API becomes a read of that
  work. Trails become grabbable, linkable, tumbler-addressable.
- **4d — Generation-keyed derived-work refresh.** When a source work
  revises, dependent derived works rebuild lazily on next read (same
  generation discipline as FR-37 Phase 2 — no staleness window, no
  eager invalidation storm).

### Standing rules (inherited, non-negotiable)

1. Nothing derived enters content crums — pure BLAKE3 stays.
2. Every cache keyed by pinned revision (Phase 3 rule).
3. Derived works are ordinary works: permissions, licensing (FR-38
   span queries just work on them), federation, and GC treat them
   identically. No special-casing downstream.

### Explicitly out of scope for 4a-4d

- Search/backlink views (the spec supports them; only the trail
  builder ships — the others are follow-ups once the pattern proves).
- Cross-server derived specs (stops referencing remote works —
  blocked on FR-6 resolution maturity anyway).
- Path B internals.

### Success criteria

- 4a property green; 4b equivalence green (trail text identical to
  legacy rendering); 4c trail round-trip via wire as a real work;
  4d concurrent source-edit/read interleave with zero stale reads.

## What We Explicitly Do NOT Do

- No caching of resolved content inside crum-hashed structures —
  content crums stay pure BLAKE3 (the S2/S5 merge fast-paths depend
  on it); resolution results live in read-side caches keyed by
  (source revision, span), never in the tree
- No async resolution inside `fetch` — resolution is synchronous and
  bounded by depth (existing 1000-depth cycle guard); cross-server
  resolution failures surface as errors, not stale content

## Success Criteria

- Phase 2: editing a source immediately changes every reader's view
  of its transclusions (no re-stamp latency) — test: concurrent
  edit/read interleave with zero stale reads
- Phase 3: property test — virtual and materialized editions of the
  same spec produce identical text; CRDT convergence test with virtual
  elements present in both replicas
- Phase 4: a trail renders as an enfilade; a tumbler address into the
  trail resolves to live source content

## Relationship to Prior Work

| Mechanism | Provides | FR-37 builds on it |
|---|---|---|
| FR-26 P1 `source_crum` | staleness detection | generation check fast-path |
| FR-26 P2 revision pinning | deterministic source identity | edit-time pinning rule |
| FR-34 S2 crum caches | O(1) subtree equality | virtual span equality via pinned crums |
| FR-34 S4/S5 stable positions + fast path | localized materialization | only touched neighborhoods materialize |
