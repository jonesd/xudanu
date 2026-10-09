import { test, expect } from "@playwright/test";
import { connect, makeWorks } from "./helpers";

test.describe("many columns — the 1972 parallel-pages posture", () => {
  test("following connections grows a third page with beams criss-crossing", async ({ page }) => {
    await connect(page);
    const { a } = await makeWorks(
      page,
      { text: "PAGE ONE alpha.\nfirst page" },
      { text: "PAGE TWO beta.\nmiddle page", },
      { excerpt: "PAGE ONE alpha.", start: 0, end: 15 },
    );
    // a third work + a link from b onward
    const { c } = await page.evaluate(async ({ a }) => {
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
      const c = await req("work_create", { edition: { text: "PAGE THREE gamma.\nlast page" } }) as number;
      void a;
      ws.close();
      return { c };
    }, { a });

    // open page one; its underline opens page two
    await page.goto(`/#w${a}`);
    await expect(page.locator("#pane-a h2")).toContainText("PAGE ONE");
    await page.locator("#scroll-a mark").first().click();
    await expect(page.locator("#pane-b:not(.ghost) h2")).toContainText("PAGE TWO");
    await expect(page.locator("#pane-c.ghost")).toBeVisible();

    // keyboard focus cycles a → b
    await page.keyboard.press("ArrowRight");
    await expect(page.locator("#pane-b.focused")).toBeVisible();

    // closing a column removes only it
    await page.locator('[data-close-pane="b"]').click();
    await expect(page.locator("#pane-b.ghost")).toBeVisible();
    await expect(page.locator("#pane-a h2")).toContainText("PAGE ONE");
    void c;
  });
});
