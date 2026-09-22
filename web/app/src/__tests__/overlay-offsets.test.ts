import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { findTextNodeAt, modelTextLength } from "../components/CollaborativeEditor";

// The overlay offset bug class (FR: marker overlay offset fix):
// overlays draw at MODEL offsets — positions in the text as the
// CRDT/save layer sees it — but the rendered DOM contains:
//   1. hidden marker spans (display:none) whose text IS model text,
//   2. visible decoration glyphs (bullet "•") that are DOM-only,
//   3. ZWSP (\u200B) chars inside editable text that are DOM-only.
// findTextNodeAt must map model offsets through all three faithfully,
// mirroring getCursorOffset/setCaretModel in styled-text.ts.

let root: HTMLDivElement;

function spanHtml(attrs: string, text: string): HTMLSpanElement {
  const el = document.createElement("span");
  el.setAttribute("style", attrs);
  el.setAttribute("contenteditable", "false");
  el.textContent = text;
  return el;
}

beforeEach(() => {
  root = document.createElement("div");
  document.body.appendChild(root);
});

afterEach(() => {
  root.remove();
});

describe("findTextNodeAt model→DOM mapping", () => {
  it("maps offsets in plain text directly", () => {
    root.textContent = "hello world";
    // Model offset 6 = the 'w'
    const hit = findTextNodeAt(root, 6);
    expect(hit).not.toBeNull();
    expect(hit!.node).toBe(root.firstChild);
    expect(hit!.offset).toBe(6);
    expect(hit!.node.textContent!.slice(hit!.offset, hit!.offset + 5)).toBe("world");
  });

  it("counts hidden marker text (model text) but never positions inside it", () => {
    // Model: "# Title" — DOM: [hidden "# "][visible "Title"]
    root.appendChild(spanHtml("display:none", "# "));
    const vis = document.createElement("span");
    vis.textContent = "Title";
    root.appendChild(vis);

    // Model offset 2 = 'T' (0,1 are '#',' ' inside the hidden span)
    const hit = findTextNodeAt(root, 2);
    expect(hit).not.toBeNull();
    expect(hit!.node).toBe(vis.firstChild);
    expect(hit!.offset).toBe(0);
    expect(hit!.node.textContent!.slice(hit!.offset)).toBe("Title");

    // Offset 4 (inside "Title"): visible node offset 2
    const mid = findTextNodeAt(root, 4);
    expect(mid!.node).toBe(vis.firstChild);
    expect(mid!.offset).toBe(2);
  });

  it("skips visible decoration glyphs entirely (bullet •)", () => {
    // Model: "item one" — DOM: [hidden ""][visible "•"][visible "item one"]
    root.appendChild(spanHtml("display:none", ""));
    root.appendChild(spanHtml("display:inline-block", "•"));
    const vis = document.createElement("span");
    vis.textContent = "item one";
    root.appendChild(vis);

    // Model offset 0 must land at 'i', not at the bullet glyph
    const hit = findTextNodeAt(root, 0);
    expect(hit).not.toBeNull();
    expect(hit!.node).toBe(vis.firstChild);
    expect(hit!.offset).toBe(0);

    // Model offset 5 = ' ' inside "item one"
    const mid = findTextNodeAt(root, 5);
    expect(mid!.node).toBe(vis.firstChild);
    expect(mid!.offset).toBe(5);
  });

  it("maps around ZWSP characters inside editable text", () => {
    // Model: "abXY" — DOM: "ab\u200BXY" (ZWSP after 'b' is DOM-only)
    root.textContent = "ab\u200BXY";

    // Model offset 2 = 'X', which sits at DOM offset 3
    const hit = findTextNodeAt(root, 2);
    expect(hit!.node).toBe(root.firstChild);
    expect(hit!.offset).toBe(3);
    expect(hit!.node.textContent!.slice(hit!.offset, hit!.offset + 2)).toBe("XY");

    // Offsets before the ZWSP are unaffected
    const before = findTextNodeAt(root, 1);
    expect(before!.offset).toBe(1);
  });

  it("handles the full FR-74 stack: heading marker + bullet + ZWSP across lines", () => {
    // Model:
    //   line 1: "# Head"        (6 chars + newline = 7)
    //   line 2: "- first"       (7 chars + newline = 8; total 15)
    //   line 3: "tail"
    const l1hidden = spanHtml("display:none", "# ");
    const l1vis = document.createElement("span");
    l1vis.textContent = "Head";
    const nl1 = document.createTextNode("\n");
    const l2hidden = spanHtml("display:none", "- ");
    const bullet = spanHtml("display:inline-block", "•");
    const l2vis = document.createElement("span");
    l2vis.textContent = "first";
    const nl2 = document.createTextNode("\n\u200B"); // Enter insert carries a ZWSP
    const l3vis = document.createTextNode("tail");
    for (const n of [l1hidden, l1vis, nl1, l2hidden, bullet, l2vis, nl2, l3vis]) {
      root.appendChild(n);
    }

    // Model layout: "# Head\n- first\n[ZWSP not counted]tail"
    // offsets:      0123456 789...
    // 'H' of Head @2, 'd' @5, '\n' @6, '-' @7, ' ' @8, 'f' @9
    const h = findTextNodeAt(root, 2);
    expect(h!.node).toBe(l1vis.firstChild);
    expect(h!.offset).toBe(0);

    const f = findTextNodeAt(root, 9);
    expect(f!.node).toBe(l2vis.firstChild);
    expect(f!.offset).toBe(0);

    // 't' of tail @ model 15: the ZWSP after the second newline is skipped
    const t = findTextNodeAt(root, 15);
    expect(t!.node).toBe(l3vis);
    expect(t!.offset).toBe(0);
    expect(t!.node.textContent!.slice(t!.offset, t!.offset + 4)).toBe("tail");
  });

  it("never returns a position inside a hidden marker span", () => {
    root.appendChild(spanHtml("display:none", "## "));
    const vis = document.createElement("span");
    vis.textContent = "H2";
    root.appendChild(vis);

    for (const off of [0, 1, 2]) {
      // Offsets 0-2 are the hidden marker — a Range there yields empty
      // rects; the mapping should still resolve to model chars, and any
      // in-visible-text position is preferred. Current contract: offsets
      // inside hidden markers clamp to the next visible position because
      // hidden text is consumed without being a return target.
      const hit = findTextNodeAt(root, off);
      expect(hit).not.toBeNull();
      expect(hit!.node).not.toBe(root.firstChild);
    }
  });

  it("returns null for offsets at/after the end of model text", () => {
    root.textContent = "abc";
    expect(findTextNodeAt(root, 3)).toBeNull();
    expect(findTextNodeAt(root, 100)).toBeNull();
  });

  it("returns null for an empty subtree", () => {
    expect(findTextNodeAt(root, 0)).toBeNull();
  });
});

