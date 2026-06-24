import { useEffect, useState, useRef, useCallback } from "react";
import type { CrdtSyncClient, GlobalSearchResultItem } from "../api/crdt_sync";

interface GlobalSearchPanelProps {
  clientRef: React.RefObject<CrdtSyncClient | null>;
  connected: boolean;
  onClose: () => void;
  onNavigateToWork: (id: number) => void;
}

export function GlobalSearchPanel({
  clientRef,
  connected,
  onClose,
  onNavigateToWork,
}: GlobalSearchPanelProps) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<GlobalSearchResultItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const flatResultsRef = useRef<Array<{ workId: number; matchIndex: number }>>([]);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const doSearch = useCallback(
    async (q: string) => {
      if (!q.trim() || !connected || !clientRef.current) {
        setResults([]);
        setLoading(false);
        return;
      }
      try {
        setError(null);
        const resp = await clientRef.current.globalTextSearch(q.trim(), 20);
        setResults(resp.results);
        setSelectedIndex(0);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Search failed");
        setResults([]);
      } finally {
        setLoading(false);
      }
    },
    [connected, clientRef],
  );

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    setLoading(true);
    debounceRef.current = setTimeout(() => doSearch(query), 300);
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [query, doSearch]);

  useEffect(() => {
    const flat: Array<{ workId: number; matchIndex: number }> = [];
    results.forEach((r) => {
      r.matches.forEach((_, mi) => {
        flat.push({ workId: r.work_id, matchIndex: mi });
      });
    });
    flatResultsRef.current = flat;
  }, [results]);

  const totalMatches = results.reduce((sum, r) => sum + r.matches.length, 0);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Escape") {
      e.preventDefault();
      onClose();
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      setSelectedIndex((i) => Math.min(i + 1, Math.max(flatResultsRef.current.length - 1, 0)));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setSelectedIndex((i) => Math.max(i - 1, 0));
    } else if (e.key === "Enter") {
      e.preventDefault();
      const item = flatResultsRef.current[selectedIndex];
      if (item) {
        onClose();
        onNavigateToWork(item.workId);
      }
    }
  };

  const highlightContext = (text: string, q: string) => {
    const lower = text.toLowerCase();
    const ql = q.toLowerCase();
    const idx = lower.indexOf(ql);
    if (idx === -1) return text;
    return (
      <>
        {text.slice(0, idx)}
        <mark style={{ background: "#fbbf24", padding: "0 1px", borderRadius: "2px" }}>
          {text.slice(idx, idx + q.length)}
        </mark>
        {text.slice(idx + q.length)}
      </>
    );
  };

  let flatIdx = 0;

  return (
    <div
      className="modal-overlay"
      onClick={onClose}
      style={{ justifyContent: "flex-start", paddingTop: "10vh" }}
    >
      <div
        className="modal-content"
        onClick={(e) => e.stopPropagation()}
        onKeyDown={handleKeyDown}
        style={{
          width: "640px",
          maxWidth: "90vw",
          maxHeight: "70vh",
          padding: 0,
          display: "flex",
          flexDirection: "column",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "8px",
            padding: "16px 20px",
            borderBottom: "1px solid var(--border-color, #333)",
          }}
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ opacity: 0.5 }}>
            <circle cx="11" cy="11" r="8" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Search all works..."
            style={{
              flex: 1,
              background: "transparent",
              border: "none",
              outline: "none",
              fontSize: "16px",
              color: "inherit",
            }}
          />
          {loading && (
            <span style={{ fontSize: "12px", opacity: 0.5 }}>searching...</span>
          )}
          {!loading && totalMatches > 0 && (
            <span style={{ fontSize: "12px", opacity: 0.5 }}>
              {totalMatches} match{totalMatches !== 1 ? "es" : ""} in {results.length} work
              {results.length !== 1 ? "s" : ""}
            </span>
          )}
          <button
            onClick={onClose}
            style={{
              background: "transparent",
              border: "none",
              color: "inherit",
              cursor: "pointer",
              opacity: 0.5,
              fontSize: "18px",
              padding: "0 4px",
            }}
          >
            x
          </button>
        </div>

        <div style={{ overflowY: "auto", flex: 1 }}>
          {error && (
            <div style={{ padding: "16px 20px", color: "#ef4444", fontSize: "14px" }}>
              {error}
            </div>
          )}

          {!error && !loading && query.trim() && results.length === 0 && (
            <div style={{ padding: "40px 20px", textAlign: "center", opacity: 0.5, fontSize: "14px" }}>
              No matches found for "{query}"
            </div>
          )}

          {!error && !query.trim() && (
            <div style={{ padding: "40px 20px", textAlign: "center", opacity: 0.4, fontSize: "14px" }}>
              Type to search across all works
              <br />
              <span style={{ fontSize: "12px", marginTop: "8px", display: "inline-block" }}>
                Use <kbd style={{ background: "var(--bg-active, #333)", padding: "1px 6px", borderRadius: "3px", fontSize: "11px" }}>Enter</kbd> to open
              </span>
            </div>
          )}

          {results.map((result) => {
            const title = result.title || `work:${result.work_id.toString(16)}`;
            return (
              <div key={result.work_id}>
                <div
                  style={{
                    padding: "6px 20px",
                    fontSize: "11px",
                    fontWeight: 600,
                    textTransform: "uppercase",
                    letterSpacing: "0.05em",
                    opacity: 0.5,
                    background: "var(--bg-active, rgba(255,255,255,0.03))",
                  }}
                >
                  {title}
                  <span style={{ marginLeft: "8px", fontWeight: 400 }}>
                    {result.matches.length} match{result.matches.length !== 1 ? "es" : ""}
                  </span>
                </div>
                {result.matches.map((match, mi) => {
                  const currentFlat = flatIdx++;
                  const isSelected = currentFlat === selectedIndex;
                  return (
                    <div
                      key={`${result.work_id}-${mi}`}
                      onClick={() => {
                        onClose();
                        onNavigateToWork(result.work_id);
                      }}
                      style={{
                        padding: "8px 20px 8px 24px",
                        cursor: "pointer",
                        fontSize: "13px",
                        lineHeight: "1.5",
                        borderLeft: isSelected ? "3px solid #4361ee" : "3px solid transparent",
                        background: isSelected
                          ? "var(--bg-active, rgba(67,97,238,0.1))"
                          : "transparent",
                      }}
                    >
                      <div style={{ opacity: 0.9 }}>
                        {highlightContext(match.context, query.trim())}
                      </div>
                      <div style={{ fontSize: "11px", opacity: 0.4, marginTop: "2px" }}>
                        line {match.line + 1}
                      </div>
                    </div>
                  );
                })}
              </div>
            );
          })}
        </div>

        <div
          style={{
            borderTop: "1px solid var(--border-color, #333)",
            padding: "8px 20px",
            fontSize: "12px",
            opacity: 0.75,
            display: "flex",
            gap: "16px",
          }}
        >
          <span>
            <kbd style={{ background: "var(--bg-active, rgba(255,255,255,0.1))", padding: "2px 6px", borderRadius: "3px", fontSize: "11px", border: "1px solid var(--border-color, #444)" }}>↑↓</kbd>{" "}
            navigate
          </span>
          <span>
            <kbd style={{ background: "var(--bg-active, rgba(255,255,255,0.1))", padding: "2px 6px", borderRadius: "3px", fontSize: "11px", border: "1px solid var(--border-color, #444)" }}>Enter</kbd>{" "}
            open
          </span>
          <span>
            <kbd style={{ background: "var(--bg-active, rgba(255,255,255,0.1))", padding: "2px 6px", borderRadius: "3px", fontSize: "11px", border: "1px solid var(--border-color, #444)" }}>Esc</kbd>{" "}
            close
          </span>
        </div>
      </div>
    </div>
  );
}
