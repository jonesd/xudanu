#!/usr/bin/node
// capture-cold-open.mjs — the video's first 15 seconds: two windows,
// edit the source, watch the placed transclusion update live with
// attribution colours flowing. Headless, deterministic, re-shootable.
//
// Usage: node scripts/capture-cold-open.mjs [base-url]
// Output: docs/videos/V0-cold-open.webm
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = "http://localhost:5173";
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/videos");
fs.mkdirSync(OUT, { recursive: true });
const W = 1440, H = 900;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  // Scene work ids from video-prep.mjs output (direct URL = deterministic)
  const arg = (n, d) => { const i = process.argv.indexOf(n); return i >= 0 ? process.argv[i + 1] : d; };
  const GARDEN = arg("--garden", "0x6d7");
  const NOTES = arg("--notes", "0x6d8");
  const browser = await chromium.launch({ headless: true });

  const ctx = await browser.newContext({
    recordVideo: { dir: OUT, size: { width: W, height: H } },
    viewport: { width: W, height: H },
  });

  // ── Window A: the source (Garden Essay) ─────────────────────────
  const pageA = await ctx.newPage();
  await pageA.goto(`${BASE}/?work=${GARDEN}`);
  await sleep(3000);

  // ── Window B (same ctx, second tab): Reading Notes with the placed quote ──
  const pageB = await ctx.newPage();
  await pageB.goto(`${BASE}/?work=${NOTES}`);
  await sleep(3000);

  // ── THE SHOT: type in the source; the placed quotation follows ──
  const editorA = pageA.locator(".editor-content, [contenteditable='true']").first();
  await editorA.click({ position: { x: 200, y: 200 } }).catch(() => {});
  await sleep(400);
  // walk to the quotable sentence: select-all then click near it is flaky;
  // typing at the current position is enough visually IF the transclusion
  // is live — we type into the source near the end.
  for (const ch of " And the garden answers.") {
    await pageA.keyboard.type(ch, { delay: 90 });
    await sleep(120); // let the CRDT delta land; pageB updates live
  }
  await sleep(2500); // hold on the live update

  await ctx.close();
  const video = pageA.video();
  if (video) {
    const file = await video.path();
    fs.renameSync(file, path.join(OUT, "V0-cold-open.webm"));
    console.log("✓ docs/videos/V0-cold-open.webm");
  }
  await browser.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
