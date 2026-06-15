import { useState, useEffect, useCallback, useRef } from "react";
import type {
  CrdtSyncClient,
  CompoundEditionPayload,
  CompoundElementPayload,
  CompoundResolveWorkResult,
  SpanRangePayload,
} from "../api/crdt_sync";

function commonPrefixLen(a: string, b: string): number {
  const minLen = Math.min(a.length, b.length);
  let i = 0;
  while (i < minLen && a.charCodeAt(i) === b.charCodeAt(i)) i++;
  return i;
}

function commonSuffixLen(a: string, b: string): number {
  let i = 0;
  while (i < a.length && i < b.length && a.charCodeAt(a.length - 1 - i) === b.charCodeAt(b.length - 1 - i)) i++;
  return i;
}

export interface CompoundSpanPlacement {
  source_work_id: number;
  char_start: number;
  char_end: number;
  flat_start: number;
  flat_end: number;
}

export function buildCompoundEdition(
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
  text: string,
) {
  const [hasCompound, setHasCompound] = useState(false);
  const [spanRanges, setSpanRanges] = useState<SpanRangePayload[]>([]);
  const [sourceTitles, setSourceTitles] = useState<Record<number, string>>({});
  const [resolvedText, setResolvedText] = useState<string>("");
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const spansRef = useRef<CompoundSpanPlacement[]>([]);
  const prevTextRef = useRef<string>("");

  const loadCompound = useCallback(async () => {
    if (!client || workBeId === null) return;
    try {
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
      pollRef.current = setInterval(() => {
        client
          .compoundResolveRecursive(workBeId)
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

  const sendCompound = useCallback((currentText: string, spans: CompoundSpanPlacement[]) => {
    const compound = buildCompoundEdition(currentText, spans);
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
  }, [client, workBeId, loadCompound]);

  useEffect(() => {
    const oldText = prevTextRef.current;
    prevTextRef.current = text;

    if (spansRef.current.length === 0 || oldText === "" || oldText === text) {
      return;
    }

    const prefix = commonPrefixLen(oldText, text);
    const oldRem = oldText.slice(prefix);
    const newRem = text.slice(prefix);
    const suffix = commonSuffixLen(oldRem, newRem);
    const deleteLen = oldRem.length - suffix;
    const insertLen = newRem.length - suffix;

    if (deleteLen === 0 && insertLen === 0) return;

    const changeStart = prefix;
    const changeOldEnd = prefix + deleteLen;
    const delta = insertLen - deleteLen;

    let changed = false;
    const migrated = spansRef.current.map((span) => {
      if (span.flat_end <= changeStart) return span;
      if (span.flat_start >= changeOldEnd) {
        changed = true;
        return { ...span, flat_start: span.flat_start + delta, flat_end: span.flat_end + delta };
      }
      changed = true;
      const newStart = Math.min(span.flat_start, changeStart);
      const newEnd = Math.max(span.flat_end + delta, changeStart + insertLen);
      return { ...span, flat_start: newStart, flat_end: Math.max(newStart + 1, newEnd) };
    });

    if (!changed) return;

    spansRef.current = migrated;
    sendCompound(text, migrated);
  }, [text, sendCompound]);

  const addSpan = useCallback(
    (
      currentText: string,
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
      prevTextRef.current = currentText;

      sendCompound(currentText, existing);
    },
    [sendCompound],
  );

  useEffect(() => {
    if (!client || workBeId === null) {
      spansRef.current = [];
      prevTextRef.current = "";
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
