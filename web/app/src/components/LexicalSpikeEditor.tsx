import { useEffect, useMemo, useRef } from "react";
import { LexicalComposer } from "@lexical/react/LexicalComposer";
import { PlainTextPlugin } from "@lexical/react/LexicalPlainTextPlugin";
import { ContentEditable } from "@lexical/react/LexicalContentEditable";
import { HistoryPlugin } from "@lexical/react/LexicalHistoryPlugin";
import { OnChangePlugin } from "@lexical/react/LexicalOnChangePlugin";
import { useLexicalComposerContext } from "@lexical/react/LexicalComposerContext";
import {
  $createParagraphNode,
  $createTextNode,
  $getRoot,
  $getSelection,
  $isParagraphNode,
  $isTextNode,
  type EditorState,
  type LexicalEditor,
  type LexicalNode,
  type Point,
} from "lexical";
import type { AttributionSpan } from "../api/crdt_sync";

/**
 * FR-150: Lexical authoring-surface spike. Plain text only; the
 * contract mirrors the core of CollaborativeEditorProps so the
 * WorkspaceShell can swap it behind a feature flag. The plain-text
 * model is paragraphs joined by "\n" — the same convention as
 * $getRoot().getTextContent(), and the offset arithmetic in
 * pointToRootOffset/selectionOffsets is the CRDT adapter's
 * position currency (model offsets, never DOM offsets).
 */

export interface LexicalSpikeEditorProps {
  text: string;
  /** Structural ops (link create, transclusion insert) bump this —
   * forces a rebuild from the model text, same contract as the
   * contentEditable editor's structuralVersion. */
  structuralVersion?: number;
  workId?: number;
  onTextChange?: (text: string) => void;
  onCursorChange: (index: number | null) => void;
  onSelectionChange: (start: number | null, end: number | null) => void;
  connected: boolean;
  attributionSpans: AttributionSpan[];
  editable: boolean;
}

/** Canonical plain-text serialization: paragraphs joined by single
 * "\n" (Lexical's own getTextContent double-counts paragraph breaks
 * — paragraph contributes a trailing \n AND root joins with \n — so
 * every consumer in this spike uses THIS function instead). */
export function serializeRoot(): string {
  const root = $getRoot();
  return root
    .getChildren()
    .map((p) => {
      const t = p.getTextContent();
      return t.endsWith("\n") ? t.slice(0, -1) : t;
    })
    .join("\n");
}

function paragraphLength(p: LexicalNode): number {
  const t = p.getTextContent();
  return (t.endsWith("\n") ? t.slice(0, -1) : t).length;
}

/** Offset of a top-level paragraph within the joined plain text. */
function paragraphBase(para: LexicalNode): number {
  const root = $getRoot();
  let base = 0;
  for (const child of root.getChildren()) {
    if (child === para) return base;
    base += paragraphLength(child) + 1;
  }
  return 0;
}

/** Map a Lexical selection point to a plain-text (model) offset. */
export function pointToRootOffset(point: Point): number | null {
  const node = point.getNode();
  if ($isParagraphNode(node)) {
    // Caret at a paragraph boundary (empty paragraph or element
    // selection): offset counts children — treat as text start.
    return paragraphBase(node);
  }
  if ($isTextNode(node)) {
    let inPara = 0;
    for (const child of node.getParentOrThrow().getChildren()) {
      if (child === node) {
        const para = node.getParentOrThrow();
        return paragraphBase(para) + inPara + point.offset;
      }
      inPara += child.getTextContent().length;
    }
  }
  return null;
}

/** Current selection as (start, end) plain-text offsets, or nulls. */
export function selectionOffsets(): [number | null, number | null] {
  const sel = $getSelection();
  if (!sel) return [null, null];
  const rangeSel = sel as unknown as { anchor?: Point; focus?: Point };
  if (!rangeSel.anchor || !rangeSel.focus) return [null, null];
  const a = pointToRootOffset(rangeSel.anchor);
  const b = pointToRootOffset(rangeSel.focus);
  if (a === null || b === null) return [null, null];
  return a <= b ? [a, b] : [b, a];
}

/** Author palette: stable hue from the author id — mirrors the
 * paired-colour scheme's intent (spike uses single hue per author). */
function authorHue(author: string | number | undefined): number {
  const s = String(author ?? "anon");
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 360;
  return h;
}

/** Rebuild the document from model text, splitting TextNodes at
 * attribution-span boundaries so each run carries its author color. */
