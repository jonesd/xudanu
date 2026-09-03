import { useMemo, useState } from "react";
import type { WorkListEntry } from "../api/crdt_sync";

export interface StudioSidebarProps {
  works: WorkListEntry[];
  worksLoading: boolean;
  activeWorkId: number | null;
  currentClubId: number | null;
  onSelectWork: (workId: number) => void;
  onNewDocument: () => void;
}

type Filter = "all" | "mine" | "starred";

function timeAgo(ts?: number): string {
  if (!ts) return "";
  const s = Math.max(1, Math.floor(Date.now() / 1000 - ts));
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  return `${Math.floor(s / 86400)}d ago`;
}

/**
 * Design B — the documents column: titled works with recency metadata
 * and filters, replacing hex-ID list items with human titles.
 */
export function StudioSidebar({
  works,
  worksLoading,
  activeWorkId,
  currentClubId,
  onSelectWork,
  onNewDocument,
}: StudioSidebarProps) {
  const [filter, setFilter] = useState<Filter>("all");

  const filtered = useMemo(() => {
    let list = works;
    if (filter === "mine") list = works.filter((w) => w.owner != null && w.owner === currentClubId);
    if (filter === "starred") list = works.filter((w) => w.is_starred);
    return [...list].sort((a, b) => (b.updated_at ?? 0) - (a.updated_at ?? 0));
  }, [works, filter, currentClubId]);

  return (
    <nav className="ws-studio-list" aria-label="Documents">
      <div className="ws-studio-list-head">
        Documents <span className="ws-studio-count">{works.length}</span>
        <button className="ws-studio-newdoc" onClick={onNewDocument} title="New document (N)">
          ＋
        </button>
      </div>
      <div className="ws-studio-filters" role="tablist">
        {(["all", "mine", "starred"] as Filter[]).map((f) => (
          <button
            key={f}
            role="tab"
            aria-selected={filter === f}
            className={`ws-studio-filter ${filter === f ? "on" : ""}`}
            onClick={() => setFilter(f)}
          >
            {f === "all" ? "All" : f === "mine" ? "Mine" : "☆ Starred"}
          </button>
        ))}
      </div>
      <div className="ws-studio-docs">
        {worksLoading && <div className="ws-studio-meta">Loading…</div>}
        {!worksLoading && filtered.length === 0 && (
          <div className="ws-studio-meta">
            {works.length === 0 ? "No documents yet — press ＋ to start." : "Nothing matches this filter."}
          </div>
        )}
        {filtered.map((w) => (
          <button
            key={w.work_id}
            className={`ws-studio-doc ${w.work_id === activeWorkId ? "active" : ""}`}
            onClick={() => onSelectWork(w.work_id)}
          >
            <span className="ws-studio-doc-t">{w.title?.trim() || "Untitled"}</span>
            <span className="ws-studio-doc-m">
              {timeAgo(w.updated_at) || `${w.revision_count} revisions`}
              {w.is_starred ? " · ☆" : ""}
            </span>
          </button>
        ))}
      </div>
    </nav>
  );
}
