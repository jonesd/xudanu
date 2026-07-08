# Multi-Server Federation Attestation Design

## Overview
Design a unified attestation system supporting both single-server installations (1 machine) and cluster deployments (3-6 machines) with seamless scalability, building upon existing provenance and attestation infrastructure.

## Existing Foundation

### Current Attestation Infrastructure
- **`edition/provenance.rs`**: Core provenance structures
  - `Provenance`: Author provenance with signature, timestamp, server_id
  - `ElementProvenance`: Detailed element-level provenance
  - `SpanProvenance`: Span-level attribution tracking
  - Support for Human, LLM, and Historical author types
  - Transclusion and derivation tracking

- **`server/transport/protocol.rs`**: Attestation operations
  - `OperationCode::AttestationReport` (0x0D0B)
  - `WireRequest::AttestationReport`
  - `ResponseValue::AttestationReportResult`

- **`server/server.rs`**: Attestation report generation
  - `generate_attestation_report()`: Creates JSON attestation reports
  - `materialize_with_provenance()`: Provenance-aware CRDT operations
  - `attribution_query_resolved()`: Span attribution resolution

- **Frontend Components**:
  - `AttributionPanel`: Display provenance chains
  - `AttributionSection`: Context panel with chain validity
  - Real-time attestation display

### Security Foundation (Phase 1 Complete)
- `crypto/server_identity.rs`: Trusted server registry
- `ServerIdentity`: Server identity management
- `TrustedServerRegistry`: Tamper-evident server trust
- `verify_server_identity()`: Timing attack protected verification
- CLI registry management (init, add, remove, verify, list)

## Design Principles

### 1. Build Upon Existing Foundation
- Extend current `Provenance` structures rather than replace
- Maintain compatibility with existing `AttestationReport` protocol
- Leverage existing cryptographic primitives (Ed25519, BLAKE3)
- Preserve current frontend components with enhanced backend

### 2. Unified Architecture
- Same core provenance system for single and cluster deployments
- Cluster features activate automatically when multiple servers configured
- Backward compatible with existing attestation reports
- No breaking changes to existing protocol

### 3. Progressive Complexity
- **Single Server**: Current `Provenance` + trusted registry verification
- **Cluster (3-6 servers)**: Add cross-server provenance verification, conflict resolution, consensus
- Each additional server incrementally improves security and reliability

### 4. Backward Compatibility
- Existing single-server deployments work unchanged
- Cluster features opt-in via configuration
- Existing `AttestationReport` JSON format preserved
- Frontend components continue to work without modification

## Architecture

### Single-Server Mode (1 Machine)
```
Client → Server → Local Registry → Verification → Attestation
```
- Simple direct verification
- Single source of truth
- Minimal overhead
- Fast operations

### Cluster Mode (3-6 Machines)
```
          ┌─────────┐
          │ Client │
          └────┬────┘
               │
    ┌──────────┼──────────┐
    │          │          │
┌───▼───┐ ┌───▼───┐ ┌───▼───┐
│Server1│ │Server2│ │Server3│
└───┬───┘ └───┬───┘ └───┬───┘
    │          │          │
    └──────────┼──────────┘
               │
        ┌──────▼──────┐
        │ Federation  │
        │ Consensus   │
        │    Layer    │
        └─────────────┘
```

## Core Components

### 1. Extended Provenance (Building on existing)
Enhance existing `Provenance` structures with federation support:

```rust
// Extends existing edition/provenance.rs
pub struct FederatedProvenance {
    // Base provenance (existing fields)
    pub base: Provenance,
    
    // Federation fields
    pub cross_server_signatures: Vec<CrossServerSignature>,
    pub verification_chain: Vec<ServerVerification>,
    pub cluster_consensus: Option<ClusterConsensus>,
}

pub struct CrossServerSignature {
    pub server_id: [u8; 32],
    pub signature: [u8; 64],
    pub timestamp: u64,
    pub verifying_key: [u8; 32],
}

pub struct ServerVerification {
    pub server_id: [u8; 32],
    pub verified_at: u64,
    pub verification_result: bool,
    pub server_info: ServerInfo,
}

pub struct ClusterConsensus {
    pub agreeing_servers: Vec<[u8; 32]>,
    pub disagreeing_servers: Vec<[u8; 32]>,
    pub consensus_timestamp: u64,
    pub consensus_type: ConsensusType,
}

pub enum ConsensusType {
    Unanimous,        // All servers agree
    Majority,         // Simple majority (2-3 servers)
    Supermajority,    // 2/3 + 1 (4-6 servers, BFT)
}
```

