import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { createOverlayCanvas } from "../overlay-canvas";

// jsdom doesn't support canvas 2D context — mock it
const mockCtx = {
  fillStyle: "",
  fillRect: vi.fn(),
  clearRect: vi.fn(),
  drawImage: vi.fn(),
  setTransform: vi.fn(),
  getImageData: vi.fn(() => ({ data: [0, 255, 0, 255] })),
};

vi.spyOn(HTMLCanvasElement.prototype, "getContext").mockImplementation(
  (type: string) => {
    if (type === "2d") return mockCtx as unknown as CanvasRenderingContext2D;
    return null;
  },
);

describe("overlay-canvas", () => {
  let canvas: HTMLCanvasElement;
  let overlay: ReturnType<typeof createOverlayCanvas>;

  beforeEach(() => {
    vi.clearAllMocks();
    canvas = document.createElement("canvas");
    overlay = createOverlayCanvas(canvas);
  });

  afterEach(() => {
    overlay.dispose();
  });

  it("exposes the canvas element", () => {
    expect(overlay.canvas).toBe(canvas);
  });

  it("resize only sets width when it changes", () => {
    const dpr = window.devicePixelRatio || 1;
    canvas.width = Math.round(100 * dpr);
    const before = canvas.width;
    overlay.resize(100, 50);
    // Same logical size — native clear avoided (width untouched)
    expect(canvas.width).toBe(before);
  });

  it("resize sets dimensions when they differ", () => {
    overlay.resize(200, 100);
    const dpr = window.devicePixelRatio || 1;
    expect(canvas.width).toBe(Math.round(200 * dpr));
    expect(canvas.height).toBe(Math.round(100 * dpr));
  });

  it("draw calls the callback and blits (async)", async () => {
    overlay.resize(100, 50);
    const fn = vi.fn();
    overlay.draw(fn);
    await new Promise((r) => requestAnimationFrame(r));
    expect(fn).toHaveBeenCalledTimes(1);
    // The blit happened (clearRect + drawImage on the visible canvas)
    expect(mockCtx.clearRect).toHaveBeenCalled();
    expect(mockCtx.drawImage).toHaveBeenCalled();
  });

  it("coalesces rapid draws into one rAF", async () => {
    overlay.resize(100, 50);
    const fn = vi.fn();
    overlay.draw(fn);
    overlay.draw(fn);
    overlay.draw(fn);
    await new Promise((r) => requestAnimationFrame(r));
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it("dispose cancels pending draws", async () => {
    overlay.resize(100, 50);
    const fn = vi.fn();
    overlay.draw(fn);
    overlay.dispose();
    await new Promise((r) => setTimeout(r, 50));
    expect(fn).not.toHaveBeenCalled();
  });
});
