import type { AnnotationEntry } from "./api/crdt_sync";

export interface StyleMark {
  annotation_id: number;
  kind: string;
  char_start: number;
  char_end: number;
  payload?: string;
}

const INLINE_KINDS = new Set(["bold", "italic"]);
const BLOCK_KINDS = new Set(["heading", "list_item", "blockquote", "code_block"]);

export function extractStyleMarks(annotations: AnnotationEntry[]): StyleMark[] {
  return annotations
    .filter((a) => INLINE_KINDS.has(a.kind) || BLOCK_KINDS.has(a.kind))
    .map((a) => ({
      annotation_id: a.annotation_id,
      kind: a.kind,
      char_start: a.char_start,
      char_end: a.char_end,
      ...(a.payload ? { payload: a.payload } : {}),
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

function applyInlineMarks(textSegment: string, marks: StyleMark[], segStart: number): string {
  const clamped = marks
    .filter((m) => INLINE_KINDS.has(m.kind))
    .map((m) => ({
      ...m,
      char_start: Math.max(0, Math.min(m.char_start - segStart, textSegment.length)),
      char_end: Math.max(0, Math.min(m.char_end - segStart, textSegment.length)),
    }))
    .filter((m) => m.char_end > m.char_start);

  if (clamped.length === 0) return escapeHtml(textSegment);

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
      result += escapeHtml(textSegment.slice(pos, b.pos));
      pos = b.pos;
    }
    const tag = b.kind === "bold"
      ? (b.type === "open" ? "<strong>" : "</strong>")
      : (b.type === "open" ? "<em>" : "</em>");
    result += tag;
  }

  if (pos < textSegment.length) {
    result += escapeHtml(textSegment.slice(pos));
  }

  return result;
}

interface LineInfo {
  text: string;
  offset: number;
  blockKind?: string;
  blockPayload?: string;
}

export function buildStyledText(text: string, marks: StyleMark[]): string {
  if (text.length === 0) return "";

  // If no marks at all, just escape
  if (marks.length === 0) return escapeHtml(text);

  const hasBlock = marks.some((m) => BLOCK_KINDS.has(m.kind));
  const hasInline = marks.some((m) => INLINE_KINDS.has(m.kind));

  // If only inline marks (no block), use the original inline-only path
  if (!hasBlock) {
    return applyInlineMarks(text, marks, 0);
  }

  // Split into lines and determine block type for each
  const lines = text.split("\n");
  const lineInfos: LineInfo[] = [];
  let lineOffset = 0;
  for (const line of lines) {
    const lineStart = lineOffset;
    const lineEnd = lineStart + line.length;
    const blockMark = marks.find(
      (m) => BLOCK_KINDS.has(m.kind) && m.char_start < lineEnd && m.char_end > lineStart,
    );
    lineInfos.push({
      text: line,
      offset: lineStart,
      blockKind: blockMark?.kind,
      blockPayload: blockMark?.payload,
    });
    lineOffset = lineEnd + 1;
  }

  // Build HTML, grouping consecutive list items
  let html = "";
  let i = 0;
  let inList = false;
  let listType = "";

  while (i < lineInfos.length) {
    const info = lineInfos[i];

    // Close list if current line is not a list item
    if (inList && info.blockKind !== "list_item") {
      html += `</${listType}>`;
      inList = false;
    }

    const lineHtml = hasInline
      ? applyInlineMarks(info.text, marks, info.offset)
      : escapeHtml(info.text);

    if (info.blockKind === "heading") {
      const level = info.blockPayload ? (JSON.parse(info.blockPayload).level as number) || 1 : 1;
      html += `<h${level}>${lineHtml}</h${level}>`;
    } else if (info.blockKind === "list_item") {
      const payload = info.blockPayload ? JSON.parse(info.blockPayload) : { type: "bullet" };
      const type = payload.type === "ordered" ? "ol" : "ul";
      if (!inList || listType !== type) {
        if (inList) html += `</${listType}>`;
        html += `<${type}>`;
        inList = true;
        listType = type;
      }
      html += `<li>${lineHtml}</li>`;
    } else if (info.blockKind === "blockquote") {
      html += `<blockquote>${lineHtml}</blockquote>`;
    } else if (info.blockKind === "code_block") {
      html += `<pre><code>${escapeHtml(info.text)}</code></pre>`;
    } else {
      html += `<p>${lineHtml}</p>`;
    }
    i++;
  }

  if (inList) html += `</${listType}>`;

  return html;
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
    range.selectNodeContents(lastChild);
    range.collapse(false);
    const sel = window.getSelection();
    if (sel) {
      sel.removeAllRanges();
      sel.addRange(range);
    }
  }
}
