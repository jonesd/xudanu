import { useState, useEffect, useCallback, useRef } from "react";
import type { AttributionSpan, WorkSummary, WorkVersionTimeline, PassageComposition } from "../../api/crdt_sync";
import type { CrdtSyncClient } from "../../api/crdt_sync";
import { ProvenanceOverlay, spansToRegions } from "../ProvenanceWidgets";
import { sourceCountColor } from "../ProvenanceWidgets";
import "./reading.css";

interface ReadingViewProps {
  workId: number;
  text: string;
  title: string;
  attributionSpans: AttributionSpan[];
  isSource: boolean;
  clientRef: React.MutableRefObject<CrdtSyncClient | null>;
  connected: boolean;
}

type ProvenanceLevel = 0 | 1 | 2 | 3;

export function ReadingView({
  workId,
  text,
  title,
  attributionSpans,
  isSource,
  clientRef,
  connected,
}: ReadingViewProps) {
  const [summary, setSummary] = useState<WorkSummary | null>(null);
  const [timeline, setTimeline] = useState<WorkVersionTimeline | null>(null);
  const [provenanceLevel, setProvenanceLevel] = useState<ProvenanceLevel>(0);
  const [hoveredRegion, setHoveredRegion] = useState<{ start: number; end: number; sourceCount: number } | null>(null);
  const [selectedRegion, setSelectedRegion] = useState<{ start: number; end: number } | null>(null);
  const [composition, setComposition] = useState<PassageComposition | null>(null);
  const [showTimeline, setShowTimeline] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!clientRef.current || !connected || workId === null) return;
    let cancelled = false;
    (async () => {
      try {
        const s = await clientRef.current!.workSummary(workId);
        if (!cancelled) setSummary(s);
      } catch (e) {
        console.warn("[reading] workSummary failed:", e);
      }
      try {
        const t = await clientRef.current!.workVersionTimeline(workId);
        if (!cancelled) setTimeline(t);
      } catch (e) {
        console.warn("[reading] workVersionTimeline failed:", e);
      }
    })();
    return () => { cancelled = true; };
  }, [workId, connected, clientRef]);

  useEffect(() => {
    if (!clientRef.current || !connected || !selectedRegion || workId === null) return;
    let cancelled = false;
    (async () => {
      try {
        const c = await clientRef.current!.passageComposition(workId, selectedRegion.start, selectedRegion.end);
        if (!cancelled) setComposition(c);
      } catch (e) {
        console.warn("[reading] passageComposition failed:", e);
      }
    })();
    return () => { cancelled = true; };
  }, [workId, connected, clientRef, selectedRegion]);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === "p" || e.key === "P") {
        if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
        setProvenanceLevel((prev) => ((prev + 1) % 4) as ProvenanceLevel);
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);

  const regions = spansToRegions(attributionSpans);

  const handleRegionClick = useCallback((start: number, end: number) => {
    if (provenanceLevel >= 2) {
      setSelectedRegion({ start, end });
      setProvenanceLevel(3);
    }
  }, [provenanceLevel]);

  if (!text) {
    return <div className="reading-empty">No content to display.</div>;
  }

  const lines = text.split("\n");

  return (
    <div className="reading-view">
      <div className="reading-header-bar">
        <div className="reading-title-section">
          <h2 className="reading-title">{title}</h2>
          {summary && (
            <div className="reading-stats">
              <span className="stat-badge stat-sources" title="Unique sources">
                {summary.unique_sources} source{summary.unique_sources !== 1 ? "s" : ""}
              </span>
              <span className="stat-badge stat-authors" title="Unique authors">
                {summary.unique_authors} author{summary.unique_authors !== 1 ? "s" : ""}
              </span>
              <span className="stat-badge stat-versions" title="Versions">
                v{summary.version_count}
              </span>
              <span className="stat-badge stat-chars" title="Character count">
                {summary.char_count.toLocaleString()} chars
              </span>
              {summary.reused_in_count > 0 && (
                <span className="stat-badge stat-reused" title="Reused in other documents">
                  Reused in {summary.reused_in_count} doc{summary.reused_in_count !== 1 ? "s" : ""}
                </span>
              )}
            </div>
          )}
        </div>
        <div className="reading-controls">
          <button
            className={`reading-provenance-btn ${provenanceLevel > 0 ? "active" : ""}`}
            onClick={() => setProvenanceLevel((prev) => ((prev + 1) % 4) as ProvenanceLevel)}
            title={`Provenance level: ${provenanceLevel}/3 (press P to cycle)`}
          >
            P{provenanceLevel}
          </button>
          <button
            className={`reading-timeline-btn ${showTimeline ? "active" : ""}`}
            onClick={() => setShowTimeline((t) => !t)}
            title="Toggle version timeline"
          >
            Timeline
          </button>
        </div>
      </div>

      {summary && summary.author_contributions.length > 0 && (
        <div className="reading-author-bar">
          {summary.author_contributions.map((ac) => (
            <div key={ac.club_id} className="author-bar-segment" style={{ width: `${ac.percentage}%` }} title={`${ac.display_name}: ${ac.percentage.toFixed(1)}%`}>
              <span className="author-bar-label" style={{ color: sourceCountColor(ac.club_id) }}>
                {ac.display_name}
              </span>
            </div>
          ))}
        </div>
      )}

      {showTimeline && timeline && (
        <div className="reading-timeline">
          <div className="timeline-track">
            {timeline.revisions.map((rev) => (
              <div
                key={rev.revision}
                className="timeline-revision"
                title={`Revision ${rev.revision}: ${rev.char_count} chars${rev.author_display_name ? ` by ${rev.author_display_name}` : ""}`}
              >
                <span className="revision-number">r{rev.revision}</span>
                <span className="revision-chars">{rev.char_count}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="reading-body" ref={containerRef}>
        {provenanceLevel === 3 ? (
          <ProvenanceOverlay
            text={text}
            spans={attributionSpans}
            visible={true}
          />
        ) : (
          <div className="reading-text">
            {lines.map((line, lineIdx) => {
              const charOffset = lines.slice(0, lineIdx).join("\n").length + (lineIdx > 0 ? 1 : 0);
              return (
                <div key={lineIdx} className="reading-line">
                  <span className="reading-line-number">{lineIdx + 1}</span>
                  <span className="reading-line-text">
                    {provenanceLevel === 0 && line}
                    {provenanceLevel >= 1 && renderAnnotatedLine(
                      line, charOffset, regions, provenanceLevel,
                      hoveredRegion, setHoveredRegion, handleRegionClick
                    )}
                  </span>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {selectedRegion && composition && (
        <div className="reading-composition">
          <div className="composition-header">
            <h4>Composition: chars {selectedRegion.start}&ndash;{selectedRegion.end}</h4>
            <button className="composition-close" onClick={() => { setSelectedRegion(null); setComposition(null); }}>&times;</button>
          </div>
          <div className="composition-layers">
            {composition.layers.map((layer, i) => (
              <div key={i} className={`composition-layer layer-${layer.operation}`}>
                <div className="layer-meta">
                  <span className="layer-revision">r{layer.revision}</span>
                  <span className="layer-operation">{layer.operation}</span>
                  {layer.author_display_name && (
                    <span className="layer-author">{layer.author_display_name}</span>
                  )}
                </div>
                <div className="layer-text">{layer.text}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="reading-footer">
        <span className="footer-mode">Reading View</span>
        {provenanceLevel === 0 && <span className="footer-hint">Press P for provenance</span>}
        {provenanceLevel > 0 && <span className="footer-hint">Provenance level {provenanceLevel}/3</span>}
        {summary && (
          <span className="footer-stats">
            {summary.unique_sources} source{summary.unique_sources !== 1 ? "s" : ""} &middot; {summary.unique_authors} author{summary.unique_authors !== 1 ? "s" : ""} &middot; v{summary.version_count}
          </span>
        )}
      </div>
    </div>
  );
}

interface Region {
  start: number;
  end: number;
  sourceCount: number;
  sources: Set<number>;
}

function renderAnnotatedLine(
  line: string,
  charOffset: number,
  regions: ReturnType<typeof spansToRegions>,
  level: ProvenanceLevel,
  hoveredRegion: { start: number; end: number; sourceCount: number } | null,
  onHover: (region: { start: number; end: number; sourceCount: number } | null) => void,
  onClick: (start: number, end: number) => void,
): React.ReactNode {
  if (regions.length === 0) return line;

  const spans: React.ReactNode[] = [];
  let pos = 0;

  const activeRegions = regions.filter(
    (r) => r.end > charOffset && r.start < charOffset + line.length
  );

  if (activeRegions.length === 0) return line;

  for (let i = 0; i < line.length; i++) {
    const absPos = charOffset + i;
    const region = activeRegions.find((r) => r.start <= absPos && r.end > absPos);

    if (region) {
      const color = sourceCountColor(region.sourceCount);
      const isHovered = hoveredRegion && hoveredRegion.start === region.start && hoveredRegion.end === region.end;
      const isEndOfRegion = i === line.length - 1 || !activeRegions.find((r) => r.start <= absPos + 1 && r.end > absPos + 1);

      let style: React.CSSProperties = {};
      if (level >= 1) {
        style.borderBottom = `2px solid ${color}`;
        if (isHovered && level >= 2) {
          style.backgroundColor = color + "20";
        }
      }

      spans.push(
        <span
          key={i}
          style={style}
          className="reading-annotated-char"
          onMouseEnter={() => onHover({ start: region.start, end: region.end, sourceCount: region.sourceCount })}
          onMouseLeave={() => onHover(null)}
          onClick={() => onClick(region.start, region.end)}
        >
          {line[i]}
        </span>
      );

      if (isEndOfRegion && level >= 1) {
        spans.push(
          <span key={`${i}-badge`} className="reading-source-badge" style={{ color }}>
            [{region.sourceCount}]
          </span>
        );
      }
    } else {
      spans.push(<span key={i}>{line[i]}</span>);
    }
  }

  return <>{spans}</>;
}
