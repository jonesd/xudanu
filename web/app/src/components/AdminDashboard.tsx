import { useState, useEffect, useCallback } from "react";

interface HealthData {
  status: string;
  server_id: string;
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

interface AdminDashboardProps {
  onClose: () => void;
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

export function AdminDashboard({ onClose }: AdminDashboardProps) {
  const [health, setHealth] = useState<HealthData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);

  const fetchHealth = useCallback(async () => {
    try {
      const resp = await fetch("/health");
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const data = await resp.json();
      setHealth(data);
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

  const checkpointWarning = health ? health.last_checkpoint_ago_secs > 300 : false;
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

      <div style={{ flex: 1, overflowY: "auto", padding: "20px" }}>
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
            <CheckAlert condition={checkpointWarning} message={`Last checkpoint was ${Math.round((health?.last_checkpoint_ago_secs ?? 0) / 60)} minutes ago — checkpoint may be stuck`} />
          )}
          {statusWarning && (
            <CheckAlert condition={statusWarning} message={`Server status: ${health?.status} — degraded or error state`} />
          )}
          {(health?.sessions ?? 0) > 40 && (
            <CheckAlert condition={(health?.sessions ?? 0) > 40} message={`High session count: ${health?.sessions} (max recommended: 40)`} />
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
            <HealthCheck label="Checkpoint recent (< 5 min)" ok={(health?.last_checkpoint_ago_secs ?? 999) < 300} />
            <HealthCheck label="Sessions under limit (< 40)" ok={(health?.sessions ?? 0) < 40} />
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
