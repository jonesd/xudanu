#!/usr/bin/env node
// render-reel-cards.mjs — title cards as PNGs (Chromium renders the
// HTML; ffmpeg loops them). Avoids ffmpeg drawtext (homebrew build
// lacks freetype) and gives better typography than drawtext anyway.
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/videos/reel/parts");
fs.mkdirSync(OUT, { recursive: true });

const cards = [
  ["intro", "XUDANU", "Nelson's Xanadu Gold, working"],
  ["c-lobby", "The Gallery of Unusual Connections", ""],
  ["c-spectrum", "One sentence, six kinds of connection", ""],
  ["c-window", "A window, not a copy", ""],
  ["c-drafts", "Shared passages, carried between drafts", ""],
  ["c-fiveway", "One connection, five ends", ""],
  ["outro", "xudanu.com", "Built on the Gold design"],
];

const html = (title, sub) => `<!doctype html><html><body style="margin:0">
<div style="width:1440px;height:900px;background:#161b22;display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif">
  <div style="color:#e6edf3;font-size:58px;font-weight:700;letter-spacing:0.5px">${title}</div>
  ${sub ? `<div style="color:#39d2c0;font-size:32px;margin-top:26px;font-weight:400">${sub}</div>` : ""}
</div></body></html>`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 });
for (const [name, title, sub] of cards) {
  await page.setContent(html(title, sub));
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
  console.log(`  ✓ ${name}.png`);
}
await browser.close();
