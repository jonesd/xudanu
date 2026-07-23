import type { AnnotationEntry } from "./api/crdt_sync";

interface DocNode {
  type: string;
  text?: string;
  attrs?: Record<string, unknown>;
  marks?: Array<{ type: string; attrs?: Record<string, unknown> }>;
  content?: DocNode[];
}

export interface TipTapDoc {
  type: "doc";
  content: DocNode[];
}

export interface MarkRange {
  kind: string;
  start: number;
  end: number;
  payload?: string;
}

const INLINE_KINDS = new Set(["bold", "italic", "code"]);
const BLOCK_KINDS = new Set(["heading", "list_item", "blockquote", "code_block"]);

interface FlattenState {
  text: string;
  pos: number;
  inlineMarks: MarkRange[];
  blockMarks: MarkRange[];
}

export function extractAllMarks(annotations: AnnotationEntry[]): MarkRange[] {
  return annotations
    .filter((a) => INLINE_KINDS.has(a.kind) || BLOCK_KINDS.has(a.kind))
    .map((a) => ({
      kind: a.kind,
      start: a.char_start,
      end: a.char_end,
      ...(a.payload ? { payload: a.payload } : {}),
    }));
}

export function tiptapDocToText(doc: TipTapDoc): { text: string; marks: MarkRange[] } {
  const state: FlattenState = { text: "", pos: 0, inlineMarks: [], blockMarks: [] };

  const children = doc.content || [];
  for (let i = 0; i < children.length; i++) {
    if (i > 0) {
      state.text += "\n";
      state.pos++;
    }
    flattenBlock(children[i], state);
  }

  return {
    text: state.text,
    marks: [...state.inlineMarks, ...state.blockMarks],
  };
}

function flattenBlock(node: DocNode, state: FlattenState): void {
  const startPos = state.pos;

  switch (node.type) {
    case "paragraph":
      flattenInline(node.content || [], state);
      break;

    case "heading": {
      flattenInline(node.content || [], state);
      state.blockMarks.push({
        kind: "heading",
        start: startPos,
        end: state.pos,
        payload: JSON.stringify({ level: (node.attrs?.level as number) || 1 }),
      });
      break;
    }

    case "blockquote": {
      const inner = node.content || [];
      for (let i = 0; i < inner.length; i++) {
        if (i > 0) {
          state.text += "\n";
          state.pos++;
        }
        const childStart = state.pos;
        flattenBlock(inner[i], state);
        state.blockMarks.push({
          kind: "blockquote",
          start: childStart,
          end: state.pos,
        });
      }
      break;
    }

    case "bulletList":
    case "orderedList": {
      const items = node.content || [];
      for (let i = 0; i < items.length; i++) {
        if (i > 0) {
          state.text += "\n";
          state.pos++;
        }
        const itemStart = state.pos;
        const listItem = items[i];
        const inner = listItem.content || [];
        for (const child of inner) {
          if (child.type === "paragraph") {
            flattenInline(child.content || [], state);
          } else {
            flattenBlock(child, state);
          }
        }
        state.blockMarks.push({
          kind: "list_item",
          start: itemStart,
          end: state.pos,
          payload: JSON.stringify({
            type: node.type === "bulletList" ? "bullet" : "ordered",
          }),
        });
      }
      break;
    }

    case "codeBlock": {
      const inner = node.content || [];
      for (const child of inner) {
        if (child.text) {
          state.text += child.text;
          state.pos += child.text.length;
        }
      }
      state.blockMarks.push({
        kind: "code_block",
        start: startPos,
        end: state.pos,
        payload: JSON.stringify({ language: (node.attrs?.language as string) || "" }),
      });
      break;
    }

    default:
      flattenInline(node.content || [], state);
  }
}

function flattenInline(content: DocNode[], state: FlattenState): void {
  for (const node of content) {
    if (node.type === "text" && node.text) {
      const start = state.pos;
      state.text += node.text;
      state.pos += node.text.length;
      if (node.marks) {
        for (const m of node.marks) {
          if (INLINE_KINDS.has(m.type)) {
            state.inlineMarks.push({ kind: m.type, start, end: state.pos });
          }
        }
      }
    } else if (node.type === "hardBreak") {
      state.text += "\n";
      state.pos++;
    }
  }
}

interface LineInfo {
  text: string;
  offset: number;
  blockKind?: string;
  blockPayload?: string;
}

