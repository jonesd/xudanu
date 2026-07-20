import { describe, it, expect } from "vitest";
import {
  normalizeEdgeType,
  scoreByType,
  computeNodeScores,
  computeNodeDegrees,
  selectTopNodes,
  nodeVisual,
  edgeVisual,
  KIND_COLOR,
} from "../graph-scoring";
import type { GraphEdge, GraphNode } from "../graph-scoring";

// ── normalizeEdgeType ──────────────────────────────────────────────────────

describe("normalizeEdgeType", () => {
  it("identifies transclusion", () => {
    expect(normalizeEdgeType("transclusion")).toBe("transclusion");
    expect(normalizeEdgeType("Transclusion")).toBe("transclusion");
    expect(normalizeEdgeType("inline_transclusion")).toBe("transclusion");
  });

  it("identifies cross-server transclusion", () => {
    expect(normalizeEdgeType("cross_server_transclusion")).toBe("cross_server_transclusion");
    expect(normalizeEdgeType("cross-server")).toBe("cross_server_transclusion");
  });

  it("splits similarity by weight", () => {
    expect(normalizeEdgeType("similarity", 95)).toBe("similarity_high");
    expect(normalizeEdgeType("similarity", 80)).toBe("similarity_high");
    expect(normalizeEdgeType("similarity", 79)).toBe("similarity_medium");
    expect(normalizeEdgeType("similarity", 50)).toBe("similarity_medium");
    expect(normalizeEdgeType("similarity", 49)).toBe("similarity_low");
    expect(normalizeEdgeType("similarity", 0)).toBe("similarity_low");
  });

  it("identifies typed link variants", () => {
    expect(normalizeEdgeType("comment")).toBe("link_comment");
    expect(normalizeEdgeType("disagreement")).toBe("link_disagreement");
    expect(normalizeEdgeType("quotation")).toBe("link_quotation");
    expect(normalizeEdgeType("quote")).toBe("link_quotation");
    expect(normalizeEdgeType("reference")).toBe("link_reference");
    expect(normalizeEdgeType("see_also")).toBe("link_see_also");
    expect(normalizeEdgeType("seealso")).toBe("link_see_also");
    expect(normalizeEdgeType("See Also")).toBe("link_see_also");
    expect(normalizeEdgeType("web")).toBe("link_web");
  });

  it("returns unknown for unrecognized types", () => {
    expect(normalizeEdgeType("xyzzy")).toBe("unknown");
    expect(normalizeEdgeType("")).toBe("unknown");
  });

  it("handles whitespace and case", () => {
    expect(normalizeEdgeType("  Transclusion  ")).toBe("transclusion");
    expect(normalizeEdgeType("COMMENT")).toBe("link_comment");
  });
});

// ── scoreByType ────────────────────────────────────────────────────────────

describe("scoreByType", () => {
  it("scores transclusion highest", () => {
    expect(scoreByType("transclusion")).toBe(5);
  });

  it("scores cross-server transclusion as 4", () => {
    expect(scoreByType("cross_server_transclusion")).toBe(4);
  });

  it("scores typed links as 3", () => {
    expect(scoreByType("comment")).toBe(3);
    expect(scoreByType("disagreement")).toBe(3);
    expect(scoreByType("quotation")).toBe(3);
    expect(scoreByType("reference")).toBe(3);
    expect(scoreByType("see_also")).toBe(3);
    expect(scoreByType("web")).toBe(3);
  });

  it("scores similarity by weight threshold", () => {
    expect(scoreByType("similarity", 95)).toBe(2);
    expect(scoreByType("similarity", 60)).toBe(1);
    expect(scoreByType("similarity", 30)).toBe(0.5);
  });

  it("scores unknown types as 1", () => {
    expect(scoreByType("mystery")).toBe(1);
    expect(scoreByType("")).toBe(1);
  });

  it("weight boundary: 80 is high, 79 is medium", () => {
    expect(scoreByType("similarity", 80)).toBe(2);
    expect(scoreByType("similarity", 79)).toBe(1);
  });

  it("weight boundary: 50 is medium, 49 is low", () => {
    expect(scoreByType("similarity", 50)).toBe(1);
    expect(scoreByType("similarity", 49)).toBe(0.5);
  });

  it("transclusion-like strings all score 5", () => {
    expect(scoreByType("inline_transclusion")).toBe(5);
    expect(scoreByType("Transclusion")).toBe(5);
  });
});

