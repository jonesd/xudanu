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

  useEffect(() => {
    if (!wsUrl || workBeId === null) return;

    const client = new CrdtSyncClient(wsUrl, workBeId);
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
  }, []);

  const login = useCallback(async (clubName: string, password: string) => {
    const client = clientRef.current;
    if (!client || !client.isConnected()) return;
    await client.loginByName(clubName, password);
  }, []);

  return {
    text, connected, awareness, setText, sendCursor, sendSelection,
    contentMatches, watchEnabled, toggleWatch, clientRef,
    attributionSpans, attributionLogStatus, refreshAttribution,
    refreshAwareness,
    identity, createIdentity, login,
  };
}
