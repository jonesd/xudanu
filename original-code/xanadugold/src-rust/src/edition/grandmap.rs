use std::collections::HashMap;

use super::backend::{BeId, BeRangeElement, InMemoryBeStorage};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct IdSpaceId(pub u64);

impl IdSpaceId {
    pub fn new(id: u64) -> Self {
        IdSpaceId(id)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Id {
    pub space: IdSpaceId,
    pub number: i64,
}

impl Id {
    pub fn global(number: i64) -> Self {
        Id {
            space: IdSpaceId(0),
            number,
        }
    }

    pub fn in_space(space: IdSpaceId, number: i64) -> Self {
        Id { space, number }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IdSpace {
    id: IdSpaceId,
    next_number: i64,
}

impl IdSpace {
    pub fn new(id: IdSpaceId) -> Self {
        IdSpace { id, next_number: 0 }
    }

    pub fn global() -> Self {
        IdSpace {
            id: IdSpaceId(0),
            next_number: 0,
        }
    }

    pub fn new_id(&mut self) -> Id {
        let number = self.next_number;
        self.next_number += 1;
        Id {
            space: self.id.clone(),
            number,
        }
    }

    pub fn space_id(&self) -> &IdSpaceId {
        &self.id
    }
}

#[derive(Debug, Clone)]
pub struct GrandMap {
    global_space: IdSpace,
    local_space_counter: u64,
    storage: InMemoryBeStorage,
    id_to_element: HashMap<BeId, Box<dyn BeRangeElement>>,
    element_to_ids: HashMap<BeId, Vec<Id>>,
    id_holders: HashMap<Id, BeId>,
    id_counter: BeId,
}

impl Default for GrandMap {
    fn default() -> Self {
        Self::new()
    }
}

impl GrandMap {
    pub fn new() -> Self {
        GrandMap {
            global_space: IdSpace::global(),
            local_space_counter: 1,
            storage: InMemoryBeStorage::new(),
            id_to_element: HashMap::new(),
            element_to_ids: HashMap::new(),
            id_holders: HashMap::new(),
            id_counter: 1000,
        }
    }

    pub fn new_id(&mut self) -> Id {
        self.global_space.new_id()
    }

    pub fn new_id_space(&mut self) -> IdSpace {
        let space_id = IdSpaceId::new(self.local_space_counter);
        self.local_space_counter += 1;
        IdSpace::new(space_id)
    }

    pub fn next_be_id(&mut self) -> BeId {
        let id = self.id_counter;
        self.id_counter += 1;
        id
    }

    pub fn id_counter(&self) -> BeId {
        self.id_counter
    }

    pub fn set_id_counter(&mut self, counter: BeId) {
        self.id_counter = counter;
    }

    pub fn assign_id(&mut self, id: &Id, element: Box<dyn BeRangeElement>) -> bool {
        let be_id = element.be_id();
        self.id_holders.insert(id.clone(), be_id);
        self.element_to_ids.entry(be_id).or_default().push(id.clone());
        if self.id_to_element.contains_key(&be_id) {
            return false;
        }
        self.id_to_element.insert(be_id, element);
        true
    }

    pub fn assign_new_id(&mut self, element: Box<dyn BeRangeElement>) -> Id {
        let id = self.new_id();
        if !self.assign_id(&id, element) {
            panic!("newly generated ID already in use");
        }
        id
    }

    pub fn fetch_by_be_id(&self, be_id: BeId) -> Option<&Box<dyn BeRangeElement>> {
        self.id_to_element.get(&be_id)
    }

    pub fn get_by_be_id(&self, be_id: BeId) -> &Box<dyn BeRangeElement> {
        self.id_to_element
            .get(&be_id)
            .expect("no element at given be_id")
    }

    pub fn fetch_by_id(&self, id: &Id) -> Option<&Box<dyn BeRangeElement>> {
        let be_id = self.id_holders.get(id)?;
        self.id_to_element.get(be_id)
    }

    pub fn get_by_id(&self, id: &Id) -> &Box<dyn BeRangeElement> {
        let be_id = self
            .id_holders
            .get(id)
            .expect("no element at given id");
        self.id_to_element
            .get(be_id)
            .expect("be_id referenced by id not found")
    }

    pub fn id_of(&self, be_id: BeId) -> Option<&Id> {
        self.element_to_ids.get(&be_id).and_then(|ids| ids.first())
    }

    pub fn ids_of(&self, be_id: BeId) -> &[Id] {
        self.element_to_ids
            .get(&be_id)
            .map(|v| v.as_slice())
            .unwrap_or(&[])
    }

    pub fn register_id_holder(&mut self, id: &Id, be_id: BeId) {
        self.id_holders.insert(id.clone(), be_id);
    }

    pub fn storage(&self) -> &InMemoryBeStorage {
        &self.storage
    }

    pub fn storage_mut(&mut self) -> &mut InMemoryBeStorage {
        &mut self.storage
    }

    pub fn new_data_holder(&mut self, data: Vec<u8>) -> (BeId, Box<dyn BeRangeElement>) {
        let be_id = self.next_be_id();
        let holder = Box::new(super::backend::BeDataHolder {
            id: be_id,
            owner: None,
            data,
        });
        (be_id, holder)
    }

    pub fn new_edition_element(&mut self) -> (BeId, Box<dyn BeRangeElement>) {
        let be_id = self.next_be_id();
        let edition = Box::new(super::backend::BeEdition {
            id: be_id,
            owner: None,
        });
        (be_id, edition)
    }

    pub fn new_work_element(&mut self, owner: Option<BeId>) -> (BeId, Box<dyn BeRangeElement>) {
        let be_id = self.next_be_id();
        let work = Box::new(super::backend::BeWork {
            id: be_id,
            owner,
        });
        (be_id, work)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn grandmap_new_id_unique() {
        let mut gm = GrandMap::new();
        let id1 = gm.new_id();
        let id2 = gm.new_id();
        assert_ne!(id1, id2);
    }

    #[test]
    fn grandmap_new_id_space_unique() {
        let mut gm = GrandMap::new();
        let space1 = gm.new_id_space();
        let space2 = gm.new_id_space();
        assert_ne!(space1.space_id(), space2.space_id());
    }

    #[test]
    fn grandmap_assign_and_fetch() {
        let mut gm = GrandMap::new();
        let (be_id, holder) = gm.new_data_holder(vec![1, 2, 3]);
        let id = gm.assign_new_id(holder);
        let fetched = gm.fetch_by_be_id(be_id).unwrap();
        assert_eq!(fetched.be_id(), be_id);
        let fetched_by_id = gm.get_by_id(&id);
        assert_eq!(fetched_by_id.be_id(), be_id);
    }

    #[test]
    fn grandmap_assign_duplicate_fails() {
        let mut gm = GrandMap::new();
        let (_, holder) = gm.new_data_holder(vec![1, 2, 3]);
        let holder2 = holder.clone_boxed();
        let id1 = gm.new_id();
        let id2 = gm.new_id();
        assert!(gm.assign_id(&id1, holder));
        assert!(!gm.assign_id(&id2, holder2));
    }

    #[test]
    fn grandmap_id_of() {
        let mut gm = GrandMap::new();
        let (be_id, holder) = gm.new_data_holder(vec![42]);
        let id = gm.assign_new_id(holder);
        assert_eq!(gm.id_of(be_id), Some(&id));
    }

    #[test]
    fn grandmap_ids_of_empty() {
        let gm = GrandMap::new();
        assert!(gm.ids_of(999).is_empty());
    }

    #[test]
    fn grandmap_multiple_ids_for_element() {
        let mut gm = GrandMap::new();
        let (be_id, holder) = gm.new_data_holder(vec![1]);
        let id1 = gm.new_id();
        let id2 = gm.new_id();
        gm.assign_id(&id1, holder.clone_boxed());
        gm.assign_id(&id2, holder);
        assert_eq!(gm.ids_of(be_id).len(), 2);
    }

    #[test]
    fn grandmap_register_id_holder() {
        let mut gm = GrandMap::new();
        let (be_id, holder) = gm.new_data_holder(vec![99]);
        let id = gm.assign_new_id(holder);
        let lookup_id = Id::global(42);
        gm.register_id_holder(&lookup_id, be_id);
        let fetched = gm.fetch_by_id(&lookup_id);
        assert!(fetched.is_some());
        assert_eq!(fetched.unwrap().be_id(), be_id);
    }

    #[test]
    fn id_space_sequential() {
        let mut space = IdSpace::new(IdSpaceId::new(7));
        let id0 = space.new_id();
        let id1 = space.new_id();
        assert_eq!(id0.number, 0);
        assert_eq!(id1.number, 1);
        assert_eq!(id0.space, IdSpaceId(7));
        assert_eq!(id1.space, IdSpaceId(7));
    }

    #[test]
    fn id_global() {
        let id = Id::global(42);
        assert_eq!(id.space, IdSpaceId(0));
        assert_eq!(id.number, 42);
    }
}
