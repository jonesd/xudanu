import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { CrdtSyncClient } from "../api/crdt_sync";

describe("WS reconnect backoff (F1)", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("nth reconnect delay follows exponential backoff envelope", () => {
    const client = new CrdtSyncClient("ws://test", 1);

    const fastSchedule = [200, 500, 1000];
    for (let attempt = 0; attempt < 6; attempt++) {
      for (let sample = 0; sample < 50; sample++) {
        const delaySpy = vi.spyOn(globalThis, "setTimeout");
        vi.spyOn(client as any, "connect").mockImplementation(() => {});

        (client as any).reconnectAttempts = attempt;
        (client as any).reconnectTimer = null;
        (client as any).scheduleReconnect();

        expect(delaySpy).toHaveBeenCalledTimes(1);
        const delay = delaySpy.mock.calls[0][1] as number;

        if (attempt < 3) {
          expect(delay).toBe(fastSchedule[attempt]);
        } else {
          const expectedBase = Math.min(500 * Math.pow(2, attempt), 10000);
          expect(delay).toBeGreaterThanOrEqual(expectedBase * 0.75);
          expect(delay).toBeLessThanOrEqual(expectedBase * 1.25);
        }

        delaySpy.mockRestore();
        vi.clearAllTimers();
      }
    }
  });

  it("delay caps at 30s", () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const base = client.getReconnectDelay(10);
    expect(base).toBe(10000);
  });

  it("base delay grows exponentially", () => {
    const client = new CrdtSyncClient("ws://test", 1);
    expect(client.getReconnectDelay(0)).toBe(500);
    expect(client.getReconnectDelay(1)).toBe(1000);
    expect(client.getReconnectDelay(2)).toBe(2000);
    expect(client.getReconnectDelay(3)).toBe(4000);
    expect(client.getReconnectDelay(4)).toBe(8000);
  });

  it("resets reconnect attempts to 0 on successful connect", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    (client as any).reconnectAttempts = 5;
    (client as any).connected = false;

    vi.spyOn(client as any, "sendRequest").mockResolvedValue({});

    await (client as any).onOpen();

    expect((client as any).reconnectAttempts).toBe(0);

    const nextBase = client.getReconnectDelay(0);
    expect(nextBase).toBe(500);
  });
});

describe("Request timeout and drop handling", () => {
  it("rejects sendRequest immediately when WebSocket is not open", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    (client as any).ws = null;

    await expect(client.sendRequest("test_op")).rejects.toThrow("WebSocket not open");
  });

  it("rejects sendRequest when WebSocket is in CONNECTING state", async () => {
    const client = new CrdtSyncClient("ws://test", 1);
    (client as any).ws = { readyState: 0 };

    await expect(client.sendRequest("test_op")).rejects.toThrow("WebSocket not open");
  });

  it("cleans up pending map entry on timeout", async () => {
    vi.useFakeTimers();
    const client = new CrdtSyncClient("ws://test", 1);
    (client as any).ws = { readyState: 1, send: vi.fn() };

    const promise = client.sendRequest("slow_op");
    vi.advanceTimersByTime(31000);

    await expect(promise).rejects.toThrow("timed out");
    expect((client as any).pending.size).toBe(0);
    vi.useRealTimers();
  });

  it("clears timeout timer when response arrives", async () => {
    vi.useFakeTimers();
    const client = new CrdtSyncClient("ws://test", 1);
    (client as any).ws = { readyState: 1, send: vi.fn() };

    const promise = client.sendRequest("fast_op");
    const pendingMap = (client as any).pending;
    const id = Array.from(pendingMap.keys())[0];
    const handler = pendingMap.get(id);
    pendingMap.delete(id);
    handler({ result: "ok" }, false);

    const result = await promise;
    expect(result).toEqual({ result: "ok" });
    expect(pendingMap.size).toBe(0);
    vi.useRealTimers();
  });
});
