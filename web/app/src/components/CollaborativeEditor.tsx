import { useRef, useEffect, useCallback, useMemo, useState } from "react";
import type { AttributionSpan, TransclusionMarker, AnnotationEntry, SpanRangePayload, AwarenessState, ChangeHighlight } from "../api/crdt_sync";
import type { PendingTransclusion } from "../hooks/useTransclusion";
import { authorColor } from "../author-color";
import { TextBuffer } from "../api/text_buffer";
import { SearchPanel } from "./SearchPanel";
import { OutlinePanel } from "./OutlinePanel";
import { RemoteCursors } from "./RemoteCursors";
import {
  DENSITY_THRESHOLD,
  assignLinkLanes,
  clusterOverlappingMarkers,
  filterMarkersByType,
  presentLinkTypeIds,
} from "../link-markers";

interface UndoEntry {
  text: string;
  selStart: number;
  selEnd: number;
}

const MAX_UNDO = 200;
const UNDO_DEBOUNCE_MS = 400;

function bytesToHex(bytes: number[]): string {
  return bytes.map((b) => b.toString(16).padStart(2, "0")).join("");
}

interface AuthorStyle {
  color: string;
  name: string;
  authorType: string | null;
  historicalAuthorId: number | null;
}

interface CollaborativeEditorProps {
  text: string;
  onTextChange?: (text: string) => void;
  onCursorChange: (index: number | null) => void;
  onSelectionChange: (start: number | null, end: number | null) => void;
  connected: boolean;
  attributionSpans: AttributionSpan[];
  editable: boolean;
  contentStartLine?: number;
  contentEndLine?: number;
  transclusionMarkers?: TransclusionMarker[];
  pendingTransclusion?: PendingTransclusion | null;
  onPlaceTransclusion?: (position: number, padding?: string) => void;
  selectionRange?: { start: number; end: number } | null;
  onNavigateToWork?: (workId: number) => void;
  onShowBacklinks?: (workId: number, excerpt: string) => void;
  onPasteText?: (text: string, pasteStart: number) => void;
  fontSize?: number;
  lineHeight?: number;
  annotations?: AnnotationEntry[];
  onCreateAnnotation?: (charStart: number, charEnd: number) => void;
  compoundSpanRanges?: SpanRangePayload[];
  remoteCursors?: AwarenessState[];
  compoundSourceTitles?: Record<number, string>;
  recentChanges?: ChangeHighlight[];
  showAttributionColors?: boolean;
  inlineResolvedText?: string;
  onUndoLastTransclusion?: () => Promise<boolean>;
}

const CHUNK_SIZE = 50_000;
const LARGE_DOC_THRESHOLD = 100_000;

function chunkedSetTextContent(el: HTMLElement, text: string): void {
  el.textContent = "";
  const textNode = document.createTextNode("");
  el.appendChild(textNode);
  let offset = 0;
  function appendChunk() {
    if (offset >= text.length) return;
    const end = Math.min(offset + CHUNK_SIZE, text.length);
    textNode.appendData(text.slice(offset, end));
    offset = end;
    requestAnimationFrame(appendChunk);
  }
  requestAnimationFrame(appendChunk);
}

interface MarkerHitZone {
  marker: TransclusionMarker;
  x: number;
  y: number;
  width: number;
  height: number;
  densityCluster?: number;
  densityCount?: number;
}

const LINK_TYPE_STYLES: Record<number, { color: string; dash: number[] }> = {
  1: { color: "#58a6ff", dash: [4, 3] },      // Comment — short dashes
  2: { color: "#3fb950", dash: [] },            // Reference — solid
  3: { color: "#f85149", dash: [8, 3] },        // Disagreement — long dashes
  4: { color: "#a371f7", dash: [1, 3] },        // Quotation — dotted
  5: { color: "#d29922", dash: [6, 2, 1, 2] }, // See Also — dash-dot
};

const LINK_TYPE_NAMES: Record<number, string> = {
  1: "Comment",
  2: "Reference",
  3: "Disagreement",
  4: "Quotation",
  5: "See Also",
};

const COMPOUND_COLORS = [
  { bg: "rgba(0, 137, 123, 0.12)", border: "rgba(0, 137, 123, 0.35)", label: "#00897b" },
  { bg: "rgba(92, 107, 192, 0.12)", border: "rgba(92, 107, 192, 0.35)", label: "#5c6bc0" },
  { bg: "rgba(244, 81, 30, 0.12)", border: "rgba(244, 81, 30, 0.35)", label: "#f4511e" },
  { bg: "rgba(123, 31, 162, 0.12)", border: "rgba(123, 31, 162, 0.35)", label: "#7b1fa2" },
  { bg: "rgba(198, 40, 40, 0.12)", border: "rgba(198, 40, 40, 0.35)", label: "#c62828" },
  { bg: "rgba(46, 125, 50, 0.12)", border: "rgba(46, 125, 50, 0.35)", label: "#2e7d32" },
  { bg: "rgba(0, 131, 143, 0.12)", border: "rgba(0, 131, 143, 0.35)", label: "#00838f" },
  { bg: "rgba(230, 81, 0, 0.12)", border: "rgba(230, 81, 0, 0.35)", label: "#e65100" },
];

function compoundColorForSource(workId: number) {
  let hash = 0;
  hash = ((hash << 5) - hash + workId) | 0;
  hash = ((hash << 5) - hash + (workId >> 8)) | 0;
  return COMPOUND_COLORS[Math.abs(hash) % COMPOUND_COLORS.length];
}

const HATCH_COLORS: [string, string][] = [
  ["#00897b", "#4db6ac"],
  ["#5c6bc0", "#9fa8da"],
  ["#f4511e", "#ffab91"],
  ["#00838f", "#4dd0e1"],
  ["#7b1fa2", "#ba68c8"],
  ["#c62828", "#ef9a9a"],
  ["#2e7d32", "#a5d6a7"],
  ["#e65100", "#ffcc80"],
  ["#37474f", "#90a4ae"],
  ["#4527a0", "#b39ddb"],
];

const hatchCache = new Map<number, CanvasPattern | null>();

function getHatchPattern(ctx: CanvasRenderingContext2D, workId: number): CanvasPattern | null {
  const cached = hatchCache.get(workId);
  if (cached !== undefined) return cached;
  let hash = 0;
  hash = ((hash << 5) - hash + workId) | 0;
  hash = ((hash << 5) - hash + (workId >> 8)) | 0;
  const pairIdx = Math.abs(hash) % (HATCH_COLORS.length * (HATCH_COLORS.length - 1));
  const idxA = pairIdx % HATCH_COLORS.length;
  let idxB = (pairIdx / HATCH_COLORS.length) | 0;
  if (idxB >= idxA) idxB++;
  const [, bg1] = HATCH_COLORS[idxA % HATCH_COLORS.length];
  const [, bg2] = HATCH_COLORS[idxB % HATCH_COLORS.length];
  const pc = document.createElement("canvas");
  pc.width = 8;
  pc.height = 8;
  const pctx = pc.getContext("2d");
  if (!pctx) { hatchCache.set(workId, null); return null; }
  pctx.fillStyle = bg1;
  pctx.fillRect(0, 0, 8, 8);
  pctx.strokeStyle = bg2;
  pctx.lineWidth = 3;
  pctx.beginPath();
  pctx.moveTo(-2, 10);
  pctx.lineTo(10, -2);
  pctx.moveTo(6, 10);
  pctx.lineTo(10, 6);
  pctx.stroke();
  const pattern = ctx.createPattern(pc, "repeat");
  hatchCache.set(workId, pattern);
  return pattern;
}

