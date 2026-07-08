import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { createRef } from "react";
import { LinkCreator } from "../components/LinkCreator";
import type { LinkCreatorSource } from "../components/LinkCreator";
import { CrdtSyncClient } from "../api/crdt_sync";
import type { WorkListEntry } from "../api/crdt_sync";

function mkClient(): CrdtSyncClient {
  const client = new CrdtSyncClient("ws://test", 1);
  client.sendRequest = vi.fn().mockResolvedValue({ type: "ok", value: 42 });
  return client;
}

function mkSource(): LinkCreatorSource {
  return {
    workId: 0x10,
    workTitle: "My Essay",
    start: 10,
    end: 30,
    text: "privacy is a human right",
  };
}

function mkWorks(): WorkListEntry[] {
  return [
    { work_id: 0x10, owner: null, revision_count: 1, is_grabbed: false, title: "My Essay", read_club: null },
    { work_id: 0x20, owner: null, revision_count: 1, is_grabbed: false, title: "Reviewer Notes", read_club: null },
    { work_id: 0x30, owner: null, revision_count: 1, is_grabbed: false, title: "Canon", read_club: null },
  ];
}

function renderCreator(overrides: {
  open?: boolean;
  source?: LinkCreatorSource | null;
  works?: WorkListEntry[];
  client?: CrdtSyncClient;
  onLinkCreated?: () => void;
  onSelectTextInOtherDoc?: () => void;
} = {}) {
  const clientRef = createRef<CrdtSyncClient | null>();
  (clientRef as React.MutableRefObject<CrdtSyncClient | null>).current = overrides.client ?? mkClient();
  const onLinkCreated = overrides.onLinkCreated ?? vi.fn();
  const onSelectTextInOtherDoc = overrides.onSelectTextInOtherDoc ?? vi.fn();
  const source = "source" in overrides ? overrides.source! : mkSource();

  return render(
    <LinkCreator
      open={overrides.open ?? true}
      source={source}
      works={overrides.works ?? mkWorks()}
      currentWorkId={0x10}
      clientRef={clientRef as React.MutableRefObject<CrdtSyncClient | null>}
      onLinkCreated={onLinkCreated}
      onClose={vi.fn()}
      onSelectTextInOtherDoc={onSelectTextInOtherDoc}
    />,
  );
}

