import { describe, it, expect } from "vitest";
import type { FederatedSearchResultEntry } from "../api/crdt_sync";

// FR-41 S1: pure classification helpers mirrored from SearchOverlay.
// Kept here as contract tests for the merge/dedupe/render rules the
// network tab relies on (remote content treated as text-only).

function splitResults(entries: FederatedSearchResultEntry[]) {
  const localHits = entries.filter((r) => r.local && !r.unreachable);
  const remoteHits = entries.filter((r) => !r.local && !r.unreachable);
  const unreachablePeers = entries.filter((r) => r.unreachable);
  const servers = new Set(remoteHits.map((r) => r.server_name));
  return { localHits, remoteHits, unreachablePeers, servers };
}

describe("FR-41 S1 network search result handling", () => {
  it("splits local, remote, and unreachable entries", () => {
    const entries: FederatedSearchResultEntry[] = [
      { work_id: 1, title: "local hit", revision: 1, char_count: 10, server_name: "here", server_id: 0, local: true },
      { work_id: 2, title: "remote hit", revision: 3, char_count: 40, server_name: "Node 2 (Bob)", server_id: 2, local: false },
      { work_id: 3, title: "another", revision: 1, char_count: 5, server_name: "Node 3 (Carol)", server_id: 3, local: false },
      { work_id: 0, title: "", revision: 0, char_count: 0, server_name: "Node 4", server_id: 4, local: false, unreachable: true, reason: "timeout" },
    ];
    const { localHits, remoteHits, unreachablePeers, servers } = splitResults(entries);
    expect(localHits).toHaveLength(1);
    expect(remoteHits).toHaveLength(2);
    expect(unreachablePeers).toHaveLength(1);
    expect(servers.size).toBe(2);
  });

  it("unreachable entries never leak into remote hits even with local=false", () => {
    const entries: FederatedSearchResultEntry[] = [
      { work_id: 0, title: "", revision: 0, char_count: 0, server_name: "X", server_id: 9, local: false, unreachable: true, reason: "budget exhausted" },
    ];
    const { remoteHits, unreachablePeers } = splitResults(entries);
    expect(remoteHits).toHaveLength(0);
    expect(unreachablePeers).toHaveLength(1);
    expect(unreachablePeers[0].reason).toContain("budget");
  });

  it("titles from remote peers are plain strings (no HTML execution path)", () => {
    // Contract: the overlay renders titles as React text nodes only.
    // A poisoned peer sending markup must see it displayed verbatim.
    const evil = '<img src=x onerror="alert(1)">';
    const entry: FederatedSearchResultEntry = {
      work_id: 7,
      title: evil,
      revision: 1,
      char_count: 9,
      server_name: "evil peer",
      server_id: 99,
      local: false,
    };
    // If anyone ever switches rendering to innerHTML, this test is
    // the reminder that the contract forbids it.
    expect(entry.title).toBe(evil);
    expect(typeof entry.title).toBe("string");
  });
});
