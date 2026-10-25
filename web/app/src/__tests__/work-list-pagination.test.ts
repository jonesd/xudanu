import { describe, it, expect } from "vitest";
import { CrdtSyncClient } from "../api/crdt_sync";
import type { WorkListEntry } from "../api/protocol";

function entry(workId: number, title: string, starred = false): WorkListEntry {
  return {
    work_id: workId,
    owner: null,
    revision_count: 1,
    is_grabbed: false,
    title,
    read_club: null,
    is_starred: starred,
  };
}

/** A ws mock that answers work_list requests like the server's
 * PaginatedWorkList envelope: stable order, offset+limit slicing.
 * `pageSizeCap` models servers that return fewer entries than
 * requested (the short-page case the client must accumulate over). */
function pagedClient(allEntries: WorkListEntry[], pageSizeCap?: number): {
  client: CrdtSyncClient;
  requests: Array<Record<string, any>>;
} {
  const client = new CrdtSyncClient("ws://test", 42);
  const requests: Array<Record<string, any>> = [];
  (client as any).connected = true;
  (client as any).ws = {
    readyState: WebSocket.OPEN,
    send: (data: string) => {
      const frame = JSON.parse(data);
      requests.push(frame);
      if (frame.op !== "work_list") return;
      const offset: number = frame.payload?.offset ?? 0;
      const limit: number = frame.payload?.limit ?? 1000;
      const effective = Math.min(limit, pageSizeCap ?? limit);
      const slice = allEntries.slice(offset, offset + effective);
      const value = {
        type: "ok",
        value: {
          entries: slice,
          total_count: allEntries.length,
          has_more: offset + slice.length < allEntries.length,
        },
      };
      queueMicrotask(() => {
        (client as any).onMessage(JSON.stringify({ type: "response", id: frame.id, value }));
      });
    },
  };
  return { client, requests };
}

describe("fetchWorkList — pagination (FR-154 bug 1: silent 1,000 truncation)", () => {
  it("fetches ALL pages until has_more is false", async () => {
    // Server caps pages at 3 regardless of the requested limit —
    // the client must accumulate by entries received, not stride.
    const { client, requests } = pagedClient(
      [entry(1, "A"), entry(2, "B"), entry(3, "C"), entry(4, "D"), entry(5, "E")],
      3,
    );

    const list = await client.fetchWorkList();

    expect(list.map((w) => w.work_id)).toEqual([1, 2, 3, 4, 5]);
    expect(list.map((w) => w.title)).toEqual(["A", "B", "C", "D", "E"]);
    expect(requests.filter((f) => f.op === "work_list")).toHaveLength(2);
    // Second request continues where the first SHORT page ended
    expect(requests[1].payload).toEqual({ offset: 3, limit: 1000 });
  });

  it("single page: exactly one request, no continuation", async () => {
    const { client, requests } = pagedClient([entry(1, "Only")]);

    const list = await client.fetchWorkList();
    expect(list).toHaveLength(1);
    expect(requests.filter((f) => f.op === "work_list")).toHaveLength(1);
  });

  it("fetchWorkListPage exposes the envelope (total_count, has_more)", async () => {
    const { client } = pagedClient([entry(1, "A"), entry(2, "B")]);

    const page = await client.fetchWorkListPage(0, 1);
    expect(page.entries).toHaveLength(1);
    expect(page.total_count).toBe(2);
    expect(page.has_more).toBe(true);
  });

  it("open-work mirror feed works when the open work is on a LATER page", async () => {
    const { client } = pagedClient(
      [entry(1, "First Page Work"), entry(42, "The Open One", true)],
      1,
    );

    await client.fetchWorkList();

    expect((client as any).openWorkTitle).toBe("The Open One");
    expect((client as any).currentStarred).toBe(true);
  });
});
