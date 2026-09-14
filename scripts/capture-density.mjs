import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";

const BASE = "http://localhost:5173";
const OUT = "docs/screenshots/density";
fs.mkdirSync(OUT, { recursive: true });
let counter = 0;

async function shot(page, name) {
  counter++;
  const file = `${String(counter).padStart(2, "0")}-${name}.png`;
  await page.screenshot({ path: path.join(OUT, file) });
  console.log("  ✓", file);
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.setDefaultTimeout(10000);

  console.log("── Density demo screenshots ──\n");

  // Open the density demo
  await page.goto(`${BASE}/?work=0x450`);
  await page.waitForTimeout(3000);

  // Full page
  await shot(page, "density-demo-full-page");

  // Scroll to each section
  const sections = [
    { y: 0, name: "one-link" },
    { y: 80, name: "two-links" },
    { y: 160, name: "four-links" },
    { y: 240, name: "eight-links-density-pill" },
  ];

  for (const s of sections) {
    await page.evaluate((y) => {
      const el = document.querySelector(".editor-container");
      if (el) el.scrollTop = y;
    }, s.y);
    await page.waitForTimeout(800);
    await shot(page, `density-${s.name}`);
  }

  // Expanded density pill (click the 8 pill)
  await page.evaluate(() => {
    const el = document.querySelector(".editor-container");
    if (el) el.scrollTop = 240;
  });
  await page.waitForTimeout(500);
  // Try clicking the pill
  const editor = page.locator(".editor-content");
  const box = await editor.boundingBox();
  if (box) {
    // Click in the center of the 8-link sentence area
    await page.mouse.click(box.x + box.width / 2, box.y + 280);
    await page.waitForTimeout(1500);
    await shot(page, "density-pill-expanded");
  }

  await browser.close();
  console.log(`\n${counter} screenshots saved to ${OUT}`);
}

main().catch(e => { console.error(e); process.exit(1); });
