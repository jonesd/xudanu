import { useState, useCallback, useMemo, useRef, useEffect } from "react";
import type { CrdtSyncClient, WorkListEntry, SpanRangePayload } from "../api/crdt_sync";

interface CompoundBuilderProps {
  centerWorkId: number;
  centerText: string;
  centerTitle: string;
  compoundSpanRanges: SpanRangePayload[];
  compoundSourceTitles: Record<number, string>;
  works: WorkListEntry[];
  client: CrdtSyncClient | null;
  onClose: () => void;
  onPlaceTransclusion: (sourceWorkId: number, sourceWorkTitle: string, start: number, end: number, text: string) => void;
  onReloadCompound: () => void;
}

interface SourceDoc {
  workId: number;
  title: string;
  text: string;
  loading: boolean;
}

const BRIDGE_COLORS = [
  "#d29922", "#56b4e9", "#009e73", "#cc79a7",
  "#f0e442", "#e69f00", "#0072b2", "#d55e00",
];

function escapeHtml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

function renderCompoundText(
  text: string,
  spans: SpanRangePayload[],
  sourceTitles: Record<number, string>,
): string {
  if (spans.length === 0) return escapeHtml(text);
  const sorted = [...spans].sort((a, b) => a.flat_start - b.flat_start);
  let html = "";
  let pos = 0;
  for (let i = 0; i < sorted.length; i++) {
    const span = sorted[i];
    const start = span.flat_start;
    const end = Math.min(span.flat_end, text.length);
    if (start < pos) continue;
    if (start > pos) html += escapeHtml(text.slice(pos, start));
    const title = sourceTitles[span.source_work_id] || `Work ${span.source_work_id.toString(16)}`;
    const color = BRIDGE_COLORS[i % BRIDGE_COLORS.length];
    html += `<span style="background:${color}20;border-left:3px solid ${color};padding-left:4px;margin-left:-4px;" title="From: ${escapeHtml(title)} — click to highlight source" data-span-idx="${i}">`;
    html += escapeHtml(text.slice(start, end));
    html += `</span>`;
    pos = Math.max(pos, end);
  }
  if (pos < text.length) html += escapeHtml(text.slice(pos));
  return html;
}

