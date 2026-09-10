import { useState, useCallback, useRef, useMemo, useEffect } from "react";
import type { CrdtSyncClient, WorkListEntry, FederatedSearchResultEntry } from "../../api/crdt_sync";

interface SearchOverlayProps {
  onClose: () => void;
  clientRef: React.MutableRefObject<CrdtSyncClient | null>;
  currentWorkId: number | null;
  works: WorkListEntry[];
  onSelectWork: (workId: number) => void;
  serverDirectory: { address: string; port?: number | null; name: string }[];
  /** FR-41 S1: open a remote hit in the main panel's remote view
   * (same flow as Servers tab → View work). */
  onViewRemoteWork: (data: {
    title: string; text: string; originServerName: string;
    license: string; tumbler: string; workId: string; serverId: string;
  }) => void;
}
const SERVER_BADGE_COLORS = ["#58a6ff", "#3fb950", "#d29922", "#bc8cff", "#f97316"];

function serverBadgeColor(name: string): string {
  let hash = 0;
  for (const ch of name) hash = (hash * 31 + ch.charCodeAt(0)) | 0;
  return SERVER_BADGE_COLORS[Math.abs(hash) % SERVER_BADGE_COLORS.length];
}

/**
 * FR-41 S1: remote work preview. Fetches from the ORIGIN server's
 * public API — never renders remote content as HTML; the preview
 * body is plain text (defensive: peers are untrusted for content).
 */
