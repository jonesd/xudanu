#!/usr/bin/env node
// examples/screenshots.mjs — product screenshots via Playwright.
//
// Shoots the Titanium Debate cluster on the running dev stack
// (server :8080, vite :5173):
//
//   1. document.png    — the plan with underlines + margin ribbons
//   2. links-panel.png — argument chains, proposals, filters
//   3. map-tab.png     — the derived argument map tree
//   4. tooltip.png     — margin-bar hover tooltip
//
//   node examples/screenshots.mjs [work-hex]
import { chromium } from "../web/extension/test/node_modules/playwright/index.mjs";
import fs from "node:fs";

const WORK = process.argv[2] ?? "0x662";
const OUT = "docs/screenshots";
fs.mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({
  viewport: { width: 1680, height: 1050 },
  deviceScaleFactor: 2,
});

const url = `http://localhost:5173/?work=${WORK}`;
console.log("◆ opening", url);
await page.goto(url, { waitUntil: "networkidle", timeout: 60_000 });

// Dismiss any first-run overlays (identity modal, welcome hints).
for (const escape of [1, 2]) {
  await page.keyboard.press("Escape").catch(() => {});
  await page.waitForTimeout(300);
}

// Wait for the document text and the canvas overlay (markers).
await page.waitForSelector(".ws-doc-title-text", { timeout: 30_000 });
await page.waitForFunction(
  () => document.body.innerText.includes("duralum"),
  { timeout: 30_000 },
);
await page.waitForTimeout(3500); // markers/ribbons draw + settle

const clickTab = async (label) => {
  const tab = page.locator(`.ws-tab`, { hasText: label }).first();
  if (await tab.count()) {
    await tab.click().catch(() => {});
    await page.waitForTimeout(1200);
    return true;
  }
  return false;
};

// 1. Document view with the Links panel open (chains visible).
if (await clickTab("Links")) {
  // Give the panel a moment to load links, then shoot full page.
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${OUT}/document.png` });
  console.log("◆ document.png");

  // 2. Links panel close-up.
  const panel = page.locator(".ws-tab-content").first();
  if (await panel.count()) {
    await panel.screenshot({ path: `${OUT}/links-panel.png` }).catch(() => {});
    console.log("◆ links-panel.png");
  }
}

// 3. The argument map.
if (await clickTab("Map")) {
  await page.waitForTimeout(1500);
  // Select the root contention so the authoring bar shows.
  await page.locator("svg[aria-label='argument map'] g").first().click().catch(() => {});
  await page.waitForTimeout(600);
  const panel = page.locator(".ws-tab-content").first();
  if (await panel.count()) {
    await panel.screenshot({ path: `${OUT}/map-tab.png` }).catch(() => {});
  } else {
    await page.screenshot({ path: `${OUT}/map-tab.png` });
  }
  console.log("◆ map-tab.png");
}

// 4. Margin-bar hover tooltip (back to the document; hover a ribbon).
await page.mouse.move(0, 0);
await clickTab("Links").catch(() => {});
// Find the canvas overlay and hover its right-margin ribbon zone:
// move along x = width-8 for the document height until a tooltip appears.
const hasTooltip = await page.evaluate(() => !!document.querySelector(".marker-tooltip"));
if (!hasTooltip) {
  const canvas = page.locator("canvas").first();
  if (await canvas.count()) {
    const box = await canvas.boundingBox();
    if (box) {
      for (let y = 200; y < Math.min(box.height, 900); y += 60) {
        await page.mouse.move(box.x + box.width - 8, box.y + y, { steps: 4 });
        await page.waitForTimeout(450);
        if (await page.evaluate(() => !!document.querySelector(".marker-tooltip"))) break;
      }
      await page.waitForTimeout(800);
      await page.screenshot({ path: `${OUT}/tooltip.png` });
      console.log("◆ tooltip.png");
    }
  }
}

await browser.close();
console.log(`\n◆ done — ${OUT}/`);
