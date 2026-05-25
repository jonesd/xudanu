import { useState, useEffect, useCallback, useMemo } from "react";
import { useCrdtSync } from "../hooks/useCrdtSync";
import { CollaborativeEditor } from "../components/CollaborativeEditor";
import { AwarenessIndicators } from "../components/AwarenessIndicators";
import { DebugPanel } from "../components/DebugPanel";
import { AttributionPanel } from "../components/AttributionPanel";
import { IdentityPanel } from "../components/IdentityPanel";

const WS_URL = `ws://${window.location.host}/xudanu`;

export function WorkspacePage() {
  const [showDebug, setShowDebug] = useState(false);
  const [showAttribution, setShowAttribution] = useState(false);
  const [workBeId, setWorkBeId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [narration, setNarration] = useState<string | null>(null);
  const [narrating, setNarrating] = useState(false);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const wid = params.get("work");
    if (wid) {
      setWorkBeId(parseInt(wid, 10));
    }
  }, []);


  const {
    text,
    connected,
    awareness,
    setText,
    sendCursor,
    sendSelection,
    contentMatches,
    watchEnabled,
    toggleWatch,
    attributionSpans,
    attributionLogStatus,
    refreshAttribution,
    refreshAwareness,
    identity,
    createIdentity,
    login,
    createWork,
    shareWork,
    narrateDiff,
  } = useCrdtSync(WS_URL, workBeId);

  const handleCreate = useCallback(async () => {
    setError(null);
    try {
      const newId = await createWork();
      if (newId === null) {
        setError("Not connected");
        return;
      }
      setWorkBeId(newId);
      const url = new URL(window.location.href);
      url.searchParams.set("work", String(newId));
      window.history.replaceState({}, "", url.toString());
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  }, [createWork]);

  useEffect(() => {
    if (workBeId !== null && connected && text === "") {
      const timer = setTimeout(() => {
        setWorkBeId((currentId) => {
          if (currentId !== null) {
            const url = new URL(window.location.href);
            url.searchParams.delete("work");
            window.history.replaceState({}, "", url.toString());
          }
          return null;
        });
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [workBeId, connected, text]);

  useEffect(() => {
    if (showAttribution && connected && workBeId !== null && text.length > 0) {
      const timer = setTimeout(() => { refreshAttribution(); }, 2000);
      return () => clearTimeout(timer);
    }
  }, [showAttribution, connected, workBeId, text.length, refreshAttribution]);

  useEffect(() => {
    if (connected && workBeId !== null) {
      const timer = setTimeout(() => { refreshAwareness(); }, 5000);
      return () => clearTimeout(timer);
    }
  }, [connected, workBeId, awareness.length, refreshAwareness]);

  const workIdDisplay = useMemo(() => {
    if (workBeId === null) return null;
    return workBeId.toString(16).padStart(4, "0");
  }, [workBeId]);

  return (
    <div className="workspace-page">
      <header className="workspace-header">
        <h1>
          {workIdDisplay ? `Work ${workIdDisplay}` : "xudanu"}
        </h1>
        <div className="header-actions">
          <span className={`sync-status ${connected ? "sync-connected" : "sync-disconnected"}`}>
            {connected ? "Live" : "Offline"}
          </span>
          <IdentityPanel
            identity={identity}
            connected={connected}
            onCreateIdentity={createIdentity}
            onLogin={login}
           />
          {workBeId !== null && (
            <>
              <button onClick={shareWork} type="button" disabled={!connected}>
                Share
              </button>
              <button
                onClick={toggleWatch}
                type="button"
                className={watchEnabled ? "watch-toggle-active" : ""}
                disabled={!connected}
              >
                {watchEnabled ? "Watching" : "Watch"}
              </button>
              <button
                onClick={() => setShowDebug((d) => !d)}
                type="button"
                className={showDebug ? "debug-toggle-active" : ""}
              >
                Debug
              </button>
              <button
                onClick={() => {
                  setShowAttribution((a) => {
                    const next = !a;
                    if (next) refreshAttribution();
                    return next;
                  });
                }}
                type="button"
                className={showAttribution ? "attribution-toggle-active" : ""}
                disabled={!connected}
              >
                Attribution
              </button>
              <button
                onClick={async () => {
                  setNarrating(true);
                  setNarration(null);
                  const text = await narrateDiff();
                  setNarration(text);
                  setNarrating(false);
                }}
                type="button"
                disabled={!connected || narrating}
              >
                {narrating ? "Thinking..." : "Narrate"}
              </button>
            </>
          )}
          {workBeId === null && (
            <>
              <button
                onClick={() => setShowDebug((d) => !d)}
                type="button"
                className={showDebug ? "debug-toggle-active" : ""}
              >
                Debug
              </button>
            </>
          )}
          {workBeId === null && identity && (
            <button onClick={handleCreate} type="button">
              New Document
            </button>
          )}
        </div>
      </header>

      {error && <div className="error">{error}</div>}

      <div className="workspace-body">
        <main className="document-area">
          {workBeId !== null ? (
            <>
              <AwarenessIndicators states={awareness} connected={connected} />
              <CollaborativeEditor
                text={text}
                onTextChange={setText}
                onCursorChange={sendCursor}
                onSelectionChange={(s, e) => sendSelection(s, e)}
                connected={connected}
                attributionSpans={attributionSpans}
                editable={identity !== null}
              />
              {watchEnabled && contentMatches.length > 0 && (
                <div className="watch-notifications">
                  <h3>Content Matches</h3>
                  <ul>
                    {contentMatches.map((match, i) => (
                      <li key={i}>
                        <span className="match-id">
                          {match.work_be_id != null
                            ? `${match.work_be_id}${match.title ? ` ${match.title}` : ""}`
                            : match.edition_be_id.toString(16).padStart(4, "0")}
                        </span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
              {narration && (
                <div className="narration-panel">
                  <h3>Change Summary</h3>
                  <p>{narration}</p>
                </div>
              )}
            </>
          ) : (
            <div className="welcome">
              {identity ? (
                <>
                  <p>Create a new document or open an existing one to start collaborating.</p>
                  <button onClick={handleCreate} type="button" className="welcome-create">
                    Create Document
                  </button>
                </>
              ) : (
                <p>Sign in or create an identity to start collaborating.</p>
              )}
            </div>
          )}
        </main>
      </div>

      {showDebug && (
        <DebugPanel workspaceId={workBeId?.toString(16) ?? ""} visible={showDebug} />
      )}

      <AttributionPanel
        spans={attributionSpans}
        logStatus={attributionLogStatus}
        documentLength={text.length}
        visible={showAttribution && workBeId !== null}
      />
    </div>
  );
}
