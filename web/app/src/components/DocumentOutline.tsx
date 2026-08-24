import { useMemo, useState, useEffect, useRef } from "react";
import { buildOutline, normalizeLevels } from "../outline";

interface DocumentOutlineProps {
  text: string;
  onNavigate: (charPos: number) => void;
  activeCharPos: number | null;
}

export function DocumentOutlinePanel({ text, onNavigate, activeCharPos }: DocumentOutlineProps) {
  const entries = useMemo(() => normalizeLevels(buildOutline(text)), [text]);
  const [filter, setFilter] = useState("");
  const [headingsOnly, setHeadingsOnly] = useState(false);
  const listRef = useRef<HTMLDivElement>(null);
  const [activeIdx, setActiveIdx] = useState<number | null>(null);

  const visible = useMemo(() => {
    const q = filter.trim().toLowerCase();
    return entries
      .map((e, i) => ({ ...e, i }))
      .filter((e) => (headingsOnly ? e.kind === "heading" : true))
      .filter((e) => (q ? e.label.toLowerCase().includes(q) : true));
  }, [entries, filter, headingsOnly]);

  useEffect(() => {
    if (activeCharPos === null) return;
    let best: number | null = null;
    for (let i = 0; i < entries.length; i++) {
      if (entries[i].charPos <= activeCharPos) best = i;
      else break;
    }
    setActiveIdx(best);
  }, [activeCharPos, entries]);

  useEffect(() => {
    if (activeIdx === null || !listRef.current) return;
    const el = listRef.current.querySelector<HTMLElement>(`[data-idx="${activeIdx}"]`);
    el?.scrollIntoView({ block: "nearest" });
  }, [activeIdx]);

  if (entries.length === 0) {
    return (
      <div className="outline-empty">
        No outline — the document is empty.
      </div>
    );
  }

  return (
    <div className="outline-panel">
      <div className="outline-controls">
        <input
          type="text"
          className="outline-filter"
          placeholder="Filter outline…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        />
        <button
          type="button"
          className={`outline-toggle ${headingsOnly ? "active" : ""}`}
          onClick={() => setHeadingsOnly((v) => !v)}
          title="Show headings only (or every paragraph)"
        >
          {headingsOnly ? "Headings" : "All"}
        </button>
      </div>
      <div className="outline-list" ref={listRef}>
        {visible.length === 0 && (
          <div className="outline-empty">No entries match.</div>
        )}
        {visible.map((e) => (
          <div
            key={e.i}
            data-idx={e.i}
            className={`outline-item ${e.kind} ${e.i === activeIdx ? "active" : ""}`}
            style={{ paddingLeft: 6 + (e.level - 1) * 14 }}
            onClick={() => onNavigate(e.charPos)}
            title={e.kind === "heading" ? `Heading level ${e.level}` : undefined}
          >
            <span className={`outline-marker ${e.kind}`} />
            <span className="outline-label">{e.label}</span>
          </div>
        ))}
      </div>
      <div className="outline-footer">
        {entries.filter((e) => e.kind === "heading").length} headings ·{" "}
        {entries.length} entries
      </div>
    </div>
  );
}
