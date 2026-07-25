import { describe, it, expect } from "vitest";
import {
  buildStyledText,
  extractStyleMarks,
  findMarkInRange,
  type StyleMark,
} from "../styled-text";
import type { AnnotationEntry } from "../api/crdt_sync";

function ann(kind: string, start: number, end: number, payload?: string): AnnotationEntry {
  return {
    annotation_id: Math.floor(Math.random() * 1e9),
    kind,
    payload: payload || "",
    char_start: start,
    char_end: end,
    created_by: 0,
    created_by_name: "",
    is_private: false,
  };
}

function mark(kind: string, start: number, end: number, payload?: string): StyleMark {
  return { annotation_id: 1, kind, char_start: start, char_end: end, ...(payload ? { payload } : {}) };
}

// ── extractStyleMarks ──────────────────────────────────────────────────────

describe("extractStyleMarks", () => {
  it("extracts inline marks (bold, italic)", () => {
    const anns = [ann("bold", 0, 5), ann("italic", 6, 10)];
    const marks = extractStyleMarks(anns);
    expect(marks).toHaveLength(2);
    expect(marks[0].kind).toBe("bold");
    expect(marks[1].kind).toBe("italic");
  });

  it("extracts block marks (heading, list_item, blockquote, code_block)", () => {
    const anns = [
      ann("heading", 0, 5, JSON.stringify({ level: 1 })),
      ann("list_item", 6, 10, JSON.stringify({ type: "bullet" })),
      ann("blockquote", 11, 20),
      ann("code_block", 21, 30),
    ];
    const marks = extractStyleMarks(anns);
    expect(marks).toHaveLength(4);
    expect(marks.map((m) => m.kind)).toEqual(["heading", "list_item", "blockquote", "code_block"]);
  });

  it("includes payload for block marks", () => {
    const anns = [ann("heading", 0, 5, JSON.stringify({ level: 2 }))];
    const marks = extractStyleMarks(anns);
    expect(marks[0].payload).toBe(JSON.stringify({ level: 2 }));
  });

  it("filters out non-style annotations", () => {
    const anns = [ann("note", 0, 5, "a comment"), ann("bold", 0, 5)];
    const marks = extractStyleMarks(anns);
    expect(marks).toHaveLength(1);
    expect(marks[0].kind).toBe("bold");
  });
});

// ── findMarkInRange ────────────────────────────────────────────────────────

describe("findMarkInRange", () => {
  it("finds overlapping mark", () => {
    const marks = [mark("bold", 5, 10)];
    expect(findMarkInRange(marks, "bold", 3, 7)).not.toBeNull();
  });

  it("returns null for non-overlapping", () => {
    const marks = [mark("bold", 0, 5)];
    expect(findMarkInRange(marks, "bold", 6, 10)).toBeNull();
  });
});

// ── buildStyledText: inline marks (original behavior) ─────────────────────

describe("buildStyledText inline marks", () => {
  it("plain text with no marks", () => {
    expect(buildStyledText("hello world", [])).toBe("hello world");
  });

  it("bold mark", () => {
    const result = buildStyledText("hello world", [mark("bold", 0, 5)]);
    expect(result).toContain("<strong>hello</strong>");
    expect(result).toContain("world");
  });

  it("italic mark", () => {
    const result = buildStyledText("hello world", [mark("italic", 6, 11)]);
    expect(result).toContain("<em>world</em>");
  });

  it("overlapping bold and italic", () => {
    const result = buildStyledText("hello", [mark("bold", 0, 5), mark("italic", 0, 5)]);
    expect(result).toContain("<strong>");
    expect(result).toContain("<em>");
  });

  it("escapes HTML in text", () => {
    const result = buildStyledText("a < b", []);
    expect(result).toBe("a &lt; b");
  });

  it("empty text", () => {
    expect(buildStyledText("", [mark("bold", 0, 5)])).toBe("");
  });
});

// ── buildStyledText: block marks (headings) ───────────────────────────────

