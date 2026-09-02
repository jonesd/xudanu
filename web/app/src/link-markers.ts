import type { HyperRefPayload, LinkEntry, TransclusionMarker } from "./api/crdt_sync";

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
 * FR-40 S6/L1: the gathered-end members that live on THIS work.
 * A link's local end (LeftEnd when viewing the origin work,
 * RightEnd when viewing the destination) may carry an end-set in
 * `end_sets`; every attachment whose work_context matches the
 * viewed work becomes a marker span. Returns members with their
 * 1-based index and the end's total — the "passage i of N" data.
 */
export interface EndSetMember {
  ref: HyperRefPayload;
  index: number; // 1-based, within the full end-set
  total: number;
}

export function localEndSetMembers(
  link: LinkEntry,
  workId: number,
): EndSetMember[] {
  const wireName = link.origin === workId ? "LeftEnd" : "RightEnd";
  const attachments = (link.end_sets ?? []).find(([name, refs]) => name === wireName && refs.length > 1)?.[1];
  if (!attachments) return [];
  const members: EndSetMember[] = [];
  attachments.forEach((ref, i) => {
    if (ref.work_context === workId) {
      members.push({ ref, index: i + 1, total: attachments.length });
    }
  });
  return members;
}

/**
 * FR-40 S6/L1: span of one attachment ref (same validity rule as
 * resolveMarkerPositions' primary path).
 */
export function refSpan(
  ref: Pick<HyperRefPayload, "start_position" | "end_position"> | null | undefined,
): SpanRange | null {
  if (
    ref &&
    typeof ref.start_position === "number" &&
    typeof ref.end_position === "number" &&
    ref.start_position >= 0 &&
    ref.end_position >= ref.start_position
  ) {
    return { start: ref.start_position, end: ref.end_position };
  }
  return null;
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

/**
 * FR-40 demo feedback fix: deterministic, non-intersecting label
 * placement for link description boxes.
 *
 * The old inline loop had two bugs: a single push-down pass (a box
 * shoved clear of one collision could land on an already-passed
 * box), and tie-breaking by marker iteration order (server HashMap
 * order — which label wins the top slot was a coin flip).
 *
 * Because every box has the same height and we place top-down in
 * deterministic order (firstTop, then lane, then span start), each
 * box only needs to clear the running lowest bottom — O(n), and
 * pairwise disjoint by construction.
 */
export interface DescBoxInput {
  firstTop: number;
  lane: number;
  /** Span start — optional third tie-break. */
  start?: number;
}

export function placeDescBoxes<T extends DescBoxInput>(
  descs: T[],
  boxHeight: number,
  gap: number,
): Array<{ desc: T; y: number }> {
  const ordered = [...descs].sort(
    (a, b) =>
      a.firstTop - b.firstTop ||
      a.lane - b.lane ||
      (a.start ?? 0) - (b.start ?? 0),
  );
  const out: Array<{ desc: T; y: number }> = [];
  let lowestBottom = -Infinity;
  for (const desc of ordered) {
    const y = Math.max(desc.firstTop, lowestBottom + gap);
    out.push({ desc, y });
    lowestBottom = Math.max(lowestBottom, y + boxHeight);
  }
  return out;
}

/**
 * FR-40 solo/focus mode: hovering a connection dims every OTHER
 * link's rendering (underlines, margin bars, labels, badges) so the
 * hovered link — and, for gathered ends, ALL its member passages —
 * stands alone against a quieted page. The untrained-eye fix:
 * density stays, confusion goes.
 */
export const FOCUS_DIM_ALPHA = 0.22;

export function markerFocusAlpha(
  marker: Pick<TransclusionMarker, "linkId">,
  focusLinkId: number | null,
): number {
  // No focus, or focus on a non-link surface: nothing dims.
  if (focusLinkId == null || focusLinkId === 0) return 1;
  // Transclusions/compounds (linkId 0) never participate.
  if (marker.linkId === 0) return 1;
  return marker.linkId === focusLinkId ? 1 : FOCUS_DIM_ALPHA;
}
