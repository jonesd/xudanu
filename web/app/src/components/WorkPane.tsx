import { useCallback, useEffect, useRef, useState } from "react";
import { CollaborativeEditor } from "./CollaborativeEditor";
import type { CrdtSyncClient } from "../api/crdt_sync";

/**
 * FR-84 split authoring: a self-contained work pane.
 *
 * Domain-agnostic by design — usable in the workspace split view,
 * connection-preview popovers, the compound builder's sources, and
 * future surfaces (FR-79 overlay authoring). No workspace-shell
 * imports; everything arrives via props.
 *
 * Slice 1 ships the read-select mode: a snapshot of the work's text
 * (fetchWorkText — deliberately NOT the CRDT stream, which is
 * coupled to the single "open" work) rendered by the standard editor
 * with selection live and editing off. Holding the far end of a
 * connection against stable, visible content is the point.
 *
 * Props:
 * - client: shared CrdtClient (reads only)
 * - workId: the work to show
 * - onClose: header ✕
 * - onSelectionChange: live selection in pane coordinates
 * - onHoldEnd: user pressed "Hold as end" with an active selection
 * - held: highlight a currently-held span (visual feedback)
 * - compact: tighten chrome (for popovers/previews)
 */

export interface WorkPaneSelection {
  start: number;
  end: number;
  text: string;
}

interface WorkPaneProps {
  client: CrdtSyncClient | null;
  workId: number;
  connected: boolean;
  onClose?: () => void;
  onSelectionChange?: (sel: WorkPaneSelection | null) => void;
  onHoldEnd?: (sel: WorkPaneSelection) => void;
  /** FR-84 promotion: take the editing focus onto this pane's work
   * (the CRDT engine edits one buffer — promotion swaps which). */
  onPromote?: () => void;
  held?: { start: number; end: number } | null;
  compact?: boolean;
  /** FR-84 long-doc positioning: restore this offset after load. */
  initialScrollTop?: number;
  /** FR-84: report scroll position for pane-memory (throttle at the
   * caller if needed; panes are few). */
  onScrollRemember?: (scrollTop: number) => void;
}

