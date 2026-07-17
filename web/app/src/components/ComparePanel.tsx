import { useState, useEffect, useRef, useMemo, useCallback } from "react";
import type { CrdtSyncClient, WorkListEntry } from "../api/crdt_sync";

const BRIDGE_COLORS = [
  "#d29922", "#56b4e9", "#009e73", "#cc79a7",
  "#f0e442", "#e69f00", "#0072b2", "#d55e00",
];

type CompareMode = "document" | "revision";
type DiffGranularity = "word" | "char";

interface TextRegion {
  start: number;
  end: number;
  cidx: number;
}

export function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function highlightRegions(
  text: string,
  regions: TextRegion[],
  highlightCls: string,
  uniqueCls?: string
): string {
  if (!regions.length) {
    if (uniqueCls) return `<span class="${uniqueCls}">${escapeHtml(text)}</span>`;
    return escapeHtml(text);
  }
  const sorted = [...regions].sort((a, b) => a.start - b.start);
  let html = "";
  let pos = 0;
  for (const r of sorted) {
    if (r.end <= pos) continue;
    const start = Math.max(r.start, pos);
    if (start > pos) {
      if (uniqueCls)
        html += `<span class="${uniqueCls}">${escapeHtml(text.slice(pos, start))}</span>`;
      else html += escapeHtml(text.slice(pos, start));
    }
    const cidx = r.cidx !== undefined ? r.cidx : 0;
    html += `<span class="${highlightCls}" data-cidx="${cidx}" style="background:${BRIDGE_COLORS[cidx]}30;border-bottom:2px solid ${BRIDGE_COLORS[cidx]}">`;
    html += escapeHtml(text.slice(start, r.end));
    html += "</span>";
    pos = r.end;
  }
  if (pos < text.length) {
    if (uniqueCls) html += `<span class="${uniqueCls}">${escapeHtml(text.slice(pos))}</span>`;
    else html += escapeHtml(text.slice(pos));
  }
  return html;
}

export function wordSimilarity(a: string, b: string): number {
  const wa = new Set(a.toLowerCase().split(/\s+/).filter((w) => w.length > 2));
  const wb = new Set(b.toLowerCase().split(/\s+/).filter((w) => w.length > 2));
  if (wa.size === 0 || wb.size === 0) return 0;
  let intersection = 0;
  for (const w of wa) if (wb.has(w)) intersection++;
  return intersection / (wa.size + wb.size - intersection);
}

function findParagraphMatches(
  leftText: string,
  rightText: string,
  fuzzy: boolean,
): { leftRegions: TextRegion[]; rightRegions: TextRegion[] } {
  const leftParas = leftText.split(/\n\s*\n/);
  const rightParas = rightText.split(/\n\s*\n/);
  const rightUsed = new Set<number>();
  const leftRegions: TextRegion[] = [];
  const rightRegions: TextRegion[] = [];

  // Track actual separator lengths by scanning the original text
  const leftSepLens: number[] = [];
  let scanLeft = 0;
  for (let i = 0; i < leftParas.length - 1; i++) {
    scanLeft += leftParas[i].length;
    const sepMatch = leftText.slice(scanLeft).match(/^\n\s*\n/);
    leftSepLens.push(sepMatch ? sepMatch[0].length : 2);
    scanLeft += leftSepLens[leftSepLens.length - 1];
  }

  const rightSepLens: number[] = [];
  let scanRight = 0;
  for (let i = 0; i < rightParas.length - 1; i++) {
    scanRight += rightParas[i].length;
    const sepMatch = rightText.slice(scanRight).match(/^\n\s*\n/);
    rightSepLens.push(sepMatch ? sepMatch[0].length : 2);
    scanRight += rightSepLens[rightSepLens.length - 1];
  }

  let leftOffset = 0;
  for (let li = 0; li < leftParas.length; li++) {
    const lTrim = leftParas[li].trim();
    if (lTrim.length < 10) {
      leftOffset += leftParas[li].length + (li < leftSepLens.length ? leftSepLens[li] : 0);
      continue;
    }
    let bestRi = -1;
    let bestSim = 0;
    let rightOffset = 0;
    const offsets: number[] = [];
    for (let ri = 0; ri < rightParas.length; ri++) {
      offsets.push(rightOffset);
      rightOffset += rightParas[ri].length + (ri < rightSepLens.length ? rightSepLens[ri] : 0);
      if (rightUsed.has(ri)) continue;
      const rTrim = rightParas[ri].trim();
      const sim = rTrim === lTrim ? 1.0 : fuzzy ? wordSimilarity(lTrim, rTrim) : 0;
      if (sim > bestSim) {
        bestSim = sim;
        bestRi = ri;
      }
    }
    if (bestRi >= 0 && bestSim >= 0.35) {
      rightUsed.add(bestRi);
      const cidx = leftRegions.length % 8;
      leftRegions.push({ start: leftOffset, end: leftOffset + leftParas[li].length, cidx });
      rightRegions.push({
        start: offsets[bestRi],
        end: offsets[bestRi] + rightParas[bestRi].length,
        cidx,
      });
    }
    leftOffset += leftParas[li].length + (li < leftSepLens.length ? leftSepLens[li] : 0);
  }
  return { leftRegions, rightRegions };
}

