/**
 * FR-148a: engine-wasm loader — one init path for browser and Node
 * (vitest). The generated wasm-bindgen `init` accepts a
 * BufferSource, so Node reads the .wasm from disk while the browser
 * fetches it by URL.
 *
 * Rebuild the artifact: `npm run build:engine` (gitignored).
 */
import init, * as engine from "./engine-wasm/xudanu.js";

let ready: Promise<typeof engine> | null = null;

async function load(): Promise<typeof engine> {
  const isNode =
    typeof process !== "undefined" && !!process.versions?.node;
  if (isNode) {
    const fs = await import("node:fs");
    const { resolve } = await import("node:path");
    const path = resolve(process.cwd(), "src/engine-wasm/xudanu_bg.wasm");
    await init(fs.readFileSync(path));
  } else {
    await init(new URL("./engine-wasm/xudanu_bg.wasm", import.meta.url));
  }
  return engine;
}

export function engineReady(): Promise<typeof engine> {
  if (!ready) ready = load();
  return ready;
}

export const BLAKE3_EMPTY_HEX =
  "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262";
