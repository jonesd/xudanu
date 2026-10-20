import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { render, screen, cleanup } from "@testing-library/react";
import EngineVerifiedDoc from "../components/EngineVerifiedDoc";

const WASM_PATH = resolve(process.cwd(), "src/engine-wasm/xudanu_bg.wasm");

/**
 * FR-148b: the viewer's verification gate. Same suite shape as the
 * trust ladder: valid passes, tampered fails closed, unverifiable
 * fails closed.
 */
describe.skipIf(!existsSync(WASM_PATH))("FR-148b EngineVerifiedDoc", () => {
  beforeEach(() => {
    globalThis.fetch = vi.fn();
  });
  afterEach(() => cleanup());

  async function engineHash(text: string): Promise<string> {
    const { engineReady } = await import("../engine-wasm-loader");
    const e = await engineReady();
    return e.blake3_hex(new TextEncoder().encode(text));
  }

  it("renders text only after wasm verification passes", async () => {
    const text = "the verified passage lives here";
    const hash = await engineHash(text);
    (globalThis.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: async () => ({ title: "Test Work", text, content_hash: hash, tumbler: "xan://x/1" }),
    });
    render(<EngineVerifiedDoc url="https://peer.example/api/public/work/1" />);
    expect(await screen.findByTestId("engine-verified-doc")).toBeTruthy();
    expect(screen.getByText(/verified passage/)).toBeTruthy();
    expect(screen.getByText(/✓ content verified/)).toBeTruthy();
  });

  it("fails closed on a tampered document (hash mismatch)", async () => {
    const hash = await engineHash("original content");
    (globalThis.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: async () => ({ title: "Evil", text: "tampered content", content_hash: hash }),
    });
    render(<EngineVerifiedDoc url="https://peer.example/api/public/work/2" />);
    expect(await screen.findByRole("alert")).toBeTruthy();
    expect(screen.getByText(/hash mismatch/)).toBeTruthy();
    expect(screen.queryByTestId("engine-verified-doc")).toBeNull();
  });

  it("fails closed when the origin declares no hash", async () => {
    (globalThis.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: async () => ({ title: "Legacy", text: "some text" }),
    });
    render(<EngineVerifiedDoc url="https://peer.example/api/public/work/3" />);
    expect(await screen.findByRole("alert")).toBeTruthy();
    expect(screen.getByText(/unverifiable/)).toBeTruthy();
  });
});
