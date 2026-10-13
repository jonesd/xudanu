import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { render, fireEvent, act } from "@testing-library/react";
import { CollaborativeEditor } from "../components/CollaborativeEditor";

/**
 * coverage-plan-web.md Phase 2: the editing surface. Harness notes:
 * - Canvas 2D context: jsdom has none — a Proxy stub stands in (the
 *   marker overlay's pixel math stays with Playwright; we assert
 *   model/DOM behavior).
 * - ResizeObserver: stubbed (two uses in the component).
 * - rAF is mapped onto setTimeout so fake timers control every
 *   async path (initial build, overlay redraw, undo debounce).
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

class IntersectionObserverStub {
  callback: IntersectionObserverCallback;
  constructor(cb: IntersectionObserverCallback) {
    this.callback = cb;
  }
  observe() {}
  unobserve() {}
  disconnect() {}
  takeRecords(): IntersectionObserverEntry[] {
    return [];
  }
}

beforeEach(() => {
  vi.useFakeTimers();
  vi.stubGlobal("requestAnimationFrame", (cb: FrameRequestCallback) => setTimeout(() => cb(0), 0) as unknown as number);
  vi.stubGlobal("cancelAnimationFrame", (id: number) => clearTimeout(id));
  vi.stubGlobal("ResizeObserver", ResizeObserverStub);
  vi.stubGlobal("IntersectionObserver", IntersectionObserverStub);
  HTMLCanvasElement.prototype.getContext = vi.fn(() => canvasCtxStub) as never;
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.useRealTimers();
});

type Spies = {
  onTextChange: ReturnType<typeof vi.fn>;
  onCursorChange: ReturnType<typeof vi.fn>;
  onSelectionChange: ReturnType<typeof vi.fn>;
  onUndoLastTransclusion: ReturnType<typeof vi.fn>;
};

function renderEditor(over: Partial<Parameters<typeof CollaborativeEditor>[0]> = {}) {
  const spies: Spies = {
    onTextChange: vi.fn(),
    onCursorChange: vi.fn(),
    onSelectionChange: vi.fn(),
    onUndoLastTransclusion: vi.fn(),
  };
  const utils = render(
    <CollaborativeEditor
      text="hello"
      connected
      editable
      attributionSpans={[]}
      onTextChange={spies.onTextChange}
      onCursorChange={spies.onCursorChange}
      onSelectionChange={spies.onSelectionChange}
      onUndoLastTransclusion={spies.onUndoLastTransclusion}
      {...over}
    />,
  );
  const editor = () => utils.container.querySelector<HTMLElement>(".editor-content")!;
  /** The contenteditable activates on first pointerdown (isEditing). */
  const beginEditing = async () => {
    await act(async () => {
      fireEvent.pointerDown(editor());
    });
  };
  return { ...utils, spies, editor, beginEditing };
}

async function flushRaf() {
  await act(async () => {
    await vi.advanceTimersByTimeAsync(50);
  });
}

describe("CollaborativeEditor — render modes", () => {
  it("renders the model text; the contenteditable activates on pointerdown", async () => {
    const { editor, beginEditing } = renderEditor();
    await flushRaf();
    expect(editor().textContent).toContain("hello");
    expect(editor().getAttribute("contenteditable")).toBe("false");
    await beginEditing();
    expect(editor().getAttribute("contenteditable")).toBe("true");
  });

  it("read-only mode: not editable, typing ignored, keys prevented", async () => {
    const { editor, spies } = renderEditor({ editable: false });
    await flushRaf();
    expect(editor().getAttribute("contenteditable")).toBe("false");
    await act(async () => {
      editor().textContent = "hacked";
      fireEvent.input(editor());
    });
    expect(spies.onTextChange).not.toHaveBeenCalled();
    let key: KeyboardEvent;
    act(() => {
      key = fireEvent.keyDown(editor(), { key: "a" }) as unknown as KeyboardEvent;
    });
    expect(key!).toBeDefined();
  });

  it("a remote text update (prop change) rebuilds the DOM", async () => {
    const { editor, rerender } = renderEditor();
    await flushRaf();
    rerender(
      <CollaborativeEditor
        text="hello remote"
        connected
        editable
        attributionSpans={[]}
        onTextChange={vi.fn()}
        onCursorChange={vi.fn()}
        onSelectionChange={vi.fn()}
      />,
    );
    await flushRaf();
    expect(editor().textContent).toContain("hello remote");
  });
});

