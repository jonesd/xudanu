import { test, expect } from "@playwright/test";
import { openHash, connect, makeWorks } from "./helpers";

test.describe("classic as a complete authoring loop on the shared model", () => {
  test("create → write → connect, all persisted server-side", async ({ page }) => {
    await connect(page);

    // Create the first work via + and write it with the born-editing flow.
    await page.locator("#new-work").click();
    await expect(page.locator("#revise-text")).toBeVisible();
    await page.locator("#revise-text").fill("AUTHORING LOOP A.\nThe first work, written in classic.");
    await page.locator("#revise-save").click();
    await expect(page.locator("#head-status")).toContainText("saved");
    await expect(page.locator("#scroll-a")).toContainText("AUTHORING LOOP A.");
    // Title derived from the first line.
    await expect(page.locator("#pane-a h2")).toContainText("AUTHORING LOOP A.");

    // Create a second work the same way.
    await page.locator("#new-work").click();
    await expect(page.locator("#revise-text")).toBeVisible();
    await page.locator("#revise-text").fill("AUTHORING LOOP B.\nThe second work, the far end.");
    await page.locator("#revise-save").click();
    await expect(page.locator("#pane-a h2")).toContainText("AUTHORING LOOP B.");

    // Open A again via search and link A → B through the UI.
    await page.locator("#q").fill("AUTHORING LOOP A");
    await page.keyboard.press("Enter");
    await expect(page.locator("#results a").first()).toBeVisible();
    await page.locator("#results a").first().click();
    await expect(page.locator("#pane-a h2")).toContainText("AUTHORING LOOP A.");

    // Select a passage in A and start the connection.
    await page.evaluate(() => {
      const pre = document.querySelector("#scroll-a pre");
      const walker = document.createTreeWalker(pre!, NodeFilter.SHOW_TEXT);
      walker.nextNode();
      const node = walker.currentNode;
      const r = document.createRange();
      r.setStart(node, 0);
      r.setEnd(node, 16);
      const s = window.getSelection();
      s?.removeAllRanges();
      s?.addRange(r);
    });
    await page.locator("#link-start").click();
    await expect(page.locator("#head-status")).toContainText("origin held");

    // Search for B and pick it as the far end.
    await page.locator("#q").fill("AUTHORING LOOP B");
    await page.keyboard.press("Enter");
    await expect(page.locator("#results a").first()).toBeVisible();
    await page.locator("#results a").first().click();

    // Choose the kind of connection.
    await expect(page.locator("#type-panel")).toBeVisible();
    await page.locator('button.type-pick[data-type="2"]').click();
    await expect(page.locator("#head-status")).toContainText("connection made");

    // B opened beside A with a beam between the passages.
    await expect(page.locator("#pane-b:not(.ghost) h2")).toContainText("AUTHORING LOOP B.");
    await expect(page.locator("#scroll-a mark[data-link]")).toHaveText("AUTHORING LOOP A.");
    await expect(page.locator("#beams path:not(.beam-hit)")).toHaveCount(1);
  });

  test("the switch to the modern view carries the open work", async ({ page }) => {
    await connect(page);
    const { a } = { a: await page.evaluate(async () => {
      const ws = new WebSocket(`ws://${location.host}/xudanu?format=json&version=2`);
      await new Promise<void>((r, j) => { ws.onopen = () => r(); ws.onerror = () => j(new Error("ws")); });
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
      const w = await req("work_create", { edition: { text: "SWITCH TEST WORK.\nbody" } });
      ws.close();
      return w as number;
    }) };

    await openHash(page, a);
    await expect(page.locator("#pane-a h2")).toContainText("SWITCH TEST");

    // workspace ↗ carries the work into the modern UI.
    const href = await page.locator(".head-link").getAttribute("href");
    expect(href).toMatch(/^\/workspace\?work=0x[0-9a-f]+$/);
    await page.locator(".head-link").click();
    await page.waitForURL(/\/workspace\?work=0x[0-9a-f]+/, { timeout: 20_000 });
    // The modern shell loads (its document title, not classic's).
    await expect(page).toHaveTitle(/Xudanu/, { timeout: 20_000 });
  });
});

test.describe("gather in classic", () => {
  test("selecting a passage offers gather into the existing end; the ordinal appears", async ({ page }) => {
    await connect(page);
    const TEXT = "GATHER SOURCE WORK.\nfirst passage lives here\nsecond passage also here\nthird line";
    const s1 = TEXT.indexOf("first passage");
    const s2 = TEXT.indexOf("second passage");
    const { a } = await makeWorks(
      page,
      { text: TEXT },
      { text: "far end for the gather demo" },
      { excerpt: "first passage", start: s1, end: s1 + 13 },
    );

    await openHash(page, a);
    await expect(page.locator("#pane-a h2")).toContainText("GATHER SOURCE");

    // select the SECOND passage (offsets walk the tree — the first
    // passage is already a <mark>, so text nodes are split)
    await page.evaluate(([start, end]) => {
      const pre = document.querySelector("#scroll-a pre")!;
      const walker = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT);
      const r = document.createRange();
      let pos = 0;
      let started = false;
      while (walker.nextNode()) {
        const node = walker.currentNode;
        if (!started && pos + node.length > start) {
          r.setStart(node, start - pos);
          started = true;
        }
        if (started && pos + node.length >= end) {
          r.setEnd(node, end - pos);
          break;
        }
        pos += node.length;
      }
      const s = window.getSelection();
      s?.removeAllRanges();
      s?.addRange(r);
    }, [s2, s2 + 16]);
    await page.locator("#link-start").click();
    await expect(page.locator("#head-status")).toContainText("origin held");

    // the gather panel offers the existing end
    const pick = page.locator(".gather-pick").first();
    await expect(pick).toBeVisible();
    await expect(pick).toContainText("first passage");
    await pick.click();
    await expect(page.locator("#head-status")).toContainText("gathered");

    // both passages are now underlines of ONE link; the new one carries its ordinal
    const marks = page.locator("#scroll-a mark[data-link]");
    await expect(marks).toHaveCount(2);
    const second = marks.nth(1);
    await expect(second).toHaveText(/second passage/);
    expect(await second.getAttribute("title")).toContain("gathered passage 2 of 2");
  });
});
