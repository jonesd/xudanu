import { useMemo } from "react";
import type { AttributionSpan, AttributionLogStatus, ProvenanceHop } from "../api/crdt_sync";

// Reconstruct the ancestry DAG from hop destinations and return each
// leaf→target path. Without dest_work_id (old server) it falls back to a
// single flat path so a multi-source doc isn't misread as a linear chain.
function buildChainPaths(chain: ProvenanceHop[]): ProvenanceHop[][] {
  if (!chain.length) return [];
  const haveDest = chain.every((h) => h.dest_work_id != null && h.dest_work_id !== 0);
  if (!haveDest) return [chain];
  const byDest = new Map<number, ProvenanceHop[]>();
  for (const h of chain) {
    const d = h.dest_work_id!;
    const arr = byDest.get(d) ?? [];
    arr.push(h);
    byDest.set(d, arr);
  }
  const sources = new Set(chain.map((h) => h.source_work_id));
  const targetId = chain.find((h) => !sources.has(h.dest_work_id!))?.dest_work_id;
  if (targetId == null) return [chain];
  const paths: ProvenanceHop[][] = [];
  const walk = (workId: number, acc: ProvenanceHop[]) => {
    const incoming = byDest.get(workId) ?? [];
    if (incoming.length === 0) {
      paths.push([...acc].reverse());
      return;
    }
    for (const h of incoming) walk(h.source_work_id, [...acc, h]);
  };
  walk(targetId, []);
  return paths.length ? paths : [chain];
}

function hslToHex(h: number, s: number, l: number): string {
  const a = s * Math.min(l, 1 - l);
  const f = (n: number) => {
    const k = (n + h / 30) % 12;
    const c = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
    return Math.round(255 * c).toString(16).padStart(2, "0");
  };
  return `#${f(0)}${f(8)}${f(4)}`;
}

function seedFromBytes(bytes: number[]): number {
  let h = 0;
  for (const b of bytes) h = ((h << 5) - h + b) | 0;
  return Math.abs(h);
}

