export interface SuggestionLike {
  work_id: number;
  windows: number;
}

export function paragraphPrefixAt(text: string, caret: number): string {
  if (!text) return "";
  const c = Math.max(0, Math.min(caret, text.length));
  let start = text.lastIndexOf("\n", Math.max(0, c - 1)) + 1;
  if (start > c) start = c;
  return text.slice(start, c);
}

export function filterDismissed<T extends SuggestionLike>(
  cards: T[],
  dismissed: Set<number>,
): T[] {
  return cards.filter((c) => !dismissed.has(c.work_id));
}

export function shouldQuery(prefix: string, minWords = 6): boolean {
  return prefix.trim().split(/\s+/).filter(Boolean).length >= minWords;
}
