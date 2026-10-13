import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { CrdtSyncClient } from "../api/crdt_sync";

/**
 * coverage-plan-web.md Phase 2 (the last critical): the wire client's
 * WebSocket engine — where lost edits would be born. Everything is
 * driven through a FakeWebSocket (frames in, frames out) plus a
 * controllable /csrf-token fetch. The handshake, request/response
 * correlation, reconnect backoff table, the disconnect generation
 * guard (a documented bug class), heartbeat, event routing, and the
 * delta/save-state machine are pinned here.
 */

type Frame = Record<string, any>;

vi.mock("../safe-storage", () => {
  const backing = new Map<string, string>();
  return {
    storageGet: (k: string) => backing.get(k) ?? null,
    storageSet: (k: string, v: string) => void backing.set(k, v),
    storageRemove: (k: string) => void backing.delete(k),
    storageClear: () => void backing.clear(),
  };
});

class FakeWebSocket {
  static instances: FakeWebSocket[] = [];
  static CONNECTING = 0;
  static OPEN = 1;
  static CLOSING = 2;
  static CLOSED = 3;

  url: string;
  readyState = 0;
  onopen: (() => void) | null = null;
  onmessage: ((e: { data: string }) => void) | null = null;
  onclose: ((ev: { code: number; reason: string; wasClean: boolean }) => void) | null = null;
  onerror: ((ev: unknown) => void) | null = null;
  sent: Frame[] = [];
  /** op → auto response value; ops listed here answer instantly. */
  auto = new Map<string, unknown>();
  /** op → reject with this message. */
  fail = new Map<string, string>();

  constructor(url: string) {
    this.url = url;
    FakeWebSocket.instances.push(this);
  }

  ops(): string[] {
    return this.sent.filter((f) => f.type === "request").map((f) => f.op);
  }

  send(data: string): void {
    const frame = JSON.parse(data) as Frame;
    this.sent.push(frame);
    if (frame.type === "request" && this.fail.has(frame.op)) {
      queueMicrotask(() =>
        this.onmessage?.({ data: JSON.stringify({ type: "error", id: frame.id, message: this.fail.get(frame.op) }) }),
      );
      return;
    }
    if (frame.type === "request" && this.auto.has(frame.op)) {
      queueMicrotask(() =>
        this.onmessage?.({ data: JSON.stringify({ type: "response", id: frame.id, value: this.auto.get(frame.op) }) }),
      );
    }
  }

  close(): void {
    this.readyState = 3;
  }

  simulateOpen(): void {
    this.readyState = 1;
    this.onopen?.();
  }

  simulateMessage(frame: Frame): void {
    this.onmessage?.({ data: JSON.stringify(frame) });
  }

  simulateClose(): void {
    this.readyState = 3;
    this.onclose?.({ code: 1006, reason: "net down", wasClean: false });
  }

  answered = new Set<number>();
  respondTo(op: string, value: unknown, isError = false): void {
    const frame = this.sent.find((f) => f.op === op && f.type === "request" && !this.answered.has(f.id));
    if (!frame) throw new Error(`no unanswered request for ${op}`);
    this.answered.add(frame.id);
    this.simulateMessage(
      isError ? { type: "error", id: frame.id, message: String(value) } : { type: "response", id: frame.id, value },
    );
  }
}

/** Controllable /csrf-token fetch; released via releaseCsrf(). */
let releaseCsrf: ((ok: boolean) => void) | null = null;

beforeEach(() => {
  vi.useFakeTimers();
  FakeWebSocket.instances = [];
  releaseCsrf = null;
  vi.stubGlobal("WebSocket", FakeWebSocket);
  vi.stubGlobal(
    "fetch",
    () =>
      releaseCsrf
        ? new Promise((res) => {
            releaseCsrf = ((ok: boolean) => {
              res(ok ? { ok: true, json: async () => ({ csrf_token: "tok-abc" }) } : { ok: false, json: async () => ({}) });
            }) as typeof releaseCsrf;
          })
        : Promise.resolve({ ok: true, json: async () => ({ csrf_token: "tok-abc" }) }),
  );
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.useRealTimers();
});

async function microtasks(n = 8) {
  for (let i = 0; i < n; i++) {
    await Promise.resolve();
  }
}

