// =============================================================================
// Phase 3: Federation-PROV Integration
// =============================================================================
//
// Integration of federation features with W3C PROV-JSON provenance model.
// Maps federation operations (cross-server signatures, cluster consensus,
// membership, governance) to PROV entities, activities, and agents.

use blake3::Hasher;
#[cfg(feature = "server")]
use ed25519_dalek::{Signature, SigningKey, VerifyingKey};

use super::backend::BeId;

const PROVENANCE_DOMAIN: &[u8] = b"xudanu/v1/provenance";
const ELEMENT_PROVENANCE_DOMAIN: &[u8] = b"xudanu/v1/element-provenance";
const HISTORICAL_ATTESTATION_DOMAIN: &[u8] = b"xudanu/v1/historical-attestation";
const FEDERATION_PROVENANCE_DOMAIN: &[u8] = b"xudanu/v1/federation-provenance";

// Helper function for hex encoding (std-only: keeps this module
// buildable without the server feature; mirrors crypto::keys)
fn hex_encode(data: &[u8]) -> String {
    data.iter().map(|b| format!("{:02x}", b)).collect()
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
        let entity_id = generate_prov_id("xudanu", &format!("federation_{}", self.server_id));
        let mut attributes = std::collections::HashMap::new();

        attributes.insert(
            "prov:type".to_string(),
            ProvValue::qname("xudanu:FederationMetadata"),
        );
        attributes.insert(
            "xudanu:serverId".to_string(),
            ProvValue::string(&self.server_id),
        );
        attributes.insert(
            "xudanu:federationDomain".to_string(),
            ProvValue::string(&self.federation_domain),
        );
        attributes.insert(
            "xudanu:clusterSize".to_string(),
            ProvValue::typed(&self.cluster_size.to_string(), "xsd:integer"),
        );
        attributes.insert("xudanu:mode".to_string(), ProvValue::string(&self.mode));
        attributes.insert(
            "xudanu:minEndorsements".to_string(),
            ProvValue::typed(&self.min_endorsements.to_string(), "xsd:integer"),
        );
        attributes.insert(
            "xudanu:membershipStatus".to_string(),
            ProvValue::string(&self.membership_status),
        );

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
        let agent_id = generate_prov_id(
            "xudanu",
            &format!("server_{}", &hex_encode(self.server_id.as_bytes())[..8]),
        );
        let mut attributes = std::collections::HashMap::new();

        attributes.insert(
            "prov:type".to_string(),
            ProvValue::qname("xudanu:FederationServer"),
        );
        attributes.insert(
            "xudanu:serverId".to_string(),
            ProvValue::string(&self.server_id),
        );
        attributes.insert(
            "xudanu:verifyingKey".to_string(),
            ProvValue::typed(&self.verifying_key_hex, "xsd:hexBinary"),
        );
        attributes.insert(
            "xudanu:kexPublicKey".to_string(),
            ProvValue::typed(&self.kex_public_hex, "xsd:hexBinary"),
        );
        attributes.insert(
            "xudanu:membershipStatus".to_string(),
            ProvValue::string(&self.membership_status),
        );
        attributes.insert(
            "xudanu:endorsementCount".to_string(),
            ProvValue::typed(&self.endorsement_count.to_string(), "xsd:integer"),
        );

        attributes.insert(
            "xudanu:joinedAt".to_string(),
            ProvValue::string(&unix_to_iso8601(self.joined_at).unwrap_or_default()),
        );

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
        let activity_id = generate_prov_id(
            "xudanu:attestation",
            &format!(
                "{}:{}:{}",
                self.attestation_type, self.attester_server_id, self.timestamp
            ),
        );
        let mut attributes = std::collections::HashMap::new();

        attributes.insert(
            "prov:type".to_string(),
            ProvValue::qname("xudanu:FederationAttestation"),
        );
        attributes.insert(
            "xudanu:attestationType".to_string(),
            ProvValue::string(&self.attestation_type),
        );
        attributes.insert(
            "xudanu:attesterServerId".to_string(),
            ProvValue::string(&self.attester_server_id),
        );
        attributes.insert(
            "xudanu:subjectServerId".to_string(),
            ProvValue::string(&self.subject_server_id),
        );
        attributes.insert(
            "xudanu:signature".to_string(),
            ProvValue::typed(&hex_encode(&self.signature), "xsd:hexBinary"),
        );

        for (key, value) in &self.metadata {
            attributes.insert(format!("xudanu:meta_{}", key), ProvValue::string(value));
        }

        let time_str = unix_to_iso8601(self.timestamp);

        (
            activity_id,
            ProvActivity {
                start_time: time_str.clone(),
                end_time: time_str,
                attributes,
            },
        )
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_association(&self) -> (String, ProvAssociation) {
        let assoc_id = generate_prov_id(
            "xudanu:assoc",
            &format!(
                "{}:{}:{}",
                self.attestation_type, self.attester_server_id, self.timestamp
            ),
        );
        let activity_id = generate_prov_id(
            "xudanu:attestation",
            &format!(
                "{}:{}:{}",
                self.attestation_type, self.attester_server_id, self.timestamp
            ),
        );
        let agent_id = generate_prov_id(
            "xudanu:server",
            &hex_encode(self.attester_server_id.as_bytes())[..8],
        );

        let mut attributes = std::collections::HashMap::new();
        attributes.insert(
            "xudanu:attestationType".to_string(),
            ProvValue::string(&self.attestation_type),
        );

        (
            assoc_id,
            ProvAssociation {
                activity: activity_id,
                agent: Some(agent_id),
                plan: None,
                role: Some(ProvValue::qname("attester")),
                attributes,
            },
        )
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

        attributes.insert(
            "prov:type".to_string(),
            ProvValue::qname(&self.activity_type),
        );
        attributes.insert(
            "xudanu:consensusType".to_string(),
            ProvValue::string(&self.consensus_type),
        );
        attributes.insert(
            "xudanu:thresholdMet".to_string(),
            ProvValue::string(&self.threshold_met.to_string()),
        );
        attributes.insert(
            "xudanu:verifyingServerCount".to_string(),
            ProvValue::typed(&self.verifying_servers.len().to_string(), "xsd:integer"),
        );

        (
            self.activity_id.clone(),
            ProvActivity {
                start_time: unix_to_iso8601(self.start_time),
                end_time: unix_to_iso8601(self.end_time),
                attributes,
            },
        )
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_associations(&self) -> Vec<(String, ProvAssociation)> {
        let mut associations = Vec::new();

        for (idx, server_id) in self.verifying_servers.iter().enumerate() {
            let assoc_id = format!("{}:assoc:{}", self.activity_id, idx);
            let agent_id = generate_prov_id(
                "xudanu",
                &format!("server_{}", &hex_encode(server_id.as_bytes())[..8]),
            );

            let mut attributes = std::collections::HashMap::new();
            attributes.insert("xudanu:role".to_string(), ProvValue::string("verifier"));

            associations.push((
                assoc_id,
                ProvAssociation {
                    activity: self.activity_id.clone(),
                    agent: Some(agent_id),
                    plan: None,
                    role: Some(ProvValue::qname("xudanu:verifier")),
                    attributes,
                },
            ));
        }

        associations
    }
}

impl FederationProvenanceBundle {
    pub fn new(bundle_id: String, timestamp: u64, federation_metadata: FederationMetadata) -> Self {
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

            attributes.insert(
                "prov:type".to_string(),
                ProvValue::qname("xudanu:CrossServerSignature"),
            );
            attributes.insert(
                "xudanu:serverId".to_string(),
                ProvValue::string(&hex_encode(&sig.server_id)),
            );
            attributes.insert(
                "xudanu:signature".to_string(),
                ProvValue::typed(&hex_encode(&sig.signature), "xsd:hexBinary"),
            );
            attributes.insert(
                "xudanu:timestamp".to_string(),
                ProvValue::typed(&sig.timestamp.to_string(), "xsd:integer"),
            );

            if let Some(time_str) = unix_to_iso8601(sig.timestamp) {
                attributes.insert("xudanu:signedAt".to_string(), ProvValue::string(&time_str));
            }

            bundle_doc
                .entity
                .insert(sig_entity_id, ProvEntity { attributes });
        }

        // Add federation metadata generation activity
        let meta_activity_id = format!("{}:meta_gen", self.bundle_id);
        let mut meta_activity_attrs = std::collections::HashMap::new();
        meta_activity_attrs.insert(
            "prov:type".to_string(),
            ProvValue::qname("xudanu:FederationMetadataGeneration"),
        );

        if let Some(time_str) = unix_to_iso8601(self.timestamp) {
            meta_activity_attrs.insert(
                "xudanu:generatedAt".to_string(),
                ProvValue::string(&time_str),
            );
        }

        bundle_doc.activity.insert(
            meta_activity_id,
            ProvActivity {
                start_time: unix_to_iso8601(self.timestamp),
                end_time: unix_to_iso8601(self.timestamp),
                attributes: meta_activity_attrs,
            },
        );

        (
            self.bundle_id.clone(),
            ProvBundle {
                content: bundle_doc,
            },
        )
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
        let server_id_hex = hex_encode(&self.server_id);
        let entity_id = generate_prov_id(
            "xudanu:crosssig",
            &format!(
                "{}:{}",
                &server_id_hex[..8.min(server_id_hex.len())],
                self.timestamp
            ),
        );
        let mut attributes = std::collections::HashMap::new();

        attributes.insert(
            "prov:type".to_string(),
            ProvValue::qname("xudanu:CrossServerSignature"),
        );
        attributes.insert(
            "xudanu:serverId".to_string(),
            ProvValue::string(&hex_encode(&self.server_id)),
        );
        attributes.insert(
            "xudanu:signature".to_string(),
            ProvValue::typed(&hex_encode(&self.signature), "xsd:hexBinary"),
        );
        attributes.insert(
            "xudanu:timestamp".to_string(),
            ProvValue::typed(&self.timestamp.to_string(), "xsd:integer"),
        );

        if let Some(time_str) = unix_to_iso8601(self.timestamp) {
            attributes.insert("xudanu:signedAt".to_string(), ProvValue::string(&time_str));
        }

        (entity_id, ProvEntity { attributes })
    }

    #[cfg(feature = "serde")]
    pub fn to_prov_association(&self, activity_id: &str) -> (String, ProvAssociation) {
        let server_id_hex = hex_encode(&self.server_id);
        let assoc_id = format!(
            "{}:assoc:{}",
            activity_id,
            &server_id_hex[..8.min(server_id_hex.len())]
        );
        let agent_id = generate_prov_id(
            "xudanu:server",
            &server_id_hex[..8.min(server_id_hex.len())],
        );

        let mut attributes = std::collections::HashMap::new();
        attributes.insert(
            "xudanu:signature".to_string(),
            ProvValue::typed(&hex_encode(&self.signature), "xsd:hexBinary"),
        );

        (
            assoc_id,
            ProvAssociation {
                activity: activity_id.to_string(),
                agent: Some(agent_id),
                plan: None,
                role: Some(ProvValue::qname("verifier")),
                attributes,
            },
        )
    }
}

