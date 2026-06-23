import { vi } from "vitest";
import { act } from "@testing-library/react";

/**
 * Micro-benchmark helper: time a function over N iterations.
 * Returns the average time per iteration in milliseconds.
 */
export function time<T>(fn: () => T, iterations = 1000): number {
  const start = performance.now();
  for (let i = 0; i < iterations; i++) {
    fn();
  }
  const elapsed = performance.now() - start;
  return elapsed / iterations;
}

/**
 * React render-count spy: wraps a component in a counter that tracks
 * how many times it renders. Returns the counter and a reset function.
 *
 * Usage:
 *   const { renderCount, reset, SpyChild } = createRenderCountSpy();
 *   // render <SpyChild> as a child of the component under test
 *   // then assert renderCount() === expected
 */
export function createRenderCountSpy(_id = "spy") {
  let count = 0;
  const reset = () => { count = 0; };
  const renderCount = () => count;

  const SpyChild = vi.fn(() => {
    count++;
    return null;
  });

  return { renderCount, reset, SpyChild };
}

/**
 * Wait for all pending React state updates to flush.
 * Useful when testing effects/timers that schedule re-renders.
 */
export async function flushUpdates() {
  await act(async () => {
    await new Promise(resolve => setTimeout(resolve, 0));
  });
}
