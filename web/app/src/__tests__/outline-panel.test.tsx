import { render, screen, fireEvent } from "@testing-library/react";
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { OutlinePanel } from "../components/OutlinePanel";
import { TextBuffer } from "../api/text_buffer";

const DOC = `Intro paragraph with no heading.

# Alpha

Text under alpha.

## Beta

Text under beta.

# Gamma

Text under gamma.`;

function setup(props: Partial<Parameters<typeof OutlinePanel>[0]> = {}) {
  const buffer = new TextBuffer(DOC);
  const onJumpTo = vi.fn();
  const onMoveSection = vi.fn();
  const onClose = vi.fn();
  render(
    <OutlinePanel
      buffer={buffer}
      onJumpTo={onJumpTo}
      onMoveSection={onMoveSection}
      onClose={onClose}
      {...props}
    />,
  );
  return { buffer, onJumpTo, onMoveSection, onClose };
}

describe("OutlinePanel", () => {
  it("renders every heading with its level and count", () => {
    setup({ onMoveSection: undefined });
    expect(screen.getByText("Alpha")).toBeInTheDocument();
    expect(screen.getByText("Beta")).toBeInTheDocument();
    expect(screen.getByText("Gamma")).toBeInTheDocument();
    expect(screen.getByText("3")).toBeInTheDocument(); // heading count
    expect(screen.getByText("Alpha").closest("button")).toHaveClass("level-1");
    expect(screen.getByText("Beta").closest("button")).toHaveClass("level-2");
  });

  it("shows the empty state when the document has no headings", () => {
    const buffer = new TextBuffer("Just prose.\nNo headings here.");
    render(<OutlinePanel buffer={buffer} onJumpTo={() => {}} onClose={() => {}} />);
    expect(screen.getByText("No headings found")).toBeInTheDocument();
  });

  it("jumps to a heading's offset on click", () => {
    const { onJumpTo } = setup();
    fireEvent.click(screen.getByText("Beta"));
    expect(onJumpTo).toHaveBeenCalledWith(DOC.indexOf("## Beta"));
  });

  it("closes on the × button", () => {
    const { onClose } = setup();
    fireEvent.click(screen.getByText("×"));
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  describe("drag reorder", () => {
    // jsdom lays out everything at (0,0); give entries a real box so
    // the before/after midpoint logic is deterministic. RTL's synthetic
    // drag events also drop clientY and dataTransfer, so build real
    // MouseEvents with a stub DataTransfer for every drag phase.
    const top = 200;
    const height = 40;
    let spy: ReturnType<typeof vi.spyOn>;
    beforeEach(() => {
      spy = vi
        .spyOn(HTMLElement.prototype, "getBoundingClientRect")
        .mockReturnValue({ top, height, bottom: top + height, left: 0, right: 100, width: 100, x: 0, y: top, toJSON: () => ({}) } as DOMRect);
    });
    afterEach(() => spy.mockRestore());

    function dragEvent(type: string, clientY = top + 1) {
      const ev = new MouseEvent(type, { bubbles: true, cancelable: true, clientY });
      Object.defineProperty(ev, "dataTransfer", {
        value: { dropEffect: "move", effectAllowed: "move", setData: () => {}, getData: () => "" },
      });
      return ev;
    }

    const entries = () => screen.getAllByRole("button").filter((b) => b.className.includes("outline-entry"));

    it("reorders a section when dropped after a later heading", () => {
      const { onMoveSection } = setup();
      const es = entries();
      fireEvent(es[0], dragEvent("dragstart"));
      fireEvent(es[2], dragEvent("dragover", top + height - 1)); // below midpoint → after
      fireEvent(es[2], dragEvent("drop", top + height - 1));

      expect(onMoveSection).toHaveBeenCalledTimes(1);
      const movedText = onMoveSection.mock.calls[0][0] as string;
      // Alpha now follows Gamma: Gamma appears before Alpha in the new text
      expect(movedText.indexOf("# Gamma")).toBeLessThan(movedText.indexOf("# Alpha"));
      expect(movedText).toContain("# Beta");
    });

    it("reorders before a NESTED subsection when dropped above the midpoint", () => {
      // Regression: before-drop onto a subsection used to be a silent
      // no-op (the panel targeted the parent's line; moveSection inserts
      // after the parent subtree, which absorbs the subsection). The
      // panel now inserts at the target heading's start instead.
      const { onMoveSection } = setup();
      fireEvent(entries()[2], dragEvent("dragstart")); // drag Gamma
      fireEvent(entries()[1], dragEvent("dragover", top + 1)); // above midpoint → before Beta
      fireEvent(entries()[1], dragEvent("drop", top + 1));

      expect(onMoveSection).toHaveBeenCalledTimes(1);
      const movedText = onMoveSection.mock.calls[0][0] as string;
      expect(movedText.indexOf("# Gamma")).toBeLessThan(movedText.indexOf("## Beta"));
      expect(movedText.indexOf("# Gamma")).toBeGreaterThan(movedText.indexOf("# Alpha"));
    });

    it("reorders before the FIRST heading (drop at top)", () => {
      const { onMoveSection } = setup();
      fireEvent(entries()[2], dragEvent("dragstart")); // drag Gamma
      fireEvent(entries()[0], dragEvent("dragover", top + 1)); // before Alpha
      fireEvent(entries()[0], dragEvent("drop", top + 1));

      const movedText = onMoveSection.mock.calls[0][0] as string;
      expect(movedText.indexOf("# Gamma")).toBeLessThan(movedText.indexOf("# Alpha"));
      expect(movedText.startsWith("Intro paragraph")).toBe(true); // preamble stays put
    });

    it("ignores a drop onto itself", () => {
      const { onMoveSection } = setup();
      const es = entries();
      fireEvent(es[1], dragEvent("dragstart"));
      fireEvent(es[1], dragEvent("dragover", top + 1));
      fireEvent(es[1], dragEvent("drop", top + 1));
      expect(onMoveSection).not.toHaveBeenCalled();
    });

    it("entries are not draggable when onMoveSection is absent", () => {
      setup({ onMoveSection: undefined });
      const entry = screen.getByText("Alpha").closest("button");
      expect(entry).toHaveAttribute("draggable", "false");
    });
  });
});
