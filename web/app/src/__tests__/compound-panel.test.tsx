import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { CompoundPanel } from "../components/CompoundPanel";
import { CrdtSyncClient } from "../api/crdt_sync";

function mkClient(): CrdtSyncClient {
  const client = new CrdtSyncClient("ws://test", 1);
  client.resolveInlineTransclusions = vi.fn().mockResolvedValue({
    text: "Hello world",
    spanRanges: [
      { source_work_id: 2, char_start: 0, char_end: 5, flat_start: 0, flat_end: 5 },
    ],
  });
  client.compoundGetEdition = vi.fn().mockResolvedValue({ elements: [] });
  return client;
}

const mkSpanRanges = () => [
  { source_work_id: 2, char_start: 0, char_end: 5, flat_start: 0, flat_end: 5 },
];

const mkSourceTitles = () => ({ 2: "Canon" });

describe("CompoundPanel", () => {
  it("renders nothing when no elements and not editable", async () => {
    const client = mkClient();
    const { container } = render(
      <CompoundPanel
        client={client}
        workBeId={1}
        canEdit={false}
        sourceTitles={{}}
        spanRanges={[]}
        onReload={vi.fn()}
        onInsertElement={vi.fn()}
        onRemoveElement={vi.fn()}
        onMoveElement={vi.fn()}
      />,
    );
    await waitFor(() => {
      expect(container).toBeEmptyDOMElement();
    });
  });

  it("shows empty hint when editable but no transclusions", async () => {
    const client = mkClient();
    client.resolveInlineTransclusions = vi.fn().mockResolvedValue({ text: "", spanRanges: [] });
    render(
      <CompoundPanel
        client={client}
        workBeId={1}
        canEdit={true}
        sourceTitles={{}}
        spanRanges={[]}
        onReload={vi.fn()}
        onInsertElement={vi.fn()}
        onRemoveElement={vi.fn()}
        onMoveElement={vi.fn()}
      />,
    );
    await waitFor(() => {
      expect(screen.getByText(/No transclusions/)).toBeTruthy();
    });
  });

  it("shows element count in header", async () => {
    const client = mkClient();
    render(
      <CompoundPanel
        client={client}
        workBeId={1}
        canEdit={true}
        sourceTitles={mkSourceTitles()}
        spanRanges={mkSpanRanges()}
        onReload={vi.fn()}
        onInsertElement={vi.fn()}
        onRemoveElement={vi.fn()}
        onMoveElement={vi.fn()}
      />,
    );
    await waitFor(() => {
      expect(screen.getByText(/Compound Structure \(1 elements\)/)).toBeTruthy();
    });
  });

  it("shows source work title for span elements", async () => {
    const client = mkClient();
    render(
      <CompoundPanel
        client={client}
        workBeId={1}
        canEdit={true}
        sourceTitles={mkSourceTitles()}
        spanRanges={mkSpanRanges()}
        onReload={vi.fn()}
        onInsertElement={vi.fn()}
        onRemoveElement={vi.fn()}
        onMoveElement={vi.fn()}
      />,
    );
    await waitFor(() => {
      expect(screen.getByText("Canon")).toBeTruthy();
    });
  });

  it("shows char range for span elements", async () => {
    const client = mkClient();
    render(
      <CompoundPanel
        client={client}
        workBeId={1}
        canEdit={true}
        sourceTitles={mkSourceTitles()}
        spanRanges={mkSpanRanges()}
        onReload={vi.fn()}
        onInsertElement={vi.fn()}
        onRemoveElement={vi.fn()}
        onMoveElement={vi.fn()}
      />,
    );
    await waitFor(() => {
      expect(screen.getByText("[0:5]")).toBeTruthy();
    });
  });

  it("shows resolved text preview", async () => {
    const client = mkClient();
    render(
      <CompoundPanel
        client={client}
        workBeId={1}
        canEdit={true}
        sourceTitles={mkSourceTitles()}
        spanRanges={mkSpanRanges()}
        onReload={vi.fn()}
        onInsertElement={vi.fn()}
        onRemoveElement={vi.fn()}
        onMoveElement={vi.fn()}
      />,
    );
    await waitFor(() => {
      expect(screen.getByText(/Hello world/)).toBeTruthy();
    });
  });

  it("shows edit buttons when canEdit", async () => {
    const client = mkClient();
    render(
      <CompoundPanel
        client={client}
        workBeId={1}
        canEdit={true}
        sourceTitles={mkSourceTitles()}
        spanRanges={mkSpanRanges()}
        onReload={vi.fn()}
        onInsertElement={vi.fn()}
        onRemoveElement={vi.fn()}
        onMoveElement={vi.fn()}
      />,
    );
    await waitFor(() => {
      expect(screen.getByTitle("Remove")).toBeTruthy();
      expect(screen.getByTitle("Move up")).toBeTruthy();
      expect(screen.getByTitle("Move down")).toBeTruthy();
    });
  });

  it("hides edit buttons when not editable", async () => {
    const client = mkClient();
    render(
      <CompoundPanel
        client={client}
        workBeId={1}
        canEdit={false}
        sourceTitles={mkSourceTitles()}
        spanRanges={mkSpanRanges()}
        onReload={vi.fn()}
        onInsertElement={vi.fn()}
        onRemoveElement={vi.fn()}
        onMoveElement={vi.fn()}
      />,
    );
    await waitFor(() => {
      expect(screen.getByText("Canon")).toBeTruthy();
    });
    expect(screen.queryByTitle("Remove")).toBeNull();
  });

  it("calls onRemoveTransclusion when remove clicked", async () => {
    const client = mkClient();
    const onRemoveTransclusion = vi.fn().mockResolvedValue(true);
    const onReload = vi.fn();
    render(
      <CompoundPanel
        client={client}
        workBeId={1}
        canEdit={true}
        sourceTitles={mkSourceTitles()}
        spanRanges={mkSpanRanges()}
        onReload={onReload}
        onInsertElement={vi.fn()}
        onRemoveElement={vi.fn()}
        onMoveElement={vi.fn()}
        onRemoveTransclusion={onRemoveTransclusion}
      />,
    );
    await waitFor(() => {
      expect(screen.getByTitle("Remove")).toBeTruthy();
    });
    fireEvent.click(screen.getByTitle("Remove"));
    await waitFor(() => {
      expect(onRemoveTransclusion).toHaveBeenCalledWith(2, 0, 5);
    });
  });

  it("collapses and expands", async () => {
    const client = mkClient();
    const { container } = render(
      <CompoundPanel
        client={client}
        workBeId={1}
        canEdit={true}
        sourceTitles={mkSourceTitles()}
        spanRanges={mkSpanRanges()}
        onReload={vi.fn()}
        onInsertElement={vi.fn()}
        onRemoveElement={vi.fn()}
        onMoveElement={vi.fn()}
      />,
    );
    await waitFor(() => {
      expect(container.textContent).toContain("Canon");
    });
    const header = screen.getByText(/Compound Structure/);
    fireEvent.click(header);
    expect(container.textContent).not.toContain("Canon");
    fireEvent.click(header);
    expect(container.textContent).toContain("Canon");
  });
});
