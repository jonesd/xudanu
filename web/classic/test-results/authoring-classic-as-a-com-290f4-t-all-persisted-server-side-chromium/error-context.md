# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: authoring.spec.ts >> classic as a complete authoring loop on the shared model >> create → write → connect, all persisted server-side
- Location: e2e/authoring.spec.ts:5:3

# Error details

```
Error: expect(locator).toHaveText(expected) failed

Locator:  locator('#scroll-a mark[data-link]')
Expected: "AUTHORING LOOP A."
Received: "AUTHORING LOOP A"
Timeout:  10000ms

Call log:
  - Expect "toHaveText" with timeout 10000ms
  - waiting for locator('#scroll-a mark[data-link]')
    24 × locator resolved to <mark data-link="60" title="reference → AUTHORING LOOP B.">AUTHORING LOOP A</mark>
       - unexpected value "AUTHORING LOOP A"

```

```yaml
- mark: AUTHORING LOOP A
```

# Test source

```ts
  1   | import { test, expect } from "@playwright/test";
  2   | import { openHash, connect, makeWorks } from "./helpers";
  3   | 
  4   | test.describe("classic as a complete authoring loop on the shared model", () => {
  5   |   test("create → write → connect, all persisted server-side", async ({ page }) => {
  6   |     await connect(page);
  7   | 
  8   |     // Create the first work via + and write it with the born-editing flow.
  9   |     await page.locator("#new-work").click();
  10  |     await expect(page.locator("#revise-text")).toBeVisible();
  11  |     await page.locator("#revise-text").fill("AUTHORING LOOP A.\nThe first work, written in classic.");
  12  |     await page.locator("#revise-save").click();
  13  |     await expect(page.locator("#head-status")).toContainText("saved");
  14  |     await expect(page.locator("#scroll-a")).toContainText("AUTHORING LOOP A.");
  15  |     // Title derived from the first line.
  16  |     await expect(page.locator("#pane-a h2")).toContainText("AUTHORING LOOP A.");
  17  | 
  18  |     // Create a second work the same way.
  19  |     await page.locator("#new-work").click();
  20  |     await expect(page.locator("#revise-text")).toBeVisible();
  21  |     await page.locator("#revise-text").fill("AUTHORING LOOP B.\nThe second work, the far end.");
  22  |     await page.locator("#revise-save").click();
  23  |     await expect(page.locator("#pane-a h2")).toContainText("AUTHORING LOOP B.");
  24  | 
  25  |     // Open A again via search and link A → B through the UI.
  26  |     await page.locator("#q").fill("AUTHORING LOOP A");
  27  |     await page.keyboard.press("Enter");
  28  |     await expect(page.locator("#results a").first()).toBeVisible();
  29  |     await page.locator("#results a").first().click();
  30  |     await expect(page.locator("#pane-a h2")).toContainText("AUTHORING LOOP A.");
  31  | 
  32  |     // Select a passage in A and start the connection.
  33  |     await page.evaluate(() => {
  34  |       const pre = document.querySelector("#scroll-a pre");
  35  |       const walker = document.createTreeWalker(pre!, NodeFilter.SHOW_TEXT);
  36  |       walker.nextNode();
  37  |       const node = walker.currentNode;
  38  |       const r = document.createRange();
  39  |       r.setStart(node, 0);
  40  |       r.setEnd(node, 16);
  41  |       const s = window.getSelection();
  42  |       s?.removeAllRanges();
  43  |       s?.addRange(r);
  44  |     });
  45  |     await page.locator("#link-start").click();
  46  |     await expect(page.locator("#head-status")).toContainText("origin held");
  47  | 
  48  |     // Search for B and pick it as the far end.
  49  |     await page.locator("#q").fill("AUTHORING LOOP B");
  50  |     await page.keyboard.press("Enter");
  51  |     await expect(page.locator("#results a").first()).toBeVisible();
  52  |     await page.locator("#results a").first().click();
  53  | 
  54  |     // Choose the kind of connection.
  55  |     await expect(page.locator("#type-panel")).toBeVisible();
  56  |     await page.locator('button.type-pick[data-type="2"]').click();
  57  |     await expect(page.locator("#head-status")).toContainText("connection made");
  58  | 
  59  |     // B opened beside A with a beam between the passages.
  60  |     await expect(page.locator("#pane-b:not(.ghost) h2")).toContainText("AUTHORING LOOP B.");
> 61  |     await expect(page.locator("#scroll-a mark[data-link]")).toHaveText("AUTHORING LOOP A.");
      |                                                             ^ Error: expect(locator).toHaveText(expected) failed
  62  |     await expect(page.locator("#beams path:not(.beam-hit)")).toHaveCount(1);
  63  |   });
  64  | 
  65  |   test("the switch to the modern view carries the open work", async ({ page }) => {
  66  |     await connect(page);
  67  |     const { a } = { a: await page.evaluate(async () => {
  68  |       const ws = new WebSocket(`ws://${location.host}/xudanu?format=json&version=2`);
  69  |       await new Promise<void>((r, j) => { ws.onopen = () => r(); ws.onerror = () => j(new Error("ws")); });
  70  |       let id = 1;
  71  |       const pending = new Map<number, { res: (v: unknown) => void; rej: (e: Error) => void }>();
  72  |       ws.addEventListener("message", (ev) => {
  73  |         const f = JSON.parse(ev.data);
  74  |         if ((f.type === "response" || f.type === "error") && pending.has(f.id)) {
  75  |           const p = pending.get(f.id)!; pending.delete(f.id);
  76  |           f.type === "error" ? p.rej(new Error(f.message)) : p.res(f.value?.value ?? f.value);
  77  |         }
  78  |       });
  79  |       const req = (op: string, payload: Record<string, unknown> = {}) =>
  80  |         new Promise<unknown>((res, rej) => {
  81  |           const i = id++; pending.set(i, { res, rej });
  82  |           ws.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload }));
  83  |           setTimeout(() => rej(new Error("timeout")), 5000);
  84  |         });
  85  |       await req("session_connect"); await req("session_login_public");
  86  |       const w = await req("work_create", { edition: { text: "SWITCH TEST WORK.\nbody" } });
  87  |       ws.close();
  88  |       return w as number;
  89  |     }) };
  90  | 
  91  |     await openHash(page, a);
  92  |     await expect(page.locator("#pane-a h2")).toContainText("SWITCH TEST");
  93  | 
  94  |     // workspace ↗ carries the work into the modern UI.
  95  |     const href = await page.locator(".head-link").getAttribute("href");
  96  |     expect(href).toMatch(/^\/workspace\?work=0x[0-9a-f]+$/);
  97  |     await page.locator(".head-link").click();
  98  |     await page.waitForURL(/\/workspace\?work=0x[0-9a-f]+/, { timeout: 20_000 });
  99  |     // The modern shell loads (its document title, not classic's).
  100 |     await expect(page).toHaveTitle(/Xudanu/, { timeout: 20_000 });
  101 |   });
  102 | });
  103 | 
  104 | test.describe("gather in classic", () => {
  105 |   test("selecting a passage offers gather into the existing end; the ordinal appears", async ({ page }) => {
  106 |     await connect(page);
  107 |     const TEXT = "GATHER SOURCE WORK.\nfirst passage lives here\nsecond passage also here\nthird line";
  108 |     const s1 = TEXT.indexOf("first passage");
  109 |     const s2 = TEXT.indexOf("second passage");
  110 |     const { a } = await makeWorks(
  111 |       page,
  112 |       { text: TEXT },
  113 |       { text: "far end for the gather demo" },
  114 |       { excerpt: "first passage", start: s1, end: s1 + 13 },
  115 |     );
  116 | 
  117 |     await openHash(page, a);
  118 |     await expect(page.locator("#pane-a h2")).toContainText("GATHER SOURCE");
  119 | 
  120 |     // select the SECOND passage (offsets walk the tree — the first
  121 |     // passage is already a <mark>, so text nodes are split)
  122 |     await page.evaluate(([start, end]) => {
  123 |       const pre = document.querySelector("#scroll-a pre")!;
  124 |       const walker = document.createTreeWalker(pre, NodeFilter.SHOW_TEXT);
  125 |       const r = document.createRange();
  126 |       let pos = 0;
  127 |       let started = false;
  128 |       while (walker.nextNode()) {
  129 |         const node = walker.currentNode;
  130 |         if (!started && pos + node.length > start) {
  131 |           r.setStart(node, start - pos);
  132 |           started = true;
  133 |         }
  134 |         if (started && pos + node.length >= end) {
  135 |           r.setEnd(node, end - pos);
  136 |           break;
  137 |         }
  138 |         pos += node.length;
  139 |       }
  140 |       const s = window.getSelection();
  141 |       s?.removeAllRanges();
  142 |       s?.addRange(r);
  143 |     }, [s2, s2 + 16]);
  144 |     await page.locator("#link-start").click();
  145 |     await expect(page.locator("#head-status")).toContainText("origin held");
  146 | 
  147 |     // the gather panel offers the existing end
  148 |     const pick = page.locator(".gather-pick").first();
  149 |     await expect(pick).toBeVisible();
  150 |     await expect(pick).toContainText("first passage");
  151 |     await pick.click();
  152 |     await expect(page.locator("#head-status")).toContainText("gathered");
  153 | 
  154 |     // both passages are now underlines of ONE link; the new one carries its ordinal
  155 |     const marks = page.locator("#scroll-a mark[data-link]");
  156 |     await expect(marks).toHaveCount(2);
  157 |     const second = marks.nth(1);
  158 |     await expect(second).toHaveText(/second passage/);
  159 |     expect(await second.getAttribute("title")).toContain("gathered passage 2 of 2");
  160 |   });
  161 | });
```