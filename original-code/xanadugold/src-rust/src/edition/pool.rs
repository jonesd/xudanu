use std::collections::HashMap;
use std::sync::Arc;

use super::range_element::RangeElement;
use super::grandmap::Id;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ContentHash(pub [u8; 32]);

impl ContentHash {
    pub fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }

    pub fn to_hex(&self) -> String {
        self.0.iter().map(|b| format!("{:02x}", b)).collect()
    }
}

impl std::fmt::Display for ContentHash {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_hex())
    }
}

fn content_hash(element: &RangeElement) -> ContentHash {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    let mut hasher = DefaultHasher::new();
    element.hash(&mut hasher);
    let hash = hasher.finish();
    let mut bytes = [0u8; 32];
    bytes[0..8].copy_from_slice(&hash.to_le_bytes());
    let mut hasher2 = DefaultHasher::new();
    format!("{:?}", element).hash(&mut hasher2);
    let hash2 = hasher2.finish();
    bytes[8..16].copy_from_slice(&hash2.to_le_bytes());
    ContentHash(bytes)
}

#[derive(Debug, Clone)]
pub struct ContentPool {
    by_hash: HashMap<ContentHash, Arc<RangeElement>>,
    id_to_hash: HashMap<Id, ContentHash>,
    hash_to_ids: HashMap<ContentHash, Vec<Id>>,
}

impl Default for ContentPool {
    fn default() -> Self {
        Self::new()
    }
}

impl ContentPool {
    pub fn new() -> Self {
        ContentPool {
            by_hash: HashMap::new(),
            id_to_hash: HashMap::new(),
            hash_to_ids: HashMap::new(),
        }
    }

    pub fn store(&mut self, element: RangeElement, id: &Id) -> ContentHash {
        let hash = content_hash(&element);
        self.by_hash.insert(hash.clone(), Arc::new(element));
        self.id_to_hash.insert(id.clone(), hash.clone());
        self.hash_to_ids.entry(hash.clone()).or_default().push(id.clone());
        hash
    }

    pub fn retrieve(&self, hash: &ContentHash) -> Option<Arc<RangeElement>> {
        self.by_hash.get(hash).cloned()
    }

    pub fn find_by_content(&self, element: &RangeElement) -> Vec<Id> {
        let hash = content_hash(element);
        self.hash_to_ids
            .get(&hash)
            .cloned()
            .unwrap_or_default()
    }

    pub fn hash_of(&self, id: &Id) -> Option<&ContentHash> {
        self.id_to_hash.get(id)
    }

    pub fn ids_for_hash(&self, hash: &ContentHash) -> &[Id] {
        self.hash_to_ids
            .get(hash)
            .map(|v| v.as_slice())
            .unwrap_or(&[])
    }

    pub fn contains_hash(&self, hash: &ContentHash) -> bool {
        self.by_hash.contains_key(hash)
    }

    pub fn len(&self) -> usize {
        self.by_hash.len()
    }

    pub fn is_empty(&self) -> bool {
        self.by_hash.is_empty()
    }

    pub fn remove(&mut self, id: &Id) -> Option<ContentHash> {
        let hash = self.id_to_hash.remove(id)?;
        if let Some(ids) = self.hash_to_ids.get_mut(&hash) {
            ids.retain(|i| i != id);
            if ids.is_empty() {
                self.hash_to_ids.remove(&hash);
                self.by_hash.remove(&hash);
            }
        }
        Some(hash)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pool_store_and_retrieve() {
        let mut pool = ContentPool::new();
        let element = RangeElement::text("hello");
        let id = Id::global(1);
        let hash = pool.store(element.clone(), &id);
        let retrieved = pool.retrieve(&hash).unwrap();
        assert_eq!(*retrieved, element);
    }

    #[test]
    fn pool_find_by_content() {
        let mut pool = ContentPool::new();
        let element = RangeElement::text("hello");
        let id1 = Id::global(1);
        let id2 = Id::global(2);
        pool.store(element.clone(), &id1);
        pool.store(element.clone(), &id2);
        let found = pool.find_by_content(&element);
        assert_eq!(found.len(), 2);
        assert!(found.contains(&id1));
        assert!(found.contains(&id2));
    }

    #[test]
    fn pool_different_content_different_hash() {
        let mut pool = ContentPool::new();
        let e1 = RangeElement::text("hello");
        let e2 = RangeElement::text("world");
        let id1 = Id::global(1);
        let id2 = Id::global(2);
        let h1 = pool.store(e1, &id1);
        let h2 = pool.store(e2, &id2);
        assert_ne!(h1, h2);
    }

    #[test]
    fn pool_hash_of() {
        let mut pool = ContentPool::new();
        let element = RangeElement::data(vec![1, 2, 3]);
        let id = Id::global(42);
        let hash = pool.store(element, &id);
        assert_eq!(pool.hash_of(&id), Some(&hash));
    }

    #[test]
    fn pool_remove() {
        let mut pool = ContentPool::new();
        let element = RangeElement::text("bye");
        let id = Id::global(1);
        let hash = pool.store(element.clone(), &id);
        assert!(!pool.is_empty());
        let removed_hash = pool.remove(&id).unwrap();
        assert_eq!(removed_hash, hash);
        assert!(pool.is_empty());
        assert!(pool.retrieve(&hash).is_none());
    }

    #[test]
    fn pool_remove_one_of_two_same_content() {
        let mut pool = ContentPool::new();
        let element = RangeElement::text("shared");
        let id1 = Id::global(1);
        let id2 = Id::global(2);
        pool.store(element.clone(), &id1);
        pool.store(element.clone(), &id2);
        pool.remove(&id1);
        assert!(pool.retrieve(&content_hash(&element)).is_some());
        assert_eq!(pool.ids_for_hash(&content_hash(&element)), &[id2]);
    }

    #[test]
    fn pool_ids_for_hash() {
        let mut pool = ContentPool::new();
        let element = RangeElement::text("test");
        let id = Id::global(5);
        let hash = pool.store(element, &id);
        assert_eq!(pool.ids_for_hash(&hash), &[id]);
    }

    #[test]
    fn pool_len() {
        let mut pool = ContentPool::new();
        assert!(pool.is_empty());
        pool.store(RangeElement::text("a"), &Id::global(1));
        pool.store(RangeElement::text("b"), &Id::global(2));
        assert_eq!(pool.len(), 2);
    }

    #[test]
    fn content_hash_display() {
        let element = RangeElement::text("test");
        let hash = content_hash(&element);
        let hex = hash.to_hex();
        assert_eq!(hex.len(), 64);
    }
}
