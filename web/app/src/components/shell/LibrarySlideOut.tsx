import { useState, useMemo } from "react";
import type { WorkListEntry } from "../../api/crdt_sync";

interface LibrarySlideOutProps {
  works: WorkListEntry[];
  currentWorkId: number | null;
  onSelect: (workId: number) => void;
  onClose: () => void;
  onCreate: () => void;
  onImport: () => void;
  connected: boolean;
  identity: { display_name: string; club_id: number } | null;
  onToggleStar?: (workId: number, current: boolean) => void;
}

export function LibrarySlideOut({
  works,
  currentWorkId,
  onSelect,
  onClose,
  onCreate,
  onImport,
  connected,
  identity,
  onToggleStar,
}: LibrarySlideOutProps) {
  const [query, setQuery] = useState("");

  const filtered = useMemo(() => {
    if (!query.trim()) return works;
    const q = query.toLowerCase();
    return works.filter(
      (w) =>
        (w.title || "").toLowerCase().includes(q) ||
        w.work_id.toString(16).includes(q)
    );
  }, [works, query]);

  const sortByRecent = (a: WorkListEntry, b: WorkListEntry) => {
    const ta = a.updated_at ?? 0;
    const tb = b.updated_at ?? 0;
    if (ta !== tb) return tb - ta;
    return b.work_id - a.work_id;
  };

  const favorites = filtered.filter((w) => w.is_starred).sort(sortByRecent);
  const documents = filtered.filter((w) => !w.is_source && !w.is_starred).sort(sortByRecent);
  const sources = filtered.filter((w) => w.is_source).sort(sortByRecent);

  return (
    <div className="library-drawer">
      <div className="library-header">
        <input
          className="library-search-input"
          type="text"
          placeholder="Filter works…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          autoFocus
        />
        <button
          onClick={onClose}
          style={{
            background: "none",
            border: "none",
            color: "var(--text-muted)",
            cursor: "pointer",
            fontSize: 18,
            padding: "2px 6px",
          }}
          title="Close"
        >
          ×
        </button>
      </div>
      <div style={{ padding: "8px 12px", display: "flex", gap: 6 }}>
        {identity && (
          <button
            onClick={onCreate}
            style={{
              flex: 1,
              padding: "6px 10px",
              borderRadius: 6,
              border: "1px solid var(--border)",
              background: "var(--bg)",
              color: "var(--text)",
              fontSize: 12,
              fontWeight: 500,
              cursor: "pointer",
            }}
          >
            + New
          </button>
        )}
        {identity && (
          <button
            onClick={onImport}
            style={{
              flex: 1,
              padding: "6px 10px",
              borderRadius: 6,
              border: "1px solid var(--border)",
              background: "var(--bg)",
              color: "var(--text)",
              fontSize: 12,
              fontWeight: 500,
              cursor: "pointer",
            }}
          >
            Import Source
          </button>
        )}
      </div>
      <div className="library-list">
        {favorites.length > 0 && (
          <>
            <div className="library-section-label">★ Favorites</div>
            {favorites.map((w) => (
              <WorkItem key={w.work_id} work={w} active={w.work_id === currentWorkId} onSelect={onSelect} onToggleStar={onToggleStar} />
            ))}
          </>
        )}
        <div className="library-section-label">Documents</div>
        {documents.length === 0 && (
          <div style={{ padding: "8px 10px", fontSize: 12, color: "var(--text-dim)" }}>No documents</div>
        )}
        {documents.map((w) => (
          <WorkItem key={w.work_id} work={w} active={w.work_id === currentWorkId} onSelect={onSelect} onToggleStar={onToggleStar} />
        ))}
        {sources.length > 0 && (
          <>
            <div className="library-section-label">Source Works</div>
            {sources.map((w) => (
              <WorkItem key={w.work_id} work={w} active={w.work_id === currentWorkId} onSelect={onSelect} onToggleStar={onToggleStar} />
            ))}
          </>
        )}
        {filtered.length === 0 && works.length === 0 && (
          <div style={{ padding: "20px 10px", fontSize: 13, color: "var(--text-dim)", textAlign: "center" }}>
            {connected ? "No works yet. Create one to get started." : "Not connected."}
          </div>
        )}
      </div>
    </div>
  );
}

function formatRelativeTime(epochSecs: number): string {
  const now = Math.floor(Date.now() / 1000);
  const diff = Math.max(0, now - epochSecs);
  if (diff < 60) return "just now";
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`;
  return new Date(epochSecs * 1000).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
  });
}

function WorkItem({
  work,
  active,
  onSelect,
  onToggleStar,
}: {
  work: WorkListEntry;
  active: boolean;
  onSelect: (id: number) => void;
  onToggleStar?: (workId: number, current: boolean) => void;
}) {
  const typeLabel = work.is_source ? "Source" : "Document";
  const revLabel = `${work.revision_count} revision${work.revision_count === 1 ? "" : "s"}`;
  return (
    <div
      className={`library-item ${active ? "active" : ""}`}
      onClick={() => onSelect(work.work_id)}
    >
      <div className="library-item-row">
        {onToggleStar && (
          <button
            className={`library-star ${work.is_starred ? "starred" : ""}`}
            onClick={(e) => { e.stopPropagation(); onToggleStar(work.work_id, !!work.is_starred); }}
            title={work.is_starred ? "Remove from favorites" : "Add to favorites"}
          >
            {work.is_starred ? "\u2605" : "\u2606"}
          </button>
        )}
        <span className="library-item-title">
          {work.is_source && (
            <span className="library-source-icon" title="Imported source work">
              {"\u{1F4D6}"}
            </span>
          )}
          {work.title || "Untitled"}
        </span>
        <span className="library-item-id">{work.work_id.toString(16).padStart(4, "0")}</span>
      </div>
      <div className="library-detail">
        <span>{typeLabel}</span>
        <span className="library-detail-sep">{"\u00B7"}</span>
        <span>{revLabel}</span>
        {work.updated_at ? (
          <>
            <span className="library-detail-sep">{"\u00B7"}</span>
            <span>edited {formatRelativeTime(work.updated_at)}</span>
          </>
        ) : null}
      </div>
    </div>
  );
}
