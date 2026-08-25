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

import { escapeHtml } from "./utils/escape";

// Render-time URL autolinking: URLs are self-describing text, so they are
// detected at display time — no stored annotations, no migration, and
// every existing/pasted document links up instantly. Links open in a new
// tab; the editor's contenteditable="false" spans keep the caret out.
const URL_RE = /\bhttps?:\/\/[^\s<>"')\]]+/g;

export function findUrls(text: string): Array<{ start: number; end: number; url: string }> {
  const out: Array<{ start: number; end: number; url: string }> = [];
  URL_RE.lastIndex = 0;
  let m: RegExpExecArray | null;
  while ((m = URL_RE.exec(text)) !== null) {
    // Trim trailing punctuation commonly glued to pasted URLs.
    let url = m[0];
    let end = m.index + url.length;
    while (/[.,;:!?)]$/.test(url)) {
      url = url.slice(0, -1);
      end -= 1;
    }
    if (url.length > "https://".length) {
      out.push({ start: m.index, end, url });
    }
  }
  return out;
}

export type LinkMode = "all" | "internal";

/** Wrap http(s) URLs in <a> tags within an HTML fragment (already-escaped
 * text). mode "internal" (server default) links ONLY same-origin URLs —
 * external URLs stay plain text, closing the external-navigation escape
 * hatch; internal links carry a distinct class so clicks navigate
 * in-app instead of opening a browser tab. */
export function autolinkEscaped(
  escapedHtml: string,
  opts?: { mode?: LinkMode; origin?: string },
): string {
  const mode = opts?.mode ?? "all";
  const origin = opts?.origin ?? (typeof window !== "undefined" ? window.location.origin : "");
  // Operate on the escaped string: URLs contain no <>&"' after escaping
  // (& became &amp; etc.), so match against the escaped forms.
  const re = /\b(https?:\/\/)([^\s&<]+(?:&amp;[^\s&<]*)*)/g;
  return escapedHtml.replace(re, (_whole, scheme, rest) => {
    let url = scheme + rest;
    let href = url;
    while (/[.,;:!?)]$/.test(href)) href = href.slice(0, -1);
    const shown = url.slice(0, href.length);
    const tail = url.slice(href.length);
    const internal = href.toLowerCase().startsWith(origin.toLowerCase() + "/");
    if (mode === "internal" && !internal) {
      return url; // external: leave as plain (escaped) text
    }
    const cls = internal ? "doc-autolink doc-autolink-internal" : "doc-autolink";
    return `<a href="${href}" target="_blank" rel="noopener noreferrer" class="${cls}">${shown}</a>${tail}`;
  });
}

interface Boundary {
  pos: number;
  type: "open" | "close";
  kind: string;
  openPos: number;
}

// === ORIGINAL inline marks logic — untouched ===
function buildInlineHtml(text: string, marks: StyleMark[], linkOpts?: { mode?: LinkMode; origin?: string }): string {
  if (marks.length === 0 || text.length === 0) {
    return autolinkEscaped(escapeHtml(text), linkOpts);
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
      result += autolinkEscaped(escapeHtml(text.slice(pos, b.pos)), linkOpts);
      pos = b.pos;
    }
    const tag = b.kind === "bold"
      ? (b.type === "open" ? "<strong>" : "</strong>")
      : (b.type === "open" ? "<em>" : "</em>");
    result += tag;
  }

  if (pos < text.length) {
    result += autolinkEscaped(escapeHtml(text.slice(pos)), linkOpts);
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

export function buildStyledText(
  text: string,
  marks: StyleMark[],
  linkOpts?: { mode?: LinkMode; origin?: string },
): string {
  if (text.length === 0) return "";

  const inlineMarks = marks.filter((m) => INLINE_KINDS.has(m.kind));
  const annBlockMarks = marks.filter((m) => BLOCK_KINDS.has(m.kind));

  // Split into lines
  const lines = text.split("\n");
  let html = "";
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
    const contentStart = marker.contentStart;

    if (!blockType && annBlockMarks.length > 0) {
      const ann = annBlockMarks.find(
        (m) => m.char_start <= lineEnd && m.char_end >= lineStart,
      );
      if (ann) {
        blockType = ann.kind as Exclude<LineBlock["type"], null>;
        if (ann.kind === "heading") {
          try { level = JSON.parse(ann.payload || "{}").level || 1; } catch { level = 1; }
        }
        if (ann.kind === "list_item") {
          try { listKind = JSON.parse(ann.payload || "{}").type === "ordered" ? "ordered" : "bullet"; } catch { listKind = "bullet"; }
        }
      }
    }

    // The visible text (strip marker prefix if detected from marker)
    const displayText = marker.type ? lineText.slice(contentStart) : lineText;
    // Wrap the marker in a hidden span so textContent preserves it
    const markerHtml = marker.type ? `<span style="display:none" contenteditable="false">${escapeHtml(lineText.slice(0, contentStart))}</span>` : "";
    const displayOffset = marker.type ? lineStart + contentStart : lineStart;

    // Apply inline marks to the display text
    const lineHtml = inlineMarks.length > 0
      ? buildInlineHtml(displayText, inlineMarks.map((m) => ({
          ...m,
          char_start: m.char_start - displayOffset,
          char_end: m.char_end - displayOffset,
        })).filter((m) => m.char_end > 0 && m.char_start < displayText.length), linkOpts)
      : autolinkEscaped(escapeHtml(displayText), linkOpts);

    // Use inline spans — NOT block tags. Block tags break contentEditable Enter behavior.
    // All decorative/marker spans get contenteditable="false" so the cursor can't land
    // inside them and corrupt the text.
    if (blockType === "heading") {
      const lv = level || 1;
      const sizes: Record<number, string> = { 1: "1.8em", 2: "1.5em", 3: "1.2em" };
      const weights: Record<number, string> = { 1: "700", 2: "700", 3: "600" };
      html += `<span style="display:none" contenteditable="false">${escapeHtml(lineText.slice(0, contentStart))}</span><span style="font-size:${sizes[lv] || "1.8em"};font-weight:${weights[lv] || "700"}">${lineHtml}</span>`;
    } else if (blockType === "list_item") {
      const bullet = listKind === "ordered" ? "&#9312;" : "&bull;";
      html += `<span style="display:none" contenteditable="false">${escapeHtml(lineText.slice(0, contentStart))}</span><span style="display:inline-block;width:18px;user-select:none;margin-right:4px;" contenteditable="false">${bullet}</span><span>${lineHtml}</span>`;
    } else if (blockType === "blockquote") {
      html += `<span style="display:none" contenteditable="false">${escapeHtml(lineText.slice(0, contentStart))}</span><span style="border-left:3px solid #58a6ff;padding-left:12px;color:#999;">${lineHtml}</span>`;
    } else if (blockType === "code_block") {
      html += `<span style="display:none" contenteditable="false">${escapeHtml(lineText.slice(0, contentStart))}</span><span style="font-family:monospace;background:rgba(255,255,255,0.06);padding:2px 6px;border-radius:3px;">${escapeHtml(displayText)}</span>`;
    } else {
      // Plain line — no wrapper, just the text (preserves pre-wrap newline behavior)
      html += `${markerHtml}${lineHtml}`;
    }

    // Add newline between lines (not after the last one)
    if (i < lines.length - 1) {
      html += "\n";
    }

    lineOffset = lineEnd + 1;
  }

  return html;
}

