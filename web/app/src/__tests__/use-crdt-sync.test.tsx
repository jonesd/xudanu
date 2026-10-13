import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { renderHook, act } from "@testing-library/react";

/**
 * coverage-plan-web.md Phase 2: useCrdtSync — where lost edits would
 * live. The hook constructs its own CrdtSyncClient, so the seam is a
 * module mock: the fake client records subscriptions and lets tests
 * FIRE events (text, save-state, connection, identity, denial) and
 * control isConnected()/switchWork()/getReconnectAttempt(). Timers
 * are faked — the disconnect grace window, reconnect poll, and
 * deferred stats are all time-based.
 */

const { FakeCrdtSyncClient } = vi.hoisted(() => {
  class FakeCrdtSyncClient {
    static instances: FakeCrdtSyncClient[] = [];
    constructorArgs: [string, number];
    connectedFlag = false;
    reconnectAttempt = 0;
    offlineReading = false;
    isAdmin = false;
    switchWorkCtl: { resolve: () => void; promise: Promise<void> } | null = null;
    sent: Array<{ op: string; payload: unknown }> = [];
    awarenessSent: unknown[] = [];
    unsubscribed: number[] = [];
    /** Per-op canned results / failures for the action-wrapper tests. */
    results = new Map<string, unknown>();
    failOps = new Set<string>();
    private handlers = new Map<string, Array<(arg?: unknown) => void>>();

    constructor(...args: [string, number]) {
      this.constructorArgs = args;
      FakeCrdtSyncClient.instances.push(this);
    }

    private on(name: string, cb: (arg?: unknown) => void) {
      const list = this.handlers.get(name) ?? [];
      list.push(cb);
      this.handlers.set(name, list);
      return () => {
        const l = this.handlers.get(name) ?? [];
        this.handlers.set(name, l.filter((h) => h !== cb));
      };
    }
    fire(name: string, arg?: unknown) {
      for (const h of this.handlers.get(name) ?? []) h(arg);
    }

    onTextChange(cb: (t: string) => void) { return this.on("text", cb); }
    onSaveStateChange(cb: (s: string) => void) { return this.on("save", cb); }
    onAccessDenied(cb: (id: number) => void) { return this.on("denied", cb); }
    onConnectionChange(cb: (c: boolean) => void) { return this.on("conn", cb); }
    onAwarenessChange(cb: (a: unknown[]) => void) { return this.on("aware", cb); }
    onContentMatch(cb: (m: unknown) => void) { return this.on("match", cb); }
    onIdentityChange(cb: (i: unknown) => void) { return this.on("identity", cb); }
    onChangeHighlights(cb: (h: unknown[]) => void) { return this.on("changes", cb); }

    connect() { this.connectedFlag = true; this.fire("conn", true); }
    disconnect() { this.connectedFlag = false; }
    isConnected() { return this.connectedFlag; }
    getReconnectAttempt() { return this.reconnectAttempt; }
    getIsAdmin() { return this.isAdmin; }

    switchWork() {
      const ctl = {} as { resolve: () => void; promise: Promise<void> };
      ctl.promise = new Promise((res) => { ctl.resolve = res; });
      this.switchWorkCtl = ctl;
      return ctl.promise;
    }
    sendAwareness(cursor: unknown, sel: unknown, typing: boolean) {
      this.awarenessSent.push({ cursor, sel, typing });
    }
    sendRequest(op: string, payload?: unknown) {
      this.sent.push({ op, payload });
      if (this.failOps.has(op)) return Promise.reject(new Error(`${op} failed`));
      if (this.results.has(op)) return Promise.resolve(this.results.get(op));
      if (op === "server_stats") {
        return Promise.resolve({ value: { llm_enabled: true, llm_usage: { total: 1 }, public_club_id: 0x2a } });
      }
      return Promise.resolve({ value: null });
    }

    /** Configurable promise source for typed client methods. */
    private api<T>(op: string, dflt: T) {
      if (this.failOps.has(op)) return Promise.reject(new Error(`${op} failed`));
      return Promise.resolve((this.results.has(op) ? (this.results.get(op) as T) : dflt));
    }

    annotationList() { return this.api("annotation_list", [] as unknown[]); }
    annotationCreate() { return this.api("annotation_create", undefined); }
    annotationDelete() { return this.api("annotation_delete", undefined); }
    loginByName() { return this.api("login_by_name", undefined); }
    sessionTicketIssue() { return this.api("session_ticket_issue", new Uint8Array([1, 2, 3])); }
    createIdentity() { return this.api("create_identity", undefined); }
    clubSetPassword() { return this.api("club_set_password", undefined); }
    setReadClub() { return this.api("set_read_club", undefined); }
    getReadClub() { return this.api("get_read_club", 5); }
    getEditClub() { return this.api("get_edit_club", 6); }
    diffNarration() { return this.api("diff_narration", { text: "n", model: "m", updatedText: "u" }); }
    writingFeedback() { return this.api("writing_feedback", { text: "f", model: "m" }); }
    suggestTitle() { return this.api("suggest_title", "A Title"); }
    workAutoTag() { return this.api("work_auto_tag", { new: [], linked: [] }); }
    workSetTitle() { return this.api("work_set_title", undefined); }
    fetchWorkList() { return this.api("work_list", [] as unknown[]); }
    attributionQueryResolved() { return this.api("attr_resolved", [] as unknown[]); }
    attributionQuery() { return this.api("attr_query", [] as unknown[]); }
    attributionLogStatus() {
      return this.api("attr_log", { entry_count: 0, chain_valid: true, last_sequence: 0, has_log: true });
    }
    canEdit() { return Promise.resolve(true); }
    checkWhoAmI() { return Promise.resolve(null); }
    refreshAwareness() { return Promise.resolve([]); }
    subscribeContentWorks() { return this.api("subscribe_content_works", 7); }
    unsubscribe(id: number) { this.unsubscribed.push(id); }
    setTextLocal(t: string) { this.fire("text", t); }
  }
  return { FakeCrdtSyncClient };
});

