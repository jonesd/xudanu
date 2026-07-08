import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { AnnotationDialog } from "../components/AnnotationDialog";

describe("AnnotationDialog", () => {
  it("renders nothing when not open", () => {
    const { container } = render(
      <AnnotationDialog open={false} charStart={0} charEnd={0} onCreate={vi.fn()} onClose={vi.fn()} />,
    );
    expect(container).toBeEmptyDOMElement();
  });

  it("shows char range in header when open", () => {
    render(<AnnotationDialog open={true} charStart={10} charEnd={25} onCreate={vi.fn()} onClose={vi.fn()} />);
    expect(screen.getByText(/10.*25/)).toBeTruthy();
  });

  it("has a textarea for the annotation text", () => {
    render(<AnnotationDialog open={true} charStart={0} charEnd={5} onCreate={vi.fn()} onClose={vi.fn()} />);
    expect(screen.getByPlaceholderText("Write your annotation...")).toBeTruthy();
  });

  it("has a private checkbox unchecked by default", () => {
    render(<AnnotationDialog open={true} charStart={0} charEnd={5} onCreate={vi.fn()} onClose={vi.fn()} />);
    const checkbox = screen.getByRole("checkbox") as HTMLInputElement;
    expect(checkbox.checked).toBe(false);
  });

  it("disables create button when text is empty", () => {
    render(<AnnotationDialog open={true} charStart={0} charEnd={5} onCreate={vi.fn()} onClose={vi.fn()} />);
    const btn = screen.getByText("Annotate") as HTMLButtonElement;
    expect(btn.disabled).toBe(true);
  });

  it("enables create button when text entered", () => {
    render(<AnnotationDialog open={true} charStart={0} charEnd={5} onCreate={vi.fn()} onClose={vi.fn()} />);
    fireEvent.change(screen.getByPlaceholderText("Write your annotation..."), {
      target: { value: "A note" },
    });
    const btn = screen.getByText("Annotate") as HTMLButtonElement;
    expect(btn.disabled).toBe(false);
  });

  it("calls onCreate with text and isPrivate=false by default", () => {
    const onCreate = vi.fn();
    const onClose = vi.fn();
    render(<AnnotationDialog open={true} charStart={10} charEnd={20} onCreate={onCreate} onClose={onClose} />);
    fireEvent.change(screen.getByPlaceholderText("Write your annotation..."), {
      target: { value: "My annotation" },
    });
    fireEvent.click(screen.getByText("Annotate"));
    expect(onCreate).toHaveBeenCalledWith("My annotation", false);
  });

  it("calls onCreate with isPrivate=true when checkbox checked", () => {
    const onCreate = vi.fn();
    const onClose = vi.fn();
    render(<AnnotationDialog open={true} charStart={0} charEnd={5} onCreate={onCreate} onClose={onClose} />);
    fireEvent.change(screen.getByPlaceholderText("Write your annotation..."), {
      target: { value: "Secret note" },
    });
    fireEvent.click(screen.getByRole("checkbox"));
    fireEvent.click(screen.getByText("Annotate"));
    expect(onCreate).toHaveBeenCalledWith("Secret note", true);
  });

  it("calls onClose when close button clicked", () => {
    const onClose = vi.fn();
    render(<AnnotationDialog open={true} charStart={0} charEnd={5} onCreate={vi.fn()} onClose={onClose} />);
    fireEvent.click(screen.getByText("\u00d7"));
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it("calls onClose when overlay clicked", () => {
    const onClose = vi.fn();
    const { container } = render(
      <AnnotationDialog open={true} charStart={0} charEnd={5} onCreate={vi.fn()} onClose={onClose} />,
    );
    fireEvent.click(container.querySelector(".modal-overlay")!);
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it("supports Ctrl+Enter to submit", () => {
    const onCreate = vi.fn();
    const onClose = vi.fn();
    render(<AnnotationDialog open={true} charStart={0} charEnd={5} onCreate={onCreate} onClose={onClose} />);
    const textarea = screen.getByPlaceholderText("Write your annotation...");
    fireEvent.change(textarea, { target: { value: "Quick note" } });
    fireEvent.keyDown(textarea, { key: "Enter", metaKey: true });
    expect(onCreate).toHaveBeenCalledWith("Quick note", false);
  });

  it("supports Escape to close", () => {
    const onClose = vi.fn();
    render(<AnnotationDialog open={true} charStart={0} charEnd={5} onCreate={vi.fn()} onClose={onClose} />);
    const textarea = screen.getByPlaceholderText("Write your annotation...");
    fireEvent.keyDown(textarea, { key: "Escape" });
    expect(onClose).toHaveBeenCalledTimes(1);
  });
});
