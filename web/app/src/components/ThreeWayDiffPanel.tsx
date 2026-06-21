import { useState, useEffect, useCallback, useMemo } from "react";
import type { CrdtSyncClient, WorkListEntry } from "../api/crdt_sync";

// ── Types ─────────────────────────────────────────────────────────────────

type SegmentKind = "unchanged" | "a_only" | "b_only" | "conflict" | "a_added" | "b_added";
type Resolution = "a" | "b" | "base";

interface MergeSegment {
  kind: SegmentKind;
  baseText: string;
  aText: string;
  bText: string;
  resolution: Resolution;
  isConflict: boolean;
}

// ── 3-way paragraph diff ──────────────────────────────────────────────────

function paragraphs(text: string): string[] {
  return text.split(/\n\s*\n/);
}

function wordsMatch(a: string, b: string): boolean {
  return a.trim() === b.trim();
}

function computeThreeWay(baseText: string, aText: string, bText: string): MergeSegment[] {
  const base = paragraphs(baseText);
  const a = paragraphs(aText);
  const b = paragraphs(bText);
  const maxLen = Math.max(base.length, a.length, b.length);
  const segments: MergeSegment[] = [];

  for (let i = 0; i < maxLen; i++) {
    const bp = base[i] ?? "";
    const ap = a[i] ?? "";
    const bp2 = b[i] ?? "";

    const baseMatchesA = wordsMatch(bp, ap);
    const baseMatchesB = wordsMatch(bp, bp2);

    let kind: SegmentKind;
    let resolution: Resolution;

    if (baseMatchesA && baseMatchesB) {
      kind = "unchanged";
      resolution = "base";
    } else if (baseMatchesA && !baseMatchesB) {
      kind = "b_only";
      resolution = "b";
    } else if (!baseMatchesA && baseMatchesB) {
      kind = "a_only";
      resolution = "a";
    } else if (!baseMatchesA && !baseMatchesB && wordsMatch(ap, bp2)) {
      // Both A and B made the same change
      kind = "unchanged";
      resolution = "a";
    } else if (!bp && ap && !bp2) {
      kind = "a_added";
      resolution = "a";
    } else if (!bp && !ap && bp2) {
      kind = "b_added";
      resolution = "b";
    } else {
      kind = "conflict";
      resolution = "base"; // default resolution
    }

    segments.push({
      kind,
      baseText: bp,
      aText: ap,
      bText: bp2,
      resolution,
      isConflict: kind === "conflict",
    });
  }

  return segments;
}

function resolveSegment(seg: MergeSegment): string {
  switch (seg.resolution) {
    case "a":
      return seg.aText;
    case "b":
      return seg.bText;
    case "base":
      return seg.baseText;
  }
}

function buildMergedText(segments: MergeSegment[]): string {
  return segments
    .filter((s) => {
      const text = resolveSegment(s);
      return text.trim().length > 0 || s.kind === "unchanged";
    })
    .map(resolveSegment)
    .join("\n\n");
}

// ── UI helpers ────────────────────────────────────────────────────────────

const KIND_STYLES: Record<SegmentKind, { border: string; bg: string; label: string; labelColor: string }> = {
  unchanged: { border: "#e8e8e8", bg: "#fafafa", label: "Common", labelColor: "#999" },
  a_only: { border: "#1a7f37", bg: "#f6fff8", label: "A only (auto)", labelColor: "#1a7f37" },
  b_only: { border: "#0969da", bg: "#f5faff", label: "B only (auto)", labelColor: "#0969da" },
  conflict: { border: "#d1242f", bg: "#fff5f5", label: "CONFLICT", labelColor: "#d1242f" },
  a_added: { border: "#1a7f37", bg: "#f6fff8", label: "Added by A (auto)", labelColor: "#1a7f37" },
  b_added: { border: "#0969da", bg: "#f5faff", label: "Added by B (auto)", labelColor: "#0969da" },
};

// ── Component ──────────────────────────────────────────────────────────────

interface Props {
  client: CrdtSyncClient | null;
  currentWorkId: number | null;
  works: WorkListEntry[];
  onClose: () => void;
}

