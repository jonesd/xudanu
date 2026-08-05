import { useState, useEffect, useCallback } from "react";
import type { CrdtSyncClient, RevisionMeta } from "../api/crdt_sync";

interface RevisionTimelineProps {
  workId: number | null;
  client: CrdtSyncClient | null;
  onViewRevision: (revisionId: number, text: string) => void;
}

function formatDate(ts: number): string {
  if (ts === 0) return "unknown date";
  return new Date(ts * 1000).toISOString().slice(0, 10);
}

export function RevisionTimeline({ workId, client, onViewRevision }: RevisionTimelineProps) {
  const [revisions, setRevisions] = useState<RevisionMeta[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [editingDesc, setEditingDesc] = useState<number | null>(null);
  const [descText, setDescText] = useState("");
  const [viewingRevision, setViewingRevision] = useState<number | null>(null);

  const loadRevisions = useCallback(async () => {
    if (!client || workId === null) {
      setRevisions([]);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const list = await client.workRevisionsList(workId);
      setRevisions(list);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [client, workId]);

  useEffect(() => {
    void loadRevisions();
  }, [loadRevisions]);

  const handleView = useCallback(async (revisionId: number) => {
    if (!client || workId === null) return;
    setViewingRevision(revisionId);
    try {
      const text = await client.workTextAtRevision(workId, revisionId);
      onViewRevision(revisionId, text);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
      setViewingRevision(null);
    }
  }, [client, workId, onViewRevision]);

  const handleSaveDescription = useCallback(async (revisionId: number) => {
    if (!client || workId === null) return;
    try {
      await client.workRevisionDescribe(workId, revisionId, descText);
      setEditingDesc(null);
      await loadRevisions();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  }, [client, workId, descText, loadRevisions]);

  const handleToggleNotable = useCallback(async (revisionId: number, current: boolean) => {
    if (!client || workId === null) return;
    try {
      await client.workRevisionMarkNotable(workId, revisionId, !current);
      await loadRevisions();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  }, [client, workId, loadRevisions]);

  if (loading) {
    return <div className="ws-placeholder"><div className="ws-placeholder-label">Loading revisions…</div></div>;
  }

  if (error) {
    return (
      <div>
        <div className="ws-picker-error">{error}</div>
        <button className="ws-more-tab-btn" onClick={loadRevisions}>Retry</button>
      </div>
    );
  }

  if (revisions.length === 0) {
    return (
      <div className="ws-placeholder">
        <div className="ws-placeholder-label">No revisions yet</div>
        <div className="ws-placeholder-sublabel">Edit the document to create revisions</div>
      </div>
    );
  }

  const sorted = [...revisions].reverse();

  return (
    <div className="ws-timeline">
      {sorted.map((rev) => {
        const isCurrent = rev.revision_id === revisions.length - 1;
        const isEditing = editingDesc === rev.revision_id;
        return (
          <div
            key={rev.revision_id}
            className={`ws-timeline-item ${rev.is_notable ? "notable" : ""} ${viewingRevision === rev.revision_id ? "viewing" : ""}`}
          >
            <div className="ws-timeline-marker">
              {rev.is_notable ? "★" : "○"}
            </div>
            <div className="ws-timeline-content">
              <div className="ws-timeline-header">
                <span className="ws-timeline-rev">
                  {isCurrent ? "Current" : `v${rev.revision_id}`}
                </span>
                <span className="ws-timeline-date">{formatDate(rev.created_at)}</span>
              </div>
              {isEditing ? (
                <div className="ws-timeline-edit">
                  <input
                    type="text"
                    className="ws-picker-search"
                    value={descText}
                    onChange={(e) => setDescText(e.target.value)}
                    placeholder="Revision description…"
                    autoFocus
                    onKeyDown={(e) => {
                      if (e.key === "Enter") void handleSaveDescription(rev.revision_id);
                      if (e.key === "Escape") setEditingDesc(null);
                    }}
                  />
                  <button className="ws-timeline-btn save" onClick={() => handleSaveDescription(rev.revision_id)}>Save</button>
                  <button className="ws-timeline-btn" onClick={() => setEditingDesc(null)}>Cancel</button>
                </div>
              ) : (
                <>
                  {rev.description ? (
                    <div className="ws-timeline-desc">{rev.description}</div>
                  ) : (
                    <div
                      className="ws-timeline-desc empty"
                      onClick={() => {
                        setEditingDesc(rev.revision_id);
                        setDescText("");
                      }}
                    >
                      + Add description
                    </div>
                  )}
                  {rev.change_summary && (
                    <div className="ws-timeline-summary">{rev.change_summary}</div>
                  )}
                  <div className="ws-timeline-actions">
                    {!isCurrent && (
                      <button
                        className="ws-timeline-btn"
                        onClick={() => handleView(rev.revision_id)}
                        title="View this revision"
                      >
                        View
                      </button>
                    )}
                    <button
                      className="ws-timeline-btn"
                      onClick={() => {
                        setEditingDesc(rev.revision_id);
                        setDescText(rev.description || "");
                      }}
                      title="Edit description"
                    >
                      Describe
                    </button>
                    <button
                      className={`ws-timeline-btn ${rev.is_notable ? "active" : ""}`}
                      onClick={() => handleToggleNotable(rev.revision_id, rev.is_notable)}
                      title={rev.is_notable ? "Remove notable flag" : "Mark as notable"}
                    >
                      {rev.is_notable ? "★ Notable" : "☆ Mark"}
                    </button>
                    {!isCurrent && (
                      <button
                        className="ws-timeline-btn rollback"
                        onClick={() => {
                          if (confirm(`Roll back to revision ${rev.revision_id}? This creates a new revision with the old content (non-destructive).`)) {
                            client?.workRevisionRollback(workId!, rev.revision_id).then(() => loadRevisions());
                          }
                        }}
                        title="Non-destructive rollback"
                      >
                        Rollback
                      </button>
                    )}
                  </div>
                </>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}
