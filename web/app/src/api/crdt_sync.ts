const PROTOCOL_VERSION = 2;

export interface AwarenessState {
  session_id: number;
  user_name: string;
  cursor: { index: number } | null;
  selection: { start: number; end: number } | null;
  is_typing: boolean;
}

export interface OutlineEntry {
  level: number;
  text: string;
  line: number;
  char_offset: number;
}

export interface SearchMatchItem {
  char_offset: number;
  line: number;
  context: string;
}

export interface SearchResult {
  matches: SearchMatchItem[];
  totalMatches: number;
}

export interface GotoResult {
  line: number;
  charOffset: number;
  context: string;
  contextStartLine: number;
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
  author_type: string | null;
  llm_model: string | null;
  historical_author_id: number | null;
}

export interface AttributionLogStatus {
  entry_count: number;
  chain_valid: boolean;
  last_sequence: number;
  has_log: boolean;
}

export interface HistoricalAuthor {
  be_id: number;
  name: string;
  display_name: string;
  birth_year: number | null;
  death_year: number | null;
  external_ids: Record<string, string>;
  source_bibliography: string;
}

export interface HistoricalAuthorEntry {
  be_id: number;
  name: string;
  display_name: string;
  birth_year: number | null;
  death_year: number | null;
}

export interface SourceDetectResult {
  source_type: string;
  detected: boolean;
  content_start_line: number;
  content_end_line: number;
  total_lines: number;
  metadata: Record<string, string>;
}

export interface SourcePatternEntry {
  source_type: string;
  display_name: string;
}

export interface WhoAmIEntry {
  club_id: number;
  display_name: string;
}

export interface LlmUsageSummary {
  total_requests: number;
  total_prompt_chars: number;
  total_response_chars: number;
  by_feature: Record<string, { count: number; prompt_chars: number; response_chars: number }>;
}

export interface LinkEntry {
  link_id: number;
  origin: number;
  destination: number;
  origin_ref: HyperRefPayload | null;
  destination_ref: HyperRefPayload | null;
}

export interface HyperRefPayload {
  kind: string;
  work_context: number | null;
  original_context: number | null;
  excerpt: string | null;
}

export interface SharedRegion {
  work_a: number;
  start_a: number;
  end_a: number;
  work_b: number;
  start_b: number;
  end_b: number;
  text: string;
}

export interface TransclusionMarker {
  start: number;
  end: number;
  linkId: number;
  direction: "outgoing" | "incoming";
  otherWorkId: number;
  otherWorkTitle: string;
  color: string;
}

export interface WorkListEntry {
  work_id: number;
  owner: number | null;
  revision_count: number;
  is_grabbed: boolean;
  title: string;
  read_club: number | null;
  is_source?: boolean;
  content_start_line?: number;
  content_end_line?: number;
  source_author_id?: number;
  source_edition_info?: string;
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

    const wsUrl = `${this.url}?format=json&version=${PROTOCOL_VERSION}`;

