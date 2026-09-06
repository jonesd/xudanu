import { useCallback, useEffect, useRef, useState } from "react";
import type { SuggestionCardPayload } from "../api/crdt_sync";
import { filterDismissed, paragraphPrefixAt, shouldQuery } from "../reuse-suggestions";

export interface SuggestionClient {
  suggestionQuery(workId: number, text: string): Promise<SuggestionCardPayload[]>;
}

const DEBOUNCE_MS = 500;

export function useReuseSuggestions(
  client: SuggestionClient | null,
  workId: number | null,
  text: string,
  caret: number,
): {
  cards: SuggestionCardPayload[];
  dismissed: Set<number>;
  dismiss: (workId: number) => void;
  refresh: (caretNow: number) => void;
} {
  const [cards, setCards] = useState<SuggestionCardPayload[]>([]);
  const [dismissed, setDismissed] = useState<Set<number>>(new Set());
  const disabledRef = useRef(false);
  const lastQueryRef = useRef("");

  const dismiss = useCallback((wid: number) => {
    setDismissed((d) => new Set(d).add(wid));
    setCards((cs) => cs.filter((c) => c.work_id !== wid));
  }, []);

  useEffect(() => {
    if (!client || workId === null || disabledRef.current) return;
    const prefix = paragraphPrefixAt(text, caret);
    if (!shouldQuery(prefix) || prefix === lastQueryRef.current) return;
    const t = setTimeout(async () => {
      try {
        const result = await client.suggestionQuery(workId, prefix);
        lastQueryRef.current = prefix;
        setCards(filterDismissed(result, dismissed));
      } catch {
        disabledRef.current = true;
        setCards([]);
      }
    }, DEBOUNCE_MS);
    return () => clearTimeout(t);
  }, [client, workId, text, caret, dismissed]);

  const refresh = useCallback(() => {
    disabledRef.current = false;
    lastQueryRef.current = "";
  }, []);

  return { cards, dismissed, dismiss, refresh };
}
