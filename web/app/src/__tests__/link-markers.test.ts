import { describe, it, expect } from "vitest";
import {
  resolveMarkerPositions,
  assignLinkLanes,
  clusterOverlappingMarkers,
  filterMarkersByType,
  presentLinkTypeIds,
  DENSITY_THRESHOLD,
} from "../link-markers";
import type { TransclusionMarker } from "../api/crdt_sync";

function mkMarker(start: number, end: number, type?: number): TransclusionMarker {
  return {
    start,
    end,
    linkId: 0,
    direction: "outgoing",
    otherWorkId: 1,
    otherWorkTitle: "t",
    color: "#fff",
    linkTypeId: type,
  };
}

describe("resolveMarkerPositions", () => {
  it("prefers a stored span over the excerpt-search fallback", () => {
    const out = resolveMarkerPositions(
      { start_position: 10, end_position: 20 },
      [{ start: 99, end: 999 }],
    );
    expect(out).toEqual([{ start: 10, end: 20 }]);
  });

  it("falls back to search results when no canonical span is stored", () => {
    const out = resolveMarkerPositions(
      { start_position: null, end_position: null },
      [{ start: 3, end: 8 }],
    );
    expect(out).toEqual([{ start: 3, end: 8 }]);
  });

  it("falls back when localRef is null", () => {
    expect(resolveMarkerPositions(null, [{ start: 0, end: 1 }])).toEqual([{ start: 0, end: 1 }]);
  });

  it("ignores an invalid stored span (end < start)", () => {
    expect(resolveMarkerPositions({ start_position: 5, end_position: 4 }, [{ start: 0, end: 2 }])).toEqual([{ start: 0, end: 2 }]);
  });

  it("accepts a zero-width stored span (point)", () => {
    expect(resolveMarkerPositions({ start_position: 7, end_position: 7 }, [])).toEqual([{ start: 7, end: 7 }]);
  });
});

describe("assignLinkLanes", () => {
  it("assigns non-overlapping markers to the same lane", () => {
    const lanes = assignLinkLanes([{ start: 0, end: 5 }, { start: 5, end: 10 }]);
    expect(lanes.get(0)).toBe(0);
    expect(lanes.get(1)).toBe(0);
  });

  it("gives overlapping markers distinct lanes", () => {
    const lanes = assignLinkLanes([{ start: 0, end: 10 }, { start: 3, end: 8 }]);
    expect(lanes.get(0)).toBe(0);
    expect(lanes.get(1)).toBe(1);
  });

  it("stacks three mutually overlapping links on three lanes", () => {
    const lanes = assignLinkLanes([{ start: 0, end: 9 }, { start: 1, end: 9 }, { start: 2, end: 9 }]);
    expect(new Set(lanes.values()).size).toBe(3);
  });

  it("skips zero-width markers", () => {
    const lanes = assignLinkLanes([{ start: 4, end: 4 }, { start: 0, end: 5 }]);
    expect(lanes.has(0)).toBe(false);
    expect(lanes.get(1)).toBe(0);
  });
});

describe("clusterOverlappingMarkers", () => {
  it("returns one cluster for a single marker", () => {
    const c = clusterOverlappingMarkers([{ start: 0, end: 5 }]);
    expect(c).toHaveLength(1);
    expect(c[0].indices).toEqual([0]);
  });

  it("groups overlapping markers transitively", () => {
    // a overlaps b, b overlaps c, a does not overlap c
    const c = clusterOverlappingMarkers([{ start: 0, end: 3 }, { start: 2, end: 6 }, { start: 5, end: 9 }]);
    expect(c).toHaveLength(1);
    expect(c[0].indices).toHaveLength(3);
  });

  it("separates disjoint markers into distinct clusters", () => {
    const c = clusterOverlappingMarkers([{ start: 0, end: 3 }, { start: 10, end: 13 }]);
    expect(c).toHaveLength(2);
  });

  it("reports the union span of a cluster", () => {
    const c = clusterOverlappingMarkers([{ start: 2, end: 6 }, { start: 4, end: 12 }]);
    expect(c[0].start).toBe(2);
    expect(c[0].end).toBe(12);
  });
});

describe("filterMarkersByType", () => {
  it("returns all markers when filter is null", () => {
    const ms = [mkMarker(0, 1, 1), mkMarker(2, 3, 2)];
    expect(filterMarkersByType(ms, null)).toBe(ms);
  });

  it("keeps typed markers only when their type is selected", () => {
    const ms = [mkMarker(0, 1, 1), mkMarker(2, 3, 2)];
    const out = filterMarkersByType(ms, new Set([1]));
    expect(out).toHaveLength(1);
    expect(out[0].linkTypeId).toBe(1);
  });

  it("always keeps untyped (transclusion) markers", () => {
    const ms = [mkMarker(0, 1), mkMarker(2, 3, 2)];
    const out = filterMarkersByType(ms, new Set([1]));
    expect(out).toHaveLength(1);
    expect(out[0].linkTypeId).toBeUndefined();
  });
});

describe("presentLinkTypeIds", () => {
  it("returns sorted distinct typed-link ids", () => {
    const ms = [mkMarker(0, 1, 3), mkMarker(2, 3), mkMarker(4, 5, 1), mkMarker(6, 7, 3)];
    expect(presentLinkTypeIds(ms)).toEqual([1, 3]);
  });

  it("excludes untyped markers", () => {
    expect(presentLinkTypeIds([mkMarker(0, 1)])).toEqual([]);
  });
});

describe("FR-4.5 density threshold", () => {
  it("is set to 5", () => {
    expect(DENSITY_THRESHOLD).toBe(5);
  });

  it("a 5-marker overlap forms a single cluster that meets the threshold", () => {
    const ms = Array.from({ length: 5 }, (_, i) => ({ start: i, end: 10 }));
    const clusters = clusterOverlappingMarkers(ms);
    expect(clusters).toHaveLength(1);
    expect(clusters[0].indices.length).toBeGreaterThanOrEqual(DENSITY_THRESHOLD);
  });
});
