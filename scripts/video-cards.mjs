// video-cards.mjs — renders section title cards as PNGs (ffmpeg here
// lacks drawtext; Playwright gives better typography for free).
// Usage: node scripts/video-cards.mjs
import { chromium } from "../web/app/node_modules/playwright/index.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, "../docs/videos");
fs.mkdirSync(OUT, { recursive: true });

const CARDS = [
  ["c1", "A quotation, live"],
  ["c2", "Xudanu — a document"],
  ["c3", "Connect anything"],
  ["c4", "Typed connections"],
  ["c5", "Links go both ways"],
  ["c6", "Many-ended connections"],
  ["c7", "Authorship travels with content"],
  ["c8", "Live, together"],
  ["c9", "The docuverse"],
  ["c10", "Welcome"],
  ["close", "Xudanu — machinery from Udanax Gold (Xanadu 92.1), open-sourced 1999", true],
];

const html = (text, isClose) => `<!doctype html><html><body style="margin:0">
<div style="width:1440px;height:900px;background:#0d1117;display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:-apple-system,Helvetica,sans-serif">
  <div style="color:${isClose ? "#d29922" : "#e6edf3"};font-size:${isClose ? 40 : 52}px;font-weight:${isClose ? 500 : 600};text-align:center;max-width:1100px;line-height:1.3">${text}</div>
  ${isClose ? '<div style="color:#8b949e;font-size:26px;margin-top:28px">independent · open source · apache 2.0</div>' : '<div style="width:64px;height:3px;background:#d29922;margin-top:32px;border-radius:2px"></div>'}
</div></body></html>`;

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
for (const [name, text, isClose] of CARDS) {
  await page.setContent(html(text, !!isClose));
  await page.screenshot({ path: path.join(OUT, `.${name}.png`) });
  console.log(`✓ card ${name}`);
}
await browser.close();
