use std::collections::{HashMap, HashSet};
use std::net::SocketAddr;

use serde::{Deserialize, Serialize};

use crate::edition::BeId;

#[derive(Debug, Clone, Hash, Eq, PartialEq, Serialize, Deserialize)]
pub struct FederatedId {
    pub server_id: String,
    pub local_id: u64,
}

impl FederatedId {
    pub fn new(server_id: impl Into<String>, local_id: u64) -> Self {
        FederatedId {
            server_id: server_id.into(),
            local_id,
        }
    }

    pub fn is_local(&self, our_server_id: &str) -> bool {
        self.server_id == our_server_id
    }
}

impl std::fmt::Display for FederatedId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}:{}", self.server_id, self.local_id)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct PeerAddress {
    pub host: String,
    pub port: u16,
}

impl PeerAddress {
    pub fn new(host: impl Into<String>, port: u16) -> Self {
        PeerAddress {
            host: host.into(),
            port,
        }
    }

    pub fn to_socket_addr(&self) -> Result<SocketAddr, String> {
        format!("{}:{}", self.host, self.port)
            .parse()
            .map_err(|e| format!("invalid peer address '{}:{}': {}", self.host, self.port, e))
    }
}

impl std::fmt::Display for PeerAddress {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}:{}", self.host, self.port)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederationConfig {
    pub enabled: bool,
    pub peers: Vec<PeerAddress>,
    #[serde(default = "default_mode")]
    pub mode: FederationMode,
    #[serde(default = "default_min_endorsements")]
    pub min_endorsements: u32,
}

fn default_mode() -> FederationMode {
    FederationMode::Closed
}

fn default_min_endorsements() -> u32 {
    2
}

impl Default for FederationConfig {
    fn default() -> Self {
        FederationConfig {
            enabled: false,
            peers: Vec::new(),
            mode: FederationMode::Closed,
            min_endorsements: 2,
        }
    }
}

impl FederationConfig {
    pub fn closed(peers: Vec<PeerAddress>) -> Self {
        FederationConfig {
            enabled: true,
            peers,
            mode: FederationMode::Closed,
            min_endorsements: 2,
        }
    }

    pub fn disabled() -> Self {
        FederationConfig::default()
    }