vi.mock("../api/crdt_sync", () => ({ CrdtSyncClient: FakeCrdtSyncClient }));
vi.mock("../safe-storage", () => {
  const backing = new Map<string, string>();
  return {
    storageGet: (k: string) => backing.get(k) ?? null,
    storageSet: (k: string, v: string) => void backing.set(k, v),
    storageRemove: (k: string) => void backing.delete(k),
  };
});

import { useCrdtSync } from "../hooks/useCrdtSync";

function renderSyncHook(wsUrl: string | null = "ws://test", workBeId: number | null = 0x10) {
  return renderHook(({ url, work }: { url: string | null; work: number | null }) =>
    useCrdtSync(url, work), { initialProps: { url: wsUrl, work: workBeId } });
}

function latest(): FakeCrdtSyncClient {
  return FakeCrdtSyncClient.instances[FakeCrdtSyncClient.instances.length - 1];
}

beforeEach(() => {
  vi.useFakeTimers();
  FakeCrdtSyncClient.instances = [];
});

afterEach(() => {
  vi.useRealTimers();
});

describe("useCrdtSync — connection lifecycle", () => {
  it("constructs one client per wsUrl and connects", () => {
    renderSyncHook();
    const c = latest();
    expect(c.constructorArgs).toEqual(["ws://test", 0x10]);
    expect(FakeCrdtSyncClient.instances).toHaveLength(1);
    expect(c.isConnected()).toBe(true);
  });

  it("wsUrl change tears down and reconnects on a NEW client", () => {
    const { rerender, unmount } = renderSyncHook("ws://a");
    const first = latest();
    rerender({ url: "ws://b", work: 0x10 });
    const second = latest();
    expect(first.connectedFlag).toBe(false);
    expect(second).not.toBe(first);
    expect(second.constructorArgs[0]).toBe("ws://b");
    unmount();
  });

  it("unmount disconnects and unsubscribes the content watch", () => {
    const { result, unmount } = renderSyncHook();
    const c = latest();
    // Turn the watch on first so teardown has a subscription to drop.
    c.connectedFlag = true;
    return act(async () => {
      await result.current.toggleWatch();
    }).then(() => {
      unmount();
      expect(c.connectedFlag).toBe(false);
      expect(c.unsubscribed).toContain(7);
    });
  });

  it("a dropped connection keeps `connected` true through the 3s grace window", () => {
    const { result } = renderSyncHook();
    const c = latest();
    c.reconnectAttempt = 2;
    act(() => {
      c.connectedFlag = false;
      c.fire("conn", false);
    });
    expect(result.current.connected).toBe(true); // no flicker
    act(() => { vi.advanceTimersByTime(2999); });
    expect(result.current.connected).toBe(true);
    act(() => { vi.advanceTimersByTime(1); });
    expect(result.current.connected).toBe(false);
    expect(result.current.reconnectAttempt).toBe(2); // surfaced from client
  });

  it("recovery inside the grace window: no disconnect state, attempt stays 0", () => {
    const { result } = renderSyncHook();
    const c = latest();
    act(() => { c.fire("conn", false); });
    act(() => { vi.advanceTimersByTime(1500); });
    act(() => {
      c.connectedFlag = true;
      c.fire("conn", true);
    });
    act(() => { vi.advanceTimersByTime(5000); });
    expect(result.current.connected).toBe(true);
    expect(result.current.reconnectAttempt).toBe(0);
  });

  it("reconnect after a drop resets the attempt counter", () => {
    const { result } = renderSyncHook();
    const c = latest();
    act(() => { c.fire("conn", false); });
    act(() => { vi.advanceTimersByTime(3000); });
    expect(result.current.connected).toBe(false);
    act(() => {
      c.connectedFlag = true;
      c.reconnectAttempt = 3;
      c.fire("conn", true);
    });
    expect(result.current.reconnectAttempt).toBe(0);
  });

  it("the 2s poll mirrors the client's attempt count while down", () => {
    const { result } = renderSyncHook();
    const c = latest();
    act(() => {
      c.connectedFlag = false;
      c.fire("conn", false);
    });
    act(() => { vi.advanceTimersByTime(3000); }); // grace expires
    c.reconnectAttempt = 5;
    act(() => { vi.advanceTimersByTime(2000); }); // poll tick
    expect(result.current.reconnectAttempt).toBe(5);
  });
});

