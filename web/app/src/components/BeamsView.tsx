import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import type { LinkEntry } from "../api/crdt_sync";
import { linkEnds } from "../link-ends";
import { DEFAULT_LINK_TYPES } from "../hooks/useTransclusion";
// FR-85: argument structure — dispute status and chain context.
import {
  disputeStatus,
  type ArgumentChain,
} from "../argument-structure";

interface SyncClient {
  sendRequest: (op: string, params: Record<string, unknown>) => Promise<unknown>;
}

export interface BeamsViewProps {
  client: SyncClient | null;
  currentWorkId: number;
  works: Array<{ work_id: number; title?: string }>;
  links: LinkEntry[];
  onClose: () => void;
}

interface Column {
  workId: number;
  title: string;
  text: string;
  loading: boolean;
  error: string | null;
}

interface Mark {
  start: number;
  end: number;
  linkId: number;
  color: string;
}

interface Beam {
  key: string;
  x1: number;
  y1: number;
  x2: number;
  y2: number;
  color: string;
  linkId: number;
}

function extractText(resp: unknown): string {
  const val =
    resp && typeof resp === "object" && "value" in (resp as Record<string, unknown>)
      ? (resp as Record<string, unknown>).value
      : resp;
  if (typeof val === "string") return val;
  if (val && typeof val === "object") {
    const o = val as Record<string, unknown>;
    return (o.Text as string) || (o.text as string) || "";
  }
  return "";
}

/** Locate an excerpt in a text; -1 when not found. */
function findExcerpt(text: string, excerpt: string): number {
  const e = excerpt.trim();
  if (!e) return -1;
  return text.indexOf(e);
}

