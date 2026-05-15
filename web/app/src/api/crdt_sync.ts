export interface CursorPosition {
  index: number;
}

export interface SelectionRange {
  start: number;
  end: number;
}

export interface AwarenessState {
  client_id: number;
  user_name: string;
  user_color: string;
  cursor: CursorPosition | null;
  selection: SelectionRange | null;
  is_typing: boolean;
}

export interface SyncStep1 {
  type: "sync_step1";
  state_vector: Array<[string, number]>;
}

export interface SyncStep2 {
  type: "sync_step2";
  changes: string[];
}

export interface CrdtUpdate {
  type: "crdt_update";
  work_be_id: string;
  update_base64: string;
}

export interface CrdtAwareness {
  type: "crdt_awareness";
  work_be_id: string;
  state: AwarenessState;
}

export type CrdtMessage =
  | SyncStep1
  | SyncStep2
  | CrdtUpdate
  | CrdtAwareness;

export type AwarenessCallback = (states: AwarenessState[]) => void;
export type SyncCallback = (message: CrdtMessage) => void;
export type ConnectionCallback = (connected: boolean) => void;

export class CrdtSyncClient {
  private ws: WebSocket | null = null;
  private awarenessCallbacks: AwarenessCallback[] = [];
  private syncCallbacks: SyncCallback[] = [];
  private connectionCallbacks: ConnectionCallback[] = [];
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private pendingUpdates: string[] = [];
  private workBeId: string;
  private url: string;
  private connected = false;
  private localAwareness: AwarenessState | null = null;

  constructor(url: string, workBeId: string) {
    this.url = url;
    this.workBeId = workBeId;
  }

  connect(): void {
    if (this.ws?.readyState === WebSocket.OPEN) return;

    this.ws = new WebSocket(this.url);
    this.ws.binaryType = "arraybuffer";

    this.ws.onopen = () => {
      this.connected = true;
      this.connectionCallbacks.forEach((cb) => cb(true));
      this.sendSyncStep1();
      this.flushPending();
      if (this.localAwareness) {
        this.sendAwareness(this.localAwareness);
      }
    };

    this.ws.onmessage = (event) => {
      this.handleMessage(event.data);
    };

    this.ws.onclose = () => {
      this.connected = false;
      this.connectionCallbacks.forEach((cb) => cb(false));
      this.scheduleReconnect();
    };

    this.ws.onerror = () => {
      this.ws?.close();
    };
  }

  disconnect(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    this.ws?.close();
    this.ws = null;
    this.connected = false;
  }

  sendUpdate(updateBase64: string): void {
    const msg: CrdtUpdate = {
      type: "crdt_update",
      work_be_id: this.workBeId,
      update_base64: updateBase64,
    };
    this.send(JSON.stringify(msg));
  }

  updateAwareness(state: AwarenessState): void {
    this.localAwareness = state;
    this.sendAwareness(state);
  }

  onAwareness(cb: AwarenessCallback): () => void {
    this.awarenessCallbacks.push(cb);
    return () => {
      this.awarenessCallbacks = this.awarenessCallbacks.filter((c) => c !== cb);
    };
  }

  onSync(cb: SyncCallback): () => void {
    this.syncCallbacks.push(cb);
    return () => {
      this.syncCallbacks = this.syncCallbacks.filter((c) => c !== cb);
    };
  }

  onConnectionChange(cb: ConnectionCallback): () => void {
    cb(this.connected);
    this.connectionCallbacks.push(cb);
    return () => {
      this.connectionCallbacks = this.connectionCallbacks.filter(
        (c) => c !== cb,
      );
    };
  }

  isConnected(): boolean {
    return this.connected;
  }

  private handleMessage(data: unknown): void {
    let text: string;
    if (data instanceof ArrayBuffer) {
      text = new TextDecoder().decode(data);
    } else if (typeof data === "string") {
      text = data;
    } else {
      return;
    }

    try {
      const msg = JSON.parse(text) as CrdtMessage;
      switch (msg.type) {
        case "crdt_awareness":
          this.awarenessCallbacks.forEach((cb) => cb([msg.state]));
          break;
        default:
          this.syncCallbacks.forEach((cb) => cb(msg));
      }
    } catch {
      // ignore non-JSON messages
    }
  }

  private sendSyncStep1(): void {
    const msg: SyncStep1 = { type: "sync_step1", state_vector: [] };
    this.send(JSON.stringify(msg));
  }

  private sendAwareness(state: AwarenessState): void {
    const msg: CrdtAwareness = {
      type: "crdt_awareness",
      work_be_id: this.workBeId,
      state,
    };
    this.send(JSON.stringify(msg));
  }

  private send(data: string): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(data);
    } else {
      this.pendingUpdates.push(data);
    }
  }

  private flushPending(): void {
    const pending = this.pendingUpdates;
    this.pendingUpdates = [];
    for (const msg of pending) {
      this.send(msg);
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer) return;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, 3000);
  }
}
