import { useState, useCallback } from "react";
import type { CrdtSyncClient, WorkListEntry } from "../api/crdt_sync";

interface MergePanelProps {
  client: CrdtSyncClient | null;
  currentWorkId: number;
  works: WorkListEntry[];
  onClose: () => void;
  onMerged: (newWorkId: number) => void;
}

export function MergePanel({ client, currentWorkId, works, onClose, onMerged }: MergePanelProps) {
  const [baseWorkId, setBaseWorkId] = useState<number | null>(null);
  const [workAId, setWorkAId] = useState<number | null>(null);
  const [workBId, setWorkBId] = useState<number | null>(null);
  const [merging, setMerging] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const otherWorks = works.filter((w) => w.work_id !== currentWorkId);

  const handleMerge = useCallback(async () => {
    if (!client || !baseWorkId || !workAId || !workBId) return;
    setMerging(true);
    setError(null);
    setResult(null);
    try {
      const newWorkId = await client.workMerge(baseWorkId, workAId, workBId);
      setResult(`Merge complete. New work: 0x${newWorkId.toString(16).padStart(4, "0")}`);
      onMerged(newWorkId);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Merge failed");
    } finally {
      setMerging(false);
    }
  }, [client, baseWorkId, workAId, workBId, onMerged]);

  const selectStyle = {
    width: "100%",
    background: "#1c1c26",
    border: "1px solid #30363d",
    color: "#c9d1d9",
    borderRadius: "4px",
    padding: "6px 8px",
    fontSize: "12px",
    fontFamily: "Inter, sans-serif",
  };

  const labelStyle = {
    fontSize: "11px",
    fontWeight: 600,
    color: "#8b949e",
    marginBottom: "4px",
    fontFamily: "Inter, sans-serif",
    textTransform: "uppercase" as const,
    letterSpacing: "0.05em",
  };

  const canMerge = baseWorkId !== null && workAId !== null && workBId !== null && !merging;

  return (
    <div style={{
      position: "fixed", inset: 0, zIndex: 100, background: "#0d1117",
      display: "flex", flexDirection: "column",
    }}>
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 16px", height: "48px", background: "#161b22", borderBottom: "1px solid #30363d",
      }}>
        <span style={{ color: "#e6edf3", fontSize: "15px", fontWeight: 700 }}>3-Way Merge</span>
        <button type="button" onClick={onClose}
          style={{ background: "#da3633", border: "1px solid #f85149", color: "#fff",
            borderRadius: "4px", padding: "4px 12px", cursor: "pointer", fontSize: "12px" }}>
          Close
        </button>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "24px" }}>
        <div style={{ maxWidth: "600px", margin: "0 auto" }}>
          <p style={{ color: "#8b949e", fontSize: "13px", marginBottom: "24px" }}>
            Select three works to merge. The base is the common ancestor. Works A and B are the two divergent versions.
            The backend uses element-level fingerprint alignment for optimal merge quality.
          </p>

          <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
            <div>
              <div style={labelStyle}>Base (common ancestor)</div>
              <select style={selectStyle} value={baseWorkId ?? ""} onChange={(e) => setBaseWorkId(e.target.value ? Number(e.target.value) : null)}>
                <option value="">Select base work...</option>
                {otherWorks.map((w) => (
                  <option key={w.work_id} value={w.work_id}>
                    {w.title || "Untitled"} (0x{w.work_id.toString(16).padStart(4, "0")})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <div style={labelStyle}>Work A (first divergent version)</div>
              <select style={selectStyle} value={workAId ?? ""} onChange={(e) => setWorkAId(e.target.value ? Number(e.target.value) : null)}>
                <option value="">Select work A...</option>
                {otherWorks.filter((w) => w.work_id !== baseWorkId).map((w) => (
                  <option key={w.work_id} value={w.work_id}>
                    {w.title || "Untitled"} (0x{w.work_id.toString(16).padStart(4, "0")})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <div style={labelStyle}>Work B (second divergent version)</div>
              <select style={selectStyle} value={workBId ?? ""} onChange={(e) => setWorkBId(e.target.value ? Number(e.target.value) : null)}>
                <option value="">Select work B...</option>
                {otherWorks.filter((w) => w.work_id !== baseWorkId && w.work_id !== workAId).map((w) => (
                  <option key={w.work_id} value={w.work_id}>
                    {w.title || "Untitled"} (0x{w.work_id.toString(16).padStart(4, "0")})
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div style={{ marginTop: "24px", display: "flex", gap: "12px", alignItems: "center" }}>
            <button type="button" onClick={handleMerge} disabled={!canMerge}
              style={{
                background: canMerge ? "#238636" : "#21262d",
                border: `1px solid ${canMerge ? "#2ea043" : "#30363d"}`,
                color: canMerge ? "#fff" : "#484f58",
                borderRadius: "6px", padding: "8px 20px", cursor: canMerge ? "pointer" : "not-allowed",
                fontSize: "13px", fontWeight: 600,
              }}>
              {merging ? "Merging..." : "Merge"}
            </button>

            {error && (
              <div style={{
                padding: "8px 12px", background: "rgba(248,81,73,0.08)",
                border: "1px solid rgba(248,81,73,0.3)", borderRadius: "6px",
                color: "#f85149", fontSize: "12px",
              }}>
                {error}
              </div>
            )}

            {result && (
              <div style={{
                padding: "8px 12px", background: "rgba(63,185,80,0.08)",
                border: "1px solid rgba(63,185,80,0.3)", borderRadius: "6px",
                color: "#3fb950", fontSize: "12px",
              }}>
                {result}
              </div>
            )}
          </div>

          <div style={{ marginTop: "32px", padding: "16px", background: "#161b22", border: "1px solid #21262d", borderRadius: "8px" }}>
            <div style={{ fontSize: "12px", color: "#8b949e", fontWeight: 600, marginBottom: "8px" }}>How it works</div>
            <ol style={{ margin: 0, paddingLeft: "20px", color: "#8b949e", fontSize: "12px", lineHeight: 1.6 }}>
              <li>Backend aligns elements via BLAKE3 content fingerprints</li>
              <li>Elements present in both A and B: kept (no conflict)</li>
              <li>Elements only in A or only in B: included (no conflict)</li>
              <li>Elements changed differently: resolved by LastWriterWins strategy</li>
              <li>Merged work gets DerivationMethod::Merge provenance stamp</li>
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
}
