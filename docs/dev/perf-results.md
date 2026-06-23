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

## B1 — Bound & prune unbounded maps

*(measure after implementation)*

## B7 — Read/write lock split

*(measure after implementation; target: concurrent_reads_serial_8x >= 3x
faster than baseline)*
