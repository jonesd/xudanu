# PROV-JSON Integration for Existing Provenance Model

## Analysis: Can We Extend Our Model to Work with PROV-JSON?

**Answer: YES** - Our existing provenance model aligns well with W3C PROV concepts and can be extended to support PROV-JSON export while maintaining backward compatibility.

## Mapping Between Models

### Core Concept Alignment

| Our Concept | W3C PROV Concept | Mapping |
|-------------|-----------------|--------|
| `Provenance` (basic authorship) | `wasAttributedTo` + `Agent` | Text span → Entity, author → Agent, attribution → wasAttributedTo |
| `ElementProvenance` (detailed element info) | `Entity` + `wasDerivedFrom` | Text elements → Entities, transclusion → wasDerivedFrom |
| `SpanProvenance` (span-level provenance) | `Entity` + `wasAttributedTo` + `wasDerivedFrom` | Complex provenance chains |
| `AuthorType::Human` | `Agent` with `prov:type = "prov:Person"` | Human authors as Person agents |
| `AuthorType::Llm` | `Agent` with `prov:type = "prov:SoftwareAgent"` | LLMs as SoftwareAgent |
| `AuthorType::Historical` | `Entity` + `wasDerivedFrom` | Historical content as derived entities |
| `FederatedProvenance` (new) | `Entity` + `agent` (server) | Servers as agents, verification as activity |

### PROV-JSON Structure Compatibility

```json
{
  "prefix": {
    "prov": "http://www.w3.org/ns/prov#",
    "xudanu": "https://dgjones.info/ns/xudanu/",
    "ex": "http://example.org/"
  },
  "entity": {
    // Our spans become PROV entities
    "span:123": {
      "xudanu:spanStart": 100,
      "xudanu:spanEnd": 150,
      "xudanu:content": "text content"
    }
  },
  "agent": {
    // Our authors become PROV agents
    "agent:alice": {
      "prov:type": "prov:Person",
      "xudanu:publicKey": "abc123...",
      "xudanu:displayName": "Alice",
      "xudanu:clubId": "club:456"
    },
    // Our servers become PROV agents (federation)
    "server:server1": {
      "prov:type": "xudanu:Server",
      "xudanu:publicKey": "def456...",
      "xudanu:domain": "xudanu"
    }
  },
  "wasAttributedTo": {
    // Our provenance becomes PROV attributions
    "att:1": {
      "prov:entity": "span:123",
      "prov:agent": "agent:alice",
      "prov:time": "2024-01-15T10:30:00Z",
      "xudanu:signature": "sig789..."
    }
  },
  "wasDerivedFrom": {
    // Our transclusion becomes PROV derivation
    "deriv:1": {
      "prov:generatedEntity": "span:123",
      "prov:usedEntity": "span:456",
      "prov:type": "xudanu:Transclusion"
    }
  },
  "activity": {
    // Server verification becomes PROV activity (federation)
    "verify:1": {
      "prov:type": "xudanu:ServerVerification",
      "prov:startTime": "2024-01-15T10:30:00Z",
      "prov:endTime": "2024-01-15T10:30:01Z"
    }
  },
  "wasAssociatedWith": {
    // Cross-server signatures become PROV associations
    "assoc:1": {
      "prov:activity": "verify:1",
      "prov:agent": "server:server1",
      "prov:role": "verifier"
    }
  }
}
```

## Implementation Strategy

### Phase 1: PROV-JSON Export Layer
- **File**: `src/edition/provenance.rs`
- **Description**: Add PROV-JSON export functions to existing provenance module
- **Details**:
  - Add `to_prov_json()` method to `FederatedProvenance`
  - Implement `ProvJsonDocument` struct following PROV-JSON structure
  - Create unique IDs for spans, agents, activities following PROV conventions
  - Map `AuthorType` to PROV agent types
  - Serialize using existing `serde` feature-gating
  - Add `xudanu:` namespace for custom properties
  - Generate proper prefixes for default namespaces

### Phase 2: Enhanced Provenance to PROV Mapping
- **File**: `src/edition/provenance.rs`
- **Description**: Extend existing structures with PROV-compatible fields
- **Details**:
  - Add optional `prov_id` field to existing structures
  - Add `prov_activity_id` for edit operations
  - Map `TransclusionInfo` to `wasDerivedFrom` with proper PROV types
  - Add `DerivationInfo` to `wasDerivedFrom` with `prov:type` mapping
  - Implement `generate_prov_ids()` for consistent ID generation
  - Add namespace management for PROV identifiers

