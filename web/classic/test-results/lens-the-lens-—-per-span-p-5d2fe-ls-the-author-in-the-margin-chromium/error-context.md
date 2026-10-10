# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: lens.spec.ts >> the lens — per-span provenance on hover >> hovering a passage reveals the author in the margin
- Location: e2e/lens.spec.ts:5:3

# Error details

```
Error: expect(locator).toContainText(expected) failed

Locator: locator('#pane-a h2')
Expected substring: "LENS TEST"
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
    - /url: /workspace?work=0x418
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
  - link "PAGE TWO beta.":
    - /url: "#"
  - link "PAGE THREE gamma.":
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
  - link "PAGE ONE alpha.":
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
- main:
  - heading "LENS TEST WORK." [level=3]
  - button "⧉"
  - button "✎"
  - button "×"
  - mark: LENS TEST
  - text: WORK. This passage has provenance attached to it.
  - heading "—" [level=2]
  - paragraph: Click an underline, or search and click a result, to open a page here.
  - heading "—" [level=2]
  - paragraph: Follow another connection or search for a third page.
  - img
```

# Test source

```ts
  1  | import { test, expect } from "@playwright/test";
  2  | import { connect, makeWorks } from "./helpers";
  3  | 
  4  | test.describe("the lens — per-span provenance on hover", () => {
  5  |   test("hovering a passage reveals the author in the margin", async ({ page }) => {
  6  |     await connect(page);
  7  |     const { a } = await makeWorks(
  8  |       page,
  9  |       { text: "LENS TEST WORK.\nThis passage has provenance attached to it." },
  10 |       { text: "far end" },
  11 |       { excerpt: "LENS TEST", start: 0, end: 9 },
  12 |     );
  13 | 
  14 |     await page.goto(`/#w${a}`);
> 15 |     await expect(page.locator("#pane-a h2")).toContainText("LENS TEST");
     |                                              ^ Error: expect(locator).toContainText(expected) failed
  16 | 
  17 |     // hover the first line of text — the lens should appear
  18 |     const pre = page.locator("#scroll-a pre");
  19 |     await pre.hover({ position: { x: 40, y: 20 } });
  20 |     await page.waitForTimeout(400);
  21 |     const note = page.locator(".lens-note");
  22 |     // The note appears (may be "public" for a public-session work, or
  23 |     // "admin" — the assertion is that SOME author marginalia shows)
  24 |     const count = await note.count();
  25 |     expect(count === 0 || count === 1).toBe(true);
  26 |     if (count === 1) {
  27 |       const text = await note.textContent();
  28 |       expect(text).toMatch(/[✓◐?]/);
  29 |     }
  30 |   });
  31 | });
  32 | 
```