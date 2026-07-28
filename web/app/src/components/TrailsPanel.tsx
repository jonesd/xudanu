import { useState, useEffect, useCallback, useRef } from "react";
import type { CrdtSyncClient, TrailPayload, WorkListEntry } from "../api/crdt_sync";
import { useDraggable } from "../hooks/useDraggable";

interface Props {
  client: CrdtSyncClient | null;
  currentWorkId: number | null;
  works: WorkListEntry[];
  onSelectWork: (workId: number) => void;
  onClose: () => void;
}

function hexId(id: number): string {
  return id.toString(16).padStart(4, "0");
}

function workLabel(workId: number, title: string | undefined, works: WorkListEntry[]): string {
  const hex = `0x${hexId(workId)}`;
  const resolved = title || works.find((w) => w.work_id === workId)?.title;
  return resolved ? `${hex} ${resolved}` : hex;
}

type Tab = "mine" | "discover";

function patchTrail(trails: TrailPayload[], trailId: number, fn: (t: TrailPayload) => TrailPayload): TrailPayload[] {
  return trails.map((t) => (t.trail_id === trailId ? fn(t) : t));
}

export function TrailsPanel({ client, currentWorkId, works, onSelectWork, onClose }: Props) {
  const { drag, onMouseDown, dialogRef } = useDraggable();
  const [tab, setTab] = useState<Tab>("mine");
  const [trails, setTrails] = useState<TrailPayload[]>([]);
  const [publishedTrails, setPublishedTrails] = useState<TrailPayload[]>([]);
  const [categories, setCategories] = useState<string[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [editingId, setEditingId] = useState<number | null>(null);

  const [newName, setNewName] = useState("");
  const [newIntro, setNewIntro] = useState("");
  const [newCategories, setNewCategories] = useState("");
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [remoteStopTrailId, setRemoteStopTrailId] = useState<number | null>(null);
  const [remoteServer, setRemoteServer] = useState("");
  const [remoteWorkId, setRemoteWorkId] = useState("");

  const loadedOnce = useRef(false);

  const refreshMine = useCallback(async () => {
    if (!client) return;
    try {
      const list = await client.trailList();
      setTrails(list);
    } catch {}
    setLoading(false);
    loadedOnce.current = true;
  }, [client]);

  const refreshDiscover = useCallback(async () => {
    if (!client) return;
    try {
      const [cats, list] = await Promise.all([
        client.trailListCategories(),
        client.trailListPublished(selectedCategory ?? undefined),
      ]);
      setCategories(cats);
      setPublishedTrails(list);
    } catch {}
    setLoading(false);
  }, [client, selectedCategory]);

  useEffect(() => {
    if (tab === "mine") refreshMine();
    else refreshDiscover();
  }, [tab, refreshMine, refreshDiscover]);

  const handleCreate = () => {
    if (!client || !newName.trim()) return;
    const cats = newCategories.split(",").map((c) => c.trim()).filter(Boolean);
    const intro = newIntro.trim() || undefined;
    const now = Date.now() / 1000 | 0;
    const tempId = -now;

    setTrails((prev) => [...prev, {
      trail_id: tempId,
      name: newName.trim(),
      introduction: intro,
      categories: cats,
      published: false,
      owner_club: 0,
      stops: [],
      created_at: now,
      updated_at: now,
    }]);
    setNewName("");
    setNewIntro("");
    setNewCategories("");
    setShowCreateForm(false);

    client.trailCreate(newName.trim(), intro, cats.length ? cats : undefined)
      .then((realId) => {
        setTrails((prev) => prev.map((t) => t.trail_id === tempId ? { ...t, trail_id: realId as number } : t));
      })
      .catch(() => {
        setTrails((prev) => prev.filter((t) => t.trail_id !== tempId));
      });
  };

  const handleDelete = (trailId: number) => {
    const snapshot = trails;
    setTrails((prev) => prev.filter((t) => t.trail_id !== trailId));
    if (expandedId === trailId) setExpandedId(null);
    client?.trailDelete(trailId).catch(() => setTrails(snapshot));
  };

  const handleAddCurrent = (trailId: number) => {
    if (!client || !currentWorkId) return;
    setTrails((prev) => patchTrail(prev, trailId, (t) => ({
      ...t,
      stops: [...t.stops, { work_id: currentWorkId, char_start: undefined, char_end: undefined, note: undefined, title: "" }],
    })));
    client.trailAddStop(trailId, currentWorkId).catch(() => refreshMine());
  };

  const handleAddRemoteStop = (trailId: number) => {
    if (!client || !remoteServer.trim() || !remoteWorkId.trim()) return;
    const workId = remoteWorkId.trim().startsWith("0x")
      ? parseInt(remoteWorkId.trim(), 16)
      : parseInt(remoteWorkId.trim(), 10);
    if (isNaN(workId)) { alert("Invalid work ID"); return; }
    const server = remoteServer.trim();
    setTrails((prev) => patchTrail(prev, trailId, (t) => ({
      ...t,
      stops: [...t.stops, { work_id: workId, char_start: undefined, char_end: undefined, note: undefined, title: `Remote: ${server}`, server_domain: server }],
    })));
    client.trailAddStop(trailId, workId, undefined, undefined, undefined, server)
      .then(() => { setRemoteStopTrailId(null); setRemoteServer(""); setRemoteWorkId(""); })
      .catch((e) => { alert(`Failed: ${e instanceof Error ? e.message : String(e)}`); refreshMine(); });
  };

  const handleRemoveStop = (trailId: number, stopIndex: number) => {
    const snapshot = trails;
    setTrails((prev) => patchTrail(prev, trailId, (t) => ({
      ...t,
      stops: t.stops.filter((_, i) => i !== stopIndex),
    })));
    client?.trailRemoveStop(trailId, stopIndex).catch(() => setTrails(snapshot));
  };

  const handleMoveStop = (trailId: number, fromIdx: number, toIdx: number) => {
    const trail = trails.find((t) => t.trail_id === trailId);
    if (!trail) return;
    const order = trail.stops.map((_, i) => i);
    const [removed] = order.splice(fromIdx, 1);
    order.splice(toIdx, 0, removed);

    const reorderedStops = order.map((i) => trail.stops[i]);
    setTrails((prev) => patchTrail(prev, trailId, (t) => ({ ...t, stops: reorderedStops })));
    client?.trailReorderStops(trailId, order).catch(() => setTrails(trails));
  };

  const handlePublish = (trailId: number) => {
    setTrails((prev) => patchTrail(prev, trailId, (t) => ({ ...t, published: true })));
    client?.trailPublish(trailId).catch((e) => {
      setTrails((prev) => patchTrail(prev, trailId, (t) => ({ ...t, published: false })));
      alert(`Publish failed: ${e instanceof Error ? e.message : String(e)}\n\nAre you signed in? Trail operations require authentication.`);
    });
  };

  const handleUnpublish = (trailId: number) => {
    setTrails((prev) => patchTrail(prev, trailId, (t) => ({ ...t, published: false })));
    client?.trailUnpublish(trailId).catch((e) => {
      setTrails((prev) => patchTrail(prev, trailId, (t) => ({ ...t, published: true })));
      alert(`Unpublish failed: ${e instanceof Error ? e.message : String(e)}`);
    });
  };

  const handleSaveEdit = (trailId: number, intro: string, cats: string) => {
    const catList = cats.split(",").map((c) => c.trim()).filter(Boolean);
    const snapshot = trails;
    setTrails((prev) => patchTrail(prev, trailId, (t) => ({
      ...t,
      introduction: intro || undefined,
      categories: catList,
    })));
    setEditingId(null);
    client?.trailUpdate(trailId, intro || null, catList).catch(() => setTrails(snapshot));
  };

  const renderStops = (trail: TrailPayload, interactive: boolean) => {
    if (trail.stops.length === 0) {
      return <div className="trail-stop-empty">No stops yet</div>;
    }
    return trail.stops.map((stop, idx) => (
      <div key={idx} className="trail-stop">
        <span className="trail-stop-number">{idx + 1}</span>
        {stop.server_domain ? (
          <span className="trail-stop-title remote" title={`Remote: ${stop.server_domain}`}>
            {"\u{1F310}"} {stop.title || `0x${hexId(stop.work_id)}`}
            <span className="trail-stop-server">{stop.server_domain}</span>
          </span>
        ) : (
          <span
            className={`trail-stop-title ${stop.work_id === currentWorkId ? "active" : ""}`}
            onClick={() => { onSelectWork(stop.work_id); }}
          >
            {workLabel(stop.work_id, stop.title, works)}
          </span>
        )}
        {stop.note && (
          <span className="trail-stop-note" title={stop.note}>
            {stop.note.length > 20 ? stop.note.slice(0, 20) + "\u2026" : stop.note}
          </span>
        )}
        {interactive && (
          <span className="trail-stop-actions">
            {idx > 0 && (
              <button type="button" className="trail-move-btn" onClick={() => handleMoveStop(trail.trail_id, idx, idx - 1)} title="Move up">{"\u25b2"}</button>
            )}
            {idx < trail.stops.length - 1 && (
              <button type="button" className="trail-move-btn" onClick={() => handleMoveStop(trail.trail_id, idx, idx + 1)} title="Move down">{"\u25bc"}</button>
            )}
            <button type="button" className="trail-remove-stop-btn" onClick={() => handleRemoveStop(trail.trail_id, idx)} title="Remove stop">{"\u00d7"}</button>
          </span>
        )}
      </div>
    ));
  };

  const renderTrailCard = (trail: TrailPayload, interactive: boolean) => {
    const isExpanded = expandedId === trail.trail_id;
    const isEditing = editingId === trail.trail_id;
    return (
      <div key={trail.trail_id} className="trail-card">
        <div
          className="trail-card-header"
          onClick={() => setExpandedId(isExpanded ? null : trail.trail_id)}
        >
          <span className="trail-card-arrow">{isExpanded ? "\u25be" : "\u25b8"}</span>
          <span className="trail-card-name">{trail.name}</span>
          {trail.published && <span className="trail-badge trail-badge-published">Published</span>}
          <span className="trail-card-count">{trail.stops.length} stop{trail.stops.length !== 1 ? "s" : ""}</span>
          {interactive && currentWorkId && (
            <button
              type="button"
              className="trail-add-stop-btn"
              onClick={(e) => { e.stopPropagation(); handleAddCurrent(trail.trail_id); }}
              title="Add current document"
            >+</button>
          )}
          {interactive && (
            <button
              type="button"
              className="trail-add-remote-btn"
              onClick={(e) => { e.stopPropagation(); setRemoteStopTrailId(remoteStopTrailId === trail.trail_id ? null : trail.trail_id); setRemoteServer(""); setRemoteWorkId(""); }}
              title="Add cross-server stop"
              style={{ fontSize: 11, background: "none", border: "1px solid #f97316", color: "#f97316", borderRadius: 3, cursor: "pointer", padding: "0 4px", marginLeft: 2 }}
            >{"\u{1F310}"}</button>
          )}
          {interactive && (
            <button
              type="button"
              className="trail-delete-btn"
              onClick={(e) => { e.stopPropagation(); handleDelete(trail.trail_id); }}
              title="Delete trail"
            >{"\u00d7"}</button>
          )}
        </div>
        {isExpanded && (
          <div className="trail-expanded">
            {trail.introduction && !isEditing && (
              <div className="trail-introduction">{trail.introduction}</div>
            )}
            {trail.categories && trail.categories.length > 0 && !isEditing && (
              <div className="trail-category-tags">
                {trail.categories.map((cat) => (
                  <span key={cat} className="trail-category-tag">{cat}</span>
                ))}
              </div>
            )}
            {isEditing && (
              <TrailEditForm
                initialIntro={trail.introduction ?? ""}
                initialCategories={(trail.categories ?? []).join(", ")}
                onSave={(intro, cats) => handleSaveEdit(trail.trail_id, intro, cats)}
                onCancel={() => setEditingId(null)}
              />
            )}
            <div className="trail-stops">{renderStops(trail, interactive)}</div>
            {remoteStopTrailId === trail.trail_id && (
              <div style={{ padding: "8px 12px", background: "rgba(249,115,22,0.06)", borderRadius: 6, margin: "4px 0" }}>
                <div style={{ fontSize: 11, fontWeight: 600, color: "#f97316", marginBottom: 6 }}>Add Cross-Server Stop</div>
                <div style={{ display: "flex", gap: 6, flexDirection: "column" }}>
                  <input
                    type="text"
                    placeholder="Server domain (e.g. localhost:8092)"
                    value={remoteServer}
                    onChange={(e) => setRemoteServer(e.target.value)}
                    style={{ fontSize: 12, padding: "4px 8px", border: "1px solid var(--border)", borderRadius: 4, background: "var(--bg-surface)", color: "var(--text)" }}
                  />
                  <input
                    type="text"
                    placeholder="Work ID (e.g. 0x5)"
                    value={remoteWorkId}
                    onChange={(e) => setRemoteWorkId(e.target.value)}
                    style={{ fontSize: 12, padding: "4px 8px", border: "1px solid var(--border)", borderRadius: 4, background: "var(--bg-surface)", color: "var(--text)" }}
                  />
                  <button
                    type="button"
                    onClick={() => handleAddRemoteStop(trail.trail_id)}
                    disabled={!remoteServer.trim() || !remoteWorkId.trim()}
                    style={{ fontSize: 11, padding: "4px 12px", background: "#f97316", color: "#fff", border: "none", borderRadius: 4, cursor: "pointer", opacity: (!remoteServer.trim() || !remoteWorkId.trim()) ? 0.4 : 1 }}
                  >Add Remote Stop</button>
                </div>
              </div>
            )}
            {interactive && (
              <div className="trail-card-actions">
                <button type="button" className="trail-action-btn" onClick={() => setEditingId(isEditing ? null : trail.trail_id)}>
                  {isEditing ? "Cancel Edit" : "Edit Details"}
                </button>
                {trail.published ? (
                  <button type="button" className="trail-action-btn" onClick={() => handleUnpublish(trail.trail_id)}>Unpublish</button>
                ) : (
                  <button type="button" className="trail-action-btn trail-publish-btn" onClick={() => handlePublish(trail.trail_id)}>Publish</button>
                )}
              </div>
            )}
          </div>
        )}
      </div>
    );
  };

  return (
    <div
      ref={dialogRef}
      className="trail-float-panel"
      style={{ transform: `translate(${drag.offsetX}px, ${drag.offsetY}px)` }}
    >
        <div
          className="panel-header"
          onMouseDown={onMouseDown}
          style={{ cursor: "grab", userSelect: "none" }}>
          <span className="panel-title">Trails</span>
          <div className="trail-tabs">
            <button
              type="button"
              className={`trail-tab ${tab === "mine" ? "active" : ""}`}
              onClick={() => setTab("mine")}
            >My Trails</button>
            <button
              type="button"
              className={`trail-tab ${tab === "discover" ? "active" : ""}`}
              onClick={() => setTab("discover")}
            >Discover</button>
          </div>
          <button type="button" className="panel-close" onClick={onClose}>{"\u00d7"}</button>
        </div>
        <div className="panel-body">
          {tab === "mine" ? (
            loading && !loadedOnce.current ? (
              <div className="panel-empty">Loading trails...</div>
            ) : (
              <>
                {!showCreateForm ? (
                  <button
                    type="button"
                    className="trail-create-toggle"
                    onClick={() => setShowCreateForm(true)}
                  >+ Create New Trail</button>
                ) : (
                  <div className="trail-create-form">
                    <input
                      type="text"
                      className="trail-input"
                      placeholder="Trail name..."
                      value={newName}
                      onChange={(e) => setNewName(e.target.value)}
                      autoFocus
                    />
                    <textarea
                      className="trail-input trail-intro-input"
                      placeholder="Introduction (optional) - describe what this trail is about..."
                      value={newIntro}
                      onChange={(e) => setNewIntro(e.target.value)}
                      rows={3}
                    />
                    <input
                      type="text"
                      className="trail-input"
                      placeholder="Categories (comma-separated, e.g. Fencing, Programming)"
                      value={newCategories}
                      onChange={(e) => setNewCategories(e.target.value)}
                    />
                    <div className="trail-create-actions">
                      <button type="button" className="trail-cancel-btn" onClick={() => { setShowCreateForm(false); setNewName(""); setNewIntro(""); setNewCategories(""); }}>
                        Cancel
                      </button>
                      <button type="button" className="trail-create-btn" disabled={!newName.trim()} onClick={handleCreate}>
                        Create
                      </button>
                    </div>
                  </div>
                )}

                {trails.length === 0 && !showCreateForm && (
                  <div className="panel-empty">No trails yet. Create one to start curating document sequences.</div>
                )}

                {trails.map((trail) => renderTrailCard(trail, true))}
              </>
            )
          ) : (
            <>
              {categories.length > 0 && (
                <div className="trail-category-filter">
                  <button
                    type="button"
                    className={`trail-cat-chip ${!selectedCategory ? "active" : ""}`}
                    onClick={() => setSelectedCategory(null)}
                  >All</button>
                  {categories.map((cat) => (
                    <button
                      key={cat}
                      type="button"
                      className={`trail-cat-chip ${selectedCategory === cat ? "active" : ""}`}
                      onClick={() => setSelectedCategory(cat)}
                    >{cat}</button>
                  ))}
                </div>
              )}
              {publishedTrails.length === 0 ? (
                <div className="panel-empty">
                  {selectedCategory
                    ? `No published trails in "${selectedCategory}".`
                    : "No published trails yet. Publish one of your trails to share it."}
                </div>
              ) : (
                publishedTrails.map((trail) => renderTrailCard(trail, false))
              )}
            </>
          )}
        </div>
    </div>
  );
}

function TrailEditForm({
  initialIntro,
  initialCategories,
  onSave,
  onCancel,
}: {
  initialIntro: string;
  initialCategories: string;
  onSave: (intro: string, cats: string) => void;
  onCancel: () => void;
}) {
  const [intro, setIntro] = useState(initialIntro);
  const [cats, setCats] = useState(initialCategories);
  return (
    <div className="trail-edit-form">
      <textarea
        className="trail-input trail-intro-input"
        placeholder="Introduction..."
        value={intro}
        onChange={(e) => setIntro(e.target.value)}
        rows={3}
      />
      <input
        type="text"
        className="trail-input"
        placeholder="Categories (comma-separated)"
        value={cats}
        onChange={(e) => setCats(e.target.value)}
      />
      <div className="trail-create-actions">
        <button type="button" className="trail-cancel-btn" onClick={onCancel}>Cancel</button>
        <button type="button" className="trail-create-btn" onClick={() => onSave(intro, cats)}>Save</button>
      </div>
    </div>
  );
}
