import type { HyperRefPayload, TransclusionMarker } from "./api/crdt_sync";

export interface SpanRange {
  start: number;
  end: number;
}

export const DENSITY_THRESHOLD = 5;

export interface MarkerCluster {
  indices: number[];
  start: number;
  end: number;
}

/**
 * Prefer a span stored on the link's HyperRef end at create time; fall back to
 * the excerpt-position search results only when no canonical span is present.
 * This makes stored coordinates the primary source (they survive span
 * migration) and keeps the text search as a genuine fallback.
 */
export function resolveMarkerPositions(
  localRef: Pick<HyperRefPayload, "start_position" | "end_position"> | null | undefined,
  fallback: SpanRange[],
): SpanRange[] {
  if (
    localRef &&
    typeof localRef.start_position === "number" &&
    typeof localRef.end_position === "number" &&
    localRef.start_position >= 0 &&
    localRef.end_position >= localRef.start_position
  ) {
    return [{ start: localRef.start_position, end: localRef.end_position }];
  }
  return fallback;
}

/**
 * Interval-partition markers into non-overlapping lanes. Markers that share any
 * character offset receive distinct lane numbers; the lane number drives the
 * vertical underline offset and the horizontal margin-bar offset so that
 * overlapping links remain individually visible (FR-4.5).
 */
export function assignLinkLanes<T extends SpanRange>(markers: T[]): Map<number, number> {
  const order = markers
    .map((m, i) => ({ m, i }))
    .sort((a, b) => a.m.start - b.m.start || a.m.end - b.m.end);
  const laneEnds: number[] = [];
  const result = new Map<number, number>();
  for (const { m, i } of order) {
    if (m.end <= m.start) continue;
    let lane = -1;
    for (let l = 0; l < laneEnds.length; l++) {
      if (laneEnds[l] <= m.start) {
        lane = l;
        laneEnds[l] = m.end;
        break;
      }
    }
    if (lane === -1) {
      lane = laneEnds.length;
      laneEnds.push(m.end);
    }
    result.set(i, lane);
  }
  return result;
}

/**
 * Group markers into connected components by interval overlap (transitive).
 * Used to detect dense regions (FR-4.5 density indicator): a cluster at or
 * above DENSITY_THRESHOLD is collapsed into a single summary marker.
 */
export function clusterOverlappingMarkers<T extends SpanRange>(markers: T[]): MarkerCluster[] {
  const order = markers
    .map((m, i) => ({ m, i }))
    .filter((e) => e.m.end > e.m.start)
    .sort((a, b) => a.m.start - b.m.start || a.m.end - b.m.end);
  if (order.length === 0) return [];

  const clusters: MarkerCluster[] = [];
  let current: number[] = [];
  let currentEnd = -1;

  const flush = () => {
    if (current.length === 0) return;
    let s = Infinity;
    let e = -1;
    for (const idx of current) {
      s = Math.min(s, markers[idx].start);
      e = Math.max(e, markers[idx].end);
    }
    clusters.push({ indices: current.slice(), start: s, end: e });
    current = [];
  };

  for (const { m, i } of order) {
    if (current.length === 0) {
      current = [i];
      currentEnd = m.end;
    } else if (m.start < currentEnd) {
      current.push(i);
      currentEnd = Math.max(currentEnd, m.end);
    } else {
      flush();
      current = [i];
      currentEnd = m.end;
    }
  }
  flush();
  return clusters;
}

/**
 * Apply a link-type filter. `null` shows everything. When a filter set is
 * active, typed link markers are kept only if their type is selected; untyped
 * (transclusion) markers are always shown, since the filter governs content
 * links only.
 */
export function filterMarkersByType(
  markers: TransclusionMarker[],
  filter: Set<number> | null,
): TransclusionMarker[] {
  if (filter === null) return markers;
  return markers.filter((m) => m.linkTypeId == null || filter.has(m.linkTypeId));
}

/** Set of distinct typed-link type ids present across the given markers. */
export function presentLinkTypeIds(markers: TransclusionMarker[]): number[] {
  const s = new Set<number>();
  for (const m of markers) if (m.linkTypeId != null) s.add(m.linkTypeId);
  return Array.from(s).sort((a, b) => a - b);
}
