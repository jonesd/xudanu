import { describe, it, expect, vi } from "vitest";
import { render, fireEvent, act } from "@testing-library/react";
import { renderHook } from "@testing-library/react";
import type { CrdtSyncClient, WorkListEntry } from "../api/crdt_sync";
import { highlightRegions, wordSimilarity, useCompare } from "../components/ComparePanel";
import { MergePanel } from "../components/MergePanel";
import { ThreeWayDiffPanel } from "../components/ThreeWayDiffPanel";

/**
 * coverage-plan-web.md Phase 4: the revision-integrity surfaces.
 * Compare (what changed), ThreeWay (who changed what), Merge (the
 * data-destruction action). All three take `client` as a prop — no
 * module mocks, plain fakes, real component bodies.
 */

function fakeClient(opts: {
  diff?: { shared: Array<{ start_a: number; end_a: number; start_b: number; end_b: number }>; coverage: number } | null;
  shared?: Array<{ start_a: number; end_a: number; start_b: number; end_b: number }>;
  editions?: Record<number, string>;
  revisions?: Record<number, string>;
  mergeError?: string;
} = {}) {
  const calls: Array<{ op: string; payload: unknown }> = [];
  const client = {
    calls,
    workDiffRegions: vi.fn(async () => opts.diff ?? null),
    findSharedRegions: vi.fn(
      async () => opts.shared ?? [{ start_a: 0, end_a: 5, start_b: 0, end_b: 5, match_len: 5, match_text: "hello" }],
    ),
    sendRequest: vi.fn(async (op: string, payload?: { work_id?: number }) => {
      calls.push({ op, payload });
      if (op === "work_get_edition") {
        return { type: "response", value: { Text: opts.editions?.[payload?.work_id ?? 0] ?? "" } };
      }
      return { type: "response", value: null };
    }),
    fetchRevision: vi.fn(async (_w: number, rev: number) => opts.revisions?.[rev] ?? ""),
    workMerge: vi.fn(async (base: number, a: number, b: number) => {
      calls.push({ op: "work_merge", payload: { base, a, b } });
      if (opts.mergeError) throw new Error(opts.mergeError);
      return 0x99;
    }),
  };
  return client as unknown as CrdtSyncClient & typeof client;
}

const work = (id: number, title: string): WorkListEntry =>
  ({ work_id: id, title, revision_count: 1, is_starred: false, owner: null, author_display_name: null, author_club_id: null }) as unknown as WorkListEntry;

describe("ComparePanel — pure exports", () => {
  it("highlightRegions: plain text, single region, overlap skipping, unique tail", () => {
    expect(highlightRegions("hello", [], "hl")).toBe("hello");
    expect(highlightRegions("hello", [], "hl", "uq")).toBe('<span class="uq">hello</span>');
    const one = highlightRegions("hello world", [{ start: 6, end: 11, cidx: 2 }], "hl");
    expect(one).toContain('data-cidx="2"');
    expect(one).toContain(">world<");
    expect(one.startsWith("hello")).toBe(true);
    // A region fully covered by an earlier one is skipped.
    const overlap = highlightRegions("abcdef", [
      { start: 0, end: 6, cidx: 0 },
      { start: 1, end: 3, cidx: 1 },
    ], "hl");
    expect(overlap).not.toContain('data-cidx="1"');
    // Tail after the last region is unique-marked.
    const tail = highlightRegions("abcdef", [{ start: 0, end: 3, cidx: 0 }], "hl", "uq");
    expect(tail.endsWith('<span class="uq">def</span>')).toBe(true);
  });

  it("wordSimilarity: identity, disjoint, empty", () => {
    expect(wordSimilarity("the quick brown fox", "the quick brown fox")).toBe(1);
    expect(wordSimilarity("alpha beta gamma", "delta epsilon zeta")).toBe(0);
    expect(wordSimilarity("", "something")).toBe(0);
  });
});

