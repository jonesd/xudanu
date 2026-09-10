import { describe, it, expect } from "vitest";

// Phase B (tumbler navigation): contract tests for xan:// address
// handling in SearchOverlay — detection regex and resolve-response
// mapping, mirrored from the component.

const XAN_COMPLETE = /^xan:\/\/[^\s/]+\/\d+(\.\d+)*$/;

function isXanAddress(query: string): boolean {
  return query.trim().startsWith("xan://");
}

// Mirrors the resolveXan response mapper in SearchOverlay.
type XanResolutionState =
  | { kind: "resolving" }
  | { kind: "local"; workId: number; title: string; position: number | null }
  | { kind: "remote"; server: string; originWorkId: number | null; knownPeer: boolean }
  | { kind: "error"; message: string };

function mapResolveResponse(data: Record<string, unknown>): XanResolutionState {
  if (data.status === "local") {
    return {
      kind: "local",
      workId: parseInt(String(data.work_id), 16),
      title: typeof data.title === "string" && data.title ? data.title : "untitled",
      position: typeof data.position === "number" ? data.position : null,
    };
  }
  if (data.status === "remote") {
    return {
      kind: "remote",
      server: String(data.server),
      originWorkId: typeof data.origin_work_id === "number" ? data.origin_work_id : null,
      knownPeer: Boolean(data.known_peer),
    };
  }
  return { kind: "error", message: "unexpected response from resolver" };
}

describe("xan:// address detection", () => {
  it("detects scheme-prefixed queries as addresses", () => {
    expect(isXanAddress("xan://alice.com/5")).toBe(true);
    expect(isXanAddress("  xan://ns-0012/1004.7  ")).toBe(true);
    expect(isXanAddress("hello world")).toBe(false);
    expect(isXanAddress("")).toBe(false);
  });

  it("complete-pattern regex accepts well-formed addresses only", () => {
    expect(XAN_COMPLETE.test("xan://alice.com/5")).toBe(true);
    expect(XAN_COMPLETE.test("xan://alice.com/5.3.10")).toBe(true);
    expect(XAN_COMPLETE.test("xan://ns-00123456789abcdef/1004")).toBe(true);
    // incomplete or malformed
    expect(XAN_COMPLETE.test("xan://alice.com/")).toBe(false);
    expect(XAN_COMPLETE.test("xan://alice.com/abc")).toBe(false);
    expect(XAN_COMPLETE.test("xan://alice com/5")).toBe(false);
    expect(XAN_COMPLETE.test("xan://alice.com/5.")).toBe(false);
  });
});

describe("xan:// resolve response mapping", () => {
  it("maps a local resolution to a numeric work id and optional position", () => {
    const s = mapResolveResponse({ status: "local", work_id: "0ec8", position: 42, title: "origin" });
    expect(s).toEqual({ kind: "local", workId: 0xec8, title: "origin", position: 42 });
  });

  it("local without position maps to null", () => {
    const s = mapResolveResponse({ status: "local", work_id: "0005", position: null, title: "" });
    if (s.kind === "local") {
      expect(s.position).toBeNull();
      expect(s.title).toBe("untitled");
      expect(s.workId).toBe(5);
    } else {
      throw new Error("expected local");
    }
  });

  it("maps a remote resolution with directory knowledge", () => {
    const s = mapResolveResponse({ status: "remote", server: "bob.com", origin_work_id: 7, known_peer: true });
    expect(s).toEqual({ kind: "remote", server: "bob.com", originWorkId: 7, knownPeer: true });
  });

  it("missing origin_work_id maps to null (not NaN)", () => {
    const s = mapResolveResponse({ status: "remote", server: "x", origin_work_id: null, known_peer: false });
    if (s.kind === "remote") {
      expect(s.originWorkId).toBeNull();
    } else {
      throw new Error("expected remote");
    }
  });

  it("unknown status shapes degrade to an error state, never a throw", () => {
    const s = mapResolveResponse({ status: "weird" });
    expect(s.kind).toBe("error");
  });
});
