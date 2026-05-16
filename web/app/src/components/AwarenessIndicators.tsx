import type { AwarenessState } from "../api/crdt_sync";

interface AwarenessIndicatorsProps {
  states: AwarenessState[];
  connected: boolean;
}

const COLORS = [
  "#e06c75", "#61afef", "#98c379", "#c678dd", "#e5c07b",
  "#56b6c2", "#d19a66", "#be5046",
];

function userColor(index: number): string {
  return COLORS[index % COLORS.length];
}

export function AwarenessIndicators({ states, connected }: AwarenessIndicatorsProps) {
  if (!connected && states.length === 0) return null;

  return (
    <div className="awareness-indicators">
      {states.map((state, i) => (
        <span
          key={state.session_id}
          className="awareness-user"
          style={{ borderColor: userColor(i) }}
          title={`${state.user_name}${state.is_typing ? " (typing)" : ""}`}
        >
          <span
            className="awareness-dot"
            style={{ backgroundColor: userColor(i) }}
          />
          {state.user_name}
          {state.is_typing && <span className="awareness-typing">...</span>}
        </span>
      ))}
    </div>
  );
}
