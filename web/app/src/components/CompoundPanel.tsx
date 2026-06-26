import { useState, useEffect, useCallback } from "react";
import type { CrdtSyncClient, CompoundElementPayload } from "../api/crdt_sync";

interface CompoundPanelProps {
  client: CrdtSyncClient | null;
  workBeId: number | null;
  canEdit: boolean;
  sourceTitles: Record<number, string>;
  spanRanges: { source_work_id: number; char_start: number; char_end: number; flat_start: number; flat_end: number }[];
  onReload: () => void;
  onInsertElement: (index: number, element: CompoundElementPayload) => Promise<number | null>;
  onRemoveElement: (index: number) => Promise<number | null>;
  onMoveElement: (from: number, to: number) => Promise<number | null>;
  onRemoveTransclusion?: (sourceWorkId: number, charStart: number, charEnd: number) => Promise<boolean>;
}

export function CompoundPanel({
  client,
  workBeId,
  canEdit,
  sourceTitles,
  spanRanges,
  onReload,
  onMoveElement,
  onRemoveTransclusion,
}: CompoundPanelProps) {
  const [elements, setElements] = useState<CompoundElementPayload[]>([]);
  const [resolvedText, setResolvedText] = useState("");
  const [expanded, setExpanded] = useState(true);

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
                  <button type="button" className="compound-btn" onClick={() => handleMoveUp(i)} disabled={i === 0} title="Move up">&#8593;</button>
                  <button type="button" className="compound-btn" onClick={() => handleMoveDown(i)} disabled={i === elements.length - 1} title="Move down">&#8595;</button>
                  <button type="button" className="compound-btn compound-btn-del" onClick={() => handleRemove(i)} title="Remove">&#215;</button>
                </span>
              )}
             </div>
          ))}
          {elements.length === 0 && (
            <div className="compound-empty-hint">
              No transclusions. Select text in a source work, then place it here.
            </div>
          )}
        </div>
      )}
    </div>
  );
}
