import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { ConnectionsSection } from "../components/panels/ConnectionsSection";
import type { LinkEntry, BacklinkEntry } from "../api/crdt_sync";

function mkLink(overrides: Partial<LinkEntry> = {}): LinkEntry {
  return {
    link_id: 100,
    origin: 0x10,
    destination: 0x20,
    origin_ref: { kind: "single", work_context: 0x10, original_context: null, excerpt: "source passage" },
    destination_ref: { kind: "single", work_context: 0x20, original_context: null, excerpt: "target passage" },
    origin_title: "My Essay",
    destination_title: "Reviewer Notes",
    link_types: [1],
    ...overrides,
  };
}

function mkBacklink(overrides: Partial<BacklinkEntry> = {}): BacklinkEntry {
  return {
    source_work_id: 0x30,
    link_id: 200,
    link_type: "hyperlink_incoming",
    excerpt: "incoming excerpt",
    title: "Rebuttal",
    ...overrides,
  };
}

function renderSection(
  overrides: {
    transclusionLinks?: LinkEntry[];
    backlinks?: BacklinkEntry[];
    onDeleteLink?: (id: number) => void;
    onRetypeLink?: (id: number, t: number) => void;
    pinnedKeys?: Set<string>;
    onTogglePin?: (k: string, p: boolean) => void;
  } = {},
) {
  return render(
    <ConnectionsSection
      transclusionLinks={overrides.transclusionLinks ?? []}
      backlinks={overrides.backlinks ?? []}
      compoundSpanRanges={[]}
      compoundSourceTitles={{}}
      currentWorkId={0x10}
      onNavigateToWork={vi.fn()}
      onDeleteLink={overrides.onDeleteLink}
      onRetypeLink={overrides.onRetypeLink}
      pinnedKeys={overrides.pinnedKeys ?? new Set()}
      onTogglePin={overrides.onTogglePin ?? vi.fn()}
    />,
  );
}

describe("ConnectionsSection", () => {
  it("renders nothing when there are no connections", () => {
    const { container } = renderSection();
    expect(container).toBeEmptyDOMElement();
  });

  it("renders link items", () => {
    renderSection({ transclusionLinks: [mkLink()] });
    expect(screen.getByText(/Reviewer Notes/)).toBeTruthy();
    expect(screen.getByText(/source passage/)).toBeTruthy();
  });

  it("renders backlink items", () => {
    renderSection({ backlinks: [mkBacklink()] });
    expect(screen.getByText(/Rebuttal/)).toBeTruthy();
    expect(screen.getByText(/incoming excerpt/)).toBeTruthy();
  });

  it("calls onNavigateToWork when item clicked", () => {
    const onNavigateToWork = vi.fn();
    render(
      <ConnectionsSection
        transclusionLinks={[mkLink()]}
        backlinks={[]}
        compoundSpanRanges={[]}
        compoundSourceTitles={{}}
        currentWorkId={0x10}
        onNavigateToWork={onNavigateToWork}
        pinnedKeys={new Set()}
        onTogglePin={vi.fn()}
      />,
    );
    const item = screen.getByText(/Reviewer Notes/).closest(".conn-item");
    fireEvent.click(item!);
    expect(onNavigateToWork).toHaveBeenCalledWith(0x20);
  });

  it("does not show delete button when onDeleteLink not provided", () => {
    renderSection({ transclusionLinks: [mkLink()] });
    expect(screen.queryByTitle("Delete link")).toBeNull();
  });

  it("shows delete button when onDeleteLink provided", () => {
    renderSection({ transclusionLinks: [mkLink()], onDeleteLink: vi.fn() });
    expect(screen.getByTitle("Delete link")).toBeTruthy();
  });

  it("calls onDeleteLink when delete button clicked", () => {
    const onDeleteLink = vi.fn();
    renderSection({ transclusionLinks: [mkLink()], onDeleteLink });
    fireEvent.click(screen.getByTitle("Delete link"));
    expect(onDeleteLink).toHaveBeenCalledWith(100);
  });

  it("shows retype dropdown when onRetypeLink provided", () => {
    renderSection({
      transclusionLinks: [mkLink({ link_types: [2] })],
      onDeleteLink: vi.fn(),
      onRetypeLink: vi.fn(),
    });
    const dropdown = screen.getByTitle("Change link type") as HTMLSelectElement;
    expect(dropdown).toBeTruthy();
    expect(dropdown.value).toBe("2");
  });

  it("calls onRetypeLink when type changed", () => {
    const onRetypeLink = vi.fn();
    renderSection({
      transclusionLinks: [mkLink({ link_types: [1] })],
      onDeleteLink: vi.fn(),
      onRetypeLink,
    });
    const dropdown = screen.getByTitle("Change link type") as HTMLSelectElement;
    fireEvent.change(dropdown, { target: { value: "3" } });
    expect(onRetypeLink).toHaveBeenCalledWith(100, 3);
  });

  it("does not show retype dropdown for backlinks", () => {
    renderSection({ backlinks: [mkBacklink()], onRetypeLink: vi.fn() });
    expect(screen.queryByTitle("Change link type")).toBeNull();
  });

  it("delete button on backlinks calls onDeleteLink with correct link_id", () => {
    const onDeleteLink = vi.fn();
    renderSection({ backlinks: [mkBacklink({ link_id: 999 })], onDeleteLink });
    fireEvent.click(screen.getByTitle("Delete link"));
    expect(onDeleteLink).toHaveBeenCalledWith(999);
  });

  it("shows correct link type label in meta", () => {
    renderSection({ transclusionLinks: [mkLink({ link_types: [3] })] });
    expect(screen.getByText("Disagreement")).toBeTruthy();
  });

  it("deduplicates links by link_id", () => {
    const link = mkLink();
    renderSection({ transclusionLinks: [link, { ...link }] });
    const items = screen.getAllByText(/Reviewer Notes/);
    expect(items).toHaveLength(1);
  });

  it("calls onTogglePin when star clicked", () => {
    const onTogglePin = vi.fn();
    renderSection({ transclusionLinks: [mkLink()], onTogglePin });
    const star = screen.getByText("\u2606");
    fireEvent.click(star);
    expect(onTogglePin).toHaveBeenCalledWith("link-100", true);
  });

  it("shows pinned star when key is in pinnedKeys", () => {
    renderSection({
      transclusionLinks: [mkLink()],
      pinnedKeys: new Set(["link-100"]),
    });
    expect(screen.getByText("\u2605")).toBeTruthy();
  });
});

