use std::fmt;

use super::persistent::{FlockId, FlockInfo, FlockLocation};
use super::traits::{Persistent, PersistentRegistry};

pub type StorageResult<T> = Result<T, StorageError>;

#[derive(Debug)]
pub enum StorageError {
    Io(String),
    NotFound(FlockId),
    AlreadyExists(FlockId),
    CorruptData(String),
    TransactionError(String),
    OutOfSpace,
}

impl std::fmt::Display for StorageError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            StorageError::Io(msg) => write!(f, "IO error: {}", msg),
            StorageError::NotFound(id) => write!(f, "not found: {}", id),
            StorageError::AlreadyExists(id) => write!(f, "already exists: {}", id),
            StorageError::CorruptData(msg) => write!(f, "corrupt data: {}", msg),
            StorageError::TransactionError(msg) => write!(f, "transaction error: {}", msg),
            StorageError::OutOfSpace => write!(f, "out of space"),
        }
    }
}

impl std::error::Error for StorageError {}

pub trait StorageEngine: fmt::Debug + Send + Sync {
    fn store_new(&mut self, obj: Box<dyn Persistent>) -> StorageResult<FlockInfo>;
    fn disk_update(&mut self, flock_id: &FlockId) -> StorageResult<()>;
    fn remember(&mut self, flock_id: &FlockId) -> StorageResult<()>;
    fn forget(&mut self, flock_id: &FlockId) -> StorageResult<()>;
    fn destroy(&mut self, flock_id: &FlockId) -> StorageResult<()>;
    fn dismantle(&mut self, flock_id: &FlockId) -> StorageResult<()>;

    fn fetch(&self, flock_id: &FlockId) -> StorageResult<Option<Box<dyn Persistent>>>;
    fn fetch_by_location(
        &self,
        location: &FlockLocation,
    ) -> StorageResult<Option<Box<dyn Persistent>>>;
    fn contains(&self, flock_id: &FlockId) -> bool;
    fn flock_info(&self, flock_id: &FlockId) -> Option<&FlockInfo>;

    fn begin_transaction(&mut self) -> StorageResult<()>;
    fn end_transaction(&mut self) -> StorageResult<()>;
    fn in_transaction(&self) -> bool;

    fn commit(&mut self) -> StorageResult<()>;
    fn rollback(&mut self) -> StorageResult<()>;

    fn next_hash(&mut self) -> u64;
    fn next_token(&mut self) -> u32;

    fn allocate_flock_id(&mut self) -> FlockId {
        FlockId::new(self.next_hash(), self.next_token())
    }

    fn registry(&self) -> &PersistentRegistry;
    fn registry_mut(&mut self) -> &mut PersistentRegistry;

    fn object_count(&self) -> usize {
        self.registry().len()
    }
}
