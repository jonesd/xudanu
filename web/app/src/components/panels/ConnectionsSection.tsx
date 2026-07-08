import { useState } from "react";
import type { LinkEntry, SpanRangePayload, BacklinkEntry } from "../../api/crdt_sync";
import { getTransclusionColor, DEFAULT_LINK_TYPES } from "../../hooks/useTransclusion";

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
  currentWorkId: number | null;
  onNavigateToWork: (workId: number) => void;
  onDeleteLink?: (linkId: number) => void;
  onRetypeLink?: (linkId: number, typeId: number) => void;
  pinnedKeys: Set<string>;
  onTogglePin: (key: string, pinned: boolean) => void;
}

export function ConnectionsSection({
  transclusionLinks,
  backlinks,
  compoundSpanRanges,
  compoundSourceTitles,
  currentWorkId,
  onNavigateToWork,
  onDeleteLink,
  onRetypeLink,
  pinnedKeys,
  onTogglePin,
}: ConnectionsSectionProps) {
  const [filter, setFilter] = useState("all");

  const togglePin = (key: string) => {
    const isPinned = pinnedKeys.has(key);
    onTogglePin(key, !isPinned);
  };

  type ConnItem = {
    key: string;
    type: "transclusion" | "link" | "backlink";
    title: string;
    excerpt: string;
    meta: string;
    workId: number;
    linkId?: number;
    linkTypeId?: number;
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
    const typeId = link.link_types?.[0] ?? 0;
    const typeName = DEFAULT_LINK_TYPE_LABELS[typeId] || "link";
    const isOutgoing = currentWorkId !== null && link.origin === currentWorkId;
    items.push({
      key,
      type: "link",
      title: link.destination_title || link.origin_title || "Untitled",
      excerpt: excerpt.slice(0, 80),
      meta: typeName,
      workId: isOutgoing ? link.destination : link.origin,
      linkId: link.link_id,
      linkTypeId: typeId,
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
      linkId: bl.link_id,
    });
  }

  const backlinkCount = backlinks.length;

  const filtered = items.filter((item) => {
    if (filter === "pinned") return pinnedKeys.has(item.key);
    if (filter === "transclusion") return item.type === "transclusion";
    if (filter === "link") return item.type === "link";
    if (filter === "backlink") return item.type === "backlink";
    return true;
  });

  const sorted = [...filtered].sort((a, b) => {
    const aPinned = pinnedKeys.has(a.key) ? 0 : 1;
    const bPinned = pinnedKeys.has(b.key) ? 0 : 1;
    if (aPinned !== bPinned) return aPinned - bPinned;
    const typeOrder = { transclusion: 0, link: 1, backlink: 2 };
    return typeOrder[a.type] - typeOrder[b.type];
  });

  if (items.length === 0) return null;

  const pinnedCount = [...pinnedKeys].filter((k) => items.some((i) => i.key === k)).length;
  const canManage = onDeleteLink !== undefined;

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
              style={{ color: pinnedKeys.has(item.key) ? "var(--amber)" : "var(--text-dim)" }}
            >
              {pinnedKeys.has(item.key) ? "\u2605" : "\u2606"}
            </span>
            <span className={`conn-type-label ${item.type}`}>{item.type}</span>
            <span>{item.type === "transclusion" ? "\u2192" : item.type === "backlink" ? "\u2190" : "\u21c4"} {item.title}</span>
            {canManage && item.linkId !== undefined && (
              <div className="conn-item-actions" style={{ marginLeft: "auto" }}>
                {item.type === "link" && onRetypeLink && (
                  <select
                    className="conn-retype-select"
                    value={item.linkTypeId ?? 0}
                    onClick={(e) => e.stopPropagation()}
                    onChange={(e) => {
                      e.stopPropagation();
                      onRetypeLink(item.linkId!, parseInt(e.target.value, 10));
                    }}
                    title="Change link type"
                  >
                    {DEFAULT_LINK_TYPES.map((t) => (
                      <option key={t.type_id} value={t.type_id}>{t.name}</option>
                    ))}
                  </select>
                )}
                {onDeleteLink && (
                  <button
                    className="conn-delete-btn"
                    onClick={(e) => {
                      e.stopPropagation();
                      onDeleteLink(item.linkId!);
                    }}
                    title="Delete link"
                  >
                    {"\u2715"}
                  </button>
                )}
              </div>
            )}
          </div>
          <div className="conn-excerpt">&ldquo;{item.excerpt}{item.excerpt.length >= 100 ? "\u2026" : ""}&rdquo;</div>
          <div className="conn-meta">
            <span>{item.meta}</span>
          </div>
        </div>
        );
      })}
    </div>
  );
}
