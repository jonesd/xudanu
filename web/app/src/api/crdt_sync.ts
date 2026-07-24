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

export interface GlobalSearchResultItem {
  work_id: number;
  title?: string;
  owner?: number;
  revision_count: number;
  matches: SearchMatchItem[];
}

export interface GlobalSearchResults {
  results: GlobalSearchResultItem[];
  totalWorksMatched: number;
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
  source_work_id?: number | null;
  transcluded_by_name?: string | null;
  transcluded_by_club_id?: number | null;
  provenance_chain?: ProvenanceHop[] | null;
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
  verifying_key?: string;
  clubs?: [number, string][];
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
  // Ghost metadata (server-side archive state + title + owner per endpoint).
  origin_archived?: boolean;
  origin_title?: string | null;
  origin_owner?: number | null;
  destination_archived?: boolean;
  destination_title?: string | null;
  destination_owner?: number | null;
  link_types?: number[];
}

export interface ProvenanceHop {
  source_work_id: number;
  link_id: number;
  source_work_title?: string | null;
  source_author_name?: string | null;
  dest_work_id?: number;
}

export interface CompoundSpanPayload {
  source_work_id: number;
  char_start: number;
  char_end: number;
}

export interface SpanRangePayload {
  source_work_id: number;
  char_start: number;
  char_end: number;
  flat_start: number;
  flat_end: number;
  content_len: number;
  otree_position?: number;
  resolved_content?: string;
  placed_at?: number;
  placed_by?: number | null;
}

export type RangeElementPayload =
  | { type: "text"; text: string }
  | { type: "transclusion"; transclusion_source: number; transclusion_start: number; transclusion_end: number }
  | { type: "blob"; content_hash: number; mime_type: string; byte_size: number; width?: number; height?: number; caption?: string };

export interface AuthorContribution {
  club_id: number;
  display_name: string;
  char_count: number;
  percentage: number;
  author_type: string | null;
}

export interface ReusedInDoc {
  work_id: number;
  title: string;
  shared_char_count: number;
}

export interface WorkSummary {
  unique_sources: number;
  unique_authors: number;
  version_count: number;
  char_count: number;
  author_contributions: AuthorContribution[];
  reused_in_count: number;
  reused_in_docs: ReusedInDoc[];
}

export interface RevisionMeta {
  revision: number;
  char_count: number;
  author_club_id: number | null;
  author_display_name: string | null;
  author_type: string | null;
}

export interface WorkVersionTimeline {
  revisions: RevisionMeta[];
}

export interface CompositionLayer {
  revision: number;
  author_club_id: number | null;
  author_display_name: string | null;
  text: string;
  operation: string;
}

export interface PassageComposition {
  layers: CompositionLayer[];
}

export interface CrossServerRefPayload {
  tumbler: string;
  origin_server_id?: number;
  origin_server_address?: string | null;
  content_hash: string;
  mime_type?: string;
  byte_size?: number;
  origin_author: string;
  origin_author_key: string;
  origin_server_sig?: string;
  fetched_at?: number;
  excerpt?: string;
}

export interface HyperRefPayload {
  kind: string;
  work_context: number | null;
  original_context: number | null;
  excerpt: string | null;
  provenance_chain?: ProvenanceHop[];
  start_position?: number | null;
  end_position?: number | null;
  cross_server_ref?: CrossServerRefPayload | null;
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

export interface WorkDiffResult {
  shared: Array<{
    start_a: number;
    end_a: number;
    start_b: number;
    end_b: number;
    text: string;
  }>;
  changed_a: [number, number][];
  changed_b: [number, number][];
  text_len_a: number;
  text_len_b: number;
  coverage: number;
}

export interface BacklinkEntry {
  source_work_id: number;
  link_id: number;
  link_type: string;
  excerpt?: string;
  title?: string;
}

export interface LinkTypeInfo {
  type_id: number;
  name: string;
}

export interface AgainHop {
  work_id: number;
  work_title: string;
  element_text: string;
  author_name: string;
  author_type: string;
  is_original: boolean;
}

export interface CrossServerBacklinkPayload {
  target_work_id: number;
  origin_server_address: string;
  origin_server_name: string;
  origin_work_id: string;
  origin_work_title: string;
  excerpt: string;
  link_type: string;
  received_at: number;
}

export interface AnnotationEntry {
  annotation_id: number;
  kind: string;
  payload: string;
  char_start: number;
  char_end: number;
  created_by: number | null;
  created_by_name: string | null;
  created_at?: number;
  is_private?: boolean;
}

export interface TransclusionMarker {
  start: number;
  end: number;
  linkId: number;
  direction: "outgoing" | "incoming";
  otherWorkId: number;
  otherWorkTitle: string;
  color: string;
  excerpt?: string;
  provenanceChain?: ProvenanceHop[];
  linkTypeId?: number;
  otherWorkIsArchived?: boolean;
  otherWorkOwner?: number | null;
  crossServerRef?: { tumbler: string; contentHash: string } | null;
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
  is_starred?: boolean;
  updated_at?: number;
}

export type WorkKind = "document" | "note" | "person" | "concept" | "collection" | "commentary";

export type License = "all-rights-reserved" | "transcopyright" | "cc-by" | "cc-by-sa" | "public-domain";

export const LICENSES: { value: License; label: string; short: string; url: string | null }[] = [
  { value: "all-rights-reserved", label: "All Rights Reserved", short: "\u00A9", url: null },
  { value: "transcopyright", label: "Transcopyright", short: "TCo", url: "https://xanadu.com/xuTco.html" },
  { value: "cc-by", label: "CC-BY (Attribution)", short: "CC-BY", url: "https://creativecommons.org/licenses/by/4.0/" },
  { value: "cc-by-sa", label: "CC-BY-SA (Share-Alike)", short: "CC-BY-SA", url: "https://creativecommons.org/licenses/by-sa/4.0/" },
  { value: "public-domain", label: "Public Domain (CC0)", short: "CC0", url: "https://creativecommons.org/publicdomain/zero/1.0/" },
];

export interface RevisionMeta {
  revision_id: number;
  parent?: number;
  created_at: number;
  created_by?: number;
  description?: string;
  is_notable: boolean;
  char_count: number;
  change_summary?: string;
}

export interface BlobMeta {
  content_hash: number[] | number;
  byte_size: number;
  mime_type: string;
  preview_hash?: number[] | number | null;
  width?: number | null;
  height?: number | null;
}

export interface BlobEntry {
  char_position: number;
  content_hash: number;
  mime_type: string;
  byte_size: number;
  width?: number | null;
  height?: number | null;
  caption?: string | null;
}

export function blobHashToU64(hash: number[] | number): number {
  if (typeof hash === "number") return hash;
  if (Array.isArray(hash) && hash.length >= 8) {
    let result = 0;
    for (let i = 0; i < 8; i++) {
      result = result * 256 + (hash[i] || 0);
    }
    return result;
  }
  return 0;
}

export interface GraphNode {
  work_id: number;
  title: string;
  is_starred: boolean;
  is_source: boolean;
  revision_count: number;
  author_type?: string;
  kind?: WorkKind;
  license?: License;
}

export interface GraphEdge {
  source: number;
  target: number;
  edge_type: string;
  weight: number;
}

export interface WorkGraphPayload {
  nodes: GraphNode[];
  edges: GraphEdge[];
}

export interface TrailStop {
  work_id: number;
  char_start?: number;
  char_end?: number;
  note?: string;
  title: string;
}

export interface TrailPayload {
  trail_id: number;
  name: string;
  introduction?: string;
  categories?: string[];
  published?: boolean;
  owner_club: number;
  stops: TrailStop[];
  created_at: number;
  updated_at: number;
}

type IdentityListener = (identity: WhoAmIEntry | null) => void;

type ResponseHandler = (value: unknown, isError: boolean) => void;

export interface ChangeHighlight {
  start: number;
  end: number;
  timestamp: number;
  author: string;
}

export class CrdtSyncClient {
  private ws: WebSocket | null = null;
  private requestId = 0;
  private pending = new Map<number, ResponseHandler>();
  private text = "";
  private textListeners = new Set<(text: string) => void>();
  private awarenessListeners = new Set<(states: AwarenessState[]) => void>();
  private connectionListeners = new Set<(connected: boolean) => void>();
  private contentMatchListeners = new Set<(match: ContentMatch) => void>();
  private changeHighlightListeners = new Set<(changes: ChangeHighlight[]) => void>();
  private compoundSourceListeners = new Set<(compoundWorkId: number, sourceWorkId: number) => void>();
  private recentChanges: ChangeHighlight[] = [];
  private identityListeners = new Set<IdentityListener>();
  private connected = false;
  private disposed = false;
  private connecting = false;
  private generation = 0;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private reconnectAttempts = 0;
  private static readonly RECONNECT_BASE_MS = 500;
  private static readonly RECONNECT_MAX_MS = 10000;
  private heartbeatTimer: ReturnType<typeof setInterval> | null = null;
  private awarenessMap = new Map<number, AwarenessState>();
  private awarenessSendTimer: ReturnType<typeof setTimeout> | null = null;
  private pendingAwareness: { cursor: number | null; selection: { start: number; end: number } | null; isTyping: boolean } | null = null;
  private url: string;
  private workBeId: number;
  private sessionId: number | null = null;
  private sessionIdStr: string | null = null;

