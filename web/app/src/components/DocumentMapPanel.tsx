import { useState, useEffect, useRef, useCallback } from "react";
import type { CrdtSyncClient, GraphNode, GraphEdge } from "../api/crdt_sync";

interface Props {
  client: CrdtSyncClient | null;
  onSelectWork: (workId: number) => void;
  currentWorkId: number | null;
  onClose: () => void;
}

interface SimNode {
  id: number;
  title: string;
  isStarred: boolean;
  isSource: boolean;
  x: number;
  y: number;
  vx: number;
  vy: number;
}

function hexId(id: number): string {
  return id.toString(16).padStart(4, "0");
}

export function DocumentMapPanel({ client, onSelectWork, currentWorkId, onClose }: Props) {
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
    client.workGraph().then((g) => {
      const cx = 400;
      const cy = 300;
      const simNodes: SimNode[] = g.nodes.map((n, i) => {
        const angle = (2 * Math.PI * i) / g.nodes.length;
        const r = 150 + Math.random() * 80;
        return {
          id: n.work_id,
          title: n.title || `Work ${hexId(n.work_id)}`,
          isStarred: n.is_starred,
          isSource: n.is_source,
          x: cx + r * Math.cos(angle),
          y: cy + r * Math.sin(angle),
          vx: 0,
          vy: 0,
        };
      });
      setNodes(simNodes);
      setEdges(g.edges);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [client]);

  const tick = useCallback(() => {
    const ns = nodesRef.current;
    const es = edgesRef.current;
    if (ns.length === 0) return;

    const alpha = 0.3;
    const repulsion = 3000;
    const attraction = 0.005;
    const centerForce = 0.01;
    const damping = 0.85;

    const cx = 400;
    const cy = 300;

    const idxMap = new Map(ns.map((n, i) => [n.id, i]));

    for (let i = 0; i < ns.length; i++) {
      ns[i].vx += (cx - ns[i].x) * centerForce;
      ns[i].vy += (cy - ns[i].y) * centerForce;
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
      n.x = Math.max(30, Math.min(770, n.x));
      n.y = Math.max(30, Math.min(570, n.y));
    }

    setNodes([...ns]);
  }, [dragId]);

  useEffect(() => {
    if (nodes.length === 0) return;
    let frame = 0;
    const maxFrames = 300;
    const run = () => {
      if (frame >= maxFrames) return;
      tick();
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
