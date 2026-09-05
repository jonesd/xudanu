import { test, chromium } from "@playwright/test";

const DIR = "../../docs/screenshots/compound-demo";
const BASE = "http://localhost:5173";

test("landing + origin extra shots", async ({ browser }) => {
  // Fresh context — no session, sees the landing
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await ctx.newPage();
  await page.goto(`${BASE}/?clear=1`);
  await page.waitForTimeout(4000);
  const landing = page.locator(".ws-home-landing");
  if (await landing.isVisible({ timeout: 3000 }).catch(() => false)) {
    await page.screenshot({ path: `${DIR}/04-home-landing.png` });
    console.log("SHOT 4 done (landing)");
  } else {
    console.log("SHOT 4: landing still not visible");
  }

  // Now open the compound and try the origin panel
  await page.goto(`${BASE}/?work=0x3ee`);
  await page.waitForTimeout(3500);
  const skip = page.locator(".ws-home-skip");
  if (await skip.isVisible({ timeout: 2000 }).catch(() => false)) await skip.click();
  await page.waitForTimeout(2000);

  // Look for transclusion elements in the editor
  const marks = page.locator("mark, .transcluded, [class*='transclusion']");
  const markCount = await marks.count();
  console.log(`Found ${markCount} transclusion elements`);
  if (markCount > 0) {
    // Hover first to show the tooltip, then look for Origin button
    await marks.first().hover();
    await page.waitForTimeout(1000);
    await page.screenshot({ path: `${DIR}/02a-transclusion-hover.png` });
    console.log("SHOT 2a: transclusion hover");
    const originBtn = page.locator("button").filter({ hasText: /origin/i }).first();
    if (await originBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
      await originBtn.click();
      await page.waitForTimeout(2000);
      await page.screenshot({ path: `${DIR}/02b-origin-panel.png` });
      console.log("SHOT 2b: origin panel");
    }
  }
  await ctx.close();
});
