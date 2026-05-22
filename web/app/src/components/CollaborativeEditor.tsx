import { useRef, useEffect, useCallback, useMemo } from "react";
import type { AttributionSpan } from "../api/crdt_sync";

const AUTHOR_COLORS = [
  "#e06c75", "#61afef", "#98c379", "#c678dd", "#e5c07b",
  "#56b6c2", "#d19a66", "#be5046", "#7ec8e3", "#c3e88d",
];

function bytesToHex(bytes: number[]): string {
  return bytes.map((b) => b.toString(16).padStart(2, "0")).join("");
}

interface AuthorStyle {
  color: string;
  name: string;
}

interface TextSegment {
  text: string;
  style: AuthorStyle | null;
}

interface CollaborativeEditorProps {
  text: string;
  onTextChange: (text: string) => void;
  onCursorChange: (index: number | null) => void;
  onSelectionChange: (start: number | null, end: number | null) => void;
  connected: boolean;
  attributionSpans: AttributionSpan[];
}

export function CollaborativeEditor({
  text,
  onTextChange,
  onCursorChange,
  onSelectionChange,
  connected,
  attributionSpans,
}: CollaborativeEditorProps) {
  const editorRef = useRef<HTMLDivElement>(null);
  const isComposing = useRef(false);
  const lastText = useRef(text);

  const authorColorMap = useMemo(() => {
    const map = new Map<string, AuthorStyle>();
    let idx = 0;
    for (const span of attributionSpans) {
      const key = bytesToHex(span.author_public_key);
      if (!map.has(key)) {
        map.set(key, {
          color: AUTHOR_COLORS[idx % AUTHOR_COLORS.length],
          name: span.author_display_name || "unknown",
        });
        idx++;
      }
    }
    return map;
  }, [attributionSpans]);

  const segments = useMemo(() => {
    if (attributionSpans.length === 0 || text.length === 0) {
      return [{ text, style: null as AuthorStyle | null }];
    }

    const result: TextSegment[] = [];
    let pos = 0;

    const sorted = [...attributionSpans].sort((a, b) => a.start - b.start);

    for (const span of sorted) {
      if (span.start >= text.length) break;
      if (span.end <= pos) continue;

      if (span.start > pos) {
        result.push({ text: text.slice(pos, span.start), style: null });
      }

      const segStart = Math.max(span.start, pos);
      const segEnd = Math.min(span.end, text.length);
      const key = bytesToHex(span.author_public_key);
      const style = authorColorMap.get(key) || null;

      result.push({ text: text.slice(segStart, segEnd), style });
      pos = segEnd;
    }

    if (pos < text.length) {
      result.push({ text: text.slice(pos), style: null });
    }

    return result;
  }, [text, attributionSpans, authorColorMap]);

  useEffect(() => {
    const el = editorRef.current;
    if (!el) return;

    const currentText = getEditorText(el);
    const textChanged = currentText !== text;

    if (textChanged) {
      const sel = window.getSelection();
      const range = sel && sel.rangeCount > 0 ? sel.getRangeAt(0) : null;
      let offset = 0;

      if (range) {
        const pre = document.createRange();
        pre.selectNodeContents(el);
        pre.setEnd(range.startContainer, range.startOffset);
        offset = pre.toString().length;
      }

      renderSegments(el, segments);

      if (range && el.firstChild) {
        try {
          const newRange = document.createRange();
          const pos = findPosition(el, offset);
          newRange.setStart(pos.node, pos.offset);
          newRange.collapse(true);
          const selection = window.getSelection();
          selection?.removeAllRanges();
          selection?.addRange(newRange);
        } catch {
          // cursor restoration failed, leave at end
        }
      }
    } else if (attributionSpans.length > 0) {
      const sel = window.getSelection();
      const range = sel && sel.rangeCount > 0 ? sel.getRangeAt(0) : null;
      let offset = 0;

      if (range && el.contains(range.startContainer)) {
        const pre = document.createRange();
        pre.selectNodeContents(el);
        pre.setEnd(range.startContainer, range.startOffset);
        offset = pre.toString().length;
      }

      renderSegments(el, segments);

      if (range && el.firstChild && el.contains(range.startContainer)) {
        try {
          const newRange = document.createRange();
          const pos = findPosition(el, offset);
          newRange.setStart(pos.node, pos.offset);
          newRange.collapse(true);
          const selection = window.getSelection();
          selection?.removeAllRanges();
          selection?.addRange(newRange);
        } catch {
          // cursor restoration failed
        }
      }
    }
    lastText.current = text;
  }, [text, segments]);

  const handleInput = useCallback(() => {
    if (isComposing.current) return;
    const el = editorRef.current;
    if (!el) return;
    const newText = getEditorText(el);
    if (newText !== lastText.current) {
      lastText.current = newText;
      onTextChange(newText);
    }
  }, [onTextChange]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
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
    e.preventDefault();
    const pasteText = e.clipboardData.getData("text/plain");
    if (!pasteText) return;
    const sel = window.getSelection();
    if (!sel || sel.rangeCount === 0) return;
    const range = sel.getRangeAt(0);
    range.deleteContents();
    const textNode = document.createTextNode(pasteText);
    range.insertNode(textNode);
    range.setStartAfter(textNode);
    range.collapse(true);
    sel.removeAllRanges();
    sel.addRange(range);
    handleInput();
  }, [handleInput]);

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

  useEffect(() => {
    document.addEventListener("selectionchange", handleSelectionChange);
    return () => {
      document.removeEventListener("selectionchange", handleSelectionChange);
    };
  }, [handleSelectionChange]);

  return (
    <div className="collaborative-editor">
      <div
        ref={editorRef}
        className="editor-content"
        contentEditable
        suppressContentEditableWarning
        onInput={handleInput}
        onKeyDown={handleKeyDown}
        onPaste={handlePaste}
        onCompositionStart={() => { isComposing.current = true; }}
        onCompositionEnd={() => {
          isComposing.current = false;
          handleInput();
        }}
        spellCheck
      />
      <div className="editor-status">
        <span className={`sync-indicator ${connected ? "sync-connected" : "sync-disconnected"}`}>
          {connected ? "Synced" : "Offline"}
        </span>
        {attributionSpans.length > 0 && (
          <span className="attribution-mode-label">
            Attribution view
          </span>
        )}
      </div>
    </div>
  );
}

function renderSegments(el: HTMLElement, segments: TextSegment[]) {
  const frag = document.createDocumentFragment();
  for (const seg of segments) {
    if (seg.style) {
      const span = document.createElement("span");
      span.className = "author-highlight";
      span.style.backgroundColor = seg.style.color + "30";
      span.style.borderBottom = `2px solid ${seg.style.color}50`;
      span.textContent = seg.text;
      span.title = seg.style.name;
      frag.appendChild(span);
    } else {
      frag.appendChild(document.createTextNode(seg.text));
    }
  }
  el.innerHTML = "";
  el.appendChild(frag);
}

function getEditorText(el: HTMLElement): string {
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

function findPosition(
  el: Node,
  targetOffset: number,
): { node: Node; offset: number } {
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null);
  let current = 0;
  let node: Node | null;
  while ((node = walker.nextNode())) {
    const len = node.textContent?.length ?? 0;
    if (current + len >= targetOffset) {
      return { node, offset: targetOffset - current };
    }
    current += len;
  }
  const last = el.lastChild || el;
  return { node: last, offset: last.textContent?.length ?? 0 };
}
