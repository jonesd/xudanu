import { useState, useEffect } from "react";

interface BottomBarProps {
  connected: boolean;
  sessionCount: number;
  workId: string | null;
  version: number | null;
  wordCount: number;
  chainValid: boolean;
  lastSavedSeconds: number | null;
}

export function BottomBar({
  connected,
  sessionCount,
  workId,
  version,
  wordCount,
  chainValid,
  lastSavedSeconds,
}: BottomBarProps) {
  const [healthDegraded, setHealthDegraded] = useState(false);

  useEffect(() => {
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      setHealthDegraded(!!detail?.degraded);
    };
    window.addEventListener("xudanu-health", handler);
    return () => window.removeEventListener("xudanu-health", handler);
  }, []);

  const savedText = lastSavedSeconds === null
    ? ""
    : lastSavedSeconds < 5
    ? "just now"
    : lastSavedSeconds < 60
    ? `${lastSavedSeconds}s ago`
    : `${Math.floor(lastSavedSeconds / 60)}m ago`;

  return (
    <div className="bottom-bar">
      <div className="bb-item">
        <div className="connection-dot" style={{ width: 6, height: 6, background: connected ? "var(--green)" : "var(--red)" }} />
        {connected ? `Connected · ${sessionCount} session${sessionCount !== 1 ? "s" : ""}` : "Offline"}
      </div>
      {workId && (
        <div className="bb-item">work:{workId}{version != null ? ` · v${version}` : ""}</div>
      )}
      <div className="bb-spacer" />
      {wordCount > 0 && <div className="bb-item">{wordCount.toLocaleString()} words</div>}
      <div className="bb-item" style={{ color: healthDegraded ? "var(--red)" : chainValid ? "var(--green)" : "var(--red)" }}>
        {healthDegraded
          ? "data integrity issue"
          : chainValid
          ? "chain valid"
          : "chain invalid"}
      </div>
      {savedText && <div className="bb-item">auto-saved {savedText}</div>}
    </div>
  );
}
