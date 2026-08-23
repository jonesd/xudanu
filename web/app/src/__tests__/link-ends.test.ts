import { describe, it, expect } from "vitest";
import { linkEnds, isMultiEnded, multiEndWorkIds, notifyStatus } from "../link-ends";
import type { LinkEntry } from "../api/crdt_sync";

function mkLink(overrides: Partial<LinkEntry> = {}): LinkEntry {
  return {
    link_id: 1,
    origin: 0x10,
    destination: 0x20,
    origin_ref: null,
    destination_ref: null,
    ...overrides,
  };
}

describe("linkEnds", () => {
  it("returns origin and destination ends for a plain two-ended link", () => {
    const ends = linkEnds(mkLink());
    expect(ends).toHaveLength(2);
    expect(ends[0].name).toBe("origin");
    expect(ends[0].workId).toBe(0x10);
    expect(ends[1].name).toBe("destination");
    expect(ends[1].workId).toBe(0x20);
  });

  it("prefers ref work_context over the origin/destination fields", () => {
    const ends = linkEnds(
      mkLink({
        origin_ref: {
          kind: "single",
          work_context: 0x99,
          original_context: null,
          excerpt: "hi",
        },
      }),
    );
    expect(ends[0].workId).toBe(0x99);
    expect(ends[0].excerpt).toBe("hi");
  });

  it("appends named ends in payload order with excerpts", () => {
    const ends = linkEnds(
      mkLink({
        named_ends: [
          ["Comparison3", { kind: "single", work_context: 0x30, original_context: null, excerpt: "third" }],
          ["Context", { kind: "single", work_context: 0x40, original_context: null, excerpt: "fourth" }],
        ],
      }),
    );
    expect(ends).toHaveLength(4);
    expect(ends[2]).toMatchObject({ name: "Comparison3", workId: 0x30, excerpt: "third" });
    expect(ends[3]).toMatchObject({ name: "Context", workId: 0x40, excerpt: "fourth" });
  });

  it("carries null workId for cross-server named ends", () => {
    const ends = linkEnds(
      mkLink({
        named_ends: [["Remote", { kind: "single", work_context: null, original_context: null, excerpt: "far" }]],
      }),
    );
    expect(ends[2].workId).toBeNull();
  });
});

describe("isMultiEnded / multiEndWorkIds", () => {
  it("false for plain links, true once named ends exist", () => {
    expect(isMultiEnded(mkLink())).toBe(false);
    expect(
      isMultiEnded(
        mkLink({ named_ends: [["E", { kind: "single", work_context: 3, original_context: null, excerpt: "" }]] }),
      ),
    ).toBe(true);
  });

  it("dedupes work ids across all ends", () => {
    const ids = multiEndWorkIds(
      mkLink({
        origin_ref: { kind: "single", work_context: 0x10, original_context: null, excerpt: "" },
        named_ends: [
          ["A", { kind: "single", work_context: 0x30, original_context: null, excerpt: "" }],
          ["B", { kind: "single", work_context: 0x10, original_context: null, excerpt: "" }],
          ["C", { kind: "single", work_context: null, original_context: null, excerpt: "" }],
        ],
      }),
    );
    expect(ids.sort()).toEqual([0x10, 0x20, 0x30]);
  });
});

describe("notifyStatus", () => {
  it("none when the field is absent or null", () => {
    expect(notifyStatus(mkLink()).kind).toBe("none");
    expect(notifyStatus(mkLink({ cross_server_notify_accepted: null })).kind).toBe("none");
  });

  it("accepted on true", () => {
    expect(notifyStatus(mkLink({ cross_server_notify_accepted: true })).kind).toBe("accepted");
  });

  it("classified as error for reachability failures", () => {
    for (const reason of [
      "could not reach receiving server: connect failed",
      "connect failed: timeout",
      "DNS resolution failed",
      "connection refused",
    ]) {
      expect(notifyStatus(mkLink({ cross_server_notify_accepted: false, cross_server_notify_error: reason })).kind).toBe("error");
    }
  });

  it("classified as rejected for receiver-side refusals, carrying the reason", () => {
    const st = notifyStatus(
      mkLink({
        cross_server_notify_accepted: false,
        cross_server_notify_error: "receiving server rejected (HTTP 404): work not found",
      }),
    );
    expect(st.kind).toBe("rejected");
    if (st.kind === "rejected") expect(st.reason).toContain("404");
  });
});
