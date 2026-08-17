import { test } from "@playwright/test";

test("capture current UX state", async ({ page }) => {
  await page.goto("http://localhost:5173/");
  await page.waitForTimeout(3000);
  await page.screenshot({ path: "/tmp/mockups/before-fresh-landing.png" });

  // Try the Create path
  const create = page.locator("button", { hasText: /create/i }).first();
  if (await create.isVisible().catch(() => false)) {
    await create.click();
    await page.waitForTimeout(1500);
    await page.screenshot({ path: "/tmp/mockups/before-create-menu.png" });
  }

  // Open library view
  const lib = page.locator("button, a", { hasText: /library/i }).first();
  if (await lib.isVisible().catch(() => false)) {
    await lib.click();
    await page.waitForTimeout(1500);
    await page.screenshot({ path: "/tmp/mockups/before-library.png" });
  }
});
