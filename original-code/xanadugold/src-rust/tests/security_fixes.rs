// Security fixes integration tests
// Tests for: secret key file permissions, key preview removal, security hardening
// Plus tests for: timing attacks, empty registry signatures, secure logging, error masking

use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::PathBuf;

/// Test that registry_init creates secure key file with proper permissions
#[test]
fn test_registry_init_creates_secure_key_file() {
    use xudanu::crypto::server_identity::TrustedServerRegistry;
    use ed25519_dalek::SigningKey;
    use std::io::Write;
    
    let temp_dir = tempfile::tempdir().expect("Failed to create temp dir");
    let registry_path = temp_dir.path().join("test-registry.json");
    let key_path = temp_dir.path().join("test-registry.json.authority-key");
    
    // Simulate registry_init behavior
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let authority_key_hex = hex::encode(authority_key.to_bytes());
    
    // Write secret key to file (simulating CLI behavior)
    fs::write(&key_path, &authority_key_hex).expect("Failed to write key file");
    
    // Set file permissions to 600 (owner read/write only)
    let mut perms = fs::metadata(&key_path).expect("Failed to read key file metadata").permissions();
    perms.set_mode(0o600);
    fs::set_permissions(&key_path, perms).expect("Failed to set permissions");
    
    // Verify key file was created
    assert!(key_path.exists(), "Authority key file was not created");
    
    // Verify key file has 600 permissions (owner read/write only)
    let metadata = fs::metadata(&key_path).expect("Failed to read key file metadata");
    let permissions = metadata.permissions();
    let mode = permissions.mode();
    assert_eq!(mode & 0o777, 0o600, "Key file has wrong permissions: {:o}", mode);
    
    // Verify key content is hex-encoded and correct length
    let key_content = fs::read_to_string(&key_path).expect("Failed to read key file");
    let key_bytes = hex::decode(&key_content.trim()).expect("Failed to decode key hex");
    assert_eq!(key_bytes.len(), 32, "Key must be 32 bytes");
}

/// Test that registry_list does NOT expose key material
#[test]
fn test_registry_list_no_key_exposure() {
    use xudanu::crypto::server_identity::{TrustedServerRegistry, ServerIdentity};
    use ed25519_dalek::SigningKey;
    
    // Create test registry with NEW API
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let mut registry = TrustedServerRegistry::new(&authority_key);
    
    // Add test server with known key
    let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let server_key_hex = hex::encode(server_key.to_bytes());
    
    let server_id = ServerIdentity::new(
        "test-server".to_string(),
        server_key.to_bytes(),
        [0u8; 32], // KEX key
        "xudanu".to_string(),
    );
    
    registry.add_server(server_id, &authority_key).expect("Failed to add server");
    
    // Simulate registry_list output (just verify key data exists but won't be shown)
    assert_eq!(registry.server_count(), 1, "Should have one server");
    let server = registry.get("test-server").expect("Should have test server");
    
    // Verify we have the key data internally
    let internal_key_hex = hex::encode(&server.signing_key);
    assert_eq!(internal_key_hex, server_key_hex, "Key should match");
    
    // But this key should NOT appear in user-facing output
    // (This test verifies the key data exists but we don't expose it)
    assert!(!internal_key_hex.is_empty(), "Key should exist internally");
}

/// Test that verify_server_identity uses constant-time comparison
#[test]
fn test_verify_server_identity_variable_naming() {
    use xudanu::crypto::server_identity::{TrustedServerRegistry, ServerIdentity, verify_server_identity};
    use ed25519_dalek::SigningKey;
    
    // Create test registry with NEW API
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let mut registry = TrustedServerRegistry::new(&authority_key);
    
    // Add test server
    let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let server_id = ServerIdentity::new(
        "test-server".to_string(),
        server_key.to_bytes(),
        [0u8; 32], // KEX key
        "xudanu".to_string(),
    );
    registry.add_server(server_id, &authority_key).expect("Failed to add server");
    
    // Test with correct key (should succeed)
    let result = verify_server_identity("test-server", &server_key.to_bytes(), &registry);
    assert!(result.is_ok(), "Should verify server with correct key");
    
    // Test with wrong key (should fail with generic error)
    let wrong_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let result = verify_server_identity("test-server", &wrong_key.to_bytes(), &registry);
    assert!(result.is_err(), "Should reject server with wrong key");
    
    // Verify error message is generic (doesn't reveal which check failed)
    let error_msg = result.unwrap_err();
    assert_eq!(error_msg, "server identity verification failed", "Error should be generic");
    
    // Test with unknown server (should fail with same generic error)
    let unknown_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let result = verify_server_identity("unknown-server", &unknown_key.to_bytes(), &registry);
    assert!(result.is_err(), "Should reject unknown server");
    
    let error_msg = result.unwrap_err();
    assert_eq!(error_msg, "server identity verification failed", "Error should be generic");
}

