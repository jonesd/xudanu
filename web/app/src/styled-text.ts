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

// === ORIGINAL buildStyledText — untouched, handles inline marks only ===
function buildInlineHtml(text: string, marks: StyleMark[]): string {
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

// === Block-aware buildStyledText ===
// If no block marks, delegates to original inline-only logic.
// If block marks exist, wraps lines in block tags, applies inline marks within each line.
export function buildStyledText(text: string, marks: StyleMark[]): string {
  if (marks.length === 0 || text.length === 0) {
    return escapeHtml(text);
  }

  const inlineMarks = marks.filter((m) => INLINE_KINDS.has(m.kind));
  const blockMarks = marks.filter((m) => BLOCK_KINDS.has(m.kind));

  // No block marks — use original inline logic exactly
  if (blockMarks.length === 0) {
    return buildInlineHtml(text, inlineMarks);
  }

  // Split into lines and determine block type for each
  const lines = text.split("\n");
  let html = "";
  let inList = false;
  let listType = "";
  let lineOffset = 0;

  for (let i = 0; i < lines.length; i++) {
    const lineText = lines[i];
    const lineStart = lineOffset;
    const lineEnd = lineStart + lineText.length;

    const blockMark = blockMarks.find(
      (m) => m.char_start < lineEnd && m.char_end > lineStart,
    );

    // Close list if current line is not a list item
    if (inList && blockMark?.kind !== "list_item") {
      html += `</${listType}>`;
      inList = false;
    }

    // Apply inline marks to this line's text
    const lineHtml = inlineMarks.length > 0
      ? buildInlineHtml(lineText, inlineMarks.map((m) => ({
          ...m,
          char_start: m.char_start - lineStart,
          char_end: m.char_end - lineStart,
        })))
      : escapeHtml(lineText);

    if (blockMark?.kind === "heading") {
      const level = blockMark.payload ? (() => { try { return JSON.parse(blockMark.payload!).level || 1; } catch { return 1; } })() : 1;
      html += `<h${level}>${lineHtml}</h${level}>`;
    } else if (blockMark?.kind === "list_item") {
      let type = "ul";
      try { if (JSON.parse(blockMark.payload || "{}").type === "ordered") type = "ol"; } catch {}
      if (!inList || listType !== type) {
        if (inList) html += `</${listType}>`;
        html += `<${type}>`;
        inList = true;
        listType = type;
      }
      html += `<li>${lineHtml}</li>`;
    } else if (blockMark?.kind === "blockquote") {
      html += `<blockquote>${lineHtml}</blockquote>`;
    } else if (blockMark?.kind === "code_block") {
      html += `<pre><code>${escapeHtml(lineText)}</code></pre>`;
    } else {
      html += `<p>${lineHtml}</p>`;
    }

    lineOffset = lineEnd + 1;
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
