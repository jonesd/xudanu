use serde::{Deserialize, Serialize};
use xanadu_types::AuthorId;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AwarenessState {
    pub client_id: u64,
    pub user_name: String,
    pub user_color: String,
    pub cursor: Option<CursorPosition>,
    pub selection: Option<SelectionRange>,
    pub is_typing: bool,
    pub author: AuthorId,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CursorPosition {
    pub index: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SelectionRange {
    pub start: usize,
    pub end: usize,
}

#[derive(Debug, Default)]
pub struct Awareness {
    states: std::collections::HashMap<u64, AwarenessState>,
}

impl Awareness {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn set_local_state(&mut self, state: AwarenessState) {
        self.states.insert(state.client_id, state);
    }

    pub fn get_state(&self, client_id: u64) -> Option<&AwarenessState> {
        self.states.get(&client_id)
    }

    pub fn remove_client(&mut self, client_id: u64) {
        self.states.remove(&client_id);
    }

    pub fn all_states(&self) -> impl Iterator<Item = &AwarenessState> {
        self.states.values()
    }

    pub fn apply_remote(&mut self, state: AwarenessState) {
        self.states.insert(state.client_id, state);
    }

    pub fn client_count(&self) -> usize {
        self.states.len()
    }
}
