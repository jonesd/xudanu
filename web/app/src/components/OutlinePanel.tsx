import { useMemo, useState, useCallback, useRef } from "react";
import { TextBuffer } from "../api/text_buffer";

interface OutlinePanelProps {
  buffer: TextBuffer;
  onJumpTo: (charOffset: number) => void;
  onMoveSection?: (newText: string) => void;
  onClose: () => void;
}

export function OutlinePanel({ buffer, onJumpTo, onMoveSection, onClose }: OutlinePanelProps) {
  const outline = useMemo(() => buffer.extractOutline(), [buffer]);
  const [dragIdx, setDragIdx] = useState<number | null>(null);
  const [dropIdx, setDropIdx] = useState<number | null>(null);
  const [dropPosition, setDropPosition] = useState<"before" | "after">("after");
  const entryRefs = useRef<(HTMLButtonElement | null)[]>([]);

  const handleDragStart = useCallback((e: React.DragEvent, idx: number) => {
    setDragIdx(idx);
    e.dataTransfer.effectAllowed = "move";
    e.dataTransfer.setData("text/plain", String(idx));
  }, []);

  const handleDragEnd = useCallback(() => {
    setDragIdx(null);
    setDropIdx(null);
  }, []);

  const computeDrop = useCallback(
    (e: React.DragEvent, idx: number) => {
      const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
      const midY = rect.top + rect.height / 2;
      const pos = e.clientY < midY ? "before" : "after";
      setDropIdx(idx);
      setDropPosition(pos);
    },
    [],
  );

  const handleDragOver = useCallback(
    (e: React.DragEvent, idx: number) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = "move";
      if (dragIdx !== null && idx !== dragIdx) {
        computeDrop(e, idx);
      }
    },
    [dragIdx, computeDrop],
  );

  const handleDrop = useCallback(
    (e: React.DragEvent, idx: number) => {
      e.preventDefault();
      if (dragIdx === null || dragIdx === idx || !onMoveSection) {
        setDragIdx(null);
        setDropIdx(null);
        return;
      }

      const fromEntry = outline[dragIdx];
      let targetLine: number;

      if (dropPosition === "before") {
        targetLine = idx === 0 ? -1 : outline[idx - 1].line;
      } else {
        targetLine = outline[idx].line;
      }

      if (targetLine === fromEntry.line) {
        setDragIdx(null);
        setDropIdx(null);
        return;
      }

      const newText = buffer.moveSection(fromEntry.line, targetLine);
      onMoveSection(newText);
      setDragIdx(null);
      setDropIdx(null);
    },
    [dragIdx, dropPosition, outline, buffer, onMoveSection],
  );

  if (outline.length === 0) {
    return (
      <div className="outline-panel">
        <div className="outline-header">
          <span className="outline-title">Outline</span>
          <button className="outline-close" onClick={onClose}>
            ×
          </button>
        </div>
        <div className="outline-empty">No headings found</div>
      </div>
    );
  }

  const renderDropIndicator = (idx: number, position: "before" | "after") => {
    if (dropIdx !== idx || dropPosition !== position || dragIdx === null) return null;
    return <div className="outline-drop-indicator" />;
  };

  return (
    <div className="outline-panel">
      <div className="outline-header">
        <span className="outline-title">Outline</span>
        <span className="outline-count">{outline.length}</span>
        <button className="outline-close" onClick={onClose}>
          ×
        </button>
      </div>
      {dragIdx !== null && (
        <div className="outline-drop-hint">Drop to reorder section</div>
      )}
      <div className="outline-entries">
        {outline.map((entry, i) => (
          <div key={i}>
            {renderDropIndicator(i, "before")}
            <button
              ref={(el) => { entryRefs.current[i] = el; }}
              className={`outline-entry level-${entry.level}${dragIdx === i ? " dragging" : ""}${dropIdx === i ? " drop-target" : ""}`}
              onClick={() => onJumpTo(entry.charOffset)}
              draggable={!!onMoveSection}
              onDragStart={(e) => handleDragStart(e, i)}
              onDragEnd={handleDragEnd}
              onDragOver={(e) => handleDragOver(e, i)}
              onDrop={(e) => handleDrop(e, i)}
            >
              <span className="outline-entry-text">{entry.text}</span>
              <span className="outline-entry-line">:{entry.line + 1}</span>
            </button>
            {i === outline.length - 1 && renderDropIndicator(i, "after")}
          </div>
        ))}
      </div>
    </div>
  );
}
