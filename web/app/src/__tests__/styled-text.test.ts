import { describe, it, expect } from "vitest";
import {
  extractStyleMarks,
  buildStyledText,
  getCursorOffset,
  setCaretModel,
  setCursorOffset,
  findMarkInRange,
  modelOffsetFromPoint,
  planBlockToggle,
  type StyleMark,
} from "../styled-text";

function mkMark(kind: string, start: number, end: number, id = 1): StyleMark {
  return { annotation_id: id, kind, char_start: start, char_end: end };
}

describe("extractStyleMarks", () => {
  it("filters bold and italic annotations from annotation list", () => {
    const marks = extractStyleMarks([
      { annotation_id: 1, kind: "bold", payload: "", char_start: 0, char_end: 5, created_by: null, created_by_name: null },
      { annotation_id: 2, kind: "italic", payload: "", char_start: 3, char_end: 8, created_by: null, created_by_name: null },
      { annotation_id: 3, kind: "note", payload: "a comment", char_start: 0, char_end: 5, created_by: null, created_by_name: null },
      { annotation_id: 4, kind: "highlight", payload: "", char_start: 1, char_end: 3, created_by: null, created_by_name: null },
    ]);
    expect(marks).toHaveLength(2);
    expect(marks[0].kind).toBe("bold");
    expect(marks[1].kind).toBe("italic");
  });

  it("returns empty array when no style marks", () => {
    const marks = extractStyleMarks([
      { annotation_id: 1, kind: "note", payload: "x", char_start: 0, char_end: 5, created_by: null, created_by_name: null },
    ]);
    expect(marks).toHaveLength(0);
  });

  it("returns empty array for empty input", () => {
    expect(extractStyleMarks([])).toHaveLength(0);
  });
});

describe("findMarkInRange", () => {
  const marks: StyleMark[] = [
    mkMark("bold", 0, 5, 1),
    mkMark("italic", 10, 15, 2),
  ];

  it("finds a mark that exactly matches the range", () => {
    const found = findMarkInRange(marks, "bold", 0, 5);
    expect(found?.annotation_id).toBe(1);
  });

  it("finds a mark that contains the range", () => {
    const found = findMarkInRange(marks, "bold", 1, 4);
    expect(found?.annotation_id).toBe(1);
  });

  it("finds a mark that overlaps the range", () => {
    const found = findMarkInRange(marks, "bold", 3, 8);
    expect(found?.annotation_id).toBe(1);
  });

  it("returns null when no mark matches", () => {
    expect(findMarkInRange(marks, "bold", 6, 9)).toBeNull();
  });

  it("returns null for wrong kind", () => {
    expect(findMarkInRange(marks, "italic", 0, 5)).toBeNull();
  });

  it("returns null for empty marks list", () => {
    expect(findMarkInRange([], "bold", 0, 5)).toBeNull();
  });
});

// The coordinate-space contract: model offsets must exclude visible
// bullet decorations and ZWSPs while including hidden marker syntax.
// Range.toString() includes the bullets — the class of bug that put
// link underlines mid-word and drifted the caret one char per list
// line (October 2026 session).
function buildListEditor(lines: string[]): HTMLElement {
  const el = document.createElement("div");
  document.body.appendChild(el);
  const blocks: string[] = [];
  let modelText = "";
  for (const line of lines) {
    if (line.startsWith("- ")) {
      const content = line.slice(2);
      blocks.push(
        `<span style="display:none" contenteditable="false">- </span>` +
        `<span style="display:inline-block;width:18px;user-select:none;margin-right:4px;" contenteditable="false">&bull;</span>` +
        `<span>${content}</span>`,
      );
      modelText += line + "\n";
    } else {
      blocks.push(`<span>${line}</span>`);
      modelText += line + "\n";
    }
  }
  el.innerHTML = blocks.join("\n") + "\u200B";
  (el as HTMLElement & { modelText?: string }).modelText = modelText;
  return el;
}

