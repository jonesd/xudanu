import { describe, it, expect } from "vitest";
import { TextBuffer } from "../api/text_buffer";

describe("TextBuffer", () => {
  describe("constructor and basic accessors", () => {
    it("builds line offsets from text", () => {
      const buf = new TextBuffer("hello\nworld\n");
      expect(buf.getLineCount()).toBe(3);
      expect(buf.getText()).toBe("hello\nworld\n");
    });

    it("handles empty text", () => {
      const buf = new TextBuffer("");
      expect(buf.getLineCount()).toBe(1);
      expect(buf.charCount()).toBe(0);
    });

    it("handles single line with no newline", () => {
      const buf = new TextBuffer("hello");
      expect(buf.getLineCount()).toBe(1);
    });

    it("handles trailing newlines", () => {
      const buf = new TextBuffer("a\nb\nc\n");
      expect(buf.getLineCount()).toBe(4);
      expect(buf.getLine(3)).toBe("");
    });
  });

  describe("getLine", () => {
    it("returns content of each line", () => {
      const buf = new TextBuffer("alpha\nbeta\ngamma");
      expect(buf.getLine(0)).toBe("alpha");
      expect(buf.getLine(1)).toBe("beta");
      expect(buf.getLine(2)).toBe("gamma");
    });

    it("returns empty for out-of-bounds", () => {
      const buf = new TextBuffer("hello");
      expect(buf.getLine(-1)).toBe("");
      expect(buf.getLine(5)).toBe("");
    });

    it("handles trailing newline line as empty", () => {
      const buf = new TextBuffer("hello\n");
      expect(buf.getLine(0)).toBe("hello");
      expect(buf.getLine(1)).toBe("");
    });
  });

  describe("getLineForChar", () => {
    it("finds the correct line for a char offset", () => {
      const buf = new TextBuffer("hello\nworld\ntest");
      expect(buf.getLineForChar(0)).toBe(0);
      expect(buf.getLineForChar(4)).toBe(0);
      expect(buf.getLineForChar(5)).toBe(0);
      expect(buf.getLineForChar(6)).toBe(1);
      expect(buf.getLineForChar(11)).toBe(1);
      expect(buf.getLineForChar(12)).toBe(2);
    });

    it("handles offset 0", () => {
      const buf = new TextBuffer("abc\ndef");
      expect(buf.getLineForChar(0)).toBe(0);
    });

    it("handles single-line text", () => {
      const buf = new TextBuffer("abcdef");
      expect(buf.getLineForChar(3)).toBe(0);
    });

    it("handles very large offset", () => {
      const buf = new TextBuffer("ab\ncd");
      expect(buf.getLineForChar(9999)).toBe(1);
    });
  });

  describe("getCharOffset", () => {
    it("returns char offset for a given line", () => {
      const buf = new TextBuffer("hello\nworld\ntest");
      expect(buf.getCharOffset(0)).toBe(0);
      expect(buf.getCharOffset(1)).toBe(6);
      expect(buf.getCharOffset(2)).toBe(12);
    });

    it("clamps out-of-bounds", () => {
      const buf = new TextBuffer("abc\ndef");
      expect(buf.getCharOffset(-1)).toBe(0);
      expect(buf.getCharOffset(99)).toBe(7);
    });
  });

  describe("getTextRange", () => {
    it("extracts a substring", () => {
      const buf = new TextBuffer("hello world");
      expect(buf.getTextRange(0, 5)).toBe("hello");
      expect(buf.getTextRange(6, 11)).toBe("world");
    });
  });

  describe("getLinesRange", () => {
    it("extracts text spanning multiple lines", () => {
      const buf = new TextBuffer("aaa\nbbb\nccc\nddd");
      expect(buf.getLinesRange(0, 2)).toBe("aaa\nbbb\n");
      expect(buf.getLinesRange(1, 3)).toBe("bbb\nccc\n");
    });
  });

  describe("applyDelta", () => {
    it("applies an insert-only delta", () => {
      const buf = new TextBuffer("Hello");
      buf.applyDelta([
        { type: "retain", count: 5 },
        { type: "insert", text: " World" },
      ]);
      expect(buf.getText()).toBe("Hello World");
    });

    it("applies a delete delta", () => {
      const buf = new TextBuffer("Hello World");
      buf.applyDelta([
        { type: "retain", count: 5 },
        { type: "delete", count: 6 },
      ]);
      expect(buf.getText()).toBe("Hello");
    });

    it("applies a replace delta", () => {
      const buf = new TextBuffer("Hello World");
      buf.applyDelta([
        { type: "retain", count: 6 },
        { type: "delete", count: 5 },
        { type: "insert", text: "There" },
      ]);
      expect(buf.getText()).toBe("Hello There");
    });

    it("applies an insert at the beginning", () => {
      const buf = new TextBuffer("world");
      buf.applyDelta([
        { type: "insert", text: "hello " },
        { type: "retain", count: 5 },
      ]);
      expect(buf.getText()).toBe("hello world");
    });

    it("throws on retain out of bounds", () => {
      const buf = new TextBuffer("abc");
      expect(() => buf.applyDelta([{ type: "retain", count: 10 }])).toThrow(
        "out of bounds"
      );
    });

    it("throws on delete out of bounds", () => {
      const buf = new TextBuffer("abc");
      expect(() => buf.applyDelta([{ type: "delete", count: 10 }])).toThrow(
        "out of bounds"
      );
    });

    it("throws when delta does not consume full text", () => {
      const buf = new TextBuffer("abcdef");
      expect(() => buf.applyDelta([{ type: "retain", count: 3 }])).toThrow(
        "did not consume full text"
      );
    });

    it("rebuilds line offsets after delta", () => {
      const buf = new TextBuffer("aaa\nbbb");
      buf.applyDelta([
        { type: "retain", count: 3 },
        { type: "insert", text: "\nccc" },
        { type: "retain", count: 4 },
      ]);
      expect(buf.getText()).toBe("aaa\nccc\nbbb");
      expect(buf.getLineCount()).toBe(3);
      expect(buf.getLine(1)).toBe("ccc");
    });
  });

  describe("replaceRange", () => {
    it("replaces a range in the middle", () => {
      const buf = new TextBuffer("hello world");
      buf.replaceRange(0, 5, "HELLO");
      expect(buf.getText()).toBe("HELLO world");
    });

    it("inserts at a position (empty range)", () => {
      const buf = new TextBuffer("abc");
      buf.replaceRange(1, 1, "X");
      expect(buf.getText()).toBe("aXbc");
    });

    it("deletes a range (empty replacement)", () => {
      const buf = new TextBuffer("aXbc");
      buf.replaceRange(1, 2, "");
      expect(buf.getText()).toBe("abc");
    });
  });

  describe("search", () => {
    it("finds all matches", () => {
      const buf = new TextBuffer("the cat sat on the mat");
      const matches = buf.search("the");
      expect(matches).toHaveLength(2);
      expect(matches[0]).toEqual({ start: 0, end: 3 });
      expect(matches[1]).toEqual({ start: 15, end: 18 });
    });

    it("returns empty for empty query", () => {
      const buf = new TextBuffer("hello");
      expect(buf.search("")).toEqual([]);
    });

    it("returns empty for no match", () => {
      const buf = new TextBuffer("hello world");
      expect(buf.search("xyz")).toEqual([]);
    });

    it("supports case-insensitive (default)", () => {
      const buf = new TextBuffer("Hello HELLO hello");
      const matches = buf.search("hello");
      expect(matches).toHaveLength(3);
    });

    it("supports case-sensitive", () => {
      const buf = new TextBuffer("Hello HELLO hello");
      const matches = buf.search("hello", true);
      expect(matches).toHaveLength(1);
      expect(matches[0].start).toBe(12);
    });

    it("finds overlapping matches (at adjacent positions)", () => {
      const buf = new TextBuffer("aaa");
      const matches = buf.search("aa");
      expect(matches).toHaveLength(2);
    });
  });

  describe("extractOutline", () => {
    it("extracts markdown headings", () => {
      const buf = new TextBuffer("# Title\nSome text\n## Section\nMore text");
      const outline = buf.extractOutline();
      expect(outline).toHaveLength(2);
      expect(outline[0]).toMatchObject({ level: 1, text: "Title", line: 0 });
      expect(outline[1]).toMatchObject({ level: 2, text: "Section", line: 2 });
    });

    it("extracts chapter/part/section keywords", () => {
      const buf = new TextBuffer("Chapter 1: Begin\nPart 1: Origins\nSection 1: Setup");
      const outline = buf.extractOutline();
      expect(outline).toHaveLength(3);
      expect(outline[0]).toMatchObject({ level: 2, line: 0 });
      expect(outline[1]).toMatchObject({ level: 1, line: 1 });
      expect(outline[2]).toMatchObject({ level: 3, line: 2 });
    });

    it("ignores plain text lines", () => {
      const buf = new TextBuffer("Just some text\nno headings here");
      expect(buf.extractOutline()).toHaveLength(0);
    });

    it("ignores empty lines", () => {
      const buf = new TextBuffer("\n\n# Heading");
      const outline = buf.extractOutline();
      expect(outline).toHaveLength(1);
      expect(outline[0]).toMatchObject({ line: 2 });
    });

    it("includes charOffset for each entry", () => {
      const buf = new TextBuffer("# A\n# B");
      const outline = buf.extractOutline();
      expect(outline[0].charOffset).toBe(0);
      expect(outline[1].charOffset).toBe(4);
    });
  });

  describe("getSectionRange", () => {
    it("returns range from heading to next same-level heading", () => {
      const buf = new TextBuffer("# A\ncontent a\n# B\ncontent b");
      const range = buf.getSectionRange(0);
      expect(range).toEqual({ startLine: 0, endLine: 2 });
    });

    it("extends to end when last section", () => {
      const buf = new TextBuffer("# A\ncontent\n# B\nlast");
      const range = buf.getSectionRange(2);
      expect(range).toEqual({ startLine: 2, endLine: 4 });
    });

    it("nested sections end at parent level", () => {
      const buf = new TextBuffer("# A\n## Sub\nsub text\n# B");
      const range = buf.getSectionRange(1);
      expect(range).toEqual({ startLine: 1, endLine: 3 });
    });

    it("returns single line for non-heading", () => {
      const buf = new TextBuffer("# A\nplain text");
      const range = buf.getSectionRange(1);
      expect(range).toEqual({ startLine: 1, endLine: 2 });
    });
  });

  describe("moveSection", () => {
    it("moves section to start (-1)", () => {
      const buf = new TextBuffer("# A\na content\n# B\nb content");
      const result = buf.moveSection(2, -1);
      expect(result.startsWith("# B")).toBe(true);
      expect(result).toContain("b content");
      expect(result).toContain("# A");
      expect(result).toContain("a content");
    });

    it("no-op when moving first section to start", () => {
      const buf = new TextBuffer("# A\na content\n# B\nb content");
      const result = buf.moveSection(0, -1);
      expect(result).toBe(buf.getText());
    });

    it("moves section after another section", () => {
      const buf = new TextBuffer("# A\na content\n# B\nb content");
      const result = buf.moveSection(0, 2);
      expect(result).toContain("a content");
      expect(result).toContain("b content");
      expect(result).toContain("# A");
      expect(result).toContain("# B");
      const bPos = result.indexOf("# B");
      const aPos = result.indexOf("# A");
      expect(bPos).toBeLessThan(aPos);
    });
  });
});
