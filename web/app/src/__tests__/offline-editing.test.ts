import { describe, it, expect, vi, beforeEach } from "vitest";
import { EditSyncEngine, type EditSyncHost } from "../api/edit-sync";
import { CrdtSyncClient } from "../api/crdt_sync";
import type { ChangeHighlight } from "../api/protocol";

const cacheMock = vi.hoisted(() => ({
  cacheDocument: vi.fn().mockResolvedValue(undefined),
  getCachedDocument: vi.fn().mockResolvedValue(null),
  setCachedStarred: vi.fn().mockResolvedValue(undefined),
}));

vi.mock("../offline-cache", () => cacheMock);

function makeHost(opts: { open?: boolean } = {}) {
  let open = opts.open ?? false;
  const sent: Array<{ op: string; payload: any }> = [];
  const host: EditSyncHost = {
    sendRequest: (op, payload) => {
      sent.push({ op, payload });
      return Promise.resolve({ type: "ok", value: null });
    },
    isSocketOpen: () => open,
    isConnected: () => open,
    getWorkBeId: () => 42,
    getCacheMeta: () => ({ title: "Test Work", starred: false }),
  };
  return { host, sent, setOpen: (v: boolean) => { open = v; } };
}

/**
 * Offline editing at the engine seam: when the server is
 * unreachable, typing still works — text updates locally, persists
 * to the offline cache, and on reconnect the reconciliation pushes
 * it. The user never sees an error, just a "syncing later"
 * indicator. No WebSocket anywhere — the host interface is faked.
 */
describe("EditSyncEngine — offline editing", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    cacheMock.cacheDocument.mockResolvedValue(undefined);
  });

  it("setText works while disconnected — updates locally, persists, no send attempted", async () => {
    const { host, sent } = makeHost(); // socket closed
    const engine = new EditSyncEngine(host);
    engine.crdtReady = true;
    engine.adoptServerText("original text");

    const texts: string[] = [];
    engine.onTextChange((t) => texts.push(t));

    engine.setText("edited while offline");
    expect(engine.getText()).toBe("edited while offline");
    expect(texts).toEqual(["edited while offline"]);
    expect(engine.hasUnsynced()).toBe(true);
    expect(sent.filter((f) => f.op === "work_revise_delta")).toHaveLength(0);
    // OFFLINE FIRST: persisted even though an ack base exists —
    // a reload must not lose the edit
    await vi.waitFor(() =>
      expect(cacheMock.cacheDocument).toHaveBeenCalledWith(
        expect.objectContaining({ work_id: 42, text: "edited while offline" }),
      ),
    );
  });

  it("offline edits survive page reload — post-reload edits persist with no ack base", async () => {
    // First session types offline → persisted
    const s1 = makeHost();
    const e1 = new EditSyncEngine(s1.host);
    e1.crdtReady = true;
    e1.adoptServerText("base");
    e1.setText("typed while offline");
    await vi.waitFor(() => expect(cacheMock.cacheDocument).toHaveBeenCalled());

    // New session (page reload): text restored from the mirror with
    // NO acked base — then the user types MORE
    const s2 = makeHost();
    const e2 = new EditSyncEngine(s2.host);
    e2.crdtReady = true;
    e2.serveOfflineCache("typed while offline");
    e2.setText("typed while offline AND after reload");

    expect(e2.getText()).toBe("typed while offline AND after reload");
    expect(e2.hasUnsynced()).toBe(true);
    // No crash, no lost text — persisted again for another reload
    await vi.waitFor(() =>
      expect(cacheMock.cacheDocument).toHaveBeenCalledWith(
        expect.objectContaining({ text: "typed while offline AND after reload" }),
      ),
    );
  });

  it("reconnect: stale full-state broadcast pushes local instead of clobbering it", async () => {
    const { host, sent, setOpen } = makeHost();
    const engine = new EditSyncEngine(host);
    engine.crdtReady = true;
    engine.adoptServerText("before offline");

    engine.setText("edited offline");
    expect(engine.hasUnsynced()).toBe(true);

    // Server returns; its broadcast carries the pre-offline view
    setOpen(true);
    engine.handleServerTextUpdate("before offline");

    // Local edits win: the server gets pushed the local text
    const pushes = sent.filter((f) => f.op === "work_revise_delta");
    expect(pushes).toHaveLength(1);
    expect(pushes[0].payload.work_id).toBe(42);
    expect(pushes[0].payload.ops).toEqual([
      { type: "delete", count: 6 },
      { type: "insert", text: "edited" },
      { type: "retain", count: 8 },
    ]);
    expect(engine.getText()).toBe("edited offline");

    // Ack lands → synced
    await vi.waitFor(() => expect(engine.hasUnsynced()).toBe(false));
  });
});

