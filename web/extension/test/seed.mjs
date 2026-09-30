#!/usr/bin/env node
// Seed the extension-test corpus on the dev server: shadow the
// fixture article, hang a Disagreement on the passage. Idempotent.
import WebSocket from "../../app/node_modules/ws/index.js";

const WS_URL_BASE = "ws://127.0.0.1:8080/xudanu?format=json";
const PASSAGE = "the funculator must be duralum before first flight";
// One shadow + Disagreement per fixture page shape (article blockquote,
// docs table cell, blog inline em) — exercises the resolver's
// whitespace tolerance differently on each.
const PAGES = [
  "http://127.0.0.1:8899/article.html",
  "http://127.0.0.1:8899/docs.html",
  "http://127.0.0.1:8899/blog.html",
];

// The dev server runs --csrf-token: fetch one first.
const csrfResp = await fetch("http://127.0.0.1:8080/csrf-token");
const csrfJson = await csrfResp.json();
const csrfToken = csrfJson.csrf_token ?? csrfJson.token ?? "";
const ws = new WebSocket(csrfToken ? `${WS_URL_BASE}&csrf_token=${encodeURIComponent(csrfToken)}` : WS_URL_BASE, { headers: { origin: "http://localhost:5173" } });
let nextId = 1;
const pending = new Map();
const opened = new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
function request(op, payload) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const t = setTimeout(() => reject(new Error(`timeout: ${op}`)), 30000);
    pending.set(id, { resolve, reject, t });
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  });
}
ws.on("message", (data) => {
  const f = JSON.parse(data.toString());
  if (f.type === "response" || f.type === "error") {
    const p = pending.get(f.id);
    if (p) { pending.delete(f.id); clearTimeout(p.t); f.type === "error" ? p.reject(new Error(`${f.op||"?"}: ${f.message}`)) : p.resolve(f.value); }
  }
});
const v = (x) => (x && typeof x === "object" && "value" in x ? x.value : x);

await opened;
await request("session_connect");
await request("session_login_public");

for (const PAGE_URL of PAGES) {
  // Idempotent: skip pages that already carry a mark.
  const existing = await fetch("http://127.0.0.1:8080/api/overlay/marks", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ url: PAGE_URL, page_text: "" }),
  }).then((r) => r.json());
  if ((existing.mark_count ?? 0) > 0) {
    console.log(`${PAGE_URL.split("/").pop()}: already marked — skip`);
    continue;
  }

  const shadow = v(await request("web_shadow", { url: PAGE_URL }));
  console.log(`shadow: 0x${shadow.work_id.toString(16)} for ${PAGE_URL.split("/").pop()}`);

  const ed = v(await request("work_get_edition", { work_id: shadow.work_id }));
  const text = typeof ed === "string" ? ed : ed?.text ?? ed?.edition?.text ?? "";
  const at = text.indexOf(PASSAGE);
  if (at < 0) throw new Error(`passage not in ${PAGE_URL} shadow text — fixture changed?`);

  const note = v(await request("work_create", { edition: { text: "The 1991 safety case is wrong about duralum." } }));
  await request("work_set_title", { work_id: note, title: `Extension test — Dispute (${PAGE_URL.split("/").pop()})` });
  await request("work_publish", { work_id: note });

  const link = v(await request("link_create", {
    origin: note, destination: shadow.work_id,
    origin_ref: { kind: "single", work_context: note, excerpt: "The 1991 safety case", start_position: 0, end_position: 20 },
    destination_ref: { kind: "single", work_context: shadow.work_id, excerpt: PASSAGE, start_position: at, end_position: at + PASSAGE.length },
  }));
  const linkId = typeof link === "number" ? link : link?.link_id;
  await request("link_set_types", { link_id: linkId, link_types: [3] }); // Disagreement
  console.log(`  link 0x${linkId.toString(16)} Disagreement on chars ${at}..${at + PASSAGE.length}`);
}
console.log("SEEDED");
process.exit(0);
