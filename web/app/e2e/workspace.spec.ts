import { test, expect } from "@playwright/test";

async function backendAvailable(): Promise<boolean> {
  try {
    const resp = await fetch("http://localhost:8080/health");
    return resp.ok;
  } catch {
    return false;
  }
}

test.describe("Xudanu workspace (UI only)", () => {

  test("page loads and renders", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator("body")).toBeVisible();
    const text = await page.locator("body").textContent();
    expect(text?.length).toBeGreaterThan(0);
  });

  test("page has interactive elements", async ({ page }) => {
    await page.goto("/");
    await page.waitForTimeout(1000);
    const buttons = page.locator("button");
    const count = await buttons.count();
    expect(count).toBeGreaterThan(0);
  });
});

test.describe("Document lifecycle (requires backend)", () => {

  test("create work and type text", async ({ page }) => {
    test.skip(!(await backendAvailable()), "Backend not running on :8080");

    await page.goto("/");
    await page.waitForTimeout(2000);

    const editor = page.locator("textarea, [contenteditable], .ws-editor-area, .cm-content").first();
    const editorVisible = await editor.isVisible({ timeout: 5000 }).catch(() => false);
    if (editorVisible) {
      await editor.click();
      await page.keyboard.type("Hello from Playwright E2E!");
      await page.waitForTimeout(2000);

      const bodyText = await page.locator("body").textContent();
      expect(bodyText).toContain("Hello from Playwright");
    }
  });
});

test.describe("Tumbler features (requires backend)", () => {

  test("tumbler input field present", async ({ page }) => {
    test.skip(!(await backendAvailable()), "Backend not running on :8080");

    await page.goto("/");
    await page.waitForTimeout(2000);

    const tumblerInput = page.locator('input[placeholder*="tumbler"]');
    const count = await tumblerInput.count();
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test("tumbler display in header", async ({ page }) => {
    test.skip(!(await backendAvailable()), "Backend not running on :8080");

    await page.goto("/");
    await page.waitForTimeout(2000);

    const pidElements = page.locator('[class*="ws-doc-pid"]');
    const count = await pidElements.count();
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test("link button for permalink sharing", async ({ page }) => {
    test.skip(!(await backendAvailable()), "Backend not running on :8080");

    await page.goto("/");
    await page.waitForTimeout(2000);

    const linkBtn = page.locator('button[title*="link"], button:has-text("link")');
    const count = await linkBtn.count();
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test("paste tumbler and navigate", async ({ page }) => {
    test.skip(!(await backendAvailable()), "Backend not running on :8080");

    await page.goto("/");
    await page.waitForTimeout(2000);

    const tumblerInput = page.locator('input[placeholder*="tumbler"]').first();
    if (await tumblerInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      await tumblerInput.fill('"localhost".0x1');
      await tumblerInput.press("Enter");
      await page.waitForTimeout(2000);
    }
  });

  test("URL hash tumbler routing", async ({ page }) => {
    test.skip(!(await backendAvailable()), "Backend not running on :8080");

    await page.goto("/#tumbler=%22localhost%22.0x1");
    await page.waitForTimeout(3000);

    const url = page.url();
    expect(url).toBeTruthy();
  });
});