export function BeamsView({ client, currentWorkId, works, links, onClose }: BeamsViewProps) {
  const [columns, setColumns] = useState<Column[]>([]);
  const [selectedLink, setSelectedLink] = useState<number | null>(null);
  const [beams, setBeams] = useState<Beam[]>([]);
  const containerRef = useRef<HTMLDivElement>(null);
  const markEls = useRef(new Map<string, HTMLElement>()); // `${workId}:${linkId}` → <mark>

  const titleFor = useCallback(
    (workId: number): string => {
      const w = works.find((x) => x.work_id === workId);
      return w?.title?.trim() || `Work 0x${workId.toString(16)}`;
    },
    [works],
  );

  const fetchColumn = useCallback(
    async (workId: number): Promise<Column> => {
      const base = { workId, title: titleFor(workId), text: "", loading: true, error: null } as Column;
      if (!client) return { ...base, loading: false, error: "Not connected" };
      try {
        const resp = await client.sendRequest("work_get_edition", { work_id: workId });
        return { ...base, text: extractText(resp), loading: false };
      } catch (e) {
        return { ...base, loading: false, error: e instanceof Error ? e.message : String(e) };
      }
    },
    [client, titleFor],
  );

  // Which other works do this document's links touch? (candidates)
  const candidates = useMemo(() => {
    const ids = new Set<number>();
    for (const l of links) {
      for (const end of linkEnds(l)) {
        if (end.workId != null && end.workId !== currentWorkId) ids.add(end.workId);
      }
    }
    return [...ids];
  }, [links, currentWorkId]);

  // Initial columns: current work + first linked work (if any).
  useEffect(() => {
    let cancelled = false;
    (async () => {
      const first = [await fetchColumn(currentWorkId)];
      if (candidates.length > 0) first.push(await fetchColumn(candidates[0]));
      if (!cancelled) setColumns(first);
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentWorkId]);

  const addColumn = useCallback(
    (workId: number) => {
      setColumns((cols) => {
        if (cols.some((c) => c.workId === workId) || cols.length >= 4) return cols;
        void fetchColumn(workId).then((col) => {
          setColumns((prev) => (prev.some((c) => c.workId === workId) ? prev : [...prev, col]));
        });
        return [...cols, { workId, title: titleFor(workId), text: "", loading: true, error: null }];
      });
    },
    [fetchColumn, titleFor],
  );

  const removeColumn = useCallback((workId: number) => {
    setColumns((cols) => cols.filter((c) => c.workId !== workId));
  }, []);

  // Marks per column: link ends whose excerpt appears in that column's text.
  const marksByColumn = useMemo(() => {
    const map = new Map<number, Mark[]>();
    for (const col of columns) map.set(col.workId, []);
    for (const l of links) {
      const color =
        DEFAULT_LINK_TYPES.find((t) => t.type_id === (l.link_types?.[0] ?? 0))?.color || "#8a8a96";
      for (const end of linkEnds(l)) {
        if (end.workId == null) continue;
        const col = columns.find((c) => c.workId === end.workId);
        if (!col || !col.text) continue;
        const idx = findExcerpt(col.text, end.excerpt ?? "");
        if (idx < 0) continue;
        map.get(end.workId)?.push({ start: idx, end: idx + end.excerpt.trim().length, linkId: l.link_id, color });
      }
    }
    return map;
  }, [links, columns]);

  // Beam geometry: measure <mark> positions after paint; redraw on scroll/resize.
  const recompute = useCallback(() => {
    const container = containerRef.current;
    if (!container) return;
    const cRect = container.getBoundingClientRect();
    const next: Beam[] = [];
    for (const l of links) {
      const pts: Array<{ col: number; el: HTMLElement }> = [];
      for (const col of columns) {
        const el = markEls.current.get(`${col.workId}:${l.link_id}`);
        if (el) pts.push({ col: columns.indexOf(col), el });
      }
      const color =
        DEFAULT_LINK_TYPES.find((t) => t.type_id === (l.link_types?.[0] ?? 0))?.color || "#8a8a96";
      for (let i = 0; i + 1 < pts.length; i++) {
        const a = pts[i].el.getBoundingClientRect();
        const b = pts[i + 1].el.getBoundingClientRect();
        next.push({
          key: `${l.link_id}:${i}`,
          x1: a.right - cRect.left,
          y1: a.top + a.height / 2 - cRect.top,
          x2: b.left - cRect.left,
          y2: b.top + b.height / 2 - cRect.top,
          color,
          linkId: l.link_id,
        });
      }
    }
    setBeams(next);
  }, [links, columns]);

  useLayoutEffect(() => {
    recompute();
  }, [recompute, columns, marksByColumn]);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;
    container.addEventListener("scroll", recompute);
    window.addEventListener("resize", recompute);
    return () => {
      container.removeEventListener("scroll", recompute);
      window.removeEventListener("resize", recompute);
    };
  }, [recompute]);

  const typesPresent = useMemo(() => {
    const ids = new Set(links.flatMap((l) => l.link_types ?? []));
    return DEFAULT_LINK_TYPES.filter((t) => ids.has(t.type_id));
  }, [links]);

  // FR-85: dispute status per column work — computed from the
  // current link set (incoming Disagreements to that work).
  const disputeByColumn = useMemo(() => {
    const map = new Map<number, { status: string; count: number }>();
    for (const col of columns) {
      const { status, chains } = disputeStatus(col.workId, links);
      map.set(col.workId, { status, count: chains.length });
    }
    return map;
  }, [columns, links]);

  const selected = links.find((l) => l.link_id === selectedLink) ?? null;

  // FR-85: argument chain context for the selected link.
  const selectedChain: ArgumentChain | null = useMemo(() => {
    if (!selected) return null;
    const { chains } = disputeStatus(currentWorkId, links);
    // Is this link the root of a chain?
    const asRoot = chains.find((c) => c.root.link_id === selected.link_id);
    if (asRoot) return asRoot;
    // Or is it a response in someone else's chain?
    for (const chain of chains) {
      if (chain.responses.some((r) => r.link_id === selected.link_id)) return chain;
    }
    return null;
  }, [selected, currentWorkId, links]);

  const copyTumblers = useCallback(() => {
    if (!selected) return;
    const ends = linkEnds(selected)
      .map((e) => `work 0x${(e.workId ?? 0).toString(16)}${e.ref.start_position != null ? ` @${e.ref.start_position}-${e.ref.end_position}` : ""}`)
      .join("\n");
    void navigator.clipboard?.writeText(`link 0x${selected.link_id.toString(16)}\n${ends}`);
  }, [selected]);

  return (
    <div className="ws-beams" role="dialog" aria-label="Beams view">
      <div className="ws-beams-topbar">
        <span className="ws-beams-brand">Xuda<span className="ws-brand-nu">nu</span></span>
        <span className="ws-beams-crumb">
          Beams — <b>{columns.length} documents</b> · {links.length} links ·{" "}
          {links.reduce((n, l) => n + linkEnds(l).length, 0)} ends
        </span>
        <select
          className="ws-beams-add"
          value=""
          onChange={(e) => {
            const id = Number(e.target.value);
            if (id) addColumn(id);
            e.target.value = "";
          }}
          aria-label="Add document"
        >
          <option value="">＋ Add document…</option>
          {candidates
            .filter((id) => !columns.some((c) => c.workId === id))
            .map((id) => (
              <option key={id} value={id}>
                {titleFor(id)}
              </option>
            ))}
        </select>
        <button className="ws-beams-close" onClick={onClose}>
          ✕ Close
        </button>
      </div>

      {typesPresent.length > 0 && (
        <div className="ws-beams-legend">
          {typesPresent.map((t) => (
            <span key={t.type_id} className="ws-beams-legend-row">
              <i style={{ background: t.color }} />
              {t.name}
            </span>
          ))}
        </div>
      )}

      {selected && (
        <div className="ws-beams-card">
          <div className="ws-beams-card-h">
            <span className="ws-beams-card-dot" style={{ background: DEFAULT_LINK_TYPES.find((t) => t.type_id === (selected.link_types?.[0] ?? 0))?.color }} />
            Link 0x{selected.link_id.toString(16)} ·{" "}
            {(selected.link_types ?? []).map((tid) => DEFAULT_LINK_TYPES.find((t) => t.type_id === tid)?.name ?? `type ${tid}`).join(", ") ||
              "untyped"}
          </div>
          <p>
            {linkEnds(selected).length} ends. Anyone can create or extend links — no author
            coordination. Addresses are tumblers: ends survive every revision.
          </p>
          <div className="ws-beams-card-ends">
            {linkEnds(selected).map((e, i) => (
              <div key={i} className="ws-beams-card-end">
                <b>{e.workId != null ? titleFor(e.workId) : "cross-server"}</b>
                <span>“{(e.excerpt || "").slice(0, 90)}{e.excerpt.length > 90 ? "…" : ""}”</span>
              </div>
            ))}
          </div>
          <div>
            <button className="ws-beams-btn" onClick={copyTumblers}>Copy tumbler set</button>
            <button className="ws-beams-btn ghost" onClick={() => setSelectedLink(null)}>Dismiss</button>
          </div>
          {selectedChain && (
            <div className="ws-beams-chain" style={{ marginTop: 10, padding: "6px 8px", borderLeft: "2px solid #f85149", background: "rgba(248,81,73,0.05)", borderRadius: "0 4px 4px 0" }}>
              <div style={{ fontSize: 10, fontWeight: 600, color: "#f85149", textTransform: "uppercase", letterSpacing: 0.5 }}>
                Argument chain — {selectedChain.status} ({selectedChain.weight} endorsements)
              </div>
              <div style={{ fontSize: 11, color: "var(--text)", marginTop: 4 }}>
                ⚑ Disagreement from <b>{titleFor(selectedChain.root.origin)}</b>
              </div>
              {selectedChain.responses.map((r) => (
                <div key={r.link_id} style={{ fontSize: 11, color: "var(--text-dim)", paddingLeft: 14, marginTop: 2 }}>
                  ↳ Response from <b>{titleFor(r.origin)}</b>
                </div>
              ))}
              {selectedChain.responses.length === 0 && (
                <div style={{ fontSize: 10, color: "var(--amber)", paddingLeft: 14, marginTop: 2 }}>
                  awaiting response
                </div>
              )}
            </div>
          )}
        </div>
      )}

      <div className="ws-beams-stage" ref={containerRef}>
        <svg className="ws-beams-overlay">
          {beams.map((b) => (
            <g key={b.key} onClick={() => setSelectedLink(b.linkId)} style={{ cursor: "pointer" }}>
              <path
                className="ws-beams-hit"
                d={`M ${b.x1} ${b.y1} C ${(b.x1 + b.x2) / 2} ${b.y1}, ${(b.x1 + b.x2) / 2} ${b.y2}, ${b.x2} ${b.y2}`}
              />
              <path
                className="ws-beams-beam"
                style={{ stroke: b.color }}
                d={`M ${b.x1} ${b.y1} C ${(b.x1 + b.x2) / 2} ${b.y1}, ${(b.x1 + b.x2) / 2} ${b.y2}, ${b.x2} ${b.y2}`}
              />
            </g>
          ))}
        </svg>

        {columns.map((col) => {
          const dispute = disputeByColumn.get(col.workId);
          return (
          <div className="ws-beams-doc" key={col.workId}>
            <div className="ws-beams-doc-head">
              <h3>{col.title}</h3>
              {dispute && dispute.count > 0 && (
                <span
                  className="ws-beams-dispute"
                  style={{
                    fontSize: 10,
                    fontWeight: 700,
                    padding: "1px 6px",
                    borderRadius: 6,
                    marginLeft: 6,
                    background:
                      dispute.status === "disputed" ? "rgba(248,81,73,0.15)" : "rgba(63,185,80,0.12)",
                    color: dispute.status === "disputed" ? "#f85149" : "#3fb950",
                    border: `1px solid ${dispute.status === "disputed" ? "#f8514944" : "#3fb95044"}`,
                  }}
                  title={`${dispute.count} argument chain${dispute.count > 1 ? "s" : ""} — ${dispute.status}`}
                >
                  {dispute.status === "disputed" ? "⚑" : "✓"} {dispute.status}
                </span>
              )}
              {col.workId !== currentWorkId && (
                <button className="ws-beams-doc-x" onClick={() => removeColumn(col.workId)} aria-label="Remove">
                  ✕
                </button>
              )}
            </div>
            <div className="ws-beams-doc-body">
              {col.loading && <p className="ws-beams-meta">Loading…</p>}
              {col.error && <p className="ws-beams-meta">Could not load: {col.error}</p>}
              {!col.loading &&
                !col.error &&
                renderMarked(col.text, marksByColumn.get(col.workId) ?? [], col.workId, markEls, (lid) =>
                  setSelectedLink(lid),
                )}
              {!col.loading && !col.error && col.text.length === 0 && (
                <p className="ws-beams-meta">Empty document</p>
              )}
            </div>
          </div>
          );
        })}
      </div>
    </div>
  );
}

