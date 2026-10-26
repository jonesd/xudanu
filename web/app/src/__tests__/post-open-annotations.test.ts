import { describe, it, expect, vi, beforeEach } from "vitest";
import { renderHook, act } from "@testing-library/react";

/**
 * Regression (code_block styling lost after work switch): the
 * read-data effect fired refreshAnnotations on the workBeId/
 * switchingWork transition, whose stale-closure ordering let the
 * annotation_list request race crdt_sync_open. When annotation_list
 * won, spans landed before the text existed — and any subsequent
 * text transition could corrupt them. The fix: annotations load from
 * the hook's post-open path, only after switchWork RESOLVES.
 */

const instances: Array<{
  onConnectionChange: (connected: boolean) => void;
  switchWork: ReturnType<typeof vi.fn>;
  annotationList: ReturnType<typeof vi.fn>;
  resolveSwitch: () => void;
  rejectSwitch: (e: unknown) => void;
}> = [];

vi.mock("../api/crdt_sync", () => ({
  CrdtSyncClient: class {
    offlineReading = false;
    onTextChange = vi.fn(() => () => {});
    onSaveStateChange = vi.fn(() => () => {});
    onAccessDenied = vi.fn(() => () => {});
    onAwarenessChange = vi.fn(() => () => {});
    onContentMatch = vi.fn(() => () => {});
    onIdentityChange = vi.fn(() => () => {});
    onChangeHighlights = vi.fn(() => () => {});
    onTextDeltaApplied = vi.fn(() => () => {});
    // Multi-subscriber: the hook registers TWO connection listeners
    // (state + deferred-init); a single stored callback would let the
    // no-op second subscription overwrite the real one.
    __connections: Array<(connected: boolean) => void> = [];
    onConnectionChange = vi.fn((cb: (connected: boolean) => void) => {
      (this as any).__connections.push(cb);
      return () => {
        (this as any).__connections = (this as any).__connections.filter((f: (connected: boolean) => void) => f !== cb);
      };
    });
    connect = vi.fn();
    disconnect = vi.fn();
    isConnected = vi.fn(() => true);
    getReconnectAttempt = vi.fn(() => 0);
    sendAwareness = vi.fn();
    unsubscribe = vi.fn();
    attributionQueryResolved = vi.fn(async () => []);
    attributionQuery = vi.fn(async () => []);
    attributionLogStatus = vi.fn(async () => null);

    __workOpened: Array<(workId: number) => void> = [];
    onWorkOpened = vi.fn((cb: (workId: number) => void) => {
      (this as any).__workOpened.push(cb);
      return () => {
        (this as any).__workOpened = (this as any).__workOpened.filter((f: (id: number) => void) => f !== cb);
      };
    });
    switchWork = vi.fn((workId: number) => {
      let resolve!: () => void;
      let reject!: (e: unknown) => void;
      const p = new Promise<void>((res, rej) => {
        resolve = res;
        reject = rej;
      });
      // Mirror the real client: the work-opened event fires at the
      // end of a SUCCESSFUL open (inside switchWork), never on reject.
      (this as any).__resolveSwitch = () => {
        for (const f of (this as any).__workOpened) f(workId);
        resolve();
      };
      (this as any).__rejectSwitch = reject;
      return p;
    });
    annotationList = vi.fn(async () => [
      { annotation_id: 7, kind: "code_block", payload: "", char_start: 2, char_end: 6, created_by: null, created_by_name: null, created_at: 1, is_private: false },
    ]);

    constructor() {
      // Lazy accessors: the hook assigns __onConnection when it
      // subscribes (after construction), so capture the instance,
      // not the still-undefined fields.
      const self = this as any;
      instances.push({
        onConnectionChange: (connected: boolean) =>
          self.__connections.forEach((f: (connected: boolean) => void) => f(connected)),
        switchWork: self.switchWork,
        annotationList: self.annotationList,
        resolveSwitch: () => self.__resolveSwitch(),
        rejectSwitch: (e: unknown) => self.__rejectSwitch(e),
      });
    }
  },
}));

import { useCrdtSync } from "../hooks/useCrdtSync";

describe("useCrdtSync — annotations load only after the work opens", () => {
  beforeEach(() => {
    instances.length = 0;
  });

  it("annotationList does not fire until switchWork resolves (the code_block race)", async () => {
    const { result } = renderHook(() => useCrdtSync("ws://test", 42));
    const inst = instances[instances.length - 1]; // StrictMode double-mount: the live client is the last one
    expect(inst).toBeDefined();

    // Connection comes up: the switch starts, its promise is PENDING
    await act(async () => {
      inst.onConnectionChange(true);
    });
    expect(inst.switchWork).toHaveBeenCalledWith(42);
    expect(inst.annotationList).not.toHaveBeenCalled();

    // The open resolves (text adopted) — only now may spans load
    await act(async () => {
      inst.resolveSwitch();
    });

    expect(inst.annotationList).toHaveBeenCalledWith(42);
    expect(result.current.annotations).toHaveLength(1);
    expect(result.current.annotations[0]).toMatchObject({ kind: "code_block", char_start: 2, char_end: 6 });
  });

  it("a failed switch never fetches spans for a work that did not open", async () => {
    const { result } = renderHook(() => useCrdtSync("ws://test", 99));
    const inst = instances[instances.length - 1]; // StrictMode double-mount: the live client is the last one

    await act(async () => {
      inst.onConnectionChange(true);
    });
    expect(inst.switchWork).toHaveBeenCalledWith(99);

    // Reject the switch (e.g. access denied): no annotation load
    await act(async () => {
      inst.rejectSwitch(new Error("not authorized"));
    });
    expect(inst.annotationList).not.toHaveBeenCalled();
    expect(result.current.annotations).toHaveLength(0);
  });
});
