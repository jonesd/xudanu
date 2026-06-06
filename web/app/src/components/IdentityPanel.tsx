import { useState } from "react";
import type { WhoAmIEntry } from "../api/crdt_sync";

interface IdentityPanelProps {
  identity: WhoAmIEntry | null;
  connected: boolean;
  onLogin: (clubName: string, password: string) => Promise<void>;
  onLogout: () => void;
}

export function IdentityPanel({ identity, connected, onLogin, onLogout }: IdentityPanelProps) {
  const [mode, setMode] = useState<"closed" | "login">("closed");
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
        <a
          href="/auth/github"
          className="identity-btn identity-btn-oauth"
        >
          Sign in with GitHub
        </a>
        <a
          href="/auth/google"
          className="identity-btn identity-btn-oauth"
        >
          Sign in with Google
        </a>
        <button
          type="button"
          className="identity-btn identity-btn-secondary"
          disabled={!connected}
          onClick={() => { setMode("login"); setError(null); setLoading(false); }}
        >
          Password Sign In
        </button>
      </div>
    );
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      if (!clubName.trim()) { setError("Identity name required"); return; }
      if (!password) { setError("Password required"); return; }
      await onLogin(clubName.trim(), password);
      setMode("closed");
      setClubName("");
      setPassword("");
    } catch (err) {
      let msg = err instanceof Error ? err.message : String(err);
      if (msg.includes("club not found") || msg.includes("ClubNotFound")) {
        msg = `Identity "${clubName}" not found. Use GitHub or Google sign-in to create one.`;
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
          <span className="identity-form-title">Password Sign In</span>
          <button type="button" className="identity-form-close" onClick={() => setMode("closed")}>
            x
          </button>
        </div>
        <input
          type="text"
          placeholder="Identity name"
          value={clubName}
          onChange={(e) => setClubName(e.target.value)}
          className="identity-input"
          disabled={loading}
          autoFocus
        />
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
          {loading ? "..." : "Login"}
        </button>
        <p className="identity-hint">
          For existing password-based accounts only. New users: use GitHub or Google above.
        </p>
      </form>
    </div>
  );
}
