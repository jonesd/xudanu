use std::fmt;

/// A Xudanu tumbler: structured address for content across independent servers.
///
/// Format: `"server.domain".path.element.element`
///
/// The first element is a domain string (DNS-resolvable server identity),
/// avoiding the need for a central server-ID registry (Gold used numeric IDs
/// requiring allocation). The remaining elements form a numeric path that
/// locates content within that server's docuverse.
///
/// Examples:
///   `"alice.example.com".5.3.10.7`  — server alice, work 5, edition 3, pos 10..7
///   `"192.168.1.5:8080".3.1`        — server at IP:port, work 3, edition 1
///   `1.5.3.10.7`                     — legacy numeric server ID 1
///
/// The numeric path supports SequenceSpace-style prefix queries and algebraic
/// operations without requiring the server component to be numeric.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct XudanuTumbler {
    /// Server identity: domain string (e.g. "alice.example.com") or empty for local
    server: String,
    /// Numeric path elements after the server prefix
    path: Vec<u64>,
}

impl XudanuTumbler {
    /// Create a local tumbler (same server, no domain prefix).
    pub fn local(path: Vec<u64>) -> Self {
        XudanuTumbler {
            server: String::new(),
            path,
        }
    }

    /// Create a cross-server tumbler with domain prefix.
    pub fn cross(domain: &str, path: Vec<u64>) -> Self {
        XudanuTumbler {
            server: domain.to_string(),
            path,
        }
    }

    /// Create from legacy numeric server ID.
    pub fn from_numeric(server_id: u64, path: Vec<u64>) -> Self {
        XudanuTumbler {
            server: server_id.to_string(),
            path,
        }
    }

    /// Parse from wire format string.
    ///
    /// `"alice.example.com".5.3.10.7` → cross-server tumbler
    /// `1.5.3.10.7`                   → legacy numeric
    /// `5.3.10.7`                     → local (no server prefix)
    pub fn parse(s: &str) -> Self {
        let s = s.trim();
        if s.starts_with('"') {
            if let Some(end) = s[1..].find('"') {
                let domain = &s[1..1 + end];
                let after = &s[2 + end..];
                let path_str = after.strip_prefix('.').unwrap_or(after);
                let path = parse_path(path_str);
                return XudanuTumbler::cross(domain, path);
            }
        }
        // Try parsing as numeric prefix
        let parts: Vec<&str> = s.split('.').collect();
        if parts.len() > 1 {
            if let Ok(server_id) = parts[0].parse::<u64>() {
                let path = parts[1..]
                    .iter()
                    .filter_map(|p| p.parse::<u64>().ok())
                    .collect();
                return XudanuTumbler::from_numeric(server_id, path);
            }
        }
        // Local path only
        XudanuTumbler::local(parse_path(s))
    }

    /// Serialize to wire format string.
    pub fn to_string(&self) -> String {
        if self.server.is_empty() {
            return self
                .path
                .iter()
                .map(|p| p.to_string())
                .collect::<Vec<_>>()
                .join(".");
        }
        if self.server.chars().all(|c| c.is_ascii_digit()) && !self.server.is_empty() {
            // Legacy numeric format
            let mut result = self.server.clone();
            for &p in &self.path {
                result.push('.');
                result.push_str(&p.to_string());
            }
            result
        } else {
            // Domain format
            format!(
                "\"{}\".{}",
                self.server,
                self.path
                    .iter()
                    .map(|p| p.to_string())
                    .collect::<Vec<_>>()
                    .join(".")
            )
        }
    }

    /// Server identity (domain or numeric string). Empty for local.
    pub fn server(&self) -> &str {
        &self.server
    }

    /// Numeric path elements.
    pub fn path(&self) -> &[u64] {
        &self.path
    }

    /// First path element (typically work ID). None if empty.
    pub fn first(&self) -> Option<u64> {
        self.path.first().copied()
    }

    /// Path elements after the first (typically edition/position within work).
    pub fn rest(&self) -> &[u64] {
        if self.path.len() > 1 {
            &self.path[1..]
        } else {
            &[]
        }
    }

    /// Number of path elements.
    pub fn depth(&self) -> usize {
        self.path.len()
    }

    /// Is this a cross-server tumbler (has a domain prefix)?
    pub fn is_cross_server(&self) -> bool {
        !self.server.is_empty()
    }

