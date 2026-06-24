import type { AwarenessState } from "../api/crdt_sync";
import { authorColor } from "../author-color";

interface AwarenessIndicatorsProps {
  states: AwarenessState[];
  connected: boolean;
}

export function AwarenessIndicators({ states, connected }: AwarenessIndicatorsProps) {
  const indicators = !connected
    ? [<span key="off" style={{ fontSize: "11px", opacity: 0.3 }}>Offline</span>]
    : states.length === 0
    ? [<span key="empty" style={{ fontSize: "11px", opacity: 0.3 }}>No other active users</span>]
    : states.map((state) => {
        const color = authorColor(state.user_name);
        return (
          <span
            key={state.session_id}
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
      });

  return (
    <div className="awareness-indicators">
      {indicators}
    </div>
  );
}
