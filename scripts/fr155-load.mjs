#!/usr/bin/env node
// fr155-load.mjs — FR-155 capacity probe: how many concurrent readers
// can one deployment support?
//
// Two phases, because the architecture splits load in two:
//
//   A. WARM  — repeated ?lang=fr reads of already-translated content.
//      The engine is never called (rendition cache); this measures
//      the xudanu read-path ceiling. Sweep concurrency 1..32.
//      Baseline: the same docs read WITHOUT ?lang at concurrency 8
//      (the zero-translation-feature reference).
//
//   B. COLD  — first-ever ?lang=fr read of D distinct documents at
//      fixed concurrency. Every read is a cache miss, so this
//      measures engine-bound throughput (docs/s, sentences/s) and
//      how fast a community can absorb new content.
//
// Usage: node scripts/fr155-load.mjs [base-url] [docs] [cold-concurrency]
//   defaults: http://127.0.0.1:8090, 48 docs, 8 cold workers
//
// The public read API rate-limits at 120 GETs/min PER CLIENT IP
// (server/rate_limiter.rs) — a deliberate design constant, not a
// bottleneck to engineer around. Two modes, auto-detected:
//   - alias mode: requests round-robined across loopback aliases
//     127.0.0.1..16 (works where the whole 127/8 is routable)
//   - paced mode (fallback): bursts of 100 requests per level,
//     61s window reset between levels — same measurement, slower
// 429 responses are counted and reported, never ignored.
import WebSocket from "ws";

const base = process.argv[2] ?? "http://127.0.0.1:8090";
const DOCS = parseInt(process.argv[3] ?? "48", 10);
const COLD_C = parseInt(process.argv[4] ?? "8", 10);
const host = new URL(base).hostname;

const ALIASES = host === "127.0.0.1"
  ? Array.from({ length: 16 }, (_, i) => `127.0.0.${i + 1}`)
  : [host];
const aliasBaseFor = (ip) => base.replace("//" + host, "//" + ip);
let paced = true; // proven false only by a reachable alias probe
let aliasIdx = 0;
const aliasBase = () => {
  if (paced) return base;
  aliasIdx++;
  return aliasBaseFor(ALIASES[aliasIdx % ALIASES.length]);
};
const windowReset = () => paced && new Promise((r) => setTimeout(r, 61000));

// ---- seed corpus ----------------------------------------------------
const BANK = [
  "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.",
  "Call me Ishmael.",
  "To be, or not to be, that is the question.",
  "All happy families are alike; each unhappy family is unhappy in its own way.",
  "It was the best of times, it was the worst of times.",
  "The past is a foreign country; they do things differently there.",
  "In the beginning the Universe was created. This has made a lot of people very angry and been widely regarded as a bad move.",
  "No one would have believed in the last years of the nineteenth century that this world was being watched keenly and closely by intelligences greater than man's.",
  "All animals are equal, but some animals are more equal than others.",
  "The sky above the port was the color of television, tuned to a dead channel.",
  "Beware the man who works hard to learn something, learns it, and finds himself no wiser than before.",
  "The only thing we have to fear is fear itself.",
];
const docText = (i) =>
  [0, 1, 2]
    .map((k) => BANK[(i * 3 + k) % BANK.length])
    .join("\n\n") + `\n\nField note ${i}: the lighthouse keeps its own hours.`;

// ---- ws plumbing (from fr155-lang-demo.mjs) --------------------------
const wsUrl = `${base.replace(/^http/, "ws")}/xudanu?format=json`;
const ws = new WebSocket(wsUrl, { headers: { origin: base } });
let nextId = 1;
const pending = new Map();
function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 30000);
    pending.set(id, { resolve, reject, timeout: t, op });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}
ws.on("message", (data) => {
  const frame = JSON.parse(data.toString());
  if (frame.type === "response" || frame.type === "error") {
    const p = pending.get(frame.id);
    if (p) {
      pending.delete(frame.id);
      clearTimeout(p.timeout);
      if (frame.type === "error") p.reject(new Error(`${p.op}: ${frame.message}`));
      else p.resolve(frame.value);
    }
  }
});
const value = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);

