import { useState } from "react";
import type { WhoAmIEntry } from "../api/crdt_sync";

interface IdentityPanelProps {
  identity: WhoAmIEntry | null;
  connected: boolean;
  onLogin: (clubName: string, password: string) => Promise<void>;
  onCreateIdentity: (displayName: string, password: string) => Promise<void>;
  onLogout: () => void;
}

const MIN_PASSWORD_LENGTH = 10;

export function validatePassword(pw: string): string | null {
  if (pw.length < MIN_PASSWORD_LENGTH) return `At least ${MIN_PASSWORD_LENGTH} characters`;
  if (!/[A-Z]/.test(pw)) return "Include at least one uppercase letter";
  if (!/[a-z]/.test(pw)) return "Include at least one lowercase letter";
  if (!/[0-9]/.test(pw)) return "Include at least one digit";
  return null;
}

export function passwordStrength(pw: string): { score: number; label: string; color: string } {
  if (!pw) return { score: 0, label: "", color: "#ccc" };
  let score = 0;
  if (pw.length >= MIN_PASSWORD_LENGTH) score++;
  if (pw.length >= 16) score++;
  if (/[A-Z]/.test(pw) && /[a-z]/.test(pw)) score++;
  if (/[0-9]/.test(pw)) score++;
  if (/[^A-Za-z0-9]/.test(pw)) score++;
  if (score <= 1) return { score, label: "Weak", color: "#e74c3c" };
  if (score <= 3) return { score, label: "Fair", color: "#f39c12" };
  return { score, label: "Strong", color: "#27ae60" };
}

export function IdentityPanel({ identity, connected, onLogin, onCreateIdentity, onLogout }: IdentityPanelProps) {
  const [mode, setMode] = useState<"closed" | "login" | "create">("closed");
  const [clubName, setClubName] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  if (identity) {
    const clubHex = identity.club_id.toString(16).padStart(4, "0");
    return (
      <div className="identity-panel identity-logged-in">
        <span className="identity-name">{identity.display_name}</span>
        <span className="identity-id">#{clubHex}</span>
        <span
          className="identity-badge identity-verified"
          title="Cryptographically verified identity"
          style={{ display: "inline-flex", alignItems: "center", gap: "2px" }}
        >
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="20 6 9 17 4 12" />
          </svg>
        </span>
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
          onClick={() => { setMode("create"); setError(null); setLoading(false); setShowPassword(true); }}
        >
          Create Identity
        </button>
        <button
          type="button"
          className="identity-btn identity-btn-secondary"
          disabled={!connected}
          onClick={() => { setMode("login"); setError(null); setLoading(false); setShowPassword(false); }}
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
      if (mode === "create") {
        const pwError = validatePassword(password);
        if (pwError) { setError(pwError); return; }
        await onCreateIdentity(clubName.trim(), password);
      } else {
        if (!password) { setError("Password required"); return; }
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
  const strength = isCreate ? passwordStrength(password) : null;

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
          name="username"
          autoComplete="username"
          placeholder={isCreate ? "Display name" : "Identity name"}
          value={clubName}
          onChange={(e) => setClubName(e.target.value)}
          className="identity-input"
          disabled={loading}
          autoFocus
        />
        <div style={{ position: "relative" }}>
          <input
            type={showPassword ? "text" : "password"}
            name="password"
            autoComplete={isCreate ? "new-password" : "current-password"}
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="identity-input"
            style={{ paddingRight: "60px" }}
            disabled={loading}
          />
          <button
            type="button"
            onClick={() => setShowPassword((s) => !s)}
            style={{ position: "absolute", right: "4px", top: "50%", transform: "translateY(-50%)", background: "none", border: "none", cursor: "pointer", fontSize: "0.8em", color: "var(--fg, #666)", padding: "4px 8px" }}
          >
            {showPassword ? "Hide" : "Show"}
          </button>
        </div>
        {isCreate && strength && password && (
          <div style={{ display: "flex", alignItems: "center", gap: "8px", fontSize: "0.8em", marginTop: "2px" }}>
            <div style={{ flex: 1, height: "4px", background: "#eee", borderRadius: "2px", overflow: "hidden" }}>
              <div style={{ height: "100%", width: `${(strength.score / 5) * 100}%`, background: strength.color, transition: "width 0.2s, background 0.2s" }} />
            </div>
            <span style={{ color: strength.color }}>{strength.label}</span>
          </div>
        )}
        {isCreate && (
          <div style={{ fontSize: "0.75em", color: "var(--fg, #888)", marginTop: "4px", lineHeight: 1.4 }}>
            <div style={{ color: password.length >= MIN_PASSWORD_LENGTH ? "#27ae60" : "inherit" }}>
              {password.length >= MIN_PASSWORD_LENGTH ? "✓" : "·"} {MIN_PASSWORD_LENGTH}+ characters
            </div>
            <div style={{ color: /[A-Z]/.test(password) ? "#27ae60" : "inherit" }}>
              {/[A-Z]/.test(password) ? "✓" : "·"} Uppercase letter
            </div>
            <div style={{ color: /[a-z]/.test(password) ? "#27ae60" : "inherit" }}>
              {/[a-z]/.test(password) ? "✓" : "·"} Lowercase letter
            </div>
            <div style={{ color: /[0-9]/.test(password) ? "#27ae60" : "inherit" }}>
              {/[0-9]/.test(password) ? "✓" : "·"} Digit
            </div>
          </div>
        )}
        {error && <div className="identity-error">{error}</div>}
        <button type="submit" className="identity-submit" disabled={loading || !connected}>
          {loading ? "..." : isCreate ? "Create" : "Sign In"}
        </button>
        <p className="identity-hint">
          {isCreate ? (
            <>Already have an identity? <button type="button" className="identity-link" onClick={() => { setMode("login"); setError(null); }}>Sign in</button></>
          ) : (
            <>No identity yet? <button type="button" className="identity-link" onClick={() => { setMode("create"); setError(null); setShowPassword(true); }}>Create one</button></>
          )}
        </p>
      </form>
    </div>
  );
}
