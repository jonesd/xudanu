use std::collections::HashMap;
use xudanu_types::{AuthorId, ItemContent, ItemId};

#[derive(Debug, Clone)]
pub struct Attribution {
    pub author: AuthorId,
    pub byte_count: usize,
    pub proportion: f64,
    pub item_count: usize,
}

#[derive(Debug)]
pub struct AttributionEngine;

impl AttributionEngine {
    pub fn compute<'a>(
        items: impl Iterator<Item = (&'a ItemId, &'a ItemContent, &'a AuthorId)>,
    ) -> Vec<Attribution> {
        let mut author_bytes: HashMap<AuthorId, (usize, usize)> = HashMap::new();
        let mut total_bytes = 0usize;

        for (_, content, author) in items {
            let len = content.len();
            total_bytes += len;
            let entry = author_bytes.entry(*author).or_insert((0, 0));
            entry.0 += len;
            entry.1 += 1;
        }

        if total_bytes == 0 {
            return Vec::new();
        }

        let mut attributions: Vec<Attribution> = author_bytes
            .into_iter()
            .map(|(author, (bytes, count))| Attribution {
                author,
                byte_count: bytes,
                proportion: bytes as f64 / total_bytes as f64,
                item_count: count,
            })
            .collect();

        attributions.sort_by(|a, b| b.byte_count.cmp(&a.byte_count));
        attributions
    }
}
