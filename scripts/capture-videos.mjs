#!/usr/bin/env node
// capture-videos.mjs — automated video capture of Xudanu's key features
// using Playwright. Each video is a focused 30-90 second demonstration.
//
// Usage: node scripts/capture-videos.mjs [base-url]
//        default base: http://localhost:5173
// Output: docs/videos/V*.webm (convert to mp4 for YouTube)
//
// Videos are recorded at 1440x900. Add voiceover in post for narration.
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.argv[2] || "http://localhost:5173";
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/videos");
fs.mkdirSync(OUT, { recursive: true });

const WIDTH = 1440;
const HEIGHT = 900;

async function openWork(page, title) {
  await page.goto(BASE);
  await page.waitForTimeout(1500);
  const libBtn = page.locator("button", { hasText: "Library" }).first();
  try { await libBtn.click(); await page.waitForTimeout(800); } catch {}
  await page.waitForSelector(".ws-work-item", { timeout: 8000 });
  const item = page.locator(".ws-work-item", { hasText: title }).first();
  await item.click();
  await page.waitForSelector(".editor-content", { timeout: 8000 });
  await page.waitForTimeout(2000); // let markers render
}

async function hoverUnderline(page) {
  // Hover over the first underlined text to trigger the tooltip
  const editor = page.locator(".editor-content");
  const box = await editor.boundingBox();
  if (!box) return;
  await page.mouse.move(box.x + box.width * 0.4, box.y + 150);
  await page.waitForTimeout(1500);
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  console.log("── Xudanu video capture ──\n");

  // ─── V1: Your First Link ───
  {
    const ctx = await browser.newContext({
      recordVideo: { dir: OUT, size: { width: WIDTH, height: HEIGHT } },
      viewport: { width: WIDTH, height: HEIGHT },
    });
    const page = await ctx.newPage();

    // Open the workshop — it has seeded links with underlines
    await openWork(page, "The Links Workshop");
    await page.waitForTimeout(1000);

    // Hover the first underlined sentence — tooltip appears
    await hoverUnderline(page);
    await page.waitForTimeout(2000);

    // Navigate to a companion (click a link marker)
    // (simulated — clicking coordinates in the editor area)
    const editor = page.locator(".editor-content");
    const box = await editor.boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width * 0.4, box.y + 150);
      await page.waitForTimeout(2000);
    }

    await ctx.close();
    const video = page.video();
    if (video) {
      const file = await video.path();
      fs.renameSync(file, path.join(OUT, "V1-first-link.webm"));
      console.log("  ✓ V1-first-link.webm");
    }
  }

  // ─── V2: Who Wrote What (provenance) ───
  {
    const ctx = await browser.newContext({
      recordVideo: { dir: OUT, size: { width: WIDTH, height: HEIGHT } },
      viewport: { width: WIDTH, height: HEIGHT },
    });
    const page = await ctx.newPage();

    await openWork(page, "The Links Workshop");

    // Look for provenance underlines (colored author attribution)
    // These should be visible on the admin-authored content
    await page.waitForTimeout(2000);
    await hoverUnderline(page);
    await page.waitForTimeout(1500);

    // Try to find and click the History tab (if visible)
    const historyBtn = page.locator("button, a", { hasText: /history/i }).first();
    try {
      if (await historyBtn.isVisible()) {
        await historyBtn.click();
        await page.waitForTimeout(2000);
      }
    } catch {}

    await ctx.close();
    const video = page.video();
    if (video) {
      const file = await video.path();
      fs.renameSync(file, path.join(OUT, "V2-provenance.webm"));
      console.log("  ✓ V2-provenance.webm");
    }
  }

  // ─── V3: One Claim, Three Places (multi-ended + compare) ───
  {
    const ctx = await browser.newContext({
      recordVideo: { dir: OUT, size: { width: WIDTH, height: HEIGHT } },
      viewport: { width: WIDTH, height: HEIGHT },
    });
    const page = await ctx.newPage();

    await openWork(page, "The Links Workshop");
    await page.waitForTimeout(2000);

    // Scroll to the multi-ended section
    await page.evaluate(() => {
      const el = document.querySelector(".editor-container");
      if (el) el.scrollTop = 600;
    });
    await page.waitForTimeout(1000);

    // Look for the compare button on multi-ended rows
    const compareBtn = page.locator("button", { hasText: "⇄" }).first();
    try {
      if (await compareBtn.isVisible()) {
        await compareBtn.click();
        await page.waitForTimeout(3000); // let the compare view render
      }
    } catch {}

    await ctx.close();
    const video = page.video();
    if (video) {
      const file = await video.path();
      fs.renameSync(file, path.join(OUT, "V3-multi-ended.webm"));
      console.log("  ✓ V3-multi-ended.webm");
    }
  }

  // ─── V4: Welcome / Onboarding ───
  {
    const ctx = await browser.newContext({
      recordVideo: { dir: OUT, size: { width: WIDTH, height: HEIGHT } },
      viewport: { width: WIDTH, height: HEIGHT },
    });
    const page = await ctx.newPage();

    // Clear localStorage to show the first-visit experience
    await page.goto(BASE);
    await page.evaluate(() => localStorage.clear());
    await page.reload();
    await page.waitForTimeout(3000);

    // The auto-open should navigate to Lesson 1
    // Or the welcome page should show "Learn in five lessons"
    await page.waitForTimeout(2000);

    await ctx.close();
    const video = page.video();
    if (video) {
      const file = await page.video().path();
      fs.renameSync(file, path.join(OUT, "V4-onboarding.webm"));
      console.log("  ✓ V4-onboarding.webm");
    }
  }

  // ─── V5: The Docuverse Map ───
  {
    const ctx = await browser.newContext({
      recordVideo: { dir: OUT, size: { width: WIDTH, height: HEIGHT } },
      viewport: { width: WIDTH, height: HEIGHT },
    });
    const page = await ctx.newPage();

    await page.goto(BASE);
    await page.waitForTimeout(2000);

    // Try to open the graph/docuverse view
    const graphBtn = page.locator("button", { hasText: /graph|docuverse|map/i }).first();
    try {
      if (await graphBtn.isVisible()) {
        await graphBtn.click();
        await page.waitForTimeout(3000);
      }
    } catch {}

    await ctx.close();
    const video = page.video();
    if (video) {
      const file = await video.path();
      fs.renameSync(file, path.join(OUT, "V5-docuverse.webm"));
      console.log("  ✓ V5-docuverse.webm");
    }
  }

  // ─── V6: The Link Wizard ───
  {
    const ctx = await browser.newContext({
      recordVideo: { dir: OUT, size: { width: WIDTH, height: HEIGHT } },
      viewport: { width: WIDTH, height: HEIGHT },
    });
    const page = await ctx.newPage();

    await openWork(page, "The Links Workshop");

    // Select text to trigger the Link flow
    await page.evaluate(() => {
      const el = document.querySelector(".editor-content");
      if (!el) return;
      const range = document.createRange();
      const textNode = el.firstChild;
      if (textNode) {
        range.setStart(textNode, 0);
        range.setEnd(textNode, 40);
        const sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
      }
    });
    await page.waitForTimeout(500);

    // Click the Link button (toolbar)
    const linkBtn = page.locator("button", { hasText: "Link" }).first();
    try {
      await linkBtn.click();
      await page.waitForTimeout(1500);
      // The wizard with the coaching text should be visible
      await page.waitForTimeout(2000);
    } catch {}

    await ctx.close();
    const video = page.video();
    if (video) {
      const file = await video.path();
      fs.renameSync(file, path.join(OUT, "V6-link-wizard.webm"));
      console.log("  ✓ V6-link-wizard.webm");
    }
  }

  await browser.close();
  console.log(`\nVideos saved to ${OUT}`);
  console.log("Convert to mp4: ffmpeg -i input.webm -c:v libx264 -pix_fmt yuv420p output.mp4");
}

main().catch(e => { console.error(e); process.exit(1); });
