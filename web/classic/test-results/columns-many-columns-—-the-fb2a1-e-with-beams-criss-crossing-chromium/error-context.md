# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: columns.spec.ts >> many columns — the 1972 parallel-pages posture >> following connections grows a third page with beams criss-crossing
- Location: e2e/columns.spec.ts:5:3

# Error details

```
Error: expect(locator).toContainText(expected) failed

Locator: locator('#pane-a h2')
Expected substring: "PAGE ONE"
Timeout: 10000ms
Error: element(s) not found

Call log:
  - Expect "toContainText" with timeout 10000ms
  - waiting for locator('#pane-a h2')

```

```yaml
- banner:
  - text: Xudanu classic
  - button "‹"
  - button "›"
  - button "▤ panes"
  - button "ink"
  - button "+"
  - link "workspace ↗":
    - /url: /workspace?work=0x414
  - text: Xudanu Server · v1.18.1 · api 1
- navigation:
  - textbox "search the docuverse"
  - heading "trails" [level=3]
  - link "▸ The Links Course":
    - /url: "#"
  - link "▸ The Curator's Tour":
    - /url: "#"
  - heading "docuverse" [level=3]
  - 'link "Gallery — Wing I · Room 2: The Junction Word"':
    - /url: "#"
  - link "origin page with a passage":
    - /url: "#"
  - link "Gallery Annex — The Original Pronouncement (1965)":
    - /url: "#"
  - link "Links Sandbox — Make Your Own":
    - /url: "#"
  - 'link "Gallery — The Fabric · Room 9: The Live Window"':
    - /url: "#"
  - link "Gallery Annex — The Inner Alcove":
    - /url: "#"
  - link "Gallery Annex — The Gloss":
    - /url: "#"
  - 'link "Gallery — Link Type: Gathers"':
    - /url: "#"
  - 'link "Gallery — Wing II · Room 5: A Link About a Link"':
    - /url: "#"
  - link "Links Lesson 4 — Commenting on a Connection":
    - /url: "#"
  - link "one two three four five six seven":
    - /url: "#"
  - link "Links Lesson 2 — Three Ends on One Connection":
    - /url: "#"
  - link "Gallery Annex — The Rebuttal":
    - /url: "#"
  - link "Gallery Annex — An Arrival":
    - /url: "#"
  - link "Lesson Companion":
    - /url: "#"
  - link "far end content one":
    - /url: "#"
  - link "Gallery Annex — Six Voices":
    - /url: "#"
  - link "Gallery Annex — The Counterpoint":
    - /url: "#"
  - 'link "Gallery — Lobby: The Gallery of Unusual Connections"':
    - /url: "#"
  - 'link "Gallery — Wing III · Room 6: The Rebuttal Constellation"':
    - /url: "#"
  - link "Gallery Annex — The First Echo (1974)":
    - /url: "#"
  - link "Gallery Annex — The Outer Room":
    - /url: "#"
  - link "Gallery Annex — The Margin Note":
    - /url: "#"
  - 'link "Gallery — Wing I · Room 1: The Spectrum Sentence"':
    - /url: "#"
  - link "destination page content":
    - /url: "#"
  - link "Gallery Annex — The Note on the Note":
    - /url: "#"
  - link "Links Lesson 5 — Reading the Connected Document":
    - /url: "#"
  - link "Second Companion":
    - /url: "#"
  - link "Gallery Annex — The Convergence":
    - /url: "#"
  - 'link "Gallery — Wing III · Room 7: The Five-Way Junction"':
    - /url: "#"
  - 'link "Gallery — Wing III · Room 8: The Standing Dispute"':
    - /url: "#"
  - 'link "Gallery — Wing I · Room 3: The Nested Scope"':
    - /url: "#"
  - link "Xanadu Lineage — What Xudanu Inherited, and What It Built":
    - /url: "#"
  - link "Gallery Annex — The Second Echo (1987)":
    - /url: "#"
  - link "Links Lesson 1 — The Simple Link":
    - /url: "#"
  - link "Links Lesson 3 — Gathering Passages into One End":
    - /url: "#"
  - link "Gallery Annex — The Source":
    - /url: "#"
  - link "Gallery Annex — The Context":
    - /url: "#"
  - link "Gallery Annex — The Case Against Tides":
    - /url: "#"
  - 'link "Gallery — Wing II · Room 4: Genealogy of a Quotation"':
    - /url: "#"
- main:
  - heading "PAGE ONE alpha." [level=3]
  - button "⧉"
  - button "✎"
  - button "×"
  - mark: PAGE ONE alpha.
  - text: first page
  - heading "—" [level=2]
  - paragraph: Click an underline, or search and click a result, to open a page here.
  - heading "—" [level=2]
  - paragraph: Follow another connection or search for a third page.
  - img
```

