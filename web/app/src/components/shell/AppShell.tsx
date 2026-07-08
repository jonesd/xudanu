import { useState, useEffect, useCallback, useRef, useMemo } from "react";
import { useCrdtSync } from "../../hooks/useCrdtSync";
import { useTransclusion, DEFAULT_LINK_TYPES } from "../../hooks/useTransclusion";
import { useCompoundEdition } from "../../hooks/useCompoundEdition";
import { authorColorPair } from "../../author-color";
import { CollaborativeEditor } from "../CollaborativeEditor";
import { TransclusionBadge } from "../TransclusionBadge";
import { LinkCreator } from "../LinkCreator";
import type { LinkCreatorSource } from "../LinkCreator";
import { AnnotationPanel } from "../AnnotationPanel";
import { AnnotationDialog } from "../AnnotationDialog";
import { CompoundPanel } from "../CompoundPanel";
import { AttributionPanel } from "../AttributionPanel";
import { SourceTextViewer } from "../SourceTextViewer";
import { ConnectionOverlay } from "../ConnectionOverlay";
import { IdentityPanel } from "../IdentityPanel";
import { ImportWizard } from "../ImportWizard";
import { TrailsPanel } from "../TrailsPanel";
import { DocumentSettings, loadDocPreferences } from "../DocumentSettings";
import type { DocPreferences } from "../DocumentSettings";
import type { WorkListEntry } from "../../api/crdt_sync";
import { TopBar } from "./TopBar";
import { LeftRail } from "./LeftRail";
import { BottomBar } from "./BottomBar";
import { ContextPanel } from "./ContextPanel";
import { LibrarySlideOut } from "./LibrarySlideOut";
import { SearchOverlay } from "./SearchOverlay";
import { PermissionBadge } from "./PermissionBadge";
import { buildProvValidatorHtml } from "../../prov-validator";
import "../../app-shell.css";

const WS_URL = `${window.location.protocol === "https:" ? "wss" : "ws"}://${window.location.host}/xudanu`;

