import { useState, useMemo } from "react";
import type { AttributionSpan } from "../api/crdt_sync";
import { authorColor } from "../author-color";

export interface ProvenanceRegion {
  start: number;
  end: number;
  sourceCount: number;
  sources: SourceInfo[];
}

export interface SourceInfo {
  id: number;
  title: string;
  author: string;
  color: string;
}

export function sourceCountColor(count: number): string {
  if (count === 0) return "transparent";
  if (count === 1) return "#4caf50";
  if (count <= 3) return "#64b5f6";
  if (count <= 8) return "#ab47bc";
  return "#fdd835";
}

export function sourceCountTint(count: number): string {
  if (count === 0) return "transparent";
  if (count === 1) return "rgba(76, 175, 80, 0.08)";
  if (count <= 3) return "rgba(100, 181, 246, 0.08)";
  if (count <= 8) return "rgba(171, 71, 188, 0.08)";
  return "rgba(253, 216, 53, 0.10)";
}

export function spansToRegions(spans: AttributionSpan[]): ProvenanceRegion[] {
  const buckets = new Map<number, { sources: Map<string, SourceInfo>; end: number }>();

  for (const span of spans) {
    const key = span.start;
    if (!buckets.has(key)) {
      buckets.set(key, { sources: new Map(), end: span.end });
    }
    const bucket = buckets.get(key)!;
    if (span.end > bucket.end) bucket.end = span.end;

    const authorName = span.author_display_name || "unknown";
    const srcKey = `${span.source_work_id ?? "self"}:${authorName}`;
    if (!bucket.sources.has(srcKey)) {
      const color = span.author_type === "historical"
        ? "#c4a35a"
        : span.author_type === "llm"
          ? "#7c4dff"
          : authorColor(authorName);
      bucket.sources.set(srcKey, {
        id: span.source_work_id ?? 0,
        title: span.source_work_id ? `Work ${span.source_work_id.toString(16).padStart(4, "0")}` : "Original",
        author: authorName,
        color,
      });
    }
  }

  return Array.from(buckets.entries()).map(([start, { end, sources }]) => ({
    start,
    end,
    sourceCount: sources.size,
    sources: Array.from(sources.values()),
  }));
}

interface ProvenanceCardProps {
  children: React.ReactNode;
  className?: string;
}

export function ProvenanceCard({ children, className }: ProvenanceCardProps) {
  return (
    <div className={`prov-card ${className || ""}`}>
      {children}
    </div>
  );
}

interface HeatMapProps {
  text: string;
  regions: ProvenanceRegion[];
}

