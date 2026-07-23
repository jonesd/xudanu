import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import Placeholder from "@tiptap/extension-placeholder";
import { useEffect, useRef, useCallback } from "react";
import type { AnnotationEntry } from "../api/crdt_sync";
import {
  textToTipTapDoc,
  tiptapDocToText,
  diffAnnotations,
  extractAllMarks,
} from "../tiptap-bridge";

interface TipTapEditorProps {
  text: string;
  onTextChange?: (text: string) => void;
  onCursorChange?: (index: number | null) => void;
  onSelectionChange?: (start: number | null, end: number | null) => void;
  editable: boolean;
  annotations?: AnnotationEntry[];
  onCreateAnnotation?: (kind: string, payload: string, start: number, end: number) => void;
  onDeleteAnnotation?: (annotationId: number) => void;
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
  onCreateAnnotation,
  onDeleteAnnotation,
  onToggleStyle,
  fontSize,
  lineHeight,
}: TipTapEditorProps) {
  const lastTextRef = useRef(text);
  const lastMarksKey = useRef("");
  const isApplyingRemote = useRef(false);
  const recentlyEdited = useRef(false);
  const editTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const handleStyleToggleRef = useRef<((kind: string) => void) | null>(null);
  const annotationsRef = useRef(annotations || []);
  annotationsRef.current = annotations || [];

  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: { levels: [1, 2, 3] },
        codeBlock: { HTMLAttributes: { class: "tiptap-code-block" } },
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
      if (isApplyingRemote.current) return;

      recentlyEdited.current = true;
      if (editTimer.current) clearTimeout(editTimer.current);
      editTimer.current = setTimeout(() => { recentlyEdited.current = false; }, 600);

      const { text: newText, marks } = tiptapDocToText(editor.getJSON() as never);
      lastTextRef.current = newText;
      onTextChange?.(newText);

      const marksKey = marks.map((m) => `${m.kind}:${m.start}:${m.end}`).join("|");
      if (marksKey !== lastMarksKey.current) {
        lastMarksKey.current = marksKey;
        syncAnnotations(marks);
      }
    },
    onSelectionUpdate: ({ editor }) => {
      const { from, to } = editor.state.selection;
      if (from === to) {
        onCursorChange?.(from);
        onSelectionChange?.(null, null);
      } else {
        const { text: t } = tiptapDocToText(editor.getJSON() as never);
        onCursorChange?.(proseMirrorPosToCharPos(t, from));
        onSelectionChange?.(proseMirrorPosToCharPos(t, from), proseMirrorPosToCharPos(t, to));
      }
    },
  });

  const syncAnnotations = useCallback(
    (desiredMarks: Array<{ kind: string; start: number; end: number; payload?: string }>) => {
      if (!onCreateAnnotation && !onDeleteAnnotation) return;
      const { toCreate, toDelete } = diffAnnotations(annotationsRef.current, desiredMarks);
      for (const m of toCreate) {
        onCreateAnnotation?.(m.kind, m.payload || "", m.start, m.end);
      }
      for (const a of toDelete) {
        onDeleteAnnotation?.(a.annotation_id);
      }
    },
    [onCreateAnnotation, onDeleteAnnotation],
  );

  const handleStyleToggle = useCallback(
    (kind: string) => {
      if (!editor || !onToggleStyle) return;
      const { from, to } = editor.state.selection;
      if (from === to) return;
      const { text: t } = tiptapDocToText(editor.getJSON() as never);
      const charStart = proseMirrorPosToCharPos(t, from);
      const charEnd = proseMirrorPosToCharPos(t, to);
      onToggleStyle(kind, charStart, charEnd);
    },
    [editor, onToggleStyle],
  );
  handleStyleToggleRef.current = handleStyleToggle;

  const loadedWorkId = useRef<number | null>(null);

  useEffect(() => {
    if (!editor) return;
    editor.setEditable(editable);
  }, [editor, editable]);

  // Rebuild doc from text + annotations ONLY on initial load or work change.
  // After that, TipTap manages its own state. Remote text changes trigger the
  // text effect below. Annotation echoes from our own sync are ignored.
  useEffect(() => {
    if (!editor) return;
    if (loadedWorkId.current === null) {
      loadedWorkId.current = -1;
      const doc = textToTipTapDoc(text, annotations ?? []);
      lastTextRef.current = text;
      lastMarksKey.current = extractAllMarks(annotations ?? [])
        .map((m) => `${m.kind}:${m.start}:${m.end}`).join("|");
      isApplyingRemote.current = true;
      editor.commands.setContent(doc);
      isApplyingRemote.current = false;
    }
  }, [editor, text, annotations]);

  // Remote text change: rebuild doc (with latest annotations)
  useEffect(() => {
    if (!editor) return;
    if (text === lastTextRef.current) return;
    if (recentlyEdited.current) return;
    lastTextRef.current = text;
    const doc = textToTipTapDoc(text, annotations ?? []);
    lastMarksKey.current = extractAllMarks(annotations ?? [])
      .map((m) => `${m.kind}:${m.start}:${m.end}`).join("|");
    isApplyingRemote.current = true;
    const sel = editor.state.selection;
    editor.commands.setContent(doc);
    try {
      editor.commands.setTextSelection({ from: sel.from, to: sel.to });
    } catch {}
    isApplyingRemote.current = false;
  }, [editor, text, annotations]);

  useEffect(() => {
    return () => editor?.destroy();
  }, [editor]);

  return (
    <div className="tiptap-editor-wrap">
      {editor && <TipTapToolbar editor={editor} />}
      <EditorContent editor={editor} />
    </div>
  );
}

function TipTapToolbar({ editor }: { editor: ReturnType<typeof useEditor> }) {
  if (!editor) return null;

  const blockTypes = [
    { label: "P", action: () => editor.chain().focus().setParagraph().run(), active: editor.isActive("paragraph") },
    { label: "H1", action: () => editor.chain().focus().setHeading({ level: 1 }).run(), active: editor.isActive("heading", { level: 1 }) },
    { label: "H2", action: () => editor.chain().focus().setHeading({ level: 2 }).run(), active: editor.isActive("heading", { level: 2 }) },
    { label: "H3", action: () => editor.chain().focus().setHeading({ level: 3 }).run(), active: editor.isActive("heading", { level: 3 }) },
    { label: "• List", action: () => editor.chain().focus().toggleBulletList().run(), active: editor.isActive("bulletList") },
    { label: "1. List", action: () => editor.chain().focus().toggleOrderedList().run(), active: editor.isActive("orderedList") },
    { label: "❝", action: () => editor.chain().focus().toggleBlockquote().run(), active: editor.isActive("blockquote") },
    { label: "< / >", action: () => editor.chain().focus().toggleCodeBlock().run(), active: editor.isActive("codeBlock") },
  ];

  return (
    <div className="tiptap-toolbar">
      {blockTypes.map((bt, i) => (
        <button
          key={i}
          className={`tiptap-toolbar-btn ${bt.active ? "active" : ""}`}
          onMouseDown={(e) => e.preventDefault()}
          onClick={bt.action}
        >
          {bt.label}
        </button>
      ))}
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
