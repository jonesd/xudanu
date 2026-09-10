import { test } from "@playwright/test";

test("gather toolbar label check", async ({ page }) => {
  page.on("console", (m) => m.type() === "error" && console.log("CONSOLE:", m.text()));
  await page.goto("http://localhost:5173/");
  await page.waitForTimeout(3500);

  // skip landing if fresh — but if identity form appears, complete it
  const skip = page.locator(".ws-home-skip");
  if (await skip.isVisible({ timeout: 2500 }).catch(() => false)) {
    // create via landing card (goes through identity if needed)
    const create = page.locator(".ws-home-card-create");
    if (await create.isVisible({ timeout: 2000 }).catch(() => false)) {
      await create.click();
      const form = page.locator(".ws-home-identity");
      if (await form.isVisible({ timeout: 4000 }).catch(() => false)) {
        await page.locator(".ws-home-identity input[type=text]").fill(`Pen ${Date.now() % 100000}`);
        await page.locator(".ws-home-identity input[type=password]").fill("test-pass-1234");
        await page.locator(".ws-home-identity button[type=submit]").click();
      }
      await page.waitForTimeout(3000);
    } else {
      await skip.click();
      await page.waitForTimeout(800);
    }
  }
  await page.waitForTimeout(800);

  // type some text if editor is empty/newly created
  const editor0 = page.locator(".editor-content").first();
  if (await editor0.isVisible({ timeout: 4000 }).catch(() => false)) {
    await editor0.click();
    await page.keyboard.type("The gathered passage probe text for toolbar inspection", { delay: 10 });
    await page.waitForTimeout(1500);
  } else {
    // open first work
    const first = page.locator(".ws-work-item, .ws-studio-doc").first();
    if (await first.isVisible({ timeout: 6000 }).catch(() => false)) {
      await first.click();
      await page.waitForTimeout(2500);
    }
  }

  // Switch to Studio layout if available
  const fab = page.locator(".ws-studio-layout-fab");
  if (await fab.isVisible({ timeout: 2000 }).catch(() => false)) {
    const label = await fab.textContent();
    if (label?.includes("Studio")) {
      await fab.click();
      await page.waitForTimeout(800);
    }
  }

  // select some text in the editor
  const editor = page.locator(".editor-content").first();
  if (await editor.isVisible({ timeout: 4000 }).catch(() => false)) {
    await editor.click();
    await page.keyboard.press("Home");
    for (let i = 0; i < 8; i++) await page.keyboard.press("Shift+ArrowRight");
    await page.waitForTimeout(1200);

    const bar = page.locator(".ws-selection-actions");
    if (await bar.isVisible({ timeout: 3000 }).catch(() => false)) {
      const buttons = bar.locator("button");
      const n = await buttons.count();
      console.log("TOOLBAR BUTTONS:", n);
      for (let i = 0; i < n; i++) {
        const txt = (await buttons.nth(i).textContent())?.trim();
        const box = await buttons.nth(i).boundingBox();
        const cls = await buttons.nth(i).getAttribute("class");
        console.log(`  btn[${i}] text="${txt}" w=${box?.width} cls=${cls}`);
      }
      await page.screenshot({ path: "/tmp/gather-toolbar.png" });
    } else {
      console.log("TOOLBAR NOT VISIBLE after selection");
    }
  } else {
    console.log("EDITOR NOT VISIBLE");
  }
});
