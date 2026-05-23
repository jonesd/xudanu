use std::collections::HashMap;

use super::engine::{StorageEngine, StorageError, StorageResult};
use super::persistent::{FlockId, FlockInfo};
use super::traits::{Persistent, PersistentRegistry};

#[derive(Debug)]
pub struct InMemoryStorage {
    registry: PersistentRegistry,
    flock_infos: HashMap<FlockId, FlockInfo>,
    hash_counter: u64,
    token_counter: u32,
    in_transaction: bool,
    dirty_set: Vec<FlockId>,
    new_in_transaction: Vec<FlockId>,
    destroy_queue: Vec<FlockId>,
}

impl InMemoryStorage {
    pub fn new() -> Self {
        InMemoryStorage {
            registry: PersistentRegistry::new(),
            flock_infos: HashMap::new(),
            hash_counter: 1,
            token_counter: 0,
            in_transaction: false,
            dirty_set: Vec::new(),
            new_in_transaction: Vec::new(),
            destroy_queue: Vec::new(),
        }
    }
}

impl Default for InMemoryStorage {
    fn default() -> Self {
        Self::new()
    }
}

impl StorageEngine for InMemoryStorage {
    fn store_new(&mut self, mut obj: Box<dyn Persistent>) -> StorageResult<FlockInfo> {
        let flock_id = obj.flock_id();
        if self.registry.contains(&flock_id) {
            return Err(StorageError::AlreadyExists(flock_id));
        }
        let info = FlockInfo::new(flock_id);
        obj.set_flock_info(Some(info.clone()));
        self.registry.register(obj);
        self.flock_infos.insert(flock_id, info.clone());
        if self.in_transaction {
            self.dirty_set.push(flock_id);
            self.new_in_transaction.push(flock_id);
        }
        Ok(info)
    }

    fn disk_update(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        if let Some(info) = self.flock_infos.get_mut(flock_id) {
            info.mark_dirty();
            if self.in_transaction {
                self.dirty_set.push(*flock_id);
            }
            Ok(())
        } else {
            Err(StorageError::NotFound(*flock_id))
        }
    }

    fn remember(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        if let Some(info) = self.flock_infos.get_mut(flock_id) {
            info.mark_remembered();
            Ok(())
        } else {
            Err(StorageError::NotFound(*flock_id))
        }
    }

    fn forget(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        if let Some(info) = self.flock_infos.get_mut(flock_id) {
            info.mark_forgotten();
            Ok(())
        } else {
            Err(StorageError::NotFound(*flock_id))
        }
    }

    fn destroy(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        if let Some(info) = self.flock_infos.get_mut(flock_id) {
            info.mark_destroyed();
            self.destroy_queue.push(*flock_id);
            Ok(())
        } else {
            Err(StorageError::NotFound(*flock_id))
        }
    }

    fn dismantle(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        self.registry.unregister(flock_id);
        self.flock_infos.remove(flock_id);
        Ok(())
    }

    fn fetch(&self, flock_id: &FlockId) -> StorageResult<Option<Box<dyn Persistent>>> {
        if self.registry.contains(flock_id) {
            let obj = self.registry.get_dyn(flock_id).unwrap();
            Ok(Some(obj.clone_boxed()))
        } else {
            Ok(None)
        }
    }

    fn fetch_by_location(
        &self,
        _location: &super::persistent::FlockLocation,
    ) -> StorageResult<Option<Box<dyn Persistent>>> {
        Ok(None)
    }

    fn contains(&self, flock_id: &FlockId) -> bool {
        self.registry.contains(flock_id)
    }

    fn flock_info(&self, flock_id: &FlockId) -> Option<&FlockInfo> {
        self.flock_infos.get(flock_id)
    }

    fn begin_transaction(&mut self) -> StorageResult<()> {
        if self.in_transaction {
            return Err(StorageError::TransactionError(
                "already in transaction".into(),
            ));
        }
        self.in_transaction = true;
        self.dirty_set.clear();
        self.new_in_transaction.clear();
        self.destroy_queue.clear();
        Ok(())
    }

    fn end_transaction(&mut self) -> StorageResult<()> {
        if !self.in_transaction {
            return Err(StorageError::TransactionError("not in transaction".into()));
        }
        self.in_transaction = false;

        while let Some(flock_id) = self.destroy_queue.pop() {
            self.dismantle(&flock_id)?;
        }

        for info in self.flock_infos.values_mut() {
            info.commit_flags();
        }
        self.dirty_set.clear();
        self.new_in_transaction.clear();
        Ok(())
    }

    fn in_transaction(&self) -> bool {
        self.in_transaction
    }

    fn commit(&mut self) -> StorageResult<()> {
        for info in self.flock_infos.values_mut() {
            info.commit_flags();
        }
        while let Some(flock_id) = self.destroy_queue.pop() {
            self.dismantle(&flock_id)?;
        }
        self.dirty_set.clear();
        self.new_in_transaction.clear();
        Ok(())
    }

    fn rollback(&mut self) -> StorageResult<()> {
        for flock_id in self.new_in_transaction.drain(..) {
            self.registry.unregister(&flock_id);
            self.flock_infos.remove(&flock_id);
        }
        self.dirty_set.clear();
        self.destroy_queue.clear();
        self.in_transaction = false;
        Ok(())
    }

    fn next_hash(&mut self) -> u64 {
        let h = self.hash_counter;
        self.hash_counter += 1;
        h
    }

