use wasm_bindgen::prelude::*;

use crate::ent::content::{
    materialize_document, materialize_node, materialize_span,
    AssertionPayload, AssertionStore, DocumentId, NodeId, SpanId,
};
use crate::ent::dagwood::{DagWood, TraceView};
use crate::ent::ent::Ent;
use crate::ent::trace::TracePosition;

#[wasm_bindgen(start)]
pub fn init() {
    console_error_panic_hook::set_once();
}

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    fn warn(msg: &str);
}

macro_rules! console_warn {
    ($($t:tt)*) => {
        warn(&format!($($t)*))
    }
}

const VALID_PAYLOADS: &[&str] = &[
    "CreateNode", "AttachChild", "DetachChild", "DeleteNode",
    "CreateSpan", "SetSpanText", "DeleteSpan",
    "AttachSpanToNode", "DetachSpanFromNode",
    "CreateAnnotation", "AttachAnnotationToNode",
    "AttachAnnotationToSpan", "DeleteAnnotation",
];

fn suggest_payload_variants(input: &str) -> String {
    let input_lower = input.to_lowercase();
    let mut suggestions: Vec<&str> = VALID_PAYLOADS
        .iter()
        .filter(|v| {
            v.to_lowercase().contains(&input_lower)
            || input_lower.contains(&v.to_lowercase())
        })
        .copied()
        .collect();
    if suggestions.is_empty() {
        suggestions = VALID_PAYLOADS.to_vec();
    }
    format!("Did you mean one of: {}?", suggestions.join(", "))
}

#[wasm_bindgen]
pub struct WasmDagWood {
    inner: DagWood,
}

#[wasm_bindgen]
impl WasmDagWood {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        WasmDagWood {
            inner: DagWood::new(),
        }
    }

    pub fn root(&self) -> WasmTracePosition {
        WasmTracePosition {
            inner: self.inner.root(),
        }
    }

    pub fn new_position(&mut self) -> WasmTracePosition {
        WasmTracePosition {
            inner: self.inner.new_position(),
        }
    }

    pub fn new_position_after(&mut self, after: &WasmTracePosition) -> WasmTracePosition {
        WasmTracePosition {
            inner: self.inner.new_position_after(after.inner),
        }
    }

    pub fn new_successor_after(
        &mut self,
        a: &WasmTracePosition,
        b: &WasmTracePosition,
    ) -> WasmTracePosition {
        WasmTracePosition {
            inner: self.inner.new_successor_after(a.inner, b.inner),
        }
    }

    pub fn is_le(
        &mut self,
        a: &WasmTracePosition,
        b: &WasmTracePosition,
    ) -> bool {
        self.inner.is_le(a.inner, b.inner)
    }

    pub fn trace_view(&self, reference: &WasmTracePosition) -> WasmTraceView {
        WasmTraceView {
            inner: self.inner.trace_view(reference.inner),
        }
    }
}

#[wasm_bindgen]
pub struct WasmTracePosition {
    inner: TracePosition,
}

#[wasm_bindgen]
impl WasmTracePosition {
    pub fn branch(&self) -> u64 {
        self.inner.branch().raw_for_hash() as u64
    }

    pub fn position(&self) -> u32 {
        self.inner.position()
    }
}

#[wasm_bindgen]
pub struct WasmTraceView {
    inner: TraceView,
}

#[wasm_bindgen]
impl WasmTraceView {
    pub fn is_visible(&self, pos: &WasmTracePosition) -> bool {
        self.inner.is_visible(pos.inner)
    }

    pub fn branch_count(&self) -> usize {
        self.inner.branch_count()
    }

    pub fn visible_max_for(&self, pos: &WasmTracePosition) -> Option<u32> {
        self.inner.visible_max(pos.inner.branch())
    }

    pub fn reference(&self) -> WasmTracePosition {
        WasmTracePosition {
            inner: self.inner.reference(),
        }
    }
}

#[wasm_bindgen]
pub struct WasmEnt {
    inner: Ent,
}

