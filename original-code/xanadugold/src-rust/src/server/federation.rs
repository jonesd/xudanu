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

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
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
    membership: MembershipState,
    governance: GovernanceState,
}

impl FederationState {
    pub fn new(config: FederationConfig) -> Self {
        let known_peers: HashSet<String> = config
            .peers
            .iter()
            .map(|p| p.to_string())
            .collect();
        let min_endorsements = config.min_endorsements;
        FederationState {
            config,
            known_peers,
            known_peer_keys: HashSet::new(),
            connected_peers: HashMap::new(),
            remote_origins: RemoteOriginRegistry::new(),
            royalty_ledger: Vec::new(),
            membership: MembershipState::new(min_endorsements),
            governance: GovernanceState::new(1),
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
            tracing::warn!("Federation enabled but no peer keys registered — rejecting all connections");
            return false;
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

    pub fn membership(&self) -> &MembershipState {
        &self.membership
    }

    pub fn membership_mut(&mut self) -> &mut MembershipState {
        &mut self.membership
    }

    pub fn governance(&self) -> &GovernanceState {
        &self.governance
    }

    pub fn governance_mut(&mut self) -> &mut GovernanceState {
        &mut self.governance
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
    fn clamp_timestamp(ts: u64) -> u64 {
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        if ts > now.saturating_add(3600) { now } else { ts }
    }

    pub fn set(&mut self, value: T, timestamp: u64, server_id: impl Into<String>) -> bool {
        let server_id = server_id.into();
        let ts = Self::clamp_timestamp(timestamp);
        if (ts, &server_id) > (self.timestamp, &self.server_id) {
            self.value = value;
            self.timestamp = ts;
            self.server_id = server_id;
            return true;
        }
        false
    }

    pub fn merge(&mut self, other: &LwwRegister<T>) {
        let ts = Self::clamp_timestamp(other.timestamp);
        if (ts, &other.server_id) > (self.timestamp, &self.server_id) {
            self.value = other.value.clone();
            self.timestamp = ts;
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

// =============================================================================
// Phase 19a: Trust & Membership — Web-of-Trust Join Protocol
// =============================================================================
//
// The membership system governs which servers may join the federation.
// It uses an OR-Set CRDT (OrSet<MembershipEntry>) so that membership
// decisions propagate correctly across the network without central
// coordination.
//
// Join Protocol Flow:
//   1. Bootstrap: Config seeds initial trusted peer keys into MembershipState
//   2. Join Request (over encrypted channel): Joining server sends identity + endorsements
//   3. Validation: Verify endorsement signatures, check endorsers are members, count >= min_endorsements
//   4. Join Response: Accept (with offered endorsement) or reject
//   5. Membership Sync: New member added to OrSet<MembershipEntry>, propagated via CRDT merge
//   6. Endorsement Offer: Any member can endorse a peer separately from join
//   7. Leave: Server sends MembershipLeave, triggers remove_value() in OrSet
//
// Invariant: a server is a member if its MembershipEntry exists in the
// membership OrSet with status Active and has >= min_endorsements from
// other active members.

/// Status of a member in the federation.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MembershipStatus {
    Active,
    Suspended,
    Pending,
}

/// A single server's membership record in the federation.
/// Identified by server_id (which is derived from the verifying key).
///
/// Equality and hashing are based on `server_id` only, so that entries
/// with different endorsement lists (e.g. after concurrent endorsements)
/// collapse into the same OrSet identity. This is critical for CRDT correctness.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MembershipEntry {
    pub server_id: String,
    pub verifying_key_hex: String,
    pub kex_public_hex: String,
    pub endorsed_by: Vec<EndorsementProof>,
    pub joined_at: u64,
    pub status: MembershipStatus,
}

impl PartialEq for MembershipEntry {
    fn eq(&self, other: &Self) -> bool {
        self.server_id == other.server_id
    }
}

impl Eq for MembershipEntry {}

impl std::hash::Hash for MembershipEntry {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.server_id.hash(state);
    }
}

impl MembershipEntry {
    pub fn new(
        server_id: impl Into<String>,
        verifying_key_hex: impl Into<String>,
        kex_public_hex: impl Into<String>,
        endorsed_by: Vec<EndorsementProof>,
        joined_at: u64,
    ) -> Self {
        MembershipEntry {
            server_id: server_id.into(),
            verifying_key_hex: verifying_key_hex.into(),
            kex_public_hex: kex_public_hex.into(),
            endorsed_by,
            joined_at,
            status: MembershipStatus::Active,
        }
    }

    pub fn with_status(mut self, status: MembershipStatus) -> Self {
        self.status = status;
        self
    }

    pub fn is_active(&self) -> bool {
        self.status == MembershipStatus::Active
    }

    pub fn endorsement_count(&self) -> usize {
        self.endorsed_by.len()
    }

    pub fn has_endorsement_from(&self, endorser_server_id: &str) -> bool {
        self.endorsed_by
            .iter()
            .any(|e| e.endorser_server_id == endorser_server_id)
    }

    pub fn key(&self) -> String {
        self.server_id.clone()
    }
}

/// A signed endorsement from one server of another server's membership.
/// The signature covers the canonical transcript of:
///   endorser_server_id || endorsee_server_id || endorsee_verifying_key_hex || timestamp
#[derive(Debug, Clone, Hash, Eq, PartialEq, Serialize, Deserialize)]
pub struct EndorsementProof {
    pub endorser_server_id: String,
    pub endorser_key_id: u64,
    pub endorsee_server_id: String,
    pub endorsee_verifying_key_hex: String,
    pub signature: Vec<u8>,
    pub timestamp: u64,
}

impl EndorsementProof {
    pub fn canonical_transcript(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(
            self.endorser_server_id.len()
                + self.endorsee_server_id.len()
                + self.endorsee_verifying_key_hex.len()
                + 8
                + 8,
        );
        buf.extend_from_slice(self.endorser_server_id.as_bytes());
        buf.push(0);
        buf.extend_from_slice(self.endorsee_server_id.as_bytes());
        buf.push(0);
        buf.extend_from_slice(self.endorsee_verifying_key_hex.as_bytes());
        buf.push(0);
        buf.extend_from_slice(&self.endorser_key_id.to_be_bytes());
        buf.extend_from_slice(&self.timestamp.to_be_bytes());
        buf
    }
}

/// Result of a join request validation.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum JoinResult {
    Accepted {
        server_id: String,
        membership_entry: MembershipEntry,
        offered_endorsement: Option<EndorsementProof>,
    },
    Rejected {
        server_id: String,
        reason: String,
    },
}

/// Result of a membership verification check.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MembershipVerifyResult {
    pub server_id: String,
    pub is_member: bool,
    pub endorsement_count: usize,
    pub min_endorsements: u32,
    pub endorsed_by: Vec<String>,
}

/// The membership state for the entire federation.
/// Wraps an OrSet<MembershipEntry> plus admission policy.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MembershipState {
    members: OrSet<MembershipEntry>,
    min_endorsements: u32,
    bootstrap_mode: bool,
    tag_counter: u64,
}

impl MembershipState {
    pub fn new(min_endorsements: u32) -> Self {
        MembershipState {
            members: OrSet::new(),
            min_endorsements,
            bootstrap_mode: false,
            tag_counter: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos() as u64,
        }
    }