### 2. FederationManager
Manages server cluster membership and attestation coordination.

```rust
pub struct FederationManager {
    servers: HashMap<String, ServerInfo>,
    cluster_mode: ClusterMode,
    consensus: Box<dyn ConsensusProtocol>,
    trusted_registry: Option<TrustedServerRegistry>,
}

pub enum ClusterMode {
    Single,        // 1 server - use existing behavior
    Small,         // 2-3 servers - simple majority
    Medium,        // 4-6 servers - BFT consensus
}

pub struct ServerInfo {
    server_id: String,
    signing_key: [u8; 32],
    kex_public: [u8; 32],
    federation_domain: String,
    last_seen: SystemTime,
    status: ServerStatus,
    health_score: u8,
}
```

### 3. Enhanced AttestationReport Generation
Extend existing `generate_attestation_report()` with federation support:

```rust
// Enhanced version of existing server.rs function
pub fn generate_federated_attestation_report(
    &mut self,
    work_be_id: BeId,
    session_id: SessionId,
    federation_context: Option<&FederationContext>
) -> Result<FederatedAttestationReport, ServerError> {
    // Use existing provenance generation
    let base_report = self.generate_attestation_report(work_be_id, session_id)?;
    
    match federation_context {
        Some(fed_ctx) if fed_ctx.cluster_mode != ClusterMode::Single => {
            // Add federation verification
            let cross_signatures = self.collect_cross_server_signatures(work_be_id, fed_ctx)?;
            let consensus = self.verify_cluster_consensus(work_be_id, fed_ctx)?;
            
            Ok(FederatedAttestationReport {
                base_report: base_report,
                cross_server_signatures,
                cluster_consensus: consensus,
                federation_metadata: self.generate_federation_metadata(fed_ctx),
            })
        }
        _ => {
            // Single server mode - wrap existing report
            Ok(FederatedAttestationReport::single_server(base_report))
        }
    }
}
```

### 4. ConsensusProtocol
Handles agreement on attestation validity across cluster.

```rust
pub trait ConsensusProtocol {
    fn propose_attestation(&mut self, attestation: &Attestation) -> ConsensusResult;
    fn validate_attestation(&self, attestation: &Attestation) -> ValidationResult;
    fn resolve_conflict(&mut self, conflicts: Vec<Attestation>) -> ResolutionResult;
}

// For 2-3 servers: Simple majority using existing verification
pub struct SimpleMajorityConsensus {
    trusted_registry: TrustedServerRegistry,
}

// For 4-6 servers: PBFT-style consensus
pub struct ByzantineFaultTolerance {
    trusted_registry: TrustedServerRegistry,
    view_number: u64,
    primary_server: Option<String>,
}
```

## Deployment Modes

### Single-Server Mode
**Configuration**: 
```json
{
  "cluster_mode": "single",
  "server_id": "server1",
  "trusted_registry": "registry.json"
}
```

**Behavior**:
- Direct verification against local trusted registry
- No cross-server communication
- Fast, minimal overhead
- Perfect for demos, development, small deployments

**Security**: Same as Phase 1 fixes (timing attacks, secure logging, etc.)

### Small Cluster Mode (2-3 Servers)
**Configuration**:
```json
{
  "cluster_mode": "small",
  "server_id": "server1", 
  "cluster_members": ["server1", "server2", "server3"],
  "trusted_registry": "registry.json",
  "consensus": "simple_majority"
}
```

**Behavior**:
- Cross-server verification with majority consensus
- Automatic failover if server goes down
- Conflict resolution by majority vote
- Good balance of security and performance

**Security**:
- Attestations verified by majority of cluster members
- Compromised single server cannot forge attestations
- Network partition handled by majority

