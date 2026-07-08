import { describe, it, expect } from "vitest";
import {
  extractStyleMarks,
  buildStyledText,
  getCursorOffset,
  setCursorOffset,
  findMarkInRange,
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
  it("returns 0 for empty element", () => {
    const el = document.createElement("div");
    expect(getCursorOffset(el)).toBe(0);
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
