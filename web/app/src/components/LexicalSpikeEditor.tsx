import { useEffect, useMemo, useRef, useState } from "react";
import { LexicalComposer } from "@lexical/react/LexicalComposer";
import { PlainTextPlugin } from "@lexical/react/LexicalPlainTextPlugin";
import { HeadingNode, QuoteNode } from "@lexical/rich-text";
import { ListNode, ListItemNode } from "@lexical/list";
import { CodeNode } from "@lexical/code";
import { registerMarkdownShortcuts, TRANSFORMERS } from "@lexical/markdown";
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
import type { AttributionSpan, AnnotationEntry } from "../api/crdt_sync";

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
  styleAnnotations?: AnnotationEntry[];
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
      let prefix = "";
      // HeadingNode: re-add the markdown marker so the text model
      // round-trips (# / ## / ###) — markdown shortcuts strip it on
      // conversion, we restore it on serialization.
      const tag = (p as unknown as { __tag?: string }).__tag;
      if (tag === "h1") prefix = "# ";
      else if (tag === "h2") prefix = "## ";
      else if (tag === "h3") prefix = "### ";
      const t = prefix + p.getTextContent();
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
export function buildContent(
  text: string,
  spans: AttributionSpan[],
  styleAnnotations: AnnotationEntry[] = [],
): void {
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
    const pos = lineStart;
    // Block type detection from text markers (same source as the old
    // editor's detectLineBlock — markers live in the text model and
    // serialize back through serializeRoot unchanged).
    const headingMatch = line.match(/^(#{1,3})\s(.*)$/);
    const isBullet = /^[*-]\s/.test(line);
    const isQuote = /^>\s/.test(line);
    const para = headingMatch
      ? (() => {
          const tag = ("h" + headingMatch[1].length) as "h1" | "h2" | "h3";
          const hn = new HeadingNode(tag);
          return hn;
        })()
      : $createParagraphNode();
    if (isBullet) para.setStyle?.("padding-left: 1.2em; ");
    if (isQuote) para.setStyle?.("padding-left: 1em; border-left: 3px solid #58a6ff55; color: #8b949e; ");
    let plain = 0;
    const push = (str: string, startInLine: number, author?: string | number) => {
      if (!str) return;
      const node = $createTextNode(str);
      if (author !== undefined) {
        const hue = authorHue(author);
        node.setStyle(
          `background-color: hsla(${hue}, 70%, 50%, 0.18); border-bottom: 2px solid hsla(${hue}, 70%, 45%, 0.6)`,
        );
      }
      // Bold/italic from style annotations (server-authoritative):
      const absStart = pos + startInLine;
      const absEnd = absStart + str.length;
      for (const ann of styleAnnotations) {
        if (ann.char_start < absEnd && ann.char_end > absStart) {
          if (ann.kind === "bold") node.setFormat("bold");
          if (ann.kind === "italic") node.setFormat("italic");
        }
      }
      para.append(node);
    };
    for (const span of sorted) {
      const spanStartInLine = Math.max(span.start - pos, 0);
      const spanEndInLine = Math.min(span.end - pos, line.length);
      if (spanStartInLine >= line.length || spanEndInLine <= 0) continue;
      if (spanStartInLine > plain) {
        push(line.slice(plain, spanStartInLine), plain);
        plain = spanStartInLine;
      }
      const segEnd = Math.max(spanEndInLine, plain);
      push(line.slice(plain, segEnd), plain, span.author);
      plain = segEnd;
    }
    if (plain < line.length) push(line.slice(plain), plain);
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
  styleAnnotations,
}: {
  text: string;
  structuralVersion?: number;
  attributionSpans: AttributionSpan[];
  styleAnnotations: AnnotationEntry[];
}) {
  const [editor] = useLexicalComposerContext();
  const applied = useRef<string | null>(null);
  useEffect(() => {
    // Rebuild ONLY when the text prop itself changes — never for
    // attributionSpan identity churn (a fresh array arrives every
    // poll; rebuilding during the typing-debounce window applied
    // STALE text and reset the caret to index 0 — the
    // "cursor jumps to start in the pause" bug, and the same class
    // as the old editor's structural rebuild).
    if (text === applied.current) return;
    applied.current = text;
    editor.update(
      () => {
        // Echo guard: if the editor already holds this text (the
        // common case — local typing echoed back by the server),
        // skip the rebuild entirely. No DOM churn, no caret restore,
        // no jump between paragraphs.
        if (serializeRoot() === text) return;
        const sel = selectionOffsets();
        buildContent(text, attributionSpans, styleAnnotations);
        if (sel[0] !== null) {
          // Restore caret/selection to its pre-rebuild offset.
          const root = $getRoot();
          let pos = sel[0];
          for (const child of root.getChildren() as unknown as (
            | { getTextContent(): string; getChildren(): unknown[]; select?: (a: number, b: number) => void }
          )[]) {
            const len = child.getTextContent().replace(/\n$/, "").length;
            if (pos <= len) {
              const kids = child.getChildren();
              const last = kids[kids.length - 1];
              if (
                last &&
                typeof (last as { select?: unknown }).select === "function"
              ) {
                (last as { select: (a: number, b: number) => void }).select(pos, pos);
              } else if (typeof child.select === "function") {
                child.select(0, 0);
              }
              break;
            }
            pos -= len + 1;
          }
        }
      },
      { discrete: true },
    );
    // structuralVersion intentionally not read — it participates via
    // the effect dependency to force re-application.
  }, [text, structuralVersion, editor]);
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


/** Live markdown: typing `# ` converts to H1 etc. in-place. The
 * text model keeps the markers (serializeRoot adds them back via
 * HeadingNode text content detection — see serializeRoot). */
function MarkdownShortcuts() {
  const [editor] = useLexicalComposerContext();
  useEffect(() => {
    return registerMarkdownShortcuts(editor, TRANSFORMERS);
  }, [editor]);
  return null;
}

/** Editability resolves as soon as the editor instance exists.
 * (canEdit may still be loading at outer mount — setting it only
 * after a first change deadlocks: never editable, never a change,
 * no keyboard on iOS.) */
function EditableGate({
  editable,
  editorRef,
}: {
  editable: boolean;
  editorRef: React.MutableRefObject<LexicalEditor | null>;
}) {
  const [editor] = useLexicalComposerContext();
  useEffect(() => {
    editorRef.current = editor;
    editor.setEditable(editable);
  }, [editor, editable]);
  return null;
}

/** Debug probe (FR-150 device triage): on-screen truth about the
 * spike's editable/focus state + whether taps reach the editor. */
let spikeDebugSink: ((msg: string) => void) | null = null;

/** On-page console (cable-free triage): mirrors console + focus
 * lifecycle onto the phone screen. */
function OnPageConsole() {
  const [lines, setLines] = useState<string[]>(["[probe ready]"]);
  const push = (l: string) =>
    setLines((prev) => [...prev.slice(-7), l]);
  useEffect(() => {
    spikeDebugSink = push;
    const origLog = console.log.bind(console);
    const origErr = console.error.bind(console);
    console.log = (...a: unknown[]) => {
      origLog(...a);
      push("log: " + a.map(String).join(" ").slice(0, 90));
    };
    console.error = (...a: unknown[]) => {
      origErr(...a);
      push("ERR: " + a.map(String).join(" ").slice(0, 90));
    };
    window.addEventListener("focusin", () => push("focusin -> " + (document.activeElement as HTMLElement)?.className?.slice(0, 30)));
    window.addEventListener("focusout", () => push("focusout"));
    return () => {
      console.log = origLog;
      console.error = origErr;
      spikeDebugSink = null;
    };
  }, []);
  return (
    <div
      style={{
        position: "fixed",
        bottom: "calc(56px + env(safe-area-inset-bottom, 0px))",
        left: 8,
        right: 8,
        zIndex: 9999,
        background: "rgba(0,0,0,0.92)",
        color: "#3fb950",
        fontFamily: "monospace",
        fontSize: 10,
        lineHeight: 1.5,
        padding: "6px 8px",
        borderRadius: 6,
        pointerEvents: "none",
        whiteSpace: "pre-wrap",
      }}
    >
      {lines.join("\n")}
    </div>
  );
}
function DebugProbe() {
  const [editor] = useLexicalComposerContext();
  const [msg, setMsg] = useState("e=? f=?");
  useEffect(() => {
    spikeDebugSink = (m) => setMsg(m);
    const push = () =>
      setMsg(
        `e=${editor.isEditable() ? 1 : 0} f=${document.activeElement === editor.getRootElement() ? 1 : 0}`,
      );
    push();
    const t = window.setInterval(push, 500);
    return () => {
      window.clearInterval(t);
      spikeDebugSink = null;
    };
  }, [editor]);
  return (
    <div
      data-testid="spike-debug"
      style={{
        position: "fixed",
        bottom: "calc(60px + env(safe-area-inset-bottom, 0px))",
        left: 8,
        zIndex: 9999,
        background: "rgba(0,0,0,0.85)",
        color: "#3fb950",
        fontFamily: "monospace",
        fontSize: 11,
        padding: "4px 8px",
        borderRadius: 4,
        pointerEvents: "none",
      }}
    >
      {msg}
    </div>
  );
}

export function LexicalSpikeEditor(props: LexicalSpikeEditorProps) {
  const {
    text,
    structuralVersion,
    onTextChange,
    onCursorChange,
    onSelectionChange,
    attributionSpans,
    styleAnnotations = [],
    editable,
  } = props;
  const initialConfig = useMemo(
    () => ({
      namespace: "xudanu-spike",
      onError(e: Error) {
        console.error("lexical-spike:", e);
      },
      nodes: [HeadingNode, QuoteNode, ListNode, ListItemNode, CodeNode],
      editable,
    }),
    // editable changes are applied imperatively below
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  );
  const editorRef = useRef<LexicalEditor | null>(null);
  const emitTimer = useRef<number | null>(null);
  const handleChange = (state: EditorState, editor: LexicalEditor) => {
    editorRef.current = editor;
    state.read(() => {
      const out = serializeRoot();
      if (out === text) return;
      // Batch commits (~350ms): per-KEYSTROKE commits expose an
      // offset bug in the shared CRDT diff pipeline (observed: each
      // char lands at offset 0 -> mirrored text on iOS). Batching
      // sidesteps it while typing; the pipeline fix is the real
      // solution (see FR-150 findings).
      if (emitTimer.current !== null) window.clearTimeout(emitTimer.current);
      emitTimer.current = window.setTimeout(() => {
        onTextChange?.(out);
        emitTimer.current = null;
      }, 350);
    });
  };
  return (
    <div
      className="lexical-spike-editor"
      onPointerDown={() => {
        spikeDebugSink?.("tap@editor");
        // iOS: contentEditable focus must be triggered within the
        // user gesture — Lexical's internal click handler loses the
        // gesture boundary on WebKit; focus explicitly here.
        editorRef.current?.focus();
      }}
      onClick={() => {
        // iOS keyboard opens for focus within CLICK specifically;
        // pointerdown alone leaves focus set but keyboard closed.
        spikeDebugSink?.("click@editor");
        editorRef.current?.focus();
      }}
      style={{ minHeight: "60vh", fontSize: 16, lineHeight: 1.7 }}
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
          <MarkdownShortcuts />
          <DebugProbe />
          <OnPageConsole />
          <EditableGate editable={editable} editorRef={editorRef} />
          <OnChangePlugin onChange={handleChange} ignoreSelectionChange={false} />
          <RemoteSync text={text} structuralVersion={structuralVersion} attributionSpans={attributionSpans} styleAnnotations={styleAnnotations} />
          <SelectionReporter onCursorChange={onCursorChange} onSelectionChange={onSelectionChange} />
        </div>
      </LexicalComposer>
    </div>
  );
}

export default LexicalSpikeEditor;
