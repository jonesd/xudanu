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

describe("linkCreateCrossServer", () => {
  it("sends link_create with cross_server_ref in destination_ref", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const calls: Array<{ op: string; payload: Record<string, unknown> }> = [];
    client.sendRequest = (op: string, payload?: object) => {
      calls.push({ op, payload: { ...(payload ?? {}) } });
      return Promise.resolve({ type: "ok", value: 55 });
    };

    const hash = "ab".repeat(32);
    const key = "cd".repeat(32);
    const id = await client.linkCreateCrossServer(
      0x10,
      { excerpt: "selected text", start: 5, end: 17 },
      {
        tumbler: '"alice.example.com".5.3.10.7',
        content_hash: hash,
        origin_author: "alice",
        origin_author_key: key,
      },
    );

    expect(id).toBe(55);
    expect(calls).toHaveLength(1);
    expect(calls[0].op).toBe("link_create");

    const p = calls[0].payload;
    expect(p.origin).toBe(0x10);
    expect(p.destination).toBe(0x10);
    expect(p.link_types).toEqual([]);

    const o = p.origin_ref as Record<string, unknown>;
    expect(o.start_position).toBe(5);
    expect(o.end_position).toBe(17);
    expect(o.excerpt).toBe("selected text");

    const d = p.destination_ref as Record<string, unknown>;
    const csr = d.cross_server_ref as Record<string, unknown>;
    expect(csr.tumbler).toBe('"alice.example.com".5.3.10.7');
    expect(csr.content_hash).toBe(hash);
    expect(csr.origin_author).toBe("alice");
    expect(csr.origin_author_key).toBe(key);
  });

  it("passes through empty author when not provided", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const calls: Array<{ op: string; payload: Record<string, unknown> }> = [];
    client.sendRequest = (op: string, payload?: object) => {
      calls.push({ op, payload: { ...(payload ?? {}) } });
      return Promise.resolve({ type: "ok", value: 1 });
    };

    await client.linkCreateCrossServer(1, { excerpt: "x", start: 0, end: 1 }, {
      tumbler: "1.5.3.10.7",
      content_hash: "ab".repeat(32),
      origin_author: "",
      origin_author_key: "",
    });

    const d = calls[0].payload.destination_ref as Record<string, unknown>;
    const csr = d.cross_server_ref as Record<string, unknown>;
    expect(csr.origin_author).toBe("");
  });
});

describe("connection pin persistence", () => {
  it("connectionPinSet sends the correct op and key", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const calls: Array<{ op: string; payload: Record<string, unknown> }> = [];
    client.sendRequest = (op: string, payload?: object) => {
      calls.push({ op, payload: { ...(payload ?? {}) } });
      return Promise.resolve({ type: "ok", value: null });
    };

    await client.connectionPinSet("link-42");

    expect(calls).toHaveLength(1);
    expect(calls[0].op).toBe("connection_pin_set");
    expect(calls[0].payload.key).toBe("link-42");
  });

  it("connectionPinUnset sends the correct op and key", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const calls: Array<{ op: string; payload: Record<string, unknown> }> = [];
    client.sendRequest = (op: string, payload?: object) => {
      calls.push({ op, payload: { ...(payload ?? {}) } });
      return Promise.resolve({ type: "ok", value: null });
    };

    await client.connectionPinUnset("backlink-99");

    expect(calls).toHaveLength(1);
    expect(calls[0].op).toBe("connection_pin_unset");
    expect(calls[0].payload.key).toBe("backlink-99");
  });

  it("connectionPinsGet returns the list of pinned keys", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    client.sendRequest = () =>
      Promise.resolve({ type: "ok", value: ["link-1", "link-2", "backlink-3"] });

    const pins = await client.connectionPinsGet();

    expect(pins).toEqual(["link-1", "link-2", "backlink-3"]);
  });

  it("connectionPinsGet returns empty array on non-array response", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    client.sendRequest = () => Promise.resolve({ type: "ok", value: null });

    const pins = await client.connectionPinsGet();

    expect(pins).toEqual([]);
  });

  it("full round-trip: set, get, unset, get", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const storedPins = new Set<string>();

    client.sendRequest = (op: string, payload?: object) => {
      const p = payload as Record<string, unknown> | undefined;
      if (op === "connection_pin_set") {
        storedPins.add(p!.key as string);
        return Promise.resolve({ type: "ok", value: null });
      }
      if (op === "connection_pin_unset") {
        storedPins.delete(p!.key as string);
        return Promise.resolve({ type: "ok", value: null });
      }
      if (op === "connection_pins_get") {
        return Promise.resolve({ type: "ok", value: [...storedPins] });
      }
      return Promise.resolve({ type: "ok", value: null });
    };

    expect(await client.connectionPinsGet()).toEqual([]);

    await client.connectionPinSet("link-1");
    await client.connectionPinSet("link-2");
    await client.connectionPinSet("backlink-3");

    let pins = await client.connectionPinsGet();
    expect(pins).toHaveLength(3);
    expect(pins).toContain("link-1");
    expect(pins).toContain("link-2");
    expect(pins).toContain("backlink-3");

    await client.connectionPinUnset("link-2");

    pins = await client.connectionPinsGet();
    expect(pins).toHaveLength(2);
    expect(pins).toContain("link-1");
    expect(pins).not.toContain("link-2");
    expect(pins).toContain("backlink-3");

    await client.connectionPinSet("link-1");
    pins = await client.connectionPinsGet();
    expect(pins).toHaveLength(2);
  });
});
