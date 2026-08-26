/// Offline reading cache (PWA): IndexedDB mirror of recently-read
/// documents plus the app shell precache. Policy:
/// - Starred works are pinned (never evicted) and refreshed whenever
///   viewed; the star already means "important to me", so it is also
///   the offline-intent signal.
/// - Unstarred reads land in an LRU bounded by a user-chosen byte
///   budget (default 50MB; text works are ~2-5KB, images change the
///   math). Eviction order: unstarred LRU first; a starred set larger
///   than the budget is reported, never silently dropped.
/// - Editing is never served from cache: offline mode is read-only
///   by design (offline CRDT queueing is a separate, larger project).

const DB_NAME = "xudanu-offline";
const DB_VERSION = 1;
const DOC_STORE = "docs";

export interface CachedDoc {
  work_id: number;
  title: string;
  text: string;
  /** Bytes of `text` (UTF-8). */
  size: number;
  starred: boolean;
  /** Last-read timestamp (ms) — LRU key. */
  last_read: number;
}

export const DEFAULT_CACHE_LIMIT_MB = 50;
export const MIN_CACHE_LIMIT_MB = 10;
export const MAX_CACHE_LIMIT_MB = 500;

const SETTINGS_KEY = "xudanu_offline_cache_limit_mb";

// localStorage is unavailable in some embed/test environments; keep an
// in-memory fallback so the setting still functions per-session.
let memoryLimitMb: number | null = null;

export function getCacheLimitMb(): number {
  if (memoryLimitMb !== null) return memoryLimitMb;
  try {
    const raw = localStorage.getItem(SETTINGS_KEY);
    const v = raw ? Number(raw) : DEFAULT_CACHE_LIMIT_MB;
    if (Number.isFinite(v) && v >= MIN_CACHE_LIMIT_MB && v <= MAX_CACHE_LIMIT_MB) {
      return v;
    }
  } catch { /* fall through */ }
  return DEFAULT_CACHE_LIMIT_MB;
}

export function setCacheLimitMb(mb: number): void {
  const clamped = Math.max(MIN_CACHE_LIMIT_MB, Math.min(MAX_CACHE_LIMIT_MB, Math.round(mb)));
  memoryLimitMb = clamped;
  try { localStorage.setItem(SETTINGS_KEY, String(clamped)); } catch { /* memory only */ }
  // Eviction runs on next access; the limit is read fresh each time.
}

function openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains(DOC_STORE)) {
        const store = db.createObjectStore(DOC_STORE, { keyPath: "work_id" });
        store.createIndex("last_read", "last_read");
        store.createIndex("starred", "starred");
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

function tx<T>(mode: IDBTransactionMode, fn: (store: IDBObjectStore) => IDBRequest<T>): Promise<T> {
  return openDb().then(
    (db) =>
      new Promise<T>((resolve, reject) => {
        const t = db.transaction(DOC_STORE, mode);
        const req = fn(t.objectStore(DOC_STORE));
        req.onsuccess = () => resolve(req.result);
        req.onerror = () => reject(req.error);
        t.oncomplete = () => db.close();
      }),
  );
}

function txAll<T>(mode: IDBTransactionMode, fn: (store: IDBObjectStore) => IDBRequest): Promise<T> {
  return openDb().then(
    (db) =>
      new Promise<T>((resolve, reject) => {
        const t = db.transaction(DOC_STORE, mode);
        const req = fn(t.objectStore(DOC_STORE));
        req.onsuccess = () => resolve(req.result as T);
        req.onerror = () => reject(req.error);
        t.oncomplete = () => db.close();
      }),
  );
}

const utf8Len = (s: string) => new TextEncoder().encode(s).length;

/** Record a read: upsert the doc and enforce the budget. */
export async function cacheDocument(work: {
  work_id: number;
  title: string;
  text: string;
  starred: boolean;
}): Promise<void> {
  if (!("indexedDB" in globalThis)) return;
  try {
    const doc: CachedDoc = {
      work_id: work.work_id,
      title: work.title,
      text: work.text,
      size: utf8Len(work.text),
      starred: work.starred,
      last_read: Date.now(),
    };
    await tx("readwrite", (s) => s.put(doc));
    await enforceBudget();
  } catch { /* cache failures never break reading */ }
}

/** Serve a doc from the mirror, bumping its LRU clock. */
export async function getCachedDocument(workId: number): Promise<CachedDoc | null> {
  if (!("indexedDB" in globalThis)) return null;
  try {
    const doc = await tx<CachedDoc | undefined>("readonly", (s) => s.get(workId));
    if (!doc) return null;
    doc.last_read = Date.now();
    await tx("readwrite", (s) => s.put(doc));
    return doc;
  } catch {
    return null;
  }
}

/** Mark/unmark pin status when the star toggles. */
export async function setCachedStarred(workId: number, starred: boolean): Promise<void> {
  if (!("indexedDB" in globalThis)) return;
  try {
    const doc = await tx<CachedDoc | undefined>("readonly", (s) => s.get(workId));
    if (doc) {
      doc.starred = starred;
      await tx("readwrite", (s) => s.put(doc));
      if (starred) await enforceBudget();
    }
  } catch { /* no-op */ }
}

async function enforceBudget(): Promise<void> {
  const limitBytes = getCacheLimitMb() * 1024 * 1024;
  const all = await txAll<CachedDoc[]>("readonly", (s) => s.getAll());
  let total = all.reduce((n, d) => n + d.size, 0);
  if (total <= limitBytes) return;

  // Evict unstarred, least-recently-read first. Starred never drops.
  const evictable = all
    .filter((d) => !d.starred)
    .sort((a, b) => a.last_read - b.last_read);
  for (const victim of evictable) {
    if (total <= limitBytes) break;
    await tx("readwrite", (s) => s.delete(victim.work_id));
    total -= victim.size;
  }
  // If still over: starred set alone exceeds the budget. Keep
  // everything (silently dropping stars is worse than exceeding) —
  // surfaced via cacheStats for the settings UI to warn about.
}

export interface CacheStats {
  documents: number;
  starred: number;
  totalBytes: number;
  limitMb: number;
  overBudget: boolean;
}

export async function cacheStats(): Promise<CacheStats> {
  const empty: CacheStats = { documents: 0, starred: 0, totalBytes: 0, limitMb: getCacheLimitMb(), overBudget: false };
  if (!("indexedDB" in globalThis)) return empty;
  try {
    const all = await txAll<CachedDoc[]>("readonly", (s) => s.getAll());
    const limitBytes = getCacheLimitMb() * 1024 * 1024;
    const totalBytes = all.reduce((n, d) => n + d.size, 0);
    return {
      documents: all.length,
      starred: all.filter((d) => d.starred).length,
      totalBytes,
      limitMb: getCacheLimitMb(),
      overBudget: totalBytes > limitBytes,
    };
  } catch {
    return empty;
  }
}

/** Prefetch all starred works (Wi-Fi idle use) — best effort. */
export async function prefetchStarred(
  fetchWork: (workId: number) => Promise<{ text: string; title?: string } | null>,
  starredIds: Array<{ work_id: number; title?: string }>,
): Promise<number> {
  let cached = 0;
  for (const w of starredIds) {
    try {
      const doc = await fetchWork(w.work_id);
      if (doc && doc.text) {
        await cacheDocument({ work_id: w.work_id, title: doc.title || w.title || "", text: doc.text, starred: true });
        cached++;
      }
    } catch { /* skip on failure */ }
  }
  return cached;
}
