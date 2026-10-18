// seed-walkthrough.mjs — "Building Documents from Sources": a
// walkthrough that teaches compound assembly BY EXAMPLE — each step
// quotes live material from the lawyer-scenario corpus. Then captures
// a fresh screenshot set of the complete compound flow.
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import WebSocket from "../web/app/node_modules/ws/index.js";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SHOTS = path.resolve(HERE, "../docs/screenshots");
fs.mkdirSync(SHOTS, { recursive: true });

const ws = new WebSocket(
  `ws://127.0.0.1:8080/xudanu?format=json&login=public&csrf_token=${await fetch("http://127.0.0.1:8080/csrf-token").then((r) => r.json()).then((d) => d.csrf_token)}`,
  { headers: { Origin: "http://localhost:5173" } },
);
await new Promise((res, rej) => { ws.on("open", res); ws.on("error", rej); });
let seq = 0;
const call = (op, payload) => new Promise((resolve) => {
  const id = ++seq + 100;
  const on = (d) => { try { const m = JSON.parse(d.toString()); if (m.id === id || m.type === "error") { ws.off("message", on); resolve(m); } } catch {} };
  ws.on("message", on);
  ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload: payload ?? {} }));
  setTimeout(() => { ws.off("message", on); resolve({ type: "timeout" }); }, 8000);
});
const ok = async (label, op, payload) => {
  const r = await call(op, payload);
  if (r.type === "error") { console.log(`FAIL ${label}: ${r.message}`); process.exit(1); }
  return r.value?.value;
};
const STATUTE = 0x6e5, PRECEDENT = 0x6e6, MEMO = 0x6e7, BRIEF = 0x6e8;

// ── seed the walkthrough ─────────────────────────────────────────
const src = async (W, phrase) => {
  const ed = await ok("edition", "work_get_edition", { work_id: W });
  const v = ed?.value ?? ed;
  const text = v?.text ?? (v?.entries ?? []).map((e) => (e[1]?.Text ? e[1].Text.text : "")).join("");
  const i = text.indexOf(phrase);
  return { src: W, start: i, end: i + phrase.length };
};
const q1 = await src(STATUTE, "in no case beyond twenty-four months absent express consent");
const q2 = await src(MEMO, "an IT manager noticed an exposed database");
const q3 = await src(PRECEDENT, "not when the full scope is understood");
const q4 = await src(BRIEF, "The duty to erase matured the day the intake purpose ended");

const SEG = [
  "Building Documents from Sources\nA walkthrough, assembled by the process it describes.\n\nEvery quotation in this document is live. The materials come from the lawyer-scenario corpus: a statute, a precedent, a client memo, and the memorandum built from them.\n\nStep 1 — Collect\nOpen a source and select the passage that matters. The retention ceiling is the fact this example needs: ",
  "«Q1»",
  "\n\nStep 2 — Note the facts\nGather from every kind of source. Client memos carry the dates that make or break the argument — here, the discovery event: ",
  "«Q2»",
  "\n\nStep 3 — Structure\nOrder the material before writing. The walkthrough suggests: duty, timeline, exposure, weak point. The precedent supplies the rule that fixes the timeline: the clock runs from knowledge, ",
  "«Q3»",
  ".\n\nStep 4 — Assemble\nWrite your analysis around the quotations. The result reads as one document but remains many windows — like this line from the finished memorandum: ",
  "«Q4»",
  "\n\nStep 5 — Verify and export\nEdit any source; this document flags the drift. Export from settings when it must travel: the export carries every citation.\n\nThis document practices what it explains. Click any quotation to visit its origin.",
];
let base = "";
const inserts = [];
for (let i = 0; i < SEG.length; i++) {
  base += SEG[i];
  if (i === 0) inserts.push({ pos: base.length, ...q1 });
  if (i === 2) inserts.push({ pos: base.length, ...q2 });
  if (i === 4) inserts.push({ pos: base.length, ...q3 });
  if (i === 6) inserts.push({ pos: base.length, ...q4 });
}
const walk = await ok("create", "work_create", { edition: { text: base } });
await ok("title", "work_set_title", { work_id: walk, title: "Building Documents from Sources" });
inserts.sort((a, b) => b.pos - a.pos);
for (const e of inserts) {
  await ok("element", "element_insert", {
    work_id: walk, position: e.pos,
    element: { type: "transclusion", transclusion_source: e.src, transclusion_start: e.start, transclusion_end: e.end },
  });
}
console.log(`walkthrough seeded: 0x${walk.toString(16)} (${inserts.length} live quotations)`);
ws.close();

// ── screenshots ───────────────────────────────────────────────────
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const shot = async (name) => { await page.screenshot({ path: path.join(SHOTS, `compound2-${name}.png`) }); console.log(`✓ compound2-${name}.png`); };

await page.goto("http://localhost:5173/?work=0x6e8");
await sleep(6000);
await shot("01-brief-top");
await page.mouse.wheel(0, 2400);
await sleep(1200);
await shot("02-brief-quotations");

await page.goto(`http://localhost:5173/?work=0x${STATUTE.toString(16)}`);
await sleep(5000);
await shot("03-source-statute");

await page.goto(`http://localhost:5173/?work=0x${walk.toString(16)}`);
await sleep(6000);
await page.mouse.wheel(0, 900);
await sleep(1000);
await shot("04-walkthrough-steps");

// export dialog on the brief
await page.goto("http://localhost:5173/?work=0x6e8");
await sleep(5000);
const gear = page.locator('button[title*="ettings"], .ws-action-btn:has-text("⚙")').first();
if (await gear.count()) {
  await gear.click().catch(() => {});
  await sleep(1200);
  await shot("05-export-dialog");
}
await browser.close();
console.log("done");
process.exit(0);