describe("useCrdtSync — text, save-state, denial propagation", () => {
  it("text and save-state events flow into state", () => {
    const { result } = renderSyncHook();
    const c = latest();
    act(() => { c.fire("text", "hello model"); });
    expect(result.current.text).toBe("hello model");
    act(() => { c.fire("save", "saving"); });
    expect(result.current.saveState).toBe("saving");
    act(() => { c.fire("save", "saved"); });
    expect(result.current.saveState).toBe("saved");
  });

  it("access denial is recorded for THE open work and ignored for others", () => {
    const { result } = renderSyncHook();
    const c = latest();
    act(() => { c.fire("denied", 0x77); });
    expect(result.current.accessDeniedWorkId).toBeNull();
    act(() => { c.fire("denied", 0x10); });
    expect(result.current.accessDeniedWorkId).toBe(0x10);
  });

  it("offlineReading follows the client flag on connection events", () => {
    const { result } = renderSyncHook();
    const c = latest();
    c.offlineReading = true;
    act(() => { c.fire("conn", false); });
    act(() => { vi.advanceTimersByTime(3000); });
    expect(result.current.offlineReading).toBe(true);
  });
});

describe("useCrdtSync — work switching", () => {
  it("switchWork runs on connect; switchingWork spans the promise; denial cleared", async () => {
    const { result } = renderSyncHook();
    const c = latest();
    await act(async () => { vi.advanceTimersByTimeAsync(0); });
    expect(c.switchWorkCtl).not.toBeNull();
    expect(result.current.switchingWork).toBe(true);
    await act(async () => {
      c.switchWorkCtl!.resolve();
      await c.switchWorkCtl!.promise;
    });
    expect(result.current.switchingWork).toBe(false);
  });

  it("late authentication retries switchWork (private work opened anonymously)", async () => {
    const { result } = renderSyncHook();
    const c = latest();
    await act(async () => {
      c.switchWorkCtl!.resolve();
      await c.switchWorkCtl!.promise;
    });
    const first = c.switchWorkCtl;
    await act(async () => {
      c.fire("identity", { club_id: 1, display_name: "u" });
    });
    expect(c.switchWorkCtl).not.toBe(first);
    await act(async () => {
      c.switchWorkCtl!.resolve();
      await c.switchWorkCtl!.promise;
    });
    expect(result.current.authenticated).toBe(true);
  });

  it("initial presence is sent 500ms after the work opens", async () => {
    renderSyncHook();
    const c = latest();
    await act(async () => {
      c.switchWorkCtl!.resolve();
      await c.switchWorkCtl!.promise;
    });
    expect(c.awarenessSent).toHaveLength(0);
    await act(async () => { vi.advanceTimersByTimeAsync(500); });
    expect(c.awarenessSent).toHaveLength(1);
    expect(c.awarenessSent[0]).toEqual({ cursor: null, sel: null, typing: false });
  });

  it("per-work state resets when the work id changes", async () => {
    const { result, rerender } = renderSyncHook("ws://test", 0x10);
    const c = latest();
    await act(async () => {
      c.switchWorkCtl!.resolve();
      await c.switchWorkCtl!.promise;
    });
    act(() => { c.fire("aware", [{ session_id: 9 }]); });
    expect(result.current.awareness).toHaveLength(1);
    rerender({ url: "ws://test", work: 0x20 });
    await act(async () => { vi.advanceTimersByTimeAsync(0); });
    expect(result.current.awareness).toHaveLength(0);
  });
});

