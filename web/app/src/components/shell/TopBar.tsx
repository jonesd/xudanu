import { Logo } from "../../logo";

interface TopBarProps {
  connected: boolean;
  identityName: string | null;
  identityColor: string;
  writeMode: boolean;
  onToggleWrite: () => void;
  onOpenSearch: () => void;
  onOpenIdentity: () => void;
}

export function TopBar({
  connected,
  identityName,
  identityColor,
  writeMode,
  onToggleWrite,
  onOpenSearch,
  onOpenIdentity,
}: TopBarProps) {
  return (
    <div className="top-bar">
      <div className="top-bar-brand">
        <Logo size={18} />
        <span>xudanu</span>
      </div>
      <div className="search-trigger" onClick={onOpenSearch}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="11" cy="11" r="8" />
          <path d="m21 21-4.3-4.3" />
        </svg>
        Search the docuverse…
        <kbd>⌘K</kbd>
      </div>
      <div className="top-bar-actions">
        <button
          className={`write-toggle ${writeMode ? "active" : ""}`}
          onClick={onToggleWrite}
          title="Toggle read/write mode"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M12 20h9" />
            <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z" />
          </svg>
          {writeMode ? "Writing" : "Read"}
        </button>
        <div className="connection-dot" title={connected ? "Connected" : "Offline"} style={connected ? {} : { background: "var(--red)" }} />
        <div className="identity-badge" onClick={onOpenIdentity}>
          <div className="identity-avatar" style={{ background: identityColor }}>
            {identityName ? identityName[0].toUpperCase() : "?"}
          </div>
          <span className="identity-name">{identityName || "Anonymous"}</span>
        </div>
      </div>
    </div>
  );
}