// =============================================================================
// Phase 3: Cluster consensus to PROV bundle mapping
// =============================================================================

impl ClusterConsensus {
    #[cfg(feature = "serde")]
    pub fn to_prov_bundle(
        &self,
        bundle_id: String,
        base_provenance: &Provenance,
    ) -> (String, ProvBundle) {
        let mut bundle_doc = ProvJsonDocument::with_default_prefix();

        // Add consensus entity
        let consensus_entity_id = format!("{}:consensus", bundle_id);
        let mut consensus_attrs = std::collections::HashMap::new();

        consensus_attrs.insert("prov:type".to_string(), ProvValue::qname("prov:Collection"));
        consensus_attrs.insert(
            "xudanu:consensusType".to_string(),
            ProvValue::string(match self.consensus_type {
                ConsensusType::Unanimous => "unanimous",
                ConsensusType::Majority => "majority",
                ConsensusType::Supermajority => "supermajority",
            }),
        );
        consensus_attrs.insert(
            "xudanu:thresholdMet".to_string(),
            ProvValue::string(&self.threshold_met.to_string()),
        );
        consensus_attrs.insert(
            "xudanu:totalServers".to_string(),
            ProvValue::typed(&self.total_servers.to_string(), "xsd:integer"),
        );
        consensus_attrs.insert(
            "xudanu:approvingServers".to_string(),
            ProvValue::typed(&self.approving_servers.to_string(), "xsd:integer"),
        );

        bundle_doc.entity.insert(
            consensus_entity_id.clone(),
            ProvEntity {
                attributes: consensus_attrs,
            },
        );

        // Add verification activity
        let activity_id = format!("{}:verification", bundle_id);
        let mut activity_attrs = std::collections::HashMap::new();

        activity_attrs.insert(
            "prov:type".to_string(),
            ProvValue::qname("xudanu:ClusterVerification"),
        );

        let timestamp = base_provenance.timestamp;
        if let Some(time_str) = unix_to_iso8601(timestamp) {
            activity_attrs.insert(
                "xudanu:verifiedAt".to_string(),
                ProvValue::string(&time_str),
            );
        }

        bundle_doc.activity.insert(
            activity_id.clone(),
            ProvActivity {
                start_time: unix_to_iso8601(timestamp),
                end_time: unix_to_iso8601(timestamp),
                attributes: activity_attrs,
            },
        );

        // Add server associations for verifications
        for verification in &self.verifications {
            if verification.verified {
                let server_id_hex = hex_encode(&verification.server_id);
                let server_agent_id = generate_prov_id(
                    "xudanu:server",
                    &server_id_hex[..8.min(server_id_hex.len())],
                );

                let assoc_id = format!(
                    "{}:assoc:{}",
                    activity_id,
                    &server_id_hex[..8.min(server_id_hex.len())]
                );
                let mut assoc_attrs = std::collections::HashMap::new();

                if let Some(time_str) = unix_to_iso8601(verification.timestamp) {
                    assoc_attrs.insert(
                        "xudanu:verifiedAt".to_string(),
                        ProvValue::string(&time_str),
                    );
                }

                bundle_doc.wasAssociatedWith.insert(
                    assoc_id,
                    ProvAssociation {
                        activity: activity_id.clone(),
                        agent: Some(server_agent_id.clone()),
                        plan: None,
                        role: Some(ProvValue::qname("verifier")),
                        attributes: assoc_attrs,
                    },
                );

                // Add server agent if not present
                if !bundle_doc.agent.contains_key(&server_agent_id) {
                    let mut server_attrs = std::collections::HashMap::new();
                    server_attrs.insert("prov:type".to_string(), ProvValue::qname("xudanu:Server"));
                    server_attrs.insert(
                        "xudanu:serverId".to_string(),
                        ProvValue::string(&server_id_hex),
                    );

                    bundle_doc.agent.insert(
                        server_agent_id,
                        ProvAgent {
                            attributes: server_attrs,
                        },
                    );
                }
            }
        }

        (
            bundle_id,
            ProvBundle {
                content: bundle_doc,
            },
        )
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
            let (bundle_id_str, bundle) = self
                .consensus
                .to_prov_bundle(bundle_id, &self.base_provenance);

            let mut bundles = std::collections::HashMap::new();
            bundles.insert(bundle_id_str, bundle);
            doc.bundle = Some(bundles);
        }

