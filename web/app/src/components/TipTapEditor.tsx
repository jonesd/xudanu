import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import Placeholder from "@tiptap/extension-placeholder";
import { useEffect, useRef, useCallback } from "react";
import type { AnnotationEntry } from "../api/crdt_sync";
import { textToTipTapDoc, tiptapDocToText, extractMarkRanges } from "../tiptap-bridge";

interface TipTapEditorProps {
  text: string;
  onTextChange?: (text: string) => void;
  onCursorChange?: (index: number | null) => void;
  onSelectionChange?: (start: number | null, end: number | null) => void;
  editable: boolean;
  annotations?: AnnotationEntry[];
  onToggleStyle?: (kind: string, start: number, end: number) => void;
  fontSize?: number;
  lineHeight?: number;
}

export function TipTapEditor({
  text,
  onTextChange,
  onCursorChange,
  onSelectionChange,
  editable,
  annotations,
  onToggleStyle,
  fontSize,
  lineHeight,
}: TipTapEditorProps) {
  const lastTextRef = useRef(text);
  const isApplyingRemote = useRef(false);
  const skipNextUpdate = useRef(false);
  const handleStyleToggleRef = useRef<((kind: string) => void) | null>(null);

  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: false,
      }),
      Placeholder.configure({
        placeholder: "Start typing…",
      }),
    ],
    content: "<p></p>",
    editable,
    editorProps: {
      attributes: {
        class: "tiptap-editor-content",
        style: [
          fontSize ? `font-size: ${fontSize}px` : "",
          lineHeight ? `line-height: ${lineHeight}` : "",
        ].filter(Boolean).join("; "),
      },
      handleKeyDown: (_view, event) => {
        if ((event.ctrlKey || event.metaKey) && event.key === "b") {
          event.preventDefault();
          handleStyleToggleRef.current?.("bold");
          return true;
        }
        if ((event.ctrlKey || event.metaKey) && event.key === "i") {
          event.preventDefault();
          handleStyleToggleRef.current?.("italic");
          return true;
        }
        return false;
      },
    },
    onUpdate: ({ editor }) => {
      if (isApplyingRemote.current || skipNextUpdate.current) {
        skipNextUpdate.current = false;
        return;
      }
      const { text: newText } = tiptapDocToText(editor.getJSON() as never);
      lastTextRef.current = newText;
      onTextChange?.(newText);
    },
    onSelectionUpdate: ({ editor }) => {
      const { from, to } = editor.state.selection;
      if (from === to) {
        onCursorChange?.(from);
        onSelectionChange?.(null, null);
      } else {
        const { text } = tiptapDocToText(editor.getJSON() as never);
        const charPos = proseMirrorPosToCharPos(text, from);
        const charPosEnd = proseMirrorPosToCharPos(text, to);
        onCursorChange?.(charPos);
        onSelectionChange?.(charPos, charPosEnd);
      }
    },
  });

  const handleStyleToggle = useCallback(
    (kind: string) => {
      if (!editor || !onToggleStyle) return;
      const { from, to } = editor.state.selection;
      if (from === to) return;
      const { text } = tiptapDocToText(editor.getJSON() as never);
      const charStart = proseMirrorPosToCharPos(text, from);
      const charEnd = proseMirrorPosToCharPos(text, to);
      onToggleStyle(kind, charStart, charEnd);
    },
    [editor, onToggleStyle],
  );
  handleStyleToggleRef.current = handleStyleToggle;

  useEffect(() => {
    if (!editor) return;
    editor.setEditable(editable);
  }, [editor, editable]);

  const marksRef = useRef("");
  useEffect(() => {
    if (!editor || !annotations) return;
    const marks = extractMarkRanges(annotations);
    const marksKey = marks.map((m) => `${m.kind}:${m.start}:${m.end}`).join("|");
    if (marksKey === marksRef.current) return;
    marksRef.current = marksKey;

    const currentText = lastTextRef.current;
    const doc = textToTipTapDoc(currentText, annotations);
    isApplyingRemote.current = true;
    editor.commands.setContent(doc);
    isApplyingRemote.current = false;
  }, [editor, annotations]);

  useEffect(() => {
    if (!editor) return;
    if (text === lastTextRef.current) return;
    lastTextRef.current = text;
    const doc = textToTipTapDoc(text, annotations ?? []);
    isApplyingRemote.current = true;
    const sel = editor.state.selection;
    editor.commands.setContent(doc);
    try {
      editor.commands.setTextSelection({ from: sel.from, to: sel.to });
    } catch {}
    isApplyingRemote.current = false;
  }, [editor, text, annotations]);

  useEffect(() => {
    return () => {
      editor?.destroy();
    };
  }, [editor]);

  return (
    <div className="tiptap-editor-wrap">
      <EditorContent editor={editor} />
    </div>
  );
}

function proseMirrorPosToCharPos(text: string, pmPos: number): number {
  const lines = text.split("\n");
  let pos = 0;
  let remaining = pmPos;
  for (let i = 0; i < lines.length; i++) {
    if (remaining <= lines[i].length + 1) {
      return Math.min(pos + Math.max(0, remaining - 1), text.length);
    }
    pos += lines[i].length + 1;
    remaining -= lines[i].length + 1;
  }
  return text.length;
}
