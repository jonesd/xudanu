import { useState, useEffect, useRef, useCallback } from "react";
import { CrdtSyncClient, type AwarenessState, type ContentMatch, type AttributionSpan, type AttributionLogStatus, type WhoAmIEntry } from "../api/crdt_sync";

export interface CrdtSyncState {
  text: string;
  connected: boolean;
  awareness: AwarenessState[];
  setText: (text: string) => void;
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
  narrateDiff: () => Promise<string>;
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
  const credentialsRef = useRef<{ name: string; password: string } | null>(null);
  const reconnectCountRef = useRef(0);

  useEffect(() => {
    if (!wsUrl) return;

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

    client.connect();

    return () => {
      unsubText();
      unsubConn();
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
    if (!connected || !credentialsRef.current) return;
    const { name, password } = credentialsRef.current;
    reconnectCountRef.current += 1;
    const count = reconnectCountRef.current;
    const client = clientRef.current;
    if (!client) return;
    client.loginByName(name, password).catch((e) => {
      if (reconnectCountRef.current === count) {
        console.error("Re-login failed after reconnect:", e);
        credentialsRef.current = null;
      }
    });
  }, [connected]);

  const setText = useCallback((newText: string) => {
    clientRef.current?.setText(newText);
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
  }, []);

  const login = useCallback(async (clubName: string, password: string) => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return;
    await client.loginByName(clubName, password);
    credentialsRef.current = { name: clubName, password };
  }, []);

  const createWork = useCallback(async (): Promise<number | null> => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return null;
    const resp = await client.sendRequest("work_create", {
      edition: { text: "Start typing here..." },
    });
    const val = resp as Record<string, unknown>;
    return (val.value as number) ?? null;
  }, []);

  const shareWork = useCallback(async (): Promise<void> => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return;
    try {
      const statsResp = await client.sendRequest("server_stats");
      const stats = (statsResp as Record<string, unknown>)?.value as Record<string, unknown> | undefined;
      const publicClubId = stats?.public_club_id as number | undefined;
      if (publicClubId == null) return;
      await client.sendRequest("work_set_edit_club", {
        work_id: workBeId,
        club_id: publicClubId,
      });
    } catch (e) {
      console.error("Failed to share work:", e);
    }
  }, [workBeId]);

  const narrateDiff = useCallback(async (): Promise<string> => {
    const client = clientRef.current;
    if (!client || !client.isConnected() || workBeId === null) return "";
    try {
      return await client.diffNarration(workBeId);
    } catch (e) {
      console.error("Failed to narrate diff:", e);
      return `Error: ${e}`;
    }
  }, [workBeId]);

  return {
    text, connected, awareness, setText, sendCursor, sendSelection,
    contentMatches, watchEnabled, toggleWatch, clientRef,
    attributionSpans, attributionLogStatus, refreshAttribution,
    refreshAwareness,
    identity, createIdentity, login, createWork, shareWork, narrateDiff,
  };
}
