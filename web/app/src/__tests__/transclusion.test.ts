import { describe, it, expect, vi } from "vitest";
import { CrdtSyncClient } from "../api/crdt_sync";

describe("Transclusion delta computation", () => {
  it("computes insert-only delta when excerpt is appended", () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const sentFrames: Array<{ op: string; payload?: object }> = [];
    (client as any).crdtReady = true;
    (client as any).text = "Hello";
    (client as any).ws = {
      readyState: WebSocket.OPEN,
      send: (data: string) => {
        const frame = JSON.parse(data);
        sentFrames.push({ op: frame.op, payload: frame.payload });
      },
    };

    client.setText("Hello World");
    expect(sentFrames).toHaveLength(1);
    expect(sentFrames[0].op).toBe("work_revise_delta");
    const ops = (sentFrames[0].payload as { ops: unknown[] }).ops;
    // sendTextDelta emits minimal delta: prefix retain + insert (no trailing retain)
    expect(ops).toEqual([
      { type: "retain", count: 5 },
      { type: "insert", text: " World" },
    ]);
  });

  it("computes insert-at-position delta for excerpt insertion", () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const sentFrames: Array<{ op: string; payload?: object }> = [];
    (client as any).crdtReady = true;
    (client as any).text = "Hello World";
    (client as any).ws = {
      readyState: WebSocket.OPEN,
      send: (data: string) => {
        const frame = JSON.parse(data);
        sentFrames.push({ op: frame.op, payload: frame.payload });
      },
    };

    const oldText = "Hello World";
    const excerpt = "beautiful ";
    const position = 6;
    const newText = oldText.slice(0, position) + excerpt + oldText.slice(position);
    client.setText(newText);

    expect(sentFrames).toHaveLength(1);
    const ops = (sentFrames[0].payload as { ops: unknown[] }).ops;
    // Minimal delta: retain prefix + insert (no trailing retain for suffix)
    expect(ops).toEqual([
      { type: "retain", count: 6 },
      { type: "insert", text: "beautiful " },
    ]);
  });

  it("computes delete delta when text is removed", () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const sentFrames: Array<{ op: string; payload?: object }> = [];
    (client as any).crdtReady = true;
    (client as any).text = "Hello World";
    (client as any).ws = {
      readyState: WebSocket.OPEN,
      send: (data: string) => {
        const frame = JSON.parse(data);
        sentFrames.push({ op: frame.op, payload: frame.payload });
      },
    };

    client.setText("Hello");
    const ops = (sentFrames[0].payload as { ops: unknown[] }).ops;
    expect(ops).toEqual([
      { type: "retain", count: 5 },
      { type: "delete", count: 6 },
    ]);
  });

  it("does not send delta when text is unchanged", () => {
    const client = new CrdtSyncClient("ws://test", 1);
    let sendCount = 0;
    (client as any).crdtReady = true;
    (client as any).text = "Hello";
    (client as any).ws = {
      readyState: WebSocket.OPEN,
      send: () => { sendCount++; },
    };

    client.setText("Hello");
    expect(sendCount).toBe(0);
  });

  it("fires text listeners on setText", () => {
    const client = new CrdtSyncClient("ws://test", 1);
    (client as any).crdtReady = true;
    (client as any).text = "Hello";
    (client as any).ws = { readyState: WebSocket.OPEN, send: () => {} };

    const newTexts: string[] = [];
    client.onTextChange((t) => newTexts.push(t));

    client.setText("Hello World");
    expect(newTexts).toEqual(["Hello World"]);
  });
});

describe("Event handling: work_revised does not clobber text", () => {
  const originalText = "Hello World";

  function setupClient(): CrdtSyncClient {
    const client = new CrdtSyncClient("ws://test", 42);
    (client as any).crdtReady = true;
    (client as any).text = originalText;
    (client as any).workBeId = 42;
    (client as any).skipCrdt = false;
    return client;
  }

  it("does NOT change text when work_revised is received", () => {
    const client = setupClient();
    const texts: string[] = [];
    client.onTextChange((t) => texts.push(t));

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "work_revised",
        payload: { work_be_id: 42, revision: 5, session_id: 1 },
      },
    });

    expect(client.getText()).toBe(originalText);
    expect(texts).toHaveLength(0);
  });

  it("does NOT call refreshText on work_revised", () => {
    const client = setupClient();
    const refreshSpy = vi.spyOn(client as any, "refreshText");

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "work_revised",
        payload: { work_be_id: 42, revision: 5, session_id: 1 },
      },
    });

    expect(refreshSpy).not.toHaveBeenCalled();
  });

  it("does NOT change text on repeated work_revised events (materialization)", () => {
    const client = setupClient();

    for (let i = 1; i <= 5; i++) {
      (client as any).handleEvent({
        type: "event",
        event: {
          type: "work_revised",
          payload: { work_be_id: 42, revision: i, session_id: 1 },
        },
      });
    }

    expect(client.getText()).toBe(originalText);
  });

  it("ignores work_revised for other works", () => {
    const client = setupClient();

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "work_revised",
        payload: { work_be_id: 99, revision: 1, session_id: 1 },
      },
    });

    expect(client.getText()).toBe(originalText);
  });
});