export function WorkPane({
  client,
  workId,
  connected,
  onClose,
  onSelectionChange,
  onHoldEnd,
  onPromote,
  held,
  compact,
  initialScrollTop,
  onScrollRemember,
}: WorkPaneProps) {
  const [text, setText] = useState<string>("");
  const [title, setTitle] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [sel, setSel] = useState<WorkPaneSelection | null>(null);
  const [revision, setRevision] = useState(0);
  const loadSeq = useRef(0);
  const bodyRef = useRef<HTMLDivElement | null>(null);

  const load = useCallback(async () => {
    if (!client) return;
    const seq = ++loadSeq.current;
    setLoading(true);
    setError(null);
    try {
      const r = await client.fetchWorkText(workId);
      if (seq !== loadSeq.current) return; // superseded
      setText(r.text);
      setTitle(r.title || `Work 0x${workId.toString(16)}`);
      setRevision(r.revision);
      setSel(null);
    } catch (e) {
      if (seq !== loadSeq.current) return;
      setError(String(e));
    } finally {
      if (seq === loadSeq.current) setLoading(false);
    }
  }, [client, workId]);

  useEffect(() => {
    void load();
  }, [load]);

  // Restore remembered position after the text lands (long-doc
  // positioning: a reopened pane returns to where you left it).
  useEffect(() => {
    if (!loading && !error && bodyRef.current && initialScrollTop) {
      bodyRef.current.scrollTop = initialScrollTop;
    }
  }, [loading, error, initialScrollTop, workId]);

  const handleSelection = useCallback(
    (start: number | null, end: number | null) => {
      if (start == null || end == null || start === end) {
        setSel(null);
        onSelectionChange?.(null);
        return;
      }
      const s = Math.min(start, end);
      const e = Math.max(start, end);
      const selection: WorkPaneSelection = {
        start: s,
        end: e,
        text: text.slice(s, e),
      };
      setSel(selection);
      onSelectionChange?.(selection);
    },
    [text, onSelectionChange],
  );

  return (
    <div
      className="work-pane"
      style={{
        display: "flex",
        flexDirection: "column",
        minWidth: 0,
        height: "100%",
        borderLeft: compact ? "1px solid #21262d" : undefined,
        background: "#0d1117",
      }}
    >
      <div
        className="work-pane-header"
        style={{
          display: "flex",
          alignItems: "center",
          gap: 8,
          padding: compact ? "4px 8px" : "6px 10px",
          borderBottom: "1px solid #21262d",
          fontSize: "var(--ws-font, 14px)",
          color: "#8b949e",
          flexWrap: "wrap",
        }}
      >
        <span
          className="work-pane-title"
          title={title}
          style={{
            fontWeight: 600,
            color: "#e8e6e0",
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap",
            maxWidth: compact ? 160 : 260,
          }}
        >
          {title}
        </span>
        <code style={{ fontSize: 10 }}>0x{workId.toString(16)}</code>
        {revision > 0 && <span style={{ fontSize: 10 }}>· v{revision}</span>}
        <span style={{ flex: 1 }} />
        {sel && onHoldEnd && (
          <button
            type="button"
            onClick={() => onHoldEnd(sel)}
            style={{
              fontSize: "calc(var(--ws-font, 14px) - 1px)",
              padding: "2px 8px",
              borderRadius: 6,
              border: "1px solid #1c5d99",
              background: "#12233a",
              color: "#9ecbff",
              cursor: "pointer",
            }}
            title="Hold this selection as one end of a connection"
          >
            Hold as end
          </button>
        )}
        {onPromote && (
          <button
            type="button"
            onClick={onPromote}
            title="Edit here — this work takes the editing focus (the previous document stays pinned as a pane)"
            style={{
              fontSize: "calc(var(--ws-font, 14px) - 1px)",
              padding: "2px 8px",
              borderRadius: 6,
              border: "1px solid #238636",
              background: "#12261a",
              color: "#7ee787",
              cursor: "pointer",
            }}
          >
            Edit here
          </button>
        )}
        <button
          type="button"
          onClick={() => void load()}
          disabled={loading}
          title="Refresh snapshot"
          style={{
            fontSize: "calc(var(--ws-font, 14px) - 1px)",
            padding: "2px 6px",
            borderRadius: 6,
            border: "1px solid #30363d",
            background: "transparent",
            color: "#8b949e",
            cursor: "pointer",
          }}
        >
          ⟳
        </button>
        {onClose && (
          <button
            type="button"
            onClick={onClose}
            title="Close pane"
            style={{
              fontSize: "var(--ws-font, 14px)",
              padding: "2px 6px",
              borderRadius: 6,
              border: "1px solid #30363d",
              background: "transparent",
              color: "#8b949e",
              cursor: "pointer",
            }}
          >
            ✕
          </button>
        )}
      </div>

      <div
        className="work-pane-body"
        ref={bodyRef}
        onScroll={(e) => onScrollRemember?.((e.target as HTMLDivElement).scrollTop)}
        style={{ flex: 1, minHeight: 0, overflow: "auto", position: "relative" }}
      >
        {loading && (
          <div style={{ padding: 16, color: "#8b949e", fontSize: 12 }}>Loading…</div>
        )}
        {error && (
          <div style={{ padding: 16, color: "#f85149", fontSize: 12 }}>
            {error}
            <button type="button" onClick={() => void load()} style={{ marginLeft: 8 }}>
              retry
            </button>
          </div>
        )}
        {!loading && !error && (
          <CollaborativeEditor
            text={text}
            workId={workId}
            editable={false}
            connected={connected}
            attributionSpans={[]}
            onCursorChange={() => {}}
            onSelectionChange={handleSelection}
            highlightRange={held ?? undefined}
          />
        )}
      </div>
    </div>
  );
}
