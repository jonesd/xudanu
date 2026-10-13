import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { render, fireEvent, act } from "@testing-library/react";

// Each test boots the FULL WorkspaceShell (~3.8s of fake-timer
// advancement through act()). Under coverage instrumentation that can
// exceed vitest's default 5s REAL per-test budget — the observed
// flake was always a timeout on these boots, never a logic failure.
vi.setConfig({ testTimeout: 20000 });

/**
 * coverage-plan-web.md Phase 3 (breadth): every right-panel TAB of
 * the live shell, driven through the wire-client seam — Attribution,
 * Map, Trails, History, Servers, Compare, More. One fixture set,
 * one boot, tab-by-tab assertions.
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
    getIsAdmin() { return false; }
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
      if (op === "server_directory_list") {
        return Promise.resolve({ value: { servers: [{ server_id: "srv1", address: "peer.example:8080", name: "Peer One", trust: "trusted" }] } });
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


describe("WorkspaceShell — right-panel tabs", () => {
  async function openTab(utils: ReturnType<typeof boot>, label: string) {
    const tab = Array.from(utils.container.querySelectorAll("button.ws-tab")).find(
      (b) => b.textContent?.startsWith(label),
    );
    await act(async () => {
      fireEvent.click(tab!);
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(400);
    });
    await act(async () => {});
    return utils.container.querySelector(".ws-right-panel") as HTMLElement;
  }

  it("Attribution: the authorship summary and the attribution log chain", async () => {
    const { utils } = await boot();
    const rp = await openTab(utils, "Attribution");
    expect(rp.textContent).toContain("Authorship");
    expect(rp.textContent).toContain("reader");
    expect(rp.textContent).toContain("1 spans");
    expect(rp.textContent).toContain("1 author");
    expect(rp.textContent).toContain("0x0010"); // the work's id in the chain
  });

  it("Map: graph nodes render with their endorsement state", async () => {
    const { utils } = await boot();
    const rp = await openTab(utils, "Map");
    expect(rp.textContent).toContain("Vouched Target");
    expect(rp.textContent).toContain("Open Work");
    expect(rp.textContent).toContain("unendorsed");
  });

  it("Trails: the work's trails list mine and published, with stop notes", async () => {
    const { utils } = await boot();
    const rp = await openTab(utils, "Trails");
    expect(rp.textContent).toContain("Trails through this work");
    expect(rp.textContent).toContain("The Grand Tour");
    expect(rp.textContent).toContain("Published Path");
    expect(rp.textContent).toContain("begin here");
    expect(rp.textContent).toContain("1 stops · 1 on this work");
  });

  it("History: revisions render with notable marks and rollback affordances", async () => {
    const { utils } = await boot();
    const rp = await openTab(utils, "History");
    expect(rp.textContent).toContain("Revision history");
    expect(rp.textContent).toContain("Notable");
    expect(rp.textContent).toContain("Rollback");
    expect(rp.textContent).toContain("Compare revisions");
    expect(rp.textContent).toContain("v2");
  });

  it("Servers: the directory lists the peer with its address and trust controls", async () => {
    const { utils } = await boot();
    const rp = await openTab(utils, "Servers");
    expect(rp.textContent).toContain("Peer One");
    expect(rp.textContent).toContain("peer.example:8080");
    expect(rp.textContent).toContain("Trust");
  });

  it("Compare: the empty-state explains the two entry paths and offers the works", async () => {
    const { utils } = await boot();
    const rp = await openTab(utils, "Compare");
    expect(rp.textContent).toContain("Compare (0)");
    expect(rp.textContent).toContain("Vouched Target");
    expect(rp.textContent).toContain("multi-ended link");
  });

  it("More: the detectors surface (Miller's fourth fundamental)", async () => {
    const { utils } = await boot();
    const rp = await openTab(utils, "More");
    expect(rp.textContent).toContain("Detectors");
    expect(rp.textContent).toContain("Watch this work");
  });
});

describe("WorkspaceShell — trails overlay and the outline rail", () => {
  async function openTabPanel(utils: ReturnType<typeof boot>, label: string) {
    const tab = Array.from(utils.container.querySelectorAll("button.ws-tab")).find(
      (b) => b.textContent?.startsWith(label),
    );
    await act(async () => {
      fireEvent.click(tab!);
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(400);
    });
    await act(async () => {});
    return utils.container.querySelector(".ws-right-panel") as HTMLElement;
  }

  it("Manage opens the full TrailsPanel overlay; close returns to the tab", async () => {
    const { utils } = await boot();
    const rp = await openTabPanel(utils, "Trails");
    const manage = rp.querySelector("button.ws-trails-manage-btn") as HTMLElement;
    expect(manage).toBeTruthy();
    await act(async () => {
      fireEvent.click(manage);
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(300);
    });
    // The full-screen panel lists the trails (mine + published).
    expect(utils.container.textContent).toContain("The Grand Tour");
    expect(utils.container.textContent).toContain("Published Path");
    // Close it.
    const close = utils.container.querySelector(".panel-close") as HTMLElement;
    await act(async () => {
      fireEvent.click(close);
    });
    expect(utils.container.querySelector(".panel-close")).toBeNull();
  });

  it("the left-rail Outline renders the document's markdown headings", async () => {
    const { utils, c } = await boot();
    // Give the document heading structure.
    await act(async () => {
      c.fire("text", "hello world\n\n# Heading One\n\n## Sub Two\n\nplain body");
      await vi.advanceTimersByTimeAsync(300);
    });
    const outlineBtn = utils.container.querySelector(
      'button[title="Outline of the open document"]',
    ) as HTMLElement;
    expect(outlineBtn).toBeTruthy();
    await act(async () => {
      fireEvent.click(outlineBtn);
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(200);
    });
    expect(utils.container.textContent).toContain("Heading One");
    expect(utils.container.textContent).toContain("Sub Two");
  });
});
