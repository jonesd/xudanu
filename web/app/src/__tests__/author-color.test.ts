import { describe, it, expect } from "vitest";
import { authorColor } from "../author-color";

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

  it("returns a color from the known palette", () => {
    const palette = [
      "#e06c75", "#61afef", "#98c379", "#c678dd", "#e5c07b",
      "#56b6c2", "#d19a66", "#be5046", "#7ec8e3", "#c3e88d",
    ];
    const color = authorColor("any-user");
    expect(palette).toContain(color);
  });

  it("handles empty string without crashing", () => {
    expect(() => authorColor("")).not.toThrow();
  });

  it("handles unicode keys", () => {
    expect(() => authorColor("ユーザー")).not.toThrow();
    expect(authorColor("ユーザー")).toMatch(/^#[0-9a-f]{6}$/);
  });
});