describe("model coordinate space (bullets, hidden markers, ZWSP)", () => {
  it("selection after N bullet lines reports the exact model offset — no +1 drift per bullet", () => {
    const el = buildListEditor(["- alpha", "- beta", "- gamma"]);
    // Content start of "gamma" includes its OWN hidden "- " marker:
    // model offset len("- alpha\n- beta\n- ") = 17. The pre-fix
    // toString() capture overcounted one per bullet ABOVE it.
    const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    let gammaNode: Text | null = null;
    let n: Node | null;
    while ((n = walker.nextNode())) {
      if (n.textContent === "gamma") { gammaNode = n as Text; break; }
    }
    expect(gammaNode).not.toBeNull();
    const off = modelOffsetFromPoint(el, gammaNode!, 0);
    expect(off).toBe("- alpha\n- beta\n- ".length);
    setCaretModel(el, off);
    expect(getCursorOffset(el)).toBe(off);
    document.body.removeChild(el);
  });

  it("caret round-trips across bullet lines and mid-word offsets", () => {
    const el = buildListEditor(["- one", "- two words here", "- three"]);
    // model: "- one\n- two words here\n- three\n"
    // content starts: 2, 9, 25; newlines at 5 and 22.
    for (const off of [2, 4, 5, 9, 22, 25, 27]) {
      setCaretModel(el, off);
      expect(getCursorOffset(el)).toBe(off);
    }
    // Offsets inside a hidden "- " marker are unrepresentable as a
    // caret — they escape FORWARD past the marker to content start.
    setCaretModel(el, 24);
    expect(getCursorOffset(el)).toBe(25);
    // Offset 0 escapes line 1's marker the same way.
    setCaretModel(el, 0);
    expect(getCursorOffset(el)).toBe(2);
    document.body.removeChild(el);
  });
});

// The block-format round trip the toolbar performs: plan an
// annotation for the line, "commit" it, then render. Proves the
// annotation path (no text marker) renders code_block/heading —
// the "codeblock ignored" bug class was the capture drift landing
// the span on the wrong line, not the renderer.
describe("block annotation round trip (planBlockToggle → extractStyleMarks → buildStyledText)", () => {
  const mkAnn = (id: number, kind: string, payload: string, s: number, e: number) => ({
    annotation_id: id, kind, payload, char_start: s, char_end: e, created_by: null, created_by_name: null,
  });

  it("code_block on a plain line renders monospace and strips nothing", () => {
    const text = "intro line\nplain code line\noutro";
    const lineStart = "intro line\n".length;
    const lineEnd = lineStart + "plain code line".length;
    const plan = planBlockToggle(lineStart, lineEnd, "code_block", "", []);
    expect(plan.create).toBeDefined();
    const anns = [mkAnn(1, "code_block", "", plan.create!.char_start, plan.create!.char_end)];
    const html = buildStyledText(text, extractStyleMarks(anns));
    expect(html).toContain("monospace");
    expect(html).toContain("plain code line");
  });

  it("code_block on a line INSIDE a bulleted doc: toolbar converts the marker (legacy path), and marker wins over stray annotations", () => {
    // The toolbar never creates a block annotation on a marker line —
    // it rewrites the prefix. "- code me" + Code → "```code me".
    const text = "- one\n- two\n```code me\n- four";
    const html = buildStyledText(text, extractStyleMarks([]));
    expect(html).toContain("monospace");
    expect(html).toContain("code me");
    expect((html.match(/&bull;/g) ?? []).length).toBe(3);
    // If an annotation DOES land on a marker line (span migration,
    // hand-edited text), the marker keeps precedence — the annotation
    // is ignored rather than double-formatting.
    const stray = buildStyledText(
      "- bullet line",
      extractStyleMarks([mkAnn(1, "code_block", "", 0, "- bullet line".length)]),
    );
    expect(stray).toContain("&bull;");
    expect(stray).not.toContain("monospace");
  });

  it("heading round trip renders size and toggling off deletes", () => {
    const text = "make me a heading";
    const plan = planBlockToggle(0, text.length, "heading", '{"level":2}', []);
    expect(plan.create).toBeDefined();
    const anns = [mkAnn(1, "heading", '{"level":2}', plan.create!.char_start, plan.create!.char_end)];
    const html = buildStyledText(text, extractStyleMarks(anns));
    expect(html).toContain("font-size:1.5em");
    const off = planBlockToggle(0, text.length, "heading", '{"level":2}', anns);
    expect(off.deleteAnnotationId).toBe(1);
    expect(off.create).toBeUndefined();
  });
});

