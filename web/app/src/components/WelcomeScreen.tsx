interface WelcomeScreenProps {
  workCount: number;
  hasIdentity: boolean;
  onNewDocument: () => void;
  onBrowseLibrary: () => void;
  onImport: () => void;
  onDemo: () => void;
}

export function WelcomeScreen({
  workCount,
  hasIdentity,
  onNewDocument,
  onBrowseLibrary,
  onImport,
  onDemo,
}: WelcomeScreenProps) {
  return (
    <div className="welcome-screen">
      <div className="welcome-title">xudanu</div>
      <div className="welcome-subtitle">
        A connected literature where every quotation maintains its bond to the original,
        where every reuse carries its full provenance.
      </div>
      <div className="welcome-features">
        <div className="welcome-feature-card">
          <div className="welcome-feature-icon" style={{ background: "rgba(88,166,255,0.12)", color: "#58a6ff" }}>{"\u2192"}</div>
          <div className="welcome-feature-name">Typed Links</div>
          <div className="welcome-feature-desc">Six link types &mdash; Comment, Reference, Disagreement, Quotation, See Also, Web &mdash; each colour-coded with margin descriptions</div>
        </div>
        <div className="welcome-feature-card">
          <div className="welcome-feature-icon" style={{ background: "rgba(63,185,80,0.12)", color: "#3fb950" }}>{"\u25A3"}</div>
          <div className="welcome-feature-name">Transclusion</div>
          <div className="welcome-feature-desc">Inline content reuse with 32-level recursive resolution. Links survive edits via O-tree span migration.</div>
        </div>
        <div className="welcome-feature-card">
          <div className="welcome-feature-icon" style={{ background: "rgba(163,113,247,0.12)", color: "#a371f7" }}>{"\u2713"}</div>
          <div className="welcome-feature-name">Provenance</div>
          <div className="welcome-feature-desc">Every character is cryptographically attributed. Ed25519 signatures, BLAKE3 verification, tamper-evident audit trail.</div>
        </div>
        <div className="welcome-feature-card">
          <div className="welcome-feature-icon" style={{ background: "rgba(210,153,34,0.12)", color: "#d29922" }}>{"\u21C4"}</div>
          <div className="welcome-feature-name">Comparison</div>
          <div className="welcome-feature-desc">Side-by-side document comparison with bezier-curve connections between shared passages. Split view and inline diff.</div>
        </div>
        <div className="welcome-feature-card">
          <div className="welcome-feature-icon" style={{ background: "rgba(57,210,192,0.12)", color: "#39d2c0" }}>{"\u2302"}</div>
          <div className="welcome-feature-name">Cross-Server</div>
          <div className="welcome-feature-desc">Domain-based tumblers route content across servers. BLAKE3 hash verification makes content substitution impossible.</div>
        </div>
        <div className="welcome-feature-card">
          <div className="welcome-feature-icon" style={{ background: "rgba(248,81,73,0.12)", color: "#f85149" }}>{"\u270E"}</div>
          <div className="welcome-feature-name">Real-time CRDT</div>
          <div className="welcome-feature-desc">Live multi-user editing without locks. Purpose-built O-tree CRDT with presence awareness and conflict-free merges.</div>
        </div>
      </div>
      <div className="welcome-actions">
        <button className="welcome-btn primary" onClick={onNewDocument}>
          New Document
        </button>
        <button className="welcome-btn" onClick={onImport}>
          Import Source
        </button>
        <button className="welcome-btn" onClick={onBrowseLibrary}>
          Browse Library
        </button>
      </div>
      <div className="welcome-actions">
        <button
          className="welcome-btn"
          style={{ borderColor: "var(--accent-blue)", color: "var(--accent-blue)" }}
          onClick={onDemo}
        >
          {"\u25B6 Try the Interactive Demo"}
        </button>
        <button
          className="welcome-btn"
          style={{ borderColor: "var(--accent-blue)", color: "var(--accent-blue)", cursor: "pointer" }}
          onClick={() => window.open("https://jonesd.github.io/xudanu/", "_blank", "noopener,noreferrer")}
        >
          {"\u2756 Documentation"}
        </button>
      </div>
      {workCount > 0 && (
        <div className="welcome-hint" style={{ marginTop: 16 }}>
          <strong>{workCount} document{workCount !== 1 ? "s" : ""} available.</strong>{" "}
          Click <strong>Browse Library</strong> to explore.
        </div>
      )}
      {!hasIdentity && (
        <div className="welcome-hint">
          Tip: You need an identity to edit documents.
          Click <strong>New Document</strong> to get started.
        </div>
      )}
      <div style={{ marginTop: 32, fontSize: 10, color: "var(--text-dim)", textAlign: "center", maxWidth: 400 }}>
        Independent open-source project (Apache 2.0). Not affiliated with Project Xanadu&trade; or the Udanax team.
      </div>
    </div>
  );
}
