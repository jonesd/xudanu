import type { AwarenessState, AttributionSpan, SpanRangePayload, LinkEntry, BacklinkEntry } from "../../api/crdt_sync";
import { PresenceSection } from "../panels/PresenceSection";
import { DocuverseSection } from "../panels/DocuverseSection";
import { ConnectionsSection } from "../panels/ConnectionsSection";
import { AttributionSection } from "../panels/AttributionSection";

interface ContextPanelProps {
  awareness: AwarenessState[];
  attributionSpans: AttributionSpan[];
  attributionLogStatus: { entry_count: number; chain_valid: boolean; last_sequence: number; has_log: boolean } | null;
  transclusionLinks: LinkEntry[];
  backlinks: BacklinkEntry[];
  compoundSpanRanges: SpanRangePayload[];
  compoundSourceTitles: Record<number, string>;
  currentWorkId: number | null;
  documentLength: number;
  onNavigateToWork: (workId: number) => void;
  onOpenProvenance?: () => void;
  onExportReport?: () => void;
  onExportProvJson?: () => void;
  focusMode: boolean;
  onToggleFocus: () => void;
}

export function ContextPanel(props: ContextPanelProps) {
  return (
    <div className="context-panel">
      <PresenceSection awareness={props.awareness} />
      <DocuverseSection
        currentWorkId={props.currentWorkId}
        transclusionLinks={props.transclusionLinks}
        compoundSpanRanges={props.compoundSpanRanges}
        compoundSourceTitles={props.compoundSourceTitles}
        onNavigateToWork={props.onNavigateToWork}
      />
      <ConnectionsSection
        transclusionLinks={props.transclusionLinks}
        backlinks={props.backlinks}
        compoundSpanRanges={props.compoundSpanRanges}
        compoundSourceTitles={props.compoundSourceTitles}
        onNavigateToWork={props.onNavigateToWork}
      />
      <AttributionSection attributionSpans={props.attributionSpans} attributionLogStatus={props.attributionLogStatus} onOpenFullView={props.onOpenProvenance} onExportReport={props.onExportReport} onExportProvJson={props.onExportProvJson} currentWorkId={props.currentWorkId} documentLength={props.documentLength} />
    </div>
  );
}
