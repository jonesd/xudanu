import { useState, useEffect, useCallback, useRef, useMemo } from "react";
import type { CrdtSyncClient, WorkListEntry } from "../api/crdt_sync";

interface AdminDashboardProps {
  onClose: () => void;
  client: CrdtSyncClient | null;
  isAdmin: boolean;
  works: WorkListEntry[];
  onNavigateToWork: (workId: number) => void;
}

interface HealthData {
  status: string;
  server_id: string;
  dirty_works?: number;
  dirty_clubs?: number;
  data_dir_bytes?: number;
  disk_free_bytes?: number | null;
  network_enabled?: boolean;
  external_links_enabled?: boolean;
  edit_policy?: string;
  operations: number;
  works: number;
  clubs: number;
  editions: number;
  links: number;
  blobs: number;
  sessions: number;
  grabbed_works: number;
  last_checkpoint_ago_secs: number;
}

function StatusBadge({ status }: { status: string }) {
  const isOk = status === "ok";
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: "6px",
      padding: "4px 10px", borderRadius: "12px", fontSize: "12px", fontWeight: 600,
      background: isOk ? "rgba(63,185,80,0.12)" : "rgba(248,81,73,0.12)",
      border: `1px solid ${isOk ? "rgba(63,185,80,0.3)" : "rgba(248,81,73,0.3)"}`,
      color: isOk ? "#3fb950" : "#f85149",
    }}>
      <span style={{ width: 8, height: 8, borderRadius: "50%", background: isOk ? "#3fb950" : "#f85149" }} />
      {isOk ? "Healthy" : status.toUpperCase()}
    </span>
  );
}

function MetricCard({ label, value, unit, warning }: { label: string; value: string | number; unit?: string; warning?: boolean }) {
  return (
    <div style={{
      background: "#161b22", border: `1px solid ${warning ? "rgba(248,81,73,0.3)" : "#21262d"}`,
      borderRadius: "8px", padding: "16px",
    }}>
      <div style={{ fontSize: "11px", color: "#8b949e", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", marginBottom: "6px" }}>
        {label}
      </div>
      <div style={{ fontSize: "24px", fontWeight: 700, color: warning ? "#f85149" : "#e6edf3" }}>
        {typeof value === "number" ? value.toLocaleString() : value}
        {unit && <span style={{ fontSize: "13px", color: "#6e7681", marginLeft: "4px" }}>{unit}</span>}
      </div>
    </div>
  );
}

function CheckAlert({ condition, message }: { condition: boolean; message: string }) {
  if (!condition) return null;
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: "8px",
      padding: "10px 14px", marginBottom: "6px",
      background: "rgba(248,81,73,0.06)", border: "1px solid rgba(248,81,73,0.2)",
      borderRadius: "6px", fontSize: "13px", color: "#f85149",
    }}>
      <span style={{ fontSize: "16px" }}>{"\u26A0"}</span>
      {message}
    </div>
  );
}

type AdminTab = "overview" | "content" | "policy" | "sessions" | "audit" | "identities";

