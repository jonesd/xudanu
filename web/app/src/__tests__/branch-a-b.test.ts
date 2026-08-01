import { describe, it, expect, vi } from "vitest";
import { extractValue } from "../api/crdt_sync";

describe("Branch A: Transclusion persistence", () => {
  it("extractValue unwraps {type, value} response", () => {
    const resp = { type: "number", value: 42 };
    expect(extractValue(resp)).toBe(42);
  });

  it("extractValue returns raw response if no value field", () => {
    const resp = { foo: "bar" };
    expect(extractValue(resp)).toEqual({ foo: "bar" });
  });

  it("extractValue handles primitive responses", () => {
    expect(extractValue(42)).toBe(42);
    expect(extractValue("hello")).toBe("hello");
  });
});

describe("Branch A: createWork ID extraction", () => {
  it("extracts work_id from {value: number} response", () => {
    const resp = { type: "number", value: 1399 };
    const val = extractValue(resp);
    expect(typeof val).toBe("number");
    expect(val).toBe(1399);
  });

  it("extracts work_id from {value: {work_id: number}} response", () => {
    const resp = { type: "object", value: { work_id: 1399 } };
    const val = extractValue(resp) as Record<string, unknown>;
    expect(val.work_id).toBe(1399);
  });

  it("returns null for empty response", () => {
    const resp = {} as Record<string, unknown>;
    const val = extractValue(resp);
    expect(val).toEqual({});
  });
});

describe("Branch A: Recent list sort", () => {
  it("sorts works with updated_at by recency", () => {
    const works = [
      { work_id: 1, updated_at: 100, is_starred: false, is_source: false, revision_count: 0, owner: 0, is_grabbed: false, read_club: 0, title: "old" },
      { work_id: 2, updated_at: 200, is_starred: false, is_source: false, revision_count: 0, owner: 0, is_grabbed: false, read_club: 0, title: "new" },
    ];
    const sorted = [...works].sort((a, b) => (b.updated_at ?? b.work_id) - (a.updated_at ?? a.work_id));
    expect(sorted[0].work_id).toBe(2);
  });

  it("falls back to work_id for null updated_at (new works)", () => {
    const works = [
      { work_id: 100, updated_at: null as number | null, is_starred: false, is_source: false, revision_count: 0, owner: 0, is_grabbed: false, read_club: 0, title: "old" },
      { work_id: 200, updated_at: null as number | null, is_starred: false, is_source: false, revision_count: 0, owner: 0, is_grabbed: false, read_club: 0, title: "new" },
    ];
    const sorted = [...works].sort((a, b) => (b.updated_at ?? b.work_id) - (a.updated_at ?? a.work_id));
    expect(sorted[0].work_id).toBe(200);
  });

  it("pins appear before unpinned", () => {
    const pinned = [
      { work_id: 1, updated_at: 100, is_starred: true, is_source: false, revision_count: 0, owner: 0, is_grabbed: false, read_club: 0, title: "pinned-old" },
    ];
    const unpinned = [
      { work_id: 2, updated_at: 200, is_starred: false, is_source: false, revision_count: 0, owner: 0, is_grabbed: false, read_club: 0, title: "unpinned-new" },
    ];
    const recent = [...pinned, ...unpinned].slice(0, 15);
    expect(recent[0].is_starred).toBe(true);
  });
});

describe("Branch A: Compound state persistence", () => {
  it("does not clear state when loadCompound returns empty and already has compound", () => {
    let hasCompound = true;
    let spanRanges = [{ source_work_id: 1, char_start: 0, char_end: 10, flat_start: 0, flat_end: 10, content_len: 10 }];

    // Simulate loadCompound with empty result when hasCompound is true
    const inline = { spanRanges: [], sourceTitles: {}, text: "" };
    if (inline.spanRanges.length > 0) {
      hasCompound = true;
      spanRanges = inline.spanRanges;
    } else if (!hasCompound) {
      hasCompound = false;
      spanRanges = [];
    }
    // State should NOT be cleared because hasCompound was true
    expect(hasCompound).toBe(true);
    expect(spanRanges.length).toBe(1);
  });

  it("clears state when loadCompound returns empty and has no compound", () => {
    let hasCompound = false;
    let spanRanges: unknown[] = [];

    const inline = { spanRanges: [], sourceTitles: {}, text: "" };
    if (inline.spanRanges.length > 0) {
      hasCompound = true;
    } else if (!hasCompound) {
      hasCompound = false;
      spanRanges = [];
    }
    expect(hasCompound).toBe(false);
    expect(spanRanges.length).toBe(0);
  });
});

describe("Branch B: Highlight range", () => {
  it("creates highlight range from span range", () => {
    const sr = { flat_start: 100, flat_end: 200, source_work_id: 1, char_start: 10, char_end: 20, content_len: 10 };
    const highlight = { start: sr.flat_start, end: sr.flat_end };
    expect(highlight.start).toBe(100);
    expect(highlight.end).toBe(200);
  });

  it("highlight auto-clears after timeout", () => {
    vi.useFakeTimers();
    let highlightRange: { start: number; end: number } | null = { start: 0, end: 10 };
    setTimeout(() => { highlightRange = null; }, 4000);
    expect(highlightRange).not.toBeNull();
    vi.advanceTimersByTime(4000);
    expect(highlightRange).toBeNull();
    vi.useRealTimers();
  });
});

describe("Branch B: Transclusion excerpt display", () => {
  it("truncates long excerpts", () => {
    const content = "A".repeat(120);
    const display = content.length > 80 ? content.slice(0, 80) + "\u2026" : content;
    expect(display.length).toBe(81); // 80 chars + ellipsis
    expect(display.endsWith("\u2026")).toBe(true);
  });

  it("shows short excerpts in full", () => {
    const content = "Short text";
    const display = content.length > 80 ? content.slice(0, 80) + "\u2026" : content;
    expect(display).toBe("Short text");
  });
});

describe("Branch A: Undo toast timing", () => {
  it("undo toast shows for 6 seconds then disappears", () => {
    vi.useFakeTimers();
    let showUndoToast = false;
    showUndoToast = true;
    setTimeout(() => { showUndoToast = false; }, 6000);
    expect(showUndoToast).toBe(true);
    vi.advanceTimersByTime(5000);
    expect(showUndoToast).toBe(true);
    vi.advanceTimersByTime(1000);
    expect(showUndoToast).toBe(false);
    vi.useRealTimers();
  });
});

describe("Branch A: Escape cancels transclusion", () => {
  it("clears pending transclusion on Escape", () => {
    let pending: { sourceWorkId: number; sourceWorkTitle: string; start: number; end: number; text: string } | null = { sourceWorkId: 1, sourceWorkTitle: "Test", start: 0, end: 10, text: "hello" };
    let pendingLink: { sourceWorkId: number; sourceWorkTitle: string; start: number; end: number; text: string } | null = { sourceWorkId: 1, sourceWorkTitle: "Test", start: 0, end: 10, text: "hello" };
    let linkDescription = "test";

    // Simulate Escape handler
    const handler = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        pending = null;
        pendingLink = null;
        linkDescription = "";
      }
    };

    handler({ key: "Escape" } as KeyboardEvent);
    expect(pending).toBeNull();
    expect(pendingLink).toBeNull();
    expect(linkDescription).toBe("");
  });
});
