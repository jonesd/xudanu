import { useState } from "react";
import type { WhoAmIEntry } from "../api/crdt_sync";

interface Roster {
  members: [number, string][];
  total: number;
  truncated: boolean;
}

interface IdentityPanelProps {
  identity: WhoAmIEntry | null;
  connected: boolean;
  onLogin: (clubName: string, password: string) => Promise<void>;
  onCreateIdentity: (displayName: string, password: string) => Promise<void>;
  onChangePassword?: (currentPassword: string, newPassword: string) => Promise<void>;
  onLogout: () => void;
  rosters?: Record<number, Roster>;
  llmEnabled?: boolean;
  llmUsage?: {
    total_requests: number;
    total_prompt_chars: number;
    total_response_chars: number;
    by_feature?: Record<string, { requests?: number; prompt_chars?: number; response_chars?: number; count?: number }>;
    recent?: Array<{ feature: string; prompt_chars: number; response_chars: number; timestamp_secs: number }>;
  } | null;
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

export function IdentityPanel({ identity, connected, onLogin, onCreateIdentity, onChangePassword, onLogout, rosters, llmEnabled, llmUsage }: IdentityPanelProps) {
  const [mode, setMode] = useState<"closed" | "login" | "create">("closed");
  const [clubName, setClubName] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);
  const [pwOpen, setPwOpen] = useState(false);
  const [pwCurrent, setPwCurrent] = useState("");
  const [pwNew, setPwNew] = useState("");
  const [pwError, setPwError] = useState<string | null>(null);
  const [pwBusy, setPwBusy] = useState(false);
  const [pwDone, setPwDone] = useState(false);