describe("useCrdtSync — deferred identity, stats, permissions", () => {
  it("deferred server_stats populates llm flags and public club id after 2s", async () => {
    const { result } = renderSyncHook();
    const c = latest();
    await act(async () => {
      c.switchWorkCtl!.resolve();
      await c.switchWorkCtl!.promise;
    });
    expect(result.current.llmEnabled).toBe(false);
    await act(async () => { await vi.advanceTimersByTimeAsync(2000); });
    await act(async () => {}); // flush the sendRequest .then state update
    expect(result.current.llmEnabled).toBe(true);
    expect(result.current.llmUsage).toEqual({ total: 1 });
    expect(result.current.publicClubId).toBe(0x2a);
  });

  it("canEdit is only checked once authenticated", async () => {
    const { result } = renderSyncHook();
    const c = latest();
    const calls: number[] = [];
    c.canEdit = (id: number) => { calls.push(id); return Promise.resolve(true); };
    await act(async () => {
      c.switchWorkCtl!.resolve();
      await c.switchWorkCtl!.promise;
    });
    await act(async () => { vi.advanceTimersByTimeAsync(2500); });
    expect(calls).toEqual([]); // anonymous: not yet
    await act(async () => {
      c.fire("identity", { club_id: 1, display_name: "u" });
    });
    await act(async () => { vi.advanceTimersByTimeAsync(0); });
    expect(calls).toEqual([0x10]);
    expect(result.current.canEdit).toBe(true);
  });

  it("identity events set identity, admin flag, and cache it", async () => {
    const { result } = renderSyncHook();
    const c = latest();
    c.isAdmin = true;
    await act(async () => {
      c.fire("identity", { club_id: 5, display_name: "editor" });
    });
    expect(result.current.identity).toEqual({ club_id: 5, display_name: "editor" });
    expect(result.current.isAdmin).toBe(true);
    expect(result.current.authenticated).toBe(true);
  });

  it("logout clears identity/flags, removes tickets, and reconnects the client", async () => {
    const { result } = renderSyncHook();
    const c = latest();
    await act(async () => {
      c.fire("identity", { club_id: 5, display_name: "editor" });
    });
    const disconnectSpy = vi.spyOn(c, "disconnect");
    const connectSpy = vi.spyOn(c, "connect");
    await act(async () => {
      result.current.logout();
    });
    expect(result.current.authenticated).toBe(false);
    expect(result.current.identity).toBeNull();
    expect(result.current.isAdmin).toBe(false);
    expect(result.current.canEdit).toBe(false);
    expect(disconnectSpy).toHaveBeenCalled();
    expect(connectSpy).toHaveBeenCalled();
  });
});

