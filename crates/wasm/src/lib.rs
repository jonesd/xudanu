use wasm_bindgen::prelude::*;
use xudanu_core::Document;
use xudanu_signing::Signer;
use xudanu_types::SiteId;

#[wasm_bindgen(start)]
pub fn init() {
    console_error_panic_hook::set_once();
}

#[wasm_bindgen]
pub struct SignedDocument {
    doc: Document,
    signer: Signer,
}

#[wasm_bindgen]
impl SignedDocument {
    #[wasm_bindgen(constructor)]
    pub fn new(display_name: String) -> Self {
        let signer = Signer::generate(display_name);
        let site = SiteId::from_author(signer.author());
        let doc = Document::new([0u8; 32], signer.author().clone(), site);
        Self { doc, signer }
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

    pub fn commit(&mut self) -> Option<String> {
        self.doc.commit_change().map(|c| {
            let signed = self.signer.sign_change(c);
            let json = serde_json::to_string(&signed.change).unwrap_or_default();
            json
        })
    }

    pub fn apply_remote(&mut self, change_json: String) -> Result<(), JsValue> {
        let change: xudanu_types::Change = serde_json::from_str(&change_json)
            .map_err(|e| JsValue::from_str(&format!("Failed to parse change: {}", e)))?;
        self.doc.integrate_change(&change);
        Ok(())
    }

    pub fn state_vector(&self) -> Vec<u8> {
        let sv = self.doc.state_vector();
        bincode::serialize(sv).unwrap_or_default()
    }

    pub fn author_name(&self) -> String {
        self.signer.author().display_name().to_string()
    }

    pub fn author_fingerprint(&self) -> String {
        self.signer.author().fingerprint()
    }

    pub fn create_branch(&mut self, name: String) {
        self.doc.create_branch(name);
    }

    pub fn list_branches(&self) -> Vec<JsValue> {
        self.doc.list_branches()
            .into_iter()
            .map(|s| JsValue::from_str(s))
            .collect()
    }

    pub fn switch_to_branch(&mut self, name: String) -> Result<(), JsValue> {
        self.doc.get_branch_mut(&name)
            .map(|_| ())
            .ok_or_else(|| JsValue::from_str("Branch not found"))
    }
}

#[wasm_bindgen]
pub fn generate_keypair(display_name: String) -> Result<Vec<u8>, JsValue> {
    let signer = Signer::generate(display_name);
    let stored = xudanu_signing::signer::StoredKey::from_signer(&signer);
    Ok(stored.serialize())
}

#[wasm_bindgen]
pub fn load_keypair(data: Vec<u8>) -> Result<String, JsValue> {
    let stored = xudanu_signing::signer::StoredKey::deserialize(&data)
        .map_err(|e| JsValue::from_str(&format!("Failed to load key: {}", e)))?;
    let signer = stored.load()
        .map_err(|e| JsValue::from_str(&format!("Invalid key: {}", e)))?;
    Ok(signer.author().fingerprint())
}
