import { useState, useEffect, useCallback } from "react";
import type { CrdtSyncClient } from "../api/crdt_sync";
import { ClubSelector } from "./ClubSelector";

interface SharePanelProps {
  workBeId: number;
  clientRef: React.RefObject<CrdtSyncClient | null>;
  connected: boolean;
  canEdit: boolean;
  onClose: () => void;
}

interface MemberInfo {
  clubId: number;
  name: string;
}

export function SharePanel({ workBeId, clientRef, connected, canEdit, onClose }: SharePanelProps) {
  const [readClub, setReadClub] = useState<number | null>(null);
  const [editClub, setEditClubState] = useState<number | null>(null);
  const [members, setMembers] = useState<MemberInfo[]>([]);
  const [publicClubId, setPublicClubId] = useState(0);
  const [addName, setAddName] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    const client = clientRef.current;
    if (!client || !connected) return;
    try {
      setLoading(true);
      const rc = await client.getReadClub(workBeId);
      const ec = await client.getEditClub(workBeId);
      setReadClub(rc || null);
      setEditClubState(ec || null);
      const stats = await client.getPublicClubId();
      setPublicClubId(stats);
      if (ec) {
        const ids = await client.clubMembers(ec);
        const infos: MemberInfo[] = [];
        for (const id of ids) {
          const name = await client.clubNameById(id).catch(() => `#${id.toString(16)}`);
          infos.push({ clubId: id, name });
        }
        setMembers(infos);
      }
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }, [clientRef, connected, workBeId]);

  useEffect(() => {
    load();
  }, [load]);

  const setPublic = async (which: "read" | "edit" | "both", value: boolean) => {
    const client = clientRef.current;
    if (!client) return;
    setSaving(true);
    setError("");
    try {
      if (value) {
        const resp = await client.sendRequest("server_stats");
        const r = (resp as Record<string, unknown>)?.value as Record<string, unknown> | undefined;
        const pubId = r?.public_club_id as number | undefined;
        if (!pubId) { setError("No public club found"); return; }
        if (which === "read" || which === "both") {
          await client.setReadClub(workBeId, pubId);
          setReadClub(pubId);
        }
        if (which === "edit" || which === "both") {
          await client.setEditClub(workBeId, pubId);
          setEditClubState(pubId);
        }
      } else {
        if (which === "read" || which === "both") {
          await client.setReadClub(workBeId, null);
          setReadClub(null);
        }
        if (which === "edit" || which === "both") {
          await client.setEditClub(workBeId, null);
          setEditClubState(null);
        }
      }
      await load();
    } catch (e) {
      setError(String(e));
    } finally {
      setSaving(false);
    }
  };

  const addMember = async () => {
    if (!addName.trim()) return;
    const client = clientRef.current;
    if (!client) return;
    setSaving(true);
    setError("");
    try {
      const resp = await client.sendRequest("club_id_by_name", { name: addName.trim() });
      const val = (resp as Record<string, unknown>)?.value;
      const memberId = typeof val === "number" ? val : null;
      if (!memberId) { setError(`User "${addName}" not found`); setSaving(false); return; }
      if (editClub) {
        await client.clubAddMember(editClub, memberId);
      } else {
        await client.setEditClub(workBeId, memberId);
        setEditClubState(memberId);
      }
      setAddName("");
      await load();
    } catch (e) {
      setError(String(e));
    } finally {
      setSaving(false);
    }
  };

  const removeMember = async (memberId: number) => {
    const client = clientRef.current;
    if (!client || !editClub) return;
    setSaving(true);
    setError("");
    try {
      await client.clubRemoveMember(editClub, memberId);
      await load();
    } catch (e) {
      setError(String(e));
    } finally {
      setSaving(false);
    }
  };

  if (!connected) return null;

  return (
    <div className="share-overlay" onClick={onClose}>
      <div className="share-panel" onClick={(e) => e.stopPropagation()}>
        <div className="share-header">
          <h3>Share Work</h3>
          <button className="share-close" onClick={onClose}>x</button>
        </div>

        {!canEdit && (
          <div className="share-readonly">You do not have permission to change sharing settings.</div>
        )}

        {loading ? (
          <div className="share-loading">Loading...</div>
        ) : (
          <div className="share-body">
            {error && <div className="share-error">{error}</div>}

            <div className="share-section">
              <label className="share-label">Read Access</label>
              <div style={{ marginBottom: "4px" }}>
                <ClubSelector
                  clientRef={clientRef}
                  connected={connected}
                  publicClubId={publicClubId}
                  value={readClub}
                  onChange={async (clubId) => {
                    if (!clientRef.current || !canEdit) return;
                    setSaving(true);
                    try {
                      await clientRef.current.setReadClub(workBeId, clubId);
                      setReadClub(clubId);
                    } catch (e) {
                      setError(String(e));
                    } finally {
                      setSaving(false);
                    }
                  }}
                  privateLabel="Owner only"
                />
              </div>
            </div>

            <div className="share-section">
              <label className="share-label">Edit Access</label>
              <div className="share-toggle-row">
                <button
                  className={"share-btn" + (editClub ? " active" : "")}
                  disabled={!canEdit || saving}
                  onClick={() => {
                    if (!editClub) setPublic("edit", true);
                    else setPublic("edit", false);
                  }}
                >
                  {editClub ? "Restricted" : "Locked"}
                </button>
                <span className="share-desc">
                  {editClub ? "Only members can edit" : "Nobody can edit"}
                </span>
              </div>
              <button
                className="share-btn-secondary"
                disabled={!canEdit || saving}
                onClick={() => setPublic("edit", true)}
              >
                Open to everyone
              </button>
            </div>

            {editClub && (
              <div className="share-section">
                <label className="share-label">Members with edit access</label>
                {members.length === 0 ? (
                  <div className="share-empty">No members yet</div>
                ) : (
                  <ul className="share-members">
                    {members.map((m) => (
                      <li key={m.clubId} className="share-member">
                        <span className="share-member-name">{m.name}</span>
                        {canEdit && (
                          <button
                            className="share-remove"
                            disabled={saving}
                            onClick={() => removeMember(m.clubId)}
                          >
                            Remove
                          </button>
                        )}
                      </li>
                    ))}
                  </ul>
                )}
                {canEdit && (
                  <div className="share-add-row">
                    <input
                      className="share-input"
                      type="text"
                      placeholder="Username to invite"
                      value={addName}
                      onChange={(e) => setAddName(e.target.value)}
                      onKeyDown={(e) => { if (e.key === "Enter") addMember(); }}
                      disabled={saving}
                    />
                    <button className="share-btn-primary" disabled={saving || !addName.trim()} onClick={addMember}>
                      Add
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
