const PROTOCOL_VERSION = 2;

export interface AwarenessState {
  session_id: number;
  user_name: string;
  cursor: { index: number } | null;
  selection: { start: number; end: number } | null;
  is_typing: boolean;
}

type ResponseHandler = (value: unknown, isError: boolean) => void;

export class CrdtSyncClient {
  private ws: WebSocket | null = null;
  private requestId = 0;
  private pending = new Map<number, ResponseHandler>();
  private text = "";
  private textListeners = new Set<(text: string) => void>();
  private awarenessListeners = new Set<(states: AwarenessState[]) => void>();
  private connectionListeners = new Set<(connected: boolean) => void>();
  private connected = false;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private url: string;
  private workBeId: number;
  private sessionId: number | null = null;
  private crdtReady = false;

  constructor(url: string, workBeId: number) {
    this.url = url;
    this.workBeId = workBeId;
  }

  connect(): void {
    if (this.ws?.readyState === WebSocket.OPEN) return;

    this.ws = new WebSocket(`${this.url}?format=json&version=${PROTOCOL_VERSION}`);
    this.ws.onopen = () => this.onOpen();
    this.ws.onmessage = (e) => this.onMessage(e.data);
    this.ws.onclose = () => this.onClose();
    this.ws.onerror = () => this.ws?.close();
  }

  disconnect(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    if (this.crdtReady && this.sessionId !== null) {
      this.sendRequest("crdt_sync_close", { work_id: this.workBeId });
      this.crdtReady = false;
    }
    this.ws?.close();
    this.ws = null;
    this.connected = false;
  }

  getText(): string {
    return this.text;
  }

  setText(newText: string): void {
    const oldText = this.text;
    if (newText === oldText) return;
    this.text = newText;

    if (this.crdtReady) {
      this.sendTextDelta(oldText, newText);
    }

    this.textListeners.forEach((cb) => cb(newText));
  }

  onTextChange(cb: (text: string) => void): () => void {
    this.textListeners.add(cb);
    return () => { this.textListeners.delete(cb); };
  }

  onAwarenessChange(cb: (states: AwarenessState[]) => void): () => void {
    this.awarenessListeners.add(cb);
    return () => { this.awarenessListeners.delete(cb); };
  }

  onConnectionChange(cb: (connected: boolean) => void): () => void {
    cb(this.connected);
    this.connectionListeners.add(cb);
    return () => { this.connectionListeners.delete(cb); };
  }

  isConnected(): boolean {
    return this.connected;
  }

  sendAwareness(cursor: number | null, selection: { start: number; end: number } | null, isTyping: boolean): void {
    if (!this.crdtReady) return;
    this.sendRequest("crdt_awareness_update", {
      work_id: this.workBeId,
      state: {
        session_id: this.sessionId ?? 0,
        user_name: "User",
        cursor: cursor !== null ? { index: cursor } : null,
        selection,
        is_typing: isTyping,
      },
    });
  }

  private nextId(): number {
    return ++this.requestId;
  }

  private sendRequest(op: string, payload?: object): Promise<unknown> {
    return new Promise((resolve, reject) => {
      const id = this.nextId();
      const frame: Record<string, unknown> = {
        v: PROTOCOL_VERSION,
        type: "request",
        id,
        op,
      };
      if (payload !== undefined) {
        frame.payload = payload;
      }
      this.pending.set(id, (value, isError) => {
        if (isError) {
          reject(new Error(String(value) || "unknown error"));
        } else {
          resolve(value);
        }
      });
      this.wsSend(JSON.stringify(frame));
    });
  }

