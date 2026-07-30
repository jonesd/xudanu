import { useState, useEffect, useRef, useCallback } from "react";
import { CrdtSyncClient, type AwarenessState, type ContentMatch, type AttributionSpan, type AttributionLogStatus, type WhoAmIEntry, type WorkListEntry, type AnnotationEntry, type ChangeHighlight, type LlmUsageSummary } from "../api/crdt_sync";

export interface CrdtSyncState {
  text: string;
  connected: boolean;
  authenticated: boolean;
  reconnectAttempt: number;
  awareness: AwarenessState[];
  setText: (text: string) => void;
  setTextLocal: (text: string) => void;
  sendCursor: (index: number | null) => void;
  sendSelection: (start: number | null, end: number | null) => void;
  contentMatches: ContentMatch[];
  watchEnabled: boolean;
  toggleWatch: () => void;
  clientRef: React.RefObject<CrdtSyncClient | null>;
  attributionSpans: AttributionSpan[];
  attributionLogStatus: AttributionLogStatus | null;
  refreshAttribution: () => void;
  refreshAwareness: () => void;
  identity: WhoAmIEntry | null;
  login: (clubName: string, password: string) => Promise<void>;
  createIdentity: (displayName: string, password: string) => Promise<void>;
  createWork: () => Promise<number | null>;
  shareWork: () => Promise<void>;
  unshareWork: () => Promise<void>;
  narrateDiff: () => Promise<{ text: string; model: string; updatedText: string }>;
  getWritingFeedback: () => Promise<{ text: string; model: string }>;
  suggestTitle: () => Promise<string>;
  setWorkTitle: (title: string) => Promise<void>;
  autoTag: () => Promise<{ new: Array<{name: string; id: number}>; linked: Array<{name: string; id: number}> }>;
  llmEnabled: boolean;
  llmUsage: LlmUsageSummary | null;
  fetchWorkList: () => Promise<WorkListEntry[]>;
  setVisibility: (workId: number, publicClubId: number | null) => Promise<void>;
  getReadClub: (workId: number) => Promise<number>;
  getEditClub: (workId: number) => Promise<number>;
  publicClubId: number;
  logout: () => void;
  annotations: AnnotationEntry[];
  refreshAnnotations: () => void;
  createAnnotation: (kind: string, payload: string, charStart: number, charEnd: number, isPrivate?: boolean) => Promise<void>;
  deleteAnnotation: (annotationId: number) => Promise<void>;
  connectionEpoch: number;
  isAdmin: boolean;
  canEdit: boolean;
  recentChanges: ChangeHighlight[];
}