export function HeatMapSidebar({ text, regions }: HeatMapProps) {
  const lineCount = useMemo(() => {
    const lines = text.split("\n");
    const buckets: { heat: number; sources: SourceInfo[] }[] = lines.map(() => ({
      heat: 0,
      sources: [],
    }));

    let charIdx = 0;
    for (let li = 0; li < lines.length; li++) {
      const lineLen = lines[li].length + 1;
      for (const r of regions) {
        if (r.start < charIdx + lineLen && r.end > charIdx) {
          buckets[li].heat += r.sourceCount;
          for (const s of r.sources) {
            if (!buckets[li].sources.find((x) => x.id === s.id && x.author === s.author)) {
              buckets[li].sources.push(s);
            }
          }
        }
      }
      charIdx += lineLen;
    }
    return buckets;
  }, [text, regions]);

  const maxHeat = Math.max(1, ...lineCount.map((b) => b.heat));
  const [hoveredLine, setHoveredLine] = useState<number | null>(null);

  return (
    <div className="prov-heatmap-sidebar">
      {lineCount.map((bucket, i) => {
        const intensity = bucket.heat / maxHeat;
        return (
          <div
            key={i}
            className="prov-heatmap-row"
            style={{
              backgroundColor: bucket.heat > 0
                ? `rgba(76, 175, 80, ${0.1 + intensity * 0.6})`
                : "transparent",
            }}
            onMouseEnter={() => setHoveredLine(i)}
            onMouseLeave={() => setHoveredLine(null)}
          >
            {hoveredLine === i && bucket.sources.length > 0 && (
              <div className="prov-heatmap-tooltip">
                {bucket.sources.map((s, si) => (
                  <div key={si} className="prov-heatmap-source">
                    <span className="prov-heatmap-dot" style={{ backgroundColor: s.color }} />
                    {s.author} — {s.title}
                  </div>
                ))}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

interface HeatMapWidgetProps {
  text: string;
  regions: ProvenanceRegion[];
}

export function HeatMapWidget({ text, regions }: HeatMapWidgetProps) {
  const lines = text.split("\n");
  return (
    <ProvenanceCard className="prov-heatmap-card">
      <div className="prov-heatmap-layout">
        <HeatMapSidebar text={text} regions={regions} />
        <div className="prov-heatmap-content">
          {lines.map((line, i) => (
            <div key={i} className="prov-heatmap-line">
              {renderTintedLine(line, i, lines, regions)}
            </div>
          ))}
        </div>
      </div>
    </ProvenanceCard>
  );
}

function renderTintedLine(line: string, lineIdx: number, lines: string[], regions: ProvenanceRegion[]) {
  let charOffset = 0;
  for (let i = 0; i < lineIdx; i++) charOffset += lines[i].length + 1;

  const parts: { text: string; tint: string; sources: SourceInfo[] }[] = [];
  let pos = 0;

  while (pos < line.length) {
    const absPos = charOffset + pos;
    let bestEnd = line.length;
    let bestSources: SourceInfo[] = [];
    let bestTint = "transparent";

    for (const r of regions) {
      if (absPos >= r.start && absPos < r.end) {
        const regionRelEnd = Math.min(r.end - charOffset, line.length);
        if (regionRelEnd > pos) {
          const tint = sourceCountTint(r.sourceCount);
          if (bestSources.length < r.sourceCount || bestTint === "transparent") {
            bestEnd = regionRelEnd;
            bestSources = r.sources;
            bestTint = tint;
          }
        }
      }
    }

    const segEnd = bestEnd > pos ? bestEnd : pos + 1;
    parts.push({
      text: line.slice(pos, segEnd),
      tint: bestTint,
      sources: bestSources,
    });
    pos = segEnd;
  }

  return parts.map((p, i) => (
    <span
      key={i}
      style={{ backgroundColor: p.tint }}
      title={p.sources.map((s) => `${s.author} (${s.title})`).join(", ")}
    >
      {p.text}
    </span>
  ));
}

interface DotDensityProps {
  text: string;
  regions: ProvenanceRegion[];
}

export function DotDensityWidget({ text, regions }: DotDensityProps) {
  const lineData = useMemo(() => {
    const lines = text.split("\n");
    return lines.map((line, li) => {
      let charOffset = 0;
      for (let i = 0; i < li; i++) charOffset += lines[i].length + 1;

      const dots: { color: string; sources: SourceInfo[] }[] = [];
      for (const r of regions) {
        if (r.start < charOffset + line.length + 1 && r.end > charOffset) {
          dots.push({ color: sourceCountColor(r.sourceCount), sources: r.sources });
        }
      }
      return { line, dots };
    });
  }, [text, regions]);

  const [hoveredLine, setHoveredLine] = useState<number | null>(null);

  return (
    <ProvenanceCard className="prov-dots-card">
      {lineData.map(({ line, dots }, i) => (
        <div key={i} className="prov-dots-row">
          <div
            className="prov-dots-line"
            onMouseEnter={() => setHoveredLine(i)}
            onMouseLeave={() => setHoveredLine(null)}
          >
            {line || "\u00a0"}
          </div>
          <div className="prov-dots-track">
            {dots.map((d, di) =>
              Array.from({ length: Math.min(d.sources.length, 12) }).map((_, si) => (
                <span
                  key={`${di}-${si}`}
                  className="prov-dot"
                  style={{ backgroundColor: d.color }}
                  title={d.sources.map((s) => `${s.author} (${s.title})`).join(", ")}
                />
              ))
            )}
          </div>
          {hoveredLine === i && dots.length > 0 && (
            <div className="prov-dots-tooltip">
              {dots.flatMap((d) => d.sources).map((s, si) => (
                <div key={si} className="prov-dot-source">
                  <span className="prov-heatmap-dot" style={{ backgroundColor: s.color }} />
                  {s.author} — {s.title}
                </div>
              ))}
            </div>
          )}
        </div>
      ))}
    </ProvenanceCard>
  );
}

interface UnderlineStyleProps {
  text: string;
  regions: ProvenanceRegion[];
}

const UNDERLINE_STYLES = [
  "solid",
  "dotted",
  "dashed",
  "wavy",
  "double",
];

export function UnderlineWidget({ text, regions }: UnderlineStyleProps) {
  const [hoveredSpan, setHoveredSpan] = useState<{ start: number; end: number } | null>(null);

  const spans = useMemo(() => {
    const result: {
      text: string;
      style: string;
      color: string;
      sources: SourceInfo[];
      absStart: number;
      absEnd: number;
    }[] = [];

    let pos = 0;
    for (const r of regions.sort((a, b) => a.start - b.start)) {
      if (r.start > pos) {
        result.push({
          text: text.slice(pos, r.start),
          style: "none",
          color: "transparent",
          sources: [],
          absStart: pos,
          absEnd: r.start,
        });
      }
      const styleIdx = (r.sourceCount - 1) % UNDERLINE_STYLES.length;
      result.push({
        text: text.slice(r.start, r.end),
        style: UNDERLINE_STYLES[styleIdx],
        color: sourceCountColor(r.sourceCount),
        sources: r.sources,
        absStart: r.start,
        absEnd: r.end,
      });
      pos = r.end;
    }
    if (pos < text.length) {
      result.push({
        text: text.slice(pos),
        style: "none",
        color: "transparent",
        sources: [],
        absStart: pos,
        absEnd: text.length,
      });
    }
    return result;
  }, [text, regions]);

  return (
    <ProvenanceCard className="prov-underline-card">
      <div className="prov-underline-text">
        {spans.map((s, i) => {
          const isHovered = hoveredSpan && hoveredSpan.start === s.absStart && hoveredSpan.end === s.absEnd;
          return (
            <span
              key={i}
              className="prov-underline-segment"
              style={{
                textDecoration: s.style !== "none" ? `${s.style} underline` : "none",
                textDecorationColor: s.color,
                textUnderlineOffset: "3px",
                cursor: s.sources.length > 0 ? "pointer" : "inherit",
              }}
              onMouseEnter={() => s.sources.length > 0 && setHoveredSpan({ start: s.absStart, end: s.absEnd })}
              onMouseLeave={() => setHoveredSpan(null)}
            >
              {s.text}
              {isHovered && s.sources.length > 0 && (
                <span className="prov-underline-tooltip">
                  {s.sources.map((src, si) => (
                    <span key={si} className="prov-tooltip-source">
                      <span className="prov-heatmap-dot" style={{ backgroundColor: src.color }} />
                      {src.author} ({src.title})
                    </span>
                  ))}
                </span>
              )}
            </span>
          );
        })}
      </div>
    </ProvenanceCard>
  );
}

interface BackgroundTintsProps {
  text: string;
  regions: ProvenanceRegion[];
}

export function BackgroundTintsWidget({ text, regions }: BackgroundTintsProps) {
  const [focusedRegion, setFocusedRegion] = useState<number | null>(null);

  const segments = useMemo(() => {
    const result: {
      text: string;
      tint: string;
      sources: SourceInfo[];
      regionIdx: number;
    }[] = [];

    let pos = 0;
    const sorted = [...regions].sort((a, b) => a.start - b.start);
    for (let ri = 0; ri < sorted.length; ri++) {
      const r = sorted[ri];
      if (r.start > pos) {
        result.push({
          text: text.slice(pos, r.start),
          tint: "transparent",
          sources: [],
          regionIdx: -1,
        });
      }
      result.push({
        text: text.slice(r.start, r.end),
        tint: sourceCountTint(r.sourceCount),
        sources: r.sources,
        regionIdx: ri,
      });
      pos = r.end;
    }
    if (pos < text.length) {
      result.push({
        text: text.slice(pos),
        tint: "transparent",
        sources: [],
        regionIdx: -1,
      });
    }
    return result;
  }, [text, regions]);

  return (
    <ProvenanceCard className="prov-tints-card">
      <div className="prov-tints-text">
        {segments.map((seg, i) => {
          const isActive = focusedRegion === seg.regionIdx;
          const enhancedTint = isActive && seg.tint !== "transparent"
            ? seg.tint.replace(/[\d.]+\)$/, (m) => `${parseFloat(m) * 3})`)
            : seg.tint;

          return (
            <span
              key={i}
              className="prov-tint-segment"
              style={{
                backgroundColor: enhancedTint,
                cursor: seg.sources.length > 0 ? "pointer" : "inherit",
                transition: "background-color 0.2s ease",
              }}
              onClick={() => seg.sources.length > 0 && setFocusedRegion(isActive ? null : seg.regionIdx)}
              title={seg.sources.map((s) => `${s.author} (${s.title})`).join(", ")}
            >
              {seg.text}
            </span>
          );
        })}
      </div>
      {focusedRegion !== null && segments[focusedRegion] && (
        <div className="prov-tints-detail">
          <div className="prov-tints-detail-header">Sources ({segments[focusedRegion].sources.length})</div>
          {segments[focusedRegion].sources.map((s, i) => (
            <div key={i} className="prov-tints-detail-source">
              <span className="prov-heatmap-dot" style={{ backgroundColor: s.color }} />
              <strong>{s.author}</strong>
              <span className="prov-tints-detail-work">{s.title}</span>
            </div>
          ))}
        </div>
      )}
    </ProvenanceCard>
  );
}

interface BracketHintsProps {
  text: string;
  regions: ProvenanceRegion[];
}

export function BracketHintsWidget({ text, regions }: BracketHintsProps) {
  const [hoveredIdx, setHoveredIdx] = useState<number | null>(null);

  const sorted = useMemo(() => [...regions].sort((a, b) => a.start - b.start), [regions]);

  const lines = useMemo(() => {
    const allLines = text.split("\n");
    let charOffset = 0;
    return allLines.map((line, _li) => {
      const prevOffset = charOffset;
      charOffset += line.length + 1;

      const lineRegions = sorted.filter(
        (r) => r.start < prevOffset + line.length && r.end > prevOffset
      );

      return { line, regions: lineRegions, charOffset: prevOffset };
    });
  }, [text, sorted]);

  return (
    <ProvenanceCard className="prov-bracket-card">
      <div className="prov-bracket-text">
        {lines.map(({ line, regions: lineRegions }, li) => (
          <div key={li} className="prov-bracket-row">
            <div className="prov-bracket-line">{line || "\u00a0"}</div>
            {lineRegions.length > 0 && (
              <div className="prov-bracket-track">
                {lineRegions.map((r, ri) => {
                  const rIdx = sorted.indexOf(r);
                  const isHovered = hoveredIdx === rIdx;
                  const color = sourceCountColor(r.sourceCount);
                  return (
                    <span
                      key={ri}
                      className={`prov-bracket-mark ${isHovered ? "prov-bracket-mark-active" : ""}`}
                      style={{ borderColor: color }}
                      onMouseEnter={() => setHoveredIdx(rIdx)}
                      onMouseLeave={() => setHoveredIdx(null)}
                    >
                      {isHovered && (
                        <span className="prov-bracket-tooltip">
                          {r.sourceCount} source{r.sourceCount !== 1 ? "s" : ""}
                          {r.sources.slice(0, 3).map((s, si) => (
                            <span key={si} className="prov-tooltip-source">
                              <span className="prov-heatmap-dot" style={{ backgroundColor: s.color }} />
                              {s.author}
                            </span>
                          ))}
                          {r.sources.length > 3 && <span>+{r.sources.length - 3} more</span>}
                        </span>
                      )}
                    </span>
                  );
                })}
              </div>
            )}
          </div>
        ))}
      </div>
    </ProvenanceCard>
  );
}

interface ExtensionBadgeProps {
  text: string;
  regions: ProvenanceRegion[];
}

export function ExtensionBadgeWidget({ text, regions }: ExtensionBadgeProps) {
  const [hoveredIdx, setHoveredIdx] = useState<number | null>(null);

  const segments = useMemo(() => {
    const result: {
      text: string;
      count: number;
      color: string;
      sources: SourceInfo[];
      regionIdx: number;
    }[] = [];

    let pos = 0;
    const sorted = [...regions].sort((a, b) => a.start - b.start);
    for (let ri = 0; ri < sorted.length; ri++) {
      const r = sorted[ri];
      if (r.start > pos) {
        result.push({ text: text.slice(pos, r.start), count: 0, color: "transparent", sources: [], regionIdx: -1 });
      }
      result.push({
        text: text.slice(r.start, r.end),
        count: r.sourceCount,
        color: sourceCountColor(r.sourceCount),
        sources: r.sources,
        regionIdx: ri,
      });
      pos = r.end;
    }
    if (pos < text.length) {
      result.push({ text: text.slice(pos), count: 0, color: "transparent", sources: [], regionIdx: -1 });
    }
    return result;
  }, [text, regions]);

  return (
    <ProvenanceCard className="prov-ext-card">
      <div className="prov-ext-text">
        {segments.map((seg, i) => (
          <span key={i} className="prov-ext-segment">
            <span
              className="prov-ext-content"
              style={{
                backgroundColor: hoveredIdx === seg.regionIdx ? sourceCountTint(seg.count).replace(/[\d.]+\)$/, "0.2)") : "transparent",
                transition: "background-color 0.15s",
              }}
              onMouseEnter={() => seg.count > 0 && setHoveredIdx(seg.regionIdx)}
              onMouseLeave={() => setHoveredIdx(null)}
            >
              {seg.text}
            </span>
            {seg.count > 0 && (
              <span
                className="prov-ext-badge"
                style={{ backgroundColor: seg.color }}
                onMouseEnter={() => setHoveredIdx(seg.regionIdx)}
                onMouseLeave={() => setHoveredIdx(null)}
              >
                {seg.count}
                {hoveredIdx === seg.regionIdx && (
                  <span className="prov-ext-tooltip">
                    {seg.sources.map((s, si) => (
                      <span key={si} className="prov-tooltip-source">
                        <span className="prov-heatmap-dot" style={{ backgroundColor: s.color }} />
                        {s.author} ({s.title})
                      </span>
                    ))}
                  </span>
                )}
              </span>
            )}
          </span>
        ))}
      </div>
    </ProvenanceCard>
  );
}

interface ColourBehindTextProps {
  text: string;
  regions: ProvenanceRegion[];
  onExploreProvenance?: (region: ProvenanceRegion) => void;
}

export function ColourBehindTextWidget({ text, regions, onExploreProvenance }: ColourBehindTextProps) {
  const segments = useMemo(() => {
    const result: {
      text: string;
      bgColor: string;
      sources: SourceInfo[];
      count: number;
    }[] = [];

    let pos = 0;
    const sorted = [...regions].sort((a, b) => a.start - b.start);
    for (const r of sorted) {
      if (r.start > pos) {
        result.push({ text: text.slice(pos, r.start), bgColor: "transparent", sources: [], count: 0 });
      }
      const alpha = Math.min(0.35, 0.08 + r.sourceCount * 0.04);
      const baseColor = sourceCountColor(r.sourceCount);
      result.push({
        text: text.slice(r.start, r.end),
        bgColor: hexToRgba(baseColor, alpha),
        sources: r.sources,
        count: r.sourceCount,
      });
      pos = r.end;
    }
    if (pos < text.length) {
      result.push({ text: text.slice(pos), bgColor: "transparent", sources: [], count: 0 });
    }
    return result;
  }, [text, regions]);

  return (
    <ProvenanceCard className="prov-color-card">
      <div className="prov-color-text">
        {segments.map((seg, i) => (
          <span
            key={i}
            className="prov-color-segment"
            style={{
              backgroundColor: seg.bgColor,
              cursor: seg.sources.length > 0 ? "pointer" : "inherit",
              borderRadius: seg.count > 0 ? "2px" : "0",
            }}
            onClick={() => seg.sources.length > 0 && onExploreProvenance?.({
              start: 0,
              end: 0,
              sourceCount: seg.count,
              sources: seg.sources,
            })}
            title={seg.sources.length > 0
              ? `${seg.count} source${seg.count !== 1 ? "s" : ""} — click to explore`
              : undefined
            }
          >
            {seg.text}
          </span>
        ))}
      </div>
    </ProvenanceCard>
  );
}

function hexToRgba(hex: string, alpha: number): string {
  if (hex === "transparent") return "transparent";
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

type WidgetMode = "heatmap" | "dots" | "underline" | "tints" | "brackets" | "extension" | "color-behind";

interface ProvenanceOverlayProps {
  text: string;
  spans: AttributionSpan[];
  visible: boolean;
}

const WIDGET_LABELS: Record<WidgetMode, string> = {
  heatmap: "Heat Map",
  dots: "Dot Density",
  underline: "Underline",
  tints: "Background Tints",
  brackets: "Bracket Hints",
  extension: "Extension Badge",
  "color-behind": "Colour Behind",
};

export function ProvenanceOverlay({ text, spans, visible }: ProvenanceOverlayProps) {
  const [mode, setMode] = useState<WidgetMode>("heatmap");

  const regions = useMemo(() => spansToRegions(spans), [spans]);

  if (!visible) return null;

  return (
    <div className="prov-overlay">
      <div className="prov-mode-bar">
        {(Object.keys(WIDGET_LABELS) as WidgetMode[]).map((m) => (
          <button
            key={m}
            className={`prov-mode-btn ${mode === m ? "prov-mode-active" : ""}`}
            onClick={() => setMode(m)}
            type="button"
          >
            {WIDGET_LABELS[m]}
          </button>
        ))}
      </div>
      <div className="prov-widget-area">
        {mode === "heatmap" && <HeatMapWidget text={text} regions={regions} />}
        {mode === "dots" && <DotDensityWidget text={text} regions={regions} />}
        {mode === "underline" && <UnderlineWidget text={text} regions={regions} />}
        {mode === "tints" && <BackgroundTintsWidget text={text} regions={regions} />}
        {mode === "brackets" && <BracketHintsWidget text={text} regions={regions} />}
        {mode === "extension" && <ExtensionBadgeWidget text={text} regions={regions} />}
        {mode === "color-behind" && <ColourBehindTextWidget text={text} regions={regions} />}
      </div>
      <div className="prov-legend">
        <span className="prov-legend-item">
          <span className="prov-legend-dot" style={{ backgroundColor: "#4caf50" }} />
          1 source
        </span>
        <span className="prov-legend-item">
          <span className="prov-legend-dot" style={{ backgroundColor: "#64b5f6" }} />
          2-3 sources
        </span>
        <span className="prov-legend-item">
          <span className="prov-legend-dot" style={{ backgroundColor: "#ab47bc" }} />
          4-8 sources
        </span>
        <span className="prov-legend-item">
          <span className="prov-legend-dot" style={{ backgroundColor: "#fdd835" }} />
          9+ sources
        </span>
      </div>
    </div>
  );
}
