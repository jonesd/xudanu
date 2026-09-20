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
  // the identity badge (Create Identity → pen name + password), then
  // Compose — the Compose nav tab creates a fresh editable work.
  await page.goto("http://localhost:5173/");
  await page.locator(".identity-badge").click({ timeout: 15000 });
  await page.getByRole("button", { name: "Create Identity" }).click();
  const nameInput = page.getByPlaceholder("Display name");
  await nameInput.waitFor({ timeout: 5000 });
  await nameInput.fill(`H1 ${Date.now() % 100000}`);
  await page.getByPlaceholder("Password", { exact: true }).fill("Test-pass-1234");
  await page.locator(".identity-submit").click();
  // Creation resets the panel to the actions view; close the modal
  await page.locator(".ws-anno-cancel", { hasText: "Close" }).click();
  await page.getByRole("button", { name: "Compose" }).click();

  const editor = page.locator(".editor-content");
  await editor.waitFor({ timeout: 15000 });
  // The compose flow sets the title only after create → select →
  // work_set_title complete — a solid quiescence signal for the
  // work switch (typing during the switch is discarded).
  await page
    .locator(".ws-doc-title-text")
    .filter({ hasText: "Untitled composition" })
    .waitFor({ timeout: 15000 });
  await page.waitForTimeout(1500);

  // The compose work-switch can race typing (server text arriving late
  // wipes the editor). Type, verify it survives a settle window, and
  // retry if the switch ate it — a real user retypes.
  for (let attempt = 0; attempt < 3; attempt++) {
    await editor.click();
    await page.keyboard.type("Stable Heading");
    await page.waitForTimeout(1200);
    const t = await editor.textContent();
    if (t?.includes("Stable Heading")) break;
  }
  await expect(editor).toContainText("Stable Heading", { timeout: 5000 });
  // Let the debounced save sync before the toggle (annotation
  // positions must match server-side text)
  await page.waitForTimeout(1000);
  await page.locator('button[title="Heading 1"]').click();

  // Annotation path: styled span, and NO "#" anywhere in the model
  // (hidden legacy markers would surface in textContent)
  const styled = page.locator('.editor-content span[style*="font-size:1.8em"]');
  await expect(styled).toBeVisible({ timeout: 5000 });
  await expect(styled).toContainText("Stable Heading");
  await expect(editor).not.toContainText("#");

  // Edits at the line end must keep the heading (span migration).
  // Re-click first: assertion polling outlasted the 2s edit-mode
  // inactivity timer, and keystrokes die in display mode.
  await editor.click();
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
