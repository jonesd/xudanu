use std::collections::HashMap;

use super::range_element::RangeElement;

pub type BeId = u64;

pub trait BeRangeElement: std::fmt::Debug + Send + Sync {
    fn be_id(&self) -> BeId;
    fn owner(&self) -> Option<BeId>;
    fn set_owner(&mut self, owner: Option<BeId>);
    fn as_range_element(&self) -> RangeElement;
    fn clone_boxed(&self) -> Box<dyn BeRangeElement>;
}

impl Clone for Box<dyn BeRangeElement> {
    fn clone(&self) -> Self {
        self.clone_boxed()
    }
}

#[derive(Debug, Clone)]
pub struct BeDataHolder {
    pub id: BeId,
    pub owner: Option<BeId>,
    pub data: Vec<u8>,
}

impl BeRangeElement for BeDataHolder {
    fn be_id(&self) -> BeId { self.id }
    fn owner(&self) -> Option<BeId> { self.owner }
    fn set_owner(&mut self, owner: Option<BeId>) { self.owner = owner; }
    fn as_range_element(&self) -> RangeElement { RangeElement::data(self.data.clone()) }
    fn clone_boxed(&self) -> Box<dyn BeRangeElement> { Box::new(self.clone()) }
}

#[derive(Debug, Clone)]
pub struct BeEdition {
    pub id: BeId,
    pub owner: Option<BeId>,
}

impl BeRangeElement for BeEdition {
    fn be_id(&self) -> BeId { self.id }
    fn owner(&self) -> Option<BeId> { self.owner }
    fn set_owner(&mut self, owner: Option<BeId>) { self.owner = owner; }
    fn as_range_element(&self) -> RangeElement { RangeElement::edition(self.id) }
    fn clone_boxed(&self) -> Box<dyn BeRangeElement> { Box::new(self.clone()) }
}

#[derive(Debug, Clone)]
pub struct BeWork {
    pub id: BeId,
    pub owner: Option<BeId>,
}

impl BeRangeElement for BeWork {
    fn be_id(&self) -> BeId { self.id }
    fn owner(&self) -> Option<BeId> { self.owner }
    fn set_owner(&mut self, owner: Option<BeId>) { self.owner = owner; }
    fn as_range_element(&self) -> RangeElement { RangeElement::work(self.id) }
    fn clone_boxed(&self) -> Box<dyn BeRangeElement> { Box::new(self.clone()) }
}

pub trait BeStorage: std::fmt::Debug + Send + Sync {
    fn get(&self, id: BeId) -> Option<Box<dyn BeRangeElement>>;
    fn put(&mut self, element: Box<dyn BeRangeElement>);
    fn remove(&mut self, id: BeId) -> Option<Box<dyn BeRangeElement>>;
    fn next_id(&mut self) -> BeId;
    fn contains(&self, id: BeId) -> bool;
}

#[derive(Debug, Clone)]
pub struct InMemoryBeStorage {
    elements: HashMap<BeId, Box<dyn BeRangeElement>>,
    next_id: BeId,
}

impl InMemoryBeStorage {
    pub fn new() -> Self {
        InMemoryBeStorage {
            elements: HashMap::new(),
            next_id: 1,
        }
    }
}

impl Default for InMemoryBeStorage {
    fn default() -> Self { Self::new() }
}

impl BeStorage for InMemoryBeStorage {
    fn get(&self, id: BeId) -> Option<Box<dyn BeRangeElement>> {
        self.elements.get(&id).map(|e| e.clone_boxed())
    }

    fn put(&mut self, element: Box<dyn BeRangeElement>) {
        let id = element.be_id();
        self.elements.insert(id, element);
    }

    fn remove(&mut self, id: BeId) -> Option<Box<dyn BeRangeElement>> {
        self.elements.remove(&id)
    }

    fn next_id(&mut self) -> BeId {
        let id = self.next_id;
        self.next_id += 1;
        id
    }

    fn contains(&self, id: BeId) -> bool {
        self.elements.contains_key(&id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::edition::range_element::RangeElementId;

    #[test]
    fn storage_put_get() {
        let mut storage = InMemoryBeStorage::new();
        let id = storage.next_id();
        storage.put(Box::new(BeDataHolder { id, owner: None, data: vec![1, 2, 3] }));
        let elem = storage.get(id).unwrap();
        assert_eq!(elem.be_id(), id);
        assert!(matches!(elem.as_range_element(), RangeElement::Data { .. }));
    }

    #[test]
    fn storage_remove() {
        let mut storage = InMemoryBeStorage::new();
        let id = storage.next_id();
        storage.put(Box::new(BeDataHolder { id, owner: None, data: vec![] }));
        assert!(storage.contains(id));
        storage.remove(id);
        assert!(!storage.contains(id));
    }

    #[test]
    fn storage_next_id_increments() {
        let mut storage = InMemoryBeStorage::new();
        assert_eq!(storage.next_id(), 1);
        assert_eq!(storage.next_id(), 2);
        assert_eq!(storage.next_id(), 3);
    }

    #[test]
    fn be_data_holder_owner() {
        let mut elem = BeDataHolder { id: 1, owner: None, data: vec![42] };
        assert!(elem.owner().is_none());
        elem.set_owner(Some(10));
        assert_eq!(elem.owner(), Some(10));
    }

    #[test]
    fn be_edition_as_range_element() {
        let elem = BeEdition { id: 5, owner: None };
        let re = elem.as_range_element();
        assert!(matches!(re, RangeElement::Edition { edition_id: RangeElementId(5) }));
    }
}
