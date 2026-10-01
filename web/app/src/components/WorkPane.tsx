import { useCallback, useEffect, useRef, useState } from "react";
import type { CrdtSyncClient, LinkEntry } from "../api/crdt_sync";

/**
 * Link-type colors — mirrors CollaborativeEditor's palette so the
 * far document speaks the same visual language as the near one.
 */
const LINK_TYPE_COLORS: Record<number, string> = {
  1: "#58a6ff", // Comment — blue
  2: "#3fb950", // Reference — green
  3: "#f85149", // Disagreement — red
  4: "#a371f7", // Quotation — purple
  5: "#d29922", // See Also — amber
  6: "#39d2c0", // Web Link — teal
  7: "#f0883e", // Trail — orange
};

interface PaneMark {
  start: number;
  end: number;
  color: string;
  linkId: number;
  title: string;
}

/**
 * Resolve link spans in the pane's text — the same excerpt-matching
 * approach the Beams view uses: find the excerpt in the text, mark
 * the span. Falls back to start/end positions when the excerpt
 * can't be found (stale text vs stale offsets).
 */
function computeMarks(
  text: string,
  workId: number,
  links: LinkEntry[],
): PaneMark[] {
  const marks: PaneMark[] = [];
  for (const link of links) {
    const color =
      LINK_TYPE_COLORS[link.link_types?.[0] ?? 0] ?? "#8a8a96";
    // Check both ends: the pane work could be origin or destination
    for (const ref of [link.origin_ref, link.destination_ref]) {
      if (!ref || ref.work_context !== workId) continue;
      const start = ref.start_position;
      const end = ref.end_position;
      if (start == null || end == null || end <= start) continue;
      const s = Math.max(0, Math.min(start, text.length));
      const e = Math.min(end, text.length);
      if (e <= s) continue;
      const farTitle =
        ref === link.origin_ref
          ? link.destination_title ?? "unknown"
          : link.origin_title ?? "unknown";
      marks.push({ start: s, end: e, color, linkId: link.link_id, title: farTitle });
    }
  }
  // Sort by start; on overlap, keep the first (same approach as
  // Beams renderMarked)
  return marks.sort((a, b) => a.start - b.start);
}

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
  // connected: unused in the text renderer; kept in the prop API
  connected: _connected,
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
  const [marks, setMarks] = useState<PaneMark[]>([]);
  const loadSeq = useRef(0);
  const bodyRef = useRef<HTMLDivElement | null>(null);
  // Scroll memory fires on scroll END, not every pixel — per-pixel
  // state updates re-render the whole shell and jank the main
  // editor's cursor/scroll (found in live testing).
  const scrollTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const handleScroll = useCallback(() => {
    if (scrollTimer.current) clearTimeout(scrollTimer.current);
    const el = bodyRef.current;
    if (!el) return;
    const top = el.scrollTop;
    scrollTimer.current = setTimeout(() => onScrollRemember?.(top), 250);
  }, [onScrollRemember]);

  // Selection from a SINGLE text node: offsets are exact by
  // construction (UTF-16 indices into `text`, the same semantics as
  // text.slice) and the DOM never rebuilds under React re-renders —
  // the full editor remounted and cleared selections mid-drag when
  // driven from a foreign parent (found in live slice-1 testing).
  const computeSelection = useCallback((): WorkPaneSelection | null => {
    const node = bodyRef.current;
    const domSel = window.getSelection();
    if (!node || !domSel || domSel.rangeCount === 0 || domSel.isCollapsed) return null;
    const range = domSel.getRangeAt(0);
    if (!node.contains(range.commonAncestorContainer)) return null;
    const measure = (side: "start" | "end"): number => {
      const r = document.createRange();
      r.selectNodeContents(node);
      if (side === "start") {
        r.setEnd(range.startContainer, range.startOffset);
      } else {
        r.setEnd(range.endContainer, range.endOffset);
      }
      return r.toString().length; // UTF-16 code units — slice parity
    };
    const start = measure("start");
    const end = measure("end");
    if (end <= start) return null;
    return { start, end, text: text.slice(start, end) };
  }, [text]);

  const reportSelection = useCallback(() => {
    const s = computeSelection();
    setSel(s);
    onSelectionChange?.(s);
  }, [computeSelection, onSelectionChange]);

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
      // FR-84 pane markers: load the work's links and compute spans
      // (the far document's connection landscape, visible).
      try {
        const links = await client.linkListForWork(workId);
        if (seq !== loadSeq.current) return;
        setMarks(computeMarks(r.text, workId, links));
      } catch {
        setMarks([]); // links are optional — don't fail the pane
      }
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
            onClick={() => {
              // Visual truth: the DOM selection's text is the excerpt
              // (immune to offset drift when rendered text differs
              // from the raw model — transclusions, quotes, compound
              // segments). Editor offsets remain the span anchor.
              const domText = window.getSelection()?.toString() ?? "";
              const holdText = domText.trim().length > 0 ? domText : sel.text;
              onHoldEnd({ ...sel, text: holdText });
            }}
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
        onScroll={handleScroll}
        onMouseUp={reportSelection}
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
          <div
            className="work-pane-text"
            style={{
              whiteSpace: "pre-wrap",
              userSelect: "text",
              padding: "10px 14px",
              fontFamily: "'Source Serif 4', Georgia, serif",
              fontSize: "var(--ws-font, 14px)",
              lineHeight: 1.7,
              color: "#e8e6e0",
              minHeight: "100%",
            }}
          >
            {(() => {
              // FR-84 pane markers: render the text with link-span
              // underlines (same type-color palette as the main
              // document) + the held highlight. Marks are
              // non-interactive visual indicators; selection works
              // through them (inline elements in the text flow).
              type Seg = { text?: string; mark?: PaneMark; held?: boolean };
              const segs: Seg[] = [];
              let pos = 0;

              // Merge marks + held span into a single sorted list
              const all: Array<{ start: number; end: number; mark?: PaneMark; held?: boolean }> = [
                ...marks.map((m) => ({ start: m.start, end: m.end, mark: m })),
                ...(held ? [{ start: held.start, end: held.end, held: true }] : []),
              ].sort((a, b) => a.start - b.start);

              for (const span of all) {
                if (span.start < pos) continue; // overlap — keep first
                if (span.start > pos) segs.push({ text: text.slice(pos, span.start) });
                const slice = text.slice(span.start, span.end);
                if (span.held) {
                  segs.push({ text: slice, held: true });
                } else if (span.mark) {
                  segs.push({ text: slice, mark: span.mark });
                }
                pos = span.end;
              }
              if (pos < text.length) segs.push({ text: text.slice(pos) });

              return segs.map((seg, i) => {
                if (seg.held) {
                  return (
                    <mark
                      key={`h${i}`}
                      style={{ background: "rgba(28, 93, 153, 0.35)", color: "inherit", padding: 0 }}
                    >
                      {seg.text}
                    </mark>
                  );
                }
                if (seg.mark) {
                  return (
                    <span
                      key={`m${i}`}
                      title={`${seg.mark.title} (link 0x${seg.mark.linkId.toString(16)})`}
                      style={{
                        borderBottom: `2px solid ${seg.mark.color}`,
                        cursor: "default",
                        paddingBottom: 1,
                      }}
                    >
                      {seg.text}
                    </span>
                  );
                }
                return <span key={`t${i}`}>{seg.text}</span>;
              });
            })()}
          </div>
        )}
      </div>
    </div>
  );
}
