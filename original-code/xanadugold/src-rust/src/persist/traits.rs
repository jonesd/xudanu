use std::any::Any;
use std::collections::HashMap;
use std::fmt;

use super::engine::StorageError;
use super::persistent::{FlockId, FlockInfo, FlockLocation};

pub trait Persistent: fmt::Debug + Send + Sync + 'static {
    fn flock_id(&self) -> FlockId;
    fn set_flock_id(&mut self, id: FlockId);

    fn flock_info(&self) -> Option<&FlockInfo>;
    fn set_flock_info(&mut self, info: Option<FlockInfo>);
    fn flock_info_mut(&mut self) -> Option<&mut FlockInfo>;

    fn is_persistent(&self) -> bool {
        self.flock_info().is_some()
    }

    fn mark_dirty(&mut self) {
        if let Some(ref mut info) = self.flock_info_mut() {
            info.mark_dirty();
        }
    }

    fn as_any(&self) -> &dyn Any;
    fn as_any_mut(&mut self) -> &mut dyn Any;

    fn clone_boxed(&self) -> Box<dyn Persistent>;

    fn type_tag(&self) -> &'static str;
    fn to_bytes(&self) -> Result<Vec<u8>, StorageError>;
}

#[derive(Debug, Clone)]
pub struct PersistentRef<T: Persistent> {
    flock_id: FlockId,
    location: Option<FlockLocation>,
    _marker: std::marker::PhantomData<T>,
}

impl<T: Persistent> PersistentRef<T> {
    pub fn new(target: &T) -> Self {
        let info = target.flock_info();
        PersistentRef {
            flock_id: target.flock_id(),
            location: info.and_then(|i| i.location.clone()),
            _marker: std::marker::PhantomData,
        }
    }

    pub fn from_flock_id(flock_id: FlockId) -> Self {
        PersistentRef {
            flock_id,
            location: None,
            _marker: std::marker::PhantomData,
        }
    }

    pub fn from_flock_id_with_location(flock_id: FlockId, location: FlockLocation) -> Self {
        PersistentRef {
            flock_id,
            location: Some(location),
            _marker: std::marker::PhantomData,
        }
    }

    pub fn flock_id(&self) -> FlockId {
        self.flock_id
    }

    pub fn location(&self) -> Option<&FlockLocation> {
        self.location.as_ref()
    }

    pub fn resolve<'a>(&self, registry: &'a PersistentRegistry) -> Option<&'a T> {
        registry.get(&self.flock_id)
    }
}

impl<T: Persistent> PartialEq for PersistentRef<T> {
    fn eq(&self, other: &Self) -> bool {
        self.flock_id == other.flock_id
    }
}

impl<T: Persistent> Eq for PersistentRef<T> {}

impl<T: Persistent> std::hash::Hash for PersistentRef<T> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.flock_id.hash(state);
    }
}

#[cfg(feature = "serde")]
impl<T: Persistent> serde::Serialize for PersistentRef<T> {
    fn serialize<S: serde::Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        use serde::ser::SerializeStruct;
        let mut s = serializer.serialize_struct("PersistentRef", 3)?;
        s.serialize_field("hash", &self.flock_id.hash)?;
        s.serialize_field("token", &self.flock_id.token)?;
        s.serialize_field("location", &self.location)?;
        s.end()
    }
}

#[cfg(feature = "serde")]
impl<'de, T: Persistent> serde::Deserialize<'de> for PersistentRef<T> {
    fn deserialize<D: serde::Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        #[derive(serde::Deserialize)]
        struct RefData {
            hash: u64,
            token: u32,
            location: Option<FlockLocation>,
        }

        let data = RefData::deserialize(deserializer)?;
        Ok(PersistentRef {
            flock_id: FlockId::new(data.hash, data.token),
            location: data.location,
            _marker: std::marker::PhantomData,
        })
    }
}

pub struct PersistentRegistry {
    objects: HashMap<FlockId, Box<dyn Persistent>>,
    by_token: HashMap<u32, FlockId>,
}

impl fmt::Debug for PersistentRegistry {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("PersistentRegistry")
            .field("count", &self.objects.len())
            .finish()
    }
}

impl PersistentRegistry {
    pub fn new() -> Self {
        PersistentRegistry {
            objects: HashMap::new(),
            by_token: HashMap::new(),
        }
    }

