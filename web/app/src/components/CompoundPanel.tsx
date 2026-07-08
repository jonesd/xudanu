import { useState, useEffect, useCallback, useRef } from "react";
import type { CrdtSyncClient, CompoundElementPayload, WorkListEntry } from "../api/crdt_sync";

interface CompoundPanelProps {
  client: CrdtSyncClient | null;
  workBeId: number | null;
  canEdit: boolean;
  sourceTitles: Record<number, string>;
  spanRanges: { source_work_id: number; char_start: number; char_end: number; flat_start: number; flat_end: number }[];
  works?: WorkListEntry[];
  onReload: () => void;
  onInsertElement: (index: number, element: CompoundElementPayload) => Promise<number | null>;
  onRemoveElement: (index: number) => Promise<number | null>;
  onMoveElement: (from: number, to: number) => Promise<number | null>;
  onRemoveTransclusion?: (sourceWorkId: number, charStart: number, charEnd: number) => Promise<boolean>;
  onPullFromWork?: (sourceWorkId: number, charStart: number, charEnd: number, text: string) => Promise<void>;
}

export function CompoundPanel({
  client,
  workBeId,
  canEdit,
  sourceTitles,
  spanRanges,
  works = [],
  onReload,
  onMoveElement,
  onRemoveTransclusion,
  onPullFromWork,
}: CompoundPanelProps) {
  const [elements, setElements] = useState<CompoundElementPayload[]>([]);
  const [resolvedText, setResolvedText] = useState("");
  const [expanded, setExpanded] = useState(true);
  const [pullOpen, setPullOpen] = useState(false);
  const [selectedSourceId, setSelectedSourceId] = useState<number | null>(null);
  const [sourceText, setSourceText] = useState("");
  const [loadingSource, setLoadingSource] = useState(false);
  const [selRange, setSelRange] = useState<{ start: number; end: number; text: string } | null>(null);
  const [inserting, setInserting] = useState(false);
  const previewRef = useRef<HTMLDivElement>(null);

  const loadElements = useCallback(async () => {
    if (!client || workBeId === null) return;
    try {
      const result = await client.resolveInlineTransclusions(workBeId);
      if (result.spanRanges && result.spanRanges.length > 0) {
        const inlineElements: CompoundElementPayload[] = result.spanRanges.map((sr) => ({
          type: "span" as const,
          source_work_id: sr.source_work_id,
          char_start: sr.char_start,
          char_end: sr.char_end,
        }));
        setElements(inlineElements);
      } else {
        const edition = await client.compoundGetEdition(workBeId);
        if (edition && edition.elements) {
          setElements(edition.elements);
        } else {
          setElements([]);
        }
      }
      setResolvedText(result.text || "");
    } catch {
      // expected during transitions
    }
  }, [client, workBeId]);

  useEffect(() => {
    loadElements();
  }, [loadElements, spanRanges]);

  const handleRemove = useCallback(async (index: number) => {
    const elem = elements[index];
    if (!elem) return;
    if (elem.type === "span" && onRemoveTransclusion) {
      await onRemoveTransclusion(elem.source_work_id, elem.char_start, elem.char_end);
    }
    await loadElements();
    onReload();
  }, [onRemoveTransclusion, elements, loadElements, onReload]);

  const handleMoveUp = useCallback(async (index: number) => {
    if (index === 0) return;
    await onMoveElement(index, index - 1);
    await loadElements();
    onReload();
  }, [onMoveElement, loadElements, onReload]);

  const handleMoveDown = useCallback(async (index: number) => {
    if (index >= elements.length - 1) return;
    await onMoveElement(index, index + 1);
    await loadElements();
    onReload();
  }, [onMoveElement, loadElements, onReload, elements.length]);

  const handleSelectSource = useCallback(async (workId: number) => {
    if (!client) return;
    setSelectedSourceId(workId);
    setSourceText("");
    setSelRange(null);
    setLoadingSource(true);
    try {
      const result = await client.resolveInlineTransclusions(workId);
      setSourceText(result.text || "");
    } catch {
      setSourceText("");
    }
    setLoadingSource(false);
  }, [client]);

  const handlePreviewMouseUp = useCallback(() => {
    const preview = previewRef.current;
    if (!preview) return;
    const sel = window.getSelection();
    if (!sel || sel.isCollapsed || sel.toString().length === 0) {
      setSelRange(null);
      return;
    }
    const selectedText = sel.toString();
    const fullText = preview.textContent || "";
    const range = sel.getRangeAt(0);
    const preRange = document.createRange();
    preRange.selectNodeContents(preview);
    preRange.setEnd(range.startContainer, range.startOffset);
    const start = preRange.toString().length;
    const end = start + selectedText.length;
    if (start < end && start >= 0 && end <= fullText.length) {
      setSelRange({ start, end, text: selectedText });
    } else {
      setSelRange(null);
    }
  }, []);

  const handleInsertPull = useCallback(async () => {
    if (!selRange || selectedSourceId === null || !onPullFromWork) return;
    setInserting(true);
    try {
      await onPullFromWork(selectedSourceId, selRange.start, selRange.end, selRange.text);
      await loadElements();
      onReload();
      setSelRange(null);
      window.getSelection()?.removeAllRanges();
    } catch (e) {
      console.error("Pull insert failed:", e);
    }
    setInserting(false);
  }, [selRange, selectedSourceId, onPullFromWork, loadElements, onReload]);

  const availableWorks = works.filter((w) => w.work_id !== workBeId);

  if (elements.length === 0 && !canEdit) return null;

  return (
    <div className="compound-panel">
      <div className="compound-panel-header" onClick={() => setExpanded((e) => !e)}>
        <span className="sidebar-collapsible-arrow">{expanded ? "\u25BE" : "\u25B8"}</span>
        <span style={{ fontWeight: 600, fontSize: 13 }}>Compound Structure ({elements.length} elements)</span>
      </div>
      {expanded && (
        <div className="compound-panel-body">
          {resolvedText && (
            <div style={{ marginBottom: 8, padding: "6px 8px", background: "#f5f5f5", borderRadius: 4, fontSize: 12, color: "#666", maxHeight: 100, overflow: "auto" }}>
              <strong>Resolved:</strong> {resolvedText.slice(0, 200)}{resolvedText.length > 200 ? "\u2026" : ""}
            </div>
          )}
          {elements.map((elem, i) => (
            <div key={i} className="compound-element-row">
              <span className="compound-element-index">{i}</span>
              {elem.type === "text" ? (
                <span className="compound-element-text" title={elem.content}>
                  {"\""}{elem.content.slice(0, 60)}{elem.content.length > 60 ? "\u2026" : ""}{"\""}
                </span>
              ) : (
                <span className="compound-element-span">
                  <span className="compound-source-badge">
                    {sourceTitles[elem.source_work_id] || `work-${elem.source_work_id.toString(16).slice(-4)}`}
                  </span>
                  <span className="compound-span-range">
                    [{elem.char_start}:{elem.char_end}]
                  </span>
                </span>
              )}
              {canEdit && (
                <span className="compound-element-actions">
                  <button type="button" className="compound-btn" onClick={() => handleMoveUp(i)} disabled={i === 0} title="Move up">{"\u2191"}</button>
                  <button type="button" className="compound-btn" onClick={() => handleMoveDown(i)} disabled={i === elements.length - 1} title="Move down">{"\u2193"}</button>
                  <button type="button" className="compound-btn compound-btn-del" onClick={() => handleRemove(i)} title="Remove">{"\u00D7"}</button>
                </span>
              )}
            </div>
          ))}
          {elements.length === 0 && (
            <div className="compound-empty-hint">
              No transclusions yet. Use "Pull from document" below to add content from other works.
            </div>
          )}

          {canEdit && onPullFromWork && availableWorks.length > 0 && (
            <div className="compound-pull-section">
              <button
                type="button"
                className="compound-pull-toggle"
                onClick={() => setPullOpen((o) => !o)}
              >
                {pullOpen ? "\u25BE" : "\u25B8"} {"\u2192"} Pull from document
              </button>
              {pullOpen && (
                <div className="compound-pull-body">
                  <select
                    className="compound-pull-select"
                    value={selectedSourceId ?? ""}
                    onChange={(e) => {
                      const v = parseInt(e.target.value, 10);
                      if (!isNaN(v)) handleSelectSource(v);
                    }}
                  >
                    <option value="">Select a document...</option>
                    {availableWorks.map((w) => (
                      <option key={w.work_id} value={w.work_id}>
                        {w.title || "Untitled"} ({w.work_id.toString(16).padStart(4, "0")})
                      </option>
                    ))}
                  </select>
                  {loadingSource && <div className="compound-pull-loading">Loading...</div>}
                  {sourceText && !loadingSource && (
                    <>
                      <div
                        ref={previewRef}
                        className="compound-pull-preview"
                        onMouseUp={handlePreviewMouseUp}
                      >
                        {sourceText}
                      </div>
                      {selRange && (
                        <div className="compound-pull-selected">
                          <div className="compound-pull-selected-text">
                            Selected: {"\""}{selRange.text.slice(0, 80)}{selRange.text.length > 80 ? "\u2026" : ""}{"\""}
                            <span className="compound-pull-range"> [{selRange.start}:{selRange.end}]</span>
                          </div>
                          <button
                            type="button"
                            className="compound-pull-insert"
                            disabled={inserting}
                            onClick={handleInsertPull}
                          >
                            {inserting ? "Inserting..." : "Insert transclusion"}
                          </button>
                        </div>
                      )}
                    </>
                  )}
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
