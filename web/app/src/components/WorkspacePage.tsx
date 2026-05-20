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

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const wid = params.get("work");
    if (wid) {
      setWorkBeId(parseInt(wid, 10));
    }
  }, []);


  const handleCreate = useCallback(async () => {
    setError(null);
    try {
      const ws = new WebSocket(`${WS_URL}?format=json&version=2`);
      await new Promise<void>((resolve, reject) => {
        ws.onopen = () => resolve();
        ws.onerror = () => reject(new Error("Connection failed"));
      });

      let id = 0;
      const send = (op: string, payload?: object): Promise<unknown> => {
        return new Promise((resolve, reject) => {
          const reqId = ++id;
          const frame: Record<string, unknown> = { v: 2, type: "request", id: reqId, op };
          if (payload) frame.payload = payload;
          const handler = (e: MessageEvent) => {
            try {
              const msg = JSON.parse(e.data as string) as Record<string, unknown>;
              if (msg.id === reqId) {
                ws.removeEventListener("message", handler);
                if (msg.type === "error") {
                  reject(new Error(String(msg.message)));
                } else {
                  resolve(msg.value);
                }
              }
            } catch { /* ignore */ }
          };
          ws.addEventListener("message", handler);
          ws.send(JSON.stringify(frame));
        });
      };

      await send("session_connect");
      await send("session_login_public");

      const edition = { text: "Start typing here..." };
      const createResp = await send("work_create", { edition });
      const newId = (createResp as Record<string, unknown>)?.value as number;

      ws.close();
      setWorkBeId(newId);
      const url = new URL(window.location.href);
      url.searchParams.set("work", String(newId));
      window.history.replaceState({}, "", url.toString());
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
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
    identity,
    createIdentity,
    login,
  } = useCrdtSync(WS_URL, workBeId);

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

  const workIdDisplay = useMemo(() => {
    if (workBeId === null) return null;
    return workBeId.toString(16).padStart(4, "0");
  }, [workBeId]);

  return (
    <div className="workspace-page">
      <header className="workspace-header">
        <h1>
          {workIdDisplay ? `Work ${workIdDisplay}` : "Xanadu Gold"}
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
            <button
              onClick={toggleWatch}
              type="button"
              className={watchEnabled ? "watch-toggle-active" : ""}
              disabled={!connected}
            >
              {watchEnabled ? "Watching" : "Watch"}
            </button>
          )}
          <button
            onClick={() => setShowDebug((d) => !d)}
            type="button"
            className={showDebug ? "debug-toggle-active" : ""}
          >
            Debug
          </button>
          {workBeId !== null && (
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
          )}
          {workBeId === null && (
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
            </>
          ) : (
            <div className="welcome">
              <p>Create a new document or open an existing one to start collaborating.</p>
              <button onClick={handleCreate} type="button" className="welcome-create">
                Create Document
              </button>
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
