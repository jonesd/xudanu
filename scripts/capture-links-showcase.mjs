#!/usr/bin/env node
// capture-links-showcase.mjs — capture screenshots of the LINK system
// in action: underlines, tooltips, compare view, connections panel,
// the wizard, and the workshop's seeded structures.
//
// Usage:  node scripts/capture-links-showcase.mjs [base-url]
//         default base: http://localhost:5173  (the vite dev server)
// Output: docs/screenshots/links/NN-*.png
//
// Requires: the Links Workshop + companions seeded on the server.
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.argv[2] || "http://localhost:5173";
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/screenshots/links");
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
  const item = page.locator(".ws-work-item", { hasText: title }).first();
  await item.click();
  await page.waitForSelector(".editor-content", { timeout: 8000 });
  await page.waitForTimeout(1500);
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.setDefaultTimeout(10000);

  console.log("── Link system showcase screenshots ──\n");

  // 1. Welcome page with the five-lessons button
  await page.goto(BASE);
  await page.waitForTimeout(1500);
  await shot(page, "welcome-course-button");

  // 2-6. The Links Workshop: each section showing live structures
  await openWork(page, "The Links Workshop");
  await page.waitForTimeout(2000);

  // Full page showing all sections
  await shot(page, "workshop-full-page", { fullPage: true });

  // Section 1: same-doc simple link
  await page.evaluate(() => {
    const el = document.querySelector(".editor-content");
    if (el) el.scrollTop = 0;
  });
  await page.waitForTimeout(500);
  await shot(page, "workshop-section1-simple-link");

  // Section 3: several independent links (different types)
  await page.evaluate(() => {
    const el = document.querySelector(".editor-container");
    if (el) el.scrollTop = el.scrollTop + 400;
  });
  await page.waitForTimeout(500);
  await shot(page, "workshop-section3-multiple-types");

  // Section 5: gathered end-set
  await page.evaluate(() => {
    const el = document.querySelector(".editor-container");
    if (el) el.scrollTop = el.scrollTop + 600;
  });
  await page.waitForTimeout(500);
  await shot(page, "workshop-section5-gathered-endset");

  // Connections panel with multiple link types
  const panel = page.locator(".ctx-section").first();
  if (await panel.isVisible()) {
    await shot(page, "connections-panel");
  }

  // 7. Companion B: the "receiving end" — backlinks + margin bars
  await openWork(page, "Workshop Companion B");
  await page.waitForTimeout(1500);
  await shot(page, "companion-backlinks-margin-bars");

  // 8. The compare view (transpointing windows)
  // Navigate back to workshop, find a multi-ended link, click compare
  await openWork(page, "The Links Workshop");
  await page.waitForTimeout(1500);
  const compareBtn = page.locator("button", { hasText: "⇄" }).first();
  try {
    await compareBtn.click();
    await page.waitForTimeout(2000);
    await shot(page, "compare-view-transpointing");
    // Close compare
    const closeBtn = page.locator("button", { hasText: "×" }).first();
    if (await closeBtn.isVisible()) await closeBtn.click();
    await page.waitForTimeout(500);
  } catch (e) {
    console.log("  (compare button not found, skipping)");
  }

  // 9. Link wizard with coaching copy
  // Select text, click Link, screenshot the wizard
  await page.evaluate(() => {
    const el = document.querySelector(".editor-content");
    if (!el) return;
    const range = document.createRange();
    const textNode = el.firstChild;
    if (textNode) {
      range.setStart(textNode, 0);
      range.setEnd(textNode, 30);
      const sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    }
  });
  await page.waitForTimeout(300);
  const linkBtn = page.locator("button", { hasText: "Link" }).first();
  try {
    await linkBtn.click();
    await page.waitForTimeout(800);
    await shot(page, "link-wizard-target-step");
    // Pick "entire document"
    const entireDoc = page.locator("button", { hasText: "entire document" }).first();
    if (await entireDoc.isVisible()) {
      await entireDoc.click();
      await page.waitForTimeout(500);
      await shot(page, "link-wizard-document-picker");
    }
    // Close wizard
    const closeWizard = page.locator(".link-creator-close").first();
    if (await closeWizard.isVisible()) await closeWizard.click();
  } catch (e) {
    console.log("  (wizard capture skipped:", e.message.substring(0, 50), ")");
  }

  // 10. Settings with permanent address
  const gearBtn = page.locator("[title*='Settings']").first();
  try {
    if (await gearBtn.isVisible()) {
      await gearBtn.click();
      await page.waitForTimeout(500);
      await shot(page, "settings-permanent-address");
      const closeSettings = page.locator(".settings-close").first();
      if (await closeSettings.isVisible()) await closeSettings.click();
    }
  } catch (e) {
    console.log("  (settings capture skipped)");
  }

  await browser.close();
  console.log(`\n${results.length} screenshots saved to ${OUT}`);
}

main().catch(e => { console.error(e); process.exit(1); });