  private wsSend(data: string): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(data);
    }
  }

  private async onOpen(): Promise<void> {
    this.connected = true;
    this.connectionListeners.forEach((cb) => cb(true));

    try {
      const resp = await this.sendRequest("session_connect");
      this.sessionId = extractValue(resp) as number;
      await this.sendRequest("session_login_public");

      const openResp = await this.sendRequest("crdt_sync_open", {
        work_id: this.workBeId,
      });
      const inner = extractValue(openResp) as Record<string, unknown>;
      this.text = (inner.current_text as string) || "";
      this.crdtReady = true;
      this.textListeners.forEach((cb) => cb(this.text));

      this.sendRequest("crdt_awareness_get", {
        work_id: this.workBeId,
      }).then((awareResp) => {
        const awareVal = extractValue(awareResp) as Record<string, unknown>;
        const states = awareVal.states as AwarenessState[] || [];
        this.awarenessListeners.forEach((cb) => cb(states));
      }).catch(() => {});
    } catch (e) {
      console.error("CRDT session setup failed:", e);
    }
  }

  private onMessage(data: unknown): void {
    let text: string;
    if (data instanceof ArrayBuffer) {
      text = new TextDecoder().decode(data);
    } else if (typeof data === "string") {
      text = data;
    } else {
      return;
    }

    try {
      const frame = JSON.parse(text) as Record<string, unknown>;

      if (frame.type === "response" || frame.type === "error") {
        const id = frame.id as number;
        const handler = this.pending.get(id);
        if (handler) {
          this.pending.delete(id);
          const isError = frame.type === "error";
          handler(isError ? frame.message : frame.value, isError);
        }
      }

      if (frame.type === "event") {
        this.handleEvent(frame);
      }
    } catch {
      // ignore non-JSON or handshake messages
    }
  }

  private handleEvent(frame: Record<string, unknown>): void {
    const event = frame.event as Record<string, unknown> | undefined;
    if (!event) return;

    const eventType = event.type as string;

    if (eventType === "work_revised") {
      const payload = event.payload as Record<string, unknown> | undefined;
      if (payload && payload.work_be_id === this.workBeId) {
        this.refreshText();
      }
    }
  }

  private async refreshText(): Promise<void> {
    if (!this.crdtReady) return;
    try {
      await this.sendRequest("crdt_sync_full_state", {
        work_id: this.workBeId,
      });
    } catch {
      // ignore
    }
  }

  private onClose(): void {
    this.connected = false;
    this.crdtReady = false;
    this.connectionListeners.forEach((cb) => cb(false));
    this.pending.forEach((handler) => handler("connection closed", true));
    this.pending.clear();
    this.scheduleReconnect();
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer) return;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, 3000);
  }

  private sendTextDelta(oldText: string, newText: string): void {
    if (oldText === newText) return;

    const prefix = commonPrefix(oldText, newText);
    const oldRemaining = oldText.slice(prefix);
    const newRemaining = newText.slice(prefix);
    const suffix = commonSuffix(oldRemaining, newRemaining);
    const deleteLen = oldText.length - prefix - suffix;
    const insertText = newText.slice(prefix, newText.length - suffix);

    const ops: Array<{ type: string; count?: number; text?: string }> = [];
    if (prefix > 0) {
      ops.push({ type: "retain", count: prefix });
    }
    if (deleteLen > 0) {
      ops.push({ type: "delete", count: deleteLen });
    }
    if (insertText.length > 0) {
      ops.push({ type: "insert", text: insertText });
    }

    this.sendRequest("work_revise_delta", {
      work_id: this.workBeId,
      base_revision: 0,
      ops,
    }).catch((e) => {
      console.error("Failed to send text delta:", e);
    });
  }
}

function extractValue(resp: unknown): unknown {
  const r = resp as Record<string, unknown>;
  if (r && typeof r === "object" && "type" in r && "value" in r) {
    return r.value;
  }
  return resp;
}

function commonPrefix(a: string, b: string): number {
  let i = 0;
  const len = Math.min(a.length, b.length);
  while (i < len && a.charCodeAt(i) === b.charCodeAt(i)) i++;
  return i;
}

function commonSuffix(a: string, b: string): number {
  let i = 0;
  const aLen = a.length;
  const bLen = b.length;
  while (i < aLen && i < bLen && a.charCodeAt(aLen - 1 - i) === b.charCodeAt(bLen - 1 - i)) i++;
  return i;
}
