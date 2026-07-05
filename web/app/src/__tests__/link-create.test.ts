import { describe, it, expect } from "vitest";
import { CrdtSyncClient } from "../api/crdt_sync";

describe("linkCreate span coordinates (FR-4 gap #1 fix)", () => {
  it("transmits start_position/end_position for origin and destination refs", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const calls: Array<{ op: string; payload: Record<string, unknown> }> = [];
    client.sendRequest = (op: string, payload?: object) => {
      calls.push({ op, payload: { ...(payload ?? {}) } });
      return Promise.resolve({ type: "ok", value: 42 });
    };

    await client.linkCreate(
      0x10,
      0x20,
      { excerpt: "hello", start: 3, end: 8 },
      { excerpt: "world", start: 5, end: 10 },
    );

    expect(calls).toHaveLength(1);
    expect(calls[0].op).toBe("link_create");
    const p = calls[0].payload;
    expect(p.origin).toBe(0x10);
    expect(p.destination).toBe(0x20);

    const o = p.origin_ref as Record<string, unknown>;
    const d = p.destination_ref as Record<string, unknown>;
    expect(o.kind).toBe("single");
    expect(o.excerpt).toBe("hello");
    expect(o.start_position).toBe(3);
    expect(o.end_position).toBe(8);
    expect(d.excerpt).toBe("world");
    expect(d.start_position).toBe(5);
    expect(d.end_position).toBe(10);
  });

  it("omits refs entirely when no span is provided", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const calls: Array<{ op: string; payload: Record<string, unknown> }> = [];
    client.sendRequest = (op: string, payload?: object) => {
      calls.push({ op, payload: { ...(payload ?? {}) } });
      return Promise.resolve({ type: "ok", value: 7 });
    };

    await client.linkCreate(0x10, 0x20);

    const p = calls[0].payload;
    expect(p.origin_ref).toBeUndefined();
    expect(p.destination_ref).toBeUndefined();
    expect(p.origin).toBe(0x10);
    expect(p.destination).toBe(0x20);
  });

  it("returns the link id from the response", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    client.sendRequest = () => Promise.resolve({ type: "ok", value: 99 });
    const id = await client.linkCreate(1, 2, { excerpt: "x", start: 0, end: 1 });
    expect(id).toBe(99);
  });
});
