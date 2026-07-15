import { useMemo, useState } from "react";
import type {
  LinkEntry,
  BacklinkEntry,
  SpanRangePayload,
  CrossServerBacklinkPayload,
} from "../api/crdt_sync";

const LINK_TYPE_LABELS: Record<number, string> = {
  1: "Comment",
  2: "Reference",
  3: "Disagreement",
  4: "Quotation",
  5: "See Also",
  6: "Web Link",
};

interface RelatedItem {
  key: string;
  title: string;
  reason: string;
  excerpt: string;
  workId: number | null;
  remoteUrl: string | null;
}

interface RelatedFooterProps {
  backlinks: BacklinkEntry[];
  outgoingLinks: LinkEntry[];
  compoundSpanRanges: SpanRangePayload[];
  compoundSourceTitles: Record<number, string>;
  crossServerBacklinks: CrossServerBacklinkPayload[];
  currentWorkId: number;
  onNavigateToWork: (workId: number) => void;
}

const MAX_ITEMS = 8;

export function RelatedFooter({
  backlinks,
  outgoingLinks,
  compoundSpanRanges,
  compoundSourceTitles,
  crossServerBacklinks,
  currentWorkId,
  onNavigateToWork,
}: RelatedFooterProps) {
  const items = useMemo(() => {
    const seen = new Set<string>();
    const result: RelatedItem[] = [];

    const add = (item: RelatedItem) => {
      const dedupKey = item.remoteUrl ?? `work-${item.workId}`;
      if (seen.has(dedupKey)) return;
      seen.add(dedupKey);
      result.push(item);
    };

    for (const bl of backlinks) {
      add({
        key: `bl-${bl.link_id}`,
        title: bl.title || `Work ${bl.source_work_id.toString(16).padStart(4, "0")}`,
        reason: bl.link_type ? `Referenced (${bl.link_type})` : "Referenced by",
        excerpt: (bl.excerpt || "").slice(0, 120),
        workId: bl.source_work_id,
        remoteUrl: null,
      });
    }

    for (const csb of crossServerBacklinks) {
      add({
        key: `csb-${csb.origin_server_address}-${csb.origin_work_id}`,
        title: csb.origin_work_title || csb.origin_server_name || csb.origin_server_address,
        reason: `Cross-server (${csb.link_type || "link"})`,
        excerpt: (csb.excerpt || "").slice(0, 120),
        workId: null,
        remoteUrl: `https://${csb.origin_server_address}/api/public/work/${csb.origin_work_id}`,
      });
    }

    for (const link of outgoingLinks) {
      const isWebLink = link.link_types?.[0] === 6;
      if (isWebLink) {
        const url = link.destination_ref?.excerpt || "";
        add({
          key: `web-${link.link_id}`,
          title: link.destination_title || url.slice(0, 60) || "Web Link",
          reason: "Web Link",
          excerpt: url.slice(0, 120),
          workId: null,
          remoteUrl: url.startsWith("http") ? url : null,
        });
        continue;
      }

      const isOutgoing = link.origin === currentWorkId;
      const targetWorkId = isOutgoing ? link.destination : link.origin;
      if (targetWorkId === currentWorkId) continue;

      const typeId = link.link_types?.[0] ?? 0;
      const typeName = LINK_TYPE_LABELS[typeId] || "Link";
      const title = isOutgoing
        ? (link.destination_title || "Untitled")
        : (link.origin_title || "Untitled");
      const excerpt = link.origin_ref?.excerpt || link.destination_ref?.excerpt || "";

      add({
        key: `link-${link.link_id}`,
        title,
        reason: typeName,
        excerpt: excerpt.slice(0, 120),
        workId: targetWorkId,
        remoteUrl: null,
      });
    }

    const sourceIds = new Set<number>();
    for (const sr of compoundSpanRanges) {
      if (sourceIds.has(sr.source_work_id)) continue;
      if (sr.source_work_id === currentWorkId) continue;
      sourceIds.add(sr.source_work_id);
      add({
        key: `src-${sr.source_work_id}`,
        title: compoundSourceTitles[sr.source_work_id] || `Work ${sr.source_work_id.toString(16).padStart(4, "0")}`,
        reason: "Includes content from",
        excerpt: (sr.resolved_content || "").slice(0, 120),
        workId: sr.source_work_id,
        remoteUrl: null,
      });
    }

    return result.slice(0, MAX_ITEMS);
  }, [backlinks, outgoingLinks, compoundSpanRanges, compoundSourceTitles, crossServerBacklinks, currentWorkId]);

  const [collapsed, setCollapsed] = useState(false);

  const totalCount = useMemo(() => {
    const ids = new Set<string>();
    for (const bl of backlinks) ids.add(`w-${bl.source_work_id}`);
    for (const csb of crossServerBacklinks) ids.add(`r-${csb.origin_server_address}`);
    for (const link of outgoingLinks) {
      const isWebLink = link.link_types?.[0] === 6;
      if (isWebLink) ids.add(`web-${link.link_id}`);
      else {
        const target = link.origin === currentWorkId ? link.destination : link.origin;
        if (target !== currentWorkId) ids.add(`w-${target}`);
      }
    }
    for (const sr of compoundSpanRanges) {
      if (sr.source_work_id !== currentWorkId) ids.add(`w-${sr.source_work_id}`);
    }
    return ids.size;
  }, [backlinks, outgoingLinks, compoundSpanRanges, crossServerBacklinks, currentWorkId]);

  if (totalCount === 0) return null;

  return (
    <div className="related-footer-panel">
      <button
        type="button"
        className="related-footer-toggle"
        onClick={() => setCollapsed((c) => !c)}
      >
        <span className="related-footer-header">Related</span>
        <span className="related-footer-count">{totalCount}</span>
        <span className="related-footer-chevron">{collapsed ? "\u25B2" : "\u25BC"}</span>
      </button>
      {!collapsed && (
        <div className="related-footer-grid">
          {items.map((item) => (
            <button
              key={item.key}
              type="button"
              className="related-card"
              onClick={() => {
                if (item.workId !== null) {
                  onNavigateToWork(item.workId);
                } else if (item.remoteUrl) {
                  window.open(item.remoteUrl, "_blank", "noopener,noreferrer");
                }
              }}
            >
              <div className="related-card-reason">{item.reason}</div>
              <div className="related-card-title">{item.title}</div>
              {item.excerpt && <div className="related-card-excerpt">{item.excerpt}</div>}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
