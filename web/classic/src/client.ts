/// <reference types="vite/client" />

export interface WellKnown {
  api_version: number;
  implementation: string;
  server_version?: string;
  server_name: string;
  stats?: { work_count?: number };
}

export interface SearchEntry {
  work_id: number;
  title?: string;
  matches?: { context?: string }[];
}

export interface TrailStopEntry {
  work_id: number;
  note?: string;
  title?: string;
}

export interface TrailEntry {
  trail_id: number;
  name: string;
  introduction?: string;
  published: boolean;
  stops: TrailStopEntry[];
}

interface Frame {
  v?: number;
  type: string;
  id?: number;
  op?: string;
  code?: string;
  payload?: Record<string, unknown>;
  value?: unknown;
  message?: string;
}

export class WireError extends Error {
  code?: string;
  constructor(message: string, code?: string) {
    super(message);
    this.code = code;
  }
}

function val<T>(v: unknown): T {
  if (v && typeof v === "object" && "value" in (v as Record<string, unknown>)) {
    return (v as Record<string, unknown>).value as T;
  }
  return v as T;
}

/**
 * Read-only client for the xudanu wire contract (api_version 1).
 * Speaks only pinned operations; refuses servers declaring a
 * different api_version.
 */
export class ClassicClient {
  private ws: WebSocket | null = null;
  private nextId = 1;
  private pending = new Map<number, { resolve: (v: unknown) => void; reject: (e: Error) => void }>();
  private wellKnown: WellKnown | null = null;
  /** Fires when the socket drops after a successful connect; the app
   *  uses it to reconnect instead of timing out every request. */
  onDrop: (() => void) | null = null;

  get serverName(): string {
    return this.wellKnown?.server_name ?? "";
  }

  get serverVersion(): string {
    return this.wellKnown?.server_version ?? "";
  }

  get apiVersion(): number {
    return this.wellKnown?.api_version ?? 0;
  }

  async connect(): Promise<void> {
    const resp = await fetch("/.well-known/xanadu-server.json");
    if (!resp.ok) throw new Error(`no well-known at this origin (${resp.status})`);
    this.wellKnown = (await resp.json()) as WellKnown;
    if (this.wellKnown.api_version !== 1) {
      throw new Error(
        `server declares api_version ${this.wellKnown.api_version}; this client speaks version 1. ` +
          "The wire contract forbids silent cross-version operation — refusing to connect.",
      );
    }

    const ws = new WebSocket(
      `${location.protocol === "https:" ? "wss" : "ws"}://${location.host}/xudanu?format=json&version=2`,
    );
    await new Promise<void>((resolve, reject) => {
      ws.onopen = () => resolve();
      ws.onerror = () => reject(new Error("websocket connect failed"));
    });
    ws.onmessage = (ev) => this.onFrame(String(ev.data));
    ws.onclose = () => {
      if (this.ws === ws) {
        this.ws = null;
        for (const [, p] of this.pending) p.reject(new Error("connection dropped"));
        this.pending.clear();
        this.onDrop?.();
      }
    };
    this.ws = ws;

    await this.request("session_connect");
    await this.request("session_login_public");
  }

  close(): void {
    this.ws?.close();
    this.ws = null;
  }

  private onFrame(raw: string): void {
    const f = JSON.parse(raw) as Frame;
    if ((f.type === "response" || f.type === "error") && f.id !== undefined) {
      const p = this.pending.get(f.id);
      if (p) {
        this.pending.delete(f.id);
        if (f.type === "error") p.reject(new WireError(`${f.op ?? "op"}: ${f.message ?? "?"}`, f.code));
        else p.resolve(f.value);
      }
    }
  }

