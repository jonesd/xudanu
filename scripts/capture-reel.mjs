#!/usr/bin/env node
// capture-reel.mjs — the 90-second xudanu tour reel.
//
// Scenes (each recorded as its own webm, assembled by ffmpeg after):
//   S1 lobby        the wired floor plan
//   S2 spectrum     one sentence, six link types, hover tooltips
//   S3 live window  transclusion bars, hover shows the source
//   S4 two drafts   compare view, beams follow scroll
//   S5 five-way     one connection, five ends
//   S6 welcome      end card (title added in post)
//
// Usage: node scripts/capture-reel.mjs [base-url]
//   default: http://localhost:5173 (vite dev; gallery must be seeded)
// Output: docs/videos/reel/S?-*.webm
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.argv[2] || "http://localhost:5173";
const ONLY = process.argv[3] || null; // e.g. "S1" — re-record one scene
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/videos/reel");
if (!ONLY) fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });
const W = 1440, H = 900;

const results = [];

async function scene(browser, name, fn) {
  if (ONLY && !name.startsWith(ONLY)) return;
  const ctx = await browser.newContext({
    recordVideo: { dir: OUT, size: { width: W, height: H } },
    viewport: { width: W, height: H },
    deviceScaleFactor: 1,
  });
  const page = await ctx.newPage();
  try {
    await fn(page);
    await page.waitForTimeout(600);
  } catch (e) {
    console.log(`  ! ${name}: ${String(e.message).slice(0, 70)}`);
  }
  await ctx.close();
  try {
    const src = await page.video().path();
    const dst = path.join(OUT, `${name}.webm`);
    fs.copyFileSync(src, dst);
    results.push(name);
    console.log(`  ✓ ${name} (${(fs.statSync(dst).size / 1024).toFixed(0)}KB)`);
  } catch (e) {
    console.log(`  ✗ ${name} video: ${e.message.slice(0, 50)}`);
  }
}

async function openWork(page, title, search = null) {
  let lastErr;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      await page.goto(BASE);
      await page.waitForTimeout(1800);
      const lib = page.locator("button", { hasText: /library/i }).first();
      try { await lib.click({ timeout: 2000 }); await page.waitForTimeout(700); } catch {}
      await page.waitForSelector(".ws-work-item", { timeout: 10000 });
      const searchBox = page.locator("input[placeholder*='Search'], input[type='search']").first();
      try {
        if (await searchBox.isVisible()) {
          await searchBox.fill(search ?? title.slice(0, 20));
          await page.waitForTimeout(600);
        }
      } catch {}
      await page.locator(".ws-work-item", { hasText: title.slice(0, 24) }).first().click({ timeout: 6000 });
      await page.waitForTimeout(2000);
      return;
    } catch (e) {
      lastErr = e;
    }
  }
  throw lastErr;
}

// Hover the underline band just below a phrase.
async function hoverPhrase(page, phrase, { sweep = 0, hold = 1800 } = {}) {
  const rect = await page.evaluate((p) => {
    const ed = document.querySelector(".editor-content");
    if (!ed) return null;
    const walker = document.createTreeWalker(ed, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      const i = (node.textContent || "").indexOf(p);
      if (i >= 0) {
        const r = document.createRange();
        r.setStart(node, i);
        r.setEnd(node, Math.min(i + p.length, node.textContent.length));
        const b = r.getBoundingClientRect();
        return { x: b.x + b.width / 2, y: b.bottom - 3, w: b.width };
      }
    }
    return null;
  }, phrase);
  if (!rect) { console.log(`    (phrase not found: ${phrase.slice(0, 30)})`); return; }
  await page.mouse.move(rect.x, rect.y);
  await page.waitForTimeout(hold);
  if (sweep > 0) {
    const steps = 12;
    for (let s = 1; s <= steps; s++) {
      await page.mouse.move(rect.x - rect.w / 2 + (rect.w * s) / steps, rect.y);
      await page.waitForTimeout(120);
    }
    await page.waitForTimeout(hold);
  }
}

async function openCompare(page, title) {
  await openWork(page, title);
  const tab = page.locator("button", { hasText: "Links" }).first();
  try { await tab.click({ timeout: 3000 }); await page.waitForTimeout(900); } catch {}
  const btn = page.locator("button[title*='compare' i], button[title*='⇄']").first();
  try { await btn.click({ timeout: 4000 }); await page.waitForTimeout(1800); } catch {
    console.log("    (compare button not found)");
  }
}

const browser = await chromium.launch();

// S1 — lobby
await scene(browser, "S1-lobby", async (page) => {
  await openWork(page, "Gallery — Lobby", "Lobby");
  await page.waitForTimeout(1200);
  await hoverPhrase(page, "Room 1", { hold: 1500 });
  await hoverPhrase(page, "Room 7", { hold: 1500 });
  await hoverPhrase(page, "Curator", { hold: 1500 });
});

// S2 — spectrum sentence
await scene(browser, "S2-spectrum", async (page) => {
  await openWork(page, "Room 1: The Spectrum Sentence");
  await hoverPhrase(page, "the light that never goes out", { sweep: 260, hold: 1600 });
});

// S3 — live window
await scene(browser, "S3-livewindow", async (page) => {
  await openWork(page, "Room 9: The Live Window");
  await hoverPhrase(page, "they are windows", { hold: 2000 });
  await hoverPhrase(page, "the window will have moved", { hold: 2200 });
});

// S4 — two drafts compare + scroll
await scene(browser, "S4-twodrafts", async (page) => {
  await openCompare(page, "Room 10: The Two Drafts");
  await page.waitForTimeout(1200);
  // slow scroll inside the compare pane — beams track
  for (let i = 0; i < 8; i++) {
    await page.mouse.wheel(0, 90);
    await page.waitForTimeout(260);
  }
  await page.waitForTimeout(800);
});

// S5 — five-way junction
await scene(browser, "S5-fiveway", async (page) => {
  await openCompare(page, "Room 7: The Five-Way Junction");
  await page.waitForTimeout(1500);
  for (let i = 0; i < 5; i++) {
    await page.mouse.wheel(0, 60);
    await page.waitForTimeout(300);
  }
  await page.waitForTimeout(1000);
});

// S6 — welcome end card
await scene(browser, "S6-welcome", async (page) => {
  await page.goto(BASE);
  await page.waitForTimeout(2600);
});

await browser.close();
console.log(`\nDONE — ${results.length} scenes in ${OUT}`);
