import { useState } from "react";
import type { LinkEntry, SpanRangePayload, BacklinkEntry } from "../../api/crdt_sync";
import { getTransclusionColor } from "../../hooks/useTransclusion";

const DEFAULT_LINK_TYPE_LABELS: Record<number, string> = {
  1: "Comment",
  2: "Reference",
  3: "Disagreement",
  4: "Quotation",
  5: "See Also",
};

interface ConnectionsSectionProps {
  transclusionLinks: LinkEntry[];
  backlinks: BacklinkEntry[];
  compoundSpanRanges: SpanRangePayload[];
  compoundSourceTitles: Record<number, string>;
  onNavigateToWork: (workId: number) => void;
}

export function ConnectionsSection({
  transclusionLinks,
  backlinks,
  compoundSpanRanges,
  compoundSourceTitles,
  onNavigateToWork,
}: ConnectionsSectionProps) {
  const [pinned, setPinned] = useState<Set<string>>(new Set());
  const [filter, setFilter] = useState("all");

  const togglePin = (key: string) => {
    setPinned((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  type ConnItem = {
    key: string;
    type: "transclusion" | "link" | "backlink";
    title: string;
    excerpt: string;
    meta: string;
    workId: number;
  };

  const items: ConnItem[] = [];

  for (const sr of compoundSpanRanges) {
    const key = `transcl-${sr.source_work_id}-${sr.char_start}-${sr.char_end}`;
    items.push({
      key,
      type: "transclusion",
      title: compoundSourceTitles[sr.source_work_id] || `work:${sr.source_work_id.toString(16)}`,
      excerpt: sr.resolved_content?.slice(0, 80) || "...",
      meta: `${sr.content_len || 0} chars`,
      workId: sr.source_work_id,
    });
  }

  const seenLinkIds = new Set<number>();
  for (const link of transclusionLinks) {
    if (seenLinkIds.has(link.link_id)) continue;
    seenLinkIds.add(link.link_id);
    if (compoundSpanRanges.some((sr) => sr.source_work_id === link.destination || sr.source_work_id === link.origin)) {
      const isTransclusionLink = !link.link_types || link.link_types.length === 0;
      if (isTransclusionLink) continue;
    }
    const key = `link-${link.link_id}`;
    const excerpt = link.origin_ref?.excerpt || link.destination_ref?.excerpt || "";
    const typeName = (link.link_types?.[0] && DEFAULT_LINK_TYPE_LABELS[link.link_types[0]]) || "link";
    items.push({
      key,
      type: "link",
      title: link.destination_title || link.origin_title || "Untitled",
      excerpt: excerpt.slice(0, 80),
      meta: typeName,
      workId: link.destination,
    });
  }

  for (const bl of backlinks) {
    const key = `backlink-${bl.link_id}`;
    items.push({
      key,
      type: "backlink",
      title: bl.title || `Work ${bl.source_work_id.toString(16).padStart(4, "0")}`,
      excerpt: (bl.excerpt || "").slice(0, 80),
      meta: bl.link_type || "link",
      workId: bl.source_work_id,
    });
  }

  const backlinkCount = backlinks.length;

  const filtered = items.filter((item) => {
    if (filter === "pinned") return pinned.has(item.key);
    if (filter === "transclusion") return item.type === "transclusion";
    if (filter === "link") return item.type === "link";
    if (filter === "backlink") return item.type === "backlink";
    return true;
  });

  const sorted = [...filtered].sort((a, b) => {
    const aPinned = pinned.has(a.key) ? 0 : 1;
    const bPinned = pinned.has(b.key) ? 0 : 1;
    if (aPinned !== bPinned) return aPinned - bPinned;
    const typeOrder = { transclusion: 0, link: 1, backlink: 2 };
    return typeOrder[a.type] - typeOrder[b.type];
  });

  if (items.length === 0) return null;

  const pinnedCount = [...pinned].filter((k) => items.some((i) => i.key === k)).length;

  return (
    <div className="ctx-section">
      <div className="ctx-header">
        <div className="ctx-title">Connections</div>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          style={{
            background: "var(--bg)",
            border: "1px solid var(--border)",
            borderRadius: 4,
            color: "var(--text-muted)",
            fontSize: 10,
            padding: "2px 4px",
            cursor: "pointer",
          }}
        >
          <option value="all">All ({items.length})</option>
          {pinnedCount > 0 && <option value="pinned">Pinned ({pinnedCount})</option>}
          {compoundSpanRanges.length > 0 && <option value="transclusion">Transclusions ({compoundSpanRanges.length})</option>}
          {transclusionLinks.length > 0 && <option value="link">Links ({transclusionLinks.length})</option>}
          {backlinkCount > 0 && <option value="backlink">Backlinks ({backlinkCount})</option>}
        </select>
      </div>

      {pinnedCount > 0 && (
        <div style={{ fontSize: 9, fontWeight: 600, textTransform: "uppercase", letterSpacing: 0.5, color: "var(--amber)", padding: "4px 0 2px" }}>
          Pinned
        </div>
      )}
      {sorted.map((item) => {
        const borderColor =
          item.type === "transclusion" ? getTransclusionColor(item.workId) :
          item.type === "backlink" ? "var(--green)" :
          "var(--blue)";
        return (
        <div
          key={item.key}
          className="conn-item"
          style={{
            borderLeft: `3px solid ${borderColor}`,
          }}
          onClick={() => onNavigateToWork(item.workId)}
        >
          <div className="conn-title" style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <span
              className="pin-toggle"
              onClick={(e) => { e.stopPropagation(); togglePin(item.key); }}
              style={{ color: pinned.has(item.key) ? "var(--amber)" : "var(--text-dim)" }}
            >
              {pinned.has(item.key) ? "★" : "☆"}
            </span>
            <span className={`conn-type-label ${item.type}`}>{item.type}</span>
            <span>{item.type === "transclusion" ? "→" : item.type === "backlink" ? "←" : "⇄"} {item.title}</span>
          </div>
          <div className="conn-excerpt">"{item.excerpt}{item.excerpt.length >= 100 ? "…" : ""}"</div>
          <div className="conn-meta">
            <span>{item.meta}</span>
          </div>
        </div>
        );
      })}
    </div>
  );
}