function drawOverlay(
  editor: HTMLElement | null,
  canvas: HTMLCanvasElement | null,
  spans: AttributionSpan[],
  colorMap: Map<string, AuthorStyle>,
  markers: TransclusionMarker[] = [],
  annotations: AnnotationEntry[] = [],
  compoundSpans: SpanRangePayload[] = [],
  recentChanges: ChangeHighlight[] = [],
  showAttribution: boolean = true,
  expandedClusters: Set<number> = new Set(),
  compoundSourceTitles: Record<number, string> = {},
  showCompound: boolean = true,
): MarkerHitZone[] {
  const hitZones: MarkerHitZone[] = [];
  if (!editor || !canvas) return hitZones;
  if (spans.length === 0 && markers.length === 0 && annotations.length === 0 && compoundSpans.length === 0 && recentChanges.length === 0) {
    // Still need to clear the canvas of any previous content
    const container = editor.parentElement;
    if (container) {
      const rect = container.getBoundingClientRect();
      const ctx = canvas.getContext("2d");
      if (ctx && rect.width > 0) ctx.clearRect(0, 0, rect.width, rect.height);
    }
    return hitZones;
  }

  const container = editor.parentElement;
  if (!container) return hitZones;

  const rect = container.getBoundingClientRect();
  if (rect.width === 0 || rect.height === 0) return hitZones;

  const dpr = window.devicePixelRatio || 1;
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  canvas.style.width = rect.width + "px";
  canvas.style.height = rect.height + "px";

  const ctx = canvas.getContext("2d");
  if (!ctx) return hitZones;
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, rect.width, rect.height);

  const textLen = editor.textContent?.length ?? 0;
  if (textLen === 0) return hitZones;
  const textNode = editor.firstChild;
  const singleNode = textNode && textNode.nodeType === Node.TEXT_NODE && textNode === editor.lastChild;

  for (const span of showAttribution ? spans : []) {
    const key = bytesToHex(span.author_public_key);
    const style = colorMap.get(key);
    if (!style) continue;

    const drawStart = Math.max(span.start, 0);
    const drawEnd = Math.min(span.end, textLen);
    if (drawStart >= drawEnd) continue;

    const range = document.createRange();
    try {
      if (singleNode) {
        range.setStart(textNode as Text, drawStart);
        range.setEnd(textNode as Text, drawEnd);
      } else {
        const sn = findTextNodeAt(editor, drawStart);
        const en = findTextNodeAt(editor, drawEnd - 1);
        if (!sn || !en) continue;
        range.setStart(sn.node, sn.offset);
        range.setEnd(en.node, en.offset + 1);
      }
    } catch {
      continue;
    }

    const rangeRects = range.getClientRects();
    const isHistorical = style.authorType === "historical";
    const isUnsigned = !span.signature_valid;
    for (const r of rangeRects) {
      const x = r.left - rect.left;
      const y = r.top - rect.top;
      if (isUnsigned) {
        ctx.fillStyle = "#f8514922";
        ctx.fillRect(x, y, r.width, r.height);
        ctx.save();
        ctx.strokeStyle = "#f85149";
        ctx.lineWidth = 1.5;
        ctx.setLineDash([6, 3]);
        ctx.beginPath();
        ctx.moveTo(x, y + r.height - 1);
        ctx.lineTo(x + r.width, y + r.height - 1);
        ctx.stroke();
        ctx.restore();
      } else {
        ctx.fillStyle = style.color + (isHistorical ? "18" : "25");
        ctx.fillRect(x, y, r.width, r.height);
        if (isHistorical) {
          ctx.save();
          ctx.setLineDash([4, 3]);
          ctx.strokeStyle = style.color + "90";
          ctx.lineWidth = 1.5;
          ctx.beginPath();
          ctx.moveTo(x, y + r.height - 1);
          ctx.lineTo(x + r.width, y + r.height - 1);
          ctx.stroke();
          ctx.restore();
        } else {
          ctx.fillStyle = style.color + "60";
          ctx.fillRect(x, y + r.height - 2, r.width, 2);
        }
      }
    }
  }

  if (showCompound) {
  for (let csIndex = 0; csIndex < compoundSpans.length; csIndex++) {
    const cs = compoundSpans[csIndex];
    const drawStart = Math.max(cs.flat_start, 0);
    const drawEnd = Math.min(cs.flat_end, textLen);
    if (drawStart >= drawEnd) continue;

    const srcColor = compoundColorForSource(cs.source_work_id);
    const srcTitle = compoundSourceTitles[cs.source_work_id]
      || `work:${cs.source_work_id.toString(16).padStart(4, "0")}`;

    const range = document.createRange();
    try {
      if (singleNode) {
        range.setStart(textNode as Text, drawStart);
        range.setEnd(textNode as Text, drawEnd);
      } else {
        const sn = findTextNodeAt(editor, drawStart);
        const en = findTextNodeAt(editor, drawEnd - 1);
        if (!sn || !en) continue;
        range.setStart(sn.node, sn.offset);
        range.setEnd(en.node, en.offset + 1);
      }
    } catch {
      continue;
    }

    const rangeRects = range.getClientRects();
    for (const r of rangeRects) {
      const x = r.left - rect.left;
      const y = r.top - rect.top;
      ctx.fillStyle = srcColor.bg;
      ctx.fillRect(x, y, r.width, r.height);
      ctx.save();
      ctx.strokeStyle = srcColor.border;
      ctx.lineWidth = 1;
      ctx.setLineDash([4, 2]);
      ctx.strokeRect(x + 0.5, y + 0.5, r.width - 1, r.height - 1);
      ctx.restore();
    }

    if (rangeRects.length > 0) {
      const firstRect = rangeRects[0];
      const firstTop = firstRect.top - rect.top;
      const lastRect = rangeRects[rangeRects.length - 1];
      const barHeight = (lastRect.bottom - rect.top) - firstTop;

      const barOffset = (csIndex % 3) * 4;
      ctx.fillStyle = srcColor.label;
      ctx.fillRect(0 + barOffset, firstTop, 3, barHeight);

      if (firstRect.width > 30) {
        const labelX = firstRect.left - rect.left + 4;
        const labelY = firstRect.top - rect.top - 2;
        if (labelY > 12) {
          ctx.font = "600 10px Inter, sans-serif";
          ctx.fillStyle = srcColor.label;
          ctx.fillText(srcTitle.slice(0, 24), labelX, labelY);
        }
      }

      const excerptText = cs.resolved_content?.slice(0, 120) || "";
      hitZones.push({
        marker: {
          start: cs.flat_start,
          end: cs.flat_end,
          linkId: 0,
          direction: "incoming" as const,
          otherWorkId: cs.source_work_id,
          otherWorkTitle: srcTitle,
          color: srcColor.label,
          excerpt: excerptText,
          provenanceChain: undefined,
          otherWorkIsArchived: undefined,
          otherWorkOwner: undefined,
        },
        x: 0,
        y: firstTop,
        width: Math.max(barOffset + 3, 12),
        height: barHeight,
      });
    }
  }
  }

  const now = Date.now();
  for (const change of recentChanges) {
    const age = now - change.timestamp;
    if (age > 5000) continue;
    const alpha = Math.max(0, 1 - age / 5000);
    const drawStart = Math.max(change.start, 0);
    const drawEnd = Math.min(change.end, textLen);
    if (drawStart >= drawEnd) continue;

    const range = document.createRange();
    try {
      if (singleNode) {
        range.setStart(textNode as Text, drawStart);
        range.setEnd(textNode as Text, drawEnd);
      } else {
        const sn = findTextNodeAt(editor, drawStart);
        const en = findTextNodeAt(editor, drawEnd - 1);
        if (!sn || !en) continue;
        range.setStart(sn.node, sn.offset);
        range.setEnd(en.node, en.offset + 1);
      }
    } catch {
      continue;
    }

    const rangeRects = range.getClientRects();
    const hex = Math.round(alpha * 100).toString(16).padStart(2, "0");
    for (const r of rangeRects) {
      const x = r.left - rect.left;
      const y = r.top - rect.top;
      ctx.fillStyle = "#22c55e" + hex;
      ctx.fillRect(x, y, r.width, r.height);
    }
  }

  // FR-4.5: profuse overlapping links — assign stack lanes and detect dense
  // regions so overlapping links stay legible.
  const lanes = assignLinkLanes(markers);
  const clusters = clusterOverlappingMarkers(markers);
  const collapsed = new Set<number>();
  const densityPills: Array<{ clusterIndex: number; count: number; start: number; end: number; first: TransclusionMarker }> = [];
  clusters.forEach((c, ci) => {
    if (c.indices.length >= DENSITY_THRESHOLD && !expandedClusters.has(ci)) {
      for (const idx of c.indices) collapsed.add(idx);
      densityPills.push({
        clusterIndex: ci,
        count: c.indices.length,
        start: c.start,
        end: c.end,
        first: markers[c.indices[0]],
      });
    }
  });

  for (let mi = 0; mi < markers.length; mi++) {
    if (collapsed.has(mi)) continue;
    const marker = markers[mi];
    const lane = lanes.get(mi) ?? 0;
    const drawStart = Math.max(marker.start, 0);
    const drawEnd = Math.min(marker.end, textLen);
    if (drawStart >= drawEnd) continue;

    const range = document.createRange();
    try {
      if (singleNode) {
        range.setStart(textNode as Text, drawStart);
        range.setEnd(textNode as Text, drawEnd);
      } else {
        const sn = findTextNodeAt(editor, drawStart);
        const en = findTextNodeAt(editor, drawEnd - 1);
        if (!sn || !en) continue;
        range.setStart(sn.node, sn.offset);
        range.setEnd(en.node, en.offset + 1);
      }
    } catch {
      continue;
    }

    const rangeRects = range.getClientRects();
    if (rangeRects.length === 0) continue;

    const firstTop = rangeRects[0].top - rect.top;
    const lastRect = rangeRects[rangeRects.length - 1];
    const lastBottom = lastRect.bottom - rect.top;
    const height = lastBottom - firstTop;

    const isIncoming = marker.direction === "incoming";
    const typeStyle = marker.linkTypeId ? LINK_TYPE_STYLES[marker.linkTypeId] : null;
    const barColor = typeStyle ? typeStyle.color : marker.color;

    if (typeStyle) {
      ctx.strokeStyle = barColor + "cc";
      ctx.lineWidth = 1.5;
      ctx.setLineDash(typeStyle.dash);
      // FR-4.5: layer overlapping underlines at 2px vertical offsets.
      for (const r of rangeRects) {
        const rx = r.left - rect.left;
        const ry = r.bottom - rect.top - 1 + lane * 2;
        ctx.beginPath();
        ctx.moveTo(rx, ry);
        ctx.lineTo(rx + r.width, ry);
        ctx.stroke();
      }
      ctx.setLineDash([]);
    }

    const barWidth = 3 + (marker.provenanceChain && marker.provenanceChain.length > 0
      ? 1 + marker.provenanceChain.length * 3 : 0);

    if (typeStyle) {
      ctx.fillStyle = barColor + "60";
    } else {
      const pattern = getHatchPattern(ctx, marker.otherWorkId);
      ctx.fillStyle = pattern || marker.color + "60";
    }
    // FR-4.5: stack margin bars per lane (left outgoing / right incoming).
    if (isIncoming && typeStyle) {
      const rightX = rect.width - 3 - lane * 4;
      ctx.fillRect(rightX, firstTop, 3, height);
      hitZones.push({
        marker,
        x: Math.max(0, rightX - 9),
        y: firstTop,
        width: Math.max(barWidth, 12),
        height,
      });
    } else {
      const leftX = lane * 4;
      ctx.fillRect(leftX, firstTop, 3, height);

      if (marker.provenanceChain && marker.provenanceChain.length > 0) {
        const chainCount = marker.provenanceChain.length;
        const stackWidth = 2;
        const gap = 1;
        const chainColor = "#c4a35a";
        for (let i = 0; i < chainCount; i++) {
          const stackX = leftX + 3 + gap + i * (stackWidth + gap);
          ctx.fillStyle = chainColor + "80";
          ctx.fillRect(stackX, firstTop, stackWidth, height);
        }
      }

      hitZones.push({
        marker,
        x: leftX,
        y: firstTop,
        width: Math.max(barWidth, 12),
        height,
      });
    }
  }

  // FR-4.5: density pills collapse DENSITY_THRESHOLD+ overlapping links into
  // one summary badge; clicking the pill expands the cluster.
  for (const pill of densityPills) {
    const drawStart = Math.max(pill.start, 0);
    const drawEnd = Math.min(pill.end, textLen);
    if (drawStart >= drawEnd) continue;
    const range = document.createRange();
    try {
      if (singleNode) {
        range.setStart(textNode as Text, drawStart);
        range.setEnd(textNode as Text, drawEnd);
      } else {
        const sn = findTextNodeAt(editor, drawStart);
        const en = findTextNodeAt(editor, drawEnd - 1);
        if (!sn || !en) continue;
        range.setStart(sn.node, sn.offset);
        range.setEnd(en.node, en.offset + 1);
      }
    } catch {
      continue;
    }
    const rr = range.getClientRects();
    if (rr.length === 0) continue;
    const firstTop = rr[0].top - rect.top;
    const lastRect = rr[rr.length - 1];
    const height = Math.max((lastRect.bottom - rect.top) - firstTop, 14);

    ctx.save();
    ctx.fillStyle = "#d29922";
    ctx.fillRect(0, firstTop, 18, height);
    ctx.fillStyle = "#0d1117";
    ctx.font = "bold 10px ui-monospace, SFMono-Regular, monospace";
    ctx.textBaseline = "top";
    ctx.fillText(String(pill.count), 5, firstTop + 2);
    ctx.restore();

    hitZones.push({
      marker: pill.first,
      x: 0,
      y: firstTop,
      width: 18,
      height,
      densityCluster: pill.clusterIndex,
      densityCount: pill.count,
    });
  }

  const now2 = Date.now();
  for (const change of recentChanges) {
    const age = now2 - change.timestamp;
    if (age > 5000) continue;
    const alpha = Math.max(0, 1 - age / 5000);
    const drawStart = Math.max(change.start, 0);
    const drawEnd = Math.min(change.end, textLen);
    if (drawStart >= drawEnd) continue;

    const range = document.createRange();
    try {
      if (singleNode) {
        range.setStart(textNode as Text, drawStart);
        range.setEnd(textNode as Text, drawEnd);
      } else {
        const sn = findTextNodeAt(editor, drawStart);
        const en = findTextNodeAt(editor, drawEnd - 1);
        if (!sn || !en) continue;
        range.setStart(sn.node, sn.offset);
        range.setEnd(en.node, en.offset + 1);
      }
    } catch {
      continue;
    }

    const rangeRects = range.getClientRects();
    if (rangeRects.length === 0) continue;
    const firstTop = rangeRects[0].top - rect.top;
    const lastRect = rangeRects[rangeRects.length - 1];
    const height = (lastRect.bottom - rect.top) - firstTop;

    const hex = Math.round(alpha * 200).toString(16).padStart(2, "0");
    ctx.fillStyle = "#22c55e" + hex;
    ctx.fillRect(rect.width - 3, firstTop, 3, height);
  }

  for (const ann of annotations) {
    if (ann.char_start >= ann.char_end) continue;
    const drawStart = Math.max(ann.char_start, 0);
    const drawEnd = Math.min(ann.char_end, textLen);
    if (drawStart >= drawEnd) continue;

    const range = document.createRange();
    try {
      if (singleNode) {
        range.setStart(textNode as Text, drawStart);
        range.setEnd(textNode as Text, drawEnd);
      } else {
        const sn = findTextNodeAt(editor, drawStart);
        const en = findTextNodeAt(editor, drawEnd - 1);
        if (!sn || !en) continue;
        range.setStart(sn.node, sn.offset);
        range.setEnd(en.node, en.offset + 1);
      }
    } catch {
      continue;
    }

    const rangeRects = range.getClientRects();
    for (const r of rangeRects) {
      const x = r.left - rect.left;
      const y = r.top - rect.top;
      ctx.fillStyle = "rgba(255, 196, 0, 0.15)";
      ctx.fillRect(x, y, r.width, r.height);
      ctx.strokeStyle = "rgba(255, 196, 0, 0.4)";
      ctx.lineWidth = 1;
      ctx.strokeRect(x + 0.5, y + 0.5, r.width - 1, r.height - 1);
    }
  }

  return hitZones;
}

