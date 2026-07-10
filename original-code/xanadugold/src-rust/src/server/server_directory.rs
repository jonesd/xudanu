use std::collections::HashMap;
use std::path::Path;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DirectoryEntry {
    pub server_id: u64,
    pub address: String,
    pub port: Option<u16>,
    pub verifying_key: String,
    pub pinned_key: Option<String>,
    pub supports_https: Option<bool>,
    pub name: String,
    pub description: String,
    pub trusted: bool,
    pub discovered: String,
    pub referred_by: Option<u64>,
    pub last_seen: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerDirectory {
    pub servers: HashMap<String, DirectoryEntry>,
}

impl Default for ServerDirectory {
    fn default() -> Self {
        ServerDirectory {
            servers: HashMap::new(),
        }
    }
}

impl ServerDirectory {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add(&mut self, entry: DirectoryEntry) {
        let key = entry.server_id.to_string();
        self.servers.insert(key, entry);
    }

    pub fn remove(&mut self, server_id: u64) -> bool {
        self.servers.remove(&server_id.to_string()).is_some()
    }

    pub fn get(&self, server_id: u64) -> Option<&DirectoryEntry> {
        self.servers.get(&server_id.to_string())
    }

    pub fn get_mut(&mut self, server_id: u64) -> Option<&mut DirectoryEntry> {
        self.servers.get_mut(&server_id.to_string())
    }

    pub fn set_trust(&mut self, server_id: u64, trusted: bool) -> bool {
        if let Some(entry) = self.get_mut(server_id) {
            entry.trusted = trusted;
            true
        } else {
            false
        }
    }

    pub fn list(&self) -> Vec<&DirectoryEntry> {
        let mut entries: Vec<&DirectoryEntry> = self.servers.values().collect();
        entries.sort_by_key(|e| e.server_id);
        entries
    }

    pub fn trusted_servers(&self) -> Vec<&DirectoryEntry> {
        self.servers.values().filter(|e| e.trusted).collect()
    }

    pub fn resolve_address(&self, server_id: u64) -> Option<String> {
        let entry = self.get(server_id)?;
        let port = entry.port.unwrap_or(8080);
        if entry.address.starts_with("http") {
            Some(format!("{}", entry.address))
        } else {
            Some(format!("http://{}:{}", entry.address, port))
        }
    }

    pub fn save_to_file(&self, path: &Path) -> std::io::Result<()> {
        let json = serde_json::to_string_pretty(self)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        let tmp = path.with_extension("tmp");
        std::fs::write(&tmp, json)?;
        std::fs::rename(&tmp, path)
    }

    pub fn load_from_file(path: &Path) -> Result<Self, Box<dyn std::error::Error>> {
        if !path.exists() {
            return Ok(Self::new());
        }
        let json = std::fs::read_to_string(path)?;
        let dir: ServerDirectory = serde_json::from_str(&json)?;
        Ok(dir)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn add_and_get() {
        let mut dir = ServerDirectory::new();
        dir.add(DirectoryEntry {
            server_id: 2,
            address: "bob.example.com".to_string(),
            port: Some(8080),
            verifying_key: "9a8b7c6d".to_string(),
            name: "Bob".to_string(),
            description: String::new(),
            pinned_key: None,
            supports_https: None,
            trusted: false,
            discovered: "manual".to_string(),
            referred_by: None,
            last_seen: None,
        });
        assert_eq!(dir.get(2).unwrap().name, "Bob");
        assert!(dir.get(99).is_none());
    }

    #[test]
    fn remove() {
        let mut dir = ServerDirectory::new();
        dir.add(DirectoryEntry {
            server_id: 3,
            address: "carol.example.com".to_string(),
            port: None,
            verifying_key: "abc".to_string(),
            name: "Carol".to_string(),
            description: String::new(),
            pinned_key: None,
            supports_https: None,
            trusted: true,
            discovered: "referral".to_string(),
            referred_by: Some(1),
            last_seen: Some(1000),
        });
        assert!(dir.remove(3));
        assert!(!dir.remove(3));
        assert!(dir.get(3).is_none());
    }

    #[test]
    fn set_trust() {
        let mut dir = ServerDirectory::new();
        dir.add(DirectoryEntry {
            server_id: 5,
            address: "dave.example.com".to_string(),
            port: Some(443),
            verifying_key: "def".to_string(),
            name: "Dave".to_string(),
            description: String::new(),
            pinned_key: None,
            supports_https: None,
            trusted: false,
            discovered: "manual".to_string(),
            referred_by: None,
            last_seen: None,
        });
        assert!(dir.set_trust(5, true));
        assert!(dir.get(5).unwrap().trusted);
        assert!(!dir.set_trust(99, true));
    }

    #[test]
    fn resolve_address() {
        let mut dir = ServerDirectory::new();
        dir.add(DirectoryEntry {
            server_id: 7,
            address: "eve.example.com".to_string(),
            port: Some(9000),
            verifying_key: "xyz".to_string(),
            name: "Eve".to_string(),
            description: String::new(),
            pinned_key: None,
            supports_https: None,
            trusted: true,
            discovered: "manual".to_string(),
            referred_by: None,
            last_seen: None,
        });
        assert_eq!(
            dir.resolve_address(7).unwrap(),
            "http://eve.example.com:9000"
        );
        assert!(dir.resolve_address(99).is_none());
    }

    #[test]
    fn resolve_address_https() {
        let mut dir = ServerDirectory::new();
        dir.add(DirectoryEntry {
            server_id: 8,
            address: "https://frank.example.com".to_string(),
            port: None,
            verifying_key: "abc".to_string(),
            name: "Frank".to_string(),
            description: String::new(),
            pinned_key: None,
            supports_https: None,
            trusted: true,
            discovered: "manual".to_string(),
            referred_by: None,
            last_seen: None,
        });
        assert_eq!(dir.resolve_address(8).unwrap(), "https://frank.example.com");
    }

    #[test]
    fn list_sorted_by_id() {
        let mut dir = ServerDirectory::new();
        for id in [5, 1, 3, 2, 4] {
            dir.add(DirectoryEntry {
                server_id: id,
                address: format!("s{}.example.com", id),
                port: None,
                verifying_key: format!("key{}", id),
                name: format!("Server {}", id),
                description: String::new(),
                pinned_key: None,
                supports_https: None,
                trusted: false,
                discovered: "manual".to_string(),
                referred_by: None,
                last_seen: None,
            });
        }
        let list = dir.list();
        let ids: Vec<u64> = list.iter().map(|e| e.server_id).collect();
        assert_eq!(ids, vec![1, 2, 3, 4, 5]);
    }

    #[test]
    fn save_and_load_roundtrip() {
        let tmp =
            std::env::temp_dir().join(format!("xudanu-server-dir-test-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&tmp);
        std::fs::create_dir_all(&tmp).unwrap();

        let path = tmp.join("server_directory.json");
        let mut dir = ServerDirectory::new();
        dir.add(DirectoryEntry {
            server_id: 42,
            address: "test.example.com".to_string(),
            port: Some(8080),
            verifying_key: "deadbeef".to_string(),
            name: "Test".to_string(),
            description: "A test server".to_string(),
            pinned_key: None,
            supports_https: None,
            trusted: true,
            discovered: "manual".to_string(),
            referred_by: None,
            last_seen: Some(999),
        });
        dir.save_to_file(&path).unwrap();

        let loaded = ServerDirectory::load_from_file(&path).unwrap();
        assert_eq!(loaded.get(42).unwrap().name, "Test");
        assert_eq!(loaded.get(42).unwrap().trusted, true);
        assert_eq!(loaded.get(42).unwrap().address, "test.example.com");

        let _ = std::fs::remove_dir_all(&tmp);
    }

    #[test]
    fn load_missing_file_returns_empty() {
        let path = std::path::Path::new("/nonexistent/path/server_directory.json");
        let dir = ServerDirectory::load_from_file(path).unwrap();
        assert!(dir.servers.is_empty());
    }

    #[test]
    fn trusted_servers_filter() {
        let mut dir = ServerDirectory::new();
        for (id, trusted) in [(1, true), (2, false), (3, true)] {
            dir.add(DirectoryEntry {
                server_id: id,
                address: format!("s{}.com", id),
                port: None,
                verifying_key: format!("k{}", id),
                pinned_key: None,
                supports_https: None,
                name: format!("S{}", id),
                description: String::new(),
                trusted,
                discovered: "manual".to_string(),
                referred_by: None,
                last_seen: None,
            });
        }
        let trusted = dir.trusted_servers();
        assert_eq!(trusted.len(), 2);
        let ids: Vec<u64> = trusted.iter().map(|e| e.server_id).collect();
        assert!(ids.contains(&1));
        assert!(ids.contains(&3));
    }
}
