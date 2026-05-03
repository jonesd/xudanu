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

// =============================================================================
// Phase 18: CRDT Data Structures for DagWood Reconciliation & Mutable State
// =============================================================================
//
// Two CRDTs for the Reconciliation Plane (see manual.md "Three Planes of
// Consensus"):
//
// 1. OrSet<T> — Observed-Remove Set CRDT
//    Used for endorsement propagation. Each add/remove is tagged with a
//    unique identifier. Merging is well-defined: adds win over removes
//    when the same tag is involved, and concurrent adds/removes from
//    different servers coexist correctly.
//
//    Invariant: if a tag was both added and removed across replicas, the
//    remove wins (the item is absent). But if different tags added the same
//    value, only the removed tag is tombstoned — the value remains visible
//    via the other tag.
//
// 2. LwwRegister<T> — Last-Writer-Wins Register CRDT
//    Used for mutable pointers (work current edition, branch heads).
//    Each write carries a (timestamp, server_id) tuple. Merge takes the
//    highest timestamp, with server_id as deterministic tiebreaker.
//
// Both are serialized for both snapshots and federation wire protocol.

/// Unique tag for an OR-Set operation. Combines the originating server's
/// identity with a monotonically increasing counter to guarantee global
/// uniqueness without coordination.
#[derive(Debug, Clone, Hash, Eq, PartialEq, Serialize, Deserialize)]
pub struct OrSetTag {
    pub server_id: String,
    pub counter: u64,
}

impl OrSetTag {
    pub fn new(server_id: impl Into<String>, counter: u64) -> Self {
        OrSetTag {
            server_id: server_id.into(),
            counter,
        }
    }
}

impl std::fmt::Display for OrSetTag {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}:{}", self.server_id, self.counter)
    }
}

/// A single entry in the OR-Set: pairs a value with the unique tag that
/// added it. The tag is used for precise remove — only the exact tag is
/// tombstoned, not the value itself (which may have been added by other
/// tags too).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrSetEntry<T> {
    pub value: T,
    pub tag: OrSetTag,
}

/// Observed-Remove Set CRDT.
///
/// Semantics:
/// - `add(value, tag)`: inserts (value, tag) into the add set.
/// - `remove(value, tag)`: moves (value, tag) from add set to tombstone set.
/// - `remove_value(value)`: tombstones ALL entries matching value.
/// - `merge(other)`: union of add sets minus union of tombstone sets.
/// - `values()`: unique values remaining in add set after subtracting tombstones.
///
/// Thread safety: NOT thread-safe. Callers must synchronize access.
/// Serialization: derives Serialize/Deserialize for snapshots and wire protocol.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrSet<T> {
    adds: Vec<OrSetEntry<T>>,
    tombstones: Vec<OrSetEntry<T>>,
}

impl<T: Clone + Eq + std::hash::Hash> OrSet<T> {
    pub fn new() -> Self {
        OrSet {
            adds: Vec::new(),
            tombstones: Vec::new(),
        }
    }

    /// Add a value with a unique tag. Idempotent for the same (value, tag) pair.
    /// Silently rejected if the tag is already tombstoned.
    pub fn add(&mut self, value: T, tag: OrSetTag) {
        let is_tombstoned = self
            .tombstones
            .iter()
            .any(|e| e.tag == tag);
        if is_tombstoned {
            return;
        }
        let already = self.adds.iter().any(|e| e.value == value && e.tag == tag);
        if !already {
            self.adds.push(OrSetEntry { value, tag });
        }
    }

    /// Remove a specific (value, tag) pair by moving it to tombstones.
    /// No-op if the pair doesn't exist in the add set.
    pub fn remove(&mut self, value: &T, tag: &OrSetTag) {
        let idx = self.adds.iter().position(|e| e.value == *value && e.tag == *tag);
        if let Some(i) = idx {
            let entry = self.adds.remove(i);
            self.tombstones.push(entry);
        }
    }

    /// Remove ALL entries for a given value (tombstone every matching tag).
    /// This is the "observed-remove" semantics — you must have observed the
    /// value to remove it.
    pub fn remove_value(&mut self, value: &T) {
        let mut remaining = Vec::new();
        for entry in self.adds.drain(..) {
            if entry.value == *value {
                self.tombstones.push(entry);
            } else {
                remaining.push(entry);
            }
        }
        self.adds = remaining;
    }

    /// Merge another OR-Set into this one. After merge:
    ///   adds = (self.adds ∪ other.adds) − (self.tombstones ∪ other.tombstones)
    ///   tombstones = self.tombstones ∪ other.tombstones
    ///
    /// The merge is commutative, associative, and idempotent (CRDT properties).
    pub fn merge(&mut self, other: &OrSet<T>) {
        let mut tombstone_tags: HashSet<String> = self
            .tombstones
            .iter()
            .map(|e| e.tag.to_string())
            .collect();
        for entry in &other.tombstones {
            let key = entry.tag.to_string();
            if !tombstone_tags.contains(&key) {
                self.tombstones.push(entry.clone());
                tombstone_tags.insert(key);
            }
        }

        for entry in &other.adds {
            let is_tombstoned = tombstone_tags.contains(&entry.tag.to_string());
            let already_have = self
                .adds
                .iter()
                .any(|e| e.value == entry.value && e.tag == entry.tag);
            if !is_tombstoned && !already_have {
                self.adds.push(entry.clone());
            }
        }

        self.adds.retain(|e| !tombstone_tags.contains(&e.tag.to_string()));
    }

