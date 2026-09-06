import { describe, expect, it } from "vitest";
import { diffTexts, renderDiffSideHtml, tokenizeWords } from "../text-diff";

describe("tokenizeWords", () => {
  it("round-trips the original text", () => {
    const t = "  one two\n\nthree  four ";
    expect(tokenizeWords(t).join("")).toBe(t);
  });
});

describe("diffTexts", () => {
  it("identical texts are all-equal with ratio 1", () => {
    const r = diffTexts("the quick brown fox", "the quick brown fox");
    expect(r?.matchRatio).toBe(1);
    expect(r?.ops.every((o) => o.kind === "equal")).toBe(true);
  });

  it("disjoint texts have ratio 0 and both sides present", () => {
    const r = diffTexts("alpha beta gamma", "delta epsilon zeta");
    expect(r?.matchRatio).toBe(0);
    expect(r?.ops.some((o) => o.kind === "delete")).toBe(true);
    expect(r?.ops.some((o) => o.kind === "insert")).toBe(true);
  });

  it("middle edit produces delete+insert between equals", () => {
    const r = diffTexts("one two three four five", "one two X four five");
    expect(r?.ops.map((o) => o.kind)).toEqual(["equal", "delete", "insert", "equal"]);
    expect(r?.matchRatio).toBeGreaterThan(0.5);
  });

  it("joining op texts reproduces each original", () => {
    const a = "the cat sat on the mat and slept";
    const b = "the cat lay on the mat and dreamed";
    const r = diffTexts(a, b);
    const rebuiltA = r?.ops.filter((o) => o.kind !== "insert").map((o) => o.text).join("") ?? "";
    const rebuiltB = r?.ops.filter((o) => o.kind !== "delete").map((o) => o.text).join("") ?? "";
    expect(rebuiltA).toBe(a);
    expect(rebuiltB).toBe(b);
  });
});

describe("renderDiffSideHtml", () => {
  it("left shows deletions, right shows insertions", () => {
    const r = diffTexts("keep old tail", "keep new tail");
    const left = renderDiffSideHtml(r!, "a");
    const right = renderDiffSideHtml(r!, "b");
    expect(left).toContain("cmp-del");
    expect(left).not.toContain("cmp-ins");
    expect(right).toContain("cmp-ins");
    expect(right).not.toContain("cmp-del");
  });

  it("collapses long matched runs with a marker", () => {
    const long = Array.from({ length: 60 }, (_, i) => `w${i}`).join(" ");
    const r = diffTexts(long, long + " extra");
    const html = renderDiffSideHtml(r!, "a");
    expect(html).toContain("matched words");
  });
});