export interface CompareState {
  mode: CompareMode;
  setMode: (m: CompareMode) => void;
  targetText: string;
  targetLabel: string;
  hasTarget: boolean;
  leftRegions: TextRegion[];
  rightRegions: TextRegion[];
  loading: boolean;
  regionCount: number;
  clearTarget: () => void;
  fuzzy: boolean;
  setFuzzy: (f: boolean) => void;
  diffGranularity: DiffGranularity;
  setDiffGranularity: (g: DiffGranularity) => void;
}

export function useCompare(
  visible: boolean,
  currentWorkId: number | null,
  currentText: string,
  client: CrdtSyncClient | null,
): CompareState {
  const [mode, setModeRaw] = useState<CompareMode>("document");
  const [fuzzy, setFuzzy] = useState(true);
  const [diffGranularity, setDiffGranularity] = useState<DiffGranularity>("word");
  const [targetText, setTargetText] = useState("");
  const [targetLabel, setTargetLabel] = useState("");
  const [leftRegions, setLeftRegions] = useState<TextRegion[]>([]);
  const [rightRegions, setRightRegions] = useState<TextRegion[]>([]);
  const [loading, setLoading] = useState(false);

  const setMode = useCallback((m: CompareMode) => {
    setModeRaw(m);
    setTargetText("");
    setLeftRegions([]);
    setRightRegions([]);
    setTargetLabel("");
  }, []);

  const clearTarget = useCallback(() => {
    setTargetText("");
    setLeftRegions([]);
    setRightRegions([]);
    setTargetLabel("");
  }, []);

  useEffect(() => {
    if (!visible) {
      setTargetText("");
      setLeftRegions([]);
      setRightRegions([]);
      setTargetLabel("");
    }
  }, [visible]);

  // Recompute paragraph matching whenever fuzzy changes or texts change.
  // This is what makes the Fuzzy/Exact toggle actually do something.
  useEffect(() => {
    if (!targetText || !currentText) return;
    const { leftRegions: lr, rightRegions: rr } = findParagraphMatches(
      currentText,
      targetText,
      fuzzy,
    );
    setLeftRegions(lr);
    setRightRegions(rr);
  }, [fuzzy, targetText, currentText]);

  const openDocumentCompare = useCallback(
    async (wid: number) => {
      if (!client || !currentWorkId || wid === currentWorkId) return;
      setTargetLabel(`Document ${wid}`);
      setLoading(true);
      try {
        const regions = await client.findSharedRegions(currentWorkId, wid);
        setLeftRegions(regions.map((r, i) => ({ start: r.start_a, end: r.end_a, cidx: i % 8 })));
        setRightRegions(regions.map((r, i) => ({ start: r.start_b, end: r.end_b, cidx: i % 8 })));
      } catch (e) {
        console.error("Compare failed:", e);
        setLeftRegions([]);
        setRightRegions([]);
      }
      try {
        const resp = await (client as any).sendRequest("work_get_edition", { work_id: wid });
        const val = (resp as any)?.value;
        const text = val?.Text || val?.text || (typeof val === "string" ? val : "");
        setTargetText(text);
      } catch {
        setTargetText("");
      }
      setLoading(false);
    },
    [client, currentWorkId]
  );

  const openRevisionCompare = useCallback(
    async (revision: number) => {
      if (!client || !currentWorkId) return;
      setTargetLabel(`Revision ${revision}`);
      setLoading(true);
      try {
        const text = await client.fetchRevision(currentWorkId, revision);
        setTargetText(text || "");
        const { leftRegions: lr, rightRegions: rr } = findParagraphMatches(currentText, text || "", fuzzy);
        setLeftRegions(lr);
        setRightRegions(rr);
      } catch (e) {
        console.error("Revision compare failed:", e);
        setTargetText("");
        setLeftRegions([]);
        setRightRegions([]);
      }
      setLoading(false);
    },
    [client, currentWorkId, currentText, fuzzy]
  );

  (useCompare as any)._openDocument = openDocumentCompare;
  (useCompare as any)._openRevision = openRevisionCompare;

  return {
    mode,
    setMode,
    targetText,
    targetLabel,
    hasTarget: targetText !== "",
    leftRegions,
    rightRegions,
    loading,
    regionCount: Math.max(leftRegions.length, rightRegions.length),
    clearTarget,
    fuzzy,
    setFuzzy,
    diffGranularity,
    setDiffGranularity,
  };
}

