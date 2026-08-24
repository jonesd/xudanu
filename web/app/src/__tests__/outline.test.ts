import { describe, it, expect } from "vitest";
import { buildOutline, normalizeLevels } from "../outline";

describe("buildOutline", () => {
  it("empty text produces no entries", () => {
    expect(buildOutline("")).toEqual([]);
  });

  it("headings nest and paragraphs sit under their heading", () => {
    const text = [
      "# Title",
      "Intro paragraph.",
      "## Section",
      "Section body.",
      "### Sub",
      "Sub body.",
    ].join("\n");
    const out = buildOutline(text);
    expect(out.map((e) => [e.kind, e.level])).toEqual([
      ["heading", 1],
      ["paragraph", 2],
      ["heading", 2],
      ["paragraph", 3],
      ["heading", 3],
      ["paragraph", 4],
    ]);
  });

  it("headingless document is fully flat", () => {
    const out = buildOutline("one\ntwo\n\nthree");
    expect(out.every((e) => e.level === 1)).toBe(true);
    expect(out.map((e) => e.label)).toEqual(["one", "two", "three"]);
  });

  it("charPos points at the line start of each entry", () => {
    const text = "first\n# Head\nbody";
    const out = buildOutline(text);
    expect(out[0].charPos).toBe(0);
    expect(out[1].charPos).toBe(6);
    expect(out[2].charPos).toBe(13);
  });

  it("blank lines are skipped, list markers stripped from labels", () => {
    const out = buildOutline("# H\n\n- item one\n\n1. item two\n");
    expect(out.map((e) => e.label)).toEqual(["H", "item one", "item two"]);
  });

  it("long labels are truncated with ellipsis", () => {
    const long = "x".repeat(100);
    const [entry] = buildOutline(long);
    expect(entry.label.length).toBeLessThanOrEqual(64);
    expect(entry.label.endsWith("\u2026")).toBe(true);
  });

  it("code fence lines are excluded", () => {
    const out = buildOutline("# H\n```\ncode line\n```\nafter");
    expect(out.map((e) => e.label)).toEqual(["H", "after"]);
  });
});

describe("normalizeLevels", () => {
  it("shifts so the shallowest heading is level 1", () => {
    const text = "## Only H2s\nbody\n### H3\nbody";
    const out = normalizeLevels(buildOutline(text));
    expect(out[0].level).toBe(1);
    expect(out[2].level).toBe(2);
  });

  it("leaves already-normal outlines untouched", () => {
    const out = normalizeLevels(buildOutline("# H\nbody"));
    expect(out.map((e) => e.level)).toEqual([1, 2]);
  });
});