### Medium Cluster Mode (4-6 Servers)
**Configuration**:
```json
{
  "cluster_mode": "medium",
  "server_id": "server1",
  "cluster_members": ["server1", "server2", "server3", "server4", "server5"],
  "trusted_registry": "registry.json", 
  "consensus": "byzantine_fault_tolerance"
}
```

**Behavior**:
- PBFT-style consensus for maximum security
- Tolerates up to ⌊(n-1)/3⌋ compromised servers
- Optimized for high-security production deployments
- Built-in replay attack prevention

**Security**:
- Attestations require supermajority agreement (2/3 + 1)
- Byzantine fault tolerance
- Cryptographic proof of consensus
- Complete audit trail

## Implementation Phases

### Phase 2.1: Federation Infrastructure (Single + Small Cluster)
- [ ] FederationManager implementation
- [ ] Server discovery and health checking
- [ ] Cross-server communication protocol
- [ ] SimpleMajorityConsensus (2-3 servers)
- [ ] Cluster configuration management
- [ ] Automatic failover for small clusters

### Phase 2.2: Cross-Server Attestation (All Modes)
- [ ] CrossServerAttestation data structures
- [ ] Cross-signature protocol
- [ ] Attestation propagation across cluster
- [ ] Conflict detection and resolution
- [ ] Timestamp and nonce generation
- [ ] Replay attack prevention

### Phase 2.3: Byzantine Fault Tolerance (Medium Cluster)
- [ ] PBFT consensus implementation
- [ ] View change protocol
- [ ] Leader election
- [ ] Cryptographic proof generation
- [ ] Optimized commitment protocol
- [ ] Network partition handling

### Phase 2.4: Key Management & Distribution
- [ ] Cluster-wide key synchronization
- [ ] Key rotation mechanism
- [ ] Secure key distribution protocol
- [ ] Certificate-based authentication
- [ ] Key compromise detection
- [ ] Emergency key revocation

### Phase 2.5: Testing & Validation
- [ ] Single-server regression tests
- [ ] 2-server cluster tests
- [ ] 3-server cluster tests  
- [ ] 6-server cluster tests
- [ ] Network partition simulation
- [ ] Byzantine failure simulation
- [ ] Performance benchmarks

## API Design

### Unified Verification API
```rust
// Works for both single and cluster modes
pub fn verify_attestation(
    attestation: &Attestation,
    server_context: &ServerContext
) -> VerificationResult {
    match server_context.cluster_mode {
        ClusterMode::Single => {
            verify_single_server(attestation, server_context)
        },
        ClusterMode::Small => {
            verify_small_cluster(attestation, server_context)  
        },
        ClusterMode::Medium => {
            verify_medium_cluster(attestation, server_context)
        },
    }
}
```

### Cluster Operations API
```rust
impl FederationManager {
    // Join cluster
    pub fn join_cluster(&mut self, cluster_config: ClusterConfig) -> Result<(), FederationError>;
    
    // Leave cluster gracefully
    pub fn leave_cluster(&mut self) -> Result<(), FederationError>;
    
    // Propagate attestation to cluster
    pub fn propagate_attestation(&self, attestation: &Attestation) -> PropagationResult;
    
    // Get cluster status
    pub fn cluster_status(&self) -> ClusterStatus;
}
```

## Security Considerations

### Cross-Server Security
- All inter-server communication encrypted with TLS
- Server authentication via mutual TLS
- Replay attack prevention with timestamps + nonces
- Rate limiting to prevent DoS
- Audit logging for all cross-server operations

### Key Management
- Authority keys distributed securely to cluster members
- Key rotation without service disruption
- HSM integration option for production
- Emergency key revocation procedure

### Byzantine Security (4-6 servers)
- Tolerates up to ⌊(n-1)/3⌋ compromised servers
- Cryptographic proof of correct consensus
- View change to isolate malicious leaders
- Complete audit trail of all consensus operations

## Performance Considerations

### Single-Server Mode
- **Latency**: ~5-10ms per attestation
- **Throughput**: 1000+ attestations/second
- **Network**: Local verification only