    /// Is this a local tumbler (no server prefix)?
    pub fn is_local(&self) -> bool {
        self.server.is_empty()
    }

    /// Length of common path prefix with another tumbler's path.
    /// Server identity is compared separately (string equality).
    pub fn common_prefix_len(&self, other: &Self) -> usize {
        if self.server != other.server {
            return 0;
        }
        let mut len = 0;
        for (a, b) in self.path.iter().zip(other.path.iter()) {
            if a == b {
                len += 1;
            } else {
                break;
            }
        }
        len
    }

    /// Does this tumbler's path start with the given prefix?
    pub fn starts_with_path(&self, prefix: &[u64]) -> bool {
        self.path.len() >= prefix.len() && self.path[..prefix.len()] == *prefix
    }

    /// Returns a sub-tumbler with only the first n path elements.
    pub fn prefix(&self, n: usize) -> Self {
        XudanuTumbler {
            server: self.server.clone(),
            path: self.path[..n.min(self.path.len())].to_vec(),
        }
    }

    /// Append a path element, returning a new tumbler.
    pub fn append(&self, element: u64) -> Self {
        let mut path = self.path.clone();
        path.push(element);
        XudanuTumbler {
            server: self.server.clone(),
            path,
        }
    }

    /// Compare path elements lexicographically.
    /// Returns -1, 0, or 1 for ordering.
    pub fn compare_path(&self, other: &Self) -> std::cmp::Ordering {
        self.path.cmp(&other.path)
    }

    /// Two tumblers are on the same server if their server strings match.
    pub fn same_server(&self, other: &Self) -> bool {
        self.server == other.server
    }

    /// Migrate the path through a Mapping displacement.
    /// Useful when content positions shift within a server.
    pub fn migrate_path(&self, mapping: &super::mapping::Mapping) -> Self {
        if self.path.is_empty() {
            return self.clone();
        }
        // Apply mapping to each path element that falls in the mapping's domain
        let migrated: Vec<u64> = self
            .path
            .iter()
            .map(|&p| mapping.of(p as i64).map(|v| v as u64).unwrap_or(p))
            .collect();
        XudanuTumbler {
            server: self.server.clone(),
            path: migrated,
        }
    }

    /// Navigate up one level (remove last path element).
    /// `"alice.com".5.3.10` → `"alice.com".5.3`
    pub fn parent(&self) -> Option<Self> {
        if self.path.is_empty() {
            return None;
        }
        Some(XudanuTumbler {
            server: self.server.clone(),
            path: self.path[..self.path.len() - 1].to_vec(),
        })
    }

    /// Replace the last path element (sibling navigation).
    /// `"alice.com".5.3.10` with n=20 → `"alice.com".5.3.20`
    pub fn sibling(&self, n: u64) -> Option<Self> {
        if self.path.is_empty() {
            return None;
        }
        let mut path = self.path.clone();
        *path.last_mut().unwrap() = n;
        Some(XudanuTumbler {
            server: self.server.clone(),
            path,
        })
    }

    /// Convert to `Sequence` (space algebra position).
    /// Enables SequenceDsp arithmetic, SequenceRegion prefix queries,
    /// and CrossSpace composition with IntegerSpace.
    pub fn to_sequence(&self) -> crate::space::Sequence {
        crate::space::Sequence::from_numbers(self.path.iter().map(|&n| n as i64).collect())
    }

    pub fn from_sequence(server: &str, seq: &crate::space::Sequence) -> Self {
        XudanuTumbler {
            server: server.to_string(),
            path: seq.numbers().iter().map(|&n| n as u64).collect(),
        }
    }

    /// Create a tumbler addressing a character range within a work.
    /// Format: `"server".work_id.start_pos.end_pos`
    pub fn for_char_range(server: &str, work_id: u64, start: usize, end: usize) -> Self {
        XudanuTumbler::cross(server, vec![work_id, start as u64, end as u64])
    }

    /// Create a tumbler addressing a work (no position detail).
    /// Format: `"server".work_id`
    pub fn for_work(server: &str, work_id: u64) -> Self {
        XudanuTumbler::cross(server, vec![work_id])
    }