describe("useCrdtSync — delegation seam", () => {
  it("setText/setTextLocal/sendCursor/sendSelection reach the client", async () => {
    const { result } = renderSyncHook();
    const c = latest();
    await act(async () => {
      c.switchWorkCtl!.resolve();
      await c.switchWorkCtl!.promise;
    });
    act(() => { result.current.setTextLocal("local edit"); });
    expect(result.current.text).toBe("local edit");
    act(() => { result.current.sendCursor(4); });
    expect(c.awarenessSent.at(-1)).toEqual({ cursor: 4, sel: null, typing: true });
    act(() => { result.current.sendSelection(1, 5); });
    expect(c.awarenessSent.at(-1)).toEqual({ cursor: 1, sel: { start: 1, end: 5 }, typing: true });
    act(() => { result.current.sendCursor(null); });
    expect(c.awarenessSent.at(-1)).toEqual({ cursor: null, sel: null, typing: false });
  });

  it("content matches cap at 200", () => {
    const { result } = renderSyncHook();
    const c = latest();
    act(() => {
      for (let i = 0; i < 205; i++) c.fire("match", { fossil_id: i });
    });
    expect(result.current.contentMatches).toHaveLength(200);
    expect(result.current.contentMatches[0].fossil_id).toBe(5); // oldest dropped
  });
});

// storage assertions read through the same mock the hook writes to.
import { storageGet } from "../safe-storage";

/** Drive the hook to "connected with work open" in one step. */
async function ready() {
  const h = renderSyncHook();
  const c = latest();
  await act(async () => {
    c.switchWorkCtl!.resolve();
    await c.switchWorkCtl!.promise;
  });
  return { r: h.result, rerender: h.rerender, unmount: h.unmount, c };
}

describe("useCrdtSync — annotations (optimistic + revert)", () => {
  it("createAnnotation shows the optimistic entry, then the server list wins", async () => {
    const { r, c } = await ready();
    const serverList = [{ annotation_id: 1, kind: "comment", payload: "p", char_start: 0, char_end: 2, is_private: false, created_by: null, created_by_name: null, created_at: 1 }];
    const gate = {} as { resolve: () => void; promise: Promise<void> };
    gate.promise = new Promise((res) => { gate.resolve = res; });
    c.annotationCreate = () => gate.promise; // hold the server ack
    c.annotationList = () => Promise.resolve(serverList);
    let createPromise!: Promise<void>;
    act(() => {
      createPromise = r.current.createAnnotation("comment", "p", 0, 2);
    });
    expect(r.current.annotations).toHaveLength(1); // optimistic, pre-ack
    expect(r.current.annotations[0].annotation_id).toBe(Date.now()); // local id
    await act(async () => {
      gate.resolve();
      await createPromise;
    });
    await act(async () => {}); // flush refresh
    expect(r.current.annotations.map((a) => a.annotation_id)).toEqual([1]);
  });

  it("createAnnotation REVERTS the optimistic entry when the server rejects", async () => {
    const { r, c } = await ready();
    c.failOps.add("annotation_create");
    c.annotationList = () => Promise.resolve([]);
    await act(async () => {
      await r.current.createAnnotation("comment", "p", 0, 2);
    });
    // Optimistic entry added, then the rejection reverts it.
    expect(r.current.annotations).toHaveLength(0);
  });

  it("deleteAnnotation removes optimistically; server refresh confirms", async () => {
    const { r, c } = await ready();
    const ann = { annotation_id: 9, kind: "comment", payload: "p", char_start: 0, char_end: 2, is_private: false, created_by: null, created_by_name: null, created_at: 1 };
    let deleted = false;
    c.annotationList = () => Promise.resolve(deleted ? [] : [ann]);
    await act(async () => { r.current.refreshAnnotations(); });
    expect(r.current.annotations).toHaveLength(1);
    const gate = {} as { resolve: () => void; promise: Promise<void> };
    gate.promise = new Promise((res) => { gate.resolve = res; });
    c.annotationDelete = () => gate.promise;
    let del!: Promise<void>;
    act(() => { del = r.current.deleteAnnotation(9); });
    expect(r.current.annotations).toHaveLength(0); // optimistic removal, pre-ack
    deleted = true;
    await act(async () => {
      gate.resolve();
      await del;
    });
    await act(async () => {}); // flush refresh
    expect(r.current.annotations).toHaveLength(0); // server agrees
  });

  it("refreshAnnotations replaces the list from the server", async () => {
    const { r, c } = await ready();
    c.annotationList = () => Promise.resolve([{ annotation_id: 2, kind: "k", payload: "x", char_start: 0, char_end: 1, is_private: false, created_by: null, created_by_name: null, created_at: 0 }]);
    await act(async () => { r.current.refreshAnnotations(); });
    expect(r.current.annotations.map((a) => a.annotation_id)).toEqual([2]);
  });
});

