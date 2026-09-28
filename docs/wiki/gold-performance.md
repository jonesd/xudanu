# Wiki draft: measured performance of the Gold mechanisms

> Target: a short "Performance" subsection. Numbers are from a Rust
> re-implementation (Xudanu 1.13.1) exercising the inherited
> mechanisms — disclosed as such; they are the first published
> measurements of this machinery running outside the original C++.
> Machine: Apple M4 (10 cores), 32 GB, release build, 2026-09-21.

## Performance characteristics (re-implementation measurements)

Corpus: 1,000 documents × 10 KB.

| Operation | p50 | p95 |
|---|---|---|
| Read document text | 0.17 ms | 0.24 ms |
| Write text (delta) | 0.08 ms | 0.20 ms |
| Backlink query | 0.00 ms | 0.01 ms |
| Content match (two 10 KB docs) | 40 ms | 42 ms |
| Work list | 0.01 ms | 0.01 ms |

Scaling with corpus size (10× documents): reads scale ≈ linearly
with document size but not corpus size; writes scale sub-linearly;
backlink queries are flat — the end-set mechanism's O(1) claim
holds under measurement. Content matching scales linearly in
document size, consistent with its pairwise design; the Bloom-filter
federated index addresses corpus scale.

Observed single-node capacity (estimated from p95 write latency,
one edit per 30 s per writer, 10:1 read:write): ~147,000 concurrent
writers or ~1.5 M concurrent readers on one commodity machine.
Server processing is idle 96–99% of request time at typical network
latency — the engine is not the bottleneck for interactive use.

Source: benchmark harness and raw results (XPS spec tiers 1–2),
reproducible via `xps-bench` in the public repository [src].
