use std::collections::HashMap;

use super::engine::{StorageEngine, StorageError, StorageResult};
use super::persistent::{FlockId, FlockInfo, FlockLocation};
use super::snarf::{SnarfStore, DEFAULT_SNARF_SIZE};
use super::traits::{Persistent, PersistentRegistry, TypeRegistry, encode_flock, decode_flock};

#[derive(Debug)]
pub struct SnarfStorage {
    registry: PersistentRegistry,
    type_registry: TypeRegistry,
    flock_infos: HashMap<FlockId, FlockInfo>,
    locations: HashMap<FlockId, FlockLocation>,
    snarf_store: SnarfStore,
    hash_counter: u64,
    token_counter: u32,
    in_transaction: bool,
    dirty_set: Vec<FlockId>,
    new_flocks: Vec<FlockId>,
    destroy_queue: Vec<FlockId>,
}

impl SnarfStorage {
    pub fn new() -> Self {
        SnarfStorage {
            registry: PersistentRegistry::new(),
            type_registry: TypeRegistry::new(),
            flock_infos: HashMap::new(),
            locations: HashMap::new(),
            snarf_store: SnarfStore::new(DEFAULT_SNARF_SIZE),
            hash_counter: 1,
            token_counter: 0,
            in_transaction: false,
            dirty_set: Vec::new(),
            new_flocks: Vec::new(),
            destroy_queue: Vec::new(),
        }
    }

    pub fn with_snarf_size(snarf_size: usize) -> Self {
        SnarfStorage {
            registry: PersistentRegistry::new(),
            type_registry: TypeRegistry::new(),
            flock_infos: HashMap::new(),
            locations: HashMap::new(),
            snarf_store: SnarfStore::new(snarf_size),
            hash_counter: 1,
            token_counter: 0,
            in_transaction: false,
            dirty_set: Vec::new(),
            new_flocks: Vec::new(),
            destroy_queue: Vec::new(),
        }
    }

    pub fn from_store(snarf_store: SnarfStore) -> Self {
        SnarfStorage {
            registry: PersistentRegistry::new(),
            type_registry: TypeRegistry::new(),
            flock_infos: HashMap::new(),
            locations: HashMap::new(),
            snarf_store,
            hash_counter: 1,
            token_counter: 0,
            in_transaction: false,
            dirty_set: Vec::new(),
            new_flocks: Vec::new(),
            destroy_queue: Vec::new(),
        }
    }

    pub fn register_type(&mut self, type_tag: &'static str, deserializer: super::traits::DeserializerFn) {
        self.type_registry.register(type_tag, deserializer);
    }

    fn serialize_flock(&self, obj: &dyn Persistent) -> StorageResult<Vec<u8>> {
        let payload = obj.to_bytes()?;
        Ok(encode_flock(obj.type_tag(), &payload))
    }

    fn deserialize_flock(&self, data: &[u8], flock_id: FlockId) -> StorageResult<Box<dyn Persistent>> {
        let (tag, payload) = decode_flock(data)?;
        self.type_registry.deserialize(tag, payload, flock_id)
    }

    fn write_flock_to_snarf(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        let obj = self.registry.get_dyn(flock_id)
            .ok_or_else(|| StorageError::NotFound(*flock_id))?;
        let data = self.serialize_flock(obj)?;
        let info = self.flock_infos.get(flock_id)
            .ok_or_else(|| StorageError::NotFound(*flock_id))?;

        if let Some(ref loc) = info.location {
            let existing_size = self.snarf_store.get(loc.snarf_id)
                .and_then(|s| s.flock_size(loc.index as usize))
                .unwrap_or(0);

            if data.len() as u32 <= existing_size {
                self.snarf_store.write_flock(loc, &data)
                    .map_err(|e| StorageError::Io(e.to_string()))?;
                return Ok(());
            }
        }

        let new_loc = self.snarf_store.allocate_and_write(&data)
            .ok_or(StorageError::OutOfSpace)?;

        if let Some(old_loc) = self.locations.get(flock_id).cloned() {
            if let Some(snarf) = self.snarf_store.get_mut(old_loc.snarf_id) {
                snarf.forward_to(old_loc.index as usize, new_loc.snarf_id, new_loc.index);
            }
        }

        self.locations.insert(*flock_id, new_loc.clone());
        if let Some(info) = self.flock_infos.get_mut(flock_id) {
            info.location = Some(new_loc);
        }

        Ok(())
    }

