import { render, screen, fireEvent } from "@testing-library/react";
import { describe, it, expect, vi } from "vitest";
import { SearchPanel } from "../components/SearchPanel";
import { TextBuffer } from "../api/text_buffer";

const DOC = `# Title

The quick brown fox jumps over the lazy dog.
A second sentence about the fox and the dog.

## Section

One more fox mention.`;

function setup(over: Partial<Parameters<typeof SearchPanel>[0]> = {}) {
  const buffer = new TextBuffer(DOC);
  const onJumpToMatch = vi.fn();
  const onClose = vi.fn();
  render(
    <SearchPanel buffer={buffer} onJumpToMatch={onJumpToMatch} onClose={onClose} {...over} />,
  );
  return { onJumpToMatch, onClose };
}

describe("SearchPanel", () => {
  it("focuses the input on mount", () => {
    setup();
    expect(screen.getByPlaceholderText("Search document...")).toHaveFocus();
  });

  it("shows 0/0 and disables navigation when there are no matches", () => {
    setup();
    fireEvent.change(screen.getByPlaceholderText("Search document..."), {
      target: { value: "zebra" },
    });
    expect(screen.getByText("0/0")).toBeInTheDocument();
    expect(screen.getByText("↑")).toBeDisabled();
    expect(screen.getByText("↓")).toBeDisabled();
  });

  it("counts matches and jumps to the first as the query lands", () => {
    const { onJumpToMatch } = setup();
    fireEvent.change(screen.getByPlaceholderText("Search document..."), {
      target: { value: "fox" },
    });
    // fox appears three times
    expect(screen.getByText("1/3")).toBeInTheDocument();
    const first = DOC.indexOf("fox");
    expect(onJumpToMatch).toHaveBeenCalledWith(first);
  });

  it("next and previous cycle through matches", () => {
    const { onJumpToMatch } = setup();
    const input = screen.getByPlaceholderText("Search document...");
    fireEvent.change(input, { target: { value: "fox" } });
    onJumpToMatch.mockClear();

    fireEvent.click(screen.getByText("↓"));
    const second = DOC.indexOf("fox", DOC.indexOf("fox") + 1);
    expect(onJumpToMatch).toHaveBeenCalledWith(second);
    expect(screen.getByText("2/3")).toBeInTheDocument();

    fireEvent.click(screen.getByText("↑"));
    expect(screen.getByText("1/3")).toBeInTheDocument();

    // prev wraps from the first to the last
    fireEvent.click(screen.getByText("↑"));
    const last = DOC.lastIndexOf("fox");
    expect(onJumpToMatch).toHaveBeenCalledWith(last);
    expect(screen.getByText("3/3")).toBeInTheDocument();
  });

  it("Enter advances and Shift+Enter goes back", () => {
    const { onJumpToMatch } = setup();
    const input = screen.getByPlaceholderText("Search document...");
    fireEvent.change(input, { target: { value: "sentence" } });
    onJumpToMatch.mockClear();

    fireEvent.keyDown(document, { key: "Enter" });
    expect(onJumpToMatch).toHaveBeenCalledWith(DOC.lastIndexOf("sentence"));
    fireEvent.keyDown(document, { key: "Enter", shiftKey: true });
    expect(onJumpToMatch).toHaveBeenCalledWith(DOC.indexOf("sentence"));
  });

  it("Ctrl/Cmd+G cycles matches", () => {
    const { onJumpToMatch } = setup();
    fireEvent.change(screen.getByPlaceholderText("Search document..."), {
      target: { value: "dog" },
    });
    onJumpToMatch.mockClear();
    fireEvent.keyDown(document, { key: "g", ctrlKey: true });
    expect(onJumpToMatch).toHaveBeenCalledWith(DOC.indexOf("dog", DOC.indexOf("dog") + 1));
  });

  it("the Aa toggle switches case sensitivity", () => {
    setup();
    const input = screen.getByPlaceholderText("Search document...");
    // "brown" appears lowercase; "Brown" matches only when insensitive
    fireEvent.change(input, { target: { value: "Brown" } });
    expect(screen.getByText("1/1")).toBeInTheDocument();

    fireEvent.click(screen.getByTitle("Case sensitive"));
    expect(screen.getByText("0/0")).toBeInTheDocument();
  });

  it("Escape and the close button close the panel", () => {
    const { onClose } = setup();
    fireEvent.keyDown(document, { key: "Escape" });
    expect(onClose).toHaveBeenCalledTimes(1);
    fireEvent.click(screen.getByText("×"));
    expect(onClose).toHaveBeenCalledTimes(2);
  });
});
