import { Component, type ReactNode } from "react";

interface Props {
  label?: string;
  children: ReactNode;
}

interface State {
  error: Error | null;
}

/**
 * Localized crash containment: one broken panel degrades to an error
 * card instead of unmounting the whole tree (which took the editor
 * AND the WebSocket down with it — the 0x5a3 provenance-cycle
 * crash). "Try again" resets the boundary and re-renders the panel.
 */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  render() {
    if (this.state.error) {
      return (
        <div
          style={{
            padding: 16,
            margin: 8,
            borderRadius: 8,
            border: "1px solid rgba(248,81,73,0.4)",
            background: "rgba(248,81,73,0.06)",
            fontSize: 12,
            color: "var(--text, #ccc)",
          }}
        >
          <div style={{ fontWeight: 600, color: "#f85149", marginBottom: 6 }}>
            The {this.props.label ?? "panel"} hit an error
          </div>
          <div style={{ fontFamily: "monospace", fontSize: 11, opacity: 0.8, marginBottom: 8, wordBreak: "break-word" }}>
            {this.state.error.message}
          </div>
          <div style={{ opacity: 0.7, marginBottom: 8 }}>
            The rest of the document is unaffected.
          </div>
          <button
            type="button"
            onClick={() => this.setState({ error: null })}
            style={{
              padding: "4px 12px",
              borderRadius: 6,
              border: "1px solid var(--border, #30363d)",
              background: "transparent",
              color: "var(--text, #ccc)",
              cursor: "pointer",
            }}
          >
            Try again
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}
