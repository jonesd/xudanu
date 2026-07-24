import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import Placeholder from "@tiptap/extension-placeholder";
import TextAlign from "@tiptap/extension-text-align";
import FontFamily from "@tiptap/extension-font-family";
import { TextStyle } from "@tiptap/extension-text-style";
import Image from "@tiptap/extension-image";
import { TextSelection } from "@tiptap/pm/state";
import { useEffect, useRef, useCallback } from "react";
import type { AnnotationEntry } from "../api/crdt_sync";
import { FontSize } from "../tiptap-extensions/font-size";
import {
  textToTipTapDoc,
  tiptapDocToText,
  diffAnnotations,
} from "../tiptap-bridge";

interface TipTapEditorProps {
  text: string;
  workId?: number;
  onTextChange?: (text: string) => void;
  onCursorChange?: (index: number | null) => void;
  onSelectionChange?: (start: number | null, end: number | null) => void;
  editable: boolean;
  annotations?: AnnotationEntry[];
  onCreateAnnotation?: (kind: string, payload: string, start: number, end: number) => void;
  onDeleteAnnotation?: (annotationId: number) => void;
  onToggleStyle?: (kind: string, start: number, end: number) => void;
  onImageUpload?: (file: File) => Promise<string | null>;
  fontSize?: number;
  lineHeight?: number;
}

export function TipTapEditor({
  text,
  workId,
  onTextChange,
  onCursorChange,
  onSelectionChange,
  editable,
  annotations,
  onCreateAnnotation,
  onDeleteAnnotation,
  onToggleStyle,
  onImageUpload,
  fontSize,
  lineHeight,
}: TipTapEditorProps) {
  const lastTextRef = useRef(text);
  const lastMarksKey = useRef("");
  const isApplyingRemote = useRef(false);
  const recentlyEdited = useRef(false);
  const editTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const handleStyleToggleRef = useRef<((kind: string) => void) | null>(null);
  const onImageUploadRef = useRef<((file: File) => Promise<string | null>) | null>(null);
  const editorRef = useRef<ReturnType<typeof useEditor>>(null);
  onImageUploadRef.current = onImageUpload ?? null;
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
      FontSize,
      FontFamily,
      Image.configure({
        inline: true,
        allowBase64: true,
      }),
      TextAlign.configure({
        types: ["heading", "paragraph"],
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
      handleDrop: (view, event) => {
        const files = event.dataTransfer?.files;
        if (!files || files.length === 0) return false;
        const imgFile = Array.from(files).find((f) => f.type.startsWith("image/"));
        if (!imgFile) return false;
        event.preventDefault();
        const dropPos = view.posAtCoords({ left: event.clientX, top: event.clientY })?.pos;
        if (dropPos === undefined) return true;
        if (onImageUploadRef.current) {
          void onImageUploadRef.current(imgFile).then((src) => {
            if (src && editorRef.current) {
              editorRef.current.chain().focus().setImage({ src }).atPosition(dropPos).run();
            }
          });
        }
        return true;
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
        if (event.key === "Enter" && !event.shiftKey) {
          const { state, dispatch } = _view;
          const { $from } = state.selection;
          if ($from.parent.type.name === "paragraph" && $from.pos === $from.end()) {
            let hasImage = false;
            $from.parent.forEach((child) => { if (child.type.name === "image") hasImage = true; });
            if (hasImage) {
              const tr = state.tr;
              tr.insert($from.after(), state.schema.nodes.paragraph.create());
              tr.setSelection(TextSelection.near(tr.doc.resolve($from.after() + 1)));
              dispatch(tr);
              _view.scrollIntoView();
              return true;
            }
          }
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
  editorRef.current = editor;

  const loadedWorkId = useRef<number | null>(null);

  useEffect(() => {
    if (!editor) return;
    editor.setEditable(editable);
  }, [editor, editable]);

  // Load doc when work changes AND text has arrived from CRDT.
  useEffect(() => {
    if (!editor) return;
    const wid = workId ?? undefined;
    if (loadedWorkId.current === wid) return; // already loaded this work
    if (text.length === 0 && wid !== undefined) return; // wait for CRDT to deliver text
    loadedWorkId.current = wid ?? null;
    const doc = textToTipTapDoc(text, annotations ?? []);
    lastTextRef.current = text;
    isApplyingRemote.current = true;
    editor.commands.setContent(doc);
    isApplyingRemote.current = false;
  }, [editor, text, workId, annotations]);

  useEffect(() => {
    return () => editor?.destroy();
  }, [editor]);

  return (
    <div className="tiptap-editor-wrap">
      {editor && <TipTapToolbar editor={editor} onImageUpload={onImageUpload} />}
      <EditorContent editor={editor} />
    </div>
  );
}

function TipTapToolbar({ editor, onImageUpload }: { editor: ReturnType<typeof useEditor>; onImageUpload?: (file: File) => Promise<string | null> }) {
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
      <span className="tiptap-toolbar-sep" />
      <select
        className="tiptap-toolbar-select"
        value={currentFontSize(editor)}
        onChange={(e) => {
          const px = parseInt(e.target.value, 10);
          if (px > 0) editor.chain().focus().setMark("textStyle", { fontSize: `${px}px` }).run();
          else editor.chain().focus().unsetMark("textStyle").run();
        }}
        onMouseDown={(e) => e.stopPropagation()}
        title="Font size"
      >
        <option value="0">Size</option>
        {[12, 13, 14, 15, 16, 18, 20, 24, 28, 32].map((px) => (
          <option key={px} value={px}>{px}px</option>
        ))}
      </select>
      <select
        className="tiptap-toolbar-select"
        value={currentFontFamily(editor)}
        onChange={(e) => {
          if (e.target.value) editor.chain().focus().setFontFamily(e.target.value).run();
          else editor.chain().focus().unsetFontFamily().run();
        }}
        onMouseDown={(e) => e.stopPropagation()}
        title="Font family"
      >
        <option value="">Font</option>
        <option value="Source Serif 4, Georgia, serif">Serif</option>
        <option value="Inter, sans-serif">Sans</option>
        <option value="JetBrains Mono, monospace">Mono</option>
      </select>
      <span className="tiptap-toolbar-sep" />
      {(["left", "center", "right"] as const).map((align) => (
        <button
          key={align}
          className={`tiptap-toolbar-btn ${editor.isActive({ textAlign: align }) ? "active" : ""}`}
          onMouseDown={(e) => e.preventDefault()}
          onClick={() => editor.chain().focus().setTextAlign(align).run()}
          title={`Align ${align}`}
        >
          {align === "left" ? "⬅" : align === "center" ? "↔" : "➡"}
        </button>
      ))}
      {onImageUpload && (
        <label className="tiptap-toolbar-btn" title="Insert image">
          {"📷"}
          <input
            type="file"
            accept="image/png,image/jpeg,image/gif,image/webp,image/bmp"
            style={{ display: "none" }}
            onChange={async (e) => {
              const f = e.target.files?.[0];
              if (f) {
                const src = await onImageUpload(f);
                if (src) editor.chain().focus().setImage({ src }).run();
              }
              e.target.value = "";
            }}
          />
        </label>
      )}
    </div>
  );
}

function currentFontSize(editor: ReturnType<typeof useEditor>): string {
  if (!editor) return "0";
  const attrs = editor.getAttributes("textStyle");
  const fs = attrs?.fontSize as string | undefined;
  if (!fs) return "0";
  return fs.replace("px", "");
}

function currentFontFamily(editor: ReturnType<typeof useEditor>): string {
  if (!editor) return "";
  return (editor.getAttributes("textStyle")?.fontFamily as string) || "";
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
