// screenshot-capture.mjs — headless screenshots of the running demo
// stack (Vite :5171 + Node 1 :8081 via demo-network, or dev :5173).
// Usage: node scripts/screenshot-capture.mjs [outDir]
import { createRequire } from 'node:module';
const require = createRequire('/Users/jonesd/code/xu-gold-2026/web/app/');
const { chromium } = require('playwright-core');
import { mkdirSync, writeFileSync, existsSync, readFileSync } from 'node:fs';
import { execSync } from 'node:child_process';

const outDir = process.argv[2] || '/Users/jonesd/code/xu-gold-2026/docs/screenshots-new';
const BASE = 'http://localhost:5173';

const REPO = '/Users/jonesd/code/xu-gold-2026';

// Browser binary discovery from playwright-core's registry
const browsers = JSON.parse(readFileSync(`${REPO}/web/app/node_modules/playwright-core/browsers.json`, 'utf8'));
const chromiumRev = browsers.browsers.find(b => b.name === 'chromium').revision;
const candidates = [
  `${process.env.HOME}/Library/Caches/ms-playwright/chromium-${chromiumRev}/chrome-mac/Chromium.app/Contents/MacOS/Chromium`,
  `${process.env.HOME}/Library/Caches/ms-playwright/chromium_headless_shell-${chromiumRev}/chrome-mac/headless_shell`,
];
const executablePath = candidates.find(p => existsSync(p));
if (!executablePath) { console.error('no chromium binary found'); process.exit(1); }

mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch({ executablePath, headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2 });

async function shot(name, url, { action, wait = 1500 } = {}) {
  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });
    await page.waitForTimeout(wait);
    if (action) await action();
    await page.screenshot({ path: `${outDir}/${name}.png`, fullPage: false });
    console.log(`✓ ${name}`);
  } catch (e) {
    console.error(`✗ ${name}: ${e.message.split('\n')[0]}`);
  }
}

// 1. Landing/library
await shot('01-library', BASE);

// 2. Editor with content (open the seeded demo doc if present)
await shot('02-editor', BASE, {
  action: async () => {
    // Try clicking the first work in the library list
    const first = page.locator('text=Compare: Paper One').first();
    if (await first.isVisible({ timeout: 3000 }).catch(() => false)) await first.click();
    await page.waitForTimeout(2000);
  }
});

// 3. Connections panel (links tab)
await shot('03-connections', BASE, {
  action: async () => {
    const linksTab = page.locator('button:has-text("Links")').first();
    if (await linksTab.isVisible({ timeout: 3000 }).catch(() => false)) await linksTab.click();
    await page.waitForTimeout(1000);
  }
});

// 4. Compare view (if we can reach it)
await shot('04-compare', BASE, {
  action: async () => {
    const compareTab = page.locator('button:has-text("Compare")').first();
    if (await compareTab.isVisible({ timeout: 3000 }).catch(() => false)) await compareTab.click();
    await page.waitForTimeout(3000);
  }
});

// 5. Attribution panel
await shot('05-attribution', BASE, {
  action: async () => {
    const attrTab = page.locator('button:has-text("Attribution"), button:has-text("Provenance")').first();
    if (await attrTab.isVisible({ timeout: 3000 }).catch(() => false)) await attrTab.click();
    await page.waitForTimeout(1000);
  }
});

// 6. Search overlay
await shot('06-search', BASE, {
  action: async () => {
    // Trigger search: keyboard shortcut or magnifier icon
    await page.keyboard.press('Meta+k').catch(() => {});
    const searchIcon = page.locator('[aria-label*="search" i], .search-icon, button:has-text("Search")').first();
    if (await searchIcon.isVisible({ timeout: 2000 }).catch(() => false)) await searchIcon.click();
    await page.keyboard.type('transclusion');
    await page.waitForTimeout(1500);
  }
});

await browser.close();
console.log(`\nSaved to ${outDir}`);
