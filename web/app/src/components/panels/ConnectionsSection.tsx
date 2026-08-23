import { useState } from "react";
import type { LinkEntry, SpanRangePayload, BacklinkEntry, CrossServerBacklinkPayload } from "../../api/crdt_sync";
import { getTransclusionColor, DEFAULT_LINK_TYPES } from "../../hooks/useTransclusion";

const DEFAULT_LINK_TYPE_LABELS: Record<number, string> = {
  1: "Comment",
  2: "Reference",
  3: "Disagreement",
  4: "Quotation",
  5: "See Also",
  6: "Web Link",
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
  onRemoveTransclusion?: (sourceWorkId: number, charStart: number, charEnd: number) => void;
  pinnedKeys: Set<string>;
  onTogglePin: (key: string, pinned: boolean) => void;
  crossServerBacklinks?: CrossServerBacklinkPayload[];
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
  onRemoveTransclusion,
  pinnedKeys,
  onTogglePin,
  crossServerBacklinks = [],
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
    spanned?: boolean;
    transclusionSource?: number;
    transclusionStart?: number;
    transclusionEnd?: number;
  };

  const items: ConnItem[] = [];

  for (const sr of compoundSpanRanges) {
    const key = `transcl-${sr.source_work_id}-${sr.char_start}-${sr.char_end}`;
    items.push({
      key,
      type: "transclusion" as const,
      title: compoundSourceTitles[sr.source_work_id] || `work:${sr.source_work_id.toString(16)}`,
      excerpt: (sr.resolved_content || "").slice(0, 80),
      meta: `transclusion · [${sr.char_start}:${sr.char_end}]`,
      workId: sr.source_work_id,
      transclusionSource: sr.source_work_id,
      transclusionStart: sr.char_start,
      transclusionEnd: sr.char_end,
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
    const isWebLink = typeId === 6;
    items.push({
      key,
      type: "link",
      title: isWebLink ? excerpt : (link.destination_title || link.origin_title || "Untitled"),
      excerpt: excerpt.slice(0, 80),
      meta: typeName,
      workId: isOutgoing ? link.destination : link.origin,
      linkId: link.link_id,
      linkTypeId: typeId,
      // Outgoing with an anchored excerpt: the underline lives on
      // THIS document's text ("On this page"); otherwise it's a
      // whole-document link listed under "This document links out".
      spanned: isOutgoing && !!(link.origin_ref?.excerpt || "").trim(),
    });
  }

  for (const bl of backlinks) {
    // Archived-origin backlinks are noise: the connecting document is
    // dead (old demo copies). Hide them; the link survives server-side.
    if (bl.source_archived) continue;
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

  for (const csb of crossServerBacklinks) {
    const key = `csbacklink-${csb.origin_server_address}-${csb.origin_work_id}`;
    items.push({
      key,
      type: "backlink" as const,
      title: csb.origin_server_name || csb.origin_server_address,
      excerpt: csb.excerpt.slice(0, 80),
      meta: `cross-server · "${csb.origin_server_address}".${csb.origin_work_id}`,
      workId: 0,
    });
  }

  const backlinkCount = backlinks.length + crossServerBacklinks.length;

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
      {(() => {
        const sectionOf = (i: ConnItem): string => {
          if (i.type === "transclusion") return "Includes content from";
          if (i.type === "backlink") return "Incoming — on other documents";
          if (i.spanned) return "On this page";
          return "This document links out";
        };
        let lastSection = "";
        return sorted.map((item) => {
        const section = sectionOf(item);
        const header = section !== lastSection ? (
          <div key={`sec-${section}`} style={{ fontSize: 9, fontWeight: 600, textTransform: "uppercase", letterSpacing: 0.5, color: "var(--text-muted)", padding: "8px 0 2px" }}>
            {section}
          </div>
        ) : null;
        lastSection = section;
        const borderColor =
          item.type === "transclusion" ? getTransclusionColor(item.workId) :
          item.type === "backlink" ? "var(--green)" :
          "var(--blue)";
        return (
          <div key={item.key} className="conn-item-wrap">
          {header}
        <div
          className="conn-item"
          style={{
            borderLeft: `3px solid ${borderColor}`,
          }}
          onClick={() => {
            // Web links open externally — but only well-formed http(s)
            // URLs. A malformed excerpt must never reach window.open
            // (no javascript:, no relative paths hijacking the tab).
            if (item.linkTypeId === 6 && item.title && /^https?:\/\//i.test(item.title.trim())) {
              window.open(item.title.trim(), "_blank", "noopener,noreferrer");
            } else {
              onNavigateToWork(item.workId);
            }
          }}
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
                    {DEFAULT_LINK_TYPES.filter((t) => t.type_id !== 6).map((t) => (
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
                {item.type === "transclusion" && onRemoveTransclusion && item.transclusionSource !== undefined && (
                  <button
                    className="conn-delete-btn"
                    onClick={(e) => {
                      e.stopPropagation();
                      onRemoveTransclusion(item.transclusionSource!, item.transclusionStart!, item.transclusionEnd!);
                    }}
                    title="Remove transclusion"
                  >
                    {"\u2715"}
                  </button>
                )}
              </div>
            )}
          </div>
          <div className="conn-excerpt">&ldquo;{item.excerpt}{item.excerpt.length >= 100 ? "\u2026" : ""}&rdquo;</div>
          {!(item.type === "link" && canManage && item.linkId !== undefined && onRetypeLink) && (
            <div className="conn-meta">
              <span>{item.meta}</span>
            </div>
          )}
        </div>
        </div>
        );
        });
      })()}
    </div>
  );
}
