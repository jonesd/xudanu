import { describe, it, expect, beforeEach } from "vitest";
import {
  cacheDocument,
  getCachedDocument,
  setCachedStarred,
  setCacheLimitMb,
  getCacheLimitMb,
  cacheStats,
  DEFAULT_CACHE_LIMIT_MB,
  MIN_CACHE_LIMIT_MB,
} from "../offline-cache";

// jsdom lacks indexedDB — these tests need the real thing; guard so the
// suite still passes where it's absent (CI jsdom) while running fully
// under `vitest --environment node` or real browsers.
const hasIdb = typeof indexedDB !== "undefined";
const maybeIt = hasIdb ? it : it.skip;

describe("cache limit setting", () => {
  it("defaults to 50MB", () => {
    expect(getCacheLimitMb()).toBe(DEFAULT_CACHE_LIMIT_MB);
  });
  it("clamps to range", () => {
    setCacheLimitMb(1);
    expect(getCacheLimitMb()).toBe(MIN_CACHE_LIMIT_MB);
    setCacheLimitMb(99999);
    expect(getCacheLimitMb()).toBe(500);
    setCacheLimitMb(50); // restore
  });
});

describe("document mirror", () => {
  beforeEach(async () => {
    if (!hasIdb) return;
    // Clean known ids
    for (const id of [91001, 91002, 91003]) {
      await setCachedStarred(id, false).catch(() => {});
    }
  });

  maybeIt("caches and retrieves a document", async () => {
    await cacheDocument({ work_id: 91001, title: "t", text: "hello offline", starred: false });
    const doc = await getCachedDocument(91001);
    expect(doc?.text).toBe("hello offline");
    expect(doc?.starred).toBe(false);
    expect(doc && doc.size).toBeGreaterThan(0);
  });

  maybeIt("star toggling updates the pin without losing text", async () => {
    await cacheDocument({ work_id: 91002, title: "t2", text: "pinned content", starred: false });
    await setCachedStarred(91002, true);
    const doc = await getCachedDocument(91002);
    expect(doc?.starred).toBe(true);
    expect(doc?.text).toBe("pinned content");
  });

  maybeIt("stats count documents and bytes", async () => {
    await cacheDocument({ work_id: 91003, title: "t3", text: "stat me", starred: true });
    const stats = await cacheStats();
    expect(stats.documents).toBeGreaterThanOrEqual(1);
    expect(stats.totalBytes).toBeGreaterThan(0);
    expect(stats.limitMb).toBe(50);
  });
});