describe("useCompare — document & revision comparison", () => {
  function renderCompare(client: CrdtSyncClient, currentText = "current text here") {
    return renderHook(() => useCompare(true, 0x10, currentText, client));
  }

  it("server-provided shared regions drive both sides; the edition loads as target text", async () => {
    const client = fakeClient({
      diff: { shared: [{ start_a: 0, end_a: 7, start_b: 2, end_b: 9 }], coverage: 0.5 },
      editions: { [0x20]: "the target document" },
    });
    const { result } = renderCompare(client);
    await act(async () => {
      await (useCompare as unknown as { _openDocument: (wid: number) => Promise<void> })._openDocument(0x20);
    });
    expect(result.current.targetText).toBe("the target document");
    expect(result.current.hasTarget).toBe(true);
    expect(result.current.targetLabel).toBe("Document 32");
    expect(result.current.sharedRegions).toEqual([{ startA: 0, endA: 7, startB: 2, endB: 9 }]);
    // SHIPPED BEHAVIOR: once the target text arrives, the paragraph
    // matcher recomputes left/right regions from the TEXTS — the
    // server-shaped regions are the initial paint only. With these
    // fixtures the paragraphs score below the 0.35 threshold, so the
    // client-side regions come back empty. sharedRegions (the server
    // payload) persists.
    expect(result.current.leftRegions).toHaveLength(0);
  });

  it("a null server diff falls back to findSharedRegions", async () => {
    const client = fakeClient({ diff: null, editions: { [0x20]: "target" } });
    const { result } = renderCompare(client);
    await act(async () => {
      await (useCompare as unknown as { _openDocument: (wid: number) => Promise<void> })._openDocument(0x20);
    });
    expect(client.findSharedRegions).toHaveBeenCalled();
    expect(result.current.sharedRegions).toHaveLength(1);
  });

  it("revision compare loads the old text and paragraph-matches against current", async () => {
    const client = fakeClient({
      revisions: { 3: "a shared paragraph of text\n\nold second paragraph" },
    });
    const { result } = renderCompare(client, "a shared paragraph of text\n\nnew second paragraph");
    await act(async () => {
      await (useCompare as unknown as { _openRevision: (rev: number) => Promise<void> })._openRevision(3);
    });
    expect(result.current.targetText).toContain("old second paragraph");
    expect(result.current.targetLabel).toBe("Revision 3");
    // BOTH paragraphs match: the first is identical, and the second
    // ("new…" vs "old second paragraph") scores 0.5 word similarity —
    // above the 0.35 fuzzy threshold. Paraphrase detection is the
    // feature, not a bug.
    expect(result.current.leftRegions).toHaveLength(2);
    expect(result.current.rightRegions).toHaveLength(2);
  });

  it("switching modes clears the target", async () => {
    const client = fakeClient({ editions: { [0x20]: "target" } });
    const { result } = renderCompare(client);
    await act(async () => {
      await (useCompare as unknown as { _openDocument: (wid: number) => Promise<void> })._openDocument(0x20);
    });
    expect(result.current.hasTarget).toBe(true);
    act(() => {
      result.current.setMode("revision");
    });
    expect(result.current.hasTarget).toBe(false);
    expect(result.current.targetText).toBe("");
  });

  it("comparing the work to itself is a no-op", async () => {
    const client = fakeClient({ editions: { [0x10]: "self" } });
    const { result } = renderCompare(client);
    await act(async () => {
      await (useCompare as unknown as { _openDocument: (wid: number) => Promise<void> })._openDocument(0x10);
    });
    expect(result.current.hasTarget).toBe(false);
    expect(client.workDiffRegions).not.toHaveBeenCalled();
  });
});

