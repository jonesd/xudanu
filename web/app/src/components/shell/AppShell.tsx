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
import type { WorkListEntry, CrossServerBacklinkPayload } from "../../api/crdt_sync";
import { TopBar } from "./TopBar";
import { LeftRail } from "./LeftRail";
import { BottomBar } from "./BottomBar";
import { ContextPanel } from "./ContextPanel";
import { LibrarySlideOut } from "./LibrarySlideOut";
import { SearchOverlay } from "./SearchOverlay";
import { PermissionBadge } from "./PermissionBadge";
import { RelatedFooter } from "../RelatedFooter";
import { PerspectiveView } from "../PerspectiveView";
import { CompoundBuilder } from "../CompoundBuilder";
import { useCompare, CompareHeader, CompareSplitView } from "../ComparePanel";
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
  const [showLinkDesc, setShowLinkDescRaw] = useState(() => {
    try { return localStorage.getItem("xudanu_showLinkDesc") !== "false"; }
    catch { return true; }
  });
  const setShowLinkDesc = useCallback((updater: boolean | ((prev: boolean) => boolean)) => {
    setShowLinkDescRaw((prev) => {
      const next = typeof updater === "function" ? updater(prev) : updater;
      try { localStorage.setItem("xudanu_showLinkDesc", String(next)); } catch {}
      return next;
    });
  }, []);
  const [linkDescription, setLinkDescription] = useState("");
  const [showCompare, setShowCompare] = useState(false);
  const [showPerspective, setShowPerspective] = useState(false);
  const [showCompoundBuilder, setShowCompoundBuilder] = useState(false);
  const [crossServerBacklinks, setCrossServerBacklinks] = useState<CrossServerBacklinkPayload[]>([]);
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
  const compare = useCompare(showCompare, workBeId, text, connected ? clientRef.current : null);

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
    }, 30000);
    return () => clearInterval(interval);
  }, [connected, loadWorks]);

  const loadTransclusionLinks = transclusion.loadLinks;
  const loadBacklinks = transclusion.loadBacklinks;
  const clearOnWorkSwitch = transclusion.clearOnWorkSwitch;
  const loadLinkTypes = transclusion.loadLinkTypes;

  useEffect(() => {
    clearOnWorkSwitch();
  }, [workBeId, clearOnWorkSwitch]);

  useEffect(() => {
    if (connected && workBeId !== null && clientRef.current) {
      refreshAttribution();
      refreshAnnotations();
      clientRef.current.crossServerBacklinksGet(workBeId).then(setCrossServerBacklinks).catch(() => setCrossServerBacklinks([]));
      loadTransclusionLinks(clientRef.current, workBeId, works);
      loadBacklinks(clientRef.current, workBeId);
    }
  }, [connected, workBeId, works, loadTransclusionLinks, loadBacklinks, refreshAttribution, refreshAnnotations]);

  useEffect(() => {
    if (!connected || workBeId === null) return;
    const timer = setTimeout(() => {
      refreshAnnotations();
      refreshAttribution();
    }, 2000);
    return () => clearTimeout(timer);
  }, [connected, workBeId, refreshAnnotations, refreshAttribution]);

  useEffect(() => {
    if (!connected || workBeId === null || !clientRef.current) return;
    const handler = setTimeout(() => {
      loadTransclusionLinks(clientRef.current!, workBeId!, works);
    }, 500);
    return () => clearTimeout(handler);
  }, [text, connected, workBeId, works, loadTransclusionLinks]);

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

  const handleCreateDemo = useCallback(async () => {
    if (!clientRef.current) return;
    if (!identity) {
      setShowIdentity(true);
      return;
    }

    const demoText = [
      "Welcome to Xudanu",
      "",
      "This interactive demo document shows the key features of the system.",
      "Each concept below is connected to others through typed links.",
      "",
      "Typed Links",
      "Typed links connect passages with coloured margin boxes.",
      "Each type has a specific meaning: Comment, Reference, Disagreement, Quotation, See Also.",
      "Hover over the margin bars to see descriptions. Click Show Links to toggle boxes.",
      "",
      "Transclusion",
      "Content can be reused across documents while maintaining its provenance.",
      "When you transclude a passage, the original author is always credited.",
      "",
      "Provenance and Attribution",
      "Every character carries cryptographic provenance via Ed25519 signatures.",
      "Click Show Prov to see attribution spans and derivation chains.",
      "",
      "Comparison View",
      "The comparison view shows shared passages between documents with bezier connections.",
      "Click Compare in the toolbar to explore side-by-side and diff views.",
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
      if (!clientRef.current) return;
      const resp = await clientRef.current.sendRequest("work_create", { edition: { text: demoText } });
      const demoId = (resp as any)?.value?.value ?? (resp as any)?.value;
      if (typeof demoId !== "number") return;

      try { await clientRef.current.workPublish(demoId); } catch {}
      selectWork(demoId);
      loadWorks();
      setShowLinkDesc(true);
      setShowProvenance(true);

      await new Promise(resolve => setTimeout(resolve, 2000));

      const client = clientRef.current;
      if (!client) return;

      const lines = demoText.split("\n");
      const findPos = (lineIdx: number, phrase: string): { start: number; end: number } => {
        let pos = 0;
        for (let i = 0; i < lineIdx; i++) pos += lines[i].length + 1;
        const lineText = lines[lineIdx];
        const rel = lineText.indexOf(phrase);
        if (rel === -1) return { start: pos, end: pos + phrase.length };
        return { start: pos + rel, end: pos + rel + phrase.length };
      };

      const links: Array<{ srcLine: number; srcPhrase: string; dstLine: number; dstPhrase: string; type: number; desc: string }> = [
        { srcLine: 6, srcPhrase: "Typed links connect passages with coloured margin boxes.", dstLine: 10, dstPhrase: "Content can be reused across documents", type: 5, desc: "See Also: transclusion is another way to connect content" },
        { srcLine: 7, srcPhrase: "Each type has a specific meaning", dstLine: 15, dstPhrase: "Every character carries cryptographic provenance", type: 2, desc: "Reference: provenance is a core principle that underpins all link types" },
        { srcLine: 8, srcPhrase: "Click Show Links to toggle boxes.", dstLine: 18, dstPhrase: "The comparison view shows shared passages", type: 1, desc: "Comment: the Compare button is another toolbar feature worth exploring" },
        { srcLine: 23, srcPhrase: "Changes merge automatically using the O-tree CRDT", dstLine: 6, dstPhrase: "Typed links connect passages", type: 3, desc: "Disagreement: CRDT editing trades deep versioning for concurrency — unlike the original Xanadu model" },
        { srcLine: 10, srcPhrase: "the original author is always credited", dstLine: 14, dstPhrase: "Every character carries cryptographic provenance", type: 4, desc: "Quotation: this principle is guaranteed by the attribution system" },
      ];

      let annId = Date.now();
      for (const link of links) {
        try {
          const srcPos = findPos(link.srcLine, link.srcPhrase);
          const dstPos = findPos(link.dstLine, link.dstPhrase);
          const linkId = await client.linkCreate(
            demoId, demoId,
            { excerpt: link.srcPhrase, start: srcPos.start, end: srcPos.end },
            { excerpt: link.dstPhrase, start: dstPos.start, end: dstPos.end },
          );
          await client.linkSetTypes(linkId, [link.type]);
          if (link.desc) {
            await client.annotationCreate(
              demoId, annId++,
              "link-description",
              JSON.stringify({ link_id: linkId, text: link.desc }),
              srcPos.start, srcPos.end,
            );
          }
        } catch (e) {
          console.warn("[demo] link creation failed:", e);
        }
      }

      const boldTitles = [0, 6, 10, 14, 18, 22, 26];
      for (const lineIdx of boldTitles) {
        const pos = findPos(lineIdx, lines[lineIdx]);
        try {
          await client.annotationCreate(demoId, annId++, "bold", "", pos.start, pos.end);
        } catch {}
      }

      const italicPhrases: Array<{ line: number; phrase: string }> = [
        { line: 7, phrase: "Comment, Reference, Disagreement, Quotation, See Also" },
        { line: 11, phrase: "the original author is always credited" },
        { line: 15, phrase: "Ed25519 signatures" },
        { line: 19, phrase: "bezier connections" },
        { line: 23, phrase: "O-tree CRDT" },
        { line: 27, phrase: "BLAKE3 hash verification" },
      ];
      for (const { line, phrase } of italicPhrases) {
        const pos = findPos(line, phrase);
        try {
          await client.annotationCreate(demoId, annId++, "italic", "", pos.start, pos.end);
        } catch {}
      }

      await refreshAnnotations();
      await transclusion.loadLinks(client, demoId, works);
      refreshAttribution();

    } catch (e) {
      const err = e as Error;
      console.error("[demo] Failed:", err);
      alert("Failed to create demo: " + (err.message || "unknown error"));
    }
  }, [createWork, selectWork, loadWorks, setShowLinkDesc, setShowProvenance, identity, refreshAnnotations, transclusion, works]);

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
      const linkId = await transclusion.placeTransclusion(clientRef.current, workBeId, spanStart);
      if (linkId !== null && clientRef.current) {
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
    await transclusion.loadLinks(clientRef.current, workBeId, works);
    await transclusion.loadBacklinks(clientRef.current, workBeId);
    refreshAnnotations();
  }, [clientRef, workBeId, transclusion, works, refreshAnnotations]);

  const handleDeleteLink = useCallback(async (linkId: number) => {
    if (!clientRef.current || workBeId === null) return;
    await transclusion.deleteLink(clientRef.current, linkId);
    await Promise.all([
      transclusion.loadLinks(clientRef.current, workBeId, works),
      transclusion.loadBacklinks(clientRef.current, workBeId),
    ]);
  }, [clientRef, workBeId, transclusion, works]);

  const handleRetypeLink = useCallback(async (linkId: number, typeId: number) => {
    if (!clientRef.current || workBeId === null) return;
    try {
      await clientRef.current.linkSetTypes(linkId, [typeId]);
      await transclusion.loadLinks(clientRef.current, workBeId, works);
    } catch (e) {
      console.error("Failed to retype link:", e);
    }
  }, [clientRef, workBeId, transclusion, works]);

  const handleResolveLinkDescription = useCallback(async (linkId: number, resolved: boolean) => {
    if (workBeId === null) return;
    const existing = annotations.find((a) => {
      if (a.kind !== "link-description" && a.kind !== "link-description-resolved") return false;
      try {
        const parsed = JSON.parse(a.payload);
        return parsed.link_id === linkId;
      } catch { return false; }
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
      try {
        const parsed = JSON.parse(a.payload);
        return parsed.link_id === linkId;
      } catch { return false; }
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

  const handleToggleStar = useCallback(
    async (workId: number, current: boolean) => {
      if (!clientRef.current) return;
      try {
        if (current) await clientRef.current.workUnstar(workId);
        else await clientRef.current.workStar(workId);
        setWorks((prev) => prev.map((w) => w.work_id === workId ? { ...w, is_starred: !current } : w));
      } catch (e) {
        console.error("Failed to toggle star:", e);
      }
    },
    [clientRef],
  );

  const handleCrossServerResolve = useCallback(
    async (tumbler: string, contentHash: string) => {
      if (!clientRef.current) return null;
      try {
        return await clientRef.current.crossServerResolve(tumbler, contentHash);
      } catch (e) {
        console.error("Cross-server resolve failed:", e);
        return null;
      }
    },
    [clientRef],
  );

  const handleTraceProvenance = useCallback(
    async (workId: number, charStart: number, charEnd: number) => {
      if (!clientRef.current) return [];
      try {
        return await clientRef.current.workTransclusionChain(workId, charStart, charEnd);
      } catch (e) {
        console.error("Provenance trace failed:", e);
        return [];
      }
    },
    [clientRef],
  );

  const handleCopyReference = useCallback(async () => {
    if (workBeId === null) return;
    try {
      const resp = await fetch(`/api/public/work/${workBeId.toString(16).padStart(4, "0")}`);
      const data = await resp.json();
      const hash = data.content_hash_blake3;
      const addr = window.location.host;
      const tumbler = `"${addr}".${workBeId.toString(16).padStart(4, "0")}.1.0.0`;
      const ref = `${tumbler}|${hash}`;
      await navigator.clipboard.writeText(ref);
      setPublishError("Reference copied! Paste on another server.");
      setTimeout(() => setPublishError(null), 3000);
    } catch (e) {
      setPublishError("Failed to copy reference");
      setTimeout(() => setPublishError(null), 3000);
    }
  }, [workBeId]);

  const handleToggleStyle = useCallback(
    async (kind: string, start: number, end: number) => {
      if (!clientRef.current || workBeId === null) return;
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
    [clientRef, workBeId, annotations, deleteAnnotation, createAnnotation],
  );

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
      const sourceStart = transclusion.pendingLink?.start ?? selectionRange.start;
      const sourceEnd = transclusion.pendingLink?.end ?? selectionRange.end;
      const linkId = await transclusion.createContentLink(
        clientRef.current,
        workBeId,
        selectionRange.start,
        selectionRange.end,
        targetText,
        typeId,
      );
      if (linkId !== null && clientRef.current) {
        if (linkDescription.trim()) {
          try {
            await createAnnotation(
              "link-description",
              JSON.stringify({ link_id: linkId, text: linkDescription.trim() }),
              sourceStart,
              sourceEnd,
            );
          } catch (e) {
            console.error("[link-desc] Failed to create annotation:", e);
          }
        }
        setLinkDescription("");
        await Promise.all([
          transclusion.loadLinks(clientRef.current, workBeId, works),
          transclusion.loadBacklinks(clientRef.current, workBeId),
        ]);
      }
    },
    [clientRef, workBeId, selectionRange, displayText, transclusion, works, linkDescription, createAnnotation],
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
      else if (item === "document") { setWorkBeId(null); setSelectionRange(null); }
    },
    []
  );

  const handleEditorSelectionChange = useCallback(
    (s: number | null, e: number | null) => {
      sendSelection(s, e);
      if (s !== null && e !== null && s !== e) setSelectionRange({ start: s, end: e });
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
              className="selection-action-btn style-btn"
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => handleToggleStyle("bold", selectionRange.start, selectionRange.end)}
              title="Bold (Ctrl+B)"
              style={{ fontWeight: 700 }}
            >
              B
            </button>
            <button
              type="button"
              className="selection-action-btn style-btn"
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => handleToggleStyle("italic", selectionRange.start, selectionRange.end)}
              title="Italic (Ctrl+I)"
              style={{ fontStyle: "italic" }}
            >
              I
            </button>
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
            {editable && (
              <button
                type="button"
                className="selection-action-btn"
                onClick={() => setAnnotationTarget({ start: selectionRange.start, end: selectionRange.end })}
                title="Add a note or comment to this passage (Ctrl+Alt+A)"
                style={{ fontSize: 11, border: "1px solid #d29922", color: "#d29922" }}
              >
                {"\u270E"} Note
              </button>
            )}
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
            <div className="welcome-features">
              <div className="welcome-feature-card">
                <div className="welcome-feature-icon" style={{ background: "rgba(88,166,255,0.12)", color: "#58a6ff" }}>{"\u2192"}</div>
                <div className="welcome-feature-name">Typed Links</div>
                <div className="welcome-feature-desc">Six link types &mdash; Comment, Reference, Disagreement, Quotation, See Also, Web &mdash; each colour-coded with margin descriptions</div>
              </div>
              <div className="welcome-feature-card">
                <div className="welcome-feature-icon" style={{ background: "rgba(63,185,80,0.12)", color: "#3fb950" }}>{"\u25A3"}</div>
                <div className="welcome-feature-name">Transclusion</div>
                <div className="welcome-feature-desc">Inline content reuse with 32-level recursive resolution. Links survive edits via O-tree span migration.</div>
              </div>
              <div className="welcome-feature-card">
                <div className="welcome-feature-icon" style={{ background: "rgba(163,113,247,0.12)", color: "#a371f7" }}>{"\u2713"}</div>
                <div className="welcome-feature-name">Provenance</div>
                <div className="welcome-feature-desc">Every character is cryptographically attributed. Ed25519 signatures, BLAKE3 verification, tamper-evident audit trail.</div>
              </div>
              <div className="welcome-feature-card">
                <div className="welcome-feature-icon" style={{ background: "rgba(210,153,34,0.12)", color: "#d29922" }}>{"\u21C4"}</div>
                <div className="welcome-feature-name">Comparison</div>
                <div className="welcome-feature-desc">Side-by-side document comparison with bezier-curve connections between shared passages. Split view and inline diff.</div>
              </div>
              <div className="welcome-feature-card">
                <div className="welcome-feature-icon" style={{ background: "rgba(57,210,192,0.12)", color: "#39d2c0" }}>{"\u2302"}</div>
                <div className="welcome-feature-name">Cross-Server</div>
                <div className="welcome-feature-desc">Domain-based tumblers route content across servers. BLAKE3 hash verification makes content substitution impossible.</div>
              </div>
              <div className="welcome-feature-card">
                <div className="welcome-feature-icon" style={{ background: "rgba(248,81,73,0.12)", color: "#f85149" }}>{"\u270E"}</div>
                <div className="welcome-feature-name">Real-time CRDT</div>
                <div className="welcome-feature-desc">Live multi-user editing without locks. Purpose-built O-tree CRDT with presence awareness and conflict-free merges.</div>
              </div>
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
            <div className="welcome-actions">
              <button className="welcome-btn" style={{ borderColor: "var(--blue)", color: "var(--blue)" }} onClick={handleCreateDemo}>
                {"\u25B6 Try the Interactive Demo"}
              </button>
            </div>
            {works.length > 0 && (
              <div className="welcome-hint" style={{ marginTop: 16 }}>
                <strong>{works.length} document{works.length !== 1 ? "s" : ""} available.</strong>{" "}
                Click <strong>Browse Library</strong> to explore. Toggle <strong>Write</strong> in the top bar to edit.
              </div>
            )}
            {!identity && (
              <div className="welcome-hint">
                Tip: Click the person icon in the left rail to create an identity.
                You need an identity to edit documents.
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
              {isPublished && (
                <button
                  type="button"
                  className="publish-toggle"
                  onClick={handleCopyReference}
                  title="Copy cross-server reference (tumbler + hash) for linking from another server"
                >
                  {"\u29C9"} Copy Ref
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
              <button
                type="button"
                className="publish-toggle"
                onClick={() => setShowLinkDesc((s) => !s)}
                title="Toggle link description boxes"
              >
                {showLinkDesc ? "Hide Links" : "Show Links"}
              </button>
              <button
                type="button"
                className="publish-toggle"
                onClick={() => setShowCompare((s) => !s)}
                title="Toggle document comparison view"
              >
                {showCompare ? "Close Compare" : "Compare"}
              </button>
              <button
                type="button"
                className="publish-toggle"
                onClick={() => setShowPerspective(true)}
                title="Open perspective view showing connected documents"
              >
                Perspective
              </button>
              <button
                type="button"
                className="publish-toggle"
                onClick={() => setShowCompoundBuilder(true)}
                title="Open compound document builder"
              >
                Build
              </button>
              <div className="doc-meta">
                {compound.spanRanges.length > 0 && (
                  <div className="compound-badge" title="This document contains transcluded content from other works">
                    {"\u25A3"} {compound.spanRanges.length} source{compound.spanRanges.length !== 1 ? "s" : ""}
                  </div>
                )}
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
            {showCompare && (
              <>
                <CompareHeader
                  visible={showCompare}
                  state={compare}
                  currentWorkId={workBeId}
                  works={works}
                  revisionCount={currentWorkMeta?.revision_count ?? 1}
                  onClose={() => setShowCompare(false)}
                />
                <CompareSplitView currentText={displayText} state={compare} />
              </>
            )}
            <div className="document-center" style={showCompare ? { display: "none" } : undefined}>
              <CollaborativeEditor
                text={displayText}
                workId={workBeId ?? undefined}
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
                onCrossServerResolve={handleCrossServerResolve}
                onTraceProvenance={handleTraceProvenance}
                compoundSpanRanges={compound.spanRanges}
                remoteCursors={awareness}
                compoundSourceTitles={compound.sourceTitles}
                inlineResolvedText={hasInlineTransclusions ? compound.resolvedText : undefined}
                onUndoLastTransclusion={compound.undoLastInsert}
                recentChanges={crdt.recentChanges}
                showAttributionColors={showProvenance}
                showLinkDescriptions={showLinkDesc}
                onResolveLinkDescription={handleResolveLinkDescription}
                onEditLinkDescription={handleEditLinkDescription}
                onDeleteLink={editable ? handleDeleteLink : undefined}
                fontSize={docPrefs.fontSize}
                lineHeight={docPrefs.lineHeight}
                annotations={crdt.annotations}
                onCreateAnnotation={editable ? handleCreateAnnotation : undefined}
                onToggleStyle={editable ? handleToggleStyle : undefined}
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
            {showAnnotations && (
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
            {showCompound && !isSourceWork && (
              <div className="provenance-split">
                <div className="provenance-split-header">
                  <span className="provenance-title">Compound Structure</span>
                  <button
                    type="button"
                    className="publish-toggle"
                    style={{ fontSize: 11, padding: "2px 8px", marginRight: 4 }}
                    onClick={() => { setShowCompound(false); setShowCompoundBuilder(true); }}
                  >
                    Build
                  </button>
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
                    works={works}
                    onReload={() => compound.reload()}
                    onRemoveTransclusion={compound.undoLastInsert}
                  />
                </div>
              </div>
            )}
            <RelatedFooter
              backlinks={transclusion.backlinks}
              outgoingLinks={transclusion.links}
              compoundSpanRanges={compound.spanRanges}
              compoundSourceTitles={compound.sourceTitles}
              crossServerBacklinks={crossServerBacklinks}
              currentWorkId={workBeId}
              onNavigateToWork={selectWork}
            />
          </>
        )}
      </div>

      <ContextPanel
        awareness={awareness}
        attributionSpans={attributionSpans}
        attributionLogStatus={attributionLogStatus}
        transclusionLinks={transclusion.links}
        backlinks={transclusion.backlinks}
        crossServerBacklinks={crossServerBacklinks}
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
          onToggleStar={handleToggleStar}
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

      {showPerspective && workBeId !== null && (
        <PerspectiveView
          centerWorkId={workBeId}
          centerText={displayText}
          centerTitle={currentWorkMeta?.title || `Work ${workIdDisplay}`}
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
          centerText={displayText}
          centerTitle={currentWorkMeta?.title || `Work ${workIdDisplay}`}
          compoundSpanRanges={compound.spanRanges}
          compoundSourceTitles={compound.sourceTitles}
          works={works}
          client={clientRef.current}
          onClose={() => setShowCompoundBuilder(false)}
          onPlaceTransclusion={(sourceWorkId, sourceWorkTitle, start, end, text) => {
            transclusion.holdSelection(sourceWorkId, sourceWorkTitle, start, end, text);
            handlePlaceTransclusion(displayText.length).then(() => {
              if (clientRef.current && workBeId !== null) {
                clientRef.current.migrateCompoundToInline(workBeId).then(() => {
                  compound.reload();
                  refreshAnnotations();
                }).catch(() => {});
              }
            });
          }}
          onReloadCompound={() => compound.reload()}
        />
      )}
    </div>
  );
}
