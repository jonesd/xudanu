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
  onFetchSourceText?: (workId: number) => Promise<string | null>;
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
  searchTerm?: string,
): string {
  if (spans.length === 0) {
    let html = escapeHtml(text);
    if (searchTerm) html = highlightSearch(html, searchTerm);
    return html;
  }
  const sorted = [...spans].sort((a, b) => a.flat_start - b.flat_start);
  let html = "";
  let pos = 0;
  for (let i = 0; i < sorted.length; i++) {
    const span = sorted[i];
    const start = span.flat_start;
    const end = Math.min(span.flat_end, text.length);
    if (start < pos) continue;
    if (start > pos) {
      let chunk = escapeHtml(text.slice(pos, start));
      if (searchTerm) chunk = highlightSearch(chunk, searchTerm);
      html += chunk;
    }
    const title = sourceTitles[span.source_work_id] || `Work ${span.source_work_id.toString(16)}`;
    const color = BRIDGE_COLORS[i % BRIDGE_COLORS.length];
    const changedBadge = span.source_changed ? ' <span style="color:#d29922;font-size:10px;">&#x26A0;</span>' : "";
    html += `<span class="cb-transclusion-span" style="background:${color}20;border-left:3px solid ${color};padding-left:4px;margin-left:-4px;" title="From: ${escapeHtml(title)}${span.source_changed ? ' (source changed)' : ''} — click to highlight source" data-span-idx="${i}">`;
    html += escapeHtml(text.slice(start, end));
    html += changedBadge;
    html += `</span>`;
    pos = Math.max(pos, end);
  }
  if (pos < text.length) {
    let chunk = escapeHtml(text.slice(pos));
    if (searchTerm) chunk = highlightSearch(chunk, searchTerm);
    html += chunk;
  }
  return html;
}