describe("buildStyledText", () => {
  it("returns plain text when no marks", () => {
    const html = buildStyledText("Hello World", []);
    expect(html).toBe("Hello World");
  });

  it("wraps bold range in strong tags", () => {
    const html = buildStyledText("Hello World", [mkMark("bold", 0, 5)]);
    expect(html).toBe("<strong>Hello</strong> World");
  });

  it("wraps italic range in em tags", () => {
    const html = buildStyledText("Hello World", [mkMark("italic", 6, 11)]);
    expect(html).toBe("Hello <em>World</em>");
  });

  it("handles bold in the middle", () => {
    const html = buildStyledText("Hello World", [mkMark("bold", 2, 7)]);
    expect(html).toBe("He<strong>llo W</strong>orld");
  });

  it("handles multiple non-overlapping marks", () => {
    const html = buildStyledText("Hello World", [
      mkMark("bold", 0, 5, 1),
      mkMark("italic", 6, 11, 2),
    ]);
    expect(html).toBe("<strong>Hello</strong> <em>World</em>");
  });

  it("handles adjacent marks", () => {
    const html = buildStyledText("Hello World", [
      mkMark("bold", 0, 5, 1),
      mkMark("italic", 5, 11, 2),
    ]);
    expect(html).toBe("<strong>Hello</strong><em> World</em>");
  });

  it("handles overlapping bold and italic with nested tags", () => {
    const html = buildStyledText("Hello World", [
      mkMark("bold", 0, 11, 1),
      mkMark("italic", 6, 11, 2),
    ]);
    expect(html).toBe("<strong>Hello <em>World</em></strong>");
  });

  it("handles italic inside bold (different boundaries)", () => {
    const html = buildStyledText("Hello World Foo", [
      mkMark("bold", 0, 11, 1),
      mkMark("italic", 6, 15, 2),
    ]);
    expect(html).toContain("<strong>Hello ");
    expect(html).toContain("<em>");
    expect(html).toContain("</em>");
    expect(html).toContain("</strong>");
  });

  it("escapes HTML in text", () => {
    const html = buildStyledText("a < b & c", []);
    expect(html).toBe("a &lt; b &amp; c");
  });

  it("handles mark at end of text", () => {
    const html = buildStyledText("Hello World", [mkMark("bold", 6, 11)]);
    expect(html).toBe("Hello <strong>World</strong>");
  });

  it("handles mark at start of text", () => {
    const html = buildStyledText("Hello World", [mkMark("bold", 0, 5)]);
    expect(html).toBe("<strong>Hello</strong> World");
  });

  it("handles full text marked", () => {
    const html = buildStyledText("Hello", [mkMark("bold", 0, 5)]);
    expect(html).toBe("<strong>Hello</strong>");
  });

  it("handles empty text", () => {
    const html = buildStyledText("", []);
    expect(html).toBe("");
  });

  it("ignores marks outside text bounds", () => {
    const html = buildStyledText("Hello", [mkMark("bold", 10, 20)]);
    expect(html).toBe("Hello");
  });

  it("clamps marks to text bounds", () => {
    const html = buildStyledText("Hello", [mkMark("bold", 0, 100)]);
    expect(html).toBe("<strong>Hello</strong>");
  });
});

describe("getCursorOffset", () => {
  it("returns null when no selection exists (must not coerce to 0 — callers would relocate the caret)", () => {
    const el = document.createElement("div");
    expect(getCursorOffset(el)).toBeNull();
  });

  it("returns 0 when cursor is at start", () => {
    const el = document.createElement("div");
    el.textContent = "Hello";
    document.body.appendChild(el);
    const range = document.createRange();
    range.setStart(el.firstChild!, 0);
    range.collapse(true);
    const sel = window.getSelection()!;
    sel.removeAllRanges();
    sel.addRange(range);
    expect(getCursorOffset(el)).toBe(0);
    document.body.removeChild(el);
  });

  it("returns text length when cursor is at end", () => {
    const el = document.createElement("div");
    el.textContent = "Hello";
    document.body.appendChild(el);
    const range = document.createRange();
    range.setStart(el.firstChild!, 5);
    range.collapse(true);
    const sel = window.getSelection()!;
    sel.removeAllRanges();
    sel.addRange(range);
    expect(getCursorOffset(el)).toBe(5);
    document.body.removeChild(el);
  });
});

describe("setCursorOffset", () => {
  it("sets cursor at start", () => {
    const el = document.createElement("div");
    el.textContent = "Hello";
    document.body.appendChild(el);
    setCursorOffset(el, 0);
    const sel = window.getSelection()!;
    expect(sel.anchorOffset).toBe(0);
    document.body.removeChild(el);
  });

  it("sets cursor at end", () => {
    const el = document.createElement("div");
    el.textContent = "Hello";
    document.body.appendChild(el);
    setCursorOffset(el, 5);
    const sel = window.getSelection()!;
    expect(sel.anchorOffset).toBe(5);
    document.body.removeChild(el);
  });

  it("sets cursor in middle of styled text", () => {
    const el = document.createElement("div");
    el.innerHTML = "He<strong>llo</strong> World";
    document.body.appendChild(el);
    setCursorOffset(el, 4);
    const sel = window.getSelection()!;
    expect(sel.toString()).toBe("");
    expect(getCursorOffset(el)).toBe(4);
    document.body.removeChild(el);
  });
});
