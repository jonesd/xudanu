import { useMemo } from "react";
import { TextBuffer } from "../api/text_buffer";

interface OutlinePanelProps {
  buffer: TextBuffer;
  onJumpTo: (charOffset: number) => void;
  onClose: () => void;
}

export function OutlinePanel({ buffer, onJumpTo, onClose }: OutlinePanelProps) {
  const outline = useMemo(() => buffer.extractOutline(), [buffer]);

  if (outline.length === 0) {
    return (
      <div className="outline-panel">
        <div className="outline-header">
          <span className="outline-title">Outline</span>
          <button className="outline-close" onClick={onClose}>×</button>
        </div>
        <div className="outline-empty">No headings found</div>
      </div>
    );
  }

  return (
    <div className="outline-panel">
      <div className="outline-header">
        <span className="outline-title">Outline</span>
        <span className="outline-count">{outline.length}</span>
        <button className="outline-close" onClick={onClose}>×</button>
      </div>
      <div className="outline-entries">
        {outline.map((entry, i) => (
          <button
            key={i}
            className={`outline-entry level-${entry.level}`}
            onClick={() => onJumpTo(entry.charOffset)}
          >
            <span className="outline-entry-text">{entry.text}</span>
            <span className="outline-entry-line">:{entry.line + 1}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
