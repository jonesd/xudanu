import { describe, it, expect } from "vitest";
import { exhibitionTransition, type Exhibition } from "../exhibition";

// The boundary is an INDICATION, never a barrier: same exhibition or
// both outside -> silence; every crossing between sets speaks once.

const mk = (cover: number, title: string, ...members: number[]): Exhibition => ({
  coverWorkId: cover,
  title,
  memberIds: new Set([cover, ...members]),
});

const gallery = mk(0x5ca, "The Gallery of Unusual Connections", 1, 2, 3);
const other = mk(0x700, "Another Exhibition", 9, 10);

describe("exhibitionTransition", () => {
  it("same exhibition -> silence", () => {
    expect(exhibitionTransition(gallery, gallery)).toBeNull();
  });

  it("both outside any exhibition -> silence", () => {
    expect(exhibitionTransition(null, null)).toBeNull();
  });

  it("leaving: member work -> unrelated work", () => {
    expect(exhibitionTransition(gallery, null)).toEqual({
      kind: "leaving",
      title: "The Gallery of Unusual Connections",
    });
  });

  it("entering: unrelated work -> member work", () => {
    expect(exhibitionTransition(null, gallery)).toEqual({
      kind: "entering",
      title: "The Gallery of Unusual Connections",
    });
  });

  it("crossing between two exhibitions speaks the departure", () => {
    expect(exhibitionTransition(gallery, other)).toEqual({
      kind: "leaving",
      title: "The Gallery of Unusual Connections",
    });
  });

  it("distinct Exhibition objects with the same cover are the same unit", () => {
    // membership resolved twice (cache miss) must not read as a crossing
    const again = mk(0x5ca, "The Gallery of Unusual Connections", 1, 2, 3);
    expect(exhibitionTransition(gallery, again)).toBeNull();
  });
});
