import { useState, useCallback, useMemo, useRef, useEffect } from "react";
import type { CrdtSyncClient, WorkListEntry, SpanRangePayload, BlobEntry } from "../api/crdt_sync";

interface SourceImage {
  hash: number;
  mime: string;
  width?: number | null;
  height?: number | null;
  caption?: string | null;
  url?: string;
  loading: boolean;
}

interface CompoundBuilderProps {
  centerWorkId: number;
  centerText: string;
  centerTitle: string;
  compoundSpanRanges: SpanRangePayload[];
  compoundSourceTitles: Record<number, string>;
  works: WorkListEntry[];
  client: CrdtSyncClient | null;
  identity?: { display_name: string } | null;
  authenticated?: boolean;
  onClose: () => void;
  onPlaceTransclusion: (sourceWorkId: number, sourceWorkTitle: string, start: number, end: number, text: string) => void;
  onReloadCompound: () => void;
  onFetchSourceText?: (workId: number) => Promise<string | null>;
  onRemoveSpan?: (sourceWorkId: number, charStart: number, charEnd: number) => Promise<boolean>;
}

interface SourceDoc {
  workId: number;
  title: string;
  text: string;
  loading: boolean;
  images: SourceImage[];
}

const BRIDGE_COLORS = [
  "#d29922", "#56b4e9", "#009e73", "#cc79a7",
  "#f0e442", "#e69f00", "#0072b2", "#d55e00",
];

