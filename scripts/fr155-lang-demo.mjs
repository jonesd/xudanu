#!/usr/bin/env node
// fr155-lang-demo.mjs — FR-155 Stage 2 tracer-bullet proof.
//
// Seeds one public German work with a `kind: "language"` document
// declaration, then exercises the lazy ?lang= read path against a
// live server:
//
//   1. plain read (original, canonical)
//   2. ?lang=en first read  (miss -> provider call, PROV recorded)
//   3. ?lang=en second read (hit  -> zero provider calls)
//   4. kill-rule timing: p95 of plain vs cached translated reads
//      (budget: translated-hit p95 must stay within +500ms of plain)
//
// Requires the server to run with XUDANU_TRANSLATE_PROVIDER_URL
// pointing at a LibreTranslate-compatible engine (de<->en loaded).
//
// Usage: node scripts/fr155-lang-demo.mjs [base-url]  (default http://127.0.0.1:8090)
import WebSocket from "ws";

const base = process.argv[2] ?? "http://127.0.0.1:8090";
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

const german = `Es irrt der Mensch, solang er strebt.

Durch diese hohle Gasse muss er kommen, es führt kein andrer Weg nach Küssnacht.

Gedanken ohne Inhalt sind leer, Anschauungen ohne Begriffe sind blind.`;

const p95 = (xs) => {
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor(0.95 * s.length))];
};

async function timedGet(url) {
  const t0 = performance.now();
  const resp = await fetch(url);
  const body = await resp.json();
  return { ms: performance.now() - t0, resp, body };
}

async function main() {
  await new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
  await request("session_connect");
  await request("session_login_public");

  const w = value(await request("work_create", { edition: { text: german } }));
  const workId = typeof w === "number" ? w : w?.work_id;
  console.log(`seeded german work ${workId} (${german.length} chars)`);

  // Document-default language declaration: kind "language", empty
  // char range, payload {"lang":"de"} — declared, never detected.
  await request("annotation_create", {
    work_id: workId,
    annotation_id: 1,
    kind: "language",
    payload: JSON.stringify({ lang: "de" }),
    char_start: 0,
    char_end: 0,
    is_private: false,
  });
  console.log("declared document language: de");

  const hex = workId.toString(16).padStart(4, "0");
  const url = `${base}/api/public/work/${hex}`;

  const plain = await timedGet(url);
  console.log(`\n[1] plain read: ${plain.ms.toFixed(0)}ms`);
  console.log(`    text head: ${JSON.stringify(plain.body.text.slice(0, 40))}`);
  console.log(`    hash: ${plain.body.content_hash_blake3.slice(0, 16)}…`);

  const miss = await timedGet(`${url}?lang=en`);
  const t = miss.body.translation ?? {};
  console.log(`\n[2] ?lang=en (cold): ${miss.ms.toFixed(0)}ms`);
  console.log(`    header x-xudanu-translation: ${miss.resp.headers.get("x-xudanu-translation")}`);
  console.log(`    text head: ${JSON.stringify(miss.body.text.slice(0, 40))}`);
  console.log(`    original hash preserved: ${miss.body.original_content_hash_blake3 === plain.body.content_hash_blake3}`);
  console.log(`    translated hash differs: ${miss.body.content_hash_blake3 !== plain.body.content_hash_blake3}`);
  console.log(`    spans: ${t.spans_total} total, ${t.spans_translated} translated, provider_calls=${t.provider_calls}`);
  const r0 = (t.renditions ?? [])[0] ?? {};
  console.log(`    PROV: entity=${String(r0.rendition_hash).slice(0, 12)}… wasDerivedFrom=${String(r0.source_hash).slice(0, 12)}… wasGeneratedBy=${r0.prov?.wasGeneratedBy} grade=${r0.prov?.quality_grade}`);

  const hit = await timedGet(`${url}?lang=en`);
  const th = hit.body.translation ?? {};
  console.log(`\n[3] ?lang=en (warm): ${hit.ms.toFixed(0)}ms`);
  console.log(`    cache_hits=${th.cache_hits} provider_calls=${th.provider_calls} (must be 0)`);
  console.log(`    byte-identical text: ${hit.body.text === miss.body.text}`);

  // Kill rule: 20 plain vs 20 cached translated reads.
  const plainRuns = [];
  const langRuns = [];
  for (let i = 0; i < 20; i++) {
    plainRuns.push((await timedGet(url)).ms);
    langRuns.push((await timedGet(`${url}?lang=en`)).ms);
  }
  const pP = p95(plainRuns), pL = p95(langRuns);
  const mP = plainRuns.reduce((a, b) => a + b, 0) / plainRuns.length;
  const mL = langRuns.reduce((a, b) => a + b, 0) / langRuns.length;
  console.log(`\n[4] kill rule (20 runs each):`);
  console.log(`    plain   mean ${mP.toFixed(0)}ms  p95 ${pP.toFixed(0)}ms`);
  console.log(`    lang-hit mean ${mL.toFixed(0)}ms  p95 ${pL.toFixed(0)}ms`);
  const delta = pL - pP;
  console.log(`    p95 delta ${delta.toFixed(0)}ms — ${delta < 500 ? "WITHIN the +500ms budget" : "KILL RULE TRIPPED"}`);

  ws.close();
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
