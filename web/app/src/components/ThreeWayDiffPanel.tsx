import { useState, useEffect, useCallback, useMemo } from "react";
import type { CrdtSyncClient, WorkListEntry } from "../api/crdt_sync";

interface DiffSeg {
  type: "common" | "added" | "removed";
  text: string;
}

function tokenize(text: string): string[] {
  return text.match(/\S+|\s+/g) || [text];
}

function computeDiff(textA: string, textB: string): DiffSeg[] {
  const a = tokenize(textA);
  const b = tokenize(textB);
  const m = a.length;
  const n = b.length;
  const dp: number[][] = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      dp[i][j] = a[i - 1] === b[j - 1]
        ? dp[i - 1][j - 1] + 1
        : Math.max(dp[i - 1][j], dp[i][j - 1]);
    }
  }
  const raw: DiffSeg[] = [];
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
  const merged: DiffSeg[] = [];
  for (const seg of raw) {
    const last = merged[merged.length - 1];
    if (last && last.type === seg.type) last.text += seg.text;
    else merged.push({ ...seg });
  }
  return merged;
}

interface DiffColumnProps {
  label: string;
  segments: DiffSeg[];
}

function DiffColumn({ label, segments }: DiffColumnProps) {
  return (
    <div style={{ flex: 1, overflowY: "auto", padding: "8px 12px", minWidth: 0 }}>
      <div
        style={{
          position: "sticky",
          top: 0,
          fontSize: 10,
          textTransform: "uppercase",
          letterSpacing: 1,
          color: "#888",
          background: "#fafafa",
          padding: "2px 6px",
          borderRadius: 3,
          display: "inline-block",
          marginBottom: 6,
          zIndex: 10,
        }}
      >
        {label}
      </div>
      <div
        style={{
          whiteSpace: "pre-wrap",
          fontFamily: "SF Mono, Fira Code, ui-monospace, monospace",
          fontSize: 12,
          lineHeight: 1.6,
          wordBreak: "break-word",
        }}
      >
        {segments.map((seg, i) => {
          if (seg.type === "added")
            return (
              <span key={i} style={{ background: "#e6ffed", color: "#1a7f37", borderRadius: 2 }}>
                {seg.text}
              </span>
            );
          if (seg.type === "removed")
            return (
              <span
                key={i}
                style={{
                  background: "#ffebe9",
                  color: "#d1242f",
                  textDecoration: "line-through",
                  borderRadius: 2,
                }}
              >
                {seg.text}
              </span>
            );
          return <span key={i} style={{ color: "#555" }}>{seg.text}</span>;
        })}
      </div>
    </div>
  );
}

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
    if (!client || !workAId) return;
    setLoading(true);
    loadText(workAId).then((t) => {
      setTextA(t);
      setLoading(false);
    });
  }, [client, workAId, loadText]);

  useEffect(() => {
    if (!client || !workBId) return;
    setLoading(true);
    loadText(workBId).then((t) => {
      setTextB(t);
      setLoading(false);
    });
  }, [client, workBId, loadText]);

  const diffA = useMemo(
    () => (baseText && textA ? computeDiff(baseText, textA) : []),
    [baseText, textA],
  );
  const diffB = useMemo(
    () => (baseText && textB ? computeDiff(baseText, textB) : []),
    [baseText, textB],
  );

  const baseSegments = useMemo(
    () => baseText ? [{ type: "common" as const, text: baseText }] : [],
    [baseText],
  );

  const ready = workAId !== null && workBId !== null && textA && textB && baseText;

  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,0.4)",
        zIndex: 200,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: "#fff",
          borderRadius: 8,
          width: "90vw",
          maxWidth: 1200,
          maxHeight: "85vh",
          display: "flex",
          flexDirection: "column",
          boxShadow: "0 4px 24px rgba(0,0,0,0.2)",
        }}
      >
        {/* Header */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 12,
            padding: "12px 16px",
            borderBottom: "1px solid #e0e0e0",
            flexShrink: 0,
          }}
        >
          <strong style={{ fontSize: 15 }}>Three-Way Diff</strong>
          <span style={{ color: "#888", fontSize: 12 }}>
            Base: {currentWorkId ? `0x${currentWorkId.toString(16)}` : "—"}
          </span>
          {!workAId ? (
            <select
              value=""
              onChange={(e) => setWorkAId(parseInt(e.target.value) || null)}
              style={{ fontSize: 12, padding: "2px 6px" }}
            >
              <option value="">— select A —</option>
              {otherWorks
                .filter((w) => w.work_id !== workBId)
                .map((w) => (
                  <option key={w.work_id} value={w.work_id}>
                    0x{w.work_id.toString(16).padStart(4, "0")} {w.title?.slice(0, 30)}
                  </option>
                ))}
            </select>
          ) : (
            <span style={{ fontSize: 12, color: "#1a73e8" }}>
              A: 0x{workAId.toString(16).padStart(4, "0")}{" "}
              <button
                type="button"
                onClick={() => {
                  setWorkAId(null);
                  setTextA("");
                }}
                style={{ border: "none", background: "none", cursor: "pointer", color: "#999" }}
              >
                ×
              </button>
            </span>
          )}
          {!workBId ? (
            <select
              value=""
              onChange={(e) => setWorkBId(parseInt(e.target.value) || null)}
              style={{ fontSize: 12, padding: "2px 6px" }}
            >
              <option value="">— select B —</option>
              {otherWorks
                .filter((w) => w.work_id !== workAId)
                .map((w) => (
                  <option key={w.work_id} value={w.work_id}>
                    0x{w.work_id.toString(16).padStart(4, "0")} {w.title?.slice(0, 30)}
                  </option>
                ))}
            </select>
          ) : (
            <span style={{ fontSize: 12, color: "#1a73e8" }}>
              B: 0x{workBId.toString(16).padStart(4, "0")}{" "}
              <button
                type="button"
                onClick={() => {
                  setWorkBId(null);
                  setTextB("");
                }}
                style={{ border: "none", background: "none", cursor: "pointer", color: "#999" }}
              >
                ×
              </button>
            </span>
          )}
          <div style={{ marginLeft: "auto", display: "flex", gap: 8, fontSize: 11, color: "#888" }}>
            <span style={{ background: "#e6ffed", color: "#1a7f37", padding: "0 3px", borderRadius: 2 }}>+added</span>
            <span style={{ background: "#ffebe9", color: "#d1242f", padding: "0 3px", borderRadius: 2, textDecoration: "line-through" }}>-removed</span>
          </div>
          <button
            type="button"
            onClick={onClose}
            style={{ border: "none", background: "none", fontSize: 18, cursor: "pointer", color: "#999" }}
          >
            ×
          </button>
        </div>

        {/* Body */}
        {loading ? (
          <div style={{ padding: 40, textAlign: "center", color: "#888" }}>Loading…</div>
        ) : ready ? (
          <div style={{ display: "flex", flex: 1, overflow: "hidden" }}>
            <DiffColumn
              label={`A: 0x${(workAId ?? 0).toString(16).padStart(4, "0")}`}
              segments={diffA}
            />
            <div style={{ width: 1, background: "#e0e0e0" }} />
            <DiffColumn label="Base (this work)" segments={baseSegments} />
            <div style={{ width: 1, background: "#e0e0e0" }} />
            <DiffColumn
              label={`B: 0x${(workBId ?? 0).toString(16).padStart(4, "0")}`}
              segments={diffB}
            />
          </div>
        ) : (
          <div style={{ padding: 40, textAlign: "center", color: "#888" }}>
            Select two documents to compare against this work as the base.
            <br />
            <span style={{ fontSize: 12 }}>
              The current work is the common ancestor (base). Changes in A and B are highlighted
              relative to it.
            </span>
          </div>
        )}
      </div>
    </div>
  );
}