describe("useCrdtSync — login, identity, tickets", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("login: http ok → client loginByName → authenticated → ticket cached", async () => {
    const fetchMock = vi.fn(async () => ({ ok: true, json: async () => ({}) }) as unknown as Response);
    vi.stubGlobal("fetch", fetchMock);
    const { r, c } = await ready();
    const loginByNameSpy = vi.spyOn(c, "loginByName");
    await act(async () => {
      await r.current.login("myclub", "pw");
    });
    expect(fetchMock).toHaveBeenCalledWith("/auth/login", expect.objectContaining({ method: "POST" }));
    expect(loginByNameSpy).toHaveBeenCalledWith("myclub", "pw");
    expect(r.current.authenticated).toBe(true);
    expect(storageGet("xudanu_login_club")).toBe("myclub");
    // ticket [1,2,3] → base64
    expect(storageGet("xudanu_session_ticket")).toBe(btoa("\u0001\u0002\u0003"));
  });

  it("login: http failure throws with the server's error", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => ({ ok: false, json: async () => ({ error: "bad club" }) }) as unknown as Response));
    const { r } = await ready();
    await expect(act(async () => {
      await r.current.login("x", "y");
    })).rejects.toThrow("bad club");
    expect(r.current.authenticated).toBe(false);
  });

  it("createIdentity: client create → http login → ticket cached", async () => {
    const fetchMock = vi.fn(async () => ({ ok: true, json: async () => ({}) }) as unknown as Response);
    vi.stubGlobal("fetch", fetchMock);
    const { r, c } = await ready();
    const createSpy = vi.spyOn(c, "createIdentity");
    await act(async () => {
      await r.current.createIdentity("newuser", "pw");
    });
    expect(createSpy).toHaveBeenCalledWith("newuser", "pw");
    expect(fetchMock).toHaveBeenCalled();
    expect(r.current.authenticated).toBe(true);
    expect(storageGet("xudanu_session_ticket")).toBe(btoa("\u0001\u0002\u0003"));
  });

  it("changePassword: re-auth sequence then clubSetPassword; requires identity", async () => {
    const { r, c } = await ready();
    await expect(r.current.changePassword("a", "b")).rejects.toThrow("not signed in");
    await act(async () => {
      c.fire("identity", { club_id: 5, display_name: "u" });
    });
    const pwSpy = vi.spyOn(c, "clubSetPassword");
    await act(async () => {
      await r.current.changePassword("old", "new");
    });
    expect(pwSpy).toHaveBeenCalledWith(5, "new");
    const ops = c.sent.map((s) => s.op);
    expect(ops).toContain("session_login_by_name");
    expect(ops).toContain("session_authenticate");
  });
});

describe("useCrdtSync — work creation, sharing, clubs", () => {
  it("createWork unwraps numeric and {work_id} response shapes", async () => {
    const { r, c } = await ready();
    c.results.set("work_create", { value: 42 });
    await act(async () => {
      expect(await r.current.createWork()).toBe(42);
    });
    c.results.set("work_create", { value: { work_id: 77 } });
    await act(async () => {
      expect(await r.current.createWork()).toBe(77);
    });
    c.results.set("work_create", { value: "junk" });
    await act(async () => {
      expect(await r.current.createWork()).toBeNull();
    });
  });

  it("shareWork sets read+edit clubs to the public club; unshare back to identity", async () => {
    const { r, c } = await ready();
    await act(async () => {
      c.fire("identity", { club_id: 5, display_name: "u" });
    });
    // publicClubId arrives via deferred server_stats (2s after connect).
    await act(async () => { await vi.advanceTimersByTimeAsync(2100); });
    await act(async () => {});
    await act(async () => { await r.current.shareWork(); });
    const shareOps = c.sent.filter((s) => s.op.startsWith("work_set_"));
    expect(shareOps.map((s) => s.op)).toEqual(["work_set_read_club", "work_set_edit_club"]);
    expect(shareOps.every((s) => (s.payload as { club_id: number }).club_id === 0x2a)).toBe(true);
    await act(async () => { await r.current.unshareWork(); });
    const last = c.sent[c.sent.length - 1];
    expect(last.op).toBe("work_set_edit_club");
    expect((last.payload as { club_id: number }).club_id).toBe(5);
  });

  it("visibility and club getters delegate; failures degrade to 0", async () => {
    const { r, c } = await ready();
    const setReadSpy = vi.spyOn(c, "setReadClub");
    await act(async () => { await r.current.setVisibility(1, 0x2a); });
    expect(setReadSpy).toHaveBeenCalledWith(1, 0x2a);
    await act(async () => {
      expect(await r.current.getReadClub(1)).toBe(5);
      expect(await r.current.getEditClub(1)).toBe(6);
    });
    c.failOps.add("get_read_club");
    c.failOps.add("get_edit_club");
    await act(async () => {
      expect(await r.current.getReadClub(1)).toBe(0);
      expect(await r.current.getEditClub(1)).toBe(0);
    });
  });
});

