# FR-83 — Lazy Restore: boot in seconds, materialize enfilades on demand

**Status:** slice 1 shipped (September 2026) — flag-gated (`XUDANU_LAZY_RESTORE=1`), both test suites green in eager AND lazy modes. Measured on the dev corpus (499 works): eager-debug 74s → lazy-debug 13.5s → **lazy-release 2.82s to health**. Slice 2 shipped (public-handler thaw gates, upgrade full-hydration). Slice 3 specced below (bind-first boot + warm tier). Remaining checklist below.
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

## Slice 3 — bind-first boot: defer the self-heal checkpoint, add a warm tier

**Re-measured October 2026** on the grown dev corpus (609 works, 72
clubs, 431 MB, release binary): lazy boot to health is **2.0s** — and
the phase spans from the boot log show the remaining cost is not
loading at all:

| Phase (lazy boot, 609-work corpus) | Span | Time |
|---|---|---|
| Root chunk read + parse (609 works, 72 clubs) | restore start → restored | 68 ms |
| Metadata restore (identity, blobs, tickets, policy, annotations, attributions) | → drift checkpoint begins | 62 ms |
| **Schema-drift self-heal checkpoint** (drifted-chunk rewrite, 5× legacy `manifest_v*.json` re-parse, chunk GC over 7,486 refs) | → checkpoint done | **1,650 ms** |
| Bind + serve | → listening | 36 ms |

Loading the corpus is 130 ms. **92% of boot is write work done before
the port opens** — `checkpoint_after_restore` (server.rs:15171,
called at bin/xudanu-server.rs:1169, synchronous, pre-bind), whose
purpose is cosmetic: persist new default fields so the SCHEMA DRIFT
warning doesn't reappear next boot.

### Part A — defer the self-heal checkpoint post-bind

1. Boot sequence becomes: restore (metadata-only under the flag) →
   **bind** → background: self-heal checkpoint → background chunk
   verification. In the shipped shape the verifier spawns during
   restore (it uses an independent read-only store handle + a
   manifest snapshot; GC's 50-gen archive grace keeps its reads
   valid), so the heal runs concurrently with it post-bind — the
   v1.17.1 tmp-chunk guards cover the overlap.
2. `/health` reports `self_heal: true` until a checkpoint commit
   lands (any commit clears it — the deferred heal, an autosave, or
   the SIGTERM final checkpoint).
3. The heal task waits ~2s after bind before its first write burst:
   std's rwlock is write-preferring, and without the delay first
   readers queued behind the checkpoint slices (measured: /health
   answered in 1.5s instead of 0.3s). Readers-first, then heal.
4. Failure posture unchanged: warn, don't crash (the pre-bind call
   was already non-fatal).
5. Crash between bind and heal: the drift warning simply survives to
   the next boot; healing is idempotent and the 5s autosave would
   also absorb it. No durability loss — restore never depended on the
   self-heal having run.

Measured result (October 2026, 609-work corpus, release): restore
115 ms, **listening ~160 ms after process start, /health at 0.31 s
warm** (was 2.0 s lazy / 9.9 s eager); `self_heal` and
`background_verification` both true at readiness, both cleared within
5 s.

Follow-up (optional, inside Part A): the self-heal path re-parses the
legacy `manifest_v*.json` history to compute GC reachability
(~1.4 s of the 1.65 s). Drift healing only needs the CURRENT
manifest — skip legacy-history verification there and boot drops the
background cost too.

### Part B — warm tier (design point 4, now earned)

Persist per-work recency and pre-thaw the likely working set after
bind, lowest priority:

1. **Recency sidecar:** top-N (say 50) most-recently-touched works,
   updated on the same paths that drive eviction LRU bookkeeping
   (`EvictionManager.last_access` — eviction.rs:40, in-memory only
   today). Persist as a JSON sidecar (ticket_nonces.json pattern) or
   a SocialSection field (starred_works pattern) — advisory data, so
   the sidecar is fine.
2. **Post-bind warmer:** thaw `starred ∪ MRU(top-N)` after the
   self-heal checkpoint completes, K works per tick, yielding to
   request dispatch. Bounded by the FR-43 LRU as usual — warming
   cannot exceed the RAM budget.
3. `/health` reports warm progress (`warm_tier: "12/50"`).

What it buys: closes the fail-soft window on cross-work indices
(backfollow/canopy answers complete for the active set seconds after
boot) and absorbs burst opens (library scroll, previews) without a
thaw stampede. Cost: ~12 ms/work measured, so 50 works ≈ 600 ms of
post-bind background work. A single deliberate doc open gains nothing
— on-demand thaw already covers it — which is why this stays a
nicety, not a dependency.

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

- [x] Restore inserts all works in evicted (metadata) state — flag-gated;
      release boot 2.82s ≤ 5s target on the current dev corpus
- [x] Edition consumers gated: dispatch pre-thaw pass (read ops),
      write choke points (revise_work, work_grab,
      ensure_trail_derived_work), restore-tail deferrals
      (backfollow meta-only + thaw-upgrade, annotated-work thaw)
- [x] The full suite under XUDANU_LAZY_RESTORE=1 green (3,689) — the
      debug-assert choke point is the permanent enforcement
- [x] Corruption at thaw quarantines with the same contract as
      eager (chunks preserved, restore_errors surfaced)
- [x] Verification runs post-bind in background; /health reports
      background_verification (flips false on completion)
- [x] Eager mode byte-identical behavior (3,689 green, flag off)
- [ ] Flip the default (on) after a soak period — flag stays opt-in
      for v1.15.0 (dev restart.sh opts in as of October 2026 — the
      soak is running). BLOCKER found in the October soak: 7
      integration tests fail under XUDANU_LAZY_RESTORE=1
      (chunk_store_persistence_*, chunk_store_multiple_checkpoints,
      dirty_checkpoint_all_work_mutation_paths) — pre-existing on
      main, not slice-3; the suite must be lazy-green again before
      the flip.
- [ ] Phase timing spans in the boot log (self-reporting boots)

Slice 3 (specced above):

- [x] Defer the boot-time schema-drift self-heal checkpoint post-bind
      (Part A) — measured: listening ~160 ms, /health 0.31 s warm on
      the 609-work corpus (was 2.0 s); /health `self_heal` field;
      readers-first 2s delay before the heal's write bursts;
      suite green in default mode (lib 3,777 + integration 328)
- [ ] Self-heal skips legacy manifest-history re-parse (drift healing
      needs only the current manifest)
- [ ] Warm tier (Part B): recency sidecar + post-bind warmer for
      starred ∪ MRU(top-N); /health warm progress
- [ ] Lazy annotation init (per-work, first access) — boot touches
      zero editions
- [ ] Clubs lazy (72 hydrate eagerly today)
- [ ] `xudanu-server upgrade` verify pass still total (deliberate
      full hydration) — verify under the flag
- [ ] XPS dispatch benches: no regression (re-run under flag)

## Out of scope

- Lazy session-ticket sidecar (revisit if it appears in profiles).
- Disk-backed enfilade paging beyond the existing eviction LRU.
- Changing checkpoint/write paths (this FR touches only load).