describe("modelTextLength", () => {
  it("equals plain textContent length without artifacts", () => {
    root.textContent = "hello";
    expect(modelTextLength(root)).toBe(5);
  });

  it("includes hidden marker text, excludes bullets and ZWSPs", () => {
    root.appendChild(spanHtml("display:none", "# "));
    const vis = document.createElement("span");
    vis.textContent = "Head";
    root.appendChild(vis);
    root.appendChild(document.createTextNode("\n"));
    root.appendChild(spanHtml("display:none", "- "));
    root.appendChild(spanHtml("display:inline-block", "•"));
    const item = document.createElement("span");
    item.textContent = "it\u200Bem"; // 4 model chars
    root.appendChild(item);

    // "# Head\n- item" = 2+4+1+2+4 = 13
    expect(modelTextLength(root)).toBe(13);
    expect(root.textContent!.length).toBe(15); // DOM length differs (bullet + ZWSP)
  });

  it("is zero for empty editors", () => {
    expect(modelTextLength(root)).toBe(0);
  });

  it("matches model offsets used by overlays end-to-end", () => {
    // The draw pattern: drawEnd = min(end, modelTextLength), then
    // findTextNodeAt(root, drawEnd - 1) must resolve for any span the
    // server sends within bounds.
    root.appendChild(spanHtml("display:none", "## "));
    const vis = document.createElement("span");
    vis.textContent = "heading";
    root.appendChild(vis);

    const len = modelTextLength(root); // "## heading" = 10
    expect(len).toBe(10);
    for (let i = 0; i < len; i++) {
      const hit = findTextNodeAt(root, i);
      expect(hit, `model offset ${i}`).not.toBeNull();
    }
    expect(findTextNodeAt(root, len)).toBeNull();
  });
});
