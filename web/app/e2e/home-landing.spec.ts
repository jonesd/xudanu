import { test, expect } from "@playwright/test";

async function backendAvailable(): Promise<boolean> {
  try {
    const res = await fetch("http://127.0.0.1:8080/health");
    return res.ok;
  } catch {
    return false;
  }
}

test("home landing renders for fresh user", async ({ page }) => {
  test.skip(!(await backendAvailable()), "Backend not running");
  await page.goto("http://localhost:5173/");
  await page.waitForTimeout(3000);
  await page.screenshot({ path: "/tmp/home-landing-live.png", fullPage: false });

  await expect(page.getByText("What would you like to", { exact: false })).toBeVisible({ timeout: 5000 });
  await expect(page.locator(".ws-home-card-create")).toBeVisible();
  await expect(page.locator(".ws-home-card", { hasText: "Import a file" })).toBeVisible();
});

test("create document card works", async ({ page }) => {
  test.skip(!(await backendAvailable()), "Backend not running");
  await page.goto("http://localhost:5173/");
  await page.waitForTimeout(3000);

  const create = page.locator(".ws-home-card-create");
  await create.waitFor({ timeout: 8000 });
  await create.click();
  await page.waitForTimeout(2500);

  // Without an identity, the pen-name step must appear (fresh-user funnel).
  // With one already set up, the editor opens directly.
  const identityForm = page.locator(".ws-home-identity");
  const hasForm = await identityForm.isVisible({ timeout: 4000 }).catch(() => false);
  if (hasForm) {
    await expect(identityForm).toBeVisible();
    await page.locator(".ws-home-identity-cancel").click();
    await expect(identityForm).toHaveCount(0);
  } else {
    await expect(page.locator(".ws-home-landing")).toHaveCount(0, { timeout: 8000 });
  }
  await page.screenshot({ path: "/tmp/home-landing-after-create.png" });
});
