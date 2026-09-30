import { describe, it, expect } from "vitest";
import {
  addPane,
  removePane,
  setPaneScroll,
  setPaneHeld,
  heldEnds,
  paneForWork,
  type PaneState,
} from "../pane-registry";

function seed(): PaneState[] {
  return addPane(addPane([], 0x10), 0x20);
}

describe("pane registry", () => {
  it("adds panes in order", () => {
    const panes = seed();
    expect(panes.map((p) => p.workId)).toEqual([0x10, 0x20]);
    expect(panes[0].key).not.toBe(panes[1].key);
  });

  it("never duplicates a work — re-adding is a no-op", () => {
    const panes = seed();
    expect(addPane(panes, 0x10)).toBe(panes); // identity: unchanged
  });

  it("does not cap pane count (layout is the user's call)", () => {
    let panes: PaneState[] = [];
    for (let i = 1; i <= 6; i++) panes = addPane(panes, i * 16);
    expect(panes).toHaveLength(6);
  });

  it("removes a pane by key, keeps others' state intact", () => {
    const panes = seed();
    const withScroll = setPaneScroll(panes, panes[1].key, 4242);
    const reduced = removePane(withScroll, withScroll[0].key);
    expect(reduced.map((p) => p.workId)).toEqual([0x20]);
    expect(reduced[0].scrollTop).toBe(4242);
  });

  it("remembers per-pane scroll (long-doc positioning)", () => {
    const panes = seed();
    const a = setPaneScroll(panes, panes[0].key, 100);
    const b = setPaneScroll(a, a[1].key, 9000);
    expect(b[0].scrollTop).toBe(100);
    expect(b[1].scrollTop).toBe(9000);
  });

  it("holds selections per pane and lists all held ends", () => {
    const panes = seed();
    const a = setPaneHeld(panes, panes[0].key, { start: 5, end: 9, text: "abcd" });
    const b = setPaneHeld(a, a[1].key, { start: 1, end: 3, text: "xy" });
    const ends = heldEnds(b);
    expect(ends).toEqual([
      { workId: 0x10, key: b[0].key, start: 5, end: 9, text: "abcd" },
      { workId: 0x20, key: b[1].key, start: 1, end: 3, text: "xy" },
    ]);
  });

  it("collapsed holds are not listed as ends", () => {
    const panes = seed();
    const a = setPaneHeld(panes, panes[0].key, { start: 7, end: 7, text: "" });
    expect(heldEnds(a)).toEqual([]);
  });

  it("closing a pane drops its held end only", () => {
    const panes = seed();
    const a = setPaneHeld(panes, panes[0].key, { start: 5, end: 9, text: "abcd" });
    const b = setPaneHeld(a, a[1].key, { start: 1, end: 3, text: "xy" });
    const after = removePane(b, b[0].key);
    expect(heldEnds(after).map((e) => e.workId)).toEqual([0x20]);
  });

  it("finds a pane by work", () => {
    const panes = seed();
    expect(paneForWork(panes, 0x20)?.key).toBe(panes[1].key);
    expect(paneForWork(panes, 0x99)).toBeUndefined();
  });
});