    pub fn new_bootstrap(min_endorsements: u32) -> Self {
        MembershipState {
            members: OrSet::new(),
            min_endorsements,
            bootstrap_mode: true,
            tag_counter: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos() as u64,
        }
    }

    pub fn min_endorsements(&self) -> u32 {
        self.min_endorsements
    }

    pub fn set_min_endorsements(&mut self, n: u32) {
        self.min_endorsements = n;
    }

    pub fn is_bootstrap(&self) -> bool {
        self.bootstrap_mode
    }

    pub fn exit_bootstrap(&mut self) {
        self.bootstrap_mode = false;
    }

    pub(crate) fn next_tag(&mut self, server_id: &str) -> OrSetTag {
        self.tag_counter += 1;
        OrSetTag::new(server_id, self.tag_counter)
    }

    pub fn add_member(&mut self, entry: MembershipEntry, tag: OrSetTag) {
        self.members.add(entry, tag);
    }

    pub fn remove_member(&mut self, server_id: &str) -> bool {
        if let Some(entry) = self.find_member(server_id) {
            self.members.remove_value(&entry);
            return true;
        }
        false
    }

    /// Check if a server is an active member with enough endorsements.
    pub fn is_member(&self, server_id: &str) -> bool {
        match self.find_member(server_id) {
            Some(entry) => entry.is_active() && entry.endorsement_count() >= self.min_endorsements as usize,
            None => false,
        }
    }

    /// Check if a server is a member (even without min endorsements, for bootstrap).
    pub fn is_known_member(&self, server_id: &str) -> bool {
        self.find_member(server_id).is_some()
    }

    /// Find a member entry by server_id.
    /// Merges endorsements from all OrSet entries with the same server_id
    /// to handle concurrent endorsement divergence after CRDT merge.
    pub fn find_member(&self, server_id: &str) -> Option<MembershipEntry> {
        let matching: Vec<&MembershipEntry> = self.members.adds
            .iter()
            .filter(|e| e.value.server_id == server_id)
            .map(|e| &e.value)
            .collect();

        if matching.is_empty() {
            return None;
        }

        let first = matching[0];
        let mut merged = first.clone();

        for entry in &matching[1..] {
            for proof in &entry.endorsed_by {
                if !merged.has_endorsement_from(&proof.endorser_server_id) {
                    merged.endorsed_by.push(proof.clone());
                }
            }
            if entry.joined_at < merged.joined_at {
                merged.joined_at = entry.joined_at;
            }
            if entry.status == MembershipStatus::Active {
                merged.status = MembershipStatus::Active;
            }
        }

        Some(merged)
    }

    /// List all active members (with merged endorsements).
    pub fn active_members(&self) -> Vec<MembershipEntry> {
        let mut seen_ids = HashSet::new();
        let mut result = Vec::new();
        for entry in self.members.adds.iter().map(|e| &e.value) {
            if seen_ids.insert(entry.server_id.clone()) {
                if let Some(merged) = self.find_member(&entry.server_id) {
                    if merged.is_active() {
                        result.push(merged);
                    }
                }
            }
        }
        result
    }

    /// List all members (including pending/suspended, with merged endorsements).
    pub fn all_members(&self) -> Vec<MembershipEntry> {
        let mut seen_ids = HashSet::new();
        let mut result = Vec::new();
        for entry in self.members.adds.iter().map(|e| &e.value) {
            if seen_ids.insert(entry.server_id.clone()) {
                if let Some(merged) = self.find_member(&entry.server_id) {
                    result.push(merged);
                }
            }
        }
        result
    }

    /// Get the number of active members.
    pub fn member_count(&self) -> usize {
        self.active_members().len()
    }

    /// Merge membership state from another server (CRDT merge).
    pub fn merge(&mut self, other: &MembershipState) {
        self.members.merge(&other.members);
    }

    /// Validate a join request: check endorsement proofs.
    pub fn validate_join(&self, entry: &MembershipEntry) -> Result<(), String> {
        if self.find_member(&entry.server_id).is_some() {
            return Err(format!("server {} is already a member", entry.server_id));
        }

        let valid_endorsements: Vec<&EndorsementProof> = entry
            .endorsed_by
            .iter()
            .filter(|proof| {
                if !self.is_known_member(&proof.endorser_server_id) && !self.bootstrap_mode {
                    return false;
                }
                true
            })
            .collect();

        if self.bootstrap_mode && valid_endorsements.is_empty() {
            return Ok(());
        }

        if valid_endorsements.len() < self.min_endorsements as usize {
            return Err(format!(
                "insufficient endorsements: {} < {}",
                valid_endorsements.len(),
                self.min_endorsements
            ));
        }

        Ok(())
    }

    /// Add an endorsement to an existing member's entry.
    /// Returns the updated entry or None if not found.
    pub fn endorse_member(&mut self, server_id: &str, proof: EndorsementProof) -> bool {
        let found = self.find_member(server_id);
        if let Some(entry) = found {
            let mut updated = entry.clone();
            if updated.has_endorsement_from(&proof.endorser_server_id) {
                return true;
            }
            updated.endorsed_by.push(proof);
            self.members.remove_value(&entry);
            let tag = self.next_tag(&updated.server_id);
            self.members.add(updated, tag);
            return true;
        }
        false
    }

    /// Export for wire protocol.
    pub fn to_orset(&self) -> &OrSet<MembershipEntry> {
        &self.members
    }

    /// Import from wire protocol (merge).
    pub fn merge_orset(&mut self, other: &OrSet<MembershipEntry>) {
        self.members.merge(other);
    }
}

// =============================================================================
// Phase 19b: Governance & BFT — PBFT Consensus for Federation Decisions
// =============================================================================
//
// The Governance Plane uses a lightweight PBFT (Practical Byzantine Fault
// Tolerance) consensus protocol for 3-10 federation members. It provides:
//
// - Total ordering of governance transactions
// - Byzantine fault tolerance (f faulty nodes tolerated in 3f+1)
// - One truth, no forks
//
// Transaction types:
//   Admit(server_id)     — Formally admit a member
//   Expel(server_id)     — Remove a member by consensus
//   KeyRegister(...)     — Register/rotate a server's cryptographic keys
//   RoyaltyRecord(...)   — Record a transclusion royalty obligation
//
// PBFT phases:
//   1. PRE-PREPARE: Leader proposes a batch of transactions with sequence number
//   2. PREPARE:     Replicas validate and broadcast prepare votes
//   3. COMMIT:      Replicas broadcast commit votes after sufficient prepares
//   4. EXECUTE:     After sufficient commits, transactions are applied to state

/// A governance transaction that must be agreed upon via PBFT consensus.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum GovernanceTx {
    Admit {
        server_id: String,
        verifying_key_hex: String,
        kex_public_hex: String,
    },
    Expel {
        server_id: String,
        reason: String,
    },
    KeyRegister {
        server_id: String,
        key_id: u64,
        verifying_key_hex: String,
        kex_public_hex: String,
    },
    RoyaltyRecord {
        origin_server_id: String,
        target_server_id: String,
        content_fingerprint_hex: String,
        royalty_type: RoyaltyType,
        amount: u64,
    },
}

