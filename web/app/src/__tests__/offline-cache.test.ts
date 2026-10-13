import { describe, it, expect, beforeEach, vi } from "vitest";
import "fake-indexeddb/auto";

// The storage seam (ui-font.test.ts pattern): a controllable map
// instead of environment localStorage.
const backing = new Map<string, string>();
vi.mock("../safe-storage", () => ({
  storageGet: (k: string) => backing.get(k) ?? null,
  storageSet: (k: string, v: string) => void backing.set(k, v),
  storageRemove: (k: string) => void backing.delete(k),
}));

import {
  getCacheLimitMb,
  setCacheLimitMb,
  cacheDocument,
  getCachedDocument,
  setCachedStarred,
  cacheStats,
  prefetchStarred,
  DEFAULT_CACHE_LIMIT_MB,
  MIN_CACHE_LIMIT_MB,
  MAX_CACHE_LIMIT_MB,
} from "../offline-cache";

// Isolation: a fresh DB per test.
beforeEach(async () => {
  indexedDB = new IDBFactory();
  backing.clear();
});

declare let indexedDB: IDBFactory;

function mb(n: number): string {
  return "x".repeat(n * 1024 * 1024);
}

describe("offline-cache — limit settings", () => {
  it("defaults to 50MB", () => {
    expect(getCacheLimitMb()).toBe(DEFAULT_CACHE_LIMIT_MB);
  });

  it("clamps to [10, 500] and rounds", () => {
    setCacheLimitMb(3);
    expect(getCacheLimitMb()).toBe(MIN_CACHE_LIMIT_MB);
    setCacheLimitMb(9999);
    expect(getCacheLimitMb()).toBe(MAX_CACHE_LIMIT_MB);
    setCacheLimitMb(50.6);
    expect(getCacheLimitMb()).toBe(51);
  });

  it("falls back to default on invalid stored settings", async () => {
    // Fresh module: memoryLimitMb must be unset for the storage path
    // to be consulted at all.
    vi.resetModules();
    const mod = await import("../offline-cache");
    backing.set("xudanu_offline_cache_limit_mb", "junk");
    expect(mod.getCacheLimitMb()).toBe(DEFAULT_CACHE_LIMIT_MB);
    backing.set("xudanu_offline_cache_limit_mb", "5");
    expect(mod.getCacheLimitMb()).toBe(DEFAULT_CACHE_LIMIT_MB);
  });
});

describe("offline-cache — document mirror", () => {
  it("round-trips a cached document with utf-8 size and LRU bump", async () => {
    await cacheDocument({ work_id: 1, title: "One", text: "héllo", starred: false });
    const doc = await getCachedDocument(1);
    expect(doc).not.toBeNull();
    expect(doc!.title).toBe("One");
    expect(doc!.size).toBe(6); // h(1) é(2) l l o — utf-8 bytes
    const again = await getCachedDocument(1);
    expect(again!.last_read).toBeGreaterThanOrEqual(doc!.last_read);
  });

  it("returns null for unknown works", async () => {
    expect(await getCachedDocument(0xdead)).toBeNull();
  });

  it("evicts unstarred LRU-first; starred never drops", async () => {
    setCacheLimitMb(MIN_CACHE_LIMIT_MB); // 10MB
    await cacheDocument({ work_id: 1, title: "old unstarred", text: mb(6), starred: false });
    await new Promise((r) => setTimeout(r, 5));
    await cacheDocument({ work_id: 2, title: "starred", text: mb(6), starred: true });
    // Total 12MB > 10MB: the unstarred older read goes, starred stays.
    expect(await getCachedDocument(1)).toBeNull();
    const kept = await getCachedDocument(2);
    expect(kept?.title).toBe("starred");
  });

  it("keeps an all-starred over-budget set and reports it", async () => {
    setCacheLimitMb(MIN_CACHE_LIMIT_MB);
    await cacheDocument({ work_id: 1, title: "a", text: mb(6), starred: true });
    await cacheDocument({ work_id: 2, title: "b", text: mb(6), starred: true });
    const stats = await cacheStats();
    expect(stats.documents).toBe(2);
    expect(stats.starred).toBe(2);
    expect(stats.overBudget).toBe(true);
  });

  it("setCachedStarred pins on star, exposes on unstar", async () => {
    setCacheLimitMb(MIN_CACHE_LIMIT_MB);
    await cacheDocument({ work_id: 1, title: "a", text: mb(6), starred: false });
    await setCachedStarred(1, true);
    await cacheDocument({ work_id: 2, title: "b", text: mb(6), starred: false });
    // 12MB, one starred: only the unstarred one can go.
    const stats = await cacheStats();
    expect(stats.documents).toBe(1);
    expect(stats.starred).toBe(1);
  });

  it("stats count documents and bytes", async () => {
    await cacheDocument({ work_id: 1, title: "a", text: "hello", starred: false });
    await cacheDocument({ work_id: 2, title: "b", text: "hi", starred: true });
    const stats = await cacheStats();
    expect(stats.documents).toBe(2);
    expect(stats.starred).toBe(1);
    expect(stats.totalBytes).toBe(7);
    expect(stats.overBudget).toBe(false);
  });
});

describe("offline-cache — prefetch", () => {
  it("counts only successful fetches with text; skips failures", async () => {
    const n = await prefetchStarred(
      async (id) => {
        if (id === 1) return { text: "content", title: "One" };
        if (id === 2) return null;
        if (id === 3) return { text: "" };
        throw new Error("fetch failed");
      },
      [
        { work_id: 1 },
        { work_id: 2 },
        { work_id: 3 },
        { work_id: 4 },
      ],
    );
    expect(n).toBe(1);
    const doc = await getCachedDocument(1);
    expect(doc?.starred).toBe(true);
  });
});
