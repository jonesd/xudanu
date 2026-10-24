/// Pending annotation operations (step 3, offline annotations):
/// creates/deletes recorded while disconnected, replayed on
/// reconnect. annotation_id is CLIENT-SUPPLIED on create, so replay
/// is idempotent server-side. Pending spans rebase through text
/// deltas (the client subscribes them to the engine's delta event)
/// so an annotation anchored to offline-typed text lands correctly
/// after the reconnect merge.
///
/// Storage: IndexedDB when available (survives reload), in-memory
/// fallback otherwise (tests, embeddable environments). Queue is
/// per-work and expected to be tiny (handfuls, not thousands).

import type { AnnotationEntry } from "./protocol";

export interface PendingAnnotationOp {
  /** Queue id (annotation id + kind disambiguate replay). */
  id: string;
  work_id: number;
  kind: "create" | "delete";
  annotation_id: number;
  /** Create-only payload fields. */
  ann_kind?: string;
  payload?: string;
  char_start?: number;
  char_end?: number;
  is_private?: boolean;
  created_at: number;
}

const DB_NAME = "xudanu-pending";
const DB_VERSION = 1;
const STORE = "annotation_ops";

let memoryQueue: PendingAnnotationOp[] | null = null;
function memory(): PendingAnnotationOp[] {
  if (memoryQueue === null) memoryQueue = [];
  return memoryQueue;
}

function hasIdb(): boolean {
  return typeof indexedDB !== "undefined";
}

function openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onupgradeneeded = () => {
      if (!req.result.objectStoreNames.contains(STORE)) {
        req.result.createObjectStore(STORE, { keyPath: "id" });
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

async function withStore<T>(mode: IDBTransactionMode, fn: (store: IDBObjectStore) => IDBRequest): Promise<T | null> {
  try {
    const db = await openDb();
    return await new Promise<T | null>((resolve, reject) => {
      const t = db.transaction(STORE, mode);
      const req = fn(t.objectStore(STORE));
      req.onsuccess = () => resolve(req.result as T);
      req.onerror = () => reject(req.error);
      t.oncomplete = () => db.close();
    });
  } catch {
    return null; // storage failures never break editing
  }
}

export async function enqueueAnnotationOp(op: PendingAnnotationOp): Promise<void> {
  if (!hasIdb()) {
    const existing = memory().find((e) => e.id === op.id);
    if (!existing) memory().push(op);
    return;
  }
  await withStore("readwrite", (s) => s.put(op));
}

export async function pendingAnnotationOps(workId: number): Promise<PendingAnnotationOp[]> {
  if (!hasIdb()) {
    return memory().filter((e) => e.work_id === workId);
  }
  const all = (await withStore<PendingAnnotationOp[]>("readonly", (s) => s.getAll())) ?? [];
  return all.filter((e) => e.work_id === workId);
}

export async function removePendingOp(id: string): Promise<void> {
  if (!hasIdb()) {
    memoryQueue = memory().filter((e) => e.id !== id);
    return;
  }
  await withStore("readwrite", (s) => s.delete(id));
}

/** Drop every queued op (work deletion, tests). */
export async function clearPendingAnnotationOps(): Promise<void> {
  if (!hasIdb()) {
    memoryQueue = [];
    return;
  }
  const all = (await withStore<PendingAnnotationOp[]>("readonly", (s) => s.getAll())) ?? [];
  for (const e of all) await removePendingOp(e.id);
}

export async function replacePendingOps(workId: number, ops: PendingAnnotationOp[]): Promise<void> {
  if (!hasIdb()) {
    memoryQueue = memory().filter((e) => e.work_id !== workId).concat(ops);
    return;
  }
  const existing = await pendingAnnotationOps(workId);
  for (const e of existing) {
    if (!ops.some((o) => o.id === e.id)) await removePendingOp(e.id);
  }
  for (const op of ops) {
    if (!existing.some((e) => e.id === op.id)) await enqueueAnnotationOp(op);
  }
}

/**
 * Merge the server list with pending ops for display: pending
 * creates append as `pending_sync` entries; pending deletes hide
 * their server entries (gone the moment the server confirms).
 */
export function mergePendingAnnotations(
  server: AnnotationEntry[],
  pending: PendingAnnotationOp[],
): AnnotationEntry[] {
  const deleted = new Set(
    pending.filter((p) => p.kind === "delete").map((p) => p.annotation_id),
  );
  const creates = pending
    .filter((p) => p.kind === "create")
    .map<AnnotationEntry>((p) => ({
      annotation_id: p.annotation_id,
      kind: p.ann_kind ?? "note",
      payload: p.payload ?? "",
      char_start: p.char_start ?? 0,
      char_end: p.char_end ?? 0,
      created_by: null,
      created_by_name: null,
      created_at: p.created_at,
      is_private: p.is_private ?? false,
      pending_sync: true,
    }));
  return server.filter((a) => !deleted.has(a.annotation_id)).concat(creates);
}
