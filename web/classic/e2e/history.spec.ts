import { test, expect, type Page } from "@playwright/test";
import { connect, makeWorks, activeTitle } from "./helpers";

/** Click a trail stop and wait for the work to land — retries if the
 *  trail list re-rendered mid-click (same pattern as the navigation
 *  spec). */
async function openStop(page: Page, n: number): Promise<void> {
  for (let attempt = 0; attempt < 5; attempt++) {
    if ((await page.locator(".trail-stops a").count()) === 0) {
      await page.locator("#trails a[data-trail]").first().click();
      await expect(page.locator(".trail-stops a").first()).toBeVisible({ timeout: 4000 });
    }
    await page.locator(".trail-stops a").nth(n).click();
    try {
      await expect(activeTitle(page, "a")).not.toBeEmpty({ timeout: 4000 });
      return;
    } catch {
      /* retry */
    }
  }
  throw new Error("trail stop never opened a work");
}

test.describe("browser history — the reading session survives back", () => {
  test("back from a follow closes the far column; forward reopens it", async ({ page }) => {
    await connect(page);
    const { a, b } = await makeWorks(
      page,
      { text: "HISTONE alpha.\nfirst page" },
      { text: "HISTTWO beta.\nmiddle page" },
      { excerpt: "HISTONE alpha.", start: 0, end: 15 },
    );

    // open through a search result: a pushed, snapshotted entry
    await page.fill("#q", "HISTONE");
    await page.press("#q", "Enter");
    await page.locator("#results a[data-work]").first().click();
    await expect(activeTitle(page, "a")).toContainText("HISTONE");
    await expect(page).toHaveURL(new RegExp(`#w${a}$`));

    // follow the underline: the far end lands in column B
    await page.locator("#scroll-a mark[data-link]").first().click();
    await expect(page.locator("#pane-b:not(.ghost) .stack-work-title").first()).toContainText("HISTTWO");
    await expect(page).toHaveURL(new RegExp(`#w${b}$`));

    // back: only the far column closes — the reading view survives
    await page.goBack();
    await expect(page.locator("#pane-b.ghost")).toBeVisible();
    await expect(activeTitle(page, "a")).toContainText("HISTONE");
    await expect(page).toHaveURL(new RegExp(`#w${a}$`));

    // forward: the far column reopens
    await page.goForward();
    await expect(page.locator("#pane-b:not(.ghost) .stack-work-title").first()).toContainText("HISTTWO");
  });

  test("trail stop, follow, back twice: reading kept, then the trail", async ({ page }) => {
    await connect(page);
    await openStop(page, 0);
    const lesson = ((await activeTitle(page, "a").textContent()) ?? "").trim().slice(0, 20);

    // follow the lesson's demonstration underline
    await page.locator("#scroll-a mark[data-link]").first().click();
    await expect(page.locator("#pane-b:not(.ghost) .stack-work-title").first()).not.toBeEmpty();

    // back once: the far column closes, the reading view survives
    await page.goBack();
    await expect(page.locator("#pane-b.ghost")).toBeVisible();
    await expect(activeTitle(page, "a")).toContainText(lesson);

    // back again: the trail view returns
    await page.goBack();
    await expect(page.locator("#pane-a")).toHaveCount(0);
    await expect(page.locator("main article, .trail-stops").first()).toBeVisible();
  });
});