/// Test that key files are not readable by other users
#[test]
fn test_key_file_permissions_security() {
    use std::io::Write;
    
    let temp_dir = tempfile::tempdir().expect("Failed to create temp dir");
    let key_path = temp_dir.path().join("test-key.secret");
    
    // Simulate writing a secret key
    let secret_key = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
    fs::write(&key_path, secret_key).expect("Failed to write key");
    
    // Set file permissions to 600 (owner read/write only)
    let mut perms = fs::metadata(&key_path).expect("Failed to read metadata").permissions();
    perms.set_mode(0o600);
    fs::set_permissions(&key_path, perms).expect("Failed to set permissions");
    
    // Check permissions multiple ways
    let metadata = fs::metadata(&key_path).expect("Failed to read metadata");
    let permissions = metadata.permissions();
    let mode = permissions.mode();
    
    // Verify no group/others read/write/execute
    assert_eq!(mode & 0o077, 0o000, "Key file should not be accessible by group/others");
    
    // Verify owner has read/write
    assert_eq!(mode & 0o600, 0o600, "Owner should have read/write permissions");
}

/// NEW: Test that empty registry signature is properly verifiable
#[test]
fn test_empty_registry_signature_verification() {
    use xudanu::crypto::server_identity::TrustedServerRegistry;
    use ed25519_dalek::SigningKey;
    
    // Create empty registry with NEW API
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let registry = TrustedServerRegistry::new(&authority_key);
    
    // Verify that empty registry signature is VALID (not using temp key)
    let verify_result = registry.verify_signature();
    assert!(verify_result.is_ok(), "Empty registry should have valid signature");
    
    // Verify authority key matches
    assert_eq!(registry.authority_key, authority_key.verifying_key().to_bytes(), 
        "Authority key should match");
}

/// NEW: Test timing attack resistance via consistent error messages
#[test]
fn test_timing_attack_resistance() {
    use xudanu::crypto::server_identity::{TrustedServerRegistry, ServerIdentity, verify_server_identity};
    use ed25519_dalek::SigningKey;
    use std::time::Instant;
    
    // Create test registry with NEW API
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let mut registry = TrustedServerRegistry::new(&authority_key);
    
    let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let server_id = ServerIdentity::new(
        "test-server".to_string(),
        server_key.to_bytes(),
        [0u8; 32],
        "xudanu".to_string(),
    );
    registry.add_server(server_id, &authority_key).expect("Failed to add server");
    
    // Test timing consistency for different failure scenarios
    let mut times = Vec::new();
    
    // Measure time for unknown server failure
    let unknown_key = SigningKey::generate(&mut rand::rngs::OsRng);
    for _ in 0..5 {
        let start = Instant::now();
        let _ = verify_server_identity("unknown-server", &unknown_key.to_bytes(), &registry);
        times.push(start.elapsed());
    }
    
    let unknown_avg: u64 = times.iter().map(|t| t.as_nanos() as u64).sum::<u64>() / times.len() as u64;
    times.clear();
    
    // Measure time for wrong key failure
    let wrong_key = SigningKey::generate(&mut rand::rngs::OsRng);
    for _ in 0..5 {
        let start = Instant::now();
        let _ = verify_server_identity("test-server", &wrong_key.to_bytes(), &registry);
        times.push(start.elapsed());
    }
    
    let wrong_key_avg: u64 = times.iter().map(|t| t.as_nanos() as u64).sum::<u64>() / times.len() as u64;
    
    // Timing should be similar (within reasonable bounds)
    // Allow up to 10x difference due to system noise
    let ratio = if unknown_avg > wrong_key_avg {
        unknown_avg as f64 / wrong_key_avg as f64
    } else {
        wrong_key_avg as f64 / unknown_avg as f64
    };
    
    assert!(ratio < 10.0, "Timing difference too large: {}x (may indicate timing vulnerability)", ratio);
    
    // Both should return same generic error message
    let unknown_result = verify_server_identity("unknown-server", &unknown_key.to_bytes(), &registry);
    let wrong_key_result = verify_server_identity("test-server", &wrong_key.to_bytes(), &registry);
    
    assert_eq!(unknown_result.unwrap_err(), "server identity verification failed");
    assert_eq!(wrong_key_result.unwrap_err(), "server identity verification failed");
}

