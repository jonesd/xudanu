import { useEffect, useState, useRef, useCallback } from "react";
import type { CrdtSyncClient, GlobalSearchResultItem } from "../api/crdt_sync";

interface GlobalSearchPanelProps {
  clientRef: React.RefObject<CrdtSyncClient | null>;
  connected: boolean;
  onClose: () => void;
  onNavigateToWork: (id: number) => void;
}

const Kbd = ({ children }: { children: React.ReactNode }) => (
  <kbd
    style={{
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      minWidth: "20px",
      height: "20px",
      padding: "0 5px",
      borderRadius: "4px",
      fontSize: "11px",
      fontFamily: "ui-monospace, monospace",
      background: "rgba(128,128,128,0.15)",
      border: "1px solid rgba(128,128,128,0.25)",
      boxShadow: "0 1px 0 rgba(128,128,128,0.2)",
      color: "inherit",
      opacity: 0.85,
    }}
  >
    {children}
  </kbd>
);

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
  const [mounted, setMounted] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const flatResultsRef = useRef<Array<{ workId: number; matchIndex: number }>>([]);

  useEffect(() => {
    setMounted(true);
    const t = setTimeout(() => inputRef.current?.focus(), 50);
    return () => clearTimeout(t);
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
    debounceRef.current = setTimeout(() => doSearch(query), 250);
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

  useEffect(() => {
    const container = scrollRef.current;
    if (!container) return;
    const el = container.querySelector(`[data-idx="${selectedIndex}"]`);
    if (el) {
      el.scrollIntoView({ block: "nearest", behavior: "smooth" });
    }
  }, [selectedIndex]);

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
        <mark
          style={{
            background: "rgba(251, 191, 36, 0.25)",
            borderBottom: "1px solid rgba(251, 191, 36, 0.6)",
            padding: "0 1px",
            borderRadius: "2px",
            color: "inherit",
          }}
        >
          {text.slice(idx, idx + q.length)}
        </mark>
        {text.slice(idx + q.length)}
      </>
    );
  };

  let flatIdx = 0;

  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 9999,
        display: "flex",
        justifyContent: "center",
        alignItems: "flex-start",
        paddingTop: "12vh",
        background: "rgba(0, 0, 0, 0.3)",
        backdropFilter: "blur(4px)",
        WebkitBackdropFilter: "blur(4px)",
        opacity: mounted ? 1 : 0,
        transition: "opacity 120ms ease-out",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        onKeyDown={handleKeyDown}
        style={{
          width: "600px",
          maxWidth: "92vw",
          maxHeight: "68vh",
          display: "flex",
          flexDirection: "column",
          borderRadius: "16px",
          background: "#ffffff",
          boxShadow: "0 25px 50px -12px rgba(0,0,0,0.25), 0 0 0 1px rgba(0,0,0,0.08)",
          overflow: "hidden",
          transform: mounted ? "scale(1) translateY(0)" : "scale(0.97) translateY(-8px)",
          opacity: mounted ? 1 : 0,
          transition: "all 150ms cubic-bezier(0.16, 1, 0.3, 1)",
        }}
      >
        {/* Search input */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "10px",
            padding: "18px 20px",
            borderBottom: "1px solid rgba(128,128,128,0.12)",
          }}
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{ opacity: 0.4, flexShrink: 0 }}
          >
            <circle cx="11" cy="11" r="8" />
            <path d="m21 21-4.35-4.35" />
          </svg>
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Search across all works..."
            style={{
              flex: 1,
              background: "transparent",
              border: "none",
              outline: "none",
              fontSize: "17px",
              fontFamily: "inherit",
              color: "#1a1a2e",
            }}
          />
          {loading ? (
            <div
              style={{
                width: "16px",
                height: "16px",
                borderRadius: "50%",
                border: "2px solid rgba(128,128,128,0.2)",
                borderTopColor: "rgba(128,128,128,0.7)",
                animation: "spin 0.6s linear infinite",
                flexShrink: 0,
              }}
            />
          ) : totalMatches > 0 ? (
            <span
              style={{
                fontSize: "12px",
                color: "rgba(128,128,128,0.7)",
                whiteSpace: "nowrap",
                flexShrink: 0,
              }}
            >
              {totalMatches} in {results.length}
            </span>
          ) : null}
          {query && (
            <button
              onClick={() => setQuery("")}
              style={{
                background: "rgba(128,128,128,0.1)",
                border: "none",
                borderRadius: "6px",
                color: "inherit",
                cursor: "pointer",
                width: "22px",
                height: "22px",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "14px",
                opacity: 0.5,
                flexShrink: 0,
                padding: 0,
              }}
            >
              {"\u00d7"}
            </button>
          )}
        </div>

        {/* Results */}
        <div
          ref={scrollRef}
          style={{
            overflowY: "auto",
            flex: 1,
            scrollbarWidth: "thin",
          }}
        >
          {error && (
            <div style={{ padding: "24px 20px", color: "#ef4444", fontSize: "14px", textAlign: "center" }}>
              {error}
            </div>
          )}

          {!error && !loading && query.trim() && results.length === 0 && (
            <div
              style={{
                padding: "48px 20px",
                textAlign: "center",
                opacity: 0.4,
              }}
            >
              <svg
                width="32"
                height="32"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.5"
                style={{ marginBottom: "12px", opacity: 0.5 }}
              >
                <circle cx="11" cy="11" r="8" />
                <path d="m21 21-4.35-4.35" />
              </svg>
              <div style={{ fontSize: "14px" }}>
                No matches for "{query}"
              </div>
            </div>
          )}

          {!error && !query.trim() && (
            <div
              style={{
                padding: "48px 20px",
                textAlign: "center",
                opacity: 0.35,
              }}
            >
              <div style={{ fontSize: "14px", marginBottom: "6px" }}>
                Search across all your works
              </div>
              <div style={{ fontSize: "12px" }}>
                Results update as you type
              </div>
            </div>
          )}

          {results.map((result) => {
            const title = result.title || `work:${result.work_id.toString(16)}`;
            return (
              <div key={result.work_id}>
                {/* Work header */}
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "8px",
                    padding: "10px 20px 4px",
                    fontSize: "12px",
                    fontWeight: 600,
                    opacity: 0.5,
                    textTransform: "uppercase",
                    letterSpacing: "0.04em",
                  }}
                >
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                    <polyline points="14 2 14 8 20 8" />
                  </svg>
                  <span style={{ flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {title}
                  </span>
                  <span
                    style={{
                      fontSize: "10px",
                      fontWeight: 500,
                      padding: "1px 7px",
                      borderRadius: "10px",
                      background: "rgba(128,128,128,0.12)",
                      opacity: 0.8,
                    }}
                  >
                    {result.matches.length}
                  </span>
                </div>
                {/* Match entries */}
                {result.matches.map((match, mi) => {
                  const currentFlat = flatIdx++;
                  const isSelected = currentFlat === selectedIndex;
                  return (
                    <div
                      key={`${result.work_id}-${mi}`}
                      data-idx={currentFlat}
                      onClick={() => {
                        onClose();
                        onNavigateToWork(result.work_id);
                      }}
                      style={{
                        margin: "0 12px",
                        padding: "8px 12px 8px 16px",
                        cursor: "pointer",
                        fontSize: "13px",
                        lineHeight: "1.5",
                        borderRadius: "8px",
                        position: "relative",
                        paddingLeft: isSelected ? "20px" : "16px",
                        transition: "all 80ms ease-out",
                        background: isSelected ? "rgba(67,97,238,0.12)" : "transparent",
                        color: isSelected ? "inherit" : "inherit",
                      }}
                      onMouseEnter={() => setSelectedIndex(currentFlat)}
                    >
                      {isSelected && (
                        <div
                          style={{
                            position: "absolute",
                            left: "12px",
                            top: "50%",
                            transform: "translateY(-50%)",
                            width: "3px",
                            height: "60%",
                            borderRadius: "2px",
                            background: "#4361ee",
                          }}
                        />
                      )}
                      <div style={{ opacity: 0.9 }}>
                        {highlightContext(match.context, query.trim())}
                      </div>
                      <div style={{ fontSize: "11px", opacity: 0.35, marginTop: "2px" }}>
                        Line {match.line + 1}
                      </div>
                    </div>
                  );
                })}
              </div>
            );
          })}
        </div>

        {/* Footer */}
        <div
          style={{
            borderTop: "1px solid rgba(128,128,128,0.12)",
            padding: "10px 20px",
            display: "flex",
            alignItems: "center",
            gap: "20px",
            fontSize: "12px",
            opacity: 0.6,
          }}
        >
          <span style={{ display: "flex", alignItems: "center", gap: "6px" }}>
            <Kbd>{"\u2191"}</Kbd>
            <Kbd>{"\u2193"}</Kbd>
            navigate
          </span>
          <span style={{ display: "flex", alignItems: "center", gap: "6px" }}>
            <Kbd>{"\u23ce"}</Kbd>
            open
          </span>
          <span style={{ display: "flex", alignItems: "center", gap: "6px" }}>
            <Kbd>Esc</Kbd>
            close
          </span>
          <span style={{ marginLeft: "auto", fontSize: "11px", opacity: 0.5 }}>
            {connected ? "Connected" : "Offline"}
          </span>
        </div>
      </div>
      <style>{`@keyframes spin { to { transform: rotate(360deg) } }`}</style>
    </div>
  );
}