impl GovernanceTx {
    pub fn tx_type_name(&self) -> &'static str {
        match self {
            GovernanceTx::Admit { .. } => "admit",
            GovernanceTx::Expel { .. } => "expel",
            GovernanceTx::KeyRegister { .. } => "key_register",
            GovernanceTx::RoyaltyRecord { .. } => "royalty_record",
        }
    }
}

/// A batch of governance transactions proposed for consensus.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct GovernanceProposal {
    pub view_number: u64,
    pub sequence_number: u64,
    pub transactions: Vec<GovernanceTx>,
    pub proposer_id: String,
    pub timestamp: u64,
}

/// A PBFT vote (used for both Prepare and Commit phases).
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct PbftVote {
    pub view_number: u64,
    pub sequence_number: u64,
    pub voter_id: String,
    pub phase: PbftPhase,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PbftPhase {
    Prepare,
    Commit,
}

/// A sealed (fully committed) governance batch in the log.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SealedBatch {
    pub view_number: u64,
    pub sequence_number: u64,
    pub transactions: Vec<GovernanceTx>,
    pub proposer_id: String,
    pub timestamp: u64,
    pub prepare_votes: Vec<String>,
    pub commit_votes: Vec<String>,
}

/// The state of a single ongoing consensus round.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConsensusRound {
    pub proposal: GovernanceProposal,
    pub prepare_votes: HashSet<String>,
    pub commit_votes: HashSet<String>,
    pub phase: RoundPhase,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RoundPhase {
    PrePrepare,
    Prepare,
    Commit,
    Sealed,
}

/// The complete governance state for a federation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernanceState {
    log: Vec<SealedBatch>,
    current_view: u64,
    current_sequence: u64,
    pending_round: Option<ConsensusRound>,
    cluster_size: usize,
    faulty_tolerance: usize,
    tag_counter: u64,
    applied_sequences: HashSet<u64>,
}

impl GovernanceState {
    pub fn new(cluster_size: usize) -> Self {
        let faulty_tolerance = (cluster_size.saturating_sub(1)) / 3;
        GovernanceState {
            log: Vec::new(),
            current_view: 0,
            current_sequence: 0,
            pending_round: None,
            cluster_size,
            faulty_tolerance,
            tag_counter: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos() as u64,
            applied_sequences: HashSet::new(),
        }
    }

    pub fn cluster_size(&self) -> usize {
        self.cluster_size
    }

    pub fn set_cluster_size(&mut self, n: usize) {
        self.cluster_size = n;
        self.faulty_tolerance = (n.saturating_sub(1)) / 3;
    }

    pub fn faulty_tolerance(&self) -> usize {
        self.faulty_tolerance
    }

    pub fn quorum_size(&self) -> usize {
        2 * self.faulty_tolerance + 1
    }

    pub fn current_view(&self) -> u64 {
        self.current_view
    }

    pub fn current_sequence(&self) -> u64 {
        self.current_sequence
    }

    pub fn log(&self) -> &[SealedBatch] {
        &self.log
    }

    pub fn log_len(&self) -> usize {
        self.log.len()
    }

    pub fn pending_round(&self) -> Option<&ConsensusRound> {
        self.pending_round.as_ref()
    }

    pub fn is_leader(&self, server_id: &str, members: &[String]) -> bool {
        if members.is_empty() {
            return false;
        }
        let leader_idx = self.current_view as usize % members.len();
        members.get(leader_idx).map(|s| s.as_str()) == Some(server_id)
        }

    pub fn leader_id(&self, members: &[String]) -> Option<String> {
        if members.is_empty() {
            return None;
        }
        let leader_idx = self.current_view as usize % members.len();
        members.get(leader_idx).cloned()
    }

    fn next_tag(&mut self) -> u64 {
        self.tag_counter += 1;
        self.tag_counter
    }

    pub fn propose(&mut self, transactions: Vec<GovernanceTx>, proposer_id: String) -> Option<GovernanceProposal> {
        if self.pending_round.is_some() {
            return None;
        }
        let seq = self.current_sequence + 1;
        let proposal = GovernanceProposal {
            view_number: self.current_view,
            sequence_number: seq,
            transactions,
            proposer_id,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
        };

        self.pending_round = Some(ConsensusRound {
            proposal: proposal.clone(),
            prepare_votes: {
                let mut s = HashSet::new();
                s.insert(proposal.proposer_id.clone());
                s
            },
            commit_votes: HashSet::new(),
            phase: RoundPhase::Prepare,
        });

        Some(proposal)
    }

    pub fn receive_prepare(&mut self, vote: PbftVote) -> RoundPhase {
        let quorum = self.quorum_size();
        let round = match &mut self.pending_round {
            Some(r) => r,
            None => return RoundPhase::PrePrepare,
        };

        if round.phase != RoundPhase::Prepare && round.phase != RoundPhase::PrePrepare {
            return round.phase;
        }

        if vote.view_number != round.proposal.view_number
            || vote.sequence_number != round.proposal.sequence_number
        {
            return round.phase;
        }

        round.prepare_votes.insert(vote.voter_id.clone());
        round.phase = RoundPhase::Prepare;

        if round.prepare_votes.len() >= quorum {
            round.phase = RoundPhase::Commit;
        }

        round.phase
    }

    pub fn receive_commit(&mut self, vote: PbftVote) -> RoundPhase {
        let quorum = self.quorum_size();
        let round = match &mut self.pending_round {
            Some(r) => r,
            None => return RoundPhase::PrePrepare,
        };

        if round.phase != RoundPhase::Commit {
            return round.phase;
        }

        if vote.view_number != round.proposal.view_number
            || vote.sequence_number != round.proposal.sequence_number
        {
            return round.phase;
        }

        round.commit_votes.insert(vote.voter_id.clone());

        if round.commit_votes.len() >= quorum {
            round.phase = RoundPhase::Sealed;
            return RoundPhase::Sealed;
        }

        RoundPhase::Commit
    }

    pub fn seal_round(&mut self) -> Option<SealedBatch> {
        let round = self.pending_round.take()?;
        if round.phase != RoundPhase::Sealed {
            self.pending_round = Some(round);
            return None;
        }

        let sealed = SealedBatch {
            view_number: round.proposal.view_number,
            sequence_number: round.proposal.sequence_number,
            transactions: round.proposal.transactions,
            proposer_id: round.proposal.proposer_id,
            timestamp: round.proposal.timestamp,
            prepare_votes: round.prepare_votes.into_iter().collect(),
            commit_votes: round.commit_votes.into_iter().collect(),
        };

        self.current_sequence = sealed.sequence_number;
        self.applied_sequences.insert(sealed.sequence_number);
        self.log.push(sealed.clone());
        Some(sealed)
    }

    pub fn advance_view(&mut self) {
        self.current_view += 1;
        self.pending_round = None;
    }

    pub fn apply_sealed(&self, batch: &SealedBatch) -> Vec<GovernanceTx> {
        batch.transactions.clone()
    }

    pub fn is_applied(&self, sequence_number: u64) -> bool {
        self.applied_sequences.contains(&sequence_number)
    }

