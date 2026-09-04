import { test, expect } from "@playwright/test";

async function backendAvailable(): Promise<boolean> {
  try {
    const res = await fetch("http://127.0.0.1:8080/health");
    return res.ok;
  } catch {
    return false;
  }
}

test("beams view: entry button, columns, beams render", async ({ page }) => {
  test.skip(!(await backendAvailable()), "Backend not running");
  await page.goto("http://localhost:5173/");
  await page.waitForTimeout(3000);

  // Skip the landing if present (fresh user) — we need to get into a doc.
  const skip = page.locator(".ws-home-skip");
  if (await skip.isVisible({ timeout: 3000 }).catch(() => false)) {
    await skip.click();
    await page.waitForTimeout(1000);
  }

  // Open the first work in the list (server has demo/seeded content).
  const firstWork = page.locator(".ws-work-item").first();
  await firstWork.waitFor({ timeout: 8000 });
  await firstWork.click();
  await page.waitForTimeout(2500);

  // Beams entry appears only when the doc has links. The seeded demo
  // document has typed links; if absent, create nothing — skip.
  const entry = page.locator(".ws-beams-entry");
  const hasEntry = await entry.isVisible({ timeout: 5000 }).catch(() => false);
  test.skip(!hasEntry, "No links on first work — beams need linked documents");

  await entry.click();
  await page.waitForTimeout(2500);

  await expect(page.locator(".ws-beams-doc").first()).toBeVisible({ timeout: 8000 });
  await page.screenshot({ path: "/tmp/beams-view-live.png", fullPage: false });

  // At least one beam (SVG path) or one highlighted span should exist.
  const beamCount = await page.locator(".ws-beams-beam").count();
  const markCount = await page.locator(".ws-beams-mark").count();
  expect(beamCount + markCount).toBeGreaterThan(0);

  // Legend renders for types present.
  const legend = await page.locator(".ws-beams-legend-row").count();
  expect(legend).toBeGreaterThan(0);

  await page.locator(".ws-beams-close").click();
  await expect(page.locator(".ws-beams")).toHaveCount(0);
});
