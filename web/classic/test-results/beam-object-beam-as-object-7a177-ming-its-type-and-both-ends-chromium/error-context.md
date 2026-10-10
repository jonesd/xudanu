# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: beam-object.spec.ts >> beam as object — the connection line is a thing >> clicking a beam opens an inspector naming its type and both ends
- Location: e2e/beam-object.spec.ts:5:3

# Error details

```
Error: expect(locator).toContainText(expected) failed

Locator: locator('#pane-b:not(.ghost) h2')
Expected substring: "destination page"
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
    - /url: /workspace?work=0x410
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
  - heading "origin page with a passage" [level=3]
  - button "⧉"
  - button "✎"
  - button "×"
  - mark: origin page
  - text: with a passage second line
  - heading "destination page content" [level=3]
  - button "⧉"
  - button "✎"
  - button "×"
  - text: destination page content second line
  - heading "—" [level=2]
  - paragraph: Follow another connection or search for a third page.
  - img
```

# Test source

```ts
  1  | import { test, expect } from "@playwright/test";
  2  | import { openHash, connect, makeWorks } from "./helpers";
  3  | 
  4  | test.describe("beam as object — the connection line is a thing", () => {
  5  |   test("clicking a beam opens an inspector naming its type and both ends", async ({ page }) => {
  6  |     await connect(page);
  7  |     const { a } = await makeWorks(
  8  |       page,
  9  |       { text: "origin page with a passage\nsecond line" },
  10 |       { text: "destination page content\nsecond line" },
  11 |       { excerpt: "origin page", start: 0, end: 11 },
  12 |     );
  13 | 
  14 |     await openHash(page, a);
  15 |     await page.locator("#scroll-a mark").first().click();
> 16 |     await expect(page.locator("#pane-b:not(.ghost) h2")).toContainText("destination page");
     |                                                          ^ Error: expect(locator).toContainText(expected) failed
  17 |     await expect(page.locator("#beams path")).toHaveCount(2); // line + hit twin
  18 | 
  19 |     // Click the line itself (its invisible wide twin).
  20 |     await page.locator("#beams path.beam-hit").first().click();
  21 |     const panel = page.locator("#beam-panel");
  22 |     await expect(panel).toBeVisible();
  23 |     await expect(panel.locator(".bp-type")).toContainText("reference");
  24 |     await expect(panel).toContainText("origin page with a passage");
  25 |     await expect(panel).toContainText("destination page content");
  26 | 
  27 |     // closing dismisses it
  28 |     await page.locator("#beam-close").click();
  29 |     await expect(panel).toHaveCount(0);
  30 |   });
  31 | });
  32 | 
```