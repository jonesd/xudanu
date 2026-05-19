use std::collections::HashMap;

use super::range_element::RangeElement;
use crate::edition::BeId;

#[derive(Debug, Clone)]
pub struct ContentAddressIndex {
    fingerprint_to_be_id: HashMap<[u8; 32], BeId>,
    be_id_to_fingerprint: HashMap<BeId, [u8; 32]>,
    next_be_id: BeId,
}

#[derive(serde::Serialize, serde::Deserialize)]
struct ContentAddressFile {
    entries: Vec<(String, BeId)>,
    next_be_id: BeId,
}

impl serde::Serialize for ContentAddressIndex {
    fn serialize<S: serde::Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
        let mut entries: Vec<(String, BeId)> = self.fingerprint_to_be_id.iter().map(|(k, v)| {
            (k.iter().map(|b| format!("{:02x}", b)).collect::<String>(), *v)
        }).collect();
        entries.sort_by(|a, b| a.0.cmp(&b.0));
        let file = ContentAddressFile {
            entries,
            next_be_id: self.next_be_id,
        };
        file.serialize(s)
    }
}

impl<'de> serde::Deserialize<'de> for ContentAddressIndex {
    fn deserialize<D: serde::Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
        let file = ContentAddressFile::deserialize(d)?;
        let mut fingerprint_to_be_id = HashMap::new();
        let mut be_id_to_fingerprint = HashMap::new();
        for (hex_str, be_id) in &file.entries {
            if hex_str.len() != 64 {
                return Err(serde::de::Error::custom("content address hash must be 64 hex chars"));
            }
            let mut hash = [0u8; 32];
            for i in 0..32 {
                hash[i] = u8::from_str_radix(&hex_str[i*2..i*2+2], 16)
                    .map_err(|_| serde::de::Error::custom("invalid hex in content address"))?;
            }
            fingerprint_to_be_id.insert(hash, *be_id);
            be_id_to_fingerprint.insert(*be_id, hash);
        }
        Ok(ContentAddressIndex {
            fingerprint_to_be_id,
            be_id_to_fingerprint,
            next_be_id: file.next_be_id,
        })
    }
}

impl ContentAddressIndex {
    pub fn new(start_id: BeId) -> Self {
        ContentAddressIndex {
            fingerprint_to_be_id: HashMap::new(),
            be_id_to_fingerprint: HashMap::new(),
            next_be_id: start_id,
        }
    }

    pub fn intern(&mut self, element: &RangeElement) -> BeId {
        if !element.is_content_addressable() {
            let id = self.next_be_id;
            self.next_be_id += 1;
            return id;
        }
        let fp = element.content_fingerprint();
        if let Some(&existing_id) = self.fingerprint_to_be_id.get(&fp) {
            return existing_id;
        }
        let id = self.next_be_id;
        self.next_be_id += 1;
        self.fingerprint_to_be_id.insert(fp, id);
        self.be_id_to_fingerprint.insert(id, fp);
        id
    }

    pub fn lookup(&self, element: &RangeElement) -> Option<BeId> {
        if !element.is_content_addressable() {
            return None;
        }
        let fp = element.content_fingerprint();
        self.fingerprint_to_be_id.get(&fp).copied()
    }

    pub fn canonical_be_id(&self, element: &RangeElement) -> BeId {
        self.lookup(element).unwrap_or_else(|| {
            let mut idx = ContentAddressIndex::new(0);
            idx.intern(element)
        })
    }

    pub fn intern_edition_elements(&mut self, edition: &super::Edition) -> Vec<(i64, BeId)> {
        let entries = edition.fetch_all();
        let mut result = Vec::with_capacity(entries.len());
        for (pos, carrier) in &entries {
            let be_id = self.intern(&carrier.element);
            result.push((*pos, be_id));
        }
        result
    }

    pub fn fingerprint_count(&self) -> usize {
        self.fingerprint_to_be_id.len()
    }

    pub fn contains(&self, element: &RangeElement) -> bool {
        if !element.is_content_addressable() {
            return false;
        }
        let fp = element.content_fingerprint();
        self.fingerprint_to_be_id.contains_key(&fp)
    }
}

impl Default for ContentAddressIndex {
    fn default() -> Self {
        Self::new(1_000_000)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn same_text_gets_same_be_id() {
        let mut idx = ContentAddressIndex::new(100);
        let a = idx.intern(&RangeElement::text("hello"));
        let b = idx.intern(&RangeElement::text("hello"));
        assert_eq!(a, b);
    }

    #[test]
    fn different_text_gets_different_be_id() {
        let mut idx = ContentAddressIndex::new(100);
        let a = idx.intern(&RangeElement::text("hello"));
        let b = idx.intern(&RangeElement::text("world"));
        assert_ne!(a, b);
    }

    #[test]
    fn same_data_gets_same_be_id() {
        let mut idx = ContentAddressIndex::new(100);
        let a = idx.intern(&RangeElement::data(vec![1, 2, 3]));
        let b = idx.intern(&RangeElement::data(vec![1, 2, 3]));
        assert_eq!(a, b);
    }

    #[test]
    fn non_content_addressable_gets_unique_ids() {
        let mut idx = ContentAddressIndex::new(100);
        let a = idx.intern(&RangeElement::edition(42));
        let b = idx.intern(&RangeElement::edition(42));
        assert_ne!(a, b, "Edition elements should get unique BeIds");
    }

    #[test]
    fn lookup_finds_interned() {
        let mut idx = ContentAddressIndex::new(100);
        idx.intern(&RangeElement::text("hello"));
        assert!(idx.lookup(&RangeElement::text("hello")).is_some());
        assert!(idx.lookup(&RangeElement::text("world")).is_none());
    }

    #[test]
    fn contains_check() {
        let mut idx = ContentAddressIndex::new(100);
        assert!(!idx.contains(&RangeElement::text("hello")));
        idx.intern(&RangeElement::text("hello"));
        assert!(idx.contains(&RangeElement::text("hello")));
    }

    #[test]
    fn fingerprint_count() {
        let mut idx = ContentAddressIndex::new(100);
        assert_eq!(idx.fingerprint_count(), 0);
        idx.intern(&RangeElement::text("hello"));
        assert_eq!(idx.fingerprint_count(), 1);
        idx.intern(&RangeElement::text("hello"));
        assert_eq!(idx.fingerprint_count(), 1);
        idx.intern(&RangeElement::text("world"));
        assert_eq!(idx.fingerprint_count(), 2);
    }

    #[test]
    fn intern_edition_elements() {
        use crate::edition::Edition;
        let mut idx = ContentAddressIndex::new(100);
        let ed = Edition::from_text("hello world");
        let bindings = idx.intern_edition_elements(&ed);
        assert_eq!(bindings.len(), 11);
        assert_eq!(idx.fingerprint_count(), 8);
    }

    #[test]
    fn cross_edition_dedup() {
        use crate::edition::Edition;
        let mut idx = ContentAddressIndex::new(100);
        let ed1 = Edition::from_text("abc");
        idx.intern_edition_elements(&ed1);
        let ed2 = Edition::from_text("xbc");
        let bindings2 = idx.intern_edition_elements(&ed2);
        assert_eq!(idx.fingerprint_count(), 4);
        let id_b_ed1 = idx.lookup(&RangeElement::text("b")).unwrap();
        let id_b_ed2 = bindings2.iter().find(|(p, _)| *p == 1).unwrap().1;
        assert_eq!(id_b_ed1, id_b_ed2, "'b' should share the same canonical BeId across editions");
    }
}
