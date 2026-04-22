use serde::{Deserialize, Serialize};

use crate::ItemId;

pub type DocumentId = [u8; 32];
pub type ChangeHash = [u8; 32];

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub struct Span {
    pub start: ItemId,
    pub end: ItemId,
}

impl Span {
    pub fn new(start: ItemId, end: ItemId) -> Self {
        Self { start, end }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub struct SpanRef {
    pub document_id: DocumentId,
    pub span: Span,
    pub version: Option<ChangeHash>,
}

impl SpanRef {
    pub fn at_version(doc_id: DocumentId, span: Span, version: ChangeHash) -> Self {
        Self {
            document_id: doc_id,
            span,
            version: Some(version),
        }
    }

    pub fn at_latest(doc_id: DocumentId, span: Span) -> Self {
        Self {
            document_id: doc_id,
            span,
            version: None,
        }
    }
}
