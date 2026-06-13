import { useState, useEffect, useCallback, useRef } from "react";
import type {
  CrdtSyncClient,
  CompoundEditionPayload,
  CompoundElementPayload,
  CompoundResolveWorkResult,
  SpanRangePayload,
} from "../api/crdt_sync";

export interface CompoundSpanPlacement {
  source_work_id: number;
  char_start: number;
  char_end: number;
  flat_start: number;
  flat_end: number;
}

function buildCompoundEdition(
  text: string,
  spans: CompoundSpanPlacement[],
): CompoundEditionPayload {
  if (spans.length === 0) {
    return { elements: [{ type: "text" as const, content: text }] };
  }

  const sorted = [...spans].sort((a, b) => a.flat_start - b.flat_start);
  const elements: CompoundElementPayload[] = [];
  let pos = 0;

  for (const span of sorted) {
    if (span.flat_start > pos) {
      elements.push({
        type: "text",
        content: text.slice(pos, span.flat_start),
      });
    }
    elements.push({
      type: "span",
      source_work_id: span.source_work_id,
      char_start: span.char_start,
      char_end: span.char_end,
    });
    pos = span.flat_end;
  }

  if (pos < text.length) {
    elements.push({ type: "text", content: text.slice(pos) });
  }

  return { elements };
}

export function useCompoundEdition(
  client: CrdtSyncClient | null,
  workBeId: number | null,
) {
  const [hasCompound, setHasCompound] = useState(false);
  const [spanRanges, setSpanRanges] = useState<SpanRangePayload[]>([]);
  const [sourceTitles, setSourceTitles] = useState<Record<number, string>>({});
  const [resolvedText, setResolvedText] = useState<string>("");
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const spansRef = useRef<CompoundSpanPlacement[]>([]);

  const loadCompound = useCallback(async () => {
    if (!client || workBeId === null) return;
    try {
      const edition = await client.compoundGetEdition(workBeId);
      if (edition && edition.elements.length > 0) {
        setHasCompound(true);
        const result = await client.compoundResolveWork(workBeId);
        setSpanRanges(result.span_ranges || []);
        setSourceTitles(result.source_titles || {});
        setResolvedText(result.flat_text || "");
      } else {
        setHasCompound(false);
        setSpanRanges([]);
        setSourceTitles({});
        setResolvedText("");
      }
    } catch (e) {
      console.warn("useCompoundEdition: load failed", e);
    }
  }, [client, workBeId]);

  useEffect(() => {
    loadCompound();
  }, [loadCompound]);

  useEffect(() => {
    if (hasCompound && client && workBeId !== null) {
      pollRef.current = setInterval(() => {
        client
          .compoundResolveWork(workBeId)
          .then((result: CompoundResolveWorkResult) => {
            setSpanRanges(result.span_ranges || []);
            setSourceTitles(result.source_titles || {});
            setResolvedText(result.flat_text || "");
          })
          .catch(() => {});
      }, 3000);
      return () => {
        if (pollRef.current) clearInterval(pollRef.current);
      };
    }
  }, [hasCompound, client, workBeId]);

  const addSpan = useCallback(
    (
      text: string,
      position: number,
      excerpt: string,
      sourceWorkId: number,
      charStart: number,
      charEnd: number,
    ) => {
      const newSpan: CompoundSpanPlacement = {
        source_work_id: sourceWorkId,
        char_start: charStart,
        char_end: charEnd,
        flat_start: position,
        flat_end: position + excerpt.length,
      };

      const existing = spansRef.current.filter((s) => {
        return !(
          s.flat_start === newSpan.flat_start &&
          s.flat_end === newSpan.flat_end &&
          s.source_work_id === newSpan.source_work_id
        );
      });
      existing.push(newSpan);
      spansRef.current = existing;

      const compound = buildCompoundEdition(text, existing);

      if (client && workBeId !== null) {
        client
          .compoundSetEdition(workBeId, compound)
          .then(() => {
            setHasCompound(true);
            loadCompound();
          })
          .catch((e) =>
            console.error("useCompoundEdition: set edition failed", e),
          );
      }
    },
    [client, workBeId, loadCompound],
  );

  useEffect(() => {
    if (!client || workBeId === null) {
      spansRef.current = [];
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
    reload: loadCompound,
  };
}