  if (identity) {
    const clubHex = identity.club_id.toString(16).padStart(4, "0");
    return (
      <div className="identity-panel identity-logged-in">
        <div className="identity-modal-name">{identity.display_name}</div>
        <div className="identity-modal-grid">
          <span className="identity-modal-label">Club ID</span>
          <span className="identity-modal-value">#{clubHex}</span>
          <span className="identity-modal-label">Status</span>
          <span className="identity-badge identity-verified">
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="20 6 9 17 4 12" />
            </svg>
            verified
          </span>
        </div>
        {identity.verifying_key && (
          <div className="identity-modal-keyblock">
            <div className="identity-modal-label">Public verifying key</div>
            <div className="identity-modal-key-full">{identity.verifying_key}</div>
            <button
              type="button"
              className="identity-modal-copy"
              onClick={() => {
                navigator.clipboard?.writeText(identity.verifying_key || "");
                setCopied(true);
                setTimeout(() => setCopied(false), 1500);
              }}
            >
              {copied ? "Copied" : "Copy"}
            </button>
          </div>
        )}
        {identity.clubs && identity.clubs.length > 0 && (
          <div className="identity-modal-clubs">
            <div className="identity-modal-label">Clubs you can access ({identity.clubs.length})</div>
            <ul>
              {identity.clubs.map(([cid, cname]) => {
                const roster = rosters?.[cid];
                return (
                  <li key={cid}>
                    <div className="identity-modal-club-row">
                      <span className="identity-modal-value">#{cid.toString(16).padStart(4, "0")}</span>
                      <span className="identity-modal-club-name">{cname}</span>
                    </div>
                    {roster && roster.total > 0 && (
                      <div className="identity-modal-roster">
                        {roster.members.map(([mid, mname]) => (
                          <span key={mid} className="identity-modal-roster-member">{mname}</span>
                        ))}
                        {roster.truncated && (
                          <span className="identity-modal-roster-more">+{roster.total - roster.members.length} more</span>
                        )}
                      </div>
                    )}
                  </li>
                );
              })}
            </ul>
          </div>
        )}
        <div className="identity-modal-hint">
          Your private signing key is encrypted at rest and never shown. Your
          public verifying key can be shared so others can confirm your signatures.
        </div>
        <div className="llm-usage-panel">
          <div className="llm-usage-header">
            <span className="llm-usage-title">LLM Activity</span>
            <span className={`llm-usage-badge ${llmEnabled ? "active" : "inactive"}`}>
              {llmEnabled ? "Enabled" : "Disabled"}
            </span>
          </div>
          {llmEnabled && llmUsage ? (
            <>
              <div className="llm-usage-stats">
                <div className="llm-usage-stat">
                  <span className="llm-usage-stat-value">{llmUsage.total_requests}</span>
                  <span className="llm-usage-stat-label">requests</span>
                </div>
                <div className="llm-usage-stat">
                  <span className="llm-usage-stat-value">{Math.round(llmUsage.total_prompt_chars / 4)}</span>
                  <span className="llm-usage-stat-label">tokens sent</span>
                </div>
                <div className="llm-usage-stat">
                  <span className="llm-usage-stat-value">{Math.round(llmUsage.total_response_chars / 4)}</span>
                  <span className="llm-usage-stat-label">tokens received</span>
                </div>
              </div>
              {llmUsage.by_feature && Object.keys(llmUsage.by_feature).length > 0 && (
                <div className="llm-usage-features">
                  {Object.entries(llmUsage.by_feature).map(([feature, data]) => (
                    <div key={feature} className="llm-usage-feature">
                      <span className="llm-usage-feature-name">{feature}</span>
                      <span className="llm-usage-feature-count">{data.count}x</span>
                    </div>
                  ))}
                </div>
              )}
              <p className="llm-usage-disclaimer">Token counts are estimates (~4 chars/token). Per-feature breakdown shows usage by LLM capability.</p>
            </>
          ) : (
            <p className="llm-usage-disabled">Enable with <code>--ollama-url</code> flag on the server.</p>
          )}
        </div>
        {onChangePassword && (
          <div className="identity-pw-change">
            {!pwOpen ? (
              <button
                type="button"
                className="identity-btn identity-btn-secondary"
                onClick={() => { setPwOpen(true); setPwError(null); setPwDone(false); }}
              >
                Change Password
              </button>
            ) : (
              <form
                onSubmit={async (e) => {
                  e.preventDefault();
                  setPwError(null);
                  const pwErr = validatePassword(pwNew);
                  if (pwErr) { setPwError(pwErr); return; }
                  setPwBusy(true);
                  try {
                    await onChangePassword(pwCurrent, pwNew);
                    setPwDone(true);
                    setPwCurrent("");
                    setPwNew("");
                    setTimeout(() => { setPwOpen(false); setPwDone(false); }, 1500);
                  } catch (err) {
                    const msg = err instanceof Error ? err.message : String(err);
                    setPwError(
                      /lock failed|credential/i.test(msg)
                        ? "Current password is incorrect."
                        : msg
                    );
                  } finally {
                    setPwBusy(false);
                  }
                }}
                style={{ display: "flex", flexDirection: "column", gap: "8px" }}
              >
                <div className="identity-form-title" style={{ fontSize: "0.9em" }}>Change Password</div>
                <input
                  type="password"
                  autoComplete="current-password"
                  placeholder="Current password"
                  value={pwCurrent}
                  onChange={(e) => setPwCurrent(e.target.value)}
                  className="identity-input"
                  disabled={pwBusy}
                />
                <input
                  type="password"
                  autoComplete="new-password"
                  placeholder="New password"
                  value={pwNew}
                  onChange={(e) => setPwNew(e.target.value)}
                  className="identity-input"
                  disabled={pwBusy}
                />
                {pwNew && (
                  <div style={{ display: "flex", alignItems: "center", gap: "8px", fontSize: "0.8em" }}>
                    <div style={{ flex: 1, height: "4px", background: "#eee", borderRadius: "2px", overflow: "hidden" }}>
                      <div style={{ height: "100%", width: `${(passwordStrength(pwNew).score / 5) * 100}%`, background: passwordStrength(pwNew).color, transition: "width 0.2s" }} />
                    </div>
                    <span style={{ color: passwordStrength(pwNew).color }}>{passwordStrength(pwNew).label}</span>
                  </div>
                )}
                {pwError && <div className="identity-error">{pwError}</div>}
                {pwDone && <div style={{ color: "#27ae60", fontSize: "0.85em" }}>Password updated ✓</div>}
                <div style={{ display: "flex", gap: "8px" }}>
                  <button type="submit" className="identity-submit" disabled={pwBusy || !pwCurrent || !pwNew} style={{ flex: 1 }}>
                    {pwBusy ? "..." : "Update"}
                  </button>
                  <button
                    type="button"
                    className="identity-btn identity-btn-secondary"
                    onClick={() => { setPwOpen(false); setPwCurrent(""); setPwNew(""); setPwError(null); }}
                    disabled={pwBusy}
                  >
                    Cancel
                  </button>
                </div>
              </form>
            )}
          </div>
        )}
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