function findTextNodeAt(root: Node, targetOffset: number): { node: Text; offset: number } | null {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null);
  let current = 0;
  let node: Node | null;
  while ((node = walker.nextNode())) {
    const len = node.textContent?.length ?? 0;
    if (current + len > targetOffset) {
      return { node: node as Text, offset: targetOffset - current };
    }
    current += len;
  }
  return null;
}

export function CollaborativeEditor({
  text,
  onTextChange,
  onCursorChange,
  onSelectionChange,
  connected,
  attributionSpans,
  editable,
  contentStartLine,
  contentEndLine,
  transclusionMarkers = [],
  pendingTransclusion,
  onPlaceTransclusion,
  onNavigateToWork,
  onShowBacklinks,
  onPasteText,
  fontSize,
  lineHeight,
  annotations = [],
  onCreateAnnotation,
  compoundSpanRanges = [],
  remoteCursors = [],
  compoundSourceTitles: compoundSourceTitles = {},
  recentChanges = [],
  showAttributionColors = true,
  inlineResolvedText,
  onUndoLastTransclusion,
}: CollaborativeEditorProps) {
  const editorRef = useRef<HTMLDivElement>(null);
  const overlayRef = useRef<HTMLCanvasElement>(null);
  const hitZonesRef = useRef<MarkerHitZone[]>([]);
  const [placementIndicator, setPlacementIndicator] = useState<{ x: number; y: number; height: number; pos: number; padding?: string } | null>(null);
  const isComposing = useRef(false);
  const lastText = useRef(text);
  const undoStack = useRef<UndoEntry[]>([]);
  const redoStack = useRef<UndoEntry[]>([]);
  const undoTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isUndoRedoing = useRef(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [outlineOpen, setOutlineOpen] = useState(false);
  const [showBoilerplate, setShowBoilerplate] = useState(false);
  const [hoveredMarker, setHoveredMarker] = useState<TransclusionMarker | null>(null);
  const [tooltipPos, setTooltipPos] = useState<{ x: number; y: number } | null>(null);
  const [linkTypeFilter, setLinkTypeFilter] = useState<Set<number> | null>(null);
  const [expandedClusters, setExpandedClusters] = useState<Set<number>>(new Set());
  const [showCompoundHighlight, setShowCompoundHighlight] = useState(true);

  const presentTypes = useMemo(() => presentLinkTypeIds(transclusionMarkers), [transclusionMarkers]);
  const filteredMarkers = useMemo(
    () => filterMarkersByType(transclusionMarkers, linkTypeFilter),
    [transclusionMarkers, linkTypeFilter],
  );

  const hasContentRange = (contentStartLine != null && contentStartLine > 0) || (contentEndLine != null);

  const bodyRange = useMemo(() => {
    if (!hasContentRange) return null;
    const lines = text.split("\n");
    const start = contentStartLine ?? 0;
    const end = contentEndLine ?? lines.length;
    let charStart = 0;
    for (let i = 0; i < start && i < lines.length; i++) {
      charStart += lines[i].length + 1;
    }
    let charEnd = charStart;
    for (let i = start; i < end && i < lines.length; i++) {
      charEnd += lines[i].length + 1;
    }
    if (charEnd > 0 && charEnd <= text.length && text[charEnd - 1] === "\n") charEnd--;
    const prefixLines = start;
    const suffixLines = Math.max(0, lines.length - end);
    if (prefixLines === 0 && suffixLines === 0) return null;
    return { charStart, charEnd, prefixLines, suffixLines };
  }, [text, contentStartLine, contentEndLine, hasContentRange]);

  const displayText = useMemo(() => {
    if (!bodyRange || showBoilerplate) return text;
    return text.slice(bodyRange.charStart, bodyRange.charEnd);
  }, [text, showBoilerplate, bodyRange]);

  const buffer = useMemo(() => new TextBuffer(displayText), [displayText]);

  const authorColorMap = useMemo(() => {
    const map = new Map<string, AuthorStyle>();
    for (const span of attributionSpans) {
      const key = bytesToHex(span.author_public_key);
      if (!map.has(key)) {
        const isLlm = span.author_type === "llm";
        const isHistorical = span.author_type === "historical";
        const name = span.author_display_name || "unknown";
        const color = isLlm ? "#7c4dff" : isHistorical ? "#c4a35a" : authorColor(name);
        map.set(key, {
          color,
          name,
          authorType: span.author_type,
          historicalAuthorId: span.historical_author_id,
        });
      }
    }
    return map;
  }, [attributionSpans]);

  const hasInlineTransclusions = !!inlineResolvedText && compoundSpanRanges.length > 0;

  useEffect(() => {
    const el = editorRef.current;
    if (!el) return;
    if (isUndoRedoing.current) return;

    if (hasInlineTransclusions && inlineResolvedText) {
      const hasTransclusionSpans = el.querySelector(".inline-transclusion") !== null;
      const currentFull = getTextContent(el);
      const needsRebuild = !hasTransclusionSpans || inlineResolvedText !== currentFull;
      if (needsRebuild) {
        if (undoTimer.current !== null) {
          clearTimeout(undoTimer.current);
          undoTimer.current = null;
          undoStack.current.push({ text: lastText.current, selStart: 0, selEnd: 0 });
          if (undoStack.current.length > MAX_UNDO) undoStack.current.shift();
        }
        redoStack.current = [];
        buildTransclusionDom(el, inlineResolvedText, compoundSpanRanges, compoundSourceTitles);
        lastText.current = getEditableText(el);
      }
      return;
    }

    let currentText = getTextContent(el);
    if (currentText === "\n" && !el.querySelector("DIV") && !el.querySelector("P")) {
      currentText = "";
    }
    const isRemote = displayText !== lastText.current && displayText !== currentText;
    if (isRemote) {
      if (undoTimer.current !== null) {
        clearTimeout(undoTimer.current);
        undoTimer.current = null;
        undoStack.current.push({ text: lastText.current, selStart: 0, selEnd: 0 });
        if (undoStack.current.length > MAX_UNDO) undoStack.current.shift();
      }
      redoStack.current = [];
    }
    if (currentText !== displayText) {
      if (displayText.length > LARGE_DOC_THRESHOLD) {
        chunkedSetTextContent(el, displayText);
      } else if (displayText === "") {
        el.innerHTML = "<br>";
      } else {
        el.textContent = displayText;
        if (displayText.endsWith("\n")) {
          el.appendChild(document.createTextNode("\u200B"));
        }
      }
    }
    lastText.current = displayText;
  }, [displayText, inlineResolvedText, hasInlineTransclusions, compoundSpanRanges, compoundSourceTitles]);

  useEffect(() => {
    if (text === "") {
      undoStack.current = [];
      redoStack.current = [];
      if (undoTimer.current !== null) {
        clearTimeout(undoTimer.current);
        undoTimer.current = null;
      }
    }
  }, [text]);

  useEffect(() => {
    const el = editorRef.current;
    const canvas = overlayRef.current;
    if (!el || !canvas) return;
    const container = el.parentElement;
    if (!container) return;

    let rafId = 0;
    const redraw = () => {
      cancelAnimationFrame(rafId);
      rafId = requestAnimationFrame(() => {
        hitZonesRef.current = drawOverlay(el, canvas, attributionSpans, authorColorMap, filteredMarkers, annotations, compoundSpanRanges, recentChanges, showAttributionColors, expandedClusters, compoundSourceTitles, showCompoundHighlight);
      });
    };

    hitZonesRef.current = drawOverlay(el, canvas, attributionSpans, authorColorMap, filteredMarkers, annotations, compoundSpanRanges, recentChanges, showAttributionColors, expandedClusters, compoundSourceTitles, showCompoundHighlight);

    const ro = new ResizeObserver(redraw);
    ro.observe(container);
    container.addEventListener("scroll", redraw, { passive: true });

    return () => {
      ro.disconnect();
      container.removeEventListener("scroll", redraw);
      cancelAnimationFrame(rafId);
    };
  }, [attributionSpans, authorColorMap, filteredMarkers, annotations, compoundSpanRanges, recentChanges, showAttributionColors, expandedClusters, compoundSourceTitles, showCompoundHighlight]);

  useEffect(() => {
    if (recentChanges.length === 0) return;
    const interval = setInterval(() => {
      const el = editorRef.current;
      const canvas = overlayRef.current;
      if (!el || !canvas) return;
      hitZonesRef.current = drawOverlay(el, canvas, attributionSpans, authorColorMap, filteredMarkers, annotations, compoundSpanRanges, recentChanges, showAttributionColors, expandedClusters, compoundSourceTitles, showCompoundHighlight);
    }, 200);
    return () => clearInterval(interval);
  }, [recentChanges, attributionSpans, authorColorMap, filteredMarkers, annotations, compoundSpanRanges, showAttributionColors, expandedClusters]);

  const hideTooltipTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const scheduleHideTooltip = useCallback(() => {
    hideTooltipTimer.current = setTimeout(() => {
      setHoveredMarker(null);
      setTooltipPos(null);
      hideTooltipTimer.current = null;
    }, 800);
  }, []);

  const cancelHideTooltip = useCallback(() => {
    if (hideTooltipTimer.current) { clearTimeout(hideTooltipTimer.current); hideTooltipTimer.current = null; }
  }, []);

  const toggleClusterExpansion = useCallback((clusterIndex: number) => {
    setExpandedClusters((prev) => {
      const next = new Set(prev);
      if (next.has(clusterIndex)) next.delete(clusterIndex);
      else next.add(clusterIndex);
      return next;
    });
  }, []);

  const handleOverlayMouseMove = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    if (hideTooltipTimer.current) { clearTimeout(hideTooltipTimer.current); hideTooltipTimer.current = null; }
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const hit = hitZonesRef.current.find((hz) =>
      x >= hz.x && x <= hz.x + hz.width && y >= hz.y && y <= hz.y + hz.height
    );
    if (hit) {
      const m = (hit.densityCluster != null && hit.densityCount != null)
        ? { ...hit.marker, otherWorkTitle: `${hit.densityCount} links in this region` }
        : hit.marker;
      setHoveredMarker(m);
      setTooltipPos({ x: e.clientX, y: e.clientY });
      e.currentTarget.style.cursor = "pointer";
    } else {
      e.currentTarget.style.cursor = pendingTransclusion ? "crosshair" : "";
      if (hoveredMarker) {
        scheduleHideTooltip();
      }
    }
  }, [hoveredMarker, scheduleHideTooltip, pendingTransclusion]);

  const handleOverlayMouseLeave = useCallback(() => {
    scheduleHideTooltip();
  }, [scheduleHideTooltip]);

  const handleOverlayClick = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const hit = hitZonesRef.current.find((hz) =>
      x >= hz.x && x <= hz.x + hz.width && y >= hz.y && y <= hz.y + hz.height
    );
    if (!hit) return;
    if (hit.densityCluster != null) {
      toggleClusterExpansion(hit.densityCluster);
      return;
    }
    if (e.detail === 2 && onShowBacklinks) {
      const excerpt = (hit.marker as unknown as Record<string, unknown>).excerpt as string || "";
      onShowBacklinks(hit.marker.otherWorkId, excerpt);
    } else if (e.detail === 1 && onNavigateToWork) {
      onNavigateToWork(hit.marker.otherWorkId);
    }
  }, [onNavigateToWork, onShowBacklinks, toggleClusterExpansion]);

  const getSelectionInEditor = useCallback((): { start: number; end: number } => {
    const el = editorRef.current;
    const sel = window.getSelection();
    if (!el || !sel || sel.rangeCount === 0 || !el.contains(sel.anchorNode)) {
      return { start: 0, end: 0 };
    }
    const range = sel.getRangeAt(0);
    const pre = document.createRange();
    pre.selectNodeContents(el);
    pre.setEnd(range.startContainer, range.startOffset);
    const start = pre.toString().length;
    pre.setEnd(range.endContainer, range.endOffset);
    const end = pre.toString().length;
    return { start, end };
  }, []);

  const pushUndo = useCallback((prevText: string) => {
    if (isUndoRedoing.current) return;
    redoStack.current = [];
    const { start, end } = getSelectionInEditor();
    if (undoTimer.current !== null) {
      clearTimeout(undoTimer.current);
    }
    undoTimer.current = setTimeout(() => {
      undoStack.current.push({ text: prevText, selStart: start, selEnd: end });
      if (undoStack.current.length > MAX_UNDO) {
        undoStack.current.shift();
      }
      undoTimer.current = null;
    }, UNDO_DEBOUNCE_MS);
  }, [getSelectionInEditor]);

  const restoreUndoEntry = useCallback((entry: UndoEntry, stack: "undo" | "redo") => {
    isUndoRedoing.current = true;
    const el = editorRef.current;
    if (!el) { isUndoRedoing.current = false; return; }
    const prevText = lastText.current;
    const { start: prevStart, end: prevEnd } = getSelectionInEditor();
    if (entry.text === "") {
      el.innerHTML = "<br>";
    } else if (el.textContent !== entry.text) {
      el.textContent = entry.text;
    }
    lastText.current = entry.text;
    onTextChange?.(entry.text);
    const textNode = el.firstChild;
    if (textNode) {
      try {
        const clampedStart = Math.min(entry.selStart, entry.text.length);
        const clampedEnd = Math.min(entry.selEnd, entry.text.length);
        const range = document.createRange();
        range.setStart(textNode, clampedStart);
        range.setEnd(textNode, clampedEnd);
        const sel = window.getSelection();
        sel?.removeAllRanges();
        sel?.addRange(range);
      } catch { /* ignore cursor restore errors */ }
    }
    const target = stack === "undo" ? redoStack : undoStack;
    target.current.push({ text: prevText, selStart: prevStart, selEnd: prevEnd });
    if (target.current.length > MAX_UNDO) target.current.shift();
    setTimeout(() => { isUndoRedoing.current = false; }, 0);
  }, [onTextChange, getSelectionInEditor]);

  const handleInput = useCallback(() => {
    if (isComposing.current || !editable) return;
    const el = editorRef.current;
    if (!el) return;
    let newText = hasInlineTransclusions ? getEditableText(el) : getTextContent(el);
    if (newText === "\n" && !el.querySelector("DIV") && !el.querySelector("P")) {
      newText = "";
    }
    if (newText !== lastText.current) {
      pushUndo(lastText.current);
      lastText.current = newText;
      onTextChange?.(newText);
    }
  }, [onTextChange, editable, pushUndo, hasInlineTransclusions]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (!editable) { console.warn("[EDIT-DEBUG] keydown blocked, editable=false"); e.preventDefault(); return; }
    if ((e.ctrlKey || e.metaKey) && e.key === "z" && !e.shiftKey) {
      e.preventDefault();
      if (undoTimer.current !== null) {
        clearTimeout(undoTimer.current);
        undoTimer.current = null;
      }
      const entry = undoStack.current.pop();
      if (entry) {
        restoreUndoEntry(entry, "undo");
      } else if (onUndoLastTransclusion) {
        onUndoLastTransclusion();
      }
      return;
    }
    if ((e.ctrlKey || e.metaKey) && (e.key === "Z" || e.key === "y")) {
      e.preventDefault();
      if (undoTimer.current !== null) {
        clearTimeout(undoTimer.current);
        undoTimer.current = null;
      }
      const entry = redoStack.current.pop();
      if (entry) restoreUndoEntry(entry, "redo");
      return;
    }
    if ((e.ctrlKey || e.metaKey) && e.altKey && e.key === "a") {
      e.preventDefault();
      const sel = window.getSelection();
      if (!sel || sel.isCollapsed || !sel.rangeCount || !onCreateAnnotation) return;
      const el = editorRef.current;
      if (!el) return;
      const preRange = document.createRange();
      preRange.setStart(el, 0);
      preRange.setEnd(sel.anchorNode!, sel.anchorOffset);
      const start = preRange.toString().length;
      const end = start + sel.toString().length;
      onCreateAnnotation(start, end);
      return;
    }
    if (e.key === "Enter") {
      e.preventDefault();
      const sel = window.getSelection();
      if (!sel || sel.rangeCount === 0) return;
      const range = sel.getRangeAt(0);
      range.deleteContents();
      const textNode = document.createTextNode("\n\u200B");
      range.insertNode(textNode);
      range.setStartAfter(textNode);
      range.collapse(true);
      sel.removeAllRanges();
      sel.addRange(range);
      handleInput();
    } else if (e.key === "Tab") {
      e.preventDefault();
      const sel = window.getSelection();
      if (!sel || sel.rangeCount === 0) return;
      const range = sel.getRangeAt(0);
      range.deleteContents();
      const textNode = document.createTextNode("\t");
      range.insertNode(textNode);
      range.setStartAfter(textNode);
      range.collapse(true);
      sel.removeAllRanges();
      sel.addRange(range);
      handleInput();
    }
  }, [handleInput, editable, onCreateAnnotation, onUndoLastTransclusion, restoreUndoEntry]);

  const handlePaste = useCallback((e: React.ClipboardEvent) => {
    if (!editable) { e.preventDefault(); return; }
    e.preventDefault();
    const pasteText = e.clipboardData.getData("text/plain");
    if (!pasteText) return;
    const sel = window.getSelection();
    if (!sel || sel.rangeCount === 0) return;
    const el = editorRef.current;
    const range = sel.getRangeAt(0);

    const pre = document.createRange();
    pre.selectNodeContents(el!);
    pre.setEnd(range.startContainer, range.startOffset);
    const pasteStart = pre.toString().length;

    range.deleteContents();
    const textNode = document.createTextNode(pasteText);
    range.insertNode(textNode);
    range.setStartAfter(textNode);
    range.collapse(true);
    sel.removeAllRanges();
    sel.addRange(range);
    handleInput();
    if (onPasteText && pasteText.length > 50) onPasteText(pasteText, pasteStart);
  }, [handleInput, editable, onPasteText]);

  const handleSelectionChange = useCallback(() => {
    const sel = window.getSelection();
    if (!sel || sel.rangeCount === 0 || !editorRef.current?.contains(sel.anchorNode)) {
      return;
    }
    const range = sel.getRangeAt(0);
    const el = editorRef.current;

    const pre = document.createRange();
    pre.selectNodeContents(el);
    pre.setEnd(range.startContainer, range.startOffset);
    const start = pre.toString().length;

    if (sel.isCollapsed) {
      onCursorChange(start);
    } else {
      const preEnd = document.createRange();
      preEnd.selectNodeContents(el);
      preEnd.setEnd(range.endContainer, range.endOffset);
      const end = preEnd.toString().length;
      onSelectionChange(start, end);
    }
  }, [onCursorChange, onSelectionChange]);

  const computePlacementPosition = useCallback((clientX: number, clientY: number, el: HTMLElement): { pos: number; rect: DOMRect; padding?: string } | null => {
    const doc = el.ownerDocument as Document & {
      caretRangeFromPoint?: (x: number, y: number) => Range | null;
      caretPositionFromPoint?: (x: number, y: number) => { offsetNode: Node; offset: number } | null;
    };

    let range: Range | null = null;
    if (doc.caretRangeFromPoint) {
      range = doc.caretRangeFromPoint(clientX, clientY);
    }
    if (!range && doc.caretPositionFromPoint) {
      const cp = doc.caretPositionFromPoint(clientX, clientY);
      if (cp) {
        range = document.createRange();
        range.setStart(cp.offsetNode, cp.offset);
        range.collapse(true);
      }
    }

    if (!range) {
      const editorRect = el.getBoundingClientRect();
      if (clientY >= editorRect.top && clientY <= editorRect.bottom) {
        const endRange = document.createRange();
        endRange.selectNodeContents(el);
        endRange.collapse(false);
        const endRect = endRange.getBoundingClientRect();

        const computedLineHeight = parseFloat(getComputedStyle(el).lineHeight) || 20;
        const linesBelow = Math.max(0, Math.round((clientY - endRect.bottom) / computedLineHeight));
        const padding = "\n".repeat(linesBelow + 1);

        const paddingNode = document.createTextNode(padding);
        endRange.insertNode(paddingNode);
        const afterRange = document.createRange();
        afterRange.selectNodeContents(el);
        afterRange.setStartAfter(paddingNode);
        afterRange.collapse(true);
        const afterRect = afterRange.getBoundingClientRect();

        el.removeChild(paddingNode);

        return { pos: -1, rect: afterRect, padding };
      }
      return null;
    }

    const rect = range.getBoundingClientRect();

    const pre = document.createRange();
    pre.selectNodeContents(el);
    pre.setEnd(range.startContainer, range.startOffset);
    const fullPos = pre.toString().replace(/\u200B/g, "").length;

    let readonlyChars = 0;
    el.querySelectorAll("[contenteditable='false']").forEach((span) => {
      const spanRange = document.createRange();
      spanRange.selectNodeContents(span);
      if (spanRange.compareBoundaryPoints(Range.START_TO_END, pre) <= 0) {
        readonlyChars += (span.textContent || "").replace(/\u200B/g, "").length;
      }
    });

    return { pos: fullPos - readonlyChars, rect };
  }, []);

  const handleEditorClick = useCallback((e: React.MouseEvent) => {
    const el = editorRef.current;
    if (!el) return;

    const target = e.target as HTMLElement;
    const transclusionSpan = target.closest(".inline-transclusion");
    if (transclusionSpan && onNavigateToWork) {
      const sourceId = parseInt((transclusionSpan as HTMLElement).dataset.sourceWorkId || "0", 10);
      if (sourceId) {
        onNavigateToWork(sourceId);
        return;
      }
    }

    if (!pendingTransclusion || !onPlaceTransclusion) return;
    if (!el.contains(e.target as Node)) return;

    const result = computePlacementPosition(e.clientX, e.clientY, el);
    if (result !== null) {
      console.log("[placement] O-tree position:", result.pos);
      onPlaceTransclusion(result.pos);
    }
    setPlacementIndicator(null);
  }, [pendingTransclusion, onPlaceTransclusion, onNavigateToWork, computePlacementPosition]);

  const handleEditorMouseMove = useCallback((e: React.MouseEvent) => {
    if (!pendingTransclusion) {
      if (placementIndicator) setPlacementIndicator(null);
      return;
    }
    const el = editorRef.current;
    if (!el) return;
    if (!el.contains(e.target as Node)) return;

    const result = computePlacementPosition(e.clientX, e.clientY, el);
    if (!result) return;

    const editorRect = el.getBoundingClientRect();
    if (result.pos === -1) {
      const editableText = getEditableText(el);
      setPlacementIndicator({
        x: 4,
        y: result.rect.top - editorRect.top,
        height: result.rect.height || 18,
        pos: editableText.length,
      });
    } else {
      setPlacementIndicator({
        x: result.rect.left - editorRect.left,
        y: result.rect.top - editorRect.top,
        height: result.rect.height || 18,
        pos: result.pos,
      });
    }
  }, [pendingTransclusion, computePlacementPosition, placementIndicator]);

  useEffect(() => {
    document.addEventListener("selectionchange", handleSelectionChange);
    return () => {
      document.removeEventListener("selectionchange", handleSelectionChange);
    };
  }, [handleSelectionChange]);

  const jumpToCharOffset = useCallback((charOffset: number) => {
    const el = editorRef.current;
    if (!el) return;
    const container = el.parentElement;
    if (!container) return;
    const line = buffer.getLineForChar(charOffset);
    const targetScroll = line * parseFloat(getComputedStyle(el).lineHeight || "20");
    container.scrollTo({ top: Math.max(0, targetScroll - container.clientHeight / 3), behavior: "smooth" });
  }, [buffer]);

  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "f") {
        e.preventDefault();
        setSearchOpen(true);
      }
    };
    document.addEventListener("keydown", handleKey);
    return () => document.removeEventListener("keydown", handleKey);
  }, []);

  useEffect(() => {
    const hash = window.location.hash;
    if (!hash || text.length === 0) return;
    let charOffset = -1;
    if (hash.startsWith("#L")) {
      const line = parseInt(hash.slice(2), 10);
      if (!isNaN(line) && line >= 0) {
        charOffset = buffer.getCharOffset(line);
      }
    } else if (hash.startsWith("#C")) {
      const c = parseInt(hash.slice(2), 10);
      if (!isNaN(c) && c >= 0) {
        charOffset = c;
      }
    }
    if (charOffset >= 0) {
      setTimeout(() => jumpToCharOffset(charOffset), 100);
      history.replaceState(null, "", window.location.pathname + window.location.search);
    }
  }, [text, buffer, jumpToCharOffset]);

  return (
    <div className="collaborative-editor">
      {searchOpen && (
        <SearchPanel
          buffer={buffer}
          onJumpToMatch={jumpToCharOffset}
          onClose={() => setSearchOpen(false)}
        />
      )}
      <div style={{ position: "relative", flex: 1, display: "flex", minHeight: 0 }}>
        {presentTypes.length > 0 && (
          <div
            className="link-type-filter"
            style={{
              position: "absolute",
              top: 6,
              right: 6,
              zIndex: 50,
              display: "flex",
              gap: 4,
              alignItems: "center",
              background: "rgba(13, 17, 23, 0.85)",
              border: "1px solid #30363d",
              borderRadius: 6,
              padding: "2px 5px",
            }}
          >
            <button
              type="button"
              className="link-type-filter-all"
              onClick={() => setLinkTypeFilter(null)}
              title="Show all links"
              style={{
                background: "transparent",
                border: linkTypeFilter === null ? "1px solid #8b949e" : "1px solid transparent",
                color: linkTypeFilter === null ? "#c9d1d9" : "#8b949e",
                borderRadius: 3,
                padding: "0 4px",
                fontSize: 11,
                cursor: "pointer",
              }}
            >
              All
            </button>
            {presentTypes.map((tid) => {
              const style = LINK_TYPE_STYLES[tid];
              const active = linkTypeFilter !== null && linkTypeFilter.has(tid);
              const color = style?.color ?? "#8b949e";
              const name = LINK_TYPE_NAMES[tid] ?? `Type ${tid}`;
              return (
                <button
                  key={tid}
                  type="button"
                  className="link-type-filter-dot"
                  title={name}
                  onClick={() =>
                    setLinkTypeFilter((prev) => {
                      const next = new Set(prev ?? []);
                      if (next.has(tid)) next.delete(tid);
                      else next.add(tid);
                      return next;
                    })
                  }
                  style={{
                    width: 14,
                    height: 14,
                    borderRadius: 3,
                    border: active ? `1px solid ${color}` : "1px solid #30363d",
                    background: active ? color : "transparent",
                    cursor: "pointer",
                    padding: 0,
                  }}
                />
              );
            })}
            {compoundSpanRanges.length > 0 && (
              <button
                type="button"
                title={showCompoundHighlight ? "Hide compound highlighting" : "Show compound highlighting"}
                onClick={() => setShowCompoundHighlight((s) => !s)}
                style={{
                  background: showCompoundHighlight ? "rgba(0, 137, 123, 0.2)" : "transparent",
                  border: showCompoundHighlight ? "1px solid #00897b" : "1px solid #30363d",
                  color: showCompoundHighlight ? "#4db6ac" : "#8b949e",
                  borderRadius: 3,
                  padding: "0 6px",
                  fontSize: 11,
                  cursor: "pointer",
                  marginLeft: 4,
                }}
              >
                {"\u25A3"} {compoundSpanRanges.length}
              </button>
            )}
          </div>
        )}
        <div
          className="editor-container"
          style={pendingTransclusion ? { cursor: "crosshair" } : undefined}
          onMouseMove={handleOverlayMouseMove}
          onMouseLeave={handleOverlayMouseLeave}
          onClick={handleOverlayClick}
        >
          <canvas
            ref={overlayRef}
            className="attribution-overlay"
          />
          {hoveredMarker && tooltipPos && (
            <div
              className="marker-tooltip"
              onMouseEnter={cancelHideTooltip}
              onMouseLeave={scheduleHideTooltip}
              style={{
                position: "fixed",
                left: tooltipPos.x + 10,
                top: tooltipPos.y - 10,
                zIndex: 100,
              }}
            >
              <div className="marker-tooltip-title" style={{ color: hoveredMarker.linkTypeId ? (LINK_TYPE_STYLES[hoveredMarker.linkTypeId]?.color ?? hoveredMarker.color) : hoveredMarker.color }}>
                {hoveredMarker.otherWorkTitle}
              </div>
              <div className="marker-tooltip-direction">
                {hoveredMarker.linkTypeId
                  ? `${LINK_TYPE_NAMES[hoveredMarker.linkTypeId] ?? "Link"} — ${hoveredMarker.direction === "outgoing" ? "links to" : "linked from"}`
                  : hoveredMarker.linkId === 0
                    ? `Compound — transcluded from`
                    : hoveredMarker.direction === "outgoing" ? "Transcluded to" : "Transcluded from"}
              </div>
              {hoveredMarker.excerpt && (
                <div className="marker-tooltip-excerpt" style={{ fontSize: 11, color: "#8b949e", marginTop: 4, fontStyle: "italic", maxHeight: 60, overflow: "hidden" }}>
                  &ldquo;{hoveredMarker.excerpt}&rdquo;
                </div>
              )}
              {hoveredMarker.otherWorkIsArchived && (
                <div
                  className="marker-tooltip-archived"
                  style={{ color: "#8a6d3b", fontWeight: 600, marginTop: 4 }}
                >
                  🗄 Archived work — content retained, source hidden
                  {hoveredMarker.otherWorkOwner != null
                    ? ` · owner: club:${hoveredMarker.otherWorkOwner
                        .toString(16)
                        .padStart(4, "0")}`
                    : ""}
                </div>
              )}
              {hoveredMarker.provenanceChain && hoveredMarker.provenanceChain.length > 0 && (
                <div className="marker-tooltip-chain">
                  {hoveredMarker.provenanceChain.length} provenance hop{hoveredMarker.provenanceChain.length > 1 ? "s" : ""}
                </div>
              )}
              {onNavigateToWork && (
                <button
                  className="marker-tooltip-link"
                  onClick={(e) => {
                    e.stopPropagation();
                    onNavigateToWork(hoveredMarker.otherWorkId);
                  }}
                >
                  Go to {hoveredMarker.otherWorkId.toString(16).padStart(4, "0")}
                </button>
              )}
            </div>
          )}
          <div
            ref={editorRef}
            className={`editor-content${!editable ? " editor-readonly" : ""}`}
            contentEditable={editable && !pendingTransclusion}
            suppressContentEditableWarning
            onInput={handleInput}
            onKeyDown={handleKeyDown}
            onPaste={handlePaste}
            onClick={handleEditorClick}
            onMouseMove={handleEditorMouseMove}
            onMouseLeave={() => setPlacementIndicator(null)}
            onCompositionStart={() => { isComposing.current = true; }}
            onCompositionEnd={() => {
              isComposing.current = false;
              handleInput();
            }}
            spellCheck
            style={{
              fontSize: fontSize ? `${fontSize}px` : undefined,
              lineHeight: lineHeight ? `${lineHeight}` : undefined,
            }}
          />
          <RemoteCursors editorRef={editorRef} states={remoteCursors} />
          {placementIndicator && (
            <div
              style={{
                position: "absolute",
                left: placementIndicator.x - 1,
                top: placementIndicator.y,
                height: placementIndicator.height,
                width: 2,
                background: "#f59e0b",
                borderRadius: 1,
                pointerEvents: "none",
                zIndex: 6,
              }}
            >
              <div
                style={{
                  position: "absolute",
                  top: -18,
                  left: 0,
                  background: "#f59e0b",
                  color: "#fff",
                  fontSize: 10,
                  fontWeight: 600,
                  padding: "1px 5px",
                  borderRadius: "3px 3px 3px 0",
                  whiteSpace: "nowrap",
                }}
              >
                &#8594; pos {placementIndicator.pos}
              </div>
            </div>
          )}
        </div>
        {outlineOpen && (
          <OutlinePanel
            buffer={buffer}
            onJumpTo={jumpToCharOffset}
            onMoveSection={(newText) => onTextChange?.(newText)}
            onClose={() => setOutlineOpen(false)}
          />
        )}
      </div>
      <div className="editor-status">
        <span className={`sync-indicator ${connected ? "sync-connected" : "sync-disconnected"}`}>
          {connected ? "Synced" : "Offline"}
        </span>
        {attributionSpans.length > 0 && attributionSpans.some(s => !s.signature_valid) && (
          <span className="attribution-mode-label" style={{ color: "#f85149", fontWeight: 700 }}>
            {attributionSpans.filter(s => !s.signature_valid).length} unsigned span{attributionSpans.filter(s => !s.signature_valid).length !== 1 ? "s" : ""} &mdash; signatures not verified
          </span>
        )}
        {attributionSpans.length > 0 && (
          <span className="attribution-mode-label">
            Attribution view
          </span>
        )}
        {attributionSpans.length > 0 && (
          <div className="attribution-legend">
            {Array.from(authorColorMap.entries()).map(([key, style]) => (
              <span key={key} className="legend-item">
                <span
                  className="legend-swatch"
                  style={{
                    backgroundColor: style.color + "60",
                    borderBottom: style.authorType === "historical"
                      ? `2px dashed ${style.color}`
                      : `2px solid ${style.color}`,
                  }}
                />
                <span className={`legend-name${style.authorType === "historical" ? " historical-name" : ""}${style.authorType === "llm" ? " llm-name" : ""}`}>
                  {style.name}
                </span>
              </span>
            ))}
          </div>
        )}
        <span style={{ marginLeft: "auto" }} />
        {hasContentRange && bodyRange && (
          <button
            className={`search-option${showBoilerplate ? " active" : ""}`}
            onClick={() => setShowBoilerplate(!showBoilerplate)}
            title={showBoilerplate ? "Hide boilerplate" : "Show boilerplate"}
          >
            {showBoilerplate ? "Hide Wrapper" : `Wrapper (${bodyRange.prefixLines}+${bodyRange.suffixLines} lines)`}
          </button>
        )}
        <button
          className={`search-option${outlineOpen ? " active" : ""}`}
          onClick={() => setOutlineOpen(!outlineOpen)}
          title="Document outline"
        >
          Outline
        </button>
      </div>
    </div>
  );
}

