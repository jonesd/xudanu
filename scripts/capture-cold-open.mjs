#!/usr/bin/node
// capture-cold-open.mjs — the video's opening shot, v2:
//   Window A: The Garden Essay (source)
//   Window B: Reading Notes, showing a placed TRANSClUSION of the
//             quotable sentence (a real inline element, placed via
//             the same op the Gather→Place flow uses)
//   The shot: type inside the quoted sentence in A; the quotation in
//   B updates live. Verified before saving the clip.
//
// Usage: node scripts/capture-cold-open.mjs [--garden 0x6d7] [--notes 0x6d8]
// Output: docs/videos/V0-cold-open.webm (load flash trimmed)
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import WebSocket from "../web/app/node_modules/ws/index.js";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/videos");
fs.mkdirSync(OUT, { recursive: true });
const W = 1440, H = 900;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const arg = (n, d) => { const i = process.argv.indexOf(n); return i >= 0 ? process.argv[i + 1] : d; };
const GARDEN = parseInt(arg("--garden", "0x6d7"), 16);
const NOTES = parseInt(arg("--notes", "0x6d8"), 16);
const SPAN = { start: 95, end: 137 }; // "content with one home, visible in many places"

async function placeTransclusion() {
  const tok = await fetch("http://127.0.0.1:8080/csrf-token").then((r) => r.json()).then((d) => d.csrf_token);
  const ws = new WebSocket(`ws://127.0.0.1:8080/xudanu?format=json&login=public&csrf_token=${tok}`, {
    headers: { Origin: "http://localhost:5173" },
  });
  await new Promise((res, rej) => { ws.on("open", res); ws.on("error", rej); });
  const call = (op, payload) => new Promise((resolve) => {
    const id = Math.floor(Math.random() * 9000) + 100;
    const on = (d) => { try { const m = JSON.parse(d.toString()); if (m.id === id || m.type === "error") { ws.off("message", on); resolve(m); } } catch {} };
    ws.on("message", on);
    ws.send(JSON.stringify({ v: 2, type: "request", id, op, payload }));
    setTimeout(() => { ws.off("message", on); resolve({ type: "timeout" }); }, 6000);
  });
  await call("session_connect", {});
  // at ~char 120 of Notes, after the intro line
  const r = await call("element_insert", {
    work_id: NOTES, position: 120,
    element: { type: "transclusion", transclusion_source: GARDEN, transclusion_start: SPAN.start, transclusion_end: SPAN.end },
  });
  console.log("placement:", r.type === "response" ? "ok" : JSON.stringify(r).slice(0, 120));
  ws.close();
}

async function main() {
  await placeTransclusion();
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext({ recordVideo: { dir: OUT, size: { width: W, height: H } }, viewport: { width: W, height: H } });

  const pageA = await ctx.newPage();
  await pageA.goto(`http://localhost:5173/?work=0x${GARDEN.toString(16)}`);
  const pageB = await ctx.newPage();
  await pageB.goto(`http://localhost:5173/?work=0x${NOTES.toString(16)}`);
  await sleep(5000); // both docs fully loaded before action

  // Focus the quotable sentence in A (last paragraph, ~78% down)
  const editor = pageA.locator(".editor-content").first();
  await editor.waitFor({ state: "visible", timeout: 15000 }).catch(() => {});
  const typed = " — and the garden answers.";
  let verified = false;
  for (const fy of [0.22, 0.15, 0.3]) {
    const box = await editor.boundingBox();
    if (!box) break;
    await editor.click({ position: { x: Math.min(300, box.width * 0.25), y: box.height * fy } }).catch(() => {});
    const focused = await pageA.evaluate(() => {
      const el = document.querySelector(".editor-content");
      return el && (document.activeElement === el || el.contains(document.activeElement));
    });
    if (!focused) { await sleep(500); continue; }
    await sleep(400);
    for (const ch of typed) { await pageA.keyboard.type(ch, { delay: 80 }); await sleep(90); }
    await sleep(2500);
    const quote = await pageB.locator(".inline-transclusion").first().textContent().catch(() => null);
    if (quote && quote.includes("garden answers")) { verified = true; break; }
    // undo this attempt before the next (keep the doc clean)
    await pageA.keyboard.press("Meta+z");
    await sleep(1200);
  }
  await sleep(2500); // hold on the live update
  await ctx.close();
  const video = pageA.video();
  if (video) {
    const raw = await video.path();
    // trim the load flash (first 3.5s) and re-encode
    fs.renameSync(raw, path.join(OUT, ".v0-raw.webm"));
    const { execSync } = await import("node:child_process");
    execSync(`ffmpeg -y -loglevel error -ss 3.5 -i ${OUT}/.v0-raw.webm -c:v libx264 -pix_fmt yuv420p ${OUT}/V0-cold-open.mp4`);
    fs.unlinkSync(path.join(OUT, ".v0-raw.webm"));
  }
  await browser.close();
  console.log(verified ? "✓ V0-cold-open.mp4 — quotation verified updating live" : "! saved, but live-update NOT verified — check the take");
}

main().catch((e) => { console.error(e); process.exit(1); });