interface CompareHeaderProps {
  visible: boolean;
  state: CompareState;
  currentWorkId: number | null;
  works: WorkListEntry[];
  revisionCount: number;
  onClose: () => void;
}

export function CompareHeader({ visible, state, currentWorkId, works, revisionCount, onClose }: CompareHeaderProps) {
  if (!visible) return null;

  const otherWorks = works.filter((w) => w.work_id !== currentWorkId);
  const openDoc = (useCompare as any)._openDocument as ((wid: number) => Promise<void>) | undefined;
  const openRev = (useCompare as any)._openRevision as ((rev: number) => Promise<void>) | undefined;

  return (
    <div className="compare-header">
      <span className="compare-title">Compare</span>
      <div className="compare-mode-tabs">
        <button
          type="button"
          className={`compare-mode-tab ${state.mode === "document" ? "active" : ""}`}
          onClick={() => state.setMode("document")}
        >
          vs Document
        </button>
        <button
          type="button"
          className={`compare-mode-tab ${state.mode === "revision" ? "active" : ""}`}
          onClick={() => state.setMode("revision")}
        >
          vs Revision
        </button>
      </div>
      <button
        type="button"
        onClick={() => state.setFuzzy(!state.fuzzy)}
        title={state.fuzzy ? "Fuzzy matching: paragraphs sharing >=35% words are linked. Click for exact-only matching." : "Exact matching: only identical paragraphs are linked. Click for fuzzy matching."}
        style={{
          padding: "2px 8px",
          fontSize: 11,
          border: "1px solid #d0d0d0",
          borderRadius: 3,
          background: state.fuzzy ? "#e8f0fe" : "#fff",
          color: state.fuzzy ? "#1a73e8" : "#888",
          cursor: "pointer",
          fontWeight: 500,
        }}
      >
        {state.fuzzy ? "Fuzzy" : "Exact"}
      </button>
      <button
        type="button"
        onClick={() => state.setDiffGranularity(state.diffGranularity === "word" ? "char" : "word")}
        title={state.diffGranularity === "word" ? "Word-level diff. Click for character-level." : "Character-level diff. Click for word-level."}
        style={{
          padding: "2px 8px",
          fontSize: 11,
          border: "1px solid #d0d0d0",
          borderRadius: 3,
          background: state.diffGranularity === "char" ? "#f0e8ff" : "#fff",
          color: state.diffGranularity === "char" ? "#7b1fa2" : "#888",
          cursor: "pointer",
          fontWeight: 500,
        }}
      >
        {state.diffGranularity === "word" ? "Word" : "Char"}
      </button>
      {state.mode === "document" && !state.hasTarget && (
        <select
          value=""
          onChange={(e) => {
            const v = parseInt(e.target.value);
            if (v && openDoc) openDoc(v);
          }}
          className="compare-select"
        >
          <option value="">— select document —</option>
          {otherWorks.map((w) => (
            <option key={w.work_id} value={String(w.work_id)}>
              {w.work_id}
              {w.title ? ` (${w.title.length > 30 ? w.title.slice(0, 30) + "..." : w.title})` : ""}
            </option>
          ))}
        </select>
      )}
      {state.mode === "revision" && !state.hasTarget && (
        <select
          value=""
          onChange={(e) => {
            const v = parseInt(e.target.value);
            if (v && openRev) openRev(v);
          }}
          className="compare-select"
        >
          <option value="">— select revision —</option>
          {Array.from({ length: revisionCount }, (_, i) => i + 1)
            .reverse()
            .map((r) => (
              <option key={r} value={String(r)}>
                Revision {r}
              </option>
            ))}
        </select>
      )}
      {state.hasTarget && (
        <span className="compare-target-label">
          vs {state.targetLabel}
          <button type="button" className="compare-close-target" onClick={state.clearTarget}>
            x
          </button>
        </span>
      )}
      <button type="button" className="compare-close" onClick={onClose}>x</button>
    </div>
  );
}