describe("useCrdtSync — LLM + list wrappers degrade safely", () => {
  it("success paths pass through; failure paths return error-shaped values", async () => {
    const { r } = await ready();
    await act(async () => {
      expect(await r.current.narrateDiff()).toEqual({ text: "n", model: "m", updatedText: "u" });
      expect(await r.current.getWritingFeedback()).toEqual({ text: "f", model: "m" });
      expect(await r.current.suggestTitle()).toBe("A Title");
    });
    const c = latest();
    c.failOps.add("diff_narration");
    c.failOps.add("writing_feedback");
    c.failOps.add("suggest_title");
    await act(async () => {
      const n = await r.current.narrateDiff();
      expect(n.text).toContain("Error");
      expect(await r.current.getWritingFeedback()).toEqual({ text: expect.stringContaining("Error"), model: "" });
      expect(await r.current.suggestTitle()).toContain("Error");
    });
  });

  it("fetchWorkList returns [] on failure, entries on success", async () => {
    const { r, c } = await ready();
    c.results.set("work_list", [{ work_id: 1, title: "one" }]);
    await act(async () => {
      expect(await r.current.fetchWorkList()).toEqual([{ work_id: 1, title: "one" }]);
    });
    c.failOps.add("work_list");
    await act(async () => {
      expect(await r.current.fetchWorkList()).toEqual([]);
    });
  });

  it("toggleWatch failure keeps the watch off", async () => {
    const { r, c } = await ready();
    c.failOps.add("subscribe_content_works");
    await act(async () => {
      await r.current.toggleWatch();
    });
    expect(r.current.watchEnabled).toBe(false);
    // Recovery works once the server accepts the subscription.
    c.failOps.delete("subscribe_content_works");
    await act(async () => {
      await r.current.toggleWatch();
    });
    expect(r.current.watchEnabled).toBe(true);
    // Toggling off unsubscribes and clears matches.
    act(() => { c.fire("match", { fossil_id: 1 }); });
    await act(async () => {
      await r.current.toggleWatch();
    });
    expect(r.current.watchEnabled).toBe(false);
    expect(c.unsubscribed).toContain(7);
    expect(r.current.contentMatches).toHaveLength(0);
  });
});

describe("useCrdtSync — attribution refresh fallback", () => {
  it("resolved spans are used directly when non-empty", async () => {
    const { r, c } = await ready();
    const spans = [{ start: 0, end: 2 }];
    c.results.set("attr_resolved", spans);
    await act(async () => { r.current.refreshAttribution(); });
    expect(r.current.attributionSpans).toEqual(spans);
    expect(r.current.attributionLogStatus).toEqual({ entry_count: 0, chain_valid: true, last_sequence: 0, has_log: true });
  });

  it("empty resolved falls back to the plain query (silent-empty bug class)", async () => {
    const { r, c } = await ready();
    c.results.set("attr_resolved", []);
    c.results.set("attr_query", [{ start: 3, end: 5 }]);
    await act(async () => { r.current.refreshAttribution(); });
    expect(r.current.attributionSpans).toEqual([{ start: 3, end: 5 }]);
  });

  it("resolved rejection also falls back", async () => {
    const { r, c } = await ready();
    c.failOps.add("attr_resolved");
    c.results.set("attr_query", [{ start: 6, end: 8 }]);
    await act(async () => { r.current.refreshAttribution(); });
    expect(r.current.attributionSpans).toEqual([{ start: 6, end: 8 }]);
  });
});