// ── computeNodeScores ──────────────────────────────────────────────────────

describe("computeNodeScores", () => {
  const edges: GraphEdge[] = [
    { source: 1, target: 2, edge_type: "transclusion", weight: 100 },
    { source: 1, target: 3, edge_type: "comment", weight: 0 },
    { source: 1, target: 4, edge_type: "similarity", weight: 90 },
    { source: 5, target: 6, edge_type: "transclusion", weight: 100 }, // not involving 1
    { source: 2, target: 3, edge_type: "comment", weight: 0 }, // not involving 1
  ];

  it("returns empty map when currentWorkId is null", () => {
    const scores = computeNodeScores(edges, null);
    expect(scores.size).toBe(0);
  });

  it("scores nodes adjacent to current work", () => {
    const scores = computeNodeScores(edges, 1);
    expect(scores.get(2)).toBe(5); // transclusion
    expect(scores.get(3)).toBe(3); // comment
    expect(scores.get(4)).toBe(2); // similarity high
  });

  it("does not score non-adjacent nodes", () => {
    const scores = computeNodeScores(edges, 1);
    expect(scores.has(5)).toBe(false);
    expect(scores.has(6)).toBe(false);
  });

  it("does not include the current work in scores", () => {
    const scores = computeNodeScores(edges, 1);
    expect(scores.has(1)).toBe(false);
  });

  it("accumulates score across multiple edges to same node", () => {
    const multiEdges: GraphEdge[] = [
      { source: 1, target: 2, edge_type: "transclusion", weight: 100 },
      { source: 1, target: 2, edge_type: "comment", weight: 0 },
      { source: 2, target: 1, edge_type: "similarity", weight: 60 }, // reversed direction
    ];
    const scores = computeNodeScores(multiEdges, 1);
    expect(scores.get(2)).toBe(5 + 3 + 1); // 9
  });

  it("handles edges where current work is the target", () => {
    const scores = computeNodeScores(edges, 2);
    expect(scores.get(1)).toBe(5); // transclusion source=1 target=2
    expect(scores.get(3)).toBe(3); // comment source=2 target=3
  });

  it("handles empty edges", () => {
    const scores = computeNodeScores([], 1);
    expect(scores.size).toBe(0);
  });
});

// ── computeNodeDegrees ─────────────────────────────────────────────────────

describe("computeNodeDegrees", () => {
  const edges: GraphEdge[] = [
    { source: 1, target: 2, edge_type: "transclusion", weight: 0 },
    { source: 1, target: 3, edge_type: "comment", weight: 0 },
    { source: 2, target: 3, edge_type: "comment", weight: 0 },
  ];

  it("counts both incoming and outgoing edges", () => {
    const degree = computeNodeDegrees(edges, null);
    expect(degree.get(1)).toBe(2);
    expect(degree.get(2)).toBe(2);
    expect(degree.get(3)).toBe(2);
  });

  it("restricts to visible IDs when filter provided", () => {
    const degree = computeNodeDegrees(edges, new Set([1, 2]));
    expect(degree.get(1)).toBe(1); // only edge 1-2
    expect(degree.get(2)).toBe(1);
    expect(degree.has(3)).toBe(false);
  });

  it("handles empty edges", () => {
    const degree = computeNodeDegrees([], null);
    expect(degree.size).toBe(0);
  });

  it("handles isolated nodes (degree 0)", () => {
    const degree = computeNodeDegrees(edges, null);
    expect(degree.has(999)).toBe(false); // node not in any edge
  });
});

// ── selectTopNodes ─────────────────────────────────────────────────────────

