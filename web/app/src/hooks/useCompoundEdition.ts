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

  const loadCompound = useCallback(async () => {
    if (!client || workBeId === null) return;
    try {
      const inline = await client.resolveInlineTransclusions(workBeId);
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
        client
          .resolveInlineTransclusions(workBeId!)
          .then((result) => {
            setSpanRanges(result.spanRanges);
            setSourceTitles(result.sourceTitles);
            setResolvedText(result.text);
          })
          .catch(() => {});
      };

      const unsubSourceChange = client.onCompoundSourceChange(() => {
        refresh();
      });

      const pollRef = setInterval(refresh, 30000);
      return () => {
        unsubSourceChange();
        clearInterval(pollRef);
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
      if (!client || workBeId === null) return;
      try {
        await client.elementInsert(workBeId, position, {
          type: "transclusion",
          transclusion_source: sourceWorkId,
          transclusion_start: charStart,
          transclusion_end: charEnd,
        });
        lastInsertedRef.current = { sourceWorkId, charStart, charEnd };
        await loadCompound();
      } catch (e) {
        console.error("useCompoundEdition: elementInsert failed", e);
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
        await loadCompound();
      }
      return removed;
    } catch (e) {
      console.error("useCompoundEdition: undo insert failed", e);
      return false;
    }
  }, [client, workBeId, loadCompound]);

  const removeTransclusion = useCallback(
    async (sourceWorkId: number, charStart: number, charEnd: number): Promise<boolean> => {
      if (!client || workBeId === null) return false;
      try {
        const removed = await client.elementRemoveTransclusion(workBeId, sourceWorkId, charStart, charEnd);
        if (removed) {
          await loadCompound();
        }
        return removed;
      } catch (e) {
        console.error("useCompoundEdition: remove transclusion failed", e);
        return false;
      }
    },
    [client, workBeId, loadCompound],
  );

  useEffect(() => {
    if (!client || workBeId === null) {
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
    undoLastInsert,
    removeTransclusion,
    reload: loadCompound,
  };
}