    fn next_token(&mut self) -> u32 {
        let t = self.token_counter;
        self.token_counter += 1;
        t
    }

    fn registry(&self) -> &PersistentRegistry {
        &self.registry
    }

    fn registry_mut(&mut self) -> &mut PersistentRegistry {
        &mut self.registry
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::any::Any;

    #[derive(Debug, Clone)]
    struct TestObj {
        flock_id: FlockId,
        info: Option<FlockInfo>,
        value: i64,
    }

    impl Persistent for TestObj {
        fn flock_id(&self) -> FlockId {
            self.flock_id
        }
        fn set_flock_id(&mut self, id: FlockId) {
            self.flock_id = id;
        }
        fn flock_info(&self) -> Option<&FlockInfo> {
            self.info.as_ref()
        }
        fn set_flock_info(&mut self, info: Option<FlockInfo>) {
            self.info = info;
        }
        fn flock_info_mut(&mut self) -> Option<&mut FlockInfo> {
            self.info.as_mut()
        }
        fn as_any(&self) -> &dyn Any {
            self
        }
        fn as_any_mut(&mut self) -> &mut dyn Any {
            self
        }
        fn clone_boxed(&self) -> Box<dyn Persistent> {
            Box::new(self.clone())
        }
        fn type_tag(&self) -> &'static str {
            "TestObj"
        }
        fn to_bytes(&self) -> Result<Vec<u8>, crate::persist::StorageError> {
            Ok(self.value.to_le_bytes().to_vec())
        }
    }

    fn make_obj(storage: &mut dyn StorageEngine, value: i64) -> FlockId {
        let id = storage.allocate_flock_id();
        let obj = Box::new(TestObj {
            flock_id: id,
            info: None,
            value,
        });
        storage.store_new(obj).unwrap();
        id
    }

    #[test]
    fn store_and_fetch() {
        let mut storage = InMemoryStorage::new();
        let id = make_obj(&mut storage, 42);
        let fetched = storage.fetch(&id).unwrap().unwrap();
        let obj = fetched.as_any().downcast_ref::<TestObj>().unwrap();
        assert_eq!(obj.value, 42);
    }

    #[test]
    fn contains_check() {
        let mut storage = InMemoryStorage::new();
        let id = make_obj(&mut storage, 1);
        assert!(storage.contains(&id));
        let other = FlockId::new(999, 999);
        assert!(!storage.contains(&other));
    }

    #[test]
    fn destroy_dismantle() {
        let mut storage = InMemoryStorage::new();
        let id = make_obj(&mut storage, 1);
        storage.destroy(&id).unwrap();
        storage.dismantle(&id).unwrap();
        assert!(!storage.contains(&id));
    }

    #[test]
    fn transaction_commit() {
        let mut storage = InMemoryStorage::new();
        storage.begin_transaction().unwrap();
        assert!(storage.in_transaction());
        let id = make_obj(&mut storage, 10);
        storage.end_transaction().unwrap();
        assert!(!storage.in_transaction());
        assert!(storage.contains(&id));
    }

    #[test]
    fn transaction_nested_rejected() {
        let mut storage = InMemoryStorage::new();
        storage.begin_transaction().unwrap();
        let result = storage.begin_transaction();
        assert!(result.is_err());
        storage.end_transaction().unwrap();
    }

    #[test]
    fn remember_forget_cycle() {
        let mut storage = InMemoryStorage::new();
        let id = make_obj(&mut storage, 1);
        let info = storage.flock_info(&id).unwrap();
        assert!(!info.is_forgotten());
        storage.forget(&id).unwrap();
        let info = storage.flock_info(&id).unwrap();
        assert!(info.is_forgotten());
        storage.remember(&id).unwrap();
        let info = storage.flock_info(&id).unwrap();
        assert!(!info.is_forgotten());
    }

    #[test]
    fn destroy_queue_processes_on_end() {
        let mut storage = InMemoryStorage::new();
        storage.begin_transaction().unwrap();
        let id = make_obj(&mut storage, 1);
        storage.destroy(&id).unwrap();
        assert!(storage.contains(&id));
        storage.end_transaction().unwrap();
        assert!(!storage.contains(&id));
    }

    #[test]
    fn disk_update_marks_dirty() {
        let mut storage = InMemoryStorage::new();
        let id = make_obj(&mut storage, 1);
        storage.commit().unwrap();
        let info = storage.flock_info(&id).unwrap();
        assert!(!info.is_dirty());
        storage.disk_update(&id).unwrap();
        let info = storage.flock_info(&id).unwrap();
        assert!(info.is_dirty());
    }

    #[test]
    fn next_hash_increments() {
        let mut storage = InMemoryStorage::new();
        let h1 = storage.next_hash();
        let h2 = storage.next_hash();
        assert_eq!(h1, 1);
        assert_eq!(h2, 2);
    }

    #[test]
    fn multiple_objects() {
        let mut storage = InMemoryStorage::new();
        let id1 = make_obj(&mut storage, 10);
        let _id2 = make_obj(&mut storage, 20);
        let id3 = make_obj(&mut storage, 30);
        assert_eq!(storage.object_count(), 3);
        let obj1 = storage.fetch(&id1).unwrap().unwrap();
        assert_eq!(obj1.as_any().downcast_ref::<TestObj>().unwrap().value, 10);
        let obj3 = storage.fetch(&id3).unwrap().unwrap();
        assert_eq!(obj3.as_any().downcast_ref::<TestObj>().unwrap().value, 30);
    }
}
