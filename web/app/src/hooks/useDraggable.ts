import { useState, useEffect, useCallback, useRef } from "react";

interface DragState {
  offsetX: number;
  offsetY: number;
}

/**
 * Hook for making a modal panel draggable by its header.
 * Returns a ref (attach to the dialog element), drag state (position),
 * and onMouseDown handler (attach to the header bar).
 */
export function useDraggable() {
  const [drag, setDrag] = useState<DragState>({ offsetX: 0, offsetY: 0 });
  const dragRef = useRef<{
    startX: number;
    startY: number;
    baseX: number;
    baseY: number;
  } | null>(null);
  const dialogRef = useRef<HTMLDivElement | null>(null);

  const onMouseDown = useCallback(
    (e: React.MouseEvent) => {
      // Only start drag from left-click
      if (e.button !== 0) return;
      // Don't drag if clicking a button/input inside the header
      const target = e.target as HTMLElement;
      if (target.tagName === "BUTTON" || target.tagName === "INPUT" || target.closest("button")) return;

      dragRef.current = {
        startX: e.clientX,
        startY: e.clientY,
        baseX: drag.offsetX,
        baseY: drag.offsetY,
      };
      e.preventDefault();
    },
    [drag],
  );

  useEffect(() => {
    const onMouseMove = (e: MouseEvent) => {
      if (!dragRef.current) return;
      const dx = e.clientX - dragRef.current.startX;
      const dy = e.clientY - dragRef.current.startY;
      setDrag({
        offsetX: dragRef.current.baseX + dx,
        offsetY: dragRef.current.baseY + dy,
      });
    };

    const onMouseUp = () => {
      dragRef.current = null;
    };

    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("mouseup", onMouseUp);
    return () => {
      window.removeEventListener("mousemove", onMouseMove);
      window.removeEventListener("mouseup", onMouseUp);
    };
  }, []);

  const reset = useCallback(() => setDrag({ offsetX: 0, offsetY: 0 }), []);

  return { drag, onMouseDown, dialogRef, reset };
}
