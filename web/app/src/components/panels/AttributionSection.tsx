import { useState } from "react";
import type { AttributionSpan, AttributionLogStatus } from "../../api/crdt_sync";
import { authorColor } from "../../author-color";

interface AttributionSectionProps {
  attributionSpans: AttributionSpan[];
  attributionLogStatus: AttributionLogStatus | null;
  onOpenFullView?: () => void;
}

export function AttributionSection({ attributionSpans, attributionLogStatus, onOpenFullView }: AttributionSectionProps) {
  const [expanded, setExpanded] = useState(false);

  const totalEnd = attributionSpans.length > 0 ? Math.max(...attributionSpans.map((s) => s.end)) : 0;
  const coveredChars = attributionSpans.reduce((sum, s) => sum + (s.end - s.start), 0);
  const coverage = totalEnd > 0 ? Math.min(100, Math.round((coveredChars / totalEnd) * 100)) : 0;
  const unsignedCount = attributionSpans.filter((s) => !s.signature_valid).length;
  const allSigned = unsignedCount === 0;
  const chainValid = attributionLogStatus?.chain_valid ?? true;
  const hasLog = attributionLogStatus?.has_log ?? false;

  const allOk = coverage >= 99 && allSigned && chainValid;
  const hasIssues = unsignedCount > 0 || !chainValid;

  const statusColor = hasIssues ? "var(--red)" : coverage >= 80 ? "var(--green)" : "var(--amber)";
  const statusLabel = hasIssues
    ? `${unsignedCount > 0 ? `${unsignedCount} unsigned` : "chain broken"}`
    : allOk ? "valid" : `${coverage}%`;

  return (
    <div className="ctx-section">
      <div
        className="ctx-header"
        style={{ cursor: "pointer", userSelect: "none" }}
        onClick={() => setExpanded((e) => !e)}
      >
        <div className="ctx-title">Attribution</div>
        <div style={{ display: "flex", gap: 4, alignItems: "center" }}>
          <span className={`ctx-badge ${hasIssues ? "risk" : allOk ? "ok" : "amber"}`}>
            {statusLabel}
          </span>
          {expanded ? "▾" : "▸"}
        </div>
      </div>
      <div className="coverage-bar">
        <div
          className={`coverage-fill ${hasIssues ? "danger" : coverage < 80 ? "partial" : ""}`}
          style={{ width: `${Math.max(coverage, hasIssues ? 100 : 0)}%`, background: statusColor }}
        />
      </div>
      {hasIssues && !expanded && (
        <div style={{ fontSize: 10, color: "var(--red)", marginTop: 4, fontWeight: 600 }}>
          {unsignedCount > 0 && `${unsignedCount} unsigned span${unsignedCount > 1 ? "s" : ""} — expand to investigate`}
          {!chainValid && " Attribution chain BROKEN — possible tampering detected"}
        </div>
      )}
      {hasLog && !expanded && allOk && (
        <div style={{ fontSize: 10, color: "var(--text-dim)", marginTop: 2 }}>
          {attributionLogStatus!.entry_count} entries . chain valid . SHA-256 + Ed25519
        </div>
      )}
      {expanded && (
        <>
          {hasLog && (
            <div style={{ marginTop: 8, padding: 8, background: "var(--bg-elevated)", borderRadius: 6, fontSize: 11 }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                <span style={{ fontWeight: 600, color: chainValid ? "var(--green)" : "var(--red)" }}>
                  {chainValid ? "Chain valid" : "CHAIN BROKEN"}
                </span>
                <span style={{ color: "var(--text-dim)" }}>
                  {attributionLogStatus!.entry_count} entries . seq #{attributionLogStatus!.last_sequence}
                </span>
              </div>
              <div style={{ color: "var(--text-dim)", fontSize: 10 }}>
                Tamper-evident append-only log. Each entry: SHA-256(prev_hash + entry_json). Seeded from attribution.log.seed.
              </div>
              {onOpenFullView && (
                <button
                  type="button"
                  onClick={onOpenFullView}
                  style={{
                    marginTop: 6,
                    background: "none",
                    border: "1px solid var(--border)",
                    borderRadius: 4,
                    color: "var(--blue)",
                    fontSize: 11,
                    padding: "3px 8px",
                    cursor: "pointer",
                    width: "100%",
                  }}
                >
                  Open full provenance view
                </button>
              )}
            </div>
          )}
          <div style={{ marginTop: 8 }}>
            {attributionSpans.length === 0 && (
              <div style={{ fontSize: 11, color: "var(--text-dim)", fontStyle: "italic" }}>
                No attribution data yet. Make a revision to generate signed spans.
              </div>
            )}
            {attributionSpans.slice(0, 10).map((span, i) => {
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
                  <span className={`attr-sig ${span.signature_valid ? "signed" : "unsigned"}`}>
                    {span.signature_valid ? "ed25519" : "UNSIGNED"}
                  </span>
                  <span className="attr-time">
                    {new Date(span.timestamp * 1000).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
                  </span>
                </div>
              );
            })}
            {attributionSpans.length > 10 && (
              <div style={{ fontSize: 11, color: "var(--text-dim)", padding: "4px 0" }}>
                + {attributionSpans.length - 10} more spans
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