// ---- FR-40 S6/S7: end-set and link-attachment rendering ----

describe("ConnectionsSection end-sets (FR-40 S6/S7)", () => {
  it("shows passage counts for gathered ends in the link row meta", () => {
    renderSection({
      transclusionLinks: [
        mkLink({
          link_types: [3],
          end_sets: [
            [
              "LeftEnd",
              [
                { kind: "single", work_context: 0x10, original_context: null, excerpt: "claim one" },
                { kind: "single", work_context: 0x10, original_context: null, excerpt: "claim two" },
                { kind: "single", work_context: 0x11, original_context: null, excerpt: "claim three" },
              ],
            ],
          ],
        }),
      ],
    });
    expect(screen.getByText(/3 passages/)).toBeInTheDocument();
  });

  it("shows connection chips for link attachments (S7)", () => {
    renderSection({
      transclusionLinks: [
        mkLink({
          named_ends: [
            [
              "Commentary",
              {
                kind: "link_attachment",
                work_context: null,
                original_context: null,
                excerpt: null,
                link_attachment: 55,
              },
            ],
          ],
        }),
      ],
    });
    expect(screen.getByText(/→ connection/)).toBeInTheDocument();
  });

  it("pluralizes multiple link attachments on one end", () => {
    renderSection({
      transclusionLinks: [
        mkLink({
          named_ends: [
            [
              "Commentary",
              {
                kind: "link_attachment",
                work_context: null,
                original_context: null,
                excerpt: null,
                link_attachment: 55,
              },
            ],
          ],
          end_sets: [
            [
              "Commentary",
              [
                {
                  kind: "link_attachment",
                  work_context: null,
                  original_context: null,
                  excerpt: null,
                  link_attachment: 55,
                },
                {
                  kind: "link_attachment",
                  work_context: null,
                  original_context: null,
                  excerpt: null,
                  link_attachment: 56,
                },
              ],
            ],
          ],
        }),
      ],
    });
    expect(screen.getByText(/→ 2 connections/)).toBeInTheDocument();
  });

  it("plain two-ended links keep the bare type meta", () => {
    renderSection({ transclusionLinks: [mkLink()] });
    expect(screen.queryByText(/passages/)).toBeNull();
    expect(screen.queryByText(/connection/)).toBeNull();
  });
});
