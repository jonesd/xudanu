import { describe, it, expect, beforeEach } from "vitest";
import { CrdtSyncClient } from "../api/crdt_sync";
import {
  enqueueAnnotationOp,
  pendingAnnotationOps,
  clearPendingAnnotationOps,
  mergePendingAnnotations,
  type PendingAnnotationOp,
} from "../api/annotation-queue";
import type { AnnotationEntry } from "../api/protocol";

function offlineClient(workId = 42): CrdtSyncClient {
  const client = new CrdtSyncClient("ws://test", workId);
  (client as any).ws = null;
  (client as any).connected = false;
  return client;
}

/** A ws mock that actually answers requests, so list/drain flows
 * resolve end-to-end. */
function responsiveClient(workId = 42): { client: CrdtSyncClient; sent: Array<Record<string, any>> } {
  const client = new CrdtSyncClient("ws://test", workId);
  const sent: Array<Record<string, any>> = [];
  (client as any).connected = true;
  (client as any).ws = {
    readyState: WebSocket.OPEN,
    send: (data: string) => {
      const frame = JSON.parse(data);
      sent.push(frame);
      if (frame.type === "request") {
        const value =
          frame.op === "annotation_list"
            ? { type: "ok", value: [] as AnnotationEntry[] }
            : { type: "ok", value: null };
        queueMicrotask(() => {
          (client as any).onMessage(JSON.stringify({ type: "response", id: frame.id, value }));
        });
      }
    },
  };
  return { client, sent };
}

describe("annotation-queue (memory fallback)", () => {
  beforeEach(async () => {
    await clearPendingAnnotationOps();
  });

  it("enqueues, lists per work, and removes", async () => {
    const op: PendingAnnotationOp = {
      id: "create:1", work_id: 42, kind: "create", annotation_id: 1,
      ann_kind: "comment", payload: "p", char_start: 0, char_end: 3,
      is_private: false, created_at: 1,
    };
    await enqueueAnnotationOp(op);
    await enqueueAnnotationOp({ ...op, id: "create:2", work_id: 43, annotation_id: 2 });
    expect(await pendingAnnotationOps(42)).toHaveLength(1);
    expect((await pendingAnnotationOps(42))[0].annotation_id).toBe(1);
  });

  it("mergePendingAnnotations appends creates and hides deleted ids", () => {
    const server: AnnotationEntry[] = [
      { annotation_id: 55, kind: "note", payload: "s", char_start: 0, char_end: 2, created_by: 1, created_by_name: "a", created_at: 1, is_private: false },
    ];
    const merged = mergePendingAnnotations(server, [
      { id: "delete:55", work_id: 42, kind: "delete", annotation_id: 55, created_at: 2 },
      { id: "create:9", work_id: 42, kind: "create", annotation_id: 9, ann_kind: "comment", payload: "off", char_start: 5, char_end: 8, is_private: true, created_at: 3 },
    ]);
    expect(merged).toHaveLength(1);
    expect(merged[0]).toMatchObject({ annotation_id: 9, pending_sync: true, char_start: 5, char_end: 8, is_private: true });
  });
});

/** A live ws whose every request is REJECTED with an error frame
 * (models the auth race: public session vs logged-in expectations). */
function rejectingClient(workId: number, message: string): CrdtSyncClient {
  const client = new CrdtSyncClient("ws://test", workId);
  (client as any).connected = true;
  (client as any).ws = {
    readyState: WebSocket.OPEN,
    send: (data: string) => {
      const frame = JSON.parse(data);
      if (frame.type === "request") {
        queueMicrotask(() => {
          (client as any).onMessage(JSON.stringify({ type: "error", id: frame.id, message }));
        });
      }
    },
  };
  return client;
}

describe("CrdtSyncClient — offline annotations", () => {
  beforeEach(async () => {
    await clearPendingAnnotationOps();
  });

  it("create while offline enqueues instead of throwing, and shows as pending", async () => {
    const client = offlineClient();
    await client.annotationCreate(42, 1001, "comment", "offline note", 5, 9);

    const list = await client.annotationList(42);
    expect(list).toHaveLength(1);
    expect(list[0]).toMatchObject({
      annotation_id: 1001,
      pending_sync: true,
      char_start: 5,
      char_end: 9,
      payload: "offline note",
    });
  });

  it("pending spans rebase through text deltas", async () => {
    const client = offlineClient();
    (client as any).engine.crdtReady = true;
    client.adoptServerText("Hello World");
    (client as any).workBeId = 42;
    (client as any).skipCrdt = false;

    await client.annotationCreate(42, 1001, "comment", "note", 5, 9);

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_text_delta",
        payload: {
          work_id: 42,
          ops: [{ type: "insert", text: "ab" }, { type: "retain", count: 11 }],
          author_name: "bob",
        },
      },
    });

    const list = await client.annotationList(42);
    expect(list[0]).toMatchObject({ char_start: 7, char_end: 11 });
  });

  it("deleting a pending offline create just drops it from the queue", async () => {
    const client = offlineClient();
    await client.annotationCreate(42, 1001, "comment", "note", 5, 9);
    await client.annotationDelete(42, 1001);

    expect(await client.annotationList(42)).toHaveLength(0);
    expect(await pendingAnnotationOps(42)).toHaveLength(0);
  });

  it("delete of a server annotation while offline queues for replay", async () => {
    const client = offlineClient();
    await client.annotationDelete(42, 55);

    const ops = await pendingAnnotationOps(42);
    expect(ops).toHaveLength(1);
    expect(ops[0]).toMatchObject({ kind: "delete", annotation_id: 55 });
  });

  it("replay KEEPS the op queued when the server rejects (auth race) — no silent loss", async () => {
    const off = offlineClient();
    await off.annotationCreate(42, 1002, "code_block", "", 3, 7);

    const client = rejectingClient(42, "not authorized");
    await (client as any).loadPendingAnnotations(42);
    await client.replayPendingAnnotations();

    const ops = await pendingAnnotationOps(42);
    expect(ops).toHaveLength(1);
    expect(ops[0]).toMatchObject({ kind: "create", annotation_id: 1002, char_start: 3, char_end: 7 });
  });

  it("replay drops ONLY delete-of-vanished annotations", async () => {
    const off = offlineClient();
    await off.annotationDelete(42, 555);

    const client = rejectingClient(42, "annotation not found");
    await (client as any).loadPendingAnnotations(42);
    await client.replayPendingAnnotations();

    expect(await pendingAnnotationOps(42)).toHaveLength(0);
  });

  it("reconnect drains the queue with idempotent annotation_create frames", async () => {
    // Queue a create while offline
    const off = offlineClient();
    await off.annotationCreate(42, 1001, "comment", "note", 5, 9);

    // Reconnect: same work, live socket
    const { client, sent } = responsiveClient();
    await (client as any).loadPendingAnnotations(42);
    await client.replayPendingAnnotations();

    const create = sent.find((f) => f.op === "annotation_create");
    expect(create).toBeDefined();
    expect(create!.payload).toMatchObject({
      work_id: 42,
      annotation_id: 1001,
      char_start: 5,
      char_end: 9,
    });
    expect(await pendingAnnotationOps(42)).toHaveLength(0);

    // Post-drain list: no pending residue
    const list = await client.annotationList(42);
    expect(list.filter((a) => a.pending_sync)).toHaveLength(0);
  });
});
