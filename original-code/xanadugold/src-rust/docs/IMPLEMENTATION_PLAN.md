## Feature: Multi-Server Federation Attestation

### Overview
Extend existing provenance and attestation infrastructure to support both single-server installations and 3-6 server clusters with Byzantine fault tolerance, building upon current `Provenance`, `ElementProvenance`, `SpanProvenance` structures and `AttestationReport` generation.

### Architecture Decisions
- **Extend vs Replace**: Build on existing `edition/provenance.rs` structures rather than creating new ones
- **Progressive Enhancement**: Cluster features activate automatically when configured, no breaking changes
- **Crypto Consistency**: Use existing Ed25519/BLAKE3 patterns and domain separation constants
- **Protocol Compatibility**: Maintain existing `AttestationReport` protocol, add federation extensions
- **Configuration-Driven**: Use existing `FederationConfig` pattern for cluster setup

### Implementation Tasks

#### Task 1: Enhanced Provenance Structures
- **File**: `src/edition/provenance.rs`
- **Description**: Extend existing provenance structures with federation support while maintaining backward compatibility
- **Details**:
  - Add `FederatedProvenance` wrapping existing `Provenance` struct
  - Add `CrossServerSignature`, `ServerVerification`, `ClusterConsensus` structures
  - Follow existing domain separation pattern with `FEDERATION_PROVENANCE_DOMAIN` constant
  - Use feature-gated serde implementation matching existing pattern
  - Add `ConsensusType` enum (Unanimous, Majority, Supermajority)
  - Implement `verify_federation_provenance()` following existing `verify_span_provenance()` pattern
  - Use existing `blake3::Hasher` and `ed25519_dalek` patterns
- **Dependencies**: None

#### Task 2: FederationManager Core
- **File**: `src/server/federation.rs` (extend existing)
- **Description**: Implement core federation management logic following existing `FederationState` patterns
- **Details**:
  - Add `FederationManager` struct to `federation.rs` module
  - Implement `ClusterMode` enum (Single, Small, Medium) following existing `FederationMode` pattern
  - Add `ServerInfo` struct with health checking and status tracking
  - Extend existing `FederationState::new()` to support federation manager
  - Implement server discovery and health checking using existing WebSocket patterns
  - Use existing `to_snapshot()`/`from_snapshot()` persistence pattern
  - Add cluster configuration validation following existing config patterns
  - Implement graceful degradation when federation unavailable
- **Dependencies**: Task 1 (needs enhanced provenance structures)

#### Task 3: Consensus Protocol Traits
- **File**: `src/server/federation.rs`
- **Description**: Define consensus protocol interfaces following existing trait patterns
- **Details**:
  - Define `ConsensusProtocol` trait with `propose_attestation()`, `validate_attestation()`, `resolve_conflict()`
  - Implement `SimpleMajorityConsensus` for 2-3 server clusters
  - Implement `ByzantineFaultTolerance` for 4-6 server clusters
  - Use existing `TrustedServerRegistry` from Phase 1 security fixes
  - Follow existing configuration-driven initialization pattern
  - Add consensus timeout and retry logic
  - Implement view change protocol for BFT mode
  - Use existing error handling patterns with `ServerError` enum
- **Dependencies**: Task 2 (needs FederationManager core)

#### Task 4: Enhanced Attestation Report Generation
- **File**: `src/server/server.rs`
- **Description**: Extend existing `generate_attestation_report()` with federation support
- **Details**:
  - Create `generate_federated_attestation_report()` method around line 2748
  - Wrap existing report generation logic rather than replace
  - Add federation context parameter `Option<&FederationContext>`
  - Integrate with existing `materialize_with_provenance()` and `attribution_query_resolved()` calls
  - Follow existing JSON report generation pattern using `serde_json::json!`
  - Add cross-server signature collection using existing federation communication
  - Implement cluster consensus verification
  - Maintain backward compatibility - single server mode returns existing report format
  - Add federation metadata generation
- **Dependencies**: Task 1, Task 3 (needs enhanced provenance and consensus protocols)

#### Task 5: Protocol Extensions
- **File**: `src/server/transport/protocol.rs`
- **Description**: Extend existing protocol codes for federation operations
- **Details**:
  - Add new operation codes: `FederationAttestationRequest`, `FederationAttestationResponse`, `CrossSignatureRequest`
  - Use existing operation code pattern (0x0D range for attestations)
  - Add corresponding wire request/response types in `WireRequest` and `ResponseValue`
  - Follow existing `#[serde(tag = "type")]` tagged enum pattern
  - Maintain `PROTOCOL_VERSION` compatibility
  - Add federation-specific error codes to `ErrorCode` enum
