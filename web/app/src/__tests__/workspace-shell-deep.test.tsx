import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { render, fireEvent, act } from "@testing-library/react";

// Each test boots the FULL WorkspaceShell (~3.8s of fake-timer
// advancement through act()). Under coverage instrumentation that can
// exceed vitest's default 5s REAL per-test budget — the observed
// flake was always a timeout on these boots, never a logic failure.
vi.setConfig({ testTimeout: 20000 });

/**
 * coverage-plan-web.md Phase 3 (deep surfaces): the ImportWizard and
 * the AdminDashboard (audit tail, full-chain verify) through the
 * shell harness's wire-client seam.
 */

type Handler = (arg?: unknown) => void;

const OPEN_WORK = 0x10;

function mkLink(over: Record<string, unknown>): Record<string, unknown> {
  return {
    link_id: 1,
    origin: OPEN_WORK,
    destination: 0x20,
    origin_ref: { kind: "single", work_context: OPEN_WORK, excerpt: "hello" },
    destination_ref: { kind: "single", work_context: 0x20, excerpt: "target one" },
    origin_title: "Open Work",
    destination_title: "Target One",
    link_types: [2],
    endorsements: [],
    endorsement_count: 1,
    link_contested: false,
    ...over,
  };
}

const CONVO = { club_id: 7, name: "The Convocation", kind: "vouch", timestamp: 100 };

function fixtures() {
  return {
    links: [
      mkLink({
        link_id: 101,
        destination: 0x20,
        destination_title: "Vouched Target",
        destination_ref: { kind: "single", work_context: 0x20, excerpt: "worth reading" },
        link_types: [2],
        endorsements: [CONVO],
        endorsement_count: 2,
      }),
      mkLink({
        link_id: 102,
        destination: 0x30,
        destination_title: "Junk Target",
        destination_ref: { kind: "single", work_context: 0x30, excerpt: "noise" },
        link_types: [3],
        endorsements: [],
        endorsement_count: 1,
      }),
      mkLink({
        link_id: 300,
        is_open: true,
        destination: null,
        destination_title: null,
        destination_ref: null,
        origin_ref: { kind: "single", work_context: OPEN_WORK, excerpt: "stub passage" },
        link_types: [1],
        endorsements: [],
        endorsement_count: 1,
      }),
    ],
    backlinks: [
      {
        source_work_id: 0x40,
        link_id: 201,
        link_type: "hyperlink_incoming",
        excerpt: "incoming excerpt",
        title: "Backlink Doc",
        source_archived: false,
        endorsements: [CONVO],
        endorsement_count: 2,
        link_contested: false,
      },
    ],
    works: [
      { work_id: OPEN_WORK, title: "Open Work", revision_count: 2, is_starred: false, owner: null, author_display_name: null, author_club_id: null },
      { work_id: 0x20, title: "Vouched Target", revision_count: 1, is_starred: false, owner: null, author_display_name: null, author_club_id: null },
      { work_id: 0x30, title: "Junk Target", revision_count: 1, is_starred: false, owner: null, author_display_name: null, author_club_id: null },
      { work_id: 0x40, title: "Backlink Doc", revision_count: 1, is_starred: false, owner: null, author_display_name: null, author_club_id: null },
    ],
  };
}

