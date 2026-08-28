import { describe, it, expect, vi, afterEach } from "vitest";
import { storageGet, storageSet, storageRemove, storageClear } from "../safe-storage";

function withThrowingStorage() {
  Object.defineProperty(window, "localStorage", {
    get(): Storage {
      throw new DOMException("The operation is insecure.", "SecurityError");
    },
    configurable: true,
  });
}

describe("safe-storage under blocked storage (Safari SecurityError)", () => {
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("storageGet returns null instead of throwing", () => {
    withThrowingStorage();
    expect(() => storageGet("k")).not.toThrow();
    expect(storageGet("k")).toBeNull();
  });

  it("storageSet does not throw", () => {
    withThrowingStorage();
    expect(() => storageSet("k", "v")).not.toThrow();
  });

  it("storageRemove does not throw", () => {
    withThrowingStorage();
    expect(() => storageRemove("k")).not.toThrow();
  });

  it("storageClear does not throw", () => {
    withThrowingStorage();
    expect(() => storageClear()).not.toThrow();
  });

  it("delegates to localStorage when available", () => {
    const backing = new Map<string, string>();
    const store = {
      getItem: (k: string) => backing.get(k) ?? null,
      setItem: (k: string, v: string) => void backing.set(k, v),
      removeItem: (k: string) => void backing.delete(k),
      clear: () => void backing.clear(),
    } as unknown as Storage;
    Object.defineProperty(window, "localStorage", { get: () => store, configurable: true });
    storageSet("a", "1");
    expect(storageGet("a")).toBe("1");
    storageRemove("a");
    expect(storageGet("a")).toBeNull();
    storageSet("b", "2");
    storageClear();
    expect(storageGet("b")).toBeNull();
  });
});
