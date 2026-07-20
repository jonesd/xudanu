import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useCrdtSync } from "../../hooks/useCrdtSync";
import { useTransclusion } from "../../hooks/useTransclusion";
import { useCompoundEdition } from "../../hooks/useCompoundEdition";
import { authorColorPair } from "../../author-color";
import { CollaborativeEditor } from "../CollaborativeEditor";
import { TransclusionBadge } from "../TransclusionBadge";
import { IdentityPanel } from "../IdentityPanel";
import { DocumentMapPanel } from "../DocumentMapPanel";
import { TrailsPanel } from "../TrailsPanel";
import { loadThemeState, saveThemeState, activePalette } from "../../theme";
import type { ThemeMode } from "../../theme";
import type { WorkListEntry, TrailPayload } from "../../api/crdt_sync";
import type { WorkKind } from "../../graph-scoring";
import { KIND_ICON, KIND_COLOR, KIND_ICON_COLOR } from "../../graph-scoring";
import { SEED_CONCEPTS } from "../../concepts-seed";
import { WorkspaceTopBar } from "./WorkspaceTopBar";
import type { WorkspaceNavTab } from "./WorkspaceTopBar";
import "../../workspace.css";

const WS_URL = `${window.location.protocol === "https:" ? "wss" : "ws"}://${window.location.host}/xudanu`;

type LeftRailMode = "graph" | "outline";
type RightPanelTab = "provenance" | "reuse" | "connections" | "trails" | "more";

interface WorkMeta {
  title: string;
  author: string | null;
  collection: string | null;
  publishedAt: string | null;
  versionLabel: string | null;
}

