import { describe, it, expect, vi } from "vitest";
import { render } from "@testing-library/react";
import { useState, useCallback, memo } from "react";

describe("Editor callback stability (F3)", () => {
  it("stable useCallback prevents memoized child re-render on parent re-render", () => {
    const childRenders = vi.fn();

    const TrackedChild = memo(({ onSel }: { onSel: (s: number | null, e: number | null) => void }) => {
      childRenders();
      return <div data-testid="child" onClick={() => onSel(1, 2)}>child</div>;
    });

    function Parent({ stable }: { stable: boolean }) {
      const [, forceUpdate] = useState(0);
      const [, setSel] = useState<{ start: number; end: number } | null>(null);

      const stableHandler = useCallback(
        (s: number | null, e: number | null) => {
          if (s !== null && e !== null) setSel({ start: s, end: e });
          else setSel(null);
        },
        [],
      );

      const inlineHandler = (s: number | null, e: number | null) => {
        if (s !== null && e !== null) setSel({ start: s, end: e });
        else setSel(null);
      };

      const handler = stable ? stableHandler : inlineHandler;

      return (
        <div>
          <button onClick={() => forceUpdate((n) => n + 1)}>force</button>
          <TrackedChild onSel={handler} />
        </div>
      );
    }

    const { rerender } = render(<Parent stable={true} />);
    expect(childRenders).toHaveBeenCalledTimes(1);

    rerender(<Parent stable={true} />);
    expect(childRenders).toHaveBeenCalledTimes(1);
  });

  it("inline handler causes memoized child re-render (negative test)", () => {
    const childRenders = vi.fn();

    const TrackedChild = memo(({ fn }: { fn: () => void }) => {
      childRenders();
      return <div onClick={fn}>child</div>;
    });

    function Parent() {
      const [, forceUpdate] = useState(0);
      return (
        <div>
          <button onClick={() => forceUpdate((n) => n + 1)}>force</button>
          <TrackedChild fn={() => {}} />
        </div>
      );
    }

    const { rerender } = render(<Parent />);
    expect(childRenders).toHaveBeenCalledTimes(1);

    rerender(<Parent />);
    expect(childRenders).toHaveBeenCalledTimes(2);
  });
});