### Phase 3: Federation-PROV Integration
- **File**: `src/edition/provenance.rs`
- **Description**: Map federation features to PROV concepts
- **Details**:
  - Map `CrossServerSignature` to `wasAssociatedWith` with server as agent
  - Map `ServerVerification` to PROV activity with `prov:type = "xudanu:ServerVerification"`
  - Map `ClusterConsensus` to `prov:Bundle` containing verification results
  - Add federation-specific namespaces and properties
  - Implement consensus results as PROV bundles
  - Map cluster metadata to PROV entity properties

### Phase 4: Server Integration
- **File**: `src/server/server.rs`
- **Description**: Add PROV-JSON export to existing attestation report generation
- **Details**:
  - Extend `generate_attestation_report()` with `--format=prov-json` option
  - Add `generate_prov_json_report()` method
  - Integrate with existing `materialize_with_provenance()` calls
  - Use existing JSON serialization patterns
  - Maintain backward compatibility with existing JSON format
  - Add PROV-JSON validation using existing signature verification

### Phase 5: Frontend PROV-JSON Display
- **File**: `web/app/src/components/AttributionPanel.tsx`
- **Description**: Add PROV-JSON visualization option
- **Details**:
  - Add PROV-JSON export button to existing UI
  - Display PROV-JSON in formatted view
  - Show PROV entity/agent/activity counts
  - Highlight federation information in PROV structure
  - Add validation status for PROV documents
  - Use existing `AttributionSection` patterns for display

## Technical Implementation Details

### PROV Identifier Generation
```rust
fn generate_prov_id(prefix: &str, base_id: &str) -> String {
    format!("{}:{}", prefix, base_id)
}

// Examples:
// span:123        → "xudanu:span:123"
// agent:alice      → "xudanu:agent:alice"  
// server:server1   → "xudanu:server:server1"
// activity:edit1   → "xudanu:activity:edit1"
```

### AuthorType to PROV Agent Mapping
```rust
impl AuthorType {
    fn to_prov_agent_type(&self) -> &'static str {
        match self {
            AuthorType::Human => "prov:Person",
            AuthorType::Llm => "prov:SoftwareAgent",
            AuthorType::Historical => "prov:Organization", // Historical sources as organizations
        }
    }
}
```

### Derivation Type to PROV Mapping
```rust
impl DerivationMethod {
    fn to_prov_type(&self) -> &'static str {
        match self {
            DerivationMethod::Transclusion => "xudanu:Transclusion",
            DerivationMethod::Merge => "xudanu:Merge",
            DerivationMethod::Import => "prov:Revision",
            DerivationMethod::Annotation => "xudanu:Annotation",
        }
    }
}
```

### PROV-JSON Document Structure
```rust
pub struct ProvJsonDocument {
    pub prefix: HashMap<String, String>,
    pub entity: HashMap<String, ProvEntity>,
    pub activity: HashMap<String, ProvActivity>,
    pub agent: HashMap<String, ProvAgent>,
    pub wasAttributedTo: HashMap<String, ProvAttribution>,
    pub wasDerivedFrom: HashMap<String, ProvDerivation>,
    pub wasAssociatedWith: HashMap<String, ProvAssociation>,
    pub wasGeneratedBy: HashMap<String, ProvGeneration>,
    pub bundle: Option<HashMap<String, ProvBundle>>, // For federation
}

// Helper structures
pub struct ProvEntity {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prov_type: Option<ProvValue>,
    #[serde(flatten)]
    pub attributes: HashMap<String, ProvValue>,
}

pub struct ProvActivity {
    pub prov_startTime: Option<String>,
    pub prov_endTime: Option<String>,
    #[serde(flatten)]
    pub attributes: HashMap<String, ProvValue>,
}

pub struct ProvAgent {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prov_type: Option<ProvValue>,
    #[serde(flatten)]
    pub attributes: HashMap<String, ProvValue>,
}

pub struct ProvValue {
    #[serde(rename = "$")]
    pub value: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lang: Option<String>,
}
```

## Benefits of PROV-JSON Integration

### 1. **Standards Compliance**
- W3C PROV is an established standard for provenance representation
- Enables interoperability with other PROV-compatible systems
- Supports validation against PROV constraints
- Access to existing PROV tools and libraries

