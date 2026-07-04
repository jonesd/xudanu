// =============================================================================
// Phase 3: Federation-PROV Integration
// =============================================================================
//
// Integration of federation features with W3C PROV-JSON provenance model.
// Maps federation operations (cross-server signatures, cluster consensus,
// membership, governance) to PROV entities, activities, and agents.

use blake3::Hasher;
use ed25519_dalek::{Signature, SigningKey, VerifyingKey, Signer, Verifier};

use super::backend::BeId;

const PROVENANCE_DOMAIN: &[u8] = b"xudanu/v1/provenance";
const ELEMENT_PROVENANCE_DOMAIN: &[u8] = b"xudanu/v1/element-provenance";
const HISTORICAL_ATTESTATION_DOMAIN: &[u8] = b"xudanu/v1/historical-attestation";
const FEDERATION_PROVENANCE_DOMAIN: &[u8] = b"xudanu/v1/federation-provenance";

// Helper function for hex encoding
fn hex_encode(data: &[u8]) -> String {
    crate::crypto::keys::hex_encode(data)
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum DerivationMethod {
    Transclusion,
    Merge,
    Import,
    Annotation,
    Revision,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DerivationInfo {
    pub method: DerivationMethod,
    pub curator_club_id: BeId,
    pub curator_display_name: String,
    pub curator_public_key: [u8; 32],
    pub timestamp: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TransclusionInfo {
    pub club_id: BeId,
    pub display_name: String,
    pub public_key: [u8; 32],
    pub timestamp: u64,
}

/// Federation metadata as PROV entity properties
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct FederationMetadata {
    pub server_id: String,
    pub federation_domain: String,
    pub cluster_size: u32,
    pub mode: String,
    pub min_endorsements: u32,
    pub membership_status: String,
}

/// Federation server agent representation
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct FederationServerAgent {
    pub server_id: String,
    pub verifying_key_hex: String,
    pub kex_public_hex: String,
    pub membership_status: String,
    pub endorsement_count: usize,
    pub joined_at: u64,
}

/// Federation attestation protocol handlers
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct FederationAttestation {
    pub attestation_type: String,
    pub attester_server_id: String,
    pub subject_server_id: String,
    pub timestamp: u64,
    pub signature: Vec<u8>,
    pub metadata: std::collections::HashMap<String, String>,
}

/// Cluster verification as PROV activity
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ClusterVerificationActivity {
    pub activity_id: String,
    pub activity_type: String,
    pub start_time: u64,
    pub end_time: u64,
    pub verifying_servers: Vec<String>,
    pub consensus_type: String,
    pub threshold_met: bool,
}

/// Federation bundle for PROV-JSON export
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct FederationProvenanceBundle {
    pub bundle_id: String,
    pub timestamp: u64,
    pub federation_metadata: FederationMetadata,
    pub server_agents: Vec<FederationServerAgent>,
    pub verification_activities: Vec<ClusterVerificationActivity>,
    pub attestations: Vec<FederationAttestation>,
    pub cross_server_signatures: Vec<CrossServerSignature>,
}

impl FederationMetadata {
    pub fn new(
        server_id: String,
        federation_domain: String,
        cluster_size: u32,
        mode: String,
        min_endorsements: u32,
        membership_status: String,
    ) -> Self {
        FederationMetadata {
            server_id,
            federation_domain,
            cluster_size,
            mode,
            min_endorsements,
            membership_status,
        }
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_entity(&self) -> (String, ProvEntity) {
        let entity_id = generate_prov_id("xudanu:federation", &self.server_id);
        let mut attributes = std::collections::HashMap::new();
        
        attributes.insert("prov:type".to_string(), ProvValue::qname("xudanu:FederationMetadata"));
        attributes.insert("xudanu:serverId".to_string(), ProvValue::string(&self.server_id));
        attributes.insert("xudanu:federationDomain".to_string(), ProvValue::string(&self.federation_domain));
        attributes.insert("xudanu:clusterSize".to_string(), ProvValue::typed(&self.cluster_size.to_string(), "xsd:integer"));
        attributes.insert("xudanu:mode".to_string(), ProvValue::string(&self.mode));
        attributes.insert("xudanu:minEndorsements".to_string(), ProvValue::typed(&self.min_endorsements.to_string(), "xsd:integer"));
        attributes.insert("xudanu:membershipStatus".to_string(), ProvValue::string(&self.membership_status));
        
        (entity_id, ProvEntity { attributes })
    }
}

impl FederationServerAgent {
    pub fn new(
        server_id: String,
        verifying_key_hex: String,
        kex_public_hex: String,
        membership_status: String,
        endorsement_count: usize,
        joined_at: u64,
    ) -> Self {
        FederationServerAgent {
            server_id,
            verifying_key_hex,
            kex_public_hex,
            membership_status,
            endorsement_count,
            joined_at,
        }
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_agent(&self) -> (String, ProvAgent) {
        let agent_id = generate_prov_id("xudanu:server", &crate::crypto::keys::hex_encode(self.server_id.as_bytes())[..8]);
        let mut attributes = std::collections::HashMap::new();
        
        attributes.insert("prov:type".to_string(), ProvValue::qname("xudanu:FederationServer"));
        attributes.insert("xudanu:serverId".to_string(), ProvValue::string(&self.server_id));
        attributes.insert("xudanu:verifyingKey".to_string(), ProvValue::typed(&self.verifying_key_hex, "xsd:hexBinary"));
        attributes.insert("xudanu:kexPublicKey".to_string(), ProvValue::typed(&self.kex_public_hex, "xsd:hexBinary"));
        attributes.insert("xudanu:membershipStatus".to_string(), ProvValue::string(&self.membership_status));
        attributes.insert("xudanu:endorsementCount".to_string(), ProvValue::typed(&self.endorsement_count.to_string(), "xsd:integer"));
        
        attributes.insert("xudanu:joinedAt".to_string(), ProvValue::string(&unix_to_iso8601(self.joined_at).unwrap_or_default()));
        
        (agent_id, ProvAgent { attributes })
    }
}

impl FederationAttestation {
    pub fn new(
        attestation_type: String,
        attester_server_id: String,
        subject_server_id: String,
        timestamp: u64,
        signature: Vec<u8>,
        metadata: std::collections::HashMap<String, String>,
    ) -> Self {
        FederationAttestation {
            attestation_type,
            attester_server_id,
            subject_server_id,
            timestamp,
            signature,
            metadata,
        }
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_activity(&self) -> (String, ProvActivity) {
        let activity_id = generate_prov_id("xudanu:attestation", &format!("{}:{}:{}", 
            self.attestation_type, self.attester_server_id, self.timestamp));
        let mut attributes = std::collections::HashMap::new();
        
        attributes.insert("prov:type".to_string(), ProvValue::qname("xudanu:FederationAttestation"));
        attributes.insert("xudanu:attestationType".to_string(), ProvValue::string(&self.attestation_type));
        attributes.insert("xudanu:attesterServerId".to_string(), ProvValue::string(&self.attester_server_id));
        attributes.insert("xudanu:subjectServerId".to_string(), ProvValue::string(&self.subject_server_id));
        attributes.insert("xudanu:signature".to_string(), ProvValue::typed(&crate::crypto::keys::hex_encode(&self.signature), "xsd:hexBinary"));
        
        for (key, value) in &self.metadata {
            attributes.insert(format!("xudanu:meta_{}", key), ProvValue::string(value));
        }
        
        let time_str = unix_to_iso8601(self.timestamp);
        
        (activity_id, ProvActivity {
            start_time: time_str.clone(),
            end_time: time_str,
            attributes,
        })
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_association(&self) -> (String, ProvAssociation) {
        let assoc_id = generate_prov_id("xudanu:assoc", &format!("{}:{}:{}", 
            self.attestation_type, self.attester_server_id, self.timestamp));
        let activity_id = generate_prov_id("xudanu:attestation", &format!("{}:{}:{}", 
            self.attestation_type, self.attester_server_id, self.timestamp));
        let agent_id = generate_prov_id("xudanu:server", &crate::crypto::keys::hex_encode(self.attester_server_id.as_bytes())[..8]);
        
        let mut attributes = std::collections::HashMap::new();
        attributes.insert("xudanu:attestationType".to_string(), ProvValue::string(&self.attestation_type));
        
        (assoc_id, ProvAssociation {
            activity: activity_id,
            agent: Some(agent_id),
            plan: None,
            role: Some("attester".to_string()),
            attributes,
        })
    }
}

impl ClusterVerificationActivity {
    pub fn new(
        activity_id: String,
        activity_type: String,
        start_time: u64,
        end_time: u64,
        verifying_servers: Vec<String>,
        consensus_type: String,
        threshold_met: bool,
    ) -> Self {
        ClusterVerificationActivity {
            activity_id,
            activity_type,
            start_time,
            end_time,
            verifying_servers,
            consensus_type,
            threshold_met,
        }
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_activity(&self) -> (String, ProvActivity) {
        let mut attributes = std::collections::HashMap::new();
        
        attributes.insert("prov:type".to_string(), ProvValue::qname(&self.activity_type));
        attributes.insert("xudanu:consensusType".to_string(), ProvValue::string(&self.consensus_type));
        attributes.insert("xudanu:thresholdMet".to_string(), ProvValue::string(&self.threshold_met.to_string()));
        attributes.insert("xudanu:verifyingServerCount".to_string(), 
            ProvValue::typed(&self.verifying_servers.len().to_string(), "xsd:integer"));
        
        (self.activity_id.clone(), ProvActivity {
            start_time: unix_to_iso8601(self.start_time),
            end_time: unix_to_iso8601(self.end_time),
            attributes,
        })
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_associations(&self) -> Vec<(String, ProvAssociation)> {
        let mut associations = Vec::new();
        
        for (idx, server_id) in self.verifying_servers.iter().enumerate() {
            let assoc_id = format!("{}:assoc:{}", self.activity_id, idx);
            let agent_id = generate_prov_id("xudanu:server", &crate::crypto::keys::hex_encode(server_id.as_bytes())[..8]);
            
            let mut attributes = std::collections::HashMap::new();
            attributes.insert("xudanu:role".to_string(), ProvValue::string("verifier"));
            
            associations.push((assoc_id, ProvAssociation {
                activity: self.activity_id.clone(),
                agent: Some(agent_id),
                plan: None,
                role: Some("verifier".to_string()),
                attributes,
            }));
        }
        
        associations
    }
}

impl FederationProvenanceBundle {
    pub fn new(
        bundle_id: String,
        timestamp: u64,
        federation_metadata: FederationMetadata,
    ) -> Self {
        FederationProvenanceBundle {
            bundle_id,
            timestamp,
            federation_metadata,
            server_agents: Vec::new(),
            verification_activities: Vec::new(),
            attestations: Vec::new(),
            cross_server_signatures: Vec::new(),
        }
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_bundle(&self) -> (String, ProvBundle) {
        let mut bundle_doc = ProvJsonDocument::with_default_prefix();
        
        // Add federation metadata as entity
        let (meta_entity_id, meta_entity) = self.federation_metadata.to_prov_entity();
        bundle_doc.entity.insert(meta_entity_id, meta_entity);
        
        // Add server agents
        for server_agent in &self.server_agents {
            let (agent_id, agent) = server_agent.to_prov_agent();
            bundle_doc.agent.insert(agent_id, agent);
        }
        
        // Add verification activities
        for verification in &self.verification_activities {
            let (activity_id, activity) = verification.to_prov_activity();
            bundle_doc.activity.insert(activity_id, activity);
            
            // Add associations for verifying servers
            for (assoc_id, association) in verification.to_prov_associations() {
                bundle_doc.wasAssociatedWith.insert(assoc_id, association);
            }
        }
        
        // Add attestations as activities and associations
        for attestation in &self.attestations {
            let (activity_id, activity) = attestation.to_prov_activity();
            bundle_doc.activity.insert(activity_id, activity);
            
            let (assoc_id, association) = attestation.to_prov_association();
            bundle_doc.wasAssociatedWith.insert(assoc_id, association);
        }
        
        // Add cross-server signatures as entities
        for (idx, sig) in self.cross_server_signatures.iter().enumerate() {
            let sig_entity_id = format!("{}:sig:{}", self.bundle_id, idx);
            let mut attributes = std::collections::HashMap::new();
            
            attributes.insert("prov:type".to_string(), ProvValue::qname("xudanu:CrossServerSignature"));
            attributes.insert("xudanu:serverId".to_string(), ProvValue::string(&crate::crypto::keys::hex_encode(&sig.server_id)));
            attributes.insert("xudanu:signature".to_string(), ProvValue::typed(&crate::crypto::keys::hex_encode(&sig.signature), "xsd:hexBinary"));
            attributes.insert("xudanu:timestamp".to_string(), ProvValue::typed(&sig.timestamp.to_string(), "xsd:integer"));
            
            if let Some(time_str) = unix_to_iso8601(sig.timestamp) {
                attributes.insert("xudanu:signedAt".to_string(), ProvValue::string(&time_str));
            }
            
            bundle_doc.entity.insert(sig_entity_id, ProvEntity { attributes });
        }
        
        // Add federation metadata generation activity
        let meta_activity_id = format!("{}:meta_gen", self.bundle_id);
        let mut meta_activity_attrs = std::collections::HashMap::new();
        meta_activity_attrs.insert("prov:type".to_string(), ProvValue::qname("xudanu:FederationMetadataGeneration"));
        
        if let Some(time_str) = unix_to_iso8601(self.timestamp) {
            meta_activity_attrs.insert("prov:startTime".to_string(), ProvValue::string(&time_str));
            meta_activity_attrs.insert("prov:endTime".to_string(), ProvValue::string(&time_str));
        }
        
        bundle_doc.activity.insert(meta_activity_id, ProvActivity {
            start_time: unix_to_iso8601(self.timestamp),
            end_time: unix_to_iso8601(self.timestamp),
            attributes: meta_activity_attrs,
        });
        
        (self.bundle_id.clone(), ProvBundle { content: bundle_doc })
    }

    pub fn add_server_agent(&mut self, agent: FederationServerAgent) {
        self.server_agents.push(agent);
    }

    pub fn add_verification_activity(&mut self, activity: ClusterVerificationActivity) {
        self.verification_activities.push(activity);
    }

    pub fn add_attestation(&mut self, attestation: FederationAttestation) {
        self.attestations.push(attestation);
    }

    pub fn add_cross_server_signature(&mut self, signature: CrossServerSignature) {
        self.cross_server_signatures.push(signature);
    }
}

// =============================================================================
// Phase 3: Cross-server signature verification to PROV association mapping
// =============================================================================

impl CrossServerSignature {
    #[cfg(feature = "serde")]
    pub fn to_prov_entity(&self) -> (String, ProvEntity) {
        let server_id_hex = crate::crypto::keys::hex_encode(&self.server_id);
        let entity_id = generate_prov_id("xudanu:crosssig", &format!("{}:{}", 
            &server_id_hex[..8.min(server_id_hex.len())], self.timestamp));
        let mut attributes = std::collections::HashMap::new();
        
        attributes.insert("prov:type".to_string(), ProvValue::qname("xudanu:CrossServerSignature"));
        attributes.insert("xudanu:serverId".to_string(), ProvValue::string(&crate::crypto::keys::hex_encode(&self.server_id)));
        attributes.insert("xudanu:signature".to_string(), ProvValue::typed(&crate::crypto::keys::hex_encode(&self.signature), "xsd:hexBinary"));
        attributes.insert("xudanu:timestamp".to_string(), ProvValue::typed(&self.timestamp.to_string(), "xsd:integer"));
        
        if let Some(time_str) = unix_to_iso8601(self.timestamp) {
            attributes.insert("xudanu:signedAt".to_string(), ProvValue::string(&time_str));
        }
        
        (entity_id, ProvEntity { attributes })
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_association(&self, activity_id: &str) -> (String, ProvAssociation) {
        let server_id_hex = crate::crypto::keys::hex_encode(&self.server_id);
        let assoc_id = format!("{}:assoc:{}", activity_id, &server_id_hex[..8.min(server_id_hex.len())]);
        let agent_id = generate_prov_id("xudanu:server", &server_id_hex[..8.min(server_id_hex.len())]);
        
        let mut attributes = std::collections::HashMap::new();
        attributes.insert("xudanu:signature".to_string(), ProvValue::typed(&crate::crypto::keys::hex_encode(&self.signature), "xsd:hexBinary"));
        
        (assoc_id, ProvAssociation {
            activity: activity_id.to_string(),
            agent: Some(agent_id),
            plan: None,
            role: Some("verifier".to_string()),
            attributes,
        })
    }
}

// =============================================================================
// Phase 3: Cluster consensus to PROV bundle mapping
// =============================================================================

impl ClusterConsensus {
    #[cfg(feature = "serde")]
    pub fn to_prov_bundle(&self, bundle_id: String, base_provenance: &Provenance) -> (String, ProvBundle) {
        let mut bundle_doc = ProvJsonDocument::with_default_prefix();
        
        // Add consensus entity
        let consensus_entity_id = format!("{}:consensus", bundle_id);
        let mut consensus_attrs = std::collections::HashMap::new();
        
        consensus_attrs.insert("prov:type".to_string(), ProvValue::qname("prov:Collection"));
        consensus_attrs.insert("xudanu:consensusType".to_string(), 
            ProvValue::string(match self.consensus_type {
                ConsensusType::Unanimous => "unanimous",
                ConsensusType::Majority => "majority",
                ConsensusType::Supermajority => "supermajority",
            }));
        consensus_attrs.insert("xudanu:thresholdMet".to_string(), ProvValue::string(&self.threshold_met.to_string()));
        consensus_attrs.insert("xudanu:totalServers".to_string(), 
            ProvValue::typed(&self.total_servers.to_string(), "xsd:integer"));
        consensus_attrs.insert("xudanu:approvingServers".to_string(), 
            ProvValue::typed(&self.approving_servers.to_string(), "xsd:integer"));
        
        bundle_doc.entity.insert(consensus_entity_id.clone(), ProvEntity { attributes: consensus_attrs });
        
        // Add verification activity
        let activity_id = format!("{}:verification", bundle_id);
        let mut activity_attrs = std::collections::HashMap::new();
        
        activity_attrs.insert("prov:type".to_string(), ProvValue::qname("xudanu:ClusterVerification"));
        
        let timestamp = base_provenance.timestamp;
        if let Some(time_str) = unix_to_iso8601(timestamp) {
            activity_attrs.insert("prov:startTime".to_string(), ProvValue::string(&time_str));
            activity_attrs.insert("prov:endTime".to_string(), ProvValue::string(&time_str));
        }
        
        bundle_doc.activity.insert(activity_id.clone(), ProvActivity {
            start_time: unix_to_iso8601(timestamp),
            end_time: unix_to_iso8601(timestamp),
            attributes: activity_attrs,
        });
        
        // Add server associations for verifications
        for verification in &self.verifications {
            if verification.verified {
                let server_id_hex = crate::crypto::keys::hex_encode(&verification.server_id);
                let server_agent_id = generate_prov_id("xudanu:server", &server_id_hex[..8.min(server_id_hex.len())]);
                
                let assoc_id = format!("{}:assoc:{}", activity_id, &server_id_hex[..8.min(server_id_hex.len())]);
                let mut assoc_attrs = std::collections::HashMap::new();
                
                if let Some(time_str) = unix_to_iso8601(verification.timestamp) {
                    assoc_attrs.insert("xudanu:verifiedAt".to_string(), ProvValue::string(&time_str));
                }
                
                bundle_doc.wasAssociatedWith.insert(assoc_id, ProvAssociation {
                    activity: activity_id.clone(),
                    agent: Some(server_agent_id.clone()),
                    plan: None,
                    role: Some("verifier".to_string()),
                    attributes: assoc_attrs,
                });
                
                // Add server agent if not present
                if !bundle_doc.agent.contains_key(&server_agent_id) {
                    let mut server_attrs = std::collections::HashMap::new();
                    server_attrs.insert("prov:type".to_string(), ProvValue::qname("xudanu:Server"));
                    server_attrs.insert("xudanu:serverId".to_string(), ProvValue::string(&server_id_hex));
                    
                    bundle_doc.agent.insert(server_agent_id, ProvAgent { attributes: server_attrs });
                }
            }
        }
        
        (bundle_id, ProvBundle { content: bundle_doc })
    }
}

// =============================================================================
// Phase 3: Enhanced FederatedProvenance PROV-JSON conversion
// =============================================================================

impl FederatedProvenance {
    #[cfg(feature = "serde")]
    pub fn to_prov_json_with_federation(&self) -> Result<ProvJsonDocument, String> {
        let mut doc = self.to_prov_json()?;
        
        // Add federation-specific bundle
        if !self.cross_server_signatures.is_empty() {
            let bundle_id = generate_federation_bundle_id(self.base_provenance.timestamp);
            let (bundle_id_str, bundle) = self.consensus.to_prov_bundle(bundle_id, &self.base_provenance);
            
            let mut bundles = std::collections::HashMap::new();
            bundles.insert(bundle_id_str, bundle);
            doc.bundle = Some(bundles);
        }
        
        Ok(doc)
    }

    #[cfg(feature = "serde")]
    pub fn export_federation_provenance_bundle(&self) -> Result<FederationProvenanceBundle, String> {
        let bundle_id = generate_federation_bundle_id(self.base_provenance.timestamp);
        let mut bundle = FederationProvenanceBundle::new(
            bundle_id.clone(),
            self.base_provenance.timestamp,
            FederationMetadata::new(
                crate::crypto::keys::hex_encode(&self.base_provenance.server_id),
                "xudanu-federation".to_string(),
                self.consensus.total_servers,
                match self.consensus.consensus_type {
                    ConsensusType::Unanimous => "unanimous".to_string(),
                    ConsensusType::Majority => "majority".to_string(),
                    ConsensusType::Supermajority => "supermajority".to_string(),
                },
                2,
                "active".to_string(),
            ),
        );
        
        // Add server agents from verifications
        for verification in &self.consensus.verifications {
            if verification.verified {
                let server_id_hex = crate::crypto::keys::hex_encode(&verification.server_id);
                bundle.add_server_agent(FederationServerAgent::new(
                    server_id_hex.clone(),
                    crate::crypto::keys::hex_encode(&verification.server_id),
                    "".to_string(),
                    "active".to_string(),
                    0,
                    verification.timestamp,
                ));
            }
        }
        
        // Add cross-server signatures
        for sig in &self.cross_server_signatures {
            bundle.add_cross_server_signature(sig.clone());
        }
        
        // Add verification activity
        let verification_activity = ClusterVerificationActivity::new(
            format!("{}:verification", bundle_id),
            "xudanu:ClusterVerification".to_string(),
            self.base_provenance.timestamp,
            self.base_provenance.timestamp,
            self.consensus.verifications.iter()
                .filter(|v| v.verified)
                .map(|v| crate::crypto::keys::hex_encode(&v.server_id))
                .collect(),
            match self.consensus.consensus_type {
                ConsensusType::Unanimous => "unanimous".to_string(),
                ConsensusType::Majority => "majority".to_string(),
                ConsensusType::Supermajority => "supermajority".to_string(),
            },
            self.consensus.threshold_met,
        );
        bundle.add_verification_activity(verification_activity);
        
        Ok(bundle)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AuthorType {
    Human,
    Llm,
    Historical,
}

impl AuthorType {
    #[cfg(feature = "serde")]
    pub fn to_prov_agent_type(&self) -> &'static str {
        match self {
            AuthorType::Human => "prov:Person",
            AuthorType::Llm => "xudanu:LLMAgent",
            AuthorType::Historical => "prov:Person",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConsensusType {
    Unanimous,
    Majority,
    Supermajority,
}

impl std::fmt::Display for ConsensusType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ConsensusType::Unanimous => write!(f, "unanimous"),
            ConsensusType::Majority => write!(f, "majority"),
            ConsensusType::Supermajority => write!(f, "supermajority"),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ElementProvenance {
    pub author_public_key: [u8; 32],
    pub author_display_name: String,
    pub author_club_id: BeId,
    pub timestamp: u64,
    pub author_type: AuthorType,
    pub llm_model: Option<String>,
    pub historical_author_id: Option<BeId>,
    pub source_work_id: Option<BeId>,
    pub transcluded_by: Option<TransclusionInfo>,
    pub derived_by: Option<DerivationInfo>,
}

impl DerivationMethod {
    #[cfg(feature = "serde")]
    pub fn to_prov_type(&self) -> &'static str {
        match self {
            DerivationMethod::Transclusion => "xudanu:Transclusion",
            DerivationMethod::Merge => "xudanu:Merge",
            DerivationMethod::Import => "prov:Revision",
            DerivationMethod::Annotation => "prov:Quotation",
            DerivationMethod::Revision => "prov:Revision",
        }
    }
}

#[cfg(feature = "serde")]
mod element_serde_impl {
    use super::*;
    use serde::{Deserialize, Deserializer, Serialize, Serializer};

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct ElementProvenanceData {
        author_public_key: Vec<u8>,
        author_display_name: String,
        author_club_id: u64,
        timestamp: u64,
        author_type: Option<String>,
        llm_model: Option<String>,
        historical_author_id: Option<u64>,
        #[serde(default)]
        source_work_id: Option<u64>,
        #[serde(default)]
        transcluded_by: Option<TransclusionInfoData>,
        #[serde(default)]
        derived_by: Option<DerivationInfoData>,
    }

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct DerivationInfoData {
        method: String,
        curator_club_id: u64,
        curator_display_name: String,
        curator_public_key: Vec<u8>,
        timestamp: u64,
    }

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct TransclusionInfoData {
        club_id: u64,
        display_name: String,
        public_key: Vec<u8>,
        timestamp: u64,
    }

    impl Serialize for ElementProvenance {
        fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
            ElementProvenanceData {
                author_public_key: self.author_public_key.to_vec(),
                author_display_name: self.author_display_name.clone(),
                author_club_id: self.author_club_id,
                timestamp: self.timestamp,
                author_type: Some(match self.author_type {
                    AuthorType::Human => "human".to_string(),
                    AuthorType::Llm => "llm".to_string(),
                    AuthorType::Historical => "historical".to_string(),
                }),
                llm_model: self.llm_model.clone(),
                historical_author_id: self.historical_author_id,
                source_work_id: self.source_work_id,
                transcluded_by: self.transcluded_by.as_ref().map(|t| TransclusionInfoData {
                    club_id: t.club_id,
                    display_name: t.display_name.clone(),
                    public_key: t.public_key.to_vec(),
                    timestamp: t.timestamp,
                }),
                derived_by: self.derived_by.as_ref().map(|d| DerivationInfoData {
                    method: match d.method {
                        DerivationMethod::Transclusion => "transclusion".to_string(),
                        DerivationMethod::Merge => "merge".to_string(),
                        DerivationMethod::Import => "import".to_string(),
                        DerivationMethod::Annotation => "annotation".to_string(),
                        DerivationMethod::Revision => "revision".to_string(),
                    },
                    curator_club_id: d.curator_club_id,
                    curator_display_name: d.curator_display_name.clone(),
                    curator_public_key: d.curator_public_key.to_vec(),
                    timestamp: d.timestamp,
                }),
            }
            .serialize(s)
        }
    }

    impl<'de> Deserialize<'de> for ElementProvenance {
        fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
            let data = ElementProvenanceData::deserialize(d)?;
            let author_public_key: [u8; 32] = data
                .author_public_key
                .try_into()
                .map_err(|_| serde::de::Error::custom("author_public_key must be 32 bytes"))?;
            let author_type = match data.author_type.as_deref() {
                Some("llm") => AuthorType::Llm,
                Some("historical") => AuthorType::Historical,
                _ => AuthorType::Human,
            };
            let transcluded_by = data.transcluded_by.map(|t| {
                let public_key: [u8; 32] = t.public_key.try_into().unwrap_or([0u8; 32]);
                TransclusionInfo {
                    club_id: t.club_id,
                    display_name: t.display_name,
                    public_key,
                    timestamp: t.timestamp,
                }
            });
            let derived_by = data.derived_by.map(|d| {
                let curator_public_key: [u8; 32] =
                    d.curator_public_key.try_into().unwrap_or([0u8; 32]);
                let method = match d.method.as_str() {
                    "merge" => DerivationMethod::Merge,
                    "import" => DerivationMethod::Import,
                    "annotation" => DerivationMethod::Annotation,
                    "revision" => DerivationMethod::Revision,
                    _ => DerivationMethod::Transclusion,
                };
                DerivationInfo {
                    method,
                    curator_club_id: d.curator_club_id,
                    curator_display_name: d.curator_display_name,
                    curator_public_key,
                    timestamp: d.timestamp,
                }
            });
            Ok(ElementProvenance {
                author_public_key,
                author_display_name: data.author_display_name,
                author_club_id: data.author_club_id,
                timestamp: data.timestamp,
                author_type,
                llm_model: data.llm_model,
                historical_author_id: data.historical_author_id,
                source_work_id: data.source_work_id,
                transcluded_by,
                derived_by,
            })
        }
    }
}

pub fn sign_element(
    signing_key: &SigningKey,
    element_fingerprint: &[u8; 32],
    timestamp: u64,
    server_id: &[u8; 32],
) -> Provenance {
    let mut hasher = Hasher::new();
    hasher.update(ELEMENT_PROVENANCE_DOMAIN);
    hasher.update(element_fingerprint);
    hasher.update(&signing_key.verifying_key().to_bytes());
    hasher.update(&timestamp.to_le_bytes());
    hasher.update(server_id);
    let payload: [u8; 32] = hasher.finalize().into();
    let signature = crate::crypto::sign::sign_bytes(signing_key, &payload);
    Provenance {
        author_public_key: signing_key.verifying_key().to_bytes(),
        signature: signature.to_bytes(),
        timestamp,
        server_id: *server_id,
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Provenance {
    pub author_public_key: [u8; 32],
    pub signature: [u8; 64],
    pub timestamp: u64,
    pub server_id: [u8; 32],
}

#[cfg(feature = "serde")]
mod serde_impl {
    use super::*;
    use serde::{Deserialize, Deserializer, Serialize, Serializer};

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct ProvenanceData {
        author_public_key: Vec<u8>,
        signature: Vec<u8>,
        timestamp: u64,
        server_id: Vec<u8>,
    }

    impl Serialize for Provenance {
        fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
            ProvenanceData {
                author_public_key: self.author_public_key.to_vec(),
                signature: self.signature.to_vec(),
                timestamp: self.timestamp,
                server_id: self.server_id.to_vec(),
            }
            .serialize(s)
        }
    }

    impl<'de> Deserialize<'de> for Provenance {
        fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
            let data = ProvenanceData::deserialize(d)?;
            let author_public_key: [u8; 32] = data
                .author_public_key
                .try_into()
                .map_err(|_| serde::de::Error::custom("author_public_key must be 32 bytes"))?;
            let signature: [u8; 64] = data
                .signature
                .try_into()
                .map_err(|_| serde::de::Error::custom("signature must be 64 bytes"))?;
            let server_id: [u8; 32] = data
                .server_id
                .try_into()
                .map_err(|_| serde::de::Error::custom("server_id must be 32 bytes"))?;
            Ok(Provenance {
                author_public_key,
                signature,
                timestamp: data.timestamp,
                server_id,
            })
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpanProvenance {
    pub start: i64,
    pub end: i64,
    pub provenance: Provenance,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CrossServerSignature {
    pub server_id: [u8; 32],
    pub verifying_key: [u8; 32],
    pub signature: [u8; 64],
    pub timestamp: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ServerVerification {
    pub server_id: [u8; 32],
    pub verified: bool,
    pub timestamp: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ClusterConsensus {
    pub consensus_type: ConsensusType,
    pub verifications: Vec<ServerVerification>,
    pub threshold_met: bool,
    pub total_servers: u32,
    pub approving_servers: u32,
    pub timestamp: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FederatedProvenance {
    pub base_provenance: Provenance,
    pub cross_server_signatures: Vec<CrossServerSignature>,
    pub consensus: ClusterConsensus,
}

#[cfg(feature = "serde")]
impl serde::Serialize for SpanProvenance {
    fn serialize<S: serde::Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
        use serde::ser::SerializeStruct;
        let mut state = s.serialize_struct("SpanProvenance", 3)?;
        state.serialize_field("start", &self.start)?;
        state.serialize_field("end", &self.end)?;
        state.serialize_field("provenance", &self.provenance)?;
        state.end()
    }
}

#[cfg(feature = "serde")]
impl<'de> serde::Deserialize<'de> for SpanProvenance {
    fn deserialize<D: serde::Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
        #[derive(serde::Deserialize)]
        struct SpanProvenanceData {
            start: i64,
            end: i64,
            provenance: Provenance,
        }
        let data = SpanProvenanceData::deserialize(d)?;
        Ok(SpanProvenance {
            start: data.start,
            end: data.end,
            provenance: data.provenance,
        })
    }
}

#[cfg(feature = "serde")]
mod federation_serde_impl {
    use super::*;
    use serde::{Deserialize, Deserializer, Serialize, Serializer};

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct CrossServerSignatureData {
        server_id: Vec<u8>,
        verifying_key: Vec<u8>,
        signature: Vec<u8>,
        timestamp: u64,
    }

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct ServerVerificationData {
        server_id: Vec<u8>,
        verified: bool,
        timestamp: u64,
    }

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct ClusterConsensusData {
        consensus_type: String,
        verifications: Vec<ServerVerificationData>,
        threshold_met: bool,
        total_servers: u32,
        approving_servers: u32,
        timestamp: u64,
    }

    #[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
    struct FederatedProvenanceData {
        base_provenance: Provenance,
        cross_server_signatures: Vec<CrossServerSignatureData>,
        consensus: ClusterConsensusData,
    }

    impl Serialize for CrossServerSignature {
        fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
            CrossServerSignatureData {
                server_id: self.server_id.to_vec(),
                verifying_key: self.verifying_key.to_vec(),
                signature: self.signature.to_vec(),
                timestamp: self.timestamp,
            }
            .serialize(s)
        }
    }

    impl<'de> Deserialize<'de> for CrossServerSignature {
        fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
            let data = CrossServerSignatureData::deserialize(d)?;
            let server_id: [u8; 32] = data
                .server_id
                .try_into()
                .map_err(|_| serde::de::Error::custom("server_id must be 32 bytes"))?;
            let signature: [u8; 64] = data
                .signature
                .try_into()
                .map_err(|_| serde::de::Error::custom("signature must be 64 bytes"))?;
            let verifying_key: [u8; 32] = data
                .verifying_key
                .try_into()
                .map_err(|_| serde::de::Error::custom("verifying_key must be 32 bytes"))?;
            Ok(CrossServerSignature {
                server_id,
                verifying_key,
                signature,
                timestamp: data.timestamp,
            })
        }
    }

    impl Serialize for ServerVerification {
        fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
            ServerVerificationData {
                server_id: self.server_id.to_vec(),
                verified: self.verified,
                timestamp: self.timestamp,
            }
            .serialize(s)
        }
    }

    impl<'de> Deserialize<'de> for ServerVerification {
        fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
            let data = ServerVerificationData::deserialize(d)?;
            let server_id: [u8; 32] = data
                .server_id
                .try_into()
                .map_err(|_| serde::de::Error::custom("server_id must be 32 bytes"))?;
            Ok(ServerVerification {
                server_id,
                verified: data.verified,
                timestamp: data.timestamp,
            })
        }
    }

    impl Serialize for ClusterConsensus {
        fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
            ClusterConsensusData {
                consensus_type: match self.consensus_type {
                    ConsensusType::Unanimous => "unanimous".to_string(),
                    ConsensusType::Majority => "majority".to_string(),
                    ConsensusType::Supermajority => "supermajority".to_string(),
                },
                verifications: self
                    .verifications
                    .iter()
                    .map(|v| ServerVerificationData {
                        server_id: v.server_id.to_vec(),
                        verified: v.verified,
                        timestamp: v.timestamp,
                    })
                    .collect(),
                threshold_met: self.threshold_met,
                total_servers: self.total_servers,
                approving_servers: self.approving_servers,
                timestamp: self.timestamp,
            }
            .serialize(s)
        }
    }

    impl<'de> Deserialize<'de> for ClusterConsensus {
        fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
            let data = ClusterConsensusData::deserialize(d)?;
            let consensus_type = match data.consensus_type.as_str() {
                "majority" => ConsensusType::Majority,
                "supermajority" => ConsensusType::Supermajority,
                _ => ConsensusType::Unanimous,
            };
            let verifications = data
                .verifications
                .into_iter()
                .map(|v| {
                    let server_id: [u8; 32] = v.server_id.try_into().unwrap_or([0u8; 32]);
                    ServerVerification {
                        server_id,
                        verified: v.verified,
                        timestamp: v.timestamp,
                    }
                })
                .collect();
            Ok(ClusterConsensus {
                consensus_type,
                verifications,
                threshold_met: data.threshold_met,
                total_servers: data.total_servers,
                approving_servers: data.approving_servers,
                timestamp: data.timestamp,
            })
        }
    }

    impl Serialize for FederatedProvenance {
        fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
            FederatedProvenanceData {
                base_provenance: self.base_provenance.clone(),
                cross_server_signatures: self
                    .cross_server_signatures
                    .iter()
                    .map(|sig| CrossServerSignatureData {
                        server_id: sig.server_id.to_vec(),
                        verifying_key: sig.verifying_key.to_vec(),
                        signature: sig.signature.to_vec(),
                        timestamp: sig.timestamp,
                    })
                    .collect(),
                consensus: ClusterConsensusData {
                    consensus_type: match self.consensus.consensus_type {
                        ConsensusType::Unanimous => "unanimous".to_string(),
                        ConsensusType::Majority => "majority".to_string(),
                        ConsensusType::Supermajority => "supermajority".to_string(),
                    },
                    verifications: self
                        .consensus
                        .verifications
                        .iter()
                        .map(|v| ServerVerificationData {
                            server_id: v.server_id.to_vec(),
                            verified: v.verified,
                            timestamp: v.timestamp,
                        })
                        .collect(),
                    threshold_met: self.consensus.threshold_met,
                    total_servers: self.consensus.total_servers,
                    approving_servers: self.consensus.approving_servers,
                    timestamp: self.consensus.timestamp,
                },
            }
            .serialize(s)
        }
    }

    impl<'de> Deserialize<'de> for FederatedProvenance {
        fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
            let data = FederatedProvenanceData::deserialize(d)?;
            let cross_server_signatures = data
                .cross_server_signatures
                .into_iter()
                .map(|sig| {
                    let server_id: [u8; 32] = sig.server_id.try_into().unwrap_or([0u8; 32]);
                    let verifying_key: [u8; 32] = sig.verifying_key.try_into().unwrap_or([0u8; 32]);
                    let signature: [u8; 64] = sig.signature.try_into().unwrap_or([0u8; 64]);
                    CrossServerSignature {
                        server_id,
                        verifying_key,
                        signature,
                        timestamp: sig.timestamp,
                    }
                })
                .collect();
            let consensus_type = match data.consensus.consensus_type.as_str() {
                "majority" => ConsensusType::Majority,
                "supermajority" => ConsensusType::Supermajority,
                _ => ConsensusType::Unanimous,
            };
            let verifications = data
                .consensus
                .verifications
                .into_iter()
                .map(|v| {
                    let server_id: [u8; 32] = v.server_id.try_into().unwrap_or([0u8; 32]);
                    ServerVerification {
                        server_id,
                        verified: v.verified,
                        timestamp: v.timestamp,
                    }
                })
                .collect();
            let consensus = ClusterConsensus {
                consensus_type,
                verifications,
                threshold_met: data.consensus.threshold_met,
                total_servers: data.consensus.total_servers,
                approving_servers: data.consensus.approving_servers,
                timestamp: data.consensus.timestamp,
            };
            Ok(FederatedProvenance {
                base_provenance: data.base_provenance,
                cross_server_signatures,
                consensus,
            })
        }
    }
}

pub fn compute_span_fingerprint_hex(fingerprints: &[[u8; 32]]) -> String {
    let fp = compute_span_fingerprint(fingerprints);
    fp.iter().map(|b| format!("{:02x}", b)).collect()
}

fn compute_span_fingerprint(fingerprints: &[[u8; 32]]) -> [u8; 32] {
    let mut hasher = Hasher::new();
    hasher.update(PROVENANCE_DOMAIN);
    for fp in fingerprints {
        hasher.update(fp);
    }
    hasher.finalize().into()
}

fn compute_signing_payload(
    span_fingerprint: &[u8; 32],
    author_public_key: &[u8; 32],
    timestamp: u64,
    server_id: &[u8; 32],
) -> [u8; 32] {
    let mut hasher = Hasher::new();
    hasher.update(PROVENANCE_DOMAIN);
    hasher.update(span_fingerprint);
    hasher.update(author_public_key);
    hasher.update(&timestamp.to_le_bytes());
    hasher.update(server_id);
    hasher.finalize().into()
}

pub fn sign_span(
    signing_key: &SigningKey,
    element_fingerprints: &[[u8; 32]],
    timestamp: u64,
    server_id: &[u8; 32],
) -> Provenance {
    let span_fp = compute_span_fingerprint(element_fingerprints);
    let payload = compute_signing_payload(
        &span_fp,
        &signing_key.verifying_key().to_bytes(),
        timestamp,
        server_id,
    );
    let signature = crate::crypto::sign::sign_bytes(signing_key, &payload);
    Provenance {
        author_public_key: signing_key.verifying_key().to_bytes(),
        signature: signature.to_bytes(),
        timestamp,
        server_id: *server_id,
    }
}

pub fn verify_span_provenance(provenance: &Provenance, element_fingerprints: &[[u8; 32]]) -> bool {
    let span_fp = compute_span_fingerprint(element_fingerprints);
    verify_span_provenance_with_span_fp(provenance, &span_fp)
}

pub fn verify_span_provenance_with_span_fp(
    provenance: &Provenance,
    span_fingerprint: &[u8; 32],
) -> bool {
    let verifying_key = match VerifyingKey::from_bytes(&provenance.author_public_key) {
        Ok(vk) => vk,
        Err(_) => return false,
    };
    let payload = compute_signing_payload(
        span_fingerprint,
        &provenance.author_public_key,
        provenance.timestamp,
        &provenance.server_id,
    );
    let signature = Signature::from_bytes(&provenance.signature);
    crate::crypto::sign::verify_signature(&verifying_key, &payload, &signature).is_ok()
}

pub fn sign_historical_attestation(
    server_signing_key: &SigningKey,
    element_fingerprints: &[[u8; 32]],
    historical_author_id: BeId,
    timestamp: u64,
    server_id: &[u8; 32],
) -> Provenance {
    let span_fp = compute_span_fingerprint(element_fingerprints);
    let mut hasher = Hasher::new();
    hasher.update(HISTORICAL_ATTESTATION_DOMAIN);
    hasher.update(&span_fp);
    hasher.update(&server_signing_key.verifying_key().to_bytes());
    hasher.update(&historical_author_id.to_le_bytes());
    hasher.update(&timestamp.to_le_bytes());
    hasher.update(server_id);
    let payload: [u8; 32] = hasher.finalize().into();
    let signature = crate::crypto::sign::sign_bytes(server_signing_key, &payload);
    Provenance {
        author_public_key: server_signing_key.verifying_key().to_bytes(),
        signature: signature.to_bytes(),
        timestamp,
        server_id: *server_id,
    }
}

pub fn verify_historical_attestation(
    provenance: &Provenance,
    element_fingerprints: &[[u8; 32]],
    historical_author_id: BeId,
) -> bool {
    let verifying_key = match VerifyingKey::from_bytes(&provenance.author_public_key) {
        Ok(vk) => vk,
        Err(_) => return false,
    };
    let span_fp = compute_span_fingerprint(element_fingerprints);
    let mut hasher = Hasher::new();
    hasher.update(HISTORICAL_ATTESTATION_DOMAIN);
    hasher.update(&span_fp);
    hasher.update(&provenance.author_public_key);
    hasher.update(&historical_author_id.to_le_bytes());
    hasher.update(&provenance.timestamp.to_le_bytes());
    hasher.update(&provenance.server_id);
    let payload: [u8; 32] = hasher.finalize().into();
    let signature = Signature::from_bytes(&provenance.signature);
    crate::crypto::sign::verify_signature(&verifying_key, &payload, &signature).is_ok()
}

fn compute_federation_payload(
    base_provenance: &Provenance,
    server_id: &[u8; 32],
    timestamp: u64,
) -> [u8; 32] {
    let mut hasher = Hasher::new();
    hasher.update(FEDERATION_PROVENANCE_DOMAIN);
    hasher.update(&base_provenance.author_public_key);
    hasher.update(&base_provenance.signature);
    hasher.update(&base_provenance.timestamp.to_le_bytes());
    hasher.update(&base_provenance.server_id);
    hasher.update(server_id);
    hasher.update(&timestamp.to_le_bytes());
    hasher.finalize().into()
}

#[cfg(feature = "serde")]
pub(crate) fn unix_to_iso8601(timestamp: u64) -> Option<String> {
    use std::time::SystemTime;
    
    SystemTime::UNIX_EPOCH
        .checked_add(std::time::Duration::from_secs(timestamp))
        .and_then(|dt| {
            let datetime: chrono::DateTime<chrono::Utc> = chrono::DateTime::from(dt);
            Some(datetime.format("%Y-%m-%dT%H:%M:%S%.9fZ").to_string())
        })
}

pub fn sign_cross_server(
    signing_key: &SigningKey,
    base_provenance: &Provenance,
    server_id: &[u8; 32],
    verifying_key: &[u8; 32],
    timestamp: u64,
) -> CrossServerSignature {
    let payload = compute_federation_payload(base_provenance, server_id, timestamp);
    let signature = crate::crypto::sign::sign_bytes(signing_key, &payload);
    CrossServerSignature {
        server_id: *server_id,
        verifying_key: *verifying_key,
        signature: signature.to_bytes(),
        timestamp,
    }
}

pub fn verify_federation_provenance(
    federated: &FederatedProvenance,
    _server_verifying_keys: &[[u8; 32]],
) -> bool {
    let verifying_key = match VerifyingKey::from_bytes(&federated.base_provenance.author_public_key) {
        Ok(vk) => vk,
        Err(_) => return false,
    };
    
    let signature = Signature::from_bytes(&federated.base_provenance.signature);
    let payload = compute_signing_payload(
        &compute_span_fingerprint(&[federated.base_provenance.author_public_key]),
        &federated.base_provenance.author_public_key,
        federated.base_provenance.timestamp,
        &federated.base_provenance.server_id,
    );
    
    if !crate::crypto::sign::verify_signature(&verifying_key, &payload, &signature).is_ok() {
        return false;
    }
    
    for cross_sig in &federated.cross_server_signatures {
        let key_bytes: [u8; 32] = cross_sig.server_id;
        let verifying_key = match VerifyingKey::from_bytes(&key_bytes) {
            Ok(vk) => vk,
            Err(_) => continue,
        };
        let payload = compute_federation_payload(&federated.base_provenance, &cross_sig.server_id, cross_sig.timestamp);
        let signature = Signature::from_bytes(&cross_sig.signature);
        if crate::crypto::sign::verify_signature(&verifying_key, &payload, &signature).is_err() {
            return false;
        }
    }
    
    match federated.consensus.consensus_type {
        ConsensusType::Unanimous => federated.cross_server_signatures.len() as u32 == federated.consensus.total_servers,
        ConsensusType::Majority => federated.cross_server_signatures.len() as u32 > federated.consensus.total_servers / 2,
        ConsensusType::Supermajority => {
            let threshold = (federated.consensus.total_servers as f64 * 0.67).ceil() as u32;
            federated.cross_server_signatures.len() as u32 >= threshold
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto::sign::generate_signing_key;
    use crate::edition::RangeElement;

    fn make_fingerprints() -> Vec<[u8; 32]> {
        vec![
            RangeElement::text("H").content_fingerprint(),
            RangeElement::text("e").content_fingerprint(),
            RangeElement::text("l").content_fingerprint(),
        ]
    }

    #[test]
    fn sign_and_verify_roundtrip() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        server_id[..4].copy_from_slice(b"serv");
        let prov = sign_span(&key, &fps, 1000, &server_id);
        assert!(verify_span_provenance(&prov, &fps));
    }

    #[test]
    fn verify_rejects_wrong_fingerprints() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        let prov = sign_span(&key, &fps, 1000, &server_id);
        let wrong_fps = vec![RangeElement::text("X").content_fingerprint()];
        assert!(!verify_span_provenance(&prov, &wrong_fps));
    }

    #[test]
    fn verify_rejects_wrong_key() {
        let key_a = generate_signing_key();
        let key_b = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        let mut prov = sign_span(&key_a, &fps, 1000, &server_id);
        prov.author_public_key = key_b.verifying_key().to_bytes();
        assert!(!verify_span_provenance(&prov, &fps));
    }

    #[test]
    fn verify_rejects_tampered_signature() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        let mut prov = sign_span(&key, &fps, 1000, &server_id);
        prov.signature[0] ^= 0xff;
        assert!(!verify_span_provenance(&prov, &fps));
    }

    #[test]
    fn verify_rejects_wrong_timestamp() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        let mut prov = sign_span(&key, &fps, 1000, &server_id);
        prov.timestamp = 2000;
        assert!(!verify_span_provenance(&prov, &fps));
    }

    #[test]
    fn same_content_same_fingerprint() {
        let fps1 = vec![RangeElement::text("abc").content_fingerprint()];
        let fps2 = vec![RangeElement::text("abc").content_fingerprint()];
        assert_eq!(
            compute_span_fingerprint(&fps1),
            compute_span_fingerprint(&fps2)
        );
    }

    #[test]
    fn different_content_different_fingerprint() {
        let fps1 = vec![RangeElement::text("abc").content_fingerprint()];
        let fps2 = vec![RangeElement::text("xyz").content_fingerprint()];
        assert_ne!(
            compute_span_fingerprint(&fps1),
            compute_span_fingerprint(&fps2)
        );
    }

    #[test]
    #[cfg(feature = "serde")]
    fn provenance_serde_roundtrip() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        server_id[..4].copy_from_slice(b"test");
        let prov = sign_span(&key, &fps, 12345, &server_id);

        let json = serde_json::to_string(&prov).unwrap();
        let restored: Provenance = serde_json::from_str(&json).unwrap();
        assert_eq!(prov, restored);
    }

    #[test]
    #[cfg(feature = "serde")]
    fn span_provenance_serde_roundtrip() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        let prov = sign_span(&key, &fps, 99999, &server_id);
        let sp = SpanProvenance {
            start: 0,
            end: 3,
            provenance: prov,
        };
 
        let json = serde_json::to_string(&sp).unwrap();
        let restored: SpanProvenance = serde_json::from_str(&json).unwrap();
        assert_eq!(sp, restored);
    }
}
// W3C PROV-JSON representation for existing provenance model
// See: https://www.w3.org/Submission/prov-json/

const PROV_JSON_DOMAIN: &[u8] = b"xudanu/v1/prov-json";
const PROV_NS: &str = "http://www.w3.org/ns/prov#";
const XUDANU_NS: &str = "http://xudanu.example.org/ns#";

// PHASE 1: PROV-JSON Data Structures

/// PROV literal value with explicit typing
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvValue {
    #[cfg_attr(feature = "serde", serde(rename = "$"))]
    pub value: String,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[serde(default)]
    pub type_: Option<String>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[serde(default)]
    pub lang: Option<String>,
}

impl ProvValue {
    pub fn string(value: &str) -> Self {
        ProvValue {
            value: value.to_string(),
            type_: None,
            lang: None,
        }
    }
    
    pub fn typed(value: &str, type_: &str) -> Self {
        ProvValue {
            value: value.to_string(),
            type_: Some(type_.to_string()),
            lang: None,
        }
    }
    
    pub fn typed_with_namespace(value: &str, type_: &str) -> Self {
        ProvValue {
            value: value.to_string(),
            type_: Some(format!("{}:{}", PROV_NS, type_.trim_start_matches(PROV_NS))),
            lang: None,
        }
    }
    
    pub fn qname(value: &str) -> Self {
        ProvValue {
            value: value.to_string(),
            type_: Some("xsd:QName".to_string()),
            lang: None,
        }
    }
}

/// PROV entity representation
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvEntity {
    #[serde(flatten)]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV activity representation  
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvActivity {
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:startTime")]
    pub start_time: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:endTime")]
    pub end_time: Option<String>,
    #[serde(flatten)]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV agent representation
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvAgent {
    #[serde(flatten)]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV attribution (wasAttributedTo) representation
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvAttribution {
    #[serde(rename = "prov:entity")]
    pub entity: String,
    #[serde(rename = "prov:agent")]
    pub agent: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:time")]
    pub time: Option<String>,
    #[serde(flatten)]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV derivation (wasDerivedFrom) representation
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvDerivation {
    #[serde(rename = "prov:generatedEntity")]
    pub generated_entity: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:activity")]
    pub activity: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:usage")]
    pub usage: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:generation")]
    pub generation: Option<String>,
    #[serde(rename = "prov:usedEntity")]
    pub used_entity: String,
    #[serde(flatten)]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV association (wasAssociatedWith) representation  
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvAssociation {
    #[serde(rename = "prov:activity")]
    pub activity: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:agent")]
    pub agent: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:plan")]
    pub plan: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:role")]
    pub role: Option<String>,
    #[serde(flatten)]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV generation (wasGeneratedBy) representation
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvGeneration {
    #[serde(rename = "prov:entity")]
    pub entity: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:activity")]
    pub activity: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "prov:time")]
    pub time: Option<String>,
    #[serde(flatten)]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV bundle representation (for federation)
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvBundle {
    #[serde(flatten)]
    pub content: ProvJsonDocument,
}

/// Complete PROV-JSON document
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvJsonDocument {
    #[serde(default)]
    pub prefix: std::collections::HashMap<String, String>,
    #[serde(default)]
    pub entity: std::collections::HashMap<String, ProvEntity>,
    #[serde(default)]
    pub activity: std::collections::HashMap<String, ProvActivity>,
    #[serde(default)]
    pub agent: std::collections::HashMap<String, ProvAgent>,
    #[serde(default)]
    pub wasAttributedTo: std::collections::HashMap<String, ProvAttribution>,
    #[serde(default)]
    pub wasDerivedFrom: std::collections::HashMap<String, ProvDerivation>,
    #[serde(default)]
    pub wasAssociatedWith: std::collections::HashMap<String, ProvAssociation>,
    #[serde(default)]
    pub wasGeneratedBy: std::collections::HashMap<String, ProvGeneration>,
    #[serde(default)]
    pub bundle: Option<std::collections::HashMap<String, ProvBundle>>,
}

impl ProvJsonDocument {
    pub fn new() -> Self {
        let mut doc = ProvJsonDocument {
            prefix: std::collections::HashMap::new(),
            entity: std::collections::HashMap::new(),
            activity: std::collections::HashMap::new(),
            agent: std::collections::HashMap::new(),
            wasAttributedTo: std::collections::HashMap::new(),
            wasDerivedFrom: std::collections::HashMap::new(),
            wasAssociatedWith: std::collections::HashMap::new(),
            wasGeneratedBy: std::collections::HashMap::new(),
            bundle: None,
        };
        
        // Add default prefixes
        doc.prefix.insert("prov".to_string(), PROV_NS.to_string());
        doc.prefix.insert("xsd".to_string(), "http://www.w3.org/2001/XMLSchema#".to_string());
        doc.prefix.insert("xudanu".to_string(), XUDANU_NS.to_string());
        
        doc
    }
    
    pub fn with_default_prefix() -> Self {
        Self::new()
    }
}

// PHASE 1: ID Generation Functions

/// Generate consistent PROV identifiers
pub fn generate_prov_id(prefix: &str, base_id: &str) -> String {
    format!("{}:{}", prefix, base_id)
}

/// Generate entity ID for span
pub fn generate_span_prov_id(work_id: BeId, span_start: i64, span_end: i64) -> String {
    generate_prov_id("xudanu:span", &format!("{}:{}:{}", work_id, span_start, span_end))
}

/// Generate agent ID for author
pub fn generate_author_prov_id(author_public_key: &[u8; 32]) -> String {
    let key_hex = crate::crypto::keys::hex_encode(author_public_key);
    generate_prov_id("xudanu:agent", &key_hex[..16]) // Use first 16 chars for brevity
}
/// Generate activity ID for edit operation
pub fn generate_edit_activity_id(work_id: BeId, timestamp: u64) -> String {
    generate_prov_id("xudanu:activity", &format!("{}:{}", work_id, timestamp))
}

/// Generate bundle ID for federation
pub fn generate_federation_bundle_id(timestamp: u64) -> String {
    generate_prov_id("xudanu:federation", &format!("consensus:{}", timestamp))
}

// PHASE 1: PROV-JSON Conversion Methods

impl FederatedProvenance {
    #[cfg(feature = "serde")]
    pub fn to_prov_json(&self) -> Result<ProvJsonDocument, String> {
        let mut doc = ProvJsonDocument::with_default_prefix();
        
        // Create entity for the span (using generic entity ID since we don't have span info)
        let entity_id = generate_span_prov_id(0, 0, 1);
        let mut entity_attrs = std::collections::HashMap::new();
        entity_attrs.insert("xudanu:timestamp".to_string(), 
            ProvValue::typed(&self.base_provenance.timestamp.to_string(), "xsd:integer"));
        entity_attrs.insert("xudanu:serverId".to_string(), 
            ProvValue::typed(&crate::crypto::keys::hex_encode(&self.base_provenance.server_id), "xsd:hexBinary"));
        
        doc.entity.insert(entity_id.clone(), ProvEntity { attributes: entity_attrs });
        
        // Create agent for the author
        let author_id = generate_author_prov_id(&self.base_provenance.author_public_key);
        let mut agent_attrs = std::collections::HashMap::new();
        agent_attrs.insert("prov:type".to_string(), 
            ProvValue::qname("prov:Person")); // Default to person
        agent_attrs.insert("xudanu:publicKey".to_string(), 
            ProvValue::typed(&crate::crypto::keys::hex_encode(&self.base_provenance.author_public_key), "xsd:hexBinary"));
        agent_attrs.insert("xudanu:signature".to_string(), 
            ProvValue::typed(&crate::crypto::keys::hex_encode(&self.base_provenance.signature), "xsd:hexBinary"));
        
        doc.agent.insert(author_id.clone(), ProvAgent { attributes: agent_attrs });
        
        // Create attribution
        let attribution_id = format!("attr:{}", entity_id);
        doc.wasAttributedTo.insert(attribution_id, ProvAttribution {
            entity: entity_id.clone(),
            agent: author_id.clone(),
            time: None,
            attributes: std::collections::HashMap::new(),
        });
        
        // Add cross-server signatures as activities and associations
        for (idx, sig) in self.cross_server_signatures.iter().enumerate() {
            let activity_id = format!("cross_sig:{}", idx);
            let mut activity_attrs = std::collections::HashMap::new();
            activity_attrs.insert("prov:type".to_string(), 
                ProvValue::qname("xudanu:CrossServerSignature"));
            activity_attrs.insert("xudanu:timestamp".to_string(), 
                ProvValue::typed(&sig.timestamp.to_string(), "xsd:integer"));
            activity_attrs.insert("xudanu:serverId".to_string(), 
                ProvValue::typed(&crate::crypto::keys::hex_encode(&sig.server_id), "xsd:hexBinary"));
            activity_attrs.insert("xudanu:verifyingKey".to_string(), 
                ProvValue::typed(&crate::crypto::keys::hex_encode(&sig.verifying_key), "xsd:hexBinary"));
            activity_attrs.insert("xudanu:signature".to_string(), 
                ProvValue::typed(&crate::crypto::keys::hex_encode(&sig.signature), "xsd:hexBinary"));
            
            doc.activity.insert(activity_id.clone(), ProvActivity {
                start_time: None,
                end_time: None,
                attributes: activity_attrs,
            });
            
            // Associate server agent with activity
            let server_agent_id = generate_prov_id("xudanu:server", 
                &crate::crypto::keys::hex_encode(&sig.server_id)[..8]);
            let mut server_attrs = std::collections::HashMap::new();
            server_attrs.insert("prov:type".to_string(), 
                ProvValue::qname("xudanu:Server"));
            server_attrs.insert("xudanu:serverId".to_string(), 
                ProvValue::typed(&crate::crypto::keys::hex_encode(&sig.server_id), "xsd:hexBinary"));
            
            doc.agent.insert(server_agent_id.clone(), ProvAgent { attributes: server_attrs });
            
            let assoc_id = format!("assoc:{}:{}", activity_id, idx);
            doc.wasAssociatedWith.insert(assoc_id, ProvAssociation {
                activity: activity_id.clone(),
                agent: Some(server_agent_id.clone()),
                role: Some("verifier".to_string()),
                plan: None,
                attributes: std::collections::HashMap::new(),
            });
        }
        
        // Add consensus as an entity
        let consensus_entity_id = format!("consensus:{}", self.consensus.timestamp);
        let mut consensus_attrs = std::collections::HashMap::new();
        consensus_attrs.insert("prov:type".to_string(), 
            ProvValue::qname("xudanu:ClusterConsensus"));
        consensus_attrs.insert("xudanu:consensusType".to_string(), 
            ProvValue::string(&self.consensus.consensus_type.to_string()));
        consensus_attrs.insert("xudanu:thresholdMet".to_string(), 
            ProvValue::string(&self.consensus.threshold_met.to_string()));
        consensus_attrs.insert("xudanu:totalServers".to_string(), 
            ProvValue::typed(&self.consensus.total_servers.to_string(), "xsd:integer"));
        consensus_attrs.insert("xudanu:approvingServers".to_string(), 
            ProvValue::typed(&self.consensus.approving_servers.to_string(), "xsd:integer"));
        
        doc.entity.insert(consensus_entity_id, ProvEntity { attributes: consensus_attrs });
        
        Ok(doc)
    }
}
