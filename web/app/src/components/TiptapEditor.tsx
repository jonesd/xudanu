import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import { useEffect, useRef, useCallback } from "react";
import type { PendingTransclusion } from "../hooks/useTransclusion";

interface TiptapEditorProps {
  text: string;
  onTextChange?: (text: string) => void;
  onCursorChange: (index: number | null) => void;
  onSelectionChange: (start: number | null, end: number | null) => void;
  connected: boolean;
  editable: boolean;
  fontSize?: number;
  lineHeight?: number;
  pendingTransclusion?: PendingTransclusion | null;
  onPlaceTransclusion?: (position: number) => void;
}

export function TiptapEditor({
  text,
  onTextChange,
  onCursorChange,
  onSelectionChange,
  connected,
  editable,
  fontSize,
  lineHeight,
  pendingTransclusion,
  onPlaceTransclusion,
}: TiptapEditorProps) {
  const lastTextRef = useRef(text);
  const isRemoteUpdate = useRef(false);

  function flatTextToHtml(text: string): string {
    if (!text) return "<p></p>";
    const lines = text.split("\n");
    return lines.map((line) => `<p>${line || "<br>"}</p>`).join("");
  }

  const handleUpdate = useCallback((editor: { getText: (opts?: { blockSeparator?: string }) => string }) => {
    if (isRemoteUpdate.current) return;
    const newText = editor.getText({ blockSeparator: "\n" });
    if (newText !== lastTextRef.current) {
      lastTextRef.current = newText;
      onTextChange?.(newText);
    }
  }, [onTextChange]);

  const handleSelection = useCallback((editor: {
    state: { selection: { from: number; to: number; empty: boolean } };
  }) => {
    const { from, to, empty } = editor.state.selection;
    if (empty) {
      onCursorChange(from - 1 >= 0 ? from - 1 : 0);
      onSelectionChange(null, null);
    } else {
      onCursorChange(null);
      onSelectionChange(from - 1, to - 1);
    }
  }, [onCursorChange, onSelectionChange]);

  const editor = useEditor({
    extensions: [
      StarterKit,
    ],
    content: text,
    editable,
    onUpdate: ({ editor }) => handleUpdate(editor),
    onSelectionUpdate: ({ editor }) => handleSelection(editor),
    editorProps: {
      attributes: {
        class: "tiptap-editor-content",
        style: [
          fontSize ? `font-size: ${fontSize}px` : "",
          lineHeight ? `line-height: ${lineHeight}` : "",
        ].filter(Boolean).join("; "),
      },
    },
  });

  const handleEditorClick = useCallback((e: React.MouseEvent) => {
    if (!editor || !pendingTransclusion || !onPlaceTransclusion) return;

    const coords = editor.view.posAtCoords({ left: e.clientX, top: e.clientY });
    if (coords === null) {
      const docLength = editor.state.doc.content.size;
      console.log("[tiptap-placement] below content, appending at end:", docLength);
      onPlaceTransclusion(docLength);
      return;
    }

    const docLength = editor.state.doc.content.size;
    let pos = Math.max(0, coords.pos - 1);

    if (pos >= docLength - 1) {
      const text = editor.getText({ blockSeparator: "\n" });
      const lastLine = editor.view.coordsAtPos(docLength - 1);

      if (e.clientY > lastLine.bottom + 4) {
        const lineHeight = parseFloat(getComputedStyle(editor.view.dom).lineHeight) || 20;
        const linesBelow = Math.max(1, Math.round((e.clientY - lastLine.bottom) / lineHeight));
        console.log("[tiptap-placement] below last line by", linesBelow, "lines, text len:", text.length);
        onPlaceTransclusion(text.length + linesBelow);
        return;
      }

      pos = text.length;
      console.log("[tiptap-placement] at end of doc, pos:", pos);
    }

    console.log("[tiptap-placement] pos:", pos);
    onPlaceTransclusion(pos);
  }, [editor, pendingTransclusion, onPlaceTransclusion]);

  useEffect(() => {
    if (!editor) return;
    editor.setEditable(editable && !pendingTransclusion);
  }, [editor, editable, pendingTransclusion]);

  useEffect(() => {
    if (!editor) return;
    if (text !== lastTextRef.current) {
      isRemoteUpdate.current = true;
      editor.commands.setContent(flatTextToHtml(text), { emitUpdate: false });
      lastTextRef.current = text;
      setTimeout(() => {
        isRemoteUpdate.current = false;
      }, 50);
    }
  }, [text, editor]);

  if (!editor) {
    return <div className="tiptap-loading">Loading editor…</div>;
  }

  return (
    <div
      className="tiptap-container"
      onClick={pendingTransclusion ? handleEditorClick : undefined}
      style={{ cursor: pendingTransclusion ? "crosshair" : "default" }}
    >
      <div className="tiptap-status">
        <span className={`sync-indicator ${connected ? "sync-connected" : "sync-disconnected"}`}>
          {connected ? "Synced" : "Offline"}
        </span>
        {pendingTransclusion && (
          <span style={{ fontSize: 12, color: "#f59e0b", fontWeight: 600 }}>
            Click to place transclusion
          </span>
        )}
      </div>
      <EditorContent editor={editor} />
    </div>
  );
}
