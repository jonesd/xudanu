use super::engine::StorageEngine;

pub struct Transaction<'a> {
    engine: &'a mut dyn StorageEngine,
    committed: bool,
}

impl<'a> Transaction<'a> {
    pub fn begin(engine: &'a mut dyn StorageEngine) -> Result<Self, super::engine::StorageError> {
        engine.begin_transaction()?;
        Ok(Transaction {
            engine,
            committed: false,
        })
    }

    pub fn commit(mut self) -> Result<(), super::engine::StorageError> {
        self.committed = true;
        self.engine.end_transaction()
    }

    pub fn engine(&mut self) -> &mut dyn StorageEngine {
        self.engine
    }
}

impl<'a> Drop for Transaction<'a> {
    fn drop(&mut self) {
        if !self.committed {
            let _ = self.engine.rollback();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::persist::memory::InMemoryStorage;
    use crate::persist::persistent::{FlockId, FlockInfo};
    use crate::persist::traits::Persistent;
    use std::any::Any;

    #[derive(Debug, Clone)]
    struct TObj {
        flock_id: FlockId,
        info: Option<FlockInfo>,
        val: i64,
    }

    impl Persistent for TObj {
        fn flock_id(&self) -> FlockId { self.flock_id }
        fn set_flock_id(&mut self, id: FlockId) { self.flock_id = id; }
        fn flock_info(&self) -> Option<&FlockInfo> { self.info.as_ref() }
        fn set_flock_info(&mut self, info: Option<FlockInfo>) { self.info = info; }
        fn flock_info_mut(&mut self) -> Option<&mut FlockInfo> { self.info.as_mut() }
        fn as_any(&self) -> &dyn Any { self }
        fn as_any_mut(&mut self) -> &mut dyn Any { self }
        fn clone_boxed(&self) -> Box<dyn Persistent> { Box::new(self.clone()) }
        fn type_tag(&self) -> &'static str { "TObj" }
        fn to_bytes(&self) -> Result<Vec<u8>, crate::persist::StorageError> {
            Ok(self.val.to_le_bytes().to_vec())
        }
    }

    #[test]
    fn transaction_commit_path() {
        let mut storage = InMemoryStorage::new();
        {
            let mut tx = Transaction::begin(&mut storage).unwrap();
            let id = tx.engine().allocate_flock_id();
            tx.engine().store_new(Box::new(TObj { flock_id: id, info: None, val: 42 })).unwrap();
            tx.commit().unwrap();
        }
        assert_eq!(storage.object_count(), 1);
    }

    #[test]
    fn transaction_drop_rolls_back() {
        let mut storage = InMemoryStorage::new();
        {
            let mut tx = Transaction::begin(&mut storage).unwrap();
            let id = tx.engine().allocate_flock_id();
            tx.engine().store_new(Box::new(TObj { flock_id: id, info: None, val: 1 })).unwrap();
        }
        assert_eq!(storage.object_count(), 0);
    }

    #[test]
    fn transaction_commit_then_verify() {
        let mut storage = InMemoryStorage::new();
        let id;
        {
            let mut tx = Transaction::begin(&mut storage).unwrap();
            id = tx.engine().allocate_flock_id();
            tx.engine().store_new(Box::new(TObj { flock_id: id, info: None, val: 99 })).unwrap();
            tx.commit().unwrap();
        }
        let fetched = storage.fetch(&id).unwrap().unwrap();
        let obj = fetched.as_any().downcast_ref::<TObj>().unwrap();
        assert_eq!(obj.val, 99);
    }

    #[test]
    fn transaction_destroy_on_commit() {
        let mut storage = InMemoryStorage::new();
        let id;
        {
            let mut tx = Transaction::begin(&mut storage).unwrap();
            id = tx.engine().allocate_flock_id();
            tx.engine().store_new(Box::new(TObj { flock_id: id, info: None, val: 1 })).unwrap();
            tx.commit().unwrap();
        }
        {
            let mut tx = Transaction::begin(&mut storage).unwrap();
            tx.engine().destroy(&id).unwrap();
            tx.commit().unwrap();
        }
        assert!(!storage.contains(&id));
    }
}
