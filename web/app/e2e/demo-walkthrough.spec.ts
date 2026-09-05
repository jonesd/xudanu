import { test } from "@playwright/test";

async function backendReady(): Promise<boolean> {
  try {
    const res = await fetch("http://127.0.0.1:8093/health");
    return res.ok;
  } catch { return false; }
}

const DIR = "../../docs/screenshots/compound-demo";
const BASE = "http://localhost:5173";

test("demo walkthrough", async ({ page }) => {
  test.skip(!(await backendReady()), "Demo server not on :8093");
  await page.setViewportSize({ width: 1440, height: 900 });

  // ── Shot 1: The compound document ────────────────────────────
  await page.goto(`${BASE}/?work=0x3ee&clear=1`);
  await page.waitForTimeout(4000);
  const skip = page.locator(".ws-home-skip");
  if (await skip.isVisible({ timeout: 2000 }).catch(() => false)) await skip.click();
  await page.waitForTimeout(2000);
  await page.screenshot({ path: `${DIR}/01-compound-document.png` });
  console.log("SHOT 1 done");

  // ── Shot 2: A source document (Gold Interview Notes) ─────────
  await page.goto(`${BASE}/?work=0x3ec`);
  await page.waitForTimeout(3000);
  await page.screenshot({ path: `${DIR}/02-source-gold-interview.png` });
  console.log("SHOT 2 done");

  // ── Shot 3: Builder (Compose tab) with live preview ──────────
  await page.goto(`${BASE}/?work=0x3ee&nav=compose`);
  await page.waitForTimeout(4000);
  await page.screenshot({ path: `${DIR}/03-builder-live-preview.png` });
  console.log("SHOT 3 done");

  // ── Shot 4: Home landing (fresh-user experience) ─────────────
  // Clear to anonymous, show landing
  await page.context().clearCookies();
  await page.goto(`${BASE}/?clear=1`);
  await page.waitForTimeout(3500);
  const landing = page.locator(".ws-home-landing");
  if (await landing.isVisible({ timeout: 3000 }).catch(() => false)) {
    await page.screenshot({ path: `${DIR}/04-home-landing.png` });
    console.log("SHOT 4 done (landing)");
  } else {
    console.log("SHOT 4: landing not visible (existing session?)");
  }

  // ── Shot 5: Studio layout ────────────────────────────────────
  await page.goto(`${BASE}/?work=0x3ee`);
  await page.waitForTimeout(2500);
  const skip2 = page.locator(".ws-home-skip");
  if (await skip2.isVisible({ timeout: 2000 }).catch(() => false)) await skip2.click();
  await page.waitForTimeout(500);
  const studioToggle = page.locator(".ws-studio-layout-fab");
  if (await studioToggle.isVisible({ timeout: 3000 }).catch(() => false)) {
    await studioToggle.click();
    await page.waitForTimeout(2000);
    await page.screenshot({ path: `${DIR}/05-studio-layout.png` });
    console.log("SHOT 5 done (studio)");
  } else {
    console.log("SHOT 5: studio toggle not visible");
  }

  // ── Shot 6: Beams (if links exist) ───────────────────────────
  const beamsBtn = page.locator(".ws-beams-entry");
  if (await beamsBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
    await beamsBtn.click();
    await page.waitForTimeout(3000);
    await page.screenshot({ path: `${DIR}/06-beams.png` });
    console.log("SHOT 6 done (beams)");
  } else {
    console.log("SHOT 6: no beams button (no links on compound)");
  }
});
