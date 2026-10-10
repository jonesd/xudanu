# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: beams.spec.ts >> Pyxi panes — every shared connection drawn at once >> all links between the two open works draw beams, passage to passage
- Location: e2e/beams.spec.ts:5:3

# Error details

```
Error: expect(locator).toContainText(expected) failed

Locator: locator('#pane-b:not(.ghost) h2')
Expected substring: "far end"
Timeout: 10000ms
Error: element(s) not found

Call log:
  - Expect "toContainText" with timeout 10000ms
  - waiting for locator('#pane-b:not(.ghost) h2')

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
    - /url: /workspace?work=0x412
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
  - link "Links Lesson 2 — Three Ends on One Connection":
    - /url: "#"
  - link "Gallery Annex — The Rebuttal":
    - /url: "#"
  - link "Gallery Annex — An Arrival":
    - /url: "#"
  - link "Lesson Companion":
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
  - heading "one two three four five six seven" [level=3]
  - button "⧉"
  - button "✎"
  - button "×"
  - mark: one
  - mark: two
  - text: three
  - mark: four
  - text: five six seven second line here
  - heading "far end content one" [level=3]
  - button "⧉"
  - button "✎"
  - button "×"
  - text: far end content one far end content two far end content three
  - heading "—" [level=2]
  - paragraph: Follow another connection or search for a third page.
  - img
```

# Test source

```ts
  1  | import { test, expect } from "@playwright/test";
  2  | import { openHash, connect, makeWorks } from "./helpers";
  3  | 
  4  | test.describe("Pyxi panes — every shared connection drawn at once", () => {
  5  |   test("all links between the two open works draw beams, passage to passage", async ({ page }) => {
  6  |     await connect(page);
  7  |     // Three typed links between the same two works, different passages.
  8  |     const { a, b } = await makeWorks(
  9  |       page,
  10 |       { text: "one two three four five six seven\nsecond line here" },
  11 |       { text: "far end content one\nfar end content two\nfar end content three" },
  12 |       { excerpt: "one", start: 0, end: 3 },
  13 |     );
  14 |     await page.evaluate(async ({ a, b }) => {
  15 |       const ws = new WebSocket(`ws://${location.host}/xudanu?format=json&version=2`);
  16 |       await new Promise<void>((res, rej) => { ws.onopen = () => res(); ws.onerror = () => rej(new Error("ws")); });
  17 |       let id = 100;
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
  33 |       const ref = (s: number, e: number) => ({ kind: "single", work_context: a, original_context: null, path_context: null, excerpt: "", start_position: s, end_position: e });
  34 |       await req("link_create", { origin: a, destination: b, origin_ref: ref(4, 8), link_types: [3] });
  35 |       await req("link_create", { origin: a, destination: b, origin_ref: ref(14, 18), link_types: [4] });
  36 |       ws.close();
  37 |     }, { a, b });
  38 | 
  39 |     await openHash(page, a);
  40 |     // open the far end by clicking the first underline
  41 |     await page.locator("#scroll-a mark[data-link]").first().click();
> 42 |     await expect(page.locator("#pane-b:not(.ghost) h2")).toContainText("far end");
     |                                                          ^ Error: expect(locator).toContainText(expected) failed
  43 | 
  44 |     // Three shared links → three beams, each anchored to its own pair
  45 |     // of passages (svg paths under #beams).
  46 |     await expect(page.locator("#beams path:not(.beam-hit)")).toHaveCount(3);
  47 | 
  48 |     // paper skin renders them straight: every path is an M..L, no curves
  49 |     await page.locator("#skin-toggle").click();
  50 |     const first = await page.locator("#beams path:not(.beam-hit)").first().getAttribute("d");
  51 |     expect(first).toMatch(/^M [\d.]+ [\d.]+ L /);
  52 |   });
  53 | });
  54 | 
```