import { describe, it, expect } from "vitest";
import { rebaseAttributionSpans, rebaseAnnotations, rebaseMarkers } from "../api/span-sync";
import type { AttributionSpan, AnnotationEntry, TransclusionMarker } from "../api/protocol";

const INSERT_AT_0: Array<{ type: string; count?: number; text?: string }> = [
  { type: "insert", text: "abc" },
  { type: "retain", count: 20 },
];

const DELETE_MIDDLE: Array<{ type: string; count?: number; text?: string }> = [
  { type: "retain", count: 4 },
  { type: "delete", count: 8 },
  { type: "retain", count: 8 },
];

describe("rebaseAttributionSpans", () => {
  const spans: AttributionSpan[] = [
    {
      start: 5, end: 9,
      author_public_key: [1, 2], author_display_name: "alice", author_club_id: 7,
      signature_valid: true, verification_state: null, timestamp: 1, server_id: [],
      author_type: "human", llm_model: null, historical_author_id: null,
    },
  ];

  it("shifts on insert-before and preserves every metadata field", () => {
    const out = rebaseAttributionSpans(spans, INSERT_AT_0);
    expect(out[0].start).toBe(8);
    expect(out[0].end).toBe(12);
    expect(out[0].author_display_name).toBe("alice");
    expect(out[0].author_club_id).toBe(7);
    expect(out[0].signature_valid).toBe(true);
  });

  it("shrinks under partial deletion and collapses when fully covered", () => {
    const partial = rebaseAttributionSpans(spans, [
      { type: "retain", count: 6 },
      { type: "delete", count: 2 },
      { type: "retain", count: 12 },
    ]);
    expect(partial[0]).toMatchObject({ start: 5, end: 7 });
    expect(rebaseAttributionSpans(spans, DELETE_MIDDLE)[0]).toMatchObject({ start: 4, end: 4 });
  });
});

describe("rebaseAnnotations", () => {
  const entries: AnnotationEntry[] = [
    { annotation_id: 31, kind: "comment", payload: "note", char_start: 6, char_end: 10, created_by: 3, created_by_name: "bob", created_at: 9, is_private: false },
  ];

  it("rebases char_start/char_end and preserves identity fields", () => {
    const out = rebaseAnnotations(entries, INSERT_AT_0);
    expect(out[0].char_start).toBe(9);
    expect(out[0].char_end).toBe(13);
    expect(out[0].annotation_id).toBe(31);
    expect(out[0].kind).toBe("comment");
    expect(out[0].payload).toBe("note");
    expect(out[0].is_private).toBe(false);
  });

  it("keeps fully-deleted annotations as collapsed entries (renderer skips, server refresh confirms)", () => {
    const out = rebaseAnnotations(entries, DELETE_MIDDLE);
    expect(out).toHaveLength(1);
    expect(out[0].char_start).toBe(out[0].char_end);
  });
});

describe("rebaseMarkers", () => {
  const markers: TransclusionMarker[] = [
    {
      start: 5, end: 9, linkId: 77, direction: "outgoing", otherWorkId: 12,
      otherWorkTitle: "Other", color: "#00897b",
      target: { workId: 12, span: { start: 100, end: 104 } },
      sameSpanCount: 2,
    },
  ];

  it("rebases the LOCAL span only — target.span lives in another work's coordinates", () => {
    const out = rebaseMarkers(markers, INSERT_AT_0);
    expect(out[0].start).toBe(8);
    expect(out[0].end).toBe(12);
    expect(out[0].target).toEqual({ workId: 12, span: { start: 100, end: 104 } });
    expect(out[0].sameSpanCount).toBe(2);
    expect(out[0].linkId).toBe(77);
  });

  it("collapses markers whose span was deleted", () => {
    const out = rebaseMarkers(markers, DELETE_MIDDLE);
    expect(out[0].start).toBe(out[0].end);
    expect(out[0].target).toEqual({ workId: 12, span: { start: 100, end: 104 } });
  });
});
