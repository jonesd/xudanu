import { useRef, useState } from "react";

export interface HomeLandingProps {
  onCreate: () => Promise<number | null>;
  onImport: (file: File) => Promise<number | null>;
  onCreateIdentity: (displayName: string, password: string) => Promise<void>;
  needsIdentity: boolean;
  recent: Array<{ work_id: number; title?: string; updated_at?: number }>;
  connected: boolean;
  onDismiss: () => void;
}

function timeAgo(ts?: number): string {
  if (!ts) return "";
  const s = Math.max(1, Math.floor(Date.now() / 1000 - ts));
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  return `${Math.floor(s / 86400)}d ago`;
}

export function HomeLanding({
  onCreate,
  onImport,
  onCreateIdentity,
  needsIdentity,
  recent,
  connected,
  onDismiss,
}: HomeLandingProps) {
  const [busy, setBusy] = useState<"create" | "import" | "identity" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pendingAction, setPendingAction] = useState<"create" | "import" | null>(null);
  const [name, setName] = useState("");
  const [password, setPassword] = useState("");
  const fileRef = useRef<HTMLInputElement>(null);

  const runCreate = async () => {
    let id = await onCreate();
    // The session's public login can land a beat after the WS opens;
    // a short retry covers the fresh-connect race.
    for (let attempt = 0; id == null && attempt < 3; attempt++) {
      await new Promise((r) => setTimeout(r, 700));
      id = await onCreate();
    }
    if (id == null) throw new Error("Could not create the document. Please try again.");
  };

  const runImport = async (f: File) => {
    let id = await onImport(f);
    for (let attempt = 0; id == null && attempt < 3; attempt++) {
      await new Promise((r) => setTimeout(r, 700));
      id = await onImport(f);
    }
    if (id == null) throw new Error("Import failed. Markdown and plain text are supported.");
  };

  const start = async () => {
    if (busy) return;
    if (needsIdentity) {
      setPendingAction("create");
      return;
    }
    setBusy("create");
    setError(null);
    try {
      await runCreate();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
    }
  };

  const pick = () => {
    if (busy) return;
    if (needsIdentity) {
      setPendingAction("import");
      return;
    }
    fileRef.current?.click();
  };

  const onFile = async (f: File | undefined) => {
    if (!f || busy) return;
    setBusy("import");
    setError(null);
    try {
      await runImport(f);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
      if (fileRef.current) fileRef.current.value = "";
    }
  };

  const submitIdentity = async (e: React.FormEvent) => {
    e.preventDefault();
    if (busy || !name.trim() || password.length < 8) return;
    setBusy("identity");
    setError(null);
    try {
      await onCreateIdentity(name.trim(), password);
      // Continue the action that needed the identity.
      if (pendingAction === "import") {
        fileRef.current?.click();
      } else {
        await runCreate();
      }
      setPendingAction(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(null);
    }
  };

  return (
    <div className="ws-home-landing" role="dialog" aria-label="Welcome">
      <button className="ws-home-skip" onClick={onDismiss} aria-label="Skip welcome">
        Skip →
      </button>
      <h1 className="ws-home-title">
        What would you like to <em>write</em>?
      </h1>
      <p className="ws-home-sub">
        Documents with live transclusion — quote anything, keep both sides connected.
      </p>

      <div className="ws-home-cards">
        <button className="ws-home-card ws-home-card-create" onClick={start} disabled={!connected || busy != null}>
          <span className="ws-home-icon" aria-hidden>📄</span>
          <span className="ws-home-card-title">Start writing</span>
          <span className="ws-home-card-desc">
            A fresh document. Type a title, begin. Everything saves and versions automatically.
          </span>
          <span className="ws-home-card-cta">{busy === "create" ? "Creating…" : "Create document →"}</span>
        </button>

        <button className="ws-home-card" onClick={start} disabled={!connected || busy != null}>
          <span className="ws-home-icon" aria-hidden>✂️</span>
          <span className="ws-home-card-title">Quote from a source</span>
          <span className="ws-home-card-desc">
            Start a document, then paste any text or tumbler — the connection to the original stays visible.
          </span>
          <span className="ws-home-card-cta ws-home-cta-purple">New transclusion →</span>
        </button>

        <button className="ws-home-card" onClick={pick} disabled={!connected || busy != null}>
          <span className="ws-home-icon" aria-hidden>📥</span>
          <span className="ws-home-card-title">Import a file</span>
          <span className="ws-home-card-desc">Markdown or plain text becomes a fully connected xudanu document.</span>
          <span className="ws-home-card-cta ws-home-cta-blue">{busy === "import" ? "Importing…" : "Import →"}</span>
        </button>
      </div>

      {needsIdentity && pendingAction && (
        <form className="ws-home-identity" onSubmit={submitIdentity}>
          <h3>Pick a pen name to start</h3>
          <p>You'll sign your edits with this name — it becomes your identity on this server.</p>
          <input
            autoFocus
            type="text"
            placeholder="Display name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            maxLength={40}
            required
          />
          <input
            type="password"
            placeholder="Password (8+ characters)"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            minLength={8}
            required
          />
          <div className="ws-home-identity-row">
            <button type="submit" disabled={busy != null || !name.trim() || password.length < 8}>
              {busy === "identity" ? "Setting up…" : "Continue"}
            </button>
            <button type="button" className="ws-home-identity-cancel" onClick={() => setPendingAction(null)}>
              Cancel
            </button>
          </div>
        </form>
      )}

      <input
        ref={fileRef}
        type="file"
        accept=".md,.markdown,.txt,text/markdown,text/plain"
        style={{ display: "none" }}
        onChange={(e) => void onFile(e.target.files?.[0])}
      />

      {recent.length > 0 && (
        <div className="ws-home-recent">
          <h4>Continue where you left off</h4>
          <div className="ws-home-chips">
            {recent.slice(0, 3).map((w) => (
              <span key={w.work_id} className="ws-home-chip">
                <i className="ws-home-chip-dot" aria-hidden />
                {w.title?.trim() || "Untitled"} · {timeAgo(w.updated_at)}
              </span>
            ))}
            {recent.length > 3 && <span className="ws-home-chip ws-home-chip-more">+ {recent.length - 3} more</span>}
          </div>
        </div>
      )}

      {!connected && <p className="ws-home-error">Connecting to server…</p>}
      {error && <p className="ws-home-error" role="alert">{error}</p>}

      <p className="ws-home-hint">tip: press N for a new document anytime</p>
    </div>
  );
}
