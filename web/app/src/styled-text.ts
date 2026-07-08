import type { AnnotationEntry } from "./api/crdt_sync";

export interface StyleMark {
  annotation_id: number;
  kind: string;
  char_start: number;
  char_end: number;
}

export function extractStyleMarks(annotations: AnnotationEntry[]): StyleMark[] {
  return annotations
    .filter((a) => a.kind === "bold" || a.kind === "italic")
    .map((a) => ({
      annotation_id: a.annotation_id,
      kind: a.kind,
      char_start: a.char_start,
      char_end: a.char_end,
    }));
}

export function findMarkInRange(
  marks: StyleMark[],
  kind: string,
  start: number,
  end: number,
): StyleMark | null {
  return marks.find(
    (m) => m.kind === kind && m.char_start < end && m.char_end > start,
  ) ?? null;
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

interface Boundary {
  pos: number;
  type: "open" | "close";
  kind: string;
  openPos: number;
}

export function buildStyledText(text: string, marks: StyleMark[]): string {
  if (marks.length === 0 || text.length === 0) {
    return escapeHtml(text);
  }

  const clamped = marks
    .map((m) => ({
      ...m,
      char_start: Math.max(0, Math.min(m.char_start, text.length)),
      char_end: Math.max(0, Math.min(m.char_end, text.length)),
    }))
    .filter((m) => m.char_end > m.char_start);

  if (clamped.length === 0) {
    return escapeHtml(text);
  }

  const boundaries: Boundary[] = [];
  for (const m of clamped) {
    boundaries.push({ pos: m.char_start, type: "open", kind: m.kind, openPos: m.char_start });
    boundaries.push({ pos: m.char_end, type: "close", kind: m.kind, openPos: m.char_start });
  }

  boundaries.sort((a, b) => {
    if (a.pos !== b.pos) return a.pos - b.pos;
    if (a.type === "close" && b.type === "open") return -1;
    if (a.type === "open" && b.type === "close") return 1;
    if (a.type === "close" && b.type === "close") return b.openPos - a.openPos;
    return 0;
  });

  let result = "";
  let pos = 0;

  for (const b of boundaries) {
    if (b.pos > pos) {
      result += escapeHtml(text.slice(pos, b.pos));
      pos = b.pos;
    }
    const tag = b.kind === "bold"
      ? (b.type === "open" ? "<strong>" : "</strong>")
      : (b.type === "open" ? "<em>" : "</em>");
    result += tag;
  }

  if (pos < text.length) {
    result += escapeHtml(text.slice(pos));
  }

  return result;
}

export function getCursorOffset(el: HTMLElement): number {
  const sel = window.getSelection();
  if (!sel || sel.rangeCount === 0 || !el.contains(sel.anchorNode)) {
    return 0;
  }
  const range = sel.getRangeAt(0);
  const preRange = document.createRange();
  preRange.selectNodeContents(el);
  preRange.setEnd(range.startContainer, range.startOffset);
  return preRange.toString().length;
}

export function setCursorOffset(el: HTMLElement, offset: number): void {
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
  let node: Node | null;
  let remaining = offset;

  while ((node = walker.nextNode())) {
    const len = node.textContent?.length ?? 0;
    if (remaining <= len) {
      const range = document.createRange();
      range.setStart(node, remaining);
      range.collapse(true);
      const sel = window.getSelection();
      if (sel) {
        sel.removeAllRanges();
        sel.addRange(range);
      }
      return;
    }
    remaining -= len;
  }

  const lastChild = el.lastChild;
  if (lastChild) {
    const range = document.createRange();
    range.selectNodeContents(el);
    range.collapse(false);
    const sel = window.getSelection();
    if (sel) {
      sel.removeAllRanges();
      sel.addRange(range);
    }
  }
}