    pub fn mark_applied(&mut self, sequence_number: u64) {
        self.applied_sequences.insert(sequence_number);
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

    // =====================================================================
    // Phase 19a: MembershipEntry Tests
    // =====================================================================

    fn make_membership_entry(
        server_id: &str,
        endorsements: Vec<EndorsementProof>,
        ts: u64,
    ) -> MembershipEntry {
        MembershipEntry::new(
            server_id,
            format!("vk-{}", server_id),
            format!("kex-{}", server_id),
            endorsements,
            ts,
        )
    }

    fn make_endorsement_proof(endorser: &str, endorsee: &str, ts: u64) -> EndorsementProof {
        EndorsementProof {
            endorser_server_id: endorser.to_string(),
            endorser_key_id: 1,
            endorsee_server_id: endorsee.to_string(),
            endorsee_verifying_key_hex: format!("vk-{}", endorsee),
            signature: vec![0u8; 64],
            timestamp: ts,
        }
    }

    #[test]
    fn membership_entry_new() {
        let entry = make_membership_entry("srv-a", vec![], 1000);
        assert_eq!(entry.server_id, "srv-a");
        assert_eq!(entry.verifying_key_hex, "vk-srv-a");
        assert_eq!(entry.kex_public_hex, "kex-srv-a");
        assert!(entry.endorsed_by.is_empty());
        assert_eq!(entry.joined_at, 1000);
        assert!(entry.is_active());
        assert_eq!(entry.status, MembershipStatus::Active);
    }

    #[test]
    fn membership_entry_with_status() {
        let entry = make_membership_entry("srv-a", vec![], 1000)
            .with_status(MembershipStatus::Suspended);
        assert_eq!(entry.status, MembershipStatus::Suspended);
        assert!(!entry.is_active());
    }

    #[test]
    fn membership_entry_endorsement_count() {
        let proofs = vec![
            make_endorsement_proof("srv-b", "srv-a", 100),
            make_endorsement_proof("srv-c", "srv-a", 101),
        ];
        let entry = make_membership_entry("srv-a", proofs, 1000);
        assert_eq!(entry.endorsement_count(), 2);
    }

    #[test]
    fn membership_entry_has_endorsement_from() {
        let proofs = vec![
            make_endorsement_proof("srv-b", "srv-a", 100),
        ];
        let entry = make_membership_entry("srv-a", proofs, 1000);
        assert!(entry.has_endorsement_from("srv-b"));
        assert!(!entry.has_endorsement_from("srv-c"));
    }

    #[test]
    fn membership_entry_key() {
        let entry = make_membership_entry("srv-a", vec![], 1000);
        assert_eq!(entry.key(), "srv-a");
    }

    #[test]
    fn membership_entry_serialize_roundtrip() {
        let proofs = vec![
            make_endorsement_proof("srv-b", "srv-a", 100),
            make_endorsement_proof("srv-c", "srv-a", 101),
        ];
        let entry = make_membership_entry("srv-a", proofs, 1000);
        let json = serde_json::to_string(&entry).unwrap();
        let back: MembershipEntry = serde_json::from_str(&json).unwrap();
        assert_eq!(back.server_id, "srv-a");
        assert_eq!(back.endorsed_by.len(), 2);
        assert!(back.is_active());
    }

    #[test]
    fn membership_status_serialize_roundtrip() {
        let statuses = vec![
            MembershipStatus::Active,
            MembershipStatus::Suspended,
            MembershipStatus::Pending,
        ];
        for status in statuses {
            let json = serde_json::to_string(&status).unwrap();
            let back: MembershipStatus = serde_json::from_str(&json).unwrap();
            assert_eq!(status, back);
        }
    }

    // =====================================================================
    // Phase 19a: EndorsementProof Tests
    // =====================================================================

    #[test]
    fn endorsement_proof_canonical_transcript_deterministic() {
        let proof = make_endorsement_proof("srv-a", "srv-b", 1000);
        let t1 = proof.canonical_transcript();
        let t2 = proof.canonical_transcript();
        assert_eq!(t1, t2, "transcript must be deterministic");
    }

    #[test]
    fn endorsement_proof_canonical_transcript_unique_per_endorser() {
        let proof_a = make_endorsement_proof("srv-a", "srv-b", 1000);
        let proof_c = make_endorsement_proof("srv-c", "srv-b", 1000);
        assert_ne!(
            proof_a.canonical_transcript(),
            proof_c.canonical_transcript(),
            "different endorsers must produce different transcripts"
        );
    }

    #[test]
    fn endorsement_proof_canonical_transcript_unique_per_endorsee() {
        let proof_b = make_endorsement_proof("srv-a", "srv-b", 1000);
        let proof_c = make_endorsement_proof("srv-a", "srv-c", 1000);
        assert_ne!(
            proof_b.canonical_transcript(),
            proof_c.canonical_transcript(),
            "different endorsees must produce different transcripts"
        );
    }

    #[test]
    fn endorsement_proof_canonical_transcript_unique_per_timestamp() {
        let proof_1 = make_endorsement_proof("srv-a", "srv-b", 1000);
        let proof_2 = make_endorsement_proof("srv-a", "srv-b", 2000);
        assert_ne!(
            proof_1.canonical_transcript(),
            proof_2.canonical_transcript(),
            "different timestamps must produce different transcripts"
        );
    }

    #[test]
    fn endorsement_proof_serialize_roundtrip() {
        let proof = make_endorsement_proof("srv-a", "srv-b", 1000);
        let json = serde_json::to_string(&proof).unwrap();
        let back: EndorsementProof = serde_json::from_str(&json).unwrap();
        assert_eq!(back.endorser_server_id, "srv-a");
        assert_eq!(back.endorsee_server_id, "srv-b");
        assert_eq!(back.timestamp, 1000);
        assert_eq!(back.signature.len(), 64);
    }

    // =====================================================================
    // Phase 19a: MembershipState Tests
    // =====================================================================

    #[test]
    fn membership_state_new_empty() {
        let state = MembershipState::new(2);
        assert_eq!(state.min_endorsements(), 2);
        assert_eq!(state.member_count(), 0);
        assert!(!state.is_bootstrap());
    }

    #[test]
    fn membership_state_bootstrap_mode() {
        let mut state = MembershipState::new_bootstrap(2);
        assert!(state.is_bootstrap());
        state.exit_bootstrap();
        assert!(!state.is_bootstrap());
    }

    #[test]
    fn membership_state_add_and_find_member() {
        let mut state = MembershipState::new(2);
        let entry = make_membership_entry("srv-a", vec![], 1000);
        let tag = OrSetTag::new("srv-a", 1);
        state.add_member(entry, tag);

        assert!(state.find_member("srv-a").is_some());
        assert!(state.find_member("srv-b").is_none());
    }

    #[test]
    fn membership_state_is_member_requires_endorsements() {
        let mut state = MembershipState::new(2);
        let entry = make_membership_entry("srv-a", vec![], 1000);
        let tag = OrSetTag::new("srv-a", 1);
        state.add_member(entry, tag);

        assert!(!state.is_member("srv-a"), "0 endorsements < min 2");
    }

    #[test]
    fn membership_state_is_member_with_enough_endorsements() {
        let mut state = MembershipState::new(2);
        let proofs = vec![
            make_endorsement_proof("srv-b", "srv-a", 100),
            make_endorsement_proof("srv-c", "srv-a", 101),
        ];
        let entry = make_membership_entry("srv-a", proofs, 1000);
        let tag = OrSetTag::new("srv-a", 1);
        state.add_member(entry, tag);

        assert!(state.is_member("srv-a"), "2 endorsements >= min 2");
    }

    #[test]
    fn membership_state_is_member_suspended_is_false() {
        let mut state = MembershipState::new(0);
        let entry = make_membership_entry("srv-a", vec![], 1000)
            .with_status(MembershipStatus::Suspended);
        let tag = OrSetTag::new("srv-a", 1);
        state.add_member(entry, tag);

        assert!(!state.is_member("srv-a"), "suspended member should not be active");
    }

    #[test]
    fn membership_state_is_known_member_ignores_endorsements() {
        let mut state = MembershipState::new(2);
        let entry = make_membership_entry("srv-a", vec![], 1000);
        let tag = OrSetTag::new("srv-a", 1);
        state.add_member(entry, tag);

        assert!(state.is_known_member("srv-a"), "known even without endorsements");
        assert!(!state.is_member("srv-a"), "but not a full member");
    }

    #[test]
    fn membership_state_remove_member() {
        let mut state = MembershipState::new(0);
        let entry = make_membership_entry("srv-a", vec![], 1000);
        let tag = OrSetTag::new("srv-a", 1);
        state.add_member(entry, tag);

        assert!(state.remove_member("srv-a"));
        assert!(!state.is_known_member("srv-a"));
        assert!(!state.remove_member("srv-a"), "already removed");
    }

    #[test]
    fn membership_state_active_members_filters_suspended() {
        let mut state = MembershipState::new(0);
        let entry_a = make_membership_entry("srv-a", vec![], 1000);
        let entry_b = make_membership_entry("srv-b", vec![], 1000)
            .with_status(MembershipStatus::Suspended);
        state.add_member(entry_a, OrSetTag::new("tag", 1));
        state.add_member(entry_b, OrSetTag::new("tag", 2));

        let active = state.active_members();
        assert_eq!(active.len(), 1);
        assert_eq!(active[0].server_id, "srv-a");
    }

    #[test]
    fn membership_state_all_members_includes_suspended() {
        let mut state = MembershipState::new(0);
        let entry_a = make_membership_entry("srv-a", vec![], 1000);
        let entry_b = make_membership_entry("srv-b", vec![], 1000)
            .with_status(MembershipStatus::Suspended);
        state.add_member(entry_a, OrSetTag::new("tag", 1));
        state.add_member(entry_b, OrSetTag::new("tag", 2));

        let all = state.all_members();
        assert_eq!(all.len(), 2);
    }

    #[test]
    fn membership_state_member_count() {
        let mut state = MembershipState::new(0);
        assert_eq!(state.member_count(), 0);

        state.add_member(
            make_membership_entry("srv-a", vec![], 1000),
            OrSetTag::new("tag", 1),
        );
        assert_eq!(state.member_count(), 1);

        state.add_member(
            make_membership_entry("srv-b", vec![], 1000)
                .with_status(MembershipStatus::Suspended),
            OrSetTag::new("tag", 2),
        );
        assert_eq!(state.member_count(), 1, "suspended not counted");
    }

    #[test]
    fn membership_state_set_min_endorsements() {
        let mut state = MembershipState::new(2);
        assert_eq!(state.min_endorsements(), 2);
        state.set_min_endorsements(5);
        assert_eq!(state.min_endorsements(), 5);
    }

    // =====================================================================
    // Phase 19a: Membership Validation Tests
    // =====================================================================

    #[test]
    fn membership_validate_join_rejects_existing_member() {
        let mut state = MembershipState::new(0);
        let entry = make_membership_entry("srv-a", vec![], 1000);
        state.add_member(entry.clone(), OrSetTag::new("tag", 1));

        let result = state.validate_join(&entry);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("already a member"));
    }