export function AppShell() {
  const [workBeId, setWorkBeId] = useState<number | null>(() => {
    const wid = new URLSearchParams(window.location.search).get("work");
    if (wid) {
      const parsed = wid.startsWith("0x") ? parseInt(wid, 16) : parseInt(wid, 10);
      if (!isNaN(parsed)) return parsed;
    }
    return null;
  });
  const [writeMode, setWriteMode] = useState(false);
  const [focusMode, setFocusMode] = useState(false);
  const [activeRail, setActiveRail] = useState("document");
  const [libraryOpen, setLibraryOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [showImport, setShowImport] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showIdentity, setShowIdentity] = useState(false);
  const [showProvenance, setShowProvenance] = useState(false);
  const [showTrails, setShowTrails] = useState(false);
  const [showAnnotations, setShowAnnotations] = useState(false);
  const [showCompound, setShowCompound] = useState(false);
  const [annotationTarget, setAnnotationTarget] = useState<{ start: number; end: number } | null>(null);
  const [isPublished, setIsPublished] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [works, setWorks] = useState<WorkListEntry[]>([]);
  const [selectionRange, setSelectionRange] = useState<{ start: number; end: number } | null>(null);
  const [docPrefs, setDocPrefs] = useState<DocPreferences>(loadDocPreferences());
  const [linkCreatorSource, setLinkCreatorSource] = useState<LinkCreatorSource | null>(null);
  const [pinnedKeys, setPinnedKeys] = useState<Set<string>>(new Set());
  const lastTypingRef = useRef(0);

  useEffect(() => {
    if (new URLSearchParams(window.location.search).get("auth") === "1") {
      window.history.replaceState({}, "", "/");
    }
  }, []);

  const crdt = useCrdtSync(WS_URL, workBeId);
  const {
    text,
    connected,
    authenticated,
    awareness,
    setText,
    sendCursor,
    sendSelection,
    identity,
    login,
    createWork,
    createIdentity,
    logout,
    clientRef,
    attributionSpans,
    attributionLogStatus,
    refreshAttribution,
    annotations,
    refreshAnnotations,
    createAnnotation,
    deleteAnnotation,
    canEdit,
    reconnectAttempt,
    fetchWorkList,
  } = crdt;

  const transclusion = useTransclusion();
  const compound = useCompoundEdition(connected ? clientRef.current : null, workBeId);

  const loadWorks = useCallback(async () => {
    if (!fetchWorkList) return;
    try {
      const list = await fetchWorkList();
      if (list) setWorks(list);
    } catch {
      // work list fetch is best-effort; failures surface via empty library
    }
  }, [fetchWorkList]);

  useEffect(() => {
    if (connected) loadWorks();
  }, [connected, authenticated, loadWorks]);

  useEffect(() => {
    if (!connected) return;
    const interval = setInterval(() => {
      const now = Date.now();
      const isTyping = now - lastTypingRef.current < 3000;
      if (!isTyping && !document.hidden) loadWorks();
    }, 5000);
    return () => clearInterval(interval);
  }, [connected, loadWorks]);

  const loadTransclusionLinks = transclusion.loadLinks;
  const loadBacklinks = transclusion.loadBacklinks;
  const loadLinkTypes = transclusion.loadLinkTypes;
  useEffect(() => {
    if (connected && workBeId !== null && clientRef.current) {
      refreshAttribution();
      refreshAnnotations();
    }
    if (connected && workBeId !== null && clientRef.current && identity) {
      loadTransclusionLinks(clientRef.current, workBeId, works);
      loadBacklinks(clientRef.current, workBeId);
    }
  }, [connected, workBeId, works, identity, loadTransclusionLinks, loadBacklinks, refreshAttribution, refreshAnnotations]);

  useEffect(() => {
    if (!connected || workBeId === null || !clientRef.current) return;
    const handler = setTimeout(() => {
      refreshAttribution();
      if (identity) {
        loadTransclusionLinks(clientRef.current!, workBeId!, works);
      }
    }, 500);
    return () => clearTimeout(handler);
  }, [text, connected, workBeId, identity, works, loadTransclusionLinks, refreshAttribution]);

  useEffect(() => {
    if (connected && clientRef.current && identity) {
      loadLinkTypes(clientRef.current);
    }
  }, [connected, identity, loadLinkTypes]);

  useEffect(() => {
    if (connected && workBeId !== null && clientRef.current && identity) {
      clientRef.current.workIsPublished(workBeId).then(setIsPublished).catch(() => setIsPublished(false));
      clientRef.current.workEditClub(workBeId).then((c) => setEditOpen(c === 1)).catch(() => setEditOpen(false));
    } else {
      setIsPublished(false);
      setEditOpen(false);
    }
  }, [connected, workBeId, identity]);

  const [publishError, setPublishError] = useState<string | null>(null);
  const [, setExportingReport] = useState(false);

  const handleTogglePublish = useCallback(async () => {
    if (!clientRef.current || workBeId === null) return;
    setPublishError(null);
    try {
      if (isPublished) {
        await clientRef.current.workUnpublish(workBeId);
        setIsPublished(false);
      } else {
        await clientRef.current.workPublish(workBeId);
        setIsPublished(true);
      }
    } catch (e) {
      const msg = String((e as Error)?.message || e || "unknown error");
      console.error("Failed to toggle publish state:", msg);
      setPublishError(msg);
      setTimeout(() => setPublishError(null), 5000);
    }
  }, [clientRef, workBeId, isPublished]);

  const handleToggleEditAccess = useCallback(async () => {
    if (!clientRef.current || workBeId === null) return;
    try {
      if (editOpen) {
        await clientRef.current.workSetEditClub(workBeId, null);
        setEditOpen(false);
      } else {
        await clientRef.current.workSetEditClub(workBeId, 1);
        setEditOpen(true);
      }
    } catch (e) {
      console.error("Failed to toggle edit access:", e);
    }
  }, [clientRef, workBeId, editOpen]);

  const handleExportReport = useCallback(async () => {
    if (!clientRef.current || workBeId === null) return;
    setExportingReport(true);
    try {
      const reportJson = await clientRef.current.generateAttestationReport(workBeId);
      const blob = new Blob([reportJson], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `work-${workBeId.toString(16).padStart(4, "0")}-attestation-${Date.now()}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (e) {
      console.error("Failed to export attestation report:", e);
    } finally {
      setExportingReport(false);
    }
  }, [clientRef, workBeId]);

  const handleExportProvJson = useCallback(async () => {
    if (!clientRef.current || workBeId === null) return;
    try {
      const provJson = await clientRef.current.exportProvJson(workBeId);
      const parsed = JSON.parse(provJson);
      const html = buildProvValidatorHtml(JSON.stringify(parsed, null, 2));
      const blob = new Blob([html], { type: "text/html" });
      const url = URL.createObjectURL(blob);
      window.open(url, "_blank");
      setTimeout(() => URL.revokeObjectURL(url), 60000);
    } catch (e) {
      console.error("Failed to export PROV-JSON:", e);
    }
  }, [clientRef, workBeId]);

  const selectWork = useCallback((id: number) => {
    setWorkBeId(id);
    const url = new URL(window.location.href);
    url.searchParams.set("work", `0x${id.toString(16)}`);
    window.history.replaceState({}, "", url.toString());
    setLibraryOpen(false);
  }, []);

  const handleShowBacklinks = useCallback(
    (workId: number) => {
      setFocusMode(false);
      selectWork(workId);
    },
    [selectWork],
  );

  const handleCreate = useCallback(async () => {
    try {
      const newId = await createWork();
      if (newId !== null) {
        selectWork(newId);
        loadWorks();
      } else {
        console.warn("[handleCreate] createWork returned null - user may need to log in");
      }
    } catch (e) {
      const err = e as Error;
      console.error("[handleCreate] Failed to create work:", err.message);
      
      // Categorize errors without exposing technical details
      const showError = (userMessage: string) => {
        alert(userMessage);
      };
      
      if (err.message.includes("not authorized") || 
          err.message.includes("NotAuthorized") ||
          err.message.includes("authentication") ||
          err.message.includes("unauthorized")) {
        showError("Please create an identity first to create documents");
      } else if (err.message.includes("network") || 
                 err.message.includes("fetch") ||
                 err.message.includes("connection")) {
        showError("Network error. Please check your connection and try again.");
      } else if (err.message.includes("timeout")) {
        showError("Request timed out. Please try again.");
      } else {
        showError("Failed to create document. Please try again.");
      }
    }
  }, [createWork, selectWork, loadWorks]);

  const currentWorkMeta = works.find((w) => w.work_id === workBeId);
  const isSourceWork = currentWorkMeta?.is_source === true;
  const hasInlineTransclusions = compound.hasCompound && compound.spanRanges.length > 0;
  const displayText = hasInlineTransclusions ? compound.resolvedText : text;

  const handleTextChange = useCallback(
    (newText: string) => {
      lastTypingRef.current = Date.now();
      setText(newText);
    },
    [setText]
  );

  const handleTranscludeSelection = useCallback(() => {
    if (!selectionRange || workBeId === null) return;
    let selectedText = "";
    const domSel = window.getSelection();
    if (domSel && !domSel.isCollapsed && domSel.toString().length > 0) {
      selectedText = domSel.toString();
    } else {
      selectedText = displayText.slice(selectionRange.start, selectionRange.end);
    }
    const title = currentWorkMeta?.title || `Work ${workBeId.toString(16).padStart(4, "0")}`;
    transclusion.holdSelection(workBeId, title, selectionRange.start, selectionRange.end, selectedText);
  }, [selectionRange, workBeId, displayText, currentWorkMeta, transclusion]);

  const handlePlaceTransclusion = useCallback(
    async (position: number, padding?: string) => {
      if (!clientRef.current || workBeId === null) return;
      const pending = transclusion.pending;
      if (!pending) return;
      const rawExcerpt = pending.text;
      let spanStart = position;
      if (padding && padding.length > 0) {
        const newText = text + padding;
        setText(newText);
        await new Promise((r) => setTimeout(r, 200));
        spanStart = newText.length;
      }
      await compound.addSpan(
        text,
        spanStart,
        rawExcerpt,
        pending.sourceWorkId,
        pending.start,
        pending.end,
      );
      const linkId = await transclusion.placeTransclusion(clientRef.current, workBeId, spanStart);
      if (linkId !== null && clientRef.current) {
        await new Promise((r) => setTimeout(r, 500));
        await transclusion.loadLinks(clientRef.current, workBeId, works);
      }
    },
    [clientRef, workBeId, transclusion, works, text, compound, setText],
  );

  const handleCreateLinkSelection = useCallback(() => {
    if (!selectionRange || workBeId === null) return;
    let selectedText = "";
    const domSel = window.getSelection();
    if (domSel && !domSel.isCollapsed && domSel.toString().length > 0) {
      selectedText = domSel.toString();
    } else {
      selectedText = displayText.slice(selectionRange.start, selectionRange.end);
    }
    const title = currentWorkMeta?.title || `Work ${workBeId.toString(16).padStart(4, "0")}`;
    transclusion.holdLinkSelection(workBeId, title, selectionRange.start, selectionRange.end, selectedText);
  }, [selectionRange, workBeId, displayText, currentWorkMeta, transclusion]);

  const handleOpenLinkCreator = useCallback(() => {
    if (!selectionRange || workBeId === null) return;
    let selectedText = "";
    const domSel = window.getSelection();
    if (domSel && !domSel.isCollapsed && domSel.toString().length > 0) {
      selectedText = domSel.toString();
    } else {
      selectedText = displayText.slice(selectionRange.start, selectionRange.end);
    }
    const title = currentWorkMeta?.title || `Work ${workBeId.toString(16).padStart(4, "0")}`;
    setLinkCreatorSource({
      workId: workBeId,
      workTitle: title,
      start: selectionRange.start,
      end: selectionRange.end,
      text: selectedText,
    });
  }, [selectionRange, workBeId, displayText, currentWorkMeta]);

  const handleLinkCreatorDone = useCallback(async () => {
    if (!clientRef.current || workBeId === null) return;
    await new Promise((r) => setTimeout(r, 300));
    await transclusion.loadLinks(clientRef.current, workBeId, works);
    await transclusion.loadBacklinks(clientRef.current, workBeId);
  }, [clientRef, workBeId, transclusion, works]);

  const handleDeleteLink = useCallback(async (linkId: number) => {
    if (!clientRef.current || workBeId === null) return;
    await transclusion.deleteLink(clientRef.current, linkId);
    await transclusion.loadBacklinks(clientRef.current, workBeId);
  }, [clientRef, workBeId, transclusion]);

  const handleRetypeLink = useCallback(async (linkId: number, typeId: number) => {
    if (!clientRef.current || workBeId === null) return;
    try {
      await clientRef.current.linkSetTypes(linkId, [typeId]);
      await new Promise((r) => setTimeout(r, 200));
      await transclusion.loadLinks(clientRef.current, workBeId, works);
    } catch (e) {
      console.error("Failed to retype link:", e);
    }
  }, [clientRef, workBeId, transclusion, works]);

  const handleCreateLinkTarget = useCallback(
    async (typeId: number) => {
      if (!clientRef.current || workBeId === null || !selectionRange) return;
      let targetText = "";
      const domSel = window.getSelection();
      if (domSel && !domSel.isCollapsed && domSel.toString().length > 0) {
        targetText = domSel.toString();
      } else {
        targetText = displayText.slice(selectionRange.start, selectionRange.end);
      }
      const linkId = await transclusion.createContentLink(
        clientRef.current,
        workBeId,
        selectionRange.start,
        selectionRange.end,
        targetText,
        typeId,
      );
      if (linkId !== null && clientRef.current) {
        await new Promise((r) => setTimeout(r, 300));
        await transclusion.loadLinks(clientRef.current, workBeId, works);
        await transclusion.loadBacklinks(clientRef.current, workBeId);
      }
    },
    [clientRef, workBeId, selectionRange, displayText, transclusion, works],
  );

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setSearchOpen((s) => !s);
      }
      if (e.key === "Escape") {
        setSearchOpen(false);
        setLibraryOpen(false);
        setLinkCreatorSource(null);
        setAnnotationTarget(null);
      }
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  }, []);

  useEffect(() => {
    if (!transclusion.pending && !transclusion.pendingLink) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        transclusion.clearPending();
        transclusion.clearPendingLink();
        e.preventDefault();
      }
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  }, [transclusion]);

  const [rosters, setRosters] = useState<Record<number, { members: [number, string][]; total: number; truncated: boolean }>>({});

  useEffect(() => {
    const clubs = identity?.clubs;
    if (!clubs || clubs.length === 0 || !clientRef.current) { setRosters({}); return; }
    const client = clientRef.current;
    let cancelled = false;
    type Roster = { members: [number, string][]; total: number; truncated: boolean };
    Promise.all(
      clubs.map(([cid]) =>
        client.clubRoster(cid)
          .then((r): [number, Roster] => [cid, r])
          .catch((): [number, Roster] => [cid, { members: [], total: 0, truncated: false }]),
      ),
    ).then((entries) => {
      if (cancelled) return;
      const map: Record<number, Roster> = {};
      for (const [cid, r] of entries) map[cid] = r;
      setRosters(map);
    });
    return () => { cancelled = true; };
  }, [identity]);

  useEffect(() => {
    if (!identity || !clientRef.current) { setPinnedKeys(new Set()); return; }
    const client = clientRef.current;
    let cancelled = false;
    client.connectionPinsGet()
      .then((pins) => {
        if (!cancelled) setPinnedKeys(new Set(pins));
      })
      .catch(() => { if (!cancelled) setPinnedKeys(new Set()); });
    return () => { cancelled = true; };
  }, [identity]);

  const handleTogglePin = useCallback(async (key: string, pinned: boolean) => {
    if (!clientRef.current) return;
    setPinnedKeys((prev) => {
      const next = new Set(prev);
      if (pinned) next.add(key);
      else next.delete(key);
      return next;
    });
    try {
      if (pinned) await clientRef.current.connectionPinSet(key);
      else await clientRef.current.connectionPinUnset(key);
    } catch (e) {
      console.error("Failed to persist pin:", e);
      setPinnedKeys((prev) => {
        const next = new Set(prev);
        if (pinned) next.delete(key);
        else next.add(key);
        return next;
      });
    }
  }, [clientRef]);

  const identityName = identity?.display_name || null;
  const identityColor = identityName
    ? authorColorPair(identityName).primary
    : "#8a8a96";

  const editable = writeMode && canEdit;

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.altKey && (e.metaKey || e.ctrlKey) && e.key === "a") {
        e.preventDefault();
        if (selectionRange && workBeId !== null && editable) {
          setAnnotationTarget({ start: selectionRange.start, end: selectionRange.end });
        }
      }
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  }, [selectionRange, workBeId, editable]);

  const handleCreateAnnotation = useCallback(
    (charStart: number, charEnd: number) => {
      if (!editable) return;
      setAnnotationTarget({ start: charStart, end: charEnd });
    },
    [editable],
  );

  const handleAnnotationSubmit = useCallback(
    (text: string, isPrivate: boolean) => {
      if (!annotationTarget) return;
      createAnnotation("note", text, annotationTarget.start, annotationTarget.end, isPrivate);
    },
    [annotationTarget, createAnnotation],
  );

  const wordCount = useMemo(() => {
    if (!displayText) return 0;
    return displayText.trim().split(/\s+/).filter(Boolean).length;
  }, [displayText]);

  const workIdDisplay = workBeId ? workBeId.toString(16).padStart(4, "0") : null;

  const handleRailNav = useCallback(
    (item: string) => {
      setActiveRail(item);
      if (item === "identity") setShowIdentity(true);
      else if (item === "settings") setShowSettings(true);
      else if (item === "provenance") setShowProvenance((s) => !s);
      else if (item === "trails") setShowTrails((s) => !s);
      else if (item === "annotate") setShowAnnotations((s) => !s);
      else if (item === "compound") setShowCompound((s) => !s);
    },
    []
  );

  const handleEditorSelectionChange = useCallback(
    (s: number | null, e: number | null) => {
      sendSelection(s, e);
      if (s !== null && e !== null) setSelectionRange({ start: s, end: e });
      else setSelectionRange(null);
    },
    [sendSelection]
  );

  return (
    <div className={`app-shell ${focusMode ? "focus-mode" : ""}`}>
      <TopBar
        connected={connected}
        identityName={identityName}
        identityColor={identityColor}
        writeMode={writeMode}
        canEdit={canEdit}
        onToggleWrite={() => setWriteMode((w) => !w)}
        onOpenSearch={() => setSearchOpen(true)}
        onOpenIdentity={() => setShowIdentity(true)}
      />

      <LeftRail
        activeItem={activeRail}
        onNavigate={handleRailNav}
        onOpenLibrary={() => setLibraryOpen((o) => !o)}
        onOpenSearch={() => setSearchOpen(true)}
      />

      <div className="document-area">
        {workBeId !== null && selectionRange && !transclusion.pending && !transclusion.pendingLink && !linkCreatorSource && (
          <div className="selection-actions">
            <button
              type="button"
              className="selection-action-btn transclusion-action"
              onClick={handleTranscludeSelection}
              title="Hold this selection as a transclusion to insert elsewhere"
            >
              Transclude
            </button>
            <button
              type="button"
              className="selection-action-btn link-action"
              onClick={handleOpenLinkCreator}
              title="Create a typed link from this selection"
            >
              Link
            </button>
          </div>
        )}
        {workBeId !== null && transclusion.pending && (
          <TransclusionBadge
            pending={transclusion.pending}
            cursorPosition={selectionRange?.start ?? null}
            onPlace={handlePlaceTransclusion}
            onCancel={transclusion.clearPending}
          />
        )}
        {workBeId === null ? (
          <div className="welcome-screen">
            <div className="welcome-title">xudanu</div>
            <div className="welcome-subtitle">
              A connected literature where every quotation maintains its bond to the original,
              where every reuse carries its full provenance.
            </div>
            <div className="welcome-actions">
              <button className="welcome-btn primary" onClick={handleCreate}>
                New Document
              </button>
              <button className="welcome-btn" onClick={() => setShowImport(true)}>
                Import Source
              </button>
              <button className="welcome-btn" onClick={() => setLibraryOpen(true)}>
                Browse Library
              </button>
            </div>
            {!identity && (
              <div className="welcome-hint">
                Tip: Create an identity first to own and edit your documents.
                Anonymous works are read-only after sign-in.
              </div>
            )}
          </div>
        ) : isSourceWork ? (
          <SourceTextViewer
            workId={workBeId}
            clientRef={clientRef}
            connected={connected}
            fontSize={docPrefs.fontSize}
            lineHeight={docPrefs.lineHeight}
            onSelectionChange={(s, e) => {
              if (s !== undefined && e !== undefined && s !== e) setSelectionRange({ start: s, end: e });
              else setSelectionRange(null);
            }}
          />
        ) : (
          <>
            <div className="doc-toolbar">
              <div className="doc-title">{currentWorkMeta?.title || `Work ${workIdDisplay}`}</div>
              <PermissionBadge
                canEdit={canEdit}
                isAnonymous={!identity}
                identityName={identityName}
                isPublished={isPublished}
                editOpen={editOpen}
                isGrabbed={currentWorkMeta?.is_grabbed ?? false}
                isOwner={!!identity && currentWorkMeta?.owner === identity.club_id}
                documentTitle={currentWorkMeta?.title || null}
              />
              <button
                type="button"
                className="publish-toggle"
                onClick={handleTogglePublish}
                title={isPublished ? "Click to make private (only you can read)" : "Click to publish (everyone can read)"}
              >
                {isPublished ? "Published" : "Private"}
              </button>
              {publishError && (
                <span style={{ fontSize: 10, color: "var(--red)", maxWidth: 200 }}>
                  {publishError}
                </span>
              )}
              {isPublished && (
                <button
                  type="button"
                  className="publish-toggle"
                  onClick={handleToggleEditAccess}
                  title={editOpen ? "Click to restrict editing to owner" : "Click to allow anyone to edit"}
                >
                  {editOpen ? "Edit: Open" : "Edit: Owner"}
                </button>
              )}
              <button
                type="button"
                className="publish-toggle"
                onClick={() => setShowProvenance((s) => !s)}
                title="Toggle provenance panel"
              >
                {showProvenance ? "Hide Prov" : "Show Prov"}
              </button>
              <div className="doc-meta">
                {awareness.length > 1 && (
                  <div className="collab-pill">
                    <div className="collab-pill-dot" />
                    {awareness.length - 1} other{awareness.length - 1 !== 1 ? "s" : ""} here
                  </div>
                )}
                <div>{wordCount.toLocaleString()} words</div>
              </div>
            </div>
            {!canEdit && identity && (
              <div className="readonly-banner">
                You can read this document but cannot edit it — it is owned by another user.
                {!isPublished && " It is also private."}
              </div>
            )}
            {transclusion.pendingLink && (
              <div className="link-action-bar">
                {!selectionRange ? (
                  <span className="link-action-text">
                    Linking from &ldquo;{transclusion.pendingLink.sourceWorkTitle}&rdquo; &mdash; select target text
                  </span>
                ) : (
                  <>
                    <span className="link-action-text">Link type:</span>
                    {DEFAULT_LINK_TYPES.map((t) => (
                      <button
                        key={t.type_id}
                        type="button"
                        className="link-type-btn"
                        style={{ border: `1px solid ${t.color}`, color: t.color }}
                        onClick={() => handleCreateLinkTarget(t.type_id)}
                      >
                        {t.name}
                      </button>
                    ))}
                  </>
                )}
                <button
                  type="button"
                  className="link-cancel-btn"
                  onClick={transclusion.clearPendingLink}
                >
                  cancel
                </button>
              </div>
            )}
            <div className="document-center">
              <CollaborativeEditor
                text={displayText}
                onTextChange={editable ? handleTextChange : undefined}
                onCursorChange={sendCursor}
                onSelectionChange={handleEditorSelectionChange}
                connected={connected}
                attributionSpans={attributionSpans}
                editable={editable}
                contentStartLine={currentWorkMeta?.content_start_line}
                contentEndLine={currentWorkMeta?.content_end_line}
                transclusionMarkers={transclusion.markers}
                pendingTransclusion={transclusion.pending}
                onPlaceTransclusion={handlePlaceTransclusion}
                selectionRange={selectionRange}
                onNavigateToWork={selectWork}
                onShowBacklinks={handleShowBacklinks}
                compoundSpanRanges={compound.spanRanges}
                remoteCursors={awareness}
                compoundSourceTitles={compound.sourceTitles}
                inlineResolvedText={hasInlineTransclusions ? compound.resolvedText : undefined}
                onUndoLastTransclusion={compound.undoLastInsert}
                recentChanges={crdt.recentChanges}
                showAttributionColors={editable}
                fontSize={docPrefs.fontSize}
                lineHeight={docPrefs.lineHeight}
                annotations={crdt.annotations}
                onCreateAnnotation={editable ? handleCreateAnnotation : undefined}
              />
            </div>
            {showProvenance && (
              <div className="provenance-split">
                <div className="provenance-split-header">
                  <span className="provenance-title">Provenance & Attribution</span>
                  <button
                    type="button"
                    className="provenance-close"
                    onClick={() => setShowProvenance(false)}
                  >
                    close
                  </button>
                </div>
                <div className="provenance-split-body">
                  <AttributionPanel
                    spans={attributionSpans}
                    logStatus={attributionLogStatus}
                    documentLength={displayText.length}
                    visible={showProvenance}
                  />
                </div>
              </div>
            )}
            {showAnnotations && workBeId !== null && (
              <div className="provenance-split">
                <div className="provenance-split-header">
                  <span className="provenance-title">Annotations</span>
                  <button
                    type="button"
                    className="provenance-close"
                    onClick={() => setShowAnnotations(false)}
                  >
                    close
                  </button>
                </div>
                <div className="provenance-split-body">
                  <AnnotationPanel
                    annotations={annotations}
                    onDelete={(id) => { deleteAnnotation(id); }}
                    onNavigate={(_cs) => {}}
                    currentClubId={identity?.club_id ?? null}
                  />
                </div>
              </div>
            )}
            {showCompound && workBeId !== null && !isSourceWork && (
              <div className="provenance-split">
                <div className="provenance-split-header">
                  <span className="provenance-title">Compound Structure</span>
                  <button
                    type="button"
                    className="provenance-close"
                    onClick={() => setShowCompound(false)}
                  >
                    close
                  </button>
                </div>
                <div className="provenance-split-body">
                  <CompoundPanel
                    client={clientRef.current}
                    workBeId={workBeId}
                    canEdit={editable}
                    sourceTitles={compound.sourceTitles}
                    spanRanges={compound.spanRanges}
                    onReload={() => compound.reload()}
                    onInsertElement={(_i, _el) => Promise.resolve(null)}
                    onRemoveElement={(_i) => Promise.resolve(null)}
                    onMoveElement={(_from, _to) => Promise.resolve(null)}
                    onRemoveTransclusion={compound.undoLastInsert}
                  />
                </div>
              </div>
            )}
          </>
        )}
      </div>

      <ContextPanel
        awareness={awareness}
        attributionSpans={attributionSpans}
        attributionLogStatus={attributionLogStatus}
        transclusionLinks={transclusion.links}
        backlinks={transclusion.backlinks}
        compoundSpanRanges={compound.spanRanges}
        compoundSourceTitles={compound.sourceTitles}
        currentWorkId={workBeId}
        documentLength={displayText.length}
        onNavigateToWork={selectWork}
        onOpenProvenance={() => setShowProvenance(true)}
        onExportReport={handleExportReport}
        onExportProvJson={handleExportProvJson}
        focusMode={focusMode}
        onToggleFocus={() => setFocusMode((f) => !f)}
        onDeleteLink={editable ? handleDeleteLink : undefined}
        onRetypeLink={editable ? handleRetypeLink : undefined}
        pinnedKeys={pinnedKeys}
        onTogglePin={handleTogglePin}
      />

      <BottomBar
        connected={connected}
        sessionCount={awareness.length}
        workId={workIdDisplay}
        version={null}
        wordCount={wordCount}
        chainValid={attributionLogStatus?.chain_valid ?? true}
        lastSavedSeconds={null}
      />

      <ConnectionOverlay connected={connected} reconnectAttempt={reconnectAttempt} />

      {libraryOpen && (
        <LibrarySlideOut
          works={works}
          currentWorkId={workBeId}
          onSelect={selectWork}
          onClose={() => setLibraryOpen(false)}
          onCreate={handleCreate}
          onImport={() => { setLibraryOpen(false); setShowImport(true); }}
          connected={connected}
          identity={identity}
        />
      )}

      {searchOpen && (
        <SearchOverlay
          onClose={() => setSearchOpen(false)}
          clientRef={clientRef}
          currentWorkId={workBeId}
          works={works}
          onSelectWork={(id) => { selectWork(id); setSearchOpen(false); }}
        />
      )}

      {showIdentity && (
        <div className="modal-overlay" onClick={() => setShowIdentity(false)}>
          <div className="modal-content identity-modal" onClick={(e) => e.stopPropagation()}>
            <IdentityPanel
              identity={identity}
              connected={connected}
              onLogin={login}
              onCreateIdentity={createIdentity}
              onLogout={logout}
              rosters={rosters}
            />
          </div>
        </div>
      )}

      {showImport && (
        <ImportWizard
          clientRef={clientRef}
          visible={true}
          onImported={() => { setShowImport(false); loadWorks(); }}
          onClose={() => setShowImport(false)}
        />
      )}

      {showSettings && (
        <DocumentSettings
          visible={true}
          prefs={docPrefs}
          onPrefsChange={setDocPrefs}
          onClose={() => setShowSettings(false)}
        />
      )}

      {showTrails && (
        <TrailsPanel
          client={clientRef.current}
          currentWorkId={workBeId}
          works={works}
          onSelectWork={selectWork}
          onClose={() => setShowTrails(false)}
        />
      )}

      <LinkCreator
        open={linkCreatorSource !== null}
        source={linkCreatorSource}
        works={works}
        currentWorkId={workBeId}
        clientRef={clientRef}
        onLinkCreated={handleLinkCreatorDone}
        onClose={() => setLinkCreatorSource(null)}
        onSelectTextInOtherDoc={handleCreateLinkSelection}
      />

      <AnnotationDialog
        open={annotationTarget !== null}
        charStart={annotationTarget?.start ?? 0}
        charEnd={annotationTarget?.end ?? 0}
        onCreate={handleAnnotationSubmit}
        onClose={() => setAnnotationTarget(null)}
      />
    </div>
  );
}
