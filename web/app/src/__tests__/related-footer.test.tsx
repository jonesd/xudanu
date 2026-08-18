import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { RelatedFooter } from "../components/RelatedFooter";
import type {
  LinkEntry,
  BacklinkEntry,
  SpanRangePayload,
  CrossServerBacklinkPayload,
} from "../api/crdt_sync";

const CURRENT_WORK = 0x10;

function mkBacklink(overrides: Partial<BacklinkEntry> = {}): BacklinkEntry {
  return {
    source_work_id: 0x30,
    link_id: 200,
    link_type: "Reference",
    excerpt: "As discussed in the original source",
    title: "Rebuttal Essay",
    ...overrides,
  };
}

function mkLink(overrides: Partial<LinkEntry> = {}): LinkEntry {
  return {
    link_id: 100,
    origin: CURRENT_WORK,
    destination: 0x20,
    origin_ref: { kind: "single", work_context: CURRENT_WORK, original_context: null, excerpt: "my passage" },
    destination_ref: { kind: "single", work_context: 0x20, original_context: null, excerpt: "their passage" },
    origin_title: "My Essay",
    destination_title: "Referenced Work",
    link_types: [2],
    ...overrides,
  };
}

function mkSpanRange(overrides: Partial<SpanRangePayload> = {}): SpanRangePayload {
  return {
    source_work_id: 0x40,
    char_start: 0,
    char_end: 50,
    flat_start: 0,
    flat_end: 50,
    content_len: 50,
    resolved_content: "This is transcluded content from another document.",
    ...overrides,
  };
}

function mkCrossServerBacklink(overrides: Partial<CrossServerBacklinkPayload> = {}): CrossServerBacklinkPayload {
  return {
    target_work_id: CURRENT_WORK,
    origin_server_address: "remote.example.com",
    origin_server_name: "Remote Server",
    origin_work_id: "abc123",
    origin_work_title: "Remote Analysis",
    excerpt: "Content from a remote server referencing this work",
    link_type: "quotation",
    received_at: Date.now(),
    ...overrides,
  };
}

function renderFooter(overrides: {
  backlinks?: BacklinkEntry[];
  outgoingLinks?: LinkEntry[];
  compoundSpanRanges?: SpanRangePayload[];
  compoundSourceTitles?: Record<number, string>;
  crossServerBacklinks?: CrossServerBacklinkPayload[];
} = {}) {
  const onNavigate = vi.fn();
  const result = render(
    <RelatedFooter
      annotations={[]}
      backlinks={overrides.backlinks ?? []}
      outgoingLinks={overrides.outgoingLinks ?? []}
      compoundSpanRanges={overrides.compoundSpanRanges ?? []}
      compoundSourceTitles={overrides.compoundSourceTitles ?? {}}
      crossServerBacklinks={overrides.crossServerBacklinks ?? []}
      currentWorkId={CURRENT_WORK}
      onNavigateToWork={onNavigate}
    />,
  );
  return { ...result, onNavigate };
}

