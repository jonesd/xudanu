import { useState, useEffect, useMemo, useRef, useCallback } from "react";
import type { CrdtSyncClient, WorkListEntry, SharedRegion } from "../api/crdt_sync";
import { highlightRegions } from "./ComparePanel";
import { diffTexts, renderDiffSideHtml } from "../text-diff";

const PAIR_COLORS = [
  "#d29922", "#56b4e9", "#009e73", "#cc79a7",
  "#f0e442", "#e69f00", "#0072b2", "#d55e00",
];

/** A drawn beam between two shared-passage highlights in adjacent
 *  columns (Nelson's transpointing-windows lines — finally literal).
 *  `cidx` is the shared-region group: same cidx = same carried text. */
interface Beam {
  cidx: number;
  x1: number;
  y1: number;
  x2: number;
  y2: number;
  color: string;
}


function highlightComplement(
  text: string,
  regions: { start: number; end: number }[],
): string {
  // "What differs" view — read it like a diff:
  //   green wash   = unique to THIS work (its own contribution)
  //   grey + strike = also present in the other work(s) — skip these
  // Background washes (not bars/shadows) so wrapped lines render
  // cleanly with no fragmentation artifacts.
  if (!regions.length) {
    return `<span class="cmp-unique">${text.replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c] ?? c))}</span>`;
  }
  const sorted = [...regions].sort((a, b) => a.start - b.start);
  const esc = (t: string) =>
    t.replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c] ?? c));
  let html = "";
  let pos = 0;
  for (const r of sorted) {
    if (r.end <= pos) continue;
    const start = Math.max(r.start, pos);
    if (start > pos) {
      html += `<span class="cmp-unique">${esc(text.slice(pos, start))}</span>`;
    }
    html += `<span class="cmp-shared">${esc(text.slice(start, r.end))}</span>`;
    pos = r.end;
  }
  if (pos < text.length) {
    html += `<span class="cmp-unique">${esc(text.slice(pos))}</span>`;
  }
  return html;
}

interface MultiEndCompareProps {
  workIds: number[];
  works: WorkListEntry[];
  clientRef: React.MutableRefObject<CrdtSyncClient | null>;
  currentWorkId: number | null;
  onPickWork: (id: number) => void;
  onClose: () => void;
  /** Full-window mode: roomier columns, no max-height, up to 4 works. */
  fullscreen?: boolean;
  onRemoveWork?: (id: number) => void;
  /** Embedded mode: open the fullscreen comparison overlay. */
  onExpand?: () => void;
}

interface Column {
  workId: number;
  title: string;
  text: string;
  regions: { start: number; end: number; cidx: number }[];
}

function pairKey(a: number, b: number): string {
  return a < b ? `${a}:${b}` : `${b}:${a}`;
}

/**
 * FR-40 Story 5: N-way comparison of a multi-ended link's ends.
 * Loads each end work's text, computes pairwise shared regions via
 * the server's find_shared_regions, and highlights every passage
 * shared with any other end — the pairwise color encodes *which*
 * other work it is shared with. The transpointing-windows payoff.
 */
