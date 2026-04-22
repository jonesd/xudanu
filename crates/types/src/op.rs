use serde::{Deserialize, Serialize};

use crate::{AuthorId, ItemContent, ItemId, SpanRef};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Op {
    Insert {
        id: ItemId,
        left_id: Option<ItemId>,
        right_id: Option<ItemId>,
        content: ItemContent,
        author: AuthorId,
    },
    Delete {
        id: ItemId,
        target_id: ItemId,
        start: usize,
        len: usize,
        author: AuthorId,
    },
    Transclude {
        id: ItemId,
        left_id: Option<ItemId>,
        right_id: Option<ItemId>,
        span_ref: SpanRef,
        author: AuthorId,
    },
}
