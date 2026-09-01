import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { storageGet, storageSet, storageRemove, storageClear } from "../../safe-storage";
import type { ReactNode } from "react";
import { useCrdtSync } from "../../hooks/useCrdtSync";
import { useWorkStore } from "../../store/work-store";
import { useTransclusion, DEFAULT_LINK_TYPES } from "../../hooks/useTransclusion";
import { linkEnds, isMultiEnded, multiEndWorkIds, notifyStatus, gatherableEnds } from "../../link-ends";
import { MultiEndCompare } from "../MultiEndCompare";
import { useCompoundEdition } from "../../hooks/useCompoundEdition";
import { authorColorPair } from "../../author-color";
import { CollaborativeEditor } from "../CollaborativeEditor";
import { EasyMDEEditor } from "../EasyMDEEditor";
import { TransclusionBadge } from "../TransclusionBadge";
import { IdentityPanel } from "../IdentityPanel";
import { DocumentMapPanel } from "../DocumentMapPanel";
import { TrailsPanel } from "../TrailsPanel";
import { RevisionTimeline } from "../RevisionTimeline";
import { LinkCreator } from "../LinkCreator";
import { ImportWizard } from "../ImportWizard";
import { AttributionPanel } from "../AttributionPanel";
import { ServerDirectoryPanel } from "../ServerDirectoryPanel";
import { loadThemeState, saveThemeState, activePalette } from "../../theme";
import type { ThemeMode } from "../../theme";
import type { WorkListEntry, TrailPayload, AgainHop } from "../../api/crdt_sync";
import type { License } from "../../api/crdt_sync";
import { LICENSES } from "../../api/crdt_sync";
import type { WorkKind } from "../../graph-scoring";
import { KIND_ICON, KIND_COLOR, KIND_ICON_COLOR } from "../../graph-scoring";
import { DataIntegrityBanner } from "../DataIntegrityBanner";
import { WelcomeScreen } from "../WelcomeScreen";
import { DocumentOutlinePanel } from "../DocumentOutline";
import { useIsTablet, useIsPhone } from "../../hooks/useMediaQuery";
import { MobileBottomNav } from "./MobileBottomNav";
import { ConnectionOverlay } from "../ConnectionOverlay";
import { RelatedFooter } from "../RelatedFooter";
import { SearchOverlay } from "../shell/SearchOverlay";
import { PerspectiveView } from "../PerspectiveView";
import { CompoundBuilder } from "../CompoundBuilder";
import { MergePanel } from "../MergePanel";
import { AdminDashboard } from "../AdminDashboard";
import { DocumentSettings, loadDocPreferences } from "../DocumentSettings";
import type { DocPreferences } from "../DocumentSettings";
import type { CrossServerBacklinkPayload } from "../../api/crdt_sync";
import { getCursorOffset, setCaretModel } from "../../styled-text";
import { SEED_CONCEPTS } from "../../concepts-seed";
import { WorkspaceTopBar } from "./WorkspaceTopBar";
import type { WorkspaceNavTab } from "./WorkspaceTopBar";
import "../../app.css";
import "../../theme.css";
import "../../workspace.css";

const WS_URL = `${window.location.protocol === "https:" ? "wss" : "ws"}://${window.location.host}/xudanu`;

type LeftRailMode = "graph" | "outline";
type RightPanelTab = "provenance" | "connections" | "trails" | "timeline" | "servers" | "compare" | "more";

interface WorkMeta {
  title: string;
  author: string | null;
  collection: string | null;
  publishedAt: string | null;
  versionLabel: string | null;
}

