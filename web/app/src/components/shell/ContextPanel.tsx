import type { AwarenessState, AttributionSpan, SpanRangePayload, LinkEntry, BacklinkEntry, CrossServerBacklinkPayload } from "../../api/crdt_sync";
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
  onDeleteLink?: (linkId: number) => void;
  onRetypeLink?: (linkId: number, typeId: number) => void;
  onCommentOnLink?: (linkId: number) => void;
  onRemoveTransclusion?: (sourceWorkId: number, charStart: number, charEnd: number) => void;
  pinnedKeys: Set<string>;
  onTogglePin: (key: string, pinned: boolean) => void;
  crossServerBacklinks?: CrossServerBacklinkPayload[];
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
        currentWorkId={props.currentWorkId}
        onNavigateToWork={props.onNavigateToWork}
        onDeleteLink={props.onDeleteLink}
        onRetypeLink={props.onRetypeLink}
        onCommentOnLink={props.onCommentOnLink}
        onRemoveTransclusion={props.onRemoveTransclusion}
        pinnedKeys={props.pinnedKeys}
        onTogglePin={props.onTogglePin}
        crossServerBacklinks={props.crossServerBacklinks}
      />
      <AttributionSection attributionSpans={props.attributionSpans} attributionLogStatus={props.attributionLogStatus} onOpenFullView={props.onOpenProvenance} onExportReport={props.onExportReport} onExportProvJson={props.onExportProvJson} currentWorkId={props.currentWorkId} documentLength={props.documentLength} />
    </div>
  );
}
