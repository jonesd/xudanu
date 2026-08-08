import { useState, useCallback, useEffect } from "react";
import {
  sanitizeAddress,
  buildRemoteWorksUrl,
  buildRemoteWorkUrl,
  validateRemoteWorksResponse,
  validateRemoteWorkResponse,
  MAX_REMOTE_FETCH_TIMEOUT_MS,
} from "../security/remote-content";

const isLocalDev = typeof window !== "undefined" && (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1");

export interface DirectoryServer {
  server_id: string;
  address: string;
  port: number | null;
  name: string;
  description: string;
  trusted: boolean;
  quarantined?: boolean;
  first_seen?: number | null;
  successful_resolutions?: number;
}

interface ServerDirectoryProps {
  client: { sendRequest: (op: string, payload: Record<string, unknown>) => Promise<unknown> } | null;
  connected: boolean;
  onNavigateToWork: (workId: number) => void;
}

export function ServerDirectoryPanel({ client, connected, onNavigateToWork: _onNavigateToWork }: ServerDirectoryProps) {
  const [servers, setServers] = useState<DirectoryServer[]>([]);
  const [loading, setLoading] = useState(false);
  const [addAddress, setAddAddress] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [browsingServer, setBrowsingServer] = useState<string | null>(null);
  const [browsingPort, setBrowsingPort] = useState<number | undefined>(undefined);
  const [remoteWorks, setRemoteWorks] = useState<Array<{ work_id: string; title: string; revision: number; char_count: number }>>([]);
  const [remoteLoading, setRemoteLoading] = useState(false);
  const [remoteError, setRemoteError] = useState<string | null>(null);
  const [remoteText, setRemoteText] = useState<{ workId: string; text: string; title: string } | null>(null);
  const [textLoading, setTextLoading] = useState(false);

  const refresh = useCallback(async () => {
    if (!client || !connected) return;
    setLoading(true);
    setError(null);
    try {
      const resp = await client.sendRequest("server_directory_list", {});
      const val = (resp as Record<string, unknown>)?.value ?? resp;
      const list = (val as Record<string, unknown>)?.servers ?? (Array.isArray(val) ? val : []);
      setServers(Array.isArray(list) ? (list as DirectoryServer[]) : []);
    } catch {
      setServers([]);
    }
    setLoading(false);
  }, [client, connected]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const handleAdd = useCallback(async () => {
    if (!client || !addAddress.trim()) return;
    setError(null);
    const parsed = sanitizeAddress(addAddress.trim(), { allowBlocked: isLocalDev });
    if (!parsed) {
      setError("Invalid or blocked address");
      return;
    }
    setLoading(true);
    try {
      await client.sendRequest("server_directory_add", {
        address: parsed.host,
        port: parsed.port,
      });
      setAddAddress("");
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to add server");
    }
    setLoading(false);
  }, [client, addAddress, refresh]);

  const handleTrust = useCallback(async (serverId: string, trust: boolean) => {
    if (!client) return;
    try {
      await client.sendRequest("server_directory_set_trust", {
        server_id: serverId,
        trusted: trust,
      });
      await refresh();
    } catch {
      setError("Failed to update trust");
    }
  }, [client, refresh]);

  const handleRemove = useCallback(async (serverId: string) => {
    if (!client) return;
    try {
      await client.sendRequest("server_directory_remove", {
        server_id: serverId,
      });
      await refresh();
    } catch {
      setError("Failed to remove server");
    }
  }, [client, refresh]);

  const handleBrowse = useCallback(async (address: string, port: number | undefined) => {
    const addrStr = port ? `${address}:${port}` : address;
    const parsed = sanitizeAddress(addrStr, { allowBlocked: isLocalDev });
    if (!parsed) {
      setRemoteError("Invalid server address");
      return;
    }
    const url = buildRemoteWorksUrl(parsed.host, parsed.port);
    setBrowsingServer(parsed.host);
    setBrowsingPort(parsed.port);
    setRemoteLoading(true);
    setRemoteError(null);
    setRemoteWorks([]);
    setRemoteText(null);
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), MAX_REMOTE_FETCH_TIMEOUT_MS);
    try {
      const resp = await fetch(url, { signal: controller.signal });
      if (!resp.ok) {
        setRemoteError(`Server returned ${resp.status}`);
        return;
      }
      const data = await resp.json();
      setRemoteWorks(validateRemoteWorksResponse(data));
    } catch (e) {
      if (e instanceof DOMException && e.name === "AbortError") {
        setRemoteError("Request timed out");
      } else {
        setRemoteError("Failed to fetch works list");
      }
    }
    clearTimeout(timeout);
    setRemoteLoading(false);
  }, []);

  const handleViewWork = useCallback(async (address: string, port: number | undefined, workId: string) => {
    const addrStr = port ? `${address}:${port}` : address;
    const parsed = sanitizeAddress(addrStr, { allowBlocked: isLocalDev });
    if (!parsed) {
      setRemoteError("Invalid server address");
      return;
    }
    const url = buildRemoteWorkUrl(parsed.host, parsed.port, workId);
    if (!url) {
      setRemoteError("Invalid work ID");
      return;
    }
    setTextLoading(true);
    setRemoteText(null);
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), MAX_REMOTE_FETCH_TIMEOUT_MS);
    try {
      const resp = await fetch(url, { signal: controller.signal });
      if (!resp.ok) {
        setRemoteError(`Failed to fetch work ${workId}`);
        return;
      }
      const data = await resp.json();
      const validated = validateRemoteWorkResponse(data);
      if (!validated) {
        setRemoteError(`Invalid response from server for work ${workId}`);
        return;
      }
      setRemoteText({
        workId,
        text: validated.text,
        title: validated.title || `Work ${workId}`,
      });
    } catch (e) {
      if (e instanceof DOMException && e.name === "AbortError") {
        setRemoteError("Request timed out");
      } else {
        setRemoteError(`Failed to fetch work ${workId}`);
      }
    }
    clearTimeout(timeout);
    setTextLoading(false);
  }, []);

  if (!connected || !client) {
    return <div className="ws-placeholder"><div className="ws-placeholder-label">Not connected</div></div>;
  }

  return (
    <div className="ws-server-directory">
      <div className="ws-conn-header">
        <span>Servers</span>
        <button className="ws-concept-add-btn" style={{ fontSize: 10 }} onClick={() => void refresh()} title="Refresh">
          ↻
        </button>
      </div>

      <div style={{ display: "flex", gap: 4, marginBottom: 8 }}>
        <input
          type="text"
          className="ws-picker-search"
          placeholder="http://alice.example.com:8081"
          value={addAddress}
          onChange={(e) => setAddAddress(e.target.value)}
          style={{ flex: 1 }}
        />
        <button
          className="ws-empty-create"
          style={{ fontSize: 11, padding: "4px 8px" }}
          onClick={() => void handleAdd()}
          disabled={loading || !addAddress.trim()}
        >
          Add
        </button>
      </div>

      {error && <div style={{ fontSize: 11, color: "var(--red)", marginBottom: 4 }}>{error}</div>}

      {loading && <div className="ws-conn-empty">Loading...</div>}

      {!loading && servers.length === 0 && (
        <div className="ws-conn-empty">No servers in directory. Add one above to browse remote content.</div>
      )}

      {servers.map((srv) => {
        const isNew = srv.first_seen
          ? (Date.now() / 1000) - srv.first_seen < 7 * 86400
          : true;
        const daysKnown = srv.first_seen
          ? Math.floor((Date.now() / 1000 - srv.first_seen) / 86400)
          : null;
        return (
        <div key={srv.server_id} className="ws-conn-item" style={{ display: "flex", flexDirection: "column", alignItems: "stretch" }}>
          <div className="ws-conn-title" style={{ display: "flex", alignItems: "center", gap: 4, flexWrap: "wrap" }}>
            <span>
              {srv.quarantined ? "⛔" : srv.trusted ? "✅" : "❓"} {srv.name || "Unknown"}
            </span>
            {isNew && !srv.quarantined && (
              <span style={{
                fontSize: 8, fontWeight: 700, color: "#fff", background: "var(--accent)",
                padding: "1px 5px", borderRadius: 8, textTransform: "uppercase", letterSpacing: 0.5,
              }}>NEW</span>
            )}
            {srv.quarantined && (
              <span style={{
                fontSize: 8, fontWeight: 700, color: "#fff", background: "var(--red)",
                padding: "1px 5px", borderRadius: 8, textTransform: "uppercase",
              }}>Blocked</span>
            )}
            <span style={{ fontSize: 9, color: "var(--text-dim)", marginLeft: "auto", fontFamily: "monospace" }}>
              {srv.address}{srv.port ? `:${srv.port}` : ""}
            </span>
          </div>
          {srv.description && (
            <div className="ws-conn-excerpt">{srv.description}</div>
          )}
          {!srv.quarantined && daysKnown !== null && (
            <div style={{ fontSize: 9, color: "var(--text-dim)", marginTop: 2 }}>
              Known {daysKnown === 0 ? "today" : `${daysKnown}d`}
              {srv.successful_resolutions !== undefined && srv.successful_resolutions > 0
                ? ` · ${srv.successful_resolutions} resolves`
                : ""
              }
            </div>
          )}
          {!srv.quarantined && (
            <div style={{ display: "flex", gap: 4, marginTop: 4 }}>
              {srv.trusted && (
                <button
                  className="ws-action-btn"
                  style={{ fontSize: 10, padding: "2px 8px" }}
                  onClick={() => void handleBrowse(srv.address, srv.port || undefined)}
                >
                  Browse
                </button>
              )}
              <button
                className="ws-action-btn"
                style={{ fontSize: 10, padding: "2px 8px" }}
                onClick={() => void handleTrust(srv.server_id, !srv.trusted)}
              >
                {srv.trusted ? "Untrust" : "Trust"}
              </button>
              <button
                className="ws-action-btn"
                style={{ fontSize: 10, padding: "2px 8px", color: "var(--red)" }}
                onClick={() => void handleRemove(srv.server_id)}
              >
                Remove
              </button>
            </div>
          )}
        </div>
        );
      })}

      {browsingServer && (
        <div className="ws-conn-section" style={{ marginTop: 8 }}>
          <div className="ws-conn-header" style={{ flexDirection: "row", justifyContent: "space-between" }}>
            <span>Remote works — {browsingServer}</span>
            <button className="ws-concept-add-btn" style={{ fontSize: 10 }} onClick={() => { setBrowsingServer(null); setRemoteWorks([]); setRemoteText(null); }}>
              ✕
            </button>
          </div>
          {remoteLoading && <div className="ws-conn-empty">Fetching works...</div>}
          {remoteError && <div className="ws-conn-empty" style={{ color: "var(--red)" }}>{remoteError}</div>}
          {!remoteLoading && !remoteError && remoteWorks.length === 0 && (
            <div className="ws-conn-empty">No public works on this server.</div>
          )}
          {remoteWorks.map((w) => (
            <div key={w.work_id} className="ws-conn-item" onClick={() => void handleViewWork(browsingServer, browsingPort, w.work_id)}>
              <div className="ws-conn-title">{w.title || `Work ${w.work_id}`}</div>
              <div className="ws-conn-excerpt">
                {w.char_count} chars · {w.revision} revisions
              </div>
            </div>
          ))}
          {textLoading && <div className="ws-conn-empty">Loading text...</div>}
          {remoteText && (
            <div style={{ marginTop: 8, border: "1px solid var(--border)", borderRadius: 4, padding: 8, maxHeight: 300, overflow: "auto" }}>
              <div style={{ fontSize: 12, fontWeight: 600, marginBottom: 4 }}>
                {remoteText.title}
              </div>
              <div style={{ fontSize: 12, whiteSpace: "pre-wrap", color: "var(--text)" }}>
                {remoteText.text.slice(0, 2000)}
                {remoteText.text.length > 2000 ? "..." : ""}
              </div>
              <div style={{ fontSize: 9, color: "var(--text-dim)", marginTop: 4 }}>
                Work ID: {remoteText.workId} — use this ID to create a cross-server link
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
