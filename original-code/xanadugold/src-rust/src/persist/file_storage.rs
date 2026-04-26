use std::io::{self, Read};
use std::path::Path;

use super::engine::{StorageEngine, StorageError, StorageResult};
use super::packer::SnarfStorage;
use super::persistent::{FlockFlags, FlockId, FlockInfo, FlockLocation};
use super::snarf::SnarfStore;
use super::traits::{Persistent, PersistentRegistry, DeserializerFn};
use super::urdi::{UrdiFile, DEFAULT_DATA_START, DEFAULT_INITIAL_COUNT, DEFAULT_SNARF_SIZE_FILE, DEFAULT_STAGE_COUNT};

const META_SNARF_ID: u32 = 0;
const DATA_SNARF_OFFSET: u32 = DEFAULT_DATA_START;
const META_VERSION: u32 = 1;

pub struct MetaRecord {
    pub(crate) hash_counter: u64,
    pub(crate) token_counter: u32,
    pub(crate) flocks: Vec<(FlockId, Option<FlockLocation>, FlockFlags, u32)>,
}

impl MetaRecord {
    fn to_bytes(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(16 + self.flocks.len() * 28);
        buf.extend_from_slice(&META_VERSION.to_le_bytes());
        buf.extend_from_slice(&self.hash_counter.to_le_bytes());
        buf.extend_from_slice(&self.token_counter.to_le_bytes());
        buf.extend_from_slice(&(self.flocks.len() as u32).to_le_bytes());
        for (id, loc, flags, old_size) in &self.flocks {
            buf.extend_from_slice(&id.hash.to_le_bytes());
            buf.extend_from_slice(&id.token.to_le_bytes());
            if let Some(l) = loc {
                buf.extend_from_slice(&1u32.to_le_bytes());
                buf.extend_from_slice(&l.snarf_id.to_le_bytes());
                buf.extend_from_slice(&l.index.to_le_bytes());
            } else {
                buf.extend_from_slice(&0u32.to_le_bytes());
                buf.extend_from_slice(&0u32.to_le_bytes());
                buf.extend_from_slice(&0u32.to_le_bytes());
            }
            buf.extend_from_slice(&flags.bits().to_le_bytes());
            buf.extend_from_slice(&old_size.to_le_bytes());
        }
        buf
    }

    fn from_bytes(data: &[u8]) -> io::Result<Self> {
        let mut cursor = io::Cursor::new(data);
        let mut version_buf = [0u8; 4];
        cursor.read_exact(&mut version_buf)?;
        let version = u32::from_le_bytes(version_buf);
        if version != META_VERSION {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("unsupported meta version {}", version),
            ));
        }
        let mut buf8 = [0u8; 8];
        let mut buf4 = [0u8; 4];
        cursor.read_exact(&mut buf8)?;
        let hash_counter = u64::from_le_bytes(buf8);
        cursor.read_exact(&mut buf4)?;
        let token_counter = u32::from_le_bytes(buf4);
        cursor.read_exact(&mut buf4)?;
        let flock_count = u32::from_le_bytes(buf4) as usize;
        let mut flocks = Vec::with_capacity(flock_count);
        for _ in 0..flock_count {
            cursor.read_exact(&mut buf8)?;
            let hash = u64::from_le_bytes(buf8);
            cursor.read_exact(&mut buf4)?;
            let token = u32::from_le_bytes(buf4);
            cursor.read_exact(&mut buf4)?;
            let has_loc = u32::from_le_bytes(buf4);
            cursor.read_exact(&mut buf4)?;
            let snarf_id = u32::from_le_bytes(buf4);
            cursor.read_exact(&mut buf4)?;
            let index = u32::from_le_bytes(buf4);
            let loc = if has_loc != 0 {
                Some(FlockLocation::new(snarf_id, index))
            } else {
                None
            };
            cursor.read_exact(&mut buf4)?;
            let flags = FlockFlags::from_bits_truncate(u32::from_le_bytes(buf4));
            cursor.read_exact(&mut buf4)?;
            let old_size = u32::from_le_bytes(buf4);
            flocks.push((FlockId::new(hash, token), loc, flags, old_size));
        }
        Ok(MetaRecord {
            hash_counter,
            token_counter,
            flocks,
        })
    }
}

#[derive(Debug)]
pub struct FileBackedStorage {
    storage: SnarfStorage,
    urdi: UrdiFile,
}

impl FileBackedStorage {
    pub fn create(path: &Path) -> io::Result<Self> {
        Self::create_with_snarf_size(path, DEFAULT_SNARF_SIZE_FILE as usize)
    }

