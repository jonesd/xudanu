import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";


// The editor is the rendering seam — mock it so pane LOGIC is what's
// under test (selection plumbing, hold payload, refresh, error path).
vi.mock("../components/CollaborativeEditor", async () => {
  const React = await import("react");
  return {
    CollaborativeEditor: (props: {
      text: string;
      editable: boolean;
      highlightRange?: { start: number; end: number } | null;
      onSelectionChange: (s: number | null, e: number | null) => void;
    }) =>
      React.createElement(
        "div",
        {
          "data-testid": "editor",
          "data-editable": String(props.editable),
          "data-highlight": JSON.stringify(props.highlightRange ?? null),
          onClick: () => props.onSelectionChange(2, 6),
          onDoubleClick: () => props.onSelectionChange(null, null),
        },
        props.text,
      ),
  };
});

import { WorkPane, type WorkPaneSelection } from "../components/WorkPane";
import type { CrdtSyncClient } from "../api/crdt_sync";

function mkClient(overrides: Partial<CrdtSyncClient> = {}): CrdtSyncClient {
  return {
    fetchWorkText: vi.fn(async () => ({
      title: "Pane Fixture",
      text: "The funculator passage stands here for selection.",
      revision: 3,
    })),
    ...overrides,
  } as unknown as CrdtSyncClient;
}

describe("WorkPane", () => {
  beforeEach(() => vi.clearAllMocks());

  it("loads and shows the work snapshot (title, id, revision)", async () => {
    const client = mkClient();
    render(<WorkPane client={client} workId={0x3e8} connected={true} />);
    await waitFor(() => expect(screen.getByText("Pane Fixture")).toBeTruthy());
    expect(screen.getByText("0x3e8")).toBeTruthy();
    expect(screen.getByText(/v3/)).toBeTruthy();
    expect(screen.getByTestId("editor").textContent).toContain("funculator");
    expect(screen.getByTestId("editor").getAttribute("data-editable")).toBe("false");
  });

  it("clears selection when collapsed and reports via onSelectionChange", async () => {
    const client = mkClient();
    const onSel = vi.fn();
    render(<WorkPane client={client} workId={1} connected={true} onSelectionChange={onSel} />);
    await waitFor(() => screen.getByTestId("editor"));

    fireEvent.click(screen.getByTestId("editor"));
    expect(onSel).toHaveBeenCalledWith({ start: 2, end: 6, text: "e fu" });

    fireEvent.doubleClick(screen.getByTestId("editor"));
    expect(onSel).toHaveBeenLastCalledWith(null);
  });

  it("shows Hold as end only with an active selection and emits the exact slice", async () => {
    const client = mkClient();
    const onHold = vi.fn();
    render(<WorkPane client={client} workId={1} connected={true} onHoldEnd={onHold} />);
    await waitFor(() => screen.getByTestId("editor"));

    expect(screen.queryByText("Hold as end")).toBeNull();
    fireEvent.click(screen.getByTestId("editor"));
    const btn = screen.getByText("Hold as end");
    fireEvent.click(btn);

    expect(onHold).toHaveBeenCalledTimes(1);
    const sel: WorkPaneSelection = onHold.mock.calls[0][0];
    expect(sel.start).toBe(2);
    expect(sel.end).toBe(6);
    // exact slice of the loaded text
    const text = "The funculator passage stands here for selection.";
    expect(sel.text).toBe(text.slice(2, 6));
  });

  it("renders the error state with retry", async () => {
    let calls = 0;
    const client = mkClient({
      fetchWorkText: vi.fn(async () => {
        calls++;
        if (calls === 1) throw new Error("work not found");
        return { title: "Back", text: "second load", revision: 0 };
      }),
    } as Partial<CrdtSyncClient>);
    render(<WorkPane client={client} workId={9} connected={true} />);
    await waitFor(() => expect(screen.getByText(/work not found/)).toBeTruthy());
    fireEvent.click(screen.getByText("retry"));
    await waitFor(() => expect(screen.getByText("Back")).toBeTruthy());
  });

  it("stale loads never overwrite a newer one (seq guard)", async () => {
    let resolveFirst: (v: { title: string; text: string; revision: number }) => void = () => {};
    const first = new Promise<{ title: string; text: string; revision: number }>((res) => {
      resolveFirst = res;
    });
    const fetchText = vi.fn()
      .mockReturnValueOnce(first)
      .mockReturnValueOnce(Promise.resolve({ title: "New", text: "newer", revision: 1 }));
    const client = mkClient({ fetchWorkText: fetchText } as Partial<CrdtSyncClient>);

    const { rerender } = render(<WorkPane client={client} workId={1} connected={true} />);
    // workId changes → second load starts; the first (slow) resolves late.
    rerender(<WorkPane client={client} workId={2} connected={true} />);
    await waitFor(() => expect(screen.getByText("New")).toBeTruthy());
    resolveFirst({ title: "Stale", text: "stale", revision: 0 });
    await new Promise((r) => setTimeout(r, 10));
    expect(screen.queryByText("Stale")).toBeNull();
  });

  it("passes held span through as the editor highlight", async () => {
    const client = mkClient();
    render(
      <WorkPane client={client} workId={1} connected={true} held={{ start: 4, end: 9 }} />,
    );
    await waitFor(() => screen.getByTestId("editor"));
    expect(screen.getByTestId("editor").getAttribute("data-highlight")).toBe(
      JSON.stringify({ start: 4, end: 9 }),
    );
  });

  it("refresh re-fetches the snapshot", async () => {
    const fetchText = vi.fn(async () => ({ title: "T", text: "x", revision: 0 }));
    const client = mkClient({ fetchWorkText: fetchText } as Partial<CrdtSyncClient>);
    render(<WorkPane client={client} workId={1} connected={true} />);
    await waitFor(() => screen.getByTestId("editor"));
    fireEvent.click(screen.getByTitle("Refresh snapshot"));
    await waitFor(() => expect(fetchText).toHaveBeenCalledTimes(2));
  });
});
