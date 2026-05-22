const PROTOCOL_VERSION = 2;

export interface AwarenessState {
  session_id: number;
  user_name: string;
  cursor: { index: number } | null;
  selection: { start: number; end: number } | null;
  is_typing: boolean;
}

export interface ContentMatch {
  fossil_id: number;
  edition_be_id: number;
  is_direct: boolean;
  work_be_id?: number;
  title?: string;
}

export interface AttributionSpan {
  start: number;
  end: number;
  author_public_key: number[];
  author_display_name: string | null;
  author_club_id: number | null;
  signature_valid: boolean;
  timestamp: number;
  server_id: number[];
}

export interface AttributionLogStatus {
  entry_count: number;
  chain_valid: boolean;
  last_sequence: number;
}

export interface WhoAmIEntry {
  club_id: number;
  display_name: string;
}

type IdentityListener = (identity: WhoAmIEntry | null) => void;

type ResponseHandler = (value: unknown, isError: boolean) => void;

export class CrdtSyncClient {
  private ws: WebSocket | null = null;
  private requestId = 0;
  private pending = new Map<number, ResponseHandler>();
  private text = "";
  private textListeners = new Set<(text: string) => void>();
  private awarenessListeners = new Set<(states: AwarenessState[]) => void>();
  private connectionListeners = new Set<(connected: boolean) => void>();
  private contentMatchListeners = new Set<(match: ContentMatch) => void>();
  private identityListeners = new Set<IdentityListener>();
  private connected = false;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private url: string;
  private workBeId: number;
  private sessionId: number | null = null;
  private crdtReady = false;
  private currentIdentity: WhoAmIEntry | null = null;

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

  onContentMatch(cb: (match: ContentMatch) => void): () => void {
    this.contentMatchListeners.add(cb);
    return () => { this.contentMatchListeners.delete(cb); };
  }

  async subscribeContentWorks(targetId: number): Promise<number> {
    const id = this.nextId();
    const frame = JSON.stringify({
      v: PROTOCOL_VERSION,
      type: "subscribe",
      id,
      payload: { detector_type: "content_works", target_id: targetId },
    });
    return new Promise((resolve, reject) => {
      this.pending.set(id, (value, isError) => {
        if (isError) {
          reject(new Error(String(value) || "subscribe failed"));
        } else {
          const val = extractValue(value) as number;
          resolve(val);
        }
      });
      this.wsSend(frame);
    });
  }

  unsubscribe(subscriptionId: number): void {
    const frame = JSON.stringify({
      v: PROTOCOL_VERSION,
      type: "unsubscribe",
      id: subscriptionId,
    });
    this.wsSend(frame);
  }

  isConnected(): boolean {
    return this.connected;
  }

  async attributionQuery(workId: number): Promise<AttributionSpan[]> {
    const resp = await this.sendRequest("attribution_query", {
      work_id: workId,
      start: null,
      end: null,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.spans as AttributionSpan[]) || [];
  }

  async attributionLogStatus(): Promise<AttributionLogStatus> {
    const resp = await this.sendRequest("attribution_log_status");
    return extractValue(resp) as AttributionLogStatus;
  }

  async createIdentity(displayName: string, password: string): Promise<WhoAmIEntry> {
    const pwBytes = Array.from(new TextEncoder().encode(password));
    const resp = await this.sendRequest("club_create_personal", {
      display_name: displayName,
      password: pwBytes,
    });
    const clubId = extractValue(resp) as number;
    await this.loginByName(displayName, password);
    const identity: WhoAmIEntry = { club_id: clubId, display_name: displayName };
    this.currentIdentity = identity;
    this.identityListeners.forEach((cb) => cb(identity));
    return identity;
  }

  async loginByName(clubName: string, password: string): Promise<void> {
    console.log("[loginByName] step 1: session_login_by_name", clubName);
    const loginResp = await this.sendRequest("session_login_by_name", { club_name: clubName });
    console.log("[loginByName] step 1 response:", JSON.stringify(loginResp));
    const pwBytes = Array.from(new TextEncoder().encode(password));
    console.log("[loginByName] step 2: session_authenticate (pw len:", pwBytes.length, ")");
    try {
      const authResp = await Promise.race([
        this.sendRequest("session_authenticate", {
          credential: { password: Array.from(pwBytes) },
        }),
        new Promise((_, reject) => setTimeout(() => reject(new Error("session_authenticate timed out after 10s")), 10000)),
      ]);
      console.log("[loginByName] step 2 response:", JSON.stringify(authResp));
    } catch (e) {
      console.error("[loginByName] step 2 FAILED:", e);
      throw e;
    }
    console.log("[loginByName] step 3: club_who_am_i");
    const whoResp = await this.sendRequest("club_who_am_i");
    console.log("[loginByName] step 3 response:", JSON.stringify(whoResp));
    const val = extractValue(whoResp) as { clubs: [number, string][] };
    const clubs = val.clubs || [];
    console.log("[loginByName] clubs:", clubs);
    if (clubs.length > 0) {
      const [clubId, name] = clubs[0];
      this.currentIdentity = { club_id: clubId, display_name: name };
    }
    this.identityListeners.forEach((cb) => cb(this.currentIdentity));

    if (this.crdtReady && this.workBeId) {
      try {
        await this.sendRequest("crdt_register_author", { work_id: this.workBeId });
      } catch (e) {
        console.error("[loginByName] crdt_register_author failed:", e);
      }
      this.sendAwareness(null, null, false);
    }
  }

  async checkWhoAmI(): Promise<WhoAmIEntry | null> {
    try {
      const resp = await this.sendRequest("club_who_am_i");
      const val = extractValue(resp) as { clubs: [number, string][] };
      const clubs = val.clubs || [];
      if (clubs.length > 0) {
        const [clubId, name] = clubs[0];
        this.currentIdentity = { club_id: clubId, display_name: name };
      } else {
        this.currentIdentity = null;
      }
    } catch {
      this.currentIdentity = null;
    }
    this.identityListeners.forEach((cb) => cb(this.currentIdentity));
    return this.currentIdentity;
  }

  getIdentity(): WhoAmIEntry | null {
    return this.currentIdentity;
  }

  onIdentityChange(cb: IdentityListener): () => void {
    this.identityListeners.add(cb);
    return () => { this.identityListeners.delete(cb); };
  }

  sendAwareness(cursor: number | null, selection: { start: number; end: number } | null, isTyping: boolean): void {
    if (!this.crdtReady) return;
    this.sendRequest("crdt_awareness_update", {
      work_id: this.workBeId,
      state: {
        session_id: this.sessionId ?? 0,
        user_name: this.currentIdentity?.display_name || `user-${(this.sessionId ?? 0).toString(16).slice(-4)}`,
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

      this.checkWhoAmI();
    } catch (e) {
      console.error("CRDT session setup failed:", e);
      const url = new URL(window.location.href);
      if (url.searchParams.has("work")) {
        url.searchParams.delete("work");
        window.history.replaceState({}, "", url.toString());
        window.location.reload();
      }
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

    if (eventType === "content_match") {
      const payload = event.payload as Record<string, unknown> | undefined;
      if (payload) {
        const match: ContentMatch = {
          fossil_id: payload.fossil_id as number,
          edition_be_id: payload.edition_be_id as number,
          is_direct: payload.is_direct as boolean,
          work_be_id: payload.work_be_id as number | undefined,
          title: payload.title as string | undefined,
        };
        this.contentMatchListeners.forEach((cb) => cb(match));
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