describe("EditSyncEngine — sync races", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("echo race: stale pre-edit broadcast shortly after our ack is dropped", async () => {
    const { host } = makeHost({ open: true });
    const engine = new EditSyncEngine(host);
    engine.crdtReady = true;
    engine.adoptServerText("Hello");
    engine.setText("Hello World"); // delta sent; host resolves → ack
    await vi.waitFor(() => expect(engine.getSaveState()).toBe("saved"));

    // Stale materialization broadcast arrives inside the echo window
    engine.handleServerTextUpdate("Hello");
    expect(engine.getText()).toBe("Hello World");
  });

  it("queue drain: a second edit during an in-flight delta sends after the ack — one in flight ever", async () => {
    let resolveAck: (v: unknown) => void = () => {};
    const sent: Array<{ op: string; payload: any }> = [];
    const host: EditSyncHost = {
      sendRequest: (op, payload) => {
        sent.push({ op, payload });
        return new Promise((res) => { resolveAck = res; });
      },
      isSocketOpen: () => true,
      isConnected: () => true,
      getWorkBeId: () => 42,
      getCacheMeta: () => ({ title: "T", starred: false }),
    };
    const engine = new EditSyncEngine(host);
    engine.crdtReady = true;
    engine.adoptServerText("A");

    engine.setText("AB");  // delta 1 in flight
    engine.setText("ABC"); // queued behind it
    expect(sent.filter((f) => f.op === "work_revise_delta")).toHaveLength(1);

    resolveAck({ type: "ok", value: null });
    await vi.waitFor(() =>
      expect(sent.filter((f) => f.op === "work_revise_delta")).toHaveLength(2),
    );
    // Second delta sends against the fresh acked base "AB"
    expect(sent[1].payload.ops).toEqual([
      { type: "retain", count: 2 },
      { type: "insert", text: "C" },
    ]);
  });

  it("remote delta from another session applies locally and highlights the change", () => {
    const { host } = makeHost({ open: true });
    const engine = new EditSyncEngine(host);
    engine.crdtReady = true;
    engine.adoptServerText("Hello World");

    const highlights: ChangeHighlight[][] = [];
    engine.onChangeHighlights((c) => highlights.push(c));
    engine.applyRemoteDelta(
      [
        { type: "retain", count: 5 },
        { type: "insert", text: " Brave" },
        { type: "retain", count: 6 },
      ],
      "alice",
    );

    expect(engine.getText()).toBe("Hello Brave World");
    expect(highlights[0]).toEqual([
      { start: 5, end: 11, timestamp: expect.any(Number), author: "alice" },
    ]);
  });
});

describe("CrdtSyncClient facade (integration)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("offline typing through the client reaches the engine — no sends, unsynced armed", async () => {
    const client = new CrdtSyncClient("ws://test", 42);
    (client as any).engine.crdtReady = true;
    client.adoptServerText("original");
    (client as any).ws = null;
    (client as any).connected = false;

    const texts: string[] = [];
    client.onTextChange((t) => texts.push(t));
    client.setText("edited offline");

    expect(client.getText()).toBe("edited offline");
    expect(texts).toEqual(["edited offline"]);
    expect((client as any).engine.hasUnsynced()).toBe(true);
    await vi.waitFor(() => expect(cacheMock.cacheDocument).toHaveBeenCalled());
  });
});