    /// Return the set of unique values currently in the OR-Set.
    /// Order is insertion order (not sorted), deduplicated by value.
    pub fn values(&self) -> Vec<&T> {
        let mut seen = HashSet::new();
        self.adds
            .iter()
            .filter(|e| seen.insert(hash_value(&e.value)))
            .map(|e| &e.value)
            .collect()
    }

    /// Check if a value is present (at least one non-tombstoned entry).
    pub fn contains(&self, value: &T) -> bool {
        self.adds.iter().any(|e| e.value == *value)
    }

    pub fn is_empty(&self) -> bool {
        self.values().is_empty()
    }

    pub fn len(&self) -> usize {
        self.values().len()
    }

    pub fn add_count(&self) -> usize {
        self.adds.len()
    }

    pub fn tombstone_count(&self) -> usize {
        self.tombstones.len()
    }

    /// Export for wire protocol: returns all adds and tombstones.
    pub fn to_entries(&self) -> (&[OrSetEntry<T>], &[OrSetEntry<T>]) {
        (&self.adds, &self.tombstones)
    }

    /// Import from wire protocol: adds all entries (skips duplicates).
    pub fn import_entries(&mut self, adds: &[OrSetEntry<T>], tombstones: &[OrSetEntry<T>]) {
        for entry in adds {
            self.add(entry.value.clone(), entry.tag.clone());
        }
        for entry in tombstones {
            let key = entry.tag.to_string();
            let already = self
                .tombstones
                .iter()
                .any(|e| e.tag.to_string() == key);
            if !already {
                self.tombstones.push(entry.clone());
            }
        }
        self.adds.retain(|e| {
            !self
                .tombstones
                .iter()
                .any(|t| t.tag == e.tag)
        });
    }
}

fn hash_value<T: std::hash::Hash + Eq>(value: &T) -> u64 {
    use std::hash::Hasher;
    let mut hasher = std::collections::hash_map::DefaultHasher::new();
    value.hash(&mut hasher);
    hasher.finish()
}

impl<T: Clone + Eq + std::hash::Hash> Default for OrSet<T> {
    fn default() -> Self {
        Self::new()
    }
}

/// A timestamped value for Last-Writer-Wins semantics.
/// Uses (timestamp, server_id) as the ordering key — higher timestamp
/// wins, with server_id as deterministic tiebreaker (lexicographic).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LwwRegister<T> {
    value: T,
    timestamp: u64,
    server_id: String,
}

impl<T: Clone + PartialEq> LwwRegister<T> {
    pub fn new(value: T, timestamp: u64, server_id: impl Into<String>) -> Self {
        LwwRegister {
            value,
            timestamp,
            server_id: server_id.into(),
        }
    }

    pub fn value(&self) -> &T {
        &self.value
    }

    pub fn timestamp(&self) -> u64 {
        self.timestamp
    }

    pub fn server_id(&self) -> &str {
        &self.server_id
    }

    /// Set a new value if (timestamp, server_id) is strictly greater than
    /// the current one. Returns true if the value was updated.
    pub fn set(&mut self, value: T, timestamp: u64, server_id: impl Into<String>) -> bool {
        let server_id = server_id.into();
        if (timestamp, &server_id) > (self.timestamp, &self.server_id) {
            self.value = value;
            self.timestamp = timestamp;
            self.server_id = server_id;
            return true;
        }
        false
    }

    /// Merge another LWW-Register into this one. Takes whichever has the
    /// higher (timestamp, server_id). Commutative, associative, idempotent.
    pub fn merge(&mut self, other: &LwwRegister<T>) {
        if (other.timestamp, &other.server_id) > (self.timestamp, &self.server_id) {
            self.value = other.value.clone();
            self.timestamp = other.timestamp;
            self.server_id = other.server_id.clone();
        }
    }

    /// Check if this register's value equals another's.
    pub fn value_eq(&self, other: &LwwRegister<T>) -> bool {
        self.value == other.value
    }
}

/// Snapshot of an LwwRegister for serialization/wire transfer.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LwwSnapshot<T> {
    pub value: T,
    pub timestamp: u64,
    pub server_id: String,
}

impl<T: Clone + PartialEq> From<&LwwRegister<T>> for LwwSnapshot<T> {
    fn from(reg: &LwwRegister<T>) -> Self {
        LwwSnapshot {
            value: reg.value.clone(),
            timestamp: reg.timestamp,
            server_id: reg.server_id.clone(),
        }
    }
}

impl<T: Clone + PartialEq> LwwRegister<T> {
    pub fn from_snapshot(snapshot: LwwSnapshot<T>) -> Self {
        LwwRegister {
            value: snapshot.value,
            timestamp: snapshot.timestamp,
            server_id: snapshot.server_id,
        }
    }
}

// =============================================================================
// Phase 18: Reconciliation State
// =============================================================================
//
// When two servers independently revise the same work (identified by its
// content fingerprint), both editions must coexist. The ReconcileState
// tracks all known alternatives for a work and uses an LWW-Register to
// determine the "current" pointer.
//
// Key invariant: editions are NEVER silently resolved. All alternatives
// are preserved and queryable. The LWW-Register only determines which
// one is presented as "current" for compatibility with existing clients.

/// A single alternative edition in the reconciliation state.
/// Identified by (origin_server_id, revision_number) for global uniqueness.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlternativeEdition {
    pub origin_server_id: String,
    pub revision_number: u64,
    pub edition_payload: crate::server::transport::protocol::EditionPayload,
    pub timestamp: u64,
}

impl AlternativeEdition {
    pub fn new(
        origin_server_id: impl Into<String>,
        revision_number: u64,
        edition: &crate::edition::Edition,
        timestamp: u64,
    ) -> Self {
        AlternativeEdition {
            origin_server_id: origin_server_id.into(),
            revision_number,
            edition_payload: crate::server::transport::protocol::EditionPayload::from_edition(
                edition,
            ),
            timestamp,
        }
    }