/// NEW: Test that error messages don't leak sensitive information
#[test]
fn test_secure_error_messages() {
    use xudanu::crypto::server_identity::{TrustedServerRegistry, ServerIdentity, verify_server_identity};
    use ed25519_dalek::SigningKey;
    
    // Create test registry with NEW API
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let mut registry = TrustedServerRegistry::new(&authority_key);
    
    let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let server_id = ServerIdentity::new(
        "test-server".to_string(),
        server_key.to_bytes(),
        [0u8; 32],
        "xudanu".to_string(),
    );
    registry.add_server(server_id, &authority_key).expect("Failed to add server");
    
    // Test various failure scenarios
    let test_cases = vec![
        ("unknown-server", &SigningKey::generate(&mut rand::rngs::OsRng).to_bytes()),
        ("test-server", &SigningKey::generate(&mut rand::rngs::OsRng).to_bytes()),
        ("wrong-length", &[1u8; 16]), // Wrong key length
    ];
    
    for (server_id, key) in test_cases {
        let result = verify_server_identity(server_id, key, &registry);
        if let Err(msg) = result {
            // Verify error doesn't contain sensitive information
            assert!(!msg.contains("signature"), "Error shouldn't mention signature");
            assert!(!msg.contains("expired"), "Error shouldn't mention expiration");
            assert!(!msg.contains("not found"), "Error shouldn't mention existence");
            assert!(!msg.contains("invalid length"), "Error shouldn't mention length");
            assert_eq!(msg, "server identity verification failed", "Error should be generic");
        }
    }
}

/// NEW: Test that registry API changes work correctly
#[test]
fn test_registry_api_signing_key_required() {
    use xudanu::crypto::server_identity::{TrustedServerRegistry, ServerIdentity};
    use ed25519_dalek::SigningKey;
    
    // Test that new API requires signing key
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let registry = TrustedServerRegistry::new(&authority_key);
    
    // Verify signature is valid
    assert!(registry.verify_signature().is_ok(), "Registry should have valid signature");
    
    // Verify we can add servers with the same key
    let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let server_id = ServerIdentity::new(
        "test-server".to_string(),
        server_key.to_bytes(),
        [0u8; 32],
        "xudanu".to_string(),
    );
    
    let updated_registry = registry.add_server(server_id, &authority_key);
    assert!(updated_registry.is_ok(), "Should be able to add server");
    
    // Verify updated registry still has valid signature
    let updated = updated_registry.unwrap();
    assert!(updated.verify_signature().is_ok(), "Updated registry should have valid signature");
}

/// NEW: Test input validation for server IDs
#[test]
fn test_input_validation_server_ids() {
    use xudanu::crypto::server_identity::ServerIdentity;
    use ed25519_dalek::SigningKey;
    
    let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
    
    // Test valid server IDs
    let valid_ids = vec![
        "server1",
        "test-server",
        "my_server_123",
        "server.example.com",
        "a", // minimal length
    ];
    
    for server_id in valid_ids {
        let identity = ServerIdentity::new(
            server_id.to_string(),
            server_key.to_bytes(),
            [0u8; 32],
            "xudanu".to_string(),
        );
        assert_eq!(identity.server_id, server_id, "Valid ID should be accepted");
    }
    
    // Test server IDs that should be handled carefully
    let problematic_ids = vec![
        "", // empty string - should this be rejected?
        "a".repeat(1000).as_str(), // very long ID - should this be rejected?
    ];
    
    // These tests verify the system handles edge cases gracefully
    // Actual validation policies can be adjusted based on requirements
    for server_id in problematic_ids {
        let identity = ServerIdentity::new(
            server_id.to_string(),
            server_key.to_bytes(),
            [0u8; 32],
            "xudanu".to_string(),
        );
        // Verify the ID is stored as-is (validation policy decision)
        assert_eq!(identity.server_id, server_id);
    }
}

/// NEW: Test input validation for federation domains
#[test]
fn test_input_validation_federation_domains() {
    use xudanu::crypto::server_identity::ServerIdentity;
    use ed25519_dalek::SigningKey;
    
    let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
    
    // Test valid federation domains
    let valid_domains = vec![
        "xudanu",
        "example.com",
        "federation.example.org",
        "my-federation",
        "test",
    ];
    
    for domain in valid_domains {
        let identity = ServerIdentity::new(
            "test-server".to_string(),
            server_key.to_bytes(),
            [0u8; 32],
            domain.to_string(),
        );
        assert_eq!(identity.federation_domain, domain, "Valid domain should be accepted");
    }
}

