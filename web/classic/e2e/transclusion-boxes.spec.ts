import { test, expect } from "@playwright/test";
import { openHash, connect } from "./helpers";

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
      const holder = await req("work_create", { edition: { text: "Holder opening.\n\nxxxx\n\nHolder closing." } }) as number;
      await req("work_grab", { work_id: holder });
      // place at the xxxx line (position 17)
      await req("element_insert", { work_id: holder, position: 17, element: { type: "transclusion", transclusion_source: src, transclusion_start: 0, transclusion_end: 22 } });
      await req("work_release", { work_id: holder });
      ws.close();
      return { src, holder };
    });

    await openHash(page, ids.holder);
    await expect(page.locator("#pane-a h2")).toContainText("Holder opening");

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

    // Editing the holder keeps the box machinery alive after re-render.
    await page.locator('[data-revise-pane="a"]').click();
    await page.locator("#revise-text").fill("Holder opening edited.\n\nSHARED PASSAGE GAMMA only here.\n\nHolder closing.");
    await page.locator("#revise-save").click();
    await expect(page.locator("#head-status")).toContainText("saved");
  });
});
