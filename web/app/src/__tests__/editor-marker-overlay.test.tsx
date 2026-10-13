import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { render, fireEvent, act } from "@testing-library/react";
import { CollaborativeEditor } from "../components/CollaborativeEditor";
import type { TransclusionMarker, AnnotationEntry } from "../api/crdt_sync";

/**
 * coverage-plan-web.md Phase 2: marker-overlay interactions. The
 * overlay draws pixels (stubbed canvas) but its CONTRACT is
 * geometric: text ranges become hit zones, zones become hover
 * tooltips and click navigation, dense regions collapse to pills.
 * jsdom has no layout — the seams are Range/Element rect stubs with
 * deterministic geometry: every character is 10px wide on a single
 * line at top=10, height=16.
 */

const canvasCtxStub = new Proxy(
  {},
  {
    get: (target: Record<string | symbol, unknown>, prop) => {
      if (prop === "canvas") return { width: 800, height: 600 };
      if (prop === "measureText") return () => ({ width: 10 });
      if (prop === "createLinearGradient" || prop === "createRadialGradient") {
        return () => ({ addColorStop: () => {} });
      }
      if (typeof prop !== "string") return undefined;
      if (!(prop in target)) target[prop] = () => {};
      return target[prop];
    },
    set: () => true,
  },
);

class ResizeObserverStub {
  observe() {}
  unobserve() {}
  disconnect() {}
}
class IntersectionObserverStub {
  observe() {}
  unobserve() {}
  disconnect() {}
  takeRecords(): IntersectionObserverEntry[] {
    return [];
  }
}

const CHAR_W = 10;
const LINE_TOP = 10;
const LINE_H = 16;

function rectFor(start: number, end: number) {
  const left = Math.max(0, start) * CHAR_W;
  const width = Math.max(1, end - Math.max(0, start)) * CHAR_W;
  return { left, top: LINE_TOP, right: left + width, bottom: LINE_TOP + LINE_H, width, height: LINE_H };
}

let rectSpy: (() => void) | null = null;
let elemRectSpy: ReturnType<typeof vi.spyOn> | null = null;

beforeEach(() => {
  vi.useFakeTimers();
  vi.stubGlobal("requestAnimationFrame", (cb: FrameRequestCallback) => setTimeout(() => cb(0), 0) as unknown as number);
  vi.stubGlobal("cancelAnimationFrame", (id: number) => clearTimeout(id));
  vi.stubGlobal("ResizeObserver", ResizeObserverStub);
  vi.stubGlobal("IntersectionObserver", IntersectionObserverStub);
  HTMLCanvasElement.prototype.getContext = vi.fn(() => canvasCtxStub) as never;

  // Deterministic layout: ranges get 10px/char on one line; every
  // element sits at (0,0) in an 800×600 viewport. jsdom defines no
  // Range.getClientRects at all — we own it entirely.
  const proto = Range.prototype as unknown as Record<string, unknown>;
  proto.getClientRects = function (this: Range) {
    const r = rectFor(this.startOffset, this.endOffset);
    return [r] as unknown as DOMRectList;
  };
  rectSpy = () => {
    delete proto.getClientRects;
  };
  elemRectSpy = vi.spyOn(Element.prototype, "getBoundingClientRect").mockImplementation(() =>
    ({ left: 0, top: 0, right: 800, bottom: 600, width: 800, height: 600 }) as DOMRect,
  );
});

afterEach(() => {
  rectSpy?.();
  elemRectSpy?.mockRestore();
  vi.unstubAllGlobals();
  vi.useRealTimers();
});

function marker(over: Partial<TransclusionMarker>): TransclusionMarker {
  return {
    start: 0,
    end: 5,
    linkId: 1,
    direction: "outgoing",
    otherWorkId: 0x30,
    otherWorkTitle: "Alpha Notes",
    color: "#58a6ff",
    linkTypeId: 2,
    ...over,
  } as TransclusionMarker;
}

const DOC = "hello world"; // chars 0-4 | 5 | 6-10

function renderWith(over: Partial<Parameters<typeof CollaborativeEditor>[0]> = {}) {
  const spies = {
    onNavigateToWork: vi.fn(),
    onNavigateToSource: vi.fn(),
    onShowBacklinks: vi.fn(),
    onTextChange: vi.fn(),
    onCursorChange: vi.fn(),
    onSelectionChange: vi.fn(),
  };
  const utils = render(
    <CollaborativeEditor
      text={DOC}
      connected
      editable
      attributionSpans={[]}
      onTextChange={spies.onTextChange}
      onCursorChange={spies.onCursorChange}
      onSelectionChange={spies.onSelectionChange}
      onNavigateToWork={spies.onNavigateToWork}
      onNavigateToSource={spies.onNavigateToSource}
      onShowBacklinks={spies.onShowBacklinks}
      {...over}
    />,
  );
  const overlay = () => utils.container.querySelector<HTMLElement>(".editor-container")!;
  const clickAt = async (x: number, y: number, detail = 1) => {
    await act(async () => {
      fireEvent.click(overlay(), { clientX: x, clientY: y, detail });
    });
  };
  const hoverAt = async (x: number, y: number, ms = 350) => {
    await act(async () => {
      fireEvent.mouseMove(overlay(), { clientX: x, clientY: y });
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(ms);
    });
  };
  return { ...utils, spies, overlay, clickAt, hoverAt };
}

