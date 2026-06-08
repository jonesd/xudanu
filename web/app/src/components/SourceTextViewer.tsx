import React, { useRef, useEffect, useCallback, useState } from "react";
import type { CrdtSyncClient } from "../api/crdt_sync";

interface SourceTextViewerProps {
  workId: number;
  clientRef: React.MutableRefObject<CrdtSyncClient | null>;
  connected: boolean;
  fontSize?: number;
  lineHeight?: number;
  onSelectionChange?: (start: number, end: number) => void;
}

const CHUNK = 100_000;
const PADDING = 16;
const OVERSCAN = 10;
const DEFAULT_FONT_SIZE = 15;
const DEFAULT_LINE_HEIGHT = 1.7;

export function SourceTextViewer({ workId, clientRef, connected, fontSize = DEFAULT_FONT_SIZE, lineHeight = DEFAULT_LINE_HEIGHT, onSelectionChange }: SourceTextViewerProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);
  const topSpacerRef = useRef<HTMLDivElement>(null);
  const bottomSpacerRef = useRef<HTMLDivElement>(null);
  const linesRef = useRef<string[]>([]);
  const lineHRef = useRef(fontSize * lineHeight);
  const viewRef = useRef({ start: 0, end: 40 });

  const renderVisible = useCallback(() => {
    const lines = linesRef.current;
    if (lines.length === 0) return;
    const el = contentRef.current;
    if (!el) return;

    const { start, end } = viewRef.current;
    const slice = lines.slice(start, end);
    el.textContent = slice.join("\n");

    const lh = lineHRef.current;
    if (topSpacerRef.current) {
      topSpacerRef.current.style.height = `${PADDING + start * lh}px`;
    }
    if (bottomSpacerRef.current) {
      const total = lines.length * lh + PADDING * 2;
      const visible = (end - start) * lh;
      bottomSpacerRef.current.style.height = `${Math.max(0, total - PADDING - start * lh - visible)}px`;
    }
  }, []);

  const charOffsetForLine = useCallback((line: number) => {
    const lines = linesRef.current;
    let off = 0;
    for (let i = 0; i < line && i < lines.length; i++) {
      off += lines[i].length + 1;
    }
    return off;
  }, []);

  const handleSelectionChange = useCallback(() => {
    if (!onSelectionChange) return;
    const el = contentRef.current;
    if (!el) return;
    const sel = window.getSelection();
    if (!sel || sel.isCollapsed || !sel.rangeCount || !el.contains(sel.anchorNode)) return;
    const { start: viewStart } = viewRef.current;
    const offset = charOffsetForLine(viewStart);
    const range = sel.getRangeAt(0);
    const pre = document.createRange();
    pre.selectNodeContents(el);
    pre.setEnd(range.startContainer, range.startOffset);
    const localStart = pre.toString().length;
    pre.setEnd(range.endContainer, range.endOffset);
    const localEnd = pre.toString().length;
    onSelectionChange(offset + localStart, offset + localEnd);
  }, [onSelectionChange, charOffsetForLine]);

  useEffect(() => {
    document.addEventListener("selectionchange", handleSelectionChange);
    return () => { document.removeEventListener("selectionchange", handleSelectionChange); };
  }, [handleSelectionChange]);

  const onScroll = useCallback(() => {
    const container = containerRef.current;
    const lines = linesRef.current;
    if (!container || lines.length === 0) return;

    const lh = lineHRef.current;
    const scrollTop = container.scrollTop;
    const vpHeight = container.clientHeight;
    const first = Math.max(0, Math.floor((scrollTop - PADDING) / lh) - OVERSCAN);
    const last = Math.min(lines.length, Math.ceil((scrollTop - PADDING + vpHeight) / lh) + OVERSCAN);

    const prev = viewRef.current;
    if (prev.start === first && prev.end === last) return;
    viewRef.current = { start: first, end: last };

    requestAnimationFrame(renderVisible);
  }, [renderVisible]);

  useEffect(() => {
    lineHRef.current = fontSize * lineHeight;
  }, [fontSize, lineHeight]);

  useEffect(() => {
    const el = contentRef.current;
    if (el && linesRef.current.length > 0) {
      renderVisible();
    }
  }, [fontSize, lineHeight, renderVisible]);

  const [ready, setReady] = useState(false);

  useEffect(() => {
    const check = () => {
      const client = clientRef.current;
      if (client && client.isConnected()) {
        setReady(true);
      }
    };
    check();
    const id = setInterval(check, 200);
    return () => clearInterval(id);
  }, [clientRef, ready]);

  useEffect(() => {
    if (!ready || !clientRef.current) return;
    let cancelled = false;
    const client = clientRef.current;
    linesRef.current = [];
    viewRef.current = { start: 0, end: 0 };
    const el = contentRef.current;
    if (el) el.textContent = "";
    (async () => {
      try {
        const first = await client.textRange(workId, 0, CHUNK);
        if (cancelled) return;
        let loaded = first.text;
        const total = first.totalChars;
        while (loaded.length < total && !cancelled) {
          const next = await client.textRange(workId, loaded.length, Math.min(loaded.length + CHUNK, total));
          if (cancelled) return;
          loaded += next.text;
        }
        if (cancelled) return;
        linesRef.current = loaded.split("\n");
        viewRef.current = { start: 0, end: 40 };
        if (containerRef.current) containerRef.current.scrollTop = 0;
        renderVisible();
      } catch (e) {
        console.error("[SourceTextViewer] load failed:", e);
      }
    })();
    return () => { cancelled = true; };
  }, [workId, ready, clientRef, renderVisible]);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;
    container.addEventListener("scroll", onScroll, { passive: true });
    onScroll();

    const onKeyDown = (e: KeyboardEvent) => {
      const lh = lineHRef.current;
      if (e.key === "ArrowDown") {
        e.preventDefault();
        container.scrollTop += lh;
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        container.scrollTop -= lh;
      } else if (e.key === "PageDown") {
        e.preventDefault();
        container.scrollTop += container.clientHeight * 0.9;
      } else if (e.key === "PageUp") {
        e.preventDefault();
        container.scrollTop -= container.clientHeight * 0.9;
      } else if (e.key === "Home") {
        e.preventDefault();
        container.scrollTop = 0;
      } else if (e.key === "End") {
        e.preventDefault();
        container.scrollTop = container.scrollHeight;
      }
    };
    container.addEventListener("keydown", onKeyDown);
    container.tabIndex = 0;
    container.focus();

    return () => {
      container.removeEventListener("scroll", onScroll);
      container.removeEventListener("keydown", onKeyDown);
    };
  }, [onScroll]);

  useEffect(() => {
    if (linesRef.current.length > 0) {
      renderVisible();
    }
  }, [renderVisible]);

  return (
    <div
      ref={containerRef}
      style={{
        overflowY: "auto",
        flex: 1,
        minHeight: 0,
        userSelect: "text",
        cursor: "text",
        background: "#fafafa",
      }}
    >
      <div ref={topSpacerRef} />
      <div
        ref={contentRef}
        style={{
          fontSize: `${fontSize}px`,
          lineHeight: `${lineHeight}`,
          whiteSpace: "pre-wrap",
          wordWrap: "break-word",
          padding: `0 20px`,
        }}
      />
      <div ref={bottomSpacerRef} />
    </div>
  );
}
