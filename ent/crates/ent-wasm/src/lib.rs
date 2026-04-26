use wasm_bindgen::prelude::*;

use ent_core::ent::ent::Ent;
use ent_core::ent::id_codec;

#[wasm_bindgen]
pub struct WasmEnt {
    inner: Ent,
}

#[wasm_bindgen]
impl WasmEnt {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        WasmEnt {
            inner: Ent::new(),
        }
    }

    pub fn root_trace_id(&self) -> String {
        let root = self.inner.root();
        id_codec::encode_trace(root)
    }

    pub fn new_trace(&mut self) -> String {
        let pos = self.inner.new_trace();
        id_codec::encode_trace(pos)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[wasm_bindgen_test::wasm_bindgen_test]
    fn root_trace_id_is_t_1_1() {
        let ent = WasmEnt::new();
        assert_eq!(ent.root_trace_id(), "t-1-1");
    }

    #[wasm_bindgen_test::wasm_bindgen_test]
    fn new_trace_returns_distinct_ids() {
        let mut ent = WasmEnt::new();
        let t1 = ent.new_trace();
        let t2 = ent.new_trace();
        let t3 = ent.new_trace();
        assert!(t1.starts_with("t-"));
        assert!(t2.starts_with("t-"));
        assert_ne!(t1, t2);
        assert_ne!(t2, t3);
    }

    #[wasm_bindgen_test::wasm_bindgen_test]
    fn new_trace_position_is_3() {
        let mut ent = WasmEnt::new();
        let trace = ent.new_trace();
        assert!(trace.ends_with("-3"), "expected position 3, got {}", trace);
    }
}
