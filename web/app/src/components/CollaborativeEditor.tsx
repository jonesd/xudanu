import { useRef, useEffect, useCallback } from "react";

interface CollaborativeEditorProps {
  text: string;
  onTextChange: (text: string) => void;
  onCursorChange: (index: number | null) => void;
  onSelectionChange: (start: number | null, end: number | null) => void;
  connected: boolean;
}

export function CollaborativeEditor({
  text,
  onTextChange,
  onCursorChange,
  onSelectionChange,
  connected,
}: CollaborativeEditorProps) {
  const editorRef = useRef<HTMLDivElement>(null);
  const isComposing = useRef(false);
  const lastText = useRef(text);

  useEffect(() => {
    const el = editorRef.current;
    if (!el) return;

    if (el.textContent !== text) {
      const sel = window.getSelection();
      const range = sel && sel.rangeCount > 0 ? sel.getRangeAt(0) : null;
      let offset = 0;

      if (range) {
        const pre = document.createRange();
        pre.selectNodeContents(el);
        pre.setEnd(range.startContainer, range.startOffset);
        offset = pre.toString().length;
      }

      el.textContent = text;

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
    }
    lastText.current = text;
  }, [text]);

  const handleInput = useCallback(() => {
    if (isComposing.current) return;
    const el = editorRef.current;
    if (!el) return;
    const newText = el.textContent || "";
    if (newText !== lastText.current) {
      lastText.current = newText;
      onTextChange(newText);
    }
  }, [onTextChange]);

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
      </div>
    </div>
  );
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
