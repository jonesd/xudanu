import { describe, it, expect } from "vitest";
import {
  textToTipTapDoc,
  tiptapDocToText,
  extractAllMarks,
  diffAnnotations,
} from "../tiptap-bridge";
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

// ── Round-trip: text + annotations → TipTap doc → text + annotations ────────

describe("tiptap-bridge round-trip", () => {
  it("plain text with no annotations", () => {
    const text = "Hello world\nSecond line";
    const anns: AnnotationEntry[] = [];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    expect(result.marks).toHaveLength(0);
  });

  it("empty text", () => {
    const doc = textToTipTapDoc("", []);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe("");
  });

  it("single line", () => {
    const doc = textToTipTapDoc("hello", []);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe("hello");
  });
});

// ── Inline marks: bold, italic ──────────────────────────────────────────────

describe("tiptap-bridge inline marks", () => {
  it("bold on a range", () => {
    const text = "Hello world";
    const anns = [ann("bold", 0, 5)];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    expect(result.marks).toContainEqual({ kind: "bold", start: 0, end: 5 });
  });

  it("italic on a range", () => {
    const text = "Hello world";
    const anns = [ann("italic", 6, 11)];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    expect(result.marks).toContainEqual({ kind: "italic", start: 6, end: 11 });
  });

  it("bold and italic overlapping", () => {
    const text = "Hello brave world";
    const anns = [ann("bold", 6, 11), ann("italic", 6, 11)];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    expect(result.marks).toContainEqual({ kind: "bold", start: 6, end: 11 });
    expect(result.marks).toContainEqual({ kind: "italic", start: 6, end: 11 });
  });

  it("bold on partial word", () => {
    const text = "Hello";
    const anns = [ann("bold", 1, 3)];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    expect(result.marks).toContainEqual({ kind: "bold", start: 1, end: 3 });
  });
});

// ── Typography: font size, font family ──────────────────────────────────────

describe("tiptap-bridge typography", () => {
  it("font size on a range", () => {
    const text = "Big text";
    const anns = [ann("font_size", 0, 3, JSON.stringify({ px: 24 }))];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    const fsMark = result.marks.find((m) => m.kind === "font_size");
    expect(fsMark).toBeDefined();
    expect(fsMark!.start).toBe(0);
    expect(fsMark!.end).toBe(3);
    expect(JSON.parse(fsMark!.payload!).px).toBe(24);
  });

  it("font family on a range", () => {
    const text = "Mono text";
    const anns = [ann("font_family", 0, 4, JSON.stringify({ family: "JetBrains Mono" }))];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    const ffMark = result.marks.find((m) => m.kind === "font_family");
    expect(ffMark).toBeDefined();
    expect(JSON.parse(ffMark!.payload!).family).toBe("JetBrains Mono");
  });
});

// ── Block marks: headings, lists, blockquotes, code blocks ──────────────────

