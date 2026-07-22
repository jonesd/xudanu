interface ConnectionOverlayProps {
  connected: boolean;
  reconnectAttempt: number;
}

export function ConnectionOverlay({ connected, reconnectAttempt }: ConnectionOverlayProps) {
  if (connected) return null;

  const isInitialConnect = reconnectAttempt === 0;
  const delay = Math.min(1000 * Math.pow(2, reconnectAttempt), 30000);
  const delayText = delay >= 1000 ? `${Math.round(delay / 1000)}s` : "soon";

  const styles = isInitialConnect
    ? {
        background: "rgba(88, 166, 255, 0.95)",
        message: "Connecting to Xudanu…",
        showRetry: false,
      }
    : {
        background: "rgba(248, 81, 73, 0.95)",
        message: `Connection lost — reconnecting (attempt ${reconnectAttempt}, next in ${delayText})`,
        showRetry: true,
      };

  return (
    <div
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        zIndex: 9999,
        background: styles.background,
        color: "#fff",
        padding: "10px 20px",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: "12px",
        fontSize: "13px",
        fontWeight: 500,
        boxShadow: "0 2px 8px rgba(0,0,0,0.2)",
        backdropFilter: "blur(4px)",
      }}
    >
      <span
        style={{
          width: "10px",
          height: "10px",
          borderRadius: "50%",
          background: "#fff",
          animation: "conn-pulse 1s ease-in-out infinite",
        }}
      />
      <span>{styles.message}</span>
      {styles.showRetry && (
        <button
          type="button"
          onClick={() => window.location.reload()}
          style={{
            background: "rgba(255,255,255,0.2)",
            border: "1px solid rgba(255,255,255,0.4)",
            borderRadius: "4px",
            padding: "2px 10px",
            color: "#fff",
            fontSize: "12px",
            cursor: "pointer",
          }}
        >
          Retry now
        </button>
      )}
      <style>{`
        @keyframes conn-pulse {
          0%, 100% { opacity: 0.4; }
          50% { opacity: 1; }
        }
      `}</style>
    </div>
  );
}