### Small Cluster Mode (2-3 servers)
- **Latency**: ~50-100ms per attestation (round-trip to peers)
- **Throughput**: 200-400 attestations/second
- **Network**: 1-2 round-trips to majority

### Medium Cluster Mode (4-6 servers)
- **Latency**: ~150-300ms per attestation (PBFT consensus)
- **Throughput**: 50-100 attestations/second
- **Network**: 2-3 round-trips for consensus

## Migration Path

### Single → Small Cluster
1. Add cluster configuration to existing server
2. Start new servers with same registry
3. Enable cluster mode
4. Automatic migration to majority verification
5. No downtime required

### Small → Medium Cluster
1. Update consensus protocol configuration
2. Add additional servers
3. Switch to BFT consensus
4. Gradual migration of active attestations
5. No breaking changes

## Configuration Examples

### Single Server (Development)
```toml
[server]
server_id = "dev-server"
bind_address = "127.0.0.1:8080"
data_dir = "./data"

[cluster]
mode = "single"
trusted_registry = "./registry.json"

[attestation]
enabled = true
```

### Small Cluster (Demo/Test)
```toml
[server]
server_id = "server1" 
bind_address = "0.0.0.0:8080"
data_dir = "./data"

[cluster]
mode = "small"
cluster_members = ["server1", "server2", "server3"]
trusted_registry = "./cluster-registry.json"
consensus = "simple_majority"

[servers.server2]
address = "server2.example.com:8080"
public_key = "hex-encoded-key"

[servers.server3]  
address = "server3.example.com:8080"
public_key = "hex-encoded-key"

[attestation]
enabled = true
cross_verification = true
```

### Medium Cluster (Production)
```toml
[server]
server_id = "prod-server-1"
bind_address = "0.0.0.0:8080" 
data_dir = "/var/lib/xudanu"

[cluster]
mode = "medium"
cluster_members = [
    "prod-server-1", "prod-server-2", 
    "prod-server-3", "prod-server-4", "prod-server-5"
]
trusted_registry = "/etc/xudanu/production-registry.json"
consensus = "byzantine_fault_tolerance"

[servers.prod-server-2]
address = "prod2.xudanu.example.com:8080"
public_key = "hex-encoded-key"
health_check_interval = 30

[servers.prod-server-3]
address = "prod3.xudanu.example.com:8080"
public_key = "hex-encoded-key"
health_check_interval = 30

[servers.prod-server-4]
address = "prod4.xudanu.example.com:8080"
public_key = "hex-encoded-key"
health_check_interval = 30

[servers.prod-server-5]
address = "prod5.xudanu.example.com:8080"
public_key = "hex-encoded-key"
health_check_interval = 30

[attestation]
enabled = true
cross_verification = true
replay_prevention = true
consensus_timeout = 3000
byzantine_tolerance = 1
```

## Testing Strategy

### Unit Tests
- FederationManager logic
- Consensus algorithms
- Cross-signature verification
- Conflict resolution

### Integration Tests
- 2-server cluster operations
- 3-server cluster consensus
- 6-server BFT consensus
- Cross-server attestation flow

### Security Tests
- Byzantine failure simulation
- Network partition handling
- Key compromise detection
- Replay attack prevention

### Performance Tests
- Single-server benchmarking
- Cluster latency measurements
- Throughput analysis
- Scalability testing

## Rollout Plan

### Phase 1: Internal Testing
- Implement FederationManager
- Test single-server regression
- Test 2-3 server clusters
- Security validation

### Phase 2: Beta Testing  
- Deploy to small cluster (3 servers)
- Monitor performance and security
- Gather feedback
- Bug fixes and optimization

### Phase 3: Production Rollout
- Deploy to medium cluster (4-6 servers)
- Gradual migration path
- Monitoring and alerting
- Documentation and training

## Success Criteria

- **Single Server**: Same performance as current system
- **Small Cluster**: <100ms latency, >200 attestations/second
- **Medium Cluster**: <300ms latency, >50 attestations/second
- **Security**: Byzantine fault tolerance (4-6 servers)
- **Availability**: >99.9% uptime with automatic failover
- **Migration**: Zero-downtime upgrades