describe("selectTopNodes", () => {
  const nodes: GraphNode[] = [
    { work_id: 1, title: "Current", is_starred: false, is_source: false },
    { work_id: 2, title: "A", is_starred: false, is_source: false },
    { work_id: 3, title: "B", is_starred: false, is_source: false },
    { work_id: 4, title: "C", is_starred: false, is_source: false },
    { work_id: 5, title: "D", is_starred: false, is_source: false },
  ];

  it("returns all nodes when currentWorkId is null", () => {
    const scores = new Map<number, number>();
    const result = selectTopNodes(nodes, scores, null, 3);
    expect(result.length).toBe(5);
  });

  it("returns all nodes when count <= maxNodes", () => {
    const scores = new Map<number, number>([[2, 5], [3, 3]]);
    const result = selectTopNodes(nodes, scores, 1, 10);
    expect(result.length).toBe(5);
  });

  it("includes the current work as first element", () => {
    const scores = new Map<number, number>([[2, 5], [3, 3], [4, 1], [5, 0]]);
    const result = selectTopNodes(nodes, scores, 1, 3);
    expect(result[0].work_id).toBe(1);
    expect(result.length).toBe(3);
  });

  it("selects highest-scoring nodes first", () => {
    const scores = new Map<number, number>([[2, 5], [3, 3], [4, 1], [5, 0]]);
    const result = selectTopNodes(nodes, scores, 1, 3);
    expect(result.map((n) => n.work_id)).toEqual([1, 2, 3]);
  });

  it("handles maxNodes=1 (only current)", () => {
    const scores = new Map<number, number>([[2, 5]]);
    const result = selectTopNodes(nodes, scores, 1, 1);
    expect(result.length).toBe(1);
    expect(result[0].work_id).toBe(1);
  });

  it("handles missing current work gracefully", () => {
    const scores = new Map<number, number>([[2, 5]]);
    const result = selectTopNodes(nodes, scores, 999, 3);
    // Current not in nodes; returns top maxNodes-1 by score
    expect(result.length).toBe(2);
    expect(result[0].work_id).toBe(2); // highest score
  });

  it("respects tie-breaking by score then original order", () => {
    const scores = new Map<number, number>([[2, 5], [3, 5], [4, 5]]);
    const result = selectTopNodes(nodes, scores, 1, 3);
    expect(result.map((n) => n.work_id)).toEqual([1, 2, 3]);
  });
});

// ── nodeVisual ─────────────────────────────────────────────────────────────

