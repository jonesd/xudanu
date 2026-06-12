import { useEffect, useState } from "react";
import type {
  CrdtSyncClient,
  WorkSummary as WorkSummaryData,
  WorkVersionTimeline,
  RevisionMeta,
  ReusedInDoc,
} from "../api/crdt_sync";

interface WorkSummaryPanelProps {
  clientRef: React.RefObject<CrdtSyncClient | null>;
  workBeId: number | null;
  connected: boolean;
  onClose: () => void;
  onNavigateToWork: (id: number) => void;
}

const TYPE_COLORS: Record<string, string> = {
  human: "#22c55e",
  llm: "#a855f7",
  historical: "#f59e0b",
  unattributed: "#6b7280",
};

const FALLBACK_COLORS = [
  "#4361ee",
  "#7209b7",
  "#f72585",
  "#4cc9f0",
  "#06d6a0",
  "#ffd166",
  "#ef476f",
  "#118ab2",
];

function authorColor(ac: { author_type: string | null }, i: number): string {
  const t = ac.author_type;
  if (t && TYPE_COLORS[t]) return TYPE_COLORS[t];
  return FALLBACK_COLORS[i % FALLBACK_COLORS.length];
}

function formatChars(n: number): string {
  if (n < 1000) return String(n);
  if (n < 1_000_000) return (n / 1000).toFixed(1) + "k";
  return (n / 1_000_000).toFixed(1) + "M";
}

export function WorkSummaryPanel({
  clientRef,
  workBeId,
  connected,
  onClose,
  onNavigateToWork,
}: WorkSummaryPanelProps) {
  const [summary, setSummary] = useState<WorkSummaryData | null>(null);
  const [timeline, setTimeline] = useState<WorkVersionTimeline | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!workBeId || !connected) return;
    const client = clientRef.current;
    if (!client) return;

    setLoading(true);
    setError(null);

    Promise.all([client.workSummary(workBeId), client.workVersionTimeline(workBeId)])
      .then(([s, t]) => {
        setSummary(s);
        setTimeline(t);
        setLoading(false);
      })
      .catch((e) => {
        setError(String(e));
        setLoading(false);
      });
  }, [workBeId, connected, clientRef]);

  if (!workBeId) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content summary-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>Work Summary</h3>
          <span className="modal-header-id">
            {"#" + workBeId.toString(16).padStart(4, "0")}
          </span>
          <button type="button" className="modal-close" onClick={onClose}>
            x
          </button>
        </div>

        {loading && (
          <div className="summary-loading">Loading...</div>
        )}

        {error && <div className="summary-error">{error}</div>}

        {summary && (
          <>
            <div className="summary-stats-grid">
              <div className="summary-stat-card" title="Number of revisions (including initial creation)">
                <div className="stat-value">{summary.version_count}</div>
                <div className="stat-label">Revisions</div>
              </div>
              <div className="summary-stat-card" title="Total characters in current version">
                <div className="stat-value">{formatChars(summary.char_count)}</div>
                <div className="stat-label">Characters</div>
              </div>
              <div className="summary-stat-card" title="Distinct authors who contributed content">
                <div className="stat-value">{summary.unique_authors}</div>
                <div className="stat-label">Authors</div>
              </div>
              <div className="summary-stat-card" title="Source documents whose content was transcluded into this work">
                <div className="stat-value">{summary.unique_sources}</div>
                <div className="stat-label">Sources</div>
              </div>
              <div className="summary-stat-card" title="Other documents that share content with this work">
                <div className="stat-value">{summary.reused_in_count}</div>
                <div className="stat-label">Shared With</div>
              </div>
            </div>

            {summary.author_contributions.length > 0 && (
              <div className="summary-section">
                <h4>Author Contributions</h4>
                <div className="summary-bar-track">
                  {summary.author_contributions.map((ac, i) => (
                    <div
                      key={ac.club_id}
                      className="summary-bar-segment"
                      style={{
                        width: `${ac.percentage}%`,
                        backgroundColor: authorColor(ac, i),
                      }}
                      title={`${ac.display_name}: ${ac.percentage.toFixed(1)}% (${formatChars(ac.char_count)} chars)`}
                    />
                  ))}
                </div>
                <ul className="summary-author-list">
                  {summary.author_contributions.map((ac, i) => (
                    <li key={ac.club_id} className="summary-author-item">
                      <span
                        className="summary-author-swatch"
                        style={{ backgroundColor: authorColor(ac, i) }}
                      />
                      <span className="summary-author-name">{ac.display_name}</span>
                      <span className="summary-author-pct">
                        {ac.percentage.toFixed(1)}%
                      </span>
                      <span className="summary-author-chars">
                        {formatChars(ac.char_count)} chars
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {summary.reused_in_docs.length > 0 && (
              <div className="summary-section">
                <h4>Shared With (content overlap)</h4>
                <ul className="summary-author-list">
                  {summary.reused_in_docs.map((doc: ReusedInDoc) => (
                    <li
                      key={doc.work_id}
                      className="summary-author-item summary-reused-in-item"
                      onClick={() => { onClose(); onNavigateToWork(doc.work_id); }}
                      title={`#${doc.work_id.toString(16).padStart(4, "0")} — ${formatChars(doc.shared_char_count)} shared chars — click to open`}
                    >
                      <span className="summary-author-swatch" style={{ backgroundColor: "#6366f1" }} />
                      <span className="summary-author-name">{doc.title || "#" + doc.work_id.toString(16).padStart(4, "0")}</span>
                      <span className="summary-author-chars">
                        {formatChars(doc.shared_char_count)} shared
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {timeline && timeline.revisions.length > 0 && (
              <div className="summary-section">
                <h4>Version Timeline</h4>
                <ul className="summary-timeline-list">
                  {timeline.revisions
                    .slice()
                    .reverse()
                    .map((rev: RevisionMeta) => {
                      const revType = rev.author_type || "unattributed";
                      const revColor = TYPE_COLORS[revType] || FALLBACK_COLORS[0];
                      return (
                        <li key={rev.revision} className="summary-timeline-entry">
                          <span className="timeline-rev">r{rev.revision}</span>
                          <span className="timeline-chars">
                            {formatChars(rev.char_count)} chars
                          </span>
                          <span
                            className="timeline-author"
                            style={{ color: revColor }}
                          >
                            {rev.author_display_name || "anonymous"}
                          </span>
                        </li>
                      );
                    })}
                </ul>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
