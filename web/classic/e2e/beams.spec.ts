import { test, expect } from "@playwright/test";
import { openHash, connect, makeWorks } from "./helpers";

test.describe("Pyxi panes — every shared connection drawn at once", () => {
  test("all links between the two open works draw beams, passage to passage", async ({ page }) => {
    await connect(page);
    // Three typed links between the same two works, different passages.
    const { a, b } = await makeWorks(
      page,
      { text: "one two three four five six seven\nsecond line here" },
      { text: "far end content one\nfar end content two\nfar end content three" },
      { excerpt: "one", start: 0, end: 3 },
    );
    await page.evaluate(async ({ a, b }) => {
      const ws = new WebSocket(`ws://${location.host}/xudanu?format=json&version=2`);
      await new Promise<void>((res, rej) => { ws.onopen = () => res(); ws.onerror = () => rej(new Error("ws")); });
      let id = 100;
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
      const ref = (s: number, e: number) => ({ kind: "single", work_context: a, original_context: null, path_context: null, excerpt: "", start_position: s, end_position: e });
      await req("link_create", { origin: a, destination: b, origin_ref: ref(4, 8), link_types: [3] });
      await req("link_create", { origin: a, destination: b, origin_ref: ref(14, 18), link_types: [4] });
      ws.close();
    }, { a, b });

    await openHash(page, a);
    // open the far end by clicking the first underline
    await page.locator("#scroll-a mark[data-link]").first().click();
    await expect(page.locator("#pane-b:not(.ghost) h2")).toContainText("far end");

    // Three shared links → three beams, each anchored to its own pair
    // of passages (svg paths under #beams).
    await expect(page.locator("#beams path:not(.beam-hit)")).toHaveCount(3);

    // paper skin renders them straight: every path is an M..L, no curves
    await page.locator("#skin-toggle").click();
    const first = await page.locator("#beams path:not(.beam-hit)").first().getAttribute("d");
    expect(first).toMatch(/^M [\d.]+ [\d.]+ L /);
  });
});
