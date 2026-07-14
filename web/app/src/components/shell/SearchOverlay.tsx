import { useState, useCallback, useRef, useMemo } from "react";
import type { CrdtSyncClient, WorkListEntry } from "../../api/crdt_sync";

interface SearchOverlayProps {
  onClose: () => void;
  clientRef: React.MutableRefObject<CrdtSyncClient | null>;
  currentWorkId: number | null;
  works: WorkListEntry[];
  onSelectWork: (workId: number) => void;
}

export function SearchOverlay({
  onClose,
  clientRef,
  currentWorkId,
  works,
  onSelectWork,
}: SearchOverlayProps) {
  const [query, setQuery] = useState("");
  const [scope, setScope] = useState("all");
  const [results, setResults] = useState<{ work_id: number; title: string; matches: { start: number; end: number }[]; excerpt: string }[]>([]);
  const [searching, setSearching] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

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
        } catch {}
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
          {searching && <span style={{ fontSize: 11, color: "var(--text-dim)" }}>…</span>}
        </div>
        <div className="search-scope-tabs">
          <button className={`scope-tab ${scope === "all" ? "active" : ""}`} onClick={() => setScope("all")}>
            All works
          </button>
          <button className={`scope-tab ${scope === "current" ? "active" : ""}`} onClick={() => setScope("current")}>
            This document
          </button>
        </div>
        <div className="search-results-container">
          {titleMatches.length > 0 && (
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
          {results.length > 0 && (
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
          {query.trim() && !searching && results.length === 0 && titleMatches.length === 0 && (
            <div style={{ padding: "20px 10px", fontSize: 13, color: "var(--text-dim)", textAlign: "center" }}>
              No results for "{query}"
            </div>
          )}
          {!query.trim() && (
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
