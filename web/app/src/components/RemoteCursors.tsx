import { useEffect, useState, useRef } from "react";
import type { AwarenessState } from "../api/crdt_sync";
import { authorColor } from "../author-color";

interface RemoteCursorsProps {
  editorRef: React.RefObject<HTMLDivElement | null>;
  states: AwarenessState[];
}

interface CursorPos {
  x: number;
  y: number;
  height: number;
}

function charIndexToPos(editor: HTMLElement, charIndex: number): CursorPos | null {
  const walker = document.createTreeWalker(
    editor,
    NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT,
    {
      acceptNode(node) {
        if (node.nodeType === Node.TEXT_NODE) return NodeFilter.FILTER_ACCEPT;
        if (node.nodeName === "BR" || node.nodeName === "DIV" || node.nodeName === "P") {
          return NodeFilter.FILTER_ACCEPT;
        }
        return NodeFilter.FILTER_SKIP;
      },
    },
  );
  let remaining = charIndex;

  while (walker.nextNode()) {
    const node = walker.currentNode;
    if (node.nodeType === Node.TEXT_NODE) {
      const textNode = node as Text;
      const raw = textNode.textContent ?? "";
      const len = raw.replace(/\u200B/g, "").length;
      if (remaining <= len) {
        try {
          const range = document.createRange();
          let domOffset = 0;
          let modelCount = 0;
          for (const ch of raw) {
            if (modelCount >= remaining) break;
            if (ch !== "\u200B") modelCount++;
            domOffset += ch.length;
          }
          range.setStart(textNode, domOffset);
          range.setEnd(textNode, domOffset);
          const rect = range.getBoundingClientRect();
          const editorRect = editor.getBoundingClientRect();
          return {
            x: rect.left - editorRect.left,
            y: rect.top - editorRect.top,
            height: rect.height || 18,
          };
        } catch { return null; }
      }
      remaining -= len;
    } else if (node.nodeName === "BR") {
      remaining -= 1;
      if (remaining <= 0) {
        try {
          const range = document.createRange();
          range.setStartAfter(node);
          range.setEndAfter(node);
          const rect = range.getBoundingClientRect();
          const editorRect = editor.getBoundingClientRect();
          return {
            x: rect.left - editorRect.left,
            y: rect.top - editorRect.top,
            height: rect.height || 18,
          };
        } catch { return null; }
      }
    } else if (node.nodeName === "DIV" || node.nodeName === "P") {
      const block = node as HTMLElement;
      const blockText = (block.textContent ?? "").replace(/\u200B/g, "");
      if (remaining <= blockText.length) {
        return charIndexToPos(block, remaining);
      }
      remaining -= blockText.length;
      remaining -= 1;
    }
  }

  const lastChild = editor.lastChild;
  if (lastChild) {
    try {
      const range = document.createRange();
      range.selectNodeContents(editor);
      range.collapse(false);
      const rect = range.getBoundingClientRect();
      const editorRect = editor.getBoundingClientRect();
      return {
        x: rect.left - editorRect.left,
        y: rect.top - editorRect.top,
        height: rect.height || 18,
      };
    } catch { return null; }
  }
  return null;
}

export function RemoteCursors({ editorRef, states }: RemoteCursorsProps) {
  const [positions, setPositions] = useState<Map<string, { pos: CursorPos; name: string; color: string }>>(new Map());
  const rafRef = useRef<number>(0);

  useEffect(() => {
    const update = () => {
      const editor = editorRef.current;
      if (!editor) return;

      const next = new Map<string, { pos: CursorPos; name: string; color: string }>();
      const seen = new Set<string>();

      for (const state of states) {
        if (state.cursor == null) continue;
        if (seen.has(state.user_name)) continue;
        seen.add(state.user_name);

        const pos = charIndexToPos(editor, state.cursor.index);
        if (!pos) continue;

        next.set(state.user_name, {
          pos,
          name: state.user_name,
          color: authorColor(state.user_name),
        });
      }

      setPositions(next);
    };

    if (rafRef.current) cancelAnimationFrame(rafRef.current);
    rafRef.current = requestAnimationFrame(update);

    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
  }, [states, editorRef]);

  // Re-measure on scroll/resize
  useEffect(() => {
    const handler = () => {
      const editor = editorRef.current;
      if (!editor) return;
      setPositions((prev) => {
        const next = new Map<string, { pos: CursorPos; name: string; color: string }>();
        for (const [name, entry] of prev) {
          const state = states.find((s) => s.user_name === name);
          if (state?.cursor) {
            const pos = charIndexToPos(editor, state.cursor.index);
            if (pos) next.set(name, { ...entry, pos });
          }
        }
        return next;
      });
    };

    const editor = editorRef.current?.parentElement;
    editor?.addEventListener("scroll", handler);
    window.addEventListener("resize", handler);
    return () => {
      editor?.removeEventListener("scroll", handler);
      window.removeEventListener("resize", handler);
    };
  }, [states, editorRef]);

  if (positions.size === 0) return null;

  return (
    <div
      style={{
        position: "absolute",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        pointerEvents: "none",
        zIndex: 5,
        overflow: "hidden",
      }}
    >
      {Array.from(positions.values()).map((entry) => (
        <div
          key={entry.name}
          style={{
            position: "absolute",
            left: entry.pos.x,
            top: entry.pos.y,
            height: entry.pos.height,
            transition: "left 80ms ease-out, top 80ms ease-out",
          }}
        >
          {/* Caret line */}
          <div
            style={{
              position: "absolute",
              left: -1,
              top: 0,
              width: 2,
              height: "100%",
              background: entry.color,
              borderRadius: 1,
            }}
          />
          {/* Name label */}
          <div
            style={{
              position: "absolute",
              top: -16,
              left: 0,
              background: entry.color,
              color: "#fff",
              fontSize: 10,
              fontWeight: 600,
              padding: "1px 5px",
              borderRadius: "3px 3px 3px 0",
              whiteSpace: "nowrap",
              lineHeight: "14px",
              maxWidth: "250px",
              zIndex: 20,
              pointerEvents: "none",
            }}
          >
            {entry.name}
          </div>
        </div>
      ))}
    </div>
  );
}
