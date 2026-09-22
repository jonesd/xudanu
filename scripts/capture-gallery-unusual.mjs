#!/usr/bin/env node
// capture-gallery-unusual.mjs — screenshots of THE GALLERY OF UNUSUAL
// CONNECTIONS: lobby floor plan, all nine exhibit rooms, hover states,
// the connections panel, and compare views.
//
// Usage:  node scripts/capture-gallery-unusual.mjs [base-url]
//   default: http://localhost:5173 (vite dev server)
// Output: docs/screenshots/gallery/NN-*.png
//
// Requires: the gallery seeded (seed-gallery-unusual.mjs).
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.argv[2] || "http://localhost:5173";
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/screenshots/gallery");
fs.mkdirSync(OUT, { recursive: true });

let counter = 0;
const results = [];
async function shot(page, name, opts = {}) {
  counter += 1;
  const file = `${String(counter).padStart(2, "0")}-${name}.png`;
  await page.screenshot({ path: path.join(OUT, file), fullPage: false, ...opts });
  results.push(file);
  console.log("  ✓", file);
}

async function openWork(page, title) {
  await page.goto(BASE);
  await page.waitForTimeout(1200);
  const libBtn = page.locator("button", { hasText: "Library" }).first();
  try { await libBtn.click(); await page.waitForTimeout(600); } catch {}
  await page.waitForSelector(".ws-work-item", { timeout: 8000 });
  const search = page.locator("input[placeholder*='Search'], input[type='search']").first();
  try {
    if (await search.isVisible()) {
      await search.fill(title.slice(0, 24));
      await page.waitForTimeout(500);
    }
  } catch {}
  const item = page.locator(".ws-work-item", { hasText: title.slice(0, 30) }).first();
  await item.click();
  await page.waitForSelector(".editor-content", { timeout: 8000 });
  await page.waitForTimeout(1500);
}

const ROOMS = [
  ["Gallery — Lobby", "lobby-floor-plan"],
  ["Gallery — Wing I · Room 1", "room1-spectrum-sentence"],
  ["Gallery — Wing I · Room 2", "room2-junction-word"],
  ["Gallery — Wing I · Room 3", "room3-nested-scope"],
  ["Gallery — Wing II · Room 4", "room4-quotation-genealogy"],
  ["Gallery — Wing II · Room 5", "room5-link-about-link"],
  ["Gallery — Wing III · Room 6", "room6-rebuttal-constellation"],
  ["Gallery — Wing III · Room 7", "room7-five-way-junction"],
  ["Gallery — Wing III · Room 8", "room8-standing-dispute"],
  ["Gallery — The Fabric · Room 9", "room9-live-window"],
];

async function main() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.setDefaultTimeout(12000);

  console.log("── Gallery of Unusual Connections ──\n");

  // 1. Welcome/landing: the gallery appears in the library
  await page.goto(BASE);
  await page.waitForTimeout(1500);
  await shot(page, "welcome");

  // 2. Every room, opening shot
  for (const [titlePrefix, name] of ROOMS) {
    try {
      await openWork(page, titlePrefix);
      await shot(page, name);
      // full-page variant for the room bodies (they are short docs)
      await shot(page, `${name}-full`, { fullPage: true });
    } catch (e) {
      console.log(`  (skip ${name}: ${String(e.message).slice(0, 60)})`);
    }
  }

  // 3. Interactions — the money shots
  // 3a. Spectrum hover: tooltip naming kind + far end (Room 1)
  try {
    await openWork(page, "Gallery — Wing I · Room 1");
    const rect = await page.evaluate(() => {
      const ed = document.querySelector(".editor-content");
      if (!ed) return null;
      const walker = document.createTreeWalker(ed, NodeFilter.SHOW_TEXT);
      let node;
      while ((node = walker.nextNode())) {
        const i = (node.textContent || "").indexOf("the light that never goes out");
        if (i >= 0) {
          const r = document.createRange();
          r.setStart(node, i);
          r.setEnd(node, i + 10);
          const b = r.getBoundingClientRect();
          return { x: b.x + b.width / 2, y: b.bottom - 2 };
        }
      }
      return null;
    });
    if (rect) {
      await page.mouse.move(rect.x, rect.y);
      await page.waitForTimeout(1200);
      await shot(page, "room1-hover-tooltip");
    }
  } catch (e) { console.log("  (hover shot skipped:", String(e.message).slice(0, 50) + ")"); }

  // helper: open Links tab, click compare on the first multi-ended row
  async function compareShot(roomPrefix, name) {
    await openWork(page, roomPrefix);
    const linksTab = page.locator(".ws-tab", { hasText: "Links" }).first();
    await linksTab.click();
    await page.waitForTimeout(1500);
    const cmp = page.locator('button[title="Compare all ends side by side"]').first();
    await cmp.click({ timeout: 8000 });
    await page.waitForTimeout(2500);
    await shot(page, name);
    const back = page.locator(".ws-tab", { hasText: "Links" }).first();
    if (await back.isVisible()) await back.click();
    await page.waitForTimeout(400);
  }

  // 3b. Five-way compare view (Room 7)
  try { await compareShot("Gallery — Wing III · Room 7", "room7-compare-five-ways"); }
  catch (e) { console.log("  (compare shot skipped:", String(e.message).slice(0, 50) + ")"); }

  // 3c. Standing dispute (Room 8) — 2-ended links have no ⇄; the
  // connections panel listing all four disagreement rows is the shot.
  try {
    await openWork(page, "Gallery — Wing III · Room 8");
    const linksTab = page.locator(".ws-tab", { hasText: "Links" }).first();
    await linksTab.click();
    await page.waitForTimeout(1500);
    await shot(page, "room8-connections-panel");
  } catch (e) { console.log("  (dispute panel skipped:", String(e.message).slice(0, 50) + ")"); }

  // 3b2. Connections panel on Room 7 (five named ends listed)
  try {
    await openWork(page, "Gallery — Wing III · Room 7");
    const linksTab = page.locator(".ws-tab", { hasText: "Links" }).first();
    await linksTab.click();
    await page.waitForTimeout(1500);
    await shot(page, "room7-connections-panel");
  } catch (e) { console.log("  (panel shot skipped:", String(e.message).slice(0, 50) + ")"); }

  // 3d. The receiving end: an annex with incoming margin bars
  try {
    await openWork(page, "Gallery Annex — The Convergence");
    await page.waitForTimeout(1200);
    await shot(page, "annex-convergence-arrivals");
  } catch (e) { console.log("  (annex shot skipped:", String(e.message).slice(0, 50) + ")"); }

  // 3e. Trails panel: the Curator's Tour
  try {
    await page.goto(BASE);
    await page.waitForTimeout(1200);
    const trailsBtn = page.locator("button", { hasText: "Trails" }).first();
    await trailsBtn.click();
    await page.waitForTimeout(1200);
    await shot(page, "curators-tour-trail");
  } catch (e) { console.log("  (trail shot skipped:", String(e.message).slice(0, 50) + ")"); }

  await browser.close();
  console.log(`\n${results.length} screenshots saved to ${OUT}`);
}

main().catch(e => { console.error(e); process.exit(1); });