        Ok(doc)
    }

    #[cfg(feature = "serde")]
    pub fn export_federation_provenance_bundle(
        &self,
    ) -> Result<FederationProvenanceBundle, String> {
        let bundle_id = generate_federation_bundle_id(self.base_provenance.timestamp);
        let mut bundle = FederationProvenanceBundle::new(
            bundle_id.clone(),
            self.base_provenance.timestamp,
            FederationMetadata::new(
                hex_encode(&self.base_provenance.server_id),
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
                let server_id_hex = hex_encode(&verification.server_id);
                bundle.add_server_agent(FederationServerAgent::new(
                    server_id_hex.clone(),
                    hex_encode(&verification.server_id),
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
            self.consensus
                .verifications
                .iter()
                .filter(|v| v.verified)
                .map(|v| hex_encode(&v.server_id))
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
        #[cfg_attr(feature = "serde", serde(default))]
        source_work_id: Option<u64>,
        #[cfg_attr(feature = "serde", serde(default))]
        transcluded_by: Option<TransclusionInfoData>,
        #[cfg_attr(feature = "serde", serde(default))]
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

#[cfg(feature = "server")]
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

#[cfg(feature = "server")]
pub fn sign_span(
    signing_key: &SigningKey,
    element_fingerprints: &[[u8; 32]],
    timestamp: u64,
    server_id: &[u8; 32],
) -> Provenance {
    if element_fingerprints.is_empty() {
        panic!("sign_span called with empty element_fingerprints");
    }
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

#[cfg(feature = "server")]
pub fn verify_span_provenance(provenance: &Provenance, element_fingerprints: &[[u8; 32]]) -> bool {
    let span_fp = compute_span_fingerprint(element_fingerprints);
    verify_span_provenance_with_span_fp(provenance, &span_fp)
}

#[cfg(feature = "server")]
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

#[cfg(feature = "server")]
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

#[cfg(feature = "server")]
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

#[cfg(feature = "server")]
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

#[cfg(feature = "server")]
pub fn verify_federation_provenance(
    federated: &FederatedProvenance,
    element_fingerprints: &[[u8; 32]],
    server_verifying_keys: &[[u8; 32]],
) -> bool {
    let span_fp = compute_span_fingerprint(element_fingerprints);

    let verifying_key = match VerifyingKey::from_bytes(&federated.base_provenance.author_public_key)
    {
        Ok(vk) => vk,
        Err(_) => return false,
    };

    let signature = Signature::from_bytes(&federated.base_provenance.signature);
    let payload = compute_signing_payload(
        &span_fp,
        &federated.base_provenance.author_public_key,
        federated.base_provenance.timestamp,
        &federated.base_provenance.server_id,
    );

    if !crate::crypto::sign::verify_signature(&verifying_key, &payload, &signature).is_ok() {
        return false;
    }

    for cross_sig in &federated.cross_server_signatures {
        let verifying_key = match VerifyingKey::from_bytes(&cross_sig.verifying_key) {
            Ok(vk) => vk,
            Err(_) => continue,
        };
        let payload = compute_federation_payload(
            &federated.base_provenance,
            &cross_sig.server_id,
            cross_sig.timestamp,
        );
        let signature = Signature::from_bytes(&cross_sig.signature);
        if crate::crypto::sign::verify_signature(&verifying_key, &payload, &signature).is_err() {
            return false;
        }
        if !server_verifying_keys.contains(&cross_sig.verifying_key) {
            return false;
        }
    }

    match federated.consensus.consensus_type {
        ConsensusType::Unanimous => {
            federated.cross_server_signatures.len() as u32 == federated.consensus.total_servers
        }
        ConsensusType::Majority => {
            federated.cross_server_signatures.len() as u32 > federated.consensus.total_servers / 2
        }
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

    // =========================================================================
    // sign_element
    // =========================================================================

    #[test]
    fn sign_element_populates_provenance() {
        let key = generate_signing_key();
        let fp = RangeElement::text("elem").content_fingerprint();
        let mut server_id = [0u8; 32];
        server_id[..4].copy_from_slice(b"srvr");
        let prov = sign_element(&key, &fp, 5000, &server_id);
        assert_eq!(prov.author_public_key, key.verifying_key().to_bytes());
        assert_eq!(prov.timestamp, 5000);
        assert_eq!(prov.server_id, server_id);
        assert_eq!(prov.signature.len(), 64);
    }

    #[test]
    fn sign_element_is_deterministic_for_same_inputs() {
        let key = generate_signing_key();
        let fp = RangeElement::text("x").content_fingerprint();
        let server_id = [9u8; 32];
        let prov1 = sign_element(&key, &fp, 100, &server_id);
        let prov2 = sign_element(&key, &fp, 100, &server_id);
        assert_eq!(prov1, prov2);
    }

    // =========================================================================
    // Historical attestation sign / verify
    // =========================================================================

    #[test]
    fn historical_attestation_roundtrip() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        server_id[..4].copy_from_slice(b"hstr");
        let prov = sign_historical_attestation(&key, &fps, 12345, 1000, &server_id);
        assert!(verify_historical_attestation(&prov, &fps, 12345));
    }

    #[test]
    fn historical_attestation_rejects_wrong_author_id() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let server_id = [0u8; 32];
        let prov = sign_historical_attestation(&key, &fps, 111, 1000, &server_id);
        assert!(!verify_historical_attestation(&prov, &fps, 222));
    }

    #[test]
    fn historical_attestation_rejects_wrong_key() {
        let key_a = generate_signing_key();
        let key_b = generate_signing_key();
        let fps = make_fingerprints();
        let server_id = [0u8; 32];
        let mut prov = sign_historical_attestation(&key_a, &fps, 111, 1000, &server_id);
        prov.author_public_key = key_b.verifying_key().to_bytes();
        assert!(!verify_historical_attestation(&prov, &fps, 111));
    }

    #[test]
    fn historical_attestation_rejects_wrong_fingerprints() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let server_id = [0u8; 32];
        let prov = sign_historical_attestation(&key, &fps, 111, 1000, &server_id);
        let wrong_fps = vec![RangeElement::text("Z").content_fingerprint()];
        assert!(!verify_historical_attestation(&prov, &wrong_fps, 111));
    }

    #[test]
    fn historical_attestation_rejects_tampered_signature() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let server_id = [0u8; 32];
        let mut prov = sign_historical_attestation(&key, &fps, 111, 1000, &server_id);
        prov.signature[0] ^= 0xff;
        assert!(!verify_historical_attestation(&prov, &fps, 111));
    }

    // =========================================================================
    // compute_span_fingerprint_hex
    // =========================================================================

    #[test]
    fn span_fingerprint_hex_is_consistent_and_well_formed() {
        let fps = make_fingerprints();
        let hex1 = compute_span_fingerprint_hex(&fps);
        let hex2 = compute_span_fingerprint_hex(&fps);
        assert_eq!(hex1, hex2);
        assert_eq!(hex1.len(), 64);
        assert!(hex1.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn span_fingerprint_hex_differs_for_different_input() {
        let fps1 = vec![RangeElement::text("a").content_fingerprint()];
        let fps2 = vec![RangeElement::text("b").content_fingerprint()];
        assert_ne!(
            compute_span_fingerprint_hex(&fps1),
            compute_span_fingerprint_hex(&fps2)
        );
    }

    // =========================================================================
    // verify_span_provenance_with_span_fp
    // =========================================================================

    #[test]
    fn verify_span_provenance_with_span_fp_roundtrip() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let server_id = [0u8; 32];
        let prov = sign_span(&key, &fps, 1000, &server_id);
        let span_fp = compute_span_fingerprint(&fps);
        assert!(verify_span_provenance_with_span_fp(&prov, &span_fp));
    }

    #[test]
    fn verify_span_provenance_with_span_fp_rejects_tampered() {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let server_id = [0u8; 32];
        let mut prov = sign_span(&key, &fps, 1000, &server_id);
        let span_fp = compute_span_fingerprint(&fps);
        prov.signature[0] ^= 0xff;
        assert!(!verify_span_provenance_with_span_fp(&prov, &span_fp));
    }

    #[test]
    fn verify_span_provenance_with_span_fp_rejects_bad_provenance() {
        let span_fp = [0u8; 32];
        let prov = Provenance {
            author_public_key: [0u8; 32],
            signature: [0u8; 64],
            timestamp: 0,
            server_id: [0u8; 32],
        };
        assert!(!verify_span_provenance_with_span_fp(&prov, &span_fp));
    }

    // =========================================================================
    // sign_cross_server / verify_federation_provenance
    // =========================================================================

    fn build_base_provenance(
        server_id_label: &[u8],
    ) -> (SigningKey, Vec<[u8; 32]>, Provenance, [u8; 32]) {
        let key = generate_signing_key();
        let fps = make_fingerprints();
        let mut server_id = [0u8; 32];
        server_id[..server_id_label.len()].copy_from_slice(server_id_label);
        let prov = sign_span(&key, &fps, 1000, &server_id);
        (key, fps, prov, server_id)
    }

    // ── W3C PROV-JSON conformance (FR: spec-compliance guard) ─────

    /// Structural validator: every rule a strict PROV consumer
    /// checks first. Run against the serialized JSON so serde
    /// renames/omissions are audited too, not just our types.
    fn assert_prov_json_conformance(value: &serde_json::Value) {
        use std::collections::HashSet;
        let obj = value.as_object().expect("document is an object");

        const ALLOWED: &[&str] = &[
            "prefix",
            "entity",
            "activity",
            "agent",
            "used",
            "wasGeneratedBy",
            "wasInformedBy",
            "wasStartedBy",
            "wasEndedBy",
            "wasInvalidatedBy",
            "wasDerivedFrom",
            "wasAttributedTo",
            "wasAssociatedWith",
            "actedOnBehalfOf",
            "wasInfluencedBy",
            "alternateOf",
            "specializationOf",
            "hadMember",
            "bundle",
        ];
        for key in obj.keys() {
            assert!(
                ALLOWED.contains(&key.as_str()),
                "non-PROV top-level key: {key}"
            );
        }

        let prefix: HashSet<String> = obj
            .get("prefix")
            .and_then(|p| p.as_object())
            .map(|m| m.keys().cloned().collect())
            .unwrap_or_default();
        assert!(prefix.contains("prov") && prefix.contains("xsd"));

        let qname_re = regex_lite_re();
        let mut check_id = |id: &str, ctx: &str| {
            let (pfx, local) = match id.split_once(':') {
                Some(x) => x,
                None => panic!("{ctx}: id is not a QName: {id}"),
            };
            assert!(
                prefix.contains(pfx),
                "{ctx}: unbound prefix {pfx:?} in id {id}"
            );
            assert!(!local.contains(':'), "{ctx}: colon in local part: {id}");
            assert!(qname_re(local), "{ctx}: illegal local name: {id}");
        };

        // Collect all entity/agent/activity ids (for reference resolution)
        let mut known: HashSet<String> = HashSet::new();
        for kind in ["entity", "activity", "agent"] {
            if let Some(map) = obj.get(kind).and_then(|v| v.as_object()) {
                for id in map.keys() {
                    check_id(id, kind);
                    known.insert(id.clone());
                }
            }
        }

        // Relations: ids valid; refs resolve; temporal slots dateTime
        let dt_ok = |v: &serde_json::Value, ctx: &str| {
            let t = v.as_str().unwrap_or_else(|| panic!("{ctx} non-string"));
            assert!(
                t.len() >= 20
                    && t.ends_with('Z')
                    && t.as_bytes()[4] == b'-'
                    && t.as_bytes()[10] == b'T',
                "{ctx}: not xsd:dateTime: {t}"
            );
        };
        for rel in [
            "used",
            "wasGeneratedBy",
            "wasAttributedTo",
            "wasAssociatedWith",
            "wasDerivedFrom",
        ] {
            let Some(map) = obj.get(rel).and_then(|v| v.as_object()) else {
                continue;
            };
            for (rid, rec) in map {
                check_id(rid, rel);
                let rec = rec.as_object().unwrap();
                for field in [
                    "prov:entity",
                    "prov:agent",
                    "prov:activity",
                    "prov:generatedEntity",
                    "prov:usedEntity",
                ] {
                    if let Some(v) = rec.get(field) {
                        let id = v.as_str().unwrap();
                        check_id(id, rel);
                        assert!(known.contains(id), "{rel}/{rid}: dangling {field} -> {id}");
                    }
                }
                if let Some(t) = rec.get("prov:time") {
                    dt_ok(t, rel);
                }
                if let Some(t) = rec.get("prov:startTime") {
                    dt_ok(t, rel);
                }
                if let Some(t) = rec.get("prov:endTime") {
                    dt_ok(t, rel);
                }
                if let Some(tv) = rec.get("prov:type") {
                    let t = tv.as_object().unwrap();
                    assert_eq!(
                        t.get("type").and_then(|x| x.as_str()),
                        Some("xsd:QName"),
                        "{rel}/{rid}: prov:type must be QName-typed"
                    );
                }
            }
        }
    }

    /// Minimal QName local-name check without a regex dep:
    /// [A-Za-z_][A-Za-z0-9_.-]*
    fn regex_lite_re() -> impl Fn(&str) -> bool {
        |s: &str| {
            let mut cs = s.chars();
            match cs.next() {
                Some(c) if c.is_ascii_alphabetic() || c == '_' => {}
                _ => return false,
            }
            cs.all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-' || c == '.')
        }
    }

    #[test]
    fn prov_json_export_conforms_to_spec() {
        let (_k, _fps, base_prov, _) = build_base_provenance(b"conf");
        let peer = generate_signing_key();
        let mut server_id = [0u8; 32];
        server_id[..4].copy_from_slice(b"peer");
        let vk = peer.verifying_key();
        let sig = sign_cross_server(&peer, &base_prov, &server_id, &vk.to_bytes(), 2000);
        let fed = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: vec![sig],
            consensus: ClusterConsensus {
                consensus_type: ConsensusType::Unanimous,
                verifications: vec![],
                threshold_met: true,
                total_servers: 1,
                approving_servers: 1,
                timestamp: 2000,
            },
        };
        let doc = fed.to_prov_json_with_federation().expect("export");
        let json = serde_json::to_value(&doc).expect("serialize");
        eprintln!("{}", serde_json::to_string_pretty(&json).unwrap());
        assert_prov_json_conformance(&json);
    }

    #[test]
    fn federated_provenance_unanimous_passes() {
        let (_author_key, fps, base_prov, _) = build_base_provenance(b"base");

        let peer_keys: Vec<_> = (0..3).map(|_| generate_signing_key()).collect();
        let mut sigs = Vec::new();
        let mut verifying_keys = Vec::new();
        for (i, pk) in peer_keys.iter().enumerate() {
            let mut sid = [0u8; 32];
            sid[0] = i as u8 + 1;
            let vk = pk.verifying_key().to_bytes();
            sigs.push(sign_cross_server(pk, &base_prov, &sid, &vk, 2000));
            verifying_keys.push(vk);
        }

        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Unanimous,
            verifications: vec![],
            threshold_met: true,
            total_servers: 3,
            approving_servers: 3,
            timestamp: 2000,
        };
        let federated = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: sigs,
            consensus,
        };
        assert!(verify_federation_provenance(
            &federated,
            &fps,
            &verifying_keys
        ));
    }

    #[test]
    fn federated_provenance_majority_passes() {
        let (_author_key, fps, base_prov, _) = build_base_provenance(b"base");

        let peer_keys: Vec<_> = (0..5).map(|_| generate_signing_key()).collect();
        let mut sigs = Vec::new();
        let mut verifying_keys = Vec::new();
        for (i, pk) in peer_keys.iter().enumerate() {
            let mut sid = [0u8; 32];
            sid[0] = i as u8 + 1;
            let vk = pk.verifying_key().to_bytes();
            sigs.push(sign_cross_server(pk, &base_prov, &sid, &vk, 2000));
            verifying_keys.push(vk);
        }

        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Majority,
            verifications: vec![],
            threshold_met: true,
            total_servers: 5,
            approving_servers: 5,
            timestamp: 2000,
        };
        let federated = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: sigs,
            consensus,
        };
        assert!(verify_federation_provenance(
            &federated,
            &fps,
            &verifying_keys
        ));
    }

    #[test]
    fn federated_provenance_supermajority_passes() {
        let (_author_key, fps, base_prov, _) = build_base_provenance(b"base");

        // 3 of 4 servers; threshold = ceil(4 * 0.67) = ceil(2.68) = 3
        let peer_keys: Vec<_> = (0..3).map(|_| generate_signing_key()).collect();
        let mut sigs = Vec::new();
        let mut verifying_keys = Vec::new();
        for (i, pk) in peer_keys.iter().enumerate() {
            let mut sid = [0u8; 32];
            sid[0] = i as u8 + 1;
            let vk = pk.verifying_key().to_bytes();
            sigs.push(sign_cross_server(pk, &base_prov, &sid, &vk, 2000));
            verifying_keys.push(vk);
        }

        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Supermajority,
            verifications: vec![],
            threshold_met: true,
            total_servers: 4,
            approving_servers: 3,
            timestamp: 2000,
        };
        let federated = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: sigs,
            consensus,
        };
        assert!(verify_federation_provenance(
            &federated,
            &fps,
            &verifying_keys
        ));
    }

    #[test]
    fn federated_provenance_fails_wrong_cross_sig() {
        let (_author_key, fps, base_prov, _) = build_base_provenance(b"base");

        let pk = generate_signing_key();
        let mut sid = [0u8; 32];
        sid[0] = 1;
        let vk = pk.verifying_key().to_bytes();
        let mut sig = sign_cross_server(&pk, &base_prov, &sid, &vk, 2000);
        sig.signature[0] ^= 0xff;

        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Unanimous,
            verifications: vec![],
            threshold_met: true,
            total_servers: 1,
            approving_servers: 1,
            timestamp: 2000,
        };
        let federated = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: vec![sig],
            consensus,
        };
        assert!(!verify_federation_provenance(&federated, &fps, &vec![vk]));
    }

    #[test]
    fn federated_provenance_fails_unknown_verifying_key() {
        let (_author_key, fps, base_prov, _) = build_base_provenance(b"base");

        let pk = generate_signing_key();
        let mut sid = [0u8; 32];
        sid[0] = 1;
        let vk = pk.verifying_key().to_bytes();
        let sig = sign_cross_server(&pk, &base_prov, &sid, &vk, 2000);

        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Unanimous,
            verifications: vec![],
            threshold_met: true,
            total_servers: 1,
            approving_servers: 1,
            timestamp: 2000,
        };
        let federated = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: vec![sig],
            consensus,
        };
        let other_vk = generate_signing_key().verifying_key().to_bytes();
        assert!(!verify_federation_provenance(
            &federated,
            &fps,
            &vec![other_vk]
        ));
    }

    #[test]
    fn federated_provenance_fails_consensus_not_met() {
        let (_author_key, fps, base_prov, _) = build_base_provenance(b"base");

        let pk = generate_signing_key();
        let mut sid = [0u8; 32];
        sid[0] = 1;
        let vk = pk.verifying_key().to_bytes();
        let sig = sign_cross_server(&pk, &base_prov, &sid, &vk, 2000);

        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Unanimous,
            verifications: vec![],
            threshold_met: false,
            total_servers: 3,
            approving_servers: 1,
            timestamp: 2000,
        };
        let federated = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: vec![sig],
            consensus,
        };
        assert!(!verify_federation_provenance(&federated, &fps, &vec![vk]));
    }

    #[test]
    fn federated_provenance_fails_base_signature_invalid() {
        let (_author_key, fps, mut base_prov, _) = build_base_provenance(b"base");
        base_prov.signature[0] ^= 0xff;

        let pk = generate_signing_key();
        let mut sid = [0u8; 32];
        sid[0] = 1;
        let vk = pk.verifying_key().to_bytes();
        let sig = sign_cross_server(&pk, &base_prov, &sid, &vk, 2000);

        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Unanimous,
            verifications: vec![],
            threshold_met: true,
            total_servers: 1,
            approving_servers: 1,
            timestamp: 2000,
        };
        let federated = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: vec![sig],
            consensus,
        };
        assert!(!verify_federation_provenance(&federated, &fps, &vec![vk]));
    }

    // =========================================================================
    // PROV-JSON helper constructors
    // =========================================================================

    #[test]
    fn prov_value_constructors() {
        let s = ProvValue::string("hi");
        assert_eq!(s.value, "hi");
        assert_eq!(s.type_.as_deref(), Some("xsd:string"));
        assert!(s.lang.is_none());

        let t = ProvValue::typed("42", "xsd:integer");
        assert_eq!(t.value, "42");
        assert_eq!(t.type_.as_deref(), Some("xsd:integer"));

        let tn = ProvValue::typed_with_namespace("x", "Person");
        assert_eq!(tn.value, "x");
        assert!(tn.type_.as_deref().unwrap().contains("Person"));

        let q = ProvValue::qname("prov:Person");
        assert_eq!(q.value, "prov:Person");
        assert_eq!(q.type_.as_deref(), Some("xsd:QName"));
    }

    #[test]
    fn prov_json_document_default_prefixes() {
        let doc = ProvJsonDocument::new();
        assert!(doc.prefix.contains_key("prov"));
        assert!(doc.prefix.contains_key("xsd"));
        assert!(doc.prefix.contains_key("xudanu"));
        assert!(doc.entity.is_empty());
        assert!(doc.bundle.is_none());

        let doc2 = ProvJsonDocument::with_default_prefix();
        assert_eq!(doc, doc2);
    }

    #[test]
    fn consensus_type_display() {
        assert_eq!(ConsensusType::Unanimous.to_string(), "unanimous");
        assert_eq!(ConsensusType::Majority.to_string(), "majority");
        assert_eq!(ConsensusType::Supermajority.to_string(), "supermajority");
    }

    #[test]
    fn prov_id_generators() {
        assert_eq!(generate_prov_id("pre", "base"), "pre:base");
        assert_eq!(generate_span_prov_id(42, 0, 10), "xudanu:span_42_0_10");
        let key = [0xaa; 32];
        let id = generate_author_prov_id(&key);
        assert!(id.starts_with("xudanu:agent_"));
        assert_eq!(generate_edit_activity_id(7, 1234), "xudanu:activity_7_1234");
        assert_eq!(
            generate_federation_bundle_id(9999),
            "xudanu:federation_consensus_9999"
        );
    }

    #[test]
    #[cfg(feature = "serde")]
    fn author_type_to_prov_agent_type() {
        assert_eq!(AuthorType::Human.to_prov_agent_type(), "prov:Person");
        assert_eq!(AuthorType::Llm.to_prov_agent_type(), "xudanu:LLMAgent");
        assert_eq!(AuthorType::Historical.to_prov_agent_type(), "prov:Person");
    }

    #[test]
    #[cfg(feature = "serde")]
    fn derivation_method_to_prov_type() {
        assert_eq!(
            DerivationMethod::Transclusion.to_prov_type(),
            "xudanu:Transclusion"
        );
        assert_eq!(DerivationMethod::Merge.to_prov_type(), "xudanu:Merge");
        assert_eq!(DerivationMethod::Import.to_prov_type(), "prov:Revision");
        assert_eq!(
            DerivationMethod::Annotation.to_prov_type(),
            "prov:Quotation"
        );
        assert_eq!(DerivationMethod::Revision.to_prov_type(), "prov:Revision");
    }

    // =========================================================================
    // Federation-PROV type conversions
    // =========================================================================

    #[test]
    #[cfg(feature = "serde")]
    fn federation_metadata_to_prov_entity() {
        let meta = FederationMetadata::new(
            "srv-1".to_string(),
            "example.com".to_string(),
            5,
            "active".to_string(),
            3,
            "member".to_string(),
        );
        let (id, entity) = meta.to_prov_entity();
        assert!(id.starts_with("xudanu:federation_"));
        assert!(entity.attributes.contains_key("prov:type"));
        assert_eq!(
            entity.attributes.get("xudanu:serverId").unwrap().value,
            "srv-1"
        );
        assert_eq!(
            entity.attributes.get("xudanu:clusterSize").unwrap().value,
            "5"
        );
    }

    #[test]
    #[cfg(feature = "serde")]
    fn federation_server_agent_to_prov_agent() {
        let agent = FederationServerAgent::new(
            "srv-1".to_string(),
            "deadbeef".to_string(),
            "cafebabe".to_string(),
            "active".to_string(),
            7,
            1000,
        );
        let (id, prov_agent) = agent.to_prov_agent();
        assert!(id.starts_with("xudanu:server_"));
        assert!(prov_agent.attributes.contains_key("prov:type"));
        assert_eq!(
            prov_agent.attributes.get("xudanu:serverId").unwrap().value,
            "srv-1"
        );
        assert_eq!(
            prov_agent
                .attributes
                .get("xudanu:endorsementCount")
                .unwrap()
                .value,
            "7"
        );
    }

    #[test]
    #[cfg(feature = "serde")]
    fn federation_attestation_to_prov() {
        let mut meta = std::collections::HashMap::new();
        meta.insert("k".to_string(), "v".to_string());
        let att = FederationAttestation::new(
            "trust".to_string(),
            "attester".to_string(),
            "subject".to_string(),
            12345,
            vec![1, 2, 3, 4],
            meta,
        );
        let (act_id, activity) = att.to_prov_activity();
        assert!(act_id.starts_with("xudanu:attestation:"));
        assert!(activity.attributes.contains_key("xudanu:attestationType"));
        assert!(activity.attributes.contains_key("xudanu:meta_k"));
        assert!(activity.start_time.is_some());

        let (assoc_id, association) = att.to_prov_association();
        assert!(assoc_id.starts_with("xudanu:assoc:"));
        assert!(association.agent.is_some());
        assert!(association.role.is_some());
    }

    #[test]
    #[cfg(feature = "serde")]
    fn cluster_verification_to_prov() {
        let cv = ClusterVerificationActivity::new(
            "act:1".to_string(),
            "xudanu:ClusterVerification".to_string(),
            1000,
            2000,
            vec!["srv-a".to_string(), "srv-b".to_string()],
            "unanimous".to_string(),
            true,
        );
        let (act_id, activity) = cv.to_prov_activity();
        assert_eq!(act_id, "act:1");
        assert_eq!(
            activity
                .attributes
                .get("xudanu:consensusType")
                .unwrap()
                .value,
            "unanimous"
        );
        assert_eq!(
            activity
                .attributes
                .get("xudanu:verifyingServerCount")
                .unwrap()
                .value,
            "2"
        );
        assert!(activity.start_time.is_some());
        assert!(activity.end_time.is_some());

        let associations = cv.to_prov_associations();
        assert_eq!(associations.len(), 2);
        for (id, assoc) in &associations {
            assert!(id.starts_with("act:1:assoc:"));
            assert_eq!(assoc.activity, "act:1");
            assert!(assoc.agent.is_some());
        }
    }

    #[test]
    #[cfg(feature = "serde")]
    fn federation_provenance_bundle_to_prov() {
        let meta = FederationMetadata::new(
            "srv-1".to_string(),
            "fed.example".to_string(),
            3,
            "active".to_string(),
            2,
            "member".to_string(),
        );
        let mut bundle = FederationProvenanceBundle::new("bundle-1".to_string(), 1000, meta);

        bundle.add_server_agent(FederationServerAgent::new(
            "srv-1".to_string(),
            "aabb".to_string(),
            "ccdd".to_string(),
            "active".to_string(),
            1,
            1000,
        ));
        bundle.add_verification_activity(ClusterVerificationActivity::new(
            "act:1".to_string(),
            "xudanu:ClusterVerification".to_string(),
            1000,
            2000,
            vec!["srv-1".to_string()],
            "unanimous".to_string(),
            true,
        ));
        let mut att_meta = std::collections::HashMap::new();
        att_meta.insert("k".to_string(), "v".to_string());
        bundle.add_attestation(FederationAttestation::new(
            "trust".to_string(),
            "attester-srv".to_string(),
            "subject-srv".to_string(),
            1500,
            vec![0; 64],
            att_meta,
        ));
        let mut sig_sid = [0u8; 32];
        sig_sid[..2].copy_from_slice(b"ss");
        bundle.add_cross_server_signature(CrossServerSignature {
            server_id: sig_sid,
            verifying_key: [1u8; 32],
            signature: [2u8; 64],
            timestamp: 3000,
        });

        assert_eq!(bundle.server_agents.len(), 1);
        assert_eq!(bundle.verification_activities.len(), 1);
        assert_eq!(bundle.attestations.len(), 1);
        assert_eq!(bundle.cross_server_signatures.len(), 1);

        let (id, prov_bundle) = bundle.to_prov_bundle();
        assert_eq!(id, "bundle-1");
        assert!(!prov_bundle.content.entity.is_empty());
        assert!(!prov_bundle.content.agent.is_empty());
        assert!(!prov_bundle.content.activity.is_empty());
        assert!(!prov_bundle.content.wasAssociatedWith.is_empty());
    }

    #[test]
    #[cfg(feature = "serde")]
    fn federation_provenance_bundle_empty_to_prov() {
        let meta = FederationMetadata::new(
            "srv-1".to_string(),
            "fed.example".to_string(),
            1,
            "active".to_string(),
            1,
            "member".to_string(),
        );
        let bundle = FederationProvenanceBundle::new("bundle-empty".to_string(), 0, meta);
        let (id, prov_bundle) = bundle.to_prov_bundle();
        assert_eq!(id, "bundle-empty");
        // federation metadata entity + nothing else
        assert_eq!(prov_bundle.content.entity.len(), 1);
        assert!(prov_bundle.content.agent.is_empty());
        // metadata-generation activity always added
        assert_eq!(prov_bundle.content.activity.len(), 1);
    }

    #[test]
    #[cfg(feature = "serde")]
    fn cross_server_signature_to_prov() {
        let sig = CrossServerSignature {
            server_id: [0xab; 32],
            verifying_key: [0xcd; 32],
            signature: [0xef; 64],
            timestamp: 4242,
        };
        let (eid, entity) = sig.to_prov_entity();
        assert!(eid.starts_with("xudanu:crosssig:"));
        assert!(entity.attributes.contains_key("xudanu:signature"));
        assert_eq!(
            entity.attributes.get("xudanu:timestamp").unwrap().value,
            "4242"
        );

        let (aid, assoc) = sig.to_prov_association("activity-1");
        assert!(aid.starts_with("activity-1:assoc:"));
        assert_eq!(assoc.activity, "activity-1");
        assert!(assoc.agent.is_some());
    }

    #[test]
    #[cfg(feature = "serde")]
    fn cluster_consensus_to_prov_bundle() {
        let (_author_key, _fps, base_prov, _) = build_base_provenance(b"base");

        let mut sid1 = [0u8; 32];
        sid1[0] = 1;
        let mut sid2 = [0u8; 32];
        sid2[0] = 2;

        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Majority,
            verifications: vec![
                ServerVerification {
                    server_id: sid1,
                    verified: true,
                    timestamp: 1000,
                },
                ServerVerification {
                    server_id: sid2,
                    verified: false,
                    timestamp: 1000,
                },
            ],
            threshold_met: true,
            total_servers: 2,
            approving_servers: 1,
            timestamp: 1000,
        };

        let (id, bundle) = consensus.to_prov_bundle("consensus-bundle".to_string(), &base_prov);
        assert_eq!(id, "consensus-bundle");
        assert!(!bundle.content.entity.is_empty());
        assert!(!bundle.content.activity.is_empty());
        // only verified servers contribute associations
        assert_eq!(bundle.content.wasAssociatedWith.len(), 1);
        // verified server agent added
        assert_eq!(bundle.content.agent.len(), 1);
    }

    #[test]
    #[cfg(feature = "serde")]
    fn federated_provenance_to_prov_json() {
        let (_author_key, _fps, base_prov, _) = build_base_provenance(b"base");

        let pk = generate_signing_key();
        let mut sid = [0u8; 32];
        sid[0] = 9;
        let vk = pk.verifying_key().to_bytes();
        let sig = sign_cross_server(&pk, &base_prov, &sid, &vk, 2000);

        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Unanimous,
            verifications: vec![],
            threshold_met: true,
            total_servers: 1,
            approving_servers: 1,
            timestamp: 2000,
        };
        let federated = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: vec![sig],
            consensus,
        };

        let doc = federated.to_prov_json().expect("prov json should succeed");
        assert!(!doc.entity.is_empty());
        assert!(!doc.agent.is_empty());
        assert!(!doc.wasAttributedTo.is_empty());
        assert!(doc.bundle.is_none());

        let doc2 = federated
            .to_prov_json_with_federation()
            .expect("prov json with federation should succeed");
        assert!(doc2.bundle.is_some());
    }

    #[test]
    #[cfg(feature = "serde")]
    fn federated_provenance_to_prov_json_no_sigs_no_bundle() {
        let (_author_key, _fps, base_prov, _) = build_base_provenance(b"base");

        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Unanimous,
            verifications: vec![],
            threshold_met: false,
            total_servers: 0,
            approving_servers: 0,
            timestamp: 2000,
        };
        let federated = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: vec![],
            consensus,
        };

        let doc = federated
            .to_prov_json_with_federation()
            .expect("prov json with federation should succeed");
        // no cross-server signatures -> no bundle added
        assert!(doc.bundle.is_none());
    }

    #[test]
    #[cfg(feature = "serde")]
    fn federated_provenance_export_bundle() {
        let (_author_key, _fps, base_prov, _) = build_base_provenance(b"base");

        let pk = generate_signing_key();
        let mut sid = [0u8; 32];
        sid[0] = 7;
        let vk = pk.verifying_key().to_bytes();
        let sig = sign_cross_server(&pk, &base_prov, &sid, &vk, 2000);

        let mut sid_v = [0u8; 32];
        sid_v[0] = 1;
        let consensus = ClusterConsensus {
            consensus_type: ConsensusType::Unanimous,
            verifications: vec![ServerVerification {
                server_id: sid_v,
                verified: true,
                timestamp: 1500,
            }],
            threshold_met: true,
            total_servers: 1,
            approving_servers: 1,
            timestamp: 2000,
        };
        let federated = FederatedProvenance {
            base_provenance: base_prov,
            cross_server_signatures: vec![sig],
            consensus,
        };

        let bundle = federated
            .export_federation_provenance_bundle()
            .expect("export should succeed");
        assert_eq!(bundle.server_agents.len(), 1);
        assert_eq!(bundle.verification_activities.len(), 1);
        assert_eq!(bundle.cross_server_signatures.len(), 1);
        assert_eq!(bundle.federation_metadata.cluster_size, 1);
    }
}
// W3C PROV-JSON representation for existing provenance model
// See: https://www.w3.org/Submission/prov-json/