describe("buildStyledText headings", () => {
  it("heading level 1", () => {
    const result = buildStyledText("Title", [mark("heading", 0, 5, JSON.stringify({ level: 1 }))]);
    expect(result).toContain("<h1>Title</h1>");
  });

  it("heading level 2", () => {
    const result = buildStyledText("Section", [mark("heading", 0, 7, JSON.stringify({ level: 2 }))]);
    expect(result).toContain("<h2>Section</h2>");
  });

  it("heading level 3", () => {
    const result = buildStyledText("Sub", [mark("heading", 0, 3, JSON.stringify({ level: 3 }))]);
    expect(result).toContain("<h3>Sub</h3>");
  });

  it("heading defaults to level 1 without payload", () => {
    const result = buildStyledText("Title", [mark("heading", 0, 5)]);
    expect(result).toContain("<h1>");
  });

  it("heading with following paragraph", () => {
    const text = "Title\nBody text";
    const marks = [mark("heading", 0, 5, JSON.stringify({ level: 1 }))];
    const result = buildStyledText(text, marks);
    expect(result).toContain("<h1>Title</h1>");
    expect(result).toContain("<p>Body text</p>");
  });
});

// ── buildStyledText: lists ────────────────────────────────────────────────

describe("buildStyledText lists", () => {
  it("single bullet item", () => {
    const result = buildStyledText("Item", [mark("list_item", 0, 4, JSON.stringify({ type: "bullet" }))]);
    expect(result).toContain("<ul>");
    expect(result).toContain("<li>Item</li>");
    expect(result).toContain("</ul>");
  });

  it("multiple bullet items", () => {
    const text = "First\nSecond";
    const marks = [mark("list_item", 0, text.length, JSON.stringify({ type: "bullet" }))];
    const result = buildStyledText(text, marks);
    expect(result).toContain("<ul>");
    expect(result).toContain("<li>First</li>");
    expect(result).toContain("<li>Second</li>");
    expect(result).toContain("</ul>");
    expect(result.match(/<ul>/g)).toHaveLength(1);
    expect(result.match(/<\/ul>/g)).toHaveLength(1);
  });

  it("ordered list", () => {
    const text = "First\nSecond";
    const marks = [mark("list_item", 0, text.length, JSON.stringify({ type: "ordered" }))];
    const result = buildStyledText(text, marks);
    expect(result).toContain("<ol>");
    expect(result).toContain("</ol>");
  });

  it("list followed by paragraph", () => {
    const text = "Item\nAfter";
    const marks = [mark("list_item", 0, 4, JSON.stringify({ type: "bullet" }))];
    const result = buildStyledText(text, marks);
    expect(result).toContain("</ul>");
    expect(result).toContain("<p>After</p>");
  });
});

// ── buildStyledText: blockquotes ──────────────────────────────────────────

describe("buildStyledText blockquotes", () => {
  it("single blockquote line", () => {
    const result = buildStyledText("A quote", [mark("blockquote", 0, 7)]);
    expect(result).toContain("<blockquote>A quote</blockquote>");
  });

  it("blockquote followed by paragraph", () => {
    const text = "Quote\nNormal";
    const marks = [mark("blockquote", 0, 5)];
    const result = buildStyledText(text, marks);
    expect(result).toContain("<blockquote>Quote</blockquote>");
    expect(result).toContain("<p>Normal</p>");
  });
});

// ── buildStyledText: code blocks ──────────────────────────────────────────

describe("buildStyledText code blocks", () => {
  it("single code block", () => {
    const result = buildStyledText("let x = 1;", [mark("code_block", 0, 10)]);
    expect(result).toContain("<pre><code>");
    expect(result).toContain("let x = 1;");
    expect(result).toContain("</code></pre>");
  });

  it("code block escapes HTML", () => {
    const result = buildStyledText("a < b", [mark("code_block", 0, 5)]);
    expect(result).toContain("&lt;");
  });
});

// ── buildStyledText: mixed content ────────────────────────────────────────

