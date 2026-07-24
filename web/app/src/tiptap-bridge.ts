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

const INLINE_KINDS = new Set(["bold", "italic", "code", "font_size", "font_family", "image"]);
const BLOCK_KINDS = new Set(["heading", "list_item", "blockquote", "code_block", "text_align"]);

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
      captureTextAlign(node, startPos, state.pos, state);
      break;

    case "heading": {
      flattenInline(node.content || [], state);
      state.blockMarks.push({
        kind: "heading",
        start: startPos,
        end: state.pos,
        payload: JSON.stringify({ level: (node.attrs?.level as number) || 1 }),
      });
      captureTextAlign(node, startPos, state.pos, state);
      break;
    }

    case "blockquote": {
      const blockStart = state.pos;
      const inner = node.content || [];
      for (let i = 0; i < inner.length; i++) {
        if (i > 0) {
          state.text += "\n";
          state.pos++;
        }
        flattenBlock(inner[i], state);
      }
      if (state.pos > blockStart) {
        state.blockMarks.push({
          kind: "blockquote",
          start: blockStart,
          end: state.pos,
        });
      }
      break;
    }

    case "bulletList":
    case "orderedList": {
      const listStart = state.pos;
      const items = node.content || [];
      for (let i = 0; i < items.length; i++) {
        if (i > 0) {
          state.text += "\n";
          state.pos++;
        }
        const listItem = items[i];
        const inner = listItem.content || [];
        for (const child of inner) {
          if (child.type === "paragraph") {
            flattenInline(child.content || [], state);
          } else {
            flattenBlock(child, state);
          }
        }
      }
      if (state.pos > listStart) {
        state.blockMarks.push({
          kind: "list_item",
          start: listStart,
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

function captureTextAlign(node: DocNode, start: number, end: number, state: FlattenState): void {
  const align = node.attrs?.textAlign as string | undefined;
  if (align && align !== "left") {
    state.blockMarks.push({
      kind: "text_align",
      start,
      end,
      payload: JSON.stringify({ align }),
    });
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
          if (m.type === "textStyle" && m.attrs) {
            if (m.attrs.fontSize) {
              const px = parseInt(String(m.attrs.fontSize).replace("px", ""), 10);
              if (px > 0) {
                state.inlineMarks.push({
                  kind: "font_size",
                  start,
                  end: state.pos,
                  payload: JSON.stringify({ px }),
                });
              }
            }
            if (m.attrs.fontFamily) {
              state.inlineMarks.push({
                kind: "font_family",
                start,
                end: state.pos,
                payload: JSON.stringify({ family: m.attrs.fontFamily }),
              });
            }
          }
        }
      }
    } else if (node.type === "hardBreak") {
      state.text += "\n";
      state.pos++;
    } else if (node.type === "image" && node.attrs?.src) {
      const src = node.attrs.src as string;
      const hashMatch = src.match(/\/blobs\/([0-9a-f]+)\/preview/);
      if (hashMatch) {
        state.inlineMarks.push({
          kind: "image",
          start: state.pos,
          end: state.pos,
          payload: JSON.stringify({ hash: hashMatch[1] }),
        });
      }
    }
  }
}

interface LineInfo {
  text: string;
  offset: number;
  blockKind?: string;
  blockPayload?: string;
  textAlign?: string;
}

export function textToTipTapDoc(text: string, annotations: AnnotationEntry[]): TipTapDoc {
  const lines = text.split("\n");
  const allMarks = extractAllMarks(annotations);

  const lineInfos: LineInfo[] = [];
  let lineOffset = 0;
  for (const line of lines) {
    const lineStart = lineOffset;
    const lineEnd = lineStart + line.length;
    const lineBlockMarks = allMarks.filter(
      (m) =>
        BLOCK_KINDS.has(m.kind) &&
        m.start <= lineStart &&
        m.end >= lineEnd,
    );
    const structMark = lineBlockMarks.find((m) => m.kind !== "text_align");
    const alignMark = lineBlockMarks.find((m) => m.kind === "text_align");
    lineInfos.push({
      text: line,
      offset: lineStart,
      blockKind: structMark?.kind,
      blockPayload: structMark?.payload,
      textAlign: alignMark ? (JSON.parse(alignMark.payload || "{}").align as string) : undefined,
    });
    lineOffset = lineEnd + 1;
  }

  const content: DocNode[] = [];
  let i = 0;
  while (i < lineInfos.length) {
    const info = lineInfos[i];

    if (info.blockKind === "heading") {
      const inlineMarks = marksForLine(allMarks, info);
      const level = info.blockPayload ? (JSON.parse(info.blockPayload).level as number) || 1 : 1;
      content.push({
        type: "heading",
        attrs: { level, ...(info.textAlign ? { textAlign: info.textAlign } : {}) },
        content: buildTextNodes(info.text, info.offset, inlineMarks),
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
    } else if (info.blockKind === "blockquote") {
      const paras: DocNode[] = [];
      while (i < lineInfos.length && lineInfos[i].blockKind === "blockquote") {
        const li = lineInfos[i];
        paras.push({
          type: "paragraph",
          attrs: li.textAlign ? { textAlign: li.textAlign } : undefined,
          content: buildTextNodes(li.text, li.offset, marksForLine(allMarks, li)),
        });
        i++;
      }
      content.push({ type: "blockquote", content: paras });
    } else if (info.blockKind === "list_item") {
      const listType = info.blockPayload
        ? (JSON.parse(info.blockPayload).type as string) || "bullet"
        : "bullet";
      const items: DocNode[] = [];
      while (i < lineInfos.length && lineInfos[i].blockKind === "list_item") {
        const li = lineInfos[i];
        items.push({
          type: "listItem",
          content: [{
            type: "paragraph",
            attrs: li.textAlign ? { textAlign: li.textAlign } : undefined,
            content: buildTextNodes(li.text, li.offset, marksForLine(allMarks, li)),
          }],
        });
        i++;
      }
      content.push({
        type: listType === "ordered" ? "orderedList" : "bulletList",
        content: items,
      });
    } else {
      const inlineMarks = marksForLine(allMarks, info);
      content.push({
        type: "paragraph",
        attrs: info.textAlign ? { textAlign: info.textAlign } : undefined,
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

function marksForLine(allMarks: MarkRange[], info: LineInfo): MarkRange[] {
  return allMarks.filter(
    (m) => {
      if (m.kind === "image") {
        // Zero-width: position must be within the line
        return m.start >= info.offset && m.start <= info.offset + info.text.length;
      }
      return INLINE_KINDS.has(m.kind) &&
        m.start < info.offset + info.text.length &&
        m.end > info.offset;
    },
  );
}

function buildTextNodes(
  lineText: string,
  lineOffset: number,
  marks: MarkRange[],
): DocNode[] {
  if (lineText.length === 0 && marks.length === 0) return [];

  const imageMarks = marks.filter((m) => m.kind === "image");
  const textMarks = marks.filter((m) => m.kind !== "image");

  // Handle lines with only images (no text)
  if (lineText.length === 0) {
    return imageMarks.map((m) => {
      const p = JSON.parse(m.payload || "{}");
      return { type: "image", attrs: { src: `/blobs/${p.hash}/preview` } };
    });
  }

  const active = textMarks.filter((m) => m.start < lineOffset + lineText.length && m.end > lineOffset);
  if (active.length === 0 && imageMarks.length === 0) {
    return [{ type: "text", text: lineText }];
  }

  // Build boundary points from text marks AND image positions
  const boundaries = new Set<number>();
  boundaries.add(0);
  boundaries.add(lineText.length);
  for (const m of active) {
    boundaries.add(Math.max(0, m.start - lineOffset));
    boundaries.add(Math.min(lineText.length, m.end - lineOffset));
  }
  // Image positions are points (zero-width) — add them as boundaries
  for (const m of imageMarks) {
    const imgPos = m.start - lineOffset;
    if (imgPos >= 0 && imgPos <= lineText.length) {
      boundaries.add(imgPos);
    }
  }
  const points = [...boundaries].sort((a, b) => a - b);
  const nodes: DocNode[] = [];

  for (let j = 0; j < points.length; j++) {
    const segStart = points[j];

    // Check for images at this position
    for (const m of imageMarks) {
      const imgPos = m.start - lineOffset;
      if (imgPos === segStart) {
        const p = JSON.parse(m.payload || "{}");
        nodes.push({ type: "image", attrs: { src: `/blobs/${p.hash}/preview` } });
      }
    }

    if (j >= points.length - 1) break;
    const segEnd = points[j + 1];
    if (segStart >= segEnd) continue;
    const segText = lineText.slice(segStart, segEnd);
    if (!segText) continue;

    const segMarks: Array<{ type: string; attrs?: Record<string, unknown> }> = [];
    const textStyleAttrs: Record<string, unknown> = {};
    for (const m of active) {
      const mStart = Math.max(0, m.start - lineOffset);
      const mEnd = Math.min(lineText.length, m.end - lineOffset);
      if (mStart <= segStart && mEnd >= segEnd) {
        if (m.kind === "font_size" && m.payload) {
          const px = JSON.parse(m.payload).px as number;
          if (px) textStyleAttrs.fontSize = `${px}px`;
        } else if (m.kind === "font_family" && m.payload) {
          const family = JSON.parse(m.payload).family as string;
          if (family) textStyleAttrs.fontFamily = family;
        } else {
          segMarks.push({ type: m.kind });
        }
      }
    }
    if (Object.keys(textStyleAttrs).length > 0) {
      segMarks.push({ type: "textStyle", attrs: textStyleAttrs });
    }
    nodes.push({
      type: "text",
      text: segText,
      ...(segMarks.length > 0 ? { marks: segMarks } : {}),
    });
  }

  // Check for images at the very end
  for (const m of imageMarks) {
    const imgPos = m.start - lineOffset;
    if (imgPos === lineText.length) {
      const p = JSON.parse(m.payload || "{}");
      nodes.push({ type: "image", attrs: { src: `/blobs/${p.hash}/preview` } });
    }
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