const PROV_JSON_DOMAIN: &[u8] = b"xudanu/v1/prov-json";
const PROV_NS: &str = "http://www.w3.org/ns/prov#";
const XUDANU_NS: &str = "https://dgjones.info/ns/xudanu/";

// PHASE 1: PROV-JSON Data Structures

/// PROV literal value with explicit typing
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvValue {
    #[cfg_attr(feature = "serde", serde(rename = "$"))]
    pub value: String,
    #[cfg_attr(
        feature = "serde",
        serde(rename = "type", skip_serializing_if = "Option::is_none")
    )]
    #[cfg_attr(feature = "serde", serde(default))]
    pub type_: Option<String>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(default))]
    pub lang: Option<String>,
}

impl ProvValue {
    pub fn string(value: &str) -> Self {
        ProvValue {
            value: value.to_string(),
            type_: Some("xsd:string".to_string()),
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
    #[cfg_attr(feature = "serde", serde(flatten))]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV activity representation  
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvActivity {
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(rename = "prov:startTime"))]
    pub start_time: Option<String>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(rename = "prov:endTime"))]
    pub end_time: Option<String>,
    #[cfg_attr(feature = "serde", serde(flatten))]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV agent representation
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvAgent {
    #[cfg_attr(feature = "serde", serde(flatten))]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV attribution (wasAttributedTo) representation
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvAttribution {
    #[cfg_attr(feature = "serde", serde(rename = "prov:entity"))]
    pub entity: String,
    #[cfg_attr(feature = "serde", serde(rename = "prov:agent"))]
    pub agent: String,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(rename = "prov:time"))]
    pub time: Option<String>,
    #[cfg_attr(feature = "serde", serde(flatten))]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV derivation (wasDerivedFrom) representation
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvDerivation {
    #[cfg_attr(feature = "serde", serde(rename = "prov:generatedEntity"))]
    pub generated_entity: String,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(rename = "prov:activity"))]
    pub activity: Option<String>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(rename = "prov:usage"))]
    pub usage: Option<String>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(rename = "prov:generation"))]
    pub generation: Option<String>,
    #[cfg_attr(feature = "serde", serde(rename = "prov:usedEntity"))]
    pub used_entity: String,
    #[cfg_attr(feature = "serde", serde(flatten))]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV association (wasAssociatedWith) representation  
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvAssociation {
    #[cfg_attr(feature = "serde", serde(rename = "prov:activity"))]
    pub activity: String,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(rename = "prov:agent"))]
    pub agent: Option<String>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(rename = "prov:plan"))]
    pub plan: Option<String>,
    #[cfg_attr(
        feature = "serde",
        serde(skip_serializing_if = "Option::is_none", rename = "prov:role")
    )]
    pub role: Option<ProvValue>,
    #[cfg_attr(feature = "serde", serde(flatten))]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV generation (wasGeneratedBy) representation
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvGeneration {
    #[cfg_attr(feature = "serde", serde(rename = "prov:entity"))]
    pub entity: String,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(rename = "prov:activity"))]
    pub activity: Option<String>,
    #[cfg_attr(feature = "serde", serde(skip_serializing_if = "Option::is_none"))]
    #[cfg_attr(feature = "serde", serde(rename = "prov:time"))]
    pub time: Option<String>,
    #[cfg_attr(feature = "serde", serde(flatten))]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV `used` relation: an activity used an entity — the relation