  private request(op: string, payload: Record<string, unknown> = {}): Promise<unknown> {
    if (!this.ws) return Promise.reject(new Error("not connected"));
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws!.send(JSON.stringify({ v: 2, type: "request", id, op, payload }));
      setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`timeout: ${op}`));
        }
      }, 10000);
    });
  }

  async search(query: string, max = 20): Promise<SearchEntry[]> {
    const r = val<{ results?: SearchEntry[]; entries?: SearchEntry[] } | SearchEntry[]>(
      await this.request("global_text_search", { query, max_results: max }),
    );
    return Array.isArray(r) ? r : (r.results ?? r.entries ?? []);
  }

  async readWork(workId: number): Promise<string> {
    const e = val<{ text?: string }>(await this.request("work_get_edition", { work_id: workId }));
    return e?.text ?? "";
  }


  async linksFor(workId: number): Promise<LinkEntryClassic[]> {
    const r = val<{ entries?: LinkEntryClassic[] } | LinkEntryClassic[]>(
      await this.request("link_list_for_work", { work_id: workId }),
    );
    return Array.isArray(r) ? r : (r.entries ?? []);
  }

  async trails(): Promise<TrailEntry[]> {
    const r = val<TrailEntry[] | { trails?: TrailEntry[] }>(
      await this.request("trail_list_published", {}),
    );
    return Array.isArray(r) ? r : (r.trails ?? []);
  }

  async grab(workId: number): Promise<void> {
    await this.request("work_grab", { work_id: workId });
  }

  /** Create a new work in the shared docuverse; returns its id. */
  async createWork(text = ""): Promise<number> {
    const r = val<number | { work_id?: number }>(
      await this.request("work_create", { edition: { text } }),
    );
    return typeof r === "number" ? r : Number(r?.work_id ?? 0);
  }

  async release(workId: number): Promise<void> {
    await this.request("work_release", { work_id: workId });
  }

  async saveAndRelease(workId: number, text: string): Promise<void> {
    await this.request("work_save_and_release", { work_id: workId, edition: { text } });
  }

  /** CRDT-path edit: apply a text delta (the same op the workspace's
   *  collaborative editor uses). The session must hold the grab. */
  async reviseDelta(
    workId: number,
    ops: Array<{ type: string; count?: number; text?: string }>,
  ): Promise<void> {
    await this.request("work_revise_delta", { work_id: workId, base_revision: 0, ops });
  }

  /** Revision history: the page-stack wire ops. */
  async revisionCount(workId: number): Promise<number> {
    const r = val<{ revision_count?: number; count?: number } | number>(
      await this.request("work_revision_count", { work_id: workId }),
    );
    if (typeof r === "number") return r;
    return r?.revision_count ?? r?.count ?? 0;
  }

  async fetchRevision(workId: number, number: number): Promise<string> {
    const e = val<{ text?: string }>(
      await this.request("work_fetch_revision", { work_id: workId, number }),
    );
    return e?.text ?? "";
  }

  /** Per-span authorship with cryptographic validity — the lens. */
  async attribution(workId: number): Promise<AttributionSpan[]> {
    const r = val<{ spans?: AttributionSpan[] } | AttributionSpan[]>(
      await this.request("attribution_query", { work_id: workId }),
    );
    return Array.isArray(r) ? r : (r?.spans ?? []);
  }

  /** Transclusion identity: the ranges of this work's text that are
   *  live windows onto other works, with source titles. */
  async resolveInline(workId: number): Promise<InlineTransclusions> {
    const r = val<{
      text?: string;
      span_ranges?: TransclusionSpan[];
      source_titles?: Record<string, string>;
    }>(await this.request("resolve_inline_transclusions", { work_id: workId }));
    return {
      text: r?.text ?? "",
      spanRanges: r?.span_ranges ?? [],
      sourceTitles: r?.source_titles ?? {},
    };
  }

  /** Create a two-ended typed link (the LinkCreator wire shape). */
  async createLink(args: {    origin: number;
    destination: number;
    originRef?: { excerpt: string; start: number; end: number };
    destinationRef?: { excerpt: string; start: number; end: number };
    linkTypes?: number[];
  }): Promise<number> {
    const ref = (workId: number, r: { excerpt: string; start: number; end: number }) => ({
      kind: "single",
      work_context: workId,
      original_context: null,
      path_context: null,
      excerpt: r.excerpt,
      start_position: r.start,
      end_position: r.end,
    });
    const payload: Record<string, unknown> = { origin: args.origin, destination: args.destination };
    if (args.originRef) payload.origin_ref = ref(args.origin, args.originRef);
    if (args.destinationRef) payload.destination_ref = ref(args.destination, args.destinationRef);
    if (args.linkTypes && args.linkTypes.length > 0) payload.link_types = args.linkTypes;
    const r = val<number>(await this.request("link_create", payload));
    return typeof r === "number" ? r : 0;
  }

  /** Gather: add a passage to an EXISTING end of a link — one
   *  connection, many passages jointly filling one blank. */
  async gatherInto(
    linkId: number,
    endName: string,
    attachment: { workContext: number; excerpt: string; start: number; end: number },
  ): Promise<void> {
    await this.request("link_end_add_attachment", {
      link_id: linkId,
      end_name: endName,
      attachment: {
        kind: "single",
        work_context: attachment.workContext,
        original_context: null,
        path_context: null,
        excerpt: attachment.excerpt,
        start_position: attachment.start,
        end_position: attachment.end,
      },
    });
  }
}

export interface LinkRef {
  kind: string;
  work_context?: number;
  original_context?: number | null;
  excerpt?: string;
  start_position?: number;
  end_position?: number;
}

export interface EndSetRef {
  work_context?: number;
  excerpt?: string | null;
  start_position?: number;
  end_position?: number;
  kind?: string;
  link_attachment?: number;
}

export interface LinkEntryClassic {
  link_id: number;
  origin: number;
  destination: number | null;
  end_sets?: Array<[string, EndSetRef[]]>;
  origin_ref?: LinkRef;
  destination_ref?: LinkRef;
  origin_title?: string;
  destination_title?: string;
  link_types?: number[];
}

export interface RevisionInfo {
  revision_count: number;
}

export interface AttributionSpan {
  start: number;
  end: number;
  author_display_name?: string | null;
  signature_valid: boolean;
  verification_state?: string | null;
}

export interface TransclusionSpan {
  source_work_id: number;
  char_start: number;
  char_end: number;
  flat_start?: number;
  flat_end?: number;
  resolved_content?: string;
}

export interface InlineTransclusions {
  text: string;
  spanRanges: TransclusionSpan[];
  sourceTitles: Record<string, string>;
}

export const LINK_TYPE_NAMES: Record<number, { name: string; color: string }> = {
  1: { name: "comment", color: "#7aa2f7" },
  2: { name: "reference", color: "#9ece6a" },
  3: { name: "disagreement", color: "#f7768e" },
  4: { name: "quotation", color: "#e0af68" },
  5: { name: "see also", color: "#bb9af7" },
  6: { name: "web", color: "#7dcfff" },
};
