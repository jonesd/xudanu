import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { render, fireEvent, act } from "@testing-library/react";
import { VirtualizedEditor } from "../components/VirtualizedEditor";

/**
 * coverage-plan-web.md Phase 2: VirtualizedEditor — large-document
 * windowing. The critical property is handleInput's STITCHING: an
 * edit inside the visible window must be merged into the full
 * document at exactly the right offsets
 * (`old.slice(0, viewportCharStart) + visible + old.slice(viewportCharEnd)`).
 * Wrong viewport math here means edits land in the wrong place —
 * silent corruption. These tests pin the math.
 */

const canvasCtxStub = new Proxy(
  {},
  {
    get: (target: Record<string | symbol, unknown>, prop) => {
      if (prop === "canvas") return { width: 800, height: 600 };
      if (prop === "measureText") return () => ({ width: 8 });
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

const LINE_H = 15 * 1.7; // fontSize 15 × lineHeight 1.7
const PAD = 16;
const OVERSCAN = 15;

// 100 deterministic lines.
const LINES = Array.from({ length: 100 }, (_, i) => `line-${String(i).padStart(3, "0")}`);
const FULL = LINES.join("\n");

function windowFor(scrollTop: number, viewportH: number, totalLines: number) {
  const first = Math.max(0, Math.floor((scrollTop - PAD) / LINE_H) - OVERSCAN);
  const last = Math.min(totalLines, Math.ceil((scrollTop - PAD + viewportH) / LINE_H) + OVERSCAN);
  return [first, last] as const;
}

beforeEach(() => {
  vi.useFakeTimers();
  vi.stubGlobal("requestAnimationFrame", (cb: FrameRequestCallback) => setTimeout(() => cb(0), 0) as unknown as number);
  vi.stubGlobal("cancelAnimationFrame", (id: number) => clearTimeout(id));
  vi.stubGlobal("ResizeObserver", ResizeObserverStub);
  HTMLCanvasElement.prototype.getContext = vi.fn(() => canvasCtxStub) as never;
  // jsdom has no Element.scrollTo — the deep-link effect needs it.
  // Fresh per test: the deep-link test asserts on this spy.
  (Element.prototype as unknown as Record<string, unknown>).scrollTo = vi.fn();
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.useRealTimers();
  window.location.hash = "";
});

function renderVirt(over: Partial<Parameters<typeof VirtualizedEditor>[0]> = {}) {
  const spies = {
    onTextChange: vi.fn(),
    onCursorChange: vi.fn(),
    onSelectionChange: vi.fn(),
  };
  const utils = render(
    <VirtualizedEditor
      text={FULL}
      connected
      editable
      attributionSpans={[]}
      onTextChange={spies.onTextChange}
      onCursorChange={spies.onCursorChange}
      onSelectionChange={spies.onSelectionChange}
      {...over}
    />,
  );
  const container = () => utils.container.querySelector<HTMLElement>(".virtual-scroll-container")!;
  const editor = () => utils.container.querySelector<HTMLElement>(".editor-content")!;
  const topSpacer = () => utils.container.querySelectorAll<HTMLElement>(".virtual-spacer")[0];
  const bottomSpacer = () => utils.container.querySelectorAll<HTMLElement>(".virtual-spacer")[1];
  return { ...utils, spies, container, editor, topSpacer, bottomSpacer };
}

async function flush() {
  await act(async () => {
    await vi.advanceTimersByTimeAsync(20);
  });
}

/** jsdom's containers have zero height — give the viewport real ones. */
function setViewport(el: HTMLElement, clientHeight: number, scrollTop: number) {
  Object.defineProperty(el, "clientHeight", { value: clientHeight, configurable: true });
  el.scrollTop = scrollTop;
}

async function scrollTo(c: HTMLElement, top: number, clientHeight = 600) {
  setViewport(c, clientHeight, top);
  await act(async () => {
    fireEvent.scroll(c);
  });
  await flush();
}

describe("VirtualizedEditor — windowing", () => {
  it("initial view renders the first window (zero-height viewport)", async () => {
    const { editor } = renderVirt();
    await flush();
    const [vs, ve] = windowFor(0, 0, 100);
    // getLinesRange includes the newline before line `ve`: the DOM
    // slice ends with \n (the stitch contract — see below).
    expect(editor().textContent).toBe(LINES.slice(vs, ve).join("\n") + "\n");
    expect(editor().getAttribute("contenteditable")).toBe("true");
  });

  it("scroll math selects the right window and sizes the spacers", async () => {
    const { editor, container, topSpacer, bottomSpacer } = renderVirt();
    await flush();
    await scrollTo(container(), 800);
    const [vs, ve] = windowFor(800, 600, 100);
    expect(editor().textContent).toBe(LINES.slice(vs, ve).join("\n") + "\n");
    // Top spacer: PAD + vs × line-height (jsdom rect heights are 0 →
    // the nominal line height is used).
    expect(topSpacer().style.height).toBe(`${PAD + vs * LINE_H}px`);
    // Bottom spacer keeps the scrollbar honest: total − top − visible.
    const visibleH = (ve - vs) * LINE_H;
    const totalH = PAD + 100 * LINE_H + PAD;
    expect(bottomSpacer().style.height).toBe(`${Math.max(0, totalH - PAD - vs * LINE_H - visibleH)}px`);
  });

  it("the window clamps at the document end", async () => {
    const { editor, container } = renderVirt();
    await flush();
    await scrollTo(container(), 100000);
    const [vse] = [windowFor(100000, 600, 100)[0]];
    expect(editor().textContent).toBe(LINES.slice(vse).join("\n")); // window ends AT the last line: no trailing \n
  });

  it("read-only: not editable and typing is ignored", async () => {
    const { editor, spies } = renderVirt({ editable: false });
    await flush();
    expect(editor().getAttribute("contenteditable")).toBe("false");
    await act(async () => {
      editor().textContent = "hacked";
      fireEvent.input(editor());
    });
    expect(spies.onTextChange).not.toHaveBeenCalled();
    act(() => {
      fireEvent.keyDown(editor(), { key: "a" });
    });
  });
});

describe("VirtualizedEditor — the stitching guard (no silent corruption)", () => {
  it("an edit inside a scrolled window lands at the right line", async () => {
    const { editor, container, spies } = renderVirt();
    await flush();
    await scrollTo(container(), 800);
    const [vs, ve] = windowFor(800, 600, 100);

    // Replace the rendered text of model line 20 (inside [vs, ve)).
    // NOTE THE CONTRACT: the rendered slice ends with \n, and
    // handleInput stitches `prefix + visible + suffix` with NO guard
    // that visible ends with a newline — real typing preserves it, but
    // any DOM state that loses it silently CONCATENATES the window's
    // last line with the first suffix line in the saved document.
    // Unguarded assumption, flagged for maintainers.
    const edited = LINES.slice(vs, ve);
    const idxInWindow = 20 - vs;
    edited[idxInWindow] = "EDITED-LINE-020";
    await act(async () => {
      editor().textContent = edited.join("\n") + "\n";
      fireEvent.input(editor());
    });

    const call = spies.onTextChange.mock.calls.at(-1)?.[0] as string;
    const outLines = call.split("\n");
    expect(outLines).toHaveLength(100);
    expect(outLines[20]).toBe("EDITED-LINE-020");
    // Everything before the window, after the window, and in between
    // is byte-identical.
    for (let i = 0; i < 100; i++) {
      if (i !== 20) expect(outLines[i]).toBe(LINES[i]);
    }
  });

  it("an edit in the INITIAL window (offset 0) stitches correctly", async () => {
    const { editor, spies } = renderVirt();
    await flush();
    const [vs, ve] = windowFor(0, 0, 100);
    const edited = LINES.slice(vs, ve);
    edited[2] = "first-window-edit";
    await act(async () => {
      editor().textContent = edited.join("\n") + "\n";
      fireEvent.input(editor());
    });
    const outLines = (spies.onTextChange.mock.calls.at(-1)?.[0] as string).split("\n");
    expect(outLines[2]).toBe("first-window-edit");
    expect(outLines[ve]).toBe(LINES[ve]); // untouched tail starts exactly at ve
  });

  it("no visible change → no onTextChange echo", async () => {
    const { editor, spies } = renderVirt();
    await flush();
    await act(async () => {
      fireEvent.input(editor());
    });
    expect(spies.onTextChange).not.toHaveBeenCalled();
  });

  it("ctrl+z after a windowed edit restores the full pre-edit text", async () => {
    const { editor, container, spies } = renderVirt();
    await flush();
    await scrollTo(container(), 800);
    const [vs, ve] = windowFor(800, 600, 100);
    const edited = LINES.slice(vs, ve);
    edited[0] = "window-head edit";
    await act(async () => {
      editor().textContent = edited.join("\n") + "\n";
      fireEvent.input(editor());
    });
    await act(async () => { await vi.advanceTimersByTimeAsync(450); }); // undo debounce lands
    await act(async () => {
      fireEvent.keyDown(editor(), { key: "z", ctrlKey: true });
    });
    expect(spies.onTextChange.mock.calls.at(-1)?.[0]).toBe(FULL);
  });
});

describe("VirtualizedEditor — deep links", () => {
  it("#L50 scrolls the container to that line's position", async () => {
    window.location.hash = "#L50";
    renderVirt();
    await flush();
    const scrollSpy = (Element.prototype as unknown as { scrollTo: ReturnType<typeof vi.fn> }).scrollTo;
    expect(scrollSpy).toHaveBeenCalled();
    const arg = scrollSpy.mock.calls.find((c: unknown[]) => typeof c[0] === "object")?.[0] as { top: number };
    // PADDING_TOP + line × line-height − viewport/3 (viewport 0 here).
    expect(arg.top).toBe(PAD + 50 * LINE_H - 0 / 3);
    // The hash is consumed.
    expect(window.location.hash).toBe("");
  });
});