function RemotePreview({
  server,
  workId,
}: {
  server: { address: string; port?: number | null; name: string };
  workId: number;
}) {
  const [text, setText] = useState<string | null>(null);
  const [title, setTitle] = useState<string>("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const baseUrl = `http://${server.address}${server.port ? `:${server.port}` : ""}`;

  useState(() => {
    let cancelled = false;
    (async () => {
      try {
        const resp = await fetch(`${baseUrl}/api/public/work/${workId.toString(16)}`);
        if (!resp.ok) {
          if (!cancelled) {
            setError(`origin returned ${resp.status}`);
            setLoading(false);
          }
          return;
        }
        const data = await resp.json();
        if (cancelled) return;
        setTitle(typeof data.title === "string" ? data.title : "");
        setText(typeof data.text === "string" ? data.text : "");
        setLoading(false);
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : "preview failed");
          setLoading(false);
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  });

  return (
    <div
      style={{
        margin: "6px 0",
        border: "1px solid var(--border)",
        borderRadius: 6,
        padding: 8,
        background: "var(--bg)",
      }}
    >
      <div style={{ fontSize: 11, color: "var(--text-dim)", marginBottom: 4 }}>
        Preview from <strong style={{ color: serverBadgeColor(server.name) }}>{server.name}</strong>
        {title ? ` — ${title}` : ""}
      </div>
      {loading && <div style={{ fontSize: 12, color: "var(--text-dim)" }}>loading…</div>}
      {error && <div style={{ fontSize: 12, color: "var(--red)" }}>{error}</div>}
      {text !== null && (
        <>
          <pre
            style={{
              margin: 0,
              maxHeight: 180,
              overflowY: "auto",
              fontSize: 11,
              whiteSpace: "pre-wrap",
              fontFamily: "inherit",
              color: "var(--text)",
            }}
          >
            {text.slice(0, 4000)}
          </pre>
          <button
            type="button"
            className="scope-tab"
            style={{ marginTop: 6, fontSize: 11 }}
            title="Select text in the preview, then pull it in by reference (FR-41 S2)"
            disabled
          >
            Transclude selection (S2 — coming)
          </button>
        </>
      )}
    </div>
  );
}

type XanResolutionState =
  | { kind: "resolving" }
  | { kind: "local"; workId: number; title: string; position: number | null }
  | { kind: "remote"; server: string; originWorkId: number | null; knownPeer: boolean }
  | { kind: "error"; message: string };

const XAN_COMPLETE = /^xan:\/\/[^\s/]+\/\d+(\.\d+)*$/;

export function SearchOverlay({
  onClose,
  clientRef,
  currentWorkId,
  works,
  onSelectWork,
  serverDirectory,
  onViewRemoteWork,
}: SearchOverlayProps) {
  const [query, setQuery] = useState("");
  const [scope, setScope] = useState("all");
  const [results, setResults] = useState<{ work_id: number; title: string; matches: { start: number; end: number }[]; excerpt: string }[]>([]);
  const [netResults, setNetResults] = useState<FederatedSearchResultEntry[]>([]);
  const [netSearching, setNetSearching] = useState(false);
  const [netError, setNetError] = useState<string | null>(null);
  const [preview, setPreview] = useState<{ server: { address: string; port?: number | null; name: string }; workId: number } | null>(null);
  const [searching, setSearching] = useState(false);
  const [xanState, setXanState] = useState<XanResolutionState | null>(null);
  const [currentXan, setCurrentXan] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const trimmedQuery = query.trim();
  const isXanAddress = trimmedQuery.startsWith("xan://");

  const serverByName = useMemo(() => {
    const map = new Map<string, { address: string; port?: number | null; name: string }>();
    for (const s of serverDirectory) map.set(s.name, s);
    return map;
  }, [serverDirectory]);

  const titleMatches = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return [];
    const pool = scope === "current" && currentWorkId
      ? works.filter((w) => w.work_id === currentWorkId)
      : works;

    let idMatch: number | null = null;
    if (/^\d+$/.test(q)) {
      idMatch = parseInt(q, 10);
    } else if (/^0x[0-9a-f]+$/i.test(q)) {
      idMatch = parseInt(q, 16);
    } else if (/^[0-9a-f]{3,6}$/i.test(q)) {
      idMatch = parseInt(q, 16);
    }

    const idResults = idMatch !== null
      ? pool.filter((w) => w.work_id === idMatch)
          .map((w) => ({ work_id: w.work_id, title: w.title || `work:${w.work_id.toString(16)}` }))
      : [];

    const titleResults = pool
      .filter((w) => (w.title || "").toLowerCase().includes(q))
      .map((w) => ({ work_id: w.work_id, title: w.title || `work:${w.work_id.toString(16)}` }));

    const seen = new Set<number>();
    return [...idResults, ...titleResults].filter((r) => {
      if (seen.has(r.work_id)) return false;
      seen.add(r.work_id);
      return true;
    });
  }, [query, scope, currentWorkId, works]);

  const resolveXan = useCallback(async (addr: string) => {
    setXanState({ kind: "resolving" });
    try {
      const resp = await fetch(`/api/public/resolve?tumbler=${encodeURIComponent(addr)}`);
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) {
        setXanState({ kind: "error", message: typeof data.error === "string" ? data.error : `HTTP ${resp.status}` });
        return;
      }
      if (data.status === "local") {
        setXanState({
          kind: "local",
          workId: parseInt(data.work_id, 16),
          title: typeof data.title === "string" && data.title ? data.title : "untitled",
          position: typeof data.position === "number" ? data.position : null,
        });
      } else if (data.status === "remote") {
        setXanState({
          kind: "remote",
          server: String(data.server),
          originWorkId: typeof data.origin_work_id === "number" ? data.origin_work_id : null,
          knownPeer: Boolean(data.known_peer),
        });
      } else {
        setXanState({ kind: "error", message: "unexpected response from resolver" });
      }
    } catch (e) {
      setXanState({ kind: "error", message: e instanceof Error ? e.message : "address resolution failed" });
    }
  }, []);

  const handleSearch = useCallback(async () => {
    if (!trimmedQuery || !clientRef.current) return;
    if (isXanAddress) {
      resolveXan(trimmedQuery);
      return;
    }
    setXanState(null);
    if (scope === "network") {
      setNetSearching(true);
      setNetError(null);
      setNetResults([]);
      setPreview(null);
      try {
        const entries = await clientRef.current.federatedSearch(query.trim());
        setNetResults(entries);
      } catch (e) {
        setNetError(e instanceof Error ? e.message : "network search failed");
      } finally {
        setNetSearching(false);
      }
      return;
    }
    setSearching(true);
    try {
      const titleIds = new Set(titleMatches.map((m) => m.work_id));
      const searchResults: { work_id: number; title: string; matches: { start: number; end: number }[]; excerpt: string }[] = [];
      const worksToSearch = scope === "current" && currentWorkId
        ? works.filter((w) => w.work_id === currentWorkId)
        : works;

      for (const work of worksToSearch) {
        try {
          const positions = await clientRef.current.findExcerptPositions(work.work_id, query);
          if (positions.length > 0) {
            searchResults.push({
              work_id: work.work_id,
              title: work.title || `work:${work.work_id.toString(16)}`,
              matches: positions,
              excerpt: "",
            });
          }
        } catch { /* no-op */ }
      }
      setResults(searchResults.filter((r) => !titleIds.has(r.work_id)));
    } finally {
      setSearching(false);
    }
  }, [query, scope, currentWorkId, works, clientRef, titleMatches, trimmedQuery, isXanAddress, resolveXan]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      handleSearch();
    }
  };

  useEffect(() => {
    if (isXanAddress && XAN_COMPLETE.test(trimmedQuery)) {
      resolveXan(trimmedQuery);
    } else if (!isXanAddress) {
      setXanState(null);
    }
  }, [trimmedQuery, isXanAddress, resolveXan]);

  useEffect(() => {
    if (currentWorkId == null) return;
    let cancelled = false;
    fetch(`/api/public/resolve?work=0x${currentWorkId.toString(16)}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => {
        if (!cancelled && d && typeof d.xan === "string") setCurrentXan(d.xan);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [currentWorkId]);

  const localHits = netResults.filter((r) => r.local && !r.unreachable);
  const remoteHits = netResults.filter((r) => !r.local && !r.unreachable);
  const unreachablePeers = netResults.filter((r) => r.unreachable);

  return (
    <>
      <div
        onClick={onClose}
        style={{ position: "fixed", inset: 0, zIndex: 49 }}
      />
      <div className="search-overlay">
        <div className="search-overlay-input">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--text-muted)" strokeWidth="2">
            <circle cx="11" cy="11" r="8" />
            <path d="m21 21-4.3-4.3" />
          </svg>
          <input
            ref={inputRef}
            type="text"
            placeholder="Search the docuverse, or paste an xan:// address…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            autoFocus
          />
          {(searching || netSearching || xanState?.kind === "resolving") && <span style={{ fontSize: 11, color: "var(--text-dim)" }}>…</span>}
        </div>
        {isXanAddress ? (
          <div className="search-results-container">
            <div className="search-group-label">Address</div>
            {xanState === null && (
              <div style={{ padding: "20px 10px", fontSize: 13, color: "var(--text-dim)", textAlign: "center" }}>
                Press Enter to resolve {trimmedQuery}
              </div>
            )}
            {xanState?.kind === "resolving" && (
              <div style={{ padding: "20px 10px", fontSize: 13, color: "var(--text-dim)", textAlign: "center" }}>
                Resolving…
              </div>
            )}
            {xanState?.kind === "error" && (
              <div style={{ padding: "20px 10px", fontSize: 13, color: "var(--red)", textAlign: "center" }}>
                {xanState.message}
              </div>
            )}
            {xanState?.kind === "local" && (
              <div className="search-result-item" onClick={() => onSelectWork(xanState.workId)}>
                <div className="sr-icon" style={{ background: "rgba(217, 119, 6, 0.12)", color: "var(--amber)" }}>
                  ⌖
                </div>
                <div className="sr-body">
                  <div className="sr-title">{xanState.title}</div>
                  <div className="sr-excerpt">
                    {xanState.position != null ? `passage ${xanState.position}` : "document"}
                  </div>
                </div>
                <span className="sr-match" style={{ background: "rgba(34, 197, 94, 0.12)", color: "var(--green)", borderRadius: 4, padding: "1px 6px", fontSize: 10 }}>
                  this server
                </span>
              </div>
            )}
            {xanState?.kind === "remote" && (
              <div
                className="search-result-item"
                onClick={async () => {
                  const { server, originWorkId } = xanState;
                  if (originWorkId == null) return;
                  const entry = serverByName.get(server);
                  const address = entry?.address ?? server;
                  const port = entry?.port ?? null;
                  const base = `http://${address}${port ? `:${port}` : ""}`;
                  try {
                    const resp = await fetch(`${base}/api/public/work/${originWorkId.toString(16)}`);
                    if (!resp.ok) {
                      setXanState({ kind: "error", message: `origin returned ${resp.status}` });
                      return;
                    }
                    const data = await resp.json();
                    onViewRemoteWork({
                      title: typeof data.title === "string" ? data.title : `Work 0x${originWorkId.toString(16)}`,
                      text: typeof data.text === "string" ? data.text : "",
                      originServerName: server,
                      license: typeof data.license === "string" ? data.license : "all-rights-reserved",
                      tumbler: typeof data.tumbler === "string" ? data.tumbler : "",
                      workId: originWorkId.toString(16),
                      serverId: server,
                    });
                    onClose();
                  } catch (e) {
                    setXanState({ kind: "error", message: e instanceof Error ? e.message : "failed to reach origin server" });
                  }
                }}
              >
                <div className="sr-icon" style={{ background: "rgba(59, 130, 246, 0.12)", color: "var(--blue, #3b82f6)" }}>
                  ⌾
                </div>
                <div className="sr-body">
                  <div className="sr-title">work 0x{xanState.originWorkId?.toString(16) ?? "?"} on {xanState.server}</div>
                  <div className="sr-excerpt">
                    {xanState.knownPeer ? "known peer — fetch on open" : "server not in directory; will try direct"}
                  </div>
                </div>
                <span className="sr-match" style={{ background: "rgba(59, 130, 246, 0.12)", color: "var(--blue, #3b82f6)", borderRadius: 4, padding: "1px 6px", fontSize: 10 }}>
                  remote
                </span>
              </div>
            )}
          </div>
        ) : (
          <>
        <div className="search-scope-tabs">
          <button className={`scope-tab ${scope === "all" ? "active" : ""}`} onClick={() => setScope("all")}>
            All works
          </button>
          <button className={`scope-tab ${scope === "current" ? "active" : ""}`} onClick={() => setScope("current")}>
            This document
          </button>
          <button
            className={`scope-tab ${scope === "network" ? "active" : ""}`}
            onClick={() => setScope("network")}
            title="Fan this search out to trusted servers in the directory"
          >
            ⌾ The network
          </button>
        </div>
        <div className="search-results-container">
          {scope !== "network" && titleMatches.length > 0 && (
            <>
              <div className="search-group-label">Documents</div>
              {titleMatches.map((r) => (
                <div
                  key={`t-${r.work_id}`}
                  className="search-result-item"
                  onClick={() => onSelectWork(r.work_id)}
                >
                  <div className="sr-icon" style={{ background: "rgba(217, 119, 6, 0.12)", color: "var(--amber)" }}>
                    📄
                  </div>
                  <div className="sr-body">
                    <div className="sr-title">{r.title}</div>
                    <div className="sr-excerpt">title match</div>
                  </div>
                </div>
              ))}
            </>
          )}
          {scope !== "network" && results.length > 0 && (
            <>
              <div className="search-group-label">
                {results.length} work{results.length !== 1 ? "s" : ""} with matches
              </div>
              {results.map((r) => (
                <div
                  key={r.work_id}
                  className="search-result-item"
                  onClick={() => onSelectWork(r.work_id)}
                >
                  <div className="sr-icon" style={{ background: "rgba(217, 119, 6, 0.12)", color: "var(--amber)" }}>
                    📄
                  </div>
                  <div className="sr-body">
                    <div className="sr-title">{r.title}</div>
                    <div className="sr-excerpt">{r.matches.length} match{r.matches.length !== 1 ? "es" : ""}</div>
                  </div>
                  <span className="sr-match">{r.matches.length}</span>
                </div>
              ))}
            </>
          )}
          {scope === "network" && (
            <>
              <div className="search-group-label">
                Network search{netResults.length > 0 ? ` — ${localHits.length} here, ${remoteHits.length} on ${new Set(remoteHits.map((r) => r.server_name)).size} server(s)` : ""}
              </div>
              {netSearching && (
                <div style={{ padding: "12px 10px", fontSize: 12, color: "var(--text-dim)" }}>
                  Asking trusted servers…
                </div>
              )}
              {netError && (
                <div style={{ padding: "12px 10px", fontSize: 12, color: "var(--red)" }}>{netError}</div>
              )}
              {[...localHits, ...remoteHits].map((r) => {
                const badgeColor = r.local ? "var(--green)" : serverBadgeColor(r.server_name);
                return (
                  <div
                    key={`${r.server_id}-${r.work_id}`}
                    className="search-result-item"
                    onClick={async () => {
                      if (r.local) {
                        onSelectWork(r.work_id);
                        return;
                      }
                      // Remote hit: open in the MAIN panel remote view
                      // (same flow as Servers tab → View work).
                      const server = serverByName.get(r.server_name) ?? {
                        address: r.server_name,
                        port: null,
                        name: r.server_name,
                      };
                      const base = `http://${server.address}${server.port ? `:${server.port}` : ""}`;
                      try {
                        const resp = await fetch(`${base}/api/public/work/${r.work_id.toString(16)}`);
                        if (!resp.ok) {
                          setNetError(`origin returned ${resp.status}`);
                          return;
                        }
                        const data = await resp.json();
                        onViewRemoteWork({
                          title: typeof data.title === "string" ? data.title : `Work 0x${r.work_id.toString(16)}`,
                          text: typeof data.text === "string" ? data.text : "",
                          originServerName: r.server_name,
                          license: typeof data.license === "string" ? data.license : "all-rights-reserved",
                          tumbler: typeof data.tumbler === "string" ? data.tumbler : "",
                          workId: r.work_id.toString(16),
                          serverId: String(r.server_id),
                        });
                        onClose();
                      } catch (e) {
                        setNetError(e instanceof Error ? e.message : "failed to open remote work");
                      }
                    }}
                  >
                    <div className="sr-icon" style={{ background: `${badgeColor}22`, color: badgeColor }}>
                      {r.local ? "◆" : "⌾"}
                    </div>
                    <div className="sr-body">
                      <div className="sr-title">{r.title || `work 0x${r.work_id.toString(16)}`}</div>
                      <div className="sr-excerpt">
                        {r.char_count} chars · rev {r.revision}
                      </div>
                    </div>
                    <span
                      className="sr-match"
                      style={{
                        background: `${badgeColor}22`,
                        color: badgeColor,
                        borderRadius: 4,
                        padding: "1px 6px",
                        fontSize: 10,
                      }}
                    >
                      {r.local ? "this server" : r.server_name}
                    </span>
                  </div>
                );
              })}
              {unreachablePeers.length > 0 && (
                <div style={{ padding: "8px 10px", fontSize: 11, color: "var(--text-dim)" }}>
                  {unreachablePeers.length} server{unreachablePeers.length !== 1 ? "s" : ""} didn't answer:{" "}
                  {unreachablePeers.map((u) => u.server_name).join(", ")}
                </div>
              )}
              {preview && (
                <RemotePreview
                  server={preview.server}
                  workId={preview.workId}
                />
              )}
              {!netSearching && !netError && netResults.length === 0 && query.trim() && (
                <div style={{ padding: "20px 10px", fontSize: 13, color: "var(--text-dim)", textAlign: "center" }}>
                  Press Enter to search the network
                </div>
              )}
              {!query.trim() && (
                <div style={{ padding: "20px 10px", fontSize: 13, color: "var(--text-dim)", textAlign: "center" }}>
                  Type to search every trusted server in the directory
                </div>
              )}
            </>
          )}
          {scope !== "network" && query.trim() && !searching && results.length === 0 && titleMatches.length === 0 && (
            <div style={{ padding: "20px 10px", fontSize: 13, color: "var(--text-dim)", textAlign: "center" }}>
              No results for "{query}"
            </div>
          )}
          {scope !== "network" && !query.trim() && (
            <div style={{ padding: "20px 10px", fontSize: 13, color: "var(--text-dim)", textAlign: "center" }}>
              Type to search across all documents
            </div>
          )}
        </div>
        </>
        )}
        <div className="search-footer">
          <span><kbd style={{ fontFamily: "monospace", background: "var(--bg)", border: "1px solid var(--border)", borderRadius: 3, padding: "1px 5px", fontSize: 10 }}>↵</kbd> search</span>
          <span><kbd style={{ fontFamily: "monospace", background: "var(--bg)", border: "1px solid var(--border)", borderRadius: 3, padding: "1px 5px", fontSize: 10 }}>esc</kbd> close</span>
          {currentXan && (
            <span
              title="click to copy this document's permanent address"
              onClick={() => navigator.clipboard?.writeText(currentXan).catch(() => {})}
              style={{ cursor: "pointer", fontFamily: "monospace", fontSize: 10, color: "var(--text-dim)", maxWidth: 260, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}
            >
              {currentXan}
            </span>
          )}
        </div>
      </div>
    </>
  );
}
