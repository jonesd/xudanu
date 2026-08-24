import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { TransclusionBadge } from "../components/TransclusionBadge";
import type { PendingTransclusion } from "../hooks/useTransclusion";

function mkPending(over: Partial<PendingTransclusion> = {}): PendingTransclusion {
  return {
    sourceWorkId: 42,
    sourceWorkTitle: "Source Doc",
    start: 0,
    end: 5,
    text: "quote",
    ...over,
  } as PendingTransclusion;
}

describe("TransclusionBadge (FR-37 pinned quotations)", () => {
  it("offers both live and pinned placement", () => {
    const onPlace = vi.fn();
    const onPlacePinned = vi.fn();
    render(
      <TransclusionBadge
        pending={mkPending()}
        cursorPosition={7}
        onPlace={onPlace}
        onPlacePinned={onPlacePinned}
        onCancel={vi.fn()}
      />,
    );
    expect(screen.getByRole("button", { name: /live link/i })).toBeTruthy();
    expect(screen.getByRole("button", { name: /pinned quote/i })).toBeTruthy();
  });

  it("live button calls onPlace at the cursor", () => {
    const onPlace = vi.fn();
    render(
      <TransclusionBadge
        pending={mkPending()}
        cursorPosition={9}
        onPlace={onPlace}
        onPlacePinned={vi.fn()}
        onCancel={vi.fn()}
      />,
    );
    fireEvent.click(screen.getByRole("button", { name: /live link/i }));
    expect(onPlace).toHaveBeenCalledWith(9);
  });

  it("pinned button calls onPlacePinned (FR-37: revision-frozen)", () => {
    const onPlacePinned = vi.fn();
    render(
      <TransclusionBadge
        pending={mkPending()}
        cursorPosition={3}
        onPlace={vi.fn()}
        onPlacePinned={onPlacePinned}
        onCancel={vi.fn()}
      />,
    );
    fireEvent.click(screen.getByRole("button", { name: /pinned quote/i }));
    expect(onPlacePinned).toHaveBeenCalledWith(3);
  });

  it("hides placement buttons without a cursor position", () => {
    render(
      <TransclusionBadge
        pending={mkPending()}
        cursorPosition={null}
        onPlace={vi.fn()}
        onPlacePinned={vi.fn()}
        onCancel={vi.fn()}
      />,
    );
    expect(screen.queryByRole("button", { name: /live link/i })).toBeNull();
    expect(screen.queryByRole("button", { name: /pinned quote/i })).toBeNull();
  });
});

describe("TransclusionBadge (placement polish)", () => {
  it("Append-to-end button calls onPlaceAtEnd", () => {
    const onPlaceAtEnd = vi.fn();
    render(
      <TransclusionBadge
        pending={mkPending()}
        cursorPosition={null}
        onPlace={vi.fn()}
        onPlacePinned={vi.fn()}
        onCancel={vi.fn()}
        onPlaceAtEnd={onPlaceAtEnd}
      />,
    );
    const btn = screen.getByRole("button", { name: /append to end/i });
    expect(btn).toBeTruthy();
    fireEvent.click(btn);
    expect(onPlaceAtEnd).toHaveBeenCalledTimes(1);
  });

  it("Place-in picker lists other works, excludes the source, and switches on click", () => {
    const onSwitchWork = vi.fn();
    render(
      <TransclusionBadge
        pending={mkPending()}
        cursorPosition={null}
        onPlace={vi.fn()}
        onPlacePinned={vi.fn()}
        onCancel={vi.fn()}
        onSwitchWork={onSwitchWork}
        recentWorks={[
          { work_id: 42, title: "Source Doc" },
          { work_id: 7, title: "Target Doc" },
          { work_id: 9, title: "Another Doc" },
        ]}
      />,
    );
    fireEvent.click(screen.getByRole("button", { name: /place in/i }));
    const items = screen.getAllByRole("menu", { hidden: true }).flatMap((m) =>
      Array.from(m.querySelectorAll("button")),
    );
    const titles = items.map((b) => b.textContent);
    expect(titles).toContain("Target Doc");
    expect(titles).toContain("Another Doc");
    expect(titles).not.toContain("Source Doc");
    fireEvent.click(screen.getByRole("button", { name: "Target Doc" }));
    expect(onSwitchWork).toHaveBeenCalledWith(7);
  });

  it("hides the picker when no other works exist", () => {
    render(
      <TransclusionBadge
        pending={mkPending()}
        cursorPosition={null}
        onPlace={vi.fn()}
        onPlacePinned={vi.fn()}
        onCancel={vi.fn()}
        onSwitchWork={vi.fn()}
        recentWorks={[{ work_id: 42, title: "Source Doc" }]}
      />,
    );
    expect(screen.queryByRole("button", { name: /place in/i })).toBeNull();
  });
});
