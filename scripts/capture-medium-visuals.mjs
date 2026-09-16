#!/usr/bin/node
// capture-medium-visuals.mjs — two images for the Medium essay:
//   1. docs/screenshots/medium/two-window-transclusion.png
//      The original passage and its live quotation, stacked, labeled.
//   2. docs/screenshots/medium/density-composite.png
//      1 / 2 / 4 / 8 links on the same passage, 2x2 grid, labeled.
// Navigates via Library (deep links don't render the editor).
// Compositing happens in a blank browser page via data URIs (no image libs).
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";

const BASE = "http://localhost:5173";
const OUT = "docs/screenshots/medium";
fs.mkdirSync(OUT, { recursive: true });

async function openWork(page, title) {
  await page.goto(BASE);
  await page.waitForTimeout(1500);
  const libBtn = page.locator("button", { hasText: "Library" }).first();
  try { await libBtn.click(); await page.waitForTimeout(800); } catch {}
  await page.waitForSelector(".ws-work-item", { timeout: 10000 });
  const item = page.locator(".ws-work-item", { hasText: title }).first();
  await item.click();
  await page.waitForSelector(".editor-content", { timeout: 10000 });
  await page.waitForTimeout(2000);
}

// Locate a text fragment even when spans split it across text nodes.
// Returns a viewport rect spanning the fragment (+ up to `tail` extra chars).
async function rectForFragment(page, fragment, tail = 60) {
  return page.evaluate(({ frag, tail }) => {
    const root = document.querySelector(".editor-content");
    if (!root) return null;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const nodes = [];
    let full = "";
    let n;
    while ((n = walker.nextNode())) {
      nodes.push({ node: n, start: full.length });
      full += n.textContent;
    }
    const i = full.indexOf(frag);
    if (i < 0) return null;
    const end = Math.min(full.length, i + frag.length + tail);
    const startNode = nodes.find((e) => e.node && i >= e.start && i < e.start + e.node.textContent.length);
    let endNode = null;
    for (const e of nodes) {
      if (e.node && end > e.start && end <= e.start + e.node.textContent.length) { endNode = e.node; break; }
    }
    if (!startNode || !endNode) return null;
    const range = document.createRange();
    range.setStart(startNode.node, i - startNode.start);
    range.setEnd(endNode, end - nodes.find((e) => e.node === endNode).start);
    const rect = range.getBoundingClientRect();
    return { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
  }, { frag: fragment, tail });
}

async function scrollToFragment(page, fragment) {
  await page.evaluate((frag) => {
    const root = document.querySelector(".editor-content");
    if (!root) return;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    let full = "";
    const nodes = [];
    let n;
    while ((n = walker.nextNode())) {
      nodes.push({ node: n, start: full.length });
      full += n.textContent;
    }
    const i = full.indexOf(frag);
    if (i < 0) return;
    const startNode = nodes.find((e) => e.node && i >= e.start && i < e.start + e.node.textContent.length);
    if (startNode && startNode.node.parentElement) {
      startNode.node.parentElement.scrollIntoView({ block: "center" });
    }
  }, fragment);
  await page.waitForTimeout(700);
}

async function composite(browser, panels, outFile) {
  const page = await browser.newPage({ viewport: { width: 1240, height: 200 } });
  const items = panels
    .map(
      (p) => `<div class="panel">
        <img src="data:image/png;base64,${p.data.toString("base64")}"/>
        ${p.label ? `<div class="label">${p.label}</div>` : ""}
      </div>`,
    )
    .join("");
  await page.setContent(`<!doctype html><html><head><style>
    body { margin: 0; padding: 28px; background: #ffffff; font-family: -apple-system, "Helvetica Neue", sans-serif; }
    .stack { display: flex; flex-direction: column; gap: 28px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
    .panel { background: #ffffff; }
    .panel img { width: 100%; display: block; border: 1px solid #e3e3e8; border-radius: 6px; }
    .label { padding: 8px 4px 0; font-size: 13px; letter-spacing: 0.06em; text-transform: uppercase; color: #6b6b76; }
  </style></head><body><div class="${panels.length > 2 ? "grid" : "stack"}">${items}</div></body></html>`,
    { waitUntil: "networkidle" });
  await page.waitForTimeout(400);
  await page.screenshot({ path: outFile, fullPage: true });
  await page.close();
  console.log("  saved", path.basename(outFile));
}

async function nonWhiteFraction(browser, buf) {
  const p = await browser.newPage();
  const pct = await p.evaluate(async (b64) => {
    const img = new Image();
    img.src = "data:image/png;base64," + b64;
    await img.decode();
    const W = 200;
    const H = Math.max(1, Math.round((img.height / img.width) * W));
    const c = document.createElement("canvas");
    c.width = W; c.height = H;
    const ctx = c.getContext("2d");
    ctx.drawImage(img, 0, 0, W, H);
    const d = ctx.getImageData(0, 0, W, H).data;
    let nw = 0;
    for (let i = 0; i < d.length; i += 4) if (d[i] < 240 || d[i + 1] < 240 || d[i + 2] < 240) nw++;
    return Math.round((nw / (d.length / 4)) * 100);
  }, buf.toString("base64"));
  await p.close();
  return pct;
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 1440, height: 900 },
    deviceScaleFactor: 2,
  });
  page.setDefaultTimeout(15000);

  console.log("── Two-window transclusion ──");
  await openWork(page, "Link Density Demo");

  const transclusionCount = await page.evaluate(
    () => document.querySelectorAll(".inline-transclusion").length,
  );
  console.log("  inline-transclusion elements:", transclusionCount);

  const panels = [];

  if (transclusionCount > 0) {
    await page.evaluate(() => {
      const el = document.querySelector(".inline-transclusion");
      el.scrollIntoView({ block: "center" });
    });
    await page.waitForTimeout(900);
    const r = await page.evaluate(() => {
      const el = document.querySelector(".inline-transclusion");
      const rect = el.getBoundingClientRect();
      return { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
    });
    const clip = {
      x: Math.max(0, r.x - 380),
      y: Math.max(0, r.y - 140),
      width: Math.min(r.width + 560, 1100),
      height: r.height + 240,
    };
    const quotation = await page.screenshot({ clip });
    panels.push({ data: quotation, label: "The quotation — included by reference, live" });

    await openWork(page, "Transclusion Source");
    await scrollToFragment(page, "The garden is not a photograph");
    const sr = await rectForFragment(page, "The garden is not a photograph", 60);
    if (sr) {
      const clip2 = {
        x: Math.max(0, sr.x - 380),
        y: Math.max(0, sr.y - 140),
        width: 1100,
        height: sr.height + 240,
      };
      const original = await page.screenshot({ clip: clip2 });
      panels.push({ data: original, label: "The original — the only stored copy" });
    } else {
      console.log("  ! source passage not found");
    }
  }

  if (panels.length === 2) {
    await composite(browser, panels, path.join(OUT, "two-window-transclusion.png"));
  } else {
    console.log("  ! skipping two-window composite (panels incomplete)");
  }

  console.log("── Density composite ──");
  await openWork(page, "Link Density Demo");

  const shots = [];
  for (const [key, label] of [
    ["This sentence has exactly one link", "1 link — a single clean connection"],
    ["This sentence has two links stacked", "2 links — stacked, both readable"],
    ["This sentence has four links stacked", "4 links — density is visible"],
    ["This sentence has eight links", "8 links — collapsed into a pill"],
  ]) {
    await scrollToFragment(page, key);
    const r = await rectForFragment(page, key, 20);
    if (!r) { console.log("  ! not found:", key); continue; }
    const clip = {
      x: Math.max(0, r.x - 140),
      y: Math.max(0, r.y - 60),
      width: Math.min(r.width + 360, 1040),
      height: r.height + 100,
    };
    const buf = await page.screenshot({ clip });
    shots.push({ data: buf, label });
    console.log("  clipped:", key, "clip=", JSON.stringify(clip), `nonWhite=${await nonWhiteFraction(browser, buf)}%`);
  }

  if (shots.length === 4) {
    await composite(browser, shots, path.join(OUT, "density-composite.png"));
  } else {
    console.log("  ! skipping density composite (got", shots.length, "of 4)");
  }

  await browser.close();
  console.log(`\nDone. Output in ${OUT}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
