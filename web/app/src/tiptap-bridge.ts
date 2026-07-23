import type { AnnotationEntry } from "./api/crdt_sync";

export interface TipTapTextNode {
  type: "text";
  text: string;
  marks?: Array<{ type: string; attrs?: Record<string, unknown> }>;
}

export interface TipTapParagraph {
  type: "paragraph";
  content: TipTapTextNode[];
}

export interface TipTapDoc {
  type: "doc";
  content: TipTapParagraph[];
}

export interface MarkRange {
  kind: string;
  start: number;
  end: number;
}

const STYLE_KINDS = new Set(["bold", "italic", "code"]);

export function extractMarkRanges(annotations: AnnotationEntry[]): MarkRange[] {
  return annotations
    .filter((a) => STYLE_KINDS.has(a.kind))
    .map((a) => ({ kind: a.kind, start: a.char_start, end: a.char_end }));
}

export function textToTipTapDoc(text: string, annotations: AnnotationEntry[]): TipTapDoc {
  const marks = extractMarkRanges(annotations);
  const lines = text.split("\n");
  const paragraphs: TipTapParagraph[] = [];
  let lineOffset = 0;

  for (const line of lines) {
    const lineStart = lineOffset;
    const lineEnd = lineStart + line.length;
    const content = buildTextNodes(line, lineStart, lineEnd, marks);
    paragraphs.push({ type: "paragraph", content });
    lineOffset = lineEnd + 1;
  }

  if (paragraphs.length === 0) {
    paragraphs.push({ type: "paragraph", content: [] });
  }
  return { type: "doc", content: paragraphs };
}

function buildTextNodes(
  lineText: string,
  lineStart: number,
  lineEnd: number,
  marks: MarkRange[],
): TipTapTextNode[] {
  if (lineText.length === 0) return [];

  const active = marks.filter((m) => m.start < lineEnd && m.end > lineStart);
  if (active.length === 0) {
    return [{ type: "text", text: lineText }];
  }

  const boundaries = new Set<number>();
  boundaries.add(0);
  boundaries.add(lineText.length);
  for (const m of active) {
    boundaries.add(Math.max(0, m.start - lineStart));
    boundaries.add(Math.min(lineText.length, m.end - lineStart));
  }
  const points = [...boundaries].sort((a, b) => a - b);
  const nodes: TipTapTextNode[] = [];

  for (let i = 0; i < points.length - 1; i++) {
    const segStart = points[i];
    const segEnd = points[i + 1];
    if (segStart >= segEnd) continue;
    const segText = lineText.slice(segStart, segEnd);
    if (segText.length === 0) continue;

    const segMarks: Array<{ type: string }> = [];
    for (const m of active) {
      const mStart = Math.max(0, m.start - lineStart);
      const mEnd = Math.min(lineText.length, m.end - lineStart);
      if (mStart <= segStart && mEnd >= segEnd) {
        segMarks.push({ type: m.kind });
      }
    }
    nodes.push({
      type: "text",
      text: segText,
      ...(segMarks.length > 0 ? { marks: segMarks } : {}),
    });
  }

  return nodes.length > 0 ? nodes : [{ type: "text", text: lineText }];
}

export function tiptapDocToText(doc: TipTapDoc): { text: string; marks: MarkRange[] } {
  const textParts: string[] = [];
  const marks: MarkRange[] = [];
  let charPos = 0;

  for (let i = 0; i < doc.content.length; i++) {
    if (i > 0) {
      textParts.push("\n");
      charPos++;
    }
    const para = doc.content[i];
    if (!para.content || para.content.length === 0) continue;
    for (const node of para.content) {
      const start = charPos;
      textParts.push(node.text);
      charPos += node.text.length;
      if (node.marks) {
        for (const m of node.marks) {
          if (STYLE_KINDS.has(m.type)) {
            marks.push({ kind: m.type, start, end: charPos });
          }
        }
      }
    }
  }

  return { text: textParts.join(""), marks };
}