/**
 * The single caret authority (FR: editor caret centralization).
 *
 * Sets the caret to a MODEL offset — a position in the text as the
 * CRDT/save layer sees it, including hidden markers like "- " — and
 * guarantees the resulting DOM selection:
 *   1. never rests inside a contenteditable=false span (markers,
 *      inline images) — typing there dies silently;
 *   2. never rests at a boundary that precedes a marker span for
 *      offsets >= marker length (the click/toggle/Enter bug class);
 *   3. maps through the same tree-walk getCursorOffset uses, so
 *      setCaretModel(el, getCursorOffset(el)) is a stable identity
 *      except for the escape corrections.
 *
 * All editor code paths that reposition the caret (Enter inserts,
 * toolbar toggles, rebuild restores, click corrections, undo) must
 * route through this function.
 */
export function setCaretModel(el: HTMLElement, modelOffset: number): void {
  const sel = window.getSelection();
  if (!sel) return;

  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
  const editorScope = el;
  let node: Node | null;
  let remaining = Math.max(0, modelOffset);

  while ((node = walker.nextNode())) {
    // Skip text inside non-editable spans (hidden markers etc.):
    // their characters count in the MODEL but are not caret targets.
    const parent = node.parentElement;
    if (parent && parent.closest("[contenteditable=\"false\"]") && editorScope.contains(parent)) {
      // Hidden marker spans (display:none) carry model text ("- ") —
      // consume their length. Visible glyphs (the bullet •) are
      // DOM-only decorations — skip WITHOUT consuming.
      const hiddenSpan = parent.closest("[contenteditable=\"false\"]") as HTMLElement | null;
      const isHidden = hiddenSpan?.style?.display === "none" ||
        (parent.style?.display === "none");
      if (isHidden) {
        remaining -= node.textContent?.length ?? 0;
      }
      continue;
    }
    const len = node.textContent?.length ?? 0;
    if (remaining <= len) {
      const range = document.createRange();
      range.setStart(node, Math.max(0, Math.min(remaining, len)));
      range.collapse(true);
      sel.removeAllRanges();
      sel.addRange(range);
      escapeNonEditable(sel, editorScope);
      return;
    }
    remaining -= len;
  }

  // Offset at/after end: anchor after the last EDITABLE content,
  // never inside a trailing marker.
  const lastEditable = lastEditableDescendant(el);
  if (lastEditable) {
    const range = document.createRange();
    if (lastEditable.nodeType === Node.TEXT_NODE) {
      range.setStart(lastEditable, lastEditable.textContent?.length ?? 0);
    } else {
      range.selectNodeContents(lastEditable);
      range.collapse(false);
    }
    sel.removeAllRanges();
    sel.addRange(range);
    escapeNonEditable(sel, editorScope);
  }
}

function escapeNonEditable(sel: Selection, scope: HTMLElement): void {
  let node: Node | null = sel.anchorNode;
  let guardian = 0;
  while (node && node !== scope && guardian < 32) {
    const parent = node.parentElement;
    if (parent && parent.getAttribute("contenteditable") === "false") {
      const after = document.createRange();
      const markerParent = parent;
      after.setStartAfter(markerParent);
      after.collapse(true);
      sel.removeAllRanges();
      sel.addRange(after);
      node = markerParent.parentElement;
      continue;
    }
    node = parent;
    guardian++;
  }
}

function lastEditableDescendant(el: HTMLElement): Node | null {
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
  let node: Node | null;
  let last: Node | null = null;
  while ((node = walker.nextNode())) {
    const parent = node.parentElement;
    if (parent && parent.closest("[contenteditable=\"false\"]") && el.contains(parent)) continue;
    last = node;
  }
  return last;
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