describe("LinkCreator", () => {
  it("renders nothing when open is false", () => {
    const { container } = renderCreator({ open: false });
    expect(container).toBeEmptyDOMElement();
  });

  it("renders nothing when source is null", () => {
    const { container } = renderCreator({ source: null });
    expect(container).toBeEmptyDOMElement();
  });

  it("shows source text preview", () => {
    renderCreator();
    expect(screen.getByText(/privacy is a human right/)).toBeTruthy();
  });

  it("shows all four target options", () => {
    renderCreator();
    expect(screen.getByText("Link to an entire document")).toBeTruthy();
    expect(screen.getByText("Link to specific text in another document")).toBeTruthy();
    expect(screen.getByText("Link to another part of this document")).toBeTruthy();
    expect(screen.getByText("Link to a remote server")).toBeTruthy();
  });

  it("does not show same-doc option when current work differs from source", () => {
    renderCreator({ source: { ...mkSource(), workId: 0x99 } });
    expect(screen.queryByText("Link to another part of this document")).toBeNull();
  });

  it("shows work list when whole-work target is chosen", () => {
    renderCreator();
    fireEvent.click(screen.getByText("Link to an entire document"));
    expect(screen.getByText("Select a document:")).toBeTruthy();
    expect(screen.getByText("Reviewer Notes")).toBeTruthy();
    expect(screen.getByText("Canon")).toBeTruthy();
  });

  it("filters out the source work from the work list", () => {
    renderCreator();
    fireEvent.click(screen.getByText("Link to an entire document"));
    expect(screen.queryByText("My Essay")).toBeNull();
  });

  it("shows empty state when no other works exist", () => {
    renderCreator({
      works: [
        { work_id: 0x10, owner: null, revision_count: 0, is_grabbed: false, title: "My Essay", read_club: null },
      ],
    });
    fireEvent.click(screen.getByText("Link to an entire document"));
    expect(screen.getByText("No other documents available")).toBeTruthy();
  });

  it("shows type grid after picking a work", () => {
    renderCreator();
    fireEvent.click(screen.getByText("Link to an entire document"));
    fireEvent.click(screen.getByText("Reviewer Notes"));
    expect(screen.getByText("Link type")).toBeTruthy();
    expect(screen.getByText("Comment")).toBeTruthy();
    expect(screen.getByText("Reference")).toBeTruthy();
    expect(screen.getByText("Disagreement")).toBeTruthy();
    expect(screen.getByText("Quotation")).toBeTruthy();
    expect(screen.getByText("See Also")).toBeTruthy();
  });

  it("calls onSelectTextInOtherDoc when other-doc-text chosen", () => {
    const onSelectTextInOtherDoc = vi.fn();
    renderCreator({ onSelectTextInOtherDoc });
    fireEvent.click(screen.getByText("Link to specific text in another document"));
    expect(onSelectTextInOtherDoc).toHaveBeenCalledTimes(1);
  });

  it("calls onSelectTextInOtherDoc when same-doc chosen", () => {
    const onSelectTextInOtherDoc = vi.fn();
    renderCreator({ onSelectTextInOtherDoc });
    fireEvent.click(screen.getByText("Link to another part of this document"));
    expect(onSelectTextInOtherDoc).toHaveBeenCalledTimes(1);
  });

  it("creates whole-work link via linkCreate + linkSetTypes", async () => {
    const client = mkClient();
    renderCreator({ client });

    fireEvent.click(screen.getByText("Link to an entire document"));
    fireEvent.click(screen.getByText("Reviewer Notes"));
    fireEvent.click(screen.getByText("Comment"));
    fireEvent.click(screen.getByRole("button", { name: "Create Link" }));

    await waitFor(() => {
      expect(client.sendRequest).toHaveBeenCalledWith("link_create", expect.objectContaining({
        origin: 0x10,
        destination: 0x20,
      }));
      expect(client.sendRequest).toHaveBeenCalledWith("link_set_types", expect.objectContaining({
        link_types: [1],
      }));
    });
  });

  it("shows remote form when remote target chosen", () => {
    renderCreator();
    fireEvent.click(screen.getByText("Link to a remote server"));
    expect(screen.getByText("Remote server link")).toBeTruthy();
    expect(screen.getByPlaceholderText(/alice.example.com/)).toBeTruthy();
    expect(screen.getByPlaceholderText("e.g. a1b2c3d4...")).toBeTruthy();
  });

  it("validates tumbler is required for remote link", () => {
    renderCreator();
    fireEvent.click(screen.getByText("Link to a remote server"));
    fireEvent.click(screen.getByText("Create Remote Link"));
    expect(screen.getByText("Tumbler is required")).toBeTruthy();
  });

  it("validates hash length for remote link", () => {
    renderCreator();
    fireEvent.click(screen.getByText("Link to a remote server"));
    const tumblerInput = screen.getByPlaceholderText(/alice.example.com/);
    fireEvent.change(tumblerInput, { target: { value: '"test.com".5.3.10.7' } });
    fireEvent.click(screen.getByText("Create Remote Link"));
    expect(screen.getByText("Content hash must be 64 hex characters (BLAKE3)")).toBeTruthy();
  });

  it("creates remote link with valid tumbler and hash", async () => {
    const client = mkClient();
    renderCreator({ client });

    fireEvent.click(screen.getByText("Link to a remote server"));
    fireEvent.change(screen.getByPlaceholderText(/alice.example.com/), {
      target: { value: '"alice.example.com".5.3.10.7' },
    });
    fireEvent.change(screen.getByPlaceholderText("e.g. a1b2c3d4..."), {
      target: { value: "ab".repeat(32) },
    });
    fireEvent.click(screen.getByText("Create Remote Link"));

    await waitFor(() => {
      expect(client.sendRequest).toHaveBeenCalledWith("link_create", expect.objectContaining({
        origin: 0x10,
      }));
      const call = (client.sendRequest as ReturnType<typeof vi.fn>).mock.calls.find(
        (c: unknown[]) => c[0] === "link_create",
      );
      const payload = call![1] as Record<string, unknown>;
      const dRef = payload.destination_ref as Record<string, unknown>;
      const csr = dRef.cross_server_ref as Record<string, unknown>;
      expect(csr.tumbler).toBe('"alice.example.com".5.3.10.7');
      expect(csr.content_hash).toBe("ab".repeat(32));
    });
  });
});
