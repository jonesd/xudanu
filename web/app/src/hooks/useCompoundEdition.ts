import { useState, useEffect, useCallback, useRef } from "react";
import type { CrdtSyncClient, SpanRangePayload } from "../api/crdt_sync";

export function useCompoundEdition(
  client: CrdtSyncClient | null,
  workBeId: number | null,
) {
  const [hasCompound, setHasCompound] = useState(false);
  const [spanRanges, setSpanRanges] = useState<SpanRangePayload[]>([]);
  const [sourceTitles, setSourceTitles] = useState<Record<number, string>>({});
  const [resolvedText, setResolvedText] = useState<string>("");
  const lastInsertedRef = useRef<{ sourceWorkId: number; charStart: number; charEnd: number } | null>(null);
  const epochRef = useRef(0);

  const loadCompound = useCallback(async () => {
    if (!client || workBeId === null) return;
    const epoch = ++epochRef.current;
    try {
      const inline = await client.resolveInlineTransclusions(workBeId);
      if (epoch !== epochRef.current) return;
      if (inline.spanRanges.length > 0) {
        setHasCompound(true);
        setSpanRanges(inline.spanRanges);
        setSourceTitles(inline.sourceTitles);
        setResolvedText(inline.text);
      } else {
        setHasCompound(false);
        setSpanRanges([]);
        setSourceTitles({});
        setResolvedText("");
      }
    } catch {
      // Expected during identity transitions or connection changes
    }
  }, [client, workBeId]);

  useEffect(() => {
    loadCompound();
  }, [loadCompound]);

  useEffect(() => {
    if (hasCompound && client && workBeId !== null) {
      const refresh = () => {
        const epoch = epochRef.current;
        client
          .resolveInlineTransclusions(workBeId!)
          .then((result) => {
            if (epoch !== epochRef.current) return;
            if (result.spanRanges.length > 0) {
              setSpanRanges(result.spanRanges);
              setSourceTitles(result.sourceTitles);
              setResolvedText(result.text);
            }
          })
          .catch(() => {});
      };

      const unsubSourceChange = client.onCompoundSourceChange(() => {
        refresh();
      });

      const pollRef = setInterval(refresh, 10000);
      return () => {
        unsubSourceChange();
        clearInterval(pollRef);
        epochRef.current++;
      };
    }
  }, [hasCompound, client, workBeId]);

  const addSpan = useCallback(
    async (
      _currentText: string,
      position: number,
      _excerpt: string,
      sourceWorkId: number,
      charStart: number,
      charEnd: number,
    ) => {
      if (!client || workBeId === null) return false;
      try {
        await client.elementInsert(workBeId, position, {
          type: "transclusion",
          transclusion_source: sourceWorkId,
          transclusion_start: charStart,
          transclusion_end: charEnd,
        });
        lastInsertedRef.current = { sourceWorkId, charStart, charEnd };
        await loadCompound();
        return true;
      } catch (e) {
        console.error("useCompoundEdition: elementInsert failed", e);
        const msg = e instanceof Error ? e.message : String(e);
        alert(`Could not include passage: ${msg}\n\nThis usually means you don't have edit access to the destination work, or you're not logged in.`);
        return false;
      }
    },
    [client, workBeId, loadCompound],
  );

  /**
   * FR-37: place a PINNED virtual quotation (Phase 3/4 UX). Pins the
   * source's CURRENT revision at placement time — the quotation is
   * immune to later source edits until deliberately re-placed. Falls
   * back to the legacy live transclusion when revision lookup fails.
   */
  const addPinnedSpan = useCallback(
    async (
      position: number,
      sourceWorkId: number,
      charStart: number,
      charEnd: number,
    ) => {
      if (!client || workBeId === null) return false;
      try {
        let revision = 0;
        try {
          revision = await client.revisionCount(sourceWorkId);
        } catch {
          // revision unknown — server will reject an unpinned virtual;
          // fall back to the legacy live transclusion.
          await client.elementInsert(workBeId, position, {
            type: "transclusion",
            transclusion_source: sourceWorkId,
            transclusion_start: charStart,
            transclusion_end: charEnd,
          });
          lastInsertedRef.current = { sourceWorkId, charStart, charEnd };
          await loadCompound();
          return true;
        }
        await client.elementInsert(workBeId, position, {
          type: "virtual",
          virtual_source: sourceWorkId,
          virtual_revision: revision,
          transclusion_start: charStart,
          transclusion_end: charEnd,
        });
        lastInsertedRef.current = { sourceWorkId, charStart, charEnd };
        await loadCompound();
        return true;
      } catch (e) {
        console.error("useCompoundEdition: addPinnedSpan failed", e);
        const msg = e instanceof Error ? e.message : String(e);
        alert(`Could not place quotation: ${msg}`);
        return false;
      }
    },
    [client, workBeId, loadCompound],
  );

  const undoLastInsert = useCallback(async (): Promise<boolean> => {
    if (!client || workBeId === null || !lastInsertedRef.current) return false;
    const { sourceWorkId, charStart, charEnd } = lastInsertedRef.current;
    try {
      const removed = await client.elementRemoveTransclusion(workBeId, sourceWorkId, charStart, charEnd);
      if (removed) {
        lastInsertedRef.current = null;
        const epoch = ++epochRef.current;
        const inline = await client.resolveInlineTransclusions(workBeId);
        if (epoch !== epochRef.current) return true;
        setHasCompound(inline.spanRanges.length > 0);
        setSpanRanges(inline.spanRanges);
        setSourceTitles(inline.sourceTitles);
        setResolvedText(inline.text);
      }
      return removed;
    } catch (e) {
      console.error("useCompoundEdition: undo insert failed", e);
      return false;
    }
  }, [client, workBeId]);

  const removeTransclusion = useCallback(
    async (sourceWorkId: number, charStart: number, charEnd: number): Promise<boolean> => {
      if (!client || workBeId === null) return false;
      try {
        const removed = await client.elementRemoveTransclusion(workBeId, sourceWorkId, charStart, charEnd);
        if (removed) {
          const epoch = ++epochRef.current;
          const inline = await client.resolveInlineTransclusions(workBeId);
          if (epoch !== epochRef.current) return true;
          setHasCompound(inline.spanRanges.length > 0);
          setSpanRanges(inline.spanRanges);
          setSourceTitles(inline.sourceTitles);
          setResolvedText(inline.text);
        }
        return removed;
      } catch (e) {
        console.error("useCompoundEdition: remove transclusion failed", e);
        return false;
      }
    },
    [client, workBeId],
  );

  useEffect(() => {
    if (!client || workBeId === null) {
      epochRef.current++;
      setHasCompound(false);
      setSpanRanges([]);
      setSourceTitles({});
      setResolvedText("");
    }
  }, [client, workBeId]);

  return {
    hasCompound,
    spanRanges,
    sourceTitles,
    resolvedText,
    addSpan,
    addPinnedSpan,
    undoLastInsert,
    removeTransclusion,
    reload: loadCompound,
  };
}
