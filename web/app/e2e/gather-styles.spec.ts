import { test } from "@playwright/test";

test("gather button computed styles when disabled", async ({ page }) => {
  await page.goto("http://localhost:5173/");
  await page.waitForTimeout(3500);

  const create = page.locator(".ws-home-card-create");
  if (await create.isVisible({ timeout: 2500 }).catch(() => false)) {
    await create.click();
    const form = page.locator(".ws-home-identity");
    if (await form.isVisible({ timeout: 4000 }).catch(() => false)) {
      await page.locator(".ws-home-identity input[type=text]").fill(`Pen ${Date.now() % 100000}`);
      await page.locator(".ws-home-identity input[type=password]").fill("test-pass-1234");
      await page.locator(".ws-home-identity button[type=submit]").click();
    }
    await page.waitForTimeout(3000);
  }

  const editor = page.locator(".editor-content").first();
  await editor.waitFor({ timeout: 6000 });
  await editor.click();
  await page.keyboard.type("probe text for gather disabled state check", { delay: 10 });
  await page.waitForTimeout(800);
  await page.keyboard.press("Home");
  for (let i = 0; i < 6; i++) await page.keyboard.press("Shift+ArrowRight");
  await page.waitForTimeout(1000);

  const info = await page.evaluate(() => {
    const btns = Array.from(document.querySelectorAll(".ws-selection-actions button"));
    const g = btns.find((b) => b.textContent?.trim() === "Gather") as HTMLButtonElement | undefined;
    if (!g) return { found: false };
    const cs = getComputedStyle(g);
    // measure actual text pixels: compare button snapshot with/without text
    const r = g.getBoundingClientRect();
    const canvas = document.createElement("canvas");
    canvas.width = Math.ceil(r.width);
    canvas.height = Math.ceil(r.height);
    const ctx = canvas.getContext("2d")!;
    const range = document.createRange();
    range.selectNodeContents(g);
    const span = range.getBoundingClientRect();
    return {
      found: true,
      disabled: g.disabled,
      color: cs.color,
      opacity: cs.opacity,
      fontSize: cs.fontSize,
      fontFamily: cs.fontFamily.slice(0, 40),
      checkVisibility: (g as unknown as { checkVisibility?: () => boolean }).checkVisibility?.() ?? null,
      textRect: { w: span.width, h: span.height, x: span.x - r.x, y: span.y - r.y },
      btnRect: { w: r.width, h: r.height },
      bodyTheme: document.body.className,
      cssVars: {
        green: getComputedStyle(document.documentElement).getPropertyValue("--green").trim(),
        bg: getComputedStyle(document.documentElement).getPropertyValue("--bg").trim(),
        bgSurface: getComputedStyle(document.documentElement).getPropertyValue("--bg-surface").trim(),
      },
      toolbarBg: (() => {
        let el: HTMLElement | null = g.parentElement;
        while (el && el !== document.body) {
          const c = getComputedStyle(el);
          if (c.backgroundColor !== "rgba(0, 0, 0, 0)") return c.backgroundColor;
          el = el.parentElement;
        }
        return "none";
      })(),
    };
  });
  console.log("GATHER:", JSON.stringify(info, null, 1));
});
