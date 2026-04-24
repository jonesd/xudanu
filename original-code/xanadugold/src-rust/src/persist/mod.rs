pub mod counter;
pub mod engine;
pub mod memory;
pub mod packer;
pub mod persistent;
pub mod snarf;
pub mod transaction;
pub mod traits;

pub use counter::{BatchCounter, Counter, SingleCounter};
pub use engine::{StorageEngine, StorageError, StorageResult};
pub use memory::InMemoryStorage;
pub use packer::SnarfStorage;
pub use persistent::{FlockFlags, FlockId, FlockInfo, FlockLocation, FlockState};
pub use snarf::{Snarf, SnarfStore, DEFAULT_SNARF_SIZE, SNARF_INFO_COUNT};
pub use transaction::Transaction;
pub use traits::{Persistent, PersistentRef, PersistentRegistry, TypeRegistry, DeserializerFn, encode_flock, decode_flock};