export function CompoundBuilder({
  centerWorkId,
  centerText,
  centerTitle,
  compoundSpanRanges,
  compoundSourceTitles,
  works,
  client,
  onClose,
  onPlaceTransclusion,
  onReloadCompound,
}: CompoundBuilderProps) {
  const [sources, setSources] = useState<SourceDoc[]>([]);
  const [activeSourceId, setActiveSourceId] = useState<number | null>(null);
  const [selectedText, setSelectedText] = useState<{ start: number; end: number; text: string } | null>(null);
  const sourceTextRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    onReloadCompound();
  }, [onReloadCompound]);

  const addSource = useCallback(async (workId: number) => {
    if (sources.some((s) => s.workId === workId)) return;
    const work = works.find((w) => w.work_id === workId);
    const title = work?.title || `Work ${workId.toString(16)}`;
    setSources((prev) => [...prev, { workId, title, text: "", loading: true }]);
    if (client) {
      try {
        const result = await client.textRange(workId, 0, 10_000_000);
        setSources((prev) => prev.map((s) => s.workId === workId ? { ...s, text: result.text, loading: false } : s));
      } catch {
        setSources((prev) => prev.map((s) => s.workId === workId ? { ...s, text: "(failed to load)", loading: false } : s));
      }
    }
  }, [sources, works, client]);

  const removeSource = useCallback((workId: number) => {
    setSources((prev) => prev.filter((s) => s.workId !== workId));
    if (activeSourceId === workId) setActiveSourceId(null);
  }, [activeSourceId]);

  const handleSourceTextSelection = useCallback(() => {
    const sel = window.getSelection();
    if (!sel || sel.isCollapsed || sel.toString().trim().length < 2) {
      setSelectedText(null);
      return;
    }
    const sourceEl = document.getElementById("compound-source-text");
    if (!sourceEl || !sourceEl.contains(sel.anchorNode)) {
      setSelectedText(null);
      return;
    }
    const range = sel.getRangeAt(0);
    const pre = document.createRange();
    pre.selectNodeContents(sourceEl);
    pre.setEnd(range.startContainer, range.startOffset);
    const start = pre.toString().length;
    pre.setEnd(range.endContainer, range.endOffset);
    const end = pre.toString().length;
    setSelectedText({ start, end, text: sel.toString() });
  }, []);

  const handleInclude = useCallback(() => {
    if (!selectedText || activeSourceId === null) return;
    const source = sources.find((s) => s.workId === activeSourceId);
    if (!source) return;
    onPlaceTransclusion(activeSourceId, source.title, selectedText.start, selectedText.end, selectedText.text);
    setSelectedText(null);
    setTimeout(() => onReloadCompound(), 500);
  }, [selectedText, activeSourceId, sources, onPlaceTransclusion, onReloadCompound]);

  const handleTransclusionClick = useCallback((span: SpanRangePayload) => {
    const workId = span.source_work_id;
    setActiveSourceId(workId);
    setTimeout(() => {
      const el = document.getElementById("compound-source-text");
      if (el) {
        el.scrollTo({ top: 0, behavior: "smooth" });
      }
    }, 300);
  }, []);

  const handleEDLExport = useCallback(() => {
    const sorted = [...compoundSpanRanges].sort((a, b) => a.flat_start - b.flat_start);
    const entries: Array<Record<string, unknown>> = [];
    let pos = 0;
    for (const span of sorted) {
      if (span.flat_start > pos) {
        entries.push({
          type: "text",
          content: centerText.slice(pos, span.flat_start),
        });
      }
      const title = compoundSourceTitles[span.source_work_id] || `Work ${span.source_work_id.toString(16)}`;
      entries.push({
        type: "transclusion",
        source_work_id: `0x${span.source_work_id.toString(16)}`,
        source_title: title,
        char_start: span.char_start,
        char_end: span.char_end,
        resolved_text: span.resolved_content || centerText.slice(span.flat_start, span.flat_end),
      });
      pos = Math.max(pos, span.flat_end);
    }
    if (pos < centerText.length) {
      entries.push({ type: "text", content: centerText.slice(pos) });
    }
    const edl = {
      version: 1,
      title: centerTitle,
      work_id: `0x${centerWorkId.toString(16)}`,
      entries,
    };
    const blob = new Blob([JSON.stringify(edl, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${centerTitle.replace(/[^a-z0-9]/gi, "_").toLowerCase()}_edl.json`;
    a.click();
    URL.revokeObjectURL(url);
  }, [compoundSpanRanges, centerText, centerTitle, centerWorkId, compoundSourceTitles]);

  const structure = useMemo(() => {
    const items: Array<{ type: "original" | "transclusion"; label: string; preview: string }> = [];
    if (compoundSpanRanges.length === 0) {
      items.push({ type: "original", label: "Original", preview: centerText.slice(0, 60) });
      return items;
    }
    const sorted = [...compoundSpanRanges].sort((a, b) => a.flat_start - b.flat_start);
    let pos = 0;
    for (let i = 0; i < sorted.length; i++) {
      const span = sorted[i];
      if (span.flat_start > pos) {
        items.push({ type: "original", label: "Original", preview: centerText.slice(pos, Math.min(pos + 60, span.flat_start)) });
      }
      const title = compoundSourceTitles[span.source_work_id] || `Work ${span.source_work_id.toString(16)}`;
      const preview = span.resolved_content?.slice(0, 60) || centerText.slice(span.flat_start, Math.min(span.flat_end, span.flat_start + 60));
      items.push({ type: "transclusion", label: `From: ${title}`, preview });
      pos = Math.max(pos, span.flat_end);
    }
    if (pos < centerText.length) {
      items.push({ type: "original", label: "Original", preview: centerText.slice(pos, Math.min(pos + 60, centerText.length)) });
    }
    return items;
  }, [compoundSpanRanges, compoundSourceTitles, centerText]);

  const otherWorks = works.filter((w) => w.work_id !== centerWorkId && !sources.some((s) => s.workId === w.work_id));

  const activeSource = sources.find((s) => s.workId === activeSourceId);

  return (
    <div style={{ position: "fixed", inset: 0, zIndex: 100, background: "#1a1a24", display: "flex", flexDirection: "column" }}>
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 16px", height: "48px", background: "#22222e", borderBottom: "1px solid #30363d", flexShrink: 0,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          <span style={{ color: "#c9d1d9", fontSize: "14px", fontWeight: 600 }}>Compound Builder</span>
          <span style={{ color: "#8b949e", fontSize: "12px" }}>{centerTitle}</span>
        </div>
        <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
          {selectedText && (
            <button type="button" onClick={handleInclude}
              style={{ background: "#238636", border: "1px solid #2ea043", color: "#fff",
                borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "13px" }}>
              Include passage
            </button>
          )}
          <button type="button" onClick={handleEDLExport}
            style={{ background: "var(--bg-surface)", border: "1px solid var(--border)", color: "var(--text-muted)",
              borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "12px" }}>
            Export EDL
          </button>
          <button type="button" onClick={onClose}
            style={{ background: "#238636", border: "1px solid #2ea043", color: "#fff",
              borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "13px" }}>
            Done
          </button>
        </div>
      </div>

      <div style={{ display: "flex", flex: 1, minHeight: 0 }}>
        {/* Left: Source Pool */}
        <div style={{ width: "300px", borderRight: "1px solid #30363d", display: "flex", flexDirection: "column", background: "#22222e" }}>
          <div style={{ padding: "8px 12px", borderBottom: "1px solid #30363d" }}>
            <span style={{ color: "#8b949e", fontSize: "11px", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em" }}>Sources</span>
          </div>
          <div style={{ flex: 1, overflowY: "auto", padding: "4px" }}>
            {sources.map((src) => (
              <div key={src.workId}
                style={{
                  padding: "6px 8px", marginBottom: "2px", borderRadius: "4px", cursor: "pointer",
                  background: activeSourceId === src.workId ? "#30363d" : "transparent",
                  border: activeSourceId === src.workId ? "1px solid #484f58" : "1px solid transparent",
                }}
                onClick={() => setActiveSourceId(src.workId)}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <span style={{ color: "#c9d1d9", fontSize: "12px", fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", flex: 1 }}>
                    {src.title}
                  </span>
                  <button type="button" onClick={(e) => { e.stopPropagation(); removeSource(src.workId); }}
                    style={{ background: "none", border: "none", color: "#6e7681", cursor: "pointer", fontSize: "14px", marginLeft: "4px", padding: "0" }}>
                    {"\u00d7"}
                  </button>
                </div>
                {src.loading && <span style={{ color: "#6e7681", fontSize: "10px" }}>loading...</span>}
              </div>
            ))}
            {otherWorks.length > 0 && (
              <div style={{ marginTop: "8px" }}>
                <select onChange={(e) => { if (e.target.value) addSource(Number(e.target.value)); e.target.value = ""; }}
                  style={{ width: "100%", background: "#1c1c26", border: "1px solid #30363d", color: "#8b949e",
                    borderRadius: "4px", padding: "4px 8px", fontSize: "11px" }}>
                  <option value="">+ Add source...</option>
                  {otherWorks.map((w) => (
                    <option key={w.work_id} value={w.work_id}>{w.title || `Work ${w.work_id.toString(16)}`}</option>
                  ))}
                </select>
              </div>
            )}
          </div>
          {/* Active source text */}
          {activeSource && (
            <div style={{ borderTop: "1px solid #30363d", flex: 1, overflowY: "auto", minHeight: "200px", background: "#1c1c26" }}>
              <div style={{ padding: "6px 10px", borderBottom: "1px solid #30363d", position: "sticky", top: 0, background: "#1c1c26", zIndex: 1 }}>
                <span style={{ color: "#c9d1d9", fontSize: "11px", fontWeight: 600 }}>{activeSource.title}</span>
                <span style={{ color: "#6e7681", fontSize: "10px", marginLeft: "6px" }}>Select text to include</span>
              </div>
              <div id="compound-source-text" ref={sourceTextRef} onMouseUp={handleSourceTextSelection}
                style={{ padding: "8px 10px", fontSize: "13px", fontFamily: "Source Serif 4, Georgia, serif",
                  lineHeight: 1.6, color: "#c9d9d9", userSelect: "text" }}>
                {activeSource.text}
              </div>
            </div>
          )}
        </div>

        {/* Center: Compound Document */}
        <div style={{ flex: 1, overflowY: "auto", background: "#fff" }}>
          <div
            style={{ maxWidth: "700px", margin: "0 auto", padding: "24px 32px" }}
            onClick={(e) => {
              const target = e.target as HTMLElement;
              const idx = target?.getAttribute?.("data-span-idx");
              if (idx !== null && idx !== undefined) {
                const sorted = [...compoundSpanRanges].sort((a, b) => a.flat_start - b.flat_start);
                const span = sorted[parseInt(idx, 10)];
                if (span) handleTransclusionClick(span);
              }
            }}
          >
            <div style={{ fontSize: "12px", fontWeight: 700, color: "#333", marginBottom: "12px", fontFamily: "Inter, sans-serif" }}>
              {centerTitle}
            </div>
            <div style={{ fontSize: "16px", fontFamily: "Source Serif 4, Georgia, serif", lineHeight: 1.75, color: "#1a1a24", whiteSpace: "pre-wrap" }}
              dangerouslySetInnerHTML={{ __html: renderCompoundText(centerText, compoundSpanRanges, compoundSourceTitles) }} />
          </div>
        </div>

        {/* Right: Structure Outline */}
        <div style={{ width: "260px", borderLeft: "1px solid #30363d", display: "flex", flexDirection: "column", background: "#22222e" }}>
          <div style={{ padding: "8px 12px", borderBottom: "1px solid #30363d" }}>
            <span style={{ color: "#8b949e", fontSize: "11px", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em" }}>Structure</span>
          </div>
          <div style={{ flex: 1, overflowY: "auto", padding: "4px" }}>
            {structure.map((item, i) => (
              <div key={i} style={{
                padding: "6px 8px", marginBottom: "3px", borderRadius: "4px",
                background: item.type === "transclusion" ? "rgba(56,166,255,0.06)" : "transparent",
                borderLeft: item.type === "transclusion" ? "2px solid #38a6ff" : "2px solid transparent",
              }}>
                <div style={{ fontSize: "10px", fontWeight: 600, fontFamily: "Inter, sans-serif",
                  color: item.type === "transclusion" ? "#38a6ff" : "#6e7681", marginBottom: "2px" }}>
                  {i + 1}. {item.type === "transclusion" ? item.label : "Original"}
                </div>
                <div style={{ fontSize: "11px", color: "#8b949e", lineHeight: 1.4,
                  overflow: "hidden", textOverflow: "ellipsis", display: "-webkit-box",
                  WebkitLineClamp: 2, WebkitBoxOrient: "vertical" }}>
                  {item.preview}
                </div>
              </div>
            ))}
          </div>
          <div style={{ padding: "8px 12px", borderTop: "1px solid #30363d" }}>
            <span style={{ color: "#6e7681", fontSize: "10px" }}>
              {structure.filter((s) => s.type === "transclusion").length} transclusion(s),
              {" "}{structure.filter((s) => s.type === "original").length} original section(s)
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
