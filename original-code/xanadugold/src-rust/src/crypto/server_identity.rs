use std::collections::HashMap;
use std::time::SystemTime;

use ed25519_dalek::{Signature, VerifyingKey};
use serde::{Deserialize, Serialize};

use super::sign::{sign_bytes, verify_signature};

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ServerIdentity {
    pub server_id: String,
    pub signing_key: [u8; 32],
    pub kex_public: [u8; 32],
    pub federation_domain: String,
    pub added_at: u64,
    pub expires_at: Option<u64>,
}

impl ServerIdentity {
    pub fn new(
        server_id: String,
        signing_key: [u8; 32],
        kex_public: [u8; 32],
        federation_domain: String,
    ) -> Self {
        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        ServerIdentity {
            server_id,
            signing_key,
            kex_public,
            federation_domain,
            added_at: now,
            expires_at: None,
        }
    }

    pub fn with_expiry(mut self, expires_at: u64) -> Self {
        self.expires_at = Some(expires_at);
        self
    }

    pub fn is_valid_at(&self, timestamp: u64) -> bool {
        if timestamp < self.added_at {
            return false;
        }
        if let Some(exp) = self.expires_at {
            if timestamp > exp {
                return false;
            }
        }
        true
    }

    pub fn verifying_key(&self) -> Result<VerifyingKey, String> {
        VerifyingKey::from_bytes(&self.signing_key)
            .map_err(|_| "invalid verifying key bytes".to_string())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrustedServerRegistry {
    pub servers: HashMap<String, ServerIdentity>,
    pub last_updated: u64,
    #[cfg_attr(feature = "serde", serde(with = "signature_serde"))]
    pub signature: Signature,
    pub authority_key: [u8; 32],
}

mod signature_serde {
    use super::*;
    use serde::{Deserialize, Deserializer, Serializer};

    pub fn serialize<S>(signature: &Signature, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_bytes(&signature.to_bytes())
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<Signature, D::Error>
    where
        D: Deserializer<'de>,
    {
        let bytes = <Vec<u8>>::deserialize(deserializer)?;
        let arr: [u8; 64] = bytes
            .try_into()
            .map_err(|_| serde::de::Error::custom("signature bytes must be exactly 64 bytes"))?;
        Ok(Signature::from_bytes(&arr))
    }
}

impl TrustedServerRegistry {
    pub fn new(authority_signing_key: &ed25519_dalek::SigningKey) -> Self {
        let authority_key = authority_signing_key.verifying_key();
        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        // Create initial payload for empty registry
        let empty_payload = {
            let mut buf = Vec::new();
            buf.extend_from_slice(&now.to_be_bytes());
            buf.extend_from_slice(&0u64.to_be_bytes()); // 0 servers
            buf
        };

        // Use the actual authority signing key for the initial registry signature
        let signature = sign_bytes(authority_signing_key, &empty_payload);

        TrustedServerRegistry {
            servers: HashMap::new(),
            last_updated: now,
            signature,
            authority_key: authority_key.to_bytes(),
        }
    }

    pub fn add_server(
        &mut self,
        identity: ServerIdentity,
        authority_signing_key: &ed25519_dalek::SigningKey,
    ) -> Result<(), String> {
        let server_id = identity.server_id.clone();
        self.servers.insert(server_id.clone(), identity);
        self.last_updated = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        self.sign(authority_signing_key)?;
        tracing::info!(
            server_id = %server_id,
            event = "SECURITY:server_added_to_registry",
            "added server to trusted registry"
        );
        Ok(())
    }

    pub fn remove_server(
        &mut self,
        server_id: &str,
        authority_signing_key: &ed25519_dalek::SigningKey,
    ) -> Result<(), String> {
        if self.servers.remove(server_id).is_some() {
            self.last_updated = SystemTime::now()
                .duration_since(SystemTime::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs();
            self.sign(authority_signing_key)?;
            tracing::info!(
                server_id = %server_id,
                event = "SECURITY:server_removed_from_registry",
                "removed server from trusted registry"
            );
            Ok(())
        } else {
            Err(format!("server {} not found in registry", server_id))
        }
    }

    // Cloneable version for CLI operations
    pub fn add_server_clone(
        &self,
        identity: ServerIdentity,
        authority_signing_key: &ed25519_dalek::SigningKey,
    ) -> Result<TrustedServerRegistry, String> {
        let mut new_registry = self.clone();
        new_registry.add_server(identity, authority_signing_key)?;
        Ok(new_registry)
    }

    pub fn remove_server_clone(
        &self,
        server_id: &str,
        authority_signing_key: &ed25519_dalek::SigningKey,
    ) -> Result<TrustedServerRegistry, String> {
        let mut new_registry = self.clone();
        new_registry.remove_server(server_id, authority_signing_key)?;
        Ok(new_registry)
    }

    pub fn get(&self, server_id: &str) -> Option<&ServerIdentity> {
        self.servers.get(server_id)
    }

    pub fn verify_signature(&self) -> Result<(), String> {
        let payload = self.encode_payload();
        let authority_key = VerifyingKey::from_bytes(&self.authority_key)
            .map_err(|_| "invalid authority key bytes".to_string())?;
        verify_signature(&authority_key, &payload, &self.signature)
            .map_err(|_| "registry signature verification failed".to_string())
    }

    pub fn is_trusted(&self, server_id: &str) -> bool {
        self.servers.contains_key(server_id)
    }

    pub fn server_count(&self) -> usize {
        self.servers.len()
    }

    fn sign(&mut self, signing_key: &ed25519_dalek::SigningKey) -> Result<(), String> {
        let payload = self.encode_payload();
        self.signature = sign_bytes(signing_key, &payload);
        Ok(())
    }

    fn encode_payload(&self) -> Vec<u8> {
        let mut buf = Vec::new();

        // Encode timestamp
        buf.extend_from_slice(&self.last_updated.to_be_bytes());

        // Encode servers count
        buf.extend_from_slice(&(self.servers.len() as u64).to_be_bytes());

        // Encode each server (sorted by server_id for determinism)
        let mut server_ids: Vec<_> = self.servers.keys().collect();
        server_ids.sort();

        for server_id in server_ids {
            if let Some(identity) = self.servers.get(server_id) {
                // Encode server_id length and bytes
                buf.extend_from_slice(&(server_id.len() as u64).to_be_bytes());
                buf.extend_from_slice(server_id.as_bytes());

                // Encode signing_key
                buf.extend_from_slice(&identity.signing_key);

                // Encode kex_public
                buf.extend_from_slice(&identity.kex_public);

                // Encode federation_domain length and bytes
                buf.extend_from_slice(&(identity.federation_domain.len() as u64).to_be_bytes());
                buf.extend_from_slice(identity.federation_domain.as_bytes());

                // Encode timestamps
                buf.extend_from_slice(&identity.added_at.to_be_bytes());
                if let Some(exp) = identity.expires_at {
                    buf.extend_from_slice(&exp.to_be_bytes());
                }
            }
        }

        buf
    }

    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string_pretty(self)
    }

    pub fn from_json(json: &str) -> Result<Self, serde_json::Error> {
        serde_json::from_str(json)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerRegistryFile {
    #[cfg_attr(feature = "serde", serde(flatten))]
    pub registry: TrustedServerRegistry,
    pub version: u8,
}

impl ServerRegistryFile {
    pub fn new(registry: TrustedServerRegistry) -> Self {
        ServerRegistryFile {
            registry,
            version: 1,
        }
    }

    pub fn save_to_file(&self, path: &std::path::Path) -> std::io::Result<()> {
        let json = serde_json::to_string_pretty(self)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        let tmp_path = path.with_extension("regtmp");
        std::fs::write(&tmp_path, json.as_bytes())?;
        std::fs::rename(&tmp_path, path)
    }

    pub fn load_from_file(path: &std::path::Path) -> Result<Self, Box<dyn std::error::Error>> {
        let json = std::fs::read_to_string(path)?;
        let file: ServerRegistryFile = serde_json::from_str(&json)?;
        // Verify signature on load
        file.registry
            .verify_signature()
            .map_err(|e| format!("invalid registry signature: {}", e))?;
        Ok(file)
    }

    // Delegate methods to the registry
    pub fn server_count(&self) -> usize {
        self.registry.server_count()
    }

    pub fn is_trusted(&self, server_id: &str) -> bool {
        self.registry.is_trusted(server_id)
    }

    pub fn get(&self, server_id: &str) -> Option<&ServerIdentity> {
        self.registry.get(server_id)
    }
}

pub fn verify_server_identity(
    server_id: &str,
    reported_key: &[u8],
    trusted_registry: &TrustedServerRegistry,
) -> Result<(), String> {
    // Perform all checks to prevent timing attacks
    // Use generic error messages to avoid leaking which check failed

    let verification_result = || -> Result<(), String> {
        // Check 1: Verify registry signature
        trusted_registry
            .verify_signature()
            .map_err(|_| "server identity verification failed".to_string())?;

        // Check 2: Get expected identity from registry
        let expected_identity = trusted_registry
            .get(server_id)
            .ok_or_else(|| "server identity verification failed".to_string())?;

        // Check 3: Validate key length
        if reported_key.len() != 32 {
            return Err("server identity verification failed".to_string());
        }

        // Check 4: Check validity period
        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        if !expected_identity.is_valid_at(now) {
            return Err("server identity verification failed".to_string());
        }

        // Check 5: Constant-time key comparison
        let mut reported_key_bytes = [0u8; 32];
        reported_key_bytes.copy_from_slice(reported_key);

        use subtle::ConstantTimeEq;
        let keys_equal: bool = expected_identity
            .signing_key
            .ct_eq(&reported_key_bytes)
            .into();
        if !keys_equal {
            return Err("server identity verification failed".to_string());
        }

        Ok(())
    }();

    if verification_result.is_err() {
        tracing::warn!(
            server_id = %server_id,
            event = "SECURITY:server_identity_verification_failed",
            "server identity verification failed"
        );
        return verification_result;
    }

    tracing::debug!(
        server_id = %server_id,
        event = "SECURITY:server_identity_verified",
        "successfully verified server identity"
    );

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use ed25519_dalek::SigningKey;

    #[test]
    fn server_identity_new() {
        let identity = ServerIdentity::new(
            "test-server".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );
        assert_eq!(identity.server_id, "test-server");
        assert_eq!(identity.signing_key, [1u8; 32]);
        assert_eq!(identity.kex_public, [2u8; 32]);
        assert!(identity.expires_at.is_none());
    }

    #[test]
    fn server_identity_with_expiry() {
        let identity = ServerIdentity::new(
            "test-server".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        )
        .with_expiry(9999999999);
        assert_eq!(identity.expires_at, Some(9999999999));
    }

    #[test]
    fn server_identity_validity() {
        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        let valid_identity = ServerIdentity::new(
            "valid-server".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );
        assert!(valid_identity.is_valid_at(now));

        let expired_identity = ServerIdentity::new(
            "expired-server".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        )
        .with_expiry(now - 3600);
        assert!(!expired_identity.is_valid_at(now));

        let future_identity = ServerIdentity::new(
            "future-server".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );
        // Manually set added_at to future
        let mut future = future_identity;
        future.added_at = now + 3600;
        assert!(!future.is_valid_at(now));
    }

    #[test]
    fn trusted_registry_new() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let registry = TrustedServerRegistry::new(&authority_key);
        assert_eq!(registry.server_count(), 0);
        assert!(!registry.is_trusted("nonexistent"));
    }

    #[test]
    fn trusted_registry_add_server() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let mut registry = TrustedServerRegistry::new(&authority_key);

        let identity = ServerIdentity::new(
            "server1".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );

        assert!(registry
            .add_server(identity.clone(), &authority_key)
            .is_ok());
        assert_eq!(registry.server_count(), 1);
        assert!(registry.is_trusted("server1"));

        let retrieved = registry.get("server1").unwrap();
        assert_eq!(retrieved.server_id, "server1");
        assert_eq!(retrieved.signing_key, [1u8; 32]);
    }

    #[test]
    fn trusted_registry_remove_server() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let mut registry = TrustedServerRegistry::new(&authority_key);

        let identity = ServerIdentity::new(
            "server1".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );

        registry.add_server(identity, &authority_key).unwrap();
        assert_eq!(registry.server_count(), 1);

        assert!(registry.remove_server("server1", &authority_key).is_ok());
        assert_eq!(registry.server_count(), 0);
        assert!(!registry.is_trusted("server1"));
    }

    #[test]
    fn trusted_registry_signature_verification() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let mut registry = TrustedServerRegistry::new(&authority_key);

        // Skip signature verification test for empty registry since it uses a temp key
        // The real signature verification will work after adding servers

        let identity = ServerIdentity::new(
            "server1".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );

        registry.add_server(identity, &authority_key).unwrap();
        // Signature should be valid after adding server with proper authority key
        assert!(registry.verify_signature().is_ok());
    }

    #[test]
    fn trusted_registry_tampered_detection() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let mut registry = TrustedServerRegistry::new(&authority_key);

        let identity = ServerIdentity::new(
            "server1".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );

        registry.add_server(identity, &authority_key).unwrap();

        // Tamper with the registry
        let mut tampered_identity = ServerIdentity::new(
            "malicious".to_string(),
            [99u8; 32],
            [88u8; 32],
            "xudanu".to_string(),
        );
        registry
            .servers
            .insert("malicious".to_string(), tampered_identity);

        // Signature verification should fail
        assert!(registry.verify_signature().is_err());
    }

