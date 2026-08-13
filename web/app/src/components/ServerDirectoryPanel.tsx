import { useState, useCallback, useEffect } from "react";
import { sanitizeAddress } from "../security/remote-content";

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
  last_seen?: number | null;
  last_success?: number | null;
  last_failure?: number | null;
  consecutive_failures?: number;
}

function timeAgo(unixSec: number): string {
  const diff = Math.floor(Date.now() / 1000) - unixSec;
  if (diff < 60) return "just now";
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

interface ServerDirectoryProps {
  client: { sendRequest: (op: string, payload: Record<string, unknown>) => Promise<unknown> } | null;
  connected: boolean;
  onNavigateToWork: (workId: number) => void;
  onViewRemoteWork?: (data: { title: string; text: string; originServerName: string; license: string; tumbler: string; workId: string; serverId: string }) => void;
}

export function ServerDirectoryPanel({ client, connected, onNavigateToWork: _onNavigateToWork, onViewRemoteWork }: ServerDirectoryProps) {
  const [servers, setServers] = useState<DirectoryServer[]>([]);
  const [loading, setLoading] = useState(false);
  const [addAddress, setAddAddress] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [browsingServer, setBrowsingServer] = useState<string | null>(null);
  const [browsingPort, setBrowsingPort] = useState<number | undefined>(undefined);
  const [browsingServerId, setBrowsingServerId] = useState<string | null>(null);
  const [remoteWorks, setRemoteWorks] = useState<Array<{ work_id: string; title: string; revision: number; char_count: number }>>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [remoteLoading, setRemoteLoading] = useState(false);
  const [remoteError, setRemoteError] = useState<string | null>(null);
  const [remoteText, setRemoteText] = useState<{ workId: string; text: string; title: string; tumbler?: string } | null>(null);
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

  const handleBrowse = useCallback(async (address: string, port: number | undefined, serverId?: string, query?: string) => {
    if (!client) return;
    let sid = serverId;
    if (!sid) {
      const resp = await client.sendRequest("server_directory_list", {});
      const val = (resp as Record<string, unknown>)?.value ?? resp;
      const list = (val as Record<string, unknown>)?.servers ?? (Array.isArray(val) ? val : []);
      const entry = (Array.isArray(list) ? (list as DirectoryServer[]) : []).find(
        (s) => s.address === address && (s.port === port || s.port === null)
      );
      sid = entry?.server_id ?? undefined;
    }
    if (!sid) {
      setRemoteError("Could not identify server");
      return;
    }
    setBrowsingServerId(sid);
    setBrowsingServer(address);
    setBrowsingPort(port);
    setRemoteLoading(true);
    setRemoteError(null);
    setRemoteWorks([]);
    setRemoteText(null);
    try {
      const resp = await client.sendRequest("cross_server_list_works", { server_id: sid });
      const val = (resp as Record<string, unknown>)?.value ?? resp;
      const data = (val ?? {}) as Record<string, unknown>;
      let works = (data.works as Array<{ work_id: string; title: string; revision: number; char_count: number }>) || [];
      if (query && query.trim()) {
        const q = query.toLowerCase();
        works = works.filter(w => w.title.toLowerCase().includes(q));
      }
      setRemoteWorks(works);
    } catch (e) {
      setRemoteError(e instanceof Error ? e.message : "Failed to fetch works list");
    }
    setRemoteLoading(false);
  }, [client]);

  const handleViewWork = useCallback(async (_address: string, _port: number | undefined, workId: string) => {
    if (!client || !browsingServerId) {
      setRemoteError("Server not identified");
      return;
    }
    setTextLoading(true);
    setRemoteText(null);
    setRemoteError(null);
    try {
      const resp = await client.sendRequest("cross_server_fetch_work", {
        server_id: browsingServerId,
        work_id: workId,
      });
      const val = (resp as Record<string, unknown>)?.value ?? resp;
      const data = (val ?? {}) as Record<string, unknown>;
      const title = (data.title as string) || `Work ${workId}`;
      const text = (data.text as string) || "";
      const originName = (data.origin_server_name as string) || "Remote";
      const license = (data.license as string) || "all-rights-reserved";
      const tumbler = (data.tumbler as string) || "";
      const cached = data.cached === true;

      if (onViewRemoteWork) {
        onViewRemoteWork({ title, text, originServerName: originName, license, tumbler, workId, serverId: browsingServerId ?? "0" });
      } else {
        setRemoteText({ workId, text, title, tumbler: tumbler || undefined });
      }
      if (cached) {
        setRemoteError(`(cached copy — source may be offline)`);
      }
    } catch (e) {
      if (e instanceof Error) {
        setRemoteError(`Failed: ${e.message}`);
      } else {
        setRemoteError(`Failed to fetch work ${workId}`);
      }
    }
    setTextLoading(false);
  }, [client, browsingServerId, onViewRemoteWork]);

  const [federatedResults, setFederatedResults] = useState<Array<{
    work_id: string; title: string; revision: number; char_count: number;
    server_name: string; server_id: number; local: boolean;
  }>>([]);
  const [fedSearching, setFedSearching] = useState(false);

  const handleFederatedSearch = useCallback(async (query: string) => {
    if (!client || !query.trim()) return;
    setFedSearching(true);
    try {
      const resp = await client.sendRequest("federated_search", { query });
      const val = (resp as Record<string, unknown>)?.value ?? resp;
      const data = (val ?? {}) as Record<string, unknown>;
      setFederatedResults((data.results as typeof federatedResults) || []);
    } catch {
      setFederatedResults([]);
    }
    setFedSearching(false);
  }, [client]);

  const [discovered, setDiscovered] = useState<Array<{
    server_id: number; name: string; address: string; verifying_key: string;
    introduced_by: number;
  }>>([]);
  const [discovering, setDiscovering] = useState(false);

  const handleDiscover = useCallback(async () => {
    if (!client) return;
    setDiscovering(true);
    const allDiscovered: Array<{ server_id: number; name: string; address: string; verifying_key: string; introduced_by: number }> = [];
    for (const srv of servers.filter(s => s.trusted && !s.quarantined)) {
      try {
        const resp = await client.sendRequest("fetch_introductions", { server_id: srv.server_id });
        const val = (resp as Record<string, unknown>)?.value ?? resp;
        const data = (val ?? {}) as Record<string, unknown>;
        const intros = (data.introductions as Array<{ server_id: number; name: string; address: string; verifying_key: string; introduced_by: number; introduced_by_name?: string }>) || [];
        for (const intro of intros) {
          if (!allDiscovered.find(d => d.server_id === intro.server_id)) {
            allDiscovered.push(intro);
          }
        }
      } catch { /* skip unreachable servers */ }
    }
    setDiscovered(allDiscovered);
    setDiscovering(false);
  }, [client, servers]);

  const handleAddDiscovered = useCallback(async (srv: { server_id: number; name: string; address: string; verifying_key: string; introduced_by: number }) => {
    if (!client) return;
    try {
      await client.sendRequest("add_discovered_server", {
        server_id: srv.server_id,
        address: srv.address,
        name: srv.name,
        verifying_key: srv.verifying_key,
        introduced_by: srv.introduced_by,
      });
      setDiscovered(prev => prev.filter(d => d.server_id !== srv.server_id));
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to add server");
    }
  }, [client, refresh]);

  if (!connected || !client) {
    return <div className="ws-placeholder"><div className="ws-placeholder-label">Not connected</div></div>;
  }

  return (
    <div className="ws-server-directory">
      <div className="ws-conn-header">
        <span>Servers</span>
        <div style={{ display: "flex", gap: 2 }}>
          {servers.some(s => s.trusted && !s.quarantined) && (
            <button className="ws-concept-add-btn" style={{ fontSize: 9 }} onClick={() => void handleDiscover()} title="Discover servers through trusted peers" disabled={discovering}>
              {discovering ? "..." : "Discover"}
            </button>
          )}
          <button className="ws-concept-add-btn" style={{ fontSize: 10 }} onClick={() => void refresh()} title="Refresh">
            ↻
          </button>
        </div>
      </div>

      <div style={{ display: "flex", gap: 4, marginBottom: 8 }}>
        <input
          type="text"
          className="ws-picker-search"
          placeholder="Search all servers..."
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              const val = (e.target as HTMLInputElement).value;
              if (val.trim()) void handleFederatedSearch(val);
            }
          }}
          style={{ flex: 1, fontSize: 12 }}
        />
      </div>

      {fedSearching && <div className="ws-conn-empty">Searching all trusted servers...</div>}

      {discovered.length > 0 && (
        <div className="ws-conn-section" style={{ marginBottom: 8 }}>
          <div className="ws-conn-header" style={{ flexDirection: "row", justifyContent: "space-between" }}>
            <span>Discovered ({discovered.length})</span>
            <button className="ws-concept-add-btn" style={{ fontSize: 10 }} onClick={() => setDiscovered([])}>✕</button>
          </div>
          {discovered.map((d) => (
            <div key={d.server_id} className="ws-conn-item">
              <div className="ws-conn-title" style={{ fontSize: 12 }}>{d.name}</div>
              <div className="ws-conn-excerpt">
                <span style={{ fontSize: 8, color: "#fff", background: "#d97706", padding: "1px 5px", borderRadius: 3 }}>via peer</span>
                {" "}{d.address}
              </div>
              <button
                className="ws-action-btn"
                style={{ fontSize: 10, padding: "2px 8px", marginTop: 4 }}
                onClick={() => void handleAddDiscovered(d)}
              >
                Add
              </button>
            </div>
          ))}
        </div>
      )}

      {federatedResults.length > 0 && (
        <div className="ws-conn-section" style={{ marginBottom: 8 }}>
          <div className="ws-conn-header" style={{ flexDirection: "row", justifyContent: "space-between" }}>
            <span>Search results ({federatedResults.length})</span>
            <button className="ws-concept-add-btn" style={{ fontSize: 10 }} onClick={() => setFederatedResults([])}>✕</button>
          </div>
          {federatedResults.map((r) => (
            <div key={`${r.server_id}-${r.work_id}`} className="ws-conn-item">
              <div className="ws-conn-title" style={{ fontSize: 12 }}>
                {r.title}
              </div>
              <div className="ws-conn-excerpt" style={{ display: "flex", gap: 6, alignItems: "center" }}>
                <span style={{
                  fontSize: 8, fontWeight: 700, color: "#fff",
                  background: r.local ? "var(--green)" : "#d97706",
                  padding: "1px 5px", borderRadius: 3,
                }}>{r.local ? "Local" : r.server_name}</span>
                <span>{r.char_count} chars</span>
              </div>
            </div>
          ))}
        </div>
      )}

      <div style={{ display: "flex", gap: 4, marginBottom: 8 }}>
        <input
          type="text"
          className="ws-picker-search"
          placeholder="e.g. alice.com:8081"
          value={addAddress}
          onChange={(e) => setAddAddress(e.target.value)}
          onKeyDown={(e) => { if (e.key === "Enter" && addAddress.trim() && !loading) { e.preventDefault(); void handleAdd(); } }}
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
              {(() => {
                if (srv.quarantined) return "⛔";
                if (!srv.trusted) return "❓";
                const fails = srv.consecutive_failures ?? 0;
                if (fails >= 3) return "🔴";
                if (fails > 0) return "🟡";
                return "🟢";
              })()} {srv.name || "Unknown"}
            </span>
            {isNew && !srv.quarantined && (
              <span style={{
                fontSize: 8, fontWeight: 700, color: "#fff", background: "#d97706",
                padding: "2px 6px", borderRadius: 3, textTransform: "uppercase",
                letterSpacing: 0.5, userSelect: "none", lineHeight: 1,
              }}>New</span>
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
          {!srv.quarantined && (daysKnown !== null || srv.last_seen) && (
            <div style={{ fontSize: 9, color: "var(--text-dim)", marginTop: 2 }}>
              {daysKnown !== null && (daysKnown === 0 ? "Known today" : `Known ${daysKnown}d`)}
              {srv.successful_resolutions !== undefined && srv.successful_resolutions > 0
                ? ` · ${srv.successful_resolutions} resolves`
                : ""
              }
              {srv.last_seen && (
                <span> · Last seen {timeAgo(srv.last_seen)}</span>
              )}
            </div>
          )}
          {!srv.quarantined && (
            <div style={{ display: "flex", gap: 4, marginTop: 4 }}>
              {srv.trusted && (
                <button
                  className="ws-action-btn"
                  style={{ fontSize: 10, padding: "2px 8px" }}
                  onClick={() => void handleBrowse(srv.address, srv.port || undefined, srv.server_id)}
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
          {remoteWorks.length > 0 && (
            <input
              type="text"
              className="ws-picker-search"
              placeholder="Search titles..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && browsingServer) {
                  void handleBrowse(browsingServer, browsingPort, browsingServerId ?? undefined, searchQuery);
                }
              }}
              style={{ fontSize: 12, marginBottom: 4 }}
            />
          )}
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
              <div style={{ fontSize: 9, color: "var(--text-dim)", fontFamily: "monospace" }}>
                "{browsingServer}".{w.work_id}
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
              <div style={{ fontSize: 9, color: "var(--text-dim)", marginTop: 4, fontFamily: "monospace" }}>
                {remoteText.tumbler || `"${browsingServer}".${remoteText.workId}`}
              </div>
              <div style={{ fontSize: 9, color: "var(--text-dim)" }}>
                Work ID: {remoteText.workId} — use this ID to create a cross-server link
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
