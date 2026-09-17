import { useState } from "react";
import type { AttributionSpan, AttributionLogStatus } from "../../api/crdt_sync";
import { authorColor } from "../../author-color";

interface AttributionSectionProps {
  attributionSpans: AttributionSpan[];
  attributionLogStatus: AttributionLogStatus | null;
  onOpenFullView?: () => void;
  onExportReport?: () => void;
  onExportProvJson?: () => void;
  onOpenWork?: (workId: number) => void;
  currentWorkId?: number | null;
  documentLength: number;
}

interface ContributingDoc {
  workId: number;
  title: string;
  dominantAuthor: string;
  dominantAuthorType: string | null;
  chars: number;
  spanCount: number;
  firstStart: number;
}

function contributingDocuments(spans: AttributionSpan[]): { docs: ContributingDoc[]; ownChars: number } {
  const byId = new Map<number, ContributingDoc>();
  const authorChars = new Map<number, Map<string, number>>();
  let ownChars = 0;
  for (const span of spans) {
    if (span.source_work_id == null) {
      ownChars += Math.max(0, span.end - span.start);
      continue;
    }
    const id = span.source_work_id;
    const len = Math.max(0, span.end - span.start);
    const name = span.author_display_name || "unknown";
    let entry = byId.get(id);
    if (!entry) {
      entry = {
        workId: id,
        title: span.source_work_title || `#${id}`,
        dominantAuthor: name,
        dominantAuthorType: span.author_type,
        chars: 0,
        spanCount: 0,
        firstStart: span.start,
      };
      byId.set(id, entry);
      authorChars.set(id, new Map());
    }
    entry.chars += len;
    entry.spanCount += 1;
    const ac = authorChars.get(id)!;
    ac.set(name, (ac.get(name) || 0) + len);
  }
  const docs = [...byId.values()];
  for (const doc of docs) {
    const ac = authorChars.get(doc.workId)!;
    let best = doc.dominantAuthor;
    let bestChars = -1;
    for (const [name, chars] of ac) {
      if (chars > bestChars) {
        best = name;
        bestChars = chars;
      }
    }
    doc.dominantAuthor = best;
  }
  docs.sort((a, b) => a.firstStart - b.firstStart);
  return { docs, ownChars };
}

export function AttributionSection({ attributionSpans, attributionLogStatus, onOpenFullView, onExportReport, onExportProvJson, onOpenWork, currentWorkId, documentLength }: AttributionSectionProps) {
  const [expanded, setExpanded] = useState(false);

  const effectiveLength = attributionSpans.length > 0
    ? Math.max(documentLength, attributionSpans.reduce((max, s) => Math.max(max, s.end), 0))
    : documentLength;
  const coveredChars = attributionSpans.reduce((sum, s) => sum + (s.end - s.start), 0);
  const coverage = effectiveLength > 0 ? Math.min(100, Math.round((coveredChars / effectiveLength) * 100)) : 0;
  const unsignedCount = attributionSpans.filter((s) => !s.signature_valid).length;
  const allSigned = unsignedCount === 0;
  const chainValid = attributionLogStatus?.chain_valid ?? true;
  const hasLog = attributionLogStatus?.has_log ?? false;

  const allOk = coverage >= 99 && allSigned && chainValid;
  const hasIssues = unsignedCount > 0 || !chainValid;
  const noData = attributionSpans.length === 0 && !hasLog;

  const statusColor = noData ? "var(--text-dim)" : hasIssues ? "var(--red)" : coverage >= 80 ? "var(--green)" : "var(--amber)";
  const statusLabel = noData
    ? "no data"
    : hasIssues
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
          {attributionSpans.length} attribution span{attributionSpans.length !== 1 ? "s" : ""} . chain valid . SHA-256 + Ed25519
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
                  {attributionSpans.length} attribution span{attributionSpans.length !== 1 ? "s" : ""} . work #{currentWorkId}
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
              {onExportReport && (
                <button
                  type="button"
                  onClick={onExportReport}
                  style={{
                    marginTop: 4,
                    background: "none",
                    border: "1px solid var(--border)",
                    borderRadius: 4,
                    color: "var(--green)",
                    fontSize: 11,
                    padding: "3px 8px",
                    cursor: "pointer",
                    width: "100%",
                  }}
                >
                  Export attestation report
                </button>
              )}
              {onExportProvJson && (
                <button
                  type="button"
                  onClick={onExportProvJson}
                  style={{
                    marginTop: 4,
                    background: "none",
                    border: "1px solid var(--border)",
                    borderRadius: 4,
                    color: "var(--purple, #a371f7)",
                    fontSize: 11,
                    padding: "3px 8px",
                    cursor: "pointer",
                    width: "100%",
                  }}
                >
                  Export PROV-JSON (W3C)
                </button>
              )}
            </div>
          )}
          {(() => {
            const { docs, ownChars } = contributingDocuments(attributionSpans);
            if (docs.length === 0) return null;
            return (
              <div style={{ marginTop: 8, padding: 8, background: "var(--bg-elevated)", borderRadius: 6 }}>
                <div style={{ fontSize: 10, fontWeight: 600, color: "var(--text-dim)", marginBottom: 4, letterSpacing: 0.3 }}>
                  CONTRIBUTING DOCUMENTS — READING ORDER
                </div>
                {ownChars > 0 && (
                  <div key="own" style={{ display: "flex", alignItems: "center", gap: 6, padding: "3px 0", fontSize: 11 }}>
                    <span style={{ color: "var(--text-dim)", width: 18, textAlign: "right" }}>—</span>
                    <span style={{ fontWeight: 500 }}>This document</span>
                    <span style={{ color: "var(--text-dim)", marginLeft: "auto" }}>{ownChars} chars</span>
                  </div>
                )}
                {docs.map((doc) => {
                  const docColor =
                    doc.dominantAuthorType === "historical"
                      ? "#c4a35a"
                      : doc.dominantAuthorType === "llm"
                      ? "#7c4dff"
                      : authorColor(doc.dominantAuthor);
                  return (
                    <div
                      key={doc.workId}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 6,
                        padding: "3px 0",
                        fontSize: 11,
                        cursor: onOpenWork ? "pointer" : "default",
                        borderRadius: 4,
                      }}
                      onClick={() => onOpenWork?.(doc.workId)}
                      title={onOpenWork ? `Open “${doc.title}”` : doc.title}
                    >
                      <span style={{ color: "var(--text-dim)", width: 18, textAlign: "right" }}>{doc.firstStart}</span>
                      <div className="attr-author-dot" style={{ background: docColor }} />
                      <span style={{ fontWeight: 500 }}>{doc.dominantAuthor}</span>
                      <span style={{ color: "var(--text-dim)" }}>→</span>
                      <span style={{ color: "var(--blue)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", maxWidth: 140 }}>
                        {doc.title}
                      </span>
                      <span style={{ color: "var(--text-dim)", marginLeft: "auto", whiteSpace: "nowrap" }}>
                        {doc.chars} chars · {doc.spanCount} span{doc.spanCount > 1 ? "s" : ""}
                      </span>
                    </div>
                  );
                })}
              </div>
            );
          })()}
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
                    <span
                      className="attr-source"
                      style={onOpenWork ? { cursor: "pointer" } : undefined}
                      onClick={onOpenWork ? () => onOpenWork(span.source_work_id!) : undefined}
                      title={span.source_work_title || `source work #${span.source_work_id}`}
                    >
                      via {span.source_work_title ? `“${span.source_work_title.slice(0, 24)}”` : `#${span.source_work_id}`}
                    </span>
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