function CropOverlay({ src, natW, natH, onApply, onCancel }: {
  src: string;
  natW: number;
  natH: number;
  onApply: (x: number, y: number, w: number, h: number) => void;
  onCancel: () => void;
}) {
  const [cx, setCx] = useState(0);
  const [cy, setCy] = useState(0);
  const [cw, setCw] = useState(natW);
  const [ch, setCh] = useState(natH);
  const leftPct = (cx / natW) * 100;
  const topPct = (cy / natH) * 100;
  const wPct = (cw / natW) * 100;
  const hPct = (ch / natH) * 100;
  return (
    <div className="ws-crop-overlay">
      <div className="ws-crop-preview" style={{ position: "relative", display: "inline-block" }}>
        <img src={src} alt="" style={{ maxWidth: "100%", display: "block", opacity: 0.4 }} />
        <div style={{
          position: "absolute",
          left: `${leftPct}%`,
          top: `${topPct}%`,
          width: `${wPct}%`,
          height: `${hPct}%`,
          border: "2px solid #58a6ff",
          background: "rgba(88,166,255,0.1)",
          boxSizing: "border-box",
        }} />
      </div>
      <div className="ws-crop-controls">
        <label>X <input type="range" min={0} max={natW - 10} value={cx} onChange={(e) => setCx(+e.target.value)} style={{ width: 80 }} /></label>
        <label>Y <input type="range" min={0} max={natH - 10} value={cy} onChange={(e) => setCy(+e.target.value)} style={{ width: 80 }} /></label>
        <label>W <input type="range" min={10} max={natW} value={cw} onChange={(e) => setCw(Math.min(+e.target.value, natW - cx))} style={{ width: 80 }} /></label>
        <label>H <input type="range" min={10} max={natH} value={ch} onChange={(e) => setCh(Math.min(+e.target.value, natH - cy))} style={{ width: 80 }} /></label>
        <span className="ws-crop-dims">{cw}×{ch}px</span>
        <button className="ws-layout-fig-btn" onClick={() => onApply(cx, cy, cw, ch)}>Apply</button>
        <button className="ws-layout-fig-btn" onClick={onCancel}>Cancel</button>
      </div>
      </div>
  );
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
  const [navTab, setNavTab] = useState<WorkspaceNavTab>(() => {
    const params = new URLSearchParams(window.location.search);
    if (params.get("clear") === "1") {
      storageClear();
      params.delete("clear");
      const url = window.location.pathname + (params.toString() ? "?" + params.toString() : "");
      window.history.replaceState({}, "", url);
    }
    const nav = params.get("nav");
    if (nav === "library") return "library";
    if (nav === "compose") return "compose";
    return "explore";
  });
  const [leftRailMode, setLeftRailMode] = useState<LeftRailMode>("graph");
  const [leftRailHidden, setLeftRailHidden] = useState(false);
  // Tablet/phone: panels are overlay drawers. Which drawer (if any) is
  // open — null, "left", or "right". One at a time; the desktop layout
  // ignores this (panels inline as always).
  const isTablet = useIsTablet();
  const isPhone = useIsPhone();
  const [openDrawer, setOpenDrawer] = useState<"left" | "right" | null>(null);
  // Phone shell: the right panel renders as a bottom sheet opened from
  // the bottom nav's Panels button. Independent of tablet drawers.
  const [sheetOpen, setSheetOpen] = useState(false);
  const [rightPanelTab, setRightPanelTab] = useState<RightPanelTab>("provenance");
  const [remoteView, setRemoteView] = useState<{
    title: string; text: string; originServerName: string;
    license: string; tumbler: string; workId: string; serverId: string;
  } | null>(null);
  const [rightPanelHidden, setRightPanelHidden] = useState(false);
  const [showIdentity, setShowIdentity] = useState(false);
  const [showAdmin, setShowAdmin] = useState(false);
  const [workMeta, setWorkMeta] = useState<WorkMeta | null>(() => {
    if (workBeId === null) return null;
    try {
      const cached = storageGet(`xudanu_meta_${workBeId}`);
      if (cached) return JSON.parse(cached) as WorkMeta;
    } catch { /* no-op */ }
    return null;
  });
  const [selectionRange, setSelectionRange] = useState<{ start: number; end: number } | null>(null);
  const [annotationTarget, setAnnotationTarget] = useState<{ start: number; end: number } | null>(null);
  const [themeState, setThemeState] = useState(() => loadThemeState());
  const [themePickerOpen, setThemePickerOpen] = useState(false);
  const [citeFeedback, setCiteFeedback] = useState<string | null>(null);
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [showUndoToast, setShowUndoToast] = useState(false);
  const [editorMode, setEditorMode] = useState<"authoring" | "reading">("authoring");
  const [highlightRange, setHighlightRange] = useState<{ start: number; end: number } | null>(null);
  const [pendingImage, setPendingImage] = useState<{ hash: string; mime: string; byte_size: number; width?: number; height?: number } | null>(null);
  const useMDE = new URLSearchParams(window.location.search).has("mde");
  const [followState, setFollowState] = useState<{ following: boolean; busy: boolean; error: string | null }>({
    following: false,
    busy: false,
    error: null,
  });
  const [works, setWorks] = useState<WorkListEntry[]>([]);
  const [worksLoading, setWorksLoading] = useState(false);
  const [worksError, setWorksError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [sortBy, setSortBy] = useState<"updated" | "title" | "revisions" | "id">("updated");
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
  const [linkDescription, setLinkDescription] = useState("");
  const [kindPickerOpen, setKindPickerOpen] = useState(false);
  const kindCache = useWorkStore(s => s.kindCache);
  const licenseCache = useWorkStore(s => s.licenseCache);
  const [pickerKindFor, setPickerKindFor] = useState<number | null>(null);
  const [workLicense, setWorkLicense] = useState<License>("all-rights-reserved");
  const [licensePickerOpen, setLicensePickerOpen] = useState(false);
  const [licenseHelpOpen, setLicenseHelpOpen] = useState(false);
  const [concepts, setConcepts] = useState<Array<{ work_id: number; title: string; link_count: number }>>([]);
  const [conceptNameOverride, setConceptNameOverride] = useState<Map<number, string>>(new Map());
  const [seedingConcepts, setSeedingConcepts] = useState(false);
  const [seedProgress, setSeedProgress] = useState(0);
  const [serverDomain, setServerDomain] = useState<string>("localhost");
  const [viewingRevision, setViewingRevision] = useState<{ id: number; text: string } | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  // FR-40 L3: the in-editor gather picker (span-level "add to this
  // end" from the selection actions bar).
  const [gatherOpen, setGatherOpen] = useState(false);
  const [gatherBusy, setGatherBusy] = useState(false);
  // FR-40 L4 (S7 attachLink): comment-on-connection composer.
  const [commentOn, setCommentOn] = useState<{ linkId: number; text: string } | null>(null);
  const [narrating, setNarrating] = useState(false);
  const [narration, setNarration] = useState<string | null>(null);
  const [loadingFeedback, setLoadingFeedback] = useState(false);
  const [feedback, setFeedback] = useState<string | null>(null);
  const [suggestingTitle, setSuggestingTitle] = useState(false);
  const [suggestedTitle, setSuggestedTitle] = useState<string | null>(null);
  const [autoTagging, setAutoTagging] = useState(false);
  const [tagResult, setTagResult] = useState<{ new: Array<{name: string; id: number}>; linked: Array<{name: string; id: number}> } | null>(null);
  const [epubImporting, setEpubImporting] = useState(false);
  const [showImport, setShowImport] = useState(false);
  const [demoTrigger, setDemoTrigger] = useState(false);
  const [isPublished, setIsPublished] = useState(false);
  const [isFrozen, setIsFrozen] = useState(false);
  const [crossServerBacklinks, setCrossServerBacklinks] = useState<CrossServerBacklinkPayload[]>([]);
  const [whereUsed, setWhereUsed] = useState<{ edition_ids: number[]; work_ids: number[] } | null>(null);
  const [whereUsedLoading, setWhereUsedLoading] = useState(false);
  const [provenanceChain, setProvenanceChain] = useState<AgainHop[] | null>(null);
  const [provenanceLoading, setProvenanceLoading] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [activeLinkTypes, setActiveLinkTypes] = useState<Set<number>>(new Set());
  const [multiCompareWorkIds, setMultiCompareWorkIds] = useState<number[]>([]);
  const [compareFullscreen, setCompareFullscreen] = useState(false);
  // Provenance underlines are ON by default: the light floating
  // underline is subtle enough for reading, and authorship visibility
  // is the signature capability. localStorage still overrides for
  // users who prefer clean text.
  const [showProv] = useState(() => {
    try { return storageGet("xudanu_showProv") !== "false"; } catch { return true; }
  });
  const [showLinkDesc, setShowLinkDesc] = useState(() => {
    try { return storageGet("xudanu_showLinkDesc") !== "false"; }
    catch { return true; }
  });
  const [showPerspective, setShowPerspective] = useState(false);
  const [showCompoundBuilder, setShowCompoundBuilder] = useState(false);

  // Compose nav tab triggers Compound Builder. The shell document is
  // created untitled on first compose; an explicit title keeps the
  // auto-title extractor (which otherwise borrows concept-seed names
  // like "Folksonomy" for empty works) out of the way.
  useEffect(() => {
    if (navTab === "compose") {
      // Compose into the current document only when it is editable;
      // opening someone else's (read-only) work and tapping Compose
      // otherwise attaches the builder to a document that cannot
      // accept inserts. In that case, start a fresh composition.
      const shouldCreateNew = workBeId === null || !canEdit;
      if (shouldCreateNew && createWork) {
        createWork().then((id) => {
          if (typeof id === "number") {
            selectWork(id);
            if (clientRef.current) {
              clientRef.current
                .sendRequest("work_set_title", {
                  work_id: id,
                  title: "Untitled composition",
                })
                .then(() => {
                  setWorks((prev) =>
                    prev.map((w) =>
                      w.work_id === id
                        ? { ...w, title: "Untitled composition" }
                        : w,
                    ),
                  );
                })
                .catch(() => {});
            }
          }
        });
      }
      setShowCompoundBuilder(true);
    } else {
      setShowCompoundBuilder(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [navTab]);
  const [showMerge, setShowMerge] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  // FR-42/45 network toggle state — mirrored from /health (default off).
  const [networkEnabled, setNetworkEnabled] = useState(false);
  const [externalLinksEnabled, setExternalLinksEnabled] = useState(false);
  const [oauthProviders, setOauthProviders] = useState<{ github: boolean; google: boolean }>({ github: false, google: false });
  useEffect(() => {
    let cancelled = false;
    const readHealth = async () => {
      try {
        const r = await fetch("/health");
        if (!r.ok) return;
        const j = (await r.json()) as {
          network_enabled?: boolean;
          external_links_enabled?: boolean;
          oauth_providers?: { github?: boolean; google?: boolean };
        };
        if (!cancelled && typeof j.network_enabled === "boolean") {
          setNetworkEnabled(j.network_enabled);
        }
        if (!cancelled && typeof j.external_links_enabled === "boolean") {
          setExternalLinksEnabled(j.external_links_enabled);
        }
        if (!cancelled && j.oauth_providers) {
          setOauthProviders({
            github: j.oauth_providers.github === true,
            google: j.oauth_providers.google === true,
          });
        }
      } catch { /* offline — keep last known */ }
    };
    readHealth();
    const iv = setInterval(readHealth, 30000);
    return () => { cancelled = true; clearInterval(iv); };
  }, []);
  const [docPrefs, setDocPrefs] = useState<DocPreferences>(loadDocPreferences());
  const [importText, setImportText] = useState<string | undefined>(undefined);

  // Listen for import requests from welcome page
  useEffect(() => {
    const handler = () => setShowImport(true);
    window.addEventListener("xudanu-open-import", handler);
    return () => window.removeEventListener("xudanu-open-import", handler);
  }, []);
  // Track uploaded images locally for display
  const [imageEntries, setImageEntries] = useState<Array<{ hash: string; mime: string; width?: number; height?: number; url?: string; loading: boolean; charPos?: number; caption?: string }>>([]);
  const [cursorPos, setCursorPos] = useState<number | null>(null);
  const [docMode] = useState<"edit" | "layout">("edit");
  const [imageSizes, setImageSizes] = useState<Map<string, number>>(new Map());
  const [lightboxHash, setLightboxHash] = useState<string | null>(null);
  const [cropTarget, setCropTarget] = useState<string | null>(null);

  const crdt = useCrdtSync(WS_URL, workBeId);
  const {
    text,
    saveState,
    connected,
    authenticated,
    offlineReading,
    accessDeniedWorkId,
    identity,
    isAdmin,
    setText,
    sendCursor,
    sendSelection,
    canEdit,
    attributionSpans,
    attributionLogStatus,
    refreshAttribution,
    createWork,
    fetchWorkList,
    clientRef,
    annotations,
    refreshAnnotations,
    createAnnotation,
    deleteAnnotation,
    awareness,
    login,
    createIdentity,
    changePassword,
    logout,
    reconnectAttempt,
    switchingWork,
    publicClubId,
  } = crdt;

  // FR-41 S1: directory snapshot for the network search tab.
  const [serverDirectoryForSearch, setServerDirectoryForSearch] = useState<
    { address: string; port?: number | null; name: string }[]
  >([]);
  useEffect(() => {
    if (!connected || !clientRef.current) return;
    const client = clientRef.current;
    let cancelled = false;
    (async () => {
      try {
        const resp = await client.sendRequest("server_directory_list", {});
        const val = (resp as { value?: unknown }).value;
        const list = Array.isArray(val)
          ? val
          : ((val as { value?: unknown[] })?.value as unknown[]) ?? [];
        if (!cancelled) {
          setServerDirectoryForSearch(
            (list as { address: string; port: number | null; name: string }[]).map((s) => ({
              address: s.address,
              port: s.port,
              name: s.name,
            })),
          );
        }
      } catch {
        if (!cancelled) setServerDirectoryForSearch([]);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [connected, clientRef]);

  // Load blob elements from server when work changes
  useEffect(() => {
    if (!connected || workBeId === null || !clientRef.current || switchingWork) {
      if (workBeId === null) setImageEntries([]);
      return;
    }
    const client = clientRef.current;
    let cancelled = false;
    client.workBlobList(workBeId).then((blobs) => {
      if (cancelled) return;
      if (blobs.length === 0) { setImageEntries([]); return; }
      setImageEntries((prev) => {
        return blobs.map((b) => {
          const existing = prev.find((e) => e.hash === b.content_hash);
          if (existing && existing.url) {
            return {
              ...existing,
              charPos: b.char_position,
              mime: b.mime_type,
              width: b.width ?? existing.width,
              height: b.height ?? existing.height,
              caption: b.caption ?? existing.caption,
              loading: false,
            };
          }
          return {
            hash: b.content_hash,
            mime: b.mime_type,
            width: b.width ?? undefined,
            height: b.height ?? undefined,
            charPos: b.char_position,
            caption: b.caption ?? undefined,
            loading: true,
          };
        });
      });
      blobs.forEach((b) => {
        const existing = imageEntries.find((e) => e.hash === b.content_hash);
        if (existing && existing.url) return;
        const hash = b.content_hash;
        const mime = b.mime_type;
        client.blobGetPreview(hash).then((previewBytes) => {
          if (cancelled) return;
          const blob = new Blob([(previewBytes || new Uint8Array()) as BlobPart], { type: mime });
          const url = URL.createObjectURL(blob);
          setImageEntries((prev) => prev.map((e) => e.hash === String(hash) ? { ...e, url, loading: false } : e));
        }).catch(() => {
          if (cancelled) return;
          client.blobGet(hash).then((fullBytes) => {
            if (cancelled) return;
            const blob = new Blob([fullBytes as BlobPart], { type: mime });
            const url = URL.createObjectURL(blob);
            setImageEntries((prev) => prev.map((e) => e.hash === String(hash) ? { ...e, url, loading: false } : e));
          }).catch(() => {
            if (cancelled) return;
            setImageEntries((prev) => prev.map((e) => e.hash === String(hash) ? { ...e, loading: false } : e));
          });
        });
      });
    }).catch(() => { if (!cancelled) setImageEntries([]); });
    return () => { cancelled = true; };
  }, [connected, authenticated, workBeId, switchingWork]);

  const transclusion = useTransclusion();

  const blobEntries = useMemo(() => imageEntries.filter(e => e.charPos != null && !e.loading).map(e => ({
    charPos: e.charPos!,
    hash: e.hash,
    url: e.url,
    mime: e.mime,
    width: e.width,
    height: e.height,
  })), [imageEntries]);
  const compound = useCompoundEdition(connected ? clientRef.current : null, workBeId);

  // Reload compound state after authentication completes — the initial load
  // may have failed with PermissionDenied before auth was ready
  useEffect(() => {
    if (connected && authenticated && workBeId !== null) {
      compound.reload();
    }
  }, [connected, authenticated, workBeId]);

  const identityName = identity?.display_name || null;

  const sourceUpdateCount = useMemo(
    () => compound.spanRanges.filter((sr) => sr.source_changed).length,
    [compound.spanRanges],
  );

  const recentWorkIds = useRef<number[]>([]);

  const prevSaveState = useRef(saveState);

  const transclusionCompliance = useMemo(() => {
    if (compound.spanRanges.length === 0) return "none" as const;
    const hasArr = compound.spanRanges.some((sr) => {
      const lic = licenseCache.get(sr.source_work_id) || "all-rights-reserved";
      return lic === "all-rights-reserved";
    });
    return hasArr ? "warning" as const : "compliant" as const;
  }, [compound.spanRanges, licenseCache]);
  const identityColor = identityName ? authorColorPair(identityName).primary : "#888";

  const getSourceText = useCallback(() => compound.resolvedText || text, [compound.resolvedText, text]);

  const selectWork = useCallback((id: number) => {
    setWorkBeId(id);
    setImageEntries([]);
    recentWorkIds.current = recentWorkIds.current.filter((r) => r !== id);
    recentWorkIds.current.push(id);
    if (navTab === "library") setNavTab("explore");
    const url = new URL(window.location.href);
    url.searchParams.set("work", `0x${id.toString(16)}`);
    window.history.replaceState({}, "", url.toString());
  }, [navTab]);

  // Trail following: the trail being followed and current stop index.
  // Persisted so a refresh mid-tour resumes where the reader left off.
  const [followTrail, setFollowTrail] = useState<{ name: string; stops: Array<{ work_id: number; note?: string | null }> } | null>(() => {
    try {
      const raw = storageGet("xudanu_follow_trail");
      return raw ? JSON.parse(raw) : null;
    } catch { return null; }
  });
  const [followIndex, setFollowIndex] = useState<number>(() => {
    try { return Number(storageGet("xudanu_follow_index") || 0); } catch { return 0; }
  });
  useEffect(() => {
    try {
      if (followTrail) {
        storageSet("xudanu_follow_trail", JSON.stringify(followTrail));
        storageSet("xudanu_follow_index", String(followIndex));
      } else {
        storageRemove("xudanu_follow_trail");
        storageRemove("xudanu_follow_index");
      }
    } catch { /* no-op */ }
  }, [followTrail, followIndex]);
  const startTrail = useCallback((name: string, stops: Array<{ work_id: number; note?: string | null }>) => {
    if (stops.length === 0) return;
    setFollowTrail({ name, stops });
    setFollowIndex(0);
    setShowTrailsPanel(false);
    selectWork(stops[0].work_id);
  }, [selectWork]);
  const followNext = useCallback(() => {
    if (!followTrail) return;
    const next = followIndex + 1;
    if (next >= followTrail.stops.length) {
      setFollowTrail(null); // tour complete
      return;
    }
    setFollowIndex(next);
    selectWork(followTrail.stops[next].work_id);
  }, [followTrail, followIndex, selectWork]);
  const followPrev = useCallback(() => {
    if (!followTrail || followIndex === 0) return;
    const prev = followIndex - 1;
    setFollowIndex(prev);
    selectWork(followTrail.stops[prev].work_id);
  }, [followTrail, followIndex, selectWork]);
  const stopFollowing = useCallback(() => setFollowTrail(null), []);

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
        // Ensure the current work is always in the list (it may be newly created
        // and not yet committed to the server's work list)
        if (workBeId !== null && !entries.some((w) => w.work_id === workBeId)) {
          entries = [...entries, {
            work_id: workBeId, title: "", is_starred: false, is_source: false,
            revision_count: 0, updated_at: Math.floor(Date.now() / 1000),
            owner: 0, is_grabbed: false, read_club: 0,
          } as WorkListEntry];
        }
        setWorks(entries);
        setWorksError(null);
        if (workBeId === null) {
          setWorkMeta(null);
          return;
        }
        const match = entries.find((e) => e.work_id === workBeId);
        if (match) {
          const meta = {
            title: match.title || `Work 0x${workBeId.toString(16)}`,
            author: identityName,
            collection: null,
            publishedAt: match.updated_at ? new Date(match.updated_at * 1000).toISOString().slice(0, 10) : null,
            versionLabel: match.revision_count ? `v${match.revision_count}` : null,
          };
          setWorkMeta(meta);
          try { storageSet(`xudanu_meta_${workBeId}`, JSON.stringify(meta)); } catch { /* no-op */ }
          setFollowState((prev) => ({ ...prev, following: !!match.is_starred }));
          setIsPublished(!!match.read_club && match.read_club === publicClubId);
          setIsFrozen(!!match.is_source);
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
  }, [connected, workBeId, fetchWorkList, identityName, authenticated]);

  // Periodic work list refresh — picks up new works from other tabs/sessions
  useEffect(() => {
    if (!connected || !fetchWorkList) return;
    const refresh = async () => {
      try {
        const entries = await fetchWorkList();
        setWorks(entries);
      } catch { /* network error — will retry */ }
    };
    const interval = setInterval(refresh, 30000);
    // Refocus/visible: the 30s interval is the floor, not the ceiling —
    // switching back to the tab (the common "I just made a doc elsewhere"
    // moment) should show fresh state immediately.
    const onVisible = () => {
      if (document.visibilityState === "visible") refresh();
    };
    window.addEventListener("focus", refresh);
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      clearInterval(interval);
      window.removeEventListener("focus", refresh);
      document.removeEventListener("visibilitychange", onVisible);
    };
  }, [connected, fetchWorkList]);

  useEffect(() => {
    const hash = window.location.hash;
    if (hash.startsWith("#tumbler=")) {
      const tumblerStr = decodeURIComponent(hash.slice("#tumbler=".length));
      const client = clientRef.current;
      if (client) {
        void client.resolveTumbler(tumblerStr).then((result) => {
          if (result.work_id && result.is_local) {
            const wid = parseInt(result.work_id, 16);
            if (!isNaN(wid)) {
              selectWork(wid);
              window.history.replaceState({}, "", window.location.pathname + window.location.search);
            }
          }
        }).catch(() => {});
      }
    }
  }, []);

  const handleTumblerNavigate = useCallback(async (tumblerStr: string) => {
    const client = clientRef.current;
    if (!client || !tumblerStr.trim()) return;
    try {
      const result = await client.resolveTumbler(tumblerStr.trim());
      if (result.work_id && result.is_local) {
        const workId = parseInt(result.work_id, 16);
        selectWork(workId);
      }
    } catch (e) {
      console.error("[tumbler] resolve failed:", e);
    }
  }, [clientRef, selectWork]);

  const handleCreateWork = useCallback(async () => {
    if (!createWork) return;
    const newId = await createWork();
    if (typeof newId === "number") {
      selectWork(newId);
    }
    if (fetchWorkList) {
      try {
        const entries = await fetchWorkList();
        if (typeof newId === "number" && !entries.some((w) => w.work_id === newId)) {
          entries.unshift({
            work_id: newId, title: "", is_starred: false, is_source: false,
            revision_count: 0, updated_at: Math.floor(Date.now() / 1000),
            owner: 0, is_grabbed: false, read_club: 0,
          } as WorkListEntry);
        }
        setWorks(entries);
      } catch {
        if (typeof newId === "number") {
          setWorks((prev) => prev.some((w) => w.work_id === newId) ? prev : [{
            work_id: newId, title: "", is_starred: false, is_source: false,
            revision_count: 0, updated_at: Math.floor(Date.now() / 1000),
            owner: 0, is_grabbed: false, read_club: 0,
          } as WorkListEntry, ...prev]);
        }
      }
    } else if (typeof newId === "number") {
      setWorks((prev) => prev.some((w) => w.work_id === newId) ? prev : [{
        work_id: newId, title: "", is_starred: false, is_source: false,
        revision_count: 0, updated_at: Math.floor(Date.now() / 1000),
        owner: 0, is_grabbed: false, read_club: 0,
      } as WorkListEntry, ...prev]);
    }
  }, [createWork, selectWork, fetchWorkList]);

  const handleTranscludeSelection = useCallback(() => {
    if (!selectionRange || workBeId === null) return;
    const srcLicense = licenseCache.get(workBeId) || workLicense;
    if (srcLicense === "all-rights-reserved") {
      if (!confirm("This work is All Rights Reserved. Transcluding it may not be permitted without the author's consent.\n\nContinue anyway?")) {
        return;
      }
    }
    const title = workMeta?.title || `Work 0x${workBeId.toString(16)}`;
    const selectedText = getSourceText().slice(selectionRange.start, selectionRange.end);
    transclusion.holdSelection(workBeId, title, selectionRange.start, selectionRange.end, selectedText);
  }, [selectionRange, workBeId, workMeta, text, transclusion, licenseCache, workLicense]);

  const handleOpenLinkCreator = useCallback(() => {
    if (!selectionRange || workBeId === null) return;
    const title = workMeta?.title || `Work 0x${workBeId.toString(16)}`;
    const selectedText = getSourceText().slice(selectionRange.start, selectionRange.end);
    transclusion.holdLinkSelection(workBeId, title, selectionRange.start, selectionRange.end, selectedText);
  }, [selectionRange, workBeId, workMeta, text, transclusion]);

  const handleCreateLinkTarget = useCallback(
    async (typeId: number) => {
      if (!selectionRange || workBeId === null || !clientRef.current) return;
      const client = clientRef.current;
      const selectedText = getSourceText().slice(selectionRange.start, selectionRange.end);
      const linkId = await transclusion.createContentLink(
        client,
        workBeId,
        selectionRange.start,
        selectionRange.end,
        selectedText,
        typeId,
      );
      if (linkId !== null && linkDescription.trim() && transclusion.pendingLink) {
        try {
          await client.annotationCreate(
            transclusion.pendingLink.sourceWorkId,
            Date.now(),
            "link-description",
            JSON.stringify({ link_id: linkId, text: linkDescription.trim() }),
            transclusion.pendingLink.start,
            transclusion.pendingLink.end,
          );
        } catch (e) {
          console.error("[handleCreateLinkTarget] failed to save description:", e);
        }
      }
      setLinkDescription("");
      setSelectionRange(null);
    },
    [selectionRange, workBeId, text, clientRef, transclusion, linkDescription],
  );

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    if (msg.toLowerCase().includes("fail") || msg.toLowerCase().includes("error")) {
      console.error("[TOAST ERROR]", msg);
    }
    setTimeout(() => setToast(null), 5000);
  }, []);

  const handleCreateAnnotation = useCallback(() => {
    if (!selectionRange) {
      showToast("Select some text first — notes attach to a passage");
      return;
    }
    setAnnotationTarget({ start: selectionRange.start, end: selectionRange.end });
  }, [selectionRange, showToast]);

  const handleToggleStyle = useCallback(
    async (kind: string, start: number, end: number) => {
      const existing = annotations.find(
        (a) => a.kind === kind && a.char_start < end && a.char_end > start,
      );
      try {
        if (existing) {
          await deleteAnnotation(existing.annotation_id);
        } else {
          await createAnnotation(kind, "", start, end, false);
        }
      } catch (e) {
        console.error("[handleToggleStyle] failed:", e);
      }
    },
    [annotations, deleteAnnotation, createAnnotation],
  );

  const handleResolveLinkDescription = useCallback(async (linkId: number, resolved: boolean) => {
    if (workBeId === null) return;
    const existing = annotations.find((a) => {
      if (a.kind !== "link-description" && a.kind !== "link-description-resolved") return false;
      try { const parsed = JSON.parse(a.payload); return parsed.link_id === linkId; } catch { return false; }
    });
    if (!existing) return;
    if (resolved === ("delete" as unknown)) {
      await deleteAnnotation(existing.annotation_id);
      return;
    }
    const newKind = resolved ? "link-description-resolved" : "link-description";
    if (existing.kind === newKind) return;
    try {
      const parsed = JSON.parse(existing.payload);
      await deleteAnnotation(existing.annotation_id);
      await createAnnotation(newKind, JSON.stringify(parsed), existing.char_start, existing.char_end);
    } catch (e) {
      console.error("Failed to update link description:", e);
    }
  }, [workBeId, annotations, deleteAnnotation, createAnnotation]);

  const handleEditLinkDescription = useCallback(async (linkId: number, newText: string) => {
    if (workBeId === null) return;
    const existing = annotations.find((a) => {
      if (a.kind !== "link-description" && a.kind !== "link-description-resolved") return false;
      try { const parsed = JSON.parse(a.payload); return parsed.link_id === linkId; } catch { return false; }
    });
    if (!existing) return;
    try {
      const parsed = JSON.parse(existing.payload);
      const updatedPayload = JSON.stringify({ ...parsed, text: newText });
      await deleteAnnotation(existing.annotation_id);
      await createAnnotation(existing.kind, updatedPayload, existing.char_start, existing.char_end);
    } catch (e) {
      console.error("Failed to edit link description:", e);
    }
  }, [workBeId, annotations, deleteAnnotation, createAnnotation]);

  const handleToggleBlock = useCallback(
    async (kind: string, _payload: string) => {
      if (workBeId === null) return;
      // Read cursor position from the LIVE DOM selection. The buttons
      // use onMouseDown preventDefault so the editor keeps focus and
      // the native caret through the click — but if focus was
      // elsewhere (page load, after panel click), getCursorOffset
      // returns 0 and the bullet prefixed the wrong line. Prefer the
      // live selection; fall back to tracked state only when the
      // editor has no valid selection at all.
      const editorEl = document.querySelector(".editor-content") as HTMLElement | null;
      let pos = 0;
      let haveLiveCaret = false;
      if (editorEl) {
        const sel = window.getSelection();
        if (sel && sel.rangeCount > 0 && editorEl.contains(sel.anchorNode)) {
          pos = getCursorOffset(editorEl);
          haveLiveCaret = true;
        }
      }
      if (!haveLiveCaret) {
        pos = cursorPos ?? 0;
      }
      // Caret at end-of-line (just before its newline) is ON that
      // line — no hop. (The old pos+=1 jumped to the next line and
      // prefixed the bullet there, stranding the cursor above.)
      const lineStart = text.lastIndexOf("\n", pos - 1) + 1;
      const lineEndIdx = text.indexOf("\n", pos);
      const lineEnd = lineEndIdx === -1 ? text.length : lineEndIdx;
      const lineText = text.slice(lineStart, lineEnd);

      // Determine the marker prefix for this block type
      let prefix = "";
      if (kind === "heading") {
        try { const lv = JSON.parse(_payload).level; prefix = "#".repeat(lv) + " "; } catch { prefix = "# "; }
      } else if (kind === "list_item") {
        prefix = "- ";
      } else if (kind === "blockquote") {
        prefix = "> ";
      } else if (kind === "code_block") {
        prefix = "```";
      }

      // Check if line already has this marker
      const hasMarker = lineText.startsWith(prefix);
      // Also check if line has ANY block marker (to replace it)
      const existingMarker = detectExistingMarker(lineText);

      let newLine: string;
      if (hasMarker) {
        // Toggle off — remove the prefix
        newLine = lineText.slice(prefix.length);
      } else if (existingMarker) {
        // Replace existing marker
        newLine = prefix + lineText.slice(existingMarker.length);
      } else {
        // Add new marker
        newLine = prefix + lineText;
      }

      const newText = text.slice(0, lineStart) + newLine + text.slice(lineEnd);
      setText(newText);
      if (!hasMarker) {
        const newCursorPos = lineStart + prefix.length;
        setCursorPos(newCursorPos);
        setTimeout(() => {
          const el = document.querySelector(".editor-content") as HTMLElement | null;
          if (el) {
            el.focus();
            setCaretModel(el, newCursorPos);
          }
        }, 50);
      }
    },
    [text, workBeId, cursorPos],
  );

  function detectExistingMarker(line: string): string {
    if (line.startsWith("### ")) return "### ";
    if (line.startsWith("## ")) return "## ";
    if (line.startsWith("# ")) return "# ";
    if (line.startsWith("- ") || line.startsWith("* ")) return line.slice(0, 2);
    if (/^\d+\.\s/.test(line)) { const m = line.match(/^\d+\.\s/); return m![0]; }
    if (line.startsWith("> ")) return "> ";
    if (line.startsWith("```")) return "```";
    return "";
  }

  useEffect(() => {
    if (saveState === "error" && prevSaveState.current !== "error") {
      showToast("Save error — changes may not be saved. Check connection.");
    }
    prevSaveState.current = saveState;
  }, [saveState, showToast]);

  // Handle ?demo=1 / demo button — open the seeded demo document.
  // The demo must work for anonymous visitors (it is the conversion path
  // for strangers), so it OPENS the published demo work read-only when
  // one exists; only if none exists does it fall back to creating one,
  // which requires being signed in.
  const demoRan = useRef(false);
  useEffect(() => {
    if (demoRan.current) return;
    if (!connected || !clientRef.current) return;
    const params = new URLSearchParams(window.location.search);
    if (params.get("demo") !== "1" && !demoTrigger) return;
    demoRan.current = true;
    params.delete("demo");
    const newParams = params.toString();
    const newUrl = newParams ? `/explore?${newParams}` : "/explore";
    window.history.replaceState({}, "", newUrl);

    const DEMO_TITLE = "Xudanu Interactive Demo";
    (async () => {
      const client = clientRef.current;
      if (!client) return;
      try {
        // Prefer the seeded, published demo — readable by anyone.
        const entries = await client.fetchWorkList();
        const demo = Array.isArray(entries)
          ? entries.find((w) => (w.title ?? "").trim() === DEMO_TITLE)
          : undefined;
        if (demo) {
          selectWork(demo.work_id);
          showToast("Opening the interactive demo");
          return;
        }
      } catch { /* fall through to create */ }

      // No seeded demo on this server: create one (requires identity).
      const demoText = [
        "Welcome to Xudanu",
        "",
        "This interactive demo document shows the key features of the system.",
        "Each concept below is connected to others through typed links.",
        "",
        "Typed Links",
        "Typed links connect passages with coloured margin boxes.",
        "Each type has a specific meaning: Comment, Reference, Disagreement, Quotation, See Also.",
        "",
        "Transclusion",
        "Content can be reused across documents while maintaining its provenance.",
        "When you transclude a passage, the original author is always credited.",
        "",
        "Provenance and Attribution",
        "Every character carries cryptographic provenance via Ed25519 signatures.",
        "",
        "Comparison View",
        "The comparison view shows shared passages between documents with bezier connections.",
        "",
        "Real-time Editing",
        "Multiple users can edit the same document simultaneously.",
        "Changes merge automatically using the O-tree CRDT without locks or conflicts.",
        "",
        "Cross-Server Networking",
        "Documents on different servers can link to each other via domain tumblers.",
        "BLAKE3 hash verification ensures content integrity across the network.",
      ].join("\n");
      try {
        const resp = await client.sendRequest("work_create", { edition: { text: demoText } });
        const val = resp as Record<string, unknown>;
        const inner = val.value as Record<string, unknown> | undefined;
        const id = (inner?.value as number) ?? (inner as unknown as number) ?? (val.value as number);
        if (typeof id === "number" && id > 0) {
          try { await client.workPublish(id); } catch { /* no-op */ }
          selectWork(id);
          showToast("Demo document created");
        } else {
          showToast("Could not open the demo — please sign in first");
        }
      } catch {
        showToast("Could not open the demo — please sign in first");
      }
    })();
  }, [connected, clientRef, selectWork, showToast, demoTrigger]);

  const handleEpubImport = useCallback(async (file: File) => {
    if (!clientRef.current) {
      showToast("Not connected");
      return;
    }
    setEpubImporting(true);
    showToast("Extracting EPUB text…");
    try {
      const buf = await file.arrayBuffer();
      // Phase 1: extract text + metadata (server-side)
      const resp = await clientRef.current.sendRequest("extract_epub", {
        epub_data: Array.from(new Uint8Array(buf)),
      });
      const val = (resp as Record<string, unknown>).value as Record<string, unknown> | undefined;
      const text = (val?.text as string) || "";
      const detectedTitle = (val?.title as string) || "";
      const detectedAuthor = (val?.author as string) || "";

      if (!text) {
        showToast("EPUB text extraction returned empty");
        return;
      }

      showToast(`✓ Extracted: ${detectedTitle || file.name} (${text.length.toLocaleString()} chars)`);

      // Pre-fill author from EPUB metadata into the import text
      // The ImportWizard's source_detect will try to find metadata,
      // but for EPUB we already know it — prepend as header
      const headerLines: string[] = [];
      if (detectedTitle) headerLines.push(`Title: ${detectedTitle}`);
      if (detectedAuthor) headerLines.push(`Author: ${detectedAuthor}`);
      headerLines.push(`Source: EPUB import (${file.name})`);
      headerLines.push("");
      const fullText = headerLines.join("\n") + text;

      // Feed into ImportWizard
      setImportText(fullText);
      setShowImport(true);
    } catch (e) {
      const msg = e instanceof Error ? e.message : typeof e === "object" ? JSON.stringify(e) : String(e);
      showToast(`EPUB extraction failed: ${msg}`);
    } finally {
      setEpubImporting(false);
    }
  }, [clientRef, showToast]);

  const handleMentionEntity = useCallback(
    async (kind: WorkKind) => {
      if (!selectionRange || workBeId === null) return;
      const displayText = compound.resolvedText || text;
      const rawText = displayText.slice(selectionRange.start, selectionRange.end).trim();
      const normalized = rawText.replace(/\s+/g, " ");
      if (!normalized || normalized.length > 100) {
        const custom = prompt(`Enter the ${kind} name:`, normalized.slice(0, 100));
        if (!custom) return;
        return handleMentionEntityWith(custom.trim(), kind);
      }
      return handleMentionEntityWith(normalized, kind);
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [selectionRange, workBeId, text, compound.resolvedText],
  );

  const handleMentionEntityWith = useCallback(
    async (name: string, kind: WorkKind) => {
      if (!selectionRange || workBeId === null || !clientRef.current) return;
      const client = clientRef.current;
      const selectedText = getSourceText().slice(selectionRange.start, selectionRange.end);

      try {
        // 1. Search for existing work with matching title + kind
        const allWorks = await client.fetchWorkList();
        const normalizedLower = name.toLowerCase();
        const match = allWorks.find(
          (w) => (w.title || "").toLowerCase() === normalizedLower &&
                  (kindCache.get(w.work_id) || "document") === kind,
        );

        let targetWorkId: number;
        let created: boolean;

        if (match) {
          targetWorkId = match.work_id;
          created = false;
        } else {
          // 2. Create new work via direct API call (avoids CRDT session switching)
          const createResp = await client.sendRequest("work_create", { edition: { text: name } });
          const createVal = createResp as Record<string, unknown>;
          targetWorkId = createVal.value as number;
          if (!targetWorkId) {
            showToast("Failed: could not create work");
            return;
          }
          // Share the work so it's readable/editable
          const pubClub = crdt.publicClubId || 1000;
          try {
            await client.sendRequest("work_set_read_club", { work_id: targetWorkId, club_id: pubClub });
            await client.sendRequest("work_set_edit_club", { work_id: targetWorkId, club_id: pubClub });
          } catch { /* sharing is best-effort */ }
          await client.workKindSet(targetWorkId, kind);
          created = true;
        }

        // 3. Create typed link (matching LinkCreator's working pattern — no destination ref)
        const linkId = await client.linkCreate(
          workBeId,
          targetWorkId,
          { excerpt: selectedText, start: selectionRange.start, end: selectionRange.end },
        );
        if (linkId) {
          try { await client.linkSetTypes(linkId, [5]); } catch { /* non-critical */ }
        }

        // 4. Feedback
        const kindLabel = kind === "person" ? "Person" : "Concept";
        showToast(created ? `✓ Created ${kindLabel}: ${name}` : `✓ Linked to ${name}`);
        setSelectionRange(null);
        // 5. Refresh work list so the new work appears in search/library
        if (created && fetchWorkList) {
          try { await fetchWorkList(); } catch { /* non-critical */ }
        }
      } catch (e) {
        const msg = e instanceof Error ? e.message : typeof e === "object" ? JSON.stringify(e) : String(e);
        console.error("[mention] failed:", e);
        showToast(`Failed: ${msg}`);
      }
    },
    [selectionRange, workBeId, text, kindCache, showToast, fetchWorkList],
  );

  const handleImageUpload = useCallback(async (file: File) => {
    if (!clientRef.current || workBeId === null) {
      showToast("Not connected");
      return;
    }
    const client = clientRef.current;
    showToast("Uploading image…");
    try {
      const buf = await file.arrayBuffer();
      // Use HTTP POST for binary upload (much faster than WebSocket byte array)
      const sessionId = (client.getSessionId() ?? 0).toString();
      const httpResp = await fetch("/api/blob/upload", {
        method: "POST",
        headers: {
          "Content-Type": file.type || "image/png",
          "X-Xudanu-Session": sessionId,
        },
        body: buf,
      });
      if (!httpResp.ok) {
        const errBody = await httpResp.text();
        showToast(`Upload failed: ${errBody}`);
        return;
      }
      const meta = await httpResp.json() as { content_hash: string; byte_size: number; mime_type: string; width?: number; height?: number };
      const hashStr = meta.content_hash;
      const insertPos = cursorPos ?? text.length;
      await client.elementInsert(workBeId, insertPos, {
        type: "blob",
        blob_hash: hashStr,
        blob_mime: meta.mime_type,
        blob_size: meta.byte_size,
        blob_width: meta.width,
        blob_height: meta.height,
      });
      showToast(`✓ Image placed (${meta.byte_size.toLocaleString()} bytes)`);
      const newEntry = {
        hash: hashStr,
        mime: meta.mime_type,
        width: meta.width ?? undefined,
        height: meta.height ?? undefined,
        loading: true,
      };
      setImageEntries((prev) => {
        const next = [...prev, newEntry];
        return next;
      });
      client.blobGetPreview(hashStr).then((previewBytes) => {
        const imgBytes = previewBytes || new Uint8Array();
        const blob = new Blob([imgBytes as BlobPart], { type: meta.mime_type });
        const url = URL.createObjectURL(blob);
        setImageEntries((prev) => prev.map((e) => e.hash === hashStr ? { ...e, url, loading: false } : e));
      }).catch(() => {
        client.blobGet(hashStr).then((fullBytes) => {
          const blob = new Blob([fullBytes as BlobPart], { type: meta.mime_type });
          const url = URL.createObjectURL(blob);
          setImageEntries((prev) => prev.map((e) => e.hash === hashStr ? { ...e, url, loading: false } : e));
        }).catch(() => {
          setImageEntries((prev) => prev.map((e) => e.hash === hashStr ? { ...e, loading: false } : e));
        });
      });
    } catch (e) {
      const msg = e instanceof Error ? e.message : typeof e === "object" ? JSON.stringify(e) : String(e);
      showToast(`Image upload failed: ${msg}`);
    }
  }, [clientRef, workBeId, showToast]);

  const handleCaptionChange = useCallback(async (hash: string, caption: string) => {
    if (!clientRef.current || workBeId === null) return;
    const entry = imageEntries.find((e) => e.hash === hash);
    if (!entry || entry.charPos == null) return;
    try {
      await clientRef.current.elementUpdate(workBeId, entry.charPos, {
        type: "blob",
        blob_hash: hash,
        blob_mime: entry.mime,
        blob_size: 0,
        blob_width: entry.width,
        blob_height: entry.height,
        blob_caption: caption || undefined,
      });
    } catch (e) {
      console.error("Failed to persist caption:", e);
    }
  }, [clientRef, workBeId, imageEntries]);

  const handleCropImage = useCallback(async (hash: string, cropX: number, cropY: number, cropW: number, cropH: number) => {
    if (!clientRef.current || workBeId === null) return;
    const entry = imageEntries.find((e) => e.hash === hash);
    if (!entry || !entry.url || entry.charPos == null) return;
    try {
      const img = new Image();
      img.src = entry.url;
      await new Promise((res) => { img.onload = res; });
      const canvas = document.createElement("canvas");
      canvas.width = cropW;
      canvas.height = cropH;
      const ctx = canvas.getContext("2d");
      if (!ctx) return;
      ctx.drawImage(img, cropX, cropY, cropW, cropH, 0, 0, cropW, cropH);
      const blob: Blob = await new Promise((res) => canvas.toBlob((b) => res(b!), "image/png"));
      const buf = await blob.arrayBuffer();
      const sessionId = (clientRef.current.getSessionId() ?? 0).toString();
      const httpResp = await fetch("/api/blob/upload", {
        method: "POST",
        headers: { "Content-Type": "image/png", "X-Xudanu-Session": sessionId },
        body: buf,
      });
      if (!httpResp.ok) { showToast("Crop upload failed"); return; }
      const meta = await httpResp.json() as { content_hash: string; byte_size: number; width?: number; height?: number };
      await clientRef.current.elementUpdate(workBeId, entry.charPos, {
        type: "blob",
        blob_hash: meta.content_hash,
        blob_mime: "image/png",
        blob_size: meta.byte_size,
        blob_width: meta.width,
        blob_height: meta.height,
        blob_caption: entry.caption,
      });
      const previewBytes = await clientRef.current.blobGetPreview(meta.content_hash);
      const previewBlob = new Blob([(previewBytes || new Uint8Array()) as BlobPart], { type: "image/png" });
      const newUrl = URL.createObjectURL(previewBlob);
      setImageEntries((prev) => prev.map((e) => e.hash === String(hash) ? {
        ...e, hash: meta.content_hash, url: newUrl, width: meta.width, height: meta.height, mime: "image/png",
      } : e));
      showToast("Image cropped");
    } catch (e) {
      showToast(`Crop failed: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [clientRef, workBeId, imageEntries, showToast]);

  const handleMoveImage = useCallback(async (hash: string, direction: "up" | "down") => {
    if (!clientRef.current || workBeId === null) return;
    const sorted = [...imageEntries].sort((a, b) => (a.charPos ?? 0) - (b.charPos ?? 0));
    const idx = sorted.findIndex((e) => e.hash === hash);
    if (idx < 0) return;
    const swapIdx = direction === "up" ? idx - 1 : idx + 1;
    if (swapIdx < 0 || swapIdx >= sorted.length) return;
    const target = sorted[swapIdx];
    const source = sorted[idx];
    if (source.charPos == null || target.charPos == null) return;
    const client = clientRef.current;
    try {
      await client.elementUpdate(workBeId, source.charPos, {
        type: "blob",
        blob_hash: target.hash,
        blob_mime: target.mime,
        blob_size: 0,
        blob_width: target.width,
        blob_height: target.height,
        blob_caption: target.caption,
      });
      await client.elementUpdate(workBeId, target.charPos, {
        type: "blob",
        blob_hash: source.hash,
        blob_mime: source.mime,
        blob_size: 0,
        blob_width: source.width,
        blob_height: source.height,
        blob_caption: source.caption,
      });
      showToast("Images swapped");
      const blobs = await client.workBlobList(workBeId);
      setImageEntries((prev) => {
        const updated = [...prev];
        for (const b of blobs) {
          const i = updated.findIndex((e) => e.hash === b.content_hash);
          if (i >= 0) updated[i] = { ...updated[i], charPos: b.char_position };
        }
        return updated;
      });
    } catch (e) {
      showToast(`Move failed: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [clientRef, workBeId, imageEntries, showToast]);

  const handleAnnotationSubmit = useCallback(async (annoText: string, isPrivate: boolean) => {
    if (!annotationTarget || !createAnnotation) return;
    await createAnnotation("note", annoText, annotationTarget.start, annotationTarget.end, isPrivate);
    setAnnotationTarget(null);
  }, [annotationTarget, createAnnotation]);

  const handlePlaceTransclusion = useCallback(
    async (position: number, padding?: string) => {
      if (workBeId === null) return;
      const pending = transclusion.pending;
      if (!pending) return;

      let insertPos: number;

      if (position < 0 && padding && padding.length > 0 && clientRef.current) {
        const client = clientRef.current;
        try {
          await client.sendRequest("work_revise_delta", {
            work_id: workBeId,
            base_revision: 0,
            ops: [
              { type: "retain", count: text.length },
              { type: "insert", text: padding },
            ],
          });
        } catch {
        }
        insertPos = text.length + padding.length;
      } else {
        insertPos = Math.max(0, Math.min(position, text.length));
      }

      await compound.addSpan(
        text,
        insertPos,
        pending.text,
        pending.sourceWorkId,
        pending.start,
        pending.end,
      );
      await compound.reload();
      setTimeout(() => compound.reload(), 2000);
      transclusion.clearPending();
      setShowUndoToast(true);
      setTimeout(() => setShowUndoToast(false), 6000);
    },
    [workBeId, text, compound, transclusion, showToast]
  );

  const handlePlaceTransclusionAtEnd = useCallback(() => {
    // Explicit append: no cursor geometry needed — a blank line, then the
    // quote. Covers the "no line available below the last content" case.
    handlePlaceTransclusion(-1, "\n\n");
  }, [handlePlaceTransclusion]);

  const handleNavigateToSource = useCallback(
    (workId: number, spanStart: number | null, spanEnd: number | null) => {
      if (workId === workBeId && spanStart != null && spanEnd != null && spanEnd > spanStart) {
        // Same document: highlight + smooth-scroll to the quoted span.
        setHighlightRange({ start: spanStart, end: spanEnd });
        setTimeout(() => setHighlightRange(null), 4000);
      } else {
        // Cross-document: navigate; the destination lands scrolled via
        // the URL hash (#C<char>) the editor already honors when the
        // new text arrives. Set the hash BEFORE selectWork — its
        // replaceState rebuilds the URL from location.href and
        // preserves the fragment.
        if (spanStart != null) {
          window.history.replaceState(
            null,
            "",
            window.location.pathname + window.location.search + `#C${spanStart}`,
          );
        }
        selectWork(workId);
      }
    },
    [workBeId, selectWork]
  );

  const handlePlacePinnedTransclusion = useCallback(
    async (position: number) => {
      if (workBeId === null) return;
      const pending = transclusion.pending;
      if (!pending) return;
      const insertPos = Math.max(0, Math.min(position, text.length));
      await compound.addPinnedSpan(insertPos, pending.sourceWorkId, pending.start, pending.end);
      await compound.reload();
      setTimeout(() => compound.reload(), 2000);
      transclusion.clearPending();
      setShowUndoToast(true);
      setTimeout(() => setShowUndoToast(false), 6000);
    },
    [workBeId, text, compound, transclusion, showToast]
  );

  const handlePlaceImage = useCallback(
    async (position: number) => {
      if (workBeId === null || !pendingImage || !clientRef.current) return;
      const client = clientRef.current;
      const doInsert = async () => {
        await client.elementInsert(workBeId, position, {
          type: "blob",
          blob_hash: pendingImage.hash,
          blob_mime: pendingImage.mime,
          blob_size: pendingImage.byte_size,
          blob_width: pendingImage.width,
          blob_height: pendingImage.height,
        });
      };
      try {
        await doInsert();
        showToast(`✓ Image placed (${pendingImage.byte_size.toLocaleString()} bytes)`);
      } catch (e) {
        try {
          await new Promise(r => setTimeout(r, 2000));
          await doInsert();
          showToast(`✓ Image placed (${pendingImage.byte_size.toLocaleString()} bytes)`);
        } catch (e2) {
          showToast(`Failed to place image: ${e2 instanceof Error ? e2.message : String(e2)}`);
        }
      }
      setPendingImage(null);
    },
    [workBeId, pendingImage, clientRef, showToast]
  );

  // Remove the Cmd+Z handler — conflicts with editor's text undo

  const handleFollow = useCallback(async () => {
    if (workBeId === null || !clientRef.current) return;
    const wasFollowing = followState.following;
    setFollowState({ following: wasFollowing, busy: true, error: null });
    try {
      if (wasFollowing) {
        await clientRef.current.workUnstar(workBeId);
        setFollowState({ following: false, busy: false, error: null });
        useWorkStore.getState().applyWorkUpdate(workBeId, { is_starred: false });
      } else {
        await clientRef.current.workStar(workBeId);
        setFollowState({ following: true, busy: false, error: null });
        useWorkStore.getState().applyWorkUpdate(workBeId, { is_starred: true });
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

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const handleOpenInvite = useCallback(async () => {
    if (workBeId === null || !clientRef.current) return;
    setShowInvite(true);
    setInviteLoading(true);
    setInviteError(null);
    try {
      const clubId = await clientRef.current.getEditClub(workBeId);
      if (clubId === 0) {
        setEditClubMembers({ members: [], total: 0, truncated: false });
        setInviteError(null);
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
  void handleOpenInvite;

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

  // Load all trails (not filtered by work — show everything)
  const loadTrailsForWork = useCallback(async () => {
    if (!clientRef.current) {
      setTrailsForWork([]);
      return;
    }
    setTrailsLoading(true);
    try {
      // Merge: your own trails first, then everyone's published trails.
      // trail_list alone is owner-scoped — a fresh user would see an
      // empty panel and never discover the onboarding tour.
      const [mine, publishedResp] = await Promise.allSettled([
        clientRef.current.trailList(),
        clientRef.current.trailListPublished(),
      ]);
      const mineList = mine.status === "fulfilled" ? mine.value : [];
      const published = publishedResp.status === "fulfilled" ? publishedResp.value : [];
      const mineIds = new Set(mineList.map((t) => t.trail_id));
      const merged = [...mineList, ...published.filter((t) => !mineIds.has(t.trail_id))];
      setTrailsForWork(merged);
    } catch {
      setTrailsForWork([]);
    } finally {
      setTrailsLoading(false);
    }
  }, [clientRef]);

  useEffect(() => {
    if (connected && rightPanelTab === "trails") {
      void loadTrailsForWork();
    }
  }, [connected, rightPanelTab, loadTrailsForWork]);

  // Load links + backlinks on every work change (needed for colored underlines in editor)
  // Deferred 200ms after text is visible so text renders first
  // Gated on authenticated so nothing fires during the ticket-redeem window
  const loadLinks = transclusion.loadLinks;

  /**
   * FR-40 L4 (S7 attachLink, winfe links.cpp:305): commenting on a
   * CONNECTION creates a link ABOUT the link — a fresh note work
   * (the comment), a two-ended link from the note to the
   * connection's context work, and a "Connection" end-set
   * attachment targeting the commented link itself.
   */
  const handleSubmitCommentOnLink = useCallback(async () => {
    if (!commentOn || !commentOn.text.trim() || !clientRef.current) return;
    const client = clientRef.current;
    const target = transclusion.links.find((l) => l.link_id === commentOn.linkId);
    if (!target) {
      setCommentOn(null);
      return;
    }
    const text = commentOn.text.trim();
    try {
      const resp = await client.sendRequest("work_create", {
        edition: { text },
      });
      const r = resp as Record<string, unknown>;
      const val = (r && typeof r === "object" && "value" in r) ? r.value : resp;
      const noteWorkId = typeof val === "number"
        ? val
        : (val && typeof val === "object" && "work_id" in val) ? (val as Record<string, unknown>).work_id as number : null;
      if (noteWorkId === null) throw new Error("note work not created");
      const contextWork = target.home_document ?? target.origin;
      const commentLinkId = await client.linkCreate(noteWorkId, contextWork);
      await client.linkSetTypes(commentLinkId, [1]);
      await client.linkEndAddAttachment(commentLinkId, "Connection", {
        workContext: contextWork,
        linkAttachment: commentOn.linkId,
      });
      setCommentOn(null);
      showToast("Comment on connection created");
      if (workBeId !== null) {
        void loadLinks(clientRef.current, workBeId, works);
      }
    } catch (e) {
      showToast(e instanceof Error ? e.message : "Comment failed");
    }
  }, [commentOn, transclusion.links, workBeId, works, loadLinks]);

  const loadBacklinks = transclusion.loadBacklinks;
  useEffect(() => {
    // Links and backlinks are READ data: the server checks read
    // permission per work, and anonymous sessions can read published
    // works. Gating on `authenticated` left anonymous visitors with
    // no underlines and an empty Links tab — and stale-ticket sessions
    // lost them too. The ticket-redeem window is a timing concern, not
    // a permission one; a redundant early fetch is harmless.
    if (!connected || workBeId === null || switchingWork) return;
    refreshAttribution();
    refreshAnnotations();
    const linkTimer = setTimeout(() => {
      if (clientRef.current) {
        void loadLinks(clientRef.current, workBeId, works);
        void loadBacklinks(clientRef.current, workBeId);
      }
    }, 200);
    return () => clearTimeout(linkTimer);
  }, [connected, workBeId, switchingWork, clientRef, works, loadLinks, loadBacklinks, refreshAttribution, refreshAnnotations]);

  // Debounced attribution refresh after text changes
  useEffect(() => {
    if (!connected || workBeId === null || !text) return;
    const timer = setTimeout(() => {
      refreshAttribution();
    }, 1500);
    return () => clearTimeout(timer);
  }, [text, connected, workBeId, refreshAttribution]);

  useEffect(() => {
    if (!connected || !authenticated || workBeId === null) {
      setCrossServerBacklinks([]);
      return;
    }
    const timer = setTimeout(() => {
      if (clientRef.current) {
        clientRef.current.crossServerBacklinksGet(workBeId).then(setCrossServerBacklinks).catch(() => setCrossServerBacklinks([]));
      }
    }, 500);
    return () => clearTimeout(timer);
  }, [connected, workBeId]);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setSearchOpen((s) => !s);
      }
      if (e.key === "Escape") {
        setSearchOpen(false);
        setShowIdentity(false);
        transclusion.clearPending();
        transclusion.clearPendingLink();
        setLinkDescription("");
      }
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  }, []);

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

  // Fetch work license when work changes
  useEffect(() => {
    if (!connected || workBeId === null || !clientRef.current) {
      setWorkLicense("all-rights-reserved");
      return;
    }
    let cancelled = false;
    clientRef.current
      .workLicenseGet(workBeId)
      .then((l) => { if (!cancelled) setWorkLicense(l); })
      .catch(() => { if (!cancelled) setWorkLicense("all-rights-reserved"); });
    return () => { cancelled = true; };
  }, [connected, workBeId, clientRef]);

  // Fetch server's public address for persistent IDs
  useEffect(() => {
    fetch("/.well-known/xudanu-server.json")
      .then((r) => r.json())
      .then((data) => {
        if (data.public_address) {
          setServerDomain(data.public_address);
        } else if (data.server_id) {
          // Fall back to globally unique server ID (Ed25519 verifying key hash)
          // Not human-readable, but unique per server — like a Tor onion address
          setServerDomain(typeof data.server_id === "string" ? data.server_id : data.server_id.toString(16));
        }
      })
      .catch(() => {});
  }, []);

  // Populate store from graph data
  // Deferred 1.5s — graph is the lowest priority panel
  useEffect(() => {
    if (!connected || !authenticated || !clientRef.current) return;
    const client = clientRef.current;
    let cancelled = false;
    const timer = setTimeout(() => {
      client
        .workGraph(workBeId ?? undefined, 20)
        .then((g) => {
        if (cancelled) return;
        useWorkStore.getState().setGraph(g.nodes, g.edges);
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
    }, 1500);
    return () => { cancelled = true; clearTimeout(timer); };
  }, [connected, authenticated, clientRef, workBeId, conceptNameOverride]);

  const refreshGraph = useCallback(async () => {
    if (!clientRef.current) return;
    try {
      const g = await clientRef.current.workGraph();
      useWorkStore.getState().setGraph(g.nodes, g.edges);
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
          return { work_id: n.work_id, title, link_count: linkCounts.get(n.work_id) || 0 };
        })
        .sort((a, b) => b.link_count - a.link_count);
      setConcepts(conceptList);
    } catch { /* network error — will retry */ }
  }, [clientRef, conceptNameOverride]);

  const handleAddConcept = useCallback(async () => {
    const name = prompt("New concept name:", "");
    if (!name || !clientRef.current) return;
    try {
      const newId = await createWork();
      if (typeof newId !== "number") return;
      await clientRef.current.workKindSet(newId, "concept");
      useWorkStore.getState().applyKindChange(newId, "concept");
      setConceptNameOverride((prev) => new Map(prev).set(newId, name));
      setConcepts((prev) => [...prev, { work_id: newId, title: name, link_count: 0 }]);
      selectWork(newId);
      refreshGraph();
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
        useWorkStore.getState().applyKindChange(newId, "concept");
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
    useWorkStore.getState().applyKindChange(workBeId, kind);
    try {
      await clientRef.current.workKindSet(workBeId, kind);
    } catch (e) {
      setWorkKind(prev);
      useWorkStore.getState().applyKindChange(workBeId, prev);
      alert(`Could not change kind: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [workBeId, clientRef, workKind]);

  const handleLicenseChange = useCallback(async (license: License) => {
    if (workBeId === null || !clientRef.current) return;
    const prev = workLicense;
    setWorkLicense(license);
    setLicensePickerOpen(false);
    useWorkStore.getState().applyLicenseChange(workBeId, license);
    try {
      await clientRef.current.workLicenseSet(workBeId, license);
    } catch (e) {
      setWorkLicense(prev);
      useWorkStore.getState().applyLicenseChange(workBeId, prev);
      alert(`Could not change license: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [workBeId, clientRef, workLicense]);

  const handlePickerKindChange = useCallback(async (workId: number, kind: WorkKind) => {
    if (!clientRef.current) return;
    const prev = useWorkStore.getState().kindCache.get(workId) || "document";
    useWorkStore.getState().applyKindChange(workId, kind);
    setPickerKindFor(null);
    try {
      await clientRef.current.workKindSet(workId, kind);
    } catch (e) {
      useWorkStore.getState().applyKindChange(workId, prev);
      alert(`Could not change kind: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [clientRef]);

  const handleAddSelectionToTrail = useCallback(async (trailId: number) => {
    if (!selectionRange || workBeId === null || !clientRef.current) return;
    const selectedText = getSourceText().slice(selectionRange.start, selectionRange.end);
    try {
      await clientRef.current.trailAddStop(
        trailId,
        workBeId,
        selectionRange.start,
        selectionRange.end,
        selectedText.length > 80 ? selectedText.slice(0, 80) + "…" : selectedText
      );
      const trailName = userTrails.find((t) => t.trail_id === trailId)?.name || "trail";
      try {
        await createAnnotation(
          "trail-link",
          JSON.stringify({ trail_id: trailId, trail_name: trailName }),
          selectionRange.start,
          selectionRange.end,
          false,
        );
      } catch { /* expected during transitions */ }
      setAddToSelector(null);
      setSelectionRange(null);
      if (rightPanelTab === "trails") await loadTrailsForWork();
      refreshAttribution();
      showToast(`Added to "${trailName}"`);
    } catch (e) {
      alert(`Could not add to trail: ${e instanceof Error ? e.message : String(e)}`);
    }
  }, [selectionRange, workBeId, clientRef, text, rightPanelTab, loadTrailsForWork, userTrails, createAnnotation, refreshAttribution, showToast]);

  const handleCreateTrailFromSelection = useCallback(async () => {
    if (!selectionRange || workBeId === null || !clientRef.current) return;
    const name = prompt("New trail name:", `Trail for ${workMeta?.title || "current work"}`);
    if (!name) return;
    try {
      const trailId = await clientRef.current.trailCreate(name);
      const selectedText = getSourceText().slice(selectionRange.start, selectionRange.end);
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

  const resolvedAttributionSpans = useMemo(() => {
    return attributionSpans.map(span => {
      if (span.author_display_name) return span;
      if (identity?.club_id && span.author_club_id === identity.club_id) {
        return { ...span, author_display_name: identity.display_name };
      }
      if (span.author_public_key && span.author_public_key.length > 0) {
        const hex = span.author_public_key.slice(0, 8).map(b => b.toString(16).padStart(2, "0")).join("");
        return { ...span, author_display_name: `${hex}…` };
      }
      return span;
    });
  }, [attributionSpans, identity]);

  const authorStats = useMemo(() => {
    type Entry = { name: string; chars: number; pct: number };
    const byName = new Map<string, number>();
    let total = 0;
    for (const span of resolvedAttributionSpans) {
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
  }, [resolvedAttributionSpans]);

  const filteredWorks = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    const sorted = [...works];
    switch (sortBy) {
      case "title":
        sorted.sort((a, b) => (a.title || "").localeCompare(b.title || ""));
        break;
      case "revisions":
        sorted.sort((a, b) => (b.revision_count || 0) - (a.revision_count || 0));
        break;
      case "id":
        sorted.sort((a, b) => a.work_id - b.work_id);
        break;
      case "updated":
      default:
        sorted.sort((a, b) => {
          if (a.is_starred !== b.is_starred) return a.is_starred ? -1 : 1;
          return (b.updated_at || 0) - (a.updated_at || 0);
        });
        break;
    }
    if (!q) return sorted;
    return sorted.filter((w) => {
      const title = (w.title || "").toLowerCase();
      const hexId = `0x${w.work_id.toString(16)}`;
      const hexShort = w.work_id.toString(16);
      const hexPadded = w.work_id.toString(16).padStart(4, "0");
      const decId = w.work_id.toString();
      return title.includes(q) || hexId.includes(q) || hexShort.includes(q) || hexPadded.includes(q) || decId.includes(q);
    });
  }, [works, searchQuery, sortBy]);

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
  void breadcrumb;

  // FR-41: hoisted so the remote view renders even when no local
  // work is open (network search hit on the welcome/library screen).
  const remoteTextRef = useRef<HTMLDivElement | null>(null);
  const [remoteActionError, setRemoteActionError] = useState<string | null>(null);
  const [remoteActionBusy, setRemoteActionBusy] = useState(false);

  const remoteViewOverlay = remoteView ? (
              <div style={{
                position: "absolute", inset: 0, zIndex: 50,
                background: "var(--bg-surface)", display: "flex",
                flexDirection: "column", overflow: "hidden",
              }}>
                <div style={{
                  padding: "8px 16px", background: "var(--bg-elevated)",
                  borderBottom: "2px solid var(--border)", display: "flex",
                  alignItems: "center", gap: 8, flexShrink: 0,
                }}>
                  <span style={{
                    fontSize: 9, fontWeight: 700, color: "#fff", background: "#d97706",
                    padding: "2px 8px", borderRadius: 3, textTransform: "uppercase",
                    letterSpacing: 0.5, userSelect: "none",
                  }}>Remote</span>
                  <span style={{ fontSize: 12, fontWeight: 600 }}>
                    From {remoteView.originServerName}
                  </span>
                  <span style={{ fontSize: 10, color: "var(--text-dim)" }}>
                    {remoteView.license}
                  </span>
                  <button
                    type="button"
                    onClick={() => setRemoteView(null)}
                    style={{
                      marginLeft: "auto", fontSize: 11, padding: "4px 12px",
                      border: "1px solid var(--border)", borderRadius: 4,
                      background: "var(--bg-surface)", cursor: "pointer",
                    }}
                  >
                    Back to my work
                  </button>
                </div>
                <div style={{
                  padding: "10px 16px", borderBottom: "1px solid var(--border)",
                  display: "flex", alignItems: "center", gap: 8, flexShrink: 0, flexWrap: "wrap",
                  background: "var(--bg-elevated)",
                }}>
                  <span style={{ fontSize: 11, fontWeight: 600, color: "var(--text)" }}>
                    Actions:
                  </span>
                  <button
                    type="button"
                    disabled={!canEdit}
                    onClick={() => {
                      const sel = window.getSelection();
                      if (!sel || sel.toString().trim().length === 0) return;
                      const excerpt = sel.toString().trim();
                      const citation = `\n\n> ${excerpt.split("\n").join("\n> ")}\n> — From "${remoteView.title}" via ${remoteView.originServerName} (${remoteView.tumbler})\n`;
                      const newText = text + citation;
                      if (clientRef.current && workBeId !== null) {
                        void clientRef.current.workSetText(workBeId, newText);
                      }
                      setRemoteView(null);
                    }}
                    style={{
                      marginLeft: "auto", fontSize: 12, padding: "6px 14px",
                      border: "2px solid var(--green)", borderRadius: 6,
                      background: "var(--green)", color: "#fff",
                      cursor: canEdit ? "pointer" : "not-allowed",
                      opacity: canEdit ? 1 : 0.4, fontWeight: 600,
                    }}
                  >
                    Insert selected text
                  </button>
                  <button
                    type="button"
                    disabled={!canEdit}
                    onClick={async () => {
                      if (!clientRef.current) return;
                      try {
                        const provenance = `> Imported from ${remoteView.originServerName}\n> Tumbler: ${remoteView.tumbler}\n> License: ${remoteView.license}\n\n`;
                        const importText = provenance + remoteView.text;
                        const resp = await clientRef.current.sendRequest("work_create", {
                          edition: { text: importText },
                        });
                        const newWorkId = (resp as Record<string, unknown>)?.value as Record<string, unknown> | undefined;
                        const wid = newWorkId?.value as number | undefined;
                        if (wid) {
                          await clientRef.current.workSetTitle(wid, `${remoteView.title} (from ${remoteView.originServerName})`);
                        }
                        setRemoteView(null);
                        if (wid) selectWork(wid);
                      } catch (e) {
                        console.error("Import failed:", e);
                      }
                    }}
                    style={{
                      marginLeft: "auto", fontSize: 11, padding: "4px 12px",
                      border: "1px solid var(--green)", borderRadius: 4,
                      background: "var(--green)", color: "#fff", cursor: canEdit ? "pointer" : "not-allowed",
                      opacity: canEdit ? 1 : 0.5,
                    }}
                  >
                    Copy to my server
                  </button>
                  <button
                    type="button"
                    disabled={!canEdit || workBeId === null}
                    title="Transclude the selected passage by reference — your document displays the origin's span (verified BLAKE3, provenance intact). Select text in the document below first."
                    onClick={async () => {
                      if (!clientRef.current || workBeId === null || !remoteTextRef.current) return;
                      const sel = window.getSelection();
                      if (!sel || sel.rangeCount === 0 || sel.toString().trim().length === 0) {
                        setRemoteActionError("Select a passage in the document first, then Transclude.");
                        return;
                      }
                      const range = sel.getRangeAt(0);
                      const pre = document.createRange();
                      pre.selectNodeContents(remoteTextRef.current);
                      try {
                        pre.setEnd(range.startContainer, range.startOffset);
                      } catch {
                        setRemoteActionError("Selection outside the document text.");
                        return;
                      }
                      const startChars = Array.from(pre.toString()).length;
                      const selChars = Array.from(range.toString()).length;
                      const end = startChars + selChars;
                      setRemoteActionError(null);
                      setRemoteActionBusy(true);
                      try {
                        const resp = await clientRef.current.sendRequest("transclusion_place_cross_server", {
                          dest_work: workBeId,
                          cursor: 0,
                          tumbler: remoteView.tumbler,
                          span_start: startChars,
                          span_end: end,
                          title_hint: remoteView.title,
                        });
                        const r = resp as Record<string, unknown>;
                        if ((r as { type?: string }).type === "error") {
                          setRemoteActionError(`Transclude failed: ${(r as { message?: string }).message ?? "unknown error"}`);
                          setRemoteActionBusy(false);
                          return;
                        }
                        setRemoteActionBusy(false);
                        setRemoteView(null);
                      } catch (e) {
                        setRemoteActionError(e instanceof Error ? e.message : "transclude failed");
                        setRemoteActionBusy(false);
                      }
                    }}
                    style={{
                      fontSize: 12, padding: "6px 14px",
                      border: "2px solid var(--amber)", borderRadius: 6,
                      background: "var(--amber)", color: "#111",
                      cursor: canEdit && workBeId !== null ? "pointer" : "not-allowed",
                      opacity: canEdit && workBeId !== null ? 1 : 0.4, fontWeight: 700,
                    }}
                  >
                    {remoteActionBusy ? "Transcluding…" : "⇄ Transclude selection"}
                  </button>
                </div>
                {remoteActionError && (
                  <div style={{ padding: "4px 16px", fontSize: 11, color: "var(--red)", background: "var(--bg-elevated)" }}>
                    {remoteActionError}
                  </div>
                )}
                <div style={{ flex: 1, overflow: "auto", padding: "32px 48px", minHeight: 0 }}>
                  <h1 style={{
                    fontSize: 24, fontWeight: 700, marginBottom: 16,
                    fontFamily: "Source Serif 4, Georgia, serif",
                  }}>
                    {remoteView.title}
                  </h1>
                  <div ref={remoteTextRef} style={{
                    whiteSpace: "pre-wrap", fontSize: 15, lineHeight: 1.75,
                    fontFamily: "Source Serif 4, Georgia, serif", color: "var(--text)",
                    userSelect: "text",
                  }}>
                    {remoteView.text}
                  </div>
                </div>
                <div style={{
                  padding: "6px 16px", borderTop: "1px solid var(--border)",
                  fontSize: 9, color: "var(--text-dim)", flexShrink: 0, display: "flex", gap: 16,
                }}>
                  <span>Tumbler: <code>{remoteView.tumbler}</code></span>
                  <span>Work ID: <code>{remoteView.workId}</code></span>
                </div>
              </div>
  ) : null;

  const rightPanelBody = (
    <>
            {rightPanelTab === "provenance" && (
              <div className="ws-provenance-full">
                {/* Compact summary */}
                <div className="ws-provenance-summary">
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
                </div>

                {/* Full detailed attribution — security-critical view */}
                <AttributionPanel
                  spans={resolvedAttributionSpans}
                  logStatus={attributionLogStatus}
                  documentLength={text.length}
                  visible={true}
                  workId={workBeId ?? undefined}
                />

                <div className="ws-provenance-details">
                  <h4>Details</h4>
                  <dl className="ws-meta-list">
                    <dt>Work ID</dt>
                    <dd><code>{workIdDisplay}</code></dd>
                    <dt>Persistent ID</dt>
                    <dd><code>xan://{serverDomain}.{workIdDisplay}</code></dd>
                    {workMeta?.publishedAt && (<><dt>Updated</dt><dd>{workMeta.publishedAt}</dd></>)}
                  </dl>
                </div>
              </div>
            )}
            {rightPanelTab === "connections" && (
              <div className="ws-connections-tab">
                {canEdit && workBeId !== null && (
                  <button
                    className="ws-action-btn"
                    style={{ width: "100%", marginBottom: 8, justifyContent: "center" }}
                    onClick={() => {
                      if (!selectionRange) {
                        setSelectionRange({ start: 0, end: 0 });
                      }
                      handleOpenLinkCreator();
                    }}
                    title="Create a link to another document"
                  >
                    + Add Link
                  </button>
                )}
                {/* Link type filter */}
                {transclusion.links.length > 0 && (
                  <div className="ws-link-filters">
                    {DEFAULT_LINK_TYPES.map((t) => {
                      const count = transclusion.links.filter((l) => (l.link_types || []).includes(t.type_id)).length;
                      if (count === 0) return null;
                      const active = activeLinkTypes.has(t.type_id);
                      return (
                        <button
                          key={t.type_id}
                          type="button"
                          className={`ws-link-filter-btn ${active ? "active" : ""}`}
                          style={active ? { background: t.color, borderColor: t.color } : { borderColor: t.color + "60", color: t.color }}
                          onClick={() => setActiveLinkTypes((prev) => {
                            const next = new Set(prev);
                            if (next.has(t.type_id)) next.delete(t.type_id);
                            else next.add(t.type_id);
                            return next;
                          })}
                          title={`${t.name} (${count})`}
                        >
                          {t.name} ({count})
                        </button>
                      );
                    })}
                    {activeLinkTypes.size > 0 && (
                      <button
                        type="button"
                        className="ws-link-filter-clear"
                        onClick={() => setActiveLinkTypes(new Set())}
                      >
                        clear
                      </button>
                    )}
                  </div>
                )}
                {/* Outbound links */}
                <div className="ws-conn-section">
                  <div className="ws-conn-header">
                    Links ({(() => {
                      const filtered = activeLinkTypes.size === 0
                        ? transclusion.links
                        : transclusion.links.filter((l) => (l.link_types || []).some((t) => activeLinkTypes.has(t)));
                      return filtered.length;
                    })()})
                  </div>
                  {(() => {
                    const filteredLinks = activeLinkTypes.size === 0
                      ? transclusion.links
                      : transclusion.links.filter((l) => (l.link_types || []).some((t) => activeLinkTypes.has(t)));
                    return filteredLinks.length === 0 ? (
                      <div className="ws-conn-empty">{transclusion.links.length === 0 ? 'No outbound links. Select text and click "Link" to create one.' : 'No links match the active filter.'}</div>
                    ) : (
                      filteredLinks.map((link) => {
                      const isWebLink = (link.link_types || []).includes(6);
                      const destUrl = link.destination_ref?.excerpt;
                      const ends = linkEnds(link);
                      const extraEnds = ends.filter((e) => e.name !== "origin" && e.name !== "destination" && e.workId !== null && e.workId !== workBeId);
                      const multi = isMultiEnded(link);
                      const destTitle = isWebLink && destUrl
                        ? destUrl
                        : (link.destination_title || `Work 0x${link.destination.toString(16)}`);
                      const typeNames = (link.link_types || []).map(
                        (tid) => DEFAULT_LINK_TYPES.find((t) => t.type_id === tid)?.name || `type ${tid}`
                      );
                      const notif = notifyStatus(link);
                      const reload = () => {
                        if (clientRef.current && workBeId !== null) {
                          void loadLinks(clientRef.current, workBeId, works);
                        }
                      };
                      return (
                        <div
                          key={link.link_id}
                          className="ws-conn-item"
                          onClick={() => !isWebLink && !multi && selectWork(link.destination)}
                          title={isWebLink && destUrl ? destUrl : undefined}
                        >
                          <div className="ws-conn-title-row">
                            <div className="ws-conn-title">
                              {isWebLink ? "🔗 " : ""}{destTitle}
                              {!isWebLink && (() => {
                                const dl = licenseCache.get(link.destination);
                                const di = dl ? LICENSES.find((l) => l.value === dl) : null;
                                return di && dl !== "all-rights-reserved" ? <span className="ws-work-license-badge" title={di.label}>{di.short}</span> : null;
                              })()}
                              {link.home_document != null && link.home_document !== workBeId && (
                                <span
                                  style={{ fontSize: 10, marginLeft: 4, color: "#8b949e", cursor: "pointer" }}
                                  title={`Link lives in ${works.find((w) => w.work_id === link.home_document)?.title || `work 0x${link.home_document?.toString(16)}`} (home document) — click to open`}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    if (link.home_document != null) selectWork(link.home_document);
                                  }}
                                >
                                  ⌂ home
                                </span>
                              )}
                            </div>
                            <div style={{ display: "flex", gap: 4 }}>
                              {multi && (
                                <button
                                  className="ws-conn-delete"
                                  title="Compare all ends side by side"
                                  style={{ color: "#58a6ff" }}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setMultiCompareWorkIds(multiEndWorkIds(link).filter((id) => id !== null));
                                    setRightPanelTab("compare");
                                  }}
                                >
                                  ⇄
                                </button>
                              )}
                              {canEdit && (
                                <button
                                  className="ws-conn-delete"
                                  title="Comment on this connection — a link about the link"
                                  style={{ color: "var(--green)" }}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setCommentOn({ linkId: link.link_id, text: "" });
                                  }}
                                >
                                  {"\u2317"}
                                </button>
                              )}
                              <button
                                className="ws-conn-delete"
                                title="Delete this link"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  if (confirm("Delete this link?")) {
                                    clientRef.current?.linkDelete(link.link_id).then(reload);
                                  }
                                }}
                              >×</button>
                            </div>
                          </div>
                          {extraEnds.length > 0 && (
                            <div style={{ fontSize: 11, color: "#8b949e", marginTop: 2 }}>
                              {"+ "}
                              {extraEnds.map((e, i) => {
                                const w = works.find((x) => x.work_id === e.workId);
                                return (
                                  <span key={e.name}>
                                    {i > 0 && " · "}
                                    <span
                                      style={{ color: "#58a6ff", cursor: "pointer" }}
                                      title={e.excerpt ? `"${e.excerpt.slice(0, 120)}"` : undefined}
                                      onClick={(ev) => {
                                        ev.stopPropagation();
                                        if (e.workId !== null) selectWork(e.workId);
                                      }}
                                    >
                                      {e.name}: {w?.title || `work 0x${e.workId?.toString(16)}`}
                                    </span>
                                    <span
                                      style={{ cursor: "pointer", marginLeft: 3 }}
                                      title={`Remove end "${e.name}"`}
                                      onClick={(ev) => {
                                        ev.stopPropagation();
                                        clientRef.current?.linkRemoveEnd(link.link_id, e.name).then(reload);
                                      }}
                                    >
                                      ×
                                    </span>
                                  </span>
                                );
                              })}
                            </div>
                          )}
                          {typeNames.length > 0 && (
                            <div className="ws-conn-types">
                              {typeNames.map((tn, i) => {
                                const lt = DEFAULT_LINK_TYPES.find((t) => t.name === tn);
                                return (
                                  <span
                                    key={i}
                                    className="ws-conn-type-badge"
                                    style={lt ? { background: lt.color + "20", color: lt.color, borderColor: lt.color + "60" } : {}}
                                  >
                                    {tn}
                                  </span>
                                );
                              })}
                              {(link.type_ends ?? []).map(([tid, defWork], i) => {
                                const t = DEFAULT_LINK_TYPES.find((x) => x.type_id === tid);
                                if (!t) return null;
                                return (
                                  <span
                                    key={`te-${i}`}
                                    className="ws-conn-type-badge"
                                    style={{ background: t.color + "10", color: t.color, borderColor: t.color + "30", cursor: "pointer", fontSize: 10 }}
                                    title={`Type definition — click to open`}
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      selectWork(defWork);
                                    }}
                                  >
                                    {t.name} ⎋
                                  </span>
                                );
                              })}
                            </div>
                          )}
                          {notif.kind !== "none" && (
                            <div style={{ fontSize: 10, marginTop: 2, color: notif.kind === "accepted" ? "#3fb950" : "#f85149" }}>
                              {notif.kind === "accepted" && "✓ remote server acknowledged"}
                              {notif.kind === "rejected" && `⚠ remote rejected: ${notif.reason}`}
                              {notif.kind === "error" && `⚠ ${notif.reason}`}
                            </div>
                          )}
                          </div>
                        );
                      })
                    );
                  })()}
                  </div>

                  {/* Backlinks */}
                <div className="ws-conn-section">
                  <div className="ws-conn-header">
                    Backlinks ({transclusion.backlinks.length})
                  </div>
                  {transclusion.backlinks.length === 0 ? (
                    <div className="ws-conn-empty">No inbound links from other works.</div>
                  ) : (
                    transclusion.backlinks.map((bl, i) => {
                      const lt = DEFAULT_LINK_TYPES.find((t) =>
                        t.name.toLowerCase() === (bl.link_type || "").toLowerCase().replace(/[\s_]/g, "") ||
                        t.name.toLowerCase().replace(/\s/g, "") === (bl.link_type || "").toLowerCase().replace(/[\s_]/g, "")
                      );
                      const typeLabel = lt ? lt.name : (bl.link_type || "link").replace(/hyperlink_/g, "").replace(/_/g, " ");
                      return (
                        <div
                          key={i}
                          className="ws-conn-item"
                          onClick={() => selectWork(bl.source_work_id)}
                        >
                          <div className="ws-conn-title">
                            {bl.title || `Work 0x${bl.source_work_id.toString(16)}`}
                            {(() => {
                              const sl = licenseCache.get(bl.source_work_id);
                              const si = sl ? LICENSES.find((l) => l.value === sl) : null;
                              return si && sl !== "all-rights-reserved" ? <span className="ws-work-license-badge" title={si.label}>{si.short}</span> : null;
                            })()}
                          </div>
                          {bl.excerpt && <div className="ws-conn-excerpt">"{bl.excerpt.slice(0, 80)}{bl.excerpt.length > 80 ? "…" : ""}"</div>}
                          <div className="ws-conn-types">
                            <span
                              className="ws-conn-type-badge"
                              style={lt ? { background: lt.color + "20", color: lt.color, borderColor: lt.color + "60" } : {}}
                            >
                              {typeLabel}
                            </span>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>

                {/* Transclusions in this work */}
                <div className="ws-conn-section">
                  <div className="ws-conn-header">
                    Transclusions ({compound.spanRanges.length})
                  </div>
                  {compound.spanRanges.length === 0 ? (
                    <div className="ws-conn-empty">No transclusions in this work.</div>
                  ) : (
                    compound.spanRanges.map((sr, i) => {
                      const sourceTitle = compound.sourceTitles[sr.source_work_id] || `Work 0x${sr.source_work_id.toString(16)}`;
                      const srcLic = licenseCache.get(sr.source_work_id);
                      const srcLicInfo = srcLic ? LICENSES.find((l) => l.value === srcLic) : null;
                      const sourceWork = works.find((w) => w.work_id === sr.source_work_id);
                      const origin = sourceWork?.is_source ? sourceWork.source_edition_info : null;
                      return (
                        <div
                          key={i}
                          className="ws-conn-item"
                          style={{ cursor: "pointer" }}
                          title={`From ${sourceTitle}${origin ? " · " + origin : ""} — click to highlight in document`}
                          onClick={() => {
                            setHighlightRange({ start: sr.flat_start, end: sr.flat_end });
                            const el = document.querySelector(".editor-content") as HTMLElement | null;
                            if (el) {
                              el.scrollIntoView({ behavior: "smooth", block: "center" });
                            }
                            setTimeout(() => setHighlightRange(null), 4000);
                          }}
                        >
                          <div className="ws-conn-title">
                            ↗ {sourceTitle}
                            {sr.source_changed && (
                              <span style={{ color: "#d29922", fontSize: 11, marginLeft: 4 }} title="Source was edited after this transclusion was created">
                                ⚠ changed
                              </span>
                            )}
                            {srcLicInfo && srcLic !== "all-rights-reserved" && (
                              <span className="ws-work-license-badge" title={srcLicInfo.label}>{srcLicInfo.short}</span>
                            )}
                          </div>
                          {origin && (
                            <div style={{ fontSize: 10, color: "#d29922", fontStyle: "italic", margin: "1px 0" }}>
                              {origin}
                            </div>
                          )}
                          {sr.resolved_content && (
                            <div className="ws-conn-excerpt" style={{ fontStyle: "italic", color: "#6e7681" }}>
                              {sr.resolved_content.length > 80
                                ? sr.resolved_content.slice(0, 80) + "\u2026"
                                : sr.resolved_content}
                            </div>
                          )}
                          <div className="ws-conn-excerpt">
                            [{sr.char_start}:{sr.char_end}]
                          </div>
                          {canEdit && (
                            <button
                              className="ws-conn-delete"
                              title="Remove this transclusion"
                              onClick={(e) => {
                                e.stopPropagation();
                                if (confirm("Remove this transclusion?")) {
                                  compound.removeTransclusion(sr.source_work_id, sr.char_start, sr.char_end).then((ok) => {
                                    if (ok) showToast("Transclusion removed");
                                  });
                                }
                              }}
                              style={{
                                position: "absolute", top: 4, right: 4,
                                background: "none", border: "none", cursor: "pointer",
                                color: "var(--text-dim)", fontSize: 14, padding: 4,
                              }}
                            >
                              {"\u2715"}
                            </button>
                          )}
                        </div>
                      );
                    })
                  )}
                </div>
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
                    <div className="ws-placeholder-sublabel">Create one from selected text (+ Trail), or ask another server's user to publish theirs.</div>
                  </div>
                ) : (
                  <ul className="ws-trail-list">
                    {trailsForWork.map((t) => {
                      const workStops = t.stops
                        .map((s, i) => ({ ...s, index: i }))
                        .filter((s) => s.work_id === workBeId);
                      return (
                        <li key={t.trail_id} className="ws-trail-card">
                          <div className="ws-trail-card-title-row">
                            <span className="ws-trail-card-title">{t.name}</span>
                            {t.stops.length > 0 && (
                              <button
                                type="button"
                                className="trail-start-btn"
                                title={`Follow this trail from stop 1 (${t.stops.length} stops)`}
                                onClick={(e) => {
                                  e.stopPropagation();
                                  startTrail(t.name, t.stops.map((s) => ({ work_id: s.work_id, note: s.note ?? null })));
                                }}
                              >{"\u25b6"} Start</button>
                            )}
                            {t.published ? (
                              <span className="ws-trail-badge published" title="Published — double-click to unpublish" onDoubleClick={async (e) => {
                                e.stopPropagation();
                                if (!confirm("Unpublish this trail?")) return;
                                try {
                                  await clientRef.current?.trailUnpublish(t.trail_id);
                                  await loadTrailsForWork();
                                } catch (err) {
                                  alert(`Unpublish failed: ${err instanceof Error ? err.message : String(err)}`);
                                }
                              }}>Published</span>
                            ) : (
                              <span className="ws-trail-badge draft" title="Click to publish" onClick={async (e) => {
                                e.stopPropagation();
                                try {
                                  await clientRef.current?.trailPublish(t.trail_id);
                                  await loadTrailsForWork();
                                } catch (err) {
                                  alert(`Publish failed: ${err instanceof Error ? err.message : String(err)}`);
                                }
                              }}>Draft</span>
                            )}
                          </div>
                          {t.introduction && (
                            <div className="ws-trail-card-intro">{t.introduction}</div>
                          )}
                          <div className="ws-trail-card-meta">
                            {t.stops.length} stops{workStops.length > 0 ? ` · ${workStops.length} on this work` : ""}
                          </div>
                          {workStops.length > 0 ? (
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
                          ) : (
                            <ul className="ws-trail-stops">
                              {t.stops.slice(0, 3).map((s, i) => (
                                <li
                                  key={i}
                                  className="ws-trail-stop"
                                  style={{ cursor: "pointer" }}
                                  title={s.note || "Open this document"}
                                  onClick={() => selectWork(s.work_id)}
                                >
                                  <span className="ws-trail-stop-pos">{i + 1}</span>
                                  <span className="ws-trail-stop-note">
                                    {(s.note || `Open stop ${i + 1}`).slice(0, 60)}
                                    {(s.note?.length ?? 0) > 60 ? "…" : ""}
                                  </span>
                                </li>
                              ))}
                              {t.stops.length > 3 && (
                                <li className="ws-trail-stop" style={{ cursor: "pointer", opacity: 0.7 }} onClick={() => setShowTrailsPanel(true)}>
                                  <span className="ws-trail-stop-pos">…</span>
                                  <span className="ws-trail-stop-note">{t.stops.length - 3} more stops</span>
                                </li>
                              )}
                            </ul>
                          )}
                        </li>
                      );
                    })}
                  </ul>
                )}
              </div>
             )}
            {rightPanelTab === "timeline" && (
              <div className="ws-timeline-tab">
                <div className="ws-trails-tab-header">
                  <span>Revision history</span>
                </div>
                <RevisionTimeline
                  workId={workBeId}
                  client={connected ? clientRef.current : null}
                  onViewRevision={(revId, revText) => {
                    setViewingRevision({ id: revId, text: revText });
                  }}
                />
              </div>
            )}
            {rightPanelTab === "servers" && (
              <ServerDirectoryPanel
                client={connected ? clientRef.current : null}
                connected={connected}
                onNavigateToWork={(workId) => selectWork(workId)}
                onViewRemoteWork={(data) => {
                  setRemoteView(data);
                  setRightPanelTab("provenance");
                }}
              />
            )}
            {rightPanelTab === "compare" && (
              <MultiEndCompare
                workIds={multiCompareWorkIds}
                works={works}
                clientRef={clientRef}
                currentWorkId={workBeId}
                onPickWork={(id) => setMultiCompareWorkIds((prev) => [...prev, id])}
                onClose={() => setRightPanelTab("connections")}
                fullscreen={compareFullscreen}
                onRemoveWork={compareFullscreen ? (id) => setMultiCompareWorkIds((prev) => prev.filter((p) => p !== id)) : undefined}
                onExpand={() => setCompareFullscreen(true)}
              />
            )}
            {rightPanelTab === "more" && (
              <div className="ws-more-tab">
                {imageEntries.length > 0 && (
                  <div className="ws-image-gallery">
                    <div className="ws-conn-header">Images ({imageEntries.length})</div>
                    {imageEntries.map((img) => (
                      <div key={img.hash} className="ws-image-thumb" title={`${img.width || "?"}×${img.height || "?"}`}>
                        {img.loading ? (
                          <div className="ws-image-loading">Loading…</div>
                        ) : img.url ? (
                          <img
                            src={img.url}
                            alt=""
                            style={{ maxWidth: "100%", borderRadius: "4px", cursor: "pointer" }}
                            onClick={async () => {
                              if (!clientRef.current) return;
                              const fullBytes = await clientRef.current.blobGet(String(img.hash));
                              const blob = new Blob([fullBytes as BlobPart], { type: img.mime });
                              const url = URL.createObjectURL(blob);
                              window.open(url, "_blank");
                              setTimeout(() => URL.revokeObjectURL(url), 60000);
                            }}
                          />
                        ) : (
                          <div className="ws-image-error">Failed to load</div>
                        )}
                        <div className="ws-image-meta">
                          {img.width && img.height ? `${img.width}×${img.height}` : "Unknown size"}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
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
    </>
  );

  return (
    <div className={`ws-shell ${activeCssClass} ${navTab === "compose" ? "ws-mode-compose" : ""} ${navTab === "library" ? "ws-mode-library" : ""} ${workBeId !== null ? "ws-mode-doc" : ""} ${workBeId === null && navTab !== "library" ? "ws-mode-welcome" : ""}`}>
      <DataIntegrityBanner />
      {offlineReading && (
        <div className="ws-offline-banner" role="status">
          Offline — showing your cached copy of this document. Edits will sync when you reconnect.
        </div>
      )}
      <WorkspaceTopBar
        connected={connected}
        identityName={identityName}
        identityColor={identityColor}
        activeNav={navTab}
        onNavChange={setNavTab}
        onHome={() => {
          setWorkBeId(null);
          setImageEntries([]);
          // The WelcomeScreen renders only off the library tab — leave
          // navTab alone there and the logo looks dead.
          if (navTab === "library") setNavTab("explore");
          const url = new URL(window.location.href);
          url.searchParams.delete("work");
          url.searchParams.delete("demo");
          window.history.replaceState({}, "", url.toString());
        }}
        onOpenSearch={() => {
          setNavTab("library");
          setTimeout(() => {
            const input = document.querySelector<HTMLInputElement>(".ws-picker-search");
            input?.focus();
          }, 100);
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
        <aside
          className={`ws-left-rail ${leftRailHidden ? "hidden" : ""} ${isTablet && openDrawer === "left" ? "drawer-open" : ""}`}
          data-drawer="left"
        >
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
            {isTablet && (
              <button
                className="ws-drawer-close"
                onClick={() => setOpenDrawer(null)}
                title="Close panel"
              >
                ×
              </button>
            )}
          </div>
          <div className="ws-rail-content">
            {leftRailMode === "graph" ? (
              <DocumentMapPanel
                key={`graph-${workBeId}-${connected}`}
                client={connected ? clientRef.current : null}
                onSelectWork={selectWork}
                currentWorkId={workBeId}
                onClose={() => setLeftRailHidden(true)}
                embedded
              />
            ) : workBeId === null ? (
              <div className="ws-placeholder">
                <div className="ws-placeholder-label">Document outline</div>
                <div className="ws-placeholder-sublabel">Open a document to see its outline</div>
              </div>
            ) : (
              <DocumentOutlinePanel
                text={getSourceText()}
                activeCharPos={null}
                onNavigate={(charPos) => {
                  window.history.replaceState(
                    null,
                    "",
                    window.location.pathname + window.location.search + `#C${charPos}`,
                  );
                  window.dispatchEvent(new HashChangeEvent("hashchange"));
                }}
              />
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

            {/* Recent Documents */}
            <div className="ws-concepts-panel">
              <div className="ws-concepts-header">
                <span className="ws-concepts-title">Recent</span>
                <button
                  className="ws-concept-add-btn"
                  onClick={async () => {
                    if (fetchWorkList) {
                      try {
                        const entries = await fetchWorkList();
                        setWorks(entries);
                      } catch { /* network error — will retry */ }
                    }
                  }}
                  title="Refresh list"
                  style={{ fontSize: 11 }}
                >
                  ↻
                </button>
              </div>
              {(() => {
                const pinned = works.filter((w) => w.is_starred);
                // Session-recency first (most recently selected/created in
                // THIS tab), then server updated_at. The ref appends on
                // selection, so array index IS recency: last = most recent.
                const sessionRecency = new Map(
                  recentWorkIds.current.map((id, i) => [id, i]),
                );
                const recentUnpinned = works
                  .filter((w) => !w.is_starred)
                  .sort((a, b) => {
                    const ra = sessionRecency.get(a.work_id) ?? 0;
                    const rb = sessionRecency.get(b.work_id) ?? 0;
                    if (ra !== rb) return rb - ra;
                    const now = Math.floor(Date.now() / 1000);
                    return (b.updated_at ?? now) - (a.updated_at ?? now);
                  })
                  .slice(0, 15 - pinned.length);
                const recent = [...pinned, ...recentUnpinned].slice(0, 15);
                if (recent.length === 0) {
                  return <div className="ws-concepts-empty">No documents yet.</div>;
                }
                return (
                  <ul className="ws-concepts-list">
                    {recent.map((w) => {
                      const title = w.title?.trim() || `Untitled 0x${w.work_id.toString(16)}`;
                      const kind = kindCache.get(w.work_id) || "document";
                      return (
                        <li
                          key={w.work_id}
                          className={`ws-concept-item ${w.work_id === workBeId ? "active" : ""}`}
                          onClick={() => selectWork(w.work_id)}
                          title={w.updated_at ? `${w.is_starred ? "\u2605 Pinned \u00b7 " : ""}Updated ${new Date(w.updated_at * 1000).toISOString().slice(0, 10)}` : (w.is_starred ? "\u2605 Pinned" : undefined)}
                        >
                          <span
                            onClick={async (e) => {
                              e.stopPropagation();
                              if (!clientRef.current) return;
                              try {
                                if (w.is_starred) {
                                  await clientRef.current.workUnstar(w.work_id);
                                } else {
                                  await clientRef.current.workStar(w.work_id);
                                }
                                if (fetchWorkList) {
                                  const entries = await fetchWorkList();
                                  setWorks(entries);
                                }
                              } catch { /* network error — will retry */ }
                            }}
                            style={{ cursor: "pointer", color: w.is_starred ? "#d29922" : "#6e7681", fontSize: 11, flexShrink: 0 }}
                            title={w.is_starred ? "Unpin" : "Pin to top"}
                          >
                            {w.is_starred ? "\u2605" : "\u2606"}
                          </span>
                          {w.is_source && <span style={{ fontSize: 11, marginRight: 2 }}>{"\u{1F4D6}"}</span>}
                          <span style={{ color: KIND_COLOR[kind], fontSize: 11, marginRight: 4 }}>{KIND_ICON[kind]}</span>
                          <span className="ws-concept-name">{title.length > 22 ? title.slice(0, 20) + "…" : title}</span>
                          <span style={{ color: "#6e7681", fontSize: 10, marginLeft: "auto", fontFamily: "monospace", flexShrink: 0 }}>0x{w.work_id.toString(16)}</span>
                        </li>
                      );
                    })}
                  </ul>
                );
              })()}
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
        <main className={`ws-doc-surface ${canEdit ? "editable" : "readonly"} ${editorMode === "reading" ? "reading-mode" : ""}`}>
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
          ) : accessDeniedWorkId !== null && workBeId === accessDeniedWorkId && !(isPhone && text) ? (
            <div className="ws-empty-doc">
              <h2>You don&rsquo;t have access to this document</h2>
              <p>
                Work 0x{accessDeniedWorkId.toString(16)} is private. The owner has not
                shared it with {identity ? "your identity" : "anonymous readers"}.
              </p>
              <div style={{ display: "flex", gap: 8, justifyContent: "center", marginTop: 12 }}>
                {!identity && (
                  <button
                    className="ws-empty-create"
                    onClick={() => setShowIdentity(true)}
                  >
                    Sign in
                  </button>
                )}
                <button
                  className="ws-empty-create"
                  onClick={() => {
                    const url = new URL(window.location.href);
                    url.searchParams.delete("work");
                    window.history.replaceState({}, "", url.toString());
                    setWorkBeId(null);
                  }}
                >
                  Browse works
                </button>
              </div>
            </div>
          ) : workBeId === null && navTab !== "library" ? (
            <WelcomeScreen
              workCount={works.length}
              hasIdentity={!!identity}
              onNewDocument={() => handleCreateWork()}
              onBrowseLibrary={() => setNavTab("library")}
              onImport={() => setShowImport(true)}
              onDemo={() => {
                const url = new URL(window.location.href);
                url.searchParams.set("demo", "1");
                window.history.replaceState({}, "", url.toString());
                setDemoTrigger(true);
              }}
            />
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
                  <select
                    className="ws-picker-sort"
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value as typeof sortBy)}
                    title="Sort by"
                  >
                    <option value="updated">Recently updated</option>
                    <option value="title">Title A-Z</option>
                    <option value="revisions">Most revisions</option>
                    <option value="id">Work ID</option>
                  </select>
                  <button className="ws-empty-create" onClick={handleCreateWork}>+ New work</button>
                  <label className={`ws-epub-import-btn ${epubImporting ? "importing" : ""}`} title="Import a document from an EPUB file">
                    {epubImporting ? "Importing…" : "Import EPUB"}
                    <input
                      type="file"
                      accept=".epub"
                      style={{ display: "none" }}
                      onChange={(e) => {
                        const f = e.target.files?.[0];
                        if (f) void handleEpubImport(f);
                        e.target.value = "";
                      }}
                    />
                  </label>
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
                     const lic = licenseCache.get(w.work_id) || "all-rights-reserved";
                     const licInfo = LICENSES.find((l) => l.value === lic);
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
                          {w.is_source && <span title="Imported source work" style={{ marginRight: 2 }}>{"\u{1F4D6}"}</span>}
                          {w.title || `Work 0x${w.work_id.toString(16)}`}
                        </div>
                        <div className="ws-work-meta">
                          <code>0x{w.work_id.toString(16)}</code>
                          {w.updated_at && <span>· updated {new Date(w.updated_at * 1000).toISOString().slice(0, 10)}</span>}
                          {w.revision_count > 0 && <span>· v{w.revision_count}</span>}
                          <span>· {kind}</span>
                          {lic !== "all-rights-reserved" && licInfo && (
                            <span className="ws-work-license-badge" title={licInfo.label}>
                              {licInfo.short}
                            </span>
                          )}
                          {w.read_club != null && w.read_club === publicClubId ? (
                            <span style={{ color: "#3fb950", fontSize: 9, fontWeight: 600 }}>· 🌍 Public</span>
                          ) : (
                            <span style={{ color: "#8b949e", fontSize: 9 }}>· 🔒 Private</span>
                          )}
                        </div>
                        {pickerKindFor === w.work_id && (
                          <div className="ws-picker-kind-menu" onClick={(e) => e.stopPropagation()}>
                            {(["document", "book", "note", "person", "concept", "collection", "commentary"] as const).map((k) => (
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
                ) : docMode === "layout" && imageEntries.length > 0 ? null : (
                  <>
              <header className="ws-doc-header">
                {!authenticated && !identity && (
                  <div className="ws-auth-warning" onClick={() => setShowIdentity(true)}>
                    ⚠ You're browsing anonymously. Sign in to save links, edits, and revisions.
                  </div>
                )}
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
                        {(["document", "book", "note", "person", "concept", "collection", "commentary"] as const).map((k) => (
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
                  <span
                    className="ws-doc-title-text"
                    title={workMeta?.title || "Click to rename"}
                    onClick={async () => {
                      const current = workMeta?.title || `Work 0x${workBeId?.toString(16) ?? ""}`;
                      const newTitle = prompt("Document title:", current);
                      if (newTitle && newTitle.trim() && newTitle !== current) {
                        try {
                          await crdt.setWorkTitle(newTitle.trim());
                          setWorkMeta((prev) => {
                            const updated = prev ? { ...prev, title: newTitle.trim() } : prev;
                            if (updated && workBeId !== null) {
                              try { storageSet(`xudanu_meta_${workBeId}`, JSON.stringify(updated)); } catch { /* no-op */ }
                            }
                            return updated;
                          });
                          setWorks((prev) => prev.map((w) => w.work_id === workBeId ? { ...w, title: newTitle.trim() } : w));
                          if (fetchWorkList) { try { const entries = await fetchWorkList(); setWorks(entries); } catch { /* network error — will retry */ } }
                        } catch (e) { console.error("Failed to set title:", e); }
                      }
                    }}
                    style={{ cursor: "pointer", fontWeight: 700, fontSize: 18, color: "var(--doc-text, #1a1a1a)" }}
                  >
                    {workMeta?.title || `Work 0x${workBeId?.toString(16) ?? ""}`}
                  </span>
                  <div className="ws-title-actions">
                  <div className="ws-license-picker-wrap">
                    <button
                      className="ws-action-btn"
                      title={`License: ${LICENSES.find((l) => l.value === workLicense)?.label || workLicense} — click to change`}
                      onClick={() => setLicensePickerOpen((o) => !o)}
                    >
                      {LICENSES.find((l) => l.value === workLicense)?.short || "\u00A9"}
                    </button>
                    {licensePickerOpen && (
                      <div className="ws-kind-menu ws-license-menu" role="menu">
                        {LICENSES.map((l) => (
                          <button
                            key={l.value}
                            className={`ws-kind-item ${workLicense === l.value ? "active" : ""}`}
                            onClick={() => handleLicenseChange(l.value)}
                            title={l.label}
                          >
                            <span style={{ fontWeight: 600, fontSize: 11 }}>{l.short}</span>
                            <span>{l.label}</span>
                            {l.url && (
                              <a
                                href={l.url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="ws-license-link"
                                onClick={(e) => e.stopPropagation()}
                                title="View full license text"
                              >
                                &#8599;
                              </a>
                            )}
                            {workLicense === l.value && <span className="ws-kind-check">✓</span>}
                          </button>
                        ))}
                        <button
                          className="ws-license-help-btn"
                          onClick={(e) => {
                            e.stopPropagation();
                            setLicensePickerOpen(false);
                            setLicenseHelpOpen(true);
                          }}
                        >
                          Help me choose
                        </button>
                      </div>
                    )}
                  </div>
                  <button
                    className={`ws-action-btn ${followState.following ? "active" : ""}`}
                    title={followState.following ? "Unstar this work" : "Star this work (adds to your library)"}
                    onClick={handleFollow}
                    disabled={followState.busy}
                  >
                    {followState.busy ? "…" : followState.following ? "★" : "☆"}
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
                        {canEdit && workBeId !== null && (
                          <button
                            className="ws-more-item"
                            onClick={async () => {
                              setMoreMenuOpen(false);
                              if (!clientRef.current) return;
                              const next = !isFrozen;
                              if (next && !confirm("Freeze this document?\n\nContent becomes immutable — no one (including you) can edit the text. Links, notes and annotations stay open. You can unfreeze later.")) return;
                              if (!next && !confirm("Unfreeze this document? Editing becomes possible again.")) return;
                              try {
                                await clientRef.current.workSetSource(workBeId, next);
                                setIsFrozen(next);
                                setWorks((prev) => prev.map((w) => w.work_id === workBeId ? { ...w, is_source: next } : w));
                                showToast(next ? "Document frozen — content immutable" : "Document unfrozen");
                              } catch (e) {
                                showToast(`Freeze failed: ${e instanceof Error ? e.message : "not owner"}`);
                              }
                            }}
                          >
                            {isFrozen ? "❄ Unfreeze document" : "❄ Freeze document"}
                          </button>
                        )}
                        <button
                          className="ws-more-item"
                          onClick={() => { handleCite(); setMoreMenuOpen(false); }}
                        >
                          {citeFeedback ? `✓ ${citeFeedback}` : "Cite…"}
                        </button>
                        {crdt.shareWork && (
                          <button
                            className="ws-more-item"
                            onClick={async () => {
                              setMoreMenuOpen(false);
                              try { await crdt.shareWork(); showToast("Work published — now accessible from other servers"); }
                              catch (e) { showToast("Publish failed"); }
                            }}
                          >
                            Publish to network
                          </button>
                        )}
                        <button
                          className="ws-more-item"
                          onClick={() => { setShowTrailsPanel(true); setMoreMenuOpen(false); }}
                        >
                          Trails
                        </button>
                        <button
                          className="ws-more-item"
                          onClick={async () => {
                            setMoreMenuOpen(false);
                            if (workBeId === null || !clientRef.current) return;
                            try {
                              const revs = await clientRef.current.workRevisionsList(workBeId);
                              const latest = revs[revs.length - 1];
                              if (latest) {
                                await clientRef.current.workRevisionMarkNotable(workBeId, latest.revision_id, true);
                              }
                              setRightPanelTab("timeline");
                            } catch (e) {
                              alert(`Could not save revision: ${e instanceof Error ? e.message : String(e)}`);
                            }
                          }}
                        >
                          Save revision
                        </button>
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
                            } catch { /* no-op */ }
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
                        <div className="ws-more-sep" />
                        <button
                          className="ws-more-item"
                          onClick={() => { setShowPerspective(true); setMoreMenuOpen(false); }}
                        >
                          Perspective View
                        </button>
                        <button
                          className="ws-more-item"
                          onClick={() => { setShowCompoundBuilder(true); setMoreMenuOpen(false); }}
                        >
                          Compound Builder
                        </button>
                        <button
                          className="ws-more-item"
                          onClick={() => { setShowMerge(true); setMoreMenuOpen(false); }}
                        >
                          3-Way Merge
                        </button>
                        <button
                          className="ws-more-item"
                          onClick={() => { setShowSettings(true); setMoreMenuOpen(false); }}
                        >
                          Document Settings
                        </button>
                        <button
                          className="ws-more-item"
                          onClick={() => {
                            setShowLinkDesc((prev) => {
                              const next = !prev;
                              try { storageSet("xudanu_showLinkDesc", String(next)); } catch { /* no-op */ }
                              return next;
                            });
                            setMoreMenuOpen(false);
                          }}
                        >
                          {showLinkDesc ? "\u2713 " : ""}Link Descriptions
                        </button>
                      </div>
                    )}
                  </div>
                  </div>
                </div>
                <div className="ws-doc-actions">
                  {transclusionCompliance === "compliant" && (
                    <span className="ws-compliance-badge compliant" title="All transclusion sources permit reuse">
                      ✓ Licensed
                    </span>
                  )}
                  {transclusionCompliance === "warning" && (
                    <span className="ws-compliance-badge warning" title="One or more transclusion sources are All Rights Reserved">
                      ⚠ ARR source
                    </span>
                  )}
                  {canEdit && (
                    <button
                      className={`ws-action-btn ${editorMode === "reading" ? "active" : ""}`}
                      onClick={() => setEditorMode(editorMode === "authoring" ? "reading" : "authoring")}
                      title={editorMode === "authoring" ? "Switch to reading mode (hides markers)" : "Switch to authoring mode (shows markers)"}
                    >
                      {editorMode === "authoring" ? "📖" : "✏️"}
                    </button>
                  )}
                  {canEdit && (
                    <button
                      className={`ws-action-btn ${isPublished ? "active" : ""}`}
                      style={isPublished ? { background: "rgba(63, 185, 80, 0.15)", borderColor: "rgba(63, 185, 80, 0.4)", color: "#3fb950" } : {}}
                      title={isPublished ? "Public — anyone on this server can read this work. Click to make private." : "Private — only you can read this work. Click to publish."}
                      onClick={async () => {
                        if (isPublished) {
                          if (!confirm("Make this work private? Other users will no longer see it.")) return;
                          try {
                            await clientRef.current?.sendRequest("work_set_read_club", { work_id: workBeId, club_id: 0 });
                            setIsPublished(false);
                            showToast("Work is now private");
                          } catch { showToast("Failed to make private"); }
                        } else {
                          const pubClub = publicClubId || 1000;
                          try {
                            await clientRef.current?.sendRequest("work_set_read_club", { work_id: workBeId, club_id: pubClub });
                            await clientRef.current?.sendRequest("work_set_edit_club", { work_id: workBeId, club_id: pubClub });
                            setIsPublished(true);
                            showToast("Work published — visible to all users on this server");
                          } catch { showToast("Publish failed"); }
                        }
                      }}
                    >
                      {isPublished ? "🌍 Public" : "🔒 Private"}
                    </button>
                  )}
                  {isFrozen && (
                    <span
                      className="ws-action-btn"
                      style={{ color: "#58a6ff", cursor: "default", background: "rgba(88, 166, 255, 0.15)", borderColor: "rgba(88, 166, 255, 0.4)" }}
                      title="Frozen — content is immutable (links and notes still welcome). Unfreeze from the ⋯ menu."
                    >
                      ❄
                    </span>
                  )}
                  {canEdit && (
                    <label className="ws-action-btn ws-image-upload-btn" title="Insert image">
                      📷
                      <input
                        type="file"
                        accept="image/png,image/jpeg,image/gif,image/webp,image/bmp"
                        style={{ display: "none" }}
                        onChange={(e) => {
                          const f = e.target.files?.[0];
                          if (f) void handleImageUpload(f);
                          e.target.value = "";
                        }}
                      />
                    </label>
                  )}
                </div>
                <div className="ws-doc-meta">
                  <span
                    className={`ws-save-dot${saveState === "error" ? " ws-save-dot-error" : ""}`}
                    style={{
                      display: "inline-block",
                      width: 8,
                      height: 8,
                      borderRadius: "50%",
                      background: saveState === "error" ? "#f85149" : saveState === "saving" ? "#d29922" : "#3fb950",
                      transition: "background 0.3s",
                      animation: saveState === "error" ? "ws-dot-pulse 1.5s infinite" : undefined,
                    }}
                    title={saveState === "error" ? "Save error — changes may not be saved. Check your connection." : saveState === "saving" ? "Saving..." : "All changes saved"}
                  />
                  {workMeta?.author && <span>{workMeta.author}</span>}
                  {workMeta?.collection && <span>· {workMeta.collection}</span>}
                  {workMeta?.publishedAt && <span>· {workMeta.publishedAt}</span>}
                  <span>· {workIdDisplay}</span>
                  <span
                    className="ws-doc-pid"
                    style={{ cursor: "pointer", userSelect: "all" }}
                    title="Click to copy tumbler address"
                    onClick={() => {
                      const tumbler = `"${serverDomain}".${workIdDisplay}`;
                      navigator.clipboard?.writeText(tumbler);
                    }}
                  >
                    "{serverDomain}".{workIdDisplay}
                  </span>
                  <button
                    title="Copy shareable link"
                    onClick={(e) => {
                      e.stopPropagation();
                      const tumbler = `"${serverDomain}".${workIdDisplay}`;
                      const url = `${window.location.origin}${window.location.pathname}#tumbler=${encodeURIComponent(tumbler)}`;
                      navigator.clipboard?.writeText(url);
                    }}
                    style={{
                      fontSize: 9, cursor: "pointer", border: "1px solid var(--border)",
                      background: "var(--bg)", color: "var(--text-muted)",
                      borderRadius: 3, padding: "1px 4px",
                    }}
                  >
                    link
                  </button>
                  <input
                    className="ws-tumbler-input"
                    placeholder="paste tumbler..."
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        void handleTumblerNavigate((e.target as HTMLInputElement).value);
                        (e.target as HTMLInputElement).value = "";
                      }
                    }}
                    style={{
                      fontSize: 9,
                      fontFamily: "monospace",
                      background: "var(--bg)",
                      border: "1px solid var(--border)",
                      borderRadius: 3,
                      padding: "1px 4px",
                      color: "var(--text-muted)",
                      width: 120,
                    }}
                    title="Paste a tumbler address and press Enter to navigate"
                  />
                  {sourceUpdateCount > 0 && (
                    <span
                      style={{
                        fontSize: 10,
                        fontWeight: 600,
                        color: "#d29922",
                        background: "rgba(210, 153, 34, 0.1)",
                        border: "1px solid rgba(210, 153, 34, 0.3)",
                        borderRadius: 10,
                        padding: "1px 8px",
                        cursor: "pointer",
                        userSelect: "none",
                      }}
                      title={`${sourceUpdateCount} transclusion source${sourceUpdateCount !== 1 ? "s" : ""} updated — see Connections panel`}
                      onClick={() => {
                        setRightPanelTab("connections");
                        const panel = document.querySelector('[class*="ctx-section"]');
                        if (panel) panel.scrollIntoView({ behavior: "smooth", block: "center" });
                      }}
                    >
                      {sourceUpdateCount} source update{sourceUpdateCount !== 1 ? "s" : ""}
                    </span>
                  )}
                </div>
              </header>

              <div className="ws-doc-scroll">
                {viewingRevision && (
                  <div className="ws-revision-banner">
                    <span>Viewing revision v{viewingRevision.id} (read-only)</span>
                    <button onClick={() => setViewingRevision(null)}>Return to current</button>
                  </div>
                )}
                {viewingRevision ? (
                  <div style={{ padding: "16px 0", maxWidth: "38em", margin: "0 auto", fontFamily: "Source Serif 4, Georgia, serif", fontSize: 16, lineHeight: 1.7, color: "#000", whiteSpace: "pre-wrap" }}>
                    {viewingRevision.text
                      .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, "")
                      .replace(/\ufffc/g, "[image]")
                      .replace(/data:image\/[^;]+;base64,[A-Za-z0-9+/=]{50,}/g, "[image]")
                      .replace(/https?:\/\/\S{50,}/g, (m) => m.substring(0, 47) + "...")
                    }
                  </div>
                ) : (
                  <>
                <div className={`ws-selection-actions ${(!selectionRange || transclusion.pending || transclusion.pendingLink) ? "ws-sel-hidden" : ""}`}>
                    <button
                      type="button"
                      className="ws-sel-btn transclude"
                      disabled={!selectionRange}
                      onClick={handleTranscludeSelection}
                    title="Hold this passage, then open another document from the Recent list (left panel) and click to place it there"
                  >
                    Transclude
                  </button>
                    <button
                      type="button"
                      className="ws-sel-btn link"
                      disabled={!selectionRange}
                      onClick={handleOpenLinkCreator}
                      title="Create a typed link from this selection"
                    >
                      Link
                    </button>
                    <button
                      type="button"
                      className="ws-sel-btn link"
                      disabled={!selectionRange || gatherableEnds(transclusion.links, workBeId ?? -1).length === 0}
                      onClick={() => setGatherOpen((g) => !g)}
                      title="Gather this passage into an existing end — one connection, many passages"
                    >
                      Gather
                    </button>
                      <button
                        type="button"
                        disabled={!canEdit || !workBeId}
                        onClick={async () => {
                          if (!clientRef.current || workBeId === null || !remoteView) return;
                          try {
                            await clientRef.current.sendRequest("cross_server_link_create", {
                              local_work_id: workBeId,
                              remote_tumbler: remoteView.tumbler,
                              remote_title: remoteView.title,
                              remote_server_name: remoteView.originServerName,
                              remote_server_id: parseInt(remoteView.serverId, 10) || 0,
                              link_type: "reference",
                            });
                          } catch (e) { console.error("Link create failed:", e); }
                          setRemoteView(null);
                        }}
                        style={{
                          fontSize: 11, padding: "4px 12px",
                          border: "1px solid var(--accent-blue)", borderRadius: 4,
                          background: "transparent", color: "var(--accent-blue)",
                          cursor: canEdit ? "pointer" : "not-allowed",
                          opacity: canEdit ? 1 : 0.5, marginRight: 4,
                        }}
                      >
                        Link to this
                      </button>
                      <button
                        type="button"
                        className="ws-sel-btn note"
                        onClick={handleCreateAnnotation}
                        disabled={!canEdit}
                        title={canEdit
                          ? "Add a note to this passage — select text first. Public (shared with readers) or private (only visible to you)"
                          : "Sign in to add notes"}
                      >
                        Note
                    </button>
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
                    <button
                      type="button"
                      className="ws-sel-btn mention"
                      onClick={() => handleMentionEntity("person")}
                      title="Link to or create a Person work for this name"
                    >
                      👤 Mention
                    </button>
                    <button
                      type="button"
                      className="ws-sel-btn tag"
                      onClick={() => handleMentionEntity("concept")}
                      title="Link to or create a Concept work for this term"
                    >
                      💡 Tag
                    </button>
                  </div>
                <div className="ws-format-bar">
                    <button type="button" className="ws-sel-btn style" onMouseDown={(e) => e.preventDefault()}
                      onClick={() => selectionRange && handleToggleStyle("bold", selectionRange.start, selectionRange.end)}
                      title="Bold (Ctrl+B)" style={{ fontWeight: 700 }}
                      disabled={!selectionRange}>B</button>
                    <button type="button" className="ws-sel-btn style" onMouseDown={(e) => e.preventDefault()}
                      onClick={() => selectionRange && handleToggleStyle("italic", selectionRange.start, selectionRange.end)}
                      title="Italic (Ctrl+I)" style={{ fontStyle: "italic" }}
                      disabled={!selectionRange}>I</button>
                    <span className="ws-sel-sep" />
                    <button type="button" className="ws-sel-btn style" onMouseDown={(e) => e.preventDefault()}
                      onClick={() => handleToggleBlock("heading", JSON.stringify({ level: 1 }))}
                      title="Heading 1" style={{ fontWeight: 700, fontSize: 13 }}>H1</button>
                    <button type="button" className="ws-sel-btn style" onMouseDown={(e) => e.preventDefault()}
                      onClick={() => handleToggleBlock("heading", JSON.stringify({ level: 2 }))}
                      title="Heading 2" style={{ fontWeight: 700, fontSize: 12 }}>H2</button>
                    <button type="button" className="ws-sel-btn style" onMouseDown={(e) => e.preventDefault()}
                      onClick={() => handleToggleBlock("heading", JSON.stringify({ level: 3 }))}
                      title="Heading 3" style={{ fontWeight: 600, fontSize: 11 }}>H3</button>
                    <button type="button" className="ws-sel-btn" onMouseDown={(e) => e.preventDefault()}
                      onClick={() => handleToggleBlock("list_item", JSON.stringify({ type: "bullet" }))}
                      title="Bullet list">&bull;</button>
                    <button type="button" className="ws-sel-btn" onMouseDown={(e) => e.preventDefault()}
                      onClick={() => handleToggleBlock("blockquote", "")}
                      title="Blockquote">&#10078;</button>
                    <button type="button" className="ws-sel-btn" onMouseDown={(e) => e.preventDefault()}
                      onClick={() => handleToggleBlock("code_block", "")}
                      title="Code block">&lt;/&gt;</button>
                    <span className="ws-sel-sep" style={{ marginLeft: "auto" }} />
                    {crdt.llmEnabled && (
                    <button type="button" className="ws-sel-btn" onMouseDown={(e) => e.preventDefault()}
                      disabled={narrating}
                      onClick={async () => {
                        setNarrating(true);
                        setNarration(null);
                        const result = await crdt.narrateDiff();
                        setNarration(result.text);
                        setNarrating(false);
                      }}
                      title="Summarize changes with AI"
                      style={{ color: "#d4a017" }}>
                      {narrating ? "Summarizing\u2026" : "\u2728 Summarize"}
                    </button>
                    )}
                    {crdt.llmEnabled && (
                    <button type="button" className="ws-sel-btn" onMouseDown={(e) => e.preventDefault()}
                      disabled={loadingFeedback}
                      onClick={async () => {
                        setLoadingFeedback(true);
                        setFeedback(null);
                        const result = await crdt.getWritingFeedback();
                        setFeedback(result.text);
                        setLoadingFeedback(false);
                      }}
                      title="Get AI writing feedback"
                      style={{ color: "#d4a017" }}>
                      {loadingFeedback ? "Reviewing\u2026" : "\u2728 Feedback"}
                    </button>
                    )}
                    {crdt.llmEnabled && (
                    <button type="button" className="ws-sel-btn" onMouseDown={(e) => e.preventDefault()}
                      disabled={suggestingTitle}
                      onClick={async () => {
                        setSuggestingTitle(true);
                        setSuggestedTitle(null);
                        const title = await crdt.suggestTitle();
                        setSuggestedTitle(title || "(No title generated)");
                        setSuggestingTitle(false);
                      }}
                      title="Generate a title with AI"
                      style={{ color: "#d4a017" }}>
                      {suggestingTitle ? "Thinking\u2026" : "\u2728 Title"}
                    </button>
                    )}
                    {crdt.llmEnabled && (
                    <button type="button" className="ws-sel-btn" onMouseDown={(e) => e.preventDefault()}
                      disabled={autoTagging}
                      onClick={async () => {
                        setAutoTagging(true);
                        setTagResult(null);
                        const result = await crdt.autoTag();
                        setTagResult(result);
                        setAutoTagging(false);
                        refreshGraph();
                      }}
                      title="Auto-tag concepts with AI"
                      style={{ color: "#d4a017" }}>
                      {autoTagging ? "Tagging\u2026" : "\u2728 Auto-Tag"}
                    </button>
                    )}
                  </div>
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
                {gatherOpen && selectionRange && workBeId !== null && (
                  <div className="ws-trail-picker">
                    <div className="ws-trail-picker-header">
                      <span>Gather this passage into an end</span>
                      <button
                        className="ws-trail-picker-close"
                        onClick={() => setGatherOpen(false)}
                        title="Close"
                      >×</button>
                    </div>
                    <div className="ws-trail-picker-list">
                      {gatherableEnds(transclusion.links, workBeId).length === 0 ? (
                        <div className="ws-placeholder-sublabel">
                          No links on this work yet — create one with Link first.
                        </div>
                      ) : (
                        gatherableEnds(transclusion.links, workBeId).map((end) => (
                          <button
                            key={`${end.linkId}-${end.wireName}`}
                            className="ws-trail-picker-item"
                            disabled={gatherBusy}
                            onClick={async () => {
                              if (!clientRef.current || !selectionRange) return;
                              setGatherBusy(true);
                              try {
                                const selectedText = getSourceText().slice(selectionRange.start, selectionRange.end);
                                await clientRef.current.linkEndAddAttachment(end.linkId, end.wireName, {
                                  workContext: workBeId,
                                  excerpt: selectedText.slice(0, 120),
                                  start: selectionRange.start,
                                  end: selectionRange.end,
                                });
                                setGatherOpen(false);
                                setToast(`Gathered into ${end.localName} — now ${end.memberCount + 1} passages`);
                                void loadLinks(clientRef.current, workBeId, works);
                              } catch (e) {
                                setToast(e instanceof Error ? e.message : "Gather failed");
                              } finally {
                                setGatherBusy(false);
                              }
                            }}
                          >
                            <span className="ws-trail-picker-name">
                              {end.localName}
                              {end.excerpt ? ` — “${end.excerpt}”` : ""}
                            </span>
                            <span className="ws-trail-picker-count">
                              {end.memberCount > 1 ? `${end.memberCount} passages` : "1 passage"}
                            </span>
                          </button>
                        ))
                      )}
                    </div>
                  </div>
                )}
                {commentOn && (
                  <div className="ws-trail-picker">
                    <div className="ws-trail-picker-header">
                      <span>Comment on connection</span>
                      <button
                        className="ws-trail-picker-close"
                        onClick={() => setCommentOn(null)}
                        title="Close"
                      >×</button>
                    </div>
                    <div style={{ padding: "6px 10px" }}>
                      <textarea
                        value={commentOn.text}
                        onChange={(e) => setCommentOn((c) => (c ? { ...c, text: e.target.value } : c))}
                        placeholder="What do you want to say about this connection?"
                        rows={3}
                        style={{ width: "100%", background: "var(--bg-secondary)", color: "var(--text-primary)", border: "1px solid var(--border)", borderRadius: 4, padding: 6, fontSize: 12, resize: "vertical" }}
                      />
                      <button
                        type="button"
                        className="ws-action-btn"
                        style={{ marginTop: 6, width: "100%", justifyContent: "center" }}
                        disabled={!commentOn.text.trim()}
                        onClick={() => void handleSubmitCommentOnLink()}
                      >
                        Save comment
                      </button>
                    </div>
                  </div>
                )}
                {narration && (
                  <div className="llm-result-panel">
                    <div className="llm-result-header">
                      <span>Summary</span>
                      <button type="button" className="llm-result-close" onClick={() => setNarration(null)}>close</button>
                    </div>
                    <p style={{ whiteSpace: "pre-wrap" }}>{narration}</p>
                  </div>
                )}
                {feedback && (
                  <div className="llm-result-panel">
                    <div className="llm-result-header">
                      <span>Writing Feedback</span>
                      <button type="button" className="llm-result-close" onClick={() => setFeedback(null)}>close</button>
                    </div>
                    <p style={{ whiteSpace: "pre-wrap" }}>{feedback}</p>
                  </div>
                )}
                {suggestedTitle && (
                  <div className="llm-result-panel">
                    <div className="llm-result-header">
                      <span>Suggested Title</span>
                      <div style={{ display: "flex", gap: 4 }}>
                        <button type="button" className="ws-sel-btn" style={{ fontSize: 10, padding: "2px 8px", color: "var(--green)" }}
                          onClick={async () => {
                            const titleToSet = suggestedTitle.startsWith("Copied to clipboard: ") ? suggestedTitle.substring(21) : suggestedTitle;
                            try {
                              await crdt.setWorkTitle(titleToSet);
                              setWorkMeta((m) => m ? { ...m, title: titleToSet } : m);
                              setSuggestedTitle(null);
                            } catch (e) {
                              console.error("Failed to set title:", e);
                            }
                          }}>
                          Use
                        </button>
                        <button type="button" className="llm-result-close" onClick={() => setSuggestedTitle(null)}>Dismiss</button>
                </div>

                {/* Trail links */}
                <div className="ws-conn-section">
                  <div className="ws-conn-header">
                    Trails ({annotations.filter((a) => a.kind === "trail-link").length})
                  </div>
                  {annotations.filter((a) => a.kind === "trail-link").length === 0 ? (
                    <div className="ws-conn-empty">No trail links. Select text and click "+ Trail" to add this passage to a trail.</div>
                  ) : (
                    annotations.filter((a) => a.kind === "trail-link").map((a) => {
                      let trailName = "trail";
                      try {
                        const parsed = JSON.parse(a.payload);
                        trailName = parsed.trail_name || "trail";
                      } catch { /* parse error */ }
                      return (
                        <div
                          key={a.annotation_id}
                          className="ws-conn-item"
                          onClick={() => { setShowTrailsPanel(true); }}
                          title="Open trails panel"
                        >
                          <div className="ws-conn-title">
                            <span style={{ color: "#f97316" }}>{"\u2691"}</span> {trailName}
                          </div>
                          <div className="ws-conn-types">
                            <span className="ws-conn-type-badge" style={{ background: "#f9731620", color: "#f97316", borderColor: "#f9731660" }}>
                              Trail
                            </span>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>
                    <p style={{ fontSize: 16, fontWeight: 600 }}>{suggestedTitle}</p>
                  </div>
                )}
                {tagResult && (
                  <div className="llm-result-panel">
                    <div className="llm-result-header">
                      <span>Tags Applied</span>
                      <button type="button" className="ws-sel-btn" style={{ fontSize: 10, padding: "2px 12px", color: "var(--green)" }} onClick={() => setTagResult(null)}>OK</button>
                    </div>
                    {tagResult.new.length > 0 && (
                      <p style={{ fontSize: 12, color: "var(--green)" }}>
                        Created: {tagResult.new.map(t => t.name).join(", ")}
                      </p>
                    )}
                    {tagResult.linked.length > 0 && (
                      <p style={{ fontSize: 12, color: "var(--text-muted)" }}>
                        Linked: {tagResult.linked.map(t => t.name).join(", ")}
                      </p>
                    )}
                    {tagResult.new.length === 0 && tagResult.linked.length === 0 && (
                      <p style={{ fontSize: 12, color: "var(--text-muted)" }}>(No concepts suggested)</p>
                    )}
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
                        <input
                          type="text"
                          className="link-description-input"
                          placeholder="Description (appears in margin box)..."
                          value={linkDescription}
                          onChange={(e) => setLinkDescription(e.target.value)}
                          style={{
                            background: "rgba(13, 17, 23, 0.9)",
                            border: "1px solid #30363d",
                            borderRadius: 4,
                            color: "#c9d1d9",
                            fontSize: 12,
                            padding: "3px 8px",
                            width: 260,
                            flexShrink: 0,
                          }}
                        />
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
                      onClick={() => { transclusion.clearPendingLink(); setLinkDescription(""); }}
                    >
                      cancel
                    </button>
                  </div>
                )}
                {transclusion.pending && (
                  <TransclusionBadge
                    pending={transclusion.pending}
                    cursorPosition={selectionRange?.start ?? null}
                    onPlace={handlePlaceTransclusion}
                    onPlacePinned={handlePlacePinnedTransclusion}
                    onCancel={transclusion.clearPending}
                    onSwitchWork={selectWork}
                    onPlaceAtEnd={handlePlaceTransclusionAtEnd}
                    recentWorks={works.map((w) => ({ work_id: w.work_id, title: w.title }))}
                  />
                )}
                {remoteViewOverlay}
                <div className="ws-phone-reader">{text || "Loading…"}</div>
                {useMDE ? (
                  <EasyMDEEditor
                    text={text}
                    onTextChange={canEdit ? setText : undefined}
                  editable={canEdit && editorMode === "authoring"}
                  />
                ) : (
                  <CollaborativeEditor
                  text={text}
                  workId={workBeId ?? undefined}
                  onTextChange={canEdit ? setText : undefined}
                  onCursorChange={(idx) => {
                    sendCursor(idx);
                    setCursorPos(idx);
                  }}
                  onSelectionChange={(s, e) => {
                    sendSelection(s, e);
                    if (s !== null && e !== null && s !== e) setSelectionRange({ start: s, end: e });
                    else setSelectionRange(null);
                  }}
                  connected={connected}
                  attributionSpans={resolvedAttributionSpans}
                  showAttributionColors={showProv}
                  editable={canEdit}
                  externalLinksEnabled={externalLinksEnabled}
                  readingMode={editorMode === "reading"}
                  fontSize={14}
                  lineHeight={1.6}
                  transclusionMarkers={transclusion.markers}
                  pendingTransclusion={transclusion.pending}
                  onPlaceTransclusion={handlePlaceTransclusion}
                  onPlacePinnedTransclusion={handlePlacePinnedTransclusion}
                  onNavigateToSource={handleNavigateToSource}
                  selectionRange={selectionRange}
                  highlightRange={highlightRange}
                  onNavigateToWork={selectWork}
                  onCrossServerResolve={async (tumbler, contentHash) => {
                    if (!clientRef.current) return null;
                    try {
                      const result = await clientRef.current.crossServerResolve(tumbler, contentHash);
                      return { text: result.text, hashVerified: result.hashVerified, cached: result.cached };
                    } catch { return null; }
                  }}
                  onTraceProvenance={async (workId, charStart, charEnd) => {
                    if (!clientRef.current) return [];
                    try {
                      return await clientRef.current.workTransclusionChain(workId, charStart, charEnd);
                    } catch { return []; }
                  }}
                  compoundSpanRanges={compound.spanRanges}
                  remoteCursors={awareness}
                  compoundSourceTitles={compound.sourceTitles}
                  inlineResolvedText={compound.resolvedText || undefined}
                  pendingImagePlacement={pendingImage}
                  onPlaceImage={handlePlaceImage}
                  blobEntries={blobEntries}
                  annotations={annotations}
                    onCreateAnnotation={canEdit ? handleCreateAnnotation : undefined}
                    onToggleStyle={canEdit ? handleToggleStyle : undefined}
                    onDeleteAnnotation={deleteAnnotation}
                    showLinkDescriptions={showLinkDesc}
                    onResolveLinkDescription={handleResolveLinkDescription}
                    onEditLinkDescription={handleEditLinkDescription}
                  />
                )}
                  </>
                 )}

                {/* Layout mode: inline images at their char positions */}
                {docMode === "layout" && imageEntries.length > 0 ? (
                  <div className="ws-doc-layout">
                    {(() => {
                      const sortedImages = [...imageEntries].sort((a, b) => (a.charPos ?? 0) - (b.charPos ?? 0));
                      let pos = 0;
                      const parts: Array<ReactNode> = [];
                      for (const img of sortedImages) {
                        const imgPos = img.charPos ?? pos;
                        if (imgPos > pos) {
                          parts.push(<div key={`t-${parts.length}`} className="ws-layout-text">{text.slice(pos, imgPos)}</div>);
                        }
                        const displayWidth = imageSizes.get(img.hash);
                        parts.push(
                          <figure key={`i-${img.hash}`} className="ws-layout-figure">
                            <div className="ws-layout-fig-bar">
                              <span className="ws-layout-fig-dims">
                                {img.width && img.height ? `${img.width}×${img.height}` : "Image"}
                              </span>
                              {canEdit && (
                                <>
                                  <button
                                    className="ws-layout-fig-btn"
                                    title="Move image earlier in document"
                                    onClick={() => handleMoveImage(img.hash, "up")}
                                  >↑</button>
                                  <button
                                    className="ws-layout-fig-btn"
                                    title="Move image later in document"
                                    onClick={() => handleMoveImage(img.hash, "down")}
                                  >↓</button>
                                  <button
                                    className="ws-layout-fig-btn"
                                    title="Crop image"
                                    onClick={() => setCropTarget(cropTarget === String(img.hash) ? null : String(img.hash))}
                                  >Crop</button>
                                </>
                              )}
                              <button
                                className="ws-layout-fig-btn"
                                onClick={async () => {
                                  if (!clientRef.current) return;
                                  const fullBytes = await clientRef.current.blobGet(String(img.hash));
                                  const blob = new Blob([fullBytes as BlobPart], { type: img.mime });
                                  const url = URL.createObjectURL(blob);
                                  window.open(url, "_blank");
                                  setTimeout(() => URL.revokeObjectURL(url), 60000);
                                }}
                              >Full</button>
                            </div>
                            <div
                              className="ws-layout-img-wrap"
                              style={displayWidth ? { width: `${displayWidth}px` } : undefined}
                            >
                              {img.loading ? (
                                <div className="ws-image-loading">Loading…</div>
                              ) : img.url ? (
                                cropTarget === String(img.hash) && img.width && img.height ? (
                                  <CropOverlay
                                    src={img.url}
                                    natW={img.width}
                                    natH={img.height}
                                    onApply={(x, y, w, h) => {
                                      void handleCropImage(img.hash, x, y, w, h);
                                      setCropTarget(null);
                                    }}
                                    onCancel={() => setCropTarget(null)}
                                  />
                                ) : (
                                  <img
                                    src={img.url}
                                    alt={img.caption || ""}
                                    className="ws-layout-img"
                                    onClick={() => setLightboxHash(String(img.hash))}
                                  />
                                )
                              ) : (
                                <div className="ws-image-error">Failed to load</div>
                              )}
                              {cropTarget !== String(img.hash) && (
                                <div
                                  className="ws-resize-handle"
                                  onMouseDown={(e) => {
                                    e.preventDefault();
                                    const startX = e.clientX;
                                    const startWidth = displayWidth || e.currentTarget.parentElement?.offsetWidth || 600;
                                    const onMove = (ev: MouseEvent) => {
                                      const delta = ev.clientX - startX;
                                      const newWidth = Math.max(120, Math.min(startWidth + delta, 1400));
                                      setImageSizes((prev) => new Map(prev).set(img.hash, newWidth));
                                    };
                                    const onUp = () => {
                                      document.removeEventListener("mousemove", onMove);
                                      document.removeEventListener("mouseup", onUp);
                                    };
                                    document.addEventListener("mousemove", onMove);
                                    document.addEventListener("mouseup", onUp);
                                  }}
                  />
                )}
                {pendingImage && (
                  <div className="ws-transclusion-badge" style={{ background: "rgba(88, 166, 255, 0.12)", borderColor: "var(--accent-blue)" }}>
                    <span className="ws-transclusion-badge-icon">{"\u{1F5BC}"}</span>
                    <span className="ws-transclusion-badge-text">
                      Image ready — <strong>click in the document</strong> to place it
                    </span>
                    <button
                      className="ws-transclusion-badge-cancel"
                      onClick={() => setPendingImage(null)}
                    >
                      {"\u00d7"}
                    </button>
                  </div>
                )}
                            </div>
                            <figcaption className="ws-layout-fig-caption">
                              <input
                                type="text"
                                placeholder="Add caption…"
                                defaultValue={img.caption || ""}
                                onBlur={(e) => {
                                  setImageEntries((prev) => prev.map((e2) => e2.hash === img.hash ? { ...e2, caption: e.target.value } : e2));
                                  if (canEdit) void handleCaptionChange(img.hash, e.target.value);
                                }}
                              />
                            </figcaption>
                          </figure>
                        );
                        pos = imgPos;
                      }
                      if (pos < text.length) {
                        parts.push(<div key={`t-${parts.length}`} className="ws-layout-text">{text.slice(pos)}</div>);
                      }
                      return parts;
                    })()}
                  </div>
                ) : (
                  <>
                {/* Inline image rendering (below editor in edit mode) */}
                {imageEntries.length > 0 && (
                  <div className="ws-doc-images">
                    {imageEntries.map((img) => (
                      <div key={img.hash} className="ws-doc-image-block">
                        <div className="ws-doc-image-controls">
                          <span className="ws-doc-image-info">
                            {img.width && img.height ? `${img.width}×${img.height}` : "Image"}
                            {img.charPos != null ? ` · at char ${img.charPos}` : ""}
                          </span>
                          <button
                            className="ws-doc-image-action"
                            onClick={async () => {
                              if (!clientRef.current) return;
                              const fullBytes = await clientRef.current.blobGet(String(img.hash));
                              const blob = new Blob([fullBytes as BlobPart], { type: img.mime });
                              const url = URL.createObjectURL(blob);
                              window.open(url, "_blank");
                              setTimeout(() => URL.revokeObjectURL(url), 60000);
                            }}
                            title="View full size"
                          >
                            Full size
                          </button>
                        </div>
                        {img.loading ? (
                          <div className="ws-image-loading">Loading…</div>
                        ) : img.url ? (
                          <img
                            src={img.url}
                            alt=""
                            className="ws-doc-image"
                            style={{
                              maxWidth: "100%",
                              borderRadius: "6px",
                              cursor: "pointer",
                              display: "block",
                            }}
                            onClick={() => setLightboxHash(String(img.hash))}
                          />
                        ) : (
                          <div className="ws-image-error">Failed to load</div>
                        )}
                        <input
                          type="text"
                          className="ws-doc-image-caption"
                          placeholder="Add caption…"
                          defaultValue={img.caption || ""}
                          onBlur={(e) => {
                            setImageEntries((prev) => prev.map((e2) => e2.hash === img.hash ? { ...e2, caption: e.target.value } : e2));
                            if (canEdit) void handleCaptionChange(img.hash, e.target.value);
                          }}
                        />
                      </div>
                    ))}
                  </div>
                )}
                  </>
                )}
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
                          const txt = ta?.value.trim() ?? "";
                          if (!txt) {
                            ta?.focus();
                            return;
                          }
                          void handleAnnotationSubmit(txt, cb?.checked ?? false);
                        }}
                      >
                        Save
                      </button>
                      <button className="ws-anno-cancel" onClick={() => setAnnotationTarget(null)}>
                        Cancel
                      </button>
                    </div>
                </div>

                  {/* Where is this used? (backfollow) */}
                  {(
                    <div className="ws-conn-section">
                      <div className="ws-conn-header" style={{ flexDirection: "row", justifyContent: "space-between" }}>
                        <span>Where is this used?</span>
                        <button
                          className="ws-concept-add-btn"
                          style={{ fontSize: 10 }}
                          disabled={whereUsedLoading}
                          onClick={async () => {
                            if (!clientRef.current || workBeId === null) return;
                            setWhereUsedLoading(true);
                            setWhereUsed(null);
                            try {
                              const result = await clientRef.current.rangeTranscluders(workBeId);
                              setWhereUsed(result);
                            } catch { setWhereUsed(null); }
                            setWhereUsedLoading(false);
                          }}
                        >
                          {whereUsedLoading ? "..." : whereUsed ? "↻" : "Find"}
                        </button>
                      </div>
                      {whereUsedLoading ? (
                        <div className="ws-conn-empty">Searching...</div>
                      ) : whereUsed === null ? (
                        <div className="ws-conn-empty">Click "Find" to search for documents that reuse this work's content.</div>
                      ) : whereUsed.work_ids.length === 0 ? (
                        <div className="ws-conn-empty">Not reused in any other documents.</div>
                      ) : (
                        whereUsed.work_ids.map((wid, i) => {
                          const w = works.find((x) => x.work_id === wid);
                          const title = w?.title || `Work 0x${wid.toString(16)}`;
                          return (
                            <div key={i} className="ws-conn-item" onClick={() => selectWork(wid)}>
                              <div className="ws-conn-title">↗ {title}</div>
                              <div className="ws-conn-excerpt">Reuses content from this work</div>
                            </div>
                          );
                        })
                      )}
                    </div>
                  )}

                  {/* Provenance chain */}
                  {(
                    <div className="ws-conn-section">
                      <div className="ws-conn-header" style={{ flexDirection: "row", justifyContent: "space-between" }}>
                        <span>Provenance chain</span>
                        <button
                          className="ws-concept-add-btn"
                          style={{ fontSize: 10 }}
                          disabled={provenanceLoading}
                          onClick={async () => {
                            if (!clientRef.current || workBeId === null) return;
                            setProvenanceLoading(true);
                            setProvenanceChain(null);
                            try {
                              const chain = await clientRef.current.workTransclusionChain(workBeId, 0, 0);
                              setProvenanceChain(chain);
                            } catch { setProvenanceChain(null); }
                            setProvenanceLoading(false);
                          }}
                        >
                          {provenanceLoading ? "..." : provenanceChain ? "↻" : "Trace"}
                        </button>
                      </div>
                      {provenanceLoading ? (
                        <div className="ws-conn-empty">Tracing provenance...</div>
                      ) : provenanceChain === null ? (
                        <div className="ws-conn-empty">Click "Trace" to trace where this work's content originated.</div>
                      ) : provenanceChain.length === 0 ? (
                        <div className="ws-conn-empty">Original content — no transclusion source.</div>
                      ) : (
                        provenanceChain.map((hop, i) => (
                          <div key={i} className="ws-conn-item" onClick={() => selectWork(hop.work_id)}>
                            <div className="ws-conn-title" style={{ display: "flex", alignItems: "center", gap: 4 }}>
                              <span style={{ fontSize: 10, color: "#8b949e", fontFamily: "monospace" }}>{i + 1}.</span>
                              {hop.work_title || `Work 0x${hop.work_id.toString(16)}`}
                              {hop.is_original && (
                                <span style={{ fontSize: 9, color: "#3fb950", fontWeight: 600 }}>ORIGINAL</span>
                              )}
                            </div>
                            {hop.author_name && (
                              <div className="ws-conn-excerpt">by {hop.author_name}{hop.author_type ? ` (${hop.author_type})` : ""}</div>
                            )}
                            {hop.element_text && (
                              <div className="ws-conn-excerpt" style={{ fontStyle: "italic", maxHeight: 40, overflow: "hidden" }}>
                                "{hop.element_text.slice(0, 80)}{hop.element_text.length > 80 ? "..." : ""}"
                              </div>
                            )}
                          </div>
                        ))
                      )}
                    </div>
                  )}
              </div>
            )}
            </>
          )}
          {workBeId !== null && (
            <RelatedFooter
              annotations={annotations}
              onDeleteAnnotation={deleteAnnotation}
              onJumpToSpan={(start, end) => {
                setHighlightRange({ start, end });
                setTimeout(() => setHighlightRange(null), 4000);
              }}
              backlinks={transclusion.backlinks}
              outgoingLinks={transclusion.links}
              compoundSpanRanges={compound.spanRanges}
              compoundSourceTitles={compound.sourceTitles}
              crossServerBacklinks={crossServerBacklinks}
              currentWorkId={workBeId}
              cursorPosition={cursorPos}
              onNavigateToWork={selectWork}
            />
          )}
        </main>

        {/* Right panel */}
        <aside
          className={`ws-right-panel ${rightPanelHidden ? "hidden" : ""} ${isTablet && openDrawer === "right" ? "drawer-open" : ""}`}
          data-drawer="right"
        >
          <div className="ws-tabs">
            {([
              ["provenance", "Attribution"],
              ["connections", "Links"],
              ["trails", "Trails"],
              ["timeline", "History"],
              ["servers", "Servers"],
              ["compare", "Compare"],
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
            {isTablet && (
              <button
                className="ws-drawer-close"
                onClick={() => setOpenDrawer(null)}
                title="Close panel"
              >
                ×
              </button>
            )}
          </div>
          <div className="ws-tab-content">
            {rightPanelBody}
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

      {/* Floating "show panel" buttons when hidden (desktop) and the
          drawer openers (tablet/phone: panels are overlays, the float
          buttons are the always-present way in). */}
      {isTablet ? (
        <>
          <button
            className="ws-float-show ws-float-left"
            onClick={() => setOpenDrawer(openDrawer === "left" ? null : "left")}
            title={openDrawer === "left" ? "Close panels" : "Graph / Outline"}
          >
            {openDrawer === "left" ? "‹" : "›"}
          </button>
          <button
            className="ws-float-show ws-float-right"
            onClick={() => setOpenDrawer(openDrawer === "right" ? null : "right")}
            title={openDrawer === "right" ? "Close panels" : "Connections / Attribution"}
          >
            {openDrawer === "right" ? "›" : "‹"}
          </button>
        </>
      ) : (
        <>
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
        </>
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
              onChangePassword={changePassword}
              onLogout={logout}
              llmEnabled={crdt.llmEnabled}
              llmUsage={crdt.llmUsage}
              oauthProviders={oauthProviders}
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

      <div style={{ display: showAdmin ? "block" : "none" }}>
        <AdminDashboard
          onClose={() => setShowAdmin(false)}
          client={connected ? clientRef.current : null}
          isAdmin={isAdmin}
          works={works}
          onNavigateToWork={(id) => { setShowAdmin(false); selectWork(id); }}
        />
      </div>

      {transclusion.pendingLink && (
        <LinkCreator
          open={!!transclusion.pendingLink}
          onClose={() => transclusion.clearPendingLink()}
          source={{
            workId: transclusion.pendingLink.sourceWorkId,
            workTitle: transclusion.pendingLink.sourceWorkTitle,
            start: transclusion.pendingLink.start,
            end: transclusion.pendingLink.end,
            text: transclusion.pendingLink.text,
          }}
          works={works}
          currentWorkId={workBeId}
          clientRef={clientRef}
          onLinkCreated={() => {
            transclusion.clearPendingLink();
            // Always reload links so colored underlines appear immediately
            if (clientRef.current && workBeId !== null) {
              void loadLinks(clientRef.current, workBeId, works);
            }
          }}
          onSelectTextInOtherDoc={() => {}}
        />
      )}

      {toast && (
        <div className="ws-toast" onClick={() => setToast(null)}>
          {toast}
          <span className="ws-toast-close">×</span>
        </div>
      )}

      {showUndoToast && (
        <div className="ws-toast" style={{ cursor: "default" }}>
          Transclusion placed
          <button
            type="button"
            onClick={async () => {
              const ok = await compound.undoLastInsert();
              setShowUndoToast(false);
              if (ok) showToast("Transclusion removed");
            }}
            style={{
              background: "rgba(255,255,255,0.2)",
              border: "1px solid rgba(255,255,255,0.4)",
              borderRadius: 4,
              padding: "2px 10px",
              color: "#fff",
              fontSize: 12,
              cursor: "pointer",
              marginLeft: 8,
            }}
          >
            Undo
          </button>
          <span className="ws-toast-close" onClick={() => setShowUndoToast(false)}>×</span>
        </div>
      )}

      {showImport && (
        <ImportWizard
          clientRef={clientRef}
          visible={true}
          initialText={importText}
          onImported={(workId) => {
            setShowImport(false);
            setImportText(undefined);
            selectWork(workId);
          }}
          onClose={() => {
            setShowImport(false);
            setImportText(undefined);
          }}
        />
      )}

      {showTrailsPanel && (
        <TrailsPanel
          client={connected ? clientRef.current : null}
          currentWorkId={workBeId}
          works={works}
          onSelectWork={selectWork}
          onStartTrail={startTrail}
          onClose={() => {
            setShowTrailsPanel(false);
            if (rightPanelTab === "trails") void loadTrailsForWork();
          }}
        />
      )}

      {/* Trail follow bar: persistent Next/Prev while following a trail */}
      {followTrail && (
        <div
          style={{
            position: "fixed",
            bottom: 16,
            left: "50%",
            transform: "translateX(-50%)",
            zIndex: 300,
            display: "flex",
            alignItems: "center",
            gap: 10,
            background: "var(--bg-elevated, #21262d)",
            border: "1px solid var(--accent-blue, #58a6ff)",
            borderRadius: 8,
            padding: "8px 14px",
            boxShadow: "0 4px 16px rgba(0,0,0,0.4)",
            maxWidth: "90vw",
          }}
        >
          <span style={{ fontWeight: 600, fontSize: 13 }}>
            {followTrail.name}
          </span>
          <span style={{ fontSize: 11, opacity: 0.75 }}>
            stop {followIndex + 1} / {followTrail.stops.length}
          </span>
          {followTrail.stops[followIndex]?.note && (
            <span style={{ fontSize: 11, opacity: 0.9, maxWidth: 300, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }} title={followTrail.stops[followIndex].note ?? undefined}>
              {followTrail.stops[followIndex].note}
            </span>
          )}
          <button type="button" className="ws-action-btn" onClick={followPrev} disabled={followIndex === 0} title="Previous stop">
            ‹ Prev
          </button>
          <button
            type="button"
            className="ws-action-btn"
            style={{ borderColor: "var(--accent-blue, #58a6ff)", color: "var(--accent-blue, #58a6ff)" }}
            onClick={followNext}
            title={followIndex + 1 >= followTrail.stops.length ? "Finish trail" : "Next stop"}
          >
            {followIndex + 1 >= followTrail.stops.length ? "Finish ✓" : "Next ›"}
          </button>
          <button type="button" className="ws-action-btn" onClick={stopFollowing} title="Stop following this trail">
            ×
          </button>
        </div>
      )}

      {licenseHelpOpen && (
        <div className="modal-overlay" onClick={() => setLicenseHelpOpen(false)}>
          <div className="modal-content ws-license-help" onClick={(e) => e.stopPropagation()}>
            <h3>Which license should I choose?</h3>
            <p className="ws-license-help-intro">
              This sets the license for <strong>this work only</strong>. Other works are unaffected.
              You can change it at any time — past transclusions keep the license they had.
            </p>
            <table className="ws-license-table">
              <thead>
                <tr>
                  <th>License</th>
                  <th>Transclude?</th>
                  <th>Copy?</th>
                  <th>Attribution?</th>
                  <th>Commercial?</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><strong>© All Rights Reserved</strong></td>
                  <td>No</td>
                  <td>No</td>
                  <td>—</td>
                  <td>—</td>
                </tr>
                <tr>
                  <td><strong>TCo Transcopyright</strong></td>
                  <td>Yes (by address)</td>
                  <td>No</td>
                  <td>Automatic</td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td><strong>CC-BY</strong></td>
                  <td>Yes</td>
                  <td>Yes</td>
                  <td>Required</td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td><strong>CC-BY-SA</strong></td>
                  <td>Yes</td>
                  <td>Yes (must share alike)</td>
                  <td>Required</td>
                  <td>Yes</td>
                </tr>
                <tr>
                  <td><strong>CC0 Public Domain</strong></td>
                  <td>Yes</td>
                  <td>Yes</td>
                  <td>Not required</td>
                  <td>Yes</td>
                </tr>
              </tbody>
            </table>
            <div className="ws-license-help-notes">
              <p><strong>Transcopyright (TCo)</strong> is designed for transclusion-based systems like Xudanu.
              Others can reference your content by address, but it always stays connected to your server.
              Attribution is automatic. This is Xudanu's recommended license for collaborative content.</p>
              <p><strong>CC-BY-SA</strong> requires that anyone who builds on your work must use the same license.
              This prevents mixing with differently-licensed content.</p>
              <p><strong>CC0</strong> waives all rights. Anyone can do anything with your content, without asking.</p>
            </div>
            <div className="ws-license-help-actions">
              <button className="ws-anno-cancel" onClick={() => setLicenseHelpOpen(false)}>Close</button>
            </div>
          </div>
        </div>
      )}

      {lightboxHash !== null && (
        <div
          className="ws-image-lightbox"
          onClick={() => setLightboxHash(null)}
        >
          {(() => {
            const img = imageEntries.find((e) => e.hash === lightboxHash || String(e.hash) === lightboxHash);
            if (!img || !img.url) return null;
            return (
              <>
                <img src={img.url} alt={img.caption || ""} />
                <div className="ws-image-lightbox-bar">
                  <span>{img.width && img.height ? `${img.width}×${img.height}` : "Image"}</span>
                  {img.caption && <span className="ws-image-lightbox-caption">{img.caption}</span>}
                  <button
                    className="ws-image-lightbox-full"
                    onClick={async (e) => {
                      e.stopPropagation();
                      if (!clientRef.current) return;
                      const fullBytes = await clientRef.current.blobGet(String(img.hash));
                      const blob = new Blob([fullBytes as BlobPart], { type: img.mime });
                      const url = URL.createObjectURL(blob);
                      window.open(url, "_blank");
                      setTimeout(() => URL.revokeObjectURL(url), 60000);
                    }}
                  >
                    Open full
                  </button>
                  <button onClick={(e) => { e.stopPropagation(); setLightboxHash(null); }}>Close</button>
                </div>
              </>
            );
          })()}
        </div>
      )}
      {searchOpen && (
        <SearchOverlay
          onClose={() => setSearchOpen(false)}
          clientRef={clientRef}
          currentWorkId={workBeId}
          works={works}
          onSelectWork={(id) => { selectWork(id); setSearchOpen(false); }}
          serverDirectory={serverDirectoryForSearch}
          onViewRemoteWork={(data) => {
            setRemoteView(data);
            setRightPanelTab("provenance");
            setSearchOpen(false);
          }}
        />
      )}
      {showSettings && (
        <DocumentSettings
          visible={true}
          prefs={docPrefs}
          onPrefsChange={setDocPrefs}
          onClose={() => setShowSettings(false)}
          networkEnabled={networkEnabled}
          externalLinksEnabled={externalLinksEnabled}
          isAdmin={isAdmin}
          onSetNetworkEnabled={async (enabled) => {
            if (!clientRef.current) return;
            try {
              await clientRef.current.sendRequest("network_set_enabled", { enabled });
              setNetworkEnabled(enabled);
              showToast(enabled ? "Xudanu network enabled" : "Xudanu network disabled — single-player mode");
            } catch (e) {
              showToast(`Could not change network setting: ${e instanceof Error ? e.message : String(e)}`);
            }
          }}
          onSetExternalLinksEnabled={async (enabled) => {
            if (!clientRef.current) return;
            try {
              await clientRef.current.sendRequest("external_links_set_enabled", { enabled });
              setExternalLinksEnabled(enabled);
              showToast(enabled ? "External links enabled" : "External links disabled — only xudanu links are clickable");
            } catch (e) {
              showToast(`Could not change link setting: ${e instanceof Error ? e.message : String(e)}`);
            }
          }}
        />
      )}
      {compareFullscreen && (
        <MultiEndCompare
          workIds={multiCompareWorkIds}
          works={works}
          clientRef={clientRef}
          currentWorkId={workBeId}
          onPickWork={(id) => setMultiCompareWorkIds((prev) => [...prev, id])}
          onClose={() => setCompareFullscreen(false)}
          fullscreen
          onRemoveWork={(id) => setMultiCompareWorkIds((prev) => prev.filter((p) => p !== id))}
        />
      )}
      {showPerspective && workBeId !== null && (
        <PerspectiveView
          centerWorkId={workBeId}
          centerText={text}
          centerTitle={workMeta?.title || `Work 0x${workBeId.toString(16)}`}
          links={transclusion.links}
          works={works}
          onClose={() => setShowPerspective(false)}
          onNavigateToWork={selectWork}
          onFetchWorkText={async (workId) => {
            if (!clientRef.current) return null;
            try {
              const resp = await clientRef.current.sendRequest("crdt_sync_open", { work_id: workId });
              const r = resp as Record<string, unknown>;
              const inner = (r.value as Record<string, unknown> | undefined) ?? r;
              return (inner?.current_text as string) || null;
            } catch { return null; }
          }}
        />
      )}
      {showCompoundBuilder && workBeId !== null && (
        <CompoundBuilder
          centerWorkId={workBeId}
          centerText={text}
          centerTitle={workMeta?.title || `Work 0x${workBeId.toString(16)}`}
          compoundSpanRanges={compound.spanRanges}
          compoundSourceTitles={compound.sourceTitles}
          works={works}
          client={clientRef.current}
          identity={identity}
          authenticated={authenticated}
          onClose={() => { setShowCompoundBuilder(false); if (navTab === "compose") setNavTab("explore"); }}
          onPlaceTransclusion={(sourceWorkId, sourceWorkTitle, start, end, txt) => {
            transclusion.holdSelection(sourceWorkId, sourceWorkTitle, start, end, txt);
            handlePlaceTransclusion(text.length).then(() => {
              if (clientRef.current && workBeId !== null) {
                clientRef.current.migrateCompoundToInline(workBeId).then(() => {
                  compound.reload();
                }).catch(() => {});
              }
            });
          }}
          onReloadCompound={() => compound.reload()}
          onRemoveSpan={compound.removeTransclusion}
        />
      )}
      {showMerge && workBeId !== null && (
        <MergePanel
          client={clientRef.current}
          currentWorkId={workBeId}
          works={works}
          onClose={() => setShowMerge(false)}
          onMerged={(newWorkId) => { setShowMerge(false); selectWork(newWorkId); }}
        />
      )}
      {isTablet && openDrawer !== null && (
        <div
          className="ws-drawer-backdrop"
          onClick={() => setOpenDrawer(null)}
          aria-hidden="true"
        />
      )}

      {isPhone && (
        <>
          {sheetOpen && (
            <div
              className="ws-sheet-backdrop"
              onClick={() => setSheetOpen(false)}
              aria-hidden="true"
            />
          )}
          <div className={`ws-bottom-sheet ${sheetOpen ? "open" : ""}`} role="dialog" aria-label="Panels">
            <div className="ws-sheet-grab" onClick={() => setSheetOpen(false)} title="Close" />
            <div className="ws-sheet-body">
              <div className="ws-tabs">
                {([
                  ["provenance", "Attribution"],
                  ["connections", "Links"],
                  ["trails", "Trails"],
                  ["timeline", "History"],
                  ["compare", "Compare"],
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
              <div className="ws-sheet-content">{rightPanelBody}</div>
            </div>
          </div>
          <MobileBottomNav
            activeNav={navTab}
            onNavChange={setNavTab}
            onOpenPanels={() => setSheetOpen((v) => !v)}
            panelsOpen={sheetOpen}
          />
        </>
      )}
      <ConnectionOverlay connected={connected} reconnectAttempt={reconnectAttempt} />
    </div>
  );
}