    pub fn create_with_snarf_size(path: &Path, snarf_size: usize) -> io::Result<Self> {
        let initial_count = DEFAULT_INITIAL_COUNT.max(DATA_SNARF_OFFSET + 4);
        let urdi = UrdiFile::create(
            path,
            snarf_size as u32,
            initial_count,
            DEFAULT_STAGE_COUNT,
            DATA_SNARF_OFFSET,
        )?;
        let mut storage = SnarfStorage::with_snarf_size(snarf_size);
        storage.snarf_store_mut().ensure_capacity(
            initial_count.saturating_sub(DATA_SNARF_OFFSET),
        );
        let mut fbs = FileBackedStorage { storage, urdi };
        fbs.write_meta()?;
        fbs.flush()?;
        Ok(fbs)
    }

    pub fn open(path: &Path) -> io::Result<Self> {
        let mut urdi = UrdiFile::open(path)?;
        let _snarf_size = urdi.snarf_size();
        let data_count = urdi.snarf_count().saturating_sub(DATA_SNARF_OFFSET);
        let mut store = SnarfStore::load_from_urdi_with_offset(&mut urdi, DATA_SNARF_OFFSET)?;
        store.ensure_capacity(data_count);
        let storage = SnarfStorage::from_store(store);
        let mut fbs = FileBackedStorage { storage, urdi };
        if let Some(meta_data) = fbs.urdi.read_snarf(META_SNARF_ID)? {
            let meta = MetaRecord::from_bytes(&meta_data)?;
            fbs.storage.restore_counters(meta.hash_counter, meta.token_counter);
            for (flock_id, loc, flags, old_size) in meta.flocks {
                fbs.storage.restore_flock_info(flock_id, loc, flags, old_size);
            }
        }
        Ok(fbs)
    }

    pub fn register_type(&mut self, type_tag: &'static str, deserializer: DeserializerFn) {
        self.storage.register_type(type_tag, deserializer);
    }

    pub fn checkpoint(&mut self) -> io::Result<()> {
        self.storage.snarf_store_mut().flush_to_urdi_with_offset(&mut self.urdi, DATA_SNARF_OFFSET)?;
        self.write_meta()?;
        self.flush()
    }

    fn write_meta(&mut self) -> io::Result<()> {
        let meta = self.storage.snapshot_meta();
        let data = meta.to_bytes();
        let snarf_size = self.urdi.snarf_size();
        if data.len() > snarf_size {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("meta record {}B exceeds snarf_size {}B", data.len(), snarf_size),
            ));
        }
        self.urdi.write_snarf(META_SNARF_ID, &data)
    }

    fn flush(&mut self) -> io::Result<()> {
        self.urdi.sync_all()
    }
}

impl StorageEngine for FileBackedStorage {
    fn store_new(&mut self, obj: Box<dyn Persistent>) -> StorageResult<FlockInfo> {
        self.storage.store_new(obj)
    }

    fn disk_update(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        self.storage.disk_update(flock_id)
    }

    fn remember(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        self.storage.remember(flock_id)
    }

    fn forget(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        self.storage.forget(flock_id)
    }

    fn destroy(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        self.storage.destroy(flock_id)
    }

    fn dismantle(&mut self, flock_id: &FlockId) -> StorageResult<()> {
        self.storage.dismantle(flock_id)
    }

    fn fetch(&self, flock_id: &FlockId) -> StorageResult<Option<Box<dyn Persistent>>> {
        if let Some(obj) = self.storage.fetch(flock_id)? {
            return Ok(Some(obj));
        }
        if !self.storage.contains(flock_id) {
            if self.storage.has_flock_info(flock_id) {
                if let Some(loc) = self.storage.flock_location(flock_id) {
                    return self.storage.fetch_by_location(&loc);
                }
            }
            return Ok(None);
        }
        if let Some(loc) = self.storage.flock_location(flock_id) {
            return self.storage.fetch_by_location(&loc);
        }
        Ok(None)
    }

    fn fetch_by_location(&self, location: &FlockLocation) -> StorageResult<Option<Box<dyn Persistent>>> {
        self.storage.fetch_by_location(location)
    }

    fn contains(&self, flock_id: &FlockId) -> bool {
        self.storage.contains(flock_id) || self.storage.has_flock_info(flock_id)
    }

    fn object_count(&self) -> usize {
        self.storage.flock_info_count()
    }

    fn flock_info(&self, flock_id: &FlockId) -> Option<&FlockInfo> {
        self.storage.flock_info(flock_id)
    }

    fn begin_transaction(&mut self) -> StorageResult<()> {
        self.storage.begin_transaction()
    }