  getSessionId(): string | null {
    return this.sessionIdStr;
  }
  private crdtReady = false;
  private deltaInFlight = false;
  private pendingServerText: string | null = null;
  private crdtOpenedThisConnection = false;
  currentIdentity: WhoAmIEntry | null = null;
  private isAdmin = false;
  private skipCrdt = false;

  constructor(url: string, workBeId: number) {
    this.url = url;
    this.workBeId = workBeId;
  }

  setSkipCrdt(skip: boolean): void {
    this.skipCrdt = skip;
  }

  connect(): void {
    if (this.ws?.readyState === WebSocket.OPEN) return;
    if (this.connecting) return;
    this.connecting = true;
    this.disposed = false;

    const gen = this.generation;
    const wsUrl = `${this.url}?format=json&version=${PROTOCOL_VERSION}`;

    fetch("/csrf-token")
      .then((r) => r.ok ? r.json() : Promise.reject(new Error("csrf disabled")))
      .then((d) => {
        if (gen !== this.generation) return;
        if (d.csrf_token) {
          this.openWs(wsUrl + "&csrf_token=" + encodeURIComponent(d.csrf_token));
        } else {
          this.openWs(wsUrl);
        }
      })
      .catch(() => {
        if (gen !== this.generation) return;
        this.openWs(wsUrl);
      });
  }

  private openWs(url: string): void {
    if (this.disposed) return;
    if (this.ws && this.ws.readyState === WebSocket.CONNECTING) {
      this.ws.onclose = null;
      this.ws.close();
    }
    this.connecting = false;
    this.ws = new WebSocket(url);
    this.ws.onopen = () => this.onOpen();
    this.ws.onmessage = (e) => this.onMessage(e.data);
    this.ws.onclose = () => this.onClose();
    this.ws.onerror = () => this.ws?.close();
  }

