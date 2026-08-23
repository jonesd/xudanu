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
