# Storage Stress Test Tool

A built-in stress testing suite for the ChunkStore content-addressable storage
layer. Exercises the LRU cache, disk I/O, edition serialization, and
production-like workload patterns.

## Quick Start

```bash
# Run all fast tests (~40s total)
cargo test --all-features --lib -- stress

# Run a single scenario
cargo test --all-features --lib -- stress_03

# Run medium and heavy scales (longer, for thorough validation)
cargo test --all-features --lib -- stress -- --ignored

# Run a specific heavy scenario
cargo test --all-features --lib -- stress_10_cold_restart_heavy -- --ignored
```

All tests live in `src/persist/stress.rs` as a `#[cfg(test)]` module. They are
regular `cargo test` targets -- no external tools or harnesses needed.

## Three Scale Tiers

Every scenario has three variants. Fast runs by default; medium and heavy are
marked `#[ignore]` so they only run when explicitly requested with `--ignored`.

| Scale | Unique chunks | Editions | Revisions | Read samples | Est. time |
|-------|--------------|----------|-----------|-------------|-----------|
| **Fast** | 2,000 | 10 | 10 | 5,000 | ~1-5s per test |
| **Medium** | 10,000 | 100 | 50 | 20,000 | ~5-15s per test |
| **Heavy** | 100,000 | 500 | 200 | 100,000 | ~30s-2min per test |

Scale parameters are defined in the `Scale` enum at the top of `stress.rs`.
Adjust the values there if you need different sizes.

## The 10 Scenarios

### 01 -- Warm-up Ramp

Sequential writes to an empty store. Measures write throughput as the LRU cache
fills from 0 to capacity (1,024 entries).

**What to look for:** Write latency should be consistent. If it spikes as the
cache fills, that indicates contention in the eviction path.

### 02 -- Content Deduplication

Writes many editions where groups share identical content. The content-addressable
store should produce the same hash (and same on-disk file) for identical data.

**What to look for:** The dedup ratio should equal the number of copies per
unique text. Chunks on disk should equal unique texts, not total editions.

### 03 -- Cache Thrashing

Writes 2x-50x more chunks than cache capacity, then performs random reads with
the cache cleared. Forces every read to go to disk or re-enter the cache via
eviction of another entry.

**What to look for:** Cache hit rate will be low (~0-10%). This measures worst-
case random access. All reads must succeed -- a failure means eviction lost data.

### 04 -- Hot/Cold Working Set

Creates a dataset where 20% of chunks are "hot" (accessed 80% of the time) and
80% are "cold" (accessed 20%). Simulates realistic access patterns where popular
documents are read frequently.

**What to look for:** The LRU cache should keep hot entries resident. If actual
hit rate is significantly below 80%, the LRU policy isn't effective for this
pattern.

### 05 -- Sequential Scan After Eviction

Writes more chunks than the cache can hold, clears the cache, then reads every
chunk in order. Tests that all data survives eviction and measures the cost of
re-populating the cache sequentially.

**What to look for:** Early reads are cold (cache misses); later reads warm up
as the cache fills. Total time measures sequential disk throughput. Every chunk
is content-verified against expected data.

### 06 -- Large Editions

Creates editions with 1,000-10,000 entries each (producing multiple 256-entry
chunks per edition). Measures serialization and deserialization of large
documents through the `edition_to_chunks` / `edition_from_chunks` path.

**What to look for:** Chunks per edition should match the expected count (1 root
+ ceil(entries / 256) entry chunks). Deserialize must recover all entries
correctly.

### 07 -- Deep Revision History

Creates works with 10-200 revisions, then reads the current version and samples
random historical revisions. Tests the lazy-loading path where history chunks
are not loaded until explicitly requested.

**What to look for:** Current reads should be faster than history reads (history
may need to load additional chunks). Historical revision data must match what
was written.

### 08 -- Mixed Read/Write

Interleaves reads (90%) and new writes (10%) against a pre-populated store.
Simulates a live server handling edits and reads concurrently.