/// PROV-DM builds its core sentence from. Without it, generation
/// says an entity appeared but never what it came from.
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvUsage {
    #[cfg_attr(feature = "serde", serde(rename = "prov:activity"))]
    pub activity: String,
    #[cfg_attr(feature = "serde", serde(rename = "prov:entity"))]
    pub entity: String,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
    #[cfg_attr(feature = "serde", serde(rename = "prov:time"))]
    pub time: Option<String>,
    #[cfg_attr(feature = "serde", serde(flatten))]
    pub attributes: std::collections::HashMap<String, ProvValue>,
}

/// PROV bundle representation (for federation)
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvBundle {
    #[cfg_attr(feature = "serde", serde(flatten))]
    pub content: ProvJsonDocument,
}

/// Complete PROV-JSON document
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct ProvJsonDocument {
    #[cfg_attr(feature = "serde", serde(default))]
    pub prefix: std::collections::HashMap<String, String>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub entity: std::collections::HashMap<String, ProvEntity>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub activity: std::collections::HashMap<String, ProvActivity>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub agent: std::collections::HashMap<String, ProvAgent>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub wasAttributedTo: std::collections::HashMap<String, ProvAttribution>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub wasDerivedFrom: std::collections::HashMap<String, ProvDerivation>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub wasAssociatedWith: std::collections::HashMap<String, ProvAssociation>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub wasGeneratedBy: std::collections::HashMap<String, ProvGeneration>,
    #[cfg_attr(feature = "serde", serde(default))]
    pub used: std::collections::HashMap<String, ProvUsage>,
    #[cfg_attr(
        feature = "serde",
        serde(default, skip_serializing_if = "Option::is_none")
    )]
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
            used: std::collections::HashMap::new(),
            bundle: None,
        };

        // Add default prefixes
        doc.prefix.insert("prov".to_string(), PROV_NS.to_string());
        doc.prefix.insert(
            "xsd".to_string(),
            "http://www.w3.org/2001/XMLSchema#".to_string(),
        );
        doc.prefix
            .insert("xudanu".to_string(), XUDANU_NS.to_string());

        doc
    }

    pub fn with_default_prefix() -> Self {
        Self::new()
    }
}

