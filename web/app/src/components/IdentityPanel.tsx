import { useState } from "react";
import type { WhoAmIEntry } from "../api/crdt_sync";

interface IdentityPanelProps {
  identity: WhoAmIEntry | null;
  connected: boolean;
  onLogin: (clubName: string, password: string) => Promise<void>;
  onCreateIdentity: (displayName: string, password: string) => Promise<void>;
  onLogout: () => void;
}

export function IdentityPanel({ identity, connected, onLogin, onCreateIdentity, onLogout }: IdentityPanelProps) {
  const [mode, setMode] = useState<"closed" | "login" | "create">("closed");
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
          className="identity-btn identity-btn-primary"
          disabled={!connected}
          onClick={() => { setMode("create"); setError(null); setLoading(false); }}
        >
          Create Identity
        </button>
        <button
          type="button"
          className="identity-btn identity-btn-secondary"
          disabled={!connected}
          onClick={() => { setMode("login"); setError(null); setLoading(false); }}
        >
          Sign In
        </button>
      </div>
    );
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      if (!clubName.trim()) { setError("Name required"); return; }
      if (!password || password.length < 8) { setError("Password must be at least 8 characters"); return; }
      if (mode === "create") {
        await onCreateIdentity(clubName.trim(), password);
      } else {
        await onLogin(clubName.trim(), password);
      }
      setMode("closed");
      setClubName("");
      setPassword("");
    } catch (err) {
      let msg = err instanceof Error ? err.message : String(err);
      if (msg.includes("club not found") || msg.includes("ClubNotFound")) {
        msg = `Identity "${clubName}" not found.`;
      }
      if (msg.includes("already exists") || msg.includes("AlreadyExists")) {
        msg = `Name "${clubName}" is taken. Try another.`;
      }
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const isCreate = mode === "create";

  return (
    <div className="identity-panel identity-form-container">
      <form onSubmit={handleSubmit} className="identity-form">
        <div className="identity-form-header">
          <span className="identity-form-title">{isCreate ? "Create Identity" : "Sign In"}</span>
          <button type="button" className="identity-form-close" onClick={() => setMode("closed")}>
            x
          </button>
        </div>
        <input
          type="text"
          placeholder={isCreate ? "Display name" : "Identity name"}
          value={clubName}
          onChange={(e) => setClubName(e.target.value)}
          className="identity-input"
          disabled={loading}
          autoFocus
        />
        <input
          type="password"
          placeholder="Password (min 8 chars)"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="identity-input"
          disabled={loading}
        />
        {error && <div className="identity-error">{error}</div>}
        <button type="submit" className="identity-submit" disabled={loading || !connected}>
          {loading ? "..." : isCreate ? "Create" : "Sign In"}
        </button>
        <p className="identity-hint">
          {isCreate ? (
            <>Already have an identity? <button type="button" className="identity-link" onClick={() => { setMode("login"); setError(null); }}>Sign in</button></>
          ) : (
            <>No identity yet? <button type="button" className="identity-link" onClick={() => { setMode("create"); setError(null); }}>Create one</button></>
          )}
        </p>
      </form>
    </div>
  );
}
