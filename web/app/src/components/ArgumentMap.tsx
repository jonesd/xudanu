import { useMemo, useState } from "react";
import type { LinkEntry } from "../api/crdt_sync";
import {
  buildArgumentMap,
  layoutMap,
  type MapNode,
  type MapNodeKind,
} from "../argument-map";

/**
 * FR-85 Phase 3b: the argument map — a derived view over the link
 * graph. Objections red below the contention, responses green
 * beneath them, argdown numbering, endorsement weight on every
 * node. Writes flow through the callbacks (create work + typed link
 * + responds_to) — the component never stores map state.
 */

const KIND_COLORS: Record<MapNodeKind, string> = {
  contention: "#58a6ff", // blue
  objection: "#f85149", // red
  reason: "#3fb950", // green
  other: "#8a8a96", // grey
  ghost: "#8a8a96", // grey, dashed
};

const NODE_W = 148;
const NODE_H = 44;
const GAP_X = 18;
const GAP_Y = 76;

interface Props {
  rootWorkId: number;
  links: LinkEntry[];
  rootLabel?: string;
  selectedId: string | null;
  onSelect: (nodeId: string) => void;
  onJump?: (workId: number) => void;
  /** Add a child node under the selected parent (writes go through the shell). */
  onAddChild?: (parent: MapNode, kind: "objection" | "reason", text: string) => void;
  busy?: boolean;
}

function nodeTitle(node: MapNode): string {
  const t = node.label || "untitled";
  return t.length > 26 ? t.slice(0, 26) + "…" : t;
}

export function ArgumentMap({
  rootWorkId,
  links,
  rootLabel,
  selectedId,
  onSelect,
  onJump,
  onAddChild,
  busy,
}: Props) {
  const [draft, setDraft] = useState("");
  const { layout, byId } = useMemo(() => {
    const { root } = buildArgumentMap(rootWorkId, links, rootLabel);
    const l = layoutMap(root);
    const map = new Map(l.nodes.map((p) => [p.node.id, p]));
    return { layout: l, byId: map };
  }, [rootWorkId, links, rootLabel]);

  const selected = selectedId != null ? byId.get(selectedId) : undefined;
  const canAdd =
    onAddChild != null && selected != null && selected.node.kind !== "ghost";

  const px = (u: number) => u * (NODE_W + GAP_X);
  const py = (u: number) => u * GAP_Y;
  const svgW = px(layout.width);
  const svgH = py(layout.height - 1) + NODE_H;

  const submit = (kind: "objection" | "reason") => {
    if (!canAdd || !selected || draft.trim().length === 0) return;
    onAddChild(selected.node, kind, draft.trim());
    setDraft("");
  };

  return (
    <div className="ws-argmap" data-testid="ws-argmap">
      {canAdd && (
        <div
          style={{
            display: "flex",
            gap: 6,
            marginBottom: 8,
            alignItems: "center",
            flexWrap: "wrap",
          }}
        >
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            placeholder={
              selected.node.kind === "contention"
                ? "state the objection…"
                : "state the response…"
            }
            style={{
              flex: 1,
              minWidth: 120,
              background: "var(--bg-inset, #161b22)",
              border: "1px solid var(--border)",
              borderRadius: 4,
              color: "var(--text)",
              fontSize: 11,
              padding: "3px 6px",
            }}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                submit(selected.node.kind === "contention" ? "objection" : "reason");
              }
            }}
          />
          {selected.node.kind === "contention" ? (
            <button
              type="button"
              disabled={busy || draft.trim().length === 0}
              onClick={() => submit("objection")}
              style={{
                fontSize: 10, background: "none", border: "1px solid #f85149",
                borderRadius: 4, color: "#f85149", padding: "2px 8px",
                cursor: "pointer", whiteSpace: "nowrap",
              }}
              title="Create a work that disputes the selected node, linked as Disagreement with responds_to"
            >
              + objection
            </button>
          ) : (
            <button
              type="button"
              disabled={busy || draft.trim().length === 0}
              onClick={() => submit("reason")}
              style={{
                fontSize: 10, background: "none", border: "1px solid #3fb950",
                borderRadius: 4, color: "#3fb950", padding: "2px 8px",
                cursor: "pointer", whiteSpace: "nowrap",
              }}
              title="Create a work that responds to the selected node, linked with responds_to"
            >
              + response
            </button>
          )}
        </div>
      )}
      <div style={{ overflowX: "auto", border: "1px solid var(--border)", borderRadius: 6 }}>
        <svg
          width={Math.max(svgW, 280)}
          height={svgH}
          role="img"
          aria-label="argument map"
          style={{ display: "block", minWidth: "100%" }}
        >
          {layout.edges.map((e) => {
            const p = byId.get(e.parentId);
            const c = byId.get(e.childId);
            if (!p || !c) return null;
            const x1 = px(p.x);
            const y1 = py(p.y) + NODE_H;
            const x2 = px(c.x);
            const y2 = py(c.y);
            const midY = (y1 + y2) / 2;
            const isObj = c.node.kind === "objection" || c.node.kind === "ghost";
            return (
              <path
                key={`${e.parentId}->${e.childId}`}
                d={`M ${x1} ${y1} C ${x1} ${midY}, ${x2} ${midY}, ${x2} ${y2}`}
                fill="none"
                stroke={isObj ? "#f8514966" : "#3fb95066"}
                strokeWidth={1.5}
                strokeDasharray={c.node.kind === "ghost" ? "3 3" : undefined}
              />
            );
          })}
          {layout.nodes.map(({ node, x, y }) => {
            const cx = px(x) - NODE_W / 2;
            const cy = py(y);
            const color = KIND_COLORS[node.kind];
            const isSel = node.id === selectedId;
            return (
              <g
                key={node.id}
                transform={`translate(${cx}, ${cy})`}
                onClick={() => onSelect(node.id)}
                style={{ cursor: "pointer" }}
              >
                <rect
                  width={NODE_W}
                  height={NODE_H}
                  rx={7}
                  fill="var(--bg-inset, #161b22)"
                  stroke={isSel ? "#e6edf3" : color}
                  strokeWidth={isSel ? 2 : 1.4}
                  strokeDasharray={node.kind === "ghost" ? "4 3" : undefined}
                />
                <text x={7} y={15} fontSize={8} fill={color} fontWeight={700}>
                  {node.number}
                  {node.kind === "objection" ? " ⚑" : ""}
                  {node.kind === "ghost" ? " ↩" : ""}
                </text>
                <text x={7} y={29} fontSize={10} fill="var(--text, #e6edf3)">
                  {nodeTitle(node)}
                </text>
                <text x={7} y={40} fontSize={8} fill="var(--text-dim, #8a8a96)">
                  {node.weight > 0 ? `${node.weight} endorse${node.weight === 1 ? "" : "s"}` : "unendorsed"}
                </text>
              </g>
            );
          })}
        </svg>
      </div>
      {selected && selected.node.workId != null && onJump && (
        <button
          type="button"
          onClick={() => onJump(selected.node.workId!)}
          style={{
            marginTop: 8, fontSize: 10, background: "none",
            border: "1px solid var(--border)", borderRadius: 4,
            color: "var(--text-dim)", padding: "2px 8px", cursor: "pointer",
          }}
          title="Open this work in the editor"
        >
          open “{nodeTitle(selected.node)}” →
        </button>
      )}
    </div>
  );
}
