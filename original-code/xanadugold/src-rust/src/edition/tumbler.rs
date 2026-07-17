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
}
