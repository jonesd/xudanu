import { useState, useEffect } from "react";

interface HealthStatus {
  status: string;
  chain_valid?: boolean;
  restore_errors?: string[] | null;
}

export function DataIntegrityBanner() {
  const [health, setHealth] = useState<HealthStatus | null>(null);

  useEffect(() => {
    const check = async () => {
      try {
        const resp = await fetch("/health");
        const data = await resp.json();
        setHealth(data);
        const degraded = data.chain_valid === false || (Array.isArray(data.restore_errors) && data.restore_errors.length > 0);
        window.dispatchEvent(new CustomEvent("xudanu-health", { detail: { degraded } }));
      } catch {}
    };
    check();
    const interval = setInterval(check, 30000);
    return () => clearInterval(interval);
  }, []);

  const chainBroken = health?.chain_valid === false;
  const restoreErrors = health?.restore_errors && Array.isArray(health.restore_errors) && health.restore_errors.length > 0;

  if (!chainBroken && !restoreErrors) return null;

  return (
    <div style={{
      background: "#5c1a1a",
      color: "#ff6b6b",
      padding: "8px 16px",
      fontSize: 12,
      fontWeight: 600,
      display: "flex",
      alignItems: "center",
      gap: 12,
      borderBottom: "1px solid #8a2020",
    }}>
      <span>{"\u26a0"}</span>
      <span>
        {chainBroken && "SECURITY: Tamper-evident log chain is BROKEN. "}
        {restoreErrors && `Data restore errors detected (${health?.restore_errors?.length}). `}
        Possible data corruption or tampering.
      </span>
      <a
        href="https://github.com/jonesd/xudanu/blob/main/docs/dev/incident-response.md"
        target="_blank"
        rel="noopener noreferrer"
        style={{ color: "#ffa0a0", textDecoration: "underline", fontSize: 11 }}
      >
        Incident response guide
      </a>
      <span style={{ marginLeft: "auto", fontSize: 11, opacity: 0.7 }}>
        Run <code style={{ background: "rgba(0,0,0,0.3)", padding: "1px 4px", borderRadius: 3 }}>xudanu-cli verify data</code> for details
      </span>
    </div>
  );
}
