export interface OutlineEntry {
  level: number;
  charPos: number;
  label: string;
  kind: "heading" | "paragraph";
}

const MAX_LABEL = 64;

function makeLabel(text: string): string {
  const collapsed = text.replace(/\s+/g, " ").trim();
  if (!collapsed) return "(blank)";
  if (collapsed.length <= MAX_LABEL) return collapsed;
  return collapsed.slice(0, MAX_LABEL - 1).trimEnd() + "\u2026";
}

/**
 * Build a document outline from plain text.
 *
 * Depth comes from markdown-style heading markers (`#`, `##`, `###`)
 * that documents already support (see styled-text.ts detectLineBlock).
 * Headings become nested entries; plain paragraphs become flat entries
 * at one level deeper than the heading they follow, so a headingless
 * document still gets a complete, navigable flat outline.
 *
 * Blank lines are skipped. List items, blockquotes, and code blocks are
 * treated as paragraphs (their marker prefixes are stripped from the
 * label).
 */
export function buildOutline(text: string): OutlineEntry[] {
  const entries: OutlineEntry[] = [];
  let pos = 0;
  let currentHeadingLevel = 0;
  let inCodeFence = false;

  const lines = text.split("\n");
  for (const line of lines) {
    const lineStart = pos;
    pos += line.length + 1;

    if (line.startsWith("```")) {
      inCodeFence = !inCodeFence;
      continue;
    }
    if (inCodeFence) continue;

    const marker = detectOutlineBlock(line);
    if (marker.type === "heading") {
      currentHeadingLevel = marker.level ?? 1;
      entries.push({
        level: currentHeadingLevel,
        charPos: lineStart,
        label: makeLabel(line.slice(marker.contentStart)),
        kind: "heading",
      });
      continue;
    }
    const body = marker.contentStart > 0 ? line.slice(marker.contentStart) : line;
    if (!body.trim()) continue;

    entries.push({
      level: currentHeadingLevel + 1,
      charPos: lineStart,
      label: makeLabel(body),
      kind: "paragraph",
    });
  }
  return entries;
}

interface OutlineBlock {
  type: "heading" | "list_item" | "blockquote" | "code_fence" | "paragraph" | null;
  level?: number;
  contentStart: number;
}

function detectOutlineBlock(line: string): OutlineBlock {
  if (line.startsWith("### ")) return { type: "heading", level: 3, contentStart: 4 };
  if (line.startsWith("## ")) return { type: "heading", level: 2, contentStart: 3 };
  if (line.startsWith("# ")) return { type: "heading", level: 1, contentStart: 2 };
  if (line.startsWith("- ") || line.startsWith("* ")) return { type: "list_item", contentStart: 2 };
  if (/^\d+\.\s/.test(line)) {
    const m = line.match(/^(\d+)\.\s/)!;
    return { type: "list_item", contentStart: m[0].length };
  }
  if (line.startsWith("> ")) return { type: "blockquote", contentStart: 2 };
  if (line.startsWith("```")) return { type: "code_fence", contentStart: 3 };
  return { type: "paragraph", contentStart: 0 };
}

/**
 * Minimum indent level in a set of entries — lets the panel normalize
 * so the shallowest heading sits at the left edge regardless of whether
 * the document starts with `#` or jumps straight to `##`.
 */
export function normalizeLevels(entries: OutlineEntry[]): OutlineEntry[] {
  const min = entries.reduce((m, e) => Math.min(m, e.level), Infinity);
  if (!Number.isFinite(min) || min <= 1) return entries;
  return entries.map((e) => ({ ...e, level: e.level - (min - 1) }));
}
