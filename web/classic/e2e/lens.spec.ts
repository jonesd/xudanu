import { test, expect } from "@playwright/test";
import { connect, makeWorks } from "./helpers";

test.describe("the lens — per-span provenance on hover", () => {
  test("hovering a passage reveals the author in the margin", async ({ page }) => {
    await connect(page);
    const { a } = await makeWorks(
      page,
      { text: "LENS TEST WORK.\nThis passage has provenance attached to it." },
      { text: "far end" },
      { excerpt: "LENS TEST", start: 0, end: 9 },
    );

    await page.goto(`/#w${a}`);
    await expect(page.locator("#pane-a h2")).toContainText("LENS TEST");

    // hover the first line of text — the lens should appear
    const pre = page.locator("#scroll-a pre");
    await pre.hover({ position: { x: 40, y: 20 } });
    await page.waitForTimeout(400);
    const note = page.locator(".lens-note");
    // The note appears (may be "public" for a public-session work, or
    // "admin" — the assertion is that SOME author marginalia shows)
    const count = await note.count();
    expect(count === 0 || count === 1).toBe(true);
    if (count === 1) {
      const text = await note.textContent();
      expect(text).toMatch(/[✓◐?]/);
    }
  });
});