export function buildContent(text: string, spans: AttributionSpan[]): void {
  const root = $getRoot();
  root.clear();
  const lines = text.split("\n");
  const sorted = [...spans]
    .map((s) => ({
      start: Math.max(0, s.start | 0),
      end: Math.max(0, s.end | 0),
      author: s.author_club_id ?? s.author_display_name ?? "anon",
    }))
    .filter((s) => s.end > s.start)
    .sort((a, b) => a.start - b.start);
  let cursor = 0;
  const flushLine = (line: string, lineStart: number) => {
    const para = $createParagraphNode();
    const pos = lineStart;
    let plain = 0;
    const push = (str: string, author?: string | number) => {
      if (!str) return;
      const node = $createTextNode(str);
      if (author !== undefined) {
        const hue = authorHue(author);
        node.setStyle(
          `background-color: hsla(${hue}, 70%, 50%, 0.18); border-bottom: 2px solid hsla(${hue}, 70%, 45%, 0.6)`,
        );
      }
      para.append(node);
    };
    for (const span of sorted) {
      const spanStartInLine = Math.max(span.start - pos, 0);
      const spanEndInLine = Math.min(span.end - pos, line.length);
      if (spanStartInLine >= line.length || spanEndInLine <= 0) continue;
      if (spanStartInLine > plain) {
        push(line.slice(plain, spanStartInLine));
        plain = spanStartInLine;
      }
      const segEnd = Math.max(spanEndInLine, plain);
      push(line.slice(plain, segEnd), span.author);
      plain = segEnd;
    }
    if (plain < line.length) push(line.slice(plain));
    root.append(para);
    void cursor;
  };
  let offset = 0;
  for (const line of lines) {
    flushLine(line, offset);
    offset += line.length + 1;
  }
  if (lines.length === 0) root.append($createParagraphNode());
  cursor = offset;
}

/** Applies remote/structural text into the editor when the model
 * text differs from the editor's own content. Local edits flow the
 * other way (onChange → onTextChange), so this is a no-op right
 * after local emission. */
function RemoteSync({
  text,
  structuralVersion,
  attributionSpans,
}: {
  text: string;
  structuralVersion?: number;
  attributionSpans: AttributionSpan[];
}) {
  const [editor] = useLexicalComposerContext();
  const applied = useRef<string | null>(null);
  useEffect(() => {
    editor.update(
      () => {
        const cur = serializeRoot();
        if (cur === text && applied.current === text) return;
        applied.current = text;
        const sel = selectionOffsets();
        buildContent(text, attributionSpans);
        return;
        void sel;
      },
      { discrete: true },
    );
    // structuralVersion intentionally not read — it participates via
    // the effect dependency to force re-application.
  }, [text, structuralVersion, attributionSpans, editor]);
  return null;
}

/** Emits cursor/selection as plain-text offsets on every update. */
function SelectionReporter({
  onCursorChange,
  onSelectionChange,
}: {
  onCursorChange: (i: number | null) => void;
  onSelectionChange: (s: number | null, e: number | null) => void;
}) {
  const [editor] = useLexicalComposerContext();
  useEffect(() => {
    return editor.registerUpdateListener(({ editorState }) => {
      editorState.read(() => {
        const [s, e] = selectionOffsets();
        onCursorChange(s);
        onSelectionChange(s, e);
      });
    });
  }, [editor, onCursorChange, onSelectionChange]);
  return null;
}

export function LexicalSpikeEditor(props: LexicalSpikeEditorProps) {
  const {
    text,
    structuralVersion,
    onTextChange,
    onCursorChange,
    onSelectionChange,
    attributionSpans,
    editable,
  } = props;
  const initialConfig = useMemo(
    () => ({
      namespace: "xudanu-spike",
      onError(e: Error) {
        console.error("lexical-spike:", e);
      },
      editable,
    }),
    // editable changes are applied imperatively below
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  );
  const editorRef = useRef<LexicalEditor | null>(null);
  useEffect(() => {
    if (editorRef.current) editorRef.current.setEditable(editable);
  }, [editable]);
  const handleChange = (state: EditorState, editor: LexicalEditor) => {
    editorRef.current = editor;
    state.read(() => {
      const out = serializeRoot();
      if (out !== text) onTextChange?.(out);
    });
  };
  return (
    <div
      className="lexical-spike-editor"
      style={{ minHeight: "60vh", fontSize: 15, lineHeight: 1.7 }}
      data-testid="lexical-spike"
    >
      <LexicalComposer initialConfig={initialConfig}>
        <div className="editor-inner" style={{ outline: "none" }}>
          <PlainTextPlugin
            contentEditable={<ContentEditable className="editor-input" style={{ outline: "none", whiteSpace: "pre-wrap" }} />}
            placeholder={null}
            ErrorBoundary={() => <div role="alert">editor error</div>}
          />
          <HistoryPlugin />
          <OnChangePlugin onChange={handleChange} ignoreSelectionChange={false} />
          <RemoteSync text={text} structuralVersion={structuralVersion} attributionSpans={attributionSpans} />
          <SelectionReporter onCursorChange={onCursorChange} onSelectionChange={onSelectionChange} />
        </div>
      </LexicalComposer>
    </div>
  );
}

export default LexicalSpikeEditor;