    pub fn is_enabled(&self) -> bool {
        self.enabled
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FederationMode {
    Closed,
    Open,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederationPeerInfo {
    pub server_id: String,
    pub address: PeerAddress,
    pub connected: bool,
}

impl FederationPeerInfo {
    pub fn unknown(address: PeerAddress) -> Self {
        FederationPeerInfo {
            server_id: String::new(),
            address,
            connected: false,
        }
    }

    pub fn connected(address: PeerAddress, server_id: String) -> Self {
        FederationPeerInfo {
            server_id,
            address,
            connected: true,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederationInfo {
    pub server_id: String,
    pub federation_domain: String,
    pub key_id: u64,
    pub verifying_key: Vec<u8>,
    pub kex_key: Vec<u8>,
    pub mode: FederationMode,
    pub peers: Vec<FederationPeerInfo>,
    pub work_count: usize,
    pub edition_count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RoyaltyEntry {
    pub origin_server_id: String,
    pub content_fingerprint: [u8; 32],
    pub royalty_type: RoyaltyType,
    pub amount: u64,
    pub timestamp: u64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RoyaltyType {
    Transclusion,
    Reference,
    Access,
    Custom(String),
}

pub struct FederationState {
    config: FederationConfig,
    known_peers: HashSet<String>,
    known_peer_keys: HashSet<String>,
    connected_peers: HashMap<String, String>,
    remote_origins: RemoteOriginRegistry,
    royalty_ledger: Vec<RoyaltyEntry>,
}

impl FederationState {
    pub fn new(config: FederationConfig) -> Self {
        let known_peers: HashSet<String> = config
            .peers
            .iter()
            .map(|p| p.to_string())
            .collect();
        FederationState {
            config,
            known_peers,
            known_peer_keys: HashSet::new(),
            connected_peers: HashMap::new(),
            remote_origins: RemoteOriginRegistry::new(),
            royalty_ledger: Vec::new(),
        }
    }

    pub fn disabled() -> Self {
        FederationState::new(FederationConfig::disabled())
    }

    pub fn config(&self) -> &FederationConfig {
        &self.config
    }

    pub fn is_enabled(&self) -> bool {
        self.config.enabled
    }

    pub fn peer_addresses(&self) -> &[PeerAddress] {
        &self.config.peers
    }

    pub fn known_peers(&self) -> &HashSet<String> {
        &self.known_peers
    }

    pub fn is_peer_known(&self, verifying_key_hex: &str) -> bool {
        if !self.config.enabled {
            return true;
        }
        if self.known_peer_keys.is_empty() {
            return true;
        }
        self.known_peer_keys.contains(verifying_key_hex)
    }

    pub fn register_peer_key(&mut self, verifying_key_hex: String) {
        self.known_peer_keys.insert(verifying_key_hex);
    }

    pub fn mark_peer_connected(&mut self, address: &str, server_id: String) {
        self.connected_peers.insert(address.to_string(), server_id);
    }

    pub fn mark_peer_disconnected(&mut self, address: &str) {
        self.connected_peers.remove(address);
    }

    pub fn peer_server_id(&self, address: &str) -> Option<&str> {
        self.connected_peers.get(address).map(|s| s.as_str())
    }

    pub fn add_peer(&mut self, address: PeerAddress) {
        self.known_peers.insert(address.to_string());
        if !self.config.peers.iter().any(|p| p == &address) {
            self.config.peers.push(address);
        }
    }

    pub fn remove_peer(&mut self, address: &PeerAddress) {
        let key = address.to_string();
        self.known_peers.remove(&key);
        self.config.peers.retain(|p| p != address);
    }

    pub fn record_royalty(&mut self, entry: RoyaltyEntry) {
        self.royalty_ledger.push(entry);
    }

    pub fn royalty_ledger(&self) -> &[RoyaltyEntry] {
        &self.royalty_ledger
    }

    pub fn record_remote_origin(&mut self, fingerprint: [u8; 32], origin: RemoteOrigin) {
        self.remote_origins.record(fingerprint, origin);
    }

    pub fn get_remote_origin(&self, fingerprint: &[u8; 32]) -> Option<&RemoteOrigin> {
        self.remote_origins.get(fingerprint)
    }

    pub fn remote_origins(&self) -> &RemoteOriginRegistry {
        &self.remote_origins
    }

    pub fn remote_origins_mut(&mut self) -> &mut RemoteOriginRegistry {
        &mut self.remote_origins
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncWorkEntry {
    pub origin_server_id: String,
    pub work_id: u64,
    pub edition_payload: crate::server::transport::protocol::EditionPayload,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncEditionEntry {
    pub origin_server_id: String,
    pub edition_id: u64,
    pub edition_payload: crate::server::transport::protocol::EditionPayload,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncBlobEntry {
    pub content_hash_hex: String,
    pub data: String,
    pub mime_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncPush {
    pub server_id: String,
    pub works: Vec<SyncWorkEntry>,
    pub editions: Vec<SyncEditionEntry>,
    pub blobs: Vec<SyncBlobEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncPull {
    pub server_id: String,
    pub known_fingerprints: Vec<String>,
    #[serde(default = "default_max_entries")]
    pub max_entries: usize,
}

fn default_max_entries() -> usize {
    1000
}

pub const MAX_SYNC_ENTRIES: usize = 1000;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentSyncResult {
    pub works_received: usize,
    pub editions_received: usize,
    pub blobs_received: usize,
    pub works_already_known: usize,
    pub editions_already_known: usize,
    pub blobs_already_known: usize,
}

pub struct ContentSyncSet {
    entries: HashSet<[u8; 32]>,
}

impl ContentSyncSet {
    pub fn new() -> Self {
        ContentSyncSet {
            entries: HashSet::new(),
        }
    }

    pub fn insert(&mut self, fingerprint: [u8; 32]) -> bool {
        self.entries.insert(fingerprint)
    }

    pub fn contains(&self, fingerprint: &[u8; 32]) -> bool {
        self.entries.contains(fingerprint)
    }

    pub fn known_fingerprints(&self) -> Vec<String> {
        self.entries.iter().map(|fp| hex::encode(fp)).collect()
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RemoteOrigin {
    pub server_id: String,
    pub local_id: u64,
    pub element_type: RemoteElementType,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RemoteElementType {
    Work,
    Edition,
    Blob,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FederatedTransclusionEntry {
    pub content_fingerprint_hex: String,
    pub origin_server_id: String,
    pub element_type: RemoteElementType,
    pub local_id: u64,
    pub is_direct: bool,
}

pub struct RemoteOriginRegistry {
    origins: HashMap<[u8; 32], RemoteOrigin>,
}

impl RemoteOriginRegistry {
    pub fn new() -> Self {
        RemoteOriginRegistry {
            origins: HashMap::new(),
        }
    }

    pub fn record(&mut self, fingerprint: [u8; 32], origin: RemoteOrigin) {
        self.origins.entry(fingerprint).or_insert(origin);
    }

    pub fn get(&self, fingerprint: &[u8; 32]) -> Option<&RemoteOrigin> {
        self.origins.get(fingerprint)
    }

    pub fn origins_by_server(&self, server_id: &str) -> Vec<([u8; 32], RemoteOrigin)> {
        self.origins
            .iter()
            .filter(|(_, o)| o.server_id == server_id)
            .map(|(fp, o)| (*fp, o.clone()))
            .collect()
    }

    pub fn len(&self) -> usize {
        self.origins.len()
    }

    pub fn is_empty(&self) -> bool {
        self.origins.is_empty()
    }

    pub fn contains(&self, fingerprint: &[u8; 32]) -> bool {
        self.origins.contains_key(fingerprint)
    }
}

impl Default for RemoteOriginRegistry {
    fn default() -> Self {
        Self::new()
    }
}

mod hex {
    pub fn encode(data: &[u8]) -> String {
        data.iter().map(|b| format!("{:02x}", b)).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn federated_id_display() {
        let fid = FederatedId::new("a1b2c3d4", 42);
        assert_eq!(format!("{}", fid), "a1b2c3d4:42");
        assert_eq!(fid.server_id, "a1b2c3d4");
        assert_eq!(fid.local_id, 42);
    }

    #[test]
    fn federated_id_is_local() {
        let fid = FederatedId::new("abc", 1);
        assert!(fid.is_local("abc"));
        assert!(!fid.is_local("xyz"));
    }

    #[test]
    fn federated_id_equality() {
        let a = FederatedId::new("abc", 1);
        let b = FederatedId::new("abc", 1);
        let c = FederatedId::new("abc", 2);
        let d = FederatedId::new("xyz", 1);
        assert_eq!(a, b);
        assert_ne!(a, c);
        assert_ne!(a, d);
    }

    #[test]
    fn federated_id_hashable() {
        let mut set = HashSet::new();
        set.insert(FederatedId::new("abc", 1));
        assert!(set.contains(&FederatedId::new("abc", 1)));
        assert!(!set.contains(&FederatedId::new("abc", 2)));
    }

    #[test]
    fn federated_id_serialize_roundtrip() {
        let fid = FederatedId::new("a1b2c3d4", 42);
        let json = serde_json::to_string(&fid).unwrap();
        let back: FederatedId = serde_json::from_str(&json).unwrap();
        assert_eq!(fid, back);
    }

    #[test]
    fn peer_address_display() {
        let pa = PeerAddress::new("10.0.1.10", 8081);
        assert_eq!(format!("{}", pa), "10.0.1.10:8081");
    }

    #[test]
    fn peer_address_equality() {
        let a = PeerAddress::new("10.0.1.10", 8081);
        let b = PeerAddress::new("10.0.1.10", 8081);
        let c = PeerAddress::new("10.0.1.10", 8082);
        assert_eq!(a, b);
        assert_ne!(a, c);
    }

    #[test]
    fn federation_config_default_disabled() {
        let config = FederationConfig::default();
        assert!(!config.enabled);
        assert!(config.peers.is_empty());
        assert_eq!(config.mode, FederationMode::Closed);
    }

    #[test]
    fn federation_config_closed() {
        let config = FederationConfig::closed(vec![
            PeerAddress::new("10.0.1.10", 8081),
            PeerAddress::new("10.0.1.11", 8081),
        ]);
        assert!(config.enabled);
        assert_eq!(config.peers.len(), 2);
        assert_eq!(config.mode, FederationMode::Closed);
    }

    #[test]
    fn federation_state_add_remove_peer() {
        let mut state = FederationState::new(FederationConfig::closed(vec![]));
        let peer = PeerAddress::new("10.0.1.10", 8081);
        state.add_peer(peer.clone());
        assert_eq!(state.peer_addresses().len(), 1);
        assert!(state.known_peers().contains("10.0.1.10:8081"));

        state.add_peer(peer.clone());
        assert_eq!(state.peer_addresses().len(), 1);

        state.remove_peer(&peer);
        assert!(state.peer_addresses().is_empty());
    }

    #[test]
    fn federation_state_royalty_ledger() {
        let mut state = FederationState::disabled();
        state.record_royalty(RoyaltyEntry {
            origin_server_id: "abc".to_string(),
            content_fingerprint: [0u8; 32],
            royalty_type: RoyaltyType::Transclusion,
            amount: 100,
            timestamp: 1000,
        });
        assert_eq!(state.royalty_ledger().len(), 1);
        assert_eq!(state.royalty_ledger()[0].amount, 100);
    }

    #[test]
    fn royalty_type_serialize() {
        let rt = RoyaltyType::Transclusion;
        let json = serde_json::to_string(&rt).unwrap();
        assert_eq!(json, "\"transclusion\"");

        let custom = RoyaltyType::Custom("micropayment".to_string());
        let json = serde_json::to_string(&custom).unwrap();
        assert!(json.contains("micropayment"));
    }

    #[test]
    fn federation_config_serialize_roundtrip() {
        let config = FederationConfig::closed(vec![
            PeerAddress::new("10.0.1.10", 8081),
        ]);
        let json = serde_json::to_string_pretty(&config).unwrap();
        let back: FederationConfig = serde_json::from_str(&json).unwrap();
        assert!(back.enabled);
        assert_eq!(back.peers.len(), 1);
        assert_eq!(back.mode, FederationMode::Closed);
    }

    #[test]
    fn remote_origin_record_and_get() {
        let mut registry = RemoteOriginRegistry::new();
        let fp = [1u8; 32];
        let origin = RemoteOrigin {
            server_id: "server-a".to_string(),
            local_id: 42,
            element_type: RemoteElementType::Work,
        };
        assert!(registry.is_empty());
        registry.record(fp, origin.clone());
        assert_eq!(registry.len(), 1);
        assert!(registry.contains(&fp));

        let got = registry.get(&fp).unwrap();
        assert_eq!(got.server_id, "server-a");
        assert_eq!(got.local_id, 42);
        assert_eq!(got.element_type, RemoteElementType::Work);
    }

    #[test]
    fn remote_origin_overwrite_on_duplicate() {
        let mut registry = RemoteOriginRegistry::new();
        let fp = [2u8; 32];
        registry.record(fp, RemoteOrigin {
            server_id: "first".to_string(),
            local_id: 1,
            element_type: RemoteElementType::Edition,
        });
        registry.record(fp, RemoteOrigin {
            server_id: "second".to_string(),
            local_id: 2,
            element_type: RemoteElementType::Work,
        });
        assert_eq!(registry.len(), 1);
        assert_eq!(registry.get(&fp).unwrap().server_id, "first");
    }

    #[test]
    fn remote_origins_by_server() {
        let mut registry = RemoteOriginRegistry::new();
        registry.record([1u8; 32], RemoteOrigin {
            server_id: "a".to_string(),
            local_id: 1,
            element_type: RemoteElementType::Work,
        });
        registry.record([2u8; 32], RemoteOrigin {
            server_id: "b".to_string(),
            local_id: 2,
            element_type: RemoteElementType::Edition,
        });
        registry.record([3u8; 32], RemoteOrigin {
            server_id: "a".to_string(),
            local_id: 3,
            element_type: RemoteElementType::Blob,
        });
        let from_a = registry.origins_by_server("a");
        assert_eq!(from_a.len(), 2);
        let from_b = registry.origins_by_server("b");
        assert_eq!(from_b.len(), 1);
        let from_c = registry.origins_by_server("c");
        assert!(from_c.is_empty());
    }

    #[test]
    fn remote_origin_serialize_roundtrip() {
        let origin = RemoteOrigin {
            server_id: "test-server".to_string(),
            local_id: 99,
            element_type: RemoteElementType::Edition,
        };
        let json = serde_json::to_string(&origin).unwrap();
        let back: RemoteOrigin = serde_json::from_str(&json).unwrap();
        assert_eq!(back.server_id, "test-server");
        assert_eq!(back.local_id, 99);
        assert_eq!(back.element_type, RemoteElementType::Edition);
    }

    #[test]
    fn federated_transclusion_entry_serialize() {
        let entry = FederatedTransclusionEntry {
            content_fingerprint_hex: "ab".repeat(32),
            origin_server_id: "srv".to_string(),
            element_type: RemoteElementType::Work,
            local_id: 7,
            is_direct: true,
        };
        let json = serde_json::to_string(&entry).unwrap();
        let back: FederatedTransclusionEntry = serde_json::from_str(&json).unwrap();
        assert_eq!(back.origin_server_id, "srv");
        assert_eq!(back.local_id, 7);
        assert!(back.is_direct);
    }

    #[test]
    fn federation_state_remote_origin_tracking() {
        let mut state = FederationState::new(FederationConfig::disabled());
        let fp = [42u8; 32];
        state.record_remote_origin(fp, RemoteOrigin {
            server_id: "remote".to_string(),
            local_id: 10,
            element_type: RemoteElementType::Work,
        });
        let origin = state.get_remote_origin(&fp).unwrap();
        assert_eq!(origin.server_id, "remote");
        assert_eq!(origin.local_id, 10);

        let missing = state.get_remote_origin(&[0u8; 32]);
        assert!(missing.is_none());
    }
}