/** Render plain text as paragraphs with link-end <mark> highlights. */
function renderMarked(
  text: string,
  marks: Mark[],
  workId: number,
  markEls: React.MutableRefObject<Map<string, HTMLElement>>,
  onSelect: (linkId: number) => void,
) {
  if (marks.length === 0) {
    return text.split(/\n{2,}/).map((para, i) => <p key={i}>{para}</p>);
  }
  const sorted = [...marks].sort((a, b) => a.start - b.start);
  const out: React.ReactNode[] = [];
  let pos = 0;
  sorted.forEach((m, i) => {
    if (m.start < pos) return; // overlapping — keep first
    if (m.start > pos) out.push(<Plain key={`t${i}`} text={text.slice(pos, m.start)} />);
    const key = `${workId}:${m.linkId}`;
    out.push(
      <mark
        key={`m${i}`}
        className="ws-beams-mark"
        style={{ borderColor: m.color, background: `${m.color}33` }}
        ref={(el) => {
          if (el) markEls.current.set(key, el);
          else markEls.current.delete(key);
        }}
        onClick={() => onSelect(m.linkId)}
      >
        {text.slice(m.start, m.end)}
      </mark>,
    );
    pos = m.end;
  });
  if (pos < text.length) out.push(<Plain key="tail" text={text.slice(pos)} />);
  return out;
}

function Plain({ text }: { text: string }) {
  return (
    <>
      {text.split(/\n{2,}/).map((para, i) => (
        <p key={i}>{para}</p>
      ))}
    </>
  );
}
