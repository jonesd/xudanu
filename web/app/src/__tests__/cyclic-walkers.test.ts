import { describe, it, expect } from "vitest";
import { buildChainPaths } from "../components/AttributionPanel";
import type { ProvenanceHop } from "../api/crdt_sync";

// The 0x5a3 crash class: provenance/link data CAN contain cycles
// (self-transclusion, mutual quotes). Every walker must terminate on
// cyclic input — these tests are the fingerprint that fails loudly
// the day an unguarded walker returns.
const hop = (source: number, dest: number): ProvenanceHop =>
  ({ source_work_id: source, dest_work_id: dest } as unknown as ProvenanceHop);

describe("buildChainPaths under cyclic provenance", () => {
  it("terminates on a SELF-loop (work quoting itself — the 0x5a3 data)", () => {
    const chain = [hop(0x5a3, 0x5a3), hop(0x100, 0x5a3)];
    const paths = buildChainPaths(chain);
    expect(Array.isArray(paths)).toBe(true);
    expect(paths.length).toBeGreaterThan(0);
  });

  it("terminates on a 2-cycle (mutual quotation)", () => {
    const chain = [hop(2, 1), hop(1, 2), hop(3, 1)];
    const paths = buildChainPaths(chain);
    expect(Array.isArray(paths)).toBe(true);
  });

  it("terminates on a 3-cycle", () => {
    const chain = [hop(2, 1), hop(3, 2), hop(1, 3)];
    const paths = buildChainPaths(chain);
    expect(Array.isArray(paths)).toBe(true);
  });

  it("still builds the ordinary linear chain correctly", () => {
    const chain = [hop(2, 1), hop(3, 2)];
    const paths = buildChainPaths(chain);
    expect(paths).toHaveLength(1);
    expect(paths[0].map((h) => h.source_work_id)).toEqual([3, 2]);
  });
});
