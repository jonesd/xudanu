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
  payload?: Record<string, unknown>;
  value?: unknown;
  message?: string;
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
        if (f.type === "error") p.reject(new Error(`${f.op ?? "op"}: ${f.message ?? "?"}`));
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
    const r = val<{ entries?: SearchEntry[] } | SearchEntry[]>(
      await this.request("global_text_search", { query, max_results: max }),
    );
    return Array.isArray(r) ? r : (r.entries ?? []);
  }

  async readWork(workId: number): Promise<string> {
    const e = val<{ text?: string }>(await this.request("work_get_edition", { work_id: workId }));
    return e?.text ?? "";
  }

  async trails(): Promise<TrailEntry[]> {
    const r = val<TrailEntry[] | { trails?: TrailEntry[] }>(
      await this.request("trail_list_published", {}),
    );
    return Array.isArray(r) ? r : (r.trails ?? []);
  }
}