function highlightSearch(html: string, term: string): string {
  if (!term || term.length < 2) return html;
  const escaped = term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return html.replace(new RegExp(`(${escaped})`, "gi"), '<mark style="background:#fff3a0;color:inherit;">$1</mark>');
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
  onFetchSourceText,
}: CompoundBuilderProps) {
  void onFetchSourceText;
  const [sources, setSources] = useState<SourceDoc[]>([]);
  const [activeSourceId, setActiveSourceId] = useState<number | null>(null);
  const [selectedText, setSelectedText] = useState<{ start: number; end: number; text: string } | null>(null);
  const [sourceSearch, setSourceSearch] = useState("");
  const [sourceFilter, setSourceFilter] = useState("");
  const [sourceHighlight, setSourceHighlight] = useState(0);
  const [placementMode, setPlacementMode] = useState<"inline" | "block" | "auto">("auto");
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
        const resp = await client.sendRequest("work_get_edition", { work_id: workId });
        const val = (resp as Record<string, unknown>);
        const inner = (val && "value" in val) ? val.value as Record<string, unknown> : val;
        const text = (inner?.text as string) || (inner?.value as string) || "";
        setSources((prev) => prev.map((s) => s.workId === workId ? { ...s, text, loading: false } : s));
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

  const effectiveMode = useMemo(() => {
    if (placementMode !== "auto") return placementMode;
    if (!selectedText) return "inline";
    return selectedText.text.includes("\n") || selectedText.text.length > 100 ? "block" : "inline";
  }, [placementMode, selectedText]);

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
    if (!sources.some((s) => s.workId === workId)) {
      void addSource(workId);
    }
    setActiveSourceId(workId);
  }, [sources, addSource]);

  const handleEDLExport = useCallback(() => {
    const sorted = [...compoundSpanRanges].sort((a, b) => a.flat_start - b.flat_start);
    const entries: Array<Record<string, unknown>> = [];
    let pos = 0;
    for (const span of sorted) {
      if (span.flat_start > pos) {
        entries.push({ type: "text", content: centerText.slice(pos, span.flat_start) });
      }
      const title = compoundSourceTitles[span.source_work_id] || `Work ${span.source_work_id.toString(16)}`;
      entries.push({
        type: "transclusion",
        source_work_id: `0x${span.source_work_id.toString(16)}`,
        source_title: title,
        char_start: span.char_start,
        char_end: span.char_end,
        resolved_text: span.resolved_content || centerText.slice(span.flat_start, span.flat_end),
        source_changed: span.source_changed || false,
      });
      pos = Math.max(pos, span.flat_end);
    }
    if (pos < centerText.length) {
      entries.push({ type: "text", content: centerText.slice(pos) });
    }
    const edl = { version: 2, title: centerTitle, work_id: `0x${centerWorkId.toString(16)}`, entries };
    const blob = new Blob([JSON.stringify(edl, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${centerTitle.replace(/[^a-z0-9]/gi, "_").toLowerCase()}_edl.json`;
    a.click();
    URL.revokeObjectURL(url);
  }, [compoundSpanRanges, centerText, centerTitle, centerWorkId, compoundSourceTitles]);

  const structure = useMemo(() => {
    const items: Array<{ type: "original" | "transclusion"; label: string; preview: string; changed?: boolean; origin?: string }> = [];
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
      const origin = sourceOriginMap.get(span.source_work_id);
      const preview = span.resolved_content?.slice(0, 60) || centerText.slice(span.flat_start, Math.min(span.flat_end, span.flat_start + 60));
      items.push({ type: "transclusion", label: title, preview, changed: span.source_changed, origin });
      pos = Math.max(pos, span.flat_end);
    }
    if (pos < centerText.length) {
      items.push({ type: "original", label: "Original", preview: centerText.slice(pos, Math.min(pos + 60, centerText.length)) });
    }
    return items;
  }, [compoundSpanRanges, compoundSourceTitles, centerText]);

  const transclusionSourceIds = useMemo(() => new Set(compoundSpanRanges.map((s) => s.source_work_id)), [compoundSpanRanges]);

  const sourceOriginMap = useMemo(() => {
    const m = new Map<number, string>();
    for (const w of works) {
      if (w.is_source && (w.source_edition_info || w.source_author_id)) {
        const parts: string[] = [];
        if (w.source_edition_info) parts.push(w.source_edition_info);
        m.set(w.work_id, parts.join(" · "));
      }
    }
    return m;
  }, [works]);

  const otherWorks = useMemo(() => {
    const q = sourceFilter.trim().toLowerCase();
    return works
      .filter((w) => w.work_id !== centerWorkId && !sources.some((s) => s.workId === w.work_id))
      .filter((w) => {
        if (!q) return true;
        const title = (w.title || "").toLowerCase();
        const hexId = `0x${w.work_id.toString(16)}`;
        return title.includes(q) || hexId.includes(q) || w.work_id.toString().includes(q);
      })
      .sort((a, b) => {
        const aIsSource = transclusionSourceIds.has(a.work_id) ? 1 : 0;
        const bIsSource = transclusionSourceIds.has(b.work_id) ? 1 : 0;
        if (aIsSource !== bIsSource) return bIsSource - aIsSource;
        return (b.updated_at ?? b.work_id) - (a.updated_at ?? a.work_id);
      });
  }, [works, centerWorkId, sources, sourceFilter, transclusionSourceIds]);
  const activeSource = sources.find((s) => s.workId === activeSourceId);
  const transclusionCount = compoundSpanRanges.length;
  const isEmpty = transclusionCount === 0 && sources.length === 0;

  return (
    <div className="cb-overlay">
      <div className="cb-header">
        <div className="cb-header-left">
          <span className="cb-title">Compound Builder</span>
          <span className="cb-doc-title">{centerTitle}</span>
          {transclusionCount > 0 && (
            <span className="cb-count-badge">{transclusionCount} transclusion{transclusionCount !== 1 ? "s" : ""}</span>
          )}
        </div>
        <div className="cb-header-actions">
          {selectedText && (
            <>
              <div className="cb-mode-toggle">
                <button type="button" className={effectiveMode === "inline" ? "active" : ""} onClick={() => setPlacementMode("inline")} title="Place within paragraph flow">Inline</button>
                <button type="button" className={effectiveMode === "block" ? "active" : ""} onClick={() => setPlacementMode("block")} title="Place on its own line">Block</button>
              </div>
              <button type="button" className="cb-btn-primary" onClick={handleInclude}>
                Include passage ({effectiveMode})
              </button>
            </>
          )}
          <button type="button" className="cb-btn-secondary" onClick={handleEDLExport} title="Export as Edit Decision List JSON">Export</button>
          <button type="button" className="cb-btn-primary" onClick={onClose}>Done</button>
        </div>
      </div>

      <div className="cb-body">
        {/* Left: Source Pool */}
        <div className="cb-source-panel">
          <div className="cb-panel-header">Sources</div>
          <div className="cb-source-list">
            {sources.length === 0 && !sourceFilter && (
              <div className="cb-source-empty">
                No sources yet.
                <br />Search below to start building.
              </div>
            )}
            {sources.map((src, i) => {
              const color = BRIDGE_COLORS[i % BRIDGE_COLORS.length];
              return (
                <div
                  key={src.workId}
                  className={`cb-source-item ${activeSourceId === src.workId ? "active" : ""}`}
                  onClick={() => setActiveSourceId(src.workId)}
                >
                  <span className="cb-source-dot" style={{ background: color }} />
                  <span className="cb-source-name">{src.title}</span>
                  {src.loading && <span className="cb-source-loading">loading...</span>}
                  <button type="button" className="cb-source-remove" onClick={(e) => { e.stopPropagation(); removeSource(src.workId); }} title="Remove source">&times;</button>
                </div>
              );
            })}
          </div>
          {/* Search to add source — OUTSIDE scroll container so dropdown isn't clipped */}
          <div className="cb-add-source-wrap">
            <input
              type="text"
              className="cb-source-search"
              placeholder="Search to add source..."
              value={sourceFilter}
              onChange={(e) => { setSourceFilter(e.target.value); setSourceHighlight(0); }}
              onKeyDown={(e) => {
                if (e.key === "ArrowDown") { e.preventDefault(); setSourceHighlight((h) => Math.min(h + 1, Math.min(otherWorks.length, 20) - 1)); }
                else if (e.key === "ArrowUp") { e.preventDefault(); setSourceHighlight((h) => Math.max(h - 1, 0)); }
                else if (e.key === "Enter") { e.preventDefault(); const w = otherWorks[sourceHighlight]; if (w) { void addSource(w.work_id); setSourceFilter(""); } }
                else if (e.key === "Escape") { setSourceFilter(""); }
              }}
            />
            {sourceFilter && otherWorks.length > 0 && (
              <div className="cb-add-source-results">
                {otherWorks.slice(0, 20).map((w, idx) => (
                  <div
                    key={w.work_id}
                    className={`cb-add-source-item ${idx === sourceHighlight ? "highlighted" : ""}`}
                    onMouseEnter={() => setSourceHighlight(idx)}
                    onClick={() => { void addSource(w.work_id); setSourceFilter(""); }}
                  >
                    <span className="cb-source-name">
                      {transclusionSourceIds.has(w.work_id) && <span className="cb-source-tag" title="Already a transclusion source">T</span>}
                      {w.title || `Work 0x${w.work_id.toString(16)}`}
                    </span>
                    <span className="cb-source-id">0x{w.work_id.toString(16)}</span>
                  </div>
                ))}
                {otherWorks.length > 20 && <div className="cb-add-source-more">+ {otherWorks.length - 20} more — refine search</div>}
              </div>
            )}
            {sourceFilter && otherWorks.length === 0 && (
              <div className="cb-add-source-no-results">No matching documents</div>
            )}
          </div>
          {/* Active source text */}
          {activeSource && (
            <div className="cb-source-reader">
              <div className="cb-source-reader-header">
                <input
                  type="text"
                  className="cb-source-search"
                  placeholder="Search in source..."
                  value={sourceSearch}
                  onChange={(e) => setSourceSearch(e.target.value)}
                />
              </div>
              <div
                id="compound-source-text"
                ref={sourceTextRef}
                onMouseUp={handleSourceTextSelection}
                className="cb-source-text"
                dangerouslySetInnerHTML={{
                  __html: sourceSearch
                    ? highlightSearch(escapeHtml(activeSource.text), sourceSearch)
                    : escapeHtml(activeSource.text),
                }}
              />
              {!activeSource.loading && activeSource.text.length > 10000 && (
                <div className="cb-source-truncated">
                  Showing first 10K characters of {activeSource.text.length.toLocaleString()}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Center: Compound Document */}
        <div className="cb-compound-panel">
          {isEmpty ? (
            <div className="cb-welcome">
              <h2>Build a document from transclusions</h2>
              <ol>
                <li><strong>Add a source</strong> — in the left panel, search for a document and click to add it</li>
                <li><strong>Select text</strong> — highlight a passage in the source reader (left panel, below sources)</li>
                <li><strong>Include passage</strong> — click the green button at the top to transclude it into this document</li>
                <li><strong>Repeat</strong> — add more sources and build your compound document</li>
              </ol>
              <p className="cb-welcome-hint">
                Transcluded content maintains its link to the source.
                If the original is edited, you&apos;ll see a warning here.
              </p>
            </div>
          ) : (
            <div
              className="cb-compound-doc"
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
              <div className="cb-compound-title">{centerTitle}</div>
              <div
                className="cb-compound-text"
                dangerouslySetInnerHTML={{ __html: renderCompoundText(centerText, compoundSpanRanges, compoundSourceTitles) }}
              />
            </div>
          )}
        </div>

        {/* Right: Structure Outline */}
        <div className="cb-structure-panel">
          <div className="cb-panel-header">Structure</div>
          <div className="cb-structure-list">
            {structure.map((item, i) => (
              <div
                key={i}
                className={`cb-structure-item ${item.type}`}
                onClick={() => {
                  const el = document.querySelector(".cb-compound-text");
                  if (el) {
                    const spans = el.querySelectorAll("[data-span-idx]");
                    if (item.type === "transclusion" && spans[i]) {
                      (spans[i] as HTMLElement).scrollIntoView({ behavior: "smooth", block: "center" });
                    }
                  }
                }}
              >
                <div className="cb-structure-num">
                  {item.type === "transclusion" ? "\u21D7" : "\u00B7"} {item.label}
                  {item.changed && <span className="cb-changed-badge" title="Source edited">&#x26A0;</span>}
                </div>
                {item.origin && <div className="cb-structure-origin" title={item.origin}>{item.origin}</div>}
                <div className="cb-structure-preview">{item.preview}</div>
              </div>
            ))}
          </div>
          <div className="cb-structure-footer">
            {structure.filter((s) => s.type === "transclusion").length} transclusion(s),
            {" "}{structure.filter((s) => s.type === "original").length} original section(s)
          </div>
        </div>
      </div>
    </div>
  );
}