export function AdminDashboard({ onClose, client, isAdmin, works, onNavigateToWork }: AdminDashboardProps) {
  const [health, setHealth] = useState<HealthData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);
  const degradedCount = useRef(0);
  const [tab, setTab] = useState<AdminTab>("overview");

  // ── Identities (FR-45 P4) ──
  interface ClubRow { be_id: number; name: string | null; display_name: string | null; is_personal: boolean; is_verified: boolean; member_count: number; works_owned: number; is_system: boolean; }
  const [clubs, setClubs] = useState<ClubRow[]>([]);
  const [clubsMsg, setClubsMsg] = useState<string | null>(null);
  const [grantConfirm, setGrantConfirm] = useState<number | null>(null);

  const loadClubs = useCallback(async () => {
    if (!client) return;
    try {
      const resp = await client.sendRequest("admin_clubs_list");
      const val = (resp as { value?: unknown }).value ?? resp;
      const inner = (val as { value?: unknown }).value ?? val;
      const d = inner as { clubs?: ClubRow[] };
      setClubs(d.clubs ?? []);
    } catch {
      setClubsMsg("Could not load identities (admin sign-in required)");
    }
  }, [client]);

  const grantAdmin = useCallback(async (clubId: number, grant: boolean) => {
    if (!client) return;
    setClubsMsg(null);
    try {
      await client.sendRequest(grant ? "admin_grant_admin" : "admin_revoke_admin", { club_id: clubId });
      setClubsMsg(grant ? `Admin authority granted to club 0x${clubId.toString(16)}` : `Admin authority revoked from 0x${clubId.toString(16)}`);
      setGrantConfirm(null);
    } catch (e) {
      setClubsMsg(`Failed: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [client]);

  // ── Sessions & Audit (FR-45 P3) ──
  interface SessionRow { session_id: number; is_logged_in: boolean; authority_clubs: number[]; initial_login?: boolean; grabbed_work_count?: number; }
  const [sessions, setSessions] = useState<SessionRow[]>([]);
  const [sessionsMsg, setSessionsMsg] = useState<string | null>(null);
  const [audit, setAudit] = useState<{ lines: string[]; chain_valid: boolean } | null>(null);
  const [auditBusy, setAuditBusy] = useState(false);

  const loadSessions = useCallback(async () => {
    if (!client) return;
    try {
      const resp = await client.sendRequest("admin_active_sessions");
      const val = (resp as { value?: unknown }).value ?? resp;
      const inner = (val as { value?: unknown }).value ?? val;
      setSessions(Array.isArray(inner) ? (inner as SessionRow[]) : []);
    } catch {
      setSessionsMsg("Could not load sessions (admin sign-in required)");
    }
  }, [client]);

  const kickSession = useCallback(async (sid: number) => {
    if (!client) return;
    setSessionsMsg(null);
    try {
      await client.sendRequest("admin_session_kick", { session_id: sid });
      setSessionsMsg(`Kicked session ${sid}`);
      void loadSessions();
    } catch (e) {
      setSessionsMsg(`Kick failed: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [client, loadSessions]);

  const loadAudit = useCallback(async () => {
    if (!client) return;
    setAuditBusy(true);
    try {
      const resp = await client.sendRequest("admin_audit_tail");
      const val = (resp as { value?: unknown }).value ?? resp;
      const inner = (val as { value?: unknown }).value ?? val;
      const d = inner as { lines?: string[]; chain_valid?: boolean };
      setAudit({ lines: d.lines ?? [], chain_valid: !!d.chain_valid });
    } catch {
      setAudit(null);
    } finally {
      setAuditBusy(false);
    }
  }, [client]);

  // ── Policy (FR-45 P2) ──
  const [policyBusy, setPolicyBusy] = useState<string | null>(null);
  const [policyMsg, setPolicyMsg] = useState<string | null>(null);

  const runPolicy = useCallback(async (key: string, action: () => Promise<void>, done: string) => {
    setPolicyBusy(key);
    setPolicyMsg(null);
    try {
      await action();
      setPolicyMsg(done);
      // refresh health (it carries the policy fields)
      fetch("/health").then((r) => r.json()).then((d) => setHealth(d)).catch(() => {});
    } catch (e) {
      setPolicyMsg(`Failed: ${e instanceof Error ? e.message : String(e)}`);
    } finally {
      setPolicyBusy(null);
    }
  }, []);

  // ── Content moderation (FR-45 P1) ──
  const [contentFilter, setContentFilter] = useState("");
  const [busyWork, setBusyWork] = useState<number | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null);
  const [deleteText, setDeleteText] = useState("");
  const [contentMsg, setContentMsg] = useState<string | null>(null);

  const filteredWorks = useMemo(() => {
    const q = contentFilter.trim().toLowerCase();
    return [...works]
      .sort((a, b) => (b.char_count ?? 0) - (a.char_count ?? 0))
      .filter((w) => {
        if (!q) return true;
        const t = (w.title || "").toLowerCase();
        const hex = `0x${w.work_id.toString(16)}`;
        return t.includes(q) || hex.includes(q) || String(w.work_id).includes(q);
      });
  }, [works, contentFilter]);

  const runWorkAction = useCallback(async (workId: number, action: "archive" | "unarchive" | "delete") => {
    if (!client) return;
    setBusyWork(workId);
    setContentMsg(null);
    try {
      if (action === "delete") {
        await client.sendRequest("work_admin_delete", { work_id: workId });
        setContentMsg(`Deleted work 0x${workId.toString(16)} (chunks recoverable via GC grace)`);
        setDeleteConfirm(null);
        setDeleteText("");
      } else if (action === "archive") {
        await client.workArchive(workId);
        setContentMsg(`Archived work 0x${workId.toString(16)}`);
      } else {
        await client.workUnarchive(workId);
        setContentMsg(`Restored work 0x${workId.toString(16)}`);
      }
    } catch (e) {
      setContentMsg(`Action failed: ${e instanceof Error ? e.message : String(e)}`);
    } finally {
      setBusyWork(null);
    }
  }, [client]);

  const fetchHealth = useCallback(async () => {
    try {
      const resp = await fetch("/health");
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const data = await resp.json();
      if (data.status === "ok") {
        degradedCount.current = 0;
      } else {
        degradedCount.current++;
      }
      const smoothed = degradedCount.current >= 2 ? data : { ...data, status: "ok" };
      setHealth(smoothed);
      setError(null);
      setLastUpdate(new Date());
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to fetch health");
    }
  }, []);

  useEffect(() => {
    fetchHealth();
    const interval = setInterval(fetchHealth, 5000);
    return () => clearInterval(interval);
  }, [fetchHealth]);

  // A stale checkpoint is only a problem when something is unpersisted:
  // dirty works/clubs exist that a crash would lose. A quiet read-only
  // server correctly skips zero-dirty checkpoints — "idle", not "stuck".
  const dirtyCount = (health?.dirty_works ?? 0) + (health?.dirty_clubs ?? 0);
  const fmtBytes = (n: number | null | undefined): string => {
    if (n == null) return "—";
    if (n < 1024) return `${n} B`;
    const units = ["KB", "MB", "GB", "TB"];
    let v = n / 1024, i = 0;
    while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
    return `${v.toFixed(v >= 10 ? 0 : 1)} ${units[i]}`;
  };
  // Disk-low thresholds: warn < 5 GB or < 10% free; critical < 1 GB.
  const freeBytes = health?.disk_free_bytes ?? null;
  const diskLow = freeBytes != null && (freeBytes < 5 * 1024 ** 3 || freeBytes < (health?.data_dir_bytes ?? 0) * 2);
  const checkpointOverdue = health ? health.last_checkpoint_ago_secs > 300 : false;
  const checkpointWarning = checkpointOverdue && dirtyCount > 0;
  const statusWarning = health ? health.status !== "ok" : false;

  const metrics = [
    { label: "Works", value: health?.works ?? "—" },
    { label: "Links", value: health?.links ?? "—" },
    { label: "Editions", value: health?.editions ?? "—" },
    { label: "Clubs", value: health?.clubs ?? "—" },
    { label: "Blobs", value: health?.blobs ?? "—" },
    { label: "Active Sessions", value: health?.sessions ?? "—", warning: (health?.sessions ?? 0) > 40 },
    { label: "Grabbed Works", value: health?.grabbed_works ?? "—" },
    { label: "Operations", value: health?.operations ?? "—" },
    { label: "Content Size", value: health?.data_dir_bytes != null ? fmtBytes(health.data_dir_bytes) : "—", },
    { label: "Disk Free", value: freeBytes != null ? fmtBytes(freeBytes) : "—", warning: diskLow },
  ];

  return (
    <div style={{ position: "fixed", inset: 0, zIndex: 100, background: "#0d1117", display: "flex", flexDirection: "column" }}>
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 20px", height: "48px", background: "#161b22", borderBottom: "1px solid #30363d", flexShrink: 0,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          <span style={{ color: "#e6edf3", fontSize: "15px", fontWeight: 700 }}>Admin Dashboard</span>
          {health && <StatusBadge status={health.status} />}
          {lastUpdate && (
            <span style={{ color: "#484f58", fontSize: "11px" }}>
              Updated {lastUpdate.toLocaleTimeString()} (auto-refresh 5s)
            </span>
          )}
        </div>
        <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
          <button type="button" onClick={fetchHealth}
            style={{ background: "#21262d", border: "1px solid #30363d", color: "#c9d1d9",
              borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "12px" }}>
            Refresh
          </button>
          <button type="button" onClick={onClose}
            style={{ background: "#da3633", border: "1px solid #f85149", color: "#fff",
              borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "12px" }}>
            Close
          </button>
        </div>
      </div>

      <div style={{ display: "flex", gap: "4px", padding: "0 20px", background: "#161b22", borderBottom: "1px solid #30363d", flexShrink: 0 }}>
        {(["overview", "content", "policy", "sessions", "audit", "identities"] as const).map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => setTab(t)}
            style={{
              background: tab === t ? "#0d1117" : "transparent",
              color: tab === t ? "#e6edf3" : "#8b949e",
              border: "1px solid #30363d",
              borderBottom: tab === t ? "1px solid #0d1117" : "1px solid #30363d",
              borderRadius: "6px 6px 0 0",
              padding: "6px 16px",
              cursor: "pointer",
              fontSize: "13px",
              fontWeight: tab === t ? 600 : 400,
              marginTop: 6,
            }}
          >
            {t === "overview" ? "Overview" : t === "content" ? "Content" : t === "policy" ? "Policy" : t === "sessions" ? "Sessions" : t === "audit" ? "Audit" : "Identities"}
          </button>
        ))}
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "20px", display: tab === "overview" ? "block" : "none" }}>
        {error && (
          <div style={{
            padding: "16px", background: "rgba(248,81,73,0.06)", border: "1px solid rgba(248,81,73,0.2)",
            borderRadius: "8px", color: "#f85149", fontSize: "14px", marginBottom: "16px",
          }}>
            <strong>Connection Error:</strong> {error}
            <div style={{ fontSize: "12px", marginTop: "4px", color: "#8b949e" }}>
              Is the backend server running? Check <code style={{ color: "#79c0ff" }}>curl http://127.0.0.1:8080/health</code>
            </div>
          </div>
        )}

        <div style={{ maxWidth: "960px", margin: "0 auto" }}>
          {checkpointWarning && (
            <CheckAlert condition={checkpointWarning} message={`Last checkpoint was ${Math.round((health?.last_checkpoint_ago_secs ?? 0) / 60)} minutes ago with ${dirtyCount} unpersisted change(s) — edits exist only in memory; checkpoint may be stuck`} />
          )}
          {statusWarning && (
            <CheckAlert condition={statusWarning} message={`Server status: ${health?.status} — degraded or error state`} />
          )}
          {(health?.sessions ?? 0) > 40 && (
            <CheckAlert condition={(health?.sessions ?? 0) > 40} message={`High session count: ${health?.sessions} (max recommended: 40)`} />
          )}
          {diskLow && (
            <CheckAlert condition={diskLow} message={`Low disk space: ${fmtBytes(freeBytes)} free — checkpoints and writes will fail when the disk fills; free space or move the data dir`} />
          )}

          <h3 style={{ color: "#8b949e", fontSize: "12px", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", marginBottom: "12px", marginTop: "8px" }}>
            System Metrics
          </h3>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))", gap: "10px", marginBottom: "32px" }}>
            {metrics.map((m) => (
              <MetricCard key={m.label} label={m.label} value={m.value} warning={m.warning} />
            ))}
          </div>

          <h3 style={{ color: "#8b949e", fontSize: "12px", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", marginBottom: "12px" }}>
            Server Identity
          </h3>
          <div style={{
            display: "flex", gap: "16px", flexWrap: "wrap", marginBottom: "32px",
            background: "#161b22", border: "1px solid #21262d", borderRadius: "8px", padding: "16px",
          }}>
            <div>
              <div style={{ fontSize: "11px", color: "#8b949e", marginBottom: "4px" }}>Server ID</div>
              <code style={{ fontSize: "14px", color: "#79c0ff" }}>{health?.server_id ?? "—"}</code>
            </div>
            <div>
              <div style={{ fontSize: "11px", color: "#8b949e", marginBottom: "4px" }}>Last Checkpoint</div>
              <span style={{ fontSize: "14px", color: checkpointWarning ? "#f85149" : "#3fb950" }}>
                {health ? `${health.last_checkpoint_ago_secs}s ago` : "—"}
                {health && dirtyCount === 0 && checkpointOverdue && (
                  <span style={{ color: "#8b949e", fontSize: 11 }}> (idle — nothing dirty)</span>
                )}
              </span>
            </div>
            <div>
              <div style={{ fontSize: "11px", color: "#8b949e", marginBottom: "4px" }}>Total Operations</div>
              <span style={{ fontSize: "14px", color: "#e6edf3" }}>
                {health?.operations.toLocaleString() ?? "—"}
              </span>
            </div>
          </div>

          <h3 style={{ color: "#8b949e", fontSize: "12px", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", marginBottom: "12px" }}>
            Health Checks
          </h3>
          <div style={{ display: "flex", flexDirection: "column", gap: "6px", marginBottom: "32px" }}>
            <HealthCheck label="Server responding" ok={!!health} />
            <HealthCheck label="Status: ok" ok={health?.status === "ok"} />
            <HealthCheck
              label={dirtyCount > 0 ? `Checkpoint overdue with ${dirtyCount} unpersisted change(s)` : "All changes persisted (checkpoint idle is normal)"}
              ok={dirtyCount === 0}
            />
            <HealthCheck label="Sessions under limit (< 40)" ok={(health?.sessions ?? 0) < 40} />
            <HealthCheck label={`Disk space adequate${freeBytes != null ? ` (${fmtBytes(freeBytes)} free)` : ""}`} ok={!diskLow} />
            <HealthCheck label="Works present" ok={(health?.works ?? 0) > 0} />
            <HealthCheck label="Links present" ok={(health?.links ?? 0) > 0} />
          </div>

          <h3 style={{ color: "#8b949e", fontSize: "12px", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", marginBottom: "12px" }}>
            Quick Links
          </h3>
          <div style={{ display: "flex", gap: "10px", flexWrap: "wrap" }}>
            <a href="/health" target="_blank" rel="noopener noreferrer"
              style={{ color: "#58a6ff", fontSize: "13px", textDecoration: "none", padding: "6px 12px", background: "#161b22", border: "1px solid #21262d", borderRadius: "6px" }}>
              /health JSON
            </a>
            <a href="/.well-known/xudanu-server.json" target="_blank" rel="noopener noreferrer"
              style={{ color: "#58a6ff", fontSize: "13px", textDecoration: "none", padding: "6px 12px", background: "#161b22", border: "1px solid #21262d", borderRadius: "6px" }}>
              Server info
            </a>
          </div>
        </div>
      </div>

      {tab === "policy" && (
        <div style={{ flex: 1, overflowY: "auto", padding: "20px" }}>
          <div style={{ maxWidth: 800, margin: "0 auto" }}>
            {!isAdmin && (
              <div style={{ padding: "12px 16px", background: "rgba(210,153,34,0.08)", border: "1px solid rgba(210,153,34,0.3)", borderRadius: "8px", color: "#d29922", fontSize: "13px", marginBottom: 16 }}>
                Admin sign-in required — policies are read-only.
              </div>
            )}
            {policyMsg && (
              <div style={{ padding: "10px 14px", marginBottom: 12, background: "rgba(88,166,255,0.08)", border: "1px solid rgba(88,166,255,0.3)", borderRadius: "6px", fontSize: 13, color: "#58a6ff" }}>
                {policyMsg}
              </div>
            )}

            <div style={{ background: "#161b22", border: "1px solid #21262d", borderRadius: "8px", padding: 16, marginBottom: 14 }}>
              <div style={{ fontSize: 15, fontWeight: 600, color: "#e6edf3", marginBottom: 4 }}>Edit policy</div>
              <div style={{ fontSize: 12, color: "#8b949e", marginBottom: 12 }}>
                Who may create and edit works. {health?.edit_policy === "public-sandbox"
                  ? "Public-sandbox: any visitor can create and edit (wiki-style)."
                  : "Owner-only (production default): only signed-in identities with rights."}
              </div>
              <div style={{ display: "flex", gap: 8 }}>
                <button
                  type="button"
                  disabled={!isAdmin || policyBusy !== null || health?.edit_policy === "owner-only"}
                  onClick={() => void runPolicy("edit",
                    () => client!.sendRequest("admin_edit_policy_set", { policy: "owner-only" }).then(() => {}),
                    "Edit policy: owner-only")}
                  style={{ background: health?.edit_policy === "owner-only" ? "#238636" : "#21262d", border: "1px solid #30363d", color: health?.edit_policy === "owner-only" ? "#fff" : "#c9d1d9", borderRadius: "4px", padding: "6px 14px", fontSize: 13, cursor: "pointer" }}
                >
                  Owner-only {health?.edit_policy === "owner-only" && "✓"}
                </button>
                <button
                  type="button"
                  disabled={!isAdmin || policyBusy !== null || health?.edit_policy === "public-sandbox"}
                  onClick={() => void runPolicy("edit",
                    () => client!.sendRequest("admin_edit_policy_set", { policy: "public-sandbox" }).then(() => {}),
                    "Edit policy: public-sandbox")}
                  style={{ background: health?.edit_policy === "public-sandbox" ? "#238636" : "#21262d", border: "1px solid #30363d", color: health?.edit_policy === "public-sandbox" ? "#fff" : "#c9d1d9", borderRadius: "4px", padding: "6px 14px", fontSize: 13, cursor: "pointer" }}
                >
                  Public sandbox {health?.edit_policy === "public-sandbox" && "✓"}
                </button>
              </div>
            </div>

            <div style={{ background: "#161b22", border: "1px solid #21262d", borderRadius: "8px", padding: 16, marginBottom: 14 }}>
              <div style={{ fontSize: 15, fontWeight: 600, color: "#e6edf3", marginBottom: 4 }}>Xudanu network (cross-server)</div>
              <div style={{ fontSize: 12, color: "#8b949e", marginBottom: 12 }}>
                {health?.network_enabled
                  ? "Cross-server links, federation sync, and the server directory are active."
                  : "Single-player (default): no outbound connections to other xudanu servers."}
              </div>
              <button
                type="button"
                disabled={!isAdmin || policyBusy !== null}
                onClick={() => void runPolicy("net",
                  () => client!.sendRequest("network_set_enabled", { enabled: !health?.network_enabled }).then(() => {}),
                  health?.network_enabled ? "Network disabled — single-player" : "Network enabled")}
                style={{ background: health?.network_enabled ? "#238636" : "#21262d", border: `1px solid ${health?.network_enabled ? "#2ea043" : "#30363d"}`, color: "#fff", borderRadius: "4px", padding: "6px 14px", fontSize: 13, cursor: "pointer" }}
              >
                {health?.network_enabled ? "ON — click to disable" : "OFF — click to enable"}
              </button>
            </div>

            <div style={{ background: "#161b22", border: "1px solid #21262d", borderRadius: "8px", padding: 16 }}>
              <div style={{ fontSize: 15, fontWeight: 600, color: "#e6edf3", marginBottom: 4 }}>External links in documents</div>
              <div style={{ fontSize: 12, color: "#8b949e", marginBottom: 12 }}>
                {health?.external_links_enabled
                  ? "http(s) URLs in documents open in a new tab."
                  : "Locked down (default): links to this server navigate in-app; external URLs stay plain text."}
              </div>
              <button
                type="button"
                disabled={!isAdmin || policyBusy !== null}
                onClick={() => void runPolicy("links",
                  () => client!.sendRequest("external_links_set_enabled", { enabled: !health?.external_links_enabled }).then(() => {}),
                  health?.external_links_enabled ? "External links disabled" : "External links enabled")}
                style={{ background: health?.external_links_enabled ? "#238636" : "#21262d", border: `1px solid ${health?.external_links_enabled ? "#2ea043" : "#30363d"}`, color: "#fff", borderRadius: "4px", padding: "6px 14px", fontSize: 13, cursor: "pointer" }}
              >
                {health?.external_links_enabled ? "ON — click to disable" : "OFF — click to enable"}
              </button>
            </div>
          </div>
        </div>
      )}

      {tab === "sessions" && (
        <div style={{ flex: 1, overflowY: "auto", padding: "20px" }}>
          <div style={{ maxWidth: 900, margin: "0 auto" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
              <span style={{ color: "#8b949e", fontSize: 13 }}>{sessions.length} active session(s)</span>
              <button type="button" onClick={() => void loadSessions()} style={{ background: "#21262d", border: "1px solid #30363d", color: "#c9d1d9", borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: 12 }}>
                Refresh
              </button>
            </div>
            {sessionsMsg && (
              <div style={{ padding: "10px 14px", marginBottom: 12, background: "rgba(88,166,255,0.08)", border: "1px solid rgba(88,166,255,0.3)", borderRadius: "6px", fontSize: 13, color: "#58a6ff" }}>{sessionsMsg}</div>
            )}
            <div style={{ display: "grid", gap: 6 }}>
              {sessions.map((srow) => (
                <div key={srow.session_id} style={{ display: "flex", alignItems: "center", gap: 12, background: "#161b22", border: "1px solid #21262d", borderRadius: "8px", padding: "10px 14px" }}>
                  <code style={{ color: "#8b949e", fontSize: 11 }}>{srow.session_id}</code>
                  <span style={{ flex: 1, fontSize: 13, color: srow.is_logged_in ? "#3fb950" : "#8b949e" }}>
                    {srow.is_logged_in ? "signed in" : "anonymous"}
                    {srow.authority_clubs?.length ? ` · authority: ${srow.authority_clubs.join(", ")}` : ""}
                    {srow.grabbed_work_count ? ` · editing ${srow.grabbed_work_count} work(s)` : ""}
                  </span>
                  <button
                    type="button"
                    disabled={!isAdmin}
                    onClick={() => void kickSession(srow.session_id)}
                    style={{ background: "#21262d", border: "1px solid rgba(248,81,73,0.4)", color: "#f85149", borderRadius: "4px", padding: "4px 10px", fontSize: 12, cursor: "pointer", opacity: isAdmin ? 1 : 0.4 }}
                    title="Disconnect this session"
                  >
                    kick
                  </button>
                </div>
              ))}
              {sessions.length === 0 && (
                <div style={{ color: "#8b949e", fontSize: 13, padding: 24, textAlign: "center" }}>No sessions loaded — click Refresh (admin sign-in required).</div>
              )}
            </div>
          </div>
        </div>
      )}

      {tab === "audit" && (
        <div style={{ flex: 1, overflowY: "auto", padding: "20px" }}>
          <div style={{ maxWidth: 1100, margin: "0 auto" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
              <span style={{ display: "inline-flex", alignItems: "center", gap: 8, fontSize: 13 }}>
                <span style={{ width: 8, height: 8, borderRadius: "50%", background: audit ? (audit.chain_valid ? "#3fb950" : "#f85149") : "#484f58" }} />
                {audit ? (audit.chain_valid ? "Chain valid (last 200 lines)" : "CHAIN INVALID — tampering suspected") : "Not loaded"}
              </span>
              <button type="button" disabled={auditBusy} onClick={() => void loadAudit()} style={{ background: "#21262d", border: "1px solid #30363d", color: "#c9d1d9", borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: 12 }}>
                {auditBusy ? "Loading…" : "Load / refresh"}
              </button>
            </div>
            <div style={{ background: "#0d1117", border: "1px solid #21262d", borderRadius: "8px", padding: 14, fontFamily: "JetBrains Mono, monospace", fontSize: 11, lineHeight: 1.6, color: "#c9d1d9", whiteSpace: "pre-wrap", wordBreak: "break-all" }}>
              {audit ? audit.lines.join("\n") || "(empty log)" : "Click Load to read the security log tail (admin only, read-only)."}
            </div>
            <div style={{ color: "#484f58", fontSize: 11, marginTop: 8 }}>
              Read-only view. Authoritative full verification: <code>xudanu-server verify-security-log &lt;data-dir&gt;</code>
            </div>
          </div>
        </div>
      )}

      {tab === "identities" && (
        <div style={{ flex: 1, overflowY: "auto", padding: "20px" }}>
          <div style={{ maxWidth: 900, margin: "0 auto" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
              <span style={{ color: "#8b949e", fontSize: 13 }}>
                {clubs.length} identit{clubs.length === 1 ? "y" : "ies"} · sorted by works owned
              </span>
              <button type="button" onClick={() => void loadClubs()} style={{ background: "#21262d", border: "1px solid #30363d", color: "#c9d1d9", borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: 12 }}>
                Refresh
              </button>
            </div>
            {clubsMsg && (
              <div style={{ padding: "10px 14px", marginBottom: 12, background: "rgba(88,166,255,0.08)", border: "1px solid rgba(88,166,255,0.3)", borderRadius: "6px", fontSize: 13, color: "#58a6ff" }}>{clubsMsg}</div>
            )}
            <div style={{ display: "grid", gap: 6 }}>
              {clubs.map((c) => {
                const label = c.display_name || c.name || `Club 0x${c.be_id.toString(16)}`;
                return (
                  <div key={c.be_id} style={{ display: "flex", alignItems: "center", gap: 12, background: "#161b22", border: "1px solid #21262d", borderRadius: "8px", padding: "10px 14px", opacity: c.is_system ? 0.6 : 1 }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: "flex", gap: 8, alignItems: "baseline" }}>
                        <span style={{ fontSize: 14, fontWeight: 600, color: "#e6edf3" }}>{label}</span>
                        <code style={{ color: "#8b949e", fontSize: 11 }}>0x{c.be_id.toString(16)}</code>
                        {c.is_system && <span style={{ fontSize: 10, color: "#484f58" }}>system</span>}
                        {c.is_verified && <span title="Verified" style={{ fontSize: 11, color: "#3fb950" }}>✓</span>}
                      </div>
                      <div style={{ color: "#8b949e", fontSize: 11, marginTop: 2 }}>
                        {c.member_count.toLocaleString()} member{c.member_count === 1 ? "" : "s"} · {c.works_owned.toLocaleString()} work{c.works_owned === 1 ? "" : "s"}
                        {c.is_personal ? " · personal identity" : ""}
                      </div>
                    </div>
                    {!c.is_system && (
                      grantConfirm === c.be_id ? (
                        <>
                          <button type="button" onClick={() => void grantAdmin(c.be_id, true)} style={{ background: "#da3633", border: "1px solid #f85149", color: "#fff", borderRadius: "4px", padding: "4px 10px", fontSize: 12, cursor: "pointer" }}>
                            GRANT ADMIN
                          </button>
                          <button type="button" onClick={() => setGrantConfirm(null)} style={{ background: "#21262d", border: "1px solid #30363d", color: "#c9d1d9", borderRadius: "4px", padding: "4px 10px", fontSize: 12, cursor: "pointer" }}>
                            cancel
                          </button>
                        </>
                      ) : (
                        <>
                          <button
                            type="button"
                            disabled={!isAdmin}
                            onClick={() => setGrantConfirm(c.be_id)}
                            style={{ background: "#21262d", border: "1px solid rgba(210,153,34,0.4)", color: "#d29922", borderRadius: "4px", padding: "4px 10px", fontSize: 12, cursor: "pointer", opacity: isAdmin ? 1 : 0.4 }}
                            title="Grant admin authority to this identity's sessions"
                          >
                            grant admin
                          </button>
                          <button
                            type="button"
                            disabled={!isAdmin}
                            onClick={() => void grantAdmin(c.be_id, false)}
                            style={{ background: "#21262d", border: "1px solid #30363d", color: "#8b949e", borderRadius: "4px", padding: "4px 10px", fontSize: 12, cursor: "pointer", opacity: isAdmin ? 1 : 0.4 }}
                            title="Revoke admin authority"
                          >
                            revoke
                          </button>
                        </>
                      )
                    )}
                  </div>
                );
              })}
              {clubs.length === 0 && (
                <div style={{ color: "#8b949e", fontSize: 13, padding: 24, textAlign: "center" }}>No identities loaded — click Refresh (admin sign-in required).</div>
              )}
            </div>
          </div>
        </div>
      )}

      {tab === "content" && (
        <div style={{ flex: 1, overflowY: "auto", padding: "20px" }}>
          <div style={{ maxWidth: "1100px", margin: "0 auto" }}>
            {!isAdmin && (
              <div style={{ padding: "12px 16px", background: "rgba(210,153,34,0.08)", border: "1px solid rgba(210,153,34,0.3)", borderRadius: "8px", color: "#d29922", fontSize: "13px", marginBottom: 16 }}>
                Admin sign-in required for actions — list is read-only.
              </div>
            )}
            <div style={{ display: "flex", gap: 10, alignItems: "center", marginBottom: 14 }}>
              <input
                type="search"
                placeholder="Filter by title or id…"
                value={contentFilter}
                onChange={(e) => setContentFilter(e.target.value)}
                style={{ flex: 1, background: "#161b22", border: "1px solid #30363d", borderRadius: "6px", color: "#e6edf3", padding: "8px 12px", fontSize: 13 }}
              />
              <span style={{ color: "#8b949e", fontSize: 12 }}>
                {filteredWorks.length} of {works.length} works · sorted by size
              </span>
            </div>
            {contentMsg && (
              <div style={{ padding: "10px 14px", marginBottom: 12, background: "rgba(88,166,255,0.08)", border: "1px solid rgba(88,166,255,0.3)", borderRadius: "6px", fontSize: 13, color: "#58a6ff" }}>
                {contentMsg}
              </div>
            )}
            <div style={{ display: "grid", gap: 6 }}>
              {filteredWorks.map((w) => {
                const hex = `0x${w.work_id.toString(16)}`;
                return (
                  <div key={w.work_id} style={{ display: "flex", alignItems: "center", gap: 12, background: "#161b22", border: "1px solid #21262d", borderRadius: "8px", padding: "10px 14px" }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: "flex", gap: 8, alignItems: "baseline" }}>
                        <span
                          style={{ color: "#58a6ff", cursor: "pointer", fontSize: 14, fontWeight: 600, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}
                          onClick={() => onNavigateToWork(w.work_id)}
                          title="Open this work"
                        >
                          {w.title?.trim() || "Untitled"}
                        </span>
                        <code style={{ color: "#8b949e", fontSize: 11 }}>{hex}</code>
                        {w.is_starred && <span title="Pinned" style={{ fontSize: 11 }}>★</span>}
                      </div>
                      <div style={{ color: "#8b949e", fontSize: 11, marginTop: 2 }}>
                        {(w.char_count ?? 0).toLocaleString()} chars · v{w.revision_count}
                        {w.updated_at ? ` · updated ${new Date(w.updated_at * 1000).toISOString().slice(0, 10)}` : ""}
                        {w.owner ? ` · owner club ${w.owner}` : " · no owner"}
                      </div>
                    </div>
                    <div style={{ display: "flex", gap: 6, flexShrink: 0 }}>
                      {deleteConfirm === w.work_id ? (
                        <>
                          <input
                            autoFocus
                            type="text"
                            placeholder={`type ${hex} to confirm`}
                            value={deleteText}
                            onChange={(e) => setDeleteText(e.target.value)}
                            style={{ width: 160, background: "#0d1117", border: "1px solid #f85149", borderRadius: "4px", color: "#e6edf3", padding: "4px 8px", fontSize: 12 }}
                          />
                          <button
                            type="button"
                            disabled={deleteText.trim().toLowerCase() !== hex || busyWork === w.work_id}
                            onClick={() => void runWorkAction(w.work_id, "delete")}
                            style={{ background: "#da3633", border: "1px solid #f85149", color: "#fff", borderRadius: "4px", padding: "4px 10px", fontSize: 12, cursor: "pointer" }}
                          >
                            DELETE
                          </button>
                          <button
                            type="button"
                            onClick={() => { setDeleteConfirm(null); setDeleteText(""); }}
                            style={{ background: "#21262d", border: "1px solid #30363d", color: "#c9d1d9", borderRadius: "4px", padding: "4px 10px", fontSize: 12, cursor: "pointer" }}
                          >
                            cancel
                          </button>
                        </>
                      ) : (
                        <>
                          <button
                            type="button"
                            disabled={!isAdmin || busyWork === w.work_id}
                            onClick={() => void runWorkAction(w.work_id, "archive")}
                            style={{ background: "#21262d", border: "1px solid #30363d", color: "#d29922", borderRadius: "4px", padding: "4px 10px", fontSize: 12, cursor: "pointer", opacity: isAdmin ? 1 : 0.4 }}
                            title="Archive (soft delete, restorable)"
                          >
                            archive
                          </button>
                          <button
                            type="button"
                            disabled={!isAdmin || busyWork === w.work_id}
                            onClick={() => void runWorkAction(w.work_id, "unarchive")}
                            style={{ background: "#21262d", border: "1px solid #30363d", color: "#3fb950", borderRadius: "4px", padding: "4px 10px", fontSize: 12, cursor: "pointer", opacity: isAdmin ? 1 : 0.4 }}
                            title="Restore from archive"
                          >
                            restore
                          </button>
                          <button
                            type="button"
                            disabled={!isAdmin}
                            onClick={() => { setDeleteConfirm(w.work_id); setDeleteText(""); }}
                            style={{ background: "#21262d", border: "1px solid rgba(248,81,73,0.4)", color: "#f85149", borderRadius: "4px", padding: "4px 10px", fontSize: 12, cursor: "pointer", opacity: isAdmin ? 1 : 0.4 }}
                            title="Hard delete (typed confirmation; chunks recoverable via GC grace)"
                          >
                            delete
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                );
              })}
              {filteredWorks.length === 0 && (
                <div style={{ color: "#8b949e", fontSize: 13, padding: 24, textAlign: "center" }}>No works match.</div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function HealthCheck({ label, ok }: { label: string; ok: boolean }) {
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: "10px",
      padding: "8px 14px", background: "#161b22", border: "1px solid #21262d", borderRadius: "6px",
    }}>
      <span style={{
        width: 16, height: 16, borderRadius: "50%",
        background: ok ? "rgba(63,185,80,0.15)" : "rgba(248,81,73,0.15)",
        border: `1.5px solid ${ok ? "#3fb950" : "#f85149"}`,
        display: "inline-flex", alignItems: "center", justifyContent: "center",
        color: ok ? "#3fb950" : "#f85149", fontSize: "10px", fontWeight: 700,
      }}>
        {ok ? "\u2713" : "\u2717"}
      </span>
      <span style={{ fontSize: "13px", color: ok ? "#c9d1d9" : "#f85149" }}>{label}</span>
    </div>
  );
}