    pub fn to_edition(&self) -> crate::edition::Edition {
        self.edition_payload.to_edition()
    }

    /// Unique key for this alternative: (server_id, revision_number).
    pub fn key(&self) -> String {
        format!("{}:{}", self.origin_server_id, self.revision_number)
    }
}

/// ReconcileState tracks all known editions for a work across servers.
///
/// - `alternatives`: OR-Set of (AlternativeEdition) — concurrent editions
///   from different servers. New editions are added; old ones are never
///   removed (content-addressed, immutable).
/// - `current`: LWW-Register pointing to the "current" edition key.
///   Determined by Last-Writer-Wins with (timestamp, server_id) tiebreak.
/// - `endorsements`: OR-Set of EndorsementEntries — endorsements from
///   different servers, propagated via CRDT merge.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReconcileState {
    /// Globally-unique work identifier (content fingerprint hex).
    pub work_fingerprint: String,
    /// All known editions, keyed by (server_id, revision_number).
    pub alternatives: HashMap<String, AlternativeEdition>,
    /// Current edition pointer — LWW-Register pointing to an alternative key.
    pub current: LwwRegister<String>,
    /// Endorsements for this work, propagated via OR-Set CRDT.
    pub endorsements: OrSet<EndorsementEntry>,
}

/// An endorsement entry for CRDT propagation. Wraps the existing Endorsement
/// type with a server origin for unique tagging.
#[derive(Debug, Clone, Hash, Eq, PartialEq, Serialize, Deserialize)]
pub struct EndorsementEntry {
    pub club_id: u64,
    pub token_id: u64,
    pub origin_server_id: String,
}

impl EndorsementEntry {
    pub fn new(club_id: u64, token_id: u64, origin_server_id: impl Into<String>) -> Self {
        EndorsementEntry {
            club_id,
            token_id,
            origin_server_id: origin_server_id.into(),
        }
    }
}

impl ReconcileState {
    pub fn new(
        work_fingerprint: impl Into<String>,
        initial_key: String,
        initial_edition: AlternativeEdition,
        server_id: impl Into<String>,
        timestamp: u64,
    ) -> Self {
        let key = initial_key.clone();
        let server_id_str = server_id.into();
        let mut alternatives = HashMap::new();
        alternatives.insert(key.clone(), initial_edition);

        ReconcileState {
            work_fingerprint: work_fingerprint.into(),
            alternatives,
            current: LwwRegister::new(initial_key, timestamp, server_id_str),
            endorsements: OrSet::new(),
        }
    }

    /// Add a new alternative edition. Returns true if this was a new addition.
    pub fn add_alternative(&mut self, edition: AlternativeEdition) -> bool {
        let key = edition.key();
        if self.alternatives.contains_key(&key) {
            return false;
        }
        self.alternatives.insert(key, edition);
        true
    }

    /// Set the current edition pointer (LWW semantics).
    pub fn set_current(
        &mut self,
        key: String,
        timestamp: u64,
        server_id: impl Into<String>,
    ) -> bool {
        self.current.set(key, timestamp, server_id)
    }

    /// Get the current edition (the one the LWW-Register points to).
    pub fn current_edition(&self) -> Option<&AlternativeEdition> {
        self.alternatives.get(self.current.value())
    }

    /// Get all alternatives as a slice of references.
    pub fn all_alternatives(&self) -> Vec<&AlternativeEdition> {
        self.alternatives.values().collect()
    }

    /// Get the text of the current edition for quick access.
    pub fn current_text(&self) -> Option<String> {
        self.current_edition().map(|alt| {
            let ed = alt.to_edition();
            ed.all_entries()
                .iter()
                .map(|(_, c)| c.element.as_text().unwrap_or(""))
                .collect()
        })
    }

    /// Merge another ReconcileState into this one.
    /// - Alternatives: union (new editions from other server).
    /// - Current: LWW merge (higher timestamp wins).
    /// - Endorsements: OR-Set merge (adds minus tombstones).
    pub fn merge(&mut self, other: &ReconcileState) {
        for (key, alt) in &other.alternatives {
            if !self.alternatives.contains_key(key) {
                self.alternatives.insert(key.clone(), alt.clone());
            }
        }
        self.current.merge(&other.current);
        self.endorsements.merge(&other.endorsements);
    }

    pub fn alternative_count(&self) -> usize {
        self.alternatives.len()
    }

    pub fn has_alternatives(&self) -> bool {
        self.alternatives.len() > 1
    }
}

/// Global reconciliation state for the entire server.
/// Maps work fingerprint → ReconcileState.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ReconcileStore {
    states: HashMap<String, ReconcileState>,
}

impl ReconcileStore {
    pub fn new() -> Self {
        ReconcileStore {
            states: HashMap::new(),
        }
    }

    /// Get or create a ReconcileState for the given work fingerprint.
    pub fn get_or_create(
        &mut self,
        work_fingerprint: &str,
        initial_key: String,
        initial_edition: AlternativeEdition,
        server_id: impl Into<String>,
        timestamp: u64,
    ) -> &mut ReconcileState {
        if !self.states.contains_key(work_fingerprint) {
            self.states.insert(
                work_fingerprint.to_string(),
                ReconcileState::new(
                    work_fingerprint,
                    initial_key,
                    initial_edition,
                    server_id,
                    timestamp,
                ),
            );
        }
        self.states.get_mut(work_fingerprint).unwrap()
    }

