import { test, expect, type Page } from "@playwright/test";

/** Wire-level helper: create scratch works and typed links through
 *  the same session the page uses. Returns created ids. */
export async function makeWorks(
  page: Page,
  a: { text: string },
  b: { text: string },
  link?: { excerpt: string; start: number; end: number },
): Promise<{ a: number; b: number; linkId?: number }> {
  return page.evaluate(async ({ a, b, link }) => {
    const ws = new WebSocket(`ws://${location.host}/xudanu?format=json&version=2`);
    await new Promise<void>((res, rej) => {
      ws.onopen = () => res();
      ws.onerror = () => rej(new Error("ws connect failed"));
    });
    let id = 1;
    const pending = new Map<number, { res: (v: unknown) => void; rej: (e: Error) => void }>();
    ws.addEventListener("message", (ev) => {
      const f = JSON.parse(ev.data);
      if ((f.type === "response" || f.type === "error") && pending.has(f.id)) {
        const p = pending.get(f.id)!;
        pending.delete(f.id);
        if (f.type === "error") p.rej(new Error(`${f.op}: ${f.message}`));
        else p.res(f.value?.value ?? f.value);
      }
    });
    const req = (op: string, payload: Record<string, unknown> = {}) =>
      new Promise<unknown>((res, rej) => {
        const i = id++;
        pending.set(i, { res, rej });
        ws.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload }));
        setTimeout(() => rej(new Error(`timeout: ${op}`)), 5000);
      });
    await req("session_connect");
    await req("session_login_public");
    const wa = (await req("work_create", { edition: { text: a.text } })) as number;
    const wb = (await req("work_create", { edition: { text: b.text } })) as number;
    let linkId: number | undefined;
    if (link) {
      const ref = {
        kind: "single",
        work_context: wa,
        original_context: null,
        path_context: null,
        excerpt: link.excerpt,
        start_position: link.start,
        end_position: link.end,
      };
      linkId = (await req("link_create", {
        origin: wa,
        destination: wb,
        origin_ref: ref,
        link_types: [2],
      })) as number;
    }
    ws.close();
    return { a: wa, b: wb, linkId };
  }, { a, b, link });
}

/** The classic client's connect gate. */
export async function connect(page: Page): Promise<void> {
  await page.goto("/");
  await page.getByRole("button", { name: "connect" }).click();
  await expect(page.locator("header .mark")).toContainText("Xudanu", { timeout: 15_000 });
}
