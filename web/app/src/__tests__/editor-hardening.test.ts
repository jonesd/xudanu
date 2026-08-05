import { describe, it, expect } from "vitest";
import { validateSpanRanges } from "../components/editor-dom-utils";
import type { SpanRangePayload } from "../api/crdt_sync";

function mkSpan(flat_start: number, flat_end: number, source = 1): SpanRangePayload {
  return {
    source_work_id: source,
    char_start: 0,
    char_end: flat_end - flat_start,
    flat_start,
    flat_end,
    content_len: flat_end - flat_start,
  };
}

describe("validateSpanRanges", () => {
  it("returns empty array for empty input", () => {
    expect(validateSpanRanges([], 100)).toEqual([]);
  });

  it("keeps valid ranges within text bounds", () => {
    const ranges = [mkSpan(0, 5), mkSpan(10, 20)];
    const valid = validateSpanRanges(ranges, 30);
    expect(valid).toHaveLength(2);
  });

  it("filters out ranges where flat_end exceeds text length", () => {
    const ranges = [mkSpan(0, 5), mkSpan(8, 50)];
    const valid = validateSpanRanges(ranges, 20);
    expect(valid).toHaveLength(1);
    expect(valid[0].flat_end).toBe(5);
  });

  it("filters out ranges where flat_start is negative", () => {
    const ranges = [mkSpan(-5, 5), mkSpan(0, 10)];
    const valid = validateSpanRanges(ranges, 20);
    expect(valid).toHaveLength(1);
    expect(valid[0].flat_start).toBe(0);
  });

  it("filters out zero-length ranges (flat_end <= flat_start)", () => {
    const ranges = [mkSpan(5, 5), mkSpan(5, 3), mkSpan(0, 10)];
    const valid = validateSpanRanges(ranges, 20);
    expect(valid).toHaveLength(1);
    expect(valid[0].flat_start).toBe(0);
  });

  it("filters out ranges entirely beyond text length", () => {
    const ranges = [mkSpan(100, 200), mkSpan(0, 5)];
    const valid = validateSpanRanges(ranges, 20);
    expect(valid).toHaveLength(1);
  });

  it("handles text length of 0", () => {
    const ranges = [mkSpan(0, 5)];
    const valid = validateSpanRanges(ranges, 0);
    expect(valid).toHaveLength(0);
  });

  it("keeps ranges that exactly span the full text", () => {
    const ranges = [mkSpan(0, 10)];
    const valid = validateSpanRanges(ranges, 10);
    expect(valid).toHaveLength(1);
  });

  it("keeps ranges that end exactly at text length", () => {
    const ranges = [mkSpan(5, 20)];
    const valid = validateSpanRanges(ranges, 20);
    expect(valid).toHaveLength(1);
  });

  it("preserves all fields of valid ranges", () => {
    const ranges = [
      {
        source_work_id: 42,
        char_start: 3,
        char_end: 8,
        flat_start: 5,
        flat_end: 15,
        content_len: 10,
        otree_position: 2,
        resolved_content: "hello world",
        placed_at: 1234567890,
        placed_by: 100,
      },
    ];
    const valid = validateSpanRanges(ranges, 20);
    expect(valid).toHaveLength(1);
    expect(valid[0]).toEqual(ranges[0]);
  });
});
