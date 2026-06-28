import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import { useEffect, useRef, useCallback } from "react";
import type { PendingTransclusion } from "../hooks/useTransclusion";
import { TransclusionExtension } from "./tiptap-extensions/TransclusionExtension";
import type { SpanRangePayload } from "../api/crdt_sync";

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
  compoundSpanRanges?: SpanRangePayload[];
  compoundSourceTitles?: Record<number, string>;
  onNavigateToWork?: (workId: number) => void;
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
  compoundSpanRanges,
  compoundSourceTitles,
  onNavigateToWork: _onNavigateToWork,
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
      TransclusionExtension,
    ],
    content: flatTextToHtml(text),
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
    const fullText = editor.getText({ blockSeparator: "\n" });

    if (coords === null) {
      console.log("[tiptap-placement] below content, appending at end:", fullText.length);
      onPlaceTransclusion(fullText.length);
      return;
    }

    const pmPos = coords.pos;
    const flatPos = editor.state.doc.textBetween(0, pmPos, "\n").length;

    if (flatPos >= fullText.length) {
      const docSize = editor.state.doc.content.size;
      const lastLine = editor.view.coordsAtPos(docSize);
      if (e.clientY > lastLine.bottom + 4) {
        const lineHeight = parseFloat(getComputedStyle(editor.view.dom).lineHeight) || 20;
        const linesBelow = Math.max(1, Math.round((e.clientY - lastLine.bottom) / lineHeight));
        console.log("[tiptap-placement] below last line by", linesBelow, "lines, flatPos:", fullText.length);
        onPlaceTransclusion(fullText.length + linesBelow);
        return;
      }
    }

    console.log("[tiptap-placement] pmPos:", pmPos, "flatPos:", flatPos);
    onPlaceTransclusion(flatPos);
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

  useEffect(() => {
    if (!editor || !compoundSpanRanges) return;

    const existingNodes: Array<{ pos: number; sourceWorkId: number; charStart: number; charEnd: number }> = [];
    editor.state.doc.descendants((node: any, pos: number) => {
      if (node.type.name === "transclusion") {
        existingNodes.push({
          pos,
          sourceWorkId: node.attrs.sourceWorkId,
          charStart: node.attrs.charStart,
          charEnd: node.attrs.charEnd,
        });
      }
      return true;
    });

    const neededSet = new Set(
      compoundSpanRanges.map((s) => `${s.source_work_id}:${s.char_start}:${s.char_end}`),
    );
    const existingSet = new Set(
      existingNodes.map((n) => `${n.sourceWorkId}:${n.charStart}:${n.charEnd}`),
    );

    let tr = editor.state.tr;
    let changed = false;

    for (const node of existingNodes.sort((a, b) => b.pos - a.pos)) {
      const key = `${node.sourceWorkId}:${node.charStart}:${node.charEnd}`;
      if (!neededSet.has(key)) {
        const nodeAtPos = editor.state.doc.nodeAt(node.pos);
        if (nodeAtPos) {
          tr = tr.delete(node.pos, node.pos + nodeAtPos.nodeSize);
          changed = true;
        }
      }
    }

    const sorted = [...compoundSpanRanges].sort((a, b) => {
      const posA = a.otree_position ?? a.flat_start;
      const posB = b.otree_position ?? b.flat_start;
      return posB - posA;
    });

    for (const sr of sorted) {
      const key = `${sr.source_work_id}:${sr.char_start}:${sr.char_end}`;
      if (existingSet.has(key)) continue;

      const insertPos = Math.min(sr.otree_position ?? sr.flat_start, tr.doc.content.size);
      const title = compoundSourceTitles?.[sr.source_work_id] || "";
      const content = sr.resolved_content || "[transclusion]";

      tr = tr.insert(insertPos, editor.state.schema.nodes.transclusion.create({
        sourceWorkId: sr.source_work_id,
        charStart: sr.char_start,
        charEnd: sr.char_end,
        resolvedContent: content,
        sourceTitle: title,
      }));
      changed = true;
    }

    if (changed) {
      editor.view.dispatch(tr.setMeta("addToHistory", false));
    }
  }, [editor, compoundSpanRanges, compoundSourceTitles]);

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
