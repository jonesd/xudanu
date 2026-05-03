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
}
