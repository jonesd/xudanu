import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { OriginPanel } from "../components/OriginPanel";
import type { LinkEntry, HyperRefPayload, TransclusionMarker } from "../api/crdt_sync";

const ORIGIN_TEXT =
  "…the interview turned to structure. Ted kept returning to the idea that the deep structure of literature is tumblered — connections go both ways. What he meant was that removal of a connection is itself a visible act…";

function ref(work: number, excerpt: string): HyperRefPayload {
  return { kind: "text", work_context: work, original_context: work, excerpt, start_position: null, end_position: null };
}

/** The same link has a third end (n-way) in another document. */
const LINK: LinkEntry = {
  link_id: 0x42,
  origin: 0x10,
  destination: 0x20,
  origin_ref: ref(0x10, "the deep structure of literature is tumblered"),
  destination_ref: ref(0x20, "the deep structure of literature is tumblered"),
  link_types: [4],
  named_ends: [["critique", ref(0x30, "the deep structure of literature is tumblered")]],
  origin_title: "Notes on hypertext",
  destination_title: "Gold interview prep",
};

const MARKER: TransclusionMarker = {
  start: 5,
  end: 55,
  linkId: 0x42,
  direction: "incoming",
  otherWorkId: 0x20,
  otherWorkTitle: "Gold interview prep",
  color: "#a371f7",
  excerpt: "the deep structure of literature is tumblered",
  provenanceChain: [
    { source_work_id: 0x20, link_id: 0x42, source_work_title: "Gold interview prep", source_author_name: "Roger Gregory" },
    { source_work_id: 0x50, link_id: 0x41, source_work_title: "Original field notes", source_author_name: "Ted Nelson" },
  ],
};

function mkClient(text: string) {
  return {
    sendRequest: vi.fn((op: string) => {
      if (op === "work_get_edition") return Promise.resolve({ value: { Text: text } });
      return Promise.resolve({});
    }),
  };
}

describe("OriginPanel", () => {
  it("shows origin title, author, and the highlighted span in context", async () => {
    render(
      <OriginPanel client={mkClient(ORIGIN_TEXT)} marker={MARKER} links={[LINK]} onClose={() => {}} onOpenFull={() => {}} />,
    );
    expect(await screen.findByText("Gold interview prep")).toBeTruthy();
    expect(screen.getByText(/by Roger Gregory/)).toBeTruthy();
    const mark = await screen.findByText("the deep structure of literature is tumblered", { selector: "mark" });
    expect(mark.className).toContain("ws-origin-mark");
    // Surrounding context is rendered (window covers the whole short text)
    expect(screen.getByText(/Ted kept returning/)).toBeTruthy();
  });

  it("lists the n-way link's other ends", async () => {
    render(
      <OriginPanel client={mkClient(ORIGIN_TEXT)} marker={MARKER} links={[LINK]} onClose={() => {}} onOpenFull={() => {}} />,
    );
    expect(await screen.findByText(/2 other ends/)).toBeTruthy();
  });

  it("shows the provenance chain hops", async () => {
    render(
      <OriginPanel client={mkClient(ORIGIN_TEXT)} marker={MARKER} links={[LINK]} onClose={() => {}} onOpenFull={() => {}} />,
    );
    expect(await screen.findByText(/2\. Original field notes — Ted Nelson/)).toBeTruthy();
  });

  it("degrades gracefully when the span is not found in the origin", async () => {
    const client = mkClient("totally different text with no overlap");
    render(<OriginPanel client={client} marker={MARKER} links={[LINK]} onClose={() => {}} onOpenFull={() => {}} />);
    expect(await screen.findByText(/could not be located/)).toBeTruthy();
  });

  it("opens the full document via callback", async () => {
    const open = vi.fn();
    render(
      <OriginPanel client={mkClient(ORIGIN_TEXT)} marker={MARKER} links={[LINK]} onClose={() => {}} onOpenFull={open} />,
    );
    const btn = await screen.findByText("Open full document");
    fireEvent.click(btn);
    expect(open).toHaveBeenCalledWith(0x20);
  });
});
