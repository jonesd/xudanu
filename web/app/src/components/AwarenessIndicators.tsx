import type { AwarenessState } from "../api/crdt_sync";
import { authorColor } from "../author-color";

interface AwarenessIndicatorsProps {
  states: AwarenessState[];
  connected: boolean;
}

export function AwarenessIndicators({ states, connected }: AwarenessIndicatorsProps) {
  if (!connected && states.length === 0) return null;

  return (
    <div className="awareness-indicators">
      {states.map((state) => {
        const color = authorColor(state.user_name);
        return (
          <span
            key={state.session_id}
            className="awareness-user"
            style={{ borderColor: color }}
            title={`${state.user_name}${state.is_typing ? " (typing)" : ""}`}
          >
            <span
              className="awareness-dot"
              style={{ backgroundColor: color }}
            />
            {state.user_name}
            {state.is_typing && <span className="awareness-typing">...</span>}
          </span>
        );
      })}
    </div>
  );
}