    fn end_transaction(&mut self) -> StorageResult<()> {
        self.storage.end_transaction()
    }

    fn in_transaction(&self) -> bool {
        self.storage.in_transaction()
    }

    fn commit(&mut self) -> StorageResult<()> {
        self.storage.commit()
    }

    fn rollback(&mut self) -> StorageResult<()> {
        self.storage.rollback()
    }

    fn next_hash(&mut self) -> u64 {
        self.storage.next_hash()
    }

    fn next_token(&mut self) -> u32 {
        self.storage.next_token()
    }

    fn registry(&self) -> &PersistentRegistry {
        self.storage.registry()
    }

    fn registry_mut(&mut self) -> &mut PersistentRegistry {
        self.storage.registry_mut()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::any::Any;

    struct TempDir(std::path::PathBuf);
    impl TempDir {
        fn new(name: &str) -> Self {
            let dir = std::env::temp_dir().join(format!(
                "xudanu_fbs_test_{}_{}", name, std::process::id()
            ));
            let _ = std::fs::create_dir_all(&dir);
            TempDir(dir)
        }
        fn join(&self, name: &str) -> std::path::PathBuf { self.0.join(name) }
    }
    impl Drop for TempDir {
        fn drop(&mut self) { let _ = std::fs::remove_dir_all(&self.0); }
    }

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
        fn to_bytes(&self) -> Result<Vec<u8>, StorageError> {
            Ok(self.value.to_le_bytes().to_vec())
        }
    }

    fn register_types(fbs: &mut FileBackedStorage) {
        fbs.register_type("TestObj", |data, flock_id| {
            let value = i64::from_le_bytes(data.try_into().map_err(|_| StorageError::CorruptData("bad i64".into()))?);
            Ok(Box::new(TestObj { flock_id, info: None, value }))
        });
    }

    fn make_obj(engine: &mut dyn StorageEngine, value: i64) -> FlockId {
        let id = engine.allocate_flock_id();
        let obj = Box::new(TestObj { flock_id: id, info: None, value });
        engine.store_new(obj).unwrap();
        id
    }

    #[test]
    fn fbs_create_and_open_empty() {
        let dir = TempDir::new("create_open");
        let path = dir.join("test.xu");

        {
            let mut fbs = FileBackedStorage::create(&path).unwrap();
            register_types(&mut fbs);
            fbs.checkpoint().unwrap();
        }
        {
            let mut fbs = FileBackedStorage::open(&path).unwrap();
            register_types(&mut fbs);
            assert_eq!(fbs.object_count(), 0);
        }
    }

    #[test]
    fn fbs_store_checkpoint_reopen() {
        let dir = TempDir::new("checkpoint_reopen");
        let path = dir.join("test.xu");

        let id;
        {
            let mut fbs = FileBackedStorage::create_with_snarf_size(&path, 4096).unwrap();
            register_types(&mut fbs);
            fbs.begin_transaction().unwrap();
            id = make_obj(&mut fbs, 42);
            fbs.end_transaction().unwrap();
            fbs.checkpoint().unwrap();
        }
        {
            let mut fbs = FileBackedStorage::open(&path).unwrap();
            register_types(&mut fbs);
            assert_eq!(fbs.object_count(), 1);
            let obj = fbs.fetch(&id).unwrap().unwrap();
            let tobj = obj.as_any().downcast_ref::<TestObj>().unwrap();
            assert_eq!(tobj.value, 42);
        }
    }

    #[test]
    fn fbs_multiple_checkpoints() {
        let dir = TempDir::new("multi_checkpoint");
        let path = dir.join("test.xu");

        let id1;
        let id2;
        {
            let mut fbs = FileBackedStorage::create_with_snarf_size(&path, 4096).unwrap();
            register_types(&mut fbs);

            fbs.begin_transaction().unwrap();
            id1 = make_obj(&mut fbs, 10);
            fbs.end_transaction().unwrap();
            fbs.checkpoint().unwrap();

            fbs.begin_transaction().unwrap();
            id2 = make_obj(&mut fbs, 20);
            fbs.end_transaction().unwrap();
            fbs.checkpoint().unwrap();
        }
        {
            let mut fbs = FileBackedStorage::open(&path).unwrap();
            register_types(&mut fbs);
            assert_eq!(fbs.object_count(), 2);
            let v1 = fbs.fetch(&id1).unwrap().unwrap().as_any().downcast_ref::<TestObj>().unwrap().value;
            let v2 = fbs.fetch(&id2).unwrap().unwrap().as_any().downcast_ref::<TestObj>().unwrap().value;
            assert_eq!(v1, 10);
            assert_eq!(v2, 20);
        }
    }

