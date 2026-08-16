import { test } from "@playwright/test";

test("render mockups", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  for (const name of ["design-a-home-first", "design-b-three-pane", "design-c-transclusion-window"]) {
    await page.goto(`file:///tmp/mockups/${name}.html`);
    await page.waitForTimeout(400);
    await page.screenshot({ path: `/tmp/mockups/${name}.png` });
  }
});