describe("nodeVisual", () => {
  const baseNode: GraphNode = {
    work_id: 1,
    title: "Test",
    is_starred: false,
    is_source: false,
  };

  it("styles current work prominently", () => {
    const v = nodeVisual(baseNode, 0, 0, true);
    expect(v.radius).toBe(36);
    expect(v.strokeWidth).toBe(4);
    expect(v.showLabel).toBe(true);
    expect(v.icon).toBeTruthy();
  });

  it("styles high-score nodes (≥5) large", () => {
    const v = nodeVisual(baseNode, 5, 0, false);
    expect(v.radius).toBe(32);
    expect(v.showLabel).toBe(true);
  });

  it("styles medium-score nodes (3-5)", () => {
    const v = nodeVisual(baseNode, 3, 0, false);
    expect(v.radius).toBe(30);
    expect(v.showLabel).toBe(true);
  });

  it("styles low-score nodes (1-3)", () => {
    const v = nodeVisual(baseNode, 1, 0, false);
    expect(v.radius).toBe(26);
    expect(v.showLabel).toBe(true);
  });

  it("styles no-score high-degree nodes", () => {
    const v = nodeVisual(baseNode, 0, 5, false);
    expect(v.radius).toBe(28);
  });

  it("styles no-score low-degree nodes", () => {
    const v = nodeVisual(baseNode, 0, 1, false);
    expect(v.radius).toBe(22);
  });

  it("styles disconnected nodes small", () => {
    const v = nodeVisual(baseNode, 0, 0, false);
    expect(v.radius).toBe(20);
  });

  it("source nodes get thicker amber border", () => {
    const sourceNode = { ...baseNode, is_source: true };
    const v = nodeVisual(sourceNode, 0, 0, false);
    expect(v.stroke).toBe("#f59e0b");
    expect(v.strokeWidth).toBe(3);
  });

  it("starred nodes get thicker yellow border", () => {
    const starredNode = { ...baseNode, is_starred: true };
    const v = nodeVisual(starredNode, 0, 0, false);
    expect(v.stroke).toBe("#fbbf24");
    expect(v.strokeWidth).toBe(3);
  });

  it("kind color always wins for fill", () => {
    // Even with high score, fill should be kind color, not score color
    const conceptNode = { ...baseNode, kind: "concept" as const };
    const v = nodeVisual(conceptNode, 10, 5, false);
    expect(v.fill).toBe(KIND_COLOR.concept);
    expect(v.fill).not.toBe("#3b82f6");
  });

  it("always provides an icon", () => {
    const v = nodeVisual(baseNode, 0, 0, false);
    expect(typeof v.icon).toBe("string");
    expect(v.icon.length).toBeGreaterThan(0);
  });

  it("uses kind-specific icon when provided", () => {
    const conceptNode = { ...baseNode, kind: "concept" as const };
    const v = nodeVisual(conceptNode, 0, 0, false);
    expect(v.icon).toBe("💡");
  });

  it("uses kind color for fill even when disconnected", () => {
    const personNode = { ...baseNode, kind: "person" as const };
    const v = nodeVisual(personNode, 0, 0, false);
    expect(v.fill).toBe("#d1d5db");  // light grey per mockup
  });

  it("current work uses kind color for fill", () => {
    const collectionNode = { ...baseNode, kind: "collection" as const };
    const v = nodeVisual(collectionNode, 0, 0, true);
    expect(v.fill).toBe("#c084fc");  // mauve per mockup
  });

  it("provides label combining icon and title", () => {
    const v = nodeVisual({ ...baseNode, title: "My Work" }, 0, 0, false);
    expect(v.label).toContain("📄");
    expect(v.label).toContain("My Work");
  });

  it("truncates long titles in label", () => {
    const longTitle = "A".repeat(50);
    const v = nodeVisual({ ...baseNode, title: longTitle }, 0, 0, false);
    expect(v.label).toContain("…");
    expect(v.label.length).toBeLessThan(longTitle.length + 10);
  });
});

// ── edgeVisual ─────────────────────────────────────────────────────────────

describe("edgeVisual", () => {
  it("transclusion edges are blue and thick", () => {
    const v = edgeVisual("transclusion", 0, true);
    expect(v.stroke).toBe("#3b82f6");
    expect(v.strokeWidth).toBeGreaterThanOrEqual(2);
    expect(v.markerEnd).toBe(true);
  });

  it("disagreement edges are red", () => {
    const v = edgeVisual("disagreement", 0, true);
    expect(v.stroke).toBe("#f85149");
  });

  it("quotation edges are purple", () => {
    const v = edgeVisual("quotation", 0, true);
    expect(v.stroke).toBe("#a371f7");
  });

  it("reference / see_also edges are green", () => {
    expect(edgeVisual("reference", 0, true).stroke).toBe("#3fb950");
    expect(edgeVisual("see_also", 0, true).stroke).toBe("#3fb950");
  });

  it("web edges are teal", () => {
    expect(edgeVisual("web", 0, true).stroke).toBe("#39d2c0");
  });

  it("similarity edges are dashed", () => {
    const v = edgeVisual("similarity", 80, true);
    expect(v.dash).toBe("4 3");
    expect(v.markerEnd).toBe(false);
  });

  it("edges involving current work are more opaque", () => {
    const involved = edgeVisual("comment", 0, true);
    const notInvolved = edgeVisual("comment", 0, false);
    expect(involved.opacity).toBeGreaterThan(notInvolved.opacity);
  });

  it("edges involving current work are thicker", () => {
    const involved = edgeVisual("comment", 0, true);
    const notInvolved = edgeVisual("comment", 0, false);
    expect(involved.strokeWidth).toBeGreaterThan(notInvolved.strokeWidth);
  });

  it("cross-server transclusion is sky blue", () => {
    const v = edgeVisual("cross_server_transclusion", 0, true);
    expect(v.stroke).toBe("#0ea5e9");
  });

  it("unknown edge types get neutral grey", () => {
    const v = edgeVisual("mystery_type", 0, true);
    expect(v.stroke).toBe("#94a3b8");
  });

  it("similarity edges thinner than transclusion", () => {
    const sim = edgeVisual("similarity", 80, true);
    const trans = edgeVisual("transclusion", 0, true);
    expect(sim.strokeWidth).toBeLessThan(trans.strokeWidth);
  });
});