const { FakeClient, RawClient } = vi.hoisted(() => {
  class FakeClient {
    static instances: FakeClient[] = [];
    connectedFlag = false;
    links: unknown[] = [];
    ops: Array<{ op: string; payload: unknown }> = [];
    linkListCalls = 0;
    private handlers = new Map<string, Handler[]>();

    constructor() {
      FakeClient.instances.push(this);
    }
    private on(name: string, cb: Handler) {
      const list = this.handlers.get(name) ?? [];
      list.push(cb);
      this.handlers.set(name, list);
      return () => this.handlers.set(name, (this.handlers.get(name) ?? []).filter((h) => h !== cb));
    }
    fire(name: string, arg?: unknown) {
      for (const h of this.handlers.get(name) ?? []) h(arg);
    }

    onTextChange(cb: Handler) { return this.on("text", cb); }
    onSaveStateChange(cb: Handler) { return this.on("save", cb); }
    onAccessDenied(cb: Handler) { return this.on("denied", cb); }
    onConnectionChange(cb: Handler) { return this.on("conn", cb); }
    onAwarenessChange(cb: Handler) { return this.on("aware", cb); }
    onContentMatch(cb: Handler) { return this.on("match", cb); }
    onIdentityChange(cb: Handler) { return this.on("identity", cb); }
    onChangeHighlights(cb: Handler) { return this.on("changes", cb); }

    connect() { this.connectedFlag = true; this.fire("conn", true); }
    disconnect() { this.connectedFlag = false; }
    isConnected() { return this.connectedFlag; }
    getReconnectAttempt() { return 0; }
    getIsAdmin() { return true; }
    get offlineReading() { return false; }
    switchWork() { return Promise.resolve(); }
    checkWhoAmI() { return Promise.resolve({ club_id: 5, display_name: "reader" }); }
    canEdit() { return Promise.resolve(true); }
    fetchWorkList() { return Promise.resolve(fixtures().works); }
    linkListForWork() { this.linkListCalls++; return Promise.resolve(this.links.length ? this.links : fixtures().links); }
    findBacklinks() { return Promise.resolve(fixtures().backlinks); }
    linkTypeList() {
      return Promise.resolve([1, 2, 3, 4, 5].map((id) => ({ type_id: id, name: ["", "Comment", "Reference", "Disagreement", "Quotation", "See Also"][id] })));
    }
    findExcerptPositions() { return Promise.resolve([]); }
    workGraph() { return Promise.resolve({ nodes: [], links: [] }); }
    resolveInlineTransclusions() { return Promise.resolve({ text: "", spanRanges: [], sourceTitles: {} }); }
    annotationList() { return Promise.resolve([]); }
    attributionQueryResolved() { return Promise.resolve([{ start: 0, end: 5, author_club_id: 5, author_display_name: "reader", author_type: null, is_transclusion: false, author_public_key: [1,2,3,4], transcluded_by_club_id: null, transcluded_by_display_name: null }]); }
    attributionQuery() { return Promise.resolve([]); }
    attributionLogStatus() { return Promise.resolve({ entry_count: 0, chain_valid: true, last_sequence: 0, has_log: false }); }
    refreshAwareness() { return Promise.resolve([]); }
    sendAwareness() {}
    sendRequest(op: string, payload?: unknown) {
      this.ops.push({ op, payload });
      if (op === "server_stats") {
        return Promise.resolve({ value: { llm_enabled: false, public_club_id: 3 } });
      }
      if (op === "work_create") {
        return Promise.resolve({ value: 0x60 });
      }
      if (op === "work_transclusion_chain") {
        return Promise.resolve({ value: [] });
      }
      if (op === "server_directory_list") {
        return Promise.resolve({ value: { servers: [{ server_id: "srv1", address: "peer.example:8080", name: "Peer One", trust: "trusted" }] } });
      }
      if (op === "admin_audit_tail") {
        return Promise.resolve({ value: { value: { lines: ["seq 42: work_create 0x10", "seq 43: link_create 101"], chain_valid: true } } });
      }
      if (op === "admin_security_log_verify") {
        return Promise.resolve({ value: { value: {
          ok: true,
          key_history: { ok: true, keys: 2 },
          security: { ok: true, entries: 3, checkpoints: 1, lines: [] },
          attribution: { ok: true, entries: 1, checkpoints: 1, lines: [] },
        } } });
      }
      return Promise.resolve({ value: null });
    }
    subscribeContentWorks() { return Promise.resolve(1); }
    unsubscribe() {}
    workBlobList() { return Promise.resolve([]); }
    workBlobGet() { return Promise.resolve(null); }
    linkCreate(origin: number, destination: number) {
      this.ops.push({ op: "link_create", payload: { origin, destination } });
      return Promise.resolve(0x77);
    }
    linkSetTypes(linkId: number, types: number[]) {
      this.ops.push({ op: "link_set_types", payload: { link_id: linkId, types } });
      return Promise.resolve();
    }
    linkEndAddAttachment(linkId: number, end: string, ref: unknown) {
      this.ops.push({ op: "link_end_add_attachment", payload: { link_id: linkId, end, ref } });
      return Promise.resolve();
    }
    linkAddEnd(linkId: number, end: string, ref: unknown) {
      this.ops.push({ op: "link_add_end", payload: { link_id: linkId, end, ref } });
      return Promise.resolve();
    }
    linkDelete(linkId: number) {
      this.ops.push({ op: "link_delete", payload: { link_id: linkId } });
      return Promise.resolve();
    }
    workTransclusionChain(workId: number, cs: number, ce: number) {
      this.ops.push({ op: "work_transclusion_chain", payload: { work_id: workId, char_start: cs, char_end: ce } });
      return Promise.resolve([
        { work_id: 0x20, work_title: "Vouched Target", is_original: true, author_name: "author one", author_type: null },
        { work_id: 0x10, work_title: "Open Work", is_original: false, author_name: "reader", author_type: null },
      ]);
    }
    rangeTranscluders() { return Promise.resolve({ edition_ids: [1], work_ids: [2] }); }
    detectorList() { return Promise.resolve([]); }
    trailList() { return Promise.resolve([{ trail_id: 100, name: "The Grand Tour", stops: [{ work_id: 0x10, title: "Open Work", note: "begin here" }], published: false, introduction: "" }]); }
    trailListPublished() { return Promise.resolve([{ trail_id: 200, name: "Published Path", stops: [{ work_id: 0x10, title: "Open Work" }], published: true, introduction: "" }]); }
    trailListCategories() { return Promise.resolve(["tours"]); }
    workRevisionsList() { return Promise.resolve([{ revision_id: 1, created_at: 1759000000, is_notable: false, char_count: 11, change_summary: "initial" }, { revision_id: 2, created_at: 1759100000, is_notable: true, char_count: 11, change_summary: "note" }]); }
    workGraph() { return Promise.resolve({ nodes: [{ work_id: 0x10, title: "Open Work", is_starred: false, is_source: false, revision_count: 2 }, { work_id: 0x20, title: "Vouched Target", is_starred: false, is_source: false, revision_count: 1 }], links: [{ source: 0x10, target: 0x20, edge_type: "hyperlink", weight: 1 }] }); }
    llmUsage() { return Promise.resolve(null); }
    setTextLocal(t: string) { this.fire("text", t); }
  }
  // Any client method the shell grows that the fixture never defined
  // resolves to [] — mount must not die on the unknown; specific
  // behavior is defined explicitly above.
  const Wrapped = function (this: unknown) {
    const inst = new (FakeClient as unknown as new () => unknown)() as Record<string | symbol, unknown>;
    return new Proxy(inst, {
      get(target, prop) {
        if (prop in target) return target[prop];
        if (typeof prop === "string") return () => Promise.resolve([]);
        return undefined;
      },
    });
  } as unknown as typeof FakeClient;
  return { FakeClient: Wrapped, RawClient: FakeClient };
});

