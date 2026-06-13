import { useState, useEffect, useCallback } from "react";
import type { CrdtSyncClient, TrailPayload } from "../api/crdt_sync";

interface Props {
  client: CrdtSyncClient | null;
  currentWorkId: number | null;
  onSelectWork: (workId: number) => void;
  onClose: () => void;
}

function hexId(id: number): string {
  return id.toString(16).padStart(4, "0");
}

export function TrailsPanel({ client, currentWorkId, onSelectWork, onClose }: Props) {
  const [trails, setTrails] = useState<TrailPayload[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [newName, setNewName] = useState("");

  const refresh = useCallback(async () => {
    if (!client) return;
    try {
      const list = await client.trailList();
      setTrails(list);
    } catch {}
    setLoading(false);
  }, [client]);

  useEffect(() => { refresh(); }, [refresh]);

  const handleCreate = async () => {
    if (!client || !newName.trim()) return;
    try {
      await client.trailCreate(newName.trim());
      setNewName("");
      await refresh();
    } catch {}
  };

  const handleDelete = async (trailId: number) => {
    if (!client) return;
    try {
      await client.trailDelete(trailId);
      if (expandedId === trailId) setExpandedId(null);
      await refresh();
    } catch {}
  };

  const handleAddCurrent = async (trailId: number) => {
    if (!client || !currentWorkId) return;
    try {
      await client.trailAddStop(trailId, currentWorkId);
      await refresh();
    } catch {}
  };

  const handleRemoveStop = async (trailId: number, stopIndex: number) => {
    if (!client) return;
    try {
      await client.trailRemoveStop(trailId, stopIndex);
      await refresh();
    } catch {}
  };

  const handleMoveStop = async (trailId: number, fromIdx: number, toIdx: number) => {
    if (!client) return;
    const trail = trails.find((t) => t.trail_id === trailId);
    if (!trail) return;
    const order = trail.stops.map((_, i) => i);
    const [removed] = order.splice(fromIdx, 1);
    order.splice(toIdx, 0, removed);
    try {
      await client.trailReorderStops(trailId, order);
      await refresh();
    } catch {}
  };

  return (
    <div className="panel-overlay" onClick={onClose}>
      <div className="panel-dialog" onClick={(e) => e.stopPropagation()}>
        <div className="panel-header">
          <span className="panel-title">Trails</span>
          <button type="button" className="panel-close" onClick={onClose}>{"\u00d7"}</button>
        </div>
        <div className="panel-body">
          {loading ? (
            <div className="panel-empty">Loading trails...</div>
          ) : (
            <>
              <div className="trail-create-row">
                <input
                  type="text"
                  className="trail-input"
                  placeholder="New trail name..."
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  onKeyDown={(e) => { if (e.key === "Enter") handleCreate(); }}
                />
                <button
                  type="button"
                  className="trail-create-btn"
                  disabled={!newName.trim()}
                  onClick={handleCreate}
                >
                  Create
                </button>
              </div>

              {trails.length === 0 && (
                <div className="panel-empty">No trails yet. Create one above to start curating document sequences.</div>
              )}

              {trails.map((trail) => (
                <div key={trail.trail_id} className="trail-card">
                  <div
                    className="trail-card-header"
                    onClick={() => setExpandedId(expandedId === trail.trail_id ? null : trail.trail_id)}
                  >
                    <span className="trail-card-arrow">{expandedId === trail.trail_id ? "\u25be" : "\u25b8"}</span>
                    <span className="trail-card-name">{trail.name}</span>
                    <span className="trail-card-count">{trail.stops.length} stop{trail.stops.length !== 1 ? "s" : ""}</span>
                    {currentWorkId && (
                      <button
                        type="button"
                        className="trail-add-stop-btn"
                        onClick={(e) => { e.stopPropagation(); handleAddCurrent(trail.trail_id); }}
                        title="Add current document"
                      >
                        +
                      </button>
                    )}
                    <button
                      type="button"
                      className="trail-delete-btn"
                      onClick={(e) => { e.stopPropagation(); handleDelete(trail.trail_id); }}
                      title="Delete trail"
                    >
                      {"\u00d7"}
                    </button>
                  </div>
                  {expandedId === trail.trail_id && (
                    <div className="trail-stops">
                      {trail.stops.length === 0 && (
                        <div className="trail-stop-empty">No stops yet</div>
                      )}
                      {trail.stops.map((stop, idx) => (
                        <div key={idx} className="trail-stop">
                          <span className="trail-stop-number">{idx + 1}</span>
                          <span
                            className={`trail-stop-title ${stop.work_id === currentWorkId ? "active" : ""}`}
                            onClick={() => { onSelectWork(stop.work_id); onClose(); }}
                          >
                            {stop.title || `Work ${hexId(stop.work_id)}`}
                          </span>
                          {stop.note && <span className="trail-stop-note" title={stop.note}>{stop.note.length > 20 ? stop.note.slice(0, 20) + "\u2026" : stop.note}</span>}
                          <span className="trail-stop-actions">
                            {idx > 0 && (
                              <button type="button" className="trail-move-btn" onClick={() => handleMoveStop(trail.trail_id, idx, idx - 1)} title="Move up">{"\u25b2"}</button>
                            )}
                            {idx < trail.stops.length - 1 && (
                              <button type="button" className="trail-move-btn" onClick={() => handleMoveStop(trail.trail_id, idx, idx + 1)} title="Move down">{"\u25bc"}</button>
                            )}
                            <button type="button" className="trail-remove-stop-btn" onClick={() => handleRemoveStop(trail.trail_id, idx)} title="Remove stop">{"\u00d7"}</button>
                          </span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