// ── Integration scenarios ──────────────────────────────────────────────────

describe("integration scenarios", () => {
  it("scenario: typical workspace graph with mixed relationships", () => {
    const edges: GraphEdge[] = [
      { source: 1, target: 2, edge_type: "transclusion", weight: 100 },
      { source: 1, target: 3, edge_type: "transclusion", weight: 100 },
      { source: 1, target: 4, edge_type: "comment", weight: 0 },
      { source: 1, target: 5, edge_type: "similarity", weight: 70 },
      { source: 1, target: 6, edge_type: "similarity", weight: 30 },
      { source: 7, target: 8, edge_type: "transclusion", weight: 100 }, // unrelated
    ];
    const scores = computeNodeScores(edges, 1);
    // Node 2 and 3 are tied at 5 (transclusion)
    expect(scores.get(2)).toBe(5);
    expect(scores.get(3)).toBe(5);
    // Node 4 has a comment (3)
    expect(scores.get(4)).toBe(3);
    // Node 5 has medium similarity (1)
    expect(scores.get(5)).toBe(1);
    // Node 6 has low similarity (0.5)
    expect(scores.get(6)).toBe(0.5);
    // 7 and 8 should not be scored
    expect(scores.has(7)).toBe(false);
    expect(scores.has(8)).toBe(false);
  });

  it("scenario: selectTopNodes filters correctly for typical case", () => {
    const nodes: GraphNode[] = Array.from({ length: 20 }, (_, i) => ({
      work_id: i + 1,
      title: `Work ${i + 1}`,
      is_starred: false,
      is_source: false,
    }));
    const scores = new Map<number, number>([
      [2, 5], [3, 5], [4, 3], [5, 3], [6, 1],
      [7, 1], [8, 0.5], [9, 0.5], [10, 0.5],
    ]);
    const result = selectTopNodes(nodes, scores, 1, 8);
    expect(result.length).toBe(8);
    expect(result[0].work_id).toBe(1); // current first
    expect(result[1].work_id).toBe(2); // highest score
    expect(result[2].work_id).toBe(3); // tied second
  });

  it("scenario: visual hierarchy matches score", () => {
    const baseNode: GraphNode = {
      work_id: 1, title: "X", is_starred: false, is_source: false,
    };
    const score5 = nodeVisual(baseNode, 5, 0, false);
    const score3 = nodeVisual(baseNode, 3, 0, false);
    const score1 = nodeVisual(baseNode, 1, 0, false);
    const score0 = nodeVisual(baseNode, 0, 0, false);
    expect(score5.radius).toBeGreaterThan(score3.radius);
    expect(score3.radius).toBeGreaterThan(score1.radius);
    expect(score1.radius).toBeGreaterThan(score0.radius);
  });

  it("scenario: edge styling distinguishes all major types", () => {
    const types = ["transclusion", "comment", "disagreement", "quotation", "reference", "similarity"];
    const colors = new Set(types.map((t) => edgeVisual(t, t === "similarity" ? 80 : 0, true).stroke));
    // At least 5 distinct colors for 6 types (some may share)
    expect(colors.size).toBeGreaterThanOrEqual(5);
  });

  it("regression: empty edge list does not crash any function", () => {
    expect(() => computeNodeScores([], 1)).not.toThrow();
    expect(() => computeNodeDegrees([], null)).not.toThrow();
    expect(() => selectTopNodes([], new Map(), 1, 5)).not.toThrow();
  });

  it("regression: null currentWorkId does not crash", () => {
    expect(() => computeNodeScores([], null)).not.toThrow();
    expect(() => selectTopNodes([], new Map(), null, 5)).not.toThrow();
  });
});