describe("MergePanel — the data-destruction surface", () => {
  const BASE = 0x10, WA = 0x20, WB = 0x30;
  const texts = {
    base: "para one\n\npara two\n\npara three",
    aClean: "para one A\n\npara two\n\npara three", // A-only change
    bClean: "para one\n\npara two\n\npara three B", // B-only change
    conflictA: "alpha version\n\npara two",
    conflictB: "beta version\n\npara two",
  };

  function renderMerge(client: CrdtSyncClient) {
    const onMerged = vi.fn();
    const onClose = vi.fn();
    const utils = render(
      <MergePanel
        client={client}
        currentWorkId={0x40}
        works={[work(BASE, "Base Doc"), work(WA, "A Doc"), work(WB, "B Doc"), work(0x40, "Current")]}
        onClose={onClose}
        onMerged={onMerged}
      />,
    );
    return { ...utils, onMerged, onClose };
  }

  async function loadComparison(utils: ReturnType<typeof renderMerge>) {
    const container = utils.container;
    const order = ["Base (common ancestor)", "Work A (first divergent version)", "Work B (second divergent version)"];
    const picks: Array<[string, number, string]> = [
      [order[0], 0x10, "Base Doc"],
      [order[1], 0x20, "A Doc"],
      [order[2], 0x30, "B Doc"],
    ];
    for (const [label, id, title] of picks) {
      const idx = order.indexOf(label);
      const el = container.querySelectorAll("input")[idx];
      await act(async () => {
        fireEvent.focus(el);
      });
      // EXACT, LEAF-only match. Two traps: the dropdown LIST div
      // starts with its first row's text (startsWith grabs it), and a
      // SINGLE-ENTRY list's container textContent EQUALS the row — so
      // the picker's last (unambiguous) choice must still be matched
      // as a leaf, never the container.
      const rowText = `${title} 0x${id.toString(16).padStart(4, "0")}`;
      const row = Array.from(container.querySelectorAll("div")).find(
        (d) => d.querySelector("div") === null && d.textContent === rowText,
      );
      await act(async () => {
        fireEvent.mouseDown(row!);
      });
      // jsdom's fireEvent.focus does NOT blur siblings (no real focus
      // move), so the picker's 150ms blur-close never fires and its
      // dropdown lingers — the next pick would hit a stale duplicate
      // row. Blur explicitly and let the close settle.
      await act(async () => {
        fireEvent.blur(el);
      });
      await act(async () => {
        await new Promise((r) => setTimeout(r, 200));
      });
    }
  }

  it("clean divergence: loads, classifies A-only/B-only, merges via workMerge", async () => {
    const client = fakeClient({
      editions: { [BASE]: texts.base, [WA]: texts.aClean, [WB]: texts.bClean },
    });
    const utils = renderMerge(client);
    await loadComparison(utils);
    const load = Array.from(utils.container.querySelectorAll("button")).find(
      (b) => b.textContent === "Load Comparison",
    )!;
    await act(async () => {
      fireEvent.click(load);
    });
    expect(utils.container.textContent).toContain("1 A-only");
    expect(utils.container.textContent).toContain("1 B-only");
    expect(utils.container.textContent).toContain("0 conflicts");
    expect(utils.container.textContent).toContain("Merged Preview");
    const merge = Array.from(utils.container.querySelectorAll("button")).find(
      (b) => b.textContent === "Create Merged Work",
    )!;
    await act(async () => {
      fireEvent.click(merge);
    });
    expect(client.workMerge).toHaveBeenCalledWith(BASE, WA, WB);
    expect(utils.onMerged).toHaveBeenCalledWith(0x99);
  });

  it("a conflict defaults to A; choosing B rewrites the merged preview", async () => {
    const client = fakeClient({
      editions: { [BASE]: texts.base, [WA]: texts.conflictA, [WB]: texts.conflictB },
    });
    const utils = renderMerge(client);
    await loadComparison(utils);
    const load = Array.from(utils.container.querySelectorAll("button")).find(
      (b) => b.textContent === "Load Comparison",
    )!;
    await act(async () => {
      fireEvent.click(load);
    });
    expect(utils.container.textContent).toContain("1 conflicts");
    // Default resolution is A: preview carries the A text.
    expect(utils.container.textContent).toContain("alpha version");
    // Choose B on the conflict segment.
    const bBtn = Array.from(utils.container.querySelectorAll("button")).filter(
      (b) => b.textContent === "B",
    )[0];
    await act(async () => {
      fireEvent.click(bBtn);
    });
    // The comparison panes keep BOTH sides; the MERGED PREVIEW is
    // what changes. Its section (after "Merged Preview") carries the
    // B text now.
    const text = utils.container.textContent!;
    const preview = text.slice(text.indexOf("Merged Preview"));
    expect(preview).toContain("beta version");
    expect(preview).not.toContain("alpha version");
  });

  it("a refused merge surfaces the server's error", async () => {
    const client = fakeClient({
      editions: { [BASE]: texts.base, [WA]: texts.aClean, [WB]: texts.bClean },
      mergeError: "merge refused: divergent crums",
    });
    const utils = renderMerge(client);
    await loadComparison(utils);
    const load = Array.from(utils.container.querySelectorAll("button")).find(
      (b) => b.textContent === "Load Comparison",
    )!;
    await act(async () => {
      fireEvent.click(load);
    });
    const merge = Array.from(utils.container.querySelectorAll("button")).find(
      (b) => b.textContent === "Create Merged Work",
    )!;
    await act(async () => {
      fireEvent.click(merge);
    });
    expect(utils.container.textContent).toContain("merge refused");
    expect(utils.onMerged).not.toHaveBeenCalled();
  });
});

describe("ThreeWayDiffPanel", () => {
  it("renders the picker surface for the current work's peers", () => {
    const client = fakeClient();
    const utils = render(
      <ThreeWayDiffPanel
        client={client}
        currentWorkId={0x40}
        works={[work(0x10, "One"), work(0x20, "Two"), work(0x40, "Current")]}
        onClose={vi.fn()}
      />,
    );
    expect(utils.container.textContent).toContain("Three-Way");
  });
});
