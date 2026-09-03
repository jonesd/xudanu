import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { StudioSidebar } from "../components/StudioSidebar";
import type { WorkListEntry } from "../api/crdt_sync";

function mkWorks(): WorkListEntry[] {
  const now = Math.floor(Date.now() / 1000);
  return [
    { work_id: 0x10, owner: 7, revision_count: 3, is_grabbed: false, title: "Notes on hypertext", read_club: null, updated_at: now - 120, is_starred: true },
    { work_id: 0x20, owner: 9, revision_count: 1, is_grabbed: false, title: "Gold interview prep", read_club: null, updated_at: now - 90000 },
    { work_id: 0x30, owner: 7, revision_count: 1, is_grabbed: false, title: "", read_club: null, updated_at: now - 10 },
  ];
}

describe("StudioSidebar", () => {
  it("lists works with human titles, untitled fallback, and recency", () => {
    render(
      <StudioSidebar works={mkWorks()} worksLoading={false} activeWorkId={0x10} currentClubId={7}
        onSelectWork={() => {}} onNewDocument={() => {}} />,
    );
    expect(screen.getByText("Notes on hypertext")).toBeTruthy();
    expect(screen.getByText("Gold interview prep")).toBeTruthy();
    expect(screen.getByText("Untitled")).toBeTruthy();
    expect(screen.getByText(/2m ago/)).toBeTruthy();
    expect(screen.getByText(/1d ago/)).toBeTruthy();
  });

  it("marks the active document", () => {
    const { container } = render(
      <StudioSidebar works={mkWorks()} worksLoading={false} activeWorkId={0x10} currentClubId={7}
        onSelectWork={() => {}} onNewDocument={() => {}} />,
    );
    const active = container.querySelector(".ws-studio-doc.active");
    expect(active?.textContent).toContain("Notes on hypertext");
  });

  it("selects a work on click", () => {
    const select = vi.fn();
    render(
      <StudioSidebar works={mkWorks()} worksLoading={false} activeWorkId={null} currentClubId={null}
        onSelectWork={select} onNewDocument={() => {}} />,
    );
    fireEvent.click(screen.getByText("Gold interview prep"));
    expect(select).toHaveBeenCalledWith(0x20);
  });

  it("filters: Mine (by owner club) and Starred", () => {
    render(
      <StudioSidebar works={mkWorks()} worksLoading={false} activeWorkId={null} currentClubId={7}
        onSelectWork={() => {}} onNewDocument={() => {}} />,
    );
    fireEvent.click(screen.getByRole("tab", { name: /mine/i }));
    expect(screen.queryByText("Gold interview prep")).toBeNull();
    expect(screen.getByText("Notes on hypertext")).toBeTruthy();
    fireEvent.click(screen.getByRole("tab", { name: /starred/i }));
    expect(screen.queryByText("Gold interview prep")).toBeNull();
    expect(screen.getByText("Notes on hypertext")).toBeTruthy();
    fireEvent.click(screen.getByRole("tab", { name: /all/i }));
    expect(screen.getByText("Gold interview prep")).toBeTruthy();
  });

  it("shows count and new-document action", () => {
    const newDoc = vi.fn();
    render(
      <StudioSidebar works={mkWorks()} worksLoading={false} activeWorkId={null} currentClubId={null}
        onSelectWork={() => {}} onNewDocument={newDoc} />,
    );
    expect(screen.getByText("3")).toBeTruthy();
    fireEvent.click(screen.getByTitle("New document (N)"));
    expect(newDoc).toHaveBeenCalled();
  });

  it("empty and loading states", () => {
    const { rerender } = render(
      <StudioSidebar works={[]} worksLoading={true} activeWorkId={null} currentClubId={null}
        onSelectWork={() => {}} onNewDocument={() => {}} />,
    );
    expect(screen.getByText("Loading…")).toBeTruthy();
    rerender(
      <StudioSidebar works={[]} worksLoading={false} activeWorkId={null} currentClubId={null}
        onSelectWork={() => {}} onNewDocument={() => {}} />,
    );
    expect(screen.getByText(/No documents yet/)).toBeTruthy();
  });
});