#[wasm_bindgen]
impl WasmEnt {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        WasmEnt { inner: Ent::new() }
    }

    pub fn new_trace(&mut self) -> WasmTracePosition {
        WasmTracePosition {
            inner: self.inner.new_trace(),
        }
    }

    pub fn table_segment_max_size() -> u32 {
        Ent::table_segment_max_size()
    }
}

#[wasm_bindgen]
pub struct WasmAssertionStore {
    inner: AssertionStore,
}

#[wasm_bindgen]
impl WasmAssertionStore {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        WasmAssertionStore {
            inner: AssertionStore::new(),
        }
    }

    pub fn assertion_count(&self) -> usize {
        self.inner.all_assertions().len()
    }

    pub fn add(&mut self, position: &WasmTracePosition, payload: &str) -> Result<(), JsValue> {
        let p: AssertionPayload = serde_json::from_str(payload).map_err(|e| {
            let err_str = format!("{}", e);
            let suggestion = if err_str.contains("unknown variant") {
                if let Some(key) = err_str.split('`').nth(1) {
                    suggest_payload_variants(key)
                } else {
                    suggest_payload_variants("")
                }
            } else {
                String::new()
            };
            console_warn!(
                "xanadu-gold: Failed to parse assertion payload.\n  Input: {}\n  Error: {}",
                payload,
                err_str
            );
            if !suggestion.is_empty() {
                console_warn!("xanadu-gold: {}", suggestion);
                JsValue::from_str(&format!("invalid payload: {}.\n{}", err_str, suggestion))
            } else {
                JsValue::from_str(&format!("invalid payload: {}.\nExpected a JSON object with one of these keys: {}",
                    err_str, VALID_PAYLOADS.join(", ")))
            }
        })?;
        self.inner.add(position.inner, p);
        Ok(())
    }

    fn serialize_to_json<T: serde::Serialize>(&self, value: &T) -> Result<JsValue, JsValue> {
        let json = serde_json::to_string(value)
            .map_err(|e| JsValue::from_str(&format!("serialization error: {}", e)))?;
        js_sys::JSON::parse(&json).map_err(|e| e.into())
    }

    fn serialize_to_json_string<T: serde::Serialize>(&self, value: &T) -> Result<String, JsValue> {
        serde_json::to_string(value)
            .map_err(|e| JsValue::from_str(&format!("serialization error: {}", e)))
    }

    pub fn materialize_document(
        &self,
        view: &WasmTraceView,
        doc_id: u64,
    ) -> Result<JsValue, JsValue> {
        let doc = materialize_document(
            &self.inner,
            &view.inner,
            DocumentId::new(doc_id),
        );
        if doc.root.is_none() {
            console_warn!(
                "xanadu-gold: materialize_document({}) returned null root. No CreateNode assertion found for this document ID.",
                doc_id
            );
        }
        self.serialize_to_json(&doc)
    }

    pub fn materialize_document_json(
        &self,
        view: &WasmTraceView,
        doc_id: u64,
    ) -> Result<String, JsValue> {
        let doc = materialize_document(
            &self.inner,
            &view.inner,
            DocumentId::new(doc_id),
        );
        if doc.root.is_none() {
            console_warn!(
                "xanadu-gold: materialize_document_json({}) returned null root. No CreateNode assertion found for this document ID.",
                doc_id
            );
        }
        self.serialize_to_json_string(&doc)
    }

    pub fn materialize_node(
        &self,
        view: &WasmTraceView,
        node_id: u64,
    ) -> Result<JsValue, JsValue> {
        let node = materialize_node(
            &self.inner,
            &view.inner,
            NodeId::new(node_id),
        );
        self.serialize_to_json(&node)
    }

    pub fn materialize_span(
        &self,
        view: &WasmTraceView,
        span_id: u64,
    ) -> Result<JsValue, JsValue> {
        let span = materialize_span(
            &self.inner,
            &view.inner,
            SpanId::new(span_id),
        );
        self.serialize_to_json(&span)
    }
}
