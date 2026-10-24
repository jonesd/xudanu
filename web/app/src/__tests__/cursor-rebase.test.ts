import { describe, it, expect, vi } from "vitest";
import { EditSyncEngine, diffToOps, type EditSyncHost } from "../api/edit-sync";
import { CrdtSyncClient } from "../api/crdt_sync";

function makeHost(open = true): { host: EditSyncHost; sent: Array<{ op: string; payload: any }> } {
  const sent: Array<{ op: string; payload: any }> = [];
  return {
    sent,
    host: {
      sendRequest: (op, payload) => {
        sent.push({ op, payload });
        return Promise.resolve({ type: "ok", value: null });
      },
      isSocketOpen: () => open,
      isConnected: () => open,
      getWorkBeId: () => 42,
      getCacheMeta: () => ({ title: "T", starred: false }),
    },
  };
}

describe("EditSyncEngine — onTextDeltaApplied", () => {
  it("fires on setText with diffed ops, source local", () => {
    const { host } = makeHost();
    const engine = new EditSyncEngine(host);
    engine.adoptServerText("Hello World");

    const fired: Array<{ ops: any[]; source: string }> = [];
    engine.onTextDeltaApplied((ops, source) => fired.push({ ops, source }));

    engine.setText("Hello Brave World");
    expect(fired).toEqual([
      {
        ops: [
          { type: "retain", count: 6 },
          { type: "insert", text: "Brave " },
          { type: "retain", count: 5 },
        ],
        source: "local",
      },
    ]);
  });

  it("fires on applyRemoteDelta with the exact incoming ops", () => {
    const { host } = makeHost();
    const engine = new EditSyncEngine(host);
    engine.adoptServerText("Hello World");

    const fired: Array<{ ops: any[]; source: string }> = [];
    engine.onTextDeltaApplied((ops, source) => fired.push({ ops, source }));

    engine.applyRemoteDelta(
      [
        { type: "retain", count: 11 },
        { type: "insert", text: "!" },
      ],
      "alice",
    );
    expect(fired).toEqual([
      {
        ops: [
          { type: "retain", count: 11 },
          { type: "insert", text: "!" },
        ],
        source: "remote",
      },
    ]);
  });

  it("fires on adoptServerText with a server-source diff", () => {
    const { host } = makeHost();
    const engine = new EditSyncEngine(host);
    engine.adoptServerText("one");

    const fired: Array<{ ops: any[]; source: string }> = [];
    engine.onTextDeltaApplied((ops, source) => fired.push({ ops, source }));

    engine.adoptServerText("once");
    expect(fired).toEqual([
      {
        ops: [
          { type: "retain", count: 2 },
          { type: "insert", text: "c" },
          { type: "retain", count: 1 },
        ],
        source: "server",
      },
    ]);
  });

  it("does not fire on identical text or silent/local-only bookkeeping", () => {
    const { host } = makeHost();
    const engine = new EditSyncEngine(host);
    engine.adoptServerText("same");

    const fired: Array<{ ops: any[]; source: string }> = [];
    engine.onTextDeltaApplied((ops, source) => fired.push({ ops, source }));

    engine.setText("same");            // no transition
    engine.setTextSilent("other");     // bookkeeping only
    engine.markSynced();
    expect(fired).toHaveLength(0);
    expect(engine.getText()).toBe("other");
  });

  it("sendTextDelta commit info matches diffToOps accounting", async () => {
    const { host, sent } = makeHost();
    const engine = new EditSyncEngine(host);
    engine.crdtReady = true;
    engine.adoptServerText("Hello");

    const commits: Array<{ inserted: number; deleted: number; net: number; total: number }> = [];
    engine.onEditCommit((info) => commits.push(info));

    engine.setText("Hi");
    await vi.waitFor(() => expect(commits).toHaveLength(1));
    expect(commits[0]).toEqual({ inserted: 1, deleted: 4, net: -3, total: 2 });
    expect(sent[0].payload.ops).toEqual(diffToOps("Hello", "Hi"));
  });
});

describe("CrdtSyncClient — remote cursor rebase", () => {
  function setup(text: string) {
    const client = new CrdtSyncClient("ws://test", 42);
    (client as any).engine.crdtReady = true;
    client.adoptServerText(text);
    (client as any).workBeId = 42;
    (client as any).skipCrdt = false;
    return client;
  }

  function seedAwareness(client: CrdtSyncClient, sessionId: number, cursor: number | null, selection?: { start: number; end: number }) {
    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_awareness_update",
        payload: {
          work_id: 42,
          state: {
            session_id: sessionId,
            user_name: "alice",
            cursor: cursor === null ? null : { index: cursor },
            selection: selection ?? null,
            is_typing: false,
          },
        },
      },
    });
  }

  function remoteDelta(client: CrdtSyncClient, ops: Array<{ type: string; count?: number; text?: string }>) {
    (client as any).handleEvent({
      type: "event",
      event: { type: "crdt_text_delta", payload: { work_id: 42, ops, author_name: "bob" } },
    });
  }

  it("remote insert before another user's cursor shifts it; awareness listeners re-emit", () => {
    const client = setup("Hello World");
    seedAwareness(client, 7, 11);

    const snapshots: Array<{ index: number } | null>[] = [];
    client.onAwarenessChange((states) =>
      snapshots.push(states.map((s) => s.cursor)),
    );

    remoteDelta(client, [
      { type: "insert", text: "Oh! " },
      { type: "retain", count: 11 },
    ]);

    const map = (client as any).awarenessMap as Map<number, any>;
    expect(map.get(7).cursor).toEqual({ index: 15 });
    expect(snapshots.length).toBeGreaterThanOrEqual(1);
  });

  it("cursor inside a remote deletion collapses to the deletion start", () => {
    const client = setup("Hello World");
    seedAwareness(client, 7, 6);

    remoteDelta(client, [
      { type: "retain", count: 4 },
      { type: "delete", count: 5 },
      { type: "retain", count: 2 },
    ]);

    const map = (client as any).awarenessMap as Map<number, any>;
    expect(map.get(7).cursor).toEqual({ index: 4 });
  });

  it("selection rebases on both edges with order preserved", () => {
    const client = setup("Hello World");
    seedAwareness(client, 7, 0, { start: 3, end: 8 });

    remoteDelta(client, [
      { type: "insert", text: "ab" },
      { type: "retain", count: 11 },
    ]);

    const map = (client as any).awarenessMap as Map<number, any>;
    expect(map.get(7).selection).toEqual({ start: 5, end: 10 });
  });

  it("own typing shifts displayed remote cursors immediately (before any ack)", () => {
    const client = setup("Hello");
    (client as any).ws = {
      readyState: WebSocket.OPEN,
      send: () => {},
    };
    seedAwareness(client, 7, 5);

    client.setText("Hello!");
    const map = (client as any).awarenessMap as Map<number, any>;
    expect(map.get(7).cursor).toEqual({ index: 6 });
  });

  it("cursorless awareness entries pass through untouched", () => {
    const client = setup("Hello World");
    seedAwareness(client, 7, null);

    remoteDelta(client, [
      { type: "retain", count: 11 },
      { type: "insert", text: "!" },
    ]);

    const map = (client as any).awarenessMap as Map<number, any>;
    expect(map.get(7).cursor).toBeNull();
  });
});