**What to look for:** Ops/sec gives a realistic throughput estimate. Cache hit
rate depends on the write pattern displacing cached reads.

### 09 -- Fragmentation and Churn

Repeatedly creates chunks, deletes half of them from disk, then verifies
survivors. Measures how disk space grows (or doesn't) through create/delete
cycles.

**What to look for:** Disk growth percentage across cycles. If the growth is
linear without bound, it indicates that space from deleted chunks is not being
reclaimed (expected for a content-addressable store, but worth tracking).

### 10 -- Cold Restart

Builds a complete dataset (works with editions and revision history), closes the
store, reopens it, and measures time to read everything back. This is the most
production-critical scenario: what happens when the server restarts.

**What to look for:**
- **Open time** should be near-instant (ChunkStore open just creates directories)
- **Warm-up time** (reading all works) measures how fast the system becomes
  fully operational
- **Current read avg** vs. **history read avg** shows the cost of lazy-loaded
  revision history
- All data must survive the restart intact

## Reading the Output

Each scenario prints a report table to stderr:

```
============================================================
Scenario: 03: Cache Thrashing (fast)
============================================================
Total duration:    287.5ms
Writes:            2000 ops, avg 12.3µs, p50 8.1µs, p95 45.2µs, p99 89.3µs
Reads:             5000 ops, avg 18.7µs, p50 11.2µs, p95 62.4µs, p99 134.1µs
Cache:             234 hits (4.7%), 4766 misses (95.3%), 1024 in cache
Chunks on disk:    2000
Disk usage:        0.17 MB
Chunks written:    2000
Cache capacity:    1024
Oversubscription:  2.0x
Random reads:      5000
Reads/sec:         17391
All reads ok:      YES
============================================================
```

### Key metrics

| Metric | Meaning |
|--------|---------|
| **p50 / p95 / p99** | Latency percentiles. p99 is the "worst normal" case. |
| **Cache hit rate** | Fraction of reads served from memory vs. disk. |
| **Oversubscription** | Ratio of total chunks to cache capacity. Above 1.0 means eviction occurs. |
| **Disk usage** | Actual bytes on disk for chunk files. |
| **Reads/sec** | Aggregate throughput for the read phase. |

## ChunkStore Instrumentation

The stress tests rely on instrumentation added to `ChunkStore`:

```rust
// Get cache statistics: (hits, misses, hit_rate, cache_len)
let (hits, misses, rate, len) = store.cache_stats();

// Reset counters between phases
store.reset_stats();

// Query disk state
let count = store.total_chunks_on_disk()?;
let bytes = store.disk_bytes()?;

// Clear the cache to simulate a cold start
store.clear_cache();
```

These methods are available on any `ChunkStore` instance and can be used in
custom tests or debugging.

## Adding a New Scenario

1. Add a `run_scenario_11_your_name(scale: Scale)` function in `stress.rs`
2. Create three test functions following the naming convention:
   ```rust
   #[test]
   fn stress_11_your_name_fast() { run_scenario_11(Scale::Fast); }

   #[test]
   #[ignore]
   fn stress_11_your_name_medium() { run_scenario_11(Scale::Medium); }

   #[test]
   #[ignore]
   fn stress_11_your_name_heavy() { run_scenario_11(Scale::Heavy); }
   ```
3. Use `Scale` methods to get scenario parameters
4. Build a `StressReport` and call `.print()` at the end
5. Clean up the temp directory with `cleanup(&dir)`

## What This Does Not Test

- **Concurrent access** -- All tests are single-threaded. The `Mutex` around
  the cache is never contended. For concurrent testing, use the integration
  test suite with the live server.
- **FileBackedStorage / Snarf / URDI** -- These tests focus on the ChunkStore
  layer. The older flock/snarf storage has its own tests in `file_storage.rs`
  and `snarf.rs`.
- **Network I/O** -- No server or transport layer is involved.
- **WASM target** -- Tests run on native only. WASM-specific behavior (e.g.,
  browser file system quirks) is not covered.
