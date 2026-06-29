import type { AwarenessState } from "../../api/crdt_sync";
import { authorColorPair } from "../../author-color";

interface PresenceSectionProps {
  awareness: AwarenessState[];
}

export function PresenceSection({ awareness }: PresenceSectionProps) {
  if (awareness.length === 0) return null;

  return (
    <div className="ctx-section">
      <div className="ctx-header">
        <div className="ctx-title">Present</div>
        <div className="ctx-badge ok">{awareness.length}</div>
      </div>
      {awareness.map((state) => {
        const name = state.user_name || "Anonymous";
        const colors = authorColorPair(name);
        return (
          <div key={state.session_id} className="presence-row">
            <div className="presence-avatar" style={{ background: colors.primary }}>
              {name[0]?.toUpperCase() || "?"}
            </div>
            <span>{name}</span>
            <span className="presence-status">
              {state.is_typing ? "typing…" : state.cursor != null ? `¶ ${state.cursor}` : "viewing"}
            </span>
          </div>
        );
      })}
    </div>
  );
}
