# FR-38: License Summary Overlays

> **Status:** Planning (groundwork landed)
> **Estimated effort:** 1-2 weeks (Phases 1-2), 2-3 weeks (Phase 3)
> **Risk:** Low-Medium — additive overlay; content crums untouched
> **Prerequisite:** FR-24 (license model — done); FR-37 Phase 1
> (span-ownership query — landed with this FR)
> **Gold lineage:** `CanopyCrum` flag words (`src/server/canopyx.hxx`
> — "CanopyCrums form binary trees that accrete in a balanced
> fashion... Any interesting Club or endorsement gets a bit... These
> flags are widded by ORing up the canopy")

## Decision Question

How does Xudanu make the per-span license question — *may this
principal transclude chars 40-60 of this work, under whose terms?* —
cheap enough to ask on every read, every transclusion placement, and
every federation replication decision?

The answer shapes:
- Whether Transcopyright (FR-24) is enforced per-span or degrades to
  work-level checks under load
- Whether cross-server sharing (FR-6/31) can replicate "only what
  peers may see" structurally
- Whether per-span licensing scales to documents with thousands of
  ownership boundaries

## Background

FR-24 gives every work a `License` (five options). Element provenance
(`author_club_id` per entry) and signed span provenance give per-span
*ownership*. What does not exist: an index from spans to license
terms that answers region queries without scanning entries.

Gold solved the same shape of problem with CanopyCrum overlays:
parallel trees above the loaves whose nodes carry OR-ed flag bits
(endorsements, Clubs), so permission queries prune whole subtrees.
Ravi's 1992 comment also carries the design's documented limit:
"Any criteria not given a bit of their own require an exhaustive
search" — bits are a fixed summary; rare queries fall back to search.

## Decision

### Design rule (the one that matters): separation

Content crums stay pure BLAKE3 — the S2/S5 merge fast-paths and
FR-26 staleness detection depend on crum equality meaning content
equality. License summaries live in a **separate overlay** keyed by
the same regions, exactly as Gold kept CanopyCrums distinct from
loaves ("myRefCount is only the count of Loafs or HCrums that point
at the CanopyCrum"). An overlay miss or staleness NEVER affects
content correctness — worst case, a query falls back to scan.

### Phase 1 — Groundwork: license classes + span-ownership query (landed)

- `LicenseClass` bitflags derived from the existing `License` enum:
  `FREE` (Public Domain), `ATTRIBUTION` (CC-BY, CC-BY-SA),
  `TRANSCLUSION_OK` (TCo), `RESTRICTED` (ARR). Four bits, one byte;
  derived, never stored independently, so no migration
- `License::license_class()` and `LicenseClass::combine()` (the OR
  monoid the overlay will widd upward)
- `Edition::span_owner_license(char_start, char_end) -> SpanLicenseSummary`
  — the authoritative ground-truth query: walks the span's entries,
  resolves each to (provenance owner -> owner work -> license),
  ORs the classes, reports the ownership boundaries crossed and any
  unknown-owner gaps. This is the fallback the overlay accelerates
  and the seed data any overlay indexes
- Tests: mixed-license spans, provenance-less spans (owner falls back
  to work-level license), zero-char elements, full-range queries

### Phase 2 — Overlay structure

- `LicenseOverlay`: nodes mirroring enfilade regions
  (`region -> (bits, span_count)`), maintained on edit paths the same
  way S2 maintains crums — an edit that changes an entry's license
  class re-ORs O(log n) ancestor nodes; insertions/deletions splice
  overlay nodes alongside tree nodes
- Rebuild-from-scratch = Phase 1 query over the full edition (used on
  restore, and as the overlay's own regression check)
- Stored in the work's chunk alongside the edition (typed snapshot
  field; absent field = rebuild lazily)

### Phase 3 — Overlay queries + integration points

- `LicenseOverlay::query(region) -> LicenseClassSet` — O(log n + b)
  descent: "all free" / "all restricted" prune; mixed nodes descend
  only where bits change
- Integration:
  - Transclusion placement (UI + server): badge computation becomes
    an overlay query instead of a work-level lookup
  - Cross-server resolution (FR-6/31): origin server answers
    may-transclude with an overlay descent
  - Federation replication (FR-35): "replicate only spans visible to
    peer cluster" prunes by overlay before Bloom-filter exchange
  - Rule-9 micropayment hooks (future): per-span fee bits are one
    more flag, not a new structure

### The documented limit (inherited from Gold)

Bits cover license *classes* — the common queries. "Who exactly owns
this span" and arbitrary per-club queries fall back to Phase 1's
ground-truth scan. If per-club granularity at scale becomes a real
product requirement, the escalation path is indexed secondary
structures (Gold's deferred "PropJoints" rebirth), not more bits.

## Complexity

| Query | Today | With overlay |
|---|---|---|
| may_transclude(span) | O(span entries) provenance walk | **O(log n + b)**, b = ownership boundaries crossed |
| License change on edit | n/a (work-level only) | O(log n) overlay re-OR |
| Overlay rebuild | n/a | O(n) on restore |
| Replication filter | O(n) scan per rule | prune by subtree |

## Success Criteria

- Phase 1: mixed-ownership document query returns correct classes and
  boundaries; matches a hand-computed fixture
- Phase 2: overlay equals ground-truth query after arbitrary edit
  sequences (property test — the same discipline as the S2
  crum-equality property)
- Phase 3: transclusion badge on a 100k-entry document answers in
  microseconds (vs milliseconds scan); federation filter demonstrably
  prunes replication sets

## What We Explicitly Do NOT Do

- No license bits inside content crums or the entries cache
- No enforcement of licenses the server cannot evaluate (ARR on a
  remote work without server cooperation is display-only, as FR-24
  established)
- No per-user bits (fixed class bits only); per-principal queries go
  through ground truth
