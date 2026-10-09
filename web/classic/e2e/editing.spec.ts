import { test, expect } from "@playwright/test";
import { connect, makeWorks } from "./helpers";

test.describe("classic editing through the CRDT delta path", () => {
  test("a save revises the text and the underline follows its words", async ({ page }) => {
    await connect(page);
    const { a } = await makeWorks(
      page,
      { text: "XXXX MOVEME YYYY\nbody of the source work" },
      { text: "far end" },
      { excerpt: "MOVEME", start: 5, end: 11 },
    );

    await page.goto(`/#w${a}`);
    await expect(page.locator("#pane-a h2")).toContainText("XXXX MOVEME");
    await expect(page.locator("#scroll-a mark[data-link]")).toHaveText("MOVEME");

    // Edit: insert text BEFORE the linked passage.
    await page.locator('[data-revise-pane="a"]').click();
    const ta = page.locator("#revise-text");
    await expect(ta).toBeVisible();
    await ta.fill("NEW PREFIX XXXX MOVEME YYYY\nbody of the source work");
    await page.locator("#revise-save").click();
    await expect(page.locator("#head-status")).toContainText("saved");

    // The persisted text carries the edit…
    await expect(page.locator("#scroll-a")).toContainText("NEW PREFIX");
    // …and the underline still wraps exactly its excerpt — the span
    // migrated with the words (the regression this suite guards).
    await expect(page.locator("#scroll-a mark[data-link]")).toHaveText("MOVEME");
  });

  test("escape cancels: hold released, text unchanged", async ({ page }) => {
    await connect(page);
    const { a } = await makeWorks(page, { text: "stable text" }, { text: "other" });

    await page.goto(`/#w${a}`);
    await page.locator('[data-revise-pane="a"]').click();
    await page.locator("#revise-text").fill("ESCAPED EDIT");
    await page.keyboard.press("Escape");
    await expect(page.locator("#revise-text")).toHaveCount(0);
    await expect(page.locator("#scroll-a")).toContainText("stable text");
    await expect(page.locator("#scroll-a")).not.toContainText("ESCAPED");
  });
});