    pub fn register(&mut self, obj: Box<dyn Persistent>) {
        let id = obj.flock_id();
        self.by_token.insert(id.token, id);
        self.objects.insert(id, obj);
    }

    pub fn unregister(&mut self, flock_id: &FlockId) {
        self.objects.remove(flock_id);
        self.by_token.remove(&flock_id.token);
    }

    pub fn get<T: Persistent>(&self, flock_id: &FlockId) -> Option<&T> {
        self.objects.get(flock_id)?.as_any().downcast_ref::<T>()
    }

    pub fn get_dyn(&self, flock_id: &FlockId) -> Option<&dyn Persistent> {
        self.objects.get(flock_id).map(|b| b.as_ref())
    }

    pub fn get_mut<T: Persistent>(&mut self, flock_id: &FlockId) -> Option<&mut T> {
        self.objects
            .get_mut(flock_id)?
            .as_any_mut()
            .downcast_mut::<T>()
    }

    pub fn contains(&self, flock_id: &FlockId) -> bool {
        self.objects.contains_key(flock_id)
    }

    pub fn len(&self) -> usize {
        self.objects.len()
    }

    pub fn is_empty(&self) -> bool {
        self.objects.is_empty()
    }

    pub fn flock_ids(&self) -> Vec<FlockId> {
        self.objects.keys().copied().collect()
    }
}

impl Default for PersistentRegistry {
    fn default() -> Self {
        Self::new()
    }
}

pub type DeserializerFn = fn(&[u8], FlockId) -> Result<Box<dyn Persistent>, StorageError>;

pub struct TypeRegistry {
    deserializers: HashMap<&'static str, DeserializerFn>,
}

impl TypeRegistry {
    pub fn new() -> Self {
        TypeRegistry {
            deserializers: HashMap::new(),
        }
    }

    pub fn register(&mut self, type_tag: &'static str, deserializer: DeserializerFn) {
        self.deserializers.insert(type_tag, deserializer);
    }

    pub fn deserialize(
        &self,
        type_tag: &str,
        data: &[u8],
        flock_id: FlockId,
    ) -> Result<Box<dyn Persistent>, StorageError> {
        let deserializer = self
            .deserializers
            .get(type_tag)
            .ok_or_else(|| StorageError::CorruptData(format!("unknown type tag: {}", type_tag)))?;
        deserializer(data, flock_id)
    }

    pub fn contains(&self, type_tag: &str) -> bool {
        self.deserializers.contains_key(type_tag)
    }
}

impl Default for TypeRegistry {
    fn default() -> Self {
        Self::new()
    }
}

impl fmt::Debug for TypeRegistry {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("TypeRegistry")
            .field("types", &self.deserializers.keys().collect::<Vec<_>>())
            .finish()
    }
}

pub fn encode_flock(type_tag: &str, payload: &[u8]) -> Vec<u8> {
    let tag_bytes = type_tag.as_bytes();
    let tag_len = tag_bytes.len() as u16;
    let mut buf = Vec::with_capacity(2 + tag_bytes.len() + payload.len());
    buf.extend_from_slice(&tag_len.to_le_bytes());
    buf.extend_from_slice(tag_bytes);
    buf.extend_from_slice(payload);
    buf
}

