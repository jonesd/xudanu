import { useState, useCallback, useRef, useMemo } from "react";
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
  const inputRef = useRef<HTMLInputElement>(null);

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

  const handleSearch = useCallback(async () => {
    if (!query.trim() || !clientRef.current) return;
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
  }, [query, scope, currentWorkId, works, clientRef, titleMatches]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      handleSearch();
    }
  };

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
            placeholder="Search the docuverse…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            autoFocus
          />
          {(searching || netSearching) && <span style={{ fontSize: 11, color: "var(--text-dim)" }}>…</span>}
        </div>
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
        <div className="search-footer">
          <span><kbd style={{ fontFamily: "monospace", background: "var(--bg)", border: "1px solid var(--border)", borderRadius: 3, padding: "1px 5px", fontSize: 10 }}>↵</kbd> search</span>
          <span><kbd style={{ fontFamily: "monospace", background: "var(--bg)", border: "1px solid var(--border)", borderRadius: 3, padding: "1px 5px", fontSize: 10 }}>esc</kbd> close</span>
        </div>
      </div>
    </>
  );
}
