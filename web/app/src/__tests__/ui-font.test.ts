import { describe, it, expect, beforeEach, vi } from "vitest";
import {
  clampUiFontSize,
  readUiFontSize,
  writeUiFontSize,
  nextUiFontSize,
  DEFAULT_UI_FONT_SIZE,
  UI_FONT_STEPS,
} from "../ui-font";
import { storageGet, storageSet } from "../safe-storage";

vi.mock("../safe-storage", () => {
  const store = new Map<string, string>();
  return {
    storageGet: vi.fn((k: string) => store.get(k)),
    storageSet: vi.fn((k: string, v: string) => void store.set(k, v)),
  };
});

describe("ui font preference", () => {
  beforeEach(() => vi.clearAllMocks());

  it("defaults to 14 when nothing stored", () => {
    expect(readUiFontSize()).toBe(DEFAULT_UI_FONT_SIZE);
  });

  it("round-trips a stored size", () => {
    writeUiFontSize(16);
    expect(readUiFontSize()).toBe(16);
    expect(storageSet).toHaveBeenCalledWith("xudanu-ui-font-size", "16");
  });

  it("clamps out-of-range and garbage values", () => {
    expect(clampUiFontSize(4)).toBe(12);
    expect(clampUiFontSize(99)).toBe(20);
    expect(clampUiFontSize(Number.NaN)).toBe(DEFAULT_UI_FONT_SIZE);
  });

  it("tolerates corrupt storage by falling back to the default", () => {
    (storageGet as ReturnType<typeof vi.fn>).mockReturnValueOnce("not-a-number");
    expect(readUiFontSize()).toBe(DEFAULT_UI_FONT_SIZE);
  });

  it("cycles through steps without leaving the range", () => {
    let size = 12;
    const seen = new Set<number>();
    for (let i = 0; i <= UI_FONT_STEPS.length; i++) {
      size = nextUiFontSize(size);
      seen.add(size);
      expect(size).toBeGreaterThanOrEqual(12);
      expect(size).toBeLessThanOrEqual(20);
    }
    expect(seen.has(12)).toBe(true); // wraps
  });
});
