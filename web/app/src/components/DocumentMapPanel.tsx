import { useState, useEffect, useRef, useCallback } from "react";
import type { CrdtSyncClient, GraphEdge } from "../api/crdt_sync";
import {
  computeNodeScores,
  selectTopNodes,
  KIND_ICON,
  KIND_COLOR,
  KIND_ICON_COLOR,
} from "../graph-scoring";
import type { GraphNode, WorkKind } from "../graph-scoring";

interface Props {
  client: CrdtSyncClient | null;
  onSelectWork: (workId: number) => void;
  currentWorkId: number | null;
  onClose: () => void;
  embedded?: boolean;
}

interface SimNode {
  id: number;
  title: string;
  isStarred: boolean;
  isSource: boolean;
  kind: string;
  x: number;
  y: number;
  vx: number;
  vy: number;
}

function hexId(id: number): string {
  return id.toString(16).padStart(4, "0");
}

export function DocumentMapPanel({ client, onSelectWork, currentWorkId, onClose, embedded = false }: Props) {
  const [nodes, setNodes] = useState<SimNode[]>([]);
  const [edges, setEdges] = useState<GraphEdge[]>([]);
  const [loading, setLoading] = useState(true);
  const [dragId, setDragId] = useState<number | null>(null);
  const svgRef = useRef<SVGSVGElement>(null);
  const animRef = useRef<number>(0);
  const nodesRef = useRef<SimNode[]>([]);
  const edgesRef = useRef<GraphEdge[]>([]);

  nodesRef.current = nodes;
  edgesRef.current = edges;

  useEffect(() => {
    if (!client) return;
    setLoading(true);
    let cancelled = false;

    const fetchGraph = async (attempt: number) => {
      try {
        const g = await client.workGraph(currentWorkId ?? undefined, 20);
        if (cancelled) return;
        const cx = 200;
        const cy = 200;
        const simNodes: SimNode[] = g.nodes.map((n, i) => {
          const angle = (2 * Math.PI * i) / Math.max(g.nodes.length, 1);
          const r = 80 + Math.random() * 80;
          return {
            id: n.work_id,
            title: n.title || `Work ${hexId(n.work_id)}`,
            isStarred: n.is_starred,
            isSource: n.is_source,
            kind: (n.kind as string) || "document",
            x: cx + r * Math.cos(angle),
            y: cy + r * Math.sin(angle),
            vx: 0,
            vy: 0,
          };
        });
        setNodes(simNodes);
        setEdges(g.edges);
        setLoading(false);
      } catch {
        if (cancelled) return;
        // Retry up to 3 times with backoff — likely auth race on first mount
        if (attempt < 3) {
          setTimeout(() => fetchGraph(attempt + 1), 500 * (attempt + 1));
        } else {
          setLoading(false);
        }
      }
    };

    fetchGraph(0);
    return () => { cancelled = true; };
  }, [client]);

  const tick = useCallback((silent = false) => {
    const ns = nodesRef.current;
    const es = edgesRef.current;
    if (ns.length === 0) return;

    const alpha = 0.08;
    const repulsion = 800;   // reduced for more nodes
    const attraction = 0.005;
    const centerForce = 0.02; // doubled
    const currentForce = 0.08; // stronger pull on current node
    const damping = 0.85;

    const cx = 200;
    const cy = 200;

    const idxMap = new Map(ns.map((n, i) => [n.id, i]));

    for (let i = 0; i < ns.length; i++) {
      const isCurrent = ns[i].id === currentWorkId;
      const f = isCurrent ? currentForce : centerForce;
      ns[i].vx += (cx - ns[i].x) * f;
      ns[i].vy += (cy - ns[i].y) * f;
    }

    for (let i = 0; i < ns.length; i++) {
      for (let j = i + 1; j < ns.length; j++) {
        const dx = ns[j].x - ns[i].x;
        const dy = ns[j].y - ns[i].y;
        const dist = Math.sqrt(dx * dx + dy * dy) || 1;
        const f = repulsion / (dist * dist);
        const fx = (dx / dist) * f;
        const fy = (dy / dist) * f;
        ns[i].vx -= fx;
        ns[i].vy -= fy;
        ns[j].vx += fx;
        ns[j].vy += fy;
      }
    }

    for (const e of es) {
      const ai = idxMap.get(e.source);
      const bi = idxMap.get(e.target);
      if (ai === undefined || bi === undefined) continue;
      const a = ns[ai];
      const b = ns[bi];
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const dist = Math.sqrt(dx * dx + dy * dy) || 1;
      const isSimilarity = e.edge_type === "similarity";
      const ideal = isSimilarity ? 200 : 120;
      const weightScale = isSimilarity ? Math.max(e.weight, 1) / 100 : 1;
      const force = isSimilarity ? 0.001 : attraction;
      const f = (dist - ideal) * force * weightScale;
      const fx = (dx / dist) * f;
      const fy = (dy / dist) * f;
      a.vx += fx;
      a.vy += fy;
      b.vx -= fx;
      b.vy -= fy;
    }

    for (const n of ns) {
      if (n.id === dragId) continue;
      n.vx *= damping;
      n.vy *= damping;
      n.x += n.vx * alpha;
      n.y += n.vy * alpha;
      // Clamp to viewBox bounds (400×600) with margin for node radius
      n.x = Math.max(30, Math.min(370, n.x));
      n.y = Math.max(30, Math.min(570, n.y));
    }

    if (!silent) setNodes([...ns]);
  }, [dragId, currentWorkId]);

  // When current work changes, gently nudge toward new center (no random kick)
  useEffect(() => {
    if (nodes.length === 0) return;
    const kicked = nodes.map((n) => ({
      ...n,
      vx: n.vx * 0.5,
      vy: n.vy * 0.5,
    }));
    setNodes(kicked);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentWorkId]);

  useEffect(() => {
    if (nodes.length === 0) return;
    // Pre-warm: run 80 iterations silently so nodes start near-converged
    for (let i = 0; i < 80; i++) {
      tick(true);
    }
    setNodes([...nodesRef.current]);
    // Then animate 60 more frames for gentle settle
    let frame = 0;
    const maxFrames = 60;
    const run = () => {
      if (frame >= maxFrames) return;
      tick();
      setNodes([...nodesRef.current]);
      frame++;
      animRef.current = requestAnimationFrame(run);
    };
    animRef.current = requestAnimationFrame(run);
    return () => cancelAnimationFrame(animRef.current);
  }, [nodes.length, tick]);

  const handleMouseDown = (id: number) => (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragId(id);
    cancelAnimationFrame(animRef.current);
  };

  const handleMouseMove = useCallback((e: React.MouseEvent<SVGSVGElement>) => {
    if (dragId === null || !svgRef.current) return;
    const rect = svgRef.current.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    setNodes((prev) =>
      prev.map((n) => (n.id === dragId ? { ...n, x, y, vx: 0, vy: 0 } : n))
    );
  }, [dragId]);

  const handleMouseUp = useCallback(() => {
    if (dragId !== null) {
      setDragId(null);
    }
  }, [dragId]);

  const nodeMap = new Map(nodes.map((n) => [n.id, n]));

  if (embedded) {
    const MAX_NODES = 9;

    // Adapt SimNode[] to GraphNode[] for the pure scoring functions
    const graphNodes: GraphNode[] = nodes.map((n) => ({
      work_id: n.id,
      title: n.title,
      is_starred: n.isStarred,
      is_source: n.isSource,
      kind: n.kind as WorkKind,
    }));

    // Score each node relative to current work (per FR-21)
    const nodeScores = computeNodeScores(edges as GraphEdge[], currentWorkId);

    // Select top N relevant nodes — fewer is better for clarity
    const visibleGraphNodes = selectTopNodes(graphNodes, nodeScores, currentWorkId, MAX_NODES);
    const visibleIds = new Set(visibleGraphNodes.map((n) => n.work_id));
    const visibleEdges = edges.filter((e) => visibleIds.has(e.source) && visibleIds.has(e.target));

    return (
      <div className="document-map-embedded">
        {loading ? (
          <div className="ws-placeholder"><div className="ws-placeholder-label">Loading graph…</div></div>
        ) : visibleGraphNodes.length === 0 ? (
          <div className="ws-placeholder"><div className="ws-placeholder-label">No works yet</div></div>
        ) : (
          <>
            <svg
              ref={svgRef}
              className="document-map-svg-embedded"
              viewBox="0 0 400 600"
              preserveAspectRatio="xMidYMid slice"
              onMouseMove={handleMouseMove}
              onMouseUp={handleMouseUp}
              onMouseLeave={handleMouseUp}
              style={{ cursor: "pointer" }}
            >
              {visibleEdges.map((e, i) => {
                const a = nodeMap.get(e.source);
                const b = nodeMap.get(e.target);
                if (!a || !b) return null;
                // All edges: simple light dotted line
                const involvesCurrent = a.id === currentWorkId || b.id === currentWorkId;
                return (
                  <line
                    key={`e-${i}`}
                    x1={a.x}
                    y1={a.y}
                    x2={b.x}
                    y2={b.y}
                    stroke="#94a3b8"
                    strokeWidth={involvesCurrent ? 1 : 0.5}
                    strokeDasharray="3 4"
                    opacity={involvesCurrent ? 0.7 : 0.4}
                  />
                );
              })}
              {visibleGraphNodes.map((gn) => {
                const simNode = nodeMap.get(gn.work_id);
                if (!simNode) return null;
                void nodeScores.get(gn.work_id);
                const isCurrent = gn.work_id === currentWorkId;
                const kind = gn.kind || "document";
                const fillColor = gn.is_source ? "#c4a35a" : KIND_COLOR[kind];
                const displayKind = gn.is_source ? "book" : kind;
                const iconChar = gn.is_source ? "📖" : KIND_ICON[kind];
                const iconColor = gn.is_source ? "#fff" : KIND_ICON_COLOR[kind];
                const r = 24;
                return (
                  <g
                    key={gn.work_id}
                    onMouseDown={handleMouseDown(gn.work_id)}
                    onClick={() => onSelectWork(gn.work_id)}
                    style={{ cursor: "pointer" }}
                  >
                    <circle
                      cx={simNode.x}
                      cy={simNode.y}
                      r={r}
                      fill={fillColor}
                      stroke={isCurrent ? "#1e3a8a" : "#fff"}
                      strokeWidth={isCurrent ? 2 : 1}
                    >
                      <title>{`${gn.title}\n${displayKind}${isCurrent ? " · current" : ""}${gn.is_source ? " · source" : ""}`}</title>
                    </circle>
                    {kind === "collection" ? (
                      <circle
                        cx={simNode.x}
                        cy={simNode.y}
                        r={r * 0.3}
                        fill="#000000"
                        style={{ pointerEvents: "none" }}
                      />
                    ) : (
                      <text
                        x={simNode.x}
                        y={simNode.y}
                        textAnchor="middle"
                        dominantBaseline="central"
                        fontSize={r * 1.2}
                        fill={iconColor}
                        style={{ pointerEvents: "none", userSelect: "none" }}
                      >
                        {iconChar}
                      </text>
                    )}
                  </g>
                );
              })}
            </svg>
            <div className="ws-graph-legend">
              <span className="ws-legend-item"><span className="ws-legend-dot" style={{ background: KIND_COLOR.document }} />📄 Doc</span>
              <span className="ws-legend-item"><span className="ws-legend-dot" style={{ background: KIND_COLOR.note }} />📝 Note</span>
              <span className="ws-legend-item"><span className="ws-legend-dot" style={{ background: KIND_COLOR.person }} />👤 Person</span>
              <span className="ws-legend-item"><span className="ws-legend-dot" style={{ background: KIND_COLOR.concept }} />💡 Concept</span>
              <span className="ws-legend-item"><span className="ws-legend-dot" style={{ background: KIND_COLOR.collection }} />● Collection</span>
              <span className="ws-legend-item"><span className="ws-legend-dot" style={{ background: KIND_COLOR.commentary }} />💬 Commentary</span>
            </div>
          </>
        )}
      </div>
    );
  }

  return (
    <div className="document-map-overlay">
      <div className="document-map-panel">
        <div className="document-map-header">
          <span className="document-map-title">Document Map</span>
          <span className="document-map-stats">
            {nodes.length} docs, {edges.filter(e => e.edge_type !== "similarity").length} links, {edges.filter(e => e.edge_type === "similarity").length} similarities
          </span>
          <button type="button" className="document-map-close" onClick={onClose}>{"\u00d7"}</button>
        </div>
        {loading ? (
          <div className="document-map-loading">Loading graph...</div>
        ) : (
          <svg
            ref={svgRef}
            className="document-map-svg"
            viewBox="0 0 800 600"
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            onMouseLeave={handleMouseUp}
          >
            <defs>
              <marker id="arrowhead" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
                <polygon points="0 0, 8 3, 0 6" fill="#aaa" />
              </marker>
            </defs>
            {edges.map((e, i) => {
              const a = nodeMap.get(e.source);
              const b = nodeMap.get(e.target);
              if (!a || !b) return null;
              const isSimilarity = e.edge_type === "similarity";
              return (
                <line
                  key={`e-${i}`}
                  x1={a.x}
                  y1={a.y}
                  x2={b.x}
                  y2={b.y}
                  stroke={isSimilarity ? "#ddd" : "#ccc"}
                  strokeWidth={1.5}
                  strokeDasharray={isSimilarity ? "4 4" : undefined}
                  opacity={isSimilarity ? 0.3 + (e.weight / 100) * 0.7 : 1}
                  markerEnd={isSimilarity ? undefined : "url(#arrowhead)"}
                />
              );
            })}
            {nodes.map((n) => {
              const isCurrent = n.id === currentWorkId;
              const r = isCurrent ? 14 : n.isStarred ? 12 : 10;
              const fill = n.isSource
                ? "#f59e0b"
                : isCurrent
                  ? "#4361ee"
                  : n.isStarred
                    ? "#f59e0b"
                    : "#6b7280";
              return (
                <g
                  key={n.id}
                  onMouseDown={handleMouseDown(n.id)}
                  onClick={() => onSelectWork(n.id)}
                  style={{ cursor: "pointer" }}
                >
                  <circle cx={n.x} cy={n.y} r={r} fill={fill} stroke={isCurrent ? "#1e3a8a" : "#fff"} strokeWidth={isCurrent ? 2.5 : 1.5} />
                  <text
                    x={n.x}
                    y={n.y + r + 12}
                    textAnchor="middle"
                    fontSize={9}
                    fill="#555"
                    style={{ pointerEvents: "none", userSelect: "none" }}
                  >
                    {n.title.length > 18 ? n.title.slice(0, 18) + "\u2026" : n.title}
                  </text>
                </g>
              );
            })}
          </svg>
        )}
      </div>
    </div>
  );
}
