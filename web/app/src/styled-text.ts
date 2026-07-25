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

// === ORIGINAL inline marks logic — untouched ===
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

// Detect block type from line prefix (Markdown-style markers in the text itself)
interface LineBlock {
  type: "heading" | "list_item" | "blockquote" | "code_block" | null;
  level?: number;
  listType?: "bullet" | "ordered";
  contentStart: number;
}

function detectLineBlock(line: string): LineBlock {
  if (line.startsWith("### ")) return { type: "heading", level: 3, contentStart: 4 };
  if (line.startsWith("## ")) return { type: "heading", level: 2, contentStart: 3 };
  if (line.startsWith("# ")) return { type: "heading", level: 1, contentStart: 2 };
  if (line.startsWith("- ") || line.startsWith("* ")) return { type: "list_item", listType: "bullet", contentStart: 2 };
  if (/^\d+\.\s/.test(line)) {
    const match = line.match(/^(\d+)\.\s/);
    return { type: "list_item", listType: "ordered", contentStart: match![0].length };
  }
  if (line.startsWith("> ")) return { type: "blockquote", contentStart: 2 };
  if (line.startsWith("```")) return { type: "code_block", contentStart: 3 };
  return { type: null, contentStart: 0 };
}

export function buildStyledText(text: string, marks: StyleMark[]): string {
  if (text.length === 0) return "";

  const inlineMarks = marks.filter((m) => INLINE_KINDS.has(m.kind));
  const annBlockMarks = marks.filter((m) => BLOCK_KINDS.has(m.kind));

  // Split into lines
  const lines = text.split("\n");
  let html = "";
  let inList = false;
  let listType = "";
  let lineOffset = 0;

  for (let i = 0; i < lines.length; i++) {
    const lineText = lines[i];
    const lineStart = lineOffset;
    const lineEnd = lineStart + lineText.length;

    // Determine block type: try marker prefix first, then annotation
    const marker = detectLineBlock(lineText);
    let blockType = marker.type;
    let level = marker.level;
    let listKind = marker.listType;
    let contentStart = marker.contentStart;

    if (!blockType && annBlockMarks.length > 0) {
      const ann = annBlockMarks.find(
        (m) => m.char_start <= lineEnd && m.char_end >= lineStart,
      );
      if (ann) {
        blockType = ann.kind as any;
        if (ann.kind === "heading") {
          try { level = JSON.parse(ann.payload || "{}").level || 1; } catch { level = 1; }
        }
        if (ann.kind === "list_item") {
          try { listKind = JSON.parse(ann.payload || "{}").type === "ordered" ? "ordered" : "bullet"; } catch { listKind = "bullet"; }
        }
      }
    }

    // Close list if current line is not a list item
    if (inList && blockType !== "list_item") {
      html += `</${listType}>`;
      inList = false;
    }

    // The visible text (strip marker prefix if detected from marker)
    const displayText = marker.type ? lineText.slice(contentStart) : lineText;
    const displayOffset = marker.type ? lineStart + contentStart : lineStart;

    // Apply inline marks to the display text
    const lineHtml = inlineMarks.length > 0
      ? buildInlineHtml(displayText, inlineMarks.map((m) => ({
          ...m,
          char_start: m.char_start - displayOffset,
          char_end: m.char_end - displayOffset,
        })).filter((m) => m.char_end > 0 && m.char_start < displayText.length))
      : escapeHtml(displayText);

    if (blockType === "heading") {
      const lv = level || 1;
      html += `<h${lv}>${lineHtml}</h${lv}>`;
    } else if (blockType === "list_item") {
      const lt = listKind === "ordered" ? "ol" : "ul";
      if (!inList || listType !== lt) {
        if (inList) html += `</${listType}>`;
        html += `<${lt}>`;
        inList = true;
        listType = lt;
      }
      html += `<li>${lineHtml}</li>`;
    } else if (blockType === "blockquote") {
      html += `<blockquote>${lineHtml}</blockquote>`;
    } else if (blockType === "code_block") {
      html += `<pre><code>${escapeHtml(displayText)}</code></pre>`;
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