describe("buildStyledText mixed content", () => {
  it("heading + paragraph + list", () => {
    const text = "Title\nBody\nItem 1\nItem 2";
    const marks = [
      mark("heading", 0, 5, JSON.stringify({ level: 1 })),
      mark("list_item", 12, 23, JSON.stringify({ type: "bullet" })),
    ];
    const result = buildStyledText(text, marks);
    expect(result).toContain("<h1>Title</h1>");
    expect(result).toContain("<p>Body</p>");
    expect(result).toContain("<ul>");
    expect(result).toContain("<li>Item 1</li>");
    expect(result).toContain("<li>Item 2</li>");
  });

  it("bold inside heading", () => {
    const text = "Title";
    const marks = [
      mark("heading", 0, 5, JSON.stringify({ level: 1 })),
      mark("bold", 0, 5),
    ];
    const result = buildStyledText(text, marks);
    expect(result).toContain("<h1>");
    expect(result).toContain("<strong>Title</strong>");
  });

  it("bold inside list item", () => {
    const text = "Important";
    const marks = [
      mark("list_item", 0, 9, JSON.stringify({ type: "bullet" })),
      mark("bold", 0, 9),
    ];
    const result = buildStyledText(text, marks);
    expect(result).toContain("<li>");
    expect(result).toContain("<strong>Important</strong>");
  });

  it("paragraphs without any block marks", () => {
    const text = "Line one\nLine two\nLine three";
    const result = buildStyledText(text, []);
    // No block marks → original behavior (just escaped text, no <p> tags)
    expect(result).toBe("Line one\nLine two\nLine three");
  });
});

// ── List auto-continuation logic ──────────────────────────────────────────

describe("list auto-continuation logic", () => {
  // Extract the core logic as a pure function for testing
  function shouldContinueList(
    newText: string,
    prevText: string,
    cursorIdx: number,
    annotations: Array<{ kind: string; char_start: number; char_end: number }>,
  ): { action: "create" | "exit" | "none"; lineStart?: number; lineEnd?: number; payload?: string } {
    if (newText.length <= prevText.length || !newText.includes("\n")) {
      return { action: "none" };
    }
    const lineStart = newText.lastIndexOf("\n", cursorIdx - 1) + 1;
    const prevLineEnd = lineStart - 1;
    const prevLineStart = newText.lastIndexOf("\n", prevLineEnd - 1) + 1;
    if (prevLineStart < 0 || prevLineEnd <= prevLineStart) return { action: "none" };

    const prevLineIsListItem = annotations.some(
      (a) => a.kind === "list_item" && a.char_start < prevLineEnd && a.char_end > prevLineStart,
    );
    if (!prevLineIsListItem) return { action: "none" };

    const newLineText = newText.slice(lineStart).split("\n")[0];
    const newLineEnd = lineStart + newLineText.length;

    if (newLineText.length === 0) return { action: "exit" };
    return { action: "create", lineStart, lineEnd: newLineEnd, payload: JSON.stringify({ type: "bullet" }) };
  }

  it("continues list when Enter pressed with text on new line", () => {
    const prev = "First item";
    const newText = "First item\nSecond";
    const annotations = [{ kind: "list_item", char_start: 0, char_end: 10 }];
    const result = shouldContinueList(newText, prev, 17, annotations);
    expect(result.action).toBe("create");
    expect(result.lineStart).toBe(11);
    expect(result.lineEnd).toBe(17);
  });

  it("exits list when Enter pressed on empty new line", () => {
    const prev = "First item";
    const newText = "First item\n";
    const annotations = [{ kind: "list_item", char_start: 0, char_end: 10 }];
    const result = shouldContinueList(newText, prev, 11, annotations);
    expect(result.action).toBe("exit");
  });

  it("does nothing when previous line is not a list item", () => {
    const prev = "Normal text";
    const newText = "Normal text\nNew line";
    const annotations: Array<{ kind: string; char_start: number; char_end: number }> = [];
    const result = shouldContinueList(newText, prev, 20, annotations);
    expect(result.action).toBe("none");
  });

  it("does nothing when text was deleted (not Enter)", () => {
    const prev = "First item\nSecond";
    const newText = "First item";
    const annotations = [{ kind: "list_item", char_start: 0, char_end: 10 }];
    const result = shouldContinueList(newText, prev, 10, annotations);
    expect(result.action).toBe("none");
  });

  it("continues after second item for third item", () => {
    const prev = "First\nSecond";
    const newText = "First\nSecond\nThird";
    const annotations = [
      { kind: "list_item", char_start: 0, char_end: 5 },
      { kind: "list_item", char_start: 6, char_end: 12 },
    ];
    const result = shouldContinueList(newText, prev, 18, annotations);
    expect(result.action).toBe("create");
    expect(result.lineStart).toBe(13);
  });
});