// ---- helpers ---------------------------------------------------------
const pct = (xs, p) => {
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor((p / 100) * s.length))];
};
async function pool(items, concurrency, fn) {
  const out = new Array(items.length);
  let i = 0;
  await Promise.all(
    Array.from({ length: concurrency }, async () => {
      while (i < items.length) {
        const idx = i++;
        out[idx] = await fn(items[idx]);
      }
    })
  );
  return out;
}

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");

  // Seed DOCS distinct English works, each declared kind:language en.
  const ids = [];
  for (let i = 0; i < DOCS; i++) {
    const w = value(await request("work_create", { edition: { text: docText(i) } }));
    const workId = typeof w === "number" ? w : w?.work_id;
    await request("annotation_create", {
      work_id: workId,
      annotation_id: 1,
      kind: "language",
      payload: JSON.stringify({ lang: "en" }),
      char_start: 0,
      char_end: 0,
      is_private: false,
    });
    ids.push(workId);
  }
  console.log(`seeded ${ids.length} distinct English works (4 translation units each)`);

  const url = (id) => `${aliasBase()}/api/public/work/${id.toString(16).padStart(4, "0")}`;
  const langUrl = (id) => `${url(id)}?lang=fr`;

  // Probe alias reachability once; fall back to paced single-IP.
  try {
    const probe = await fetch(aliasBaseFor(ALIASES[1]) + "/health", {
      signal: AbortSignal.timeout(2000),
    });
    if (probe.ok) paced = false;
  } catch {
    /* stay paced */
  }
  console.log(paced
    ? `alias IPs unreachable here — paced mode: 100-req bursts, 61s window resets`
    : `alias mode: spreading load across ${ALIASES.length} loopback IPs`);

  let rateLimited = 0;
  const one = async (u) => {
    const t0 = performance.now();
    const r = await fetch(u);
    const text = await r.text();
    if (r.status === 429) {
      rateLimited++;
      return { ms: performance.now() - t0, body: null, limited: true };
    }
    if (!r.ok) throw new Error(`HTTP ${r.status}: ${text.slice(0, 60)}`);
    return { ms: performance.now() - t0, body: JSON.parse(text) };
  };

  // ---- phase A: warm (cache hits; engine untouched) -----------------
  // Prime doc[0] once, then sweep concurrency levels on it.
  await one(langUrl(ids[0]));
  console.log("\n[A] warm reads — ?lang=fr, all cache hits (engine idle)");
  console.log("    conc   reqs   req/s    p50     p95");
  for (const c of [1, 4, 16, 32]) {
    await windowReset();
    const N = paced ? 100 : 240;
    const lat = [];
    const ok = [];
    const t0 = performance.now();
    await pool(Array.from({ length: N }, (_, k) => k), c, async () => {
      const r = await one(langUrl(ids[0]));
      lat.push(r.ms);
      if (!r.limited) ok.push(r.ms);
    });
    const dur = (performance.now() - t0) / 1000;
    const served = ok.length;
    console.log(
      `    ${String(c).padStart(4)}  ${String(N).padStart(6)}  ${String((served / dur).toFixed(0)).padStart(6)}  ${pct(ok, 50).toFixed(0).padStart(5)}ms  ${pct(ok, 95).toFixed(0).padStart(6)}ms${served < N ? `  (${N - served} rate-limited)` : ""}`
    );
  }
  const check = await one(langUrl(ids[0]));
  const pcWarm = check.body?.translation?.provider_calls;
  console.log(`    provider_calls after ${paced ? 401 : 1441} warm reads: ${pcWarm} (must be 0)`);

  // Baseline: same docs, no ?lang, concurrency 8.
  await windowReset();
  const baseLat = [];
  const tb = performance.now();
  await pool(Array.from({ length: 240 }, (_, k) => ids[k % ids.length]), 8, async (id) => {
    const r = await one(url(id));
    if (!r.limited) baseLat.push(r.ms);
  });
  const baseDur = (performance.now() - tb) / 1000;
  console.log(
    `    baseline (no ?lang, conc 8): ${(baseLat.length / baseDur).toFixed(0)} req/s over ${baseLat.length} served, p95 ${pct(baseLat, 95).toFixed(0)}ms`
  );

  // ---- phase B: cold (every read a miss; engine-bound) --------------
  await windowReset();
  console.log(`\n[B] cold reads — ${ids.length} distinct docs, conc ${COLD_C}, every read a miss`);
  const coldLat = [];
  let engineCalls = 0;
  const spans = [];
  const tc = performance.now();
  await pool(ids, COLD_C, async (id) => {
    const r = await one(langUrl(id));
    if (r.limited) throw new Error("cold read rate-limited — widen the alias pool");
    coldLat.push(r.ms);
    engineCalls += r.body.translation?.provider_calls ?? 0;
    spans.push(r.body.translation?.spans_translated ?? 0);
  });
  const coldDur = (performance.now() - tc) / 1000;
  const totalSpans = spans.reduce((a, b) => a + b, 0);
  console.log(`    ${ids.length} docs in ${coldDur.toFixed(1)}s = ${(ids.length / coldDur).toFixed(2)} docs/s`);
  console.log(`    ${totalSpans} translation units = ${(totalSpans / coldDur).toFixed(1)} units/s at the engine`);
  console.log(`    engine calls: ${engineCalls} (1 batched call per doc)`);
  console.log(`    p50 ${pct(coldLat, 50).toFixed(0)}ms  p95 ${pct(coldLat, 95).toFixed(0)}ms`);

  // ---- concurrent-reader arithmetic ---------------------------------
  console.log("\n[C] arithmetic (verify against your own read-rate assumption)");
  console.log(`    per-reader design cap: 120 public reads/min per IP (rate limiter) = 2/s sustained`);
  console.log(`    at 1 page per 30s per reader: readers supported ≈ phase-A req/s × 30`);
  console.log(`    new-content absorption: ${(ids.length / coldDur).toFixed(2)} first-views/s, once per (doc, language) ever`);
  console.log(`    429s observed (should be 0 with alias pool): ${rateLimited}`);

  ws.close();
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