export function WorkspaceShell() {
  const [workBeId, setWorkBeId] = useState<number | null>(() => {
    const wid = new URLSearchParams(window.location.search).get("work");
    if (wid) {
      const parsed = wid.startsWith("0x") ? parseInt(wid, 16) : parseInt(wid, 10);
      if (!isNaN(parsed)) return parsed;
    }
    return null;
  });
  const [navTab, setNavTab] = useState<WorkspaceNavTab>("explore");
  const [leftRailMode, setLeftRailMode] = useState<LeftRailMode>("graph");
  const [leftRailHidden, setLeftRailHidden] = useState(false);
  const [rightPanelTab, setRightPanelTab] = useState<RightPanelTab>("provenance");
  const [rightPanelHidden, setRightPanelHidden] = useState(false);
  const [showIdentity, setShowIdentity] = useState(false);
  const [showAdmin, setShowAdmin] = useState(false);
  const [workMeta, setWorkMeta] = useState<WorkMeta | null>(null);
  const [selectionRange, setSelectionRange] = useState<{ start: number; end: number } | null>(null);
  const [annotationTarget, setAnnotationTarget] = useState<{ start: number; end: number } | null>(null);
  const [themeState, setThemeState] = useState(() => loadThemeState());
  const [themePickerOpen, setThemePickerOpen] = useState(false);
  const [citeFeedback, setCiteFeedback] = useState<string | null>(null);
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [followState, setFollowState] = useState<{ following: boolean; busy: boolean; error: string | null }>({
    following: false,
    busy: false,
    error: null,
  });
  const [works, setWorks] = useState<WorkListEntry[]>([]);
  const [worksLoading, setWorksLoading] = useState(false);
  const [worksError, setWorksError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [invalidWorkId, setInvalidWorkId] = useState<number | null>(null);
  const [showInvite, setShowInvite] = useState(false);
  const [editClubMembers, setEditClubMembers] = useState<{ members: [number, string][]; total: number; truncated: boolean } | null>(null);
  const [inviteLoading, setInviteLoading] = useState(false);
  const [inviteError, setInviteError] = useState<string | null>(null);
  const [showTrailsPanel, setShowTrailsPanel] = useState(false);
  const [trailsForWork, setTrailsForWork] = useState<TrailPayload[]>([]);
  const [trailsLoading, setTrailsLoading] = useState(false);
  const [addToSelector, setAddToSelector] = useState<{ trailId: number; trailName: string } | null>(null);
  const [userTrails, setUserTrails] = useState<TrailPayload[]>([]);
  const [workKind, setWorkKind] = useState<WorkKind>("document");
  const [kindPickerOpen, setKindPickerOpen] = useState(false);
  const [kindCache, setKindCache] = useState<Map<number, WorkKind>>(new Map());
  const [pickerKindFor, setPickerKindFor] = useState<number | null>(null);
  const [concepts, setConcepts] = useState<Array<{ work_id: number; title: string; link_count: number }>>([]);
  const [conceptNameOverride, setConceptNameOverride] = useState<Map<number, string>>(new Map());
  const [seedingConcepts, setSeedingConcepts] = useState(false);
  const [seedProgress, setSeedProgress] = useState(0);
  const [serverDomain, setServerDomain] = useState<string>("localhost");

  const crdt = useCrdtSync(WS_URL, workBeId);
  const {
    text,
    connected,
    identity,
    isAdmin,
    setText,
    sendCursor,
    sendSelection,
    canEdit,
    attributionSpans,
    createWork,
    fetchWorkList,
    clientRef,
    annotations,
    createAnnotation,
    awareness,
    login,
    createIdentity,
    logout,
  } = crdt;

  const transclusion = useTransclusion();
  const compound = useCompoundEdition(connected ? clientRef.current : null, workBeId);

  const identityName = identity?.display_name || null;
  const identityColor = identityName ? authorColorPair(identityName).primary : "#888";

  const selectWork = useCallback((id: number) => {
    setWorkBeId(id);
    if (navTab === "library") setNavTab("explore");
    const url = new URL(window.location.href);
    url.searchParams.set("work", `0x${id.toString(16)}`);
    window.history.replaceState({}, "", url.toString());
  }, [navTab]);

  // Single effect: fetch works list when connected; set work metadata if available
  useEffect(() => {
    if (!connected || !fetchWorkList) {
      setWorkMeta(null);
      return;
    }
    let cancelled = false;
    fetchWorkList()
      .then((entries: WorkListEntry[]) => {
        if (cancelled) return;
        setWorks(entries);
        setWorksError(null);
        if (workBeId === null) {
          setWorkMeta(null);
          return;
        }
        const match = entries.find((e) => e.work_id === workBeId);
        if (match) {
          setWorkMeta({
            title: match.title || `Work 0x${workBeId.toString(16)}`,
            author: identityName,
            collection: null,
            publishedAt: match.updated_at ? new Date(match.updated_at * 1000).toLocaleDateString() : null,
            versionLabel: match.revision_count ? `v${match.revision_count}` : null,
          });
          setFollowState((prev) => ({ ...prev, following: !!match.is_starred }));
        } else {
          // Work not in the list — still try to open it (it may be readable)
          setWorkMeta({
            title: `Work 0x${workBeId.toString(16)}`,
            author: identityName,
            collection: null,
            publishedAt: null,
            versionLabel: null,
          });
        }
      })
      .catch((e) => {
        if (!cancelled) {
          setWorksError(e instanceof Error ? e.message : String(e));
        }
      })
      .finally(() => {
        if (!cancelled) setWorksLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [connected, workBeId, fetchWorkList, identityName]);

  const handleCreateWork = useCallback(async () => {
    if (!createWork) return;
    const newId = await createWork();
    if (typeof newId === "number") selectWork(newId);
  }, [createWork, selectWork]);

  const handleTranscludeSelection = useCallback(() => {
    if (!selectionRange || workBeId === null) return;
    const title = workMeta?.title || `Work 0x${workBeId.toString(16)}`;
    const selectedText = text.slice(selectionRange.start, selectionRange.end);
    transclusion.holdSelection(workBeId, title, selectionRange.start, selectionRange.end, selectedText);
  }, [selectionRange, workBeId, workMeta, text, transclusion]);

  const handleOpenLinkCreator = useCallback(() => {
    if (!selectionRange || workBeId === null) return;
    const title = workMeta?.title || `Work 0x${workBeId.toString(16)}`;
    const selectedText = text.slice(selectionRange.start, selectionRange.end);
    transclusion.holdLinkSelection(workBeId, title, selectionRange.start, selectionRange.end, selectedText);
  }, [selectionRange, workBeId, workMeta, text, transclusion]);

  const handleCreateAnnotation = useCallback(() => {
    if (!selectionRange) return;
    setAnnotationTarget({ start: selectionRange.start, end: selectionRange.end });
  }, [selectionRange]);

  const handleAnnotationSubmit = useCallback(async (annoText: string, isPrivate: boolean) => {
    if (!annotationTarget || !createAnnotation) return;
    await createAnnotation("note", annoText, annotationTarget.start, annotationTarget.end, isPrivate);
    setAnnotationTarget(null);
  }, [annotationTarget, createAnnotation]);

  const handlePlaceTransclusion = useCallback(
    async (position: number, padding?: string) => {
      void padding;
      if (workBeId === null) return;
      const pending = transclusion.pending;
      if (!pending) return;
      const rawExcerpt = pending.text;
      let spanStart = position;
      if (padding && padding.length > 0) {
        const newText = text + padding;
        setText(newText);
        spanStart = newText.length;
      }
      for (const sr of compound.spanRanges) {
        if (sr.flat_end <= spanStart) {
          spanStart -= (sr.flat_end - sr.flat_start);
        }
      }
      await compound.addSpan(
        text,
        spanStart,
        rawExcerpt,
        pending.sourceWorkId,
        pending.start,
        pending.end,
      );
      transclusion.clearPending();
    },
    [workBeId, text, setText, compound, transclusion]
  );

  const handleFollow = useCallback(async () => {
    if (workBeId === null || !clientRef.current) return;
    const wasFollowing = followState.following;
    setFollowState({ following: wasFollowing, busy: true, error: null });
    try {
      if (wasFollowing) {
        await clientRef.current.workUnstar(workBeId);
        setFollowState({ following: false, busy: false, error: null });
      } else {
        await clientRef.current.workStar(workBeId);
        setFollowState({ following: true, busy: false, error: null });
      }
    } catch (e) {
      setFollowState({
        following: wasFollowing,
        busy: false,
        error: e instanceof Error ? e.message : String(e),
      });
    }
  }, [workBeId, clientRef, followState.following]);

  const handleCite = useCallback(() => {
    if (workBeId === null) return;
    const ref = `xan://${serverDomain}.0x${workBeId.toString(16)}`;
    try {
      navigator.clipboard.writeText(ref);
      setCiteFeedback("Copied!");
      setTimeout(() => setCiteFeedback(null), 1800);
    } catch {
      setCiteFeedback(ref);
      setTimeout(() => setCiteFeedback(null), 5000);
    }
  }, [workBeId]);

  const handleOpenInvite = useCallback(async () => {
    if (workBeId === null || !clientRef.current) return;
    setShowInvite(true);
    setInviteLoading(true);
    setInviteError(null);
    try {
      const clubId = await clientRef.current.getEditClub(workBeId);
      if (clubId === 0) {
        setEditClubMembers({ members: [], total: 0, truncated: false });
      } else {
        const roster = await clientRef.current.clubRoster(clubId);
        setEditClubMembers(roster);
      }
    } catch (e) {
      setInviteError(e instanceof Error ? e.message : String(e));
    } finally {
      setInviteLoading(false);
    }
  }, [workBeId, clientRef]);

  // Load all of the user's trails (for the "add to trail" picker)
  const loadUserTrails = useCallback(async () => {
    if (!clientRef.current) return;
    try {
      const list = await clientRef.current.trailList();
      setUserTrails(list);
    } catch (e) {
      console.warn("trail_list failed", e);
    }
  }, [clientRef]);

  // Load trails that have at least one stop on the current work
  const loadTrailsForWork = useCallback(async () => {
    if (!clientRef.current || workBeId === null) {
      setTrailsForWork([]);
      return;
    }
    setTrailsLoading(true);
    try {
      const all = await clientRef.current.trailList();
      const filtered = all.filter((t) => t.stops.some((s) => s.work_id === workBeId));
      setTrailsForWork(filtered);
    } catch (e) {
      console.warn("trail_list failed", e);
      setTrailsForWork([]);
    } finally {
      setTrailsLoading(false);
    }
  }, [clientRef, workBeId]);

  useEffect(() => {
    if (connected && rightPanelTab === "trails") {
      void loadTrailsForWork();
    }
  }, [connected, rightPanelTab, loadTrailsForWork]);

  // Fetch work kind when work changes
  useEffect(() => {
    if (!connected || workBeId === null || !clientRef.current) {
      setWorkKind("document");
      return;
    }
    let cancelled = false;
    clientRef.current
      .workKindGet(workBeId)
      .then((k) => { if (!cancelled) setWorkKind(k); })
      .catch(() => { if (!cancelled) setWorkKind("document"); });
    return () => { cancelled = true; };
  }, [connected, workBeId, clientRef]);

  // Fetch server's public address for persistent IDs
  useEffect(() => {
    fetch("/.well-known/xudanu-server.json")
      .then((r) => r.json())
      .then((data) => {
        if (data.public_address) {
          setServerDomain(data.public_address);
        }
      })
      .catch(() => {});
  }, []);

  // Populate kind cache from graph data (so work picker can show kinds without N fetches)
  useEffect(() => {
    if (!connected || !clientRef.current) return;
    let cancelled = false;
    clientRef.current
      .workGraph()
      .then((g) => {
        if (cancelled) return;
        const cache = new Map<number, WorkKind>();
        for (const node of g.nodes) {
          if (node.kind) cache.set(node.work_id, node.kind);
        }
        setKindCache(cache);
        // Compute inbound link count per concept
        const linkCounts = new Map<number, number>();
        for (const edge of g.edges) {
          linkCounts.set(edge.target, (linkCounts.get(edge.target) || 0) + 1);
        }
        const conceptList = g.nodes
          .filter((n) => n.kind === "concept")
          .map((n) => {
            const override = conceptNameOverride.get(n.work_id);
            const backendTitle = n.title || "";
            const isGenericTitle = !backendTitle || backendTitle.startsWith("Concept ") || backendTitle.startsWith("Work ");
            const title = override && isGenericTitle ? override : (backendTitle || `Concept ${n.work_id}`);
            return {
              work_id: n.work_id,
              title,
              link_count: linkCounts.get(n.work_id) || 0,
            };
          })
          .sort((a, b) => b.link_count - a.link_count);
        setConcepts(conceptList);
      })
      .catch(() => {});
    return () => { cancelled = true; };
  }, [connected, clientRef]);

  const handleAddConcept = useCallback(async () => {
    const name = prompt("New concept name:", "");
    if (!name || !clientRef.current) return;
    try {
      const newId = await createWork();
      if (typeof newId !== "number") return;
      await clientRef.current.workKindSet(newId, "concept");
      setKindCache((c) => new Map(c).set(newId, "concept"));
      setConceptNameOverride((prev) => new Map(prev).set(newId, name));
      setConcepts((prev) => [...prev, { work_id: newId, title: name, link_count: 0 }]);
      selectWork(newId);
    } catch (e) {
      alert(`Could not create concept: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [createWork, clientRef, selectWork]);

  const handleSeedDefaults = useCallback(async () => {
    if (!clientRef.current || seedingConcepts) return;
    const existingNames = new Set(concepts.map((c) => c.title.toLowerCase()));
    const toCreate = SEED_CONCEPTS.filter((c) => !existingNames.has(c.name.toLowerCase()));
    if (toCreate.length === 0) {
      alert("All default concepts already exist.");
      return;
    }
    const ok = confirm(`Create ${toCreate.length} concept works?\n\nEach will be empty (you can fill in descriptions later). Concepts are filterable in the graph and linkable from any work.`);
    if (!ok) return;
    setSeedingConcepts(true);
    setSeedProgress(0);
    try {
      const newConcepts: Array<{ work_id: number; title: string; link_count: number }> = [];
      for (let i = 0; i < toCreate.length; i++) {
        const concept = toCreate[i];
        const newId = await createWork();
        if (typeof newId !== "number") continue;
        await clientRef.current!.workKindSet(newId, "concept");
        // Write the concept name + description as text so the title is correct
        await clientRef.current!.workSetText(newId, `${concept.name}\n\n${concept.description}`);
        setKindCache((c) => new Map(c).set(newId, "concept"));
        setConceptNameOverride((prev) => new Map(prev).set(newId, concept.name));
        newConcepts.push({ work_id: newId, title: concept.name, link_count: 0 });
        setSeedProgress(i + 1);
        await new Promise((r) => setTimeout(r, 100));
      }
      setConcepts((prev) => [...prev, ...newConcepts].sort((a, b) => b.link_count - a.link_count));
    } catch (e) {
      alert(`Seeding failed: ${e instanceof Error ? e.message : String(e)}`);
    } finally {
      setSeedingConcepts(false);
      setSeedProgress(0);
    }
  }, [clientRef, createWork, concepts, seedingConcepts]);

  const handleKindChange = useCallback(async (kind: WorkKind) => {
    if (workBeId === null || !clientRef.current) return;
    const prev = workKind;
    setWorkKind(kind);
    setKindPickerOpen(false);
    setKindCache((prev) => new Map(prev).set(workBeId, kind));
    try {
      await clientRef.current.workKindSet(workBeId, kind);
    } catch (e) {
      setWorkKind(prev);
      alert(`Could not change kind: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [workBeId, clientRef, workKind]);

  const handlePickerKindChange = useCallback(async (workId: number, kind: WorkKind) => {
    if (!clientRef.current) return;
    const prev = kindCache.get(workId) || "document";
    setKindCache((c) => new Map(c).set(workId, kind));
    setPickerKindFor(null);
    try {
      await clientRef.current.workKindSet(workId, kind);
    } catch (e) {
      setKindCache((c) => new Map(c).set(workId, prev));
      alert(`Could not change kind: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [clientRef, kindCache]);

  const handleAddSelectionToTrail = useCallback(async (trailId: number) => {
    if (!selectionRange || workBeId === null || !clientRef.current) return;
    const selectedText = text.slice(selectionRange.start, selectionRange.end);
    try {
      await clientRef.current.trailAddStop(
        trailId,
        workBeId,
        selectionRange.start,
        selectionRange.end,
        selectedText.length > 80 ? selectedText.slice(0, 80) + "…" : selectedText
      );
      setAddToSelector(null);
      setSelectionRange(null);
      // Refresh trails for work if visible
      if (rightPanelTab === "trails") await loadTrailsForWork();
    } catch (e) {
      alert(`Could not add to trail: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [selectionRange, workBeId, clientRef, text, rightPanelTab, loadTrailsForWork]);

  const handleCreateTrailFromSelection = useCallback(async () => {
    if (!selectionRange || workBeId === null || !clientRef.current) return;
    const name = prompt("New trail name:", `Trail for ${workMeta?.title || "current work"}`);
    if (!name) return;
    try {
      const trailId = await clientRef.current.trailCreate(name);
      const selectedText = text.slice(selectionRange.start, selectionRange.end);
      await clientRef.current.trailAddStop(
        trailId,
        workBeId,
        selectionRange.start,
        selectionRange.end,
        selectedText.length > 80 ? selectedText.slice(0, 80) + "…" : selectedText
      );
      setAddToSelector(null);
      setSelectionRange(null);
      if (rightPanelTab === "trails") await loadTrailsForWork();
    } catch (e) {
      alert(`Could not create trail: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [selectionRange, workBeId, clientRef, text, workMeta, rightPanelTab, loadTrailsForWork]);

  const authorStats = useMemo(() => {
    type Entry = { name: string; chars: number; pct: number };
    const byName = new Map<string, number>();
    let total = 0;
    for (const span of attributionSpans) {
      const name = span.author_display_name || "Anonymous";
      const len = span.end - span.start;
      byName.set(name, (byName.get(name) || 0) + len);
      total += len;
    }
    if (total === 0) return [] as Entry[];
    const entries: Entry[] = Array.from(byName.entries())
      .map(([name, chars]) => ({ name, chars, pct: (chars / total) * 100 }))
      .sort((a, b) => b.chars - a.chars);
    return entries;
  }, [attributionSpans]);

  const filteredWorks = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    const sorted = [...works].sort((a, b) => {
      if (a.is_starred !== b.is_starred) return a.is_starred ? -1 : 1;
      const at = a.updated_at || 0;
      const bt = b.updated_at || 0;
      return bt - at;
    });
    if (!q) return sorted;
    return sorted.filter((w) => (w.title || "").toLowerCase().includes(q));
  }, [works, searchQuery]);

  const activeCssClass = activePalette(themeState).cssClass;
  const workIdDisplay = workBeId !== null ? `0x${workBeId.toString(16)}` : "";

  const moreMenuRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!moreMenuOpen) return;
    function onDocClick(e: MouseEvent) {
      if (moreMenuRef.current && !moreMenuRef.current.contains(e.target as Node)) {
        setMoreMenuOpen(false);
      }
    }
    document.addEventListener("mousedown", onDocClick);
    return () => document.removeEventListener("mousedown", onDocClick);
  }, [moreMenuOpen]);

  const breadcrumb = useMemo(() => {
    if (!workMeta) return null;
    return ["Library", workMeta.collection || "Drafts", workMeta.title].filter(Boolean);
  }, [workMeta]);

  return (
    <div className={`ws-shell ${activeCssClass} ${navTab === "compose" ? "ws-mode-compose" : ""}`}>
      <WorkspaceTopBar
        connected={connected}
        identityName={identityName}
        identityColor={identityColor}
        activeNav={navTab}
        onNavChange={setNavTab}
        onOpenSearch={() => {
          /* TODO Phase 1: command palette */
        }}
        onOpenIdentity={() => setShowIdentity(true)}
        onOpenAdmin={() => setShowAdmin(true)}
        isAdmin={isAdmin}
        onCreateWork={handleCreateWork}
        themeMode={themeState.mode}
        themePickerOpen={themePickerOpen}
        onToggleThemePicker={() => setThemePickerOpen((o) => !o)}
        onSelectPalette={(paletteId, mode) => {
          setThemeState((prev) => {
            const next =
              mode === "light"
                ? { ...prev, mode: "light" as ThemeMode, lightPaletteId: paletteId }
                : { ...prev, mode: "dark" as ThemeMode, darkPaletteId: paletteId };
            saveThemeState(next);
            return next;
          });
          setThemePickerOpen(false);
        }}
        onQuickToggleMode={() => {
          setThemeState((prev) => {
            const nextMode: ThemeMode = prev.mode === "light" ? "dark" : "light";
            const next = { ...prev, mode: nextMode };
            saveThemeState(next);
            return next;
          });
        }}
        activeLightPaletteId={themeState.lightPaletteId}
        activeDarkPaletteId={themeState.darkPaletteId}
      />

      <div className="ws-body">
        {/* Left rail */}
        <aside className={`ws-left-rail ${leftRailHidden ? "hidden" : ""}`}>
          <div className="ws-rail-toggle">
            <button
              className={leftRailMode === "graph" ? "active" : ""}
              onClick={() => setLeftRailMode("graph")}
              title="Graph view"
            >
              Graph
            </button>
            <button
              className={leftRailMode === "outline" ? "active" : ""}
              onClick={() => setLeftRailMode("outline")}
              title="Outline view"
            >
              Outline
            </button>
          </div>
          <div className="ws-rail-content">
            {leftRailMode === "graph" ? (
              <DocumentMapPanel
                client={connected ? clientRef.current : null}
                onSelectWork={selectWork}
                currentWorkId={workBeId}
                onClose={() => setLeftRailHidden(true)}
                embedded
              />
            ) : (
              <div className="ws-placeholder">
                <div className="ws-placeholder-label">Document outline</div>
                <div className="ws-placeholder-sublabel">Coming soon</div>
              </div>
            )}

            {/* Related Concepts panel — below the graph */}
            <div className="ws-concepts-panel">
              <div className="ws-concepts-header">
                <span className="ws-concepts-title">Related Concepts</span>
                <div className="ws-concepts-actions">
                  <button
                    className="ws-concept-add-btn"
                    onClick={handleAddConcept}
                    title="Add a new concept"
                  >+</button>
                  <button
                    className="ws-concept-add-btn"
                    onClick={handleSeedDefaults}
                    disabled={seedingConcepts}
                    title="Seed default concept list (hypertext/PKM/writing)"
                  >
                    {seedingConcepts ? `… ${seedProgress}/${SEED_CONCEPTS.length}` : "⇣"}
                  </button>
                </div>
              </div>
              {concepts.length === 0 ? (
                <div className="ws-concepts-empty">
                  No concepts yet.
                  <br />
                  Click <strong>⇣</strong> to seed defaults
                  <br />
                  or <strong>+</strong> to add your own.
                </div>
              ) : (
                <ul className="ws-concepts-list">
                  {concepts.map((c) => (
                    <li
                      key={c.work_id}
                      className="ws-concept-item"
                      onClick={() => selectWork(c.work_id)}
                      title={c.link_count > 0 ? `${c.link_count} linked work${c.link_count === 1 ? "" : "s"}` : "No linked works yet"}
                    >
                      <span className="ws-concept-name">{c.title}</span>
                      {c.link_count > 0 && (
                        <span className="ws-concept-count">{c.link_count}</span>
                      )}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>
          <button
            className="ws-rail-collapse"
            onClick={() => setLeftRailHidden(true)}
            title="Hide panel"
          >
            ‹
          </button>
        </aside>

        {/* Document surface */}
        <main className={`ws-doc-surface ${canEdit ? "editable" : "readonly"}`}>
          {invalidWorkId !== null ? (
            <div className="ws-empty-doc">
              <h2>Work 0x{invalidWorkId.toString(16)} not found</h2>
              <p>This work ID doesn't exist on this server.</p>
              <button
                className="ws-empty-create"
                onClick={() => {
                  setInvalidWorkId(null);
                  setWorkBeId(null);
                  const url = new URL(window.location.href);
                  url.searchParams.delete("work");
                  window.history.replaceState({}, "", url.toString());
                }}
              >
                Browse works
              </button>
            </div>
          ) : workBeId === null || navTab === "library" ? (
            <div className="ws-work-picker">
              <div className="ws-picker-header">
                <h2>{navTab === "library" ? "Library" : "Xudanu workspace"}</h2>
                <p>{navTab === "library" ? "Browse and open your works." : "Pick a work to read or edit, or create a new one."}</p>
                <div className="ws-picker-actions">
                  <input
                    type="search"
                    placeholder="Search works…"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="ws-picker-search"
                  />
                  <button className="ws-empty-create" onClick={handleCreateWork}>+ New work</button>
                </div>
              </div>
              {worksError && <div className="ws-picker-error">Failed to load: {worksError}</div>}
              {worksLoading ? (
                <div className="ws-placeholder"><div className="ws-placeholder-label">Loading works…</div></div>
              ) : filteredWorks.length === 0 ? (
                <div className="ws-placeholder">
                  <div className="ws-placeholder-label">{works.length === 0 ? "No works yet" : "No matches"}</div>
                  <div className="ws-placeholder-sublabel">{works.length === 0 ? "Create your first work" : "Try a different search"}</div>
                </div>
              ) : (
                <ul className="ws-work-list">
                  {filteredWorks.map((w) => {
                    const kind = kindCache.get(w.work_id) || "document";
                    return (
                      <li
                        key={w.work_id}
                        className={`ws-work-item ${w.work_id === workBeId ? "active" : ""}`}
                        onClick={() => selectWork(w.work_id)}
                      >
                        <div className="ws-work-title">
                          <span
                            className="ws-work-kind-badge"
                            onClick={(e) => {
                              e.stopPropagation();
                              setPickerKindFor(pickerKindFor === w.work_id ? null : w.work_id);
                            }}
                            style={{ background: KIND_COLOR[kind] }}
                            title={`Kind: ${kind} — click to change`}
                          >
                            <span style={{ color: KIND_ICON_COLOR[kind] }}>{KIND_ICON[kind]}</span>
                          </span>
                          {w.is_starred && <span className="ws-star">★</span>}
                          {w.title || `Work 0x${w.work_id.toString(16)}`}
                        </div>
                        <div className="ws-work-meta">
                          <code>0x{w.work_id.toString(16)}</code>
                          {w.updated_at && <span>· updated {new Date(w.updated_at * 1000).toLocaleDateString()}</span>}
                          {w.revision_count > 0 && <span>· v{w.revision_count}</span>}
                          <span>· {kind}</span>
                        </div>
                        {pickerKindFor === w.work_id && (
                          <div className="ws-picker-kind-menu" onClick={(e) => e.stopPropagation()}>
                            {(["document", "note", "person", "concept", "collection", "commentary"] as const).map((k) => (
                              <button
                                key={k}
                                className={`ws-kind-item ${kind === k ? "active" : ""}`}
                                onClick={(e) => {
                                  e.stopPropagation();
                                  void handlePickerKindChange(w.work_id, k);
                                }}
                              >
                                <span style={{ color: KIND_COLOR[kind] }}>{KIND_ICON[kind]}</span>
                                <span style={{ color: KIND_COLOR[k] }}>{KIND_ICON[k]}</span>
                                <span>{k.charAt(0).toUpperCase() + k.slice(1)}</span>
                                {kind === k && <span className="ws-kind-check">✓</span>}
                              </button>
                            ))}
                          </div>
                        )}
                      </li>
                    );
                  })}
                </ul>
              )}
            </div>
          ) : (
            <>
              <header className="ws-doc-header">
                <div className="ws-doc-title-row">
                  <div className="ws-kind-picker-wrap">
                    <button
                      className="ws-kind-button"
                      title={`Kind: ${workKind} — click to change`}
                      onClick={() => setKindPickerOpen((o) => !o)}
                      style={{ color: KIND_COLOR[workKind] }}
                    >
                      <span className="ws-kind-icon">{KIND_ICON[workKind]}</span>
                    </button>
                    {kindPickerOpen && (
                      <div className="ws-kind-menu" role="menu">
                        {(["document", "note", "person", "concept", "collection", "commentary"] as const).map((k) => (
                          <button
                            key={k}
                            className={`ws-kind-item ${workKind === k ? "active" : ""}`}
                            onClick={() => handleKindChange(k)}
                            title={k.charAt(0).toUpperCase() + k.slice(1)}
                          >
                            <span style={{ color: KIND_COLOR[k] }}>{KIND_ICON[k]}</span>
                            <span>{k.charAt(0).toUpperCase() + k.slice(1)}</span>
                            {workKind === k && <span className="ws-kind-check">✓</span>}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                  {breadcrumb && (
                    <nav className="ws-breadcrumb">
                    {breadcrumb.map((seg, i) => (
                      <span key={i} className="ws-breadcrumb-seg">
                        {i > 0 && <span className="ws-breadcrumb-sep">/</span>}
                        {seg}
                      </span>
                    ))}
                  </nav>
                  )}
                </div>
                <div className="ws-doc-actions">
                  <button
                    className={`ws-action-btn ${followState.following ? "active" : ""}`}
                    title={followState.following ? "Unstar this work" : "Star this work (adds to your library)"}
                    onClick={handleFollow}
                    disabled={followState.busy}
                  >
                    {followState.busy ? "…" : followState.following ? "★ Following" : "☆ Follow"}
                  </button>
                  <button
                    className="ws-action-btn"
                    title="Copy persistent xan:// reference"
                    onClick={handleCite}
                  >
                    {citeFeedback ? `✓ ${citeFeedback}` : "Cite…"}
                  </button>
                  <button
                    className="ws-action-btn"
                    title="Invite collaborators"
                    onClick={handleOpenInvite}
                  >
                    Invite
                  </button>
                  <button
                    className="ws-action-btn"
                    title="Curated trails through this work and others"
                    onClick={() => setShowTrailsPanel(true)}
                  >
                    Trails
                  </button>
                  <div className="ws-more-wrap" ref={moreMenuRef}>
                    <button
                      className="ws-action-btn"
                      title="More actions"
                      onClick={() => setMoreMenuOpen((o) => !o)}
                    >
                      ⋯
                    </button>
                    {moreMenuOpen && (
                      <div className="ws-more-menu" role="menu">
                        <button
                          className="ws-more-item"
                          onClick={() => {
                            const textblob = new Blob([text], { type: "text/plain" });
                            const url = URL.createObjectURL(textblob);
                            const a = document.createElement("a");
                            a.href = url;
                            a.download = `${workMeta?.title || "work"}.txt`;
                            a.click();
                            setTimeout(() => URL.revokeObjectURL(url), 1000);
                            setMoreMenuOpen(false);
                          }}
                        >
                          Export as .txt
                        </button>
                        <button
                          className="ws-more-item"
                          onClick={() => {
                            try {
                              navigator.share?.({ title: workMeta?.title || "Xudanu work", text }).catch(() => {});
                            } catch {}
                            setMoreMenuOpen(false);
                          }}
                        >
                          Share…
                        </button>
                        <button
                          className="ws-more-item"
                          onClick={() => {
                            window.open(`/?work=0x${(workBeId ?? 0).toString(16)}`, "_blank");
                            setMoreMenuOpen(false);
                          }}
                        >
                          Open in classic editor
                        </button>
                      </div>
                    )}
                  </div>
                </div>
                <div className="ws-doc-meta">
                  {workMeta?.author && <span>{workMeta.author}</span>}
                  {workMeta?.collection && <span>· {workMeta.collection}</span>}
                  {workMeta?.publishedAt && <span>· {workMeta.publishedAt}</span>}
                  <span>· {workIdDisplay}</span>
                  <span className="ws-doc-pid">
                    xan://{serverDomain}.{workIdDisplay}
                  </span>
                </div>
              </header>

              <div className="ws-doc-scroll">
                {selectionRange && !transclusion.pending && !transclusion.pendingLink && (
                  <div className="ws-selection-actions">
                    <button
                      type="button"
                      className="ws-sel-btn transclude"
                      onClick={handleTranscludeSelection}
                      title="Hold this selection as a transclusion to insert elsewhere"
                    >
                      Transclude
                    </button>
                    <button
                      type="button"
                      className="ws-sel-btn link"
                      onClick={handleOpenLinkCreator}
                      title="Create a typed link from this selection"
                    >
                      Link
                    </button>
                    {canEdit && (
                      <button
                        type="button"
                        className="ws-sel-btn note"
                        onClick={handleCreateAnnotation}
                        title="Add a note or comment to this passage"
                      >
                        ✎ Note
                      </button>
                    )}
                    <button
                      type="button"
                      className="ws-sel-btn trail"
                      onClick={async () => {
                        await loadUserTrails();
                        setAddToSelector({ trailId: 0, trailName: "" });
                      }}
                      title="Add this passage to a curated trail"
                    >
                      + Trail
                    </button>
                  </div>
                )}
                {addToSelector && selectionRange && (
                  <div className="ws-trail-picker">
                    <div className="ws-trail-picker-header">
                      <span>Add to trail</span>
                      <button
                        className="ws-trail-picker-close"
                        onClick={() => setAddToSelector(null)}
                        title="Close"
                      >×</button>
                    </div>
                    <div className="ws-trail-picker-list">
                      {userTrails.length === 0 ? (
                        <div className="ws-placeholder-sublabel">No trails yet — create one below.</div>
                      ) : (
                        userTrails.map((t) => (
                          <button
                            key={t.trail_id}
                            className="ws-trail-picker-item"
                            onClick={() => handleAddSelectionToTrail(t.trail_id)}
                          >
                            <span className="ws-trail-picker-name">{t.name}</span>
                            <span className="ws-trail-picker-count">{t.stops.length} stops</span>
                          </button>
                        ))
                      )}
                    </div>
                    <button
                      className="ws-trail-picker-new"
                      onClick={handleCreateTrailFromSelection}
                    >
                      + New trail from this passage
                    </button>
                  </div>
                )}
                {transclusion.pending && (
                  <TransclusionBadge
                    pending={transclusion.pending}
                    cursorPosition={selectionRange?.start ?? null}
                    onPlace={handlePlaceTransclusion}
                    onCancel={transclusion.clearPending}
                  />
                )}
                <CollaborativeEditor
                  text={text}
                  workId={workBeId ?? undefined}
                  onTextChange={canEdit ? setText : undefined}
                  onCursorChange={sendCursor}
                  onSelectionChange={(s, e) => {
                    sendSelection(s, e);
                    if (s !== null && e !== null && s !== e) setSelectionRange({ start: s, end: e });
                    else setSelectionRange(null);
                  }}
                  connected={connected}
                  attributionSpans={attributionSpans}
                  editable={canEdit}
                  fontSize={14}
                  lineHeight={1.6}
                  transclusionMarkers={transclusion.markers}
                  pendingTransclusion={transclusion.pending}
                  onPlaceTransclusion={handlePlaceTransclusion}
                  selectionRange={selectionRange}
                  onNavigateToWork={selectWork}
                  compoundSpanRanges={compound.spanRanges}
                  remoteCursors={awareness}
                  compoundSourceTitles={compound.sourceTitles}
                  inlineResolvedText={compound.resolvedText || undefined}
                  annotations={annotations}
                  onCreateAnnotation={canEdit ? handleCreateAnnotation : undefined}
                />
              </div>

              {annotationTarget && (
                <div className="ws-modal-overlay" onClick={() => setAnnotationTarget(null)}>
                  <div className="ws-modal ws-anno-modal" onClick={(e) => e.stopPropagation()}>
                    <h3>Add annotation</h3>
                    <textarea
                      className="ws-anno-text"
                      placeholder="Your note (supports markdown)…"
                      autoFocus
                      rows={4}
                    />
                    <label className="ws-anno-private">
                      <input type="checkbox" id="ws-anno-private-cb" /> Private (only visible to you)
                    </label>
                    <div className="ws-anno-actions">
                      <button
                        className="ws-anno-save"
                        onClick={() => {
                          const ta = document.querySelector<HTMLTextAreaElement>(".ws-anno-text");
                          const cb = document.querySelector<HTMLInputElement>("#ws-anno-private-cb");
                          if (ta) void handleAnnotationSubmit(ta.value, cb?.checked ?? false);
                        }}
                      >
                        Save
                      </button>
                      <button className="ws-anno-cancel" onClick={() => setAnnotationTarget(null)}>
                        Cancel
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </>
          )}
        </main>

        {/* Right panel */}
        <aside className={`ws-right-panel ${rightPanelHidden ? "hidden" : ""}`}>
          <div className="ws-tabs">
            {([
              ["provenance", "Provenance"],
              ["connections", "Connections"],
              ["trails", "Trails"],
              ["more", "More"],
            ] as const).map(([id, label]) => (
              <button
                key={id}
                className={`ws-tab ${rightPanelTab === id ? "active" : ""}`}
                onClick={() => setRightPanelTab(id)}
              >
                {label}
              </button>
            ))}
          </div>
          <div className="ws-tab-content">
            {rightPanelTab === "provenance" && (
              <div className="ws-provenance">
                <h4>Authorship</h4>
                {authorStats.length === 0 ? (
                  <div className="ws-placeholder-sublabel">No attribution data</div>
                ) : (
                  <ul className="ws-author-list">
                    {authorStats.map((a) => (
                      <li key={a.name} className="ws-author-row">
                        <span className="ws-author-name">{a.name}</span>
                        <span className="ws-author-bar">
                          <span
                            className="ws-author-bar-fill"
                            style={{ width: `${Math.max(2, a.pct)}%`, background: authorColorPair(a.name).primary }}
                          />
                        </span>
                        <span className="ws-author-pct">{a.pct.toFixed(0)}%</span>
                      </li>
                    ))}
                  </ul>
                )}
                <h4>Details</h4>
                <dl className="ws-meta-list">
                  <dt>Work ID</dt>
                  <dd><code>{workIdDisplay}</code></dd>
                  <dt>Persistent ID</dt>
                  <dd><code>xan://{serverDomain}.{workIdDisplay}</code></dd>
                  {workMeta?.publishedAt && (<><dt>Updated</dt><dd>{workMeta.publishedAt}</dd></>)}
                </dl>
              </div>
            )}
            {rightPanelTab === "reuse" && (
              <div className="ws-placeholder">
                <div className="ws-placeholder-label">Reuse</div>
                <div className="ws-placeholder-sublabel">Coming soon — works that transclude or quote this one</div>
              </div>
            )}
            {rightPanelTab === "connections" && (
              <div className="ws-placeholder">
                <div className="ws-placeholder-label">Connections</div>
                <div className="ws-placeholder-sublabel">Coming soon — typed links and backlinks</div>
              </div>
            )}
            {rightPanelTab === "trails" && (
              <div className="ws-trails-tab">
                <div className="ws-trails-tab-header">
                  <span>Trails through this work</span>
                  <button
                    className="ws-trails-manage-btn"
                    onClick={() => setShowTrailsPanel(true)}
                    title="Manage all trails"
                  >
                    Manage
                  </button>
                </div>
                {trailsLoading ? (
                  <div className="ws-placeholder"><div className="ws-placeholder-label">Loading…</div></div>
                ) : trailsForWork.length === 0 ? (
                  <div className="ws-placeholder">
                    <div className="ws-placeholder-label">No trails yet</div>
                    <div className="ws-placeholder-sublabel">Select text and click "+ Trail" to start one</div>
                  </div>
                ) : (
                  <ul className="ws-trail-list">
                    {trailsForWork.map((t) => {
                      const workStops = t.stops
                        .map((s, i) => ({ ...s, index: i }))
                        .filter((s) => s.work_id === workBeId);
                      return (
                        <li key={t.trail_id} className="ws-trail-card">
                          <div className="ws-trail-card-title">{t.name}</div>
                          {t.introduction && (
                            <div className="ws-trail-card-intro">{t.introduction}</div>
                          )}
                          <div className="ws-trail-card-meta">
                            {t.stops.length} stops · {workStops.length} on this work
                            {t.published && <span className="ws-trail-published">· published</span>}
                          </div>
                          {workStops.length > 0 && (
                            <ul className="ws-trail-stops">
                              {workStops.map((s) => (
                                <li
                                  key={s.index}
                                  className="ws-trail-stop"
                                  title={s.note || "No note"}
                                >
                                  <span className="ws-trail-stop-pos">
                                    ¶{s.char_start != null ? `@${s.char_start}` : ""}
                                  </span>
                                  <span className="ws-trail-stop-note">
                                    {s.note ? (s.note.length > 60 ? s.note.slice(0, 60) + "…" : s.note) : "(no note)"}
                                  </span>
                                </li>
                              ))}
                            </ul>
                          )}
                        </li>
                      );
                    })}
                  </ul>
                )}
              </div>
            )}
            {rightPanelTab === "more" && (
              <div className="ws-more-tab">
                <button
                  className="ws-more-tab-btn"
                  onClick={() => {
                    const textblob = new Blob([text], { type: "text/plain" });
                    const url = URL.createObjectURL(textblob);
                    const a = document.createElement("a");
                    a.href = url;
                    a.download = `${workMeta?.title || "work"}.txt`;
                    a.click();
                    setTimeout(() => URL.revokeObjectURL(url), 1000);
                  }}
                >
                  Export as .txt
                </button>
                <button
                  className="ws-more-tab-btn"
                  onClick={() => window.open(`/?work=${workIdDisplay}`, "_blank")}
                >
                  Open in classic editor
                </button>
              </div>
            )}
          </div>
          <button
            className="ws-rail-collapse"
            onClick={() => setRightPanelHidden(true)}
            title="Hide panel"
          >
            ›
          </button>
        </aside>
      </div>

      {/* Bottom lens row — hidden until at least one lens ships real content */}

      {/* Floating "show panel" buttons when hidden */}
      {leftRailHidden && (
        <button
          className="ws-float-show ws-float-left"
          onClick={() => setLeftRailHidden(false)}
          title="Show left panel"
        >
          ›
        </button>
      )}
      {rightPanelHidden && (
        <button
          className="ws-float-show ws-float-right"
          onClick={() => setRightPanelHidden(false)}
          title="Show right panel"
        >
          ‹
        </button>
      )}

      {/* Identity modal — reuse existing IdentityPanel + modal styling */}
      {showIdentity && (
        <div className="modal-overlay" onClick={() => setShowIdentity(false)}>
          <div className="modal-content identity-modal" onClick={(e) => e.stopPropagation()}>
            <IdentityPanel
              identity={identity}
              connected={connected}
              onLogin={login}
              onCreateIdentity={createIdentity}
              onLogout={logout}
            />
            <div style={{ textAlign: "right", marginTop: 12 }}>
              <button className="ws-anno-cancel" onClick={() => setShowIdentity(false)}>Close</button>
            </div>
          </div>
        </div>
      )}

      {/* Invite modal — show current collaborators */}
      {showInvite && (
        <div className="modal-overlay" onClick={() => setShowInvite(false)}>
          <div className="modal-content ws-invite-modal" onClick={(e) => e.stopPropagation()}>
            <h3>Who has access</h3>
            <p style={{ color: "var(--text-muted)", fontSize: 13, marginTop: 4 }}>
              People with edit access to <strong>{workMeta?.title || workIdDisplay}</strong>
            </p>
            {inviteError && (
              <div className="ws-picker-error">{inviteError}</div>
            )}
            {inviteLoading ? (
              <p style={{ color: "var(--text-muted)", fontSize: 12 }}>Loading…</p>
            ) : editClubMembers && editClubMembers.members.length === 0 ? (
              <p style={{ color: "var(--text-muted)", fontSize: 12 }}>
                Only the work owner can edit this work. To invite collaborators,
                they need a Xudanu identity on this server — share the work URL
                and ask them to log in, then add their identity ID here.
              </p>
            ) : editClubMembers ? (
              <>
                <ul className="ws-invite-list">
                  {editClubMembers.members.map(([id, name]) => (
                    <li key={id} className="ws-invite-member">
                      <span className="ws-invite-avatar" style={{ background: authorColorPair(name).primary }}>
                        {name[0]?.toUpperCase() || "?"}
                      </span>
                      <span className="ws-invite-name">{name}</span>
                      <code className="ws-invite-id">0x{id.toString(16)}</code>
                    </li>
                  ))}
                </ul>
                {editClubMembers.truncated && (
                  <p style={{ color: "var(--text-muted)", fontSize: 11 }}>
                    (List truncated — {editClubMembers.total} members total)
                  </p>
                )}
              </>
            ) : null}
            <div className="ws-invite-actions">
              <button className="ws-anno-cancel" onClick={() => setShowInvite(false)}>Close</button>
            </div>
          </div>
        </div>
      )}

      {showAdmin && (
        <div className="modal-overlay" onClick={() => setShowAdmin(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h3>Admin Dashboard</h3>
            <p>Phase 2 (reuse AdminDashboard component)</p>
            <button onClick={() => setShowAdmin(false)}>Close</button>
          </div>
        </div>
      )}

      {showTrailsPanel && (
        <TrailsPanel
          client={connected ? clientRef.current : null}
          currentWorkId={workBeId}
          works={works}
          onSelectWork={selectWork}
          onClose={() => {
            setShowTrailsPanel(false);
            if (rightPanelTab === "trails") void loadTrailsForWork();
          }}
        />
      )}
    </div>
  );
}
