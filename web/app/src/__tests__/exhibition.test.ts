import { describe, it, expect, beforeEach, vi } from "vitest";
import type { CrdtSyncClient, LinkEntry } from "../api/crdt_sync";

/**
 * exhibition.ts — exhibitions as gathers-typed links (containment as
 * connection). Module-level caches (gathersTypeId, coverByMember)
 * make isolation necessary: fresh module per test via resetModules.
 */
async function freshExhibition() {
  vi.resetModules();
  const mod = await import("../exhibition");
  return mod;
}

function fakeClient(opts: {
  types?: Array<{ type_id: number; name: string }>;
  linksByWork?: Record<number, LinkEntry[]>;
  failFor?: number[];
}): { client: CrdtSyncClient; linkListCalls: () => number } {
  let listCalls = 0;
  const client = {
    linkTypeList: async () => opts.types ?? [],
    linkListForWork: async (workId: number) => {
      listCalls++;
      if (opts.failFor?.includes(workId)) throw new Error("transient");
      return opts.linksByWork?.[workId] ?? [];
    },
  } as unknown as CrdtSyncClient;
  return { client, linkListCalls: () => listCalls };
}

function gathersLink(origin: number, destination: number, title?: string): LinkEntry {
  return {
    link_id: origin * 100 + destination,
    origin,
    destination,
    origin_title: title ?? null,
    link_types: [0x55],
  } as unknown as LinkEntry;
}

const COVER = 0x10;
const MEMBER = 0x20;
const OTHER_MEMBER = 0x30;
const OUTSIDE = 0x99;

function galleryWorld() {
  // Cover 0x10 gathers members 0x20 and 0x30.
  return {
    types: [{ type_id: 0x55, name: "Gathers" }],
    linksByWork: {
      [COVER]: [
        gathersLink(COVER, MEMBER, "The Gallery"),
        gathersLink(COVER, OTHER_MEMBER, "The Gallery"),
      ],
      // Members see the same links (bidirectionality of the model).
      [MEMBER]: [gathersLink(COVER, MEMBER, "The Gallery")],
      [OTHER_MEMBER]: [gathersLink(COVER, OTHER_MEMBER, "The Gallery")],
    } as Record<number, LinkEntry[]>,
  };
}

describe("exhibitionTransition (pure)", () => {
  it("silence for same exhibition or both outside", async () => {
    const { exhibitionTransition } = await freshExhibition();
    expect(exhibitionTransition(null, null)).toBeNull();
    const ex = { coverWorkId: 1, title: "T", memberIds: new Set([1]) };
    expect(exhibitionTransition(ex, ex)).toBeNull();
    expect(exhibitionTransition(ex, { ...ex })).toBeNull();
  });

  it("entering, leaving, and direct crossings", async () => {
    const { exhibitionTransition } = await freshExhibition();
    const a = { coverWorkId: 1, title: "A", memberIds: new Set<number>() };
    const b = { coverWorkId: 2, title: "B", memberIds: new Set<number>() };
    expect(exhibitionTransition(null, a)).toEqual({ kind: "entering", title: "A" });
    expect(exhibitionTransition(a, null)).toEqual({ kind: "leaving", title: "A" });
    // Crossing directly between exhibitions: leaving is said first.
    expect(exhibitionTransition(a, b)).toEqual({ kind: "leaving", title: "A" });
  });
});

describe("checkExhibitionCrossing (resolution)", () => {
  beforeEach(() => {
    vi.resetModules();
  });

  it("null when there is no previous work or it is the same work", async () => {
    const { checkExhibitionCrossing } = await freshExhibition();
    const { client } = fakeClient(galleryWorld());
    expect(await checkExhibitionCrossing(client, null, MEMBER)).toBeNull();
    expect(await checkExhibitionCrossing(client, MEMBER, MEMBER)).toBeNull();
  });

  it("entering a member's exhibition names the cover's title", async () => {
    const { checkExhibitionCrossing } = await freshExhibition();
    const { client, linkListCalls } = fakeClient(galleryWorld());
    expect(await checkExhibitionCrossing(client, OUTSIDE, MEMBER)).toBe("Entering The Gallery");
    // OUTSIDE (1 call) + MEMBER (1 call) + the cover's member list (1 call).
    expect(linkListCalls()).toBe(3);
    // Cached: the reverse crossing re-fetches nothing.
    expect(await checkExhibitionCrossing(client, MEMBER, OUTSIDE)).toBe("Leaving The Gallery");
    expect(linkListCalls()).toBe(3);
  });

  it("the cover itself is inside its exhibition", async () => {
    const { checkExhibitionCrossing } = await freshExhibition();
    const { client } = fakeClient(galleryWorld());
    expect(await checkExhibitionCrossing(client, COVER, OUTSIDE)).toBe("Leaving The Gallery");
  });

  it("same exhibition: silence across members", async () => {
    const { checkExhibitionCrossing } = await freshExhibition();
    const { client } = fakeClient(galleryWorld());
    expect(await checkExhibitionCrossing(client, MEMBER, OTHER_MEMBER)).toBeNull();
  });

  it("no Gathers type registered: safe silence (no membership at all)", async () => {
    const { checkExhibitionCrossing } = await freshExhibition();
    const world = galleryWorld();
    const { client } = fakeClient({ ...world, types: [] });
    expect(await checkExhibitionCrossing(client, OUTSIDE, MEMBER)).toBeNull();
  });

  it("transient fetch failures read as no exhibition", async () => {
    const { checkExhibitionCrossing } = await freshExhibition();
    const world = galleryWorld();
    const { client } = fakeClient({ ...world, failFor: [MEMBER] });
    expect(await checkExhibitionCrossing(client, OUTSIDE, MEMBER)).toBeNull();
  });

  it("title falls back to the cover's hex id", async () => {
    const { checkExhibitionCrossing } = await freshExhibition();
    const { client } = fakeClient({
      types: [{ type_id: 0x55, name: "Gathers" }],
      linksByWork: {
        [COVER]: [gathersLink(COVER, MEMBER)],
        [MEMBER]: [gathersLink(COVER, MEMBER)],
      },
    });
    expect(await checkExhibitionCrossing(client, OUTSIDE, MEMBER)).toBe(
      `Entering Work 0x${COVER.toString(16)}`,
    );
  });

  it("forgetExhibitionMembership forces a re-resolution", async () => {
    const { checkExhibitionCrossing, forgetExhibitionMembership } = await freshExhibition();
    const { client, linkListCalls } = fakeClient(galleryWorld());
    await checkExhibitionCrossing(client, OUTSIDE, MEMBER);
    const calls = linkListCalls();
    forgetExhibitionMembership(MEMBER);
    await checkExhibitionCrossing(client, MEMBER, OUTSIDE);
    expect(linkListCalls()).toBeGreaterThan(calls);
    forgetExhibitionMembership(); // clears everything
    await checkExhibitionCrossing(client, OUTSIDE, MEMBER);
    expect(linkListCalls()).toBeGreaterThan(calls + 1);
  });
});