### 2. **Ecosystem Integration**
- Can integrate with PROV-aware tools and services
- Enables export to PROV-compliant analysis tools
- Supports PROV-O (RDF) conversion for semantic web integration
- Compatible with PROV validation tools

### 3. **Richer Provenance Expression**
- PROV provides more comprehensive provenance relationships
- Better support for complex derivation chains
- Standardized way to represent temporal aspects
- Clear separation between entities, activities, and agents

### 4. **Federation Support**
- PROV bundles perfect for representing cross-server verification
- Standard way to represent multi-server consensus
- Clear modeling of server roles (agents, activities)
- Temporal aspects of verification processes

### 5. **Backward Compatibility**
- Existing attestation reports remain unchanged
- PROV-JSON export is optional format
- No breaking changes to existing API
- Progressive enhancement approach

## Migration Strategy

### Phase 1: Add Export Capability
- Add PROV-JSON export without changing existing structures
- Maintain current JSON format as default
- PROV-JSON available via `?format=prov-json` parameter

### Phase 2: Dual Format Support
- Support both existing JSON and PROV-JSON formats
- Frontend can display both formats
- API clients can choose preferred format

### Phase 3: PROV-JSON as Primary
- Make PROV-JSON the default export format
- Maintain legacy JSON for backward compatibility
- Add conversion tools for existing data

### Phase 4: PROV-Native Internal Representation
- Consider internal representation aligned with PROV concepts
- Seamless PROV-JSON export without conversion
- Leverage PROV validation and tools internally

## Compatibility with Existing Code

### Our Existing Model + PROV Extensions

```rust
// Existing structure (unchanged)
pub struct Provenance {
    pub author_public_key: [u8; 32],
    pub signature: [u8; 64],
    pub timestamp: u64,
    pub server_id: [u8; 32],
}

// New PROV-compatible fields (optional)
#[cfg(feature = "prov-json")]
pub struct ProvCompatibleProvenance {
    pub base: Provenance,
    pub prov_id: Option<String>,
    pub prov_entity_id: Option<String>,
    pub prov_agent_id: Option<String>,
    pub prov_activity_id: Option<String>,
}

// Conversion to PROV-JSON
#[cfg(feature = "prov-json")]
impl ProvCompatibleProvenance {
    pub fn to_prov_json(&self) -> ProvJsonDocument {
        // Convert existing provenance to PROV-JSON format
    }
}
```

### Federation Integration

```rust
// Existing federation structure (unchanged)
pub struct FederatedProvenance {
    pub base: Provenance,
    pub cross_server_signatures: Vec<CrossServerSignature>,
    pub verification_chain: Vec<ServerVerification>,
    pub cluster_consensus: Option<ClusterConsensus>,
}

// PROV-JSON conversion with federation
#[cfg(feature = "prov-json")]
impl FederatedProvenance {
    pub fn to_prov_json(&self) -> ProvJsonDocument {
        let mut doc = self.base.to_prov_json();
        
        // Add federation as PROV bundle
        if let Some(consensus) = &self.cluster_consensus {
            let bundle = self.create_prov_bundle(consensus);
            doc.bundle = Some({
                let mut bundles = HashMap::new();
                bundles.insert(format!("federation:{}", self.base.timestamp), bundle);
                bundles
            });
        }
        
        // Add server agents
        for verification in &self.verification_chain {
            let server_agent = self.server_to_prov_agent(&verification.server_info);
            doc.agent.insert(server_agent.id, server_agent.agent);
        }
        
        // Add verification activities
        for sig in &self.cross_server_signatures {
            let verification_activity = self.signature_to_prov_activity(sig);
            doc.activity.insert(verification_activity.id, verification_activity.activity);
        }
        
        doc
    }
}
```

## Conclusion

**Yes, we can extend our existing provenance model to work with PROV-JSON** while maintaining backward compatibility and gaining the benefits of W3C PROV standards compliance. The integration is clean and follows our existing patterns, with PROV-JSON serving as an export format rather than replacing our internal representation.

The federation features we're implementing fit naturally into PROV concepts:
- Servers → PROV agents
- Verification processes → PROV activities  
- Cross-server signatures → PROV associations
- Cluster consensus → PROV bundles

This provides standards compliance while building upon our strong foundation.