pub fn decode_flock(data: &[u8]) -> Result<(&str, &[u8]), StorageError> {
    if data.len() < 2 {
        return Err(StorageError::CorruptData("flock data too short".into()));
    }
    let tag_len = u16::from_le_bytes([data[0], data[1]]) as usize;
    if data.len() < 2 + tag_len {
        return Err(StorageError::CorruptData("flock data truncated tag".into()));
    }
    let tag = std::str::from_utf8(&data[2..2 + tag_len])
        .map_err(|e| StorageError::CorruptData(format!("invalid type tag utf8: {}", e)))?;
    let payload = &data[2 + tag_len..];
    Ok((tag, payload))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_flock_id(hash: u64, token: u32) -> FlockId {
        FlockId::new(hash, token)
    }

    #[derive(Debug)]
    struct StubPersistent {
        flock_id: FlockId,
        info: Option<FlockInfo>,
    }

    impl Persistent for StubPersistent {
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
            Box::new(StubPersistent {
                flock_id: self.flock_id,
                info: self.info.clone(),
            })
        }
        fn type_tag(&self) -> &'static str {
            "StubPersistent"
        }
        fn to_bytes(&self) -> Result<Vec<u8>, StorageError> {
            Ok(vec![])
        }
    }

    #[test]
    fn persistent_ref_eq() {
        let id = make_flock_id(42, 1);
        let r1: PersistentRef<StubPersistent> = PersistentRef::from_flock_id(id);
        let r2: PersistentRef<StubPersistent> = PersistentRef::from_flock_id(id);
        assert_eq!(r1, r2);
    }

    #[test]
    fn persistent_ref_neq() {
        let r1: PersistentRef<StubPersistent> = PersistentRef::from_flock_id(make_flock_id(1, 0));
        let r2: PersistentRef<StubPersistent> = PersistentRef::from_flock_id(make_flock_id(2, 0));
        assert_ne!(r1, r2);
    }

    #[test]
    fn persistent_ref_hashable() {
        use std::collections::HashSet;
        let id = make_flock_id(42, 1);
        let mut set = HashSet::new();
        set.insert(PersistentRef::<StubPersistent>::from_flock_id(id));
        set.insert(PersistentRef::<StubPersistent>::from_flock_id(id));
        assert_eq!(set.len(), 1);
    }

    #[test]
    fn registry_register_get() {
        let mut reg = PersistentRegistry::new();
        let id = make_flock_id(1, 0);
        reg.register(Box::new(StubPersistent {
            flock_id: id,
            info: None,
        }));
        assert!(reg.contains(&id));
        assert_eq!(reg.len(), 1);
    }

    #[test]
    fn registry_unregister() {
        let mut reg = PersistentRegistry::new();
        let id = make_flock_id(1, 0);
        reg.register(Box::new(StubPersistent {
            flock_id: id,
            info: None,
        }));
        reg.unregister(&id);
        assert!(!reg.contains(&id));
        assert!(reg.is_empty());
    }

    #[test]
    fn registry_get_typed() {
        let mut reg = PersistentRegistry::new();
        let id = make_flock_id(1, 0);
        reg.register(Box::new(StubPersistent {
            flock_id: id,
            info: None,
        }));
        let got: Option<&StubPersistent> = reg.get(&id);
        assert!(got.is_some());
        assert_eq!(got.unwrap().flock_id, id);
    }

    #[test]
    fn registry_get_mut_typed() {
        let mut reg = PersistentRegistry::new();
        let id = make_flock_id(1, 0);
        reg.register(Box::new(StubPersistent {
            flock_id: id,
            info: None,
        }));
        let got: Option<&mut StubPersistent> = reg.get_mut(&id);
        assert!(got.is_some());
    }

    #[test]
    fn registry_flock_ids() {
        let mut reg = PersistentRegistry::new();
        let id1 = make_flock_id(1, 0);
        let id2 = make_flock_id(2, 1);
        reg.register(Box::new(StubPersistent {
            flock_id: id1,
            info: None,
        }));
        reg.register(Box::new(StubPersistent {
            flock_id: id2,
            info: None,
        }));
        let mut ids = reg.flock_ids();
        ids.sort();
        assert_eq!(ids, vec![id1, id2]);
    }

    #[test]
    fn encode_decode_roundtrip() {
        let encoded = encode_flock("Counter", &[1, 2, 3]);
        let (tag, payload) = decode_flock(&encoded).unwrap();
        assert_eq!(tag, "Counter");
        assert_eq!(payload, &[1, 2, 3]);
    }

    #[test]
    fn decode_too_short() {
        assert!(decode_flock(&[1]).is_err());
    }

    #[test]
    fn type_registry_register_deserialize() {
        let mut reg = TypeRegistry::new();
        reg.register("StubPersistent", |_data, flock_id| {
            Ok(Box::new(StubPersistent {
                flock_id,
                info: None,
            }))
        });
        assert!(reg.contains("StubPersistent"));
        let id = make_flock_id(42, 7);
        let obj = reg.deserialize("StubPersistent", &[], id).unwrap();
        assert_eq!(obj.flock_id(), id);
    }

    #[test]
    fn type_registry_unknown_tag() {
        let reg = TypeRegistry::new();
        assert!(reg
            .deserialize("Unknown", &[], make_flock_id(1, 0))
            .is_err());
    }
}
