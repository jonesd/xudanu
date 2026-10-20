import { describe, it, expect } from "vitest";

/**
 * Regression: WS request ids are u16 on the wire (id 0 reserved for
 * error frames). The client counter used to grow unbounded — long
 * sessions ran past 65535 and every subsequent request was rejected
 * server-side as a protocol violation (~5k observed on xudanu.com
 * after id 71640). nextId must wrap 1..=65535.
 */
describe("crdt_sync request id wrap", () => {
  it("wraps within u16 range, skipping 0", async () => {
    const mod = (await import("../api/crdt_sync")) as unknown as Record<
      string,
      unknown
    >;
    const candidate = Object.values(mod).find(
      (v): v is new () => { nextId?: () => number } =>
        typeof v === "function" &&
        /^class\s/.test(Function.prototype.toString.call(v)) &&
        "prototype" in v &&
        typeof (v as { prototype?: { nextId?: unknown } }).prototype?.nextId ===
          "function",
    );
    if (!candidate) throw new Error("client class with nextId not found");
    // Construct without connecting (nextId never touches the socket).
    const client = new candidate() as unknown as { nextId: () => number };
    // Drive the counter to the boundary.
    for (let i = 0; i < 65534; i++) client.nextId();
    const a = client.nextId();
    expect(a).toBe(65535);
    const b = client.nextId();
    expect(b).toBe(1); // wraps, never 0
    const c = client.nextId();
    expect(c).toBe(2);
  });
});