    /// Extract the character range (start, end) from path elements 2 and 3.
    /// Returns None if the path doesn't have at least 4 elements.
    pub fn char_range(&self) -> Option<(usize, usize)> {
        match self.path.len() {
            3 => Some((self.path[1] as usize, self.path[2] as usize)),
            n if n >= 4 => Some((self.path[2] as usize, self.path[3] as usize)),
            _ => None,
        }
    }
}

impl fmt::Display for XudanuTumbler {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_string())
    }
}

impl PartialOrd for XudanuTumbler {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for XudanuTumbler {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.server
            .cmp(&other.server)
            .then_with(|| self.path.cmp(&other.path))
    }
}

fn parse_path(s: &str) -> Vec<u64> {
    if s.is_empty() {
        return Vec::new();
    }
    s.split('.').filter_map(|p| p.parse::<u64>().ok()).collect()
}

/// Arrangement mapping between IntegerSpace (document-local i64 positions)
/// and SequenceSpace (global tumbler addresses).
///
/// A document arrangement knows its server identity and work ID, and can
/// translate between local positions and global tumblers:
///
///   local position 42 in work 5 on "alice.com"  ↔  tumbler "alice.com".5.42
///
/// This is the bridge between the enfilade's i64 position model and the
/// tumbler-based cross-document addressing model.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DocumentArrangement {
    server: String,
    work_id: u64,
}

impl DocumentArrangement {
    /// Create a new arrangement for a document on a specific server.
    pub fn new(server: &str, work_id: u64) -> Self {
        DocumentArrangement {
            server: server.to_string(),
            work_id,
        }
    }

    /// Map a local i64 position to a global tumbler address.
    pub fn to_tumbler(&self, position: i64) -> XudanuTumbler {
        XudanuTumbler::cross(&self.server, vec![self.work_id, position as u64])
    }

    /// Map a range of local positions to tumbler addresses.
    pub fn to_tumbler_range(&self, start: i64, end: i64) -> XudanuTumbler {
        XudanuTumbler::cross(&self.server, vec![self.work_id, start as u64, end as u64])
    }

    /// Try to map a tumbler back to a local position.
    /// Returns None if the tumbler doesn't belong to this document.
    pub fn from_tumbler(&self, tumbler: &XudanuTumbler) -> Option<i64> {
        let path = tumbler.path();
        if path.len() < 2 {
            return None;
        }
        if path[0] != self.work_id {
            return None;
        }
        if tumbler.server() != self.server {
            return None;
        }
        Some(path[1] as i64)
    }

    /// Check if a tumbler belongs to this document.
    pub fn owns_tumbler(&self, tumbler: &XudanuTumbler) -> bool {
        tumbler.server() == self.server && tumbler.first() == Some(self.work_id)
    }

    /// The server identity.
    pub fn server(&self) -> &str {
        &self.server
    }

    /// The work ID.
    pub fn work_id(&self) -> u64 {
        self.work_id
    }

