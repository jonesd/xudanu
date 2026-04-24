use super::engine::{StorageEngine, StorageResult};
use super::persistent::{FlockId, FlockInfo};
use super::traits::Persistent;

#[derive(Debug, Clone)]
pub struct Counter {
    flock_id: FlockId,
    info: Option<FlockInfo>,
    value: u64,
}

impl Counter {
    pub fn new(flock_id: FlockId) -> Self {
        Counter {
            flock_id,
            info: None,
            value: 0,
        }
    }

    pub fn value(&self) -> u64 {
        self.value
    }

    pub fn next(&mut self) -> u64 {
        let v = self.value;
        self.value += 1;
        v
    }
}

impl Persistent for Counter {
    fn flock_id(&self) -> FlockId { self.flock_id }
    fn set_flock_id(&mut self, id: FlockId) { self.flock_id = id; }
    fn flock_info(&self) -> Option<&FlockInfo> { self.info.as_ref() }
    fn set_flock_info(&mut self, info: Option<FlockInfo>) { self.info = info; }
    fn flock_info_mut(&mut self) -> Option<&mut FlockInfo> { self.info.as_mut() }
    fn as_any(&self) -> &dyn std::any::Any { self }
    fn as_any_mut(&mut self) -> &mut dyn std::any::Any { self }
    fn clone_boxed(&self) -> Box<dyn Persistent> { Box::new(self.clone()) }
    fn type_tag(&self) -> &'static str { "Counter" }
    fn to_bytes(&self) -> Result<Vec<u8>, super::engine::StorageError> {
        Ok(self.value.to_le_bytes().to_vec())
    }
}

const BATCH_SIZE: u64 = 64;

#[derive(Debug, Clone)]
pub struct BatchCounter {
    flock_id: FlockId,
    info: Option<FlockInfo>,
    current: u64,
    limit: u64,
}

impl BatchCounter {
    pub fn new(flock_id: FlockId) -> Self {
        BatchCounter {
            flock_id,
            info: None,
            current: 0,
            limit: BATCH_SIZE,
        }
    }

    pub fn current(&self) -> u64 {
        self.current
    }

    pub fn next(&mut self, engine: &mut dyn StorageEngine) -> StorageResult<u64> {
        if self.current >= self.limit {
            self.limit = self.current + BATCH_SIZE;
            engine.disk_update(&self.flock_id)?;
        }
        let v = self.current;
        self.current += 1;
        Ok(v)
    }

    pub fn next_batch(&mut self, engine: &mut dyn StorageEngine, count: u64) -> StorageResult<(u64, u64)> {
        let needed = self.current + count;
        if needed > self.limit {
            self.limit = needed + BATCH_SIZE;
            engine.disk_update(&self.flock_id)?;
        }
        let start = self.current;
        self.current += count;
        Ok((start, start + count))
    }
}

impl Persistent for BatchCounter {
    fn flock_id(&self) -> FlockId { self.flock_id }
    fn set_flock_id(&mut self, id: FlockId) { self.flock_id = id; }
    fn flock_info(&self) -> Option<&FlockInfo> { self.info.as_ref() }
    fn set_flock_info(&mut self, info: Option<FlockInfo>) { self.info = info; }
    fn flock_info_mut(&mut self) -> Option<&mut FlockInfo> { self.info.as_mut() }
    fn as_any(&self) -> &dyn std::any::Any { self }
    fn as_any_mut(&mut self) -> &mut dyn std::any::Any { self }
    fn clone_boxed(&self) -> Box<dyn Persistent> { Box::new(self.clone()) }
    fn type_tag(&self) -> &'static str { "BatchCounter" }
    fn to_bytes(&self) -> Result<Vec<u8>, super::engine::StorageError> {
        let mut buf = Vec::with_capacity(16);
        buf.extend_from_slice(&self.current.to_le_bytes());
        buf.extend_from_slice(&self.limit.to_le_bytes());
        Ok(buf)
    }
}

