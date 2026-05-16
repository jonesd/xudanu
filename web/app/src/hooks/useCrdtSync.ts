import { useState, useEffect, useRef, useCallback } from "react";
import { CrdtSyncClient, type AwarenessState } from "../api/crdt_sync";

export interface CrdtSyncState {
  text: string;
  connected: boolean;
  awareness: AwarenessState[];
  setText: (text: string) => void;
  sendCursor: (index: number | null) => void;
  sendSelection: (start: number | null, end: number | null) => void;
}

export function useCrdtSync(
  wsUrl: string | null,
  workBeId: number | null,
): CrdtSyncState {
  const clientRef = useRef<CrdtSyncClient | null>(null);
  const [text, setTextState] = useState("");
  const [connected, setConnected] = useState(false);
  const [awareness, setAwareness] = useState<AwarenessState[]>([]);

  useEffect(() => {
    if (!wsUrl || workBeId === null) return;

    const client = new CrdtSyncClient(wsUrl, workBeId);
    clientRef.current = client;

    const unsubText = client.onTextChange(setTextState);
    const unsubConn = client.onConnectionChange(setConnected);
    const unsubAware = client.onAwarenessChange(setAwareness);

    client.connect();

    return () => {
      unsubText();
      unsubConn();
      unsubAware();
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

  return { text, connected, awareness, setText, sendCursor, sendSelection };
}