- **Dependencies**: Task 4 (needs enhanced attestation report generation)

#### Task 6: Codec Support
- **File**: `src/server/transport/codec.rs`
- **Description**: Extend codec implementations for federation operations
- **Details**:
  - Add federation request handling to `BinaryCodec::work_id_request()`
  - Extend `JsonCodec::build_wire_request()` with federation cases
  - Follow existing `WireCodec` trait implementation pattern
  - Add serialization/deserialization for federation message types
  - Implement error wrapping with `ProtocolError` enum
  - Maintain existing JSON and binary protocol compatibility
- **Dependencies**: Task 5 (needs protocol extensions)

#### Task 7: Dispatch Integration
- **File**: `src/server/transport/dispatch.rs`
- **Description**: Add federation operation handlers to existing dispatch logic
- **Details**:
  - Add cases for `FederationAttestationRequest` around line 1000 (near existing `AttestationReport`)
  - Implement handler methods following existing `srv.method_call()` pattern
  - Use existing `ensure_can_read()` and session management
  - Integrate with `FederationManager` for cross-server coordination
  - Follow existing error handling with `ServerError` enum
  - Add logging with existing tracing patterns
  - Maintain existing response format patterns
- **Dependencies**: Task 6 (needs codec support)

#### Task 8: Federation Transport
- **File**: `src/server/transport/federation_handler.rs`
- **Description**: Extend federation transport for attestation coordination
- **Details**:
  - Add attestation-related frame types to `FederationFrame` enum
  - Implement cross-server signature exchange
  - Add consensus message propagation
  - Use existing WebSocket communication patterns
  - Follow existing session cipher encryption patterns
  - Add federation attestation protocol handling
  - Implement message retry and timeout logic
  - Add federation-specific error handling
- **Dependencies**: Task 7 (needs dispatch integration)

#### Task 9: Configuration Integration
- **File**: `src/bin/xudanu-server.rs` and config files
- **Description**: Add cluster configuration support following existing config patterns
- **Details**:
  - Extend existing `FederationConfig` in CLI arguments
  - Add `--cluster-mode` option (single/small/medium)
  - Add `--cluster-members` for server list configuration
  - Add `--consensus-type` option (simple_majority/byzantine_fault_tolerance)
  - Integrate with existing `--trusted-registry` from Phase 1
  - Add cluster health check interval configuration
  - Follow existing configuration validation patterns
  - Add configuration examples to documentation
- **Dependencies**: Task 8 (needs federation transport)

#### Task 10: Frontend Federation Display
- **File**: `web/app/src/components/AttributionPanel.tsx`
- **Description**: Extend existing attribution panel to display federation information
- **Details**:
  - Add cluster status display (number of verifying servers)
  - Show consensus type and agreement level
  - Display cross-server signatures summary
  - Add federation health indicator
  - Maintain existing provenance chain display
  - Add federation metadata tooltips
  - Follow existing React component patterns
  - Use existing API client patterns
- **Dependencies**: Task 9 (needs configuration integration)

### Testing Strategy

**Unit Tests:**
- Enhanced provenance structure verification (Task 1)
- Federation manager logic (Task 2)
- Consensus protocol correctness (Task 3)
- Cross-server signature validation (Task 5)

**Integration Tests:**
- 2-server cluster operations (Task 7-8)
- 3-server consensus verification (Task 7-8)
- 6-server BFT consensus (Task 7-8)
- Cross-server attestation flow (Task 8)

**Security Tests:**
- Byzantine failure simulation (6-server clusters)
- Network partition handling
- Key compromise detection with federation
- Cross-server replay attack prevention

**Backward Compatibility Tests:**
- Single-server mode regression (all existing tests pass)
- Existing AttestationReport format unchanged
- Frontend components work without federation

### Integration Points

**Existing Code Dependencies:**
- `edition/provenance.rs`: Core provenance structures - will be extended
- `server/server.rs:2748`: `generate_attestation_report()` - will be enhanced
- `server/federation.rs`: Existing federation state - will be extended
- `server/transport/protocol.rs`: Operation codes - will be extended
- `server/transport/codec.rs`: Wire codec - will be extended
- `server/transport/dispatch.rs`: Request handling - will be extended
- `server/transport/federation_handler.rs`: Peer communication - will be extended
- `crypto/server_identity.rs`: Phase 1 security fixes - will be leveraged

**Potential Impacts:**
- No breaking changes to existing single-server deployments
- Existing attestation reports remain compatible
- Frontend components gracefully handle missing federation data
- Performance impact only in cluster mode
- Additional configuration required for cluster deployments