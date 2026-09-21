# Performance Results

Running log of benchmark baselines and post-change measurements.
All numbers from `cargo bench --features server --bench dispatch_bench`.

Machine: macOS (dev). Criterion defaults (100 samples, 3s warmup).

## Baselines (B0 harness — `before` baseline)

Captured on initial benchmark harness commit.

| Benchmark                    | Time (median) | Notes                              |
|------------------------------|---------------|------------------------------------|
| work_list/10                 | 2.46 us       | 10 works in store                  |
| work_list/100                | 19.8 us       | 100 works — ~8x slower than /10    |
| work_list/500                | 95.6 us       | 500 works — ~5x slower than /100   |
| work_get_edition             | 2.38 us       | single-work read                   |
| work_create                  | 179.9 us      | write-path: new work               |
| concurrent_reads_serial_8x   | 123.5 us      | 8 reads serialized (B7 target)     |
| crdt_sync_full_state         | 725.7 ns      | CRDT state read                    |

### Observations

- `work_list` scales ~linearly with work count (B8 target).
- `concurrent_reads_serial_8x` = ~8x single `work_list/100`, confirming all
  reads are serialized by the write lock (B7 target).
- `work_create` is the heaviest single op (write path + allocation).

---

## Post B0-B8 + Flakiness Fixes (Jun 28 2026)

Captured after: B0-B8 perf arc (commit c1f7d13d), Mutex→RwLock, async
checkpoint, edit protection, TipTap migration, and flakiness fixes #1-5
(async auto_checkpoint, request timeouts, text clobber prevention,
reconnect text refresh, drain_fn lock guard).

| Benchmark                         | Baseline   | Current    | Change  | Notes                         |
|-----------------------------------|------------|------------|---------|-------------------------------|
| work_list/100                     | 19.8 us    | 5.78 us    | -71%    | B8 inline iteration           |
| work_list/500                     | 95.6 us    | 7.52 us    | -92%    | B8 inline iteration           |
| work_list/1000                    | —          | 13.6 us    | —       | (not in original baseline)    |
| work_list/5000                    | —          | 27.5 us    | —       | (not in original baseline)    |
| work_get_edition                  | 2.38 us    | 1.47 us    | -38%    | RwLock read path              |
| concurrent_reads_serial_8x        | 123.5 us   | 32.0 us    | -74%    | B7 read/write split           |
| concurrent_reads/parallel_1x      | —          | 32.0 us    | —       | single-thread read            |
| concurrent_reads/parallel_8x      | —          | 222 us     | —       | 8 threads, read lock shared   |
| crdt_sync_full_state              | 725.7 ns   | 479.5 ns   | -34%    | RwLock read path              |
| checkpoint_impact/idle            | —          | 5.95 us    | —       | read during no checkpoint     |
| checkpoint_impact/during_checkpoint| —        | 12.6 us    | —       | read during async checkpoint  |

### Key observations

- `concurrent_reads_serial_8x` improved 74% — B7 read/write split confirmed effective.
- `work_list/100` improved 71%, `work_list/500` improved 92% — B8 inline iteration.
- `checkpoint_impact/during_checkpoint` = 12.6 us vs idle 5.95 us = 2.1x overhead
  during async checkpoint. Previous sync checkpoint caused 10x+ stalls.
- `concurrent_reads/parallel_8x` = 222 us shows read lock still serializes
  parallel reads (P3 target: try_lock for opportunistic reads).

---

## Post P1-P3 (Jun 28 2026)

P1: Lock-free `AtomicU64` for `operation_counter` on `ServerHandle`.
P2: Perf metrics recorded (this section).
P3: `try_with_server_ref` + `try_health_json` — health endpoint and drain_fn
use `try_read` instead of blocking `read`.

| Benchmark                         | Post-Flakiness | Post-P1P3  | Change  |
|-----------------------------------|----------------|------------|---------|
| concurrent_reads/parallel_1x      | 32.0 us        | 33.3 us    | +4% (noise) |
| concurrent_reads/parallel_8x      | 222 us         | 218 us     | -2%     |
| checkpoint_impact/idle            | 5.95 us        | ~6.0 us    | stable  |
| checkpoint_impact/during_checkpoint| 12.6 us       | 12.6 us    | stable  |
| crdt_sync_full_state              | 479.5 ns       | ~480 ns    | stable  |

### Key observations

- **P1 (atomics)**: No regression on hot paths. The `operation_counter` atomic
  increment happens outside the write lock. Health endpoint can now serve
  stats without any lock via `try_health_json`.
- **P3 (try_lock)**: Health endpoint degrades to `{"status":"degraded"}`
  instead of blocking during write-lock contention. `drain_fn` skips
  notification checks when the lock is held by a writer (next 200ms tick
  picks it up).
