use wasm_bindgen::prelude::*;
use xudanu_core::Document;
use xudanu_signing::Signer;
use xudanu_sync::protocol::SyncProtocol;
use xudanu_sync::Awareness;
use xudanu_types::{Change, SiteId};

#[wasm_bindgen]
pub struct SyncClient {
    doc: Document,
    signer: Signer,
    site: SiteId,
    sync: SyncProtocol,
    awareness: Awareness,
}

#[wasm_bindgen]
impl SyncClient {
    #[wasm_bindgen(constructor)]
    pub fn new(display_name: String) -> Self {
        let signer = Signer::generate(display_name);
        let site = SiteId::from_author(signer.author());
        let doc = Document::new([0u8; 32], signer.author().clone(), site);
        let initial_sv = doc.state_vector().clone();
        let sync = SyncProtocol::new(initial_sv);
        let awareness = Awareness::new();
        Self {
            doc,
            signer,
            site,
            sync,
            awareness,
        }
    }

    pub fn insert(&mut self, index: usize, text: String) {
        self.doc.insert(index, text);
    }

    pub fn delete(&mut self, index: usize, len: usize) {
        self.doc.delete(index, len);
    }

    pub fn text(&self) -> String {
        self.doc.to_string()
    }

    pub fn length(&self) -> usize {
        self.doc.len()
    }

    pub fn commit_and_sync(&mut self) -> Option<String> {
        let change = self.doc.commit_change()?;
        self.sync
            .update_local_state_vector(self.doc.state_vector().clone());
        serde_json::to_string(&change).ok()
    }

    pub fn create_sync_step1(&self) -> Result<String, JsValue> {
        let msg = self.sync.create_sync_step1(self.site);
        serde_json::to_string(&msg)
            .map_err(|e| JsValue::from_str(&format!("Serialization error: {}", e)))
    }

    pub fn handle_sync_step1(&mut self, msg_json: String) -> Result<String, JsValue> {
        let msg: xudanu_sync::message::SyncMessage = serde_json::from_str(&msg_json)
            .map_err(|e| JsValue::from_str(&format!("Failed to parse sync message: {}", e)))?;
        let changes: Vec<Change> = self.doc.change_history().into_iter().cloned().collect();
        let response = self.sync.handle_sync_step1(&msg, &changes);
        serde_json::to_string(&response)
            .map_err(|e| JsValue::from_str(&format!("Serialization error: {}", e)))
    }

    pub fn handle_sync_step2(&mut self, msg_json: String) -> Result<(), JsValue> {
        let msg: xudanu_sync::message::SyncMessage = serde_json::from_str(&msg_json)
            .map_err(|e| JsValue::from_str(&format!("Failed to parse sync message: {}", e)))?;
        let accepted =
            self.sync
                .handle_sync_step2(&msg, self.site, *self.signer.author().id(), |_change| true);
        for change in &accepted {
            self.doc.integrate_change(change);
        }
        self.sync
            .update_local_state_vector(self.doc.state_vector().clone());
        Ok(())
    }

    pub fn apply_remote_change(&mut self, change_json: String) -> Result<(), JsValue> {
        let change: Change = serde_json::from_str(&change_json)
            .map_err(|e| JsValue::from_str(&format!("Failed to parse change: {}", e)))?;
        self.doc.integrate_change(&change);
        self.sync
            .update_local_state_vector(self.doc.state_vector().clone());
        Ok(())
    }

    pub fn set_awareness(
        &mut self,
        user_name: String,
        user_color: String,
        cursor_index: Option<usize>,
        selection_start: Option<usize>,
        selection_end: Option<usize>,
        is_typing: bool,
    ) {
        let state = xudanu_sync::awareness::AwarenessState {
            client_id: self.doc_state_vector_clock(),
            user_name,
            user_color,
            cursor: cursor_index.map(|i| xudanu_sync::awareness::CursorPosition { index: i }),
            selection: match (selection_start, selection_end) {
                (Some(s), Some(e)) => {
                    Some(xudanu_sync::awareness::SelectionRange { start: s, end: e })
                }
                _ => None,
            },
            is_typing,
            author: *self.signer.author().id(),
        };
        self.awareness.set_local_state(state);
    }

    pub fn get_awareness_json(&self) -> Result<String, JsValue> {
        let states: Vec<&xudanu_sync::awareness::AwarenessState> =
            self.awareness.all_states().collect();
        serde_json::to_string(&states)
            .map_err(|e| JsValue::from_str(&format!("Serialization error: {}", e)))
    }

    pub fn apply_remote_awareness(&mut self, state_json: String) -> Result<(), JsValue> {
        let state: xudanu_sync::awareness::AwarenessState = serde_json::from_str(&state_json)
            .map_err(|e| JsValue::from_str(&format!("Failed to parse awareness: {}", e)))?;
        self.awareness.apply_remote(state);
        Ok(())
    }

    pub fn remove_awareness_client(&mut self, client_id: f64) {
        self.awareness.remove_client(client_id as u64);
    }

    pub fn awareness_client_count(&self) -> usize {
        self.awareness.client_count()
    }

    pub fn author_name(&self) -> String {
        self.signer.author().display_name().to_string()
    }

    pub fn author_fingerprint(&self) -> String {
        self.signer.author().fingerprint()
    }

    pub fn site_id_hex(&self) -> String {
        self.site.short()
    }

    pub fn state_vector_json(&self) -> String {
        let sv = self.doc.state_vector();
        let pairs: Vec<(String, u64)> = sv
            .iter()
            .map(|(site, &clock)| (site.short(), clock))
            .collect();
        serde_json::to_string(&pairs).unwrap_or_default()
    }

    fn doc_state_vector_clock(&self) -> u64 {
        self.doc.state_vector().get(&self.site)
    }
}
