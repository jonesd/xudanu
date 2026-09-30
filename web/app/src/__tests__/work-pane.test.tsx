import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { WorkPane, type WorkPaneSelection } from "../components/WorkPane";
import type { CrdtSyncClient } from "../api/crdt_sync";

const TEXT = "The funculator passage stands here for selection.";

function mkClient(overrides: Partial<CrdtSyncClient> = {}): CrdtSyncClient {
  return {
    fetchWorkText: vi.fn(async () => ({
      title: "Pane Fixture",
      text: TEXT,
      revision: 3,
    })),
    ...overrides,
  } as unknown as CrdtSyncClient;
}

/** jsdom selection helper: select [a,b) inside the pane's text node
 * and fire mouseup (the pane's capture point). */
async function selectRange(a: number, b: number) {
  const el = document.querySelector(".work-pane-text") as HTMLElement;
  expect(el, "text container").toBeTruthy();
  const node = el.firstChild as Text;
  const range = document.createRange();
  range.setStart(node, a);
  range.setEnd(node, b);
  const sel = window.getSelection();
  sel?.removeAllRanges();
  sel?.addRange(range);
  fireEvent.mouseUp(el.closest(".work-pane-body") as HTMLElement);
}

describe("WorkPane (text renderer)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    window.getSelection()?.removeAllRanges();
  });

  it("loads and shows the work snapshot (title, id, revision, text)", async () => {
    render(<WorkPane client={mkClient()} workId={0x3e8} connected={true} />);
    await waitFor(() => expect(screen.getByText("Pane Fixture")).toBeTruthy());
    expect(screen.getByText("0x3e8")).toBeTruthy();
    expect(screen.getByText(/v3/)).toBeTruthy();
    expect(document.querySelector(".work-pane-text")?.textContent).toBe(TEXT);
  });

  it("reports selection with exact offsets and slice", async () => {
    const onSel = vi.fn();
    render(
      <WorkPane client={mkClient()} workId={1} connected={true} onSelectionChange={onSel} />,
    );
    await waitFor(() => document.querySelector(".work-pane-text"));
    await selectRange(2, 6);
    expect(onSel).toHaveBeenCalledWith({ start: 2, end: 6, text: "e fu" });
  });

  it("reports null when the selection collapses", async () => {
    const onSel = vi.fn();
    render(
      <WorkPane client={mkClient()} workId={1} connected={true} onSelectionChange={onSel} />,
    );
    await waitFor(() => document.querySelector(".work-pane-text"));
    await selectRange(2, 6);
    window.getSelection()?.removeAllRanges();
    fireEvent.mouseUp(document.querySelector(".work-pane-body") as HTMLElement);
    expect(onSel).toHaveBeenLastCalledWith(null);
  });

  it("Hold as end appears only with a selection and emits its payload", async () => {
    const onHold = vi.fn();
    render(<WorkPane client={mkClient()} workId={1} connected={true} onHoldEnd={onHold} />);
    await waitFor(() => document.querySelector(".work-pane-text"));
    expect(screen.queryByText("Hold as end")).toBeNull();
    await selectRange(4, 13);
    fireEvent.click(screen.getByText("Hold as end"));
    const payload: WorkPaneSelection = onHold.mock.calls[0][0];
    expect(payload.start).toBe(4);
    expect(payload.end).toBe(13);
    // DOM-selection text preferred when present; falls back to the
    // offset slice otherwise (jsdom may report either).
    expect([TEXT.slice(4, 13), "funculator".slice(0, 9)]).toContain(payload.text);
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
    const fetchText = vi.fn().mockReturnValueOnce(first).mockReturnValueOnce(
      Promise.resolve({ title: "New", text: "newer body", revision: 1 }),
    );
    const client = mkClient({ fetchWorkText: fetchText } as Partial<CrdtSyncClient>);
    const { rerender } = render(<WorkPane client={client} workId={1} connected={true} />);
    rerender(<WorkPane client={client} workId={2} connected={true} />);
    await waitFor(() => expect(screen.getByText("New")).toBeTruthy());
    resolveFirst({ title: "Stale", text: "stale body", revision: 0 });
    await new Promise((r) => setTimeout(r, 10));
    expect(screen.queryByText("Stale")).toBeNull();
  });

  it("highlights the held span", async () => {
    render(
      <WorkPane client={mkClient()} workId={1} connected={true} held={{ start: 4, end: 13 }} />,
    );
    await waitFor(() => document.querySelector(".work-pane-text"));
    const mark = document.querySelector(".work-pane-text mark");
    expect(mark).toBeTruthy();
    expect(mark?.textContent).toBe(TEXT.slice(4, 13));
  });

  it("refresh re-fetches the snapshot", async () => {
    const fetchText = vi.fn(async () => ({ title: "T", text: "x", revision: 0 }));
    const client = mkClient({ fetchWorkText: fetchText } as Partial<CrdtSyncClient>);
    render(<WorkPane client={client} workId={1} connected={true} />);
    await waitFor(() => document.querySelector(".work-pane-text"));
    fireEvent.click(screen.getByTitle("Refresh snapshot"));
    await waitFor(() => expect(fetchText).toHaveBeenCalledTimes(2));
  });
});
