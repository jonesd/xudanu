import type { PendingTransclusion } from "../hooks/useTransclusion";

interface TransclusionBadgeProps {
  pending: PendingTransclusion;
  onPlace: (position: number) => void;
  onCancel: () => void;
}

export function TransclusionBadge({ pending, onCancel }: TransclusionBadgeProps) {
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
        <span className="transclusion-badge-hint">
          Click to place &middot; Esc to cancel
        </span>
        <button className="transclusion-badge-cancel" onClick={onCancel}>
          Cancel
        </button>
      </div>
    </div>
  );
}