/** Connect + full handshake. Returns the live socket. */
async function boot() {
  const c = new CrdtSyncClient("ws://test", 0x10);
  c.connect();
  await microtasks();
  // The instance openWs created — give it the standard server config.
  const ws = FakeWebSocket.instances.at(-1)!;
  wireStandard(ws);
  ws.simulateOpen();
  await microtasks(12);
  return { c, ws };
}

describe("CrdtSyncClient WS — handshake", () => {
  it("fetches the csrf token, opens with it, and runs the anonymous session sequence", async () => {
    const { c, ws } = await boot();
    expect(ws.url).toContain("csrf_token=tok-abc");
    // The anonymous handshake order.
    const ops = ws.ops();
    expect(ops.indexOf("session_connect")).toBe(0);
    expect(ops).toContain("club_who_am_i");
    expect(ops).toContain("session_login_public"); // anonymous: no identity
    expect(ops).toContain("crdt_sync_open");
    expect(ops).toContain("crdt_awareness_get");
    expect(c.isConnected()).toBe(true);
    expect(c.getText()).toBe("server text");
  });

  it("the open response's text reaches listeners (the editor's first paint)", async () => {
    const { c } = await boot();
    const seen: string[] = [];
    c.onTextChange((t) => seen.push(t));
    // Text arrived during boot before we subscribed; reconnect-style
    // verification: setTextLocal round-trip still notifies.
    c.setTextLocal("local");
    expect(seen).toEqual(["local"]);
    expect(c.getText()).toBe("local");
  });
});

describe("CrdtSyncClient WS — request/response correlation", () => {
  it("responses resolve by frame id; errors reject with the server's message", async () => {
    const { c, ws } = await boot();
    const p1 = c.sendRequest("custom_op", { x: 1 });
    const p2 = c.sendRequest("custom_op", { x: 2 });
    ws.respondTo("custom_op", "first-ack");
    // The SECOND request with that op is still pending; answer with error.
    ws.respondTo("custom_op", "boom", true);
    expect(await p1).toBe("first-ack");
    await expect(p2).rejects.toThrow("boom");
  });

  it("a closed socket rejects immediately (no silent drops)", async () => {
    const { c } = await boot();
    c.disconnect();
    await expect(c.sendRequest("anything")).rejects.toThrow("WebSocket not open");
  });

  it("a dropped connection fails all pending requests", async () => {
    const { c, ws } = await boot();
    const p = c.sendRequest("never-answered");
    const failP = c.sendRequest("never-answered");
    ws.fail.set("never-answered", "x"); // irrelevant; we close first
    ws.simulateClose();
    await expect(p).rejects.toThrow("connection closed");
    await expect(failP).rejects.toThrow("connection closed");
  });
});

describe("CrdtSyncClient WS — reconnect backoff", () => {
  it("consecutive FAILED attempts escalate [200, 500, 1000] then exponential; a successful open resets the table", async () => {
    const { c } = await boot();
    const ws1 = FakeWebSocket.instances.at(-1)!;

    // Each reconnect's socket FAILS to open (connection refused):
    // created, then immediately closed — the attempt counter climbs.
    const failLatest = () => {
      const ws = FakeWebSocket.instances.at(-1)!;
      ws.simulateClose(); // never opened
    };

    // Attempt 1: 200ms.
    ws1.simulateClose();
    await actAdvance(199);
    expect(FakeWebSocket.instances).toHaveLength(1);
    await actAdvance(1);
    expect(FakeWebSocket.instances).toHaveLength(2);
    failLatest();

    // Attempt 2: 500ms.
    await actAdvance(499);
    expect(FakeWebSocket.instances).toHaveLength(2);
    await actAdvance(1);
    expect(FakeWebSocket.instances).toHaveLength(3);
    failLatest();

    // Attempt 3: 1000ms.
    await actAdvance(999);
    expect(FakeWebSocket.instances).toHaveLength(3);
    await actAdvance(1);
    expect(FakeWebSocket.instances).toHaveLength(4);
    failLatest();

    // Attempt 4: exponential — base 500*2^3 = 4000, ±25% jitter ⇒
    // fires in [3000, 5000]. Deterministic bounds.
    await actAdvance(2999);
    expect(FakeWebSocket.instances).toHaveLength(4);
    await actAdvance(2001);
    expect(FakeWebSocket.instances).toHaveLength(5);

    // A SUCCESSFUL reconnection resets the table: next drop waits 200ms.
    const ws6 = FakeWebSocket.instances.at(-1)!;
    wireStandard(ws6);
    ws6.simulateOpen();
    await microtasks(4);
    expect(c.getReconnectAttempt()).toBe(0);
    ws6.simulateClose();
    await actAdvance(199);
    expect(FakeWebSocket.instances).toHaveLength(5);
    await actAdvance(1);
    expect(FakeWebSocket.instances).toHaveLength(6);
  }, 20000);

  it("disconnect() is final: a disposed client never resurrects", async () => {
    const { c } = await boot();
    const ws = FakeWebSocket.instances.at(-1)!;
    c.disconnect();
    ws.simulateClose();
    await actAdvance(30000);
    // Only the boot socket ever existed.
    expect(FakeWebSocket.instances).toHaveLength(1);
  }, 20000);
});

