import { useState, useEffect, useCallback, useRef } from "react";
import { useCrdtSync } from "../hooks/useCrdtSync";
import { useTransclusion } from "../hooks/useTransclusion";
import { CollaborativeEditor } from "../components/CollaborativeEditor";
import { VirtualizedEditor } from "../components/VirtualizedEditor";
import { DropdownMenu, DropdownItem, DropdownSeparator, DropdownLabel } from "../components/DropdownMenu";
import { AwarenessIndicators } from "../components/AwarenessIndicators";
import { DebugPanel } from "../components/DebugPanel";
import { AttributionPanel } from "../components/AttributionPanel";
import { CompareHeader, CompareSplitView, useCompare } from "../components/ComparePanel";
import { IdentityPanel } from "../components/IdentityPanel";
import { ImportWizard } from "../components/ImportWizard";
import { TransclusionBadge } from "../components/TransclusionBadge";
import { ReadingView } from "./reading/ReadingView";
import { DocumentSettings, loadDocPreferences, saveDocPreferences } from "../components/DocumentSettings";
import type { DocPreferences } from "../components/DocumentSettings";
import type { WorkListEntry, HistoricalAuthorEntry } from "../api/crdt_sync";

function SidebarSection({ title, defaultOpen = false, children }: { title: string; defaultOpen?: boolean; children: React.ReactNode }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div className="sidebar-collapsible">
      <button
        type="button"
        className="sidebar-collapsible-toggle"
        onClick={() => setOpen((o) => !o)}
      >
        <span className="sidebar-collapsible-arrow">{open ? "▾" : "▸"}</span>
        {title}
      </button>
      {open && <div className="sidebar-collapsible-content">{children}</div>}
    </div>
  );
}

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
  const [showImport, setShowImport] = useState(false);
  const [showCompare, setShowCompare] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [docPrefs, setDocPrefs] = useState<DocPreferences>(loadDocPreferences);
  const [viewMode, setViewMode] = useState<"editing" | "reading">(
    () => (localStorage.getItem("xudanu-view-mode") as "editing" | "reading") || "editing"
  );
  const [authors, setAuthors] = useState<HistoricalAuthorEntry[]>([]);
  const [expandedAuthorId, setExpandedAuthorId] = useState<number | null>(null);
  const [authorWorks, setAuthorWorks] = useState<WorkListEntry[]>([]);
  const [sourceText, setSourceText] = useState<string | null>(null);
  const [selectionRange, setSelectionRange] = useState<{ start: number; end: number } | null>(null);
  const sourceViewerRef = useRef<HTMLDivElement>(null);

  const transclusion = useTransclusion();

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const wid = params.get("work");
    if (wid) {
      const parsed = wid.startsWith("0x") ? parseInt(wid, 16) : parseInt(wid, 10);
      if (!isNaN(parsed)) setWorkBeId(parsed);
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
    createIdentity,
    clientRef,
  } = useCrdtSync(WS_URL, workBeId);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    if (params.get("auth") === "1") {
      window.history.replaceState({}, "", "/");
    }
  }, []);

  const currentWorkMeta = works.find(w => w.work_id === workBeId);
  const isSourceWork = currentWorkMeta?.is_source === true;
  const displayText = isSourceWork && sourceText !== null ? sourceText : text;

  const compare = useCompare(showCompare, workBeId, displayText, clientRef.current);

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
    if (connected) loadAuthors();

  }, [connected, authenticated, loadAuthors]);
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
    const newText = text.slice(0, position) + excerpt + text.slice(position);
    setText(newText);
    const linkId = await transclusion.placeTransclusion(clientRef.current, workBeId, position);
    if (linkId !== null) {
      if (clientRef.current) {
        await new Promise((r) => setTimeout(r, 500));
        await transclusion.loadLinks(clientRef.current, workBeId, works);
      }
    }
  }, [clientRef, workBeId, transclusion, works, text, setText]);

  useEffect(() => {
    if (!isSourceWork) return;
    const el = sourceViewerRef.current;
    if (!el) return;
    const handler = () => {
      const sel = window.getSelection();
      if (!sel || sel.rangeCount === 0 || !el.contains(sel.anchorNode)) {
        setSelectionRange(null);
        return;
      }
      if (sel.isCollapsed) {
        setSelectionRange(null);
        return;
      }
      const range = sel.getRangeAt(0);
      const pre = document.createRange();
      pre.selectNodeContents(el);
      pre.setEnd(range.startContainer, range.startOffset);
      const start = pre.toString().length;
      const preEnd = document.createRange();
      preEnd.selectNodeContents(el);
      preEnd.setEnd(range.endContainer, range.endOffset);
      const end = preEnd.toString().length;
      setSelectionRange({ start, end });
    };
    document.addEventListener("selectionchange", handler);
    return () => document.removeEventListener("selectionchange", handler);
  }, [isSourceWork]);

  const handleTranscludeSelection = useCallback(() => {
    if (!selectionRange || workBeId === null) return;
    const selectedText = displayText.slice(selectionRange.start, selectionRange.end);
    const title = currentWorkMeta?.title || `Work ${workBeId.toString(16).padStart(4, "0")}`;
    transclusion.holdSelection(workBeId, title, selectionRange.start, selectionRange.end, selectedText);
  }, [selectionRange, workBeId, displayText, currentWorkMeta, transclusion]);

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

        {workIdDisplay && (
          <>
            <div className="header-separator" />
            <span className="work-id-label">{workIdDisplay}</span>
            <span className="work-title-label">
              {currentWorkMeta?.title || "Untitled"}
              {isSourceWork ? " SRC" : ""}
            </span>
          </>
        )}

        <div className="header-spacer" />

        {workBeId !== null && (
          <>
            <button
              onClick={() => {
                const next = viewMode === "editing" ? "reading" : "editing";
                setViewMode(next);
                localStorage.setItem("xudanu-view-mode", next);
              }}
              type="button"
              className={`mode-toggle-btn ${viewMode === "reading" ? "mode-reading" : ""}`}
              title={viewMode === "reading" ? "Switch to Editing mode" : "Switch to Reading mode"}
            >
              {viewMode === "reading" ? "✏️ Edit" : "👁 View"}
            </button>

            {identity && (
              <DropdownMenu
                label={isShared ? "Shared ▾" : isPublic ? "Public ▾" : "Share ▾"}
                active={isShared || isPublic}
              >
                {(close) => (
                  <>
                    <DropdownLabel>Visibility</DropdownLabel>
                    <DropdownItem
                      checked={isPublic}
                      onClick={async () => {
                        if (!isPublic && workBeId !== null) {
                          const targetClub = publicClubId;
                          if (targetClub) {
                            await setVisibility(workBeId, targetClub);
                            setIsPublic(true);
                            loadWorks();
                          }
                        }
                        close();
                      }}
                    >
                      Public — anyone can read
                    </DropdownItem>
                    <DropdownItem
                      checked={!isPublic}
                      onClick={async () => {
                        if (isPublic && workBeId !== null) {
                          const targetClub = identity?.club_id ?? null;
                          if (targetClub) {
                            await setVisibility(workBeId, targetClub);
                            setIsPublic(false);
                            loadWorks();
                          }
                        }
                        close();
                      }}
                    >
                      Private — only you
                    </DropdownItem>
                    <DropdownSeparator />
                    <DropdownLabel>Editing</DropdownLabel>
                    <DropdownItem
                      checked={isShared}
                      onClick={async () => {
                        if (isShared) {
                          await unshareWork();
                          setIsShared(false);
                        } else {
                          await shareWork();
                          setIsPublic(true);
                          setIsShared(true);
                        }
                        close();
                      }}
                    >
                      {isShared ? "Restrict to owner" : "Anyone can edit"}
                    </DropdownItem>
                  </>
                )}
              </DropdownMenu>
            )}

            <DropdownMenu label="More ▾">
              {(close) => (
                <>
                  <DropdownItem
                    checked={watchEnabled}
                    onClick={() => { toggleWatch(); }}
                  >
                    Watch for matches
                  </DropdownItem>
                  <DropdownItem
                    checked={showAttribution}
                    onClick={() => {
                      setShowAttribution((a) => {
                        const next = !a;
                        if (next) refreshAttribution();
                        return next;
                      });
                    }}
                  >
                    Show attribution
                  </DropdownItem>
                  <DropdownItem
                    disabled={!connected || works.length < 2}
                    onClick={() => { setShowCompare((c) => !c); }}
                  >
                    Compare
                  </DropdownItem>
                  <DropdownSeparator />
                  <DropdownItem
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
                    disabled={!llmEnabled || narrating}
                  >
                    {narrating ? "Summarizing..." : "Summarize Changes"}
                  </DropdownItem>
                  <DropdownItem
                    onClick={async () => {
                      setLoadingFeedback(true);
                      setFeedback(null);
                      setFeedbackModel("");
                      const result = await getWritingFeedback();
                      setFeedback(result.text);
                      setFeedbackModel(result.model);
                      setLoadingFeedback(false);
                    }}
                    disabled={!llmEnabled || loadingFeedback}
                  >
                    {loadingFeedback ? "Reviewing..." : "Writing Feedback"}
                  </DropdownItem>
                  <DropdownSeparator />
                  <DropdownItem
                    checked={showDebug}
                    onClick={() => { setShowDebug((d) => !d); }}
                  >
                    Debug panel
                  </DropdownItem>
                  <DropdownSeparator />
                  <DropdownItem onClick={() => { setShowSettings(true); }}>
                    Settings
                  </DropdownItem>
                </>
              )}
            </DropdownMenu>

            <CompareHeader
              visible={showCompare}
              state={compare}
              currentWorkId={workBeId}
              works={works}
              revisionCount={currentWorkMeta?.revision_count ?? 0}
              onClose={() => setShowCompare(false)}
            />
            {selectionRange && !transclusion.pending && (
              <button
                onClick={handleTranscludeSelection}
                type="button"
                className="transclude-btn"
                title="Create transclusion link from selected text"
              >
                Transclude ({selectionRange.start}-{selectionRange.end})
              </button>
            )}
          </>
        )}
        <IdentityPanel
          identity={identity}
          connected={connected}
          onLogin={login}
          onCreateIdentity={createIdentity}
          onLogout={logout}
        />
      </header>

      {error && <div className="error">{error}</div>}

      <div className="workspace-body">
        <aside className="document-sidebar">
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
              placeholder="Search documents, authors..."
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
              const filteredAuthors = q
                ? authors.filter((a) =>
                    (a.display_name || a.name || "").toLowerCase().includes(q)
                  )
                : authors;
              const outgoing = transclusion.links.filter((l) => l.origin === workBeId);
              const incoming = transclusion.links.filter((l) => l.destination === workBeId);

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

              const renderSourceWork = (w: WorkListEntry) => (
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
              );

              const renderLinkItem = (link: typeof transclusion.links[0], arrow: string) => {
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
                    title={ref?.excerpt || otherTitle}
                  >
                    <div className="link-list-header">
                      <span className="link-list-direction">{arrow}</span>
                      <span className="link-list-title">{otherTitle}</span>
                    </div>
                    {ref?.excerpt && (
                      <span className="link-list-excerpt" title={ref.excerpt}>
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
                      {"\u00d7"}
                    </button>
                  </div>
                );
              };

              const hasContent = docs.length > 0 || sources.length > 0 || filteredAuthors.length > 0 || outgoing.length > 0 || incoming.length > 0;

              if (!hasContent && !q) {
                return <div className="work-list-empty">No documents yet</div>;
              }
              if (!hasContent && q) {
                return <div className="work-list-empty">No matches</div>;
              }

              return (
                <>
                  {docs.length > 0 && (
                    <div className="sidebar-section">
                      <div className="link-section-label">Documents ({docs.length})</div>
                      {docs.map(renderWork)}
                    </div>
                  )}
                  {sources.length > 0 && (
                    <div className="sidebar-section">
                      <div className="link-section-label">Source Works ({sources.length})</div>
                      {sources.map(renderSourceWork)}
                    </div>
                  )}
                  {(outgoing.length > 0 || incoming.length > 0) && (
                    <SidebarSection title={`Links (${outgoing.length + incoming.length})`} defaultOpen={false}>
                      {outgoing.length > 0 && (
                        <div className="sidebar-section">
                          <div className="link-section-label">Transcluded to ({outgoing.length})</div>
                          {outgoing.map((l) => renderLinkItem(l, "\u2192"))}
                        </div>
                      )}
                      {incoming.length > 0 && (
                        <div className="sidebar-section">
                          <div className="link-section-label">Transcluded from ({incoming.length})</div>
                          {incoming.map((l) => renderLinkItem(l, "\u2190"))}
                        </div>
                      )}
                    </SidebarSection>
                  )}
                  {filteredAuthors.length > 0 && (
                    <SidebarSection title={`Authors (${filteredAuthors.length})`} defaultOpen={authors.length <= 5}>
                      {filteredAuthors.map((a) => (
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
                      ))}
                    </SidebarSection>
                  )}
                </>
              );
            })()}
          </div>
        </aside>

        <main className="document-area">
          {workBeId !== null ? (
            <>
              {viewMode === "reading" && !showCompare ? (
                <ReadingView
                  workId={workBeId}
                  text={displayText}
                  title={currentWorkMeta?.title || `Work ${workIdDisplay}`}
                  attributionSpans={attributionSpans}
                  isSource={isSourceWork}
                  clientRef={clientRef}
                  connected={connected}
                />
              ) : (
              <>
              <AwarenessIndicators states={awareness} connected={connected} />
              {transclusion.pending && (
                <TransclusionBadge
                  pending={transclusion.pending}
                  onPlace={handlePlaceTransclusion}
                  onCancel={transclusion.clearPending}
                />
              )}
              {showCompare && compare.hasTarget ? (
                <CompareSplitView currentText={displayText} state={compare} />
                ) : isSourceWork ? (
                  <div
                    ref={sourceViewerRef}
                    className="source-work-viewer"
                    style={{
                      padding: "16px 20px",
                      fontSize: `${docPrefs.fontSize}px`,
                      lineHeight: `${docPrefs.lineHeight}`,
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
                   fontSize={docPrefs.fontSize}
                   lineHeight={docPrefs.lineHeight}
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
                   fontSize={docPrefs.fontSize}
                   lineHeight={docPrefs.lineHeight}
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

      <DocumentSettings
        visible={showSettings}
        onClose={() => setShowSettings(false)}
        prefs={docPrefs}
        onPrefsChange={setDocPrefs}
      />
    </div>
  );
}
