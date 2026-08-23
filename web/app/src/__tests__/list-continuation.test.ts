import { describe, it, expect } from "vitest";

// FR: list continuation semantics — pure functions matching the
// Enter-branch logic in CollaborativeEditor (mirrored here as a
// contract test; the component applies these via DOM ranges).

export function enterInsertText(before: string): string {
  const lineStartIdx = before.lastIndexOf("\n") + 1;
  const lineText = before.slice(lineStartIdx);
  const markerMatch = lineText.match(/^(?:[-*+] |\d+\. )/);
  if (markerMatch) {
    const marker = markerMatch[0];
    if (lineText.trim() === marker.trim()) {
      return "__EXIT_LIST__";
    }
    return "\n" + marker + "\u200B";
  }
  return "\n\u200B";
}

describe("Enter list continuation", () => {
  it("continues a bullet list", () => {
    expect(enterInsertText("- one")).toBe("\n- \u200B");
  });
  it("continues with the same marker style", () => {
    expect(enterInsertText("* one")).toBe("\n* \u200B");
    expect(enterInsertText("+ one")).toBe("\n+ \u200B");
  });
  it("continues ordered lists with the same number format", () => {
    expect(enterInsertText("1. one")).toBe("\n1. \u200B");
  });
  it("continues mid-list after typed text", () => {
    expect(enterInsertText("text before\n- one and some more text")).toBe("\n- \u200B");
  });
  it("exits the list on an empty item", () => {
    expect(enterInsertText("- ")).toBe("__EXIT_LIST__");
  });
  it("bare dash without space is prose, not a list", () => {
    expect(enterInsertText("-")).toBe("\n\u200B");
  });
  it("plain newline when not in a list", () => {
    expect(enterInsertText("just text")).toBe("\n\u200B");
    expect(enterInsertText("head\nno markers here")).toBe("\n\u200B");
  });
  it("does not treat indented prose as a list", () => {
    // "-one" (no space) is not a list marker
    expect(enterInsertText("-one tight")).toBe("\n\u200B");
  });
});
