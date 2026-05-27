import { useState, useEffect, useCallback, useRef } from "react";
import { useCrdtSync } from "../hooks/useCrdtSync";
import { CollaborativeEditor } from "../components/CollaborativeEditor";
import { AwarenessIndicators } from "../components/AwarenessIndicators";
import { DebugPanel } from "../components/DebugPanel";
import { AttributionPanel } from "../components/AttributionPanel";
import { IdentityPanel } from "../components/IdentityPanel";
import type { WorkListEntry } from "../api/crdt_sync";

const WS_URL = `ws://${window.location.host}/xudanu`;

export function WorkspacePage() {
  const [showDebug, setShowDebug] = useState(false);
  const [showAttribution, setShowAttribution] = useState(false);
  const [workBeId, setWorkBeId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [narration, setNarration] = useState<string | null>(null);
  const [narrating, setNarrating] = useState(false);
  const [narrationModel, setNarrationModel] = useState<string>("");
  const [feedback, setFeedback] = useState<string | null>(null);
  const [loadingFeedback, setLoadingFeedback] = useState(false);
  const [feedbackModel, setFeedbackModel] = useState<string>("");
  const [works, setWorks] = useState<WorkListEntry[]>([]);
  const [isPublic, setIsPublic] = useState(false);
  const [isShared, setIsShared] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [llmMenuOpen, setLlmMenuOpen] = useState(false);
  const llmRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!llmMenuOpen) return;
    const handler = (e: MouseEvent) => {
      if (llmRef.current && !llmRef.current.contains(e.target as Node)) {
        setLlmMenuOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [llmMenuOpen]);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const wid = params.get("work");
    if (wid) {
      setWorkBeId(parseInt(wid, 10));
    }
  }, []);

  const {
    text,
    connected,
    authenticated,
    awareness,
    setText,
    sendCursor,
    sendSelection,
    contentMatches,
    watchEnabled,
    toggleWatch,
    attributionSpans,
    attributionLogStatus,
    refreshAttribution,
    refreshAwareness,
    identity,
    createIdentity,
    login,
    createWork,
    shareWork,
    unshareWork,
    narrateDiff,
    getWritingFeedback,
    llmEnabled,
    setTextLocal,
    fetchWorkList,
    setVisibility,
    getReadClub,
    getEditClub,
    publicClubId,
    logout,
  } = useCrdtSync(WS_URL, workBeId);

  const loadWorks = useCallback(async () => {
    const list = await fetchWorkList();
    setWorks([...list].sort((a, b) => a.work_id - b.work_id));
  }, [fetchWorkList]);

  useEffect(() => {
    if (connected && authenticated) loadWorks();
  }, [connected, authenticated, loadWorks]);

  useEffect(() => {
    if (!connected || !authenticated) return;
    const interval = setInterval(loadWorks, 5000);
    return () => clearInterval(interval);
  }, [connected, authenticated, loadWorks]);

  const handleCreate = useCallback(async () => {
    setError(null);
    try {
      const newId = await createWork();
      if (newId === null) {
        setError("Not connected");
        return;
      }
      setWorkBeId(newId);
      const url = new URL(window.location.href);
      url.searchParams.set("work", String(newId));
      window.history.replaceState({}, "", url.toString());
      loadWorks();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  }, [createWork, loadWorks]);

  const selectWork = useCallback((id: number) => {
    setWorkBeId(id);
    const url = new URL(window.location.href);
    url.searchParams.set("work", String(id));
    window.history.replaceState({}, "", url.toString());
    setNarration(null);
    setFeedback(null);
  }, []);

  useEffect(() => {
    if (connected && workBeId !== null && publicClubId > 0) {
      getReadClub(workBeId).then((clubId) => {
        setIsPublic(clubId === publicClubId);
      });
      getEditClub(workBeId).then((clubId) => {
        setIsShared(clubId === publicClubId);
      });
    }
  }, [connected, workBeId, publicClubId, getReadClub, getEditClub]);

  useEffect(() => {
    if (workBeId !== null && connected && text === "") {
      const timer = setTimeout(() => {
        setWorkBeId((currentId) => {
          if (currentId !== null) {
            const url = new URL(window.location.href);
            url.searchParams.delete("work");
            window.history.replaceState({}, "", url.toString());
          }
          return null;
        });
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [workBeId, connected, text]);

  useEffect(() => {
    if (showAttribution && connected && workBeId !== null && text.length > 0) {
      const timer = setTimeout(() => { refreshAttribution(); }, 2000);
      return () => clearTimeout(timer);
    }
  }, [showAttribution, connected, workBeId, text.length, refreshAttribution]);

  useEffect(() => {
    if (connected && workBeId !== null) {
      const timer = setTimeout(() => { refreshAwareness(); }, 5000);
      return () => clearTimeout(timer);
    }
  }, [connected, workBeId, awareness.length, refreshAwareness]);

  const workIdDisplay = workBeId !== null
    ? workBeId.toString(16).padStart(4, "0")
    : null;

  return (
    <div className="workspace-page">
      <header className="workspace-header">
        <h1>xudanu</h1>
        <span className={`sync-status ${connected ? "sync-connected" : "sync-disconnected"}`}>
          {connected ? "Live" : "Offline"}
        </span>
        <div className="header-spacer" />
        {workIdDisplay && (
          <span className="work-id-label">Work {workIdDisplay}</span>
        )}
        {workBeId !== null && (
          <>
            <button
              onClick={async () => {
                if (isShared) {
                  await unshareWork();
                  setIsShared(false);
                } else {
                  await shareWork();
                  setIsPublic(true);
                  setIsShared(true);
                }
              }}
              type="button"
              className={isShared ? "share-active" : ""}
              disabled={!connected || !identity}
              title={isShared ? "Anyone can edit. Click to restrict to owner." : "Click to let anyone read and edit."}
            >
              {isShared ? "Shared" : "Share"}
            </button>
            <button
              onClick={async () => {
                if (workBeId === null) return;
                const nextPublic = !isPublic;
                const targetClub = nextPublic ? publicClubId : identity?.club_id ?? null;
                console.log("[visibility] toggle:", { isPublic, nextPublic, targetClub, publicClubId, identityClub: identity?.club_id });
                if (!targetClub && !nextPublic) return;
                await setVisibility(workBeId, targetClub);
                setIsPublic(nextPublic);
                loadWorks();
              }}
              type="button"
              className={isPublic ? "visibility-public" : "visibility-private"}
              disabled={!connected || !identity}
              title={isPublic ? "Public — anyone can read. Click to make private." : "Private — only you can read. Click to make public."}
            >
              {isPublic ? "Public" : "Private"}
            </button>
            <button
              onClick={toggleWatch}
              type="button"
              className={watchEnabled ? "watch-toggle-active" : ""}
              disabled={!connected}
            >
              {watchEnabled ? "Watching" : "Watch"}
            </button>
            <button
              onClick={() => setShowDebug((d) => !d)}
              type="button"
              className={showDebug ? "debug-toggle-active" : ""}
            >
              Debug
            </button>
            <button
              onClick={() => {
                setShowAttribution((a) => {
                  const next = !a;
                  if (next) refreshAttribution();
                  return next;
                });
              }}
              type="button"
              className={showAttribution ? "attribution-toggle-active" : ""}
              disabled={!connected}
            >
              Attribution
            </button>
            {llmEnabled && (
              <div className="llm-dropdown" ref={llmRef}>
                <button
                  type="button"
                  className="llm-dropdown-toggle"
                  disabled={!connected}
                  onClick={() => setLlmMenuOpen((o) => !o)}
                >
                  AI &#9662;
                </button>
                {llmMenuOpen && (
                  <div className="llm-dropdown-menu">
                    <button
                      type="button"
                      disabled={narrating}
                      onClick={async () => {
                        setLlmMenuOpen(false);
                        setNarrating(true);
                        setNarration(null);
                        setNarrationModel("");
                        const result = await narrateDiff();
                        setNarration(result.text);
                        setNarrationModel(result.model);
                        if (result.updatedText) {
                          setTextLocal(result.updatedText);
                          setTimeout(() => refreshAttribution(), 300);
                        }
                        setNarrating(false);
                      }}
                    >
                      {narrating ? "Summarizing..." : "Summarize Changes"}
                    </button>
                    <button
                      type="button"
                      disabled={loadingFeedback}
                      onClick={async () => {
                        setLlmMenuOpen(false);
                        setLoadingFeedback(true);
                        setFeedback(null);
                        setFeedbackModel("");
                        const result = await getWritingFeedback();
                        setFeedback(result.text);
                        setFeedbackModel(result.model);
                        setLoadingFeedback(false);
                      }}
                    >
                      {loadingFeedback ? "Reviewing..." : "Writing Feedback"}
                    </button>
                  </div>
                )}
              </div>
            )}
          </>
        )}
        <IdentityPanel
          identity={identity}
          connected={connected}
          onCreateIdentity={createIdentity}
          onLogin={login}
          onLogout={logout}
        />
      </header>

      {error && <div className="error">{error}</div>}

      <div className="workspace-body">
        <aside className="document-sidebar">
          <div className="sidebar-header">
            <span>Documents</span>
            <button onClick={handleCreate} type="button" disabled={!connected || !identity}>
              + New
            </button>
          </div>
          <div className="sidebar-search">
            <input
              type="text"
              placeholder="Filter..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="sidebar-search-input"
            />
          </div>
          <div className="work-list">
            {(() => {
              const q = searchQuery.toLowerCase();
              const filtered = q
                ? works.filter((w) =>
                    (w.title || "").toLowerCase().includes(q) ||
                    w.work_id.toString(16).includes(q)
                  )
                : works;
              return filtered.length === 0 ? (
                <div className="work-list-empty">{q ? "No matches" : "No documents yet"}</div>
              ) : (
                filtered.map((w) => (
                  <div
                    key={w.work_id}
                    className={`work-list-item ${w.work_id === workBeId ? "active" : ""}`}
                    onClick={() => selectWork(w.work_id)}
                  >
                    <div className="work-list-meta">
                      <span className="work-list-id">
                        {w.work_id.toString(16).padStart(4, "0")}
                      </span>
                      <span className={`work-list-badge ${w.read_club === publicClubId ? "badge-public" : "badge-private"}`}>
                        {w.read_club === publicClubId ? "pub" : "priv"}
                      </span>
                      <span className="work-list-rev">r{w.revision_count}</span>
                    </div>
                    <span className="work-list-title">
                      {w.title
                        ? w.title.length > 30
                          ? w.title.slice(0, 30) + "..."
                          : w.title
                        : "Untitled"}
                    </span>
                  </div>
                ))
              );
            })()}
          </div>
        </aside>

        <main className="document-area">
          {workBeId !== null ? (
            <>
              <AwarenessIndicators states={awareness} connected={connected} />
              <CollaborativeEditor
                text={text}
                onTextChange={setText}
                onCursorChange={sendCursor}
                onSelectionChange={(s, e) => sendSelection(s, e)}
                connected={connected}
                attributionSpans={attributionSpans}
                editable={identity !== null}
              />
              {watchEnabled && contentMatches.length > 0 && (
                <div className="watch-notifications">
                  <h3>Content Matches</h3>
                  <ul>
                    {contentMatches.map((match, i) => (
                      <li key={i}>
                        <span className="match-id">
                          {match.work_be_id != null
                            ? `${match.work_be_id}${match.title ? ` ${match.title}` : ""}`
                            : match.edition_be_id.toString(16).padStart(4, "0")}
                        </span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
              {narration && !narrationModel && (
                <div className="narration-panel">
                  <p>{narration}</p>
                </div>
              )}
              {feedback && (
                <div className="narration-panel">
                  <h3>Writing Feedback</h3>
                  <p style={{ whiteSpace: "pre-wrap" }}>{feedback}</p>
                  {feedbackModel && (
                    <p className="llm-provenance">&mdash; via {feedbackModel}</p>
                  )}
                </div>
              )}
            </>
          ) : (
            <div className="welcome">
              {identity ? (
                <p>Select a document from the sidebar or create a new one.</p>
              ) : (
                <p>Sign in or create an identity to start collaborating.</p>
              )}
            </div>
          )}
        </main>
      </div>

      {showDebug && (
        <DebugPanel workspaceId={workBeId?.toString(16) ?? ""} visible={showDebug} />
      )}

      <AttributionPanel
        spans={attributionSpans}
        logStatus={attributionLogStatus}
        documentLength={text.length}
        visible={showAttribution && workBeId !== null}
      />
    </div>
  );
}
