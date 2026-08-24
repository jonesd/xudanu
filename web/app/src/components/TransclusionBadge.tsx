import { useState } from "react";
import type { PendingTransclusion } from "../hooks/useTransclusion";

interface RecentWork {
  work_id: number;
  title: string;
}

interface TransclusionBadgeProps {
  pending: PendingTransclusion;
  cursorPosition: number | null;
  onPlace: (position: number, padding?: string) => void;
  onPlacePinned: (position: number) => void;
  onCancel: () => void;
  onSwitchWork?: (workId: number) => void;
  onPlaceAtEnd?: () => void;
  recentWorks?: RecentWork[];
}

export function TransclusionBadge({
  pending,
  cursorPosition,
  onPlace,
  onPlacePinned,
  onCancel,
  onSwitchWork,
  onPlaceAtEnd,
  recentWorks,
}: TransclusionBadgeProps) {
  const [pickerOpen, setPickerOpen] = useState(false);
  const preview =
    pending.text.length > 80
      ? pending.text.slice(0, 80) + "\u2026"
      : pending.text;

  const candidates = (recentWorks ?? []).filter(
    (w) => w.work_id !== pending.sourceWorkId,
  );

  return (
    <div className="transclusion-badge">
      <div className="transclusion-badge-info">
        <span className="transclusion-badge-icon">&#x1f517;</span>
        <span className="transclusion-badge-label">
          Transcluding from: <strong>{pending.sourceWorkTitle}</strong>
        </span>
        <span className="transclusion-badge-preview">&ldquo;{preview}&rdquo;</span>
      </div>
      <div className="transclusion-badge-actions">
        {cursorPosition !== null && (
          <>
            <button
              className="transclusion-badge-place"
              onClick={() => onPlace(cursorPosition)}
              title="Live link: keeps following the source document (updates when the source is edited)"
            >
              Live link
            </button>
            <button
              className="transclusion-badge-place transclusion-badge-place-pinned"
              onClick={() => onPlacePinned(cursorPosition)}
              title="Pinned quotation: freezes this passage at its current revision (immune to later source edits)"
            >
              Pinned quote
            </button>
          </>
        )}
        {onPlaceAtEnd && (
          <button
            className="transclusion-badge-place transclusion-badge-place-end"
            onClick={() => onPlaceAtEnd()}
            title="Append the quotation after the last line of this document (adds a blank line first)"
          >
            Append to end
          </button>
        )}
        <span className="transclusion-badge-hint">
          or click in editor &middot; Esc to cancel
        </span>
        {onSwitchWork && candidates.length > 0 && (
          <span className="transclusion-badge-picker-wrap">
            <button
              className="transclusion-badge-switch"
              onClick={() => setPickerOpen((v) => !v)}
              title="Switch to another document and place the quote there"
            >
              Place in&hellip;
            </button>
            {pickerOpen && (
              <div className="transclusion-badge-picker" role="menu">
                <div className="transclusion-badge-picker-title">
                  Switch document, then click to place
                </div>
                {candidates.slice(0, 8).map((w) => (
                  <button
                    key={w.work_id}
                    className="transclusion-badge-picker-item"
                    onClick={() => {
                      setPickerOpen(false);
                      onSwitchWork(w.work_id);
                    }}
                    title={`Open "${w.title}" and place the quote there`}
                  >
                    {w.title?.trim() || `Untitled 0x${w.work_id.toString(16)}`}
                  </button>
                ))}
              </div>
            )}
          </span>
        )}
        <button className="transclusion-badge-cancel" onClick={onCancel}>
          Cancel
        </button>
      </div>
    </div>
  );
}
