import { test } from "@playwright/test";
test("fresh landing via 5174", async ({ browser }) => {
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await ctx.newPage();
  await page.goto("http://localhost:5174/");
  await page.waitForTimeout(4500);
  const landing = page.locator(".ws-home-landing");
  const vis = await landing.isVisible({ timeout: 3000 }).catch(() => false);
  if (vis) {
    await page.screenshot({ path: "../../docs/screenshots/compound-demo/04-home-landing.png" });
    console.log("LANDING captured");
  } else {
    await page.screenshot({ path: "/tmp/landing-debug.png" });
    console.log("LANDING not visible — debug shot at /tmp/landing-debug.png");
  }
  await ctx.close();
});
