import { useState, useCallback, useMemo } from "react";
import type { CrdtSyncClient, WorkListEntry } from "../api/crdt_sync";

interface WorkPickerProps {
  label: string;
  works: WorkListEntry[];
  value: number | null;
  onSelect: (id: number | null) => void;
}

function WorkPicker({ label, works, value, onSelect }: WorkPickerProps) {
  const [query, setQuery] = useState("");
  const [focused, setFocused] = useState(false);
  const selected = works.find((w) => w.work_id === value);

  const filtered = useMemo(() => {
    if (!query) return works.slice(0, 20);
    const q = query.toLowerCase();
    return works.filter((w) =>
      (w.title || "Untitled").toLowerCase().includes(q) ||
      w.work_id.toString(16).includes(q)
    ).slice(0, 20);
  }, [works, query]);

  const inputStyle: React.CSSProperties = {
    width: "100%", background: "#1c1c26", border: "1px solid #30363d", color: "#c9d1d9",
    borderRadius: "4px", padding: "6px 8px", fontSize: "12px", fontFamily: "Inter, sans-serif",
  };
  const labelStyle: React.CSSProperties = {
    fontSize: "11px", fontWeight: 600, color: "#8b949e", marginBottom: "4px",
    fontFamily: "Inter, sans-serif", textTransform: "uppercase", letterSpacing: "0.05em",
  };

  return (
    <div style={{ position: "relative" }}>
      <div style={labelStyle}>{label}</div>
      <input
        type="text"
        value={selected ? (selected.title || "Untitled") + ` (0x${selected.work_id.toString(16).padStart(4, "0")})` : query}
        placeholder="Type to search..."
        onFocus={() => { setFocused(true); if (selected) { setQuery(""); onSelect(null); } }}
        onBlur={() => { setTimeout(() => setFocused(false), 150); }}
        onChange={(e) => setQuery(e.target.value)}
        style={inputStyle}
      />
      {focused && (
        <div style={{
          position: "absolute", top: "100%", left: 0, right: 0, zIndex: 10,
          background: "#1c1c26", border: "1px solid #30363d", borderRadius: "0 0 4px 4px",
          maxHeight: "240px", overflowY: "auto",
        }}>
          {filtered.length === 0 && (
            <div style={{ padding: "8px", color: "#6e7681", fontSize: "12px" }}>No matches</div>
          )}
          {filtered.map((w) => (
            <div key={w.work_id}
              onMouseDown={(e) => { e.preventDefault(); onSelect(w.work_id); setFocused(false); }}
              style={{
                padding: "6px 10px", cursor: "pointer", fontSize: "12px", color: "#c9d1d9",
                borderBottom: "1px solid #21262d",
              }}
              onMouseEnter={(e) => { e.currentTarget.style.background = "#30363d"; }}
              onMouseLeave={(e) => { e.currentTarget.style.background = "transparent"; }}
            >
              {w.title || "Untitled"} <span style={{ color: "#6e7681", fontSize: "10px" }}>0x{w.work_id.toString(16).padStart(4, "0")}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

interface MergePanelProps {
  client: CrdtSyncClient | null;
  currentWorkId: number;
  works: WorkListEntry[];
  onClose: () => void;
  onMerged: (newWorkId: number) => void;
}

interface MergeSegment {
  type: "unchanged" | "a_only" | "b_only" | "conflict" | "both_same";
  baseText: string;
  aText: string;
  bText: string;
  resolution: "a" | "b" | null;
}

function splitIntoParagraphs(text: string): string[] {
  return text.split(/\n\s*\n/).filter((p) => p.trim().length > 0);
}

function paragraphsMatch(a: string, b: string): boolean {
  return a.trim() === b.trim();
}

function computeThreeWay(baseText: string, aText: string, bText: string): MergeSegment[] {
  const base = splitIntoParagraphs(baseText);
  const a = splitIntoParagraphs(aText);
  const b = splitIntoParagraphs(bText);
  const segments: MergeSegment[] = [];

  const maxLen = Math.max(base.length, a.length, b.length);

  for (let i = 0; i < maxLen; i++) {
    const bp = base[i] || "";
    const ap = a[i] || "";
    const bp2 = b[i] || "";

    if (!bp && !ap && !bp2) continue;

    const aChanged = !paragraphsMatch(bp, ap);
    const bChanged = !paragraphsMatch(bp, bp2);

    if (!aChanged && !bChanged) {
      segments.push({ type: "unchanged", baseText: bp, aText: ap, bText: bp2, resolution: null });
    } else if (aChanged && !bChanged) {
      segments.push({ type: "a_only", baseText: bp, aText: ap, bText: bp2, resolution: "a" });
    } else if (!aChanged && bChanged) {
      segments.push({ type: "b_only", baseText: bp, aText: ap, bText: bp2, resolution: "b" });
    } else if (aChanged && bChanged && paragraphsMatch(ap, bp2)) {
      segments.push({ type: "both_same", baseText: bp, aText: ap, bText: bp2, resolution: "a" });
    } else {
      segments.push({ type: "conflict", baseText: bp, aText: ap, bText: bp2, resolution: "a" });
    }
  }

  const extraA = a.slice(maxLen);
  const extraB = b.slice(maxLen);
  for (const p of extraA) {
    segments.push({ type: "a_only", baseText: "", aText: p, bText: "", resolution: "a" });
  }
  for (const p of extraB) {
    segments.push({ type: "b_only", baseText: "", aText: "", bText: p, resolution: "b" });
  }

  return segments;
}

export function MergePanel({ client, currentWorkId, works, onClose, onMerged }: MergePanelProps) {
  const [baseWorkId, setBaseWorkId] = useState<number | null>(null);
  const [workAId, setWorkAId] = useState<number | null>(null);
  const [workBId, setWorkBId] = useState<number | null>(null);
  const [baseText, setBaseText] = useState("");
  const [aText, setAText] = useState("");
  const [bText, setBText] = useState("");
  const [loading, setLoading] = useState(false);
  const [merging, setMerging] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loaded, setLoaded] = useState(false);
  const [resolutions, setResolutions] = useState<Record<number, "a" | "b">>({});

  const otherWorks = works.filter((w) => w.work_id !== currentWorkId);

  const fetchWorkText = useCallback(async (wid: number): Promise<string> => {
    if (!client) return "";
    try {
      const resp = await client.sendRequest("work_get_edition", { work_id: wid });
      const val = (resp as Record<string, unknown>)?.value;
      const r = val as Record<string, unknown> | undefined;
      return (r?.Text as string) || (r?.text as string) || (typeof val === "string" ? val : "");
    } catch {
      return "";
    }
  }, [client]);

  const handleLoad = useCallback(async () => {
    if (!client || !baseWorkId || !workAId || !workBId) return;
    setLoading(true);
    setError(null);
    try {
      const [bt, at, bt2] = await Promise.all([
        fetchWorkText(baseWorkId),
        fetchWorkText(workAId),
        fetchWorkText(workBId),
      ]);
      setBaseText(bt);
      setAText(at);
      setBText(bt2);
      setLoaded(true);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load works");
    } finally {
      setLoading(false);
    }
  }, [client, baseWorkId, workAId, workBId, fetchWorkText]);

  const segments = useMemo(() => {
    if (!loaded) return [];
    return computeThreeWay(baseText, aText, bText);
  }, [loaded, baseText, aText, bText]);

  const conflictCount = segments.filter((s) => s.type === "conflict").length;
  const aOnlyCount = segments.filter((s) => s.type === "a_only").length;
  const bOnlyCount = segments.filter((s) => s.type === "b_only").length;
  const unchangedCount = segments.filter((s) => s.type === "unchanged" || s.type === "both_same").length;

  const resolvedSegments = useMemo(() => {
    return segments.map((seg, i) => {
      const override = resolutions[i];
      return { ...seg, resolution: override || seg.resolution };
    });
  }, [segments, resolutions]);

  const mergedText = useMemo(() => {
    return resolvedSegments
      .map((seg) => {
        if (seg.type === "unchanged" || seg.type === "both_same") return seg.aText;
        if (seg.type === "a_only") return seg.aText;
        if (seg.type === "b_only") return seg.bText;
        if (seg.type === "conflict") return seg.resolution === "b" ? seg.bText : seg.aText;
        return seg.baseText;
      })
      .filter((t) => t.trim().length > 0)
      .join("\n\n");
  }, [resolvedSegments]);

  const handleMerge = useCallback(async () => {
    if (!client || !baseWorkId || !workAId || !workBId) return;
    setMerging(true);
    setError(null);
    try {
      const newWorkId = await client.workMerge(baseWorkId, workAId, workBId);
      onMerged(newWorkId);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Merge failed");
    } finally {
      setMerging(false);
    }
  }, [client, baseWorkId, workAId, workBId, onMerged]);

  return (
    <div style={{ position: "fixed", inset: 0, zIndex: 100, background: "#0d1117", display: "flex", flexDirection: "column" }}>
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 16px", height: "48px", background: "#161b22", borderBottom: "1px solid #30363d", flexShrink: 0,
      }}>
        <span style={{ color: "#e6edf3", fontSize: "15px", fontWeight: 700 }}>3-Way Merge</span>
        {loaded && (
          <div style={{ display: "flex", gap: "12px", fontSize: "11px", color: "#8b949e" }}>
            <span style={{ color: "#3fb950" }}>{unchangedCount} unchanged</span>
            <span style={{ color: "#58a6ff" }}>{aOnlyCount} A-only</span>
            <span style={{ color: "#d29922" }}>{bOnlyCount} B-only</span>
            <span style={{ color: conflictCount > 0 ? "#f85149" : "#3fb950" }}>{conflictCount} conflicts</span>
          </div>
        )}
        <button type="button" onClick={onClose}
          style={{ background: "#da3633", border: "1px solid #f85149", color: "#fff",
            borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "12px" }}>
          Close
        </button>
      </div>

      {!loaded ? (
        <div style={{ flex: 1, overflowY: "auto", padding: "24px" }}>
          <div style={{ maxWidth: "600px", margin: "0 auto" }}>
            <p style={{ color: "#8b949e", fontSize: "13px", marginBottom: "24px" }}>
              Select three works to merge. The base is the common ancestor. Works A and B are the two divergent versions.
              After loading, you'll see a paragraph-level comparison with conflict resolution.
            </p>
            <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
              <WorkPicker label="Base (common ancestor)" works={otherWorks} value={baseWorkId} onSelect={setBaseWorkId} />
              <WorkPicker label="Work A (first divergent version)" works={otherWorks.filter((w) => w.work_id !== baseWorkId)} value={workAId} onSelect={setWorkAId} />
              <WorkPicker label="Work B (second divergent version)" works={otherWorks.filter((w) => w.work_id !== baseWorkId && w.work_id !== workAId)} value={workBId} onSelect={setWorkBId} />
            </div>
            <div style={{ marginTop: "24px" }}>
              <button type="button" onClick={handleLoad} disabled={!baseWorkId || !workAId || !workBId || loading}
                style={{
                  background: (!baseWorkId || !workAId || !workBId) ? "#21262d" : "#238636",
                  border: `1px solid ${(!baseWorkId || !workAId || !workBId) ? "#30363d" : "#2ea043"}`,
                  color: (!baseWorkId || !workAId || !workBId) ? "#484f58" : "#fff",
                  borderRadius: "6px", padding: "8px 20px", cursor: "pointer", fontSize: "13px", fontWeight: 600,
                }}>
                {loading ? "Loading..." : "Load Comparison"}
              </button>
              {error && <span style={{ marginLeft: "12px", color: "#f85149", fontSize: "12px" }}>{error}</span>}
            </div>
          </div>
        </div>
      ) : (
        <div style={{ flex: 1, display: "flex", minHeight: 0 }}>
          {/* Left: Conflict resolution */}
          <div style={{ flex: 1, overflowY: "auto", padding: "16px" }}>
            <div style={{ maxWidth: "800px", margin: "0 auto" }}>
              {segments.map((seg, i) => {
                const resolved = resolutions[i] || seg.resolution;
                const segStyle: React.CSSProperties = {
                  marginBottom: "8px", borderRadius: "6px", overflow: "hidden",
                  border: `1px solid ${
                    seg.type === "conflict" ? "rgba(248,81,73,0.3)" :
                    seg.type === "a_only" ? "rgba(88,166,255,0.2)" :
                    seg.type === "b_only" ? "rgba(210,153,22,0.2)" :
                    "rgba(63,185,80,0.15)"
                  }`,
                };

                return (
                  <div key={i} style={segStyle}>
                    {/* Type badge */}
                    <div style={{
                      padding: "4px 10px", fontSize: "10px", fontWeight: 600,
                      textTransform: "uppercase", letterSpacing: "0.05em",
                      background: seg.type === "conflict" ? "rgba(248,81,73,0.08)" :
                        seg.type === "a_only" ? "rgba(88,166,255,0.06)" :
                        seg.type === "b_only" ? "rgba(210,153,22,0.06)" :
                        "rgba(63,185,80,0.04)",
                      color: seg.type === "conflict" ? "#f85149" :
                        seg.type === "a_only" ? "#58a6ff" :
                        seg.type === "b_only" ? "#d29922" :
                        "#3fb950",
                      display: "flex", alignItems: "center", justifyContent: "space-between",
                    }}>
                      <span>
                        {seg.type === "unchanged" ? "Unchanged" :
                         seg.type === "both_same" ? "Both changed (same)" :
                         seg.type === "a_only" ? "Only in A" :
                         seg.type === "b_only" ? "Only in B" :
                         "Conflict"}
                      </span>
                      {seg.type === "conflict" && (
                        <div style={{ display: "flex", gap: "4px" }}>
                          <button type="button" onClick={() => setResolutions((r) => ({ ...r, [i]: "a" }))}
                            style={{
                              padding: "2px 8px", fontSize: "10px", borderRadius: "3px", cursor: "pointer",
                              background: resolved === "a" ? "#58a6ff" : "transparent",
                              border: `1px solid ${resolved === "a" ? "#58a6ff" : "#30363d"}`,
                              color: resolved === "a" ? "#fff" : "#8b949e",
                            }}>
                            A
                          </button>
                          <button type="button" onClick={() => setResolutions((r) => ({ ...r, [i]: "b" }))}
                            style={{
                              padding: "2px 8px", fontSize: "10px", borderRadius: "3px", cursor: "pointer",
                              background: resolved === "b" ? "#d29922" : "transparent",
                              border: `1px solid ${resolved === "b" ? "#d29922" : "#30363d"}`,
                              color: resolved === "b" ? "#fff" : "#8b949e",
                            }}>
                            B
                          </button>
                        </div>
                      )}
                    </div>
                    {/* Content */}
                    <div style={{ padding: "8px 12px", display: "grid", gridTemplateColumns: seg.type === "conflict" ? "1fr 1fr" : "1fr", gap: "8px" }}>
                      {seg.type === "conflict" ? (
                        <>
                          <div style={{
                            background: resolved === "a" ? "rgba(88,166,255,0.08)" : "transparent",
                            padding: "6px", borderRadius: "4px", fontSize: "12px",
                            fontFamily: "Source Serif 4, Georgia, serif", lineHeight: 1.6, color: "#c9d1d9",
                            border: resolved === "a" ? "1px solid rgba(88,166,255,0.3)" : "1px solid transparent",
                          }}>
                            <div style={{ fontSize: "9px", color: "#58a6ff", fontWeight: 600, marginBottom: "4px" }}>A</div>
                            {seg.aText}
                          </div>
                          <div style={{
                            background: resolved === "b" ? "rgba(210,153,22,0.08)" : "transparent",
                            padding: "6px", borderRadius: "4px", fontSize: "12px",
                            fontFamily: "Source Serif 4, Georgia, serif", lineHeight: 1.6, color: "#c9d1d9",
                            border: resolved === "b" ? "1px solid rgba(210,153,22,0.3)" : "1px solid transparent",
                          }}>
                            <div style={{ fontSize: "9px", color: "#d29922", fontWeight: 600, marginBottom: "4px" }}>B</div>
                            {seg.bText}
                          </div>
                        </>
                      ) : (
                        <div style={{ fontSize: "12px", fontFamily: "Source Serif 4, Georgia, serif", lineHeight: 1.6, color: "#8b949e" }}>
                          {seg.type === "b_only" ? seg.bText : seg.aText}
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Right: Merged preview */}
          <div style={{ width: "400px", borderLeft: "1px solid #30363d", display: "flex", flexDirection: "column", background: "#161b22" }}>
            <div style={{
              padding: "8px 12px", borderBottom: "1px solid #30363d",
              display: "flex", alignItems: "center", justifyContent: "space-between",
            }}>
              <span style={{ fontSize: "11px", fontWeight: 600, color: "#8b949e", textTransform: "uppercase", letterSpacing: "0.05em" }}>
                Merged Preview
              </span>
              <button type="button" onClick={handleMerge} disabled={merging}
                style={{
                  background: merging ? "#21262d" : "#238636",
                  border: `1px solid ${merging ? "#30363d" : "#2ea043"}`,
                  color: merging ? "#484f58" : "#fff",
                  borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "11px", fontWeight: 600,
                }}>
                {merging ? "Merging..." : "Create Merged Work"}
              </button>
            </div>
            <div style={{ flex: 1, overflowY: "auto", padding: "12px" }}>
              <div style={{ fontSize: "12px", fontFamily: "Source Serif 4, Georgia, serif", lineHeight: 1.6, color: "#c9d1d9", whiteSpace: "pre-wrap" }}>
                {mergedText}
              </div>
            </div>
            {error && (
              <div style={{ padding: "8px 12px", borderTop: "1px solid rgba(248,81,73,0.2)", color: "#f85149", fontSize: "11px" }}>
                {error}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
