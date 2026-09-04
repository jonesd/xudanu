import { test } from "@playwright/test";
import { resolve } from "path";

const dir = resolve(process.cwd(), "../../docs/mockups");

test("render mockups", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  for (const name of [
    "design-a-home-first",
    "design-b-three-pane",
    "design-c-transclusion-window",
    "design-d-beams-n-way",
  ]) {
    await page.goto(`file://${dir}/${name}.html`);
    await page.waitForTimeout(400);
    await page.screenshot({ path: `${dir}/${name}.png` });
  }
});
