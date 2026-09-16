#!/usr/bin/node
// capture-connection-showcase.mjs — screenshot sequence of the
// Connection Atlas: the rendering ladder from one lane to the
// crowded passage, with hover ledger and pill interaction states.
// Output: docs/screenshots/showcase/01-09.
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";

const BASE = "http://localhost:5173";
const OUT = "docs/screenshots/showcase";
fs.mkdirSync(OUT, { recursive: true });

async function openWork(page, title) {
  await page.goto(BASE);
  await page.waitForTimeout(2000);
  const lib = page.locator("button", { hasText: "Library" }).first();
  try { await lib.click(); await page.waitForTimeout(1000); } catch {}
  await page.waitForSelector(".ws-work-item", { timeout: 10000 });
  await page.locator(".ws-work-item", { hasText: title }).first().click();
  await page.waitForSelector(".editor-content", { timeout: 10000 });
  await page.waitForTimeout(3000);
}

async function scrollTo(page, needle) {
  await page.evaluate((frag) => {
    const root = document.querySelector(".editor-content");
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    let n;
    while ((n = walker.nextNode())) {
      const i = n.textContent.indexOf(frag);
      if (i >= 0 && n.parentElement) {
        const r = document.createRange();
        r.setStart(n, i);
        r.setEnd(n, Math.min(n.textContent.length, i + frag.length + 20));
        const b = r.getBoundingClientRect();
        (document.querySelector(".editor-container") || root).scrollBy({ top: b.y - 350, behavior: "instant" });
        break;
      }
    }
  }, needle);
  await page.waitForTimeout(700);
}

async function rectOf(page, needle, tail = 0) {
  return page.evaluate(({ frag, tail }) => {
    const root = document.querySelector(".editor-content");
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    let n;
    while ((n = walker.nextNode())) {
      const i = n.textContent.indexOf(frag);
      if (i >= 0 && n.parentElement) {
        const r = document.createRange();
        r.setStart(n, i);
        r.setEnd(n, Math.min(n.textContent.length, i + frag.length + tail));
        const b = r.getBoundingClientRect();
        return { x: b.x, y: b.y, cx: b.x + b.width / 2, cy: b.y + b.height / 2, right: b.right, w: b.width, h: b.height };
      }
    }
    return null;
  }, { frag: needle, tail });
}

const shot = (page, name, clip) => page.screenshot({ path: `${OUT}/${name}.png`, ...(clip ? { clip } : {}) }).then(() => console.log("saved", name));

async function main() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2 });
  await openWork(page, "The Connection Atlas");

  // 01 — the whole atlas
  await page.evaluate(() => (document.querySelector(".editor-container") || document.querySelector(".editor-content")).scrollTop = 0);
  await page.waitForTimeout(600);
  await shot(page, "01-atlas-overview");

  // 02 — one comment: single ribbon + hover
  await scrollTo(page, "This sentence carries a single connection");
  let r = await rectOf(page, "This sentence carries a single connection");
  await page.mouse.move(r.cx, r.cy, { steps: 4 });
  await page.waitForTimeout(900);
  await shot(page, "02-one-comment-hover", { x: 300, y: Math.max(0, r.y - 140), width: 900, height: 380 });

  // 03 — two kinds: dispute first, comment below
  await scrollTo(page, "This sentence draws a dispute and a remark");
  r = await rectOf(page, "This sentence draws a dispute and a remark");
  await page.mouse.move(r.cx - 100, r.cy, { steps: 4 });
  await page.waitForTimeout(500);
  await page.mouse.move(r.cx, r.cy, { steps: 4 });
  await page.waitForTimeout(900);
  await shot(page, "03-two-kinds-hover", { x: 300, y: Math.max(0, r.y - 140), width: 900, height: 420 });

  // 04 — four kinds
  await scrollTo(page, "This sentence gathers a dispute, a comment, a reference");
  r = await rectOf(page, "This sentence gathers a dispute, a comment, a reference");
  await page.mouse.move(r.cx, r.cy, { steps: 4 });
  await page.waitForTimeout(900);
  await shot(page, "04-four-kinds-hover", { x: 300, y: Math.max(0, r.y - 160), width: 900, height: 460 });

  // 05 — gathered end: one ribbon, three segments
  await scrollTo(page, "This sentence is supported by three passages");
  r = await rectOf(page, "This sentence is supported by three passages");
  await page.mouse.move(r.cx, r.cy, { steps: 4 });
  await page.waitForTimeout(900);
  await shot(page, "05-gathered-evidence-hover", { x: 300, y: Math.max(0, r.y - 160), width: 900, height: 460 });

  // 06 — the crowded passage: composition pill at rest
  await scrollTo(page, "This sentence is where the whole debate lands");
  r = await rectOf(page, "This sentence is where the whole debate lands");
  await page.mouse.move(900, 200, { steps: 2 });
  await page.waitForTimeout(600);
  await shot(page, "06-composition-pill", { x: 260, y: Math.max(0, r.y - 120), width: 980, height: 340 });

  // 07 — hover the pill: the grouped ledger
  const overlay = await page.evaluate(() => document.querySelector("canvas")?.parentElement?.getBoundingClientRect());
  await page.mouse.move(overlay.x + 30, r.cy, { steps: 5 });
  await page.waitForTimeout(1000);
  await shot(page, "07-grouped-ledger", { x: 200, y: Math.max(0, r.y - 200), width: 1080, height: 640 });

  // 08 — click the pill: ribbons expand
  await page.mouse.click(overlay.x + 30, r.cy);
  await page.waitForTimeout(1000);
  await page.mouse.move(900, 150, { steps: 2 });
  await page.waitForTimeout(500);
  await shot(page, "08-pill-expanded", { x: 260, y: Math.max(0, r.y - 140), width: 980, height: 420 });

  await browser.close();
  console.log(`\nSequence saved to ${OUT}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
