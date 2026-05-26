import { useState } from "react";
import type { WhoAmIEntry } from "../api/crdt_sync";

interface IdentityPanelProps {
  identity: WhoAmIEntry | null;
  connected: boolean;
  onCreateIdentity: (displayName: string, password: string) => Promise<void>;
  onLogin: (clubName: string, password: string) => Promise<void>;
  onLogout: () => void;
}

export function IdentityPanel({ identity, connected, onCreateIdentity, onLogin, onLogout }: IdentityPanelProps) {
  const [mode, setMode] = useState<"closed" | "create" | "login">("closed");
  const [displayName, setDisplayName] = useState("");
  const [clubName, setClubName] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  if (identity) {
    const clubHex = identity.club_id.toString(16).padStart(4, "0");
    return (
      <div className="identity-panel identity-logged-in">
        <span className="identity-name">{identity.display_name}</span>
        <span className="identity-id">#{clubHex}</span>
        <span className="identity-badge identity-verified">verified</span>
        <button type="button" className="identity-logout" onClick={onLogout}>Sign Out</button>
      </div>
    );
  }

  if (mode === "closed") {
    return (
      <div className="identity-panel identity-actions">
        <button
          type="button"
          className="identity-btn identity-btn-secondary"
          disabled={!connected}
          onClick={() => { setMode("login"); setError(null); setLoading(false); }}
        >
          Sign In
        </button>
        <button
          type="button"
          className="identity-btn"
          disabled={!connected}
          onClick={() => { setMode("create"); setError(null); setLoading(false); }}
        >
          New Identity
        </button>
      </div>
    );
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      if (mode === "create") {
        if (!displayName.trim()) { setError("Display name required"); return; }
        if (password.length < 8) { setError("Password must be at least 8 characters"); return; }
        await onCreateIdentity(displayName.trim(), password);
      } else {
        if (!clubName.trim()) { setError("Identity name required"); return; }
        if (!password) { setError("Password required"); return; }
        await onLogin(clubName.trim(), password);
      }
      setMode("closed");
      setDisplayName("");
      setClubName("");
      setPassword("");
    } catch (err) {
      let msg = err instanceof Error ? err.message : String(err);
      if (msg.includes("already taken") || msg.includes("already exists")) {
        msg = `Name "${mode === "create" ? displayName : clubName}" already exists. Use "Sign In" instead.`;
      }
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="identity-panel identity-form-container">
      <form onSubmit={handleSubmit} className="identity-form">
        <div className="identity-form-header">
          <span className="identity-form-title">
            {mode === "create" ? "Create Identity" : "Login"}
          </span>
          <button type="button" className="identity-form-close" onClick={() => setMode("closed")}>
            x
          </button>
        </div>
        {mode === "create" && (
          <input
            type="text"
            placeholder="Display name"
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
            className="identity-input"
            disabled={loading}
            autoFocus
          />
        )}
        {mode === "login" && (
          <input
            type="text"
            placeholder="Identity name"
            value={clubName}
            onChange={(e) => setClubName(e.target.value)}
            className="identity-input"
            disabled={loading}
            autoFocus
          />
        )}
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="identity-input"
          disabled={loading}
        />
        {error && <div className="identity-error">{error}</div>}
        <button type="submit" className="identity-submit" disabled={loading || !connected}>
          {loading ? "..." : mode === "create" ? "Create" : "Login"}
        </button>
        {mode === "create" && (
          <p className="identity-hint">
            Creates a cryptographic identity with Ed25519 signing key.
            Your edits will be signed and attributed to you.
          </p>
        )}
      </form>
    </div>
  );
}
