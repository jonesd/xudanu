import { describe, it, expect } from "vitest";
import { renderHook, act } from "@testing-library/react";
import { useTransclusion } from "../hooks/useTransclusion";
import type { CrdtSyncClient } from "../api/crdt_sync";

const WORK = 1112;
const LINKS = [{"link_id": 67, "origin": 1112, "destination": 1112, "origin_ref": {"kind": "single", "work_context": 1112, "original_context": null, "excerpt": "Udanax Gold ", "start_position": 15, "end_position": 27}, "destination_ref": {"kind": "single", "work_context": 1112, "original_context": null, "excerpt": "http://udanax.xanadu.com/gold/index.html", "start_position": 0, "end_position": 0}, "origin_archived": false, "origin_title": "# Udanax Gold", "origin_owner": 1021, "destination_archived": false, "destination_title": "# Udanax Gold", "destination_owner": 1021, "link_types": [6]}, {"link_id": 67, "origin": 1112, "destination": 1112, "origin_ref": {"kind": "single", "work_context": 1112, "original_context": null, "excerpt": "Udanax Gold ", "start_position": 15, "end_position": 27}, "destination_ref": {"kind": "single", "work_context": 1112, "original_context": null, "excerpt": "http://udanax.xanadu.com/gold/index.html", "start_position": 0, "end_position": 0}, "origin_archived": false, "origin_title": "# Udanax Gold", "origin_owner": 1021, "destination_archived": false, "destination_title": "# Udanax Gold", "destination_owner": 1021, "link_types": [6]}, {"link_id": 49, "origin": 1101, "destination": 1112, "origin_ref": {"kind": "single", "work_context": 1101, "original_context": null, "excerpt": "Udanax Gold", "start_position": 349, "end_position": 360}, "destination_ref": {"kind": "single", "work_context": 1112, "original_context": null, "start_position": 0, "end_position": 0}, "origin_archived": false, "origin_title": "# The Xudanu Story", "origin_owner": 1021, "destination_archived": false, "destination_title": "# Udanax Gold", "destination_owner": 1021, "link_types": [2]}, {"link_id": 43, "origin": 1112, "destination": 1110, "origin_ref": {"kind": "single", "work_context": 1112, "original_context": null, "excerpt": "Ted Nelson \u2014 the origin of the vision", "start_position": 864, "end_position": 901}, "destination_ref": {"kind": "single", "work_context": 1110, "original_context": null, "start_position": 0, "end_position": 0}, "origin_archived": false, "origin_title": "# Udanax Gold", "origin_owner": 1021, "destination_archived": false, "destination_title": "# Ted Nelson", "destination_owner": 1021, "link_types": [5]}, {"link_id": 42, "origin": 1112, "destination": 1111, "origin_ref": {"kind": "single", "work_context": 1112, "original_context": null, "excerpt": "Project Xanadu \u2014 the design Udanax Gold implemented", "start_position": 811, "end_position": 862}, "destination_ref": {"kind": "single", "work_context": 1111, "original_context": null, "start_position": 0, "end_position": 0}, "origin_archived": false, "origin_title": "# Udanax Gold", "origin_owner": 1021, "destination_archived": false, "destination_title": "# Project Xanadu", "destination_owner": 1021, "link_types": [5]}, {"link_id": 41, "origin": 1111, "destination": 1112, "origin_ref": {"kind": "single", "work_context": 1111, "original_context": null, "excerpt": "Udanax Gold \u2014 the 1990s implementation whose open-sourcing m", "start_position": 958, "end_position": 1044}, "destination_ref": {"kind": "single", "work_context": 1112, "original_context": null, "start_position": 0, "end_position": 0}, "origin_archived": false, "origin_title": "# Project Xanadu", "origin_owner": 1021, "destination_archived": false, "destination_title": "# Udanax Gold", "destination_owner": 1021, "link_types": [5]}, {"link_id": 46, "origin": 1102, "destination": 1112, "origin_ref": {"kind": "single", "work_context": 1102, "original_context": null, "excerpt": "Udanax Gold", "start_position": 640, "end_position": 651}, "destination_ref": {"kind": "single", "work_context": 1112, "original_context": null, "start_position": 0, "end_position": 0}, "origin_archived": false, "origin_title": "# Welcome to Xudanu", "origin_owner": 1021, "destination_archived": false, "destination_title": "# Udanax Gold", "destination_owner": 1021, "link_types": [2]}];

// Replay of the exact live payload from xudanu.com work 1112 — the
// live site renders no link underlines despite this data arriving.
describe("live payload replay", () => {
  it("builds markers from the real 7-entry (6 unique) list", async () => {
    const client = {
      linkListForWork: async (wid: number) => (wid === WORK ? LINKS : []),
      findExcerptPositions: async () => [],
      workBacklinks: async () => [],
    } as unknown as CrdtSyncClient;
    const { result } = renderHook(() => useTransclusion());
    await act(async () => {
      await result.current.loadLinks(client, WORK, []);
    });
    console.log("links:", result.current.links.length, "markers:", result.current.markers.length,
      "marker spans:", JSON.stringify(result.current.markers.map(m => [m.start, m.end, m.linkTypeId])));
    expect(result.current.markers.length).toBeGreaterThan(0);
  });
});