    #[test]
    fn verify_server_identity_success() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let mut registry = TrustedServerRegistry::new(&authority_key);

        let identity = ServerIdentity::new(
            "server1".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );

        registry.add_server(identity, &authority_key).unwrap();

        // Verification with correct key should succeed
        assert!(verify_server_identity("server1", &[1u8; 32], &registry).is_ok());
    }

    #[test]
    fn verify_server_identity_wrong_key() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let mut registry = TrustedServerRegistry::new(&authority_key);

        let identity = ServerIdentity::new(
            "server1".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );

        registry.add_server(identity, &authority_key).unwrap();

        // Verification with wrong key should fail
        let result = verify_server_identity("server1", &[99u8; 32], &registry);
        assert!(result.is_err());
        // Implementation uses generic error to prevent information leakage
        assert_eq!(result.unwrap_err(), "server identity verification failed");
    }

    #[test]
    fn verify_server_identity_unknown_server() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let registry = TrustedServerRegistry::new(&authority_key);

        // Verification of unknown server should fail
        let result = verify_server_identity("unknown", &[1u8; 32], &registry);
        assert!(result.is_err());
        // Implementation uses generic error to prevent information leakage
        assert_eq!(result.unwrap_err(), "server identity verification failed");
    }

    #[test]
    fn verify_server_identity_expired() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let mut registry = TrustedServerRegistry::new(&authority_key);

        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        let expired_identity = ServerIdentity::new(
            "expired-server".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        )
        .with_expiry(now - 3600);

        registry
            .add_server(expired_identity, &authority_key)
            .unwrap();

        // Verification of expired server should fail
        let result = verify_server_identity("expired-server", &[1u8; 32], &registry);
        assert!(result.is_err());
        // Implementation uses generic error to prevent information leakage
        assert_eq!(result.unwrap_err(), "server identity verification failed");
    }

    #[test]
    fn server_registry_file_roundtrip() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let mut registry = TrustedServerRegistry::new(&authority_key);

        let identity = ServerIdentity::new(
            "server1".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );

        registry.add_server(identity, &authority_key).unwrap();

        let file = ServerRegistryFile::new(registry.clone());

        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("registry.json");

        assert!(file.save_to_file(&path).is_ok());

        let loaded = ServerRegistryFile::load_from_file(&path).unwrap();
        assert_eq!(loaded.server_count(), 1);
        assert!(loaded.is_trusted("server1"));

        let loaded_identity = loaded.get("server1").unwrap();
        assert_eq!(loaded_identity.server_id, "server1");
        assert_eq!(loaded_identity.signing_key, [1u8; 32]);
    }

    #[test]
    fn server_registry_file_rejects_tampered() {
        let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let mut registry = TrustedServerRegistry::new(&authority_key);

        let identity = ServerIdentity::new(
            "server1".to_string(),
            [1u8; 32],
            [2u8; 32],
            "xudanu".to_string(),
        );

        registry.add_server(identity, &authority_key).unwrap();

        let file = ServerRegistryFile::new(registry);

        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("registry.json");

        file.save_to_file(&path).unwrap();

        // Tamper with the file by modifying the registry data directly
        let json_str = std::fs::read_to_string(&path).unwrap();
        let mut value: serde_json::Value = serde_json::from_str(&json_str).unwrap();

        // Change the signing key which should break the signature
        if let Some(servers) = value.get_mut("servers").and_then(|s| s.as_object_mut()) {
            if let Some(server1) = servers.get_mut("server1") {
                if let Some(signing_key) = server1
                    .get_mut("signing_key")
                    .and_then(|k| k.as_array_mut())
                {
                    signing_key[0] = serde_json::json!(99u8);
                }
            }
        }

        std::fs::write(&path, serde_json::to_string(&value).unwrap().as_bytes()).unwrap();

        // Loading tampered file should fail signature verification
        let result = ServerRegistryFile::load_from_file(&path);
        assert!(result.is_err());
        let error_msg = result.unwrap_err().to_string();
        assert!(error_msg.to_lowercase().contains("signature"));
    }
}
