import { describe, it, expect } from "vitest";
import { canConnect, buildLinkRefs, chipExcerpt, type PaneEnd } from "../split-authoring";

function end(over: Partial<PaneEnd> = {}): PaneEnd {
  return { workId: 1, start: 10, end: 20, text: "the funculator passage", ...over };
}

describe("canConnect", () => {
  it("accepts two real ends on different works", () => {
    expect(canConnect(end(), end({ workId: 2 }))).toBe(true);
  });
  it("rejects missing ends", () => {
    expect(canConnect(null, end({ workId: 2 }))).toBe(false);
    expect(canConnect(end(), null)).toBe(false);
    expect(canConnect(null, null)).toBe(false);
  });
  it("rejects same-work ends (self-link collapse)", () => {
    expect(canConnect(end(), end({ workId: 1, start: 30, end: 40 }))).toBe(false);
  });
  it("rejects empty or collapsed spans", () => {
    expect(canConnect(end(), end({ workId: 2, start: 5, end: 5 }))).toBe(false);
    expect(canConnect(end(), end({ workId: 2, start: 9, end: 5 }))).toBe(false);
    expect(canConnect(end(), end({ workId: 2, text: "   " }))).toBe(false);
  });
});

describe("buildLinkRefs", () => {
  it("maps ends to wire refs with exact spans", () => {
    const { originRef, destinationRef } = buildLinkRefs(
      end({ workId: 7, start: 3, end: 9, text: "origin text" }),
      end({ workId: 9, start: 100, end: 110, text: "destination text" }),
    );
    expect(originRef).toEqual({ excerpt: "origin text", start: 3, end: 9 });
    expect(destinationRef).toEqual({ excerpt: "destination text", start: 100, end: 110 });
  });
  it("caps excerpts at 200 chars (overlay contract parity)", () => {
    const long = "x".repeat(350);
    const { originRef } = buildLinkRefs(end({ text: long }), end({ workId: 2 }));
    expect(originRef.excerpt.length).toBe(200);
  });
});

describe("chipExcerpt", () => {
  it("collapses whitespace and trims", () => {
    expect(chipExcerpt("  a \n\n b  ")).toBe("a b");
  });
  it("ellipsizes beyond max", () => {
    expect(chipExcerpt("abcdefghij", 5)).toBe("abcd…");
  });
  it("passes short text through", () => {
    expect(chipExcerpt("short")).toBe("short");
  });
});
