/**
 * Double-buffered canvas overlay — the fix for marker/underline
 * flashing during typing, extracted from CollaborativeEditor so every
 * canvas-overlay component gets it for free.
 *
 * Three properties (found the hard way, Sept 2026):
 *
 * 1. Double buffering: all drawing goes to an offscreen canvas. The
 *    visible canvas only receives one atomic drawImage blit — never
 *    blank, no matter how slow the DOM reads between clear and paint.
 *
 * 2. Resize guard: canvas.width/height are only assigned when they
 *    actually change. Setting either attribute — even to the same
 *    value — natively clears the canvas bitmap.
 *
 * 3. rAF batching: draw calls are batched into a single
 *    requestAnimationFrame, so clear+compute+draw composite as one
 *    browser frame.
 *
 * Usage:
 *   const overlay = createOverlayCanvas(canvasEl);
 *   overlay.draw((ctx, width, height) => {
 *     // your drawing code — ctx is the offscreen buffer (pre-scaled
 *     // for devicePixelRatio); width/height are CSS pixels
 *     ctx.fillRect(10, 20, 100, 2);
 *   });
 *   overlay.dispose(); // when the component unmounts
 */

export interface OverlayCanvas {
  /** Draw to the offscreen buffer and blit. The callback receives a
   *  pre-scaled 2D context and CSS-pixel dimensions. */
  draw(fn: (ctx: CanvasRenderingContext2D, width: number, height: number) => void): void;
  /** Resize the visible canvas (guards against no-op native clears). */
  resize(width: number, height: number): void;
  /** The visible canvas element (for attaching to the DOM). */
  readonly canvas: HTMLCanvasElement;
  /** Release resources. */
  dispose(): void;
}

export function createOverlayCanvas(canvas: HTMLCanvasElement): OverlayCanvas {
  const buffer = document.createElement("canvas");
  let rafId = 0;

  const dpr = () => window.devicePixelRatio || 1;

  const resize = (width: number, height: number) => {
    const d = dpr();
    const newW = Math.round(width * d);
    const newH = Math.round(height * d);
    if (canvas.width !== newW) {
      canvas.width = newW;
      canvas.style.width = width + "px";
    }
    if (canvas.height !== newH) {
      canvas.height = newH;
      canvas.style.height = height + "px";
    }
  };

  const draw = (fn: (ctx: CanvasRenderingContext2D, width: number, height: number) => void) => {
    cancelAnimationFrame(rafId);
    rafId = requestAnimationFrame(() => {
      const d = dpr();
      const cssW = canvas.width / d;
      const cssH = canvas.height / d;

      // Sync buffer dimensions (buffer resize is free — user never sees it)
      buffer.width = canvas.width;
      buffer.height = canvas.height;

      const ctx = buffer.getContext("2d");
      if (!ctx) return;
      ctx.setTransform(d, 0, 0, d, 0, 0);

      // All user drawing goes to the buffer
      fn(ctx, cssW, cssH);

      // Atomic blit: buffer -> visible canvas (single operation)
      const visCtx = canvas.getContext("2d");
      if (visCtx) {
        visCtx.clearRect(0, 0, canvas.width, canvas.height);
        visCtx.drawImage(buffer, 0, 0);
      }
    });
  };

  return {
    draw,
    resize,
    canvas,
    dispose: () => cancelAnimationFrame(rafId),
  };
}
