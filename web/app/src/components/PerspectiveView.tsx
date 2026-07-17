import { useState, useEffect, useRef, useMemo, useCallback } from "react";
import type { LinkEntry, WorkListEntry } from "../api/crdt_sync";

const BRIDGE_COLORS = [
  "#d29922", "#56b4e9", "#009e73", "#cc79a7",
  "#f0e442", "#e69f00", "#0072b2", "#d55e00",
];

interface NeighborDoc {
  workId: number;
  title: string;
  text: string;
  links: LinkEntry[];
}

interface PerspectiveViewProps {
  centerWorkId: number;
  centerText: string;
  centerTitle: string;
  links: LinkEntry[];
  works: WorkListEntry[];
  onClose: () => void;
  onNavigateToWork: (workId: number) => void;
  onFetchWorkText?: (workId: number) => Promise<string | null>;
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function renderTextWithSpans(text: string, spans: Array<{ start: number; end: number; linkId: number; color: string }>, idPrefix: string): string {
  if (spans.length === 0) return escapeHtml(text);
  const sorted = [...spans].sort((a, b) => a.start - b.start);
  let html = "";
  let pos = 0;
  for (const span of sorted) {
    if (span.start < pos) continue;
    if (span.start > pos) html += escapeHtml(text.slice(pos, span.start));
    html += `<span id="${idPrefix}${span.linkId}" style="background:${span.color}30;border-bottom:2px solid ${span.color}">`;
    html += escapeHtml(text.slice(span.start, Math.min(span.end, text.length)));
    html += "</span>";
    pos = Math.max(pos, span.end);
  }
  if (pos < text.length) html += escapeHtml(text.slice(pos));
  return html;
}

export function PerspectiveView({
  centerWorkId,
  centerText,
  centerTitle,
  links,
  works,
  onClose,
  onNavigateToWork,
  onFetchWorkText,
}: PerspectiveViewProps) {
  const [zoom, setZoom] = useState(0);
  const [selectedLink] = useState<number | null>(null);
  const [neighborTexts, setNeighborTexts] = useState<Map<number, string>>(new Map());
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const docRefs = useRef<Map<number, HTMLDivElement>>(new Map());

  const allLinks = useMemo(() => links, [links]);

  const neighbors = useMemo<NeighborDoc[]>(() => {
    const neighborMap = new Map<number, NeighborDoc>();
    for (const link of allLinks) {
      const isOrigin = link.origin === centerWorkId;
      const otherWorkId = isOrigin ? link.destination : link.origin;
      if (otherWorkId === centerWorkId) continue;
      if (!neighborMap.has(otherWorkId)) {
        const title = (isOrigin ? link.destination_title : link.origin_title) ||
          works.find((w) => w.work_id === otherWorkId)?.title ||
          `Work ${otherWorkId.toString(16)}`;
        const ref = isOrigin ? link.destination_ref : link.origin_ref;
        const fullText = neighborTexts.get(otherWorkId) || ref?.excerpt || "";
        const text = fullText.length > 800 ? fullText.slice(0, 800) + " \u2026" : fullText;
        neighborMap.set(otherWorkId, { workId: otherWorkId, title, text, links: [] });
      }
      neighborMap.get(otherWorkId)!.links.push(link);
    }
    return Array.from(neighborMap.values()).sort((a, b) => b.links.length - a.links.length);
  }, [allLinks, centerWorkId, works]);

  useEffect(() => {
    if (!onFetchWorkText) return;
    for (const neighbor of neighbors) {
      if (neighborTexts.has(neighbor.workId)) continue;
      onFetchWorkText(neighbor.workId).then((text) => {
        if (text) {
          setNeighborTexts((prev) => new Map(prev).set(neighbor.workId, text));
        }
      }).catch(() => {});
    }
  }, [neighbors, onFetchWorkText, neighborTexts]);

  const centerSpans = useMemo(() => {
    const spans: Array<{ start: number; end: number; linkId: number; color: string }> = [];
    for (let i = 0; i < allLinks.length; i++) {
      const link = allLinks[i];
      const isOrigin = link.origin === centerWorkId;
      const ref = isOrigin ? link.origin_ref : link.destination_ref;
      if (ref && typeof ref.start_position === "number" && typeof ref.end_position === "number" && ref.end_position > ref.start_position) {
        spans.push({
          start: ref.start_position,
          end: ref.end_position,
          linkId: link.link_id,
          color: BRIDGE_COLORS[i % BRIDGE_COLORS.length],
        });
      } else {
        const previewEnd = Math.min(centerText.length, 300);
        spans.push({
          start: 0,
          end: previewEnd,
          linkId: link.link_id,
          color: BRIDGE_COLORS[i % BRIDGE_COLORS.length],
        });
      }
    }
    return spans;
  }, [allLinks, centerWorkId, centerText.length]);

  const linkColorMap = useMemo(() => {
    const m = new Map<number, string>();
    allLinks.forEach((link, i) => m.set(link.link_id, BRIDGE_COLORS[i % BRIDGE_COLORS.length]));
    return m;
  }, [allLinks]);

  const layout = useMemo(() => {
    const maxNeighbors = Math.min(neighbors.length, 4 + zoom * 2);
    const visible = neighbors.slice(0, maxNeighbors);
    return { visible };
  }, [neighbors, zoom]);

  const neighborScale = useCallback((distance: number) => {
    const baseScale = Math.max(0.15, 0.75 - distance * 0.2);
    const zoomMultiplier = 1 + zoom * 0.4;
    return Math.min(1.5, baseScale * zoomMultiplier);
  }, [zoom]);

  const neighborWidth = useCallback((distance: number) => {
    const base = Math.max(8, 24 - distance * 5);
    const zoomBonus = zoom * 4;
    return base + zoomBonus;
  }, [zoom]);

  const drawConnections = useCallback(() => {
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const rect = container.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    canvas.style.width = rect.width + "px";
    canvas.style.height = rect.height + "px";
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, rect.width, rect.height);

    const containerLeft = rect.left;
    const containerTop = rect.top;

    for (const link of allLinks) {
      const color = linkColorMap.get(link.link_id) || "#888";
      const isFocused = selectedLink === link.link_id;

      const centerSpan = document.getElementById(`plink-${link.link_id}`);
      if (!centerSpan) continue;

      const isOrigin = link.origin === centerWorkId;
      const otherWorkId = isOrigin ? link.destination : link.origin;
      const neighborDoc = layout.visible.find((n) => n.workId === otherWorkId);
      if (!neighborDoc) continue;

      const neighborSpan = document.getElementById(`nplink-${link.link_id}`);
      if (!neighborSpan) continue;

      const centerRect = centerSpan.getBoundingClientRect();
      const neighborRect = neighborSpan.getBoundingClientRect();

      const cx = centerRect.left - containerLeft + centerRect.width / 2;
      const cy = centerRect.top - containerTop + centerRect.height / 2;
      const nx = neighborRect.left - containerLeft + neighborRect.width / 2;
      const ny = neighborRect.top - containerTop + neighborRect.height / 2;

      ctx.strokeStyle = isFocused ? color : color + "80";
      ctx.lineWidth = isFocused ? 3 : 1.5;
      ctx.setLineDash(isFocused ? [] : [4, 3]);

      ctx.beginPath();
      ctx.moveTo(cx, cy);
      const midX = (cx + nx) / 2;
      ctx.bezierCurveTo(midX, cy, midX, ny, nx, ny);
      ctx.stroke();
      ctx.setLineDash([]);

      if (isFocused) {
        ctx.fillStyle = color + "30";
        ctx.beginPath();
        ctx.arc(cx, cy, 6, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(nx, ny, 6, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }, [allLinks, linkColorMap, selectedLink, layout.visible]);

  useEffect(() => {
    const handler = () => requestAnimationFrame(drawConnections);
    handler();
    const container = containerRef.current;
    if (container) {
      container.addEventListener("scroll", handler, { passive: true });
      window.addEventListener("resize", handler);
      return () => {
        container.removeEventListener("scroll", handler);
        window.removeEventListener("resize", handler);
      };
    }
  }, [drawConnections]);

  const renderColumn = useCallback(
    (doc: NeighborDoc, _side: "left" | "right", distance: number) => {
      const scale = neighborScale(distance);
      const widthPct = neighborWidth(distance);
      const leftPct = 42 + 2 + (distance - 1) * (widthPct + 2);

      const spans = doc.links.flatMap((link) => {
        const color = linkColorMap.get(link.link_id) || "#888";
        const isOrigin = link.origin === centerWorkId;
        const ref = isOrigin ? link.destination_ref : link.origin_ref;
        if (ref && typeof ref.start_position === "number" && typeof ref.end_position === "number" && ref.end_position > ref.start_position) {
          return [{ start: 0, end: Math.min(ref.end_position - ref.start_position, doc.text.length), linkId: link.link_id, color, hasSpan: true }];
        }
        return [{ start: 0, end: doc.text.length, linkId: link.link_id, color, hasSpan: false }];
      });

      const wholeWorkColors = spans.filter(s => !s.hasSpan).map(s => s.color);

      return (
        <div
          key={doc.workId}
          style={{
            position: "absolute",
            left: `${leftPct}%`,
            top: "48px",
            width: `${widthPct}%`,
            height: "calc(100% - 48px)",
            overflowY: "auto" as const,
            overflowX: "hidden" as const,
            transformStyle: "flat",
            transform: `scale(${scale})`,
            transformOrigin: "top left",
            opacity: Math.max(0.3, 1 - distance * 0.2),
            background: "#faf9f6",
            border: "1px solid #d0d0d0",
            borderLeft: wholeWorkColors.length > 0 ? `4px solid ${wholeWorkColors[0]}` : "1px solid #d0d0d0",
            borderRadius: "6px",
            boxShadow: distance === 1 ? "0 4px 12px rgba(0,0,0,0.25)" : distance === 2 ? "0 2px 8px rgba(0,0,0,0.15)" : "none",
            cursor: "default",
          }}
          onDoubleClick={() => onNavigateToWork(doc.workId)}
          title={`Double-click to focus: ${doc.title}`}
        >
          <div style={{ padding: "8px 6px", fontSize: "14px", fontFamily: "Source Serif 4, Georgia, serif", lineHeight: 1.5, color: "#1a1a24" }}>
            <div style={{
              fontSize: "11px", fontWeight: 700, color: "#fff",
              marginBottom: "6px", fontFamily: "Inter, sans-serif",
              background: "#30363d", padding: "3px 6px", borderRadius: "3px",
              whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
              display: "flex", alignItems: "center", gap: "4px",
            }}>
              <span style={{ flex: 1, overflow: "hidden", textOverflow: "ellipsis" }}>{doc.title}</span>
              <span style={{ fontSize: "9px", color: "#8b949e", flexShrink: 0 }}>{doc.links.length}</span>
            </div>
            {doc.text ? (
              <div
                ref={(el) => { if (el) docRefs.current.set(doc.workId, el); }}
                dangerouslySetInnerHTML={{ __html: renderTextWithSpans(doc.text, spans.filter(s => s.hasSpan).map((s) => ({ ...s, linkId: s.linkId })), "nplink-") }}
              />
            ) : (
              <div style={{ color: "#6e7681", fontSize: "11px", fontStyle: "italic" }}>Loading...</div>
            )}
          </div>
        </div>
      );
    },
    [neighborScale, neighborWidth, linkColorMap, centerWorkId, onNavigateToWork],
  );

  const centerWholeWorkColors = centerSpans.filter(s => {
    const link = allLinks.find(l => l.link_id === s.linkId);
    if (!link) return false;
    const isOrigin = link.origin === centerWorkId;
    const ref = isOrigin ? link.origin_ref : link.destination_ref;
    return !ref || typeof ref.start_position !== "number" || typeof ref.end_position !== "number" || ref.end_position <= ref.start_position;
  }).map(s => s.color);

  const centerColumn = (
    <div
      style={{
        position: "absolute",
        left: "30%",
        top: "32px",
        width: "40%",
        height: "calc(100% - 48px)",
        overflowY: "auto" as const,
        background: "#fff",
        border: "2px solid #d0d0d0",
        borderLeft: centerWholeWorkColors.length > 0 ? `4px solid ${centerWholeWorkColors[0]}` : "2px solid #d0d0d0",
        borderRadius: "6px",
        zIndex: 5,
      }}
    >
      <div style={{ padding: "12px 16px", fontSize: "17px", fontFamily: "Source Serif 4, Georgia, serif", lineHeight: 1.75, color: "#1a1a24" }}>
        <div style={{ fontSize: "12px", fontWeight: 700, color: "#333", marginBottom: "8px", fontFamily: "Inter, sans-serif" }}>
          {centerTitle}
        </div>
          <div
              dangerouslySetInnerHTML={{ __html: renderTextWithSpans(centerText, centerSpans, "plink-") }}
            />
      </div>
    </div>
  );

  return (
    <div style={{ position: "fixed", inset: 0, zIndex: 100, background: "#1a1a24" }}>
      <div style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: "0 16px",
        height: "48px",
        background: "#22222e",
        borderBottom: "1px solid #30363d",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          <span style={{ color: "#c9d1d9", fontSize: "14px", fontWeight: 600 }}>
            Perspective View
          </span>
          <span style={{ color: "#8b949e", fontSize: "12px" }}>
            {neighbors.length} connected document{neighbors.length !== 1 ? "s" : ""}
          </span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
          <button
            type="button"
            onClick={() => setZoom((z) => Math.min(z + 1, 3))}
            style={{
              background: "#30363d", border: "1px solid #484f58", color: "#c9d1d9",
              borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "13px",
            }}
          >
            +
          </button>
          <span style={{ color: "#8b949e", fontSize: "11px", minWidth: "40px", textAlign: "center" }}>
            Zoom {zoom}
          </span>
          <button
            type="button"
            onClick={() => setZoom((z) => Math.max(z - 1, -1))}
            style={{
              background: "#30363d", border: "1px solid #484f58", color: "#c9d1d9",
              borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "13px",
            }}
          >
            -
          </button>
          <button
            type="button"
            onClick={onClose}
            style={{
              background: "#da3633", border: "1px solid #f85149", color: "#fff",
              borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "13px",
              marginLeft: "8px",
            }}
          >
            Close
          </button>
        </div>
      </div>
      <div ref={containerRef} style={{ position: "relative", width: "100%", height: "calc(100% - 48px)", overflowX: "auto", overflowY: "hidden" }}>
        <div style={{ position: "relative", height: "100%", minWidth: "100%" }}>
        {centerColumn}
        {layout.visible.map((doc, i) => renderColumn(doc, "right", i + 1))}
        <canvas
          ref={canvasRef}
          style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 10 }}
        />
        </div>
      </div>
      {neighbors.length > 0 && (
        <div style={{
          position: "absolute", bottom: 0, left: 0, right: 0,
          display: "flex", gap: "12px", alignItems: "center",
          padding: "4px 16px", height: "28px",
          background: "#22222e", borderTop: "1px solid #30363d",
        }}>
          <span style={{ color: "#8b949e", fontSize: "10px", fontFamily: "Inter, sans-serif" }}>Connections:</span>
          {allLinks.slice(0, 8).map((link, i) => {
            const color = BRIDGE_COLORS[i % BRIDGE_COLORS.length];
            const typeId = link.link_types?.[0];
            const typeName = typeId ? ["", "Comment", "Reference", "Disagreement", "Quotation", "See Also", "Web"][typeId] || "Link" : "Link";
            return (
              <span key={link.link_id} style={{ display: "flex", alignItems: "center", gap: "3px" }}>
                <span style={{ width: 8, height: 8, borderRadius: 2, background: color, display: "inline-block" }} />
                <span style={{ color: "#8b949e", fontSize: "10px", fontFamily: "Inter, sans-serif" }}>{typeName}</span>
              </span>
            );
          })}
        </div>
      )}
      {neighbors.length === 0 && (
        <div style={{
          position: "absolute", inset: "48px 0 0 0",
          display: "flex", alignItems: "center", justifyContent: "center",
          color: "#8b949e", fontSize: "16px", fontFamily: "Inter, sans-serif",
        }}>
          No connected documents. Create links to other works to see them here.
        </div>
      )}
    </div>
  );
}
