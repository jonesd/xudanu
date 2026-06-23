import { describe, it, expect } from "vitest";
import { time, createRenderCountSpy } from "./bench";

describe("Benchmark helpers", () => {
  it("time() measures average iteration cost", () => {
    const avg = time(() => [1, 2, 3].reduce((a, b) => a + b, 0), 10000);
    expect(avg).toBeGreaterThan(0);
    expect(avg).toBeLessThan(1);
  });

  it("createRenderCountSpy tracks renders", () => {
    const { renderCount, reset, SpyChild } = createRenderCountSpy("test");
    expect(renderCount()).toBe(0);

    SpyChild();
    SpyChild();
    expect(renderCount()).toBe(2);

    reset();
    expect(renderCount()).toBe(0);
  });
});