describe("Event handling: crdt_text_update applies remote text", () => {
  function setupClient(text = "Hello World"): CrdtSyncClient {
    const client = new CrdtSyncClient("ws://test", 42);
    (client as any).crdtReady = true;
    (client as any).text = text;
    (client as any).workBeId = 42;
    (client as any).skipCrdt = false;
    return client;
  }

  it("updates text when crdt_text_update received from remote merge", () => {
    const client = setupClient("Hello World");
    const texts: string[] = [];
    client.onTextChange((t) => texts.push(t));

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_text_update",
        payload: { work_id: 42, text: "Hello Beautiful World" },
      },
    });

    expect(client.getText()).toBe("Hello Beautiful World");
    expect(texts).toEqual(["Hello Beautiful World"]);
  });

  it("does not fire listeners when text is same", () => {
    const client = setupClient("Hello World");
    const texts: string[] = [];
    client.onTextChange((t) => texts.push(t));

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_text_update",
        payload: { work_id: 42, text: "Hello World" },
      },
    });

    expect(texts).toHaveLength(0);
  });

  it("ignores crdt_text_update when skipCrdt is true", () => {
    const client = setupClient("Hello World");
    (client as any).skipCrdt = true;

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_text_update",
        payload: { work_id: 42, text: "Changed" },
      },
    });

    expect(client.getText()).toBe("Hello World");
  });

  it("ignores crdt_text_update for other works", () => {
    const client = setupClient("Hello World");

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_text_update",
        payload: { work_id: 99, text: "Changed" },
      },
    });

    expect(client.getText()).toBe("Hello World");
  });
});

describe("Event handling: crdt_text_delta applies remote deltas", () => {
  function setupClient(text = "Hello World"): CrdtSyncClient {
    const client = new CrdtSyncClient("ws://test", 42);
    (client as any).crdtReady = true;
    (client as any).text = text;
    (client as any).workBeId = 42;
    (client as any).skipCrdt = false;
    return client;
  }

  it("applies insert delta from remote session", () => {
    const client = setupClient("Hello World");
    // Insert " Beautiful" after "Hello" — must consume full 11-char text
    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_text_delta",
        payload: {
          work_id: 42,
          ops: [
            { type: "retain", count: 5 },
            { type: "insert", text: " Beautiful" },
            { type: "retain", count: 6 },
          ],
        },
      },
    });

    expect(client.getText()).toBe("Hello Beautiful World");
  });

  it("applies delete delta from remote session", () => {
    const client = setupClient("Hello Beautiful World");
    // Delete " Beautiful" (10 chars) — must consume full 21-char text
    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_text_delta",
        payload: {
          work_id: 42,
          ops: [
            { type: "retain", count: 5 },
            { type: "delete", count: 10 },
            { type: "retain", count: 6 },
          ],
        },
      },
    });

    expect(client.getText()).toBe("Hello World");
  });
});