// PHASE 1: ID Generation Functions

/// Generate consistent PROV identifiers.
///
/// W3C PROV-JSON conformance: identifiers are QNames. The local part
/// must not contain ':' (or other QName-illegal characters), so the
/// base id is sanitized — `xudanu:span` + `1:0:1` becomes
/// `xudanu:span_1_0_1`, not `xudanu:span:1:0:1`.
pub fn generate_prov_id(prefix: &str, base_id: &str) -> String {
    let local: String = base_id
        .chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || c == '_' || c == '-' || c == '.' {
                c
            } else {
                '_'
            }
        })
        .collect();
    format!("{}:{}", prefix, local)
}

/// Unix seconds → xsd:dateTime (RFC 3339, UTC) for PROV temporal
/// slots. Integer timestamps stay available via xudanu: attributes.
pub fn unix_to_xsd_datetime(secs: u64) -> String {
    // Civil-from-days algorithm (Howard Hinnant) — no chrono dep
    // needed at this layer.
    let days = (secs / 86400) as i64;
    let rem = (secs % 86400) as i64;
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    format!(
        "{:04}-{:02}-{:02}T{:02}:{:02}:{:02}Z",
        y,
        m,
        d,
        rem / 3600,
        (rem % 3600) / 60,
        rem % 60
    )
}