describe("RelatedFooter", () => {
  it("renders nothing when there are no connections", () => {
    const { container } = renderFooter();
    expect(container.firstChild).toBeNull();
  });

  it("renders backlinks with reason and title", () => {
    renderFooter({ backlinks: [mkBacklink()] });
    expect(screen.getByText("Rebuttal Essay")).toBeTruthy();
    expect(screen.getByText(/Referenced/)).toBeTruthy();
    expect(screen.getByText(/As discussed/)).toBeTruthy();
  });

  it("renders outgoing links with link type label", () => {
    renderFooter({ outgoingLinks: [mkLink()] });
    expect(screen.getByText("Referenced Work")).toBeTruthy();
    expect(screen.getByText("Reference")).toBeTruthy();
  });

  it("renders transclusion sources with includes-content reason", () => {
    renderFooter({
      compoundSpanRanges: [mkSpanRange()],
      compoundSourceTitles: { 0x40: "Source Document" },
    });
    expect(screen.getByText("Source Document")).toBeTruthy();
    expect(screen.getByText("Includes content from")).toBeTruthy();
  });

  it("renders cross-server backlinks", () => {
    renderFooter({ crossServerBacklinks: [mkCrossServerBacklink()] });
    expect(screen.getByText("Remote Analysis")).toBeTruthy();
    expect(screen.getByText(/Cross-server/)).toBeTruthy();
  });

  it("navigates to work on click for local items", () => {
    const { onNavigate } = renderFooter({ backlinks: [mkBacklink()] });
    fireEvent.click(screen.getByText("Rebuttal Essay"));
    expect(onNavigate).toHaveBeenCalledWith(0x30);
  });

  it("deduplicates items from the same work", () => {
    const backlinks = [
      mkBacklink({ link_id: 201, excerpt: "first reference" }),
      mkBacklink({ link_id: 202, excerpt: "second reference" }),
    ];
    renderFooter({ backlinks });
    const cards = screen.getAllByRole("button").filter((b) => b.className.includes("related-card"));
    expect(cards).toHaveLength(1);
  });

  it("limits rendered cards (single-row strip scrolls for overflow)", () => {
    const backlinks = Array.from({ length: 16 }, (_, i) =>
      mkBacklink({
        link_id: 300 + i,
        source_work_id: 0x50 + i,
        title: `Work ${i}`,
      }),
    );
    renderFooter({ backlinks });
    const cards = screen.getAllByRole("button").filter((b) => b.className.includes("related-card"));
    expect(cards).toHaveLength(12);
  });

  it("shows count badge with total connections", () => {
    renderFooter({ backlinks: [mkBacklink(), mkBacklink({ source_work_id: 0x99, link_id: 333 })] });
    expect(screen.getByText("2")).toBeTruthy();
  });

  it("can be collapsed and expanded", () => {
    renderFooter({ backlinks: [mkBacklink()] });
    const toggle = screen.getByRole("button", { name: /Related/ });
    fireEvent.click(toggle);
    expect(screen.queryByText("Rebuttal Essay")).toBeNull();
    fireEvent.click(toggle);
    expect(screen.getByText("Rebuttal Essay")).toBeTruthy();
  });
});

describe("RelatedFooter notes section", () => {
  const mkNote = (id: number, over: Partial<Record<string, unknown>> = {}) => ({
    annotation_id: id,
    kind: "note",
    payload: `note ${id}`,
    char_start: 3,
    char_end: 9,
    created_by: 1,
    created_by_name: "Ann",
    created_at: 1000,
    is_private: false,
    ...over,
  });

  function renderFooter(annotations: Record<string, unknown>[]) {
    return render(
      <RelatedFooter
        annotations={annotations as never}
        onJumpToSpan={vi.fn()}
        backlinks={[]}
        outgoingLinks={[]}
        compoundSpanRanges={[]}
        compoundSourceTitles={{}}
        crossServerBacklinks={[]}
        currentWorkId={7}
        onNavigateToWork={vi.fn()}
      />,
    );
  }

  it("renders notes with count and public/private badges", () => {
    renderFooter([mkNote(1), mkNote(2, { is_private: true })]);
    expect(screen.getByText(/Notes/)).toBeTruthy();
    expect(screen.getByText(/public/)).toBeTruthy();
    expect(screen.getByText(/private/)).toBeTruthy();
  });

  it("shows the footer when only notes exist (no related)", () => {
    const r = renderFooter([mkNote(1)]);
    expect(r.container.querySelector(".related-note-row")).toBeTruthy();
    expect(screen.queryByText(/^Related$/)).toBeNull();
  });

  it("renders nothing when no notes and no related", () => {
    const r = renderFooter([]);
    expect(r.container.querySelector(".related-footer-panel")).toBeNull();
  });

  it("filters empty and non-note annotations out", () => {
    const r = renderFooter([
      mkNote(1),
      { ...mkNote(2), payload: "   " },
      { ...mkNote(3), kind: "bold" },
    ]);
    expect(r.container.querySelectorAll(".related-note-row").length).toBe(1);
  });
});
