import { describe, it, expect } from "vitest";
import {
  escapeHtml,
  wordSimilarity,
  tokenize,
  computeDiff,
  highlightRegions,
} from "../components/ComparePanel";

describe("escapeHtml", () => {
  it("escapes ampersands", () => {
    expect(escapeHtml("a&b")).toBe("a&amp;b");
  });

  it("escapes angle brackets", () => {
    expect(escapeHtml("<div>")).toBe("&lt;div&gt;");
  });

  it("escapes quotes", () => {
    expect(escapeHtml('"hello"')).toBe("&quot;hello&quot;");
  });

  it("escapes all special chars together", () => {
    expect(escapeHtml('<a href="x">&')).toBe(
      "&lt;a href=&quot;x&quot;&gt;&amp;"
    );
  });

  it("passes through plain text unchanged", () => {
    expect(escapeHtml("hello world")).toBe("hello world");
  });
});

describe("wordSimilarity", () => {
  it("returns 1 for identical strings", () => {
    expect(wordSimilarity("hello world", "hello world")).toBeCloseTo(1);
  });

  it("returns 0 for completely different strings", () => {
    expect(wordSimilarity("alpha beta", "gamma delta")).toBe(0);
  });

  it("returns 0 for strings with only short words (<=2 chars)", () => {
    expect(wordSimilarity("a b c", "x y z")).toBe(0);
  });

  it("is case-insensitive", () => {
    expect(wordSimilarity("Hello World", "hello world")).toBeCloseTo(1);
  });

  it("computes Jaccard similarity for partial overlap", () => {
    const sim = wordSimilarity("apple banana cherry", "banana cherry date");
    expect(sim).toBeGreaterThan(0);
    expect(sim).toBeLessThan(1);
  });
});

describe("tokenize", () => {
  it("splits text preserving whitespace tokens", () => {
    expect(tokenize("hello world")).toEqual(["hello", " ", "world"]);
  });

  it("handles multiple spaces as a single whitespace token", () => {
    expect(tokenize("a   b")).toEqual(["a", "   ", "b"]);
  });

  it("handles newlines and tabs as whitespace tokens", () => {
    expect(tokenize("a\nb\tc")).toEqual(["a", "\n", "b", "\t", "c"]);
  });

  it("handles empty string", () => {
    expect(tokenize("")).toEqual([""]);
  });

  it("handles leading/trailing whitespace", () => {
    expect(tokenize("  hello  ")).toEqual(["  ", "hello", "  "]);
  });
});

describe("computeDiff", () => {
  it("returns all-added for empty source", () => {
    const segments = computeDiff("", "hello world");
    expect(segments.some((s) => s.type === "added" && s.text === "hello world")).toBe(true);
  });

  it("returns all-removed for empty target", () => {
    const segments = computeDiff("hello world", "");
    expect(segments.some((s) => s.type === "removed")).toBe(true);
  });

  it("returns all-common for identical text", () => {
    const segments = computeDiff("hello world", "hello world");
    expect(segments.every((s) => s.type === "common")).toBe(true);
  });

  it("detects a pure insertion", () => {
    const segments = computeDiff("hello world", "hello beautiful world");
    expect(segments.some((s) => s.type === "added" && s.text.includes("beautiful"))).toBe(true);
  });

  it("detects a pure deletion", () => {
    const segments = computeDiff("hello beautiful world", "hello world");
    expect(segments.some((s) => s.type === "removed" && s.text.includes("beautiful"))).toBe(true);
  });

  it("reconstructs source text from common+removed segments", () => {
    const src = "the quick brown fox";
    const segments = computeDiff(src, "the lazy dog");
    const reconstructed = segments
      .filter((s) => s.type === "common" || s.type === "removed")
      .map((s) => s.text)
      .join("")
      .trim();
    expect(reconstructed).toBe(src);
  });

  it("reconstructs target text from common+added segments", () => {
    const target = "the lazy dog";
    const segments = computeDiff("the quick brown fox", target);
    const reconstructed = segments
      .filter((s) => s.type === "common" || s.type === "added")
      .map((s) => s.text)
      .join("")
      .trim();
    expect(reconstructed).toBe(target);
  });
});

describe("highlightRegions", () => {
  it("escapes HTML in text with no regions", () => {
    const html = highlightRegions("<script>", [], "hl");
    expect(html).toContain("&lt;script&gt;");
  });

  it("wraps full text in a region", () => {
    const html = highlightRegions("hello", [{ start: 0, end: 5, cidx: 0 }], "highlight");
    expect(html).toContain("highlight");
    expect(html).toContain("hello");
  });

  it("handles multiple regions", () => {
    const html = highlightRegions(
      "abcdef",
      [
        { start: 0, end: 2, cidx: 0 },
        { start: 4, end: 6, cidx: 1 },
      ],
      "hl",
    );
    expect(html).toContain("hl");
  });

  it("wraps unregioned text with uniqueCls when provided", () => {
    const html = highlightRegions(
      "abc",
      [{ start: 0, end: 1, cidx: 0 }],
      "hl",
      "plain",
    );
    expect(html).toContain("plain");
  });
});
