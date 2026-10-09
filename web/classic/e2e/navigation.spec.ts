import { test, expect, type Page } from "@playwright/test";
import { connect } from "./helpers";

/** Click a trail stop and wait for the work to land — retries once
 *  if the trail list re-rendered mid-click (async trails fetch can
 *  replace the anchor between visibility and click). */
async function openStop(page: Page, n: number): Promise<void> {
  for (let attempt = 0; attempt < 3; attempt++) {
    await page.locator(".trail-stops a").nth(n).click();
    try {
      await expect(page.locator("#pane-a h2")).not.toBeEmpty({ timeout: 4000 });
      return;
    } catch {
      /* list likely re-rendered; click again */
    }
  }
  throw new Error("trail stop never opened a work");
}

test.describe("classic navigation", () => {
  test("connect, open the Links Course from the trails panel, walk a lesson", async ({ page }) => {
    await connect(page);

    // The seeded course appears in the trails panel; expand it.
    await page.locator("#trails a[data-trail]").first().click();
    const stops = page.locator(".trail-stops a");
    await expect(stops.first()).toBeVisible();
    expect(await stops.count()).toBeGreaterThanOrEqual(5);

    // Open the first stop: it lands in the left column, hash deep-links it.
    await openStop(page, 0);
    // The pane heading is the work's first line (not its title).
    await expect(page.locator("#pane-a h2")).not.toBeEmpty();
    await expect(page).toHaveURL(/#w\d+$/);

    // The lesson's demonstration underline opens its far end in the
    // right column — the sideways walk through the docuverse.
    const mark = page.locator("#scroll-a mark[data-link]").first();
    await expect(mark).toBeVisible();
    await mark.click();
    await expect(page.locator("#pane-b:not(.ghost) h2")).toBeVisible();

    // History: the back button leaves the walk and returns to the
    // trail view (following a connection opens pane B without pushing
    // a history entry — back returns to the last opened work's
    // predecessor: here, the expanded trail).
    await page.locator("#hist-back").click();
    await expect(page.locator("#pane-a")).toHaveCount(0);
    await expect(page.locator("main article, .trail-stops").first()).toBeVisible();
  });

  test("postures and skins toggle without losing the open work", async ({ page }) => {
    await connect(page);
    await page.locator("#trails a[data-trail]").first().click();
    const stops = page.locator(".trail-stops a");
    await expect(stops.first()).toBeVisible();
    await openStop(page, 0);
    const heading = page.locator("#pane-a h2");
    await expect(heading).not.toBeEmpty();
    const openedHeading = ((await heading.textContent()) ?? "").trim().slice(0, 20);

    // windows posture
    await page.locator("#mode-toggle").click();
    await expect(page.locator("#stage")).toBeVisible();
    await expect(page.locator("#win-center h2")).toContainText(openedHeading);

    // paper skin: the page background flips to cream
    await page.locator("#skin-toggle").click();
    await expect(page.locator("body.paper")).toBeVisible();

    // and back
    await page.locator("#mode-toggle").click();
    await expect(page.locator("#pane-a h2")).toContainText(openedHeading);
  });
});
