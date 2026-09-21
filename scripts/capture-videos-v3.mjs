#!/usr/bin/node
// capture-videos-v3.mjs — production-quality video capture
// Shows: typing, link creation, collaborative editing, backlinks, compare
//
// Usage: node scripts/capture-videos-v3.mjs [base-url]
// Output: docs/videos/V3-*.webm
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.argv[2] || "http://localhost:5173";
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/videos");
fs.mkdirSync(OUT, { recursive: true });
const W = 1440, H = 900;
const results = [];

async function videoCtx(browser, name) {
  const ctx = await browser.newContext({
    recordVideo: { dir: OUT, size: { width: W, height: H } },
    viewport: { width: W, height: H },
  });
  return { ctx, name };
}

async function finish(ctx, page, name) {
  await ctx.close();
  try {
    const video = page.video();
    if (video) {
      const src = await video.path();
      const dst = path.join(OUT, name);
      if (fs.existsSync(src)) {
        fs.copyFileSync(src, dst);
        const size = fs.statSync(dst).size;
        results.push({ name, size });
        console.log(`  ✓ ${name} (${(size/1024).toFixed(0)}KB)`);
      }
    }
  } catch (e) { console.log(`  ✗ ${name}: ${e.message.substring(0,50)}`); }
}

async function waitStable(page, ms = 2000) {
  await page.waitForTimeout(ms);
}

// Open a work by title with retry
async function openWork(page, title, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      await page.goto(BASE);
      await waitStable(page, 1500);
      const lib = page.locator("button", { hasText: /library/i }).first();
      try { await lib.click({timeout: 2000}); await waitStable(page, 800); } catch {}
      const item = page.locator(".ws-work-item", { hasText: title }).first();
      await item.click({ timeout: 5000 });
      await page.waitForSelector(".editor-content", { timeout: 8000 });
      await waitStable(page, 2000);
      return true;
    } catch (e) {
      console.log(`  retry ${i+1}: ${e.message.substring(0, 40)}`);
    }
  }
  return false;
}