function authorStripeColors(seed: number): [string, string] {
  const hue1 = (seed * 137) % 360;
  const hue2 = (hue1 + 40) % 360;
  return [
    hslToHex(hue1, 0.45, 0.38),
    hslToHex(hue2, 0.35, 0.42),
  ];
}

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
  stripeColors: [string, string] | null;
  spans: AttributionSpan[];
  allValid: boolean;
  authorType: string | null;
  historicalAuthorId: number | null;
  sourceWorkId: number | null;
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
      const isHistorical = span.author_type === "historical";
      const isLlm = span.author_type === "llm";
      const key = isHistorical && span.historical_author_id != null
        ? `ha:${span.historical_author_id}`
        : isHistorical && span.source_work_id != null
          ? `sw:${span.source_work_id}`
          : bytesToHex(span.author_public_key);
      if (!groups.has(key)) {
        const displayName = isHistorical
          ? (span.author_display_name || "Unknown Historical Author")
          : isLlm
            ? (span.llm_model || "LLM")
            : (span.author_display_name || shortKey(span.author_public_key));
        const stripeSeed = isHistorical
          ? (span.historical_author_id ?? span.source_work_id ?? 0)
          : seedFromBytes(span.author_public_key);
        const stripeColors = authorStripeColors(stripeSeed);
        const color = isLlm ? "#7c4dff" : stripeColors[0];
        groups.set(key, {
          key,
          displayName,
          color,
          stripeColors,
          spans: [],
          allValid: true,
          authorType: span.author_type,
          historicalAuthorId: span.historical_author_id,
          sourceWorkId: span.source_work_id ?? null,
        });
      }
      const group = groups.get(key)!;
      group.spans.push(span);
      if (!span.signature_valid) group.allValid = false;
    }

    return Array.from(groups.values());
  }, [spans]);

  if (!visible) return null;

  const derivationChain = spans.find((s) => s.provenance_chain && s.provenance_chain.length > 0)?.provenance_chain ?? null;

  const effectiveLength = spans.length > 0
    ? Math.max(documentLength, spans.reduce((max, s) => Math.max(max, s.end), 0))
    : documentLength;
  const sortedSpans = [...spans].sort((a, b) => a.start - b.start);
  let unionLength = 0;
  let prevEnd = -1;
  for (const s of sortedSpans) {
    if (s.end <= prevEnd) continue;
    const start = Math.max(s.start, prevEnd);
    unionLength += s.end - start;
    prevEnd = s.end;
  }
  const coverage = effectiveLength > 0 ? Math.round((unionLength / effectiveLength) * 100) : 0;

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
            const isH = span.author_type === "historical";
            const key = isH && span.historical_author_id != null
              ? `ha:${span.historical_author_id}`
              : isH && span.source_work_id != null
                ? `sw:${span.source_work_id}`
                : bytesToHex(span.author_public_key);
            const author = authors.find((a) => a.key === key);
            const c0 = author?.stripeColors?.[0] || "#888";
            const c1 = author?.stripeColors?.[1] || "#666";
            const bg = `repeating-linear-gradient(45deg, ${c0}, ${c0} 3px, ${c1}, ${c1} 6px)`;
            return (
              <div
                key={i}
                className="attribution-bar-segment"
                style={{
                  left: `${leftPct}%`,
                  width: `${widthPct}%`,
                  background: bg,
                  opacity: span.signature_valid ? 0.7 : 0.35,
                }}
                title={`${author?.displayName || "unknown"} [${span.start}..${span.end}]${span.signature_valid ? "" : " (unsigned)"}`}
              />
            );
          })}
        </div>
      )}

      {derivationChain && derivationChain.length > 0 && (
        <div className="attribution-derivation">
          <h4>Derivation Chain{buildChainPaths(derivationChain).length > 1 ? "s" : ""}</h4>
          <div className="derivation-chain" style={{ flexDirection: "column", alignItems: "stretch", gap: "6px" }}>
            {buildChainPaths(derivationChain).map((path, pi) => (
              <div key={pi} className="chain-hop" style={{ flexWrap: "wrap", alignItems: "center" }}>
                {path.map((hop, i) => (
                  <span key={i} className="chain-hop">
                    {i > 0 && <span className="chain-arrow">{"\u2192"}</span>}
                    <span className="chain-work">
                      {hop.source_work_title || `work:${hop.source_work_id.toString(16).padStart(4, "0")}`}
                    </span>
                    {hop.source_author_name && (
                      <span className="chain-author">({hop.source_author_name})</span>
                    )}
                  </span>
                ))}
                <span className="chain-arrow">{"\u2192"}</span>
                <span className="chain-current">This document</span>
              </div>
            ))}
          </div>
        </div>
      )}

      <ul className="attribution-authors">
        {authors.map((author) => (
          <li key={author.key} className={`attribution-author${author.authorType === "historical" ? " historical-author" : ""}`}>
            <span className="author-color" style={author.stripeColors
              ? { background: `repeating-linear-gradient(45deg, ${author.stripeColors[0]}, ${author.stripeColors[0]} 3px, ${author.stripeColors[1]} 3px, ${author.stripeColors[1]} 6px)` }
              : { backgroundColor: author.color }} />
            <span className={`author-name${author.authorType === "historical" ? " historical-name" : ""}${author.authorType === "llm" ? " llm-name" : ""}`}>
              {author.displayName}
            </span>
            {author.authorType === "historical" && (
              <span className="author-type-badge historical-badge">historical</span>
            )}
            {author.authorType === "llm" && (
              <span className="author-type-badge llm-badge">LLM</span>
            )}
            {author.sourceWorkId != null && (
              <span className="author-source-work">via work:{author.sourceWorkId.toString(16).padStart(4, "0")}</span>
            )}
            {author.spans.some((s) => s.transcluded_by_name) && (
              <span className="author-transcluded-by">
                transcluded by {author.spans.find((s) => s.transcluded_by_name)?.transcluded_by_name}
              </span>
            )}
            <span className={`author-sig ${author.allValid ? "sig-valid" : "sig-invalid"}`}>
              {author.authorType === "historical" ? "attested" : author.allValid ? "signed" : "unsigned"}
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
            {[...spans].sort((a, b) => a.start - b.start).map((span, i) => {
              const isHistorical = span.author_type === "historical";
              const key = isHistorical && span.historical_author_id != null
                ? `ha:${span.historical_author_id}`
                : isHistorical && span.source_work_id != null
                  ? `sw:${span.source_work_id}`
                  : bytesToHex(span.author_public_key);
              const author = authors.find((a) => a.key === key);
              const time = new Date(Number(BigInt(span.timestamp) / 1000000n));
              return (
                <li key={i} className="timeline-entry">
                  <span className="timeline-time">{time.toLocaleTimeString()}</span>
                  <span className="timeline-range">[{span.start}..{span.end}]</span>
                  <span className="timeline-author" style={{ color: author?.color }}>
                    {author?.displayName || "unknown"}
                  </span>
                  {span.source_work_id != null && (
                    <span className="timeline-via">via work:{span.source_work_id.toString(16).padStart(4, "0")}</span>
                  )}
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
