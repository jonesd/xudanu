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
  const walker = document.createTreeWalker(editor, NodeFilter.SHOW_TEXT, null);
  let remaining = charIndex;
  let node: Text | null = null;

  while (walker.nextNode()) {
    const textNode = walker.currentNode as Text;
    const len = textNode.textContent?.length ?? 0;
    if (remaining <= len) {
      node = textNode;
      break;
    }
    remaining -= len;
  }

  if (!node) {
    const last = editor.lastChild;
    if (last && last.nodeType === Node.TEXT_NODE) {
      node = last as Text;
      remaining = (node.textContent?.length ?? 0);
    } else {
      return null;
    }
  }

  try {
    const range = document.createRange();
    range.setStart(node, Math.min(remaining, node.textContent?.length ?? 0));
    range.setEnd(node, Math.min(remaining, node.textContent?.length ?? 0));
    const rect = range.getBoundingClientRect();
    const editorRect = editor.getBoundingClientRect();
    return {
      x: rect.left - editorRect.left,
      y: rect.top - editorRect.top,
      height: rect.height || 18,
    };
  } catch {
    return null;
  }
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
              maxWidth: "80px",
              overflow: "hidden",
              textOverflow: "ellipsis",
            }}
          >
            {entry.name}
          </div>
        </div>
      ))}
    </div>
  );
}