    fetch("/csrf-token")
      .then((r) => r.json())
      .then((d) => {
        if (d.csrf_token) {
          this.openWs(wsUrl + "&csrf_token=" + encodeURIComponent(d.csrf_token));
        } else {
          this.openWs(wsUrl);
        }
      })
      .catch(() => {
        this.openWs(wsUrl);
      });
  }

  private openWs(url: string): void {
    this.ws = new WebSocket(url);
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

  setTextLocal(newText: string): void {
    if (newText === this.text) return;
    this.text = newText;
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

  async textRange(
    workId: number,
    startChar: number,
    endChar: number,
  ): Promise<{ text: string; totalChars: number; startChar: number; endChar: number }> {
    const resp = await this.sendRequest("work_text_range", {
      work_id: workId,
      start_char: startChar,
      end_char: endChar,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return {
      text: (val.text as string) || "",
      totalChars: (val.total_chars as number) || 0,
      startChar: (val.start_char as number) || 0,
      endChar: (val.end_char as number) || 0,
    };
  }

  async workOutline(workId: number): Promise<OutlineEntry[]> {
    const resp = await this.sendRequest("work_outline", { work_id: workId });
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.entries as OutlineEntry[]) || [];
  }

  async workSearch(workId: number, query: string, maxResults?: number): Promise<SearchResult> {
    const resp = await this.sendRequest("work_search", {
      work_id: workId,
      query,
      max_results: maxResults ?? null,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return {
      matches: (val.matches as SearchMatchItem[]) || [],
      totalMatches: (val.total_matches as number) || 0,
    };
  }

  async workGoto(workId: number, line?: number, char?: number): Promise<GotoResult> {
    const resp = await this.sendRequest("work_goto", {
      work_id: workId,
      line: line ?? null,
      char: char ?? null,
      context_lines: 10,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return {
      line: (val.line as number) || 0,
      charOffset: (val.char_offset as number) || 0,
      context: (val.context as string) || "",
      contextStartLine: (val.context_start_line as number) || 0,
    };
  }

  async diffNarration(workId: number): Promise<{ text: string; model: string; updatedText: string }> {
    const resp = await this.sendRequest("work_diff_narration", {
      work_id: workId,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return { text: (val.narration as string) || "", model: (val.llm_model as string) || "", updatedText: (val.updated_text as string) || "" };
  }

  async writingFeedback(workId: number): Promise<{ text: string; model: string }> {
    const resp = await this.sendRequest("work_writing_feedback", {
      work_id: workId,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return { text: (val.feedback as string) || "", model: (val.llm_model as string) || "" };
  }

  async llmUsage(): Promise<LlmUsageSummary | null> {
    const resp = await this.sendRequest("server_stats");
    const val = (resp as Record<string, unknown>)?.value as Record<string, unknown> | undefined;
    if (!val) return null;
    return val.llm_usage as LlmUsageSummary || null;
  }

  async refreshAwareness(): Promise<AwarenessState[]> {
    const resp = await this.sendRequest("crdt_awareness_get", {
      work_id: this.workBeId,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.states as AwarenessState[]) || [];
  }

  async attributionLogStatus(): Promise<AttributionLogStatus> {
    const resp = await this.sendRequest("attribution_log_status");
    return extractValue(resp) as AttributionLogStatus;
  }

  async registerHistoricalAuthor(
    name: string,
    displayName: string,
    birthYear: number | null,
    deathYear: number | null,
    externalIds: Record<string, string>,
    sourceBibliography: string,
  ): Promise<HistoricalAuthor> {
    const resp = await this.sendRequest("historical_author_register", {
      name,
      display_name: displayName,
      birth_year: birthYear,
      death_year: deathYear,
      external_ids: externalIds,
      source_bibliography: sourceBibliography,
    });
    return extractValue(resp) as HistoricalAuthor;
  }

  async getHistoricalAuthor(authorId: number): Promise<HistoricalAuthor> {
    const resp = await this.sendRequest("historical_author_get", {
      author_id: authorId,
    });
    return extractValue(resp) as HistoricalAuthor;
  }

  async searchHistoricalAuthors(query: string): Promise<HistoricalAuthorEntry[]> {
    const resp = await this.sendRequest("historical_author_search", { query });
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.authors as HistoricalAuthorEntry[]) || [];
  }

  async listHistoricalAuthors(): Promise<HistoricalAuthorEntry[]> {
    const resp = await this.sendRequest("historical_author_list");
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.authors as HistoricalAuthorEntry[]) || [];
  }

  async importSourceWork(
    authorId: number,
    title: string,
    text: string,
    editionInfo: string,
    skipPrefixLines: number,
    skipSuffixLines: number,
  ): Promise<{ workId: number; authorId: number; title: string; textLength: number }> {
    const resp = await this.sendRequest("import_source_work", {
      author_id: authorId,
      title,
      text,
      edition_info: editionInfo,
      skip_prefix_lines: skipPrefixLines,
      skip_suffix_lines: skipSuffixLines,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return {
      workId: (val.work_id as number) || 0,
      authorId: (val.author_id as number) || 0,
      title: (val.title as string) || "",
      textLength: (val.text_length as number) || 0,
    };
  }

  async detectSource(text: string): Promise<SourceDetectResult> {
    const resp = await this.sendRequest("source_detect", { text });
    return extractValue(resp) as SourceDetectResult;
  }

  async listSourcePatterns(): Promise<SourcePatternEntry[]> {
    const resp = await this.sendRequest("source_pattern_list");
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.patterns as SourcePatternEntry[]) || [];
  }

  async fetchWorkList(): Promise<WorkListEntry[]> {
    const resp = await this.sendRequest("work_list");
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as WorkListEntry[];
    const rec = val as Record<string, unknown>;
    return (rec.work_list as WorkListEntry[]) || (rec.value as WorkListEntry[]) || [];
  }

  async linkCreate(
    origin: number,
    destination: number,
    originRef?: { excerpt: string; start: number; end: number },
    destinationRef?: { excerpt: string; start: number; end: number },
  ): Promise<number> {
    const payload: Record<string, unknown> = { origin, destination };
    if (originRef) {
      payload.origin_ref = {
        kind: "single",
        work_context: origin,
        original_context: null,
        path_context: null,
        excerpt: originRef.excerpt,
      };
    }
    if (destinationRef) {
      payload.destination_ref = {
        kind: "single",
        work_context: destination,
        original_context: null,
        path_context: null,
        excerpt: destinationRef.excerpt,
      };
    }
    const resp = await this.sendRequest("link_create", payload);
    return extractValue(resp) as number;
  }

  async linkGet(linkId: number): Promise<LinkEntry> {
    const resp = await this.sendRequest("link_get", { link_id: linkId });
    return extractValue(resp) as LinkEntry;
  }

  async linkListForWork(workId: number): Promise<LinkEntry[]> {
    const resp = await this.sendRequest("link_list_for_work", { work_id: workId });
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as LinkEntry[];
    const rec = val as Record<string, unknown>;
    return (rec.links as LinkEntry[]) || [];
  }

  async linkDelete(linkId: number): Promise<void> {
    await this.sendRequest("link_delete", { link_id: linkId });
  }

  async findSharedRegions(workA: number, workB: number, filterText?: string): Promise<SharedRegion[]> {
    const payload: Record<string, unknown> = { work_a: workA, work_b: workB };
    if (filterText) payload.filter_text = filterText;
    const resp = await this.sendRequest("find_shared_regions", payload);
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as SharedRegion[];
    return [];
  }

  async rangeTranscluders(workId: number): Promise<{ edition_ids: number[]; work_ids: number[] }> {
    const resp = await this.sendRequest("range_transcluders", { work_id: workId });
    const val = extractValue(resp) as Record<string, unknown>;
    return {
      edition_ids: (val.edition_ids as number[]) || [],
      work_ids: (val.work_ids as number[]) || [],
    };
  }

  async fetchWorksByAuthor(authorId: number): Promise<WorkListEntry[]> {
    const resp = await this.sendRequest("work_list_by_author", { author_id: authorId });
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as WorkListEntry[];
    const rec = val as Record<string, unknown>;
    return (rec.work_list as WorkListEntry[]) || [];
  }

  async setReadClub(workId: number, clubId: number | null): Promise<void> {
    await this.sendRequest("work_set_read_club", {
      work_id: workId,
      club_id: clubId,
    });
  }

  async getReadClub(workId: number): Promise<number> {
    const resp = await this.sendRequest("work_read_club", { work_id: workId });
    const val = extractValue(resp);
    return (val as number) || 0;
  }

  async getEditClub(workId: number): Promise<number> {
    const resp = await this.sendRequest("work_edit_club", { work_id: workId });
    const val = extractValue(resp);
    return (val as number) || 0;
  }

  async createIdentity(displayName: string, password: string): Promise<WhoAmIEntry> {
    const pwBytes = Array.from(new TextEncoder().encode(password));
    const resp = await this.sendRequest("club_create_personal", {
      display_name: displayName,
      password: pwBytes,
    });
    const clubId = extractValue(resp) as number;
    const identity = { club_id: clubId, display_name: displayName };
    this.currentIdentity = identity;
    this.identityListeners.forEach((cb) => cb(identity));
    try {
      await this.loginByName(displayName, password);
    } catch (e) {
      console.error("[createIdentity] loginByName failed after account creation:", e);
      throw e;
    }
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

    if (this.crdtReady && this.workBeId) {
      try {
        await this.sendRequest("crdt_register_author", { work_id: this.workBeId });
      } catch (e) {
        console.error("[loginByName] crdt_register_author failed:", e);
      }
      this.sendAwareness(null, null, false);
    }

    this.identityListeners.forEach((cb) => cb(this.currentIdentity));
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

  sendRequest(op: string, payload?: object): Promise<unknown> {
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

      this.checkWhoAmI();

      await this.tryOpenWork();
    } catch (e) {
      console.error("CRDT session setup failed:", e);
    }
  }

  async tryOpenWork(): Promise<void> {
    if (!this.workBeId || !this.ws?.OPEN) return;
    try {
      const openResp = await this.sendRequest("crdt_sync_open", {
        work_id: this.workBeId,
      });
      const inner = extractValue(openResp) as Record<string, unknown>;
      this.text = (inner.current_text as string) || "";

      if (this.currentIdentity) {
        try {
          await this.sendRequest("crdt_register_author", { work_id: this.workBeId });
        } catch (e) {
          console.warn("crdt_sync: register_author failed:", e);
        }
      }

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
      console.warn("crdt_sync_open failed (work may be private):", e);
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

    if (eventType === "crdt_text_update") {
      const payload = event.payload as Record<string, unknown> | undefined;
      if (payload && payload.work_id === this.workBeId) {
        const newText = payload.text as string;
        if (newText !== this.text) {
          this.text = newText;
          this.textListeners.forEach((cb) => cb(newText));
        }
      }
    }

    if (eventType === "crdt_text_delta") {
      const payload = event.payload as Record<string, unknown> | undefined;
      if (payload && payload.work_id === this.workBeId) {
        const ops = payload.ops as Array<{ type: string; count?: number; text?: string }>;
        try {
          const newText = applyDeltaOps(this.text, ops);
          if (newText !== this.text) {
            this.text = newText;
            this.textListeners.forEach((cb) => cb(newText));
          }
        } catch {
          this.refreshText();
        }
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

function applyDeltaOps(
  text: string,
  ops: Array<{ type: string; count?: number; text?: string }>,
): string {
  let result = "";
  let pos = 0;
  for (const op of ops) {
    switch (op.type) {
      case "retain": {
        const count = op.count ?? 0;
        if (pos + count > text.length)
          throw new Error(`delta retain out of bounds: pos=${pos} count=${count} len=${text.length}`);
        result += text.slice(pos, pos + count);
        pos += count;
        break;
      }
      case "delete": {
        const count = op.count ?? 0;
        if (pos + count > text.length)
          throw new Error(`delta delete out of bounds: pos=${pos} count=${count} len=${text.length}`);
        pos += count;
        break;
      }
      case "insert": {
        result += op.text ?? "";
        break;
      }
    }
  }
  if (pos !== text.length)
    throw new Error(`delta did not consume full text: pos=${pos} len=${text.length}`);
  return result;
}
