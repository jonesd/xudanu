#!/usr/bin/env node
// capture-showcase.mjs — drive a running Xudanu server with Playwright
// and capture screenshots of the showcase features, including
// multi-step FLOW sequences (numbered files).
//
// Usage:  node scripts/capture-showcase.mjs [base-url]
//         default base: http://127.0.0.1:8081  (the seeded demo server)
// Output: docs/screenshots/showcase/NN-*.png
//
// The same script runs against https://xudanu.com once v1.12.1 +
// --seed-links-demo are deployed there.
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.argv[2] || "http://127.0.0.1:8081";
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/screenshots/showcase");
fs.mkdirSync(OUT, { recursive: true });

let counter = 0;
const results = [];
async function shot(page, name) {
  counter += 1;
  const file = `${String(counter).padStart(2, "0")}-${name}.png`;
  await page.screenshot({ path: path.join(OUT, file), fullPage: false });
  results.push(file);
  console.log("  ✓", file);
}

const browser = await chromium.launch();
const ctx = await browser.newContext({
  viewport: { width: 1440, height: 900 },
  deviceScaleFactor: 2,
});
const page = await ctx.newPage();
page.setDefaultTimeout(8000);

async function openWork(title) {
  await page.goto(BASE);
  await page.waitForTimeout(900);
  // app lands in welcome mode — open the Library rail first
  const libBtn = page.locator("button", { hasText: "Library" }).first();
  if (await libBtn.count() > 0 && await libBtn.isVisible()) {
    await libBtn.click();
    await page.waitForTimeout(600);
  }
  await page.waitForSelector(".ws-work-item", { timeout: 6000 });
  const item = page.locator(`.ws-work-item`, { hasText: title }).first();
  await item.click();
  await page.waitForSelector(".editor-content");
  await page.waitForTimeout(600);
}

async function flow(name, fn) {
  console.log("FLOW:", name);
  try {
    await fn();
  } catch (e) {
    console.log("  ✗ flow failed, continuing:", e.message.split("\n")[0]);
  }
}

// ── 1. Landing / library ────────────────────────────────────────────
await flow("library", async () => {
  await page.goto(BASE);
  await page.waitForTimeout(900);
  await shot(page, "welcome");
  const libBtn = page.locator("button", { hasText: "Library" }).first();
  await libBtn.click();
  await page.waitForSelector(".ws-work-item", { timeout: 6000 });
  await page.waitForTimeout(500);
  await shot(page, "library-work-list");
});

// ── 2. Links Lesson 1: typed link underline + hover card ────────────
await flow("lesson1-link", async () => {
  await openWork("Links Lesson 1");
  await shot(page, "lesson1-underlines");
  const live = page.getByText("its underline connects to a line in the Lesson Companion").first();
  await live.hover().catch(() => {});
  await page.locator(".marker-tooltip-link").waitFor({ state: "visible", timeout: 3000 }).catch(() => {});
  await shot(page, "lesson1-hover-card");
});

// ── 3. Lesson 2: three-ended connection ─────────────────────────────
await flow("lesson2-multi-ended", async () => {
  await openWork("Links Lesson 2");
  await shot(page, "lesson2-three-ends");
});

// ── 4. Lesson 3: gathered end-sets + chips ───────────────────────────
await flow("lesson3-gathered", async () => {
  await openWork("Links Lesson 3");
  await page.waitForTimeout(400);
  await shot(page, "lesson3-gathered-chips");
});

// ── 5. Connections panel (typed links list) ─────────────────────────
await flow("connections", async () => {
  await openWork("Links Lesson 2");
  const connTab = page.locator("button, [role='tab'], .ctx-title", { hasText: "Links" }).first();
  if (await connTab.count() > 0) {
    await connTab.click();
    await page.waitForTimeout(600);
    await shot(page, "connections-typed-links");
  }
});

// ── 6. Compare: essay vs critique (aligned diff) ────────────────────
await flow("compare", async () => {
  await openWork("The Docuverse Idea");
  const cmpTab = page.locator("button", { hasText: "Compare" }).first();
  await cmpTab.click();
  await page.waitForTimeout(800);
  const addSel = page.locator("select").last();
  const opts = await addSel.locator("option").allTextContents().catch(() => []);
  const critique = opts.find((o) => o.includes("Critique"));
  if (critique) {
    await addSel.selectOption({ label: critique });
    await page.locator("button", { hasText: "add" }).click();
    await page.waitForTimeout(1500);
  }
  await shot(page, "compare-essay-critique");
});

