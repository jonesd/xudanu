#!/usr/bin/env node
// examples/fix-link-spans.mjs — normalize link ref spans.
//
// For every link touching the given work(s): for each end ref with
// an excerpt + positions, re-derive end = start + excerpt.length
// (UTF-16 — matching the client's rendering) and push the correction
// via link_update when it differs. Fixes seed data written with
// hand-counted offsets (the missing-last-character underlines).
//
//   node examples/fix-link-spans.mjs 0x662 [0x663 ...]
import WebSocket from "../web/app/node_modules/ws/index.js";

const workIds = process.argv.slice(2).map((s) => parseInt(s, s.startsWith("0x") ? 16 : 10));
if (workIds.length === 0) {
  console.error("usage: fix-link-spans.mjs <work-id-hex>...");
  process.exit(1);
}

const csrf = await (await fetch("http://127.0.0.1:8080/csrf-token")).json();
const ws = new WebSocket(
  `ws://127.0.0.1:8080/xudanu?format=json&csrf_token=${encodeURIComponent(csrf.csrf_token ?? csrf.token ?? "")}`,
  { headers: { origin: "http://localhost:5173" } },
);
let nextId = 1;
const pending = new Map();
function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => { pending.delete(id); reject(new Error(`timeout: ${op}`)); }, 30000);
    pending.set(id, { resolve, reject, timeout: t });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}
ws.on("message", (data) => {
  const frame = JSON.parse(data.toString());
  if (frame.type === "response" || frame.type === "error") {
    const p = pending.get(frame.id);
    if (p) {
      pending.delete(frame.id); clearTimeout(p.timeout);
      frame.type === "error" ? p.reject(new Error(`${p.op}: ${frame.message}`)) : p.resolve(frame.value);
    }
  }
});
const v = (x) => (x && typeof x === "object" && "value" in x ? x.value : x);

await new Promise((r) => ws.once("open", r));
await request("session_connect");
await request("session_login_public");

const refShape = (ref, workId) => ({
  kind: "single",
  work_context: ref.work_context ?? workId,
  original_context: null,
  path_context: null,
  excerpt: ref.excerpt,
  start_position: ref.start_position,
  end_position: ref.start_position + (ref.excerpt ? ref.excerpt.length : 0),
});

let fixed = 0;
for (const wid of workIds) {
  const links = v(await request("link_list_for_work", { work_id: wid }));
  const entries = links?.entries ?? links ?? [];
  for (const l of entries) {
    const patch = {};
    for (const [end, ref] of [["origin_ref", l.origin_ref], ["destination_ref", l.destination_ref]]) {
      if (!ref || typeof ref.excerpt !== "string" || ref.excerpt.length === 0) continue;
      if (ref.start_position == null) continue;
      const wantEnd = ref.start_position + ref.excerpt.length;
      if (ref.end_position === wantEnd) continue;
      patch[end] = refShape(ref, ref.work_context ?? wid);
      console.log(
        `0x${l.link_id.toString(16)} ${end}: end ${ref.end_position} → ${wantEnd} ("${ref.excerpt.slice(0, 40)}${ref.excerpt.length > 40 ? "…" : ""}")`,
      );
    }
    if (Object.keys(patch).length > 0) {
      await request("link_update", { link_id: l.link_id, ...patch });
      fixed++;
    }
  }
}
console.log(`\n◆ ${fixed} link(s) normalized.`);
ws.close();
process.exit(0);
