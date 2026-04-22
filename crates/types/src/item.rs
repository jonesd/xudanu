use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

use crate::{AuthorId, ItemId, SpanRef};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum MarkType {
    Bold,
    Italic,
    Underline,
    Strikethrough,
    Link { href: String },
    Code,
    Custom(String),
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub struct Mark {
    pub mark_type: MarkType,
    pub attributes: BTreeMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum BlockType {
    Paragraph,
    Heading { level: u8 },
    CodeBlock { language: Option<String> },
    BlockQuote,
    List { ordered: bool },
    ListItem,
    Divider,
    Custom(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ItemContent {
    Text {
        text: String,
        marks: Vec<Mark>,
    },
    BlockStart(BlockType),
    BlockEnd,
    Transclusion(SpanRef),
    Embedded(serde_json::Value),
}

impl ItemContent {
    pub fn plain(text: impl Into<String>) -> Self {
        ItemContent::Text {
            text: text.into(),
            marks: Vec::new(),
        }
    }

    pub fn styled(text: impl Into<String>, marks: Vec<Mark>) -> Self {
        ItemContent::Text {
            text: text.into(),
            marks,
        }
    }

    pub fn len(&self) -> usize {
        match self {
            ItemContent::Text { text, .. } => text.len(),
            ItemContent::BlockStart(_) | ItemContent::BlockEnd => 1,
            ItemContent::Transclusion(_) => 1,
            ItemContent::Embedded(v) => v.to_string().len(),
        }
    }

    pub fn is_empty(&self) -> bool {
        match self {
            ItemContent::Text { text, .. } => text.is_empty(),
            _ => false,
        }
    }

    pub fn text(&self) -> Option<&str> {
        match self {
            ItemContent::Text { text, .. } => Some(text),
            _ => None,
        }
    }

    pub fn marks(&self) -> &[Mark] {
        match self {
            ItemContent::Text { marks, .. } => marks,
            _ => &[],
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Item {
    pub id: ItemId,
    pub left_id: Option<ItemId>,
    pub right_id: Option<ItemId>,
    pub content: ItemContent,
    pub is_deleted: bool,
    pub author: AuthorId,
    pub lamport: u64,
}

impl Item {
    pub fn new(
        id: ItemId,
        left_id: Option<ItemId>,
        right_id: Option<ItemId>,
        content: ItemContent,
        author: AuthorId,
        lamport: u64,
    ) -> Self {
        Self {
            id,
            left_id,
            right_id,
            content,
            is_deleted: false,
            author,
            lamport,
        }
    }

    pub fn is_tombstone(&self) -> bool {
        self.is_deleted
    }

    pub fn visible_len(&self) -> usize {
        if self.is_deleted {
            0
        } else {
            self.content.len()
        }
    }
}