// ── 7. Transclusion live-update flow (2 shots) ──────────────────────
await flow("transclusion-flow", async () => {
  await openWork("The Docuverse Idea");
  await shot(page, "transclusion-source-before");
  const editor = page.locator(".editor-content");
  await editor.click();
  // put caret in the quoted sentence, then type a marker word
  const quoted = page.locator(".editor-content", { hasText: "performance that repeats daily" });
  await page.keyboard.press("End");
  await page.keyboard.type(" EDITED-LIVE");
  await page.waitForTimeout(1500);
  await openWork("Black Swan — The Critique");
  const body = await page.locator(".editor-content").innerText();
  await shot(page, "transclusion-dest-updated");
});

// ── 8. Provenance: Harbor Log + attribution colors ──────────────────
await flow("provenance", async () => {
  await openWork("The Harbor Log");
  await page.waitForTimeout(400);
  await shot(page, "harbor-log");
  const provTab = page.locator("button, [role='tab'], .ctx-title", { hasText: "Attribution" }).first();
  if (await provTab.count() > 0) {
    await provTab.click();
    await page.waitForTimeout(600);
    await shot(page, "provenance-panel");
  }
});

// ── 9. Revision compare flow (History tab) ──────────────────────────
await flow("revision-compare", async () => {
  await openWork("The Harbor Log");
  const histTab = page.locator("button, [role='tab'], .ctx-title", { hasText: "History" }).first();
  await histTab.click();
  await page.waitForTimeout(700);
  await shot(page, "history-timeline");
  const selects = page.locator(".ws-timeline select");
  if (await selects.count() >= 2) {
    await selects.nth(0).selectOption("0").catch(() => {});
    await selects.nth(1).selectOption(String(3)).catch(() => selects.nth(1).selectOption({ label: "r3" }).catch(() => {}));
    const btn = page.locator("button", { hasText: "compare" }).first();
    await btn.click();
    await page.waitForTimeout(900);
    await shot(page, "revision-compare-hunks");
  }
});

// ── 10. Suggestions flow (4-shot sequence) ──────────────────────────
await flow("suggestions", async () => {
  // enable via the Settings modal — needs a work open first
  await openWork("Links Lesson 1");
  await page.waitForTimeout(400);
  const settings = page.locator("button", { hasText: "Settings" }).first();
  await settings.waitFor({ state: "visible", timeout: 4000 }).catch(() => {});
  await settings.click().catch(() => {});
  const sw = page.locator(".settings-section:has-text('Reference-over-copy') [role='switch']").first();
  await sw.waitFor({ state: "visible", timeout: 4000 });
  const on = await sw.getAttribute("aria-checked");
  if (on !== "true") {
    await sw.click();
    await page.waitForTimeout(400);
  }
  await shot(page, "suggestions-settings-on");
  await page.locator(".settings-close").click().catch(() => page.keyboard.press("Escape"));
  // new work + type a verbatim quote
  const newBtn = page.locator("button", { hasText: /New document|New/ }).first();
  if (await newBtn.count() > 0) {
    await newBtn.click();
    await page.waitForTimeout(800);
    await page.waitForSelector(".editor-content");
    await page.keyboard.type("A garden is not a photograph; it is a performance that repeats daily.");
    await page.waitForTimeout(1500);
    await page.waitForTimeout(800);
    await shot(page, "suggestions-card-appears");
    const accept = page.locator("button", { hasText: "Insert as transclusion" }).first();
    await accept.waitFor({ state: "visible", timeout: 4000 }).catch(async () => {
      console.log("  (card debug):", (await page.locator("[data-testid='reuse-suggestion-card']").innerHTML().catch(() => "no card")).slice(0, 200));
    });
    if (await accept.count() > 0 && await accept.isVisible()) {
      await accept.click();
      await page.waitForTimeout(1200);
      await shot(page, "suggestions-accepted-transclusion");
    }
  }
});

// ── 11. Docuverse graph ─────────────────────────────────────────────
await flow("graph", async () => {
  await page.goto(BASE);
  await openWork("Links Lesson 1");
  const graph = page.locator("[title*='graph'], button:has-text('Graph'), .ctx-title:has-text('Docuverse')").first();
  if (await graph.count() > 0) {
    await graph.click();
    await page.waitForTimeout(1000);
    await shot(page, "docuverse-graph");
  }
});

await browser.close();
console.log(`\n${results.length} screenshots → ${OUT}`);
if (results.length === 0) console.log("WARNING: no shots captured — check selectors/base URL");
