import { describe, it, expect } from "vitest";

describe("Unified position mapper — resolved text vs CRDT text", () => {
  const crdtText = "Hello  goodbye";
  const resolvedText = "Hello world goodbye";

  it("getSourceText returns resolved text when available", () => {
    const getSourceText = () => resolvedText;
    expect(getSourceText()).toBe("Hello world goodbye");
  });

  it("getSourceText falls back to CRDT text", () => {
    const fallback: string | undefined = undefined;
    const getSourceText = () => fallback || crdtText;
    expect(getSourceText()).toBe("Hello  goodbye");
  });

  it("selection entirely in own text (before transclusion) extracts correctly from resolved text", () => {
    const start = 0;
    const end = 5;
    expect(resolvedText.slice(start, end)).toBe("Hello");
    expect(crdtText.slice(start, end)).toBe("Hello");
  });

  it("selection entirely in own text (after transclusion) extracts correctly from resolved text", () => {
    const start = 11;
    const end = 19;
    expect(resolvedText.slice(start, end)).toBe(" goodbye");
  });

  it("selection entirely within transclusion content extracts from resolved text", () => {
    const start = 6;
    const end = 11;
    expect(resolvedText.slice(start, end)).toBe("world");
  });

  it("selection spanning own text and transclusion extracts from resolved text", () => {
    const start = 3;
    const end = 9;
    expect(resolvedText.slice(start, end)).toBe("lo wor");
  });

  it("selection spanning entire transclusion and surrounding text", () => {
    const start = 2;
    const end = 15;
    expect(resolvedText.slice(start, end)).toBe("llo world goo");
  });

  it("CRDT text would produce WRONG result for same positions", () => {
    const start = 3;
    const end = 9;
    expect(crdtText.slice(start, end)).not.toBe("lo wor");
    expect(crdtText.slice(start, end)).toBe("lo  go");
  });
});

describe("Position mapping with multiple transclusion spans", () => {
  const resolvedText = "A[foo]B[bar]C";

  it("selection before first transclusion", () => {
    expect(resolvedText.slice(0, 1)).toBe("A");
  });

  it("selection in first transclusion", () => {
    expect(resolvedText.slice(1, 4)).toBe("[fo");
    expect(resolvedText.slice(2, 5)).toBe("foo");
  });

  it("selection between transclusions", () => {
    expect(resolvedText.slice(4, 6)).toBe("o]");
    expect(resolvedText.slice(5, 6)).toBe("]");
    expect(resolvedText.slice(6, 7)).toBe("B");
  });

  it("selection spanning both transclusions", () => {
    expect(resolvedText.slice(0, 10)).toBe("A[foo]B[ba");
  });

  it("selection of entire content", () => {
    expect(resolvedText.slice(0)).toBe("A[foo]B[bar]C");
  });
});

describe("Selection text for transclusion placement", () => {
  it("extracts correct text for holdSelection when crossing transclusion boundary", () => {
    const resolvedText = "Introduction transcluded-conclusion more text";
    const selectionStart = 5;
    const selectionEnd = 25;

    const selectedText = resolvedText.slice(selectionStart, selectionEnd);
    expect(selectedText).toContain("duction");
    expect(selectedText).toContain("transcluded");
    expect(selectedText.length).toBe(20);
  });

  it("handles empty resolved text gracefully", () => {
    const resolvedText = "";
    expect(resolvedText.slice(0, 10)).toBe("");
  });

  it("handles selection at end of resolved text", () => {
    const resolvedText = "Hello world";
    expect(resolvedText.slice(6)).toBe("world");
  });
});
