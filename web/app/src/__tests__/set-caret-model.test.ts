// @vitest-environment jsdom
import { describe, it, expect, beforeEach } from "vitest";
import { getCursorOffset, setCaretModel } from "../styled-text";

// Build the same DOM shape buildStyledText produces for list lines:
// hidden marker span (contenteditable=false) + visible bullet + text.
function buildEditor(lines: Array<{ marker?: string; text: string }>): HTMLElement {
  const el = document.createElement("div");
  el.setAttribute("contenteditable", "true");
  lines.forEach(({ marker, text }, i) => {
    if (marker) {
      const hidden = document.createElement("span");
      hidden.style.display = "none";
      hidden.setAttribute("contenteditable", "false");
      hidden.textContent = marker;
      el.appendChild(hidden);
      const bullet = document.createElement("span");
      bullet.setAttribute("contenteditable", "false");
      bullet.textContent = "\u2022";
      el.appendChild(bullet);
    }
    el.appendChild(document.createTextNode(text));
    if (i < lines.length - 1) el.appendChild(document.createTextNode("\n"));
  });
  document.body.appendChild(el);
  return el;
}

function caretInNonEditable(): boolean {
  const sel = window.getSelection();
  if (!sel || sel.rangeCount === 0) return false;
  let node: Node | null = sel.anchorNode;
  let guardian = 0;
  while (node && node !== document.body && guardian < 20) {
    const parent = node.parentElement;
    if (parent && parent.getAttribute("contenteditable") === "false") return true;
    node = parent;
    guardian++;
  }
  return false;
}

let editor: HTMLElement;
beforeEach(() => {
  document.body.innerHTML = "";
});

describe("setCaretModel", () => {
  it("places caret at a plain-text offset", () => {
    editor = buildEditor([{ text: "hello world" }]);
    setCaretModel(editor, 6);
    const sel = window.getSelection();
    expect(sel?.anchorOffset).toBe(6);
    expect(getCursorOffset(editor)).toBe(6);
  });

  it("places caret AFTER a list marker for a post-marker model offset", () => {
    editor = buildEditor([{ marker: "- ", text: "one" }]);
    // Model text is "- one": offset 3 = after "- " (marker) + 1 char in.
    setCaretModel(editor, 3);
    const sel = window.getSelection();
    expect(caretInNonEditable()).toBe(false);
    // The anchor should be in the TEXT node ("one") at index 1.
    expect(sel?.anchorNode?.nodeType).toBe(Node.TEXT_NODE);
    expect((sel?.anchorNode as Text).data).toBe("one");
    expect(sel?.anchorOffset).toBe(1);
  });

  it("never rests inside the hidden marker span even for marker-range offsets", () => {
    editor = buildEditor([{ marker: "- ", text: "one" }]);
    // Offset 1 is inside the marker — the caret must escape it
    // (landing after the marker structure), never rest inside.
    setCaretModel(editor, 1);
    expect(caretInNonEditable()).toBe(false);
  });

  it("handles multiple list lines and a following plain line", () => {
    editor = buildEditor([
      { marker: "- ", text: "one" },
      { marker: "- ", text: "two" },
      { text: "plain" },
    ]);
    // Model: "- one\n- two\nplain". Offset 8 = start of "two" text.
    setCaretModel(editor, 8);
    expect(caretInNonEditable()).toBe(false);
    const sel = window.getSelection();
    expect((sel?.anchorNode as Text)?.data).toBe("two");
    expect(sel?.anchorOffset).toBe(0);
  });

  it("offset past end anchors in the last editable text, not a marker", () => {
    editor = buildEditor([
      { text: "intro" },
      { marker: "- ", text: "last item" },
    ]);
    setCaretModel(editor, 999);
    expect(caretInNonEditable()).toBe(false);
    const sel = window.getSelection();
    expect((sel?.anchorNode as Text)?.data).toBe("last item");
  });

  it("round-trips with getCursorOffset on plain text", () => {
    editor = buildEditor([{ text: "0123456789" }]);
    for (const off of [0, 3, 7, 10]) {
      setCaretModel(editor, off);
      expect(getCursorOffset(editor)).toBe(off);
    }
  });
});
