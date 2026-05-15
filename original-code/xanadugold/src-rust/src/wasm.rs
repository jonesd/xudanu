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
                "xudanu: Failed to parse assertion payload.\n  Input: {}\n  Error: {}",
                payload,
                err_str
            );
            if !suggestion.is_empty() {
                console_warn!("xudanu: {}", suggestion);
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
        doc_id: f64,
    ) -> Result<JsValue, JsValue> {
        let doc = materialize_document(
            &self.inner,
            &view.inner,
            DocumentId::new(doc_id as u64),
        );
        if doc.root.is_none() {
            console_warn!(
                "xudanu: materialize_document({}) returned null root.",
                doc_id
            );
        }
        self.serialize_to_json(&doc)
    }

    pub fn materialize_document_json(
        &self,
        view: &WasmTraceView,
        doc_id: f64,
    ) -> Result<String, JsValue> {
        let doc = materialize_document(
            &self.inner,
            &view.inner,
            DocumentId::new(doc_id as u64),
        );
        if doc.root.is_none() {
            console_warn!(
                "xudanu: materialize_document_json({}) returned null root. No CreateNode assertion found for this document ID.",
                doc_id
            );
        }
        self.serialize_to_json_string(&doc)
    }

    pub fn materialize_node(
        &self,
        view: &WasmTraceView,
        node_id: f64,
    ) -> Result<JsValue, JsValue> {
        let node = materialize_node(
            &self.inner,
            &view.inner,
            NodeId::new(node_id as u64),
        );
        self.serialize_to_json(&node)
    }

    pub fn materialize_span(
        &self,
        view: &WasmTraceView,
        span_id: f64,
    ) -> Result<JsValue, JsValue> {
        let span = materialize_span(
            &self.inner,
            &view.inner,
            SpanId::new(span_id as u64),
        );
        self.serialize_to_json(&span)
    }
}

#[cfg(all(test, feature = "serde_json"))]
mod wasm_tests {
    use super::*;

    fn make_store_with_doc(_n_children: usize) -> (WasmDagWood, WasmTracePosition, WasmAssertionStore) {
        let mut dw = WasmDagWood::new();
        let store = WasmAssertionStore::new();
        let root = dw.root();
        let pos = dw.new_position();
        (dw, pos, store)
    }

    #[test]
    fn wasm_add_valid_payload() {
        let (dw, pos, mut store) = make_store_with_doc(0);
        store.add(&pos, r#"{"CreateNode":{"node_id":1,"kind":"document"}}"#).unwrap();
        assert_eq!(store.assertion_count(), 1);
    }

    #[test]
    fn wasm_add_rejects_unknown_variant() {
        let (dw, pos, mut store) = make_store_with_doc(0);
        let result = store.add(&pos, r#"{"NotARealThing":{"node_id":1}}"#);
        assert!(result.is_err());
        let msg = format!("{:?}", result.unwrap_err());
        assert!(msg.contains("unknown variant"), "should mention unknown variant: {}", msg);
    }

    #[test]
    fn wasm_add_rejects_missing_field() {
        let (dw, pos, mut store) = make_store_with_doc(0);
        let result = store.add(&pos, r#"{"CreateNode":{"node_id":1}}"#);
        assert!(result.is_err());
        let msg = format!("{:?}", result.unwrap_err());
        assert!(msg.contains("missing field"), "should mention missing field: {}", msg);
    }

    #[test]
    fn wasm_add_rejects_wrong_type() {
        let (dw, pos, mut store) = make_store_with_doc(0);
        let result = store.add(&pos, r#"{"CreateNode":{"node_id":"not_a_number","kind":"doc"}}"#);
        assert!(result.is_err());
    }

    #[test]
    fn wasm_add_rejects_invalid_json() {
        let (dw, pos, mut store) = make_store_with_doc(0);
        let result = store.add(&pos, r#"not json at all"#);
        assert!(result.is_err());
    }

    #[test]
    fn wasm_materialize_empty_store() {
        let dw = WasmDagWood::new();
        let store = WasmAssertionStore::new();
        let root = dw.root();
        let view = dw.trace_view(&root);
        let result = store.materialize_document(&view, 1.0).unwrap();
        let doc = js_sys::JSON::stringify(&result).unwrap().as_string().unwrap();
        assert!(doc.contains("\"doc_id\":1"));
        assert!(doc.contains("\"root\":null"));
    }

    #[test]
    fn wasm_assertion_count_tracks_adds() {
        let (dw, pos, mut store) = make_store_with_doc(0);
        assert_eq!(store.assertion_count(), 0);
        store.add(&pos, r#"{"CreateNode":{"node_id":1,"kind":"document"}}"#).unwrap();
        assert_eq!(store.assertion_count(), 1);
        store.add(&pos, r#"{"CreateSpan":{"span_id":10}}"#).unwrap();
        assert_eq!(store.assertion_count(), 2);
    }

    #[test]
    fn wasm_full_pipeline() {
        let mut dw = WasmDagWood::new();
        let mut store = WasmAssertionStore::new();
        let root = dw.root();
        let pos = dw.new_position();

        store.add(&pos, r#"{"CreateNode":{"node_id":1,"kind":"document"}}"#).unwrap();
        store.add(&pos, r#"{"CreateSpan":{"span_id":10}}"#).unwrap();
        store.add(&pos, r#"{"SetSpanText":{"span_id":10,"text":"Hello WASM"}}"#).unwrap();
        store.add(&pos, r#"{"AttachSpanToNode":{"node_id":1,"span_id":10,"ordinal":1}}"#).unwrap();

        let view = dw.trace_view(&pos);
        let result = store.materialize_document(&view, 1.0).unwrap();
        let doc_str = js_sys::JSON::stringify(&result).unwrap().as_string().unwrap();
        assert!(doc_str.contains("Hello WASM"));
        assert!(doc_str.contains("document"));
    }

    #[test]
    fn wasm_materialize_document_json_string() {
        let mut dw = WasmDagWood::new();
        let mut store = WasmAssertionStore::new();
        let pos = dw.new_position();
        store.add(&pos, r#"{"CreateNode":{"node_id":1,"kind":"doc"}}"#).unwrap();

        let view = dw.trace_view(&pos);
        let json = store.materialize_document_json(&view, 1.0).unwrap();
        assert!(json.contains("\"doc_id\":\"1\""));
        assert!(json.contains("\"kind\":\"doc\""));
    }

    #[test]
    fn wasm_large_document_pipeline() {
        let mut dw = WasmDagWood::new();
        let mut store = WasmAssertionStore::new();
        let pos = dw.new_position();

        store.add(&pos, r#"{"CreateNode":{"node_id":1,"kind":"document"}}"#).unwrap();

        for i in 0..200 {
            let payload = format!(
                r#"{{"CreateNode":{{"node_id":{},"kind":"paragraph"}}}}"#,
                100 + i
            );
            store.add(&pos, &payload).unwrap();
            let attach = format!(
                r#"{{"AttachChild":{{"parent_id":1,"child_id":{},"ordinal":{}}}}}"#,
                100 + i, i
            );
            store.add(&pos, &attach).unwrap();
        }

        assert_eq!(store.assertion_count(), 401);

        let view = dw.trace_view(&pos);
        let result = store.materialize_document(&view, 1.0).unwrap();
        let doc_str = js_sys::JSON::stringify(&result).unwrap().as_string().unwrap();
        assert!(doc_str.contains("paragraph"));

        let parsed: serde_json::Value = serde_json::from_str(&doc_str).unwrap();
        let children = parsed["root"]["children"].as_array().unwrap();
        assert_eq!(children.len(), 200);
    }
}
