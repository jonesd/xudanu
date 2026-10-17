/**
 * Session-scoped record of the last span copied FROM a Xudanu editor.
 * Powers paste-as-transclusion: ⌘V of a passage copied from another
 * document can be converted into a live reference instead of a
 * frozen, provenance-severed copy. Deliberately NOT the OS clipboard
 * — no custom mime types, nothing leaves the tab; a copy from any
 * other app pastes as plain text exactly as before.
 */
export interface CopiedSpan {
  workId: number;
  start: number;
  end: number;
  text: string;
  at: number;
}

let lastCopied: CopiedSpan | null = null;

export function setLastCopiedSpan(span: CopiedSpan): void {
  lastCopied = span;
}

export function getLastCopiedSpan(): CopiedSpan | null {
  return lastCopied;
}

export function clearCopiedSpan(): void {
  lastCopied = null;
}
