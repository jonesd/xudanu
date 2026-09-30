/**
 * FR-84 split authoring: pure logic for the two-ended connection bar.
 * Kept free of React so the connection contract is unit-testable.
 */

export interface PaneEnd {
  workId: number;
  start: number;
  end: number;
  text: string;
}

/** A connection can complete iff both ends exist, span real text,
 * and are not the same work (a self-link's ends would collapse). */
export function canConnect(a: PaneEnd | null, b: PaneEnd | null): boolean {
  if (!a || !b) return false;
  if (a.workId === b.workId) return false;
  if (a.start >= a.end || b.start >= b.end) return false;
  if (!a.text.trim() || !b.text.trim()) return false;
  return true;
}

/** Wire refs for linkCreate: origin → destination, excerpt capped at
 * 200 chars (the same cap the overlay contract uses). */
export function buildLinkRefs(
  origin: PaneEnd,
  destination: PaneEnd,
): {
  originRef: { excerpt: string; start: number; end: number };
  destinationRef: { excerpt: string; start: number; end: number };
} {
  const cap = (s: string) => (s.length > 200 ? s.slice(0, 200) : s);
  return {
    originRef: { excerpt: cap(origin.text), start: origin.start, end: origin.end },
    destinationRef: {
      excerpt: cap(destination.text),
      start: destination.start,
      end: destination.end,
    },
  };
}

/** Display excerpt for the bar chips. */
export function chipExcerpt(text: string, max = 48): string {
  const t = text.replace(/\s+/g, " ").trim();
  return t.length > max ? t.slice(0, max - 1) + "…" : t;
}