describe("tiptap-bridge block marks", () => {
  it("heading level 1", () => {
    const text = "My Title\nBody text";
    const anns = [ann("heading", 0, 8, JSON.stringify({ level: 1 }))];
    const doc = textToTipTapDoc(text, anns);
    expect(doc.content[0].type).toBe("heading");
    expect(doc.content[0].attrs?.level).toBe(1);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    const hMark = result.marks.find((m) => m.kind === "heading");
    expect(hMark).toBeDefined();
    expect(JSON.parse(hMark!.payload!).level).toBe(1);
  });

  it("heading level 2", () => {
    const text = "Section";
    const anns = [ann("heading", 0, 7, JSON.stringify({ level: 2 }))];
    const doc = textToTipTapDoc(text, anns);
    expect(doc.content[0].type).toBe("heading");
    expect(doc.content[0].attrs?.level).toBe(2);
  });

  it("bullet list with two items", () => {
    const text = "First\nSecond";
    const anns = [ann("list_item", 0, 12, JSON.stringify({ type: "bullet" }))];
    const doc = textToTipTapDoc(text, anns);
    expect(doc.content[0].type).toBe("bulletList");
    expect(doc.content[0].content).toHaveLength(2);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    const liMark = result.marks.find((m) => m.kind === "list_item");
    expect(liMark).toBeDefined();
    expect(JSON.parse(liMark!.payload!).type).toBe("bullet");
  });

  it("ordered list", () => {
    const text = "First\nSecond";
    const anns = [ann("list_item", 0, 12, JSON.stringify({ type: "ordered" }))];
    const doc = textToTipTapDoc(text, anns);
    expect(doc.content[0].type).toBe("orderedList");
  });

  it("blockquote with two lines", () => {
    const text = "Quote line 1\nQuote line 2";
    const anns = [ann("blockquote", 0, text.length)];
    const doc = textToTipTapDoc(text, anns);
    expect(doc.content[0].type).toBe("blockquote");
    expect(doc.content[0].content).toHaveLength(2);
    const result = tiptapDocToText(doc);
    const bqMarks = result.marks.filter((m) => m.kind === "blockquote");
    expect(bqMarks.length).toBeGreaterThanOrEqual(1);
    expect(bqMarks[0].start).toBe(0);
  });

  it("code block", () => {
    const text = "let x = 1;";
    const anns = [ann("code_block", 0, 10, JSON.stringify({ language: "rust" }))];
    const doc = textToTipTapDoc(text, anns);
    expect(doc.content[0].type).toBe("codeBlock");
    expect(doc.content[0].attrs?.language).toBe("rust");
  });

  it("text alignment", () => {
    const text = "Centered text";
    const anns = [ann("text_align", 0, 13, JSON.stringify({ align: "center" }))];
    const doc = textToTipTapDoc(text, anns);
    expect(doc.content[0].attrs?.textAlign).toBe("center");
    const result = tiptapDocToText(doc);
    const taMark = result.marks.find((m) => m.kind === "text_align");
    expect(taMark).toBeDefined();
    expect(JSON.parse(taMark!.payload!).align).toBe("center");
  });
});

// ── Images ──────────────────────────────────────────────────────────────────

describe("tiptap-bridge images", () => {
  it("image in the middle of text", () => {
    const text = "Before\nAfter";
    const hash = "a130d34e9f0b7a72";
    const anns = [ann("image", 6, 6, JSON.stringify({ hash }))];
    const doc = textToTipTapDoc(text, anns);
    // Find the image node
    const para1 = doc.content[0]; // "Before"
    const para2 = doc.content[1]; // "After"
    const hasImage = [para1, para2].some((p) =>
      p.content?.some((n) => n.type === "image" && (n.attrs?.src as string)?.includes(hash)),
    );
    expect(hasImage).toBe(true);
  });

  it("image at end of text", () => {
    const text = "Some text";
    const hash = "deadbeef";
    const anns = [ann("image", 9, 9, JSON.stringify({ hash }))];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    const imgMark = result.marks.find((m) => m.kind === "image");
    expect(imgMark).toBeDefined();
    expect(JSON.parse(imgMark!.payload!).hash).toBe(hash);
  });

  it("image on empty line", () => {
    const text = "Hello\n\nWorld";
    const hash = "cafe1234";
    const anns = [ann("image", 6, 6, JSON.stringify({ hash }))];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    const imgMark = result.marks.find((m) => m.kind === "image");
    expect(imgMark).toBeDefined();
    expect(imgMark!.start).toBe(6);
    expect(imgMark!.end).toBe(6);
  });

  it("multiple images", () => {
    const text = "A\nB";
    const anns = [
      ann("image", 0, 0, JSON.stringify({ hash: "aaa1" })),
      ann("image", 2, 2, JSON.stringify({ hash: "bbb2" })),
    ];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    const imgMarks = result.marks.filter((m) => m.kind === "image");
    expect(imgMarks).toHaveLength(2);
  });
});

// ── Mixed content ───────────────────────────────────────────────────────────

describe("tiptap-bridge mixed content", () => {
  it("heading + paragraph + list", () => {
    const text = "Title\nBody text\nItem 1\nItem 2";
    const anns = [
      ann("heading", 0, 5, JSON.stringify({ level: 1 })),
      ann("list_item", 14, 25, JSON.stringify({ type: "bullet" })),
    ];
    const doc = textToTipTapDoc(text, anns);
    expect(doc.content[0].type).toBe("heading");
    expect(doc.content[1].type).toBe("paragraph");
    expect(doc.content[2].type).toBe("bulletList");

    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    expect(result.marks.some((m) => m.kind === "heading")).toBe(true);
    expect(result.marks.some((m) => m.kind === "list_item")).toBe(true);
  });

  it("bold inside heading", () => {
    const text = "Important";
    const anns = [
      ann("heading", 0, 9, JSON.stringify({ level: 2 })),
      ann("bold", 0, 9),
    ];
    const doc = textToTipTapDoc(text, anns);
    expect(doc.content[0].type).toBe("heading");
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
    expect(result.marks.some((m) => m.kind === "bold")).toBe(true);
    expect(result.marks.some((m) => m.kind === "heading")).toBe(true);
  });

  it("paragraph + blockquote + paragraph", () => {
    const text = "Intro\nA quote\nOutro";
    const anns = [ann("blockquote", 6, 13)];
    const doc = textToTipTapDoc(text, anns);
    expect(doc.content[0].type).toBe("paragraph");
    expect(doc.content[1].type).toBe("blockquote");
    expect(doc.content[2].type).toBe("paragraph");
  });
});

