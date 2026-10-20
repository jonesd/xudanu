import { describe, it, expect } from "vitest";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { runEngineBenches } from "../engine-bench";

const WASM_PATH = resolve(process.cwd(), "src/engine-wasm/xudanu_bg.wasm");

/**
 * FR-148f: budgets are the contract ("no UI without a budget"). A
 * median above budgetMs fails CI — energy regressions surface as op
 * cost before they surface as battery drain. On-device joule runs
 * (Xcode Energy Log / Battery Historian) correlate against the same
 * numbers this suite prints.
 */
describe.skipIf(!existsSync(WASM_PATH))("FR-148f engine budgets", () => {
  it("all benches within budget", async () => {
    const { results, json } = await runEngineBenches();
    for (const r of results) {
      // eslint-disable-next-line no-console
      console.log(
        `  ${r.name}: ${r.ms.toFixed(1)}ms (budget ${r.budgetMs}ms), ` +
          `${Math.round(r.opsPerSec)} ops/s, ${r.mbPerSec.toFixed(1)} MB/s`,
      );
      expect(
        r.ms,
        `${r.name} exceeded budget: ${r.ms.toFixed(1)}ms > ${r.budgetMs}ms`,
      ).toBeLessThan(r.budgetMs);
    }
    expect(json).toContain("fr-148f");
  }, 60000);
});