function getTextContent(el: HTMLElement): string {
  let result = "";
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT);
  let node: Node | null;
  while ((node = walker.nextNode())) {
    if (node.nodeType === Node.TEXT_NODE) {
      result += node.textContent || "";
    } else if (node.nodeType === Node.ELEMENT_NODE) {
      const tag = (node as Element).tagName;
      if (tag === "BR") {
        result += "\n";
      } else if (tag === "DIV" || tag === "P") {
        if (result.length > 0 && !result.endsWith("\n")) {
          result += "\n";
        }
      }
    }
  }
  return result.replace(/\u200B/g, "");
}

function isReadonlyNode(node: Node | null): boolean {
  let n = node;
  while (n && n.nodeType !== Node.DOCUMENT_NODE) {
    if (n.nodeType === Node.ELEMENT_NODE) {
      const el = n as Element;
      if (el.getAttribute && el.getAttribute("contenteditable") === "false") return true;
    }
    n = n.parentNode;
  }
  return false;
}

function getEditableText(el: HTMLElement): string {
  let result = "";
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT);
  let node: Node | null;
  while ((node = walker.nextNode())) {
    if (node.nodeType === Node.TEXT_NODE) {
      if (isReadonlyNode(node)) continue;
      result += node.textContent || "";
    } else if (node.nodeType === Node.ELEMENT_NODE) {
      if (isReadonlyNode(node)) continue;
      const tag = (node as Element).tagName;
      if (tag === "BR") {
        result += "\n";
      } else if (tag === "DIV" || tag === "P") {
        if (result.length > 0 && !result.endsWith("\n")) {
          result += "\n";
        }
      }
    }
  }
  return result.replace(/\u200B/g, "");
}

