import { useState, useEffect, useCallback, useRef, useMemo } from "react";
import { useCrdtSync } from "../hooks/useCrdtSync";
import { useTransclusion } from "../hooks/useTransclusion";
import { authorColor } from "../author-color";
import { CollaborativeEditor } from "../components/CollaborativeEditor";
import { SourceTextViewer } from "../components/SourceTextViewer";
import { VirtualizedEditor } from "../components/VirtualizedEditor";
import type { BacklinkEntry, AttributionSpan as AttribSpan } from "../api/crdt_sync";
import { DropdownMenu, DropdownItem, DropdownSeparator, DropdownLabel } from "../components/DropdownMenu";
import { AwarenessIndicators } from "../components/AwarenessIndicators";
import { DebugPanel } from "../components/DebugPanel";
import { AttributionPanel } from "../components/AttributionPanel";
import { AnnotationPanel } from "../components/AnnotationPanel";
import { CompareHeader, CompareSplitView, useCompare } from "../components/ComparePanel";
import { IdentityPanel } from "../components/IdentityPanel";
import { ImportWizard } from "../components/ImportWizard";
import { TransclusionBadge } from "../components/TransclusionBadge";
import { WorkSummaryPanel } from "../components/WorkSummaryPanel";
import { DocumentMapPanel } from "../components/DocumentMapPanel";
import { TrailsPanel } from "../components/TrailsPanel";
import { SharePanel } from "../components/SharePanel";
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
  const [showAnnotations, setShowAnnotations] = useState(false);
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
  const [showSummary, setShowSummary] = useState(false);
  const [showShare, setShowShare] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showRevisions, setShowRevisions] = useState(false);
  const [showMap, setShowMap] = useState(false);
  const [showTrails, setShowTrails] = useState(false);
  const [revisionList, setRevisionList] = useState<string[]>([]);
  const [revisionIndex, setRevisionIndex] = useState(0);
  const [similarWorks, setSimilarWorks] = useState<{ query: string; workIds: number[] } | null>(null);
  const [docPrefs, setDocPrefs] = useState<DocPreferences>(loadDocPreferences);
  const [viewMode, setViewMode] = useState<"editing" | "reading">(
    () => (localStorage.getItem("xudanu-view-mode") as "editing" | "reading") || "editing"
  );
  const [authors, setAuthors] = useState<HistoricalAuthorEntry[]>([]);
  const [expandedAuthorId, setExpandedAuthorId] = useState<number | null>(null);
  const [authorWorks, setAuthorWorks] = useState<WorkListEntry[]>([]);
  const [selectionRange, setSelectionRange] = useState<{ start: number; end: number } | null>(null);
  const sourceViewerRef = useRef<HTMLDivElement>(null);

  const transclusion = useTransclusion();
  const [backlinks, setBacklinks] = useState<BacklinkEntry[]>([]);
  const [endorsementCount, setEndorsementCount] = useState(0);
  const [hasEndorsed, setHasEndorsed] = useState(false);
  const [endorsedWorkIds, setEndorsedWorkIds] = useState<Set<number>>(new Set());

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
    annotations,
    refreshAnnotations,
    createAnnotation,
    deleteAnnotation,
    connectionEpoch,
    canEdit,
  } = useCrdtSync(WS_URL, workBeId);

  const toggleStar = useCallback(async (workId: number, current: boolean) => {
    if (!clientRef.current) {
      console.warn("toggleStar: no client");
      return;
    }
    try {
      if (current) {
        await clientRef.current.workUnstar(workId);
      } else {
        await clientRef.current.workStar(workId);
      }
      console.log("toggleStar: success", workId, !current);
      setWorks((prev) =>
        prev.map((w) =>
          w.work_id === workId ? { ...w, is_starred: !current } : w
        )
      );
    } catch (e) {
      console.error("toggleStar failed:", e);
    }
  }, [clientRef]);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    if (params.get("auth") === "1") {
      window.history.replaceState({}, "", "/");
    }
  }, []);

  useEffect(() => {
    if (!clientRef.current || !workBeId) { setBacklinks([]); return; }
    clientRef.current.findBacklinks(workBeId).then(setBacklinks).catch(() => setBacklinks([]));
  }, [workBeId, connected]);

  useEffect(() => {
    if (!clientRef.current || !workBeId || !authenticated) return;
    clientRef.current.workEndorsements(workBeId).then((es) => {
      setEndorsementCount(es.length);
      const myClub = clientRef.current?.currentIdentity?.club_id;
      setHasEndorsed(myClub ? es.some((e) => e[0] === myClub) : false);
    }).catch(() => {});
  }, [workBeId, connected, authenticated]);

  useEffect(() => {
    if (!clientRef.current || !authenticated || works.length === 0) {
      setEndorsedWorkIds(new Set());
      return;
    }
    const myClub = clientRef.current.currentIdentity?.club_id;
    if (!myClub) return;
    let cancelled = false;
    let timer: ReturnType<typeof setTimeout> | null = null;
    const run = async () => {
      const endorsed = new Set<number>();
      for (const w of works) {
        if (cancelled) return;
        try {
          const es = await clientRef.current!.workEndorsements(w.work_id);
          if (es.some((e) => e[0] === myClub)) endorsed.add(w.work_id);
        } catch { break; }
        await new Promise<void>((r) => { timer = setTimeout(r, 50); });
      }
      if (!cancelled) setEndorsedWorkIds(endorsed);
    };
    timer = setTimeout(run, 1000);
    return () => { cancelled = true; if (timer) clearTimeout(timer); };
  }, [works.length, authenticated]);

  const currentWorkMeta = works.find(w => w.work_id === workBeId);
  const isSourceWork = currentWorkMeta?.is_source === true;
  const displayText = text;

  const docAuthors = useMemo(() => {
    const seen = new Map<string, { name: string; color: string }>();
    for (const span of attributionSpans) {
      const name = span.author_display_name || "unknown";
      const key = `${span.author_public_key.join(",")}:${name}`;
      if (seen.has(key)) continue;
      const isHistorical = span.author_type === "historical";
      const isLlm = span.author_type === "llm";
      const color = isHistorical ? "#c4a35a" : isLlm ? "#7c4dff" : authorColor(name);
      seen.set(key, { name, color });
    }
    return Array.from(seen.values());
  }, [attributionSpans]);

  const compare = useCompare(showCompare, workBeId, displayText, clientRef.current);

  useEffect(() => {
    if (clientRef.current) clientRef.current.setSkipCrdt(!!isSourceWork);
  }, [isSourceWork, clientRef]);

  const loadWorks = useCallback(async () => {
    const list = await fetchWorkList();
    setWorks((prev) => {
      const sorted = [...list].sort((a, b) => a.work_id - b.work_id);
      const prevStarred = new Map<number, boolean>();
      for (const w of prev) {
        if (w.is_starred) prevStarred.set(w.work_id, true);
      }
      if (prevStarred.size === 0) return sorted;
      return sorted.map((w) => {
        if (w.is_starred) return w;
        if (prevStarred.has(w.work_id)) return { ...w, is_starred: true };
        return w;
      });
    });
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
    if (showAnnotations && connected && workBeId !== null) {
      refreshAnnotations();
    }
  }, [showAnnotations, connected, workBeId, text, refreshAnnotations]);

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

  useEffect(() => {
    if (!transclusion.pending) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        transclusion.clearPending();
        e.preventDefault();
      }
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  }, [transclusion]);

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

  const toggleEndorse = useCallback(async () => {
    if (!clientRef.current || !workBeId || !identity) {
      console.warn("Endorse: missing client/work/identity", { workBeId, identity: !!identity });
      return;
    }
    const myClub = identity.club_id;
    const pair: [number, number] = [myClub, 1];
    try {
      if (hasEndorsed) {
        await clientRef.current.workRetractEndorsement(workBeId, [pair]);
        setHasEndorsed(false);
        setEndorsementCount((c) => Math.max(0, c - 1));
      } else {
        await clientRef.current.workEndorse(workBeId, [pair]);
        setHasEndorsed(true);
        setEndorsementCount((c) => c + 1);
      }
    } catch (e) {
      console.error("Endorse failed:", e);
    }
  }, [clientRef, workBeId, identity, hasEndorsed]);

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
             {workBeId !== null && (
               <span
                 className={`header-star ${currentWorkMeta?.is_starred ? "starred" : ""}`}
                 onClick={() => toggleStar(workBeId, !!currentWorkMeta?.is_starred)}
                 title={currentWorkMeta?.is_starred ? "Remove from favorites" : "Add to favorites"}
                 role="button"
                 style={{ cursor: "pointer" }}
               >
                 {currentWorkMeta?.is_starred ? "\u2605" : "\u2606"}
               </span>
             )}
             <span className="work-title-label">
              {currentWorkMeta?.title || "Untitled"}
              {isSourceWork && <span className="work-list-badge badge-public" style={{ fontSize: "10px", verticalAlign: "middle", marginLeft: 6 }}>pub src</span>}
            </span>
            {docAuthors.length > 0 && (
              <span className="author-pills">
                {docAuthors.map((a) => (
                  <span
                    key={a.name}
                    className="author-pill"
                    style={{ borderColor: a.color, color: a.color }}
                    title={a.name}
                  >
                    {a.name.length > 12 ? a.name.slice(0, 12) + "\u2026" : a.name}
                  </span>
                ))}
              </span>
            )}
          </>
        )}

        <div className="header-spacer" />

        {workBeId !== null && (
          <>
            {isSourceWork ? (
              <span className="source-badge" title="This is a historical source document — read only">
                Historical · read only
              </span>
            ) : (
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
            )}

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
                     checked={showAnnotations}
                     onClick={() => {
                       setShowAnnotations((a) => {
                         const next = !a;
                         if (next) refreshAnnotations();
                         return next;
                       });
                     }}
                   >
                      Annotations
                    </DropdownItem>
                    <DropdownItem
                      disabled={!selectionRange || !authenticated}
                      onClick={() => {
                        if (!selectionRange) return;
                        const note = prompt("Annotation note:");
                        if (note) {
                          createAnnotation("note", note, selectionRange.start, selectionRange.end);
                          setShowAnnotations(true);
                        }
                        close();
                      }}
                    >
                       Annotate Selection
                     </DropdownItem>
                     <DropdownItem
                       disabled={!selectionRange}
                       onClick={() => {
                         handleTranscludeSelection();
                         close();
                       }}
                     >
                       Transclude Selection
                     </DropdownItem>
                  <DropdownItem
                    disabled={!connected || works.length < 2}
                    onClick={() => { setShowCompare((c) => !c); }}
                  >
                    Compare
                  </DropdownItem>
                  <DropdownItem
                    disabled={!connected || works.length === 0}
                    onClick={() => { setShowMap(true); close(); }}
                  >
                    Document Map
                  </DropdownItem>
                  <DropdownItem
                    disabled={!connected || !authenticated}
                    onClick={() => { setShowTrails(true); close(); }}
                  >
                    Trails
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
                  <DropdownItem
                    disabled={!authenticated || !workBeId}
                    checked={hasEndorsed}
                    onClick={() => { toggleEndorse(); }}
                  >
                    {hasEndorsed ? "Endorsed" : "Endorse"}{endorsementCount > 0 ? ` (${endorsementCount})` : ""}
                  </DropdownItem>
                  <DropdownItem
                    disabled={!workBeId || (currentWorkMeta?.revision_count ?? 0) < 2}
                    onClick={async () => {
                      if (!clientRef.current || !workBeId) return;
                      const count = currentWorkMeta?.revision_count ?? 0;
                      if (count < 2) return;
                      setShowRevisions(true);
                      try {
                        const batchSize = 5;
                        const revs: string[] = [];
                        for (let batch = 0; batch < count; batch += batchSize) {
                          const promises: Promise<string>[] = [];
                          for (let i = batch + 1; i <= Math.min(batch + batchSize, count); i++) {
                            promises.push(clientRef.current!.fetchRevision(workBeId, i).then(t => t || ""));
                          }
                          const batchResults = await Promise.all(promises);
                          revs.push(...batchResults);
                        }
                        setRevisionList(revs);
                        setRevisionIndex(count - 1);
                      } catch (e) {
                        console.error("Failed to load revisions:", e);
                      }
                    }}
                  >
                    Revisions ({currentWorkMeta?.revision_count ?? 0})
                  </DropdownItem>
                  <DropdownItem
                     disabled={!selectionRange || !clientRef.current || !authenticated}
                    onClick={async () => {
                      if (!selectionRange || !clientRef.current) return;
                      const selText = displayText.slice(selectionRange.start, selectionRange.end);
                      if (selText.trim().length < 10) return;
                      try {
                        const workIds = await clientRef.current.findWorksForContent(selText.trim());
                        setSimilarWorks({ query: selText.trim(), workIds });
                      } catch (e) {
                        console.error("Find similar failed:", e);
                      }
                    }}
                  >
                    Find Similar
                  </DropdownItem>
                  <DropdownSeparator />
                  <DropdownItem
                    disabled={!workBeId}
                    onClick={() => { setShowSummary(true); close(); }}
                  >
                    Work Summary
                  </DropdownItem>
                  <DropdownItem
                    disabled={!workBeId}
                    onClick={() => { setShowShare(true); close(); }}
                  >
                    Share
                  </DropdownItem>
                  <DropdownItem onClick={() => { setShowSettings(true); close(); }}>
                    Settings
                  </DropdownItem>
                  {authenticated && (
                    <DropdownItem onClick={() => { logout(); close(); }}>
                      Sign Out
                    </DropdownItem>
                  )}
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
              const base = authenticated ? works : works.filter((w) => w.read_club === publicClubId);
              const filtered = q
                ? base.filter((w) =>
                    (w.title || "").toLowerCase().includes(q) ||
                    w.work_id.toString(16).includes(q)
                  )
                : base;
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
                     <button
                       type="button"
                       className={`star-btn ${w.is_starred ? "starred" : ""}`}
                       onClick={(e) => { e.stopPropagation(); toggleStar(w.work_id, !!w.is_starred); }}
                       title={w.is_starred ? "Remove from favorites" : "Add to favorites"}
                     >
                       {w.is_starred ? "\u2605" : "\u2606"}
                     </button>
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
                     <button
                       type="button"
                       className={`star-btn ${w.is_starred ? "starred" : ""}`}
                       onClick={(e) => { e.stopPropagation(); toggleStar(w.work_id, !!w.is_starred); }}
                       title={w.is_starred ? "Remove from favorites" : "Add to favorites"}
                     >
                       {w.is_starred ? "\u2605" : "\u2606"}
                     </button>
                     <span className="work-list-id">
                       {w.work_id.toString(16).padStart(4, "0")}
                     </span>
                     <span className="work-list-badge badge-public">pub src</span>
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
                  {!searchQuery && works.some((w) => w.is_starred) && (
                    <SidebarSection title={`Favorites (${works.filter((w) => w.is_starred).length})`} defaultOpen={true}>
                      {works.filter((w) => w.is_starred).map((w) => (
                        w.is_source ? renderSourceWork(w) : renderWork(w)
                      ))}
                    </SidebarSection>
                  )}
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
                  {endorsedWorkIds.size > 0 && !searchQuery && (
                    <SidebarSection title={`Endorsed (${endorsedWorkIds.size})`} defaultOpen={false}>
                      {works.filter((w) => endorsedWorkIds.has(w.work_id)).map((w) => (
                        w.is_source ? renderSourceWork(w) : renderWork(w)
                      ))}
                    </SidebarSection>
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
                  {backlinks.length > 0 && (
                    <SidebarSection title={`Referenced by (${backlinks.length})`} defaultOpen={false}>
                      {backlinks.map((bl) => {
                        const blWork = works.find((w) => w.work_id === bl.source_work_id);
                        const blTitle = bl.title || blWork?.title || `Work ${bl.source_work_id.toString(16).padStart(4, "0")}`;
                        return (
                          <div
                            key={bl.link_id}
                            className="link-list-item"
                            onClick={() => selectWork(bl.source_work_id)}
                            title={bl.excerpt || blTitle}
                          >
                            <div className="link-list-header">
                              <span className="link-list-direction">←</span>
                              <span className="link-list-title">{blTitle}</span>
                            </div>
                            {bl.excerpt && (
                              <span className="link-list-excerpt" title={bl.excerpt}>
                                {bl.excerpt.length > 60 ? bl.excerpt.slice(0, 60) + "\u2026" : bl.excerpt}
                              </span>
                            )}
                          </div>
                        );
                      })}
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
              {isSourceWork ? (
                <SourceTextViewer
                  workId={workBeId}
                  clientRef={clientRef}
                  connected={connected}
                  fontSize={docPrefs.fontSize}
                  lineHeight={docPrefs.lineHeight}
                  onSelectionChange={(s, e) => setSelectionRange({ start: s, end: e })}
                />
              ) : viewMode === "reading" && !showCompare ? (
                <ReadingView
                  workId={workBeId}
                  text={displayText}
                  title={currentWorkMeta?.title || `Work ${workIdDisplay}`}
                  attributionSpans={attributionSpans}
                  isSource={isSourceWork}
                  clientRef={clientRef}
                  connected={connected}
                  onSelectionChange={(s, e) => {
                    if (s !== e) setSelectionRange({ start: s, end: e });
                    else setSelectionRange(null);
                  }}
                />
              ) : (
              <>
              <AwarenessIndicators states={awareness} connected={connected} />
              {workBeId && connected && !canEdit && (
                <div className="readonly-banner">
                  Read-only — you do not have edit permission for this work.
                  {identity === null && <span className="readonly-hint"> Log in or create an identity to edit.</span>}
                </div>
              )}
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
                  <SourceTextViewer
                    workId={workBeId!}
                    clientRef={clientRef}
                    connected={connected}
                    fontSize={docPrefs.fontSize}
                    lineHeight={docPrefs.lineHeight}
                  />
                ) : displayText.length > 100_000 ? (
                  <VirtualizedEditor
                    text={displayText}
                    onTextChange={setText}
                    onCursorChange={sendCursor}
                    onSelectionChange={(s, e) => {
                      sendSelection(s, e);
                      if (s !== null && e !== null) setSelectionRange({ start: s, end: e });
                      else setSelectionRange(null);
                    }}
                     connected={connected}
                     attributionSpans={attributionSpans}
                   editable={canEdit}
                     contentStartLine={currentWorkMeta?.content_start_line}
                     contentEndLine={currentWorkMeta?.content_end_line}
                     transclusionMarkers={transclusion.markers}
                     pendingTransclusion={transclusion.pending}
                     onPlaceTransclusion={handlePlaceTransclusion}
                      selectionRange={selectionRange}
                     onNavigateToWork={selectWork}
                     onPasteText={handlePasteText}
                      fontSize={docPrefs.fontSize}
                      lineHeight={docPrefs.lineHeight}
                    />
                 ) : (
                    <CollaborativeEditor
                     text={displayText}
                    onTextChange={canEdit ? setText : undefined}
                   onCursorChange={sendCursor}
                   onSelectionChange={(s, e) => {
                     sendSelection(s, e);
                     if (s !== null && e !== null) setSelectionRange({ start: s, end: e });
                     else setSelectionRange(null);
                   }}
                   connected={connected}
                   attributionSpans={attributionSpans}
                    editable={canEdit}
                    contentStartLine={isSourceWork ? undefined : currentWorkMeta?.content_start_line}
                    contentEndLine={isSourceWork ? undefined : currentWorkMeta?.content_end_line}
                   transclusionMarkers={transclusion.markers}
                   pendingTransclusion={transclusion.pending}
                   onPlaceTransclusion={handlePlaceTransclusion}
                   selectionRange={selectionRange}
                   onNavigateToWork={selectWork}
                    onPasteText={canEdit ? handlePasteText : undefined}
                    fontSize={docPrefs.fontSize}
                    lineHeight={docPrefs.lineHeight}
                   annotations={annotations}
                   onCreateAnnotation={(charStart, charEnd) => {
                     const note = prompt("Annotation note:");
                     if (note) createAnnotation("note", note, charStart, charEnd);
                   }}
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

      {showAnnotations && authenticated && workBeId !== null && (
        <div style={{ position: "fixed", right: 0, top: 0, bottom: 0, width: "260px", background: "var(--bg, #fff)", borderLeft: "1px solid var(--border, #ddd)", overflowY: "auto", zIndex: 100, padding: "8px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "8px" }}>
            <strong>Annotations</strong>
            <button type="button" onClick={() => setShowAnnotations(false)} style={{ background: "none", border: "none", cursor: "pointer", fontSize: "1.2em" }}>&times;</button>
          </div>
          <AnnotationPanel
            annotations={annotations}
            onDelete={deleteAnnotation}
            currentClubId={identity?.club_id ?? null}
            onNavigate={(charStart) => {
              const el = document.querySelector('[contenteditable="true"]');
              if (!el) return;
              const range = document.createRange();
              const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
              let current = 0;
              let node: Node | null;
              while ((node = walker.nextNode())) {
                const len = node.textContent?.length ?? 0;
                if (current + len > charStart) {
                  range.setStart(node, charStart - current);
                  range.collapse(true);
                  const sel = window.getSelection();
                  sel?.removeAllRanges();
                  sel?.addRange(range);
                  break;
                }
                current += len;
              }
            }}
          />
        </div>
      )}

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
      {showRevisions && (
        <div className="modal-overlay" onClick={() => setShowRevisions(false)}>
          <div className="modal-content revision-modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Revision History</h3>
              <button type="button" className="modal-close" onClick={() => setShowRevisions(false)}>x</button>
            </div>
            {revisionList.length === 0 ? (
              <div className="revision-text" style={{ textAlign: "center", color: "#888" }}>Loading...</div>
            ) : (
              <>
                <div className="revision-slider">
                  <input
                    type="range"
                    min={0}
                    max={revisionList.length - 1}
                    value={revisionIndex}
                    onChange={(e) => setRevisionIndex(Number(e.target.value))}
                  />
                  <span className="revision-label">
                    Revision {revisionIndex + 1} / {revisionList.length}
                  </span>
                </div>
                <pre className="revision-text">{revisionList[revisionIndex]}</pre>
              </>
            )}
          </div>
        </div>
      )}
      {similarWorks && (
        <div className="modal-overlay" onClick={() => setSimilarWorks(null)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Similar Works</h3>
              <button type="button" className="modal-close" onClick={() => setSimilarWorks(null)}>x</button>
            </div>
            <p className="similar-query">&ldquo;{similarWorks.query.length > 100 ? similarWorks.query.slice(0, 100) + "\u2026" : similarWorks.query}&rdquo;</p>
            {similarWorks.workIds.length === 0 ? (
              <p className="similar-empty">No similar works found.</p>
            ) : (
              <ul className="similar-results">
                {similarWorks.workIds.map((wid) => {
                  const w = works.find((x) => x.work_id === wid);
                  return (
                    <li key={wid} className="similar-item" onClick={() => { setSimilarWorks(null); selectWork(wid); }}>
                      <span className="similar-id">{wid.toString(16).padStart(4, "0")}</span>
                      <span className="similar-title">{w?.title || "Untitled"}</span>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
        </div>
      )}

      {showSummary && (
        <WorkSummaryPanel
          clientRef={clientRef}
          workBeId={workBeId}
          connected={connected}
          onClose={() => setShowSummary(false)}
          onNavigateToWork={selectWork}
        />
      )}

      {showMap && (
        <DocumentMapPanel
          client={clientRef.current}
          onSelectWork={(id) => { selectWork(id); setShowMap(false); }}
          currentWorkId={workBeId}
          onClose={() => setShowMap(false)}
        />
      )}

      {showTrails && (
        <TrailsPanel
          client={clientRef.current}
          currentWorkId={workBeId}
          onSelectWork={(id) => selectWork(id)}
          onClose={() => setShowTrails(false)}
        />
      )}

      {showShare && workBeId && (
        <SharePanel
          workBeId={workBeId}
          clientRef={clientRef}
          connected={connected}
          canEdit={canEdit}
          onClose={() => setShowShare(false)}
        />
      )}
    </div>
  );
}
