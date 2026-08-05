import { describe, it, expect } from "vitest";
import {
  computeSelectionSegments,
  segmentsToText,
  isMultiSourceSelection,
  type SelectionSegment,
} from "../components/selection-segments";

describe("computeSelectionSegments", () => {
  const spanRanges = [
    { flat_start: 6, flat_end: 11, source_work_id: 42, char_start: 0, char_end: 5 },
  ];
  const sourceText = "Hello world goodbye";

  it("selection entirely in own text (before transclusion)", () => {
    const segs = computeSelectionSegments({} as HTMLElement, 0, 5, spanRanges);
    expect(segs).toHaveLength(1);
    expect(segs[0].type).toBe("text");
    expect(segs[0].resolvedStart).toBe(0);
    expect(segs[0].resolvedEnd).toBe(5);
    expect(segmentsToText(segs, sourceText)).toBe("Hello");
  });

  it("selection entirely in own text (after transclusion)", () => {
    const segs = computeSelectionSegments({} as HTMLElement, 12, 19, spanRanges);
    expect(segs).toHaveLength(1);
    expect(segs[0].type).toBe("text");
    expect(segmentsToText(segs, sourceText)).toBe("goodbye");
  });

  it("selection entirely within transclusion", () => {
    const segs = computeSelectionSegments({} as HTMLElement, 6, 11, spanRanges);
    expect(segs).toHaveLength(1);
    expect(segs[0].type).toBe("transclusion");
    expect(segs[0].workId).toBe(42);
    expect(segs[0].sourceCharStart).toBe(0);
    expect(segs[0].sourceCharEnd).toBe(5);
    expect(segmentsToText(segs, sourceText)).toBe("world");
  });

  it("selection spanning own text + transclusion", () => {
    const segs = computeSelectionSegments({} as HTMLElement, 3, 9, spanRanges);
    expect(segs).toHaveLength(2);
    expect(segs[0].type).toBe("text");
    expect(segs[0].resolvedStart).toBe(3);
    expect(segs[0].resolvedEnd).toBe(6);
    expect(segs[1].type).toBe("transclusion");
    expect(segs[1].workId).toBe(42);
    expect(segs[1].sourceCharStart).toBe(0);
    expect(segs[1].sourceCharEnd).toBe(3);
    expect(segmentsToText(segs, sourceText)).toBe("lo wor");
  });

  it("selection spanning text + transclusion + text", () => {
    const segs = computeSelectionSegments({} as HTMLElement, 2, 15, spanRanges);
    expect(segs).toHaveLength(3);
    expect(segs[0].type).toBe("text");
    expect(segs[1].type).toBe("transclusion");
    expect(segs[1].workId).toBe(42);
    expect(segs[2].type).toBe("text");
    expect(segmentsToText(segs, sourceText)).toBe("llo world goo");
  });

  it("selection with no transclusions", () => {
    const segs = computeSelectionSegments({} as HTMLElement, 0, 5, []);
    expect(segs).toHaveLength(1);
    expect(segs[0].type).toBe("text");
  });

  it("selection with multiple transclusion spans", () => {
    const multiRanges = [
      { flat_start: 1, flat_end: 4, source_work_id: 1, char_start: 0, char_end: 3 },
      { flat_start: 6, flat_end: 9, source_work_id: 2, char_start: 0, char_end: 3 },
    ];
    const multiText = "A[foo]B[bar]C";
    const segs = computeSelectionSegments({} as HTMLElement, 0, 10, multiRanges);
    expect(segs).toHaveLength(5);
    expect(segs[0].type).toBe("text");
    expect(segs[1].type).toBe("transclusion");
    expect(segs[1].workId).toBe(1);
    expect(segs[2].type).toBe("text");
    expect(segs[3].type).toBe("transclusion");
    expect(segs[3].workId).toBe(2);
    expect(segs[4].type).toBe("text");
    expect(segmentsToText(segs, multiText)).toBe("A[foo]B[ba");
  });

  it("partial overlap with transclusion start", () => {
    const segs = computeSelectionSegments({} as HTMLElement, 4, 8, spanRanges);
    expect(segs).toHaveLength(2);
    expect(segs[0].type).toBe("text");
    expect(segs[0].resolvedEnd).toBe(6);
    expect(segs[1].type).toBe("transclusion");
    expect(segs[1].sourceCharStart).toBe(0);
    expect(segs[1].sourceCharEnd).toBe(2);
  });

  it("partial overlap with transclusion end", () => {
    const segs = computeSelectionSegments({} as HTMLElement, 8, 14, spanRanges);
    expect(segs).toHaveLength(2);
    expect(segs[0].type).toBe("transclusion");
    expect(segs[0].sourceCharStart).toBe(2);
    expect(segs[0].sourceCharEnd).toBe(5);
    expect(segs[1].type).toBe("text");
    expect(segs[1].resolvedStart).toBe(11);
  });
});

describe("segmentsToText", () => {
  const sourceText = "Hello world goodbye";

  it("extracts text from mixed segments", () => {
    const segs: SelectionSegment[] = [
      { type: "text", content: "", resolvedStart: 0, resolvedEnd: 6 },
      { type: "transclusion", content: "", workId: 42, resolvedStart: 6, resolvedEnd: 11 },
      { type: "text", content: "", resolvedStart: 11, resolvedEnd: 19 },
    ];
    expect(segmentsToText(segs, sourceText)).toBe("Hello world goodbye");
  });

  it("handles empty segments", () => {
    expect(segmentsToText([], sourceText)).toBe("");
  });
});

describe("isMultiSourceSelection", () => {
  it("returns false for single text segment", () => {
    expect(isMultiSourceSelection([
      { type: "text", content: "", resolvedStart: 0, resolvedEnd: 5 },
    ])).toBe(false);
  });

  it("returns false for single transclusion segment", () => {
    expect(isMultiSourceSelection([
      { type: "transclusion", content: "", workId: 42, resolvedStart: 6, resolvedEnd: 11 },
    ])).toBe(false);
  });

  it("returns true for text + transclusion", () => {
    expect(isMultiSourceSelection([
      { type: "text", content: "", resolvedStart: 0, resolvedEnd: 5 },
      { type: "transclusion", content: "", workId: 42, resolvedStart: 6, resolvedEnd: 11 },
    ])).toBe(true);
  });

  it("returns true for multiple transclusion sources", () => {
    expect(isMultiSourceSelection([
      { type: "transclusion", content: "", workId: 1, resolvedStart: 1, resolvedEnd: 4 },
      { type: "transclusion", content: "", workId: 2, resolvedStart: 6, resolvedEnd: 9 },
    ])).toBe(true);
  });
});
