import type { AwarenessState } from "../api/crdt_sync";
import { authorColorPair, gradientCss } from "../author-color";

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
          const pair = authorColorPair(state.user_name);
          return (
            <span
              key={state.user_name}
              className="awareness-user"
              title={`${state.user_name}${state.is_typing ? " (typing)" : ""}`}
            >
              <span
                className="awareness-pulse"
                style={{ background: gradientCss(pair) }}
              />
              <span
                className="awareness-name"
                style={{
                  background: gradientCss(pair),
                  color: "#fff",
                }}
              >
                {state.user_name}
              </span>
              {state.is_typing && <span className="awareness-typing">...</span>}
            </span>
          );
        })
      )}
    </div>
  );
}