vi.mock("../api/crdt_sync", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../api/crdt_sync")>();
  return { ...actual, CrdtSyncClient: FakeClient };
});
vi.mock("../safe-storage", () => {
  const backing = new Map<string, string>();
  return {
    storageGet: (k: string) => backing.get(k) ?? null,
    storageSet: (k: string, v: string) => void backing.set(k, v),
    storageRemove: (k: string) => void backing.delete(k),
    storageClear: () => void backing.clear(),
  };
});

import { WorkspaceShell } from "../components/workspace/WorkspaceShell";

const canvasCtxStub = new Proxy(
  {},
  {
    get: (target: Record<string | symbol, unknown>, prop) => {
      if (prop === "canvas") return { width: 800, height: 600 };
      if (prop === "measureText") return () => ({ width: 10 });
      if (typeof prop !== "string") return undefined;
      if (!(prop in target)) target[prop] = () => {};
      return target[prop];
    },
    set: () => true,
  },
);
class ResizeObserverStub { observe() {} unobserve() {} disconnect() {} }
class IntersectionObserverStub {
  observe() {} unobserve() {} disconnect() {}
  takeRecords(): IntersectionObserverEntry[] { return []; }
}
const matchMediaStub = (query: string) => ({
  matches: false, media: query, onchange: null,
  addListener: () => {}, removeListener: () => {},
  addEventListener: () => {}, removeEventListener: () => {}, dispatchEvent: () => false,
});

beforeEach(() => {
  vi.useFakeTimers();
  // AdminDashboard's overview polls /health; the client is mocked so
  // nothing else here needs fetch.
  vi.stubGlobal("fetch", vi.fn(async () => ({ ok: true, json: async () => ({ status: "ok", works: 1, links: 1, sessions: 1, operations: 42, disk_free_mb: 1000, checkpoint_idle: true }) })));
  window.history.replaceState({}, "", `/?work=${OPEN_WORK}`);
  RawClient.instances = [];
  vi.stubGlobal("requestAnimationFrame", (cb: FrameRequestCallback) => setTimeout(() => cb(0), 0) as unknown as number);
  vi.stubGlobal("cancelAnimationFrame", (id: number) => clearTimeout(id));
  vi.stubGlobal("ResizeObserver", ResizeObserverStub);
  vi.stubGlobal("IntersectionObserver", IntersectionObserverStub);
  vi.stubGlobal("matchMedia", matchMediaStub);
  HTMLCanvasElement.prototype.getContext = vi.fn(() => canvasCtxStub) as never;
  (Range.prototype as unknown as Record<string, unknown>).getClientRects = function (this: Range) {
    return [{ left: this.startOffset * 10, top: 10, right: this.endOffset * 10, bottom: 26, width: 10, height: 16 }] as unknown as DOMRectList;
  };
});

afterEach(() => {
  delete (Range.prototype as unknown as Record<string, unknown>).getClientRects;
  vi.unstubAllGlobals();
  vi.useRealTimers();
  window.history.replaceState({}, "", "/");
});