import { escapeHtml } from "../utils/escape";

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
  identity: _identity,
  authenticated: _authenticated,
  onClose,
  onPlaceTransclusion,
  onReloadCompound,
  onRemoveSpan,
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

  // Content preview index: the source picker used to match titles/IDs
  // only, so searching body text found nothing. Index the first ~200
  // chars of each work once (lazily, first search keystroke) and match
  // against them too.
  const [contentIndex, setContentIndex] = useState<Record<number, string> | null>(null);
  const contentIndexStarted = useRef(false);
  const ensureContentIndex = useCallback(() => {
    if (contentIndexStarted.current || !client) return;
    contentIndexStarted.current = true;
    (async () => {
      const idx: Record<number, string> = {};
      const targets = works.filter((w) => w.work_id !== centerWorkId).slice(0, 100);
      const results = await Promise.all(
        targets.map(async (w) => {
          try {
            const resp = await client.sendRequest("work_get_edition", { work_id: w.work_id });
            const val = resp as Record<string, unknown>;
            const inner = (val && "value" in val) ? val.value as Record<string, unknown> : val;
            const text = (inner?.text as string) || "";
            return [w.work_id, text.slice(0, 200)] as const;
          } catch {
            return null;
          }
        }),
      );
      for (const r of results) {
        if (r) idx[r[0]] = r[1];
      }
      setContentIndex(idx);
    })();
  }, [client, works, centerWorkId]);

  const addSource = useCallback(async (workId: number) => {
    if (sources.some((s) => s.workId === workId)) return;
    const work = works.find((w) => w.work_id === workId);
    const title = work?.title || `Work ${workId.toString(16)}`;
    setSources((prev) => [...prev, { workId, title, text: "", loading: true, images: [] }]);
    if (client) {
      try {
        const resp = await client.sendRequest("work_get_edition", { work_id: workId });
        const val = (resp as Record<string, unknown>);
        const inner = (val && "value" in val) ? val.value as Record<string, unknown> : val;
        const text = (inner?.text as string) || (inner?.value as string) || "";
        setSources((prev) => prev.map((s) => s.workId === workId ? { ...s, text, loading: false } : s));

        // Load images from blob store
        try {
          const blobs = await client.workBlobList(workId);
          if (blobs.length > 0) {
            const images: SourceImage[] = blobs.map((b: BlobEntry) => ({
              hash: typeof b.content_hash === "number" ? b.content_hash : 0,
              mime: b.mime_type,
              width: b.width,
              height: b.height,
              caption: b.caption,
              loading: true,
            }));
            setSources((prev) => prev.map((s) => s.workId === workId ? { ...s, images } : s));
            // Load thumbnails
            for (const blob of blobs) {
              const hashU64 = typeof blob.content_hash === "number" ? blob.content_hash : 0;
              client.blobGetPreview(String(hashU64)).then((previewBytes) => {
                const blobObj = new Blob([(previewBytes || new Uint8Array()) as BlobPart], { type: blob.mime_type });
                const url = URL.createObjectURL(blobObj);
                setSources((prev) => prev.map((s) => {
                  if (s.workId !== workId) return s;
                  return { ...s, images: s.images.map((img) => img.hash === hashU64 ? { ...img, url, loading: false } : img) };
                }));
              }).catch(() => {
                client.blobGet(String(hashU64)).then((fullBytes) => {
                  const blobObj = new Blob([fullBytes as BlobPart], { type: blob.mime_type });
                  const url = URL.createObjectURL(blobObj);
                  setSources((prev) => prev.map((s) => {
                    if (s.workId !== workId) return s;
                    return { ...s, images: s.images.map((img) => img.hash === hashU64 ? { ...img, url, loading: false } : img) };
                  }));
                }).catch(() => {
                  setSources((prev) => prev.map((s) => {
                    if (s.workId !== workId) return s;
                    return { ...s, images: s.images.map((img) => img.hash === hashU64 ? { ...img, loading: false } : img) };
                  }));
                });
              });
            }
          }
        } catch { /* blob list might fail for works without images */ }
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

  const sourceOriginMap = useMemo(() => {
    const m = new Map<number, string>();
    for (const w of works) {
      if (w.is_source && (w.source_edition_info || w.source_author_id)) {
        const parts: string[] = [];
        if (w.source_edition_info) parts.push(w.source_edition_info);
        m.set(w.work_id, parts.join(" \u00b7 "));
      }
    }
    return m;
  }, [works]);

  const structure = useMemo(() => {
    const items: Array<{ type: "original" | "transclusion"; label: string; preview: string; changed?: boolean; origin?: string; sectionNum?: number; duplicate?: boolean; span?: SpanRangePayload }> = [];
    if (compoundSpanRanges.length === 0) {
      items.push(
      centerText.trim()
        ? { type: "original", label: "Your text", preview: centerText.slice(0, 60) }
        : { type: "original", label: "Empty", preview: "Include a passage from a source to begin your document" },
    );
      return items;
    }
    const sorted = [...compoundSpanRanges].sort((a, b) => a.flat_start - b.flat_start);
    const seenRanges = new Set<string>();
    let transclusionNum = 0;
    let pos = 0;
    for (let i = 0; i < sorted.length; i++) {
      const span = sorted[i];
      if (span.flat_start > pos) {
        items.push({ type: "original", label: "Your text", preview: centerText.slice(pos, Math.min(pos + 60, span.flat_start)) });
      }
      transclusionNum++;
      const title = compoundSourceTitles[span.source_work_id] || `Work ${span.source_work_id.toString(16)}`;
      const origin = sourceOriginMap.get(span.source_work_id);
      const preview = span.resolved_content?.slice(0, 60) || centerText.slice(span.flat_start, Math.min(span.flat_end, span.flat_start + 60));
      const rangeKey = `${span.source_work_id}:${span.char_start}:${span.char_end}`;
      const duplicate = seenRanges.has(rangeKey);
      seenRanges.add(rangeKey);
      items.push({ type: "transclusion", label: title, preview, changed: span.source_changed, origin, sectionNum: transclusionNum, duplicate, span });
      pos = Math.max(pos, span.flat_end);
    }
    if (pos < centerText.length) {
      items.push({ type: "original", label: "Your text", preview: centerText.slice(pos, Math.min(pos + 60, centerText.length)) });
    }
    return items;
  }, [compoundSpanRanges, compoundSourceTitles, centerText, sourceOriginMap]);

  const stats = useMemo(() => {
    const totalWords = centerText.trim().split(/\s+/).filter(Boolean).length;
    let transcludedWords = 0;
    for (const span of compoundSpanRanges) {
      const content = span.resolved_content || centerText.slice(span.flat_start, span.flat_end);
      transcludedWords += content.trim().split(/\s+/).filter(Boolean).length;
    }
    const sourceCount = new Set(compoundSpanRanges.map((s) => s.source_work_id)).size;
    const percent = totalWords > 0 ? Math.round((transcludedWords / totalWords) * 100) : 0;
    return { totalWords, transcludedWords, originalWords: totalWords - transcludedWords, sourceCount, percent };
  }, [compoundSpanRanges, centerText]);

  const transclusionSourceIds = useMemo(() => new Set(compoundSpanRanges.map((s) => s.source_work_id)), [compoundSpanRanges]);

  const otherWorks = useMemo(() => {
    const q = sourceFilter.trim().toLowerCase();
    return works
      .filter((w) => w.work_id !== centerWorkId && !sources.some((s) => s.workId === w.work_id))
      .filter((w) => {
        if (!q) return true;
        const title = (w.title || "").toLowerCase();
        const hexId = `0x${w.work_id.toString(16)}`;
        if (title.includes(q) || hexId.includes(q) || w.work_id.toString().includes(q)) return true;
        const preview = (contentIndex?.[w.work_id] || "").toLowerCase();
        return preview.includes(q);
      })
      .sort((a, b) => {
        const aIsSource = transclusionSourceIds.has(a.work_id) ? 1 : 0;
        const bIsSource = transclusionSourceIds.has(b.work_id) ? 1 : 0;
        if (aIsSource !== bIsSource) return bIsSource - aIsSource;
        return (b.updated_at ?? b.work_id) - (a.updated_at ?? a.work_id);
      });
  }, [works, centerWorkId, sources, sourceFilter, transclusionSourceIds, contentIndex]);
  const activeSource = sources.find((s) => s.workId === activeSourceId);

  // Memoize source HTML so re-renders (from selectedText state change)
  // don't destroy the DOM and lose the user's text selection
  const sourceHtml = useMemo(() => {
    if (!activeSource) return { __html: "" };
    const html = sourceSearch
      ? highlightSearch(escapeHtml(activeSource.text), sourceSearch)
      : escapeHtml(activeSource.text);
    return { __html: html };
  }, [activeSource?.text, sourceSearch]);

  const transclusionCount = compoundSpanRanges.length;

  return (
    <div className="cb-dock">
      <div className="cb-header">
        <div className="cb-header-left">
          <span className="cb-title">Builder</span>
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
                Include ({effectiveMode})
              </button>
            </>
          )}
          <button type="button" className="cb-btn-secondary" onClick={handleEDLExport} title="Export as Edit Decision List JSON">Export</button>
          <button type="button" className="cb-btn-primary" onClick={onClose}>Done</button>
        </div>
      </div>
      <div className="cb-dock-hint">
        Write your own text in the document (left). Search, read, and quote sources here.
      </div>

      <div className="cb-dock-body">
        {/* Source pool + active source reader */}
        <div className="cb-source-panel cb-dock-sources">
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
              placeholder="Search titles or text…"
              value={sourceFilter}
              onFocus={ensureContentIndex}
              onChange={(e) => { setSourceFilter(e.target.value); setSourceHighlight(0); ensureContentIndex(); }}
              onKeyDown={(e) => {
                if (e.key === "ArrowDown") { e.preventDefault(); setSourceHighlight((h) => Math.min(h + 1, Math.min(otherWorks.length, 20) - 1)); }
                else if (e.key === "ArrowUp") { e.preventDefault(); setSourceHighlight((h) => Math.max(h - 1, 0)); }
                else if (e.key === "Enter") { e.preventDefault(); const w = otherWorks[sourceHighlight]; if (w) { void addSource(w.work_id); setActiveSourceId(w.work_id); setSourceFilter(""); } }
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
                    onClick={() => { void addSource(w.work_id); setActiveSourceId(w.work_id); setSourceFilter(""); }}
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
              <div className="cb-add-source-no-results">
                {contentIndex === null
                  ? "Indexing documents for text search…"
                  : "No matching documents"}
              </div>
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
                onKeyDown={(e) => {
                  if (selectedText && (e.key === "Enter")) {
                    e.preventDefault();
                    handleInclude();
                  }
                }}
                tabIndex={0}
                className="cb-source-text"
                dangerouslySetInnerHTML={sourceHtml}
              />
              {!activeSource.loading && activeSource.text.length > 10000 && (
                <div className="cb-source-truncated">
                  Showing first 10K characters of {activeSource.text.length.toLocaleString()}
                </div>
              )}
              {activeSource.images.length > 0 && (
                <div className="cb-source-images">
                  <div className="cb-source-images-header">Images ({activeSource.images.length})</div>
                  {activeSource.images.map((img, idx) => (
                    <div key={idx} className="cb-source-image-item" title={img.caption || `Image ${idx + 1}`}>
                      {img.loading ? (
                        <div className="cb-image-placeholder">loading...</div>
                      ) : img.url ? (
                        <img src={img.url} alt={img.caption || ""} style={{ maxWidth: "100%", borderRadius: 4 }} />
                      ) : (
                        <div className="cb-image-placeholder">failed to load</div>
                      )}
                      {img.caption && <div className="cb-image-caption">{img.caption}</div>}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Quoted passages (manifest) */}
        <div className="cb-panel-resizer cb-dock-vresizer">
          <span />
        </div>
        <div className="cb-structure-panel cb-dock-structure">
          <div className="cb-panel-header">Quoted passages</div>
          <div className="cb-panel-sub">In document order — click to scroll, × to remove</div>
          <div className="cb-structure-list">
            {structure.map((item, i) => (
              <div
                key={i}
                className={`cb-structure-item ${item.type}`}
                onClick={() => {
                  // Scroll the quoted passage into view in the live
                  // editor (left). Spans are ordered; jump by flat_start.
                  if (item.type === "transclusion" && item.span) {
                    window.history.replaceState(
                      null,
                      "",
                      window.location.pathname + window.location.search + `#C${item.span.flat_start}`,
                    );
                    window.dispatchEvent(new HashChangeEvent("hashchange"));
                  }
                }}
              >
                <div className="cb-structure-num">
                  {item.type === "transclusion" ? `\u00A7${item.sectionNum} \u21D7` : "\u00B7"} {item.label}
                  {item.changed && <span className="cb-changed-badge" title="Source edited">&#x26A0;</span>}
                  {item.duplicate && <span style={{ color: "#f85149", fontSize: 10, marginLeft: 4 }} title="Same passage transcluded elsewhere">(dup)</span>}
                </div>
                {item.origin && <div className="cb-structure-origin" title={item.origin}>{item.origin}</div>}
                <div className="cb-structure-preview">{item.preview}</div>
                {item.type === "transclusion" && item.span && onRemoveSpan && (
                  <button
                    type="button"
                    className="cb-structure-remove"
                    title="Remove this quoted passage (the source document is untouched)"
                    onClick={async (e) => {
                      e.stopPropagation();
                      const span = item.span!;
                      const ok = await onRemoveSpan(span.source_work_id, span.char_start, span.char_end);
                      if (ok) onReloadCompound();
                    }}
                  >
                    &times; remove
                  </button>
                )}
              </div>
            ))}
          </div>
          <div className="cb-structure-footer">
            {stats.totalWords} words ({stats.percent}% transcluded) &middot;
            {" "}from {stats.sourceCount} source{stats.sourceCount !== 1 ? "s" : ""}
          </div>
        </div>
      </div>
    </div>
  );
}
