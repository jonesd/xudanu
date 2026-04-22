use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use xudanu_types::{AuthorId, DocumentId, SpanRef};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoyaltyEntry {
    pub document_id: DocumentId,
    pub author: AuthorId,
    pub byte_count: usize,
    pub source: RoyaltySource,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum RoyaltySource {
    Original,
    Transcluded {
        from_document: DocumentId,
        span_ref: SpanRef,
    },
    Derived {
        from_documents: Vec<DocumentId>,
        transform_description: String,
    },
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RoyaltyLedger {
    entries: Vec<RoyaltyEntry>,
    author_totals: HashMap<AuthorId, AuthorTotal>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthorTotal {
    pub total_bytes: usize,
    pub original_bytes: usize,
    pub transcluded_bytes: usize,
    pub derived_bytes: usize,
    pub document_count: usize,
}

impl RoyaltyLedger {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add_entry(&mut self, entry: RoyaltyEntry) {
        let total = self.author_totals.entry(entry.author).or_insert(AuthorTotal {
            total_bytes: 0,
            original_bytes: 0,
            transcluded_bytes: 0,
            derived_bytes: 0,
            document_count: 0,
        });

        total.total_bytes += entry.byte_count;
        match &entry.source {
            RoyaltySource::Original => total.original_bytes += entry.byte_count,
            RoyaltySource::Transcluded { .. } => total.transcluded_bytes += entry.byte_count,
            RoyaltySource::Derived { .. } => total.derived_bytes += entry.byte_count,
        }
        total.document_count += 1;

        self.entries.push(entry);
    }

    pub fn author_total(&self, author: &AuthorId) -> Option<&AuthorTotal> {
        self.author_totals.get(author)
    }

    pub fn author_proportion(&self, author: &AuthorId) -> f64 {
        let grand_total: usize = self.author_totals.values().map(|t| t.total_bytes).sum();
        if grand_total == 0 {
            return 0.0;
        }
        self.author_totals.get(author).map(|t| t.total_bytes as f64 / grand_total as f64).unwrap_or(0.0)
    }

    pub fn entries_for_document(&self, doc_id: &DocumentId) -> Vec<&RoyaltyEntry> {
        self.entries.iter().filter(|e| &e.document_id == doc_id).collect()
    }

    pub fn summary(&self) -> Vec<(AuthorId, f64)> {
        let grand_total: usize = self.author_totals.values().map(|t| t.total_bytes).sum();
        if grand_total == 0 {
            return Vec::new();
        }
        let mut summary: Vec<_> = self
            .author_totals
            .iter()
            .map(|(author, total)| (*author, total.total_bytes as f64 / grand_total as f64))
            .collect();
        summary.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        summary
    }
}
