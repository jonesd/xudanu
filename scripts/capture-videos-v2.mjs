#!/usr/bin/node
// capture-videos-v2.mjs — improved video capture showing CREATION
// (typing, link wizard, collaborative editing with live cursors)
//
// Usage: node scripts/capture-videos-v2.mjs [base-url]
// Output: docs/videos/V2-*.webm
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = process.argv[2] || "http://localhost:5173";
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/videos");
fs.mkdirSync(OUT, { recursive: true });

const W = 1440, H = 900;

async function newVideoCtx(browser) {
  const ctx = await browser.newContext({
    recordVideo: { dir: OUT, size: { width: W, height: H } },
    viewport: { width: W, height: H },
  });
  return ctx;
}

async function saveVideo(ctx, page, name) {
  await ctx.close();
  const video = page.video();
  if (video) {
    const src = await video.path();
    const dst = path.join(OUT, name);
    try { fs.renameSync(src, dst); console.log("  ✓", name); }
    catch { fs.copyFileSync(src, dst); fs.unlinkSync(src); console.log("  ✓", name); }
  }
}

async function typeSlowly(page, selector, text, delay = 80) {
  const el = page.locator(selector).first();
  await el.click();
  for (const char of text) {
    await page.keyboard.type(char, { delay });
  }
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  console.log("── Xudanu video capture v2 (creation-focused) ──\n");

  // ─── V2-1: Creating a document (typing visible) ───
  {
    const ctx = await newVideoCtx(browser);
    const page = await ctx.newPage();
    await page.goto(BASE);
    await page.waitForTimeout(2000);

    // Click "New Document" on the welcome page
    const newDocBtn = page.locator("button", { hasText: /new document/i }).first();
    if (await newDocBtn.isVisible()) {
      await newDocBtn.click();
      await page.waitForTimeout(1500);
    }

    // Type content — the viewer sees text appearing
    await typeSlowly(page, ".editor-content",
      "The quarterly report shows three trends.\n\n", 70);
    await page.waitForTimeout(500);
    await typeSlowly(page, ".editor-content",
      "First, customer retention improved by twelve percent.\n\n", 70);
    await page.waitForTimeout(500);
    await typeSlowly(page, ".editor-content",
      "Second, maintenance costs dropped across all corridors.\n\n", 70);
    await page.waitForTimeout(2000);

    await saveVideo(ctx, page, "V2-1-typing.webm");
  }

  // ─── V2-2: Creating a link (full wizard flow) ───
  {
    const ctx = await newVideoCtx(browser);
    const page = await ctx.newPage();

    // Open a document that already has text
    await page.goto(BASE);
    await page.waitForTimeout(2000);
    const libBtn = page.locator("button", { hasText: "Library" }).first();
    try { await libBtn.click(); await page.waitForTimeout(800); } catch {}
    const work = page.locator(".ws-work-item", { hasText: "Multi Test" }).first();
    try { await work.click(); await page.waitForTimeout(2000); } catch {}

    // Select text for the link source
    const editor = page.locator(".editor-content");
    const box = await editor.boundingBox();
    if (box) {
      // Click and drag to select (visible selection)
      await page.mouse.move(box.x + 100, box.y + 120);
      await page.mouse.down();
      await page.mouse.move(box.x + 500, box.y + 120, { steps: 15 });
      await page.mouse.up();
      await page.waitForTimeout(800);
    }

    // Click the Link button
    const linkBtn = page.locator("button", { hasText: /^Link$/ }).first();
    try {
      if (await linkBtn.isVisible()) {
        await linkBtn.click();
        await page.waitForTimeout(1500);

        // The wizard opens — click "entire document"
        const entireDoc = page.locator("button", { hasText: /entire document/i }).first();
        if (await entireDoc.isVisible()) {
          await entireDoc.click();
          await page.waitForTimeout(1000);

          // Pick a document from the list
          const docPicker = page.locator(".link-work-item").first();
          if (await docPicker.isVisible()) {
            await docPicker.click();
            await page.waitForTimeout(1000);

            // Pick a type (See Also)
            const seeAlso = page.locator(".link-type-card", { hasText: /see also/i }).first();
            if (await seeAlso.isVisible()) {
              await seeAlso.click();
              await page.waitForTimeout(800);

              // Scroll down and click Create
              const createBtn = page.locator("button", { hasText: /create link/i }).first();
              if (await createBtn.isVisible()) {
                await createBtn.click();
                await page.waitForTimeout(3000); // let the underline appear
              }
            }
          }
        }
      }
    } catch (e) {
      console.log("  (wizard flow:", e.message.substring(0, 60), ")");
    }

    await saveVideo(ctx, page, "V2-2-link-creation.webm");
  }

  // ─── V2-3: Collaborative editing (two live cursors) ───
  {
    // Two browser contexts showing the same document
    const ctxA = await newVideoCtx(browser);
    const ctxB = await newVideoCtx(browser);
    const pageA = await ctxA.newPage();
    const pageB = await ctxB.newPage();

    // Both open the same work
    const url = `${BASE}/?work=0x44d`; // Multi Test
    await pageA.goto(url);
    await pageB.goto(url);
    await pageA.waitForTimeout(2000);
    await pageB.waitForTimeout(2000);

    // Type in page A — should appear in page B
    const editorA = pageA.locator(".editor-content").first();
    if (await editorA.isVisible()) {
      await editorA.click();
      await pageA.keyboard.press("End");
      await pageA.keyboard.press("Enter");
      await pageA.waitForTimeout(300);

      // Type slowly — the viewer sees characters appearing
      const text = "Live collaborative editing — this text appears in both windows simultaneously.";
      for (const char of text) {
        await pageA.keyboard.type(char, { delay: 60 });
        await pageA.waitForTimeout(50);
      }
      await pageA.waitForTimeout(3000);

      // Type in page B too — showing bidirectional sync
      const editorB = pageB.locator(".editor-content").first();
      if (await editorB.isVisible()) {
        await editorB.click();
        await pageB.keyboard.press("End");
        await pageB.keyboard.press("Enter");
        await pageB.waitForTimeout(300);

        const text2 = "And this line was typed from the other window.";
        for (const char of text2) {
          await pageB.keyboard.type(char, { delay: 60 });
          await pageB.waitForTimeout(50);
        }
        await pageB.waitForTimeout(3000);
      }
    }

    // Save both videos
    await saveVideo(ctxA, pageA, "V2-3-collab-A.webm");
    await saveVideo(ctxB, pageB, "V2-3-collab-B.webm");
  }

  await browser.close();
  console.log(`\nVideos saved to ${OUT}`);
}

main().catch(e => { console.error(e); process.exit(1); });