export function useCrdtSync(
  wsUrl: string | null,
  workBeId: number | null,
): CrdtSyncState {
  const clientRef = useRef<CrdtSyncClient | null>(null);
  const [text, setTextState] = useState("");
  const [connected, setConnected] = useState(false);
  const [reconnectAttempt, setReconnectAttempt] = useState(0);
  const disconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [awareness, setAwareness] = useState<AwarenessState[]>([]);
  const [contentMatches, setContentMatches] = useState<ContentMatch[]>([]);
  const [watchEnabled, setWatchEnabled] = useState(false);
  const watchEnabledRef = useRef(false);
  const subscriptionIdRef = useRef<number | null>(null);
  const [attributionSpans, setAttributionSpans] = useState<AttributionSpan[]>([]);
  const [attributionLogStatus, setAttributionLogStatus] = useState<AttributionLogStatus | null>(null);
  const [identity, setIdentity] = useState<WhoAmIEntry | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [llmEnabled, setLlmEnabled] = useState(false);
  const [llmUsage, setLlmUsage] = useState<LlmUsageSummary | null>(null);
  const [publicClubId, setPublicClubId] = useState(0);
  const [authenticated, setAuthenticated] = useState(false);
  const [annotations, setAnnotations] = useState<AnnotationEntry[]>([]);
  const [connectionEpoch, setConnectionEpoch] = useState(0);
  const epochRef = useRef(0);
  const [canEdit, setCanEdit] = useState(false);
  const [recentChanges, setRecentChanges] = useState<ChangeHighlight[]>([]);

  useEffect(() => {
    if (!wsUrl) return;

    setTextState("");
    setConnected(false);
    setAuthenticated(false);
    const newEpoch = epochRef.current + 1;
    epochRef.current = newEpoch;
    setConnectionEpoch(newEpoch);

    const client = new CrdtSyncClient(wsUrl, workBeId ?? 0);
    clientRef.current = client;

    const unsubText = client.onTextChange(setTextState);
    const unsubConn = client.onConnectionChange((isConnected) => {
      if (isConnected) {
        if (disconnectTimerRef.current) {
          clearTimeout(disconnectTimerRef.current);
          disconnectTimerRef.current = null;
        }
        setConnected(true);
        setReconnectAttempt(0);
      } else {
        if (!disconnectTimerRef.current) {
          disconnectTimerRef.current = setTimeout(() => {
            disconnectTimerRef.current = null;
            setConnected(false);
            setReconnectAttempt(client!.getReconnectAttempt());
          }, 3000);
        }
      }
    });

    const reconnectPoll = setInterval(() => {
      if (client && !client.isConnected()) {
        setReconnectAttempt(client.getReconnectAttempt());
      }
    }, 2000);
    const unsubAware = client.onAwarenessChange(setAwareness);
    const MAX_CONTENT_MATCHES = 200;
    const unsubMatch = client.onContentMatch((match) => {
      setContentMatches((prev) => {
        const next = [...prev, match];
        return next.length > MAX_CONTENT_MATCHES ? next.slice(-MAX_CONTENT_MATCHES) : next;
      });
    });
    const unsubIdentity = client.onIdentityChange((id) => {
      setIdentity(id);
      setIsAdmin(client!.getIsAdmin());
    });
    const unsubChanges = client.onChangeHighlights(setRecentChanges);

    const unsubConn2 = client.onConnectionChange((isConnected) => {
      if (isConnected) {
        client!.sendRequest("server_stats").then((resp) => {
          const r = resp as Record<string, unknown>;
          if (r && "value" in r) {
            const val = r.value as Record<string, unknown>;
            setLlmEnabled(val?.llm_enabled === true);
            setLlmUsage((val?.llm_usage as LlmUsageSummary) || null);
            if (typeof val?.public_club_id === "number") {
              setPublicClubId(val.public_club_id);
            }
          }
        }).catch(() => {});

        const storedTicket = (() => {
          try {
            const b64 = localStorage.getItem("xudanu_session_ticket");
            if (!b64) return null;
            const binary = atob(b64);
            const arr = new Uint8Array(binary.length);
            for (let i = 0; i < binary.length; i++) arr[i] = binary.charCodeAt(i);
            return arr;
          } catch { return null; }
        })();

        const tryAuth = async () => {
          if (storedTicket) {
            await client!.sessionTicketRedeem(storedTicket);
          }
          const id = await client!.checkWhoAmI();
          if (id) {
            setAuthenticated(true);
            setIdentity(id);
            client!.sessionTicketIssue().then((ticket) => {
              if (ticket) {
                try {
                  const b64 = btoa(String.fromCharCode(...ticket));
                  localStorage.setItem("xudanu_session_ticket", b64);
                } catch {}
              }
            }).catch(() => {});
          } else {
            setAuthenticated(false);
          }
          setIsAdmin(client!.getIsAdmin());
        };
        tryAuth().catch(() => setAuthenticated(false));
      }
    });

    client.connect();

    return () => {
      clearInterval(reconnectPoll);
      unsubText();
      unsubConn();
      unsubConn2();
      unsubAware();
      unsubMatch();
      unsubIdentity();
      unsubChanges();
      if (disconnectTimerRef.current) {
        clearTimeout(disconnectTimerRef.current);
        disconnectTimerRef.current = null;
      }
      if (subscriptionIdRef.current !== null) {
        client.unsubscribe(subscriptionIdRef.current);
        subscriptionIdRef.current = null;
      }
      watchEnabledRef.current = false;
      setWatchEnabled(false);
      setContentMatches([]);
      client.disconnect();
      clientRef.current = null;
    };
    // Intentionally [wsUrl] only — NOT workBeId. The WebSocket connection
    // persists across document switches. Work switching is handled by the
    // switchWork effect below (crdt_sync_close + crdt_sync_open on the same
    // connection), which eliminates the reconnect gap.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [wsUrl]);

  // Switch works on the persistent connection (no WebSocket reconnect).
  // Replaces the old behavior of tearing down + recreating the entire
  // connection on every document switch.
  useEffect(() => {
    if (!connected || workBeId === null) return;
    clientRef.current?.switchWork(workBeId);
    // Send initial presence so other sessions see us immediately
    const t = setTimeout(() => {
      clientRef.current?.sendAwareness(null, null, false);
    }, 500);
    return () => clearTimeout(t);
  }, [workBeId, connected, authenticated]);

  // Low-frequency awareness reconciliation (30s safety net).
  // Primary awareness updates arrive via push events (crdt_awareness_update)
  // handled in CrdtSyncClient.handleEvent. This poll catches any missed
  // updates from edge cases (race conditions, dropped events).
  useEffect(() => {
    if (!connected || workBeId === null) return;
    const interval = setInterval(() => {
      const client = clientRef.current;
      if (client && client.isConnected()) {
        client.refreshAwareness().then(setAwareness).catch(() => {});
      }
    }, 30000);
    return () => clearInterval(interval);
  }, [connected, workBeId]);

  // Clear per-work state when switching works — prevents stale highlights,
  // annotations, attribution spans, and awareness from the previous work
  // rendering during the gap before the new work's data arrives.
  useEffect(() => {
    setAnnotations([]);
    setAttributionSpans([]);
    setAttributionLogStatus(null);
    setAwareness([]);
    setRecentChanges([]);
  }, [workBeId]);

  useEffect(() => {
    const handler = () => {
      const client = clientRef.current;
      if (client && client.isConnected() && workBeId !== null) {
        try {
          client.sendRequest("crdt_sync_close", { work_id: workBeId });
        } catch {}
      }
    };
    window.addEventListener("beforeunload", handler);
    return () => window.removeEventListener("beforeunload", handler);
  }, [workBeId]);

  useEffect(() => {
    if (!connected || !workBeId || !authenticated) return;
    const client = clientRef.current;
    if (!client) return;
    client.canEdit(workBeId).then(setCanEdit).catch(() => {});
  }, [connected, workBeId, authenticated]);

  const setText = useCallback((newText: string) => {
    clientRef.current?.setText(newText);
  }, []);

  const setTextLocal = useCallback((newText: string) => {
    clientRef.current?.setTextLocal(newText);
  }, []);

  const sendCursor = useCallback((index: number | null) => {
    clientRef.current?.sendAwareness(index, null, index !== null);
  }, []);

  const sendSelection = useCallback((start: number | null, end: number | null) => {
    const sel = start !== null && end !== null ? { start, end } : null;
    clientRef.current?.sendAwareness(start, sel, start !== null);
  }, []);

  const toggleWatch = useCallback(async () => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return;

    if (watchEnabledRef.current && subscriptionIdRef.current !== null) {
      client.unsubscribe(subscriptionIdRef.current);
      subscriptionIdRef.current = null;
      watchEnabledRef.current = false;
      setWatchEnabled(false);
      setContentMatches([]);
    } else {
      try {
        const subId = await client.subscribeContentWorks(workBeId!);
        subscriptionIdRef.current = subId;
        watchEnabledRef.current = true;
        setWatchEnabled(true);
      } catch (e) {
        console.error("Watch subscribe failed:", e);
      }
    }
  }, [workBeId]);

  const refreshAttribution = useCallback(() => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return;
    client
      .attributionQueryResolved(workBeId)
      .then(setAttributionSpans)
      .catch(() => {
        client.attributionQuery(workBeId).then(setAttributionSpans).catch(() => {});
      });
    client.attributionLogStatus().then(setAttributionLogStatus).catch(() => {});
  }, [workBeId]);

  const refreshAwareness = useCallback(() => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return;
    client.refreshAwareness().then(setAwareness).catch(() => {});
  }, [workBeId]);

  const login = useCallback(async (clubName: string, password: string) => {
    const resp = await fetch("/auth/login", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ club_name: clubName, password }),
    });
    if (!resp.ok) {
      const body = await resp.json().catch(() => ({}));
      throw new Error(body.error || "login failed");
    }
    const client = clientRef.current;
    if (client && client.isConnected()) {
      await client.loginByName(clubName, password);
    }
    setAuthenticated(true);
    client?.sessionTicketIssue().then((ticket) => {
      if (ticket) {
        try {
          const b64 = btoa(String.fromCharCode(...ticket));
          localStorage.setItem("xudanu_session_ticket", b64);
        } catch {}
      }
    }).catch(() => {});
  }, []);

  const createIdentity = useCallback(async (displayName: string, password: string) => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return;
    await client.createIdentity(displayName, password);
    const resp = await fetch("/auth/login", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ club_name: displayName, password }),
    });
    if (!resp.ok) throw new Error("identity created but session login failed");
    setAuthenticated(true);
    client.sessionTicketIssue().then((ticket) => {
      if (ticket) {
        try {
          const b64 = btoa(String.fromCharCode(...ticket));
          localStorage.setItem("xudanu_session_ticket", b64);
        } catch {}
      }
    }).catch(() => {});
  }, []);

  const createWork = useCallback(async (): Promise<number | null> => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return null;
    const resp = await client.sendRequest("work_create", {
      edition: { text: "" },
    });
    const val = resp as Record<string, unknown>;
    return (val.value as number) ?? null;
  }, []);

  const shareWork = useCallback(async (): Promise<void> => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return;
    try {
      await client.sendRequest("work_set_read_club", {
        work_id: workBeId,
        club_id: publicClubId,
      });
      await client.sendRequest("work_set_edit_club", {
        work_id: workBeId,
        club_id: publicClubId,
      });
    } catch (e) {
      console.error("Failed to share work:", e);
    }
  }, [workBeId, publicClubId]);

  const unshareWork = useCallback(async (): Promise<void> => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null || !identity) return;
    try {
      await client.sendRequest("work_set_edit_club", {
        work_id: workBeId,
        club_id: identity.club_id,
      });
    } catch (e) {
      console.error("Failed to unshare work:", e);
    }
  }, [workBeId, identity]);

  const narrateDiff = useCallback(async (): Promise<{ text: string; model: string; updatedText: string }> => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return { text: "", model: "", updatedText: "" };
    try {
      return await client.diffNarration(workBeId);
    } catch (e) {
      console.error("Failed to narrate diff:", e);
      return { text: `Error: ${e}`, model: "", updatedText: "" };
    }
  }, [workBeId]);

  const getWritingFeedback = useCallback(async (): Promise<{ text: string; model: string }> => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return { text: "", model: "" };
    try {
      return await client.writingFeedback(workBeId);
    } catch (e) {
      console.error("Failed to get writing feedback:", e);
      return { text: `Error: ${e}`, model: "" };
    }
  }, [workBeId]);

  const suggestTitle = useCallback(async (): Promise<string> => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return "";
    try {
      return await client.suggestTitle(workBeId);
    } catch (e) {
      console.error("Failed to suggest title:", e);
      return `Error: ${e}`;
    }
  }, [workBeId]);

  const setWorkTitle = useCallback(async (title: string) => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return;
    try {
      await client.workSetTitle(workBeId, title);
    } catch (e) {
      console.error("Failed to set work title:", e);
    }
  }, [workBeId]);

  const autoTag = useCallback(async (): Promise<{ new: Array<{name: string; id: number}>; linked: Array<{name: string; id: number}> }> => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return { new: [], linked: [] };
    try {
      return await client.workAutoTag(workBeId);
    } catch (e) {
      console.error("Failed to auto-tag:", e);
      return { new: [], linked: [] };
    }
  }, [workBeId]);

  const fetchWorkList = useCallback(async (): Promise<WorkListEntry[]> => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return [];
    try {
      return await client.fetchWorkList();
    } catch (e) {
      console.error("Failed to fetch work list:", e);
      return [];
    }
  }, []);

  const setVisibility = useCallback(async (workId: number, pubClubId: number | null) => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return;
    try {
      await client.setReadClub(workId, pubClubId);
    } catch (e) {
      console.error("Failed to set visibility:", e);
    }
  }, []);

  const getReadClub = useCallback(async (workId: number): Promise<number> => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return 0;
    try {
      return await client.getReadClub(workId);
    } catch (e) {
      console.error("Failed to get read club:", e);
      return 0;
    }
  }, []);

  const getEditClub = useCallback(async (workId: number): Promise<number> => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return 0;
    try {
      return await client.getEditClub(workId);
    } catch (e) {
      console.error("Failed to get edit club:", e);
      return 0;
    }
  }, []);

  const logout = useCallback(() => {
    setAuthenticated(false);
    fetch("/auth/logout", { method: "POST" }).catch(() => {});
    const client = clientRef.current;
    if (client) {
      client.disconnect();
      client.connect();
    }
  }, []);

  const refreshAnnotations = useCallback(() => {
    const client = clientRef.current;
    if (!client || workBeId === null) return;
    client.annotationList(workBeId).then(setAnnotations).catch(() => {});
  }, [workBeId]);

  const createAnnotation = useCallback(async (kind: string, payload: string, charStart: number, charEnd: number, isPrivate = false) => {
    const client = clientRef.current;
    if (!client || workBeId === null) return;
    const id = Date.now();
    // Optimistic update — add to local state immediately for instant feedback
    setAnnotations((prev) => [...prev, {
      annotation_id: id,
      kind,
      payload,
      char_start: charStart,
      char_end: charEnd,
      is_private: isPrivate,
      created_by: null,
      created_by_name: null,
      created_at: Math.floor(Date.now() / 1000),
    }]);
    // Send to server (don't block on response)
    client.annotationCreate(workBeId, id, kind, payload, charStart, charEnd, isPrivate)
      .then(() => refreshAnnotations())
      .catch(() => {
        // Revert on failure
        setAnnotations((prev) => prev.filter((a) => a.annotation_id !== id));
      });
  }, [workBeId, refreshAnnotations]);

  const deleteAnnotation = useCallback(async (annotationId: number) => {
    const client = clientRef.current;
    if (!client || workBeId === null) return;
    if (!client.isConnected()) return;
    // Optimistic update — remove locally immediately
    const existing = annotations.find((a) => a.annotation_id === annotationId);
    setAnnotations((prev) => prev.filter((a) => a.annotation_id !== annotationId));
    client.annotationDelete(workBeId, annotationId)
      .then(() => refreshAnnotations())
      .catch(() => {
        // Revert on failure
        if (existing) setAnnotations((prev) => [...prev, existing]);
      });
  }, [workBeId, annotations, refreshAnnotations]);

  return {
    text, connected, authenticated, reconnectAttempt, awareness, setText, setTextLocal, sendCursor, sendSelection,
    contentMatches, watchEnabled, toggleWatch, clientRef,
    attributionSpans, attributionLogStatus, refreshAttribution,
    refreshAwareness,
    identity, login, createIdentity, createWork, shareWork, unshareWork, narrateDiff,
    getWritingFeedback, llmEnabled, llmUsage, suggestTitle, setWorkTitle, autoTag, fetchWorkList,     setVisibility, getReadClub, getEditClub, publicClubId, logout,
    annotations, refreshAnnotations, createAnnotation, deleteAnnotation,
    connectionEpoch,
    isAdmin,
    canEdit,
    recentChanges,
  };
}
