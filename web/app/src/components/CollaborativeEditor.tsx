import { useRef, useEffect, useCallback, useMemo, useState } from "react";
import type { AttributionSpan, TransclusionMarker } from "../api/crdt_sync";
import type { PendingTransclusion } from "../hooks/useTransclusion";
import { authorColor } from "../author-color";
import { TextBuffer } from "../api/text_buffer";
import { SearchPanel } from "./SearchPanel";
import { OutlinePanel } from "./OutlinePanel";

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
  onTextChange: (text: string) => void;
  onCursorChange: (index: number | null) => void;
  onSelectionChange: (start: number | null, end: number | null) => void;
  connected: boolean;
  attributionSpans: AttributionSpan[];
  editable: boolean;
  contentStartLine?: number;
  contentEndLine?: number;
  transclusionMarkers?: TransclusionMarker[];
  pendingTransclusion?: PendingTransclusion | null;
  onPlaceTransclusion?: (position: number) => void;
  selectionRange?: { start: number; end: number } | null;
  onNavigateToWork?: (workId: number) => void;
  onPasteText?: (text: string, pasteStart: number) => void;
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
}

function drawOverlay(
  editor: HTMLElement | null,
  canvas: HTMLCanvasElement | null,
  spans: AttributionSpan[],
  colorMap: Map<string, AuthorStyle>,
  markers: TransclusionMarker[] = [],
): MarkerHitZone[] {
  const hitZones: MarkerHitZone[] = [];
  if (!editor || !canvas) return hitZones;
  if (spans.length === 0 && markers.length === 0) return hitZones;

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

  for (const span of spans) {
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
    for (const r of rangeRects) {
      const x = r.left - rect.left;
      const y = r.top - rect.top;
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

  for (const marker of markers) {
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

    const barWidth = 3 + (marker.provenanceChain && marker.provenanceChain.length > 0
      ? 1 + marker.provenanceChain.length * 3 : 0);

    ctx.fillStyle = marker.color + "60";
    ctx.fillRect(0, firstTop, 3, height);

    if (marker.provenanceChain && marker.provenanceChain.length > 0) {
      const chainCount = marker.provenanceChain.length;
      const stackWidth = 2;
      const gap = 1;
      const chainColor = "#c4a35a";
      for (let i = 0; i < chainCount; i++) {
        const stackX = 3 + gap + i * (stackWidth + gap);
        ctx.fillStyle = chainColor + "80";
        ctx.fillRect(stackX, firstTop, stackWidth, height);
      }
    }

    hitZones.push({
      marker,
      x: 0,
      y: firstTop,
      width: Math.max(barWidth, 12),
      height,
    });
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
  onPasteText,
}: CollaborativeEditorProps) {
  const editorRef = useRef<HTMLDivElement>(null);
  const overlayRef = useRef<HTMLCanvasElement>(null);
  const hitZonesRef = useRef<MarkerHitZone[]>([]);
  const isComposing = useRef(false);
  const lastText = useRef(text);
  const [searchOpen, setSearchOpen] = useState(false);
  const [outlineOpen, setOutlineOpen] = useState(false);
  const [showBoilerplate, setShowBoilerplate] = useState(false);
  const [hoveredMarker, setHoveredMarker] = useState<TransclusionMarker | null>(null);
  const [tooltipPos, setTooltipPos] = useState<{ x: number; y: number } | null>(null);

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

  useEffect(() => {
    const el = editorRef.current;
    if (!el) return;
    const currentText = getTextContent(el);
    if (currentText !== displayText) {
      if (displayText.length > LARGE_DOC_THRESHOLD) {
        chunkedSetTextContent(el, displayText);
      } else {
        el.textContent = displayText;
      }
    }
    lastText.current = displayText;
  }, [displayText]);

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
        hitZonesRef.current = drawOverlay(el, canvas, attributionSpans, authorColorMap, transclusionMarkers);
      });
    };

    hitZonesRef.current = drawOverlay(el, canvas, attributionSpans, authorColorMap, transclusionMarkers);

    const ro = new ResizeObserver(redraw);
    ro.observe(container);
    container.addEventListener("scroll", redraw, { passive: true });

    return () => {
      ro.disconnect();
      container.removeEventListener("scroll", redraw);
      cancelAnimationFrame(rafId);
    };
  }, [attributionSpans, authorColorMap, transclusionMarkers]);

  const handleOverlayMouseMove = useCallback((e: React.MouseEvent<HTMLCanvasElement>) => {
    const canvas = overlayRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const hit = hitZonesRef.current.find((hz) =>
      x >= hz.x && x <= hz.x + hz.width && y >= hz.y && y <= hz.y + hz.height
    );
    if (hit) {
      setHoveredMarker(hit.marker);
      setTooltipPos({ x: e.clientX, y: e.clientY });
      canvas.style.cursor = "pointer";
    } else {
      setHoveredMarker(null);
      setTooltipPos(null);
      canvas.style.cursor = "";
    }
  }, []);

  const handleOverlayMouseLeave = useCallback(() => {
    setHoveredMarker(null);
    setTooltipPos(null);
  }, []);

  const handleOverlayClick = useCallback((e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!onNavigateToWork) return;
    const canvas = overlayRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const hit = hitZonesRef.current.find((hz) =>
      x >= hz.x && x <= hz.x + hz.width && y >= hz.y && y <= hz.y + hz.height
    );
    if (hit) {
      onNavigateToWork(hit.marker.otherWorkId);
    }
  }, [onNavigateToWork]);

  const handleInput = useCallback(() => {
    if (isComposing.current || !editable) return;
    const el = editorRef.current;
    if (!el) return;
    const newText = getTextContent(el);
    if (newText !== lastText.current) {
      lastText.current = newText;
      onTextChange(newText);
    }
  }, [onTextChange, editable]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (!editable) { e.preventDefault(); return; }
    if (e.key === "Enter") {
      e.preventDefault();
      const sel = window.getSelection();
      if (!sel || sel.rangeCount === 0) return;
      const range = sel.getRangeAt(0);
      range.deleteContents();
      const textNode = document.createTextNode("\n");
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
  }, [handleInput]);

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
    pre.selectNodeContents(el);
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
      onSelectionChange(null, null);
    } else {
      const preEnd = document.createRange();
      preEnd.selectNodeContents(el);
      preEnd.setEnd(range.endContainer, range.endOffset);
      const end = preEnd.toString().length;
      onCursorChange(null);
      onSelectionChange(start, end);
    }
  }, [onCursorChange, onSelectionChange]);

  const handleEditorClick = useCallback((e: React.MouseEvent) => {
    if (!pendingTransclusion || !onPlaceTransclusion) return;
    const el = editorRef.current;
    if (!el) return;
    if (!el.contains(e.target as Node)) return;

    const sel = window.getSelection();
    if (!sel || sel.rangeCount === 0) return;
    const range = sel.getRangeAt(0);
    const pre = document.createRange();
    pre.selectNodeContents(el);
    pre.setEnd(range.startContainer, range.startOffset);
    const pos = pre.toString().length;
    onPlaceTransclusion(pos);
  }, [pendingTransclusion, onPlaceTransclusion]);

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
        <div className="editor-container" style={pendingTransclusion ? { cursor: "crosshair" } : undefined}>
          <canvas
            ref={overlayRef}
            className="attribution-overlay"
            onMouseMove={handleOverlayMouseMove}
            onMouseLeave={handleOverlayMouseLeave}
            onClick={handleOverlayClick}
          />
          {hoveredMarker && tooltipPos && (
            <div
              className="marker-tooltip"
              style={{
                position: "fixed",
                left: tooltipPos.x + 10,
                top: tooltipPos.y - 10,
                pointerEvents: "none",
                zIndex: 100,
              }}
            >
              <div className="marker-tooltip-title" style={{ color: hoveredMarker.color }}>
                {hoveredMarker.otherWorkTitle}
              </div>
              <div className="marker-tooltip-direction">
                {hoveredMarker.direction === "outgoing" ? "Transcluded to" : "Transcluded from"}
              </div>
              {hoveredMarker.provenanceChain && hoveredMarker.provenanceChain.length > 0 && (
                <div className="marker-tooltip-chain">
                  {hoveredMarker.provenanceChain.length} provenance hop{hoveredMarker.provenanceChain.length > 1 ? "s" : ""}
                </div>
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
            onCompositionStart={() => { isComposing.current = true; }}
            onCompositionEnd={() => {
              isComposing.current = false;
              handleInput();
            }}
            spellCheck
          />
        </div>
        {outlineOpen && (
          <OutlinePanel
            buffer={buffer}
            onJumpTo={jumpToCharOffset}
            onMoveSection={(newText) => onTextChange(newText)}
            onClose={() => setOutlineOpen(false)}
          />
        )}
      </div>
      <div className="editor-status">
        <span className={`sync-indicator ${connected ? "sync-connected" : "sync-disconnected"}`}>
          {connected ? "Synced" : "Offline"}
        </span>
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
  return result;
}