    fn process_destroys(&mut self) -> StorageResult<()> {
        let destroys: Vec<FlockId> = self.destroy_queue.drain(..).collect();
        for flock_id in destroys {
            if let Some(info) = self.flock_infos.get(&flock_id) {
                if info.is_forgotten() {
                    if let Some(ref loc) = info.location {
                        if let Some(snarf) = self.snarf_store.get_mut(loc.snarf_id) {
                            snarf.wipe_flock(loc.index as usize);
                        }
                    }
                    self.registry.unregister(&flock_id);
                    self.flock_infos.remove(&flock_id);
                    self.locations.remove(&flock_id);
                }
            }
        }
        Ok(())
    }

    pub fn snarf_store_mut(&mut self) -> &mut SnarfStore {
        &mut self.snarf_store
    }

    pub fn snapshot_meta(&self) -> super::file_storage::MetaRecord {
        let flocks = self.flock_infos.iter()
            .filter(|(_, info)| !info.is_destroyed())
            .map(|(id, info)| {
                let loc = self.locations.get(id).cloned();
                (*id, loc, info.flags, info.old_size)
            })
            .collect();
        super::file_storage::MetaRecord {
            hash_counter: self.hash_counter,
            token_counter: self.token_counter,
            flocks,
        }
    }

    pub fn restore_counters(&mut self, hash_counter: u64, token_counter: u32) {
        self.hash_counter = hash_counter;
        self.token_counter = token_counter;
    }

    pub fn restore_flock_info(
        &mut self,
        flock_id: FlockId,
        location: Option<FlockLocation>,
        flags: super::persistent::FlockFlags,
        old_size: u32,
    ) {
        let mut info = FlockInfo::new(flock_id);
        info.location = location.clone();
        info.flags = flags & !super::persistent::FlockFlags::CONTENTS_DIRTY & !super::persistent::FlockFlags::IS_NEW;
        info.old_size = old_size;
        self.flock_infos.insert(flock_id, info);
        if let Some(loc) = location {
            self.locations.insert(flock_id, loc);
        }
    }

    pub fn has_flock_info(&self, flock_id: &FlockId) -> bool {
        self.flock_infos.contains_key(flock_id)
    }

    pub fn flock_location(&self, flock_id: &FlockId) -> Option<FlockLocation> {
        self.locations.get(flock_id).cloned()
    }

    pub fn flock_info_count(&self) -> usize {
        self.flock_infos.values()
            .filter(|info| !info.is_destroyed())
            .count()
    }
}

impl Default for SnarfStorage {
    fn default() -> Self {
        Self::new()
    }
}

impl StorageEngine for SnarfStorage {
    fn store_new(&mut self, mut obj: Box<dyn Persistent>) -> StorageResult<FlockInfo> {
        let flock_id = obj.flock_id();
        if self.registry.contains(&flock_id) {
            return Err(StorageError::AlreadyExists(flock_id));
        }
        let info = FlockInfo::new(flock_id);
        obj.set_flock_info(Some(info.clone()));
        self.registry.register(obj);
        self.flock_infos.insert(flock_id, info.clone());
        self.new_flocks.push(flock_id);
        Ok(info)
    }