export function MultiEndCompare({
  workIds,
  works,
  clientRef,
  currentWorkId,
  onPickWork,
  onClose,
  fullscreen = false,
  onRemoveWork,
  onExpand,
}: MultiEndCompareProps) {
  const [columns, setColumns] = useState<Column[]>([]);
  const [pairLabels, setPairLabels] = useState<Map<string, string>>(new Map());
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [addWorkId, setAddWorkId] = useState<number | "">("");
  const [viewMode, setViewMode] = useState<"auto" | "diff" | "shared" | "unique">("auto");
  const [focusCidx, setFocusCidx] = useState<number | null>(null);

  // Pairwise aligned diff (Myers over words) — the mode that reads
  // like a code compare when the texts are versions of one thing.
  const pairDiff = useMemo(
    () => (columns.length === 2 ? diffTexts(columns[0].text, columns[1].text) : null),
    [columns],
  );
  const autoMode: "diff" | "shared" = pairDiff && pairDiff.matchRatio >= 0.3 ? "diff" : "shared";
  const effMode = viewMode === "auto" ? autoMode : viewMode;

  // ── Beams (transpointing windows, literally) ──────────────────────
  // Drawn connections between shared-passage highlights in adjacent
  // columns; same cidx = same carried text. Hover a beam (or a
  // passage) to focus it — the rest dims. Beams track scrolling:
  // connections follow content, per the 1972 sketch.
  const gridRef = useRef<HTMLDivElement | null>(null);
  const [beams, setBeams] = useState<Beam[]>([]);
  const recomputeBeams = useCallback(() => {
    const grid = gridRef.current;
    if (!grid) { setBeams([]); return; }
    const grect = grid.getBoundingClientRect();
    const colEls = Array.from(grid.children).filter(
      (el) => el instanceof HTMLElement && (el as HTMLElement).dataset.col != null,
    ) as HTMLElement[];
    const out: Beam[] = [];
    for (let ci = 0; ci + 1 < colEls.length; ci++) {
      const aSpans = colEls[ci].querySelectorAll(".compare-hl[data-cidx]");
      const bByCidx = new Map<string, HTMLElement>();
      colEls[ci + 1].querySelectorAll(".compare-hl[data-cidx]").forEach((s) => {
        const k = s.getAttribute("data-cidx") ?? "";
        if (!bByCidx.has(k)) bByCidx.set(k, s as HTMLElement);
      });
      aSpans.forEach((asEl) => {
        const k = asEl.getAttribute("data-cidx") ?? "";
        const bsEl = bByCidx.get(k);
        if (!bsEl) return;
        const ra = asEl.getBoundingClientRect();
        const rb = bsEl.getBoundingClientRect();
        const cidx = Number(k);
        out.push({
          cidx,
          x1: ra.right - grect.left + 1,
          y1: ra.top + ra.height / 2 - grect.top,
          x2: rb.left - grect.left - 1,
          y2: rb.top + rb.height / 2 - grect.top,
          color: PAIR_COLORS[cidx % PAIR_COLORS.length],
        });
      });
    }
    setBeams(out);
  }, []);
  useEffect(() => {
    if (effMode !== "shared" || columns.length < 2) { setBeams([]); return; }
    let raf = 0;
    const schedule = () => { cancelAnimationFrame(raf); raf = requestAnimationFrame(recomputeBeams); };
    schedule();
    // Scroll events don't bubble but DO capture — one capture listener
    // on the grid catches every column's internal scrolling.
    const grid = gridRef.current;
    grid?.addEventListener("scroll", schedule, { capture: true, passive: true });
    const ro = new ResizeObserver(schedule);
    if (grid) ro.observe(grid);
    return () => {
      cancelAnimationFrame(raf);
      grid?.removeEventListener("scroll", schedule, { capture: true } as EventListenerOptions);
      ro.disconnect();
    };
  }, [effMode, columns, recomputeBeams, fullscreen]);
  // Delegated hover on passage highlights: the beams answer.
  const onGridMouseOver = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    const t = e.target as HTMLElement;
    const hl = t.closest?.(".compare-hl[data-cidx]") as HTMLElement | null;
    if (hl) setFocusCidx(Number(hl.getAttribute("data-cidx")));
  }, []);
  const onGridMouseOut = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    const t = e.target as HTMLElement;
    if (t.closest?.(".compare-hl[data-cidx]")) setFocusCidx(null);
  }, []);

  const uniqueIds = useMemo(() => {
    const seen = new Set<number>();
    const ids: number[] = [];
    for (const id of workIds) {
      if (!seen.has(id)) {
        seen.add(id);
        ids.push(id);
      }
    }
    return ids;
  }, [workIds]);

  useEffect(() => {
    let cancelled = false;
    const client = clientRef.current;
    if (!client || uniqueIds.length < 2) {
      setColumns([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    (async () => {
      try {
        const texts = new Map<number, string>();
        for (const id of uniqueIds) {
          if (cancelled) return;
          const resp = await client.sendRequest("work_get_edition", { work_id: id });
          // sendRequest resolves with frame.value = {type:"edition", value:{text}}
          // so text is at resp.value.text — TWO levels total.
          const val = (resp as { value?: { text?: string } })?.value;
          const text: string = val?.text ?? "";
          texts.set(id, text);
        }
        const regionsByWork = new Map<number, { start: number; end: number; cidx: number }[]>();
        const labels = new Map<string, string>();
        let colorIdx = 0;
        const addRegion = (id: number, start: number, end: number, cidx: number) => {
          const r = regionsByWork.get(id) ?? [];
          r.push({ start, end, cidx });
          regionsByWork.set(id, r);
        };

        // FR-37 K3: n-way pass first — one shared_crum_regions request
        // instead of O(n^2) pairwise diffs; each region carries exact
        // spans for every member work.
        let nwayOk = false;
        try {
          const resp = await client.sendRequest("shared_crum_regions", { work_ids: uniqueIds });
          const val = resp && typeof resp === "object" && "value" in (resp as Record<string, unknown>)
            ? (resp as Record<string, unknown>).value : resp;
          const regions = (val as { regions?: Array<{ works: number[]; spans: Array<[number, number]> }> })?.regions;
          if (Array.isArray(regions)) {
            nwayOk = true;
            for (const region of regions) {
              const cidx = colorIdx % PAIR_COLORS.length;
              colorIdx++;
              const memberTitles = region.works
                .map((id) => works.find((w) => w.work_id === id)?.title || `0x${id.toString(16)}`)
                .join(" · ");
              labels.set(
                region.works.join(":"),
                `${memberTitles} (${region.works.length}-way)`,
              );
              region.works.forEach((id, k) => {
                const [s, e] = region.spans[k] ?? [0, 0];
                if (e > s) addRegion(id, s, e, cidx);
              });
            }
          }
        } catch {
          // older server or op unavailable — fall through to pairwise
        }

        if (!nwayOk) {
          for (let i = 0; i < uniqueIds.length && !cancelled; i++) {
            for (let j = i + 1; j < uniqueIds.length && !cancelled; j++) {
              const a = uniqueIds[i];
              const b = uniqueIds[j];
              let shared: SharedRegion[] = [];
              try {
                shared = await client.findSharedRegions(a, b);
              } catch {
                continue;
              }
              if (shared.length === 0) continue;
              const cidx = colorIdx % PAIR_COLORS.length;
              colorIdx++;
              const wa = works.find((w) => w.work_id === a);
              const wb = works.find((w) => w.work_id === b);
              labels.set(pairKey(a, b), `${wa?.title || `0x${a.toString(16)}`} ⇄ ${wb?.title || `0x${b.toString(16)}`} (${shared.length})`);
              for (const s of shared) {
                addRegion(a, s.start_a, s.end_a, cidx);
                addRegion(b, s.start_b, s.end_b, cidx);
              }
            }
          }
        }
        if (cancelled) return;
        const cols: Column[] = uniqueIds.map((id) => ({
          workId: id,
          title: works.find((w) => w.work_id === id)?.title || `Work 0x${id.toString(16)}`,
          text: texts.get(id) ?? "",
          regions: (regionsByWork.get(id) ?? []).sort((x, y) => x.start - y.start),
        }));
        setColumns(cols);
        setPairLabels(labels);
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : "comparison failed");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [uniqueIds, clientRef, works]);

  // Recent first, starred pinned — the same priority the Library list
  // uses. The server's work_list order is HashMap order (arbitrary);
  // an unsorted picker buried recently-used works under hundreds of
  // older ones.
  const otherWorks = works
    .filter((w) => !uniqueIds.includes(w.work_id) && w.work_id !== currentWorkId)
    .sort((a, b) => {
      if ((!!a.is_starred) !== (!!b.is_starred)) return a.is_starred ? -1 : 1;
      return (b.updated_at || 0) - (a.updated_at || 0);
    });

  const maxCols = fullscreen ? 4 : 3;
  return (
    <div className={fullscreen ? "mc-fullscreen" : "ws-connections-tab"}>
      <div className="ws-conn-section">
        <div className="ws-conn-header" style={{ display: "flex", justifyContent: "space-between" }}>
          <span>Compare ({uniqueIds.length})</span>
          <span>
            {!fullscreen && onExpand && (
              <button
                type="button"
                className="ws-link-filter-btn"
                style={{ fontSize: 10, padding: "1px 8px", marginRight: 6 }}
                title="Open the full-window comparison — roomier columns for larger works"
                onClick={onExpand}
              >
                ⤢ expand
              </button>
            )}
            <button className="ws-conn-delete" title={fullscreen ? "Close comparison" : "Back to connections"} onClick={onClose}>×</button>
          </span>
        </div>
        {uniqueIds.length < 2 && (
          <div className="ws-conn-empty">
            {otherWorks.length > 0
              ? "Select a multi-ended link in Connections and click ⇄ to compare its ends, or pick works below."
              : "Comparison needs at least one other document. Create a second document first (＋ New document), or open Connections on a multi-ended link and click ⇄ — then the ends load here automatically."}
          </div>
        )}
        {loading && <div className="ws-conn-empty">Comparing…</div>}
        {error && <div className="ws-conn-empty" style={{ color: "#f85149" }}>{error}</div>}
        {!loading && pairLabels.size > 0 && (
          <div style={{ fontSize: 11, color: "#8b949e", marginBottom: 6 }}>
            {[...pairLabels.entries()].map(([key, label], i) => (
              <span key={key} style={{ marginRight: 10 }}>
                <span
                  style={{
                    display: "inline-block",
                    width: 10,
                    height: 10,
                    borderRadius: 2,
                    background: PAIR_COLORS[i % PAIR_COLORS.length],
                    marginRight: 4,
                  }}
                />
                {label}
              </span>
            ))}
          </div>
        )}
        {!loading && columns.length >= 2 && (
          (() => {
            const anyShared = columns.some((c) => c.regions.length > 0);
            const totalShared = columns.reduce((n, c) => n + c.regions.length, 0);
            // Meaningfulness: phrase-level matches (common words, short
            // runs) inflate the count while carrying no information.
            // A comparison is SUBSTANTIAL only when some shared run is
            // long enough to be real carried content; otherwise say so
            // plainly instead of presenting noise as findings.
            const SUBSTANTIAL = 40;
            const longestRun = columns.reduce(
              (m, c) => Math.max(m, ...c.regions.map((r) => r.end - r.start), 0),
              0,
            );
            return (
              <div
                style={{
                  fontSize: 12,
                  padding: "6px 10px",
                  marginBottom: 8,
                  borderRadius: 6,
                  background: longestRun >= SUBSTANTIAL ? "rgba(88,166,255,0.07)" : anyShared ? "rgba(210,153,34,0.07)" : "rgba(139,148,158,0.08)",
                  border: `1px solid ${longestRun >= SUBSTANTIAL ? "rgba(88,166,255,0.35)" : anyShared ? "rgba(210,153,34,0.4)" : "#30363d"}`,
                  color: "#c9d1d9",
                }}
              >
                {longestRun >= SUBSTANTIAL
                  ? `${columns.length} works compared · ${Math.round(totalShared / columns.length)} shared passage${Math.round(totalShared / columns.length) === 1 ? "" : "s"} on average · longest shared run ${longestRun} characters — switch between “Shared passages” and “What differs” above`
                  : anyShared
                  ? `${columns.length} works compared · only scattered word matches (longest is ${longestRun} characters). These works share no substantial passages — there is nothing meaningful to learn from this comparison.`
                  : `${columns.length} works compared · they share no passages — these are independent texts. Every word is unique to its own work.`}
              </div>
            );
          })()
        )}
        {!loading && columns.length >= 2 && (
          <div style={{ display: "flex", gap: 4, marginBottom: 8 }}>
            {([
              ...(pairDiff ? ([["diff", `Aligned diff (${Math.round(pairDiff.matchRatio * 100)}%)`]] as const) : []),
              ["shared", "Shared passages"],
              ["unique", "What differs"],
            ] as const).map(([m, label]) => (
              <button
                key={m}
                type="button"
                className={`ws-link-filter-btn ${effMode === m ? "active" : ""}`}
                style={{
                  fontSize: 11,
                  padding: "2px 10px",
                  background: effMode === m ? "#58a6ff" : "transparent",
                  color: effMode === m ? "#fff" : "#8b949e",
                  borderColor: effMode === m ? "#58a6ff" : "#30363d",
                }}
                onClick={() => setViewMode(m as "diff" | "shared" | "unique")}
              >
                {label}
              </button>
            ))}
            <span style={{ fontSize: 11, color: "#8b949e", marginLeft: 8, alignSelf: "center" }}>
              {effMode === "diff"
                ? "aligned word-by-word — red = only left · green = only right · collapsed grey = matched"
                : effMode === "shared"
                ? "coloured highlight = this passage also appears in the work with that colour"
                : "green = only in this work · grey struck-out = also in the other work(s)"}
            </span>
          </div>
        )}
        {!loading && columns.length >= 2 && (
          <div
            ref={gridRef}
            className={focusCidx != null ? "mc-beam-focus" : undefined}
            onMouseOver={onGridMouseOver}
            onMouseOut={onGridMouseOut}
            style={{
              position: "relative",
              display: "grid",
              gridTemplateColumns: `repeat(${Math.min(columns.length, maxCols)}, 1fr)`,
              gap: 8,
              flex: fullscreen ? 1 : undefined,
              minHeight: fullscreen ? 0 : undefined,
            }}
          >
            {focusCidx != null && (
              <style>{`.mc-beam-focus .compare-hl:not([data-cidx="${focusCidx}"]) { opacity: 0.35; }`}</style>
            )}
            {effMode === "shared" && beams.length > 0 && (
              <svg
                style={{ position: "absolute", inset: 0, width: "100%", height: "100%", pointerEvents: "none", zIndex: 5, overflow: "visible" }}
                aria-hidden="true"
              >
                {beams.map((b, i) => {
                  const dx = Math.max(18, (b.x2 - b.x1) / 2);
                  const d = `M ${b.x1} ${b.y1} C ${b.x1 + dx} ${b.y1}, ${b.x2 - dx} ${b.y2}, ${b.x2} ${b.y2}`;
                  const focused = focusCidx === b.cidx;
                  const dimmed = focusCidx != null && !focused;
                  return (
                    <g key={i} style={{ pointerEvents: "visibleStroke", cursor: "pointer" }}
                      onMouseEnter={() => setFocusCidx(b.cidx)}
                      onMouseLeave={() => setFocusCidx(null)}
                    >
                      <path d={d} stroke="transparent" strokeWidth={12} fill="none" />
                      <path
                        d={d}
                        stroke={b.color}
                        strokeWidth={focused ? 2.5 : 1.75}
                        strokeOpacity={dimmed ? 0.15 : focused ? 1 : 0.7}
                        fill="none"
                        pointerEvents="none"
                      />
                    </g>
                  );
                })}
              </svg>
            )}
            {columns.map((col, colIndex) => (
              <div
                key={col.workId}
                data-col={colIndex}
                style={{
                  border: "1px solid #30363d",
                  borderRadius: 6,
                  padding: 8,
                  minHeight: 200,
                  maxHeight: fullscreen ? undefined : 420,
                  overflowY: "auto",
                  fontSize: fullscreen ? 14 : 12,
                  lineHeight: 1.6,
                  display: fullscreen ? "flex" : undefined,
                  flexDirection: fullscreen ? "column" : undefined,
                }}
              >
                <div style={{ fontWeight: 600, marginBottom: 4, fontSize: fullscreen ? 13 : 11, color: "#8b949e", display: "flex", justifyContent: "space-between" }}>
                  <span>
                    {col.title}
                    {col.regions.length === 0 && (
                      <span style={{ color: "#484f58", marginLeft: 6 }}>(no shared passages)</span>
                    )}
                  </span>
                  {fullscreen && onRemoveWork && (
                    <button
                      type="button"
                      className="ws-conn-delete"
                      title="Remove from comparison"
                      onClick={() => onRemoveWork(col.workId)}
                    >×</button>
                  )}
                </div>
                {(() => {
                  const sharedChars = col.regions.reduce((n, r) => n + Math.max(0, r.end - r.start), 0);
                  const total = Math.max(1, col.text.length);
                  const pctShared = Math.round((sharedChars / total) * 100);
                  return (
                    <div style={{ fontSize: 10, color: "#8b949e", marginBottom: 6 }}>
                      {sharedChars === 0
                        ? "nothing shared with the others"
                        : `${pctShared}% also in the other work(s) · ${100 - pctShared}% only here (${col.regions.length} shared passage${col.regions.length === 1 ? "" : "s"})`}
                    </div>
                  );
                })()}
                <div
                  className="compare-hl"
                  style={fullscreen ? { flex: 1, minHeight: 0 } : undefined}
                  dangerouslySetInnerHTML={{
                    __html: effMode === "diff" && pairDiff
                      ? renderDiffSideHtml(pairDiff, colIndex === 0 ? "a" : "b")
                      : effMode === "shared"
                      ? highlightRegions(col.text, col.regions, "compare-hl")
                      : highlightComplement(col.text, col.regions),
                  }}
                />
              </div>
            ))}
          </div>
        )}
        {!loading && (
          <div style={{ marginTop: 8, display: "flex", gap: 6, alignItems: "center" }}>
            <select
              className="ws-filter-select"
              value={addWorkId}
              disabled={otherWorks.length === 0}
              onChange={(e) => setAddWorkId(e.target.value === "" ? "" : Number(e.target.value))}
              style={{ flex: 1 }}
            >
              {otherWorks.length === 0 ? (
                <option value="">No other documents yet — create a second document to compare</option>
              ) : (
                <option value="">Add a work to the comparison…</option>
              )}
              {otherWorks.map((w) => (
                <option key={w.work_id} value={w.work_id}>
                  {w.title || "Untitled"}
                </option>
              ))}
            </select>
            <button
              type="button"
              className="ws-link-filter-btn"
              disabled={addWorkId === ""}
              onClick={() => {
                if (addWorkId !== "") {
                  onPickWork(Number(addWorkId));
                  setAddWorkId("");
                }
              }}
            >
              add
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
