import type { SuggestionCardPayload } from "../api/crdt_sync";

interface SuggestionCardListProps {
  cards: SuggestionCardPayload[];
  onAccept: (card: SuggestionCardPayload) => void;
  onDismiss: (workId: number) => void;
  busy?: boolean;
}

export function SuggestionCardList({ cards, onAccept, onDismiss, busy }: SuggestionCardListProps) {
  if (cards.length === 0) return null;
  const top = cards[0];
  return (
    <div
      style={{
        position: "absolute",
        right: 16,
        bottom: 16,
        maxWidth: 320,
        background: "rgba(22, 27, 34, 0.97)",
        border: "1px solid #39d2c0",
        borderRadius: 10,
        padding: "10px 12px",
        zIndex: 40,
        boxShadow: "0 4px 18px rgba(0,0,0,0.45)",
        fontFamily: "inherit",
      }}
      data-testid="reuse-suggestion-card"
    >
      <div style={{ fontSize: 10, letterSpacing: 1, color: "#39d2c0", textTransform: "uppercase", marginBottom: 4 }}>
        Exists elsewhere
      </div>
      <div style={{ fontSize: 13, color: "#e6edf3", fontWeight: 600, marginBottom: 4 }}>
        {top.title || `Work ${top.work_id}`}
      </div>
      <div style={{ fontSize: 12, color: "#8b949e", marginBottom: 8, maxHeight: 54, overflow: "hidden" }}>
        {top.snippet}
      </div>
      <div style={{ display: "flex", gap: 8 }}>
        <button
          type="button"
          disabled={busy}
          onClick={() => onAccept(top)}
          style={{
            fontSize: 12,
            padding: "4px 10px",
            borderRadius: 6,
            border: "1px solid #39d2c0",
            background: "rgba(57,210,192,0.12)",
            color: "#39d2c0",
            cursor: busy ? "default" : "pointer",
          }}
        >
          Insert as transclusion
        </button>
        <button
          type="button"
          onClick={() => onDismiss(top.work_id)}
          style={{
            fontSize: 12,
            padding: "4px 10px",
            borderRadius: 6,
            border: "1px solid #30363d",
            background: "transparent",
            color: "#8b949e",
            cursor: "pointer",
          }}
        >
          Dismiss
        </button>
      </div>
    </div>
  );
}