function client(): FakeClient {
  return RawClient.instances[RawClient.instances.length - 1];
}

/** Boot the shell to "work open, links loaded". */
async function boot() {
  const utils = render(<WorkspaceShell />);
  const c = client();
  // Text arrives (switchWork resolved inside the hook): the editor
  // has content; deferred identity/stats flows follow.
  await act(async () => {
    c.fire("text", "hello world");
    await vi.advanceTimersByTimeAsync(3000);
  });
  // Let every deferred chain (identity, stats, links, backlinks,
  // markers) settle through its microtasks.
  for (let i = 0; i < 6; i++) {
    await act(async () => {
      await vi.advanceTimersByTimeAsync(100);
    });
  }
  // The Links panel is a right-panel tab (default: Attribution).
  const linksTab = Array.from(utils.container.querySelectorAll("button.ws-tab")).find(
    (b) => b.textContent === "Links",
  );
  await act(async () => {
    fireEvent.click(linksTab!);
  });
  await act(async () => {
    await vi.advanceTimersByTimeAsync(100);
  });
  const rp = () => utils.container.querySelector(".ws-right-panel") as HTMLElement;
  return { utils, c, rp };
}


describe("WorkspaceShell — import wizard and admin dashboard", () => {
  it("the import wizard opens via the welcome-page event and closes", async () => {
    const { utils } = await boot();
    expect(utils.container.textContent).not.toContain("Paste");
    await act(async () => {
      window.dispatchEvent(new Event("xudanu-open-import"));
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(200);
    });
    // The wizard's first step is the paste surface.
    expect(utils.container.textContent).toContain("Paste");
    const close = utils.container.querySelector(".wizard-close") as HTMLElement;
    expect(close).toBeTruthy();
    await act(async () => {
      fireEvent.click(close);
    });
    expect(utils.container.textContent).not.toContain("Paste");
  });

  it("the admin dashboard renders for admins; the audit tab shows the tamper-evident tail", async () => {
    const { utils } = await boot();
    const adminBtn = utils.container.querySelector("button.ws-admin-btn") as HTMLElement;
    expect(adminBtn).toBeTruthy(); // admin_grants succeeded in the fake
    await act(async () => {
      fireEvent.click(adminBtn);
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(300);
    });
    const auditTab = Array.from(utils.container.querySelectorAll("button")).find(
      (b) => b.textContent === "Audit",
    )!;
    expect(auditTab).toBeTruthy();
    await act(async () => {
      fireEvent.click(auditTab);
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(200);
    });
    // The tail loads on demand.
    const loadBtn = Array.from(utils.container.querySelectorAll("button")).find(
      (b) => b.textContent === "Load / refresh",
    )!;
    expect(loadBtn).toBeTruthy();
    await act(async () => {
      fireEvent.click(loadBtn);
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(200);
    });
    expect(utils.container.textContent).toContain("seq 42: work_create 0x10");
    expect(utils.container.textContent).toContain("seq 43: link_create 101");
  });
});

describe("WorkspaceShell — the provenance chain surface (restored)", () => {
  it("renders unconditionally (the annotation-modal nesting regression)", async () => {
    const { utils } = await boot();
    // REGRESSION: these sections were swallowed by the annotation
    // modal's unterminated conditional — invisible in normal use.
    expect(utils.container.textContent).toContain("Where is this used?");
    expect(utils.container.textContent).toContain("Provenance chain");
    expect(
      Array.from(utils.container.querySelectorAll("button")).some((b) => b.textContent === "Trace"),
    ).toBe(true);
  });

  it("Trace walks the FULL document span and renders the hop chain", async () => {
    const { utils, c } = await boot();
    const trace = Array.from(utils.container.querySelectorAll("button")).find(
      (b) => b.textContent === "Trace",
    )!;
    await act(async () => {
      fireEvent.click(trace);
    });
    await act(async () => {});
    expect(utils.container.textContent).toContain("Vouched Target");
    expect(utils.container.textContent).toContain("ORIGINAL");
    // The wire call carries the full span, not (0,0).
    const call = c.ops.find((s) => s.op === "work_transclusion_chain");
    expect(call).toBeTruthy();
    expect((call!.payload as { char_end: number }).char_end).toBe("hello world".length);
  });

  it("Find runs the backfollow search over the whole work", async () => {
    const { utils } = await boot();
    const find = Array.from(utils.container.querySelectorAll("button")).find(
      (b) => b.textContent === "Find",
    )!;
    await act(async () => {
      fireEvent.click(find);
    });
    await act(async () => {});
    // The fake's rangeTranscluders returns editions [1], works [2].
    expect(utils.container.textContent).toContain("Reuses content from");
  });
});
