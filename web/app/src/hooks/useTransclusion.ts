import { useState, useCallback } from "react";
import type { CrdtSyncClient, LinkEntry, TransclusionMarker, WorkListEntry, BacklinkEntry } from "../api/crdt_sync";

export interface PendingTransclusion {
  sourceWorkId: number;
  sourceWorkTitle: string;
  start: number;
  end: number;
  text: string;
}

export interface TransclusionState {
  pending: PendingTransclusion | null;
  links: LinkEntry[];
  markers: TransclusionMarker[];
  backlinks: BacklinkEntry[];
  holdSelection: (workId: number, workTitle: string, start: number, end: number, text: string) => void;
  clearPending: () => void;
  placeTransclusion: (client: CrdtSyncClient, targetWorkId: number, targetPosition: number) => Promise<number | null>;
  loadLinks: (client: CrdtSyncClient, workId: number, works: WorkListEntry[]) => Promise<void>;
  loadBacklinks: (client: CrdtSyncClient, workId: number) => Promise<void>;
  deleteLink: (client: CrdtSyncClient, linkId: number) => Promise<void>;
}

const MARKER_COLORS = [
  "#00897b", "#5c6bc0", "#f4511e", "#00838f",
  "#7b1fa2", "#c62828", "#2e7d32", "#e65100",
];

function markerColorForWork(workId: number): string {
  let hash = 0;
  hash = ((hash << 5) - hash + workId) | 0;
  hash = ((hash << 5) - hash + (workId >> 8)) | 0;
  const idx = Math.abs(hash) % MARKER_COLORS.length;
  return MARKER_COLORS[idx];
}

export function useTransclusion(): TransclusionState {
  const [pending, setPending] = useState<PendingTransclusion | null>(null);
  const [links, setLinks] = useState<LinkEntry[]>([]);
  const [markers, setMarkers] = useState<TransclusionMarker[]>([]);
  const [backlinks, setBacklinks] = useState<BacklinkEntry[]>([]);

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
          if (excerpt.length >= 3) {
            const positions = await client.findExcerptPositions(workId, excerpt);
            const chain = localRef?.provenance_chain || remoteRef?.provenance_chain;
            for (const pos of positions) {
              newMarkers.push({
                start: pos.start,
                end: pos.end,
                linkId: link.link_id,
                direction: isOrigin ? "outgoing" : "incoming",
                otherWorkId,
                otherWorkTitle: title,
                color,
                provenanceChain: chain,
                otherWorkIsArchived: !!otherArchived,
                otherWorkOwner: otherOwner ?? null,
              });
            }
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
    links,
    markers,
    backlinks,
    holdSelection,
    clearPending,
    placeTransclusion,
    loadLinks,
    loadBacklinks,
    deleteLink,
  };
}