export function ThreeWayDiffPanel({ client, currentWorkId, works, onClose }: Props) {
  const [workAId, setWorkAId] = useState<number | null>(null);
  const [workBId, setWorkBId] = useState<number | null>(null);
  const [textA, setTextA] = useState("");
  const [textB, setTextB] = useState("");
  const [baseText, setBaseText] = useState("");
  const [loading, setLoading] = useState(false);
  const [segments, setSegments] = useState<MergeSegment[]>([]);
  const [creating, setCreating] = useState(false);

  const otherWorks = useMemo(
    () => works.filter((w) => w.work_id !== currentWorkId),
    [works, currentWorkId],
  );

  const loadText = useCallback(
    async (wid: number): Promise<string> => {
      if (!client) return "";
      try {
        const resp = await (client as any).sendRequest("work_get_edition", { work_id: wid });
        const val = (resp as any)?.value;
        return val?.Text || val?.text || (typeof val === "string" ? val : "") || "";
      } catch {
        return "";
      }
    },
    [client],
  );

  useEffect(() => {
    if (!client || !currentWorkId) return;
    loadText(currentWorkId).then(setBaseText);
  }, [client, currentWorkId, loadText]);

  useEffect(() => {
    if (!client || !workAId) { setTextA(""); return; }
    setLoading(true);
    loadText(workAId).then((t) => { setTextA(t); setLoading(false); });
  }, [client, workAId, loadText]);

  useEffect(() => {
    if (!client || !workBId) { setTextB(""); return; }
    setLoading(true);
    loadText(workBId).then((t) => { setTextB(t); setLoading(false); });
  }, [client, workBId, loadText]);

  useEffect(() => {
    if (baseText && textA && textB) {
      setSegments(computeThreeWay(baseText, textA, textB));
    } else {
      setSegments([]);
    }
  }, [baseText, textA, textB]);

  const ready = workAId !== null && workBId !== null && textA && textB && baseText;

  const conflictCount = useMemo(() => segments.filter((s) => s.isConflict).length, [segments]);
  const unresolvedCount = useMemo(
    () => segments.filter((s) => s.isConflict && s.resolution === "base").length,
    [segments],
  );

  const resolveConflict = useCallback((index: number, resolution: Resolution) => {
    setSegments((prev) => {
      const next = [...prev];
      next[index] = { ...next[index], resolution };
      return next;
    });
  }, []);

  const acceptAll = useCallback((which: "a" | "b") => {
    setSegments((prev) =>
      prev.map((s) => (s.isConflict ? { ...s, resolution: which } : s)),
    );
  }, []);

  const createMerged = useCallback(async () => {
    if (!client || !currentWorkId) return;
    setCreating(true);
    const mergedText = buildMergedText(segments);
    try {
      const resp = await (client as any).sendRequest("work_create", {
        edition: { text: mergedText },
      });
      const val = (resp as any)?.value;
      const newId = (val?.value ?? val) as number;
      if (newId) {
        alert("Merged document created: work 0x" + newId.toString(16));
      }
    } catch (e) {
      alert("Failed to create merged document: " + (e instanceof Error ? e.message : String(e)));
    }
    setCreating(false);
  }, [client, currentWorkId, segments]);

  const mergedPreview = useMemo(() => {
    if (!segments.length) return "";
    return buildMergedText(segments);
  }, [segments]);

  // ── Render ──────────────────────────────────────────────────────────────

  return (
    <div
      onClick={onClose}
      style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)", zIndex: 200, display: "flex", alignItems: "flex-start", justifyContent: "center", overflowY: "auto", padding: "20px 0" }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{ background: "#fff", borderRadius: 8, width: "92vw", maxWidth: 1000, boxShadow: "0 4px 24px rgba(0,0,0,0.2)" }}
      >
        {/* Header */}
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 16px", borderBottom: "1px solid #e0e0e0", flexWrap: "wrap" }}>
          <strong style={{ fontSize: 15 }}>Three-Way Merge</strong>
          <span style={{ color: "#888", fontSize: 11 }}>
            Base: {currentWorkId ? `0x${currentWorkId.toString(16)}` : "—"}
          </span>
          {!workAId ? (
            <select value="" onChange={(e) => setWorkAId(parseInt(e.target.value) || null)} style={{ fontSize: 11, padding: "2px 6px" }}>
              <option value="">— select A —</option>
              {otherWorks.filter((w) => w.work_id !== workBId).map((w) => (
                <option key={w.work_id} value={w.work_id}>0x{w.work_id.toString(16).padStart(4, "0")} {w.title?.slice(0, 25)}</option>
              ))}
            </select>
          ) : (
            <span style={{ fontSize: 11, color: "#1a7f37" }}>
              A: 0x{workAId.toString(16).padStart(4, "0")}{" "}
              <button type="button" onClick={() => { setWorkAId(null); setTextA(""); }} style={{ border: "none", background: "none", cursor: "pointer", color: "#999" }}>×</button>
            </span>
          )}
          {!workBId ? (
            <select value="" onChange={(e) => setWorkBId(parseInt(e.target.value) || null)} style={{ fontSize: 11, padding: "2px 6px" }}>
              <option value="">— select B —</option>
              {otherWorks.filter((w) => w.work_id !== workAId).map((w) => (
                <option key={w.work_id} value={w.work_id}>0x{w.work_id.toString(16).padStart(4, "0")} {w.title?.slice(0, 25)}</option>
              ))}
            </select>
          ) : (
            <span style={{ fontSize: 11, color: "#0969da" }}>
              B: 0x{workBId.toString(16).padStart(4, "0")}{" "}
              <button type="button" onClick={() => { setWorkBId(null); setTextB(""); }} style={{ border: "none", background: "none", cursor: "pointer", color: "#999" }}>×</button>
            </span>
          )}
          <button type="button" onClick={onClose} style={{ marginLeft: "auto", border: "none", background: "none", fontSize: 18, cursor: "pointer", color: "#999" }}>×</button>
        </div>

        {/* Status bar */}
        {ready && !loading && (
          <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "6px 16px", borderBottom: "1px solid #eee", fontSize: 12, color: "#666", flexWrap: "wrap" }}>
            <span>{segments.length} segments</span>
            {conflictCount > 0 && (
              <span style={{ color: conflictCount === unresolvedCount ? "#d1242f" : "#1a7f37", fontWeight: 600 }}>
                {conflictCount} conflict{conflictCount !== 1 ? "s" : ""} ({unresolvedCount} unresolved)
              </span>
            )}
            {conflictCount === 0 && <span style={{ color: "#1a7f37", fontWeight: 600 }}>No conflicts — clean merge</span>}
            {conflictCount > 0 && (
              <>
                <button type="button" onClick={() => acceptAll("a")} style={{ fontSize: 11, padding: "1px 8px", border: "1px solid #1a7f37", borderRadius: 3, background: "#fff", color: "#1a7f37", cursor: "pointer" }}>Accept all A</button>
                <button type="button" onClick={() => acceptAll("b")} style={{ fontSize: 11, padding: "1px 8px", border: "1px solid #0969da", borderRadius: 3, background: "#fff", color: "#0969da", cursor: "pointer" }}>Accept all B</button>
              </>
            )}
          </div>
        )}

        {/* Body */}
        {loading ? (
          <div style={{ padding: 40, textAlign: "center", color: "#888" }}>Loading…</div>
        ) : ready ? (
          <div style={{ maxHeight: "calc(85vh - 120px)", overflowY: "auto", padding: "8px 12px" }}>
            {segments.map((seg, i) => {
              const st = KIND_STYLES[seg.kind];
              const chosen = resolveSegment(seg);
              return (
                <div
                  key={i}
                  style={{
                    border: `2px solid ${st.border}`,
                    borderRadius: 6,
                    background: st.bg,
                    marginBottom: 8,
                    padding: 8,
                  }}
                >
                  {/* Kind label */}
                  <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                    <span style={{ fontSize: 10, fontWeight: 700, textTransform: "uppercase", letterSpacing: 0.5, color: st.labelColor }}>
                      {st.label}
                    </span>
                    <span style={{ fontSize: 10, color: "#aaa" }}>§{i + 1}</span>
                  </div>

                  {/* For unchanged: show compact */}
                  {seg.kind === "unchanged" ? (
                    <div style={{ fontSize: 12, color: "#666", lineHeight: 1.5, whiteSpace: "pre-wrap", fontFamily: "monospace" }}>
                      {chosen.slice(0, 120)}{chosen.length > 120 ? "…" : ""}
                    </div>
                  ) : seg.isConflict ? (
                    /* Conflict: show all three + resolution buttons */
                    <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
                      <div style={{ display: "flex", gap: 8 }}>
                        {([["a", "A (green)", seg.aText, "#1a7f37"], ["b", "B (blue)", seg.bText, "#0969da"], ["base", "Base", seg.baseText, "#999"]] as const).map(([key, label, text, color]) => (
                          <div
                            key={key}
                            onClick={() => resolveConflict(i, key)}
                            style={{
                              flex: 1,
                              cursor: "pointer",
                              border: seg.resolution === key ? `2px solid ${color}` : "1px solid #ddd",
                              borderRadius: 4,
                              padding: 6,
                              background: seg.resolution === key ? color + "08" : "#fff",
                            }}
                          >
                            <div style={{ fontSize: 9, fontWeight: 700, textTransform: "uppercase", color, marginBottom: 3 }}>
                              {label}{seg.resolution === key ? " ✓" : ""}
                            </div>
                            <div style={{ fontSize: 11, lineHeight: 1.5, whiteSpace: "pre-wrap", fontFamily: "monospace", maxHeight: 100, overflow: "auto" }}>
                              {text || "(empty)"}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  ) : (
                    /* A-only / B-only / added: show the chosen version */
                    <div style={{ fontSize: 12, lineHeight: 1.5, whiteSpace: "pre-wrap", fontFamily: "monospace", color: st.labelColor === "#1a7f37" ? "#1a7f37" : "#0969da" }}>
                      {chosen.slice(0, 200)}{chosen.length > 200 ? "…" : ""}
                    </div>
                  )}
                </div>
              );
            })}

            {/* Merged preview + create button */}
            <div style={{ marginTop: 12, borderTop: "2px solid #e0e0e0", paddingTop: 12 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 8 }}>
                <strong style={{ fontSize: 13 }}>Merged Result</strong>
                <span style={{ fontSize: 11, color: "#888" }}>{mergedPreview.length} chars</span>
                <button
                  type="button"
                  onClick={createMerged}
                  disabled={creating || (conflictCount > 0 && unresolvedCount > 0)}
                  style={{
                    marginLeft: "auto",
                    padding: "4px 14px",
                    fontSize: 12,
                    fontWeight: 600,
                    border: "none",
                    borderRadius: 4,
                    cursor: creating || (conflictCount > 0 && unresolvedCount > 0) ? "not-allowed" : "pointer",
                    background: creating || (conflictCount > 0 && unresolvedCount > 0) ? "#ccc" : "#2da44e",
                    color: "#fff",
                  }}
                  title={conflictCount > 0 && unresolvedCount > 0 ? "Resolve all conflicts first" : "Create a new work from the merged result"}
                >
                  {creating ? "Creating…" : "Create Merged Document"}
                </button>
              </div>
              <div
                style={{
                  background: "#f8f9fa",
                  border: "1px solid #e0e0e0",
                  borderRadius: 4,
                  padding: 12,
                  maxHeight: 200,
                  overflowY: "auto",
                  fontSize: 12,
                  lineHeight: 1.6,
                  whiteSpace: "pre-wrap",
                  fontFamily: "SF Mono, Fira Code, ui-monospace, monospace",
                  color: "#333",
                }}
              >
                {mergedPreview || "(empty)"}
              </div>
            </div>
          </div>
        ) : (
          <div style={{ padding: 40, textAlign: "center", color: "#888" }}>
            Select two documents to merge against this work as the base.
            <br />
            <span style={{ fontSize: 12 }}>
              The current work is the common ancestor. Changes from A and B are auto-merged;
              conflicts (both changed the same paragraph) require your decision.
            </span>
          </div>
        )}
      </div>
    </div>
  );
}