  disconnect(): void {
    this.disposed = true;
    this.connecting = false;
    this.generation++;
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
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

  onChangeHighlights(cb: (changes: ChangeHighlight[]) => void): () => void {
    this.changeHighlightListeners.add(cb);
    return () => { this.changeHighlightListeners.delete(cb); };
  }

  onCompoundSourceChange(cb: (compoundWorkId: number, sourceWorkId: number) => void): () => void {
    this.compoundSourceListeners.add(cb);
    return () => { this.compoundSourceListeners.delete(cb); };
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

  getReconnectAttempt(): number {
    return this.reconnectAttempts;
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

  async attributionQueryResolved(workId: number): Promise<AttributionSpan[]> {
    const resp = await this.sendRequest("attribution_query_resolved", {
      work_id: workId,
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

  async globalTextSearch(query: string, maxResults?: number): Promise<GlobalSearchResults> {
    const resp = await this.sendRequest("global_text_search", {
      query,
      max_results: maxResults ?? null,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return {
      results: (val.results as GlobalSearchResultItem[]) || [],
      totalWorksMatched: (val.total_works_matched as number) || 0,
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
    const states = (val.states as AwarenessState[]) || [];
    this.awarenessMap.clear();
    for (const s of states) {
      this.awarenessMap.set(s.session_id, s);
    }
    return states;
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

  async importEpub(
    epubData: Uint8Array,
    title?: string,
    author?: string,
    skipPrefixLines: number = 0,
    skipSuffixLines: number = 0,
  ): Promise<{ workId: number; authorId: number; title: string; textLength: number }> {
    const payload: Record<string, unknown> = {
      epub_data: Array.from(epubData),
      skip_prefix_lines: skipPrefixLines,
      skip_suffix_lines: skipSuffixLines,
    };
    if (title) payload.title = title;
    if (author) payload.author = author;
    const resp = await this.sendRequest("import_epub", payload);
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

  async matchContent(text: string): Promise<{ matched: boolean; work_id?: number; author_id?: number; score?: number }> {
    const resp = await this.sendRequest("content_match", { text });
    return extractValue(resp) as { matched: boolean; work_id?: number; author_id?: number; score?: number };
  }

  async applySourceAttribution(
    workId: number,
    historicalAuthorId: number,
    sourceWorkId?: number,
    pasteStart?: number,
    pasteEnd?: number,
  ): Promise<void> {
    const params: Record<string, unknown> = {
      work_id: workId,
      historical_author_id: historicalAuthorId,
    };
    if (sourceWorkId != null) params.source_work_id = sourceWorkId;
    if (pasteStart != null) params.paste_start = pasteStart;
    if (pasteEnd != null) params.paste_end = pasteEnd;
    await this.sendRequest("work_apply_source_attribution", params);
  }

  async applyTransclusionAttribution(linkId: number): Promise<void> {
    await this.sendRequest("work_apply_transclusion_attribution", {
      link_id: linkId,
    });
  }

  async listSourcePatterns(): Promise<SourcePatternEntry[]> {
    const resp = await this.sendRequest("source_pattern_list");
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.patterns as SourcePatternEntry[]) || [];
  }

  async fetchWorkList(): Promise<WorkListEntry[]> {
    const resp = await this.sendRequest("work_list", {});
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as WorkListEntry[];
    const rec = val as Record<string, unknown>;
    return (rec.entries as WorkListEntry[]) || (rec.work_list as WorkListEntry[]) || (rec.value as WorkListEntry[]) || [];
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
        start_position: originRef.start,
        end_position: originRef.end,
      };
    }
    if (destinationRef) {
      payload.destination_ref = {
        kind: "single",
        work_context: destination,
        original_context: null,
        path_context: null,
        excerpt: destinationRef.excerpt,
        start_position: destinationRef.start,
        end_position: destinationRef.end,
      };
    }
    const resp = await this.sendRequest("link_create", payload);
    return extractValue(resp) as number;
  }

  async linkCreateCrossServer(
    originWorkId: number,
    originRef: { excerpt: string; start: number; end: number },
    crossServerRef: CrossServerRefPayload,
  ): Promise<number> {
    const payload: Record<string, unknown> = {
      origin: originWorkId,
      destination: originWorkId,
      origin_ref: {
        kind: "single",
        work_context: originWorkId,
        original_context: null,
        path_context: null,
        excerpt: originRef.excerpt,
        start_position: originRef.start,
        end_position: originRef.end,
      },
      destination_ref: {
        kind: "single",
        work_context: null,
        original_context: null,
        path_context: null,
        excerpt: crossServerRef.excerpt || null,
        start_position: null,
        end_position: null,
        cross_server_ref: crossServerRef,
      },
      link_types: [],
    };
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
    return (rec.entries as LinkEntry[]) || (rec.links as LinkEntry[]) || [];
  }

  async linkDelete(linkId: number): Promise<void> {
    await this.sendRequest("link_delete", { link_id: linkId });
  }

  async linkSetTypes(linkId: number, linkTypes: number[]): Promise<void> {
    await this.sendRequest("link_set_types", { link_id: linkId, link_types: linkTypes });
  }

  async linkTypeList(): Promise<LinkTypeInfo[]> {
    const resp = await this.sendRequest("link_type_list", {});
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as LinkTypeInfo[];
    return [];
  }

  async workPublish(workId: number): Promise<void> {
    await this.sendRequest("work_publish", { work_id: workId });
  }

  async workUnpublish(workId: number): Promise<void> {
    await this.sendRequest("work_unpublish", { work_id: workId });
  }

  async workIsPublished(workId: number): Promise<boolean> {
    const resp = await this.sendRequest("work_is_published", { work_id: workId });
    return extractValue(resp) === true;
  }

  async workSetEditClub(workId: number, clubId: number | null): Promise<void> {
    const payload: Record<string, unknown> = { work_id: workId };
    if (clubId !== null) payload.club_id = clubId;
    await this.sendRequest("work_set_edit_club", payload);
  }

  async workEditClub(workId: number): Promise<number | null> {
    const resp = await this.sendRequest("work_edit_club", { work_id: workId });
    const val = extractValue(resp);
    if (val === null || val === undefined) return null;
    const club = (val as Record<string, unknown>).value ?? val;
    return typeof club === "number" ? club : null;
  }

  async generateAttestationReport(workId: number): Promise<string> {
    const resp = await this.sendRequest("attestation_report", { work_id: workId });
    const val = extractValue(resp);
    const obj = val as Record<string, unknown>;
    return (obj.report_json as string) || (obj.value as string) || JSON.stringify(val);
  }

  async exportProvJson(workId: number, includeFederation: boolean = false): Promise<string> {
    const resp = await this.sendRequest("prov_json_export", {
      work_id: workId,
      include_federation: includeFederation,
    });
    const val = extractValue(resp);
    const obj = val as Record<string, unknown>;
    return (obj.prov_json as string) || JSON.stringify(val);
  }

  async findSharedRegions(workA: number, workB: number, filterText?: string): Promise<SharedRegion[]> {
    const payload: Record<string, unknown> = { work_a: workA, work_b: workB };
    if (filterText) payload.filter_text = filterText;
    const resp = await this.sendRequest("find_shared_regions", payload);
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as SharedRegion[];
    return [];
  }

  async workDiffRegions(workA: number, workB: number): Promise<WorkDiffResult | null> {
    try {
      const resp = await this.sendRequest("work_diff_regions", { work_a: workA, work_b: workB });
      const val = extractValue(resp);
      if (val && typeof val === "object") {
        return val as WorkDiffResult;
      }
      return null;
    } catch {
      return null;
    }
  }

  async fetchRevision(workId: number, revision: number): Promise<string> {
    const resp = await this.sendRequest("work_fetch_revision", { work_id: workId, number: revision });
    const val = extractValue(resp);
    if (typeof val === "string") return val;
    if (val && typeof val === "object") {
      const v = val as Record<string, unknown>;
      if (typeof v.Text === "string") return v.Text;
      if (typeof v.text === "string") return v.text;
      const inner = v.value as Record<string, unknown> | undefined;
      if (inner && typeof inner.Text === "string") return inner.Text;
      if (inner && typeof inner.text === "string") return inner.text;
    }
    return "";
  }

  async revisionCount(workId: number): Promise<number> {
    const resp = await this.sendRequest("work_revision_count", { work_id: workId });
    const val = extractValue(resp);
    if (typeof val === "number") return val;
    return 0;
  }

  async findExcerptPositions(workId: number, excerpt: string): Promise<Array<{ start: number; end: number }>> {
    const resp = await this.sendRequest("find_excerpt_positions", { work_id: workId, excerpt });
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as Array<{ start: number; end: number }>;
    return [];
  }

  async versionIsBefore(workA: number, workB: number): Promise<boolean | null> {
    const resp = await this.sendRequest("version_is_before", { work_a: workA, work_b: workB });
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.is_before as boolean | null) ?? null;
  }

  async versionTracePosition(workId: number): Promise<{ branchId: number; position: number } | null> {
    const resp = await this.sendRequest("version_trace_position", { work_id: workId });
    const val = extractValue(resp) as Record<string, unknown>;
    const tp = val.trace_position as Record<string, unknown> | null;
    if (!tp) return null;
    return { branchId: tp.branch_id as number, position: tp.position as number };
  }

  async provenanceAncestry(workId: number): Promise<ProvenanceHop[]> {
    const resp = await this.sendRequest("provenance_ancestry", { work_id: workId });
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.chain as ProvenanceHop[]) || [];
  }

  async resolveInlineTransclusions(workId: number): Promise<{ text: string; spanRanges: SpanRangePayload[]; sourceTitles: Record<number, string> }> {
    const resp = await this.sendRequest("resolve_inline_transclusions", { work_id: workId });
    const val = extractValue(resp) as Record<string, unknown>;
    return {
      text: (val.text as string) || "",
      spanRanges: (val.span_ranges as SpanRangePayload[]) || [],
      sourceTitles: (val.source_titles as Record<number, string>) || {},
    };
  }

  async elementInsert(workId: number, position: number, element: RangeElementPayload): Promise<number> {
    const resp = await this.sendRequest("element_insert", { work_id: workId, position, element });
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.revision as number) || 0;
  }

  async elementUpdate(workId: number, charPosition: number, element: RangeElementPayload): Promise<number> {
    const resp = await this.sendRequest("element_update", { work_id: workId, char_position: charPosition, element });
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.revision as number) || 0;
  }

  async elementRemoveTransclusion(workId: number, sourceWorkId: number, charStart: number, charEnd: number): Promise<boolean> {
    const resp = await this.sendRequest("element_remove_transclusion", {
      work_id: workId, source_work_id: sourceWorkId, char_start: charStart, char_end: charEnd,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.removed as boolean) || false;
  }

  async workTransclusionChain(workId: number, charStart: number, charEnd: number): Promise<AgainHop[]> {
    const resp = await this.sendRequest("work_transclusion_chain", { work_id: workId, char_start: charStart, char_end: charEnd });
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as AgainHop[];
    return [];
  }

  async migrateCompoundToInline(workId: number): Promise<number | null> {
    try {
      const resp = await this.sendRequest("migrate_compound_to_inline", { work_id: workId });
      const val = extractValue(resp) as Record<string, unknown>;
      return (val.migrated_count as number) || 0;
    } catch {
      return null;
    }
  }

  async workMerge(baseWorkId: number, workAId: number, workBId: number): Promise<number> {
    const resp = await this.sendRequest("work_merge", { base_work_id: baseWorkId, work_a_id: workAId, work_b_id: workBId });
    const val = extractValue(resp);
    if (typeof val === "number") return val;
    const r = val as Record<string, unknown>;
    return (r.work_id as number) || (r.value as number) || 0;
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

  async workStar(workId: number): Promise<void> {
    await this.sendRequest("work_star", { work_id: workId });
  }

  async workUnstar(workId: number): Promise<void> {
    await this.sendRequest("work_unstar", { work_id: workId });
  }

  async connectionPinSet(key: string): Promise<void> {
    await this.sendRequest("connection_pin_set", { key });
  }

  async connectionPinUnset(key: string): Promise<void> {
    await this.sendRequest("connection_pin_unset", { key });
  }

  async connectionPinsGet(): Promise<string[]> {
    const resp = await this.sendRequest("connection_pins_get", {});
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as string[];
    return [];
  }

  async crossServerBacklinksGet(workId: number): Promise<CrossServerBacklinkPayload[]> {
    const resp = await this.sendRequest("cross_server_backlinks_get", { work_id: workId });
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as CrossServerBacklinkPayload[];
    return [];
  }

  async workArchive(workId: number): Promise<void> {
    await this.sendRequest("work_archive", { work_id: workId });
  }

  async workUnarchive(workId: number): Promise<void> {
    await this.sendRequest("work_unarchive", { work_id: workId });
  }

  async listArchivedWorks(): Promise<WorkListEntry[]> {
    const resp = await this.sendRequest("work_list_archived");
    const val = extractValue(resp);
    return (val as WorkListEntry[]) || [];
  }

  async workIsStarred(workId: number): Promise<boolean> {
    const resp = await this.sendRequest("work_is_starred", { work_id: workId });
    return extractValue(resp) as boolean;
  }

  async workGraph(): Promise<WorkGraphPayload> {
    const resp = await this.sendRequest("work_graph");
    return extractValue(resp) as WorkGraphPayload;
  }

  async workKindGet(workId: number): Promise<WorkKind> {
    const resp = await this.sendRequest("work_kind_get", { work_id: workId });
    const val = extractValue(resp);
    const idx = typeof val === "number" ? val : 0;
    return (["document", "note", "person", "concept", "collection", "commentary"][idx] || "document") as WorkKind;
  }

  async workKindSet(workId: number, kind: WorkKind): Promise<void> {
    await this.sendRequest("work_kind_set", { work_id: workId, kind });
  }

  async workLicenseGet(workId: number): Promise<License> {
    const resp = await this.sendRequest("work_license_get", { work_id: workId });
    const val = extractValue(resp);
    const idx = typeof val === "number" ? val : 0;
    return (LICENSES[idx]?.value || "all-rights-reserved") as License;
  }

  async workLicenseSet(workId: number, license: License): Promise<void> {
    await this.sendRequest("work_license_set", { work_id: workId, license });
  }

  async workSetText(workId: number, text: string): Promise<void> {
    await this.sendRequest("work_set_text", { work_id: workId, text });
  }

  // ── FR-23: Revisions ──

  async workRevisionsList(workId: number): Promise<RevisionMeta[]> {
    const resp = await this.sendRequest("work_revisions_list", { work_id: workId });
    return extractValue(resp) as RevisionMeta[];
  }

  async workTextAtRevision(workId: number, revisionId: number): Promise<string> {
    const resp = await this.sendRequest("work_text_at_revision", {
      work_id: workId,
      revision_id: revisionId,
    });
    const val = extractValue(resp);
    if (typeof val === "string") return val;
    return (val as { text?: string }).text || "";
  }

  async workRevisionDescribe(workId: number, revisionId: number, description: string): Promise<void> {
    await this.sendRequest("work_revision_describe", {
      work_id: workId,
      revision_id: revisionId,
      description,
    });
  }

  async workRevisionMarkNotable(workId: number, revisionId: number, notable: boolean): Promise<void> {
    await this.sendRequest("work_revision_mark_notable", {
      work_id: workId,
      revision_id: revisionId,
      notable,
    });
  }

  async workRevisionRollback(workId: number, targetRevisionId: number): Promise<number> {
    const resp = await this.sendRequest("work_revision_rollback", {
      work_id: workId,
      target_revision_id: targetRevisionId,
    });
    return extractValue(resp) as number;
  }

  async trailCreate(name: string, introduction?: string, categories?: string[]): Promise<number> {
    const payload: Record<string, unknown> = { name };
    if (introduction) payload.introduction = introduction;
    if (categories && categories.length) payload.categories = categories;
    const resp = await this.sendRequest("trail_create", payload);
    return extractValue(resp) as number;
  }

  async trailDelete(trailId: number): Promise<void> {
    await this.sendRequest("trail_delete", { trail_id: trailId });
  }

  async trailRename(trailId: number, name: string): Promise<void> {
    await this.sendRequest("trail_rename", { trail_id: trailId, name });
  }

  async trailUpdate(trailId: number, introduction: string | null, categories: string[]): Promise<void> {
    await this.sendRequest("trail_update", {
      trail_id: trailId,
      introduction,
      categories,
    });
  }

  async trailPublish(trailId: number): Promise<void> {
    await this.sendRequest("trail_publish", { trail_id: trailId });
  }

  async trailUnpublish(trailId: number): Promise<void> {
    await this.sendRequest("trail_unpublish", { trail_id: trailId });
  }

  async trailAddStop(trailId: number, workId: number, charStart?: number, charEnd?: number, note?: string): Promise<void> {
    const payload: Record<string, unknown> = { trail_id: trailId, work_id: workId };
    if (charStart !== undefined) payload.char_start = charStart;
    if (charEnd !== undefined) payload.char_end = charEnd;
    if (note) payload.note = note;
    await this.sendRequest("trail_add_stop", payload);
  }

  async trailRemoveStop(trailId: number, stopIndex: number): Promise<void> {
    await this.sendRequest("trail_remove_stop", { trail_id: trailId, stop_index: stopIndex });
  }

  async trailReorderStops(trailId: number, stopOrder: number[]): Promise<void> {
    await this.sendRequest("trail_reorder_stops", { trail_id: trailId, stop_order: stopOrder });
  }

  async trailList(): Promise<TrailPayload[]> {
    const resp = await this.sendRequest("trail_list");
    return extractValue(resp) as TrailPayload[];
  }

  async trailGet(trailId: number): Promise<TrailPayload> {
    const resp = await this.sendRequest("trail_get", { trail_id: trailId });
    return extractValue(resp) as TrailPayload;
  }

  async trailListPublished(category?: string): Promise<TrailPayload[]> {
    const payload: Record<string, unknown> = {};
    if (category) payload.category = category;
    const resp = await this.sendRequest("trail_list_published", payload);
    return extractValue(resp) as TrailPayload[];
  }

  async trailListCategories(): Promise<string[]> {
    const resp = await this.sendRequest("trail_list_categories");
    return extractValue(resp) as string[];
  }

  // ── Blob / Image API ──

  async blobUpload(data: Uint8Array, mimeType: string): Promise<BlobMeta> {
    const resp = await this.sendRequest("blob_upload", {
      data: Array.from(data),
      mime_type: mimeType,
    });
    return extractValue(resp) as BlobMeta;
  }

  async blobGet(hashU64: number): Promise<Uint8Array> {
    const resp = await this.sendRequest("blob_get", { content_hash: hashU64 });
    const val = extractValue(resp);
    if (val instanceof Uint8Array) return val;
    const arr = val as number[];
    return new Uint8Array(arr);
  }

  async blobGetPreview(hashU64: number): Promise<Uint8Array | null> {
    const resp = await this.sendRequest("blob_get_preview", { content_hash: hashU64 });
    const val = extractValue(resp);
    if (val === null || val === undefined) return null;
    if (val instanceof Uint8Array) return val;
    const arr = val as number[];
    return arr.length > 0 ? new Uint8Array(arr) : null;
  }

  async blobExists(hashU64: number): Promise<boolean> {
    const resp = await this.sendRequest("blob_exists", { content_hash: hashU64 });
    return extractValue(resp) as boolean;
  }

  async blobInfo(hashU64: number): Promise<BlobMeta> {
    const resp = await this.sendRequest("blob_info", { content_hash: hashU64 });
    return extractValue(resp) as BlobMeta;
  }

  async blobStats(): Promise<{ total_blobs: number; total_bytes: number }> {
    const resp = await this.sendRequest("blob_stats");
    return extractValue(resp) as { total_blobs: number; total_bytes: number };
  }

  async workBlobList(workId: number): Promise<BlobEntry[]> {
    const resp = await this.sendRequest("work_blob_list", { work_id: workId });
    return extractValue(resp) as BlobEntry[];
  }

  async workSummary(workId: number): Promise<WorkSummary> {
    const resp = await this.sendRequest("work_summary", { work_id: workId });
    return extractValue(resp) as WorkSummary;
  }

  async versionAncestors(workId: number): Promise<number[]> {
    const resp = await this.sendRequest("version_ancestors", { work_id: workId });
    const v = extractValue(resp) as { ancestors: number[] };
    return v.ancestors;
  }

  async versionDescendants(workId: number): Promise<number[]> {
    const resp = await this.sendRequest("version_descendants", { work_id: workId });
    const v = extractValue(resp) as { descendants: number[] };
    return v.descendants;
  }

  async workTitle(workId: number): Promise<string> {
    const resp = await this.sendRequest("work_get_edition", { work_id: workId });
    const v = extractValue(resp) as { title?: string };
    return v.title || "";
  }

  async workVersionTimeline(workId: number): Promise<WorkVersionTimeline> {
    const resp = await this.sendRequest("work_version_timeline", { work_id: workId });
    return extractValue(resp) as WorkVersionTimeline;
  }

  async passageComposition(workId: number, start: number, end: number): Promise<PassageComposition> {
    const resp = await this.sendRequest("passage_composition", {
      work_id: workId,
      start,
      end,
    });
    return extractValue(resp) as PassageComposition;
  }

  async setReadClub(workId: number, clubId: number | null): Promise<void> {
    await this.sendRequest("work_set_read_club", {
      work_id: workId,
      club_id: clubId,
    });
  }

  async setEditClub(workId: number, clubId: number | null): Promise<void> {
    await this.sendRequest("work_set_edit_club", {
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

  async canEdit(workId: number): Promise<boolean> {
    try {
      const resp = await this.sendRequest("work_can_revise", { work_id: workId });
      const val = extractValue(resp);
      return val === true;
    } catch {
      return false;
    }
  }

  async clubMembers(clubId: number): Promise<number[]> {
    const resp = await this.sendRequest("club_members", { club_id: clubId });
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as number[];
    const r = val as Record<string, unknown>;
    return (r.members as number[]) || [];
  }

  async clubRoster(clubId: number): Promise<{ members: [number, string][]; total: number; truncated: boolean }> {
    const resp = await this.sendRequest("club_roster", { club_id: clubId });
    const val = extractValue(resp) as { members: [number, string][]; total: number; truncated: boolean };
    return val;
  }

  async clubAddMember(clubId: number, memberId: number): Promise<void> {
    await this.sendRequest("club_add_member", { club_id: clubId, member_id: memberId });
  }

  async clubRemoveMember(clubId: number, memberId: number): Promise<void> {
    await this.sendRequest("club_remove_member", { club_id: clubId, member_id: memberId });
  }

  async clubNameById(clubId: number): Promise<string> {
    const resp = await this.sendRequest("club_name_by_id", { club_id: clubId });
    const val = extractValue(resp);
    return (val as string) || "";
  }

  async fetchClubNames(offset?: number, limit?: number): Promise<[string, number][]> {
    const resp = await this.sendRequest("club_names", {
      offset: offset ?? null,
      limit: limit ?? null,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    const entries = (val.entries as [string, number][]) || [];
    return entries;
  }

  async getPublicClubId(): Promise<number> {
    const resp = await this.sendRequest("server_stats");
    const val = (resp as Record<string, unknown>)?.value as Record<string, unknown> | undefined;
    return (val?.public_club_id as number) || 0;
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
    await this.sendRequest("session_login_by_name", { club_name: clubName });
    const pwBytes = Array.from(new TextEncoder().encode(password));
    await Promise.race([
      this.sendRequest("session_authenticate", {
        credential: { password: Array.from(pwBytes) },
      }),
      new Promise((_, reject) => setTimeout(() => reject(new Error("session_authenticate timed out after 10s")), 10000)),
    ]);
    const whoResp = await this.sendRequest("club_who_am_i");
    const val = extractValue(whoResp) as { clubs: [number, string][]; verifying_key?: string };
    const clubs = val.clubs || [];
    if (clubs.length > 0) {
      const [clubId, name] = clubs[0];
      this.currentIdentity = { club_id: clubId, display_name: name, verifying_key: val.verifying_key, clubs };
    }

    if (this.crdtReady && this.workBeId) {
      try {
        await this.sendRequest("crdt_register_author", { work_id: this.workBeId });
      } catch {
        // Expected during identity transitions
      }
      this.sendAwareness(null, null, false);
    }

    this.identityListeners.forEach((cb) => cb(this.currentIdentity));
  }

  async checkWhoAmI(): Promise<WhoAmIEntry | null> {
    try {
      const resp = await this.sendRequest("club_who_am_i");
      const val = extractValue(resp) as { clubs: [number, string][]; verifying_key?: string };
      const clubs = val.clubs || [];
      if (clubs.length > 0) {
        const [clubId, name] = clubs[0];
        this.currentIdentity = { club_id: clubId, display_name: name, verifying_key: val.verifying_key, clubs };
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

  getIsAdmin(): boolean {
    return this.isAdmin;
  }

  private async checkAdminStatus(): Promise<void> {
    try {
      await this.sendRequest("admin_grants");
      this.isAdmin = true;
    } catch {
      this.isAdmin = false;
    }
    this.identityListeners.forEach((cb) => cb(this.currentIdentity));
  }

  onIdentityChange(cb: IdentityListener): () => void {
    this.identityListeners.add(cb);
    return () => { this.identityListeners.delete(cb); };
  }

  sendAwareness(cursor: number | null, selection: { start: number; end: number } | null, isTyping: boolean): void {
    if (!this.crdtReady) return;
    this.pendingAwareness = { cursor, selection, isTyping };
    if (this.awarenessSendTimer !== null) return;
    this.awarenessSendTimer = setTimeout(() => {
      this.awarenessSendTimer = null;
      const p = this.pendingAwareness;
      if (!p) return;
      this.pendingAwareness = null;
      this.sendRequest("crdt_awareness_update", {
        work_id: this.workBeId,
        state: {
          session_id: this.sessionId ?? 0,
          user_name: this.currentIdentity?.display_name || `user-${(this.sessionId ?? 0).toString(16).slice(-4)}`,
          cursor: p.cursor !== null ? { index: p.cursor } : null,
          selection: p.selection,
          is_typing: p.isTyping,
        },
      });
    }, 50);
  }

  private nextId(): number {
    return ++this.requestId;
  }

  private static readonly REQUEST_TIMEOUT_MS = 30000;

  sendRequest(op: string, payload?: object): Promise<unknown> {
    const p = new Promise((resolve, reject) => {
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

      if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
        this.pending.delete(id);
        reject(new Error(`WebSocket not open (state=${this.ws?.readyState ?? "null"})`));
        return;
      }

      const timer = setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`Request "${op}" timed out after ${CrdtSyncClient.REQUEST_TIMEOUT_MS}ms`));
        }
      }, CrdtSyncClient.REQUEST_TIMEOUT_MS);

      this.pending.set(id, (value, isError) => {
        clearTimeout(timer);
        if (isError) {
          reject(new Error(String(value) || "unknown error"));
        } else {
          resolve(value);
        }
      });
      this.wsSend(JSON.stringify(frame));
    });
    p.catch(() => {});
    return p;
  }

  private wsSend(data: string): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(data);
    }
  }

  private async onOpen(): Promise<void> {
    this.connected = true;
    this.reconnectAttempts = 0;
    this.connectionListeners.forEach((cb) => cb(true));

    this.heartbeatTimer = setInterval(() => {
      if (this.ws?.readyState === WebSocket.OPEN) {
        this.wsSend(JSON.stringify({ v: PROTOCOL_VERSION, id: 0, type: "heartbeat" }));
      }
    }, 20000);

    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        const resp = await this.sendRequest("session_connect");
        this.sessionId = extractValue(resp) as number;

        const who = await this.checkWhoAmI();
        if (!who) {
          await this.sendRequest("session_login_public");
        }

        await this.checkSourceWork();
        await this.tryOpenWork();
        this.checkAdminStatus().catch(() => {});
        return;
      } catch (e) {
        if (attempt < 2) {
          console.warn(`CRDT session setup attempt ${attempt + 1} failed, retrying...`, e);
          await new Promise((r) => setTimeout(r, 1000 * (attempt + 1)));
        } else {
          console.warn("CRDT session setup failed after 3 attempts:", e);
        }
      }
    }
  }

  private async checkSourceWork(): Promise<void> {
    if (!this.workBeId) return;
    try {
      const resp = await this.sendRequest("work_list", {});
      let val = extractValue(resp);
      const r = val as Record<string, unknown>;
      if (r && typeof r === "object" && "value" in r) val = r.value;
      const entries = ((val as Record<string, unknown>).entries as WorkListEntry[]) || [];
      console.log("[checkSource] entries:", entries.length, "is_source:", entries.find(e => e.work_id === this.workBeId)?.is_source);
      const entry = entries.find((e: WorkListEntry) => e.work_id === this.workBeId);
      if (entry?.is_source) {
        console.log("[CRDT-DIAG] work", this.workBeId, "is a source work — skipCrdt=true");
        this.skipCrdt = true;
      } else {
        console.log("[CRDT-DIAG] work", this.workBeId, "is NOT a source work — skipCrdt=false");
      }
    } catch (e) {
      console.warn("[checkSource] failed:", e);
      // ignore — will try CRDT open as fallback
    }
  }

  async tryOpenWork(): Promise<void> {
    if (!this.workBeId || !this.ws || this.ws.readyState !== WebSocket.OPEN) return;
    let loaded = false;
    if (!this.skipCrdt) {
      try {
        console.log("[CRDT-DIAG] crdt_sync_open for work", this.workBeId, "skipCrdt=", this.skipCrdt);
        const openResp = await this.sendRequest("crdt_sync_open", {
          work_id: this.workBeId,
        });
        console.log("[CRDT-DIAG] crdt_sync_open succeeded for work", this.workBeId);
        const inner = extractValue(openResp) as Record<string, unknown>;

        const wasInitialOpen = !this.crdtOpenedThisConnection;
        if (wasInitialOpen) {
          this.crdtOpenedThisConnection = true;
        }

        if (this.currentIdentity) {
          try {
            await this.sendRequest("crdt_register_author", { work_id: this.workBeId });
          } catch (e) {
            console.warn("crdt_sync: register_author failed:", e);
          }
        }

        if (wasInitialOpen) {
          this.text = (inner.current_text as string) || "";
        }

        this.crdtReady = true;
        loaded = true;
        if (wasInitialOpen) {
          this.textListeners.forEach((cb) => cb(this.text));
        }

        this.sendRequest("crdt_awareness_get", {
          work_id: this.workBeId,
        }).then((awareResp) => {
          const awareVal = extractValue(awareResp) as Record<string, unknown>;
          const states = awareVal.states as AwarenessState[] || [];
          this.awarenessMap.clear();
          for (const s of states) {
            this.awarenessMap.set(s.session_id, s);
          }
          this.awarenessListeners.forEach((cb) => cb(Array.from(this.awarenessMap.values())));
        }).catch(() => {});
      } catch (e) {
        console.warn("[CRDT-DIAG] crdt_sync_open failed for work", this.workBeId, "— falling back to edition. Error:", e);
        // CRDT open failed — fall through to edition fallback below
      }
    }
    if (!loaded) {
      try {
        console.log("[CRDT-DIAG] work_get_edition fallback for work", this.workBeId);
        const edResp = await this.sendRequest("work_get_edition", {
          work_id: this.workBeId,
        });
        const edVal = extractValue(edResp) as Record<string, unknown>;
        if (edVal) {
          const edText = (edVal as { text?: string }).text
            || (edVal as { type?: string; value?: string }).value
            || "";
          this.text = edText;
          console.log("[CRDT-DIAG] edition loaded, length=", edText.length);
          this.textListeners.forEach((cb) => cb(this.text));
        }
      } catch {
        // Expected during identity transitions
      }
    }
  }

  /**
   * Switch to a different work WITHOUT reconnecting the WebSocket.
   * Closes the old work's CRDT channel and opens the new one on the same
   * persistent connection — eliminates the reconnect gap that caused the
   * two-click bug and transclusion race conditions.
   */
  async switchWork(newWorkId: number): Promise<void> {
    if (this.workBeId === newWorkId && this.crdtReady) return;
    if (!this.connected || !this.ws || this.ws.readyState !== WebSocket.OPEN) return;

    // Close the old work's CRDT channel (keeps the WebSocket alive)
    if (this.crdtReady && this.workBeId) {
      try {
        await this.sendRequest("crdt_sync_close", { work_id: this.workBeId });
      } catch {
        // ignore close errors during switch
      }
      this.crdtReady = false;
    }

    // Clear local state for the new work
    this.text = "";
    this.skipCrdt = false;
    this.crdtOpenedThisConnection = false;
    this.awarenessMap.clear();
    this.recentChanges = [];
    this.textListeners.forEach((cb) => cb(""));

    // Open the new work's CRDT channel on the SAME connection
    this.workBeId = newWorkId;
    await this.tryOpenWork();
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

    // Capture large session ID from raw text before JSON.parse loses precision
    const humberMatch = text.match(/"Humber":(\d{16,})/);
    if (humberMatch) {
      this.sessionIdStr = humberMatch[1];
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
      // When CRDT is active, client text is authoritative.
      // Server-side materialization fires work_revised after debounce,
      // but our CRDT text already reflects all local edits.
      // Remote changes arrive via crdt_text_delta from other sessions.
      // Calling refreshText() here would clobber the editor with stale text.
    }

    if (eventType === "crdt_text_update") {
      const payload = event.payload as Record<string, unknown> | undefined;
      if (payload && payload.work_id === this.workBeId && !this.skipCrdt) {
        console.log("[CRDT-DIAG] received crdt_text_update from another session");
        const newText = payload.text as string;
        if (this.deltaInFlight) {
          this.pendingServerText = newText;
        } else if (newText !== this.text) {
          this.text = newText;
          this.textListeners.forEach((cb) => cb(newText));
        }
      }
    }

    if (eventType === "crdt_text_delta") {
      const payload = event.payload as Record<string, unknown> | undefined;
      if (payload && payload.work_id === this.workBeId && !this.skipCrdt) {
        console.log("[CRDT-DIAG] received crdt_text_delta from another session");
        const ops = payload.ops as Array<{ type: string; count?: number; text?: string }>;
        const author = (payload.author_name as string) || "unknown";
        try {
          const newText = applyDeltaOps(this.text, ops);
          if (newText !== this.text) {
            const changes = this.computeChangesFromDelta(ops);
            if (changes.length > 0) {
              const now = Date.now();
              for (const c of changes) {
                this.recentChanges.push({ ...c, timestamp: now, author });
              }
              this.recentChanges = this.recentChanges.filter(
                (c) => now - c.timestamp < 5000,
              );
              this.changeHighlightListeners.forEach((cb) =>
                cb([...this.recentChanges]),
              );
            }
            this.text = newText;
            this.textListeners.forEach((cb) => cb(newText));
          }
        } catch {
          this.refreshText();
        }
      }
    }

    if (eventType === "crdt_awareness_update") {
      const payload = event.payload as Record<string, unknown> | undefined;
      if (payload && payload.work_id === this.workBeId) {
        const incoming = payload.state as AwarenessState;
        this.awarenessMap.set(incoming.session_id, incoming);
        this.awarenessListeners.forEach((cb) => cb(Array.from(this.awarenessMap.values())));
      }
    }

    if (eventType === "crdt_awareness_remove") {
      const payload = event.payload as Record<string, unknown> | undefined;
      if (payload && payload.work_id === this.workBeId) {
        const removedSessionId = payload.session_id as number;
        this.awarenessMap.delete(removedSessionId);
        this.awarenessListeners.forEach((cb) => cb(Array.from(this.awarenessMap.values())));
      }
    }

    if (eventType === "compound_source_changed") {
      const payload = event.payload as Record<string, unknown> | undefined;
      if (payload) {
        const compoundWorkId = payload.compound_work_id as number;
        const sourceWorkId = payload.source_work_id as number;
        if (compoundWorkId === this.workBeId) {
          this.compoundSourceListeners.forEach((cb) => cb(compoundWorkId, sourceWorkId));
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

  private computeChangesFromDelta(
    ops: Array<{ type: string; count?: number; text?: string }>,
  ): Array<{ start: number; end: number }> {
    const changes: Array<{ start: number; end: number }> = [];
    let offset = 0;
    for (const op of ops) {
      if (op.type === "retain") {
        offset += op.count ?? 0;
      } else if (op.type === "insert") {
        const len = op.text?.length ?? 0;
        if (len > 0) {
          changes.push({ start: offset, end: offset + len });
          offset += len;
        }
      }
    }
    return changes;
  }

  private onClose(): void {
    if (this.ws && this.ws.readyState !== WebSocket.CLOSED) {
      return;
    }
    this.connected = false;
    this.crdtReady = false;
    this.crdtOpenedThisConnection = false;
    this.deltaInFlight = false;
    this.pendingServerText = null;
    if (this.awarenessSendTimer !== null) {
      clearTimeout(this.awarenessSendTimer);
      this.awarenessSendTimer = null;
    }
    this.pendingAwareness = null;
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
    this.connectionListeners.forEach((cb) => cb(false));
    this.pending.forEach((handler) => handler("connection closed", true));
    this.pending.clear();
    if (!this.disposed) {
      this.scheduleReconnect();
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer) return;
    const base = Math.min(
      CrdtSyncClient.RECONNECT_BASE_MS * Math.pow(2, this.reconnectAttempts),
      CrdtSyncClient.RECONNECT_MAX_MS,
    );
    const jitter = base * 0.25 * (Math.random() * 2 - 1);
    const delay = Math.max(CrdtSyncClient.RECONNECT_BASE_MS, base + jitter);
    this.reconnectAttempts++;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, delay);
  }

  getReconnectDelay(attempt: number): number {
    const base = Math.min(
      CrdtSyncClient.RECONNECT_BASE_MS * Math.pow(2, attempt),
      CrdtSyncClient.RECONNECT_MAX_MS,
    );
    return base;
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
    if (suffix > 0) {
      ops.push({ type: "retain", count: suffix });
    }

    this.deltaInFlight = true;
    console.log("[CRDT-DIAG] sending work_revise_delta, ops:", ops.length, "for work", this.workBeId);
    this.sendRequest("work_revise_delta", {
      work_id: this.workBeId,
      base_revision: 0,
      ops,
    }).then(() => {
      this.deltaInFlight = false;
      if (this.pendingServerText !== null) {
        const serverText = this.pendingServerText;
        this.pendingServerText = null;
        const currentText = this.text;
        if (serverText !== currentText) {
          this.text = serverText;
          this.textListeners.forEach((cb) => cb(serverText));
        }
      }
    }).catch((e) => {
      this.deltaInFlight = false;
      const msg = String(e?.message || e || "");
      if (msg.includes("WebSocket not open") || msg.includes("connection closed") || msg.includes("timed out")) {
        console.warn("Text delta not sent (will sync on reconnect):", msg);
      } else {
        console.error("Failed to send text delta:", e);
        this.text = oldText;
        this.textListeners.forEach((cb) => cb(oldText));
      }
    });
  }

  async findBacklinks(workId: number): Promise<BacklinkEntry[]> {
    const resp = await this.sendRequest("work_backlinks", { work_id: workId });
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as BacklinkEntry[];
    return [];
  }

  async crossServerResolve(tumbler: string, contentHashHex: string): Promise<{ text: string; hashVerified: boolean; cached: boolean; originServerId: number }> {
    const resp = await this.sendRequest("cross_server_resolve", { tumbler, content_hash_hex: contentHashHex });
    const val = extractValue(resp) as Record<string, unknown>;
    return {
      text: (val.text as string) || "",
      hashVerified: val.hash_verified === true,
      cached: val.cached === true,
      originServerId: (val.origin_server_id as number) || 0,
    };
  }

  async workEndorse(workId: number, endorsements: Array<[number, number]>): Promise<void> {
    await this.sendRequest("work_endorse", { work_id: workId, endorsements });
  }

  async workRetractEndorsement(workId: number, endorsements: Array<[number, number]>): Promise<void> {
    await this.sendRequest("work_retract", { work_id: workId, endorsements });
  }

  async workEndorsements(workId: number): Promise<Array<[number, number]>> {
    const resp = await this.sendRequest("work_endorsements", { work_id: workId });
    const val = extractValue(resp) as Record<string, unknown>;
    return (val.endorsements as Array<[number, number]>) || [];
  }

  async fetchRevisionRange(workId: number, from: number, to: number): Promise<string[]> {
    const resp = await this.sendRequest("work_fetch_revision_range", { work_id: workId, from, to });
    const val = extractValue(resp) as Record<string, unknown>;
    const revisions = (val.revisions as Array<[number, Record<string, unknown>]>) || [];
    return revisions.map(([, ed]): string => {
      if (typeof ed === "string") return ed;
      const entries = (ed as Record<string, unknown>).entries;
      if (Array.isArray(entries)) {
        return entries.map((e: Record<string, unknown>) => {
          const el = e.element as Record<string, unknown> | undefined;
          return el?.Text || el?.text || "";
        }).join("");
      }
      return String(ed?.Text || ed?.text || JSON.stringify(ed) || "");
    });
  }

  async findTranscluders(text: string): Promise<number[]> {
    const resp = await this.sendRequest("find_text_transcluders", { text });
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as number[];
    const rec = val as Record<string, unknown>;
    return (rec.work_ids as number[]) || [];
  }

  async findWorksForContent(text: string): Promise<number[]> {
    const resp = await this.sendRequest("find_works_for_content", { text });
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as number[];
    const rec = val as Record<string, unknown>;
    return (rec.work_ids as number[]) || [];
  }

  async annotationCreate(workId: number, annotationId: number, kind: string, payload: string, charStart: number, charEnd: number, isPrivate?: boolean): Promise<void> {
    await this.sendRequest("annotation_create", {
      work_id: workId,
      annotation_id: annotationId,
      kind,
      payload,
      char_start: charStart,
      char_end: charEnd,
      is_private: isPrivate ?? false,
    });
  }

  async annotationDelete(workId: number, annotationId: number): Promise<void> {
    await this.sendRequest("annotation_delete", {
      work_id: workId,
      annotation_id: annotationId,
    });
  }

  async annotationList(workId: number): Promise<AnnotationEntry[]> {
    const resp = await this.sendRequest("annotation_list", { work_id: workId });
    const val = extractValue(resp);
    if (Array.isArray(val)) return val as AnnotationEntry[];
    return [];
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
