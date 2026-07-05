import { useState, useCallback } from "react";
import type { CrdtSyncClient, LinkEntry, TransclusionMarker, WorkListEntry, BacklinkEntry, LinkTypeInfo } from "../api/crdt_sync";
import { resolveMarkerPositions } from "../link-markers";

export interface PendingTransclusion {
  sourceWorkId: number;
  sourceWorkTitle: string;
  start: number;
  end: number;
  text: string;
}

export interface PendingLink {
  sourceWorkId: number;
  sourceWorkTitle: string;
  start: number;
  end: number;
  text: string;
}

export const DEFAULT_LINK_TYPES: { type_id: number; name: string; color: string; lineStyle: string }[] = [
  { type_id: 1, name: "Comment", color: "#58a6ff", lineStyle: "dashed" },
  { type_id: 2, name: "Reference", color: "#3fb950", lineStyle: "solid" },
  { type_id: 3, name: "Disagreement", color: "#f85149", lineStyle: "underline" },
  { type_id: 4, name: "Quotation", color: "#a371f7", lineStyle: "dotted" },
  { type_id: 5, name: "See Also", color: "#d29922", lineStyle: "dashed" },
];

export interface TransclusionState {
  pending: PendingTransclusion | null;
  pendingLink: PendingLink | null;
  links: LinkEntry[];
  markers: TransclusionMarker[];
  backlinks: BacklinkEntry[];
  linkTypes: LinkTypeInfo[];
  holdSelection: (workId: number, workTitle: string, start: number, end: number, text: string) => void;
  clearPending: () => void;
  holdLinkSelection: (workId: number, workTitle: string, start: number, end: number, text: string) => void;
  clearPendingLink: () => void;
  createContentLink: (client: CrdtSyncClient, targetWorkId: number, targetStart: number, targetEnd: number, targetText: string, typeId: number) => Promise<number | null>;
  placeTransclusion: (client: CrdtSyncClient, targetWorkId: number, targetPosition: number) => Promise<number | null>;
  loadLinks: (client: CrdtSyncClient, workId: number, works: WorkListEntry[]) => Promise<void>;
  loadBacklinks: (client: CrdtSyncClient, workId: number) => Promise<void>;
  loadLinkTypes: (client: CrdtSyncClient) => Promise<void>;
  deleteLink: (client: CrdtSyncClient, linkId: number) => Promise<void>;
}

const MARKER_COLORS = [
  "#00897b", "#5c6bc0", "#f4511e", "#00838f",
  "#7b1fa2", "#c62828", "#2e7d32", "#e65100",
];

const HATCH_COLORS: [string, string][] = [
  ["#00897b", "#4db6ac"],
  ["#5c6bc0", "#9fa8da"],
  ["#f4511e", "#ffab91"],
  ["#00838f", "#4dd0e1"],
  ["#7b1fa2", "#ba68c8"],
  ["#c62828", "#ef9a9a"],
  ["#2e7d32", "#a5d6a7"],
  ["#e65100", "#ffcc80"],
  ["#37474f", "#90a4ae"],
  ["#4527a0", "#b39ddb"],
];

export function getTransclusionColor(workId: number): string {
  let hash = 0;
  hash = ((hash << 5) - hash + workId) | 0;
  hash = ((hash << 5) - hash + (workId >> 8)) | 0;
  const pairIdx = Math.abs(hash) % (HATCH_COLORS.length * (HATCH_COLORS.length - 1));
  const idxA = pairIdx % HATCH_COLORS.length;
  return HATCH_COLORS[idxA][0];
}

function markerColorForWork(workId: number): string {
  let hash = 0;
  hash = ((hash << 5) - hash + workId) | 0;
  hash = ((hash << 5) - hash + (workId >> 8)) | 0;
  const idx = Math.abs(hash) % MARKER_COLORS.length;
  return MARKER_COLORS[idx];
}

