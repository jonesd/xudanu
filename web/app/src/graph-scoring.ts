// Graph relevance scoring — pure functions for testability.
// See docs/dev/FR-21-graph-relevance.md for the design.

export type WorkKind = "document" | "note" | "person" | "concept" | "collection" | "commentary";

// Type colors per the workspace graph mockup (FR-22 §"Visual: Larger Nodes with Icons").
// These are the canonical type colors used in the graph legend, node fills, and any
// other place that visually distinguishes work kinds.
//
// Documented color scheme:
//   Document    — blue background
//   Note        — yellow background
//   Person      — light grey background (with black head silhouette icon)
//   Concept     — light green background
//   Collection  — mauve background (with black dot in center)
//   Commentary  — mauve background
//
// Hex values chosen to match the mockup while remaining readable.
export const KIND_COLOR: Record<WorkKind, string> = {
  document: "#3b82f6",      // blue
  note: "#fbbf24",          // yellow
  person: "#d1d5db",        // light grey
  concept: "#86efac",       // light green
  collection: "#c084fc",    // mauve
  commentary: "#d8b4fe",    // mauve (slightly lighter to distinguish from collection)
};

export const KIND_ICON: Record<WorkKind, string> = {
  document: "📄",
  note: "📝",
  person: "👤",      // head silhouette — rendered black on light grey
  concept: "💡",
  collection: "●",   // rendered as SVG black circle, not text
  commentary: "💬",
};

// Icon color: most icons are white on colored bg, but Person and Collection
// use black icons on light backgrounds per the mockup.
export const KIND_ICON_COLOR: Record<WorkKind, string> = {
  document: "#ffffff",
  note: "#ffffff",
  person: "#000000",      // black head silhouette on light grey
  concept: "#ffffff",
  collection: "#000000",  // black dot on mauve (rendered as SVG circle)
  commentary: "#ffffff",
};

export interface GraphEdge {
  source: number;
  target: number;
  edge_type: string;
  weight: number;
}

export interface GraphNode {
  work_id: number;
  title: string;
  is_starred: boolean;
  is_source: boolean;
  kind?: WorkKind;
}

export type EdgeKind =
  | "transclusion"
  | "cross_server_transclusion"
  | "link_comment"
  | "link_disagreement"
  | "link_quotation"
  | "link_reference"
  | "link_see_also"
  | "link_web"
  | "similarity_high"
  | "similarity_medium"
  | "similarity_low"
  | "unknown";

/**
 * Normalize an edge_type string from the backend into a known kind.
 * The backend may use various conventions; we tolerate them all.
 */
export function normalizeEdgeType(edgeType: string, weight: number = 0): EdgeKind {
  const t = edgeType.toLowerCase().trim();
  // Check cross-server BEFORE transclusion (it's a subset)
  if (t.includes("cross") && (t.includes("server") || t.includes("transclusion"))) return "cross_server_transclusion";
  if (t === "transclusion" || t.includes("transclusion")) return "transclusion";
  if (t === "similarity" || t === "similar") {
    if (weight >= 80) return "similarity_high";
    if (weight >= 50) return "similarity_medium";
    return "similarity_low";
  }
  if (t.includes("comment")) return "link_comment";
  if (t.includes("disagree")) return "link_disagreement";
  if (t.includes("quot")) return "link_quotation";
  if (t.includes("reference") || t.includes("ref")) return "link_reference";
  if (t.includes("see_also") || t.includes("seealso") || t.includes("see also")) return "link_see_also";
  if (t.includes("web")) return "link_web";
  return "unknown";
}

/**
 * Score a single edge by its type. Higher = stronger relationship.
 * Per FR-21 spec.
 */
export function scoreByType(edgeType: string, weight: number = 0): number {
  const kind = normalizeEdgeType(edgeType, weight);
  switch (kind) {
    case "transclusion":
      return 5;
    case "cross_server_transclusion":
      return 4;
    case "link_comment":
    case "link_disagreement":
    case "link_quotation":
    case "link_reference":
    case "link_see_also":
    case "link_web":
      return 3;
    case "similarity_high":
      return 2;
    case "similarity_medium":
      return 1;
    case "similarity_low":
      return 0.5;
    case "unknown":
    default:
      return 1;
  }
}

/**
 * Aggregate score per node relative to a focal (current) work.
 * Returns a map of workId -> total score.
 */
export function computeNodeScores(
  edges: GraphEdge[],
  currentWorkId: number | null
): Map<number, number> {
  const scores = new Map<number, number>();
  if (currentWorkId === null) return scores;
  for (const e of edges) {
    let other = -1;
    if (e.source === currentWorkId) other = e.target;
    else if (e.target === currentWorkId) other = e.source;
    if (other === -1) continue;
    const s = scoreByType(e.edge_type, e.weight);
    scores.set(other, (scores.get(other) || 0) + s);
  }
  return scores;
}

/**
 * Compute the degree (number of edges) per node, restricted to a
 * set of visible node IDs (or all nodes if visibleIds is null).
 */
export function computeNodeDegrees(
  edges: GraphEdge[],
  visibleIds: Set<number> | null = null
): Map<number, number> {
  const degree = new Map<number, number>();
  for (const e of edges) {
    if (visibleIds && (!visibleIds.has(e.source) || !visibleIds.has(e.target))) continue;
    degree.set(e.source, (degree.get(e.source) || 0) + 1);
    degree.set(e.target, (degree.get(e.target) || 0) + 1);
  }
  return degree;
}

/**
 * Filter and rank nodes by relevance score, returning the top N.
 * The current work is always included as the first element.
 * Nodes with score 0 are excluded (unless there's room).
 */
