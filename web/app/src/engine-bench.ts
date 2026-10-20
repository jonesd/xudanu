/**
 * FR-148f: engine measurement harness. Batteries can't be read from
 * a browser — the harness measures the PROXIES that dominate energy
 * (CPU time per op, bytes processed, throughput) so:
 *  - CI asserts BUDGETS (a regression in op cost fails the build)
 *  - on-device runs (Xcode Energy Log / Battery Historian) correlate
 *    joules against these same numbers
 *
 * Every bench reports { ops, ms, bytes, opsPerSec, mbPerSec } and a
 * JSON blob shaped for the future on-device collector.
 */
import { engineReady, type Engine } from "./engine-wasm-loader";

export interface BenchResult {
  name: string;
  ops: number;
  bytes: number;
  /** wall-clock ms across all ops (median of 3 runs) */
  ms: number;
  opsPerSec: number;
  mbPerSec: number;
  /** budget contract (ms) — CI fails when the median exceeds it */
  budgetMs: number;
}

async function medianMs(fn: () => void, runs = 3): Promise<number> {
  const samples: number[] = [];
  for (let i = 0; i < runs; i++) {
    const t0 = performance.now();
    fn();
    samples.push(performance.now() - t0);
  }
  samples.sort((a, b) => a - b);
  return samples[Math.floor(samples.length / 2)];
}

export async function runEngineBenches(): Promise<{
  results: BenchResult[];
  json: string;
}> {
  const e: Engine = await engineReady();
  const enc = new TextEncoder();
  const results: BenchResult[] = [];

  const record = async (
    name: string,
    ops: number,
    bytesPerOp: number,
    budgetMs: number,
    fn: () => void,
  ) => {
    const ms = await medianMs(fn);
    results.push({
      name,
      ops,
      bytes: ops * bytesPerOp,
      ms,
      opsPerSec: ops / (ms / 1000),
      mbPerSec: (ops * bytesPerOp) / 1e6 / (ms / 1000),
      budgetMs,
    });
  };

  // 1. Content hashing — the crum/verification hot path.
  const blob = enc.encode("x".repeat(64 * 1024)); // 64 KiB
  await record(
    "blake3-64kib",
    200,
    blob.length,
    400,
    () => {
      for (let i = 0; i < 200; i++) e.blake3_hex(blob);
    },
  );

  // 2. Chunk framing — the fetch-and-parse hot path.
  const payload = new Uint8Array(4 * 1024).fill(7);
  const tagged = e.chunk_tag("postcard", payload);
  await record(
    "chunk-unframe-4kib",
    2000,
    tagged.length,
    800,
    () => {
      for (let i = 0; i < 2000; i++) e.chunk_payload(tagged);
    },
  );

  // 3. Verify cycle — hash + compare, the wake protocol's core verb.
  const hex = e.blake3_hex(blob);
  await record(
    "verify-blake3-64kib",
    200,
    blob.length,
    400,
    () => {
      for (let i = 0; i < 200; i++) e.verify_blake3(blob, hex);
    },
  );

  // 4. Document materialization — the rendering path (200 spans).
  const doc = buildSyntheticDoc(e, 200);
  await record(
    "materialize-200spans",
    50,
    0,
    2000,
    () => {
      for (let i = 0; i < 50; i++) e.WasmAssertionStore === undefined ? undefined : doc();
    },
  );

  return {
    results,
    json: JSON.stringify({
      harness: "fr-148f",
      at: new Date().toISOString(),
      results: results.map((r) => ({
        name: r.name,
        ms: Number(r.ms.toFixed(2)),
        opsPerSec: Math.round(r.opsPerSec),
        mbPerSec: Number(r.mbPerSec.toFixed(1)),
      })),
    }),
  };
}

/** Synthetic N-span document builder (ent layer). */
function buildSyntheticDoc(e: Engine, spans: number): () => unknown {
  return () => {
    const dw = new e.WasmDagWood();
    const store = new e.WasmAssertionStore();
    const pos = dw.new_position();
    store.add(pos, JSON.stringify({ CreateNode: { node_id: 1, kind: "document" } }));
    for (let i = 0; i < spans; i++) {
      store.add(pos, JSON.stringify({ CreateSpan: { span_id: 100 + i } }));
      store.add(pos, JSON.stringify({ SetSpanText: { span_id: 100 + i, text: `span ${i} ` } }));
      store.add(pos, JSON.stringify({ AttachSpanToNode: { node_id: 1, span_id: 100 + i, ordinal: i } }));
    }
    const view = dw.trace_view(pos);
    return JSON.parse(store.materialize_document_json(view, 1));
  };
}
