#!/usr/bin/env node
// screenshot-classic.mjs — the '72 reading room, captured for essays
// and promotion (docs/screenshots-classic/).
//
// Frames, in teaching order:
//   1. gate.png           — the honest front door before connecting
//   2. reading-room.png   — trails panel + the Links Course article
//   3. beams.png          — parallel pages, underline followed into
//                           column B, connection drawn as a beam
//   4. nelson-box.png     — a seeded transclusion work with its
//                           identity box (↩ source tab)
//
// Usage: node scripts/screenshot-classic.mjs [base] [outDir]
//   base default http://127.0.0.1:8082 (the seeded production-shaped
//   preview: owner-only policy, Links Course corpus)
import { createRequire } from "node:module";
const require = createRequire("/Users/jonesd/code/xu-gold-2026/web/app/");
const { chromium } = require("playwright-core");
import { mkdirSync, existsSync, readFileSync } from "node:fs";

const BASE = process.argv[2] ?? "http://127.0.0.1:8082";
const outDir = process.argv[3] ?? "/Users/jonesd/code/xu-gold-2026/docs/screenshots-classic";
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
  console.error("no chromium found under", base);
  process.exit(1);
}

mkdirSync(outDir, { recursive: true });
const shot = (page, name) => page.screenshot({ path: `${outDir}/${name}` });
const settle = (ms) => new Promise((r) => setTimeout(r, ms));
const activeTitleText = (page) =>
  page
    .locator("#pane-a .stack-work-title")
    .first()
    .textContent()
    .then((t) => (t ? t.trim() : null))
    .catch(() => null);

const browser = await chromium.launch({ executablePath, headless: true });
const page = await browser.newPage({
  viewport: { width: 1680, height: 1050 },
  deviceScaleFactor: 2,
});

try {
  // 1. The gate — before connecting.
  await page.goto(`${BASE}/classic/`, { waitUntil: "domcontentloaded" });
  await page.locator(".gate").waitFor({ timeout: 15_000 });
  await settle(600);
  await page.mouse.move(0, 0);
  await shot(page, "gate.png");
  console.log("gate.png");

  // Connect — anonymous read on the production-shaped policy.
  await page.getByRole("button", { name: "connect" }).click();
  await page.locator("header .mark").waitFor({ timeout: 15_000 });
  await page.locator("#trails a[data-trail]").first().waitFor({ timeout: 15_000 });
  await settle(700);

  // 2. Reading room — the trails panel with the course open.
  await page.locator("#trails a[data-trail]").first().click();
  await page.locator(".trail-stops a").first().waitFor({ timeout: 15_000 });
  await settle(500);
  await page.mouse.move(0, 0);
  await shot(page, "reading-room.png");
  console.log("reading-room.png");

  // 3. Beams — lesson 1, follow the first underline into column B.
  await page.locator(".trail-stops a").first().click();
  await page.locator("#scroll-a").waitFor({ timeout: 15_000 });
  await page.locator("#scroll-a mark[data-link]").first().waitFor({ timeout: 15_000 });
  await page.locator("#scroll-a mark[data-link]").first().click();
  await page.locator("#pane-b:not(.ghost) .stack-work-title").first().waitFor({ timeout: 15_000 });
  await page
    .locator("#beams path:not(.beam-hit)")
    .first()
    .waitFor({ timeout: 10_000 });
  await settle(600); // let beams + tboxes finish their overlay math
  await page.mouse.move(0, 0);
  await shot(page, "beams.png");
  console.log("beams.png");

  // 4. Nelson box — find a seeded work whose inline resolution draws
  //    identity boxes (Gallery annex works carry transclusions).
  const navIds = await page.$$eval("nav a[data-work]", (els) =>
    [...new Set(els.map((e) => e.getAttribute("data-work")))].filter(Boolean),
  );
  console.log(`probing ${navIds.length} works for transclusions...`);
  let boxed = false;
  for (const id of navIds) {
    await page.evaluate((wid) => {
      location.hash = `#w${wid}`;
    }, Number(id));
    await page.locator("#scroll-a").waitFor({ timeout: 8_000 }).catch(() => {});
    await settle(900); // fetch + inline resolve + tbox draw
    const n = await page.locator("#pane-a .tbox").count();
    const title = (await activeTitleText(page)) ?? "?";
    console.log(`  work ${id} (${title.slice(0, 40)}): ${n} identity box(es)`);
    if (n > 0) {
      console.log(`  work ${id}: ${n} identity box(es)`);
      await page.locator("#pane-a .tbox").first().waitFor({ state: "visible", timeout: 5_000 });
      await page.mouse.move(0, 0);
      await shot(page, "nelson-box.png");
      boxed = true;
      break;
    }
  }
  console.log(boxed ? "nelson-box.png" : "nelson-box.png SKIPPED (no seeded transclusion found)");
} catch (e) {
  console.error("capture failed:", e.message);
  process.exitCode = 1;
} finally {
  await browser.close();
}