// ── Inline diff (word-level LCS) ─────────────────────────────────────────

export interface DiffSegment {
  type: "common" | "added" | "removed";
  text: string;
}

export function tokenize(text: string): string[] {
  return text.match(/\S+|\s+/g) || [text];
}

export function charTokens(text: string): string[] {
  return Array.from(text);
}

export function computeDiff(textA: string, textB: string, granularity: DiffGranularity = "word"): DiffSegment[] {
  const a = granularity === "char" ? charTokens(textA) : tokenize(textA);
  const b = granularity === "char" ? charTokens(textB) : tokenize(textB);
  const m = a.length;
  const n = b.length;

  // LCS DP table
  const dp: number[][] = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      dp[i][j] = a[i - 1] === b[j - 1]
        ? dp[i - 1][j - 1] + 1
        : Math.max(dp[i - 1][j], dp[i][j - 1]);
    }
  }

  // Backtrack
  const raw: DiffSegment[] = [];
  let i = m;
  let j = n;
  while (i > 0 && j > 0) {
    if (a[i - 1] === b[j - 1]) {
      raw.unshift({ type: "common", text: a[i - 1] });
      i--;
      j--;
    } else if (dp[i - 1][j] >= dp[i][j - 1]) {
      raw.unshift({ type: "removed", text: a[i - 1] });
      i--;
    } else {
      raw.unshift({ type: "added", text: b[j - 1] });
      j--;
    }
  }
  while (i > 0) raw.unshift({ type: "removed", text: a[--i] });
  while (j > 0) raw.unshift({ type: "added", text: b[--j] });

  // Merge consecutive same-type segments
  const merged: DiffSegment[] = [];
  for (const seg of raw) {
    const last = merged[merged.length - 1];
    if (last && last.type === seg.type) last.text += seg.text;
    else merged.push({ ...seg });
  }
  return merged;
}

