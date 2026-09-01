import { describe, it, expect } from "vitest";
import { linkEnds, isMultiEnded, multiEndWorkIds, notifyStatus } from "../link-ends";
import type { LinkEntry, HyperRefPayload } from "../api/crdt_sync";

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

// ---- FR-40 S6/S7: end-sets ----

import {
  isGatheredEnd,
  endSetCount,
  linkAttachmentTarget,
  linkIdentityKey,
  planEndSetOperations,
} from "../link-ends";

describe("FR-40 S6 end-sets", () => {
  const ref = (work: number, start = 0, end = 5): HyperRefPayload => ({
    kind: "single",
    work_context: work,
    original_context: null,
    excerpt: `passage ${work}`,
    start_position: start,
    end_position: end,
  });

  it("linkEnds merges end_sets into the origin slot with all attachments", () => {
    const link = mkLink({
      origin_ref: ref(0x10),
      end_sets: [
        ["LeftEnd", [ref(0x10, 0, 6), ref(0x10, 8, 11), ref(0x30, 0, 5)]],
      ],
    });
    const ends = linkEnds(link);
    expect(ends).toHaveLength(2);
    const origin = ends[0];
    expect(isGatheredEnd(origin)).toBe(true);
    expect(endSetCount(origin)).toBe(3);
    expect(origin.attachments?.map((a) => a.work_context)).toEqual([0x10, 0x10, 0x30]);
    // compat view: first attachment
    expect(origin.workId).toBe(0x10);
    expect(origin.excerpt).toBe("passage 16");
    // destination untouched
    expect(isGatheredEnd(ends[1])).toBe(false);
    expect(endSetCount(ends[1])).toBe(1);
  });

  it("linkEnds merges end_sets into named ends and destination", () => {
    const link = mkLink({
      destination_ref: ref(0x20),
      named_ends: [["Evidence", ref(0x40, 6, 9)]],
      end_sets: [
        ["RightEnd", [ref(0x20, 0, 4), ref(0x21, 0, 4)]],
        ["Evidence", [ref(0x40, 6, 9), ref(0x41, 0, 3), ref(0x42, 0, 3)]],
      ],
    });
    const ends = linkEnds(link);
    const byName = Object.fromEntries(ends.map((e) => [e.name, e]));
    expect(endSetCount(byName.destination)).toBe(2);
    expect(endSetCount(byName.Evidence)).toBe(3);
    expect(isGatheredEnd(byName.Evidence)).toBe(true);
  });

  it("singleton-only end_sets are ignored (compat shape governs)", () => {
    const link = mkLink({ end_sets: [["LeftEnd", [ref(0x10)]]] });
    const ends = linkEnds(link);
    expect(isGatheredEnd(ends[0])).toBe(false);
    expect(ends[0].attachments).toBeUndefined();
  });

  it("unknown end_sets names still surface as ends", () => {
    const link = mkLink({
      end_sets: [["Witnesses", [ref(0x50), ref(0x51)]]],
    });
    const ends = linkEnds(link);
    const witnesses = ends.find((e) => e.name === "Witnesses");
    expect(witnesses).toBeDefined();
    expect(endSetCount(witnesses!)).toBe(2);
  });
});

describe("FR-40 S7 link attachments", () => {
  it("linkAttachmentTarget reads kind=link_attachment refs", () => {
    expect(
      linkAttachmentTarget({
        kind: "link_attachment",
        work_context: null,
        original_context: null,
        excerpt: null,
        link_attachment: 77,
      }),
    ).toBe(77);
    expect(linkAttachmentTarget({ kind: "single", work_context: 1, original_context: null, excerpt: null })).toBeNull();
    expect(linkAttachmentTarget(null)).toBeNull();
  });

  it("linkIdentityKey is stable and position-independent", () => {
    expect(linkIdentityKey(42)).toBe("link-42");
    expect(linkIdentityKey(42)).toBe(linkIdentityKey(42));
    expect(linkIdentityKey(43)).not.toBe(linkIdentityKey(42));
  });
});

describe("FR-40 S6 gather planning", () => {
  const span = (endName: string, work: number) => ({ endName, workContext: work });

  it("first span per end creates the end, subsequent attach", () => {
    const ops = planEndSetOperations([
      span("Evidence", 1),
      span("Evidence", 2),
      span("Witness", 3),
      span("Evidence", 4),
    ]);
    expect(ops.map((o) => o.op)).toEqual([
      "add-end",
      "add-attachment",
      "add-end",
      "add-attachment",
    ]);
    expect(ops[0].endName).toBe("Evidence");
    expect(ops[1].endName).toBe("Evidence");
    expect(ops[2].endName).toBe("Witness");
  });

  it("empty end names are dropped", () => {
    expect(planEndSetOperations([span("", 1), span("E", 2)])).toHaveLength(1);
  });

  it("empty input yields empty plan", () => {
    expect(planEndSetOperations([])).toEqual([]);
  });
});