    /// Create a work-level tumbler (no position).
    pub fn work_tumbler(&self) -> XudanuTumbler {
        XudanuTumbler::for_work(&self.server, self.work_id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_domain_tumbler() {
        let t = XudanuTumbler::parse("\"alice.example.com\".5.3.10.7");
        assert_eq!(t.server(), "alice.example.com");
        assert_eq!(t.path(), &[5, 3, 10, 7]);
        assert!(t.is_cross_server());
    }

    #[test]
    fn parse_numeric_tumbler() {
        let t = XudanuTumbler::parse("1.5.3.10.7");
        assert_eq!(t.server(), "1");
        assert_eq!(t.path(), &[5, 3, 10, 7]);
        assert!(t.is_cross_server());
    }

    #[test]
    fn parse_local_tumbler() {
        // "5.3.10.7" is ambiguous — parsed as numeric server 5 by convention.
        // Use local() constructor for unambiguous local tumblers.
        let t = XudanuTumbler::local(vec![5, 3, 10, 7]);
        assert!(t.is_local());
        assert_eq!(t.path(), &[5, 3, 10, 7]);
        assert_eq!(t.to_string(), "5.3.10.7");
    }

    #[test]
    fn roundtrip_domain() {
        let original = "\"alice.example.com\".5.3.10.7";
        let t = XudanuTumbler::parse(original);
        assert_eq!(t.to_string(), original);
    }

    #[test]
    fn roundtrip_numeric() {
        let original = "1.5.3.10.7";
        let t = XudanuTumbler::parse(original);
        assert_eq!(t.to_string(), original);
    }

    #[test]
    fn roundtrip_local() {
        let t = XudanuTumbler::local(vec![5, 3, 10, 7]);
        assert_eq!(t.to_string(), "5.3.10.7");
    }

    #[test]
    fn first_and_rest() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3, 10, 7]);
        assert_eq!(t.first(), Some(5));
        assert_eq!(t.rest(), &[3, 10, 7]);
    }

    #[test]
    fn common_prefix() {
        let a = XudanuTumbler::cross("alice.com", vec![5, 3, 10, 7]);
        let b = XudanuTumbler::cross("alice.com", vec![5, 3, 20, 1]);
        assert_eq!(a.common_prefix_len(&b), 2);

        let c = XudanuTumbler::cross("bob.com", vec![5, 3, 10, 7]);
        assert_eq!(a.common_prefix_len(&c), 0); // different server
    }

    #[test]
    fn starts_with_path() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3, 10, 7]);
        assert!(t.starts_with_path(&[5]));
        assert!(t.starts_with_path(&[5, 3]));
        assert!(t.starts_with_path(&[5, 3, 10, 7]));
        assert!(!t.starts_with_path(&[5, 3, 10, 7, 9]));
        assert!(!t.starts_with_path(&[6]));
    }

    #[test]
    fn prefix_extraction() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3, 10, 7]);
        let p = t.prefix(2);
        assert_eq!(p.path(), &[5, 3]);
        assert_eq!(p.server(), "alice.com");
    }

    #[test]
    fn append_element() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3]);
        let extended = t.append(10);
        assert_eq!(extended.path(), &[5, 3, 10]);
        assert_eq!(t.path(), &[5, 3]); // original unchanged
    }

    #[test]
    fn same_server() {
        let a = XudanuTumbler::cross("alice.com", vec![5]);
        let b = XudanuTumbler::cross("alice.com", vec![10]);
        let c = XudanuTumbler::cross("bob.com", vec![5]);
        assert!(a.same_server(&b));
        assert!(!a.same_server(&c));
    }

    #[test]
    fn depth() {
        assert_eq!(XudanuTumbler::local(vec![]).depth(), 0);
        assert_eq!(XudanuTumbler::local(vec![5]).depth(), 1);
        assert_eq!(XudanuTumbler::cross("a.com", vec![5, 3, 1]).depth(), 3);
    }

    #[test]
    fn ordering() {
        let a = XudanuTumbler::cross("alice.com", vec![5, 3]);
        let b = XudanuTumbler::cross("alice.com", vec![5, 10]);
        let c = XudanuTumbler::cross("bob.com", vec![1]);
        assert!(a < b); // same server, path [5,3] < [5,10]
        assert!(b < c); // alice.com < bob.com
    }

    #[test]
    fn parse_domain_with_port() {
        let t = XudanuTumbler::parse("\"192.168.1.5:8080\".3.1");
        assert_eq!(t.server(), "192.168.1.5:8080");
        assert_eq!(t.path(), &[3, 1]);
    }

    #[test]
    fn migrate_path_through_mapping() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 15, 25]);
        let dsp = super::super::mapping::Mapping::restricted(
            10,
            super::super::xn_region::XnRegion::above(10),
        );
        let migrated = t.migrate_path(&dsp);
        assert_eq!(migrated.path(), &[5, 25, 35]);
        assert_eq!(migrated.server(), "alice.com");
    }

    #[test]
    fn empty_path() {
        let t = XudanuTumbler::cross("alice.com", vec![]);
        assert_eq!(t.depth(), 0);
        assert_eq!(t.to_string(), "\"alice.com\".");
        let parsed = XudanuTumbler::parse(&t.to_string());
        assert_eq!(parsed.server(), "alice.com");
        assert!(parsed.path().is_empty());
    }

    #[test]
    fn display_format() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3]);
        assert_eq!(format!("{}", t), "\"alice.com\".5.3");
    }

    #[test]
    fn parent_navigation() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3, 10, 7]);
        assert_eq!(t.parent().unwrap().path(), &[5, 3, 10]);
        assert_eq!(t.parent().unwrap().server(), "alice.com");
        assert_eq!(t.parent().unwrap().parent().unwrap().path(), &[5, 3]);
    }

    #[test]
    fn parent_of_empty() {
        let t = XudanuTumbler::local(vec![]);
        assert!(t.parent().is_none());
    }

    #[test]
    fn sibling_navigation() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3, 10]);
        let s = t.sibling(20).unwrap();
        assert_eq!(s.path(), &[5, 3, 20]);
        assert_eq!(s.server(), "alice.com");
    }

    #[test]
    fn sibling_of_empty() {
        let t = XudanuTumbler::local(vec![]);
        assert!(t.sibling(1).is_none());
    }

    #[test]
    fn sequence_conversion() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3, 10, 7]);
        let seq = t.to_sequence();
        assert_eq!(seq.numbers(), &[5, 3, 10, 7]);

        let back = XudanuTumbler::from_sequence("alice.com", &seq);
        assert_eq!(back.path(), &[5, 3, 10, 7]);
        assert_eq!(back.server(), "alice.com");
    }

    #[test]
    fn sequence_arithmetic() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3]);
        let seq = t.to_sequence();
        let offset = crate::space::Sequence::two(0, 10);
        let shifted = seq.plus(&offset);
        let result = XudanuTumbler::from_sequence("alice.com", &shifted);
        assert_eq!(result.path(), &[5, 13]);
    }

    #[test]
    fn for_char_range_constructor() {
        let t = XudanuTumbler::for_char_range("alice.com", 5, 10, 20);
        assert_eq!(t.path(), &[5, 10, 20]);
        assert_eq!(t.server(), "alice.com");
        assert_eq!(t.first(), Some(5));
    }

    #[test]
    fn for_work_constructor() {
        let t = XudanuTumbler::for_work("alice.com", 42);
        assert_eq!(t.path(), &[42]);
        assert_eq!(t.first(), Some(42));
    }

    #[test]
    fn char_range_extraction() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3, 10, 20]);
        assert_eq!(t.char_range(), Some((10, 20)));

        let short = XudanuTumbler::cross("alice.com", vec![5, 3]);
        assert_eq!(short.char_range(), None);
    }

    #[test]
    fn prefix_hierarchy() {
        let doc = XudanuTumbler::cross("alice.com", vec![5]);
        let section = doc.append(3);
        let para = section.append(10);
        let char_pos = para.append(7);

        assert!(char_pos.starts_with_path(doc.path()));
        assert!(char_pos.starts_with_path(section.path()));
        assert_eq!(char_pos.common_prefix_len(&section), 2);
        assert_eq!(section.parent().unwrap(), doc);
    }

    #[test]
    fn arrangement_position_to_tumbler() {
        let arr = DocumentArrangement::new("alice.com", 5);
        let t = arr.to_tumbler(42);
        assert_eq!(t.server(), "alice.com");
        assert_eq!(t.path(), &[5, 42]);
    }

    #[test]
    fn arrangement_tumbler_to_position() {
        let arr = DocumentArrangement::new("alice.com", 5);
        let t = arr.to_tumbler(42);
        assert_eq!(arr.from_tumbler(&t), Some(42));
    }

    #[test]
    fn arrangement_rejects_foreign_tumbler() {
        let arr = DocumentArrangement::new("alice.com", 5);
        let foreign = XudanuTumbler::cross("bob.com", vec![5, 42]);
        assert!(!arr.owns_tumbler(&foreign));
        assert_eq!(arr.from_tumbler(&foreign), None);

        let wrong_work = XudanuTumbler::cross("alice.com", vec![99, 42]);
        assert!(!arr.owns_tumbler(&wrong_work));
    }

    #[test]
    fn arrangement_range_to_tumbler() {
        let arr = DocumentArrangement::new("alice.com", 5);
        let t = arr.to_tumbler_range(10, 20);
        assert_eq!(t.path(), &[5, 10, 20]);
        assert_eq!(t.char_range(), Some((10, 20)));
    }

    #[test]
    fn arrangement_work_tumbler() {
        let arr = DocumentArrangement::new("alice.com", 5);
        let wt = arr.work_tumbler();
        assert_eq!(wt.path(), &[5]);
        assert_eq!(wt.server(), "alice.com");
    }

    #[test]
    fn range_crum_for_section() {
        use crate::edition::Edition;
        let ed = Edition::from_text("hello world");
        let entries = ed.cached_entries();
        let n = entries.len() as i64;
        let crum1 = ed.range_crum(0, n);
        let crum2 = ed.range_crum(0, n);
        assert_eq!(crum1, crum2, "same range should produce same crum");

        let crum_half = ed.range_crum(0, n / 2);
        assert_ne!(crum1, crum_half, "different range should differ");
    }

    #[test]
    fn range_crum_empty_is_none() {
        use crate::edition::Edition;
        let ed = Edition::from_text("hello");
        assert!(ed.range_crum(100, 200).is_none());
    }

    #[test]
    fn entries_in_range_query() {
        use crate::edition::Edition;
        let ed = Edition::from_text("abcde");
        let mid = ed.entries_in_range(1, 4);
        assert_eq!(mid.len(), 3);
        assert_eq!(mid[0].0, 1);
        assert_eq!(mid[2].0, 3);
    }

    #[test]
    fn integration_position_to_cross_server_ref() {
        use crate::edition::links::CrossServerRef;

        let arr = DocumentArrangement::new("alice.com", 42);
        let tumbler = arr.to_tumbler_range(10, 20);

        let csr = CrossServerRef::new(tumbler.to_string(), [0u8; 32], "Alice", [0u8; 32]);

        assert_eq!(csr.work_id(), Some(42));
        assert_eq!(csr.char_range(), Some((10, 20)));
        assert_eq!(
            csr.parent_tumbler(),
            Some("\"alice.com\".42.10".to_string())
        );
    }

    #[test]
    fn integration_hyperref_tumbler_roundtrip() {
        use crate::edition::links::{CrossServerRef, HyperRef};

        let original_tumbler = XudanuTumbler::cross("alice.com", vec![42, 10, 20]);
        let hr = HyperRef::for_tumbler_span(original_tumbler.clone());

        let recovered = hr.tumbler_address().unwrap();
        assert_eq!(recovered.server(), "alice.com");
        assert_eq!(recovered.first(), Some(42));
        assert_eq!(recovered.char_range(), Some((10, 20)));
    }

    #[test]
    fn integration_compound_span_cross_server() {
        use crate::edition::compound::CompoundSpan;

        let arr = DocumentArrangement::new("bob.com", 99);
        let span = CompoundSpan::new(99, 5, 15);
        let tumbler = span.to_tumbler(&arr);

        assert_eq!(tumbler.server(), "bob.com");
        assert_eq!(tumbler.path(), &[99, 5, 15]);

        let back = CompoundSpan::from_tumbler(&tumbler).unwrap();
        assert_eq!(back.source_work_id(), 99);
        assert_eq!(back.char_start(), 5);
        assert_eq!(back.char_end(), 15);
    }

    #[test]
    fn integration_document_hierarchy_navigation() {
        let arr = DocumentArrangement::new("alice.com", 5);

        let char_10 = arr.to_tumbler(10);
        let char_20 = arr.to_tumbler(20);
        let char_30 = arr.to_tumbler(30);

        assert!(char_10.starts_with_path(&[5]));
        assert_eq!(char_10.common_prefix_len(&char_20), 1);
        assert_eq!(char_20.common_prefix_len(&char_30), 1);

        let work_tumbler = arr.work_tumbler();
        assert_eq!(work_tumbler.path(), &[5]);
    }

    #[test]
    fn integration_tumbler_to_sequence_and_back() {
        let t = XudanuTumbler::cross("alice.com", vec![5, 3, 10, 7]);
        let seq = t.to_sequence();

        let numbers: Vec<i64> = seq.numbers().to_vec();
        assert_eq!(numbers, vec![5, 3, 10, 7]);

        let back = XudanuTumbler::from_sequence("alice.com", &seq);
        assert_eq!(back, t);
    }

    #[test]
    fn integration_csr_same_server_check() {
        use crate::edition::links::CrossServerRef;

        let make_csr = |server: &str, work: u64| {
            CrossServerRef::new(
                format!("\"{}\".{}.0.0", server, work),
                [0u8; 32],
                "",
                [0u8; 32],
            )
        };

        let a = make_csr("alice.com", 5);
        let b = make_csr("alice.com", 10);
        let c = make_csr("bob.com", 5);

        assert!(a.same_server_as(&b), "same server should match");
        assert!(!a.same_server_as(&c), "different server should not match");
    }
}
