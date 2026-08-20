import { describe, it, expect } from "vitest";
import { renderHook, act } from "@testing-library/react";
import { useTransclusion } from "../hooks/useTransclusion";
import type { CrdtSyncClient, LinkEntry } from "../api/crdt_sync";

// Regression for the live "no underlines" incident: link_list_for_work
// succeeds and returns well-formed entries, but a racing second
// loadLinks call for the SAME work discarded the first result via the
// epoch guard, leaving markers empty forever.
function fakeClient(links: LinkEntry[]): CrdtSyncClient {
  return {
    linkListForWork: async (wid: number) => (wid === WORK ? links : []),
    findExcerptPositions: async () => [],
    workBacklinks: async () => [],
  } as unknown as CrdtSyncClient;
}

const WORK = 1112;
const webLink: LinkEntry = {
  link_id: 67,
  origin: WORK,
  destination: WORK,
  origin_ref: { kind: "single", work_context: WORK, original_context: null, excerpt: "Ted Nelson", start_position: 15, end_position: 27 },
  destination_ref: { kind: "single", work_context: WORK, original_context: null, excerpt: "http://udanax.xanadu.com/gold/index.html", start_position: 0, end_position: 0 },
  link_types: [6],
};

describe("useTransclusion.loadLinks race", () => {
  it("same-work refresh does not discard in-flight results", async () => {
    const client = fakeClient([webLink]);
    const { result } = renderHook(() => useTransclusion());

    // Two overlapping loads for the SAME work (effect re-run before the
    // first completes — the works-list update case).
    await act(async () => {
      const first = result.current.loadLinks(client, WORK, []);
      const second = result.current.loadLinks(client, WORK, []);
      await Promise.all([first, second]);
    });

    expect(result.current.links.length).toBe(1);
    expect(result.current.markers.length).toBe(1);
    expect(result.current.markers[0].linkTypeId).toBe(6);
    expect(result.current.markers[0].start).toBe(15);
    expect(result.current.markers[0].end).toBe(27);
  });

  it("a load for a different work supersedes earlier results", async () => {
    const client = fakeClient([webLink]);
    const { result } = renderHook(() => useTransclusion());
    await act(async () => {
      const stale = result.current.loadLinks(client, WORK, []);
      await result.current.loadLinks(client, 9999, []);
      await stale;
    });
    expect(result.current.links.length).toBe(0);
    expect(result.current.markers.length).toBe(0);
  });

  it("single load populates markers", async () => {
    const client = fakeClient([webLink]);
    const { result } = renderHook(() => useTransclusion());
    await act(async () => {
      await result.current.loadLinks(client, WORK, []);
    });
    expect(result.current.markers.length).toBe(1);
  });
});
