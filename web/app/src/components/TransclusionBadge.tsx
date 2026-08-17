import type { PendingTransclusion } from "../hooks/useTransclusion";

interface TransclusionBadgeProps {
  pending: PendingTransclusion;
  cursorPosition: number | null;
  onPlace: (position: number, padding?: string) => void;
  onPlacePinned: (position: number) => void;
  onCancel: () => void;
}

export function TransclusionBadge({ pending, cursorPosition, onPlace, onPlacePinned, onCancel }: TransclusionBadgeProps) {
  const preview =
    pending.text.length > 80
      ? pending.text.slice(0, 80) + "\u2026"
      : pending.text;

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
        <span className="transclusion-badge-hint">
          or click in editor &middot; Esc to cancel
        </span>
        <button className="transclusion-badge-cancel" onClick={onCancel}>
          Cancel
        </button>
      </div>
    </div>
  );
}
