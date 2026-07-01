import type { AwarenessState } from "../../api/crdt_sync";
import { authorColorPair } from "../../author-color";

interface PresenceSectionProps {
  awareness: AwarenessState[];
}

export function PresenceSection({ awareness }: PresenceSectionProps) {
  if (awareness.length === 0) return null;

  const byUser = new Map<string, { states: AwarenessState[]; typing: boolean }>();
  for (const state of awareness) {
    const name = state.user_name || "Anonymous";
    const existing = byUser.get(name);
    if (existing) {
      existing.states.push(state);
      if (state.is_typing) existing.typing = true;
    } else {
      byUser.set(name, { states: [state], typing: state.is_typing });
    }
  }

  const users = Array.from(byUser.entries()).map(([name, { states, typing }]) => ({
    name,
    typing,
    sessionCount: states.length,
    cursor: states.find((s) => s.cursor != null)?.cursor ?? null,
  }));

  return (
    <div className="ctx-section">
      <div className="ctx-header">
        <div className="ctx-title">Present</div>
        <div className="ctx-badge ok">{users.length}</div>
      </div>
      {users.map((user) => {
        const colors = authorColorPair(user.name);
        return (
          <div key={user.name} className="presence-row">
            <div className="presence-avatar" style={{ background: colors.primary }}>
              {user.name[0]?.toUpperCase() || "?"}
            </div>
            <span>{user.name}</span>
            {user.sessionCount > 1 && (
              <span className="presence-status" style={{ opacity: 0.5 }}>
                ({user.sessionCount})
              </span>
            )}
            <span className="presence-status">
              {user.typing ? "typing…" : user.cursor != null ? `¶ ${user.cursor.index}` : "viewing"}
            </span>
          </div>
        );
      })}
    </div>
  );
}
