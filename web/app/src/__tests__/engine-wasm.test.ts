import { describe, it, expect } from "vitest";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { engineReady, BLAKE3_EMPTY_HEX } from "../engine-wasm-loader";

const WASM_PATH = resolve(process.cwd(), "src/engine-wasm/xudanu_bg.wasm");

/**
 * FR-148a browser tests: the wasm engine must be bit-identical with
 * native — these assert the SAME known vectors as the Rust suite
 * (wasm_engine_known_vectors). Skipped when the artifact hasn't been
 * built (CI without the wasm toolchain).
 */
describe.skipIf(!existsSync(WASM_PATH))("FR-148a wasm engine (browser)", () => {
  it("loads and initializes", async () => {
    const e = await engineReady();
    expect(typeof e.blake3_hex).toBe("function");
  });

  it("blake3 matches the canonical empty-input vector (native parity)", async () => {
    const e = await engineReady();
    expect(e.blake3_hex(new Uint8Array(0))).toBe(BLAKE3_EMPTY_HEX);
  });

  it("verifies content hashes and rejects tampering", async () => {
    const e = await engineReady();
    const data = new TextEncoder().encode("cross-server content verification");
    const hex = e.blake3_hex(data);
    expect(e.verify_blake3(data, hex)).toBe(true);
    expect(e.verify_blake3(new TextEncoder().encode("tampered"), hex)).toBe(false);
  });

  it("frames and parses chunks (round-trip + malformed rejection)", async () => {
    const e = await engineReady();
    const payload = new Uint8Array([1, 2, 3, 0xff]);
    const tagged = e.chunk_tag("postcard", payload);
    expect(tagged.length).toBe(payload.length + 1);
    expect(e.chunk_format_is_json(tagged)).toBe(false);
    const parsed = e.chunk_payload(tagged);
    expect(Array.from(parsed)).toEqual([1, 2, 3, 0xff]);
    expect(() => e.chunk_payload(new Uint8Array(0))).toThrow();
    expect(() => e.chunk_tag("yaml", payload)).toThrow();
  });

  it("exposes the DagWood surface (ent layer)", async () => {
    const e = await engineReady();
    const dw = new e.WasmDagWood();
    const root = dw.root();
    // u64 crosses the bindgen boundary as BigInt
    expect(typeof root.branch()).toBe("bigint");
    const pos = dw.new_position();
    expect(dw.is_le(root, pos)).toBe(true);
  });

  it("materializes an ent document end to end", async () => {
    const e = await engineReady();
    const dw = new e.WasmDagWood();
    const store = new e.WasmAssertionStore();
    const pos = dw.new_position();
    store.add(pos, JSON.stringify({ CreateNode: { node_id: 1, kind: "document" } }));
    store.add(pos, JSON.stringify({ CreateSpan: { span_id: 10 } }));
    store.add(pos, JSON.stringify({ SetSpanText: { span_id: 10, text: "Hello WASM" } }));
    store.add(pos, JSON.stringify({ AttachSpanToNode: { node_id: 1, span_id: 10, ordinal: 1 } }));
    const view = dw.trace_view(pos);
    const doc = JSON.parse(store.materialize_document_json(view, 1));
    const text = JSON.stringify(doc);
    expect(text).toContain("Hello WASM");
  });
});
