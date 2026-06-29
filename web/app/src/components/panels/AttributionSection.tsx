import type { AttributionSpan } from "../../api/crdt_sync";
import { authorColor } from "../../author-color";

interface AttributionSectionProps {
  attributionSpans: AttributionSpan[];
}

export function AttributionSection({ attributionSpans }: AttributionSectionProps) {
  if (attributionSpans.length === 0) return null;

  const totalEnd = Math.max(...attributionSpans.map((s) => s.end));
  const coveredChars = attributionSpans.reduce((sum, s) => sum + (s.end - s.start), 0);
  const coverage = totalEnd > 0 ? Math.min(100, Math.round((coveredChars / totalEnd) * 100)) : 0;

  const chainValid = attributionSpans.every((s) => s.signature_valid);

  return (
    <div className="ctx-section">
      <div className="ctx-header">
        <div className="ctx-title">Attribution</div>
        <div style={{ display: "flex", gap: 4 }}>
          <span className={`ctx-badge ${coverage >= 80 ? "ok" : "amber"}`}>{coverage}%</span>
          <span className={`ctx-badge ${chainValid ? "ok" : "amber"}`}>
            {chainValid ? "valid" : "check"}
          </span>
        </div>
      </div>
      <div className="coverage-bar">
        <div className={`coverage-fill ${coverage < 80 ? "partial" : ""}`} style={{ width: `${coverage}%` }} />
      </div>
      <div style={{ marginTop: 8 }}>
        {attributionSpans.slice(0, 5).map((span, i) => {
          const name = span.author_display_name || "unknown";
          const color = span.author_type === "historical"
            ? "#c4a35a"
            : span.author_type === "llm"
            ? "#7c4dff"
            : authorColor(name);
          return (
            <div key={i} className="attr-row">
              <span className="attr-range">[{span.start}..{span.end}]</span>
              <div className="attr-author-dot" style={{ background: color }} />
              <span style={{ fontWeight: 500, fontSize: 12 }}>{name}</span>
              {span.source_work_id != null && (
                <span className="attr-source">via work</span>
              )}
              <span className={`attr-sig ${span.signature_valid ? "signed" : "server"}`}>
                {span.signature_valid ? "ed25519" : "stamped"}
              </span>
              <span className="attr-time">
                {new Date(span.timestamp * 1000).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
              </span>
            </div>
          );
        })}
        {attributionSpans.length > 5 && (
          <div style={{ fontSize: 11, color: "var(--text-dim)", padding: "4px 0" }}>
            + {attributionSpans.length - 5} more spans
          </div>
        )}
      </div>
    </div>
  );
}
