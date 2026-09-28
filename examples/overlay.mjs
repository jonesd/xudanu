#!/usr/bin/env node
// examples/overlay.mjs — FR-79 Stage 2, as a running walkthrough.
//
// The overlay marks query is the extension's one API call: POST
// /api/overlay/marks { url, page_text }. The SERVER resolves every
// anchor against the exact page text the caller extracted — one
// anchoring implementation, proof tiers (fingerprint → context →
// excerpt → hidden). This script runs the whole loop without a
// browser: it serves a fixture page, shadows it, links onto a
// passage, then queries marks as the extension would — before and
// after the page is edited.
//
// Start your server with loopback fetches allowed:
//
//   XUDANU_ADMIN_PASSPHRASE=... xudanu-server run 127.0.0.1:8080 data --allow-loopback
//   node examples/overlay.mjs [ws-url]
//   e.g. node examples/overlay.mjs ws://127.0.0.1:8080/xudanu?format=json
//
import WebSocket from "../web/app/node_modules/ws/index.js";
import http from "node:http";
import crypto from "node:crypto";

const WS_URL = process.argv[2] ?? "ws://127.0.0.1:8080/xudanu?format=json";
const HTTP_BASE = WS_URL.replace(/^ws/, "http").replace(/\/xudanu.*$/, "");

// ── The fixture page the "browser" is visiting ─────────────────────
const PASSAGE = "the funculator must be duralum before first flight";
let pageText =
  "WidgetPerfect Engineering Memo\n\n" +
  "Safety case, draft 3.\n\n" +
  `All told, ${PASSAGE}. No exceptions were granted in the 1991 review.\n\n` +
  "The coupler remains thermoplastic pending further study.\n";

// Tiny loopback page server (stand-in for the real web).
const pageServer = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end(pageText);
});
await new Promise((res) => pageServer.listen(0, "127.0.0.1", res));
const pagePort = pageServer.address().port;
const PAGE_URL = `http://127.0.0.1:${pagePort}/memo`;
say(`◆ fixture page serving at ${PAGE_URL}\n`);

// ── Xudanu session (same shape as detectors.mjs) ───────────────────
const ws = new WebSocket(WS_URL, { headers: { origin: "http://localhost:5173" } });
let nextId = 1;
const pending = new Map();
const wsOpened = new Promise((res, rej) => { ws.once("open", res); ws.once("error", rej); });
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
      pending.delete(frame.id); clearTimeout(p.timeout);
      frame.type === "error" ? p.reject(new Error(`${p.op}: ${frame.message}`)) : p.resolve(frame.value);
    }
  }
});
const valueOf = (v) => (v && typeof v === "object" && "value" in v ? v.value : v);
function say(msg) { console.log(msg); }

async function marksQuery(url, text) {
  const res = await fetch(`${HTTP_BASE}/api/overlay/marks`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ url, page_text: text }),
  });
  return res.json();
}

function showMarks(resp) {
  say(`  shadow: ${resp.shadow ? `0x${resp.shadow.work_id} @ rev ${resp.shadow.revision}` : "none"}`);
  say(`  marks: ${resp.mark_count}`);
  for (const m of resp.marks) {
    const r = m.resolution
      ? `RESOLVED ${m.resolution.how} @ chars ${m.resolution.start}..${m.resolution.end}`
      : "hidden (no proof — the passage is not on this page)";
    say(`    · [${m.link_type_names.join(", ")}] ${m.direction} "${m.far?.title ?? "?"}" — ${r}`);
    say(`      excerpt: “${m.excerpt.slice(0, 60)}${m.excerpt.length > 60 ? "…" : ""}”`);
  }
}

await wsOpened;
await request("session_connect");
await request("session_login_public");
say("◆ connected as the public session\n");

// ── 1. Shadow the page ──────────────────────────────────────────────
const shadow = valueOf(await request("web_shadow", { url: PAGE_URL }));
say(`◆ shadow created: work 0x${shadow.work_id.toString(16)} (${shadow.created ? "new" : "existing"})`);

// ── 2. A disagreement hanging on the passage ───────────────────────
const note = valueOf(await request("work_create", {
  edition: { text: "The 1991 safety case is wrong about duralum.\n" },
}));
await request("work_set_title", { work_id: note, title: "Example — Dispute of the memo" });
await request("work_publish", { work_id: note });

const edResp = valueOf(await request("work_get_edition", { work_id: shadow.work_id }));
const shadowText =
  typeof edResp === "string" ? edResp : edResp?.text ?? edResp?.edition?.text ?? "";
if (!shadowText) throw new Error("could not read shadow text: " + JSON.stringify(edResp).slice(0, 200));
const spanStart = shadowText.indexOf(PASSAGE);
if (spanStart < 0) throw new Error("passage not found in shadow text");
const link = valueOf(await request("link_create", {
  origin: note, destination: shadow.work_id,
  origin_ref: { kind: "single", work_context: note, excerpt: "The 1991 safety case", start_position: 0, end_position: 20 },
  destination_ref: { kind: "single", work_context: shadow.work_id, excerpt: PASSAGE,
    start_position: spanStart, end_position: spanStart + PASSAGE.length },
}));
const linkId = typeof link === "number" ? link : link?.link_id;
await request("link_set_types", { link_id: linkId, link_types: [3] }); // 3 = Disagreement
say(`◆ Disagreement link 0x${linkId.toString(16)} attached to the passage\n`);

// ── 3. The extension's query, unedited page ────────────────────────
say("── marks query, page as the reader first sees it ──");
showMarks(await marksQuery(PAGE_URL, pageText));

// ── 4. The page is edited: a paragraph lands ABOVE the passage ─────
say("\n── the memo is revised upstream; the passage moves down 46 chars ──");
pageText =
  "WidgetPerfect Engineering Memo\n\n" +
  "DISTRIBUTION: widened to the regulator, per the October letter.\n\n" +
  "Safety case, draft 3.\n\n" +
  `All told, ${PASSAGE}. No exceptions were granted in the 1991 review.\n\n` +
  "The coupler remains thermoplastic pending further study.\n";
await request("web_shadow", { url: PAGE_URL, refresh: true });
showMarks(await marksQuery(PAGE_URL, pageText));

// ── 5. The passage is deleted: the mark hides, never guesses ───────
say("\n── a later draft drops the sentence entirely ──");
pageText = "WidgetPerfect Engineering Memo\n\nSafety case, final.\n\nSee the appendix.\n";
showMarks(await marksQuery(PAGE_URL, pageText));

// ── 6. A page nobody ever shadowed: the cheap exit ─────────────────
say("\n── an unshadowed URL ──");
showMarks(await marksQuery("http://127.0.0.1:1/never-seen", "some unrelated page"));

say("\n◆ done. In the browser extension the resolved offsets become");
say("  tint + margin ribbons; the hidden mark renders nothing.");

ws.close();
pageServer.close();
process.exit(0);
