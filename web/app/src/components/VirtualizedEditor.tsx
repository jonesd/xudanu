import React, { useRef, useEffect, useCallback, useMemo, useState } from "react";
import { TextBuffer } from "../api/text_buffer";
import type { AttributionSpan, TransclusionMarker } from "../api/crdt_sync";
import type { PendingTransclusion } from "../hooks/useTransclusion";
import { authorColor } from "../author-color";
import { SearchPanel } from "./SearchPanel";
import { OutlinePanel } from "./OutlinePanel";

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

interface VirtualizedEditorProps {
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
  fontSize?: number;
  lineHeight?: number;
}

const DEFAULT_FONT_SIZE = 15;
const DEFAULT_LINE_HEIGHT = 1.7;
const PADDING_TOP = 16;
const PADDING_BOTTOM = 16;
const OVERSCAN = 15;

function VirtualizedEditorInner({
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
  onNavigateToWork: _onNavigateToWork,
  onPasteText,
  fontSize = DEFAULT_FONT_SIZE,
  lineHeight = DEFAULT_LINE_HEIGHT,
}: VirtualizedEditorProps) {
  const bufferRef = useRef<TextBuffer | null>(null);
  if (bufferRef.current === null) bufferRef.current = new TextBuffer(text);
  const LINE_HEIGHT = fontSize * lineHeight;
  const containerRef = useRef<HTMLDivElement>(null);
  const editorRef = useRef<HTMLDivElement>(null);
  const overlayRef = useRef<HTMLCanvasElement>(null);
  const topSpacerRef = useRef<HTMLDivElement>(null);
  const bottomSpacerRef = useRef<HTMLDivElement>(null);
  const isComposing = useRef(false);
  const skipNextTextProp = useRef(false);
  const lineHeightRef = useRef(LINE_HEIGHT);
  const lastViewRange = useRef({ start: 0, end: 60 });
  const undoStack = useRef<UndoEntry[]>([]);
  const redoStack = useRef<UndoEntry[]>([]);
  const undoTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isUndoRedoing = useRef(false);

  const [viewStart, setViewStart] = useState(0);
  const [viewEnd, setViewEnd] = useState(60);
  const [searchOpen, setSearchOpen] = useState(false);
  const [outlineOpen, setOutlineOpen] = useState(false);
  const [showBoilerplate, setShowBoilerplate] = useState(false);

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
    if (isUndoRedoing.current) return;
    if (skipNextTextProp.current) {
      skipNextTextProp.current = false;
      return;
    }
    const buf = bufferRef.current;
    if (buf.getText() !== displayText) {
      if (undoTimer.current !== null) {
        clearTimeout(undoTimer.current);
        undoTimer.current = null;
        undoStack.current.push({ text: buf.getText(), selStart: 0, selEnd: 0 });
        if (undoStack.current.length > MAX_UNDO) undoStack.current.shift();
      }
      redoStack.current = [];
      bufferRef.current = new TextBuffer(displayText);
    }
  }, [displayText]);

  useEffect(() => {
    const hash = window.location.hash;
    if (!hash || displayText.length === 0) return;
    const buf = bufferRef.current;
    const container = containerRef.current;
    if (!container) return;

    let charOffset = -1;
    if (hash.startsWith("#L")) {
      const line = parseInt(hash.slice(2), 10);
      if (!isNaN(line) && line >= 0) {
        charOffset = buf.getCharOffset(line);
      }
    } else if (hash.startsWith("#C")) {
      const c = parseInt(hash.slice(2), 10);
      if (!isNaN(c) && c >= 0) {
        charOffset = c;
      }
    }

    if (charOffset >= 0) {
      const line = buf.getLineForChar(charOffset);
      const lh = lineHeightRef.current;
      const targetScroll = PADDING_TOP + line * lh - container.clientHeight / 3;
      container.scrollTo({ top: Math.max(0, targetScroll), behavior: "smooth" });
      history.replaceState(null, "", window.location.pathname + window.location.search);
    }
  }, [text]);

  const updateSpacers = useCallback((buf: TextBuffer, vs: number, ve: number) => {
    const el = editorRef.current;
    const totalLines = buf.getLineCount();
    const visibleCount = ve - vs;

    let avgLineHeight = lineHeightRef.current;
    if (el && visibleCount > 0) {
      const actualHeight = el.getBoundingClientRect().height;
      if (actualHeight > 0) {
        avgLineHeight = actualHeight / visibleCount;
      }
    }

    if (topSpacerRef.current) {
      topSpacerRef.current.style.height = `${PADDING_TOP + vs * avgLineHeight}px`;
    }
    if (bottomSpacerRef.current) {
      const totalHeight = PADDING_TOP + totalLines * avgLineHeight + PADDING_BOTTOM;
      const visibleHeight = visibleCount * avgLineHeight;
      bottomSpacerRef.current.style.height = `${Math.max(0, totalHeight - PADDING_TOP - vs * avgLineHeight - visibleHeight)}px`;
    }
  }, []);

  const renderVisible = useCallback(() => {
    const el = editorRef.current;
    const buf = bufferRef.current;
    if (!el || buf.getLineCount() === 0) return;

    const { start: vs, end: ve } = lastViewRange.current;
    const visibleText = buf.getLinesRange(vs, ve);

    const sel = window.getSelection();
    let localCursorOffset: number | null = null;
    if (sel && sel.rangeCount > 0 && el.contains(sel.anchorNode)) {
      const range = sel.getRangeAt(0);
      const pre = document.createRange();
      pre.selectNodeContents(el);
      pre.setEnd(range.startContainer, range.startOffset);
      localCursorOffset = pre.toString().length;
    }

    if (el.textContent !== visibleText) {
      el.textContent = visibleText;
    }

    if (localCursorOffset !== null) {
      const textNode = el.firstChild;
      if (textNode && textNode.nodeType === Node.TEXT_NODE) {
        try {
          const clamped = Math.min(localCursorOffset, (textNode as Text).length);
          const newRange = document.createRange();
          newRange.setStart(textNode as Text, clamped);
          newRange.collapse(true);
          sel!.removeAllRanges();
          sel!.addRange(newRange);
        } catch (e) {
          console.warn("VirtualizedEditor: failed to restore cursor:", e);
        }
      }
    }

    updateSpacers(buf, vs, ve);
  }, [updateSpacers]);

  const updateViewport = useCallback(() => {
    const container = containerRef.current;
    const buf = bufferRef.current;
    if (!container || !buf || buf.getLineCount() === 0) return;

    const scrollTop = container.scrollTop;
    const viewportHeight = container.clientHeight;
    const lh = lineHeightRef.current;

    const firstVisible = Math.max(0, Math.floor((scrollTop - PADDING_TOP) / lh) - OVERSCAN);
    const lastVisible = Math.min(
      buf.getLineCount(),
      Math.ceil((scrollTop - PADDING_TOP + viewportHeight) / lh) + OVERSCAN,
    );

    const prev = lastViewRange.current;
    if (prev.start === firstVisible && prev.end === lastVisible) return;

    lastViewRange.current = { start: firstVisible, end: lastVisible };
    setViewStart(firstVisible);
    setViewEnd(lastVisible);
  }, []);

  useEffect(() => {
    renderVisible();
  }, [displayText, viewStart, viewEnd, renderVisible]);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    let rafId = 0;
    const onScroll = () => {
      cancelAnimationFrame(rafId);
      rafId = requestAnimationFrame(updateViewport);
    };

    container.addEventListener("scroll", onScroll, { passive: true });
    const ro = new ResizeObserver(updateViewport);
    ro.observe(container);

    updateViewport();

    return () => {
      container.removeEventListener("scroll", onScroll);
      ro.disconnect();
      cancelAnimationFrame(rafId);
    };
  }, [updateViewport]);

  useEffect(() => {
    const el = editorRef.current;
    if (!el) return;
    const textNode = el.firstChild;
    if (textNode && textNode.nodeType === Node.TEXT_NODE) {
      const content = (textNode as Text).textContent || "";
      const firstNewline = content.indexOf("\n");
      const sampleText = firstNewline > 0 ? content.slice(0, firstNewline) : content;
      if (sampleText.length > 0) {
        const span = document.createElement("span");
        span.textContent = sampleText;
        span.style.visibility = "hidden";
        span.style.position = "absolute";
        span.style.fontSize = "15px";
        span.style.lineHeight = "1.7";
        span.style.whiteSpace = "pre";
        document.body.appendChild(span);
        const measured = span.getBoundingClientRect().height;
        document.body.removeChild(span);
        if (measured > 0) {
          lineHeightRef.current = measured;
        }
      }
    }
  }, [viewStart]);

  useEffect(() => {
    const el = editorRef.current;
    const canvas = overlayRef.current;
    if (!el || !canvas || attributionSpans.length === 0) return;

    const container = containerRef.current;
    if (!container) return;

    const rect = container.getBoundingClientRect();
    if (rect.width === 0 || rect.height === 0) return;

    const dpr = window.devicePixelRatio || 1;
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    canvas.style.width = rect.width + "px";
    canvas.style.height = rect.height + "px";

    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, rect.width, rect.height);

    const buf = bufferRef.current;
    const viewportCharStart = buf.getCharOffset(viewStart);
    const viewportCharEnd = buf.getCharOffset(viewEnd);
    const viewportTextLen = viewportCharEnd - viewportCharStart;

    for (const span of attributionSpans) {
      const key = bytesToHex(span.author_public_key);
      const style = authorColorMap.get(key);
      if (!style) continue;

      const drawStart = Math.max(span.start, viewportCharStart) - viewportCharStart;
      const drawEnd = Math.min(span.end, viewportCharEnd) - viewportCharStart;
      if (drawStart >= drawEnd || drawEnd <= 0 || drawStart >= viewportTextLen) continue;

      const textNode = el.firstChild;
      if (!textNode || textNode.nodeType !== Node.TEXT_NODE) continue;

      const range = document.createRange();
      try {
        const cs = Math.max(0, Math.min(drawStart, viewportTextLen));
        const ce = Math.max(0, Math.min(drawEnd, viewportTextLen));
        range.setStart(textNode as Text, cs);
        range.setEnd(textNode as Text, ce);
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

    for (const marker of transclusionMarkers) {
      const drawStart = Math.max(marker.start, viewportCharStart) - viewportCharStart;
      const drawEnd = Math.min(marker.end, viewportCharEnd) - viewportCharStart;
      if (drawStart >= drawEnd || drawEnd <= 0 || drawStart >= viewportTextLen) continue;

      const textNode = el.firstChild;
      if (!textNode || textNode.nodeType !== Node.TEXT_NODE) continue;

      const range = document.createRange();
      try {
        const cs = Math.max(0, Math.min(drawStart, viewportTextLen));
        const ce = Math.max(0, Math.min(drawEnd, viewportTextLen));
        range.setStart(textNode as Text, cs);
        range.setEnd(textNode as Text, ce);
      } catch {
        continue;
      }

      const rangeRects = range.getClientRects();
      if (rangeRects.length === 0) continue;

      const firstTop = rangeRects[0].top - rect.top;
      const lastRect = rangeRects[rangeRects.length - 1];
      const lastBottom = lastRect.bottom - rect.top;

      ctx.fillStyle = marker.color + "60";
      ctx.fillRect(0, firstTop, 3, lastBottom - firstTop);
    }
  }, [attributionSpans, authorColorMap, viewStart, viewEnd, transclusionMarkers]);

  const pushUndo = useCallback((prevText: string) => {
    if (isUndoRedoing.current) return;
    redoStack.current = [];
    if (undoTimer.current !== null) {
      clearTimeout(undoTimer.current);
    }
    undoTimer.current = setTimeout(() => {
      undoStack.current.push({ text: prevText, selStart: 0, selEnd: 0 });
      if (undoStack.current.length > MAX_UNDO) {
        undoStack.current.shift();
      }
      undoTimer.current = null;
    }, UNDO_DEBOUNCE_MS);
  }, []);

  const restoreUndoEntry = useCallback((entry: UndoEntry, stack: "undo" | "redo") => {
    isUndoRedoing.current = true;
    const prevText = bufferRef.current.getText();
    bufferRef.current = new TextBuffer(entry.text);
    skipNextTextProp.current = true;
    onTextChange(entry.text);
    const target = stack === "undo" ? redoStack : undoStack;
    target.current.push({ text: prevText, selStart: 0, selEnd: 0 });
    if (target.current.length > MAX_UNDO) target.current.shift();
    setTimeout(() => { isUndoRedoing.current = false; }, 0);
  }, [onTextChange]);

  const handleInput = useCallback(() => {
    if (isComposing.current || !editable) return;
    const el = editorRef.current;
    if (!el) return;

    const visibleText = el.textContent || "";
    const buf = bufferRef.current;
    const oldFullText = buf.getText();

    const { start: vs, end: ve } = lastViewRange.current;
    const viewportCharStart = buf.getCharOffset(vs);
    const viewportCharEnd = buf.getCharOffset(ve);

    const newFullText =
      oldFullText.slice(0, viewportCharStart) +
      visibleText +
      oldFullText.slice(viewportCharEnd);

    if (newFullText !== oldFullText) {
      pushUndo(oldFullText);
      bufferRef.current = new TextBuffer(newFullText);
      skipNextTextProp.current = true;
      onTextChange(newFullText);
    }
  }, [onTextChange, editable, pushUndo]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (!editable) {
        e.preventDefault();
        return;
      }
      if ((e.ctrlKey || e.metaKey) && e.key === "z" && !e.shiftKey) {
        e.preventDefault();
        if (undoTimer.current !== null) {
          clearTimeout(undoTimer.current);
          undoTimer.current = null;
        }
        const entry = undoStack.current.pop();
        if (entry) restoreUndoEntry(entry, "undo");
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
    },
    [handleInput, editable],
  );

  const handlePaste = useCallback(
    (e: React.ClipboardEvent) => {
      if (!editable) {
        e.preventDefault();
        return;
      }
      e.preventDefault();
      const pasteText = e.clipboardData.getData("text/plain");
      if (!pasteText) return;
      const sel = window.getSelection();
      if (!sel || sel.rangeCount === 0) return;
      const el = editorRef.current;
      const range = sel.getRangeAt(0);

      const buf = bufferRef.current;
      const { start: vs } = lastViewRange.current;
      const viewportCharStart = buf.getCharOffset(vs);
      const pre = document.createRange();
      pre.selectNodeContents(el);
      pre.setEnd(range.startContainer, range.startOffset);
      const localStart = pre.toString().length;
      const pasteStart = viewportCharStart + localStart;

      range.deleteContents();
      const textNode = document.createTextNode(pasteText);
      range.insertNode(textNode);
      range.setStartAfter(textNode);
      range.collapse(true);
      sel.removeAllRanges();
      sel.addRange(range);
      handleInput();
      if (onPasteText && pasteText.length > 50) onPasteText(pasteText, pasteStart);
    },
    [handleInput, editable, onPasteText],
  );

  const handleSelectionChange = useCallback(() => {
    const el = editorRef.current;
    const sel = window.getSelection();
    if (!sel || sel.rangeCount === 0 || !el?.contains(sel.anchorNode)) return;

    const range = sel.getRangeAt(0);
    const buf = bufferRef.current;
    const { start: vs } = lastViewRange.current;
    const viewportCharStart = buf.getCharOffset(vs);

    const pre = document.createRange();
    pre.selectNodeContents(el);
    pre.setEnd(range.startContainer, range.startOffset);
    const localStart = pre.toString().length;
    const globalStart = viewportCharStart + localStart;

    if (sel.isCollapsed) {
      onCursorChange(globalStart);
      onSelectionChange(null, null);
    } else {
      const preEnd = document.createRange();
      preEnd.selectNodeContents(el);
      preEnd.setEnd(range.endContainer, range.endOffset);
      const localEnd = preEnd.toString().length;
      const globalEnd = viewportCharStart + localEnd;
      onCursorChange(null);
      onSelectionChange(globalStart, globalEnd);
    }
  }, [onCursorChange, onSelectionChange]);

  const handleEditorClick = useCallback((e: React.MouseEvent) => {
    if (!pendingTransclusion || !onPlaceTransclusion) return;
    const el = editorRef.current;
    if (!el) return;
    if (!el.contains(e.target as Node)) return;

    const buf = bufferRef.current;
    const { start: vs } = lastViewRange.current;
    const viewportCharStart = buf.getCharOffset(vs);

    let range: Range | null = null;
    const sel = window.getSelection();
    if (sel && sel.rangeCount > 0) {
      range = sel.getRangeAt(0);
    }
    if (!range) {
      const doc = el.ownerDocument as Document & { caretRangeFromPoint?: (x: number, y: number) => Range | null };
      if (doc.caretRangeFromPoint) {
        range = doc.caretRangeFromPoint(e.clientX, e.clientY);
      }
    }
    if (!range) return;

    const pre = document.createRange();
    pre.selectNodeContents(el);
    pre.setEnd(range.startContainer, range.startOffset);
    const localPos = pre.toString().length;
    const globalPos = viewportCharStart + localPos;
    onPlaceTransclusion(globalPos);
  }, [pendingTransclusion, onPlaceTransclusion]);

  useEffect(() => {
    document.addEventListener("selectionchange", handleSelectionChange);
    return () => {
      document.removeEventListener("selectionchange", handleSelectionChange);
    };
  }, [handleSelectionChange]);

  const jumpToCharOffset = useCallback((charOffset: number) => {
    const container = containerRef.current;
    const buf = bufferRef.current;
    if (!container) return;
    const line = buf.getLineForChar(charOffset);
    const lh = lineHeightRef.current;
    const targetScroll = PADDING_TOP + line * lh - container.clientHeight / 3;
    container.scrollTop = Math.max(0, targetScroll);
  }, []);

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

  const buf = bufferRef.current;

  return (
    <div className="collaborative-editor virtualized">
      {searchOpen && (
        <SearchPanel
          buffer={buf}
          onJumpToMatch={jumpToCharOffset}
          onClose={() => setSearchOpen(false)}
        />
      )}
      <div style={{ position: "relative", flex: 1, display: "flex", minHeight: 0 }}>
        <div
          ref={containerRef}
          className="editor-container virtual-scroll-container"
          style={pendingTransclusion ? { cursor: "crosshair" } : undefined}
        >
          <canvas ref={overlayRef} className="attribution-overlay" />
          <div ref={topSpacerRef} className="virtual-spacer" />
          <div
            ref={editorRef}
            className={`editor-content${!editable ? " editor-readonly" : ""}`}
            contentEditable={editable && !pendingTransclusion}
            suppressContentEditableWarning
            onInput={handleInput}
            onKeyDown={handleKeyDown}
            onPaste={handlePaste}
            onClick={handleEditorClick}
            onCompositionStart={() => {
              isComposing.current = true;
            }}
            onCompositionEnd={() => {
              isComposing.current = false;
              handleInput();
            }}
            spellCheck
          />
          <div ref={bottomSpacerRef} className="virtual-spacer" />
        </div>
        {outlineOpen && (
          <OutlinePanel
            buffer={buf}
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
        {attributionSpans.length > 0 && <span className="attribution-mode-label">Attribution view</span>}
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
        <span className="doc-stats">
          {buf.getLineCount()} lines, {buf.charCount().toLocaleString()} chars
        </span>
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

export const VirtualizedEditor = React.memo(VirtualizedEditorInner);
