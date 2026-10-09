import { test, expect } from "@playwright/test";
import { connect, makeWorks } from "./helpers";

test.describe("beam as object — the connection line is a thing", () => {
  test("clicking a beam opens an inspector naming its type and both ends", async ({ page }) => {
    await connect(page);
    const { a } = await makeWorks(
      page,
      { text: "origin page with a passage\nsecond line" },
      { text: "destination page content\nsecond line" },
      { excerpt: "origin page", start: 0, end: 11 },
    );

    await page.goto(`/#w${a}`);
    await page.locator("#scroll-a mark").first().click();
    await expect(page.locator("#pane-b:not(.ghost) h2")).toContainText("destination page");
    await expect(page.locator("#beams path")).toHaveCount(2); // line + hit twin

    // Click the line itself (its invisible wide twin).
    await page.locator("#beams path.beam-hit").first().click();
    const panel = page.locator("#beam-panel");
    await expect(panel).toBeVisible();
    await expect(panel.locator(".bp-type")).toContainText("reference");
    await expect(panel).toContainText("origin page with a passage");
    await expect(panel).toContainText("destination page content");

    // closing dismisses it
    await page.locator("#beam-close").click();
    await expect(panel).toHaveCount(0);
  });
});
