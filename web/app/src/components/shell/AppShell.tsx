import { useState, useEffect, useCallback, useRef, useMemo } from "react";
import { useCrdtSync } from "../../hooks/useCrdtSync";
import { useTransclusion } from "../../hooks/useTransclusion";
import { useCompoundEdition } from "../../hooks/useCompoundEdition";
import { authorColorPair } from "../../author-color";
import { CollaborativeEditor } from "../CollaborativeEditor";
import { TransclusionBadge } from "../TransclusionBadge";
import { SourceTextViewer } from "../SourceTextViewer";
import { ConnectionOverlay } from "../ConnectionOverlay";
import { IdentityPanel } from "../IdentityPanel";
import { ImportWizard } from "../ImportWizard";
import { DocumentSettings, loadDocPreferences } from "../DocumentSettings";
import type { DocPreferences } from "../DocumentSettings";
import type { WorkListEntry } from "../../api/crdt_sync";
import { TopBar } from "./TopBar";
import { LeftRail } from "./LeftRail";
import { BottomBar } from "./BottomBar";
import { ContextPanel } from "./ContextPanel";
import { LibrarySlideOut } from "./LibrarySlideOut";
import { SearchOverlay } from "./SearchOverlay";
import "../../app-shell.css";

const WS_URL = `${window.location.protocol === "https:" ? "wss" : "ws"}://${window.location.host}/xudanu`;

export function AppShell() {
  const [workBeId, setWorkBeId] = useState<number | null>(null);
  const [writeMode, setWriteMode] = useState(false);
  const [focusMode, setFocusMode] = useState(false);
  const [activeRail, setActiveRail] = useState("document");
  const [libraryOpen, setLibraryOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [showImport, setShowImport] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showIdentity, setShowIdentity] = useState(false);
  const [works, setWorks] = useState<WorkListEntry[]>([]);
  const [selectionRange, setSelectionRange] = useState<{ start: number; end: number } | null>(null);
  const [docPrefs, setDocPrefs] = useState<DocPreferences>(loadDocPreferences());
  const lastTypingRef = useRef(0);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const wid = params.get("work");
    if (wid) {
      const parsed = wid.startsWith("0x") ? parseInt(wid, 16) : parseInt(wid, 10);
      if (!isNaN(parsed)) setWorkBeId(parsed);
    }
    if (params.get("auth") === "1") {
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
    } catch {}
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
  useEffect(() => {
    if (connected && workBeId !== null && clientRef.current && identity) {
      loadTransclusionLinks(clientRef.current, workBeId, works);
      loadBacklinks(clientRef.current, workBeId);
    }
  }, [connected, workBeId, works, identity, loadTransclusionLinks, loadBacklinks]);

  const selectWork = useCallback((id: number) => {
    setWorkBeId(id);
    const url = new URL(window.location.href);
    url.searchParams.set("work", String(id));
    window.history.replaceState({}, "", url.toString());
    setLibraryOpen(false);
  }, []);

  const handleCreate = useCallback(async () => {
    try {
      const newId = await createWork();
      if (newId !== null) {
        selectWork(newId);
        loadWorks();
      }
    } catch {}
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

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setSearchOpen((s) => !s);
      }
      if (e.key === "Escape") {
        setSearchOpen(false);
        setLibraryOpen(false);
      }
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  }, []);

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

  const identityName = identity?.display_name || null;
  const identityColor = identityName
    ? authorColorPair(identityName).primary
    : "#8a8a96";

  const editable = writeMode && canEdit;

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
      else if (item === "annotate") setActiveRail("annotate");
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
        {workBeId !== null && selectionRange && !transclusion.pending && (
          <button
            type="button"
            className="transclude-btn"
            onClick={handleTranscludeSelection}
            title="Hold this selection as a transclusion to insert elsewhere"
          >
            Transclude ({selectionRange.start}-{selectionRange.end})
          </button>
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
                onCreateAnnotation={undefined}
              />
            </div>
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
        onNavigateToWork={selectWork}
        focusMode={focusMode}
        onToggleFocus={() => setFocusMode((f) => !f)}
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
    </div>
  );
}
