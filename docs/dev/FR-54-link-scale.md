# FR-54: Link Scale — corporate-adoption roadmap

> **Status:** planning (measured baseline recorded; no item started)
> **Created:** 2026-08-31
> **Prompt:** "backlinks/links are going to skyrocket, say if a
> corporation uses it" — what breaks first, in what order we fix it.
> **Companion:** FR-40 (the link model), the enfiladic-matching
> branch `fr40/enfiladic-link-canopy` (whose benchmark produced
> the baseline below).

## The concern, precisely

The canopy (FR-40 branch) fixed the QUERY path — matching is now
bounded by the answer set, not the corpus. But queries are not
where links hurt at scale. The paths that degrade with link count
are the WRITE path (every edit), the PERSISTENCE path (every
checkpoint), and the LOADING path (every work open).

## Measured baseline (2026-08-31, dev profile, 3000 links / 150 works)

| Path | Before canopy | After canopy | Notes |
|---|---|---|---|
| `link_query` (rare type, empty result) | 2.05 ms | 0.61 ms (3.3x) | debug build — release pass pending |
| `link_query` (rare type, matching) | 2.09 ms | 0.73 ms (2.9x) | |
| Pure canopy descent | — | **0.008 ms** | index itself is done; remaining path overhead is debug-build allocation noise |
| Entries visited (pruned descent) | 100% (scan) | **0%** | pruning WIDENS with corpus size: scan is O(L), descent is O(log + candidates) |
| `find_backlinks` | O(links-per-work) via `work_to_links` | unchanged | indexed; the answer set, not overhead |

Bench (retained, ignored-by-default):
`cargo test --features server --lib link_canopy_bench -- --ignored --nocapture`

## Cost inventory — where link count bites, ranked

### S1 — `work_to_links` accumulation is O(n²) on hot works (HOURS)

The per-work index is `Vec<BeId>` with linear `contains` checks on
every insert. Fine at hundreds; a flagship document accruing tens
of thousands of links pays quadratic accumulation on the insert
path. **Fix:** `HashSet<BeId>` (or sorted vec + binary search).
Smallest, do first — pure mechanical.

### S2 — checkpoint/manifest bloat (MEDIUM — the storage refactor)

Every checkpoint serializes ALL links into the manifest JSON:
100k links means giant writes, full-parse restores, and — coupled
with the blocking-checkpoint problem (strategic priority #5) —
request-dispatch stalls that grow with the corpus. **Fix:** this
IS strategic priority #2 (move pseudo-pointers into the chunk
store): links persist as chunks, the manifest keeps references.
Solves size, restore parse, and unblocks non-blocking checkpoint.

### S3 — span migration on every edit (THE WALL — the position-keyed index)

Every `revise_work` walks ALL links touching the work × their
attachments, checking positions against the edit window. A
canonical document with 10k links pays a 10k-link scan on EVERY
edit batch — and edits are the hottest path in a collaborative
CRDT system. This is the one that breaks a corporate deployment
first. **Fix:** per-work INTERVAL INDEX over link spans
(position-keyed, maintained through migration — positions change,
unlike the work-keyed canopy). The FR-40 canopy keys on (work,
link, end) precisely so migration never touches it; S3 is the
complementary structure that makes migration itself sublinear:
edit window → affected spans via interval lookup → migrate only
those ends. The two indexes together close the loop.

### S4 — frontend link loading (MEDIUM)

`useTransclusion` loads ALL links for a work and builds every
marker: 10k links on one work = full payload + marker build on
open, before the user sees anything. **Fix:** paginate or
viewport-filter link loading; the marker layer already supports
deferred resolution (excerpt fallback), and B.2's link-data-driven
surfaces (gutter badges, bottom bar) tolerate partial loads by
design.

### S5 — backfollow registration cost (AUDIT)

`register_link_content` / `unregister_link_content` run on every
link mutation; cost per call at scale is unprofiled. **Action:**
measure before designing — it may be a non-issue.

### S6 — canopy query fixed overhead (PROFILE)

The ~600 µs gap between pure descent (8 µs) and the full query
path in the debug bench. Likely debug-build allocation noise;
**action:** one release-mode bench pass; only act on what
survives optimization.

## Sequencing

```
S1 (hours)            -> do immediately, zero risk
S2 (storage refactor) -> already strategic priority #2; links are
                          a beneficiary, not the driver
S3 (interval index)   -> the corporate-scale trigger item; design
                          note first (it composes with the FR-40
                          canopy and rides the same derived-data
                          contract: rebuild at restore, maintain
                          through migration)
S4 (frontend)         -> when link-heavy works appear in practice
S5, S6 (audit/profile) -> cheap measurements, no pre-work
```

## Success criteria

A flagship document with 10k links and a server with 100k links:
- edit latency independent of link count (S3)
- checkpoint size independent of link count (S2)
- work-open payload proportional to the viewport, not the corpus (S4)
- queries bounded by answer sets (DONE — the canopy)

## Relationship to prior work

| FR/priority | Relationship |
|---|---|
| FR-40 | The link model this scales; the canopy is the query-side half |
| Strategic #2 (storage refactor) | S2 IS that refactor's link slice |
| Strategic #5 (non-blocking checkpoint) | unblocked by S2 |
| `fr40/enfiladic-link-canopy` branch | baseline measurements; merges independently |
