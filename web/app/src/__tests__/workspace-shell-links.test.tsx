import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { render, fireEvent, act } from "@testing-library/react";

// Each test boots the FULL WorkspaceShell (~3.8s of fake-timer
// advancement through act()). Under coverage instrumentation that can
// exceed vitest's default 5s REAL per-test budget — the observed
// flake was always a timeout on these boots, never a logic failure.
vi.setConfig({ testTimeout: 20000 });

/**
 * coverage-plan-web.md Phase 3: WorkspaceShell data operations,
 * driven end-to-end through the wire-client seam (module mock). The
 * first surface: FR-87 §16.12 — the endorser filter over real panel
 * rows, and the reader's vouch toggle.
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
    attributionQueryResolved() { return Promise.resolve([]); }
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

describe("WorkspaceShell — FR-87 endorser filter, end to end", () => {
  it("mounts, loads the work's links, and offers the endorser filter", async () => {
    const { rp } = await boot();
    expect(rp().textContent).toContain("Vouched Target");
    expect(rp().textContent).toContain("Junk Target");
    // The dropdown appears because a third-party vouch exists.
    const filter = rp().querySelector(
      'select[title="Show only links endorsed by a club whose judgment you weigh (Miller §16.12)"]',
    ) as HTMLSelectElement;
    expect(filter).toBeTruthy();
  });

  it('"any vouch" thins the swamp to the vouched row; backlinks follow the same filter', async () => {
    const { rp } = await boot();
    const filter = () => rp().querySelector(
      'select[title="Show only links endorsed by a club whose judgment you weigh (Miller §16.12)"]',
    ) as HTMLSelectElement;
    await act(async () => {
      fireEvent.change(filter(), { target: { value: "vouched" } });
    });
    expect(rp().textContent).toContain("Vouched Target");
    expect(rp().textContent).not.toContain("Junk Target");
    // The endorsed backlink survives; count shows 1 of 1.
    expect(rp().textContent).toMatch(/Backlinks \(1\)/);
  });

  it("a specific endorser filters to their vouches only", async () => {
    const { rp } = await boot();
    const filter = () => rp().querySelector(
      'select[title="Show only links endorsed by a club whose judgment you weigh (Miller §16.12)"]',
    ) as HTMLSelectElement;
    await act(async () => {
      fireEvent.change(filter(), { target: { value: "7" } });
    });
    expect(rp().textContent).toContain("Vouched Target");
    expect(rp().textContent).not.toContain("Junk Target");
    // Reset to anyone: everything returns.
    await act(async () => {
      fireEvent.change(filter(), { target: { value: "any" } });
    });
    expect(rp().textContent).toContain("Junk Target");
  });

  it("the reader's vouch toggle sends link_endorse/link_unendorse and reloads", async () => {
    const { c, rp } = await boot();
    expect(c.linkListCalls).toBeGreaterThan(0);

    // Vouch the unvouched row (its button title says "Vouch for this
    // connection") — scoped to the panel; the left rail has no rows.
    const vouchBtn = rp().querySelector(
      'button[title="Vouch for this connection — a reader\'s review: worth reading"]',
    ) as HTMLElement;
    expect(vouchBtn).toBeTruthy();
    const callsBefore = c.linkListCalls;
    await act(async () => {
      fireEvent.click(vouchBtn);
    });
    const endorse = c.ops.find((o) => o.op === "link_endorse");
    expect(endorse).toBeTruthy();
    // First vouch button in the panel = link 101. Its existing vouch
    // is ANOTHER club's (The Convocation); our reader (club 5) adds
    // their own — two reputations, one row.
    expect(endorse!.payload).toEqual({ link_id: 101 });
    // The click reloads the panel's link list.
    expect(c.linkListCalls).toBeGreaterThan(callsBefore);
  });
});

describe("WorkspaceShell — comment-on-link (a link about the link)", () => {
  it("creates the note work, the comment link, and the Connection attachment", async () => {
    const { utils, rp, c } = await boot();
    const commentBtn = rp().querySelector(
      'button[title="Comment on this connection — a link about the link"]',
    ) as HTMLElement;
    expect(commentBtn).toBeTruthy();
    await act(async () => {
      fireEvent.click(commentBtn);
    });
    // The composer renders in the document column, not the panel.
    const ta = utils.container.querySelector(
      'textarea[placeholder="What do you want to say about this connection?"]',
    ) as HTMLTextAreaElement;
    expect(ta).toBeTruthy();
    await act(async () => {
      fireEvent.change(ta, { target: { value: "this connection matters" } });
    });
    const save = Array.from(utils.container.querySelectorAll("button")).find(
      (b) => b.textContent === "Save comment",
    )!;
    expect(save).toBeTruthy();
    await act(async () => {
      fireEvent.click(save);
    });
    // The FR-40 S7 (winfe links.cpp:305) sequence.
    expect(c.ops.find((o) => o.op === "work_create")).toBeTruthy();
    const created = c.ops.find((o) => o.op === "link_create");
    expect(created?.payload).toEqual({ origin: 0x60, destination: OPEN_WORK });
    const typed = c.ops.find((o) => o.op === "link_set_types");
    expect(typed?.payload).toEqual({ link_id: 0x77, types: [1] });
    const attach = c.ops.find((o) => o.op === "link_end_add_attachment");
    expect(attach?.payload).toEqual({
      link_id: 0x77,
      end: "Connection",
      ref: { workContext: OPEN_WORK, linkAttachment: 101 },
    });
    // Composer closes on success.
    expect(utils.container.querySelector(".ws-trail-picker")).toBeNull();
  });
});

describe("WorkspaceShell — open-link completion (FR-71)", () => {
  it("the complete affordance creates the target work and completes the RightEnd", async () => {
    const { rp, c } = await boot();
    expect(rp().textContent).toContain("Open ends");
    const complete = rp().querySelector(
      'button[title="Create the target document and complete this connection"]',
    ) as HTMLElement;
    expect(complete).toBeTruthy();
    await act(async () => {
      fireEvent.click(complete);
    });
    const addEnd = c.ops.find((o) => o.op === "link_add_end");
    expect(addEnd?.payload).toEqual({
      link_id: 300,
      end: "RightEnd",
      ref: { workContext: 0x60, excerpt: "" },
    });
  });
});

describe("WorkspaceShell — type chips and row actions", () => {
  it("the Reference chip filters to reference-typed rows only", async () => {
    const { rp } = await boot();
    const chip = Array.from(rp().querySelectorAll("button.ws-link-filter-btn")).find((b) =>
      b.textContent?.startsWith("Reference"),
    )!;
    expect(chip).toBeTruthy();
    await act(async () => {
      fireEvent.click(chip);
    });
    expect(rp().textContent).toContain("Vouched Target");
    expect(rp().textContent).not.toContain("Junk Target");
    await act(async () => {
      fireEvent.click(chip); // toggle off
    });
    expect(rp().textContent).toContain("Junk Target");
  });

  it("delete asks for confirmation and issues link_delete", async () => {
    vi.stubGlobal("confirm", () => true);
    const { rp, c } = await boot();
    const del = rp().querySelector('button[title="Delete this link"]') as HTMLElement;
    expect(del).toBeTruthy();
    await act(async () => {
      fireEvent.click(del);
    });
    expect(c.ops.find((o) => o.op === "link_delete")?.payload).toEqual({ link_id: 101 });
  });

  it("retype issues link_set_types with the chosen type", async () => {
    const { rp, c } = await boot();
    const select = rp().querySelector('select[title="Change link type"]') as HTMLSelectElement;
    expect(select).toBeTruthy();
    await act(async () => {
      fireEvent.change(select, { target: { value: "3" } });
    });
    const typed = c.ops.filter((o) => o.op === "link_set_types").at(-1);
    expect(typed?.payload).toEqual({ link_id: 101, types: [3] });
  });
});
