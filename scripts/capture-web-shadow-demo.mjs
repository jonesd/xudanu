#!/usr/bin/env node
// capture-web-shadow-demo.mjs — screenshots of "Room 11 — The
// Disagreed Article" (FR-79 web shadow demo):
//   1. the room with its Links panel (Disagreement row + ⇄)
//   2. the shadow work with the live-window banner
//   3. the compare view against the shadow
//
// Usage:  node scripts/capture-web-shadow-demo.mjs [base-url]
//   default: http://localhost:5173 (vite dev server)
// Output: docs/screenshots/web-shadow-demo/NN-*.png
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import path from "node:path";
import fs from "node:fs";
import { fileURLToPath } from "node:url";

const BASE = process.argv[2] || "http://localhost:5173";
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/screenshots/web-shadow-demo");
fs.mkdirSync(OUT, { recursive: true });

async function openWork(page, title) {
  await page.goto(BASE);
  await page.waitForTimeout(1500);
  const libBtn = page.locator("button", { hasText: "Library" }).first();
  try { await libBtn.click(); await page.waitForTimeout(600); } catch {}
  await page.waitForSelector(".ws-work-item", { timeout: 10000 });
  const search = page.locator("input[placeholder*='Search'], input[type='search']").first();
  try {
    if (await search.isVisible()) {
      await search.fill(title.slice(0, 24));
      await page.waitForTimeout(500);
    }
  } catch {}
  const item = page.locator(".ws-work-item", { hasText: title.slice(0, 30) }).first();
  await item.click();
  await page.waitForTimeout(1500);
}

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2 });

// 1. Room 11 with Links panel
await openWork(page, "Room 11: The Disagreed Article");
const linksTab = page.locator("button", { hasText: "Links" }).first();
try { await linksTab.click(); await page.waitForTimeout(800); } catch {}
await page.screenshot({ path: path.join(OUT, "01-room-links-panel.png") });
console.log("  ✓ 01-room-links-panel.png");

// 2. The shadow work (banner)
await openWork(page, "Project Xanadu");
await page.waitForTimeout(1500);
await page.screenshot({ path: path.join(OUT, "02-shadow-banner.png") });
console.log("  ✓ 02-shadow-banner.png");

// 3. Compare: back to room, press ⇄ on the Disagreement row
await openWork(page, "Room 11: The Disagreed Article");
const linksTab2 = page.locator("button", { hasText: "Links" }).first();
try { await linksTab2.click(); await page.waitForTimeout(800); } catch {}
const compareBtn = page.locator("button[title*='compare'], button[title*='Compare']").first();
try {
  await compareBtn.click();
  await page.waitForTimeout(1500);
} catch { console.log("  (compare button not found — capturing panel only)"); }
await page.screenshot({ path: path.join(OUT, "03-compare.png") });
console.log("  ✓ 03-compare.png");

await browser.close();
console.log("DONE");
