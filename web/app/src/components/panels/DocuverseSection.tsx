import type { LinkEntry, SpanRangePayload } from "../../api/crdt_sync";

interface DocuverseSectionProps {
  currentWorkId: number | null;
  transclusionLinks: LinkEntry[];
  compoundSpanRanges: SpanRangePayload[];
  compoundSourceTitles: Record<number, string>;
  onNavigateToWork: (workId: number) => void;
}

export function DocuverseSection({
  currentWorkId,
  transclusionLinks,
  compoundSpanRanges,
  compoundSourceTitles,
  onNavigateToWork,
}: DocuverseSectionProps) {
  const transclCount = compoundSpanRanges.length;
  const linkCount = transclusionLinks.length;

  if (transclCount === 0 && linkCount === 0) return null;

  return (
    <div className="ctx-section">
      <div className="ctx-header">
        <div className="ctx-title">Docuverse</div>
        <div style={{ display: "flex", gap: 4 }}>
          {transclCount > 0 && <span className="ctx-badge amber">{transclCount} transcl.</span>}
          {linkCount > 0 && <span className="ctx-badge blue">{linkCount} link{linkCount !== 1 ? "s" : ""}</span>}
        </div>
      </div>
      <div>
        {currentWorkId && (
          <div className="docuverse-node">
            <div className="dv-dot current" />
            <span style={{ fontWeight: 600 }}>This document</span>
          </div>
        )}

        {compoundSpanRanges.map((sr, i) => (
          <div key={`tcl-${i}`}>
            <div className="dv-arrow" style={{ color: "var(--amber)" }}>↳ transcludes</div>
            <div
              className="docuverse-node"
              onClick={() => onNavigateToWork(sr.source_work_id)}
            >
              <div className="dv-dot" style={{ borderColor: "var(--amber)", background: "var(--amber)" }} />
              <span>{compoundSourceTitles[sr.source_work_id] || `work:${sr.source_work_id.toString(16)}`}</span>
            </div>
          </div>
        ))}

        {transclusionLinks
          .filter((link, idx, arr) => arr.findIndex((l) => l.link_id === link.link_id) === idx)
          .map((link) => {
          const isOrigin = link.origin === currentWorkId;
          const otherWorkId = isOrigin ? link.destination : link.origin;
          const otherTitle = (isOrigin ? link.destination_title : link.origin_title) || `work:${otherWorkId.toString(16)}`;
          return (
            <div key={`link-${link.link_id}`}>
              <div className="dv-arrow" style={{ color: "var(--blue)" }}>
                {isOrigin ? "↳ links to" : "↳ referenced by"}
              </div>
              <div className="docuverse-node" onClick={() => onNavigateToWork(otherWorkId)}>
                <div className="dv-dot" style={{ borderColor: "var(--blue)" }} />
                <span>{otherTitle}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
