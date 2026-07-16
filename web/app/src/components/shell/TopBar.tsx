import { Logo } from "../../logo";

interface TopBarProps {
  connected: boolean;
  identityName: string | null;
  identityColor: string;
  writeMode: boolean;
  canEdit: boolean;
  onToggleWrite: () => void;
  onOpenSearch: () => void;
  onOpenIdentity: () => void;
  onOpenAdmin: () => void;
  isAdmin: boolean;
}

export function TopBar({
  connected,
  identityName,
  identityColor,
  writeMode,
  canEdit,
  onToggleWrite,
  onOpenSearch,
  onOpenIdentity,
  onOpenAdmin,
  isAdmin,
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
          onClick={canEdit ? onToggleWrite : undefined}
          disabled={!canEdit}
          title={canEdit ? "Toggle read/write mode" : "You don't have edit access to this document"}
          style={canEdit ? {} : { opacity: 0.4, cursor: "not-allowed" }}
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M12 20h9" />
            <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z" />
          </svg>
          {writeMode ? "Writing" : "Read"}
        </button>
        <div className="connection-dot" title={connected ? "Connected" : "Offline"} style={connected ? {} : { background: "var(--red)" }} />
        {isAdmin && (
          <button
            onClick={onOpenAdmin}
            title="Admin Dashboard"
            style={{ background: "none", border: "1px solid var(--border)", color: "var(--text-muted)", borderRadius: "4px", padding: "3px 8px", cursor: "pointer", fontSize: "11px", fontFamily: "Inter, sans-serif", display: "flex", alignItems: "center", gap: "4px" }}
          >
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20z" />
              <path d="M12 16v-4M12 8h.01" />
            </svg>
            Admin
          </button>
        )}
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
