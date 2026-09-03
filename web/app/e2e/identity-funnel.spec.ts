import { test, expect } from "@playwright/test";
test("identity funnel: start writing → pen name → editor", async ({ page }) => {
  await page.goto("http://localhost:5173/");
  await page.waitForTimeout(3000);
  const create = page.locator(".ws-home-card-create");
  await create.waitFor({ timeout: 8000 });
  await create.click();
  const form = page.locator(".ws-home-identity");
  await expect(form).toBeVisible({ timeout: 5000 });
  await page.locator(".ws-home-identity input[type=text]").fill(`Playwright ${Date.now() % 100000}`);
  await page.locator(".ws-home-identity input[type=password]").fill("test-pass-1234");
  await page.locator(".ws-home-identity button[type=submit]").click();
  await expect(page.locator(".ws-home-landing")).toHaveCount(0, { timeout: 15000 });
  await page.screenshot({ path: "/tmp/home-identity-funnel.png" });
});
