import { useState } from "react";
import type { AnnotationEntry } from "../api/crdt_sync";

function formatTimestamp(ts: number): string {
  if (!ts) return "";
  try {
    const d = new Date(ts * 1000);
    return d.toLocaleString();
  } catch {
    return "";
  }
}

interface AnnotationPanelProps {
  annotations: AnnotationEntry[];
  onDelete: (annotationId: number) => void;
  onNavigate: (charStart: number) => void;
  currentClubId: number | null;
}

export function AnnotationPanel({ annotations, onDelete, onNavigate, currentClubId: _currentClubId = null }: AnnotationPanelProps) {
  const [expanded, setExpanded] = useState(true);

  if (annotations.length === 0) {
    return (
      <div className="sidebar-collapsible">
        <button
          type="button"
          className="sidebar-collapsible-toggle"
          onClick={() => setExpanded((e) => !e)}
        >
          <span className="sidebar-collapsible-arrow">{expanded ? "\u25BE" : "\u25B8"}</span>
          Annotations (0)
        </button>
        {expanded && (
          <div className="sidebar-collapsible-content">
            <p style={{ opacity: 0.5, fontSize: "0.85em" }}>
              Select text and press Ctrl+Alt+A to annotate.
            </p>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="sidebar-collapsible">
      <button
        type="button"
        className="sidebar-collapsible-toggle"
        onClick={() => setExpanded((e) => !e)}
      >
        <span className="sidebar-collapsible-arrow">{expanded ? "\u25BE" : "\u25B8"}</span>
        Annotations ({annotations.length})
      </button>
      {expanded && (
        <div className="sidebar-collapsible-content">
          {annotations.map((ann) => {
            const authorLabel = ann.created_by_name
              || (ann.created_by != null ? `0x${ann.created_by.toString(16)}` : null)
              || "anonymous";
            const timestamp = formatTimestamp(ann.created_at ?? 0);
            const hoverTitle = timestamp
              ? `Created ${timestamp} by ${authorLabel}`
              : `By ${authorLabel}`;
            return (
              <div
                key={ann.annotation_id}
                title={hoverTitle}
                style={{
                  padding: "6px 8px",
                  marginBottom: "4px",
                  borderLeft: "3px solid rgba(255, 196, 0, 0.6)",
                  background: "rgba(255, 196, 0, 0.06)",
                  cursor: "pointer",
                  fontSize: "0.85em",
                }}
              >
                <div
                  style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}
                  onClick={() => onNavigate(ann.char_start)}
                >
                  <span style={{ fontWeight: 600, color: "#c4960a" }}>
                    {ann.kind || "note"}
                  </span>
                  {ann.is_private && (
                    <span
                      title="Private — only visible to you"
                      style={{
                        fontSize: "0.8em",
                        opacity: 0.5,
                        marginLeft: "4px",
                      }}
                    >
                      {"\u{1F512}"}
                    </span>
                  )}
                  <button
                    type="button"
                    onClick={(e) => { e.stopPropagation(); onDelete(ann.annotation_id); }}
                    style={{
                      background: "none",
                      border: "none",
                      color: "#999",
                      cursor: "pointer",
                      padding: "0 4px",
                      fontSize: "1em",
                    }}
                    title="Delete annotation"
                  >
                    {"\u00D7"}
                  </button>
                </div>
                {ann.payload && (
                  <div style={{ marginTop: "2px", opacity: 0.8, wordBreak: "break-word" }}>
                    {ann.payload}
                  </div>
                )}
                <div style={{ marginTop: "2px", opacity: 0.4, fontSize: "0.9em", display: "flex", justifyContent: "space-between" }}>
                  <span>{authorLabel}</span>
                  <span>
                    {timestamp && <span style={{ marginRight: 6 }}>{timestamp}</span>}
                    chars {ann.char_start}{"\u2013"}{ann.char_end}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
