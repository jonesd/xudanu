import { describe, it, expect } from "vitest";
import type { LinkEntry } from "../api/crdt_sync";

function filterLinksByType(links: LinkEntry[], activeTypes: Set<number>): LinkEntry[] {
  if (activeTypes.size === 0) return links;
  return links.filter((l) => (l.link_types || []).some((t) => activeTypes.has(t)));
}

function makeLink(id: number, types: number[]): LinkEntry {
  return {
    link_id: id,
    origin: 1,
    destination: id + 100,
    origin_ref: null,
    destination_ref: null,
    link_types: types,
  };
}

describe("FR-27: Link type filtering", () => {
  const allLinks = [
    makeLink(1, [1]),          // Comment
    makeLink(2, [2]),          // Reference
    makeLink(3, [1, 2]),       // Comment + Reference
    makeLink(4, [5]),          // See Also
    makeLink(5, [7]),          // Trail
    makeLink(6, []),           // No type
  ];

  it("returns all links when no filter is active", () => {
    const result = filterLinksByType(allLinks, new Set());
    expect(result).toHaveLength(6);
  });

  it("filters to a single type", () => {
    const result = filterLinksByType(allLinks, new Set([1])); // Comment
    expect(result).toHaveLength(2); // links 1 and 3
    expect(result.map((l) => l.link_id)).toEqual([1, 3]);
  });

  it("filters to multiple types (OR logic)", () => {
    const result = filterLinksByType(allLinks, new Set([2, 5])); // Reference + See Also
    expect(result).toHaveLength(3); // links 2, 3 (has type 2), 4
    expect(result.map((l) => l.link_id)).toEqual([2, 3, 4]);
  });

  it("includes links with no types when filter is empty", () => {
    const result = filterLinksByType(allLinks, new Set());
    expect(result.some((l) => l.link_id === 6)).toBe(true);
  });

  it("excludes links with no types when a filter is active", () => {
    const result = filterLinksByType(allLinks, new Set([1]));
    expect(result.some((l) => l.link_id === 6)).toBe(false);
  });

  it("returns empty when filter matches nothing", () => {
    const result = filterLinksByType(allLinks, new Set([99])); // Non-existent type
    expect(result).toHaveLength(0);
  });

  it("handles links with undefined link_types", () => {
    const linksWithUndefined = [
      ...allLinks,
      { ...makeLink(7, [1]), link_types: undefined },
    ];
    const result = filterLinksByType(linksWithUndefined, new Set([1]));
    expect(result.some((l) => l.link_id === 7)).toBe(false);
  });

  it("Trail type (7) filters correctly", () => {
    const result = filterLinksByType(allLinks, new Set([7]));
    expect(result).toHaveLength(1);
    expect(result[0].link_id).toBe(5);
  });
});