describe("Transclusion placement simulation", () => {
  it("simulates text insertion for transclusion placement", () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const sentFrames: Array<{ op: string; payload?: object }> = [];
    (client as any).crdtReady = true;
    (client as any).text = "Hello World";
    (client as any).workBeId = 1;
    (client as any).ws = {
      readyState: WebSocket.OPEN,
      send: (data: string) => {
        const frame = JSON.parse(data);
        sentFrames.push({ op: frame.op, payload: frame.payload });
      },
    };

    const excerpt = "beautiful ";
    const position = 6;
    const oldText = client.getText();
    const newText = oldText.slice(0, position) + excerpt + oldText.slice(position);
    client.setText(newText);

    expect(client.getText()).toBe("Hello beautiful World");

    const deltaFrame = sentFrames.find((f) => f.op === "work_revise_delta");
    expect(deltaFrame).toBeDefined();
    const ops = (deltaFrame!.payload as { ops: unknown[] }).ops;
    expect(ops).toEqual([
      { type: "retain", count: 6 },
      { type: "insert", text: "beautiful " },
    ]);
  });

  it("text remains editable after work_revised echo following transclusion", () => {
    const client = new CrdtSyncClient("ws://test", 42);
    (client as any).crdtReady = true;
    (client as any).text = "Hello beautiful World";
    (client as any).workBeId = 42;
    (client as any).skipCrdt = false;

    const sentFrames: Array<{ op: string; payload?: object }> = [];
    (client as any).ws = {
      readyState: WebSocket.OPEN,
      send: (data: string) => {
        const frame = JSON.parse(data);
        sentFrames.push({ op: frame.op, payload: frame.payload });
      },
    };

    // Simulate server materialization firing work_revised
    (client as any).handleEvent({
      type: "event",
      event: {
        type: "work_revised",
        payload: { work_be_id: 42, revision: 3, session_id: 1 },
      },
    });

    // Text must be unchanged
    expect(client.getText()).toBe("Hello beautiful World");

    // User continues typing after transclusion
    client.setText("Hello beautiful World!");
    expect(client.getText()).toBe("Hello beautiful World!");

    const deltaFrame = sentFrames.find((f) => f.op === "work_revise_delta");
    expect(deltaFrame).toBeDefined();
    const ops = (deltaFrame!.payload as { ops: unknown[] }).ops;
    expect(ops).toEqual([
      { type: "retain", count: 21 },
      { type: "insert", text: "!" },
    ]);
  });

  it("multiple transclusions can be placed sequentially", () => {
    const client = new CrdtSyncClient("ws://test", 1);
    const sentFrames: Array<{ op: string; payload?: object }> = [];
    (client as any).crdtReady = true;
    (client as any).text = "Start End";
    (client as any).workBeId = 1;
    (client as any).ws = {
      readyState: WebSocket.OPEN,
      send: (data: string) => {
        const frame = JSON.parse(data);
        sentFrames.push({ op: frame.op, payload: frame.payload });
      },
    };

    // First transclusion: insert "ONE " at position 6
    let text = client.getText();
    text = text.slice(0, 6) + "ONE " + text.slice(6);
    client.setText(text);
    expect(client.getText()).toBe("Start ONE End");

    // Second transclusion: insert "TWO " before "End" (position 10 in "Start ONE End")
    text = client.getText();
    text = text.slice(0, 10) + "TWO " + text.slice(10);
    client.setText(text);
    expect(client.getText()).toBe("Start ONE TWO End");

    const deltas = sentFrames.filter((f) => f.op === "work_revise_delta");
    expect(deltas).toHaveLength(2);
  });

  it("editing after transclusion with work_revised arriving mid-edit", () => {
    const client = new CrdtSyncClient("ws://test", 42);
    (client as any).crdtReady = true;
    (client as any).text = "Hello excerpt World";
    (client as any).workBeId = 42;
    (client as any).skipCrdt = false;

    const sentFrames: Array<{ op: string; payload?: object }> = [];
    (client as any).ws = {
      readyState: WebSocket.OPEN,
      send: (data: string) => {
        const frame = JSON.parse(data);
        sentFrames.push({ op: frame.op, payload: frame.payload });
      },
    };

    // User types a character
    client.setText("Hello excerpt World!");
    expect(client.getText()).toBe("Hello excerpt World!");

    // Server fires work_revised (from materialization)
    (client as any).handleEvent({
      type: "event",
      event: {
        type: "work_revised",
        payload: { work_be_id: 42, revision: 10, session_id: 1 },
      },
    });

    // Text must not have been clobbered
    expect(client.getText()).toBe("Hello excerpt World!");

    // User types again
    client.setText("Hello excerpt World!!!");
    expect(client.getText()).toBe("Hello excerpt World!!!");

    const deltas = sentFrames.filter((f) => f.op === "work_revise_delta");
    expect(deltas).toHaveLength(2);
  });
});

describe("Delta application correctness", () => {
  it("applyDeltaOps handles pure insert", () => {
    const client = new CrdtSyncClient("ws://test", 42);
    (client as any).crdtReady = true;
    (client as any).text = "ABC";
    (client as any).workBeId = 42;
    (client as any).skipCrdt = false;

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_text_delta",
        payload: {
          work_id: 42,
          ops: [
            { type: "retain", count: 1 },
            { type: "insert", text: "X" },
            { type: "retain", count: 2 },
          ],
        },
      },
    });

    expect(client.getText()).toBe("AXBC");
  });

  it("applyDeltaOps handles replace (delete + insert)", () => {
    const client = new CrdtSyncClient("ws://test", 42);
    (client as any).crdtReady = true;
    (client as any).text = "ABC";
    (client as any).workBeId = 42;
    (client as any).skipCrdt = false;

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_text_delta",
        payload: {
          work_id: 42,
          ops: [
            { type: "retain", count: 1 },
            { type: "delete", count: 1 },
            { type: "insert", text: "XYZ" },
            { type: "retain", count: 1 },
          ],
        },
      },
    });

    expect(client.getText()).toBe("AXYZC");
  });

  it("falls back to refreshText on invalid delta ops", () => {
    const client = new CrdtSyncClient("ws://test", 42);
    (client as any).crdtReady = true;
    (client as any).text = "ABC";
    (client as any).workBeId = 42;
    (client as any).skipCrdt = false;

    const refreshSpy = vi.spyOn(client as any, "refreshText").mockImplementation(() => {});

    (client as any).handleEvent({
      type: "event",
      event: {
        type: "crdt_text_delta",
        payload: {
          work_id: 42,
          ops: [{ type: "retain", count: 100 }],
        },
      },
    });

    expect(refreshSpy).toHaveBeenCalled();
  });
});