export function textToTipTapDoc(text: string, annotations: AnnotationEntry[]): TipTapDoc {
  const lines = text.split("\n");
  const allMarks = extractAllMarks(annotations);

  const lineInfos: LineInfo[] = [];
  let lineOffset = 0;
  for (const line of lines) {
    const lineStart = lineOffset;
    const lineEnd = lineStart + line.length;
    const blockMark = allMarks.find(
      (m) =>
        BLOCK_KINDS.has(m.kind) &&
        m.start <= lineStart &&
        m.end >= lineEnd,
    );
    lineInfos.push({
      text: line,
      offset: lineStart,
      blockKind: blockMark?.kind,
      blockPayload: blockMark?.payload,
    });
    lineOffset = lineEnd + 1;
  }

  const content: DocNode[] = [];
  let i = 0;
  while (i < lineInfos.length) {
    const info = lineInfos[i];
    const inlineMarks = allMarks.filter(
      (m) => INLINE_KINDS.has(m.kind) && m.start < info.offset + info.text.length && m.end > info.offset,
    );

    if (info.blockKind === "heading") {
      const level = info.blockPayload ? (JSON.parse(info.blockPayload).level as number) || 1 : 1;
      content.push({
        type: "heading",
        attrs: { level },
        content: buildTextNodes(info.text, info.offset, inlineMarks),
      });
      i++;
    } else if (info.blockKind === "blockquote") {
      content.push({
        type: "blockquote",
        content: [{
          type: "paragraph",
          content: buildTextNodes(info.text, info.offset, inlineMarks),
        }],
      });
      i++;
    } else if (info.blockKind === "code_block") {
      content.push({
        type: "codeBlock",
        attrs: info.blockPayload
          ? { language: (JSON.parse(info.blockPayload).language as string) || "" }
          : { language: "" },
        content: info.text.length > 0 ? [{ type: "text", text: info.text }] : [],
      });
      i++;
    } else if (info.blockKind === "list_item") {
      const listType = info.blockPayload
        ? (JSON.parse(info.blockPayload).type as string) || "bullet"
        : "bullet";
      const items: DocNode[] = [];
      while (i < lineInfos.length && lineInfos[i].blockKind === "list_item") {
        const liInfo = lineInfos[i];
        const liMarks = allMarks.filter(
          (m) => INLINE_KINDS.has(m.kind) && m.start < liInfo.offset + liInfo.text.length && m.end > liInfo.offset,
        );
        items.push({
          type: "listItem",
          content: [{
            type: "paragraph",
            content: buildTextNodes(liInfo.text, liInfo.offset, liMarks),
          }],
        });
        i++;
      }
      content.push({
        type: listType === "ordered" ? "orderedList" : "bulletList",
        content: items,
      });
    } else {
      content.push({
        type: "paragraph",
        content: buildTextNodes(info.text, info.offset, inlineMarks),
      });
      i++;
    }
  }

  if (content.length === 0) {
    content.push({ type: "paragraph", content: [] });
  }
  return { type: "doc", content };
}

function buildTextNodes(
  lineText: string,
  lineOffset: number,
  marks: MarkRange[],
): DocNode[] {
  if (lineText.length === 0) return [];

  const active = marks.filter((m) => m.start < lineOffset + lineText.length && m.end > lineOffset);
  if (active.length === 0) {
    return [{ type: "text", text: lineText }];
  }

  const boundaries = new Set<number>();
  boundaries.add(0);
  boundaries.add(lineText.length);
  for (const m of active) {
    boundaries.add(Math.max(0, m.start - lineOffset));
    boundaries.add(Math.min(lineText.length, m.end - lineOffset));
  }
  const points = [...boundaries].sort((a, b) => a - b);
  const nodes: DocNode[] = [];

  for (let j = 0; j < points.length - 1; j++) {
    const segStart = points[j];
    const segEnd = points[j + 1];
    if (segStart >= segEnd) continue;
    const segText = lineText.slice(segStart, segEnd);
    if (!segText) continue;

    const segMarks: Array<{ type: string }> = [];
    for (const m of active) {
      const mStart = Math.max(0, m.start - lineOffset);
      const mEnd = Math.min(lineText.length, m.end - lineOffset);
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

export function diffAnnotations(
  current: AnnotationEntry[],
  desired: MarkRange[],
): {
  toCreate: MarkRange[];
  toDelete: AnnotationEntry[];
} {
  const toCreate: MarkRange[] = [];
  const toDelete: AnnotationEntry[] = [];
  const used = new Set<number>();

  for (const dm of desired) {
    const idx = current.findIndex(
      (a, i) =>
        !used.has(i) &&
        a.kind === dm.kind &&
        a.char_start === dm.start &&
        a.char_end === dm.end,
    );
    if (idx >= 0) {
      used.add(idx);
    } else {
      toCreate.push(dm);
    }
  }

  current.forEach((a, i) => {
    if (!used.has(i) && (INLINE_KINDS.has(a.kind) || BLOCK_KINDS.has(a.kind))) {
      toDelete.push(a);
    }
  });

  return { toCreate, toDelete };
}
