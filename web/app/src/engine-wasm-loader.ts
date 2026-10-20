/**
 * FR-148a: engine-wasm loader — one init path for browser and Node
 * (vitest). The generated wasm-bindgen `init` accepts a
 * BufferSource, so Node reads the .wasm from disk while the browser
 * fetches it by URL.
 *
 * The artifact is a gitignored build product (`npm run
 * build:engine`); imports are DYNAMIC so vite/tsc never resolve the
 * module when it's absent (CI). Tests skip via existsSync.
 *
 * Engine is the STRUCTURAL surface (not the generated module type —
 * that reference breaks tsc when the artifact is absent).
 */
export interface WasmTracePositionLike {
  branch(): bigint;
  position(): number;
}
export interface WasmDagWoodLike {
  root(): WasmTracePositionLike;
  new_position(): WasmTracePositionLike;
  new_position_after(p: WasmTracePositionLike): WasmTracePositionLike;
  is_le(a: WasmTracePositionLike, b: WasmTracePositionLike): boolean;
  trace_view(ref: WasmTracePositionLike): unknown;
}
export interface WasmAssertionStoreLike {
  add(pos: WasmTracePositionLike, payload: string): void;
  assertion_count(): number;
  materialize_document_json(view: unknown, docId: number): string;
}
export interface Engine {
  blake3_hex(data: Uint8Array): string;
  verify_blake3(data: Uint8Array, expectedHex: string): boolean;
  chunk_tag(format: string, payload: Uint8Array): Uint8Array;
  chunk_payload(data: Uint8Array): Uint8Array;
  chunk_format_is_json(data: Uint8Array): boolean;
  WasmDagWood: new () => WasmDagWoodLike;
  WasmAssertionStore: new () => WasmAssertionStoreLike;
}

let ready: Promise<Engine> | null = null;

async function load(): Promise<Engine> {
  // Indirect specifier: tsc/vite must not resolve the module at
  // typecheck/transform time (artifact absent in CI); resolution
  // happens at execution, guarded by the tests' existsSync skip.
  const specifier = "./engine-wasm/xudanu.js";
  const imported = await import(/* @vite-ignore */ specifier);
  const engine = imported as unknown as Engine;
  // wasm-bindgen web target: `default` = init(input) accepting a
  // URL/BufferSource; the namespace `init()` is a DIFFERENT no-arg
  // auto-init (fetches a default URL) — never use it here.
  const initFn = (imported as unknown as { default?: unknown }).default as
    | ((input: RequestInfo | URL | BufferSource | WebAssembly.Module) => Promise<unknown>)
    | undefined;
  if (typeof initFn !== "function") {
    throw new Error("engine-wasm: no init(input) export");
  }
  const isNode =
    typeof process !== "undefined" && !!process.versions?.node;
  if (isNode) {
    const fs = await import("node:fs");
    const { resolve } = await import("node:path");
    const path = resolve(process.cwd(), "src/engine-wasm/xudanu_bg.wasm");
    await initFn(fs.readFileSync(path));
  } else {
    await initFn(new URL("./engine-wasm/xudanu_bg.wasm", import.meta.url));
  }
  return engine;
}

export function engineReady(): Promise<Engine> {
  if (!ready) ready = load();
  return ready;
}

export const BLAKE3_EMPTY_HEX =
  "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262";
