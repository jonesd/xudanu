#!/usr/bin/env node
// examples/llm-confirm-demo.mjs — the FR-86 confirm loop, headless.
//
//   node examples/llm-confirm-demo.mjs <work-id> [max-confirm]
//
// Calls llm_propose_connections on the work (the server's LLM reads
// the work + connected works + library catalog), then plays the
// human: resolves far-end titles against the library, re-anchors
// excerpts, and confirms the best proposals as ordinary links.
// In the browser the same flow is the ✨ button + Confirm.
import WebSocket from "../web/app/node_modules/ws/index.js";

const workId = parseInt(process.argv[2], 16);
const maxConfirm = parseInt(process.argv[3] ?? "2", 10);
if (!workId) { console.error("usage: llm-confirm-demo.mjs <work-id-hex> [max]"); process.exit(1); }

const csrf = await (await fetch("http://127.0.0.1:8080/csrf-token")).json();
const ws = new WebSocket(
  `ws://127.0.0.1:8080/xudanu?format=json&csrf_token=${encodeURIComponent(csrf.csrf_token ?? csrf.token ?? "")}`,
  { headers: { origin: "http://localhost:5173" } },
);
let nextId = 1; const pending = new Map();
function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 180000);
    pending.set(id, { resolve, reject, timeout: t, op });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}
ws.on("message", (data) => {
  const frame = JSON.parse(data.toString());
  if (frame.type === "response" || frame.type === "error") {
    const p = pending.get(frame.id);
    if (p) { pending.delete(frame.id); clearTimeout(p.timeout);
      frame.type === "error" ? p.reject(new Error(`${p.op}: ${frame.message}`)) : p.resolve(frame.value); }
  }
});
const v = (x) => (x && typeof x === "object" && "value" in x ? x.value : x);

await new Promise((r) => ws.once("open", r));
await request("session_connect");
await request("session_login_public");

console.log(`✨ llm_propose_connections on 0x${workId.toString(16)}…`);
const t0 = Date.now();
const proposals = v(await request("llm_propose_connections", { work_id: workId }));
console.log(`  model ${proposals?.model} (${proposals?.backend}) returned ${proposals?.proposals?.length ?? 0} in ${((Date.now() - t0) / 1000).toFixed(1)}s`);

const ed = v(await request("work_get_edition", { work_id: workId }));
const text = typeof ed === "string" ? ed : ed?.text ?? "";
const worksList = v(await request("work_list", { limit: 1000 }))?.entries ?? [];
const byTitle = new Map(worksList.map((w) => [w.title, w.work_id]));

async function link(origin, destination, oRef) {
  const id = v(await request("link_create", {
    origin, destination,
    origin_ref: { kind: "single", work_context: origin,
      excerpt: oRef.excerpt, start_position: oRef.start, end_position: oRef.end },
  }));
  return typeof id === "number" ? id : id?.link_id;
}

let confirmed = 0;
for (const p of proposals?.proposals ?? []) {
  if (confirmed >= maxConfirm) break;
  const farId = p.far_end_title ? byTitle.get(p.far_end_title) : null;
  if (!farId || farId === workId) { console.log(`  · skipped → "${p.far_end_title}" (unresolved)`); continue; }
  const at = text.indexOf(p.excerpt);
  if (at < 0) { console.log(`  · skipped (excerpt drift): "${(p.excerpt ?? "").slice(0, 40)}…"`); continue; }
  const lid = await link(workId, farId, { excerpt: p.excerpt, start: at, end: at + p.excerpt.length });
  await request("link_set_types", { link_id: lid, link_types: [p.type_id] });
  confirmed++;
  console.log(`  ✓ "${p.excerpt.slice(0, 44)}${p.excerpt.length > 44 ? "…" : ""}" → ${p.far_end_title}`);
  if (p.reasoning) console.log(`    reasoning: ${p.reasoning.slice(0, 100)}${p.reasoning.length > 100 ? "…" : ""}`);
}
console.log(`\n◆ ${confirmed} proposal(s) confirmed — ordinary links now.`);
ws.close();
process.exit(0);