function DiffView({ segments }: { segments: DiffSegment[] }) {
  return (
    <div
      style={{
        whiteSpace: "pre-wrap",
        fontFamily: "SF Mono, Fira Code, ui-monospace, monospace",
        fontSize: 13,
        lineHeight: 1.7,
        padding: 16,
        overflow: "auto",
        flex: 1,
        minHeight: 0,
      }}
    >
      {segments.map((seg, i) => {
        if (seg.type === "added")
          return (
            <span key={i} style={{ background: "#f0f9f0", color: "#3a7a3a", borderRadius: 2 }}>
              {seg.text}
            </span>
          );
        if (seg.type === "removed")
          return (
            <span
              key={i}
              style={{ background: "#fdf2f2", color: "#a04040", textDecoration: "line-through", borderRadius: 2 }}
            >
              {seg.text}
            </span>
          );
        return <span key={i}>{seg.text}</span>;
      })}
    </div>
  );
}

interface CompareSplitViewProps {
  currentText: string;
  state: CompareState;
}

export function CompareSplitView({ currentText, state }: CompareSplitViewProps) {
  const leftWrapRef = useRef<HTMLDivElement>(null);
  const rightWrapRef = useRef<HTMLDivElement>(null);
  const areaRef = useRef<HTMLDivElement>(null);

  const leftHtml = useMemo(() => {
    if (!currentText) return "";
    return highlightRegions(currentText, state.leftRegions, "compare-hl", "compare-unique-left");
  }, [currentText, state.leftRegions]);

  const rightHtml = useMemo(() => {
    if (!state.targetText) return '<span style="color:#888">Loading...</span>';
    return highlightRegions(state.targetText, state.rightRegions, "compare-hl", "compare-unique-right");
  }, [state.targetText, state.rightRegions]);

  const [viewMode, setViewMode] = useState<"split" | "diff">("split");
  const diffSegments = useMemo(() => {
    if (viewMode !== "diff" || !state.targetText) return [];
    return computeDiff(currentText, state.targetText, state.diffGranularity);
  }, [viewMode, currentText, state.targetText, state.diffGranularity]);

  useEffect(() => {
    if (!state.leftRegions.length && !state.rightRegions.length) return;

    function computeBridges() {
      const lc = leftWrapRef.current?.querySelectorAll(".compare-hl");
      const rc = rightWrapRef.current?.querySelectorAll(".compare-hl");
      const area = areaRef.current;
      const lw = leftWrapRef.current;
      const rw = rightWrapRef.current;
      if (!lc?.length || !rc?.length || !area || !lw || !rw) return;

      const areaRect = area.getBoundingClientRect();
      const lwRect = lw.getBoundingClientRect();
      const rwRect = rw.getBoundingClientRect();
      const n = Math.min(lc.length, rc.length);

      const canvas = area.querySelector("canvas._bridge") as HTMLCanvasElement;
      if (!canvas) return;

      const dpr = window.devicePixelRatio || 1;
      canvas.width = Math.round(areaRect.width) * dpr;
      canvas.height = Math.round(areaRect.height) * dpr;
      canvas.style.width = Math.round(areaRect.width) + "px";
      canvas.style.height = Math.round(areaRect.height) + "px";
      const ctx = canvas.getContext("2d")!;
      ctx.scale(dpr, dpr);
      ctx.clearRect(0, 0, areaRect.width, areaRect.height);
      ctx.lineWidth = 1.5;
      ctx.setLineDash([4, 3]);
      ctx.globalAlpha = 0.7;

      for (let i = 0; i < n; i++) {
        const lr = lc[i].getBoundingClientRect();
        const rr = rc[i].getBoundingClientRect();
        if (lr.bottom < lwRect.top || lr.top > lwRect.bottom) continue;
        if (rr.bottom < rwRect.top || rr.top > rwRect.bottom) continue;

        const ly = (lr.top + lr.bottom) / 2 - areaRect.top;
        const ry = (rr.top + rr.bottom) / 2 - areaRect.top;
        const lEdge = lwRect.right - areaRect.left;
        const rEdge = rwRect.left - areaRect.left;

        ctx.strokeStyle = BRIDGE_COLORS[i % 8];
        ctx.beginPath();
        ctx.moveTo(lEdge, ly);
        ctx.bezierCurveTo(lEdge + 20, ly, rEdge - 20, ry, rEdge, ry);
        ctx.stroke();
      }
    }

    const timer = setTimeout(computeBridges, 100);
    const lw = leftWrapRef.current;
    const rw = rightWrapRef.current;
    if (lw) lw.addEventListener("scroll", computeBridges);
    if (rw) rw.addEventListener("scroll", computeBridges);
    window.addEventListener("resize", computeBridges);
    return () => {
      clearTimeout(timer);
      if (lw) lw.removeEventListener("scroll", computeBridges);
      if (rw) rw.removeEventListener("scroll", computeBridges);
      window.removeEventListener("resize", computeBridges);
    };
  }, [state.leftRegions, state.rightRegions, leftHtml, rightHtml]);

  return (
    <div className="compare-split" ref={areaRef}>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 0,
          borderBottom: "1px solid #e0e0e0",
          background: "#fafafa",
          fontSize: 12,
        }}
      >
        {(["split", "diff"] as const).map((mode) => (
          <button
            key={mode}
            type="button"
            onClick={() => setViewMode(mode)}
            style={{
              padding: "4px 10px",
              border: "none",
              borderRight: "1px solid #e0e0e0",
              background: viewMode === mode ? "#fff" : "transparent",
              borderBottom: viewMode === mode ? "2px solid #4a6da7" : "2px solid transparent",
              fontWeight: viewMode === mode ? 600 : 400,
              color: viewMode === mode ? "#333" : "#999",
              cursor: "pointer",
              fontSize: 12,
            }}
          >
            {mode === "split" ? "Split" : "Diff"}
          </button>
        ))}
        {viewMode === "diff" ? (
          <span style={{ marginLeft: "auto", paddingRight: 10, color: "#aaa" }}>
            <span style={{ background: "#f0f9f0", color: "#3a7a3a", padding: "0 3px", borderRadius: 2 }}>+added</span>{" "}
            <span style={{ background: "#fdf2f2", color: "#a04040", padding: "0 3px", borderRadius: 2, textDecoration: "line-through" }}>-removed</span>
          </span>
        ) : state.regionCount > 0 ? (
          <span style={{ marginLeft: "auto", paddingRight: 10, color: "#999", fontSize: 11 }}>
            <span style={{ background: BRIDGE_COLORS[0] + "30", borderBottom: `2px solid ${BRIDGE_COLORS[0]}`, padding: "0 3px", borderRadius: 2 }}>
              Shared ({state.regionCount})
            </span>{" "}
            <span style={{ opacity: 0.5 }}>Left only</span>{" "}
            <span style={{ opacity: 0.5 }}>Right only</span>
          </span>
        ) : null}
      </div>
      {viewMode === "diff" ? (
        state.loading ? (
          <div style={{ padding: 24, color: "#888" }}>Loading...</div>
        ) : (
          <DiffView segments={diffSegments} />
        )
      ) : (
        <>
          <div className="compare-pane" ref={leftWrapRef}>
            <div className="compare-pane-label">Current</div>
            <div className="compare-content" dangerouslySetInnerHTML={{ __html: leftHtml }} />
          </div>
          <canvas className="_bridge" />
          <div className="compare-pane" ref={rightWrapRef}>
            <div className="compare-pane-label">{state.targetLabel}</div>
            {state.loading ? (
              <div className="compare-loading">Loading...</div>
            ) : (
              <div className="compare-content" dangerouslySetInnerHTML={{ __html: rightHtml }} />
            )}
          </div>
        </>
      )}
    </div>
  );
}