- **Net effect**: P1-P3 are infrastructure for future fine-grained locking
  (P4). No user-visible perf change at current concurrency levels.


---

## XPS Baseline — 2026-09-21

**Machine:** Apple M4 (10 cores), 32GB unified memory, NVMe SSD, macOS
**Build:** debug (cargo build --features server)
**XPS version:** 1.13.1
**Runner:** `xps-bench --tier 1` and `--tier 2`

### Tier 1 (100 docs, 1KB each)

| Operation | p50 | p95 | Class | Bound | Pass |
|---|---|---|---|---|---|
| L2-backlink-query | 0.0ms | 0.0ms | responsive | 100ms | ✓ |
| C4-read-text | 0.1ms | 0.1ms | interactive | 16ms | ✓ |
| C5-write-text | 0.4ms | 0.4ms | interactive | 16ms | ✓ |
| C5-write-text-small | 0.4ms | 0.5ms | interactive | 16ms | ✓ |
| C1-content-match | 38.6ms | 39.1ms | batch | 1000ms | ✓ |
| P1-attribution | 0.0ms | 0.0ms | responsive | 100ms | ✓ |
| C3-work-list | 0.0ms | 0.0ms | responsive | 100ms | ✓ |

**Estimated capacity:** ~68K concurrent writers, ~686K concurrent readers
(based on p95 write latency, 1 write per 30s per user, 10:1 read:write)

### Tier 2 (1,000 docs, 10KB each)

| Operation | p50 | p95 | Class | Bound | Pass |
|---|---|---|---|---|---|
| L2-backlink-query | 0.1ms | 0.1ms | responsive | 100ms | ✓ |
| C4-read-text | 0.8ms | 0.9ms | interactive | 16ms | ✓ |
| C5-write-text | 0.6ms | 0.8ms | interactive | 16ms | ✓ |
| C5-write-text-small | 0.4ms | 0.5ms | interactive | 16ms | ✓ |
| C1-content-match | 377.8ms | 422.5ms | batch | 1000ms | ✓ |
| P1-attribution | 0.0ms | 0.0ms | responsive | 100ms | ✓ |
| C3-work-list | 0.1ms | 0.1ms | responsive | 100ms | ✓ |

**Estimated capacity:** ~39K concurrent writers, ~391K concurrent readers

### Scaling observations (tier 1 → tier 2)

| Operation | Tier 1 p95 | Tier 2 p95 | Scale factor (10× docs) | Complexity |
|---|---|---|---|---|
| Read text | 0.1ms | 0.9ms | 9× (≈linear) | O(1) expected — doc-level lookup |
| Write text | 0.4ms | 0.8ms | 2× (sub-linear) | O(log N) expected |
| Content match | 39.1ms | 422.5ms | 10.8× (linear) | O(N×M) expected — pair of 10KB docs |
| Work list | 0.0ms | 0.1ms | — | O(N) expected |
| Attribution | 0.0ms | 0.0ms | flat | O(spans) expected |

Content match scales linearly with document size (1KB→10KB per doc),
confirming the O(N×M) pair comparison. This is the operation that
needs the n-gram/BLAKE3 index (FR-35 Bloom filters) for sub-linear
scaling at corpus scale.

### Not yet measured

| Operation | Status | Blocker |
|---|---|---|
| L1-create-link | deferred | requires HyperRef construction (dispatch-layer benchmark) |
| T2-compound-resolve | not implemented | needs transclusion corpus setup |
| C2-corpus-matching | not implemented | needs content-match index across all works |

### Typical operation payload sizes

| Operation | Request (bytes) | Response (~bytes) | Comparison |
|---|---|---|---|
| Text edit (delta) | 200-400 | ~50 (ack) | Google Docs: ~200B/~200B |
| Open document | ~91 | 1K-100K (text) | REST GET: ~500B/~5KB |
| Create link | ~243 | ~20 (ID) | REST POST: ~500B/~1KB |
| Work list (100 works) | ~95 | ~12,000 | REST list: ~500B/~10KB |
| Heartbeat | ~76 | ~10 | Keep-alive: similar |
| Annotation create | ~182 | ~20 | REST POST: ~500B |
| Governance propose | ~314 | ~100 | REST POST: ~1KB |

### Network context

Server processing is NOT the bottleneck. At 0.4ms p95 for a write
edit with a typical 1-5ms WebSocket round-trip, the server is idle
~92-98% of the time per request. Capacity is limited by:
1. Memory for the document corpus (enfilade + chunks)
2. Concurrent WebSocket connections (~50KB per session)
3. Network bandwidth for large document reads

The epoch-sharding design (FR-76) addresses #1; the federation
architecture addresses #3 through caching.
