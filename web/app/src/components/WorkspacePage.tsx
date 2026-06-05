import { useState, useEffect, useCallback, useRef } from "react";
import { useCrdtSync } from "../hooks/useCrdtSync";
import { useTransclusion } from "../hooks/useTransclusion";
import { CollaborativeEditor } from "../components/CollaborativeEditor";
import { VirtualizedEditor } from "../components/VirtualizedEditor";
import { AwarenessIndicators } from "../components/AwarenessIndicators";
import { DebugPanel } from "../components/DebugPanel";
import { AttributionPanel } from "../components/AttributionPanel";
import { IdentityPanel } from "../components/IdentityPanel";
import { ImportWizard } from "../components/ImportWizard";
import { TransclusionBadge } from "../components/TransclusionBadge";
import type { WorkListEntry, HistoricalAuthorEntry } from "../api/crdt_sync";

const WS_URL = `${window.location.protocol === "https:" ? "wss" : "ws"}://${window.location.host}/xudanu`;

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
  const [showImport, setShowImport] = useState(false);
  const [sidebarTab, setSidebarTab] = useState<"docs" | "authors" | "links">("docs");
  const [authors, setAuthors] = useState<HistoricalAuthorEntry[]>([]);
  const [expandedAuthorId, setExpandedAuthorId] = useState<number | null>(null);
  const [authorWorks, setAuthorWorks] = useState<WorkListEntry[]>([]);
  const [sourceText, setSourceText] = useState<string | null>(null);
  const [selectionRange, setSelectionRange] = useState<{ start: number; end: number } | null>(null);
  const llmRef = useRef<HTMLDivElement>(null);

  const transclusion = useTransclusion();

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
    clientRef,
  } = useCrdtSync(WS_URL, workBeId);

  const currentWorkMeta = works.find(w => w.work_id === workBeId);
  const isSourceWork = currentWorkMeta?.is_source === true;
  const displayText = isSourceWork && sourceText !== null ? sourceText : text;

  useEffect(() => {
    if (clientRef.current) clientRef.current.setSkipCrdt(!!isSourceWork);
  }, [isSourceWork, clientRef]);

  useEffect(() => {
    if (!isSourceWork || workBeId === null || !connected || !clientRef.current) {
      if (!isSourceWork && sourceText !== null) setSourceText(null);
      return;
    }
    let cancelled = false;
    const CHUNK = 100_000;
    (async () => {
      try {
        const first = await clientRef.current!.textRange(workBeId!, 0, CHUNK);
        if (cancelled) return;
        let loaded = first.text;
        const total = first.totalChars;
        while (loaded.length < total && !cancelled) {
          const next = await clientRef.current!.textRange(workBeId!, loaded.length, Math.min(loaded.length + CHUNK, total));
          if (cancelled) return;
          loaded += next.text;
        }
        if (!cancelled) setSourceText(loaded);
      } catch (e) {
        console.error("[src] source work text load failed:", e);
      }
    })();
    return () => { cancelled = true; };
  }, [isSourceWork, workBeId, connected, clientRef]);

  const loadWorks = useCallback(async () => {
    const list = await fetchWorkList();
    setWorks([...list].sort((a, b) => a.work_id - b.work_id));
  }, [fetchWorkList]);

  const loadAuthors = useCallback(async () => {
    if (!clientRef.current) return;
    try {
      const list = await clientRef.current.listHistoricalAuthors();
      setAuthors(list);
    } catch {}
  }, [clientRef]);

  const handleExpandAuthor = useCallback(async (authorId: number) => {
    if (expandedAuthorId === authorId) {
      setExpandedAuthorId(null);
      setAuthorWorks([]);
      return;
    }
    setExpandedAuthorId(authorId);
    if (!clientRef.current) return;
    try {
      const list = await clientRef.current.fetchWorksByAuthor(authorId);
      setAuthorWorks(list);
    } catch {
      setAuthorWorks([]);
    }
  }, [clientRef, expandedAuthorId]);

  useEffect(() => {
    if (connected) loadWorks();
  }, [connected, loadWorks]);

  useEffect(() => {
    if (connected && authenticated) loadWorks();
  }, [connected, authenticated, loadWorks]);

  useEffect(() => {
    if (connected && sidebarTab === "authors") loadAuthors();
  }, [connected, authenticated, sidebarTab, loadAuthors]);

  useEffect(() => {
    if (!connected) return;
    const interval = setInterval(loadWorks, 5000);
    return () => clearInterval(interval);
  }, [connected, loadWorks]);

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

  const prevTextRef = useRef(text);
  useEffect(() => { prevTextRef.current = text; }, [text]);

  useEffect(() => {
    if (workBeId === null || !connected || !authenticated) return;
    if (text !== "") return;
    if (prevTextRef.current === "") return;
    const timer = setTimeout(() => {
      setWorkBeId((currentId) => {
        if (currentId !== null) {
          const url = new URL(window.location.href);
          url.searchParams.delete("work");
          window.history.replaceState({}, "", url.toString());
        }
        return null;
      });
    }, 5000);
    return () => clearTimeout(timer);
  }, [workBeId, connected, authenticated, text]);

  useEffect(() => {
    if (showAttribution && connected && workBeId !== null && text.length > 0) {
      const timer = setTimeout(() => { refreshAttribution(); }, 500);
      return () => clearTimeout(timer);
    }
  }, [showAttribution, connected, workBeId, text, refreshAttribution]);

  useEffect(() => {
    if (connected && workBeId !== null) {
      const timer = setTimeout(() => { refreshAwareness(); }, 5000);
      return () => clearTimeout(timer);
    }
  }, [connected, workBeId, awareness.length, refreshAwareness]);

  useEffect(() => {
    if (connected && workBeId !== null && clientRef.current && identity !== null) {
      transclusion.loadLinks(clientRef.current, workBeId, works);
    }
  }, [connected, workBeId, works, identity]);

  const handlePlaceTransclusion = useCallback(async (position: number) => {
    if (!clientRef.current || workBeId === null) return;
    const pending = transclusion.pending;
    if (!pending) return;
    const excerpt = pending.text;
    const linkId = await transclusion.placeTransclusion(clientRef.current, workBeId, position);
      if (linkId !== null) {
      const newText = text.slice(0, position) + excerpt + text.slice(position);
      setText(newText);
      if (clientRef.current) {
        await new Promise((r) => setTimeout(r, 500));
        await transclusion.loadLinks(clientRef.current, workBeId, works);
      }
    }
  }, [clientRef, workBeId, transclusion, works, text, setText]);

  const handleTranscludeSelection = useCallback(() => {
    if (!selectionRange || workBeId === null) return;
    const selectedText = text.slice(selectionRange.start, selectionRange.end);
    const title = currentWorkMeta?.title || `Work ${workBeId.toString(16).padStart(4, "0")}`;
    transclusion.holdSelection(workBeId, title, selectionRange.start, selectionRange.end, selectedText);
  }, [selectionRange, workBeId, text, currentWorkMeta, transclusion]);

  const handlePasteText = useCallback(async (pasteText: string, pasteStart: number) => {
    if (!clientRef.current || workBeId === null) return;
    try {
      console.log("[paste-detect] checking paste, length:", pasteText.length, "start:", pasteStart);
      const match = await clientRef.current.matchContent(pasteText);
      console.log("[paste-detect] match result:", match);
      if (match.matched && match.author_id != null && match.work_id != null) {
        const pasteEnd = pasteStart + pasteText.length;
        await clientRef.current.applySourceAttribution(
          workBeId,
          match.author_id,
          match.work_id,
          pasteStart,
          pasteEnd,
        );
        console.log("[paste-detect] attribution applied");
      }
    } catch (e) {
      console.error("[paste-detect] error:", e);
    }
  }, [clientRef, workBeId]);

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
            {selectionRange && !transclusion.pending && (
              <button
                onClick={handleTranscludeSelection}
                type="button"
                className="transclude-btn"
                title="Create transclusion link from selected text"
              >
                Transclude
              </button>
            )}
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
          <div className="sidebar-tabs">
            <button
              className={`sidebar-tab ${sidebarTab === "docs" ? "active" : ""}`}
              onClick={() => setSidebarTab("docs")}
            >
              Docs
            </button>
            <button
              className={`sidebar-tab ${sidebarTab === "authors" ? "active" : ""}`}
              onClick={() => setSidebarTab("authors")}
            >
              Authors
            </button>
            <button
              className={`sidebar-tab ${sidebarTab === "links" ? "active" : ""}`}
              onClick={() => setSidebarTab("links")}
            >
              Links
            </button>
          </div>
          {sidebarTab === "docs" && (
            <>
              <div className="sidebar-actions">
                <button onClick={handleCreate} type="button" disabled={!connected || !identity}>
                  + New
                </button>
                <button onClick={() => setShowImport(true)} type="button" disabled={!connected || !identity}>
                  Import Source
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
                  const docs = filtered.filter((w) => !w.is_source);
                  const sources = filtered.filter((w) => w.is_source);

                  const renderWork = (w: WorkListEntry) => (
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
                  );

                  return filtered.length === 0 ? (
                    <div className="work-list-empty">{q ? "No matches" : "No documents yet"}</div>
                  ) : (
                    <>
                      {docs.length > 0 && (
                        <>
                          <div className="link-section-label">Documents ({docs.length})</div>
                          {docs.map(renderWork)}
                        </>
                      )}
                      {sources.length > 0 && (
                        <>
                          <div className="link-section-label">Source Works ({sources.length})</div>
                          {sources.map((w) => (
                            <div
                              key={w.work_id}
                              className={`work-list-item source-work-item ${w.work_id === workBeId ? "active" : ""}`}
                              onClick={() => selectWork(w.work_id)}
                            >
                              <div className="work-list-meta">
                                <span className="work-list-id">
                                  {w.work_id.toString(16).padStart(4, "0")}
                                </span>
                                <span className="work-list-badge badge-source">src</span>
                                <span className="work-list-rev">r{w.revision_count}</span>
                              </div>
                              <span className="work-list-title">
                                {w.title
                                  ? w.title.length > 30
                                    ? w.title.slice(0, 30) + "..."
                                    : w.title
                                  : "Untitled"}
                              </span>
                              {w.source_edition_info && (
                                <span className="author-work-info">{w.source_edition_info}</span>
                              )}
                            </div>
                          ))}
                        </>
                      )}
                    </>
                  );
                })()}
              </div>
            </>
          )}
          {sidebarTab === "authors" && (
            <div className="work-list">
              {authors.length === 0 ? (
                <div className="work-list-empty">No historical authors</div>
              ) : (
                authors.map((a) => (
                  <div key={a.be_id}>
                    <div
                      className={`author-list-item ${expandedAuthorId === a.be_id ? "active" : ""}`}
                      onClick={() => handleExpandAuthor(a.be_id)}
                    >
                      <span className="author-list-name">{a.display_name || a.name}</span>
                      <span className="author-list-dates">
                        {a.birth_year != null || a.death_year != null
                          ? `${a.birth_year != null ? a.birth_year : "?"}\u2013${a.death_year != null ? a.death_year : "?"}`
                          : ""}
                      </span>
                    </div>
                    {expandedAuthorId === a.be_id && (
                      <div className="author-works">
                        {authorWorks.length === 0 ? (
                          <div className="author-work-empty">No imported works</div>
                        ) : (
                          authorWorks.map((w) => (
                            <div
                              key={w.work_id}
                              className={`work-list-item author-work-item ${w.work_id === workBeId ? "active" : ""}`}
                              onClick={() => selectWork(w.work_id)}
                            >
                              <span className="work-list-title">
                                {w.title || "Untitled"}
                              </span>
                              {w.source_edition_info && (
                                <span className="author-work-info">{w.source_edition_info}</span>
                              )}
                            </div>
                          ))
                        )}
                      </div>
                    )}
                  </div>
                ))
              )}
            </div>
          )}
          {sidebarTab === "links" && (
            <div className="work-list">
              {transclusion.links.length === 0 ? (
                <div className="work-list-empty">No transclusion links</div>
              ) : (
                (() => {
                  const outgoing = transclusion.links.filter((l) => l.origin === workBeId);
                  const incoming = transclusion.links.filter((l) => l.destination === workBeId);
                  const renderLinks = (links: typeof transclusion.links, label: string, arrow: string) => {
                    if (links.length === 0) return null;
                    return (
                      <div key={label}>
                        <div className="link-section-label">{label} ({links.length})</div>
                        {links.map((link) => {
                          const isOrigin = link.origin === workBeId;
                          const otherId = isOrigin ? link.destination : link.origin;
                          const otherWork = works.find((w) => w.work_id === otherId);
                          const otherTitle = otherWork?.title || `Work ${otherId.toString(16).padStart(4, "0")}`;
                          const ref = link.origin_ref || link.destination_ref;
                          return (
                            <div
                              key={link.link_id}
                              className="link-list-item"
                              onClick={() => selectWork(otherId)}
                            >
                              <div className="link-list-header">
                                <span className="link-list-direction">{arrow}</span>
                                <span className="link-list-title">{otherTitle}</span>
                              </div>
                              {ref?.excerpt && (
                                <span className="link-list-excerpt">
                                  {ref.excerpt.length > 60 ? ref.excerpt.slice(0, 60) + "\u2026" : ref.excerpt}
                                </span>
                              )}
                              {ref?.provenance_chain && ref.provenance_chain.length > 0 && (
                                <span className="link-list-chain" title={ref.provenance_chain.map((h) => `Work ${h.source_work_id.toString(16).padStart(4, "0")} via link ${h.link_id.toString(16).padStart(4, "0")}`).join("\n")}>
                                  {ref.provenance_chain.length} hop{ref.provenance_chain.length > 1 ? "s" : ""}
                                </span>
                              )}
                              <button
                                className="link-list-delete"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  if (clientRef.current) transclusion.deleteLink(clientRef.current, link.link_id);
                                }}
                              >
                                \u00d7
                              </button>
                            </div>
                          );
                        })}
                      </div>
                    );
                  };
                  return (
                    <>
                      {renderLinks(outgoing, "Transcluded to", "\u2192")}
                      {renderLinks(incoming, "Transcluded from", "\u2190")}
                    </>
                  );
                })()
              )}
            </div>
          )}
        </aside>

        <main className="document-area">
          {workBeId !== null ? (
            <>
              <AwarenessIndicators states={awareness} connected={connected} />
              {transclusion.pending && (
                <TransclusionBadge
                  pending={transclusion.pending}
                  onPlace={handlePlaceTransclusion}
                  onCancel={transclusion.clearPending}
                />
              )}
                {isSourceWork ? (
                  <div
                    className="source-work-viewer"
                    style={{
                      padding: "16px 20px",
                      fontSize: "15px",
                      lineHeight: "1.7",
                      whiteSpace: "pre-wrap",
                      wordWrap: "break-word",
                      overflowY: "auto",
                      flex: 1,
                      minHeight: 0,
                      background: "#fafafa",
                      userSelect: "text",
                    }}
                  >
                    {displayText}
                  </div>
                ) : displayText.length > 100_000 ? (
                  <VirtualizedEditor
                    text={displayText}
                   onTextChange={isSourceWork ? undefined : setText}
                   onCursorChange={sendCursor}
                   onSelectionChange={(s, e) => {
                     sendSelection(s, e);
                     if (s !== null && e !== null) setSelectionRange({ start: s, end: e });
                     else setSelectionRange(null);
                   }}
                    connected={connected}
                    attributionSpans={attributionSpans}
                   editable={!isSourceWork && identity !== null}
                    contentStartLine={isSourceWork ? undefined : currentWorkMeta?.content_start_line}
                    contentEndLine={isSourceWork ? undefined : currentWorkMeta?.content_end_line}
                   transclusionMarkers={transclusion.markers}
                   pendingTransclusion={transclusion.pending}
                   onPlaceTransclusion={handlePlaceTransclusion}
                   selectionRange={selectionRange}
                   onNavigateToWork={selectWork}
                  onPasteText={isSourceWork ? undefined : handlePasteText}
                 />
               ) : (
                  <CollaborativeEditor
                    text={displayText}
                   onTextChange={isSourceWork ? undefined : setText}
                  onCursorChange={sendCursor}
                  onSelectionChange={(s, e) => {
                    sendSelection(s, e);
                    if (s !== null && e !== null) setSelectionRange({ start: s, end: e });
                    else setSelectionRange(null);
                  }}
                  connected={connected}
                  attributionSpans={attributionSpans}
                   editable={!isSourceWork && identity !== null}
                   contentStartLine={currentWorkMeta?.content_start_line}
                   contentEndLine={currentWorkMeta?.content_end_line}
                   transclusionMarkers={transclusion.markers}
                   pendingTransclusion={transclusion.pending}
                   onPlaceTransclusion={handlePlaceTransclusion}
                   selectionRange={selectionRange}
                   onNavigateToWork={selectWork}
                  onPasteText={isSourceWork ? undefined : handlePasteText}
                 />
               )}
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
        documentLength={displayText.length}
        visible={showAttribution && workBeId !== null}
      />

      <ImportWizard
        clientRef={clientRef}
        visible={showImport}
        onClose={() => setShowImport(false)}
        onImported={(workId) => {
          setWorkBeId(workId);
          const url = new URL(window.location.href);
          url.searchParams.set("work", String(workId));
          window.history.replaceState({}, "", url.toString());
          loadWorks();
        }}
      />
    </div>
  );
}