// ── Edge cases ──────────────────────────────────────────────────────────────

describe("tiptap-bridge edge cases", () => {
  it("consecutive empty lines", () => {
    const text = "A\n\n\nB";
    const doc = textToTipTapDoc(text, []);
    expect(doc.content).toHaveLength(4);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
  });

  it("mark at exact line boundary", () => {
    const text = "Hello\nWorld";
    const anns = [ann("bold", 0, 5)];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    expect(result.marks).toContainEqual({ kind: "bold", start: 0, end: 5 });
  });

  it("mark spanning multiple lines", () => {
    const text = "Hello\nWorld";
    const anns = [ann("bold", 0, 11)];
    const doc = textToTipTapDoc(text, anns);
    const result = tiptapDocToText(doc);
    // Bold gets split at paragraph boundaries — both parts should be bold
    const boldMarks = result.marks.filter((m) => m.kind === "bold");
    expect(boldMarks.length).toBeGreaterThanOrEqual(1);
    expect(boldMarks[0].start).toBe(0);
    expect(boldMarks[0].end).toBe(5);
  });

  it("trailing newline", () => {
    const text = "Hello\n";
    const doc = textToTipTapDoc(text, []);
    expect(doc.content).toHaveLength(2);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
  });

  it("only newlines", () => {
    const text = "\n\n";
    const doc = textToTipTapDoc(text, []);
    const result = tiptapDocToText(doc);
    expect(result.text).toBe(text);
  });
});

// ── diffAnnotations ─────────────────────────────────────────────────────────

describe("diffAnnotations", () => {
  it("detects new marks to create", () => {
    const current: AnnotationEntry[] = [];
    const desired = [{ kind: "bold", start: 0, end: 5 }];
    const { toCreate, toDelete } = diffAnnotations(current, desired);
    expect(toCreate).toHaveLength(1);
    expect(toDelete).toHaveLength(0);
  });

  it("detects marks to delete", () => {
    const current = [ann("bold", 0, 5)];
    const desired: Array<{ kind: string; start: number; end: number }> = [];
    const { toCreate, toDelete } = diffAnnotations(current, desired);
    expect(toCreate).toHaveLength(0);
    expect(toDelete).toHaveLength(1);
  });

  it("no diff when marks match", () => {
    const current = [ann("bold", 0, 5)];
    const desired = [{ kind: "bold", start: 0, end: 5 }];
    const { toCreate, toDelete } = diffAnnotations(current, desired);
    expect(toCreate).toHaveLength(0);
    expect(toDelete).toHaveLength(0);
  });

  it("ignores non-style annotations", () => {
    const current = [ann("note", 0, 5, "a comment")];
    const desired: Array<{ kind: string; start: number; end: number }> = [];
    const { toDelete } = diffAnnotations(current, desired);
    expect(toDelete).toHaveLength(0);
  });
});

// ── extractAllMarks ─────────────────────────────────────────────────────────

describe("extractAllMarks", () => {
  it("filters to style marks only", () => {
    const anns = [
      ann("bold", 0, 5),
      ann("note", 0, 5, "comment"),
      ann("heading", 0, 5, JSON.stringify({ level: 1 })),
      ann("link-description", 0, 5, "desc"),
    ];
    const marks = extractAllMarks(anns);
    expect(marks).toHaveLength(2);
    expect(marks.every((m) => m.kind === "bold" || m.kind === "heading")).toBe(true);
  });

  it("includes image marks", () => {
    const anns = [ann("image", 5, 5, JSON.stringify({ hash: "abc" }))];
    const marks = extractAllMarks(anns);
    expect(marks).toHaveLength(1);
    expect(marks[0].kind).toBe("image");
  });
});