# Test source

```ts
  1  | import { test, expect } from "@playwright/test";
  2  | import { openHash, connect, makeWorks } from "./helpers";
  3  | 
  4  | test.describe("many columns — the 1972 parallel-pages posture", () => {
  5  |   test("following connections grows a third page with beams criss-crossing", async ({ page }) => {
  6  |     await connect(page);
  7  |     const { a } = await makeWorks(
  8  |       page,
  9  |       { text: "PAGE ONE alpha.\nfirst page" },
  10 |       { text: "PAGE TWO beta.\nmiddle page", },
  11 |       { excerpt: "PAGE ONE alpha.", start: 0, end: 15 },
  12 |     );
  13 |     // a third work + a link from b onward
  14 |     const { c } = await page.evaluate(async ({ a }) => {
  15 |       const ws = new WebSocket(`ws://${location.host}/xudanu?format=json&version=2`);
  16 |       await new Promise<void>((res, rej) => { ws.onopen = () => res(); ws.onerror = () => rej(new Error("ws")); });
  17 |       let id = 1;
  18 |       const pending = new Map<number, { res: (v: unknown) => void; rej: (e: Error) => void }>();
  19 |       ws.addEventListener("message", (ev) => {
  20 |         const f = JSON.parse(ev.data);
  21 |         if ((f.type === "response" || f.type === "error") && pending.has(f.id)) {
  22 |           const p = pending.get(f.id)!; pending.delete(f.id);
  23 |           f.type === "error" ? p.rej(new Error(f.message)) : p.res(f.value?.value ?? f.value);
  24 |         }
  25 |       });
  26 |       const req = (op: string, payload: Record<string, unknown> = {}) =>
  27 |         new Promise<unknown>((res, rej) => {
  28 |           const i = id++; pending.set(i, { res, rej });
  29 |           ws.send(JSON.stringify({ v: 2, type: "request", id: i, op, payload }));
  30 |           setTimeout(() => rej(new Error("timeout")), 5000);
  31 |         });
  32 |       await req("session_connect"); await req("session_login_public");
  33 |       const c = await req("work_create", { edition: { text: "PAGE THREE gamma.\nlast page" } }) as number;
  34 |       void a;
  35 |       ws.close();
  36 |       return { c };
  37 |     }, { a });
  38 | 
  39 |     // open page one; its underline opens page two
  40 |     await openHash(page, a);
> 41 |     await expect(page.locator("#pane-a h2")).toContainText("PAGE ONE");
     |                                              ^ Error: expect(locator).toContainText(expected) failed
  42 |     await page.locator("#scroll-a mark").first().click();
  43 |     await expect(page.locator("#pane-b:not(.ghost) h2")).toContainText("PAGE TWO");
  44 |     await expect(page.locator("#pane-c.ghost")).toBeVisible();
  45 | 
  46 |     // keyboard focus cycles a → b
  47 |     await page.keyboard.press("ArrowRight");
  48 |     await expect(page.locator("#pane-b.focused")).toBeVisible();
  49 | 
  50 |     // closing a column removes only it
  51 |     await page.locator('[data-close-pane="b"]').click();
  52 |     await expect(page.locator("#pane-b.ghost")).toBeVisible();
  53 |     await expect(page.locator("#pane-a h2")).toContainText("PAGE ONE");
  54 |     void c;
  55 |   });
  56 | });
  57 | 
```