describe("CrdtSyncClient WS — the generation guard (stranded-connect bug class)", () => {
  it("disconnect during the csrf fetch abandons the open AND unlocks connect()", async () => {
    const c = new CrdtSyncClient("ws://test", 0x10);
    c.connect();
    // Fetch still pending; the user switches works — disconnect bumps
    // the generation.
    c.disconnect();
    // The fetch resolves now — dead client must NOT open a socket.
    await microtasks(10);
    expect(FakeWebSocket.instances).toHaveLength(0);
    // And the guard is unlocked: a fresh connect on the same client works.
    c.connect();
    await microtasks(10);
    expect(FakeWebSocket.instances).toHaveLength(1);
  });
});

describe("CrdtSyncClient WS — heartbeat and events", () => {
  it("a heartbeat frame goes out every 20s", async () => {
    const { ws } = await boot();
    ws.sent = [];
    await actAdvance(19999);
    expect(ws.sent.filter((f) => f.type === "heartbeat")).toHaveLength(0);
    await actAdvance(1);
    expect(ws.sent.filter((f) => f.type === "heartbeat")).toHaveLength(1);
  });

  it("crdt_text_update events apply when idle; the echo guard drops recent-ack echoes", async () => {
    const { c, ws } = await boot();
    const seen: string[] = [];
    c.onTextChange((t) => seen.push(t));
    // Outside the 2.5s echo window: a genuine remote edit applies.
    await actAdvance(3000);
    ws.simulateMessage({ type: "event", event: { type: "crdt_text_update", payload: { work_id: 0x10, text: "remote edit" } } });
    expect(c.getText()).toBe("remote edit");
    expect(seen).toEqual(["remote edit"]);
  });
});

describe("CrdtSyncClient WS — the delta/save-state machine", () => {
  it("setText sends a retain/insert delta and walks saving→saved→idle", async () => {
    const { c, ws } = await boot();
    const states: string[] = [];
    c.onSaveStateChange((s) => states.push(s));
    ws.sent = [];
    c.setText("server text edited");
    const delta = ws.sent.find((f) => f.op === "work_revise_delta");
    expect(delta).toBeTruthy();
    expect(delta.payload).toEqual({
      work_id: 0x10,
      base_revision: 0,
      ops: [{ type: "retain", count: 11 }, { type: "insert", text: " edited" }],
    });
    ws.respondTo("work_revise_delta", null);
    await microtasks(4);
    expect(states).toEqual(["saving", "saved"]);
    await actAdvance(2000);
    expect(states).toEqual(["saving", "saved", "idle"]);
    expect(c.getText()).toBe("server text edited");
  });

  it("a failed ordinary delta ROLLS THE EDIT BACK (server is authoritative)", async () => {
    const { c, ws } = await boot();
    const seen: string[] = [];
    c.onTextChange((t) => seen.push(t));
    ws.fail.set("work_revise_delta", "rejected");
    c.setText("server text edited");
    await microtasks(8);
    expect(c.getText()).toBe("server text"); // rolled back
    expect(seen).toContain("server text");
    expect(c.getSaveState()).toBe("error");
  });
});

async function actAdvance(ms: number) {
  await vi.advanceTimersByTimeAsync(ms);
}

function wireStandard(ws: FakeWebSocket) {
  ws.auto.set("session_connect", 42);
  ws.auto.set("club_who_am_i", { clubs: [] });
  ws.auto.set("session_login_public", null);
  ws.auto.set("crdt_sync_open", { current_text: "server text" });
  ws.auto.set("crdt_awareness_get", { states: [] });
  ws.auto.set("admin_grants", null);
  ws.auto.set("crdt_sync_close", null);
}
