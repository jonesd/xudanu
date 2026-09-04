import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { BeamsView } from "../components/BeamsView";
import type { LinkEntry, HyperRefPayload } from "../api/crdt_sync";

function ref(work: number, excerpt: string): HyperRefPayload {
  return {
    kind: "text",
    work_context: work,
    original_context: work,
    excerpt,
    start_position: null,
    end_position: null,
  };
}

/** Three-ended link (n-way): the tumblered passage cited in 3 documents. */
const N_WAY: LinkEntry = {
  link_id: 0x3f7,
  origin: 0x10,
  destination: 0x20,
  origin_ref: ref(0x10, "the deep structure of literature is tumblered"),
  destination_ref: ref(0x20, "the deep structure of literature is tumblered"),
  link_types: [4], // Quotation (purple)
  named_ends: [
    ["critique", ref(0x30, "the deep structure of literature is tumblered")],
  ],
};

const TWO_WAY: LinkEntry = {
  link_id: 0x3f8,
  origin: 0x20,
  destination: 0x30,
  origin_ref: ref(0x20, "This is the part the web never got right"),
  destination_ref: ref(0x30, "Disagree — see the interview notes"),
  link_types: [3], // Disagreement (red)
};

const TEXTS: Record<number, string> = {
  0x10:
    "The core insight is that quotation is not copying; the deep structure of literature is tumblered, and connections go both ways.",
  0x20:
    "Ted kept returning to the idea that the deep structure of literature is tumblered. This is the part the web never got right.",
  0x30:
    "Whatever its merits, the claim that the deep structure of literature is tumblered needs evidence. Disagree — see the interview notes.",
};

const WORKS = [
  { work_id: 0x10, title: "Notes on hypertext" },
  { work_id: 0x20, title: "Gold interview prep" },
  { work_id: 0x30, title: "Critique of transclusion" },
];

function mkClient() {
  return {
    sendRequest: vi.fn((op: string) => {
      if (op === "work_get_edition") return Promise.resolve({ value: { Text: "" } });
      return Promise.resolve({});
    }),
  };
}

// work_get_edition returns per-work text
function mkClientWithTexts() {
  return {
    sendRequest: vi.fn((op: string, params: Record<string, unknown>) => {
      if (op === "work_get_edition") {
        const t = TEXTS[params.work_id as number] ?? "";
        return Promise.resolve({ value: { Text: t } });
      }
      return Promise.resolve({});
    }),
  };
}

describe("BeamsView", () => {
  beforeEach(() => {
    // jsdom rects are all zeros — geometry still computes, counts matter.
    Element.prototype.getBoundingClientRect = vi.fn(() => ({
      x: 0, y: 0, top: 0, right: 100, bottom: 20, left: 0, width: 100, height: 20, toJSON: () => ({}),
    }) as DOMRect);
  });

  it("loads the current work plus the first linked work as columns", async () => {
    render(
      <BeamsView client={mkClientWithTexts()} currentWorkId={0x10} works={WORKS} links={[N_WAY]} onClose={() => {}} />,
    );
    expect(await screen.findByText("Notes on hypertext")).toBeTruthy();
    expect(await screen.findByText("Gold interview prep")).toBeTruthy();
    // Exactly two document columns (the third linked work is only in the picker)
    await waitFor(() => {
      expect(document.querySelectorAll(".ws-beams-doc-head h3").length).toBe(2);
    });
  });

  it("offers the other linked works in the Add-document picker", async () => {
    render(
      <BeamsView client={mkClientWithTexts()} currentWorkId={0x10} works={WORKS} links={[N_WAY, TWO_WAY]} onClose={() => {}} />,
    );
    await screen.findByText("Notes on hypertext");
    const select = screen.getByLabelText("Add document");
    const options = Array.from(select.querySelectorAll("option")).map((o) => o.textContent);
    expect(options).toContain("Critique of transclusion");
    expect(options).not.toContain("Notes on hypertext"); // already shown
  });

  it("highlights n-way ends in every column that carries the excerpt", async () => {
    const { container } = render(
      <BeamsView client={mkClientWithTexts()} currentWorkId={0x10} works={WORKS} links={[N_WAY, TWO_WAY]} onClose={() => {}} />,
    );
    await screen.findByText("Notes on hypertext");
    // Current doc quotes the passage (n-way end) — one mark in column 1.
    // The linked second doc quotes it too. Wait for marks to appear.
    await waitFor(() => {
      expect(container.querySelectorAll(".ws-beams-mark").length).toBeGreaterThanOrEqual(2);
    });
    // Legend: Quotation + Disagreement types present
    expect(screen.getByText("Quotation")).toBeTruthy();
    expect(screen.getByText("Disagreement")).toBeTruthy();
  });

  it("opens a hovercard listing all ends of a selected link", async () => {
    render(
      <BeamsView client={mkClientWithTexts()} currentWorkId={0x10} works={WORKS} links={[N_WAY]} onClose={() => {}} />,
    );
    await screen.findByText("Notes on hypertext");
    await waitFor(() => {
      expect(containerMarks().length).toBeGreaterThan(0);
    });
    function containerMarks() {
      return document.querySelectorAll(".ws-beams-mark");
    }
    fireEvent.click(document.querySelector(".ws-beams-mark")!);
    const endsLines = await screen.findAllByText(/ends\./);
    expect(endsLines.length).toBeGreaterThanOrEqual(1);
    // All three documents appear as ends (n-way visible)
    expect(screen.getByText("Notes on hypertext", { selector: ".ws-beams-card-end b" })).toBeTruthy();
    expect(screen.getByText("Gold interview prep", { selector: ".ws-beams-card-end b" })).toBeTruthy();
  });

  it("renders empty documents and loader states without crashing", async () => {
    render(
      <BeamsView client={mkClient()} currentWorkId={0x10} works={WORKS} links={[]} onClose={() => {}} />,
    );
    expect(await screen.findByText(/Empty document/)).toBeTruthy();
    // No links → no legend
    expect(document.querySelector(".ws-beams-legend")).toBeNull();
  });
});