#[derive(Debug, Clone)]
pub struct SingleCounter {
    flock_id: FlockId,
    info: Option<FlockInfo>,
    value: u64,
}

impl SingleCounter {
    pub fn new(flock_id: FlockId) -> Self {
        SingleCounter {
            flock_id,
            info: None,
            value: 0,
        }
    }

    pub fn value(&self) -> u64 {
        self.value
    }

    pub fn next(&mut self, engine: &mut dyn StorageEngine) -> StorageResult<u64> {
        let v = self.value;
        self.value += 1;
        engine.disk_update(&self.flock_id)?;
        Ok(v)
    }
}

impl Persistent for SingleCounter {
    fn flock_id(&self) -> FlockId { self.flock_id }
    fn set_flock_id(&mut self, id: FlockId) { self.flock_id = id; }
    fn flock_info(&self) -> Option<&FlockInfo> { self.info.as_ref() }
    fn set_flock_info(&mut self, info: Option<FlockInfo>) { self.info = info; }
    fn flock_info_mut(&mut self) -> Option<&mut FlockInfo> { self.info.as_mut() }
    fn as_any(&self) -> &dyn std::any::Any { self }
    fn as_any_mut(&mut self) -> &mut dyn std::any::Any { self }
    fn clone_boxed(&self) -> Box<dyn Persistent> { Box::new(self.clone()) }
    fn type_tag(&self) -> &'static str { "SingleCounter" }
    fn to_bytes(&self) -> Result<Vec<u8>, super::engine::StorageError> {
        Ok(self.value.to_le_bytes().to_vec())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::persist::memory::InMemoryStorage;

    #[test]
    fn counter_sequential() {
        let id = FlockId::new(1, 0);
        let mut c = Counter::new(id);
        assert_eq!(c.next(), 0);
        assert_eq!(c.next(), 1);
        assert_eq!(c.next(), 2);
        assert_eq!(c.value(), 3);
    }

    #[test]
    fn batch_counter_within_batch() {
        let mut storage = InMemoryStorage::new();
        let id = storage.allocate_flock_id();
        let mut bc = BatchCounter::new(id);
        storage.store_new(Box::new(bc.clone())).unwrap();

        for i in 0..10u64 {
            let v = bc.next(&mut storage).unwrap();
            assert_eq!(v, i);
        }
        assert_eq!(bc.current(), 10);
    }

    #[test]
    fn batch_counter_crosses_batch_boundary() {
        let mut storage = InMemoryStorage::new();
        let id = storage.allocate_flock_id();
        let mut bc = BatchCounter::new(id);
        storage.store_new(Box::new(bc.clone())).unwrap();

        for i in 0..100u64 {
            let v = bc.next(&mut storage).unwrap();
            assert_eq!(v, i);
        }
        assert_eq!(bc.current(), 100);
    }

    #[test]
    fn batch_counter_next_batch() {
        let mut storage = InMemoryStorage::new();
        let id = storage.allocate_flock_id();
        let mut bc = BatchCounter::new(id);
        storage.store_new(Box::new(bc.clone())).unwrap();

        let (start, end) = bc.next_batch(&mut storage, 10).unwrap();
        assert_eq!(start, 0);
        assert_eq!(end, 10);
        assert_eq!(bc.current(), 10);

        let (start2, end2) = bc.next_batch(&mut storage, 100).unwrap();
        assert_eq!(start2, 10);
        assert_eq!(end2, 110);
    }

    #[test]
    fn single_counter_each_write() {
        let mut storage = InMemoryStorage::new();
        let id = storage.allocate_flock_id();
        let mut sc = SingleCounter::new(id);
        storage.store_new(Box::new(sc.clone())).unwrap();

        let v0 = sc.next(&mut storage).unwrap();
        assert_eq!(v0, 0);
        let info = storage.flock_info(&id).unwrap();
        assert!(info.is_dirty());
        storage.commit().unwrap();

        let v1 = sc.next(&mut storage).unwrap();
        assert_eq!(v1, 1);
    }
}
