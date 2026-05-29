import { useState, useEffect, useRef, useCallback } from "react";
import { CrdtSyncClient, type AwarenessState, type ContentMatch, type AttributionSpan, type AttributionLogStatus, type WhoAmIEntry, type WorkListEntry } from "../api/crdt_sync";

export interface CrdtSyncState {
  text: string;
  connected: boolean;
  authenticated: boolean;
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
  createIdentity: (displayName: string, password: string) => Promise<void>;
  login: (clubName: string, password: string) => Promise<void>;
  createWork: () => Promise<number | null>;
  shareWork: () => Promise<void>;
  unshareWork: () => Promise<void>;
  narrateDiff: () => Promise<{ text: string; model: string; updatedText: string }>;
  getWritingFeedback: () => Promise<{ text: string; model: string }>;
  llmEnabled: boolean;
  fetchWorkList: () => Promise<WorkListEntry[]>;
  setVisibility: (workId: number, publicClubId: number | null) => Promise<void>;
  getReadClub: (workId: number) => Promise<number>;
  getEditClub: (workId: number) => Promise<number>;
  publicClubId: number;
  logout: () => void;
}

export function useCrdtSync(
  wsUrl: string | null,
  workBeId: number | null,
): CrdtSyncState {
  const clientRef = useRef<CrdtSyncClient | null>(null);
  const [text, setTextState] = useState("");
  const [connected, setConnected] = useState(false);
  const [awareness, setAwareness] = useState<AwarenessState[]>([]);
  const [contentMatches, setContentMatches] = useState<ContentMatch[]>([]);
  const [watchEnabled, setWatchEnabled] = useState(false);
  const watchEnabledRef = useRef(false);
  const subscriptionIdRef = useRef<number | null>(null);
  const [attributionSpans, setAttributionSpans] = useState<AttributionSpan[]>([]);
  const [attributionLogStatus, setAttributionLogStatus] = useState<AttributionLogStatus | null>(null);
  const [identity, setIdentity] = useState<WhoAmIEntry | null>(null);
  const [llmEnabled, setLlmEnabled] = useState(false);
  const [publicClubId, setPublicClubId] = useState(0);
  const credentialsRef = useRef<{ name: string; password: string } | null>(null);
  const reconnectCountRef = useRef(0);
  const [authenticated, setAuthenticated] = useState(false);

  useEffect(() => {
    try {
      const saved = localStorage.getItem("xudanu_credentials");
      if (saved) {
        credentialsRef.current = JSON.parse(saved);
      }
    } catch (e) {
      console.warn("useCrdtSync: failed to parse saved credentials:", e);
    }
  }, []);

  useEffect(() => {
    if (!wsUrl) return;

    setTextState("");

    const client = new CrdtSyncClient(wsUrl, workBeId ?? 0);
    clientRef.current = client;

    const unsubText = client.onTextChange(setTextState);
    const unsubConn = client.onConnectionChange(setConnected);
    const unsubAware = client.onAwarenessChange(setAwareness);
    const MAX_CONTENT_MATCHES = 200;
    const unsubMatch = client.onContentMatch((match) => {
      setContentMatches((prev) => {
        const next = [...prev, match];
        return next.length > MAX_CONTENT_MATCHES ? next.slice(-MAX_CONTENT_MATCHES) : next;
      });
    });
    const unsubIdentity = client.onIdentityChange(setIdentity);

    const unsubConn2 = client.onConnectionChange((isConnected) => {
      if (isConnected) {
        client.sendRequest("server_stats").then((resp) => {
          const r = resp as Record<string, unknown>;
          if (r && "value" in r) {
            const val = r.value as Record<string, unknown>;
            setLlmEnabled(val?.llm_enabled === true);
            if (typeof val?.public_club_id === "number") {
              setPublicClubId(val.public_club_id);
            }
          }
        }).catch(() => {});
      }
    });

    client.connect();

    return () => {
      unsubText();
      unsubConn();
      unsubConn2();
      unsubAware();
      unsubMatch();
      unsubIdentity();
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
  }, [wsUrl, workBeId]);

  useEffect(() => {
    if (!connected) {
      setAuthenticated(false);
      return;
    }
    if (!credentialsRef.current) {
      setAuthenticated(false);
      return;
    }
    const { name, password } = credentialsRef.current;
    reconnectCountRef.current += 1;
    const count = reconnectCountRef.current;
    const client = clientRef.current;
    if (!client) return;
    client.loginByName(name, password).then(() => {
      if (reconnectCountRef.current === count) {
        setAuthenticated(true);
      }
    }).catch((e) => {
      if (reconnectCountRef.current === count) {
        console.error("Re-login failed after reconnect:", e);
        credentialsRef.current = null;
        setAuthenticated(false);
      }
    });
  }, [connected]);

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
    clientRef.current?.sendAwareness(null, sel, start !== null);
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
    client.attributionQuery(workBeId).then(setAttributionSpans).catch(() => {});
    client.attributionLogStatus().then(setAttributionLogStatus).catch(() => {});
  }, [workBeId]);

  const refreshAwareness = useCallback(() => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return;
    client.refreshAwareness().then(setAwareness).catch(() => {});
  }, [workBeId]);

  const createIdentity = useCallback(async (displayName: string, password: string) => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return;
    await client.createIdentity(displayName, password);
    credentialsRef.current = { name: displayName, password };
    try { localStorage.setItem("xudanu_credentials", JSON.stringify(credentialsRef.current)); } catch (e) { console.error("useCrdtSync: CRITICAL - failed to persist credentials:", e); }
    setAuthenticated(true);
  }, []);

  const login = useCallback(async (clubName: string, password: string) => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return;
    await client.loginByName(clubName, password);
    credentialsRef.current = { name: clubName, password };
    try { localStorage.setItem("xudanu_credentials", JSON.stringify(credentialsRef.current)); } catch (e) { console.error("useCrdtSync: CRITICAL - failed to persist credentials:", e); }
    setAuthenticated(true);
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
    credentialsRef.current = null;
    setAuthenticated(false);
    try { localStorage.removeItem("xudanu_credentials"); } catch (e) { console.error("useCrdtSync: CRITICAL - failed to clear credentials on logout:", e); }
    const client = clientRef.current;
    if (client) {
      client.disconnect();
      client.connect();
    }
  }, []);

  return {
    text, connected, authenticated, awareness, setText, setTextLocal, sendCursor, sendSelection,
    contentMatches, watchEnabled, toggleWatch, clientRef,
    attributionSpans, attributionLogStatus, refreshAttribution,
    refreshAwareness,
    identity, createIdentity, login,     createWork, shareWork, unshareWork, narrateDiff,
    getWritingFeedback, llmEnabled, fetchWorkList,     setVisibility, getReadClub, getEditClub, publicClubId, logout,
  };
}
