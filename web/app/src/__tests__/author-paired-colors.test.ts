import { describe, it, expect } from "vitest";
import {
  authorColor,
  authorOrderedPair,
  pairedAuthorColors,
  setPairedAuthorColors,
} from "../author-color";

describe("authorOrderedPair (paired-colour identity codes)", () => {
  it("is stable per identity", () => {
    expect(authorOrderedPair("alice")).toEqual(authorOrderedPair("alice"));
    expect(authorOrderedPair("alice")).toEqual(authorOrderedPair("alice"));
  });

  it("always returns two DISTINCT hues", () => {
    for (const name of ["alice", "bob", "carol", "dave", "eve", "frank", "grace", "heidi"]) {
      const [a, b] = authorOrderedPair(name);
      expect(a).not.toBe(b);
      expect(a).toMatch(/^#[0-9a-f]{6}$/);
      expect(b).toMatch(/^#[0-9a-f]{6}$/);
    }
  });

  it("distinguishes many authors beyond the 25-hue single palette", () => {
    const singles = new Set<string>();
    const pairs = new Set<string>();
    for (let i = 0; i < 200; i++) {
      const name = `user-${i}`;
      singles.add(authorColor(name));
      pairs.add(authorOrderedPair(name).join("|"));
    }
    // Single hues must collide well before 200 users; pairs must not
    // collapse anywhere near as fast.
    expect(singles.size).toBeLessThan(200);
    expect(pairs.size).toBeGreaterThan(singles.size * 4);
  });
});

describe("paired colour mode toggle", () => {
  it("round-trips the persisted preference (when storage is available)", () => {
    // Some test sandboxes run without a working localStorage backend
    // (the safety wrapper then degrades to session-only). Probe it
    // first and skip the persistence assertion if writes don't stick.
    let storageWorks = false;
    try {
      window.localStorage.setItem("__probe__", "1");
      storageWorks = window.localStorage.getItem("__probe__") === "1";
      window.localStorage.removeItem("__probe__");
    } catch {
      storageWorks = false;
    }
    if (!storageWorks) return;
    setPairedAuthorColors(true);
    expect(pairedAuthorColors()).toBe(true);
    setPairedAuthorColors(false);
    expect(pairedAuthorColors()).toBe(false);
  });
});