export function useTransclusion(): TransclusionState {
  const [pending, setPending] = useState<PendingTransclusion | null>(null);
  const [pendingLink, setPendingLink] = useState<PendingLink | null>(null);
  const [links, setLinks] = useState<LinkEntry[]>([]);
  const [markers, setMarkers] = useState<TransclusionMarker[]>([]);
  const [backlinks, setBacklinks] = useState<BacklinkEntry[]>([]);
  const [linkTypes, setLinkTypes] = useState<LinkTypeInfo[]>([]);

  const holdSelection = useCallback(
    (workId: number, workTitle: string, start: number, end: number, text: string) => {
      setPending({ sourceWorkId: workId, sourceWorkTitle: workTitle, start, end, text });
    },
    [],
  );

  const clearPending = useCallback(() => {
    setPending(null);
  }, []);

  const placeTransclusion = useCallback(
    async (client: CrdtSyncClient, targetWorkId: number, targetPosition: number): Promise<number | null> => {
      if (!pending) return null;
      const pendingData = pending;
      setPending(null);
      try {
        const linkId = await client.linkCreate(
          pendingData.sourceWorkId,
          targetWorkId,
          { excerpt: pendingData.text, start: pendingData.start, end: pendingData.end },
          { excerpt: "", start: targetPosition, end: targetPosition },
        );
        try {
          await client.applyTransclusionAttribution(linkId);
        } catch (e) {
          console.error("Failed to apply transclusion attribution:", e);
        }
        return linkId;
      } catch (e) {
        console.error("Failed to create transclusion link:", e);
        return null;
      }
    },
    [pending],
  );

  const loadLinks = useCallback(
    async (client: CrdtSyncClient, workId: number, works: WorkListEntry[]) => {
      try {
      const rawList = await client.linkListForWork(workId);
      const seenIds = new Set<number>();
      const linkList = rawList.filter((l) =>
        seenIds.has(l.link_id) ? false : (seenIds.add(l.link_id), true),
      );
      setLinks(linkList);

        const workTitleMap = new Map<number, string>();
        for (const w of works) {
          workTitleMap.set(w.work_id, w.title || "Untitled");
        }

        const newMarkers: TransclusionMarker[] = [];
        for (const link of linkList) {
          const isOrigin = link.origin === workId;
          const otherWorkId = isOrigin ? link.destination : link.origin;
          const color = markerColorForWork(otherWorkId);
          // Prefer the link's endpoint title (it covers archived works, which are
          // excluded from the work list and thus absent from workTitleMap).
          const title =
            (isOrigin ? link.destination_title : link.origin_title) ||
            workTitleMap.get(otherWorkId) ||
            `Work ${otherWorkId.toString(16).padStart(4, "0")}`;
          const otherArchived = isOrigin ? link.destination_archived : link.origin_archived;
          const otherOwner = isOrigin ? link.destination_owner : link.origin_owner;

          const localRef = isOrigin ? link.origin_ref : link.destination_ref;
          const remoteRef = isOrigin ? link.destination_ref : link.origin_ref;
          const excerpt = localRef?.excerpt || remoteRef?.excerpt || "";
          const chain = localRef?.provenance_chain || remoteRef?.provenance_chain;
          const fallback = excerpt.length >= 3
            ? await client.findExcerptPositions(workId, excerpt)
            : [];
          const positions = resolveMarkerPositions(localRef, fallback);
          for (const pos of positions) {
            newMarkers.push({
              start: pos.start,
              end: pos.end,
              linkId: link.link_id,
              direction: isOrigin ? "outgoing" : "incoming",
              otherWorkId,
              otherWorkTitle: title,
              color,
              excerpt: excerpt.slice(0, 120),
              provenanceChain: chain,
              linkTypeId: link.link_types?.[0],
              otherWorkIsArchived: !!otherArchived,
              otherWorkOwner: otherOwner ?? null,
            });
          }
        }
        setMarkers(newMarkers);
      } catch {
        setLinks([]);
        setMarkers([]);
      }
    },
    [],
  );

  const holdLinkSelection = useCallback(
    (workId: number, workTitle: string, start: number, end: number, text: string) => {
      setPendingLink({ sourceWorkId: workId, sourceWorkTitle: workTitle, start, end, text });
    },
    [],
  );

  const clearPendingLink = useCallback(() => {
    setPendingLink(null);
  }, []);

  const createContentLink = useCallback(
    async (
      client: CrdtSyncClient,
      targetWorkId: number,
      targetStart: number,
      targetEnd: number,
      targetText: string,
      typeId: number,
    ): Promise<number | null> => {
      if (!pendingLink) return null;
      const source = pendingLink;
      setPendingLink(null);
      try {
        const linkId = await client.linkCreate(
          source.sourceWorkId,
          targetWorkId,
          { excerpt: source.text, start: source.start, end: source.end },
          { excerpt: targetText, start: targetStart, end: targetEnd },
        );
        try {
          await client.linkSetTypes(linkId, [typeId]);
        } catch (e) {
          console.error("Failed to set link type:", e);
        }
        return linkId;
      } catch (e) {
        console.error("Failed to create content link:", e);
        return null;
      }
    },
    [pendingLink],
  );

  const loadLinkTypes = useCallback(
    async (client: CrdtSyncClient) => {
      try {
        const result = await client.linkTypeList();
        setLinkTypes(result.length > 0 ? result : DEFAULT_LINK_TYPES.map((t) => ({ type_id: t.type_id, name: t.name })));
      } catch {
        setLinkTypes(DEFAULT_LINK_TYPES.map((t) => ({ type_id: t.type_id, name: t.name })));
      }
    },
    [],
  );

  const loadBacklinks = useCallback(
    async (client: CrdtSyncClient, workId: number) => {
      try {
        const result = await client.findBacklinks(workId);
        setBacklinks(result);
      } catch {
        setBacklinks([]);
      }
    },
    [],
  );

  const deleteLink = useCallback(
    async (client: CrdtSyncClient, linkId: number) => {
      try {
        await client.linkDelete(linkId);
        setLinks((prev) => prev.filter((l) => l.link_id !== linkId));
        setMarkers((prev) => prev.filter((m) => m.linkId !== linkId));
      } catch (e) {
        console.error("Failed to delete link:", e);
      }
    },
    [],
  );

  return {
    pending,
    pendingLink,
    links,
    markers,
    backlinks,
    linkTypes,
    holdSelection,
    clearPending,
    holdLinkSelection,
    clearPendingLink,
    createContentLink,
    placeTransclusion,
    loadLinks,
    loadBacklinks,
    loadLinkTypes,
    deleteLink,
  };
}