function buildTransclusionDom(
  el: HTMLElement,
  resolvedText: string,
  spanRanges: SpanRangePayload[],
  sourceTitles?: Record<number, string>,
) {
  el.textContent = "";
  if (spanRanges.length === 0) {
    el.textContent = resolvedText;
    if (resolvedText.endsWith("\n")) {
      el.appendChild(document.createTextNode("\u200B"));
    }
    return;
  }

  const sorted = [...spanRanges].sort((a, b) => a.flat_start - b.flat_start);
  let pos = 0;

  for (const sr of sorted) {
    if (sr.flat_start > pos) {
      el.appendChild(document.createTextNode(resolvedText.slice(pos, sr.flat_start)));
    }
    const content = resolvedText.slice(sr.flat_start, sr.flat_end);
    const title = sourceTitles?.[sr.source_work_id] || sr.source_work_id.toString(16);
    const span = document.createElement("span");
    span.className = "inline-transclusion";
    span.setAttribute("contenteditable", "false");
    span.textContent = content;
    span.title = `Transclusion from: ${title} (click to navigate)`;
    (span as HTMLElement).dataset.sourceWorkId = String(sr.source_work_id);
    el.appendChild(span);
    pos = sr.flat_end;
  }

  if (pos < resolvedText.length) {
    el.appendChild(document.createTextNode(resolvedText.slice(pos)));
  }
  if (resolvedText.endsWith("\n")) {
    el.appendChild(document.createTextNode("\u200B"));
  }
}
