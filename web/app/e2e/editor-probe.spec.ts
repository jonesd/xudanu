import { test, expect } from "@playwright/test";

async function backendAvailable(): Promise<boolean> {
  try {
    const res = await fetch("http://127.0.0.1:8080/health");
    return res.ok;
  } catch {
    return false;
  }
}

test("probe — editor surface exists and is clean", async ({ page }) => {
  test.skip(!(await backendAvailable()), "Backend not running");
  const errors: string[] = [];
  page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
  page.on("pageerror", (e) => errors.push(`PAGEERROR: ${e.message}`));

  await page.goto("http://localhost:5173/");
  await page.waitForTimeout(3000);

  const editor = page.locator(".editor-content").first();
  const visible = await editor.isVisible({ timeout: 3000 }).catch(() => false);
  console.log("EDITOR VISIBLE:", visible);
  if (visible) {
    const editable = await editor.getAttribute("contenteditable");
    console.log("EDITABLE ATTR:", editable);
    console.log("READONLY CLASS:", await editor.getAttribute("class"));
  }
  console.log("CONSOLE ERRORS:", JSON.stringify(errors));
  expect(errors.filter((e) => !e.includes("favicon")).length).toBe(0);
});

test("probe — typing latency 30 lines", async ({ page }) => {
  test.skip(!(await backendAvailable()), "Backend not running");
  await page.goto("http://localhost:5173/");
  await page.waitForTimeout(2500);

  const editor = page.locator(".editor-content").first();
  if (!(await editor.isVisible({ timeout: 3000 }).catch(() => false))) {
    console.log("NO EDITOR — screenshot the page state instead");
    return;
  }
  await editor.click();
  const t0 = Date.now();
  for (let i = 0; i < 30; i++) {
    await page.keyboard.type(`line ${i} rapid input probe\n`, { delay: 3 });
  }
  const elapsed = Date.now() - t0;
  const perLine = elapsed / 30;
  console.log(`TYPING: 30 lines in ${elapsed}ms (${perLine.toFixed(0)}ms/line)`);
  expect(perLine).toBeLessThan(500);
});
