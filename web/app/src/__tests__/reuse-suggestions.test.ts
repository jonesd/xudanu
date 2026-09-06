import { describe, expect, it } from "vitest";
import { filterDismissed, paragraphPrefixAt, shouldQuery } from "../reuse-suggestions";

describe("paragraphPrefixAt", () => {
  it("returns the paragraph text up to the caret", () => {
    const text = "First paragraph here.\n\nSecond one being typed";
    const caret = text.indexOf("being") + "being".length;
    expect(paragraphPrefixAt(text, caret)).toBe("Second one being");
  });

  it("clamps out-of-range carets", () => {
    expect(paragraphPrefixAt("hello world", 999)).toBe("hello world");
    expect(paragraphPrefixAt("hello", -3)).toBe("");
  });

  it("handles carets at the very start", () => {
    expect(paragraphPrefixAt("abc\ndef", 0)).toBe("");
  });
});

describe("shouldQuery", () => {
  it("requires six words", () => {
    expect(shouldQuery("one two three four five")).toBe(false);
    expect(shouldQuery("one two three four five six")).toBe(true);
  });

  it("ignores pure whitespace", () => {
    expect(shouldQuery("   \n\t  ")).toBe(false);
  });
});

describe("filterDismissed", () => {
  it("drops dismissed works and keeps the rest ordered", () => {
    const cards = [
      { work_id: 1, windows: 3 },
      { work_id: 2, windows: 5 },
      { work_id: 3, windows: 1 },
    ];
    const kept = filterDismissed(cards, new Set([2]));
    expect(kept.map((c) => c.work_id)).toEqual([1, 3]);
  });
});