    #[test]
    fn membership_validate_join_bootstrap_allows_no_endorsements() {
        let state = MembershipState::new_bootstrap(2);
        let entry = make_membership_entry("srv-new", vec![], 1000);
        assert!(state.validate_join(&entry).is_ok());
    }

    #[test]
    fn membership_validate_join_rejects_insufficient_endorsements() {
        let mut state = MembershipState::new(2);
        let proofs = vec![
            make_endorsement_proof("srv-b", "srv-new", 100),
        ];
        let entry = make_membership_entry("srv-new", proofs, 1000);

        let result = state.validate_join(&entry);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("insufficient endorsements"));
    }

    #[test]
    fn membership_validate_join_accepts_enough_endorsements() {
        let mut state = MembershipState::new(2);
        state.add_member(
            make_membership_entry("srv-b", vec![], 900),
            OrSetTag::new("tag", 1),
        );
        state.add_member(
            make_membership_entry("srv-c", vec![], 900),
            OrSetTag::new("tag", 2),
        );
        let proofs = vec![
            make_endorsement_proof("srv-b", "srv-new", 100),
            make_endorsement_proof("srv-c", "srv-new", 101),
        ];
        let entry = make_membership_entry("srv-new", proofs, 1000);
        assert!(state.validate_join(&entry).is_ok());
    }

    #[test]
    fn membership_validate_join_filters_non_member_endorsers() {
        let mut state = MembershipState::new(2);
        state.add_member(
            make_membership_entry("srv-b", vec![], 900),
            OrSetTag::new("tag", 1),
        );
        let proofs = vec![
            make_endorsement_proof("srv-b", "srv-new", 100),
            make_endorsement_proof("srv-unknown", "srv-new", 101),
        ];
        let entry = make_membership_entry("srv-new", proofs, 1000);

        let result = state.validate_join(&entry);
        assert!(result.is_err(), "only 1 endorsement from member, need 2");
    }

    // =====================================================================
    // Phase 19a: Membership Endorsement Tests
    // =====================================================================

    #[test]
    fn membership_endorse_member_adds_endorsement() {
        let mut state = MembershipState::new(2);
        let entry = make_membership_entry("srv-a", vec![], 1000);
        state.add_member(entry, OrSetTag::new("tag", 1));

        let proof = make_endorsement_proof("srv-b", "srv-a", 200);
        let result = state.endorse_member("srv-a", proof);
        assert!(result);

        let found = state.find_member("srv-a").unwrap();
        assert_eq!(found.endorsement_count(), 1);
        assert!(found.has_endorsement_from("srv-b"));
    }

    #[test]
    fn membership_endorse_member_idempotent_same_endorser() {
        let mut state = MembershipState::new(2);
        let entry = make_membership_entry("srv-a", vec![], 1000);
        state.add_member(entry, OrSetTag::new("tag", 1));

        let proof1 = make_endorsement_proof("srv-b", "srv-a", 200);
        let proof2 = make_endorsement_proof("srv-b", "srv-a", 300);
        state.endorse_member("srv-a", proof1);
        state.endorse_member("srv-a", proof2);

        let found = state.find_member("srv-a").unwrap();
        assert_eq!(found.endorsement_count(), 1, "same endorser should not duplicate");
    }

    #[test]
    fn membership_endorse_member_unknown_server() {
        let mut state = MembershipState::new(2);
        let proof = make_endorsement_proof("srv-b", "srv-unknown", 200);
        let result = state.endorse_member("srv-unknown", proof);
        assert!(!result);
    }

    #[test]
    fn membership_endorse_upgrades_to_full_member() {
        let mut state = MembershipState::new(2);
        state.add_member(
            make_membership_entry("srv-b", vec![], 900),
            OrSetTag::new("srv-b", 1),
        );
        state.add_member(
            make_membership_entry("srv-c", vec![], 900),
            OrSetTag::new("srv-c", 1),
        );
        let entry = make_membership_entry("srv-a", vec![], 1000);
        state.add_member(entry, OrSetTag::new("tag", 1));

        assert!(!state.is_member("srv-a"));

        state.endorse_member("srv-a", make_endorsement_proof("srv-b", "srv-a", 200));
        assert!(!state.is_member("srv-a"), "1 endorsement < min 2");

        state.endorse_member("srv-a", make_endorsement_proof("srv-c", "srv-a", 201));
        assert!(state.is_member("srv-a"), "2 endorsements >= min 2");
    }

    // =====================================================================
    // Phase 19a: Membership CRDT Merge Tests
    // =====================================================================

    #[test]
    fn membership_merge_union_of_members() {
        let mut state_a = MembershipState::new(0);
        state_a.add_member(
            make_membership_entry("srv-a", vec![], 1000),
            OrSetTag::new("tag", 1),
        );

        let mut state_b = MembershipState::new(0);
        state_b.add_member(
            make_membership_entry("srv-b", vec![], 1000),
            OrSetTag::new("tag", 2),
        );

        state_a.merge(&state_b);
        assert!(state_a.is_known_member("srv-a"));
        assert!(state_a.is_known_member("srv-b"));
    }

    #[test]
    fn membership_merge_is_commutative() {
        let mut state_a = MembershipState::new(0);
        state_a.add_member(
            make_membership_entry("srv-a", vec![], 1000),
            OrSetTag::new("tag", 1),
        );

        let mut state_b = MembershipState::new(0);
        state_b.add_member(
            make_membership_entry("srv-b", vec![], 1000),
            OrSetTag::new("tag", 2),
        );

        let mut merged_ab = state_a.clone();
        merged_ab.merge(&state_b);

        let mut merged_ba = state_b.clone();
        merged_ba.merge(&state_a);

        let mut members_ab: Vec<String> = merged_ab.all_members()
            .iter().map(|m| m.server_id.clone()).collect();
        members_ab.sort();
        let mut members_ba: Vec<String> = merged_ba.all_members()
            .iter().map(|m| m.server_id.clone()).collect();
        members_ba.sort();
        assert_eq!(members_ab, members_ba);
    }

    #[test]
    fn membership_merge_is_idempotent() {
        let mut state = MembershipState::new(0);
        state.add_member(
            make_membership_entry("srv-a", vec![], 1000),
            OrSetTag::new("tag", 1),
        );

        let snapshot = state.clone();
        state.merge(&snapshot);
        assert_eq!(state.all_members().len(), 1);
    }

    #[test]
    fn membership_merge_three_way_converges() {
        let mut a = MembershipState::new(0);
        a.add_member(make_membership_entry("srv-a", vec![], 1000), OrSetTag::new("tag", 1));

        let mut b = MembershipState::new(0);
        b.add_member(make_membership_entry("srv-b", vec![], 1000), OrSetTag::new("tag", 2));

        let mut c = MembershipState::new(0);
        c.add_member(make_membership_entry("srv-c", vec![], 1000), OrSetTag::new("tag", 3));

        a.merge(&b);
        a.merge(&c);
        b.merge(&a);
        c.merge(&a);

        let mut members_a: Vec<String> = a.all_members().iter().map(|m| m.server_id.clone()).collect();
        members_a.sort();
        let mut members_b: Vec<String> = b.all_members().iter().map(|m| m.server_id.clone()).collect();
        members_b.sort();
        let mut members_c: Vec<String> = c.all_members().iter().map(|m| m.server_id.clone()).collect();
        members_c.sort();

        assert_eq!(members_a, members_b);
        assert_eq!(members_b, members_c);
    }

    #[test]
    fn membership_merge_orset_preserves_removals() {
        let mut state_a = MembershipState::new(0);
        state_a.add_member(
            make_membership_entry("srv-a", vec![], 1000),
            OrSetTag::new("tag", 1),
        );
        state_a.add_member(
            make_membership_entry("srv-b", vec![], 1000),
            OrSetTag::new("tag", 2),
        );
        state_a.remove_member("srv-b");

        let mut state_b = MembershipState::new(0);
        state_b.add_member(
            make_membership_entry("srv-a", vec![], 1000),
            OrSetTag::new("tag", 1),
        );
        state_b.add_member(
            make_membership_entry("srv-b", vec![], 1000),
            OrSetTag::new("tag", 2),
        );

        state_b.merge(&state_a);
        assert!(state_b.is_known_member("srv-a"));
        assert!(!state_b.is_known_member("srv-b"), "removal should propagate via CRDT merge");
    }

    // =====================================================================
    // Phase 19a: MembershipState Serialization
    // =====================================================================

    #[test]
    fn membership_state_serialize_roundtrip() {
        let mut state = MembershipState::new(2);
        let proofs = vec![
            make_endorsement_proof("srv-b", "srv-a", 100),
            make_endorsement_proof("srv-c", "srv-a", 101),
        ];
        state.add_member(
            make_membership_entry("srv-a", proofs, 1000),
            OrSetTag::new("tag", 1),
        );

        let json = serde_json::to_string(&state).unwrap();
        let back: MembershipState = serde_json::from_str(&json).unwrap();
        assert_eq!(back.min_endorsements(), 2);
        assert_eq!(back.member_count(), 1);
        assert!(back.is_member("srv-a"));
    }

    #[test]
    fn join_result_serialize_roundtrip_accepted() {
        let entry = make_membership_entry("srv-a", vec![], 1000);
        let proof = make_endorsement_proof("srv-b", "srv-a", 200);
        let result = JoinResult::Accepted {
            server_id: "srv-a".to_string(),
            membership_entry: entry,
            offered_endorsement: Some(proof),
        };
        let json = serde_json::to_string(&result).unwrap();
        let back: JoinResult = serde_json::from_str(&json).unwrap();
        match back {
            JoinResult::Accepted { server_id, .. } => assert_eq!(server_id, "srv-a"),
            JoinResult::Rejected { .. } => panic!("expected Accepted"),
        }
    }

    #[test]
    fn join_result_serialize_roundtrip_rejected() {
        let result = JoinResult::Rejected {
            server_id: "srv-a".to_string(),
            reason: "insufficient endorsements".to_string(),
        };
        let json = serde_json::to_string(&result).unwrap();
        let back: JoinResult = serde_json::from_str(&json).unwrap();
        match back {
            JoinResult::Rejected { reason, .. } => {
                assert!(reason.contains("insufficient"));
            }
            JoinResult::Accepted { .. } => panic!("expected Rejected"),
        }
    }

    #[test]
    fn membership_verify_result_serialize() {
        let result = MembershipVerifyResult {
            server_id: "srv-a".to_string(),
            is_member: true,
            endorsement_count: 3,
            min_endorsements: 2,
            endorsed_by: vec!["srv-b".to_string(), "srv-c".to_string(), "srv-d".to_string()],
        };
        let json = serde_json::to_string(&result).unwrap();
        let back: MembershipVerifyResult = serde_json::from_str(&json).unwrap();
        assert!(back.is_member);
        assert_eq!(back.endorsement_count, 3);
        assert_eq!(back.endorsed_by.len(), 3);
    }

    // =====================================================================
    // Phase 19a: FederationState Integration with Membership
    // =====================================================================

    #[test]
    fn federation_state_has_membership() {
        let mut state = FederationState::new(FederationConfig::closed(vec![]));
        assert_eq!(state.membership().member_count(), 0);

        state.membership_mut().add_member(
            make_membership_entry("srv-a", vec![], 1000),
            OrSetTag::new("tag", 1),
        );
        assert_eq!(state.membership().member_count(), 1);
    }

    // =====================================================================
    // Phase 19a Review Regression Tests
    // =====================================================================

    #[test]
    fn membership_eq_based_on_server_id_only() {
        let entry_a = MembershipEntry::new("srv-x", "vk-1", "kex-1", vec![], 1000);
        let mut entry_b = MembershipEntry::new("srv-x", "vk-1", "kex-1", vec![], 1000);
        entry_b.endorsed_by.push(make_endorsement_proof("srv-b", "srv-x", 200));
        assert_eq!(entry_a, entry_b, "entries with same server_id must be equal");

        let entry_c = MembershipEntry::new("srv-y", "vk-2", "kex-2", vec![], 1000);
        assert_ne!(entry_a, entry_c, "entries with different server_id must not be equal");
    }

    #[test]
    fn membership_hash_based_on_server_id_only() {
        let entry_a = MembershipEntry::new("srv-x", "vk-1", "kex-1", vec![], 1000);
        let mut entry_b = MembershipEntry::new("srv-x", "vk-1", "kex-1", vec![], 1000);
        entry_b.endorsed_by.push(make_endorsement_proof("srv-b", "srv-x", 200));
        let mut set = std::collections::HashSet::new();
        set.insert(entry_a);
        assert!(set.contains(&entry_b), "hash must match for same server_id");
    }

    #[test]
    fn membership_concurrent_endorsement_merge_converges() {
        let mut state_a = MembershipState::new(2);
        state_a.add_member(
            make_membership_entry("srv-b", vec![], 900),
            OrSetTag::new("srv-b", 1),
        );
        state_a.add_member(
            make_membership_entry("srv-x", vec![], 1000),
            OrSetTag::new("srv-x", 1),
        );
        state_a.endorse_member("srv-x", make_endorsement_proof("srv-b", "srv-x", 200));

        assert!(!state_a.is_member("srv-x"), "only 1 endorsement in A");

        let mut state_b = MembershipState::new(2);
        state_b.add_member(
            make_membership_entry("srv-c", vec![], 900),
            OrSetTag::new("srv-c", 1),
        );
        state_b.add_member(
            make_membership_entry("srv-x", vec![], 1000),
            OrSetTag::new("srv-x", 1),
        );
        state_b.endorse_member("srv-x", make_endorsement_proof("srv-c", "srv-x", 201));

        assert!(!state_b.is_member("srv-x"), "only 1 endorsement in B");

        state_a.merge(&state_b);

        assert!(state_a.is_known_member("srv-x"), "srv-x should be known after merge");

        let entry = state_a.find_member("srv-x").expect("srv-x should exist after merge");
        assert!(
            entry.endorsement_count() >= 2,
            "after merge, endorsements from both servers must be visible, got {}",
            entry.endorsement_count()
        );
        assert!(state_a.is_member("srv-x"), "2 endorsements >= min 2");
    }

    // =====================================================================
    // Phase 19b: Governance & BFT Tests
    // =====================================================================

    #[test]
    fn governance_state_new() {
        let gov = GovernanceState::new(4);
        assert_eq!(gov.cluster_size(), 4);
        assert_eq!(gov.faulty_tolerance(), 1);
        assert_eq!(gov.quorum_size(), 3);
        assert_eq!(gov.current_view(), 0);
        assert_eq!(gov.current_sequence(), 0);
        assert!(gov.log().is_empty());
        assert!(gov.pending_round().is_none());
    }

    #[test]
    fn governance_quorum_for_various_cluster_sizes() {
        assert_eq!(GovernanceState::new(1).quorum_size(), 1);
        assert_eq!(GovernanceState::new(3).quorum_size(), 1);
        assert_eq!(GovernanceState::new(4).quorum_size(), 3);
        assert_eq!(GovernanceState::new(7).quorum_size(), 5);
        assert_eq!(GovernanceState::new(10).quorum_size(), 7);
    }

    #[test]
    fn governance_leader_rotation() {
        let gov = GovernanceState::new(3);
        let members = vec!["srv-a".to_string(), "srv-b".to_string(), "srv-c".to_string()];
        assert!(gov.is_leader("srv-a", &members));
        assert!(!gov.is_leader("srv-b", &members));
        assert_eq!(gov.leader_id(&members), Some("srv-a".to_string()));
    }

    #[test]
    fn governance_leader_view_rotation() {
        let mut gov = GovernanceState::new(3);
        let members = vec!["srv-a".to_string(), "srv-b".to_string(), "srv-c".to_string()];
        assert!(gov.is_leader("srv-a", &members));
        gov.advance_view();
        assert!(gov.is_leader("srv-b", &members));
        gov.advance_view();
        assert!(gov.is_leader("srv-c", &members));
        gov.advance_view();
        assert!(gov.is_leader("srv-a", &members));
    }

    #[test]
    fn governance_propose_creates_round() {
        let mut gov = GovernanceState::new(3);
        let tx = GovernanceTx::Admit {
            server_id: "srv-new".to_string(),
            verifying_key_hex: "vk-new".to_string(),
            kex_public_hex: "kex-new".to_string(),
        };

        let proposal = gov.propose(vec![tx], "srv-a".to_string()).unwrap();
        assert_eq!(proposal.view_number, 0);
        assert_eq!(proposal.sequence_number, 1);
        assert_eq!(proposal.transactions.len(), 1);
        assert_eq!(proposal.proposer_id, "srv-a");

        let round = gov.pending_round().unwrap();
        assert_eq!(round.phase, RoundPhase::Prepare);
        assert!(round.prepare_votes.contains("srv-a"));
    }

    #[test]
    fn governance_full_consensus_four_nodes() {
        let mut gov = GovernanceState::new(4);
        let tx = GovernanceTx::Expel {
            server_id: "srv-bad".to_string(),
            reason: "malicious".to_string(),
        };

        gov.propose(vec![tx], "srv-a".to_string());

        assert_eq!(gov.pending_round().unwrap().phase, RoundPhase::Prepare);

        let vote_b = PbftVote {
            view_number: 0, sequence_number: 1,
            voter_id: "srv-b".to_string(), phase: PbftPhase::Prepare,
        };
        let phase = gov.receive_prepare(vote_b);
        assert_eq!(phase, RoundPhase::Prepare, "2 prepares < quorum 3");

        let vote_c = PbftVote {
            view_number: 0, sequence_number: 1,
            voter_id: "srv-c".to_string(), phase: PbftPhase::Prepare,
        };
        let phase = gov.receive_prepare(vote_c);
        assert_eq!(phase, RoundPhase::Commit, "3 prepares >= quorum 3");

        let commit_a = PbftVote {
            view_number: 0, sequence_number: 1,
            voter_id: "srv-a".to_string(), phase: PbftPhase::Commit,
        };
        let phase = gov.receive_commit(commit_a);
        assert_eq!(phase, RoundPhase::Commit);

        let commit_b = PbftVote {
            view_number: 0, sequence_number: 1,
            voter_id: "srv-b".to_string(), phase: PbftPhase::Commit,
        };
        let phase = gov.receive_commit(commit_b);
        assert_eq!(phase, RoundPhase::Commit);

        let commit_c = PbftVote {
            view_number: 0, sequence_number: 1,
            voter_id: "srv-c".to_string(), phase: PbftPhase::Commit,
        };
        let phase = gov.receive_commit(commit_c);
        assert_eq!(phase, RoundPhase::Sealed);

        let batch = gov.seal_round().unwrap();
        assert_eq!(batch.sequence_number, 1);
        assert_eq!(batch.transactions.len(), 1);
        assert_eq!(batch.prepare_votes.len(), 3);
        assert_eq!(batch.commit_votes.len(), 3);
        assert_eq!(gov.log_len(), 1);
        assert_eq!(gov.current_sequence(), 1);
        assert!(gov.pending_round().is_none());
    }

    #[test]
    fn governance_seal_fails_if_not_ready() {
        let mut gov = GovernanceState::new(3);
        gov.propose(vec![], "srv-a".to_string());
        assert!(gov.seal_round().is_none(), "should not seal without commits");
        assert!(gov.pending_round().is_some(), "round should still be pending");
    }

    #[test]
    fn governance_rejects_wrong_view() {
        let mut gov = GovernanceState::new(3);
        gov.propose(vec![], "srv-a".to_string());

        let wrong_view = PbftVote {
            view_number: 99, sequence_number: 1,
            voter_id: "srv-b".to_string(), phase: PbftPhase::Prepare,
        };
        let phase = gov.receive_prepare(wrong_view);
        assert_eq!(phase, RoundPhase::Prepare, "wrong view should be ignored");
        assert_eq!(gov.pending_round().unwrap().prepare_votes.len(), 1);
    }

    #[test]
    fn governance_advance_view_clears_round() {
        let mut gov = GovernanceState::new(3);
        gov.propose(vec![], "srv-a".to_string());
        assert!(gov.pending_round().is_some());
        gov.advance_view();
        assert!(gov.pending_round().is_none());
        assert_eq!(gov.current_view(), 1);
    }

    #[test]
    fn governance_tx_type_names() {
        assert_eq!(GovernanceTx::Admit { server_id: "a".into(), verifying_key_hex: "v".into(), kex_public_hex: "k".into() }.tx_type_name(), "admit");
        assert_eq!(GovernanceTx::Expel { server_id: "a".into(), reason: "r".into() }.tx_type_name(), "expel");
        assert_eq!(GovernanceTx::KeyRegister { server_id: "a".into(), key_id: 1, verifying_key_hex: "v".into(), kex_public_hex: "k".into() }.tx_type_name(), "key_register");
        assert_eq!(GovernanceTx::RoyaltyRecord { origin_server_id: "a".into(), target_server_id: "b".into(), content_fingerprint_hex: "ff".into(), royalty_type: RoyaltyType::Transclusion, amount: 100 }.tx_type_name(), "royalty_record");
    }

    #[test]
    fn governance_proposal_serialize_roundtrip() {
        let proposal = GovernanceProposal {
            view_number: 1,
            sequence_number: 5,
            transactions: vec![GovernanceTx::Admit {
                server_id: "srv-x".to_string(),
                verifying_key_hex: "vk-x".to_string(),
                kex_public_hex: "kex-x".to_string(),
            }],
            proposer_id: "srv-a".to_string(),
            timestamp: 12345,
        };
        let json = serde_json::to_string(&proposal).unwrap();
        let back: GovernanceProposal = serde_json::from_str(&json).unwrap();
        assert_eq!(back.view_number, 1);
        assert_eq!(back.sequence_number, 5);
        assert_eq!(back.proposer_id, "srv-a");
    }

    #[test]
    fn governance_sealed_batch_serialize_roundtrip() {
        let batch = SealedBatch {
            view_number: 0,
            sequence_number: 1,
            transactions: vec![],
            proposer_id: "srv-a".to_string(),
            timestamp: 999,
            prepare_votes: vec!["a".into(), "b".into(), "c".into()],
            commit_votes: vec!["a".into(), "b".into(), "c".into()],
        };
        let json = serde_json::to_string(&batch).unwrap();
        let back: SealedBatch = serde_json::from_str(&json).unwrap();
        assert_eq!(back.prepare_votes.len(), 3);
        assert_eq!(back.commit_votes.len(), 3);
    }

    #[test]
    fn governance_vote_serialize_roundtrip() {
        let vote = PbftVote {
            view_number: 2,
            sequence_number: 10,
            voter_id: "srv-b".to_string(),
            phase: PbftPhase::Commit,
        };
        let json = serde_json::to_string(&vote).unwrap();
        let back: PbftVote = serde_json::from_str(&json).unwrap();
        assert_eq!(back.phase, PbftPhase::Commit);
    }

    #[test]
    fn governance_multiple_batches() {
        let mut gov = GovernanceState::new(4);

        for i in 0..3 {
            let tx = GovernanceTx::RoyaltyRecord {
                origin_server_id: format!("srv-{}", i),
                target_server_id: format!("srv-{}", i + 1),
                content_fingerprint_hex: format!("{:064x}", i),
                royalty_type: RoyaltyType::Transclusion,
                amount: 100 * (i as u64 + 1),
            };
            gov.propose(vec![tx], "srv-a".to_string());

            for voter in &["srv-a", "srv-b", "srv-c"] {
                gov.receive_prepare(PbftVote {
                    view_number: 0, sequence_number: (i as u64) + 1,
                    voter_id: voter.to_string(), phase: PbftPhase::Prepare,
                });
            }
            for voter in &["srv-a", "srv-b", "srv-c"] {
                gov.receive_commit(PbftVote {
                    view_number: 0, sequence_number: (i as u64) + 1,
                    voter_id: voter.to_string(), phase: PbftPhase::Commit,
                });
            }
            gov.seal_round().unwrap();
        }

        assert_eq!(gov.log_len(), 3);
        assert_eq!(gov.current_sequence(), 3);
        assert_eq!(gov.log()[0].transactions[0].tx_type_name(), "royalty_record");
        assert_eq!(gov.log()[2].transactions[0].tx_type_name(), "royalty_record");
    }

    #[test]
    fn governance_set_cluster_size() {
        let mut gov = GovernanceState::new(1);
        assert_eq!(gov.quorum_size(), 1);
        gov.set_cluster_size(7);
        assert_eq!(gov.cluster_size(), 7);
        assert_eq!(gov.faulty_tolerance(), 2);
        assert_eq!(gov.quorum_size(), 5);
    }
}
