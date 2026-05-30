import { useState, useCallback } from "react";
import type { CrdtSyncClient, LinkEntry, TransclusionMarker, WorkListEntry } from "../api/crdt_sync";

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
  holdSelection: (workId: number, workTitle: string, start: number, end: number, text: string) => void;
  clearPending: () => void;
  placeTransclusion: (client: CrdtSyncClient, targetWorkId: number, targetPosition: number) => Promise<number | null>;
  loadLinks: (client: CrdtSyncClient, workId: number, works: WorkListEntry[]) => Promise<void>;
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
      try {
        const linkId = await client.linkCreate(
          pending.sourceWorkId,
          targetWorkId,
          { excerpt: pending.text, start: pending.start, end: pending.end },
          { excerpt: "", start: targetPosition, end: targetPosition },
        );
        setPending(null);
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
        const linkList = await client.linkListForWork(workId);
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
          const title = workTitleMap.get(otherWorkId) || `Work ${otherWorkId.toString(16).padStart(4, "0")}`;

          const localRef = isOrigin ? link.origin_ref : link.destination_ref;
          const remoteRef = isOrigin ? link.destination_ref : link.origin_ref;
          const excerpt = localRef?.excerpt || remoteRef?.excerpt || "";

          if (excerpt.length >= 10) {
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
              });
            }
          }
        }
        setMarkers(newMarkers);
      } catch (e) {
        console.error("Failed to load links:", e);
        setLinks([]);
        setMarkers([]);
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
    holdSelection,
    clearPending,
    placeTransclusion,
    loadLinks,
    deleteLink,
  };
}
