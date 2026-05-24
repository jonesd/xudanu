import { useMemo } from "react";
import type { AttributionSpan, AttributionLogStatus } from "../api/crdt_sync";
import { authorColor } from "../author-color";

function bytesToHex(bytes: number[]): string {
  return bytes.map((b) => b.toString(16).padStart(2, "0")).join("");
}

function shortKey(bytes: number[]): string {
  const hex = bytesToHex(bytes);
  return hex.length > 16 ? `${hex.slice(0, 8)}..${hex.slice(-8)}` : hex;
}

interface AuthorGroup {
  key: string;
  displayName: string;
  color: string;
  spans: AttributionSpan[];
  allValid: boolean;
}

interface AttributionPanelProps {
  spans: AttributionSpan[];
  logStatus: AttributionLogStatus | null;
  documentLength: number;
  visible: boolean;
}

export function AttributionPanel({ spans, logStatus, documentLength, visible }: AttributionPanelProps) {
  const authors = useMemo(() => {
    const groups = new Map<string, AuthorGroup>();

    for (const span of spans) {
      const key = bytesToHex(span.author_public_key);
      if (!groups.has(key)) {
        const displayName = span.author_display_name || shortKey(span.author_public_key);
        groups.set(key, {
          key,
          displayName,
          color: authorColor(displayName),
          spans: [],
          allValid: true,
        });
      }
      const group = groups.get(key)!;
      group.spans.push(span);
      if (!span.signature_valid) group.allValid = false;
    }

    return Array.from(groups.values());
  }, [spans]);

  if (!visible) return null;

  const effectiveLength = spans.length > 0
    ? Math.max(documentLength, spans.reduce((max, s) => Math.max(max, s.end), 0))
    : documentLength;
  const totalAttributed = spans.reduce((sum, s) => sum + (s.end - s.start), 0);
  const coverage = effectiveLength > 0 ? Math.round((totalAttributed / effectiveLength) * 100) : 0;

  return (
    <div className="attribution-panel">
      <div className="attribution-header">
        <h3>Attribution</h3>
        <div className="attribution-stats">
          <span className="attribution-stat">{spans.length} spans</span>
          <span className="attribution-stat">{authors.length} author{authors.length !== 1 ? "s" : ""}</span>
          <span className="attribution-stat">{coverage}% coverage</span>
        </div>
      </div>

      {logStatus && (
        <div className="attribution-log-status">
          <span className={logStatus.has_log ? (logStatus.chain_valid ? "log-valid" : "log-invalid") : "log-none"}>
            {logStatus.has_log ? (logStatus.chain_valid ? "Chain valid" : "Chain INVALID") : "No Log"}
          </span>
          <span className="log-detail">{logStatus.entry_count} entries, seq #{logStatus.last_sequence}</span>
        </div>
      )}

      {effectiveLength > 0 && (
        <div className="attribution-bar">
          {spans.map((span, i) => {
            const leftPct = (span.start / effectiveLength) * 100;
            const widthPct = ((span.end - span.start) / effectiveLength) * 100;
            const key = bytesToHex(span.author_public_key);
            const author = authors.find((a) => a.key === key);
            return (
              <div
                key={i}
                className="attribution-bar-segment"
                style={{
                  left: `${leftPct}%`,
                  width: `${widthPct}%`,
                  backgroundColor: author?.color || "#666",
                  opacity: span.signature_valid ? 0.7 : 0.35,
                }}
                title={`${author?.displayName || "unknown"} [${span.start}..${span.end}]${span.signature_valid ? "" : " (unsigned)"}`}
              />
            );
          })}
        </div>
      )}

      <ul className="attribution-authors">
        {authors.map((author) => (
          <li key={author.key} className="attribution-author">
            <span className="author-color" style={{ backgroundColor: author.color }} />
            <span className="author-name">{author.displayName}</span>
            <span className={`author-sig ${author.allValid ? "sig-valid" : "sig-invalid"}`}>
              {author.allValid ? "signed" : "unsigned"}
            </span>
            <span className="author-spans">{author.spans.length} span{author.spans.length !== 1 ? "s" : ""}</span>
            <span className="author-key" title={author.key}>{shortKey(author.spans[0].author_public_key)}</span>
            {author.spans[0].author_club_id != null && (
              <span className="author-club">club:{author.spans[0].author_club_id.toString(16).padStart(4, "0")}</span>
            )}
          </li>
        ))}
      </ul>

      {spans.length > 0 && (
        <div className="attribution-timeline">
          <h4>Timeline</h4>
          <ul>
            {spans.map((span, i) => {
              const key = bytesToHex(span.author_public_key);
              const author = authors.find((a) => a.key === key);
              const time = new Date(Number(BigInt(span.timestamp) / 1000000n));
              return (
                <li key={i} className="timeline-entry">
                  <span className="timeline-time">{time.toLocaleTimeString()}</span>
                  <span className="timeline-range">[{span.start}..{span.end}]</span>
                  <span className="timeline-author" style={{ color: author?.color }}>
                    {author?.displayName || "unknown"}
                  </span>
                  {!span.signature_valid && <span className="timeline-unsigned">(unsigned)</span>}
                </li>
              );
            })}
          </ul>
        </div>
      )}

      {spans.length === 0 && (
        <p className="attribution-empty">
          No attribution data yet. Make a revision to generate signed spans.
        </p>
      )}
    </div>
  );
}