// Select text by clicking and dragging across a line
async function selectLine(page, y = 120) {
  const editor = page.locator(".editor-content").first();
  const box = await editor.boundingBox();
  if (!box) return;
  await page.mouse.move(box.x + 80, box.y + y);
  await page.mouse.down();
  await page.mouse.move(box.x + 600, box.y + y, { steps: 20 });
  await page.mouse.up();
  await waitStable(page, 500);
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  console.log("── Xudanu video capture v3 ──\n");

  // ═══ V3-1: Typing content into a document ═══
  {
    const { ctx } = await videoCtx(browser, "V3-1");
    const page = await ctx.newPage();
    try {
      // Open Multi Test (has existing content, is editable)
      if (await openWork(page, "Multi Test")) {
        // Click at the end of existing text
        const editor = page.locator(".editor-content").first();
        await editor.click();
        await page.keyboard.press("Meta+End"); // Cmd+End
        await page.keyboard.press("End");
        await page.keyboard.press("Enter");
        await page.keyboard.press("Enter");
        await waitStable(page, 500);

        // Type new content — viewer sees it appearing
        const lines = [
          "The ferry schedule survived three administrations.",
          "Anyone who says a map is the territory has never maintained either.",
          "Maintenance is what you do so failure has to make an appointment.",
        ];
        for (const line of lines) {
          for (const ch of line) {
            await page.keyboard.type(ch, { delay: 50 });
          }
          await page.keyboard.press("Enter");
          await page.keyboard.press("Enter");
          await waitStable(page, 400);
        }
        await waitStable(page, 2000);
      }
    } catch (e) { console.log("  V3-1 error:", e.message.substring(0, 60)); }
    await finish(ctx, page, "V3-1-typing.webm");
  }

  // ═══ V3-2: Creating a link (full wizard) ═══
  {
    const { ctx } = await videoCtx(browser, "V3-2");
    const page = await ctx.newPage();
    try {
      if (await openWork(page, "Multi Test")) {
        // Select text
        await selectLine(page, 100);
        await waitStable(page, 500);

        // Click the Link button in the toolbar
        const linkBtn = page.locator("button", { hasText: /^Link$/ }).first();
        if (await linkBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
          await linkBtn.click();
          await waitStable(page, 1500);

          // Step 1: click "entire document"
          const entireDoc = page.locator("button, div", { hasText: /entire document/i }).first();
          if (await entireDoc.isVisible({ timeout: 3000 }).catch(() => false)) {
            await entireDoc.click();
            await waitStable(page, 1000);

            // Step 2: pick Link Target from the document list
            const target = page.locator(".link-work-item", { hasText: /link target/i }).first();
            if (await target.isVisible({ timeout: 3000 }).catch(() => false)) {
              await target.click();
              await waitStable(page, 1000);

              // Step 3: pick a type (See Also)
              const typeCard = page.locator(".link-type-card, button", { hasText: /see also/i }).first();
              if (await typeCard.isVisible({ timeout: 3000 }).catch(() => false)) {
                await typeCard.click();
                await waitStable(page, 800);

                // Step 4: scroll down and click Create
                const createBtn = page.locator("button", { hasText: /create link/i }).first();
                if (await createBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
                  await createBtn.click();
                  await waitStable(page, 4000); // let the underline appear
                }
              }
            }
          }
        }
      }
    } catch (e) { console.log("  V3-2 error:", e.message.substring(0, 60)); }
    await finish(ctx, page, "V3-2-link-wizard.webm");
  }

  // ═══ V3-3: Hover a link + tooltip + navigate ═══
  {
    const { ctx } = await videoCtx(browser, "V3-3");
    const page = await ctx.newPage();
    try {
      if (await openWork(page, "Multi Test")) {
        // Hover over the first underlined text
        const editor = page.locator(".editor-content").first();
        const box = await editor.boundingBox();
        if (box) {
          // Move slowly to the underline area
          await page.mouse.move(box.x + 200, box.y + 100, { steps: 10 });
          await waitStable(page, 1000);
          // Hold for the tooltip
          await page.mouse.move(box.x + 300, box.y + 130, { steps: 5 });
          await waitStable(page, 2000);

          // Click to navigate
          await page.mouse.click(box.x + 300, box.y + 130);
          await waitStable(page, 3000);

          // We should now be on the target document
          // Look for the backlink in the panel
          await waitStable(page, 2000);
        }
      }
    } catch (e) { console.log("  V3-3 error:", e.message.substring(0, 60)); }
    await finish(ctx, page, "V3-3-hover-navigate.webm");
  }

  // ═══ V3-4: Collaborative editing (two windows) ═══
  {
    const ctxA = await browser.newContext({
      recordVideo: { dir: OUT, size: { width: W, height: H } },
      viewport: { width: W, height: H },
    });
    const ctxB = await browser.newContext({
      recordVideo: { dir: OUT, size: { width: W, height: H } },
      viewport: { width: W, height: H },
    });
    const pageA = await ctxA.newPage();
    const pageB = await ctxB.newPage();

    try {
      // Both open the same document
      const workUrl = `${BASE}/?work=0x44d`;
      await pageA.goto(workUrl);
      await pageB.goto(workUrl);
      await waitStable(pageA, 2500);
      await waitStable(pageB, 2500);

      // Type in A — B should see it
      const edA = pageA.locator(".editor-content").first();
      if (await edA.isVisible({ timeout: 5000 }).catch(() => false)) {
        await edA.click();
        await pageA.keyboard.press("End");
        await pageA.keyboard.press("Enter");
        await pageA.waitForTimeout(200);

        const text1 = "Typed from window A — live sync demo.";
        for (const ch of text1) {
          await pageA.keyboard.type(ch, { delay: 50 });
        }
        await waitStable(pageA, 2000);

        // Type in B — A should see it
        const edB = pageB.locator(".editor-content").first();
        if (await edB.isVisible({ timeout: 3000 }).catch(() => false)) {
          await edB.click();
          await pageB.keyboard.press("End");
          await pageB.keyboard.press("Enter");
          await pageB.waitForTimeout(200);

          const text2 = "And this from window B.";
          for (const ch of text2) {
            await pageB.keyboard.type(ch, { delay: 50 });
          }
          await waitStable(pageB, 3000);
        }
      }
    } catch (e) { console.log("  V3-4 error:", e.message.substring(0, 60)); }

    await finish(ctxA, pageA, "V3-4-collab-A.webm");
    await finish(ctxB, pageB, "V3-4-collab-B.webm");
  }

  // ═══ V3-5: The Links Workshop tour ═══
  {
    const { ctx } = await videoCtx(browser, "V3-5");
    const page = await ctx.newPage();
    try {
      if (await openWork(page, "The Links Workshop")) {
        // Slow scroll through the document showing all the structures
        const editor = page.locator(".editor-container").first();
        if (await editor.isVisible()) {
          // Scroll slowly to show each section
          for (let scroll = 0; scroll < 2000; scroll += 200) {
            await page.evaluate((y) => {
              const el = document.querySelector(".editor-container");
              if (el) el.scrollTop = y;
            }, scroll);
            await waitStable(page, 800);
          }
        }
        await waitStable(page, 2000);
      }
    } catch (e) { console.log("  V3-5 error:", e.message.substring(0, 60)); }
    await finish(ctx, page, "V3-5-workshop-tour.webm");
  }

  await browser.close();
  console.log(`\n${results.length} videos saved to ${OUT}`);
}

main().catch(e => { console.error(e); process.exit(1); });