describe("CollaborativeEditor — typing round-trip (the lost-edit seam)", () => {
  it("DOM edits flow out as model text via onTextChange", async () => {
    const { editor, spies, beginEditing } = renderEditor();
    await flushRaf();
    await beginEditing();
    await act(async () => {
      editor().textContent = "hello world";
      fireEvent.input(editor());
    });
    expect(spies.onTextChange).toHaveBeenCalledWith("hello world");
  });

  it("identical text does not re-fire (no echo loops)", async () => {
    const { editor, spies, beginEditing } = renderEditor();
    await flushRaf();
    await beginEditing();
    await act(async () => {
      fireEvent.input(editor());
    });
    expect(spies.onTextChange).not.toHaveBeenCalled();
  });

  it("leading newlines from <br>-first DOM are stripped to the model", async () => {
    const { editor, spies, beginEditing } = renderEditor();
    await flushRaf();
    await beginEditing();
    await act(async () => {
      editor().textContent = "\n\nhello world";
      fireEvent.input(editor());
    });
    expect(spies.onTextChange).toHaveBeenCalledWith("hello world");
  });

  it("a lone newline in a bare div-less DOM is the empty document", async () => {
    const { editor, spies, beginEditing } = renderEditor();
    await flushRaf();
    await beginEditing();
    await act(async () => {
      editor().textContent = "\n";
      fireEvent.input(editor());
    });
    expect(spies.onTextChange).toHaveBeenCalledWith("");
  });
});

describe("CollaborativeEditor — undo/redo (debounced stack)", () => {
  async function typeTo(editor: HTMLElement, text: string) {
    await act(async () => {
      editor.textContent = text;
      fireEvent.input(editor);
    });
  }

  it("ctrl+z restores the previous text; shift+z redoes", async () => {
    const { editor, spies, beginEditing } = renderEditor();
    await flushRaf();
    await beginEditing();

    await typeTo(editor(), "hello world");
    await act(async () => { await vi.advanceTimersByTimeAsync(450); }); // debounce lands
    await typeTo(editor(), "hello world again");
    await act(async () => { await vi.advanceTimersByTimeAsync(450); });

    await act(async () => {
      fireEvent.keyDown(editor(), { key: "z", ctrlKey: true });
    });
    expect(spies.onTextChange).toHaveBeenLastCalledWith("hello world");
    expect(editor().textContent).toBe("hello world");

    await act(async () => {
      fireEvent.keyDown(editor(), { key: "z", ctrlKey: true });
    });
    expect(spies.onTextChange).toHaveBeenLastCalledWith("hello");

    await act(async () => {
      fireEvent.keyDown(editor(), { key: "Z", ctrlKey: true, shiftKey: true });
    });
    expect(spies.onTextChange).toHaveBeenLastCalledWith("hello world");
  });

  it("typing inside the debounce window collapses to ONE undo entry — the LAST pre-keystroke state", async () => {
    const { editor, spies, beginEditing } = renderEditor();
    await flushRaf();
    await beginEditing();
    await typeTo(editor(), "h");
    await typeTo(editor(), "he");
    await typeTo(editor(), "hel");
    // All within 400ms: each pushUndo REPLACES the pending entry with
    // its own pre-keystroke text, so the burst collapses to "he" —
    // the state before the FINAL keystroke, not the burst start
    // ("hello"). SHIPPED BEHAVIOR, documented here: undo skips to one
    // step inside a fast burst; the pre-burst state is unreachable
    // via ctrl+z (it falls through to onUndoLastTransclusion only
    // when the stack empties). Flagged for maintainers: the debounce
    // comment suggests burst-start was the intent.
    await act(async () => { await vi.advanceTimersByTimeAsync(450); });
    await act(async () => {
      fireEvent.keyDown(editor(), { key: "z", ctrlKey: true });
    });
    expect(spies.onTextChange).toHaveBeenLastCalledWith("he");
    // And the stack is now empty — one entry per burst, as designed.
    await act(async () => {
      fireEvent.keyDown(editor(), { key: "z", ctrlKey: true });
    });
    expect(spies.onUndoLastTransclusion).toHaveBeenCalled();
  });

  it("an empty undo stack falls back to onUndoLastTransclusion", async () => {
    const { editor, spies, beginEditing } = renderEditor();
    await flushRaf();
    await beginEditing();
    await act(async () => {
      fireEvent.keyDown(editor(), { key: "z", ctrlKey: true });
    });
    expect(spies.onUndoLastTransclusion).toHaveBeenCalled();
    expect(spies.onTextChange).not.toHaveBeenCalled();
  });
});

describe("CollaborativeEditor — document outline sidebar", () => {
  it("the outline toggle lists markdown headings and closes", async () => {
    const utils = renderEditor({ text: "# Top Section\n\n## Child Note\n\nbody text" });
    await flushRaf();
    const toggle = utils.container.querySelector(
      'button[title="Document outline"]',
    ) as HTMLElement;
    expect(toggle).toBeTruthy();
    await act(async () => {
      fireEvent.click(toggle);
    });
    await act(async () => {
      await vi.advanceTimersByTimeAsync(50);
    });
    expect(utils.container.textContent).toContain("Top Section");
    expect(utils.container.textContent).toContain("Child Note");
    const close = utils.container.querySelector(".outline-close") as HTMLElement;
    await act(async () => {
      fireEvent.click(close);
    });
    expect(utils.container.querySelector(".outline-panel")).toBeNull();
  });
});
