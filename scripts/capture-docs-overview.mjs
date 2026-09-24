#!/usr/bin/env node
// capture-docs-overview.mjs — screenshot the "Xudanu at a Glance"
// architecture map from the docs site for embedding in the README.
//
// Usage:  node scripts/capture-docs-overview.mjs [url]
//   default: https://dgjones.info/xudanu/
// Output: docs/screenshots/docs-overview.png (2x for crispness)
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const URL_ = process.argv[2] || "https://dgjones.info/xudanu/";
const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/screenshots/docs-overview.png");

const browser = await chromium.launch();
const page = await browser.newPage({
  viewport: { width: 1180, height: 900 },
  deviceScaleFactor: 2,
});
await page.goto(URL_, { waitUntil: "networkidle" });
await page.waitForTimeout(500);

// The glance map: the dark bordered card wrapping the SVG that contains g.coremap.
const card = page.locator("div:has(> svg:has(g.coremap))").first();
await card.scrollIntoViewIfNeeded();
await card.screenshot({ path: OUT });
const { width, height } = await card.boundingBox();
console.log(`✓ ${OUT} (${width}x${height} logical, 2x)`);
await browser.close();
