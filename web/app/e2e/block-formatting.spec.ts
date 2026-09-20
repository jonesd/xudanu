import { test, expect } from "@playwright/test";

// FR-74 Phase B: block toolbar buttons create ANNOTATIONS on unmarked
// lines — the text model never gains "# " prefixes. Hidden marker spans
// ARE part of textContent by design (legacy path keeps model text
// intact), so "editor contains no #" is a true model-level assertion.

async function backendAvailable(): Promise<boolean> {
  try {
    const resp = await fetch("http://localhost:8080/health");
    return resp.ok;
  } catch {
    return false;
  }
}

test("H1 toggle styles without touching the text model", async ({ page }) => {
  test.skip(!(await backendAvailable()), "Backend not running on :8080");

  // The workspace opens for anonymous sessions. Create an identity via
  // the identity badge (pen name + password), then Compose — the
  // Compose nav tab creates a fresh editable work.
  await page.goto("http://localhost:5173/");
  await page.locator(".identity-badge").click({ timeout: 15000 });
  const nameInput = page.getByPlaceholder("Display name");
  await nameInput.waitFor({ timeout: 5000 });
  await nameInput.fill(`H1 ${Date.now() % 100000}`);
  await page.getByPlaceholder("Password", { exact: true }).fill("test-pass-1234");
  await page.locator(".identity-submit").click();
  await page.locator(".identity-badge").click(); // close panel
  await page.getByRole("button", { name: "Compose" }).click();

  const editor = page.locator(".editor-content");
  await editor.waitFor({ timeout: 15000 });

  // Type a line, then toggle H1 with the caret on it
  await editor.click();
  await page.keyboard.type("Stable Heading");
  await page.locator('button[title="Heading 1"]').click();

  // Annotation path: styled span, and NO "#" anywhere in the model
  // (hidden legacy markers would surface in textContent)
  const styled = page.locator('.editor-content span[style*="font-size:1.8em"]');
  await expect(styled).toBeVisible({ timeout: 5000 });
  await expect(styled).toContainText("Stable Heading");
  await expect(editor).not.toContainText("#");

  // Edits at the line end must keep the heading (span migration)
  await page.keyboard.press("End");
  await page.keyboard.type("!");
  await expect(page.locator('.editor-content span[style*="font-size:1.8em"]'))
    .toContainText("Stable Heading!", { timeout: 5000 });

  // Toggle off — styling gone, text intact
  await page.locator('button[title="Heading 1"]').click();
  await expect(page.locator('.editor-content span[style*="font-size:1.8em"]')).toHaveCount(0, { timeout: 5000 });
  await expect(editor).toContainText("Stable Heading!");
  await expect(editor).not.toContainText("#");
});
