import { useState, useEffect, useCallback, useRef } from "react";
import type {
  CrdtSyncClient,
  CompoundElementPayload,
  CompoundResolveWorkResult,
  SpanRangePayload,
} from "../api/crdt_sync";

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
        return;
      }

      const edition = await client.compoundGetEdition(workBeId);
      if (edition && edition.elements.length > 0) {
        setHasCompound(true);
        const result = await client.compoundResolveRecursive(workBeId);
        setSpanRanges(result.span_ranges || []);
        setSourceTitles(result.source_titles || {});
        setResolvedText(result.flat_text || "");
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
            if (result.spanRanges.length > 0) {
              setSpanRanges(result.spanRanges);
              setSourceTitles(result.sourceTitles);
              setResolvedText(result.text);
            } else {
              client
                .compoundResolveRecursive(workBeId!)
                .then((r: CompoundResolveWorkResult) => {
                  setSpanRanges(r.span_ranges || []);
                  setSourceTitles(r.source_titles || {});
                  setResolvedText(r.flat_text || "");
                })
                .catch(() => {});
            }
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
    setSpanRanges([]);
    setResolvedText("");
    setSourceTitles({});
    try {
      const removed = await client.elementRemoveTransclusion(workBeId, sourceWorkId, charStart, charEnd);
      if (removed) {
        lastInsertedRef.current = null;
        await loadCompound();
      } else {
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
      setSpanRanges([]);
      setResolvedText("");
      setSourceTitles({});
      try {
        const removed = await client.elementRemoveTransclusion(workBeId, sourceWorkId, charStart, charEnd);
        if (removed) {
          await loadCompound();
        } else {
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

  const insertElement = useCallback(
    async (index: number, element: CompoundElementPayload): Promise<number | null> => {
      if (!client || workBeId === null) return null;
      try {
        const count = await client.compoundInsertElement(workBeId, index, element);
        await loadCompound();
        return count;
      } catch (e) {
        console.error("useCompoundEdition: insert element failed", e);
        return null;
      }
    },
    [client, workBeId, loadCompound],
  );

  const removeElement = useCallback(
    async (index: number): Promise<number | null> => {
      if (!client || workBeId === null) return null;
      try {
        const count = await client.compoundRemoveElement(workBeId, index);
        await loadCompound();
        return count;
      } catch (e) {
        console.error("useCompoundEdition: remove element failed", e);
        return null;
      }
    },
    [client, workBeId, loadCompound],
  );

  const moveElement = useCallback(
    async (from: number, to: number): Promise<number | null> => {
      if (!client || workBeId === null) return null;
      try {
        const count = await client.compoundMoveElement(workBeId, from, to);
        await loadCompound();
        return count;
      } catch (e) {
        console.error("useCompoundEdition: move element failed", e);
        return null;
      }
    },
    [client, workBeId, loadCompound],
  );

  return {
    hasCompound,
    spanRanges,
    sourceTitles,
    resolvedText,
    addSpan,
    undoLastInsert,
    removeTransclusion,
    reload: loadCompound,
    insertElement,
    removeElement,
    moveElement,
  };
}
