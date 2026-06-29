import { useState } from "react";

interface AuditTrailSectionProps {
  status: { entry_count: number; chain_valid: boolean; last_sequence: number; has_log: boolean } | null;
}

export function AuditTrailSection({ status }: AuditTrailSectionProps) {
  const [expanded, setExpanded] = useState(false);

  if (!status) return null;

  return (
    <div className="ctx-section">
      <div className="ctx-header" style={{ cursor: "pointer" }} onClick={() => setExpanded(!expanded)}>
        <div className="ctx-title">Audit Trail</div>
        <div className={`ctx-badge ${status.chain_valid ? "ok" : "amber"}`}>
          {status.chain_valid ? "valid" : "invalid"}
        </div>
      </div>
      {!expanded ? (
        <div style={{ fontSize: 11, color: "var(--text-muted)", lineHeight: 1.6 }}>
          <div>{status.entry_count} entries · seq #{status.last_sequence}</div>
          <div style={{ marginTop: 2 }}>SHA-256 + Ed25519 + BLAKE3</div>
          <div style={{ marginTop: 6, color: "var(--blue)", fontSize: 11, cursor: "pointer" }}>
            View details →
          </div>
        </div>
      ) : (
        <div>
          <div style={{ fontSize: 11, color: "var(--text-muted)", marginBottom: 8 }}>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6 }}>
              <div>
                <span style={{ color: "var(--text-dim)" }}>Entries</span>
                <br />
                <span style={{ fontWeight: 600, color: "var(--text)" }}>{status.entry_count}</span>
              </div>
              <div>
                <span style={{ color: "var(--text-dim)" }}>Sequence</span>
                <br />
                <span style={{ fontWeight: 600, color: "var(--text)" }}>#{status.last_sequence}</span>
              </div>
              <div>
                <span style={{ color: "var(--text-dim)" }}>Algorithm</span>
                <br />
                <span style={{ color: "var(--text)" }}>SHA-256</span>
              </div>
              <div>
                <span style={{ color: "var(--text-dim)" }}>Signatures</span>
                <br />
                <span style={{ color: "var(--text)" }}>Ed25519</span>
              </div>
            </div>
          </div>
          <div style={{ marginTop: 8, padding: 8, background: "var(--bg)", borderRadius: 6, fontSize: 10, color: "var(--text-dim)", lineHeight: 1.5 }}>
            Each entry: SHA-256(prev_hash + entry_json).
            Tamper-evident append-only log seeded from attribution.log.seed.
            Any modification breaks the chain hash.
          </div>
          <div style={{ marginTop: 6, color: "var(--blue)", fontSize: 11, cursor: "pointer" }} onClick={() => setExpanded(false)}>
            ← Back to summary
          </div>
        </div>
      )}
    </div>
  );
}