export function selectTopNodes(
  nodes: GraphNode[],
  scores: Map<number, number>,
  currentWorkId: number | null,
  maxNodes: number
): GraphNode[] {
  if (currentWorkId === null) return nodes;
  if (nodes.length <= maxNodes) return nodes;

  const scored = nodes
    .filter((n) => n.work_id !== currentWorkId)
    .map((n) => ({ node: n, score: scores.get(n.work_id) || 0 }))
    .sort((a, b) => b.score - a.score)
    .slice(0, maxNodes - 1)
    .map((x) => x.node);

  const current = nodes.find((n) => n.work_id === currentWorkId);
  return current ? [current, ...scored] : scored;
}

export interface NodeVisualProps {
  radius: number;
  fill: string;
  stroke: string;
  strokeWidth: number;
  showLabel: boolean;
  icon: string;
  label: string;
}

/**
 * Determine visual styling for a node. Per FR-22:
 * - Fill color ALWAYS reflects kind (so types are distinguishable at a glance)
 * - Size reflects relevance score
 * - Border reflects status (current, starred, source)
 */
export function nodeVisual(
  node: GraphNode,
  score: number,
  degree: number,
  isCurrent: boolean
): NodeVisualProps {
  const kind = node.kind || "document";
  const icon = KIND_ICON[kind];
  const fill = KIND_COLOR[kind];
  const title = node.title.length > 24 ? node.title.slice(0, 24) + "…" : node.title;
  const label = `${icon} ${title}`;

  // Border reflects status, not kind
  let stroke: string;
  let strokeWidth: number;
  if (isCurrent) {
    stroke = "#1e3a8a";
    strokeWidth = 4;
  } else if (node.is_source) {
    stroke = "#f59e0b";
    strokeWidth = 3;
  } else if (node.is_starred) {
    stroke = "#fbbf24";
    strokeWidth = 3;
  } else if (score >= 3) {
    stroke = "#fff";
    strokeWidth = 2.5;
  } else {
    stroke = "#fff";
    strokeWidth = 1.5;
  }

  // Size reflects score (relevance) + minimum to fit icon
  let radius: number;
  let showLabel: boolean;

  if (isCurrent) {
    radius = 36;
    showLabel = true;
  } else if (node.is_source || node.is_starred) {
    radius = Math.max(28, 30 + Math.min(score, 4) * 0.5);
    showLabel = true;
  } else if (score >= 5) {
    radius = 32;
    showLabel = true;
  } else if (score >= 3) {
    radius = 30;
    showLabel = true;
  } else if (score >= 1) {
    radius = 26;
    showLabel = true;
  } else if (degree >= 4) {
    radius = 28;
    showLabel = true;
  } else if (degree >= 2) {
    radius = 24;
    showLabel = true;
  } else if (degree === 1) {
    radius = 22;
    showLabel = false;
  } else {
    radius = 20;
    showLabel = false;
  }

  return { radius, fill, stroke, strokeWidth, showLabel, icon, label };
}

export interface EdgeVisualProps {
  stroke: string;
  strokeWidth: number;
  dash: string | undefined;
  opacity: number;
  markerEnd: boolean;
}

/**
 * Determine visual styling for an edge by type. Per FR-21 §"Edge Styling".
 * Lighter strokes to avoid visual clutter; current-work edges still emphasized.
 */
export function edgeVisual(
  edgeType: string,
  weight: number,
  involvesCurrent: boolean
): EdgeVisualProps {
  const kind = normalizeEdgeType(edgeType, weight);
  const baseOpacity = involvesCurrent ? 0.85 : 0.45;
  const baseWidthBoost = involvesCurrent ? 1 : 0;

  switch (kind) {
    case "transclusion":
      return { stroke: "#3b82f6", strokeWidth: 2.5 + baseWidthBoost, dash: undefined, opacity: baseOpacity, markerEnd: true };
    case "cross_server_transclusion":
      return { stroke: "#0ea5e9", strokeWidth: 2 + baseWidthBoost, dash: undefined, opacity: baseOpacity, markerEnd: true };
    case "link_comment":
      return { stroke: "#58a6ff", strokeWidth: 1.5 + baseWidthBoost, dash: undefined, opacity: baseOpacity, markerEnd: true };
    case "link_disagreement":
      return { stroke: "#f85149", strokeWidth: 1.5 + baseWidthBoost, dash: undefined, opacity: baseOpacity, markerEnd: true };
    case "link_quotation":
      return { stroke: "#a371f7", strokeWidth: 1.5 + baseWidthBoost, dash: undefined, opacity: baseOpacity, markerEnd: true };
    case "link_reference":
    case "link_see_also":
      return { stroke: "#3fb950", strokeWidth: 1.5 + baseWidthBoost, dash: undefined, opacity: baseOpacity, markerEnd: true };
    case "link_web":
      return { stroke: "#39d2c0", strokeWidth: 1.5 + baseWidthBoost, dash: undefined, opacity: baseOpacity, markerEnd: true };
    case "similarity_high":
    case "similarity_medium":
    case "similarity_low":
      // Light grey, thin, dashed — visible but not noisy
      return {
        stroke: "#94a3b8",
        strokeWidth: 1,
        dash: "4 3",
        opacity: involvesCurrent ? 0.6 : 0.3,
        markerEnd: false,
      };
    case "unknown":
    default:
      return { stroke: "#94a3b8", strokeWidth: 1.5, dash: undefined, opacity: baseOpacity, markerEnd: true };
  }
}
