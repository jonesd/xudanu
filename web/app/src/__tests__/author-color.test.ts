import { describe, it, expect } from "vitest";
import { authorColor, authorColorPair, authorColorSecondary } from "../author-color";

describe("authorColor", () => {
  it("returns a hex color string", () => {
    const color = authorColor("alice");
    expect(color).toMatch(/^#[0-9a-f]{6}$/);
  });

  it("is deterministic — same key always maps to same color", () => {
    const a = authorColor("bob");
    const b = authorColor("bob");
    expect(a).toBe(b);
  });

  it("different keys can map to different colors", () => {
    const colors = new Set<string>();
    for (let i = 0; i < 100; i++) {
      colors.add(authorColor(`user-${i}`));
    }
    expect(colors.size).toBeGreaterThan(1);
  });

  it("returns a valid hex color from the pair palette", () => {
    const color = authorColor("any-user");
    expect(color).toMatch(/^#[0-9a-f]{6}$/);
  });

  it("handles empty string without crashing", () => {
    expect(() => authorColor("")).not.toThrow();
  });

  it("handles unicode keys", () => {
    expect(() => authorColor("ユーザー")).not.toThrow();
    expect(authorColor("ユーザー")).toMatch(/^#[0-9a-f]{6}$/);
  });
});

describe("authorColorPair", () => {
  it("returns primary and secondary colors", () => {
    const pair = authorColorPair("alice");
    expect(pair.primary).toMatch(/^#[0-9a-f]{6}$/);
    expect(pair.secondary).toMatch(/^#[0-9a-f]{6}$/);
  });

  it("primary and secondary are different", () => {
    const pair = authorColorPair("david");
    expect(pair.primary).not.toBe(pair.secondary);
  });

  it("is deterministic", () => {
    expect(authorColorPair("alice")).toEqual(authorColorPair("alice"));
  });

  it("authorColor matches pair.primary", () => {
    expect(authorColor("alice")).toBe(authorColorPair("alice").primary);
  });

  it("authorColorSecondary matches pair.secondary", () => {
    expect(authorColorSecondary("alice")).toBe(authorColorPair("alice").secondary);
  });
});