/// Generate entity ID for span
pub fn generate_span_prov_id(work_id: BeId, span_start: i64, span_end: i64) -> String {
    generate_prov_id(
        "xudanu",
        &format!("span_{}_{}_{}", work_id, span_start, span_end),
    )
}

/// Generate agent ID for author
pub fn generate_author_prov_id(author_public_key: &[u8; 32]) -> String {
    let key_hex = hex_encode(author_public_key);
    generate_prov_id("xudanu", &format!("agent_{}", &key_hex[..16]))
}
/// Generate activity ID for edit operation
pub fn generate_edit_activity_id(work_id: BeId, timestamp: u64) -> String {
    generate_prov_id("xudanu", &format!("activity_{}_{}", work_id, timestamp))
}

/// Generate bundle ID for federation
pub fn generate_federation_bundle_id(timestamp: u64) -> String {
    generate_prov_id("xudanu", &format!("federation_consensus_{}", timestamp))
}

// PHASE 1: PROV-JSON Conversion Methods

impl FederatedProvenance {
    #[cfg(feature = "serde")]
    pub fn to_prov_json(&self) -> Result<ProvJsonDocument, String> {
        let mut doc = ProvJsonDocument::with_default_prefix();

        // Create entity for the span (using generic entity ID since we don't have span info)
        let entity_id = generate_span_prov_id(0, 0, 1);
        let mut entity_attrs = std::collections::HashMap::new();
        entity_attrs.insert(
            "xudanu:timestamp".to_string(),
            ProvValue::typed(&self.base_provenance.timestamp.to_string(), "xsd:integer"),
        );
        entity_attrs.insert(
            "xudanu:serverId".to_string(),
            ProvValue::typed(
                &hex_encode(&self.base_provenance.server_id),
                "xsd:hexBinary",
            ),
        );

        doc.entity.insert(
            entity_id.clone(),
            ProvEntity {
                attributes: entity_attrs,
            },
        );

        // Create agent for the author
        let author_id = generate_author_prov_id(&self.base_provenance.author_public_key);
        let mut agent_attrs = std::collections::HashMap::new();
        agent_attrs.insert("prov:type".to_string(), ProvValue::qname("prov:Person")); // Default to person
        agent_attrs.insert(
            "xudanu:publicKey".to_string(),
            ProvValue::typed(
                &hex_encode(&self.base_provenance.author_public_key),
                "xsd:hexBinary",
            ),
        );
        agent_attrs.insert(
            "xudanu:signature".to_string(),
            ProvValue::typed(
                &hex_encode(&self.base_provenance.signature),
                "xsd:hexBinary",
            ),
        );

        doc.agent.insert(
            author_id.clone(),
            ProvAgent {
                attributes: agent_attrs,
            },
        );

        // Create attribution
        let attribution_id = generate_prov_id("xudanu", &format!("attr_{}", entity_id));
        doc.wasAttributedTo.insert(
            attribution_id,
            ProvAttribution {
                entity: entity_id.clone(),
                agent: author_id.clone(),
                time: None,
                attributes: std::collections::HashMap::new(),
            },
        );

        // Add cross-server signatures as activities and associations
        for (idx, sig) in self.cross_server_signatures.iter().enumerate() {
            let activity_id = generate_prov_id("xudanu", &format!("crosssig_{}", idx));
            let mut activity_attrs = std::collections::HashMap::new();
            activity_attrs.insert(
                "prov:type".to_string(),
                ProvValue::qname("xudanu:CrossServerSignature"),
            );
            activity_attrs.insert(
                "xudanu:timestamp".to_string(),
                ProvValue::typed(&sig.timestamp.to_string(), "xsd:integer"),
            );
            activity_attrs.insert(
                "xudanu:serverId".to_string(),
                ProvValue::typed(&hex_encode(&sig.server_id), "xsd:hexBinary"),
            );
            activity_attrs.insert(
                "xudanu:verifyingKey".to_string(),
                ProvValue::typed(&hex_encode(&sig.verifying_key), "xsd:hexBinary"),
            );
            activity_attrs.insert(
                "xudanu:signature".to_string(),
                ProvValue::typed(&hex_encode(&sig.signature), "xsd:hexBinary"),
            );

            doc.activity.insert(
                activity_id.clone(),
                ProvActivity {
                    // PROV temporal slots carry xsd:dateTime; the raw
                    // integer stays in xudanu:timestamp.
                    start_time: Some(unix_to_xsd_datetime(sig.timestamp)),
                    end_time: Some(unix_to_xsd_datetime(sig.timestamp)),
                    attributes: activity_attrs,
                },
            );

            // The verification activity USED the attested entity —
            // the core PROV usage record (previously unstateable).
            let usage_id = generate_prov_id("xudanu", &format!("use_crosssig_{}", idx));
            doc.used.insert(
                usage_id,
                ProvUsage {
                    activity: activity_id.clone(),
                    entity: entity_id.clone(),
                    time: Some(unix_to_xsd_datetime(sig.timestamp)),
                    attributes: std::collections::HashMap::new(),
                },
            );

            // Associate server agent with activity
            let server_agent_id = generate_prov_id(
                "xudanu",
                &format!("server_{}", &hex_encode(&sig.server_id)[..8]),
            );
            let mut server_attrs = std::collections::HashMap::new();
            server_attrs.insert("prov:type".to_string(), ProvValue::qname("xudanu:Server"));
            server_attrs.insert(
                "xudanu:serverId".to_string(),
                ProvValue::typed(&hex_encode(&sig.server_id), "xsd:hexBinary"),
            );

            doc.agent.insert(
                server_agent_id.clone(),
                ProvAgent {
                    attributes: server_attrs,
                },
            );

            let assoc_id = generate_prov_id("xudanu", &format!("assoc_{}_{}", idx, idx));
            doc.wasAssociatedWith.insert(
                assoc_id,
                ProvAssociation {
                    activity: activity_id.clone(),
                    agent: Some(server_agent_id.clone()),
                    role: Some(ProvValue::qname("verifier")),
                    plan: None,
                    attributes: std::collections::HashMap::new(),
                },
            );
        }

        // Add consensus as an entity
        let consensus_entity_id =
            generate_prov_id("xudanu", &format!("consensus_{}", self.consensus.timestamp));
        let mut consensus_attrs = std::collections::HashMap::new();
        consensus_attrs.insert(
            "prov:type".to_string(),
            ProvValue::qname("xudanu:ClusterConsensus"),
        );
        consensus_attrs.insert(
            "xudanu:consensusType".to_string(),
            ProvValue::string(&self.consensus.consensus_type.to_string()),
        );
        consensus_attrs.insert(
            "xudanu:thresholdMet".to_string(),
            ProvValue::string(&self.consensus.threshold_met.to_string()),
        );
        consensus_attrs.insert(
            "xudanu:totalServers".to_string(),
            ProvValue::typed(&self.consensus.total_servers.to_string(), "xsd:integer"),
        );
        consensus_attrs.insert(
            "xudanu:approvingServers".to_string(),
            ProvValue::typed(&self.consensus.approving_servers.to_string(), "xsd:integer"),
        );

        doc.entity.insert(
            consensus_entity_id,
            ProvEntity {
                attributes: consensus_attrs,
            },
        );

        Ok(doc)
    }
}
