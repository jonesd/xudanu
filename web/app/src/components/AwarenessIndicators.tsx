import type { AwarenessState } from "../api/crdt_sync";
import { authorColor } from "../author-color";

interface AwarenessIndicatorsProps {
  states: AwarenessState[];
  connected: boolean;
}

export function AwarenessIndicators({ states, connected }: AwarenessIndicatorsProps) {
  if (!connected) {
    return (
      <div className="awareness-indicators">
        <span style={{ fontSize: "11px", opacity: 0.3 }}>Offline</span>
      </div>
    );
  }

  // Deduplicate by user name — same user with multiple sessions shows once
  const seen = new Set<string>();
  const uniqueStates = states.filter((s) => {
    if (seen.has(s.user_name)) return false;
    seen.add(s.user_name);
    return true;
  });

  return (
    <div className="awareness-indicators">
      {uniqueStates.length === 0 ? (
        <span style={{ fontSize: "11px", opacity: 0.3 }}>No other active users</span>
      ) : (
        uniqueStates.map((state) => {
          const color = authorColor(state.user_name);
          return (
            <span
              key={state.user_name}
              className="awareness-user"
              title={`${state.user_name}${state.is_typing ? " (typing)" : ""}`}
            >
              <span
                className="awareness-pulse"
                style={{ backgroundColor: color, color }}
              />
              {state.user_name}
              {state.is_typing && <span className="awareness-typing">...</span>}
            </span>
          );
        })
      )}
    </div>
  );
}
