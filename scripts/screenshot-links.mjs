#!/usr/bin/env node
// screenshot-links.mjs — the FR-40 links screenshot collector (GitHub docs).
//
// Progression by design: ONE link first, then ONE gathered end, then the
// complex interacting case, then the panel — dense multi-link renderings
// are illegible to untrained eyes, so each frame teaches one concept.
//
// Usage: node scripts/screenshot-links.mjs [wsBase] [outDir]
//   wsBase default http://127.0.0.1:8081 (the static demo build)
import { createRequire } from "node:module";
const require = createRequire("/Users/jonesd/code/xu-gold-2026/web/app/");
const { chromium } = require("playwright-core");
import { mkdirSync, existsSync, readFileSync } from "node:fs";

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

async function openWork(title) {
  await page.goto(BASE, { waitUntil: "networkidle", timeout: 20000 });
  await page.waitForTimeout(1500);
  const item = page.locator(`text=${title} >> visible=true`).first();
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

// Raw-DOM locate: TreeWalker for the text, scrollIntoView, viewport rect
// (Playwright's visibility heuristics reject text under the canvas overlay).
async function rectOf(needle) {
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

// ── 1. ONE link: the whole concept in one frame ─────────────────────────
await openWork("One Clean Link");
await shot("01-one-link", async () => {
  await rectOf("which is connected to another document");
});

// ── 2. ONE gathered end: Lesson 3 explains itself in its own text ──────
await openWork("Links Lesson 3");
await shot("02-gathered-end", async () => {
  await rectOf("Hover any of the three");
});

// 2b. The tooltip on a member (aim at the UNDERLINE strip at the line's
// bottom, where the canvas hit-zones live).
await shot("03-gathered-tooltip", async () => {
  const r = await rectOf("Hover any of the three");
  await page.mouse.move(r.x + r.width * 0.4, r.y + r.height - 2);
  await page.waitForTimeout(1000);
});

// ── 3. The complex case: labels interacting on shared lines ────────────
await openWork("Multi-Link Showcase");
await shot("04-links-interacting", async () => {
  await rectOf("The whole of this sentence");
});

// 3b. Solo/focus: hovering one connection dims every other link —
// the untrained-eye fix for the dense frame above.
await shot("04b-focus-dimming", async () => {
  const r = await rectOf("The performance repeats daily");
  await page.mouse.move(r.x + r.width * 0.4, r.y + r.height - 2);
  await page.waitForTimeout(1000);
});

// ── 4. The Connections panel: rows as the legend ───────────────────────
await shot("05-connections-panel", async () => {
  const linksTab = page.locator('button:has-text("Links")').first();
  if (await linksTab.isVisible({ timeout: 4000 }).catch(() => false)) {
    await linksTab.click();
    await page.waitForTimeout(1200);
  }
});

await browser.close();
console.log(`saved to ${outDir}`);
