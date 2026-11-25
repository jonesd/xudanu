import { test, expect } from "@playwright/test";
import { openHash, connect, activeTitle } from "./helpers";

test.describe("transclusion identity boxes", () => {
  test("a placed transclusion displays resolved content in a Nelson box with its source tab", async ({ page }) => {
    await connect(page);
    const ids = await page.evaluate(async () => {
      const ws = new WebSocket(`ws://${location.host}/xudanu?format=json&version=2`);
      await new Promise<void>((res, rej) => { ws.onopen = () => res(); ws.onerror = () => rej(new Error("ws")); });
      let id = 1;
      const pending = new Map<number, { res: (v: unknown) => void; rej: (e: Error) => void }>();
      ws.addEventListener("message", (ev) => {
        const f = JSON.parse(ev.data);
        if ((f.type === "response" || f.type === "error") && pending.has(f.id)) {
          const p = pending.get(f.id)!; pending.delete(f.id);
          f.type === "error" ? p.rej(new Error(f.message)) : p.res(f.value?.value ?? f.value);
        }
      });
      const req = (op: string, payload: Record<string, unknown> = {}) =>
        new Promise<unknown>((res, rej) => {
          const i = id++; pending.set(i, { res, rej });
          ws.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload }));
          setTimeout(() => rej(new Error("timeout")), 5000);
        });
      await req("session_connect"); await req("session_login_public");
      const src = await req("work_create", { edition: { text: "SHARED PASSAGE GAMMA only here.\nsource body" } }) as number;
      // Filler pushes the window below the fold so the scroll-alignment
      // assertions below exercise a real scroll offset.
      const filler = Array.from({ length: 14 }, (_, i) => `Filler paragraph ${i} stands here so the window starts below the fold.`).join("\n\n");
      const prefix = "Holder opening.\n\n" + filler + "\n\n";
      const holder = await req("work_create", { edition: { text: prefix + "xxxx\n\nHolder closing." } }) as number;
      await req("work_grab", { work_id: holder });
      // place at the xxxx line (start of the last content block)
      await req("element_insert", { work_id: holder, position: prefix.length, element: { type: "transclusion", transclusion_source: src, transclusion_start: 0, transclusion_end: 22 } });
      await req("work_release", { work_id: holder });
      ws.close();
      return { src, holder };
    });

    await openHash(page, ids.holder);
    await expect(activeTitle(page, "a")).toContainText("Holder opening");

    // The reading surface shows the RESOLVED text: the live window's
    // content appears inline, not a placeholder.
    await expect(page.locator("#scroll-a")).toContainText("SHARED PASSAGE GAMMA");

    // One identity box over the shared passage, tabbed with its source.
    await expect(page.locator("#pane-a .tbox").first()).toBeVisible();
    await expect(page.locator("#pane-a .tbox-tab").first()).toContainText("SHARED PASSAGE GAMMA");

    // The box sits over its words: the tab's x position is inside the
    // pane's text column, and the box width is positive.
    const box = page.locator("#pane-a .tbox").first();
    const bw = await box.boundingBox();
    expect(bw).not.toBeNull();
    expect(bw!.width).toBeGreaterThan(40);

    // The identity layer rides inside the scroller: box coordinates are
    // content-relative, so alignment holds at every scroll offset with
    // no redraw chasing the scroll (the fix for touch-scroll undulation).
    await expect(page.locator("#scroll-a > .tboxes")).toHaveCount(1);
    const align = () =>
      page.evaluate(() => {
        const b = document.querySelector("#pane-a .tbox") as HTMLElement | null;
        const pre = document.querySelector("#scroll-a pre");
        if (!b || !pre) return null;
        const walker = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT);
        let node: Text | null = null;
        let at = -1;
        while (walker.nextNode()) {
          const t = walker.currentNode as Text;
          const i = t.textContent?.indexOf("SHARED PASSAGE GAMMA") ?? -1;
          if (i >= 0) { node = t; at = i; break; }
        }
        if (!node || at < 0) return null;
        const r = document.createRange();
        r.setStart(node, at);
        r.setEnd(node, at + 20);
        const textR = r.getBoundingClientRect();
        const boxR = b.getBoundingClientRect();
        return {
          st: document.getElementById("scroll-a")!.scrollTop,
          dx: Math.abs(boxR.left - textR.left),
          dy: Math.abs(boxR.top - textR.top),
        };
      });
    const atRest = await align();
    expect(atRest).not.toBeNull();
    expect(atRest!.dx).toBeLessThan(2);
    expect(atRest!.dy).toBeLessThan(2);
    await page.evaluate(() => { document.getElementById("scroll-a")!.scrollTop = 600; });
    const scrolled = await align();
    expect(scrolled).not.toBeNull();
    // The work is tall enough that this is a real scroll, not a no-op.
    expect(scrolled!.st).toBeGreaterThan(400);
    expect(scrolled!.dx).toBeLessThan(2);
    expect(scrolled!.dy).toBeLessThan(2);

    // Editing the holder keeps the box machinery alive after re-render.
    await page.locator('[data-revise-pane="a"]').click();
    await page.locator("#revise-text").fill("Holder opening edited.\n\nSHARED PASSAGE GAMMA only here.\n\nHolder closing.");
    await page.locator("#revise-save").click();
    await expect(page.locator("#head-status")).toContainText("saved");
  });
});
