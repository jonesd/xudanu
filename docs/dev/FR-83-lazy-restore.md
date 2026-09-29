# FR-83 — Lazy Restore: boot in seconds, materialize enfilades on demand

**Status:** specified, not started (September 2026)
**Diagnosed from:** dev-server restore of 499 works ≈ 35–40s to bind
(the proximate cause of the "restart didn't work" session — the
restart script's 30s wait expired and killed a healthy server).
**Related:** FR-43 (capacity/eviction — this FR is its load-direction
sibling), FR-82 (migration verify runs a full restore), the XPS
capacity notes (persist/perf docs).

## Why

Restore eagerly hydrates EVERY work's edition into its enfilade
before binding the port:

```
src/server/server.rs (~15285)
for work_entry in &manifest.works {
    work_from_chunks_current(&work_entry.work_ref, &chunk_store)  // chunks → OrglRoot
}
```

Boot cost is O(total corpus): 499 works + 72 clubs + a ~12s
verification pass + 10k session tickets ≈ 35–40s today, growing with
the data. The assumption — the server holds the whole docuverse in
RAM, so reconstruct it totally before serving — was correct at tens
of works and is wrong at hundreds-plus. Every restart, deploy, and
migration-verify pays it.

The optimization is not new machinery: it already exists, built for
the shedding direction (FR-43 eviction). This FR applies it to the
load direction.

## What exists today (the pieces to adopt)

- **Evicted state**: a work's metadata lives in `works` with the
  edition dropped; `evict_work` / `enable_eviction` / LRU bookkeeping
  (eviction-gap tests prove reads still work).
- **On-demand loader**: `work_from_chunks_current` (persist/
  edition_chunks.rs) — chunks → Work + OrglRoot, used by thaw.
- **Thaw gate**: `work_text_fresh` rematerializes an evicted edition
  on read (proven for text reads and transclusion sources).
- **Verification**: the restore-time chunk verification pass
  (~12s) — integrity is already vouched for at write time by
  checkpoint hashes + the chained security log.

## Design

1. **Restore to evicted state.** The restore loop inserts each
   work's `WorkState` metadata (owner, clubs, kind, title cache,
   chunk refs, trace) WITHOUT hydrating the edition — the same state
   eviction produces. Clubs likewise (their works are tiny; hydrate
   clubs eagerly if measurement says so).
2. **Thaw gates on every edition consumer.** Audit and gate:
   - `work_text_fresh` — gated today (reference implementation)
   - work grab/edit paths (revise_work, work_save_and_release)
   - transclusion resolution + provenance span reads
   - backfollow content registration — DEFER: register link content
     lazily on first backfollow query, or index at thaw time
   - canopy inserts — defer to thaw (queries gate on thawed works;
     unthawed works answer from a metadata-only fallback or thaw
     on demand)
   - search index — already lazy/dirty-set driven; keep
   - overlay/`work_get_edition`, attribution, compare
   The invariant to enforce in tests: NO code path may touch
   `ws.work.edition()` on a possibly-evicted work without passing a
   thaw gate. (Consider a debug-mode assertion in the accessor.)
3. **Bind first, verify after.** Move the chunk verification pass to
   a background task post-bind. `/health` reports
   `verifying: true` until it completes; failures surface as restore
   errors + security-log events, not boot failures (write-time
   hashes already guarantee integrity; this pass is detection of
   on-disk rot).
4. **Warm tier (optional nicety).** Background pre-thaw of starred +
   recently-touched works after bind, lowest priority. Order
   heuristics are otherwise unnecessary: demand drives loading, and
   the LRU bounds RAM (FR-43's budget).
5. **Migration verify (FR-82) benefits automatically** — it runs a
   full restore; with lazy restore it should hydrate all works
   deliberately (verification is its point) but its cost becomes
   explicit and parallelizable rather than incidental.

## Measurements to beat

Current dev data (499 works, 72 clubs, 10,271 tickets, seq 3412):

| Phase | Today | Target |
|---|---|---|
| Manifest + metadata + sidecars + bind | ~3s (inside the 35–40s) | ≤ 5s total to bind |
| Edition hydration | ~20s blocking | 0 at boot; per-work on demand |
| Verification pass | ~12s blocking | background, post-bind |

XPS work_list numbers must not regress (the preview field already
rides the same listing path; lazy works answer metadata from the map).

## Risks

- **The gate audit is the real work.** Every ungated consumer is a
  runtime panic or silent empty-read on a cold work. The
  eviction-gap tests cover some paths; this FR adds a
  restore-then-read-everything integration test that exercises each
  consumer against a fully-evicted boot.
- **Cross-work indices degrade to partial until warm.** Backfollow/
  canopy over unthawed works must fail soft (miss, not error) and
  self-heal as works thaw — same posture as the search index.
- **Session tickets** (10k) parse fast today; if they grow, they get
  their own lazy pass (out of scope here).

## Exit criteria

- [ ] Restore inserts all works in evicted state; bind ≤ 5s on the
      current dev corpus
- [ ] Every edition consumer passes a thaw gate (audit list above
      checked off, debug assertion in place)
- [ ] Restore-then-read-everything integration test green against a
      cold boot (every consumer exercised)
- [ ] Backfollow/canopy/search behave over cold works (miss → thaw →
      correct), proven by test
- [ ] Verification runs post-bind in background; `/health` reflects
      it; failure path surfaces without wedging the server
- [ ] eviction-gap + existing eviction tests still green
- [ ] `xudanu-server upgrade` verify pass still total (deliberate
      full hydration)
- [ ] XPS dispatch benches: no regression

## Out of scope

- Lazy session-ticket sidecar (revisit if it appears in profiles).
- Disk-backed enfilade paging beyond the existing eviction LRU.
- Changing checkpoint/write paths (this FR touches only load).