    fn disk_update(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        if let Some(info) = self.flock_infos.get_mut(flock_id) {
            info.mark_dirty();
            self.dirty_set.push(*flock_id);
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
        if let Some(info) = self.flock_infos.get(flock_id) {
            if let Some(ref loc) = info.location {
                if let Some(snarf) = self.snarf_store.get_mut(loc.snarf_id) {
                    snarf.wipe_flock(loc.index as usize);
                }
            }
        }
        self.registry.unregister(flock_id);
        self.flock_infos.remove(flock_id);
        self.locations.remove(flock_id);
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

    fn fetch_by_location(&self, location: &FlockLocation) -> StorageResult<Option<Box<dyn Persistent>>> {
        let data = self.snarf_store.read_flock(location)
            .map_err(|e| StorageError::Io(e.to_string()))?;
        let flock_id = self.locations.iter()
            .find(|(_, loc)| loc.snarf_id == location.snarf_id && loc.index == location.index)
            .map(|(id, _)| *id)
            .ok_or_else(|| StorageError::NotFound(FlockId::new(0, 0)))?;
        let obj = self.deserialize_flock(&data, flock_id)?;
        Ok(Some(obj))
    }

    fn contains(&self, flock_id: &FlockId) -> bool {
        self.registry.contains(flock_id)
    }

    fn flock_info(&self, flock_id: &FlockId) -> Option<&FlockInfo> {
        self.flock_infos.get(flock_id)
    }

    fn begin_transaction(&mut self) -> StorageResult<()> {
        if self.in_transaction {
            return Err(StorageError::TransactionError("already in transaction".into()));
        }
        self.in_transaction = true;
        self.dirty_set.clear();
        self.new_flocks.clear();
        self.destroy_queue.clear();
        Ok(())
    }

    fn end_transaction(&mut self) -> StorageResult<()> {
        if !self.in_transaction {
            return Err(StorageError::TransactionError("not in transaction".into()));
        }
        self.in_transaction = false;

        let new_flocks: Vec<FlockId> = self.new_flocks.drain(..).collect();
        for flock_id in &new_flocks {
            self.write_flock_to_snarf(flock_id)?;
        }
        let dirty_set: Vec<FlockId> = self.dirty_set.drain(..).collect();
        for flock_id in &dirty_set {
            self.write_flock_to_snarf(flock_id)?;
        }

        for info in self.flock_infos.values_mut() {
            info.commit_flags();
        }

        self.process_destroys()?;

        self.dirty_set.clear();
        self.new_flocks.clear();
        Ok(())
    }

    fn in_transaction(&self) -> bool {
        self.in_transaction
    }

    fn commit(&mut self) -> StorageResult<()> {
        for flock_id in self.registry.flock_ids() {
            if let Some(info) = self.flock_infos.get(&flock_id) {
                if info.is_dirty() {
                    self.write_flock_to_snarf(&flock_id)?;
                }
            }
        }
        for info in self.flock_infos.values_mut() {
            info.commit_flags();
        }
        self.dirty_set.clear();
        self.new_flocks.clear();
        Ok(())
    }

    fn rollback(&mut self) -> StorageResult<()> {
        let rolled_back: Vec<FlockId> = self.new_flocks.drain(..).collect();
        for flock_id in &rolled_back {
            if let Some(loc) = self.locations.get(flock_id) {
                if let Some(snarf) = self.snarf_store.get_mut(loc.snarf_id) {
                    snarf.wipe_flock(loc.index as usize);
                }
            }
            self.registry.unregister(flock_id);
            self.flock_infos.remove(flock_id);
            self.locations.remove(flock_id);
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
        fn flock_id(&self) -> FlockId { self.flock_id }
        fn set_flock_id(&mut self, id: FlockId) { self.flock_id = id; }
        fn flock_info(&self) -> Option<&FlockInfo> { self.info.as_ref() }
        fn set_flock_info(&mut self, info: Option<FlockInfo>) { self.info = info; }
        fn flock_info_mut(&mut self) -> Option<&mut FlockInfo> { self.info.as_mut() }
        fn as_any(&self) -> &dyn Any { self }
        fn as_any_mut(&mut self) -> &mut dyn Any { self }
        fn clone_boxed(&self) -> Box<dyn Persistent> { Box::new(self.clone()) }
        fn type_tag(&self) -> &'static str { "TestObj" }
        fn to_bytes(&self) -> Result<Vec<u8>, crate::persist::StorageError> {
            Ok(self.value.to_le_bytes().to_vec())
        }
    }

    fn make_obj(engine: &mut dyn StorageEngine, value: i64) -> FlockId {
        let id = engine.allocate_flock_id();
        let obj = Box::new(TestObj { flock_id: id, info: None, value });
        engine.store_new(obj).unwrap();
        id
    }

    fn new_storage() -> SnarfStorage {
        let mut storage = SnarfStorage::new();
        storage.register_type("TestObj", |data, flock_id| {
            let value = i64::from_le_bytes(data.try_into().map_err(|_| StorageError::CorruptData("bad i64".into()))?);
            Ok(Box::new(TestObj { flock_id, info: None, value }))
        });
        storage
    }

    #[test]
    fn snarf_storage_store_and_fetch() {
        let mut storage = new_storage();
        let id = make_obj(&mut storage, 42);
        let fetched = storage.fetch(&id).unwrap().unwrap();
        let obj = fetched.as_any().downcast_ref::<TestObj>().unwrap();
        assert_eq!(obj.value, 42);
    }

    #[test]
    fn snarf_storage_contains() {
        let mut storage = new_storage();
        let id = make_obj(&mut storage, 1);
        assert!(storage.contains(&id));
        assert!(!storage.contains(&FlockId::new(999, 999)));
    }

    #[test]
    fn snarf_storage_transaction_commit() {
        let mut storage = new_storage();
        storage.begin_transaction().unwrap();
        let id = make_obj(&mut storage, 10);
        storage.end_transaction().unwrap();
        assert!(storage.contains(&id));
    }

    #[test]
    fn snarf_storage_destroy_removes() {
        let mut storage = new_storage();
        storage.begin_transaction().unwrap();
        let id = make_obj(&mut storage, 1);
        storage.end_transaction().unwrap();

        storage.begin_transaction().unwrap();
        storage.destroy(&id).unwrap();
        storage.end_transaction().unwrap();
        assert!(!storage.contains(&id));
    }

    #[test]
    fn snarf_storage_remember_forget() {
        let mut storage = new_storage();
        let id = make_obj(&mut storage, 1);
        storage.remember(&id).unwrap();
        assert!(!storage.flock_info(&id).unwrap().is_forgotten());
        storage.forget(&id).unwrap();
        assert!(storage.flock_info(&id).unwrap().is_forgotten());
        storage.remember(&id).unwrap();
        assert!(!storage.flock_info(&id).unwrap().is_forgotten());
    }

    #[test]
    fn snarf_storage_multiple_objects() {
        let mut storage = new_storage();
        let ids: Vec<FlockId> = (0..10).map(|i| make_obj(&mut storage, i)).collect();
        assert_eq!(storage.object_count(), 10);
        for (i, id) in ids.iter().enumerate() {
            let obj = storage.fetch(id).unwrap().unwrap();
            assert_eq!(obj.as_any().downcast_ref::<TestObj>().unwrap().value, i as i64);
        }
    }

    #[test]
    fn snarf_storage_disk_update_marks_dirty() {
        let mut storage = new_storage();
        let id = make_obj(&mut storage, 1);
        storage.commit().unwrap();
        assert!(!storage.flock_info(&id).unwrap().is_dirty());
        storage.disk_update(&id).unwrap();
        assert!(storage.flock_info(&id).unwrap().is_dirty());
    }

    #[test]
    fn snarf_storage_transaction_writes_new_flocks() {
        let mut storage = new_storage();
        storage.begin_transaction().unwrap();
        let id1 = make_obj(&mut storage, 10);
        let id2 = make_obj(&mut storage, 20);
        storage.end_transaction().unwrap();

        let obj1 = storage.fetch(&id1).unwrap().unwrap();
        assert_eq!(obj1.as_any().downcast_ref::<TestObj>().unwrap().value, 10);
        let obj2 = storage.fetch(&id2).unwrap().unwrap();
        assert_eq!(obj2.as_any().downcast_ref::<TestObj>().unwrap().value, 20);
    }

    #[test]
    fn snarf_storage_rollback_clears() {
        let mut storage = new_storage();
        storage.begin_transaction().unwrap();
        let id = make_obj(&mut storage, 1);
        storage.rollback().unwrap();
        assert!(!storage.contains(&id));
    }

    #[test]
    fn snarf_storage_serialize_deserialize_roundtrip() {
        let mut storage = new_storage();
        storage.begin_transaction().unwrap();
        let id = make_obj(&mut storage, 12345);
        storage.end_transaction().unwrap();

        let loc = storage.locations.get(&id).cloned().unwrap();
        let fetched = storage.fetch_by_location(&loc).unwrap().unwrap();
        let obj = fetched.as_any().downcast_ref::<TestObj>().unwrap();
        assert_eq!(obj.value, 12345);
        assert_eq!(obj.flock_id, id);
    }

    #[test]
    fn snarf_storage_update_refits_and_rereads() {
        let mut storage = new_storage();
        storage.begin_transaction().unwrap();
        let id = make_obj(&mut storage, 10);
        storage.end_transaction().unwrap();

        {
            let obj = storage.registry_mut().get_mut::<TestObj>(&id).unwrap();
            obj.value = 99;
        }
        storage.begin_transaction().unwrap();
        storage.disk_update(&id).unwrap();
        storage.end_transaction().unwrap();

        let fetched = storage.fetch(&id).unwrap().unwrap();
        let obj = fetched.as_any().downcast_ref::<TestObj>().unwrap();
        assert_eq!(obj.value, 99);
    }

    #[test]
    #[ignore]
    fn stress_snarf_storage_10k_objects() {
        let mut storage = new_storage();
        storage.begin_transaction().unwrap();
        let mut ids = Vec::new();
        for i in 0..10_000i64 {
            let id = make_obj(&mut storage, i);
            ids.push(id);
        }
        storage.end_transaction().unwrap();
        assert_eq!(storage.object_count(), 10_000);

        for (i, id) in ids.iter().enumerate() {
            let obj = storage.fetch(id).unwrap().unwrap();
            assert_eq!(obj.as_any().downcast_ref::<TestObj>().unwrap().value, i as i64);
        }

        storage.begin_transaction().unwrap();
        for id in &ids[0..5000] {
            storage.destroy(id).unwrap();
        }
        storage.end_transaction().unwrap();
        assert_eq!(storage.object_count(), 5_000);
    }
}
