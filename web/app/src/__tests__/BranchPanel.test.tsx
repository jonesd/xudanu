import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, it, expect } from "vitest";
import { BranchPanel } from "../components/BranchPanel";
import type { BranchItem } from "../types/api";

const branches: BranchItem[] = [
  { branchId: "main", name: "main", headTraceId: "t-1-1" },
  { branchId: "feature", name: "feature", headTraceId: "t-2-3" },
];

describe("BranchPanel", () => {
  it("renders all branches", () => {
    render(
      <BranchPanel
        branches={branches}
        selectedBranchId={null}
        onSelect={() => {}}
      />,
    );
    expect(screen.getByText("main")).toBeInTheDocument();
    expect(screen.getByText("feature")).toBeInTheDocument();
  });

  it("marks the selected branch", () => {
    const { container } = render(
      <BranchPanel
        branches={branches}
        selectedBranchId="main"
        onSelect={() => {}}
      />,
    );
    const selected = container.querySelector(".branch-selected");
    expect(selected).toBeTruthy();
    expect(selected!.textContent).toContain("main");
  });

  it("calls onSelect when a branch is clicked", async () => {
    const user = userEvent.setup();
    let selected: BranchItem | null = null;
    render(
      <BranchPanel
        branches={branches}
        selectedBranchId={null}
        onSelect={(b) => {
          selected = b;
        }}
      />,
    );
    await user.click(screen.getByText("feature"));
    expect(selected).toBeTruthy();
    expect(selected!.branchId).toBe("feature");
  });
});
