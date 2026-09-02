#!/usr/bin/env node
// screenshot-links.mjs — the FR-40 links screenshot collector (GitHub docs).
// Captures the Multi-Link Showcase work: stacked labels, gathered-end
// chips + tooltip, the bottom-bar strip, and the Connections panel.
//
// Usage: node scripts/screenshot-links.mjs [wsBase] [outDir]
//   wsBase default http://127.0.0.1:8081 (the static demo build)
import { createRequire } from "node:module";
const require = createRequire("/Users/jonesd/code/xu-gold-2026/web/app/");
const { chromium } = require("playwright-core");
import { mkdirSync, writeFileSync, existsSync, readFileSync } from "node:fs";

const BASE = process.argv[2] ?? "http://127.0.0.1:8081";
const outDir = process.argv[3] ?? "/Users/jonesd/code/xu-gold-2026/docs/screenshots-links";
const REPO = "/Users/jonesd/code/xu-gold-2026";

const browsers = JSON.parse(
  readFileSync(`${REPO}/web/app/node_modules/playwright-core/browsers.json`, "utf8"),
);
const chromiumRev = browsers.browsers.find((b) => b.name === "chromium").revision;
const base = `${process.env.HOME}/Library/Caches/ms-playwright`;
const candidates = [
  `${base}/chromium-${chromiumRev}/chrome-mac/Chromium.app/Contents/MacOS/Chromium`,
  `${base}/chromium-${chromiumRev}/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing`,
  `${base}/chromium_headless_shell-${chromiumRev}/chrome-mac/headless_shell`,
];
const executablePath = candidates.find((p) => existsSync(p));
if (!executablePath) {
  console.error("no chromium binary found (playwright-core registry)");
  process.exit(1);
}

mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch({ executablePath, headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2 });

async function openShowcase() {
  await page.goto(BASE, { waitUntil: "networkidle", timeout: 20000 });
  await page.waitForTimeout(1500);
  const item = page.locator("text=Multi-Link Showcase >> visible=true").first();
  await item.waitFor({ state: "visible", timeout: 10000 });
  await item.click();
  await page.waitForTimeout(2500);
}

async function shot(name, action) {
  try {
    if (action) await action();
    await page.screenshot({ path: `${outDir}/${name}.png`, fullPage: false });
    console.log(`ok ${name}`);
  } catch (e) {
    console.error(`fail ${name}: ${e.message.split("\n")[0]}`);
  }
}

await openShowcase();

// 1. Stacked labels: the overlap trio at the top of the work.
await shot("links-label-stacking", async () => {
  await page.mouse.move(400, 300); // clear hover
  await page.waitForTimeout(400);
});

// The editor virtualizes/off-screens content: wheel-scroll the
// editor area until the target text enters the DOM, then use it.
async function scrollToText(needle) {
  // Raw-DOM: find the text node's element, scrollIntoView, and read
  // its viewport rect (bypasses Playwright visibility heuristics).
  const rect = await page.evaluate((n) => {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      if (node.textContent?.includes(n)) {
        const el = node.parentElement;
        el.scrollIntoView({ block: "center", behavior: "instant" });
        const r = el.getBoundingClientRect();
        return { x: r.x, y: r.y, width: r.width, height: r.height };
      }
    }
    return null;
  }, needle);
  if (!rect) throw new Error(`text not found in DOM: ${needle}`);
  await page.waitForTimeout(400);
  return rect;
}

// 2. Gathered end: hover a member for the "passage i of N" tooltip
//    and the gutter chips.
await shot("links-gathered-end-tooltip", async () => {
  const box = await scrollToText("performance repeats daily");
  await page.mouse.move(box.x + 10, box.y + box.height / 2);
  await page.waitForTimeout(900); // tooltip fade-in
});

// 3. Bottom bar: click inside a member so the caret drives the
//    gathered-end strip with its numbered jump buttons.
await shot("links-bottom-bar", async () => {
  const box = await scrollToText("dares own the schedule");
  await page.mouse.click(box.x + 15, box.y + box.height / 2);
  await page.waitForTimeout(900);
});

// 4. Connections panel: rows with "N passages", type badges, chips.
await shot("links-connections-panel", async () => {
  const linksTab = page.locator('button:has-text("Links")').first();
  if (await linksTab.isVisible({ timeout: 4000 }).catch(() => false)) {
    await linksTab.click();
    await page.waitForTimeout(1200);
  }
});

await browser.close();
console.log(`saved to ${outDir}`);