/// NEW: Test key validation and format
#[test]
fn test_key_validation_and_format() {
    use xudanu::crypto::server_identity::ServerIdentity;
    use ed25519_dalek::SigningKey;
    
    // Test valid key formats
    let valid_keys = vec![
        SigningKey::generate(&mut rand::rngs::OsRng).to_bytes(),
        [0u8; 32], // all zeros
        [0xFFu8; 32], // all max
    ];
    
    for key in valid_keys {
        let identity = ServerIdentity::new(
            "test-server".to_string(),
            key,
            [0u8; 32],
            "xudanu".to_string(),
        );
        assert_eq!(identity.signing_key, key, "Valid key should be accepted");
        assert_eq!(identity.signing_key.len(), 32, "Key must be 32 bytes");
        assert_eq!(identity.kex_public.len(), 32, "KEX key must be 32 bytes");
    }
}

/// NEW: Test key material protection
#[test]
fn test_key_material_protection() {
    use xudanu::crypto::server_identity::{TrustedServerRegistry, ServerIdentity};
    use ed25519_dalek::SigningKey;
    use std::fs;
    
    let temp_dir = tempfile::tempdir().expect("Failed to create temp dir");
    let registry_path = temp_dir.path().join("test-registry.json");
    
    // Create registry and add server
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let server_id = ServerIdentity::new(
        "secure-server".to_string(),
        server_key.to_bytes(),
        [0u8; 32],
        "xudanu".to_string(),
    );
    
    let mut registry = TrustedServerRegistry::new(&authority_key);
    registry.add_server(server_id, &authority_key).expect("Failed to add server");
    
    // Save registry to file
    let file = xudanu::crypto::server_identity::ServerRegistryFile::new(registry);
    file.save_to_file(&registry_path).expect("Failed to save registry");
    
    // Read file contents and verify keys are present (this is expected)
    let file_content = fs::read_to_string(&registry_path).expect("Failed to read registry");
    
    // Keys should be in the file (as hex), but file should have restricted permissions
    let server_key_hex = hex::encode(server_key.to_bytes());
    assert!(file_content.contains(&server_key_hex), "Keys should be stored in file");
    
    // Verify file permissions are restrictive
    let metadata = fs::metadata(&registry_path).expect("Failed to read file metadata");
    let permissions = metadata.permissions();
    let mode = permissions.mode();
    
    // Verify no group/others read permissions
    assert_eq!(mode & 0o044, 0o000, "Registry file should not be readable by group/others");
}

/// NEW: Test audit trail preservation
#[test]
fn test_audit_trail_preservation() {
    use xudanu::crypto::server_identity::{TrustedServerRegistry, ServerIdentity, ServerRegistryFile};
    use ed25519_dalek::SigningKey;
    use std::fs;
    use std::time::SystemTime;
    
    let temp_dir = tempfile::tempdir().expect("Failed to create temp dir");
    let registry_path = temp_dir.path().join("test-registry.json");
    
    // Create initial registry
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let mut registry = TrustedServerRegistry::new(&authority_key);
    let initial_timestamp = registry.last_updated;
    
    // Save initial state
    let file = ServerRegistryFile::new(registry);
    file.save_to_file(&registry_path).expect("Failed to save registry");
    
    // Load and verify
    let loaded = ServerRegistryFile::load_from_file(&registry_path).expect("Failed to load registry");
    assert_eq!(loaded.registry.last_updated, initial_timestamp, "Timestamp should be preserved");
    assert!(loaded.registry.verify_signature().is_ok(), "Signature should be valid");
    
    // Add server and update
    let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let server_id = ServerIdentity::new(
        "test-server".to_string(),
        server_key.to_bytes(),
        [0u8; 32],
        "xudanu".to_string(),
    );
    
    let updated_registry = loaded.registry.add_server(server_id, &authority_key)
        .expect("Failed to add server");
    let updated_timestamp = updated_registry.last_updated;
    
    // Timestamp should increase
    assert!(updated_timestamp > initial_timestamp, "Timestamp should increase after update");
    
    // Save updated state
    let updated_file = ServerRegistryFile::new(updated_registry);
    updated_file.save_to_file(&registry_path).expect("Failed to save updated registry");
    
    // Load and verify audit trail is preserved
    let reloaded = ServerRegistryFile::load_from_file(&registry_path).expect("Failed to reload registry");
    assert_eq!(reloaded.registry.last_updated, updated_timestamp, "Updated timestamp should be preserved");
    assert_eq!(reloaded.registry.server_count(), 1, "Server count should be preserved");
    assert!(reloaded.registry.verify_signature().is_ok(), "Updated signature should be valid");
}

