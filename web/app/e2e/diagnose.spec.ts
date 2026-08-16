import { test } from "@playwright/test";

test("diagnose — what does a fresh user actually see", async ({ page }) => {
  const failed: string[] = [];
  page.on("requestfailed", (r) => failed.push(`REQFAIL: ${r.url()} ${r.failure()?.errorText}`));
  page.on("response", (r) => r.status() >= 400 && failed.push(`${r.status()} ${r.url()}`));

  await page.goto("http://localhost:5173/");
  await page.waitForTimeout(3500);

  const body = await page.locator("body").innerText();
  console.log("=== PAGE TEXT (first 800 chars) ===");
  console.log(body.slice(0, 800));
  console.log("=== FAILED REQUESTS ===");
  console.log(JSON.stringify(failed, null, 1));
  console.log("=== URL ===", page.url());
  await page.screenshot({ path: "/tmp/fresh_user.png", fullPage: false });
});
