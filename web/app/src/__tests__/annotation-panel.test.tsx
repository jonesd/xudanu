import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { AnnotationPanel } from "../components/AnnotationPanel";
import type { AnnotationEntry } from "../api/crdt_sync";

function mkAnnotation(overrides: Partial<AnnotationEntry> = {}): AnnotationEntry {
  return {
    annotation_id: 1,
    kind: "note",
    payload: "This needs a citation",
    char_start: 10,
    char_end: 25,
    created_by: 100,
    created_by_name: "Alice",
    created_at: 1700000000,
    is_private: false,
    ...overrides,
  };
}

describe("AnnotationPanel", () => {
  it("shows empty hint when no annotations", () => {
    render(<AnnotationPanel annotations={[]} onDelete={vi.fn()} onNavigate={vi.fn()} currentClubId={null} />);
    expect(screen.getByText(/Select text and press Ctrl\+Alt\+A/)).toBeTruthy();
  });

  it("shows annotation count in header", () => {
    render(
      <AnnotationPanel
        annotations={[mkAnnotation(), mkAnnotation({ annotation_id: 2 })]}
        onDelete={vi.fn()}
        onNavigate={vi.fn()}
        currentClubId={null}
      />,
    );
    expect(screen.getByText("Annotations (2)")).toBeTruthy();
  });

  it("shows annotation payload text", () => {
    render(<AnnotationPanel annotations={[mkAnnotation()]} onDelete={vi.fn()} onNavigate={vi.fn()} currentClubId={null} />);
    expect(screen.getByText("This needs a citation")).toBeTruthy();
  });

  it("shows kind label", () => {
    render(<AnnotationPanel annotations={[mkAnnotation({ kind: "question" })]} onDelete={vi.fn()} onNavigate={vi.fn()} currentClubId={null} />);
    expect(screen.getByText("question")).toBeTruthy();
  });

  it("defaults kind to 'note' when empty", () => {
    render(<AnnotationPanel annotations={[mkAnnotation({ kind: "" })]} onDelete={vi.fn()} onNavigate={vi.fn()} currentClubId={null} />);
    expect(screen.getByText("note")).toBeTruthy();
  });

  it("shows author name", () => {
    render(<AnnotationPanel annotations={[mkAnnotation()]} onDelete={vi.fn()} onNavigate={vi.fn()} currentClubId={null} />);
    expect(screen.getByText("Alice")).toBeTruthy();
  });

  it("shows char range", () => {
    render(<AnnotationPanel annotations={[mkAnnotation()]} onDelete={vi.fn()} onNavigate={vi.fn()} currentClubId={null} />);
    expect(screen.getByText(/10.*25/,)).toBeTruthy();
  });

  it("shows private lock when is_private", () => {
    render(<AnnotationPanel annotations={[mkAnnotation({ is_private: true })]} onDelete={vi.fn()} onNavigate={vi.fn()} currentClubId={null} />);
    expect(screen.getByTitle("Private — only visible to you")).toBeTruthy();
  });

  it("calls onDelete when delete button clicked", () => {
    const onDelete = vi.fn();
    render(<AnnotationPanel annotations={[mkAnnotation({ annotation_id: 42 })]} onDelete={onDelete} onNavigate={vi.fn()} currentClubId={null} />);
    fireEvent.click(screen.getByTitle("Delete annotation"));
    expect(onDelete).toHaveBeenCalledWith(42);
  });

  it("calls onNavigate when annotation header clicked", () => {
    const onNavigate = vi.fn();
    render(<AnnotationPanel annotations={[mkAnnotation({ char_start: 77 })]} onDelete={vi.fn()} onNavigate={onNavigate} currentClubId={null} />);
    fireEvent.click(screen.getByText("note"));
    expect(onNavigate).toHaveBeenCalledWith(77);
  });

  it("collapses and expands", () => {
    const { container } = render(
      <AnnotationPanel annotations={[mkAnnotation()]} onDelete={vi.fn()} onNavigate={vi.fn()} currentClubId={null} />,
    );
    const toggle = screen.getByText("Annotations (1)");
    fireEvent.click(toggle);
    expect(container.textContent).not.toContain("This needs a citation");
    fireEvent.click(toggle);
    expect(container.textContent).toContain("This needs a citation");
  });

  it("falls back to hex club id when no name", () => {
    render(
      <AnnotationPanel
        annotations={[mkAnnotation({ created_by_name: undefined, created_by: 256 })]}
        onDelete={vi.fn()}
        onNavigate={vi.fn()}
        currentClubId={null}
      />,
    );
    expect(screen.getByText("0x100")).toBeTruthy();
  });

  it("shows anonymous when no author info", () => {
    render(
      <AnnotationPanel
        annotations={[mkAnnotation({ created_by_name: undefined, created_by: null } as unknown as AnnotationEntry)]}
        onDelete={vi.fn()}
        onNavigate={vi.fn()}
        currentClubId={null}
      />,
    );
    expect(screen.getByText("anonymous")).toBeTruthy();
  });
});