    pub fn get(&self, work_fingerprint: &str) -> Option<&ReconcileState> {
        self.states.get(work_fingerprint)
    }

    pub fn get_mut(&mut self, work_fingerprint: &str) -> Option<&mut ReconcileState> {
        self.states.get_mut(work_fingerprint)
    }

    /// Merge a remote ReconcileState into the local one.
    /// Creates the local state if it doesn't exist yet.
    pub fn merge_remote(&mut self, remote: &ReconcileState) {
        let fp = remote.work_fingerprint.clone();
        if let Some(local) = self.states.get_mut(&fp) {
            local.merge(remote);
        } else {
            self.states.insert(fp, remote.clone());
        }
    }

    pub fn len(&self) -> usize {
        self.states.len()
    }

    pub fn is_empty(&self) -> bool {
        self.states.is_empty()
    }

    pub fn fingerprints(&self) -> Vec<String> {
        self.states.keys().cloned().collect()
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

    // =====================================================================
    // OR-Set CRDT Tests
    // =====================================================================

    #[test]
    fn orset_add_and_contains() {
        let mut set: OrSet<String> = OrSet::new();
        assert!(set.is_empty());
        set.add("hello".to_string(), OrSetTag::new("srv-a", 1));
        assert!(set.contains(&"hello".to_string()));
        assert_eq!(set.len(), 1);
    }

    #[test]
    fn orset_add_idempotent_same_tag() {
        let mut set: OrSet<String> = OrSet::new();
        set.add("hello".to_string(), OrSetTag::new("srv-a", 1));
        set.add("hello".to_string(), OrSetTag::new("srv-a", 1));
        assert_eq!(set.add_count(), 1, "same (value, tag) should not duplicate");
        assert_eq!(set.len(), 1);
    }

    #[test]
    fn orset_same_value_different_tags_both_visible() {
        let mut set: OrSet<String> = OrSet::new();
        set.add("hello".to_string(), OrSetTag::new("srv-a", 1));
        set.add("hello".to_string(), OrSetTag::new("srv-b", 1));
        assert_eq!(set.add_count(), 2, "different tags for same value both stored");
        assert_eq!(set.len(), 1, "values() deduplicates by value");
    }

    #[test]
    fn orset_remove_specific_tag() {
        let mut set: OrSet<String> = OrSet::new();
        let tag_a = OrSetTag::new("srv-a", 1);
        let tag_b = OrSetTag::new("srv-b", 1);
        set.add("hello".to_string(), tag_a.clone());
        set.add("hello".to_string(), tag_b.clone());

        set.remove(&"hello".to_string(), &tag_a);
        assert!(
            set.contains(&"hello".to_string()),
            "value still present via tag_b"
        );
        assert_eq!(set.add_count(), 1);
        assert_eq!(set.tombstone_count(), 1);
    }

    #[test]
    fn orset_remove_all_tags_removes_value() {
        let mut set: OrSet<String> = OrSet::new();
        set.add("hello".to_string(), OrSetTag::new("srv-a", 1));
        set.add("hello".to_string(), OrSetTag::new("srv-b", 1));

        set.remove_value(&"hello".to_string());
        assert!(!set.contains(&"hello".to_string()));
        assert_eq!(set.add_count(), 0);
        assert_eq!(set.tombstone_count(), 2);
    }

    #[test]
    fn orset_remove_nonexistent_is_noop() {
        let mut set: OrSet<String> = OrSet::new();
        set.remove(&"nope".to_string(), &OrSetTag::new("srv-a", 1));
        assert!(set.is_empty());
        assert_eq!(set.tombstone_count(), 0);
    }

    #[test]
    fn orset_merge_union_of_adds() {
        let mut set_a: OrSet<String> = OrSet::new();
        set_a.add("alpha".to_string(), OrSetTag::new("srv-a", 1));
        set_a.add("shared".to_string(), OrSetTag::new("srv-a", 2));

        let mut set_b: OrSet<String> = OrSet::new();
        set_b.add("bravo".to_string(), OrSetTag::new("srv-b", 1));
        set_b.add("shared".to_string(), OrSetTag::new("srv-b", 2));

        set_a.merge(&set_b);
        assert!(set_a.contains(&"alpha".to_string()));
        assert!(set_a.contains(&"bravo".to_string()));
        assert!(set_a.contains(&"shared".to_string()));
        assert_eq!(set_a.len(), 3);
    }

    #[test]
    fn orset_merge_tombstones_remove_adds() {
        let mut set_a: OrSet<String> = OrSet::new();
        set_a.add("hello".to_string(), OrSetTag::new("srv-a", 1));
        set_a.add("world".to_string(), OrSetTag::new("srv-a", 2));

        let mut set_b: OrSet<String> = OrSet::new();
        set_b.add("hello".to_string(), OrSetTag::new("srv-a", 1));
        set_b.add("world".to_string(), OrSetTag::new("srv-a", 2));
        set_b.remove(&"hello".to_string(), &OrSetTag::new("srv-a", 1));

        set_a.merge(&set_b);
        assert!(
            !set_a.contains(&"hello".to_string()),
            "tombstoned entry should be removed after merge"
        );
        assert!(set_a.contains(&"world".to_string()));
    }

    #[test]
    fn orset_merge_is_commutative() {
        let mut set_a: OrSet<String> = OrSet::new();
        set_a.add("x".to_string(), OrSetTag::new("srv-a", 1));

        let mut set_b: OrSet<String> = OrSet::new();
        set_b.add("y".to_string(), OrSetTag::new("srv-b", 1));

        let mut merged_ab = set_a.clone();
        merged_ab.merge(&set_b);

        let mut merged_ba = set_b.clone();
        merged_ba.merge(&set_a);

        let mut vals_ab: Vec<String> = merged_ab.values().into_iter().cloned().collect();
        vals_ab.sort();
        let mut vals_ba: Vec<String> = merged_ba.values().into_iter().cloned().collect();
        vals_ba.sort();
        assert_eq!(vals_ab, vals_ba, "merge should be commutative");
    }

    #[test]
    fn orset_merge_is_idempotent() {
        let mut set_a: OrSet<String> = OrSet::new();
        set_a.add("hello".to_string(), OrSetTag::new("srv-a", 1));

        let snapshot = set_a.clone();
        set_a.merge(&snapshot);
        assert_eq!(set_a.add_count(), 1, "merging with self should not duplicate");
        assert_eq!(set_a.tombstone_count(), 0);
    }

    #[test]
    fn orset_tombstone_prevents_re_add_after_merge() {
        let mut set_a: OrSet<String> = OrSet::new();
        set_a.add("secret".to_string(), OrSetTag::new("srv-a", 1));

        let mut set_b: OrSet<String> = OrSet::new();
        set_b.add("secret".to_string(), OrSetTag::new("srv-a", 1));
        set_b.remove(&"secret".to_string(), &OrSetTag::new("srv-a", 1));

        set_a.merge(&set_b);
        assert!(!set_a.contains(&"secret".to_string()));

        set_a.add("secret".to_string(), OrSetTag::new("srv-a", 1));
        assert!(
            !set_a.contains(&"secret".to_string()),
            "re-adding with tombstoned tag should not revive it"
        );
    }

    #[test]
    fn orset_different_tag_same_value_survives_tombstone() {
        let mut set: OrSet<String> = OrSet::new();
        set.add("hello".to_string(), OrSetTag::new("srv-a", 1));
        set.add("hello".to_string(), OrSetTag::new("srv-b", 5));

        set.remove(&"hello".to_string(), &OrSetTag::new("srv-a", 1));
        assert!(
            set.contains(&"hello".to_string()),
            "value survives via different tag"
        );

        let mut other: OrSet<String> = OrSet::new();
        other.add("hello".to_string(), OrSetTag::new("srv-c", 10));
        set.merge(&other);
        assert!(set.contains(&"hello".to_string()));
    }

    #[test]
    fn orset_import_entries() {
        let mut set: OrSet<String> = OrSet::new();
        let adds = vec![
            OrSetEntry {
                value: "alpha".to_string(),
                tag: OrSetTag::new("srv-a", 1),
            },
            OrSetEntry {
                value: "bravo".to_string(),
                tag: OrSetTag::new("srv-b", 2),
            },
        ];
        let tombstones = vec![OrSetEntry {
            value: "gamma".to_string(),
            tag: OrSetTag::new("srv-c", 3),
        }];

        set.import_entries(&adds, &tombstones);
        assert!(set.contains(&"alpha".to_string()));
        assert!(set.contains(&"bravo".to_string()));
        assert!(!set.contains(&"gamma".to_string()));
        assert_eq!(set.tombstone_count(), 1);
    }

    #[test]
    fn orset_import_tombstone_removes_existing_add() {
        let mut set: OrSet<String> = OrSet::new();
        set.add("doomed".to_string(), OrSetTag::new("srv-a", 1));

        let tombstones = vec![OrSetEntry {
            value: "doomed".to_string(),
            tag: OrSetTag::new("srv-a", 1),
        }];
        set.import_entries(&[], &tombstones);
        assert!(!set.contains(&"doomed".to_string()));
    }

    #[test]
    fn orset_tag_display() {
        let tag = OrSetTag::new("server-42", 7);
        assert_eq!(tag.to_string(), "server-42:7");
    }

    #[test]
    fn orset_serialize_roundtrip() {
        let mut set: OrSet<String> = OrSet::new();
        set.add("hello".to_string(), OrSetTag::new("srv-a", 1));
        set.add("world".to_string(), OrSetTag::new("srv-b", 2));
        set.remove(&"hello".to_string(), &OrSetTag::new("srv-a", 1));

        let json = serde_json::to_string(&set).unwrap();
        let back: OrSet<String> = serde_json::from_str(&json).unwrap();
        assert!(!back.contains(&"hello".to_string()));
        assert!(back.contains(&"world".to_string()));
        assert_eq!(back.tombstone_count(), 1);
    }

    #[test]
    fn orset_three_way_merge_converges() {
        let mut a: OrSet<String> = OrSet::new();
        let mut b: OrSet<String> = OrSet::new();
        let mut c: OrSet<String> = OrSet::new();

        a.add("item-1".to_string(), OrSetTag::new("srv-a", 1));
        b.add("item-2".to_string(), OrSetTag::new("srv-b", 1));
        c.add("item-3".to_string(), OrSetTag::new("srv-c", 1));

        a.remove_value(&"item-1".to_string());

        b.merge(&a);
        c.merge(&a);
        b.merge(&c);
        c.merge(&b);

        assert!(!b.contains(&"item-1".to_string()));
        assert!(!c.contains(&"item-1".to_string()));
        assert!(b.contains(&"item-2".to_string()));
        assert!(b.contains(&"item-3".to_string()));
        assert!(c.contains(&"item-2".to_string()));
        assert!(c.contains(&"item-3".to_string()));
    }

    // =====================================================================
    // LWW-Register CRDT Tests
    // =====================================================================

    #[test]
    fn lww_register_new_and_read() {
        let reg = LwwRegister::new("hello".to_string(), 100, "srv-a");
        assert_eq!(reg.value(), "hello");
        assert_eq!(reg.timestamp(), 100);
        assert_eq!(reg.server_id(), "srv-a");
    }

    #[test]
    fn lww_register_set_higher_timestamp() {
        let mut reg = LwwRegister::new("old".to_string(), 100, "srv-a");
        let updated = reg.set("new".to_string(), 200, "srv-b");
        assert!(updated);
        assert_eq!(reg.value(), "new");
        assert_eq!(reg.timestamp(), 200);
    }

    #[test]
    fn lww_register_set_lower_timestamp_rejected() {
        let mut reg = LwwRegister::new("keep".to_string(), 200, "srv-a");
        let updated = reg.set("discard".to_string(), 100, "srv-b");
        assert!(!updated);
        assert_eq!(reg.value(), "keep");
    }

    #[test]
    fn lww_register_same_timestamp_server_id_tiebreak() {
        let mut reg = LwwRegister::new("alpha".to_string(), 100, "srv-a");
        let updated = reg.set("bravo".to_string(), 100, "srv-b");
        assert!(updated, "srv-b > srv-a lexicographically");
        assert_eq!(reg.value(), "bravo");
    }

    #[test]
    fn lww_register_same_timestamp_same_server_rejected() {
        let mut reg = LwwRegister::new("keep".to_string(), 100, "srv-a");
        let updated = reg.set("discard".to_string(), 100, "srv-a");
        assert!(!updated, "identical (timestamp, server_id) should not overwrite");
        assert_eq!(reg.value(), "keep");
    }

    #[test]
    fn lww_register_merge_takes_higher_timestamp() {
        let mut reg_a = LwwRegister::new("from-a".to_string(), 100, "srv-a");
        let reg_b = LwwRegister::new("from-b".to_string(), 200, "srv-b");
        reg_a.merge(&reg_b);
        assert_eq!(reg_a.value(), "from-b");
    }

    #[test]
    fn lww_register_merge_is_commutative() {
        let reg_a = LwwRegister::new("from-a".to_string(), 100, "srv-a");
        let reg_b = LwwRegister::new("from-b".to_string(), 100, "srv-b");

        let mut merged_ab = reg_a.clone();
        merged_ab.merge(&reg_b);

        let mut merged_ba = reg_b.clone();
        merged_ba.merge(&reg_a);

        assert_eq!(merged_ab.value(), merged_ba.value());
    }

    #[test]
    fn lww_register_merge_is_idempotent() {
        let reg = LwwRegister::new("hello".to_string(), 100, "srv-a");
        let mut merged = reg.clone();
        merged.merge(&reg);
        assert_eq!(merged.value(), "hello");
        assert_eq!(merged.timestamp(), 100);
    }

    #[test]
    fn lww_register_snapshot_roundtrip() {
        let reg = LwwRegister::new("test-value".to_string(), 42, "srv-x");
        let snapshot = LwwSnapshot::from(&reg);
        let restored = LwwRegister::from_snapshot(snapshot);
        assert_eq!(restored.value(), "test-value");
        assert_eq!(restored.timestamp(), 42);
        assert_eq!(restored.server_id(), "srv-x");
    }

    #[test]
    fn lww_register_serialize_roundtrip() {
        let reg = LwwRegister::new("serialize-me".to_string(), 999, "srv-z");
        let snapshot = LwwSnapshot::from(&reg);
        let json = serde_json::to_string(&snapshot).unwrap();
        let back: LwwSnapshot<String> = serde_json::from_str(&json).unwrap();
        let restored = LwwRegister::from_snapshot(back);
        assert_eq!(restored.value(), "serialize-me");
    }

    #[test]
    fn lww_register_value_eq() {
        let a = LwwRegister::new("same".to_string(), 100, "srv-a");
        let b = LwwRegister::new("same".to_string(), 200, "srv-b");
        let c = LwwRegister::new("different".to_string(), 100, "srv-a");
        assert!(a.value_eq(&b));
        assert!(!a.value_eq(&c));
    }

    #[test]
    fn lww_register_three_way_merge_converges() {
        let reg_a = LwwRegister::new("a-wins".to_string(), 300, "srv-a");
        let reg_b = LwwRegister::new("b-wins".to_string(), 200, "srv-b");
        let reg_c = LwwRegister::new("c-wins".to_string(), 100, "srv-c");

        let mut merged_ab = reg_a.clone();
        merged_ab.merge(&reg_b);
        let mut merged_abc = merged_ab.clone();
        merged_abc.merge(&reg_c);
        assert_eq!(merged_abc.value(), "a-wins", "highest timestamp should win");
    }

    // =====================================================================
    // ReconcileState Tests
    // =====================================================================

    fn make_alt_edition(server: &str, rev: u64, text: &str, ts: u64) -> AlternativeEdition {
        let edition = crate::edition::Edition::from_text(text);
        AlternativeEdition::new(server, rev, &edition, ts)
    }

    #[test]
    fn reconcile_state_new() {
        let alt = make_alt_edition("srv-a", 0, "hello", 100);
        let state = ReconcileState::new("fp-abc", "srv-a:0".to_string(), alt, "srv-a", 100);
        assert_eq!(state.work_fingerprint, "fp-abc");
        assert_eq!(state.alternative_count(), 1);
        assert!(!state.has_alternatives());
        assert!(state.current_edition().is_some());
    }

    #[test]
    fn reconcile_state_current_edition_text() {
        let alt = make_alt_edition("srv-a", 0, "hello world", 100);
        let state = ReconcileState::new("fp-1", "srv-a:0".to_string(), alt, "srv-a", 100);
        assert_eq!(state.current_text().unwrap(), "hello world");
    }

    #[test]
    fn reconcile_state_add_alternative() {
        let alt_a = make_alt_edition("srv-a", 0, "version A", 100);
        let mut state = ReconcileState::new("fp-1", "srv-a:0".to_string(), alt_a, "srv-a", 100);

        let alt_b = make_alt_edition("srv-b", 0, "version B", 200);
        let added = state.add_alternative(alt_b);
        assert!(added, "new alternative should be added");
        assert_eq!(state.alternative_count(), 2);
        assert!(state.has_alternatives());
    }

    #[test]
    fn reconcile_state_add_duplicate_ignored() {
        let alt = make_alt_edition("srv-a", 0, "hello", 100);
        let mut state = ReconcileState::new("fp-1", "srv-a:0".to_string(), alt.clone(), "srv-a", 100);

        let added = state.add_alternative(alt);
        assert!(!added, "duplicate should be ignored");
        assert_eq!(state.alternative_count(), 1);
    }

    #[test]
    fn reconcile_state_set_current_lww() {
        let alt_a = make_alt_edition("srv-a", 0, "from A", 100);
        let mut state = ReconcileState::new("fp-1", "srv-a:0".to_string(), alt_a, "srv-a", 100);

        let alt_b = make_alt_edition("srv-b", 0, "from B", 200);
        state.add_alternative(alt_b);

        let changed = state.set_current("srv-b:0".to_string(), 200, "srv-b");
        assert!(changed);
        assert_eq!(state.current_text().unwrap(), "from B");
    }

    #[test]
    fn reconcile_state_set_current_lower_timestamp_rejected() {
        let alt_a = make_alt_edition("srv-a", 0, "from A", 200);
        let mut state = ReconcileState::new("fp-1", "srv-a:0".to_string(), alt_a, "srv-a", 200);

        let changed = state.set_current("srv-b:0".to_string(), 100, "srv-b");
        assert!(!changed);
        assert_eq!(state.current_text().unwrap(), "from A");
    }

    #[test]
    fn reconcile_state_merge_union_alternatives() {
        let alt_a = make_alt_edition("srv-a", 0, "A-edition", 100);
        let mut state_a = ReconcileState::new("fp-1", "srv-a:0".to_string(), alt_a, "srv-a", 100);

        let alt_b = make_alt_edition("srv-b", 0, "B-edition", 150);
        let mut state_b = ReconcileState::new("fp-1", "srv-b:0".to_string(), alt_b, "srv-b", 150);

        state_a.merge(&state_b);
        assert_eq!(state_a.alternative_count(), 2);
        assert!(state_a.has_alternatives());
    }

    #[test]
    fn reconcile_state_merge_lww_current() {
        let alt_a = make_alt_edition("srv-a", 0, "from A", 100);
        let mut state_a = ReconcileState::new("fp-1", "srv-a:0".to_string(), alt_a, "srv-a", 100);

        let alt_b = make_alt_edition("srv-b", 0, "from B", 200);
        let state_b = ReconcileState::new("fp-1", "srv-b:0".to_string(), alt_b, "srv-b", 200);

        state_a.merge(&state_b);
        assert_eq!(state_a.current_text().unwrap(), "from B");
    }

    #[test]
    fn reconcile_state_merge_endorsements() {
        let alt = make_alt_edition("srv-a", 0, "hello", 100);
        let mut state_a = ReconcileState::new("fp-1", "srv-a:0".to_string(), alt, "srv-a", 100);
        state_a.endorsements.add(
            EndorsementEntry::new(1, 10, "srv-a"),
            OrSetTag::new("srv-a", 1),
        );

        let alt_b = make_alt_edition("srv-b", 0, "hello", 150);
        let mut state_b = ReconcileState::new("fp-1", "srv-b:0".to_string(), alt_b, "srv-b", 150);
        state_b.endorsements.add(
            EndorsementEntry::new(2, 20, "srv-b"),
            OrSetTag::new("srv-b", 1),
        );

        state_a.merge(&state_b);
        assert_eq!(state_a.endorsements.len(), 2);
    }

    #[test]
    fn reconcile_state_all_alternatives() {
        let alt_a = make_alt_edition("srv-a", 0, "A", 100);
        let mut state = ReconcileState::new("fp-1", "srv-a:0".to_string(), alt_a, "srv-a", 100);

        let alt_b = make_alt_edition("srv-b", 0, "B", 200);
        state.add_alternative(alt_b);

        let alts = state.all_alternatives();
        assert_eq!(alts.len(), 2);
    }

    #[test]
    fn reconcile_state_serialize_roundtrip() {
        let alt = make_alt_edition("srv-a", 0, "serialize me", 100);
        let mut state = ReconcileState::new("fp-test", "srv-a:0".to_string(), alt, "srv-a", 100);
        state.endorsements.add(
            EndorsementEntry::new(5, 50, "srv-a"),
            OrSetTag::new("srv-a", 1),
        );

        let json = serde_json::to_string(&state).unwrap();
        let back: ReconcileState = serde_json::from_str(&json).unwrap();
        assert_eq!(back.work_fingerprint, "fp-test");
        assert_eq!(back.alternative_count(), 1);
        assert_eq!(back.endorsements.len(), 1);
    }

    // =====================================================================
    // ReconcileStore Tests
    // =====================================================================

    #[test]
    fn reconcile_store_new_empty() {
        let store = ReconcileStore::new();
        assert!(store.is_empty());
        assert_eq!(store.len(), 0);
    }

    #[test]
    fn reconcile_store_get_or_create() {
        let mut store = ReconcileStore::new();
        let alt = make_alt_edition("srv-a", 0, "initial", 100);
        let state = store.get_or_create("fp-1", "srv-a:0".to_string(), alt, "srv-a", 100);
        assert_eq!(state.work_fingerprint, "fp-1");
        assert_eq!(state.alternative_count(), 1);
    }

    #[test]
    fn reconcile_store_get_or_create_idempotent() {
        let mut store = ReconcileStore::new();
        let alt = make_alt_edition("srv-a", 0, "initial", 100);
        store.get_or_create("fp-1", "srv-a:0".to_string(), alt.clone(), "srv-a", 100);
        store.get_or_create("fp-1", "srv-a:0".to_string(), alt, "srv-a", 100);
        assert_eq!(store.len(), 1);
    }

    #[test]
    fn reconcile_store_get() {
        let mut store = ReconcileStore::new();
        let alt = make_alt_edition("srv-a", 0, "hello", 100);
        store.get_or_create("fp-1", "srv-a:0".to_string(), alt, "srv-a", 100);

        assert!(store.get("fp-1").is_some());
        assert!(store.get("fp-nonexistent").is_none());
    }

    #[test]
    fn reconcile_store_merge_remote_creates_new() {
        let mut store = ReconcileStore::new();
        let alt = make_alt_edition("srv-b", 0, "from B", 100);
        let remote = ReconcileState::new("fp-remote", "srv-b:0".to_string(), alt, "srv-b", 100);

        store.merge_remote(&remote);
        assert_eq!(store.len(), 1);
        assert!(store.get("fp-remote").is_some());
    }

    #[test]
    fn reconcile_store_merge_remote_adds_alternatives() {
        let mut store = ReconcileStore::new();
        let alt_a = make_alt_edition("srv-a", 0, "from A", 100);
        store.get_or_create("fp-1", "srv-a:0".to_string(), alt_a, "srv-a", 100);

        let alt_b = make_alt_edition("srv-b", 0, "from B", 200);
        let remote = ReconcileState::new("fp-1", "srv-b:0".to_string(), alt_b, "srv-b", 200);

        store.merge_remote(&remote);
        let state = store.get("fp-1").unwrap();
        assert_eq!(state.alternative_count(), 2);
        assert!(state.has_alternatives());
        assert_eq!(state.current_text().unwrap(), "from B");
    }

    #[test]
    fn reconcile_store_fingerprints() {
        let mut store = ReconcileStore::new();
        let alt1 = make_alt_edition("srv-a", 0, "one", 100);
        let alt2 = make_alt_edition("srv-a", 0, "two", 100);
        store.get_or_create("fp-alpha", "srv-a:0".to_string(), alt1, "srv-a", 100);
        store.get_or_create("fp-beta", "srv-a:0".to_string(), alt2, "srv-a", 100);

        let mut fps = store.fingerprints();
        fps.sort();
        assert_eq!(fps, vec!["fp-alpha", "fp-beta"]);
    }

    #[test]
    fn reconcile_store_three_way_merge_converges() {
        let alt_a = make_alt_edition("srv-a", 0, "A-v1", 100);
        let mut store_a = ReconcileStore::new();
        store_a.get_or_create("fp-1", "srv-a:0".to_string(), alt_a, "srv-a", 100);

        let alt_b = make_alt_edition("srv-b", 0, "B-v1", 150);
        let mut store_b = ReconcileStore::new();
        store_b.get_or_create("fp-1", "srv-b:0".to_string(), alt_b, "srv-b", 150);

        let alt_c = make_alt_edition("srv-c", 0, "C-v1", 200);
        let mut store_c = ReconcileStore::new();
        store_c.get_or_create("fp-1", "srv-c:0".to_string(), alt_c, "srv-c", 200);

        let remote_b = store_b.get("fp-1").unwrap().clone();
        let remote_c = store_c.get("fp-1").unwrap().clone();

        store_a.merge_remote(&remote_b);
        store_a.merge_remote(&remote_c);

        let state_a = store_a.get("fp-1").unwrap();
        assert_eq!(state_a.alternative_count(), 3);
        assert_eq!(state_a.current_text().unwrap(), "C-v1");

        store_b.merge_remote(&store_a.get("fp-1").unwrap().clone());
        let state_b = store_b.get("fp-1").unwrap();
        assert_eq!(state_b.alternative_count(), 3);
        assert_eq!(state_b.current_text().unwrap(), "C-v1");
    }

    #[test]
    fn reconcile_store_serialize_roundtrip() {
        let mut store = ReconcileStore::new();
        let alt = make_alt_edition("srv-a", 0, "persist me", 100);
        store.get_or_create("fp-1", "srv-a:0".to_string(), alt, "srv-a", 100);

        let json = serde_json::to_string(&store).unwrap();
        let back: ReconcileStore = serde_json::from_str(&json).unwrap();
        assert_eq!(back.len(), 1);
        assert!(back.get("fp-1").unwrap().current_edition().is_some());
    }

    #[test]
    fn endorsement_entry_new() {
        let entry = EndorsementEntry::new(3, 42, "srv-a");
        assert_eq!(entry.club_id, 3);
        assert_eq!(entry.token_id, 42);
        assert_eq!(entry.origin_server_id, "srv-a");
    }

    #[test]
    fn endorsement_entry_hash_eq() {
        let a = EndorsementEntry::new(1, 10, "srv-a");
        let b = EndorsementEntry::new(1, 10, "srv-a");
        let c = EndorsementEntry::new(1, 10, "srv-b");
        assert_eq!(a, b);
        assert_ne!(a, c);
        let mut set = HashSet::new();
        set.insert(a);
        assert!(set.contains(&b));
        assert!(!set.contains(&c));
    }
}
