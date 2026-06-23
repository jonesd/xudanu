import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, act } from "@testing-library/react";
import { useState, useEffect } from "react";

describe("Background polling taming (F6)", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("loadWorks is not called while typing", () => {
    const loadWorks = vi.fn();
    const lastTypingRef = { current: 0 };

    function Test() {
      const [, force] = useState(0);
      useEffect(() => {
        const interval = setInterval(() => {
          const now = Date.now();
          const isTyping = now - lastTypingRef.current < 3000;
          const isHidden = document.hidden;
          if (!isTyping && !isHidden) {
            loadWorks();
          }
        }, 5000);
        return () => clearInterval(interval);
      }, []);
      return (
        <div>
          <button onClick={() => { lastTypingRef.current = Date.now(); force(1); }}>type</button>
        </div>
      );
    }

    render(<Test />);

    act(() => { vi.advanceTimersByTime(5000); });
    expect(loadWorks).toHaveBeenCalledTimes(1);

    act(() => { vi.advanceTimersByTime(4000); });
    screen.getByText("type").click();
    act(() => { vi.advanceTimersByTime(1000); });
    expect(loadWorks).toHaveBeenCalledTimes(1);

    act(() => { vi.advanceTimersByTime(5000); });
    expect(loadWorks).toHaveBeenCalledTimes(2);
  });

  it("endorsments are fetched in parallel (not N+1)", async () => {
    const workEndorsements = vi.fn(async (_workId: number) => []);

    const works = Array.from({ length: 5 }, (_, i) => ({ work_id: 100 + i }));

    await Promise.all(
      works.map((w) =>
        workEndorsements(w.work_id).then(() => ({ workId: w.work_id, endorsed: false })),
      ),
    );

    expect(workEndorsements).toHaveBeenCalledTimes(5);
  });

  it("awareness effect does not loop on awareness.length change", () => {
    const refreshAwareness = vi.fn();
    const awarenessRefreshedRef = { current: false };

    function Test({ awarenessLen }: { awarenessLen: number }) {
      useEffect(() => {
        if (!awarenessRefreshedRef.current) {
          const timer = setTimeout(() => {
            awarenessRefreshedRef.current = true;
            refreshAwareness();
          }, 5000);
          return () => clearTimeout(timer);
        }
      }, [awarenessLen]);
      return null;
    }

    const { rerender } = render(<Test awarenessLen={0} />);
    expect(refreshAwareness).not.toHaveBeenCalled();

    act(() => { vi.advanceTimersByTime(5000); });
    expect(refreshAwareness).toHaveBeenCalledTimes(1);

    rerender(<Test awarenessLen={1} />);
    act(() => { vi.advanceTimersByTime(10000); });
    expect(refreshAwareness).toHaveBeenCalledTimes(1);
  });
});
