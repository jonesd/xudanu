use ed25519_dalek::SigningKey;
use xudanu_core::Document;
use xudanu_signing::{KeyStore, Signer};
use xudanu_types::*;

#[test]
fn test_generate_signer() {
    let signer = Signer::generate("Alice".to_string());
    assert_eq!(signer.author().display_name(), "Alice");
    assert!(signer.verifying_key().to_bytes().iter().any(|&b| b != 0));
}

#[test]
fn test_sign_and_verify_change() {
    let signer = Signer::generate("Alice".to_string());
    let site = SiteId::from_author(signer.author());
    let mut doc = Document::new([0u8; 32], signer.author().clone(), site);

    doc.insert(0, "Test content");
    let change = doc.commit_change().unwrap();

    let signed = signer.sign_change(change);
    assert!(
        signed.change.verify_signature(&signer.verifying_key()),
        "Author's own signature must verify"
    );
}

#[test]
fn test_wrong_key_fails_verification() {
    let signer_a = Signer::generate("Alice".to_string());
    let signer_b = Signer::generate("Bob".to_string());
    let site = SiteId::from_author(signer_a.author());
    let mut doc = Document::new([0u8; 32], signer_a.author().clone(), site);

    doc.insert(0, "Secret");
    let change = doc.commit_change().unwrap();
    let signed = signer_a.sign_change(change);

    assert!(
        !signed.change.verify_signature(&signer_b.verifying_key()),
        "Bob's key must NOT verify Alice's signature"
    );
}

#[test]
fn test_unsigned_change_fails_verification() {
    let signer = Signer::generate("Alice".to_string());
    let site = SiteId::from_author(signer.author());
    let mut doc = Document::new([0u8; 32], signer.author().clone(), site);

    doc.insert(0, "Data");
    let change = doc.commit_change().unwrap();

    assert!(
        !change.verify_signature(&signer.verifying_key()),
        "Unsigned change must fail verification"
    );
}

#[test]
fn test_sign_multiple_changes() {
    let signer = Signer::generate("Alice".to_string());
    let site = SiteId::from_author(signer.author());
    let mut doc = Document::new([0u8; 32], signer.author().clone(), site);

    doc.insert(0, "First");
    let change1 = doc.commit_change().unwrap();
    doc.insert(5, " Second");
    let change2 = doc.commit_change().unwrap();

    let signed1 = signer.sign_change(change1);
    let signed2 = signer.sign_change(change2);

    assert!(signed1.change.verify_signature(&signer.verifying_key()));
    assert!(signed2.change.verify_signature(&signer.verifying_key()));
    assert_ne!(
        signed1.change.signature.unwrap(),
        signed2.change.signature.unwrap(),
        "Different changes must produce different signatures"
    );
}

#[test]
fn test_signing_key_persistence() {
    let signer = Signer::generate("Alice".to_string());
    let original_fingerprint = signer.author().fingerprint();

    let stored = xudanu_signing::signer::StoredKey::from_signer(&signer);
    let serialized = stored.serialize();
    let deserialized = xudanu_signing::signer::StoredKey::deserialize(&serialized).unwrap();
    let restored = deserialized.load().unwrap();

    assert_eq!(restored.author().fingerprint(), original_fingerprint);
}

#[test]
fn test_sign_arbitrary_bytes() {
    let signer = Signer::generate("Alice".to_string());
    let data = b"arbitrary data to sign";
    let signature = signer.sign_bytes(data);

    assert!(signer
        .verifying_key()
        .verify_strict(data, &signature)
        .is_ok());
    assert!(signer
        .verifying_key()
        .verify_strict(b"tampered data", &signature)
        .is_err());
}

#[test]
fn test_tampered_content_fails() {
    let signer = Signer::generate("Alice".to_string());
    let site = SiteId::from_author(signer.author());
    let mut doc = Document::new([0u8; 32], signer.author().clone(), site);

    doc.insert(0, "Original");
    let mut change = doc.commit_change().unwrap();
    let signed = signer.sign_change(change.clone());

    assert!(signed.change.verify_signature(&signer.verifying_key()));

    change.operations.clear();
    assert!(
        !change.verify_signature(&signer.verifying_key()),
        "Tampered change must fail verification"
    );
}

#[test]
fn test_different_signers_produce_different_keys() {
    let a = Signer::generate("Alice".to_string());
    let b = Signer::generate("Bob".to_string());

    assert_ne!(a.author_id(), b.author_id());
    assert_ne!(a.verifying_key().to_bytes(), b.verifying_key().to_bytes());
}

#[test]
fn test_author_fingerprint_uniqueness() {
    let a = Signer::generate("Alice".to_string());
    let b = Signer::generate("Bob".to_string());

    assert_ne!(a.author().fingerprint(), b.author().fingerprint());
}

#[test]
fn test_key_store_register_and_lookup() {
    let mut store = KeyStore::new();
    let signer = Signer::generate("Alice".to_string());
    let author = signer.author().clone();
    let ts = HybridTimestamp::now(1);

    store.register_author(author.clone(), ts);

    assert!(store.is_known(author.id()));
    assert!(!store.is_revoked(author.id()));
    assert_eq!(
        store.get_author(author.id()).unwrap().display_name(),
        "Alice"
    );
}

#[test]
fn test_key_store_revocation() {
    let mut store = KeyStore::new();
    let old_signer = Signer::generate("Alice".to_string());
    let new_signer = Signer::generate("Alice".to_string());
    let ts = HybridTimestamp::now(1);

    store.register_author(old_signer.author().clone(), ts);
    store.register_author(new_signer.author().clone(), ts);

    store
        .revoke_key(old_signer.author_id(), new_signer.author_id(), ts)
        .unwrap();

    assert!(store.is_revoked(old_signer.author_id()));
    assert!(!store.is_revoked(new_signer.author_id()));
}

#[test]
fn test_key_rotation_chain() {
    let mut store = KeyStore::new();
    let k1 = Signer::generate("Alice".to_string());
    let k2 = Signer::generate("Alice".to_string());
    let k3 = Signer::generate("Alice".to_string());
    let ts = HybridTimestamp::now(1);

    store.register_author(k1.author().clone(), ts);
    store.register_author(k2.author().clone(), ts);
    store.register_author(k3.author().clone(), ts);

    store
        .revoke_key(k1.author_id(), k2.author_id(), ts)
        .unwrap();
    store
        .revoke_key(k2.author_id(), k3.author_id(), ts)
        .unwrap();

    let chain = store.key_chain_for(k3.author_id());
    assert_eq!(chain.len(), 3, "Should have full key chain");
}

#[test]
fn test_key_store_active_authors() {
    let mut store = KeyStore::new();
    let a = Signer::generate("Alice".to_string());
    let b = Signer::generate("Bob".to_string());
    let ts = HybridTimestamp::now(1);

    store.register_author(a.author().clone(), ts);
    store.register_author(b.author().clone(), ts);

    let active = store.active_authors();
    assert_eq!(active.len(), 2);
}
