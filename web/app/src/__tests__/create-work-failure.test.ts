import { describe, it, expect } from "vitest";
import { renderHook, act } from "@testing-library/react";
import { useCrdtSync, parseWorkCreateResponse } from "../hooks/useCrdtSync";

// The +Create silent-failure bug (October 2026 session): during a
// reconnect backoff, createWork returned null / rejected with nothing
// catching, so the click did nothing visible and the editor kept the
// previously open work — the user believed they were writing a new
// document while staring at (and editing) the old one.
//
// Contract under test: every create failure is LOUD — createWork
// throws, callers toast; the response parser accepts every wire shape
// the server has ever produced.

describe("parseWorkCreateResponse", () => {
  it("unwraps the v2 tagged envelope {type:'id', value:N}", () => {
    expect(parseWorkCreateResponse({ type: "id", value: 1714 })).toBe(1714);
  });

  it("unwraps a single {value: N} wrap", () => {
    expect(parseWorkCreateResponse({ value: 42 })).toBe(42);
  });

  it("accepts a bare number", () => {
    expect(parseWorkCreateResponse(7)).toBe(7);
  });

  it("accepts {work_id: N}", () => {
    expect(parseWorkCreateResponse({ work_id: 9 })).toBe(9);
  });

  it("returns null for shapes without an id", () => {
    expect(parseWorkCreateResponse({ type: "ok" })).toBeNull();
    expect(parseWorkCreateResponse("nope")).toBeNull();
    expect(parseWorkCreateResponse(null)).toBeNull();
    expect(parseWorkCreateResponse({ work_id: "not-a-number" })).toBeNull();
  });
});

describe("createWork failure contract", () => {
  it("rejects loudly when disconnected instead of a silent null", async () => {
    // wsUrl=null → no client is ever constructed → the disconnected
    // guard fires. Before the fix this resolved to null and every
    // caller silently did nothing.
    const { result } = renderHook(() => useCrdtSync(null, null));
    let err: string | null = null;
    await act(async () => {
      try {
        await result.current.createWork();
      } catch (e) {
        err = e instanceof Error ? e.message : String(e);
      }
    });
    expect(err).toMatch(/Not connected/);
    expect(result.current.switchError).toBeNull();
  });
});
