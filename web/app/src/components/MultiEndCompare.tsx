import { useState, useEffect, useMemo } from "react";
import type { CrdtSyncClient, WorkListEntry, SharedRegion } from "../api/crdt_sync";
import { highlightRegions } from "./ComparePanel";

const PAIR_COLORS = [
  "#d29922", "#56b4e9", "#009e73", "#cc79a7",
  "#f0e442", "#e69f00", "#0072b2", "#d55e00",
];


function highlightComplement(
  text: string,
  regions: { start: number; end: number }[],
): string {
  // "What differs" view: shared passages are dimmed/struck; the
  // text UNIQUE to this work renders full-contrast. The difference
  // is what's NOT colored.
  if (!regions.length) {
    return `<span>${text.replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c] ?? c))}</span>`;
  }
  const sorted = [...regions].sort((a, b) => a.start - b.start);
  const esc = (t: string) =>
    t.replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c] ?? c));
  let html = "";
  let pos = 0;
  for (const r of sorted) {
    if (r.end <= pos) continue;
    const start = Math.max(r.start, pos);
    if (start > pos) html += esc(text.slice(pos, start));
    html += `<span style="opacity:0.35;background:rgba(139,148,158,0.15)">${esc(text.slice(start, r.end))}</span>`;
    pos = r.end;
  }
  if (pos < text.length) html += esc(text.slice(pos));
  return html;
}

interface MultiEndCompareProps {
  workIds: number[];
  works: WorkListEntry[];
  clientRef: React.MutableRefObject<CrdtSyncClient | null>;
  currentWorkId: number | null;
  onPickWork: (id: number) => void;
  onClose: () => void;
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
}: MultiEndCompareProps) {
  const [columns, setColumns] = useState<Column[]>([]);
  const [pairLabels, setPairLabels] = useState<Map<string, string>>(new Map());
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [addWorkId, setAddWorkId] = useState<number | "">("");
  const [viewMode, setViewMode] = useState<"shared" | "unique">("shared");

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
              const ra = regionsByWork.get(a) ?? [];
              ra.push({ start: s.start_a, end: s.end_a, cidx });
              regionsByWork.set(a, ra);
              const rb = regionsByWork.get(b) ?? [];
              rb.push({ start: s.start_b, end: s.end_b, cidx });
              regionsByWork.set(b, rb);
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

  const otherWorks = works.filter(
    (w) => !uniqueIds.includes(w.work_id) && w.work_id !== currentWorkId,
  );

  return (
    <div className="ws-connections-tab">
      <div className="ws-conn-section">
        <div className="ws-conn-header" style={{ display: "flex", justifyContent: "space-between" }}>
          <span>Compare ({uniqueIds.length})</span>
          <button className="ws-conn-delete" title="Back to connections" onClick={onClose}>×</button>
        </div>
        {uniqueIds.length < 2 && (
          <div className="ws-conn-empty">
            Select a multi-ended link in Connections and click ⇄ to compare its ends,
            or pick works below.
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
          <div style={{ display: "flex", gap: 4, marginBottom: 8 }}>
            {(["shared", "unique"] as const).map((m) => (
              <button
                key={m}
                type="button"
                className={`ws-link-filter-btn ${viewMode === m ? "active" : ""}`}
                style={{
                  fontSize: 11,
                  padding: "2px 10px",
                  background: viewMode === m ? "#58a6ff" : "transparent",
                  color: viewMode === m ? "#fff" : "#8b949e",
                  borderColor: viewMode === m ? "#58a6ff" : "#30363d",
                }}
                onClick={() => setViewMode(m)}
              >
                {m === "shared" ? "Shared passages" : "What differs"}
              </button>
            ))}
          </div>
        )}
        {!loading && columns.length >= 2 && (
          <div style={{ display: "grid", gridTemplateColumns: `repeat(${Math.min(columns.length, 3)}, 1fr)`, gap: 8 }}>
            {columns.map((col) => (
              <div
                key={col.workId}
                style={{
                  border: "1px solid #30363d",
                  borderRadius: 6,
                  padding: 8,
                  minHeight: 200,
                  maxHeight: 420,
                  overflowY: "auto",
                  fontSize: 12,
                  lineHeight: 1.5,
                }}
              >
                <div style={{ fontWeight: 600, marginBottom: 4, fontSize: 11, color: "#8b949e" }}>
                  {col.title}
                  {col.regions.length === 0 && (
                    <span style={{ color: "#484f58", marginLeft: 6 }}>(no shared passages)</span>
                  )}
                </div>
                <div
                  className="compare-hl"
                  dangerouslySetInnerHTML={{
                    __html: viewMode === "shared"
                      ? highlightRegions(col.text, col.regions, "compare-hl")
                      : highlightComplement(col.text, col.regions),
                  }}
                />
              </div>
            ))}
          </div>
        )}
        {!loading && otherWorks.length > 0 && (
          <div style={{ marginTop: 8, display: "flex", gap: 6, alignItems: "center" }}>
            <select
              className="ws-filter-select"
              value={addWorkId}
              onChange={(e) => setAddWorkId(e.target.value === "" ? "" : Number(e.target.value))}
              style={{ flex: 1 }}
            >
              <option value="">Add a work to the comparison…</option>
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