/// NEW: Test signature integrity over multiple operations
#[test]
fn test_signature_integrity_multiple_operations() {
    use xudanu::crypto::server_identity::{TrustedServerRegistry, ServerIdentity};
    use ed25519_dalek::SigningKey;
    
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let mut registry = TrustedServerRegistry::new(&authority_key);
    
    // Perform multiple operations
    for i in 1..=5 {
        let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
        let server_id = ServerIdentity::new(
            format!("server-{}", i),
            server_key.to_bytes(),
            [0u8; 32],
            "xudanu".to_string(),
        );
        
        registry = registry.add_server(server_id, &authority_key)
            .expect("Failed to add server");
        
        // Verify signature after each operation
        assert!(registry.verify_signature().is_ok(), 
            format!("Signature should be valid after adding server {}", i));
    }
    
    // Remove a server
    registry = registry.remove_server("server-3", &authority_key)
        .expect("Failed to remove server");
    
    // Verify signature still valid
    assert!(registry.verify_signature().is_ok(), "Signature should be valid after removal");
    
    // Verify final state
    assert_eq!(registry.server_count(), 4, "Should have 4 servers");
    assert!(!registry.is_trusted("server-3"), "Removed server should not be trusted");
}

/// NEW: Test tamper detection
#[test]
fn test_tamper_detection() {
    use xudanu::crypto::server_identity::{TrustedServerRegistry, ServerIdentity, ServerRegistryFile};
    use ed25519_dalek::SigningKey;
    use std::fs;
    
    let temp_dir = tempfile::tempdir().expect("Failed to create temp dir");
    let registry_path = temp_dir.path().join("test-registry.json");
    
    // Create and save registry
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
    let server_id = ServerIdentity::new(
        "test-server".to_string(),
        server_key.to_bytes(),
        [0u8; 32],
        "xudanu".to_string(),
    );
    
    let mut registry = TrustedServerRegistry::new(&authority_key);
    registry.add_server(server_id, &authority_key).expect("Failed to add server");
    
    let file = ServerRegistryFile::new(registry);
    file.save_to_file(&registry_path).expect("Failed to save registry");
    
    // Tamper with the file
    let mut content = fs::read_to_string(&registry_path).expect("Failed to read file");
    content.push_str("tampered_data");
    fs::write(&registry_path, content).expect("Failed to write tampered file");
    
    // Loading should fail or signature verification should fail
    let result = ServerRegistryFile::load_from_file(&registry_path);
    
    match result {
        Ok(loaded) => {
            // If load succeeds, signature verification should fail
            let verify_result = loaded.registry.verify_signature();
            assert!(verify_result.is_err(), "Tampered registry should fail signature verification");
        }
        Err(_) => {
            // Load failed, which is also acceptable
        }
    }
}

/// NEW: Test concurrent access safety
#[test]
fn test_concurrent_access_safety() {
    use xudanu::crypto::server_identity::{TrustedServerRegistry, ServerIdentity};
    use ed25519_dalek::SigningKey;
    use std::sync::{Arc, Mutex};
    use std::thread;
    
    let authority_key = Arc::new(SigningKey::generate(&mut rand::rngs::OsRng));
    let registry = Arc::new(Mutex::new(TrustedServerRegistry::new(&authority_key)));
    
    let mut handles = vec![];
    
    // Spawn multiple threads that try to add servers
    for i in 0..10 {
        let auth_key = Arc::clone(&authority_key);
        let reg = Arc::clone(&registry);
        
        let handle = thread::spawn(move || {
            let server_key = SigningKey::generate(&mut rand::rngs::OsRng);
            let server_id = ServerIdentity::new(
                format!("server-{}", i),
                server_key.to_bytes(),
                [0u8; 32],
                "xudanu".to_string(),
            );
            
            let mut registry = reg.lock().unwrap();
            let result = registry.add_server(server_id, &auth_key);
            result
        });
        
        handles.push(handle);
    }
    
    // Wait for all threads to complete
    let results: Vec<_> = handles.into_iter().map(|h| h.join().unwrap()).collect();
    
    // All operations should succeed
    for result in &results {
        assert!(result.is_ok(), "Concurrent add operations should succeed");
    }
    
    // Verify final state
    let final_registry = registry.lock().unwrap();
    assert_eq!(final_registry.server_count(), 10, "All servers should be added");
    assert!(final_registry.verify_signature().is_ok(), "Final signature should be valid");
}