    #[test]
    fn fbs_update_and_reopen() {
        let dir = TempDir::new("update_reopen");
        let path = dir.join("test.xu");

        let id;
        {
            let mut fbs = FileBackedStorage::create_with_snarf_size(&path, 4096).unwrap();
            register_types(&mut fbs);
            fbs.begin_transaction().unwrap();
            id = make_obj(&mut fbs, 1);
            fbs.end_transaction().unwrap();
            fbs.checkpoint().unwrap();

            {
                let obj = fbs.registry_mut().get_mut::<TestObj>(&id).unwrap();
                obj.value = 99;
            }
            fbs.begin_transaction().unwrap();
            fbs.disk_update(&id).unwrap();
            fbs.end_transaction().unwrap();
            fbs.checkpoint().unwrap();
        }
        {
            let mut fbs = FileBackedStorage::open(&path).unwrap();
            register_types(&mut fbs);
            let obj = fbs.fetch(&id).unwrap().unwrap();
            assert_eq!(obj.as_any().downcast_ref::<TestObj>().unwrap().value, 99);
        }
    }

    #[test]
    fn fbs_destroy_and_reopen() {
        let dir = TempDir::new("destroy_reopen");
        let path = dir.join("test.xu");

        let id;
        {
            let mut fbs = FileBackedStorage::create_with_snarf_size(&path, 4096).unwrap();
            register_types(&mut fbs);
            fbs.begin_transaction().unwrap();
            id = make_obj(&mut fbs, 1);
            fbs.end_transaction().unwrap();
            fbs.checkpoint().unwrap();

            fbs.begin_transaction().unwrap();
            fbs.destroy(&id).unwrap();
            fbs.end_transaction().unwrap();
            fbs.checkpoint().unwrap();
        }
        {
            let mut fbs = FileBackedStorage::open(&path).unwrap();
            register_types(&mut fbs);
            assert!(!fbs.contains(&id));
            assert_eq!(fbs.object_count(), 0);
        }
    }

    #[test]
    fn fbs_counters_preserved() {
        let dir = TempDir::new("counters");
        let path = dir.join("test.xu");

        let saved_hash;
        {
            let mut fbs = FileBackedStorage::create_with_snarf_size(&path, 4096).unwrap();
            register_types(&mut fbs);
            for _ in 0..5 {
                fbs.begin_transaction().unwrap();
                make_obj(&mut fbs, 0);
                fbs.end_transaction().unwrap();
            }
            fbs.checkpoint().unwrap();
            saved_hash = fbs.next_hash();
        }
        {
            let mut fbs = FileBackedStorage::open(&path).unwrap();
            register_types(&mut fbs);
            assert_eq!(fbs.next_hash(), saved_hash);
        }
    }

    #[test]
    fn fbs_rollback_no_checkpoint() {
        let dir = TempDir::new("rollback");
        let path = dir.join("test.xu");

        let id;
        {
            let mut fbs = FileBackedStorage::create_with_snarf_size(&path, 4096).unwrap();
            register_types(&mut fbs);
            fbs.begin_transaction().unwrap();
            id = make_obj(&mut fbs, 1);
            fbs.end_transaction().unwrap();
            fbs.checkpoint().unwrap();

            fbs.begin_transaction().unwrap();
            make_obj(&mut fbs, 2);
            fbs.rollback().unwrap();
        }
        {
            let mut fbs = FileBackedStorage::open(&path).unwrap();
            register_types(&mut fbs);
            assert!(fbs.contains(&id));
            assert_eq!(fbs.object_count(), 1);
        }
    }

    #[test]
    fn fbs_many_objects() {
        let dir = TempDir::new("many_objects");
        let path = dir.join("test.xu");

        let count = 50;
        let mut ids = Vec::new();
        {
            let mut fbs = FileBackedStorage::create_with_snarf_size(&path, 4096).unwrap();
            register_types(&mut fbs);
            fbs.begin_transaction().unwrap();
            for i in 0..count {
                ids.push(make_obj(&mut fbs, i as i64));
            }
            fbs.end_transaction().unwrap();
            fbs.checkpoint().unwrap();
        }
        {
            let mut fbs = FileBackedStorage::open(&path).unwrap();
            register_types(&mut fbs);
            assert_eq!(fbs.object_count(), count);
            for (i, id) in ids.iter().enumerate() {
                let obj = fbs.fetch(id).unwrap().unwrap();
                assert_eq!(obj.as_any().downcast_ref::<TestObj>().unwrap().value, i as i64);
            }
        }
    }
}