async function flush() {
  await act(async () => {
    await vi.advanceTimersByTimeAsync(50);
  });
}

describe("marker overlay — click navigation", () => {
  it("a click on a marker's zone navigates to the far work", async () => {
    const { spies, clickAt } = renderWith({
      transclusionMarkers: [
        // Outgoing links live in the LEFT margin gutter (zone x ~0-20);
        // incoming links in the RIGHT (x ~780-800, an 800px container).
        marker({ start: 0, end: 5, otherWorkId: 0x30, otherWorkTitle: "Alpha Notes" }),
        marker({ start: 6, end: 11, linkId: 2, direction: "incoming", otherWorkId: 0x40, otherWorkTitle: "Beta Notes", color: "#3fb950", linkTypeId: 3 }),
      ],
    });
    await flush();
    await clickAt(10, 18);
    expect(spies.onNavigateToWork).toHaveBeenCalledWith(0x30);
    await clickAt(787, 18);
    expect(spies.onNavigateToWork).toHaveBeenCalledWith(0x40);
    // A click on the text itself (not a gutter zone) navigates nowhere.
    spies.onNavigateToWork.mockClear();
    await clickAt(80, 18);
    await clickAt(400, 300);
    expect(spies.onNavigateToWork).not.toHaveBeenCalled();
  });

  it("a double-click on a marker opens its backlinks instead of navigating", async () => {
    const { spies, clickAt } = renderWith({
      transclusionMarkers: [marker({ excerpt: "hello" })],
    });
    await flush();
    await clickAt(10, 18, 2);
    expect(spies.onShowBacklinks).toHaveBeenCalledWith(0x30, "hello");
    expect(spies.onNavigateToWork).not.toHaveBeenCalled();
  });

  it("a marker with a jump target prefers onNavigateToSource (work + span travel together)", async () => {
    const { spies, clickAt } = renderWith({
      transclusionMarkers: [
        marker({ target: { workId: 0x77, span: { start: 3, end: 9 } } } as Partial<TransclusionMarker>),
      ],
    });
    await flush();
    await clickAt(10, 18);
    expect(spies.onNavigateToSource).toHaveBeenCalledWith(0x77, 3, 9);
    expect(spies.onNavigateToWork).not.toHaveBeenCalled();
  });
});

describe("marker overlay — hover tooltips", () => {
  it("hovering a zone for 300ms shows the marker tooltip; leaving hides it", async () => {
    const { overlay, hoverAt } = renderWith({
      transclusionMarkers: [marker({})],
    });
    await flush();
    await hoverAt(10, 18);
    expect(document.body.textContent).toContain("Alpha Notes");
    // Leave: the hide timer (2000ms) clears the tooltip.
    await act(async () => {
      fireEvent.mouseLeave(overlay());
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(2100);
    });
    expect(document.querySelector(".marker-tooltip")).toBeNull();
  });

  it("a click pins the tooltip; Escape unpins", async () => {
    const { clickAt } = renderWith({
      transclusionMarkers: [marker({})],
    });
    await flush();
    await clickAt(10, 18);
    expect(document.querySelector(".marker-tooltip")).not.toBeNull();
    await act(async () => {
      fireEvent.keyDown(window, { key: "Escape" });
    });
    expect(document.querySelector(".marker-tooltip")).toBeNull();
  });

  it("annotation hover zones win over marker zones and show the note", async () => {
    const annotations: AnnotationEntry[] = [
      {
        annotation_id: 1,
        kind: "note",
        payload: "a marginal note",
        char_start: 0,
        char_end: 5,
        is_private: false,
        created_by: null,
        created_by_name: null,
        created_at: 0,
      } as AnnotationEntry,
    ];
    const { hoverAt } = renderWith({
      transclusionMarkers: [marker({})],
      annotations,
    });
    await flush();
    await hoverAt(20, 18, 100);
    expect(document.body.textContent).toContain("a marginal note");
  });
});

describe("marker overlay — density pills (the swamp, collapsed)", () => {
  it("≥5 overlapping links collapse to a pill: first click expands, then individual links are clickable", async () => {
    const swamp = Array.from({ length: 6 }, (_, i) =>
      marker({
        linkId: 100 + i,
        start: i,
        end: i + 5,
        otherWorkId: 0x100 + i,
        otherWorkTitle: `Swamp ${i}`,
      }),
    );
    const { spies, clickAt } = renderWith({ transclusionMarkers: swamp });
    await flush();

    // Collapsed: the pill (x 0..~60 on the line) intercepts — one
    // click EXPANDS the cluster; no navigation fires.
    await clickAt(10, 18);
    expect(spies.onNavigateToWork).not.toHaveBeenCalled();

    // Expanded (after the redraw): the member markers are
    // individually clickable again.
    await flush();
    await clickAt(10, 18);
    expect(spies.onNavigateToWork).toHaveBeenCalled();
  });
});
