use xudanu_core::{SignedDocument, VerificationError};
use xudanu_signing::Signer;
use xudanu_types::*;

fn make_signed_user(name: &str) -> (Signer, SiteId, Author) {
    let signer = Signer::generate(name.to_string());
    let site = SiteId::from_author(signer.author());
    let author = signer.author().clone();
    (signer, site, author)
}

#[test]
fn test_sign_and_verify_roundtrip() {
    let (alice_signer, alice_site, alice_author) = make_signed_user("Alice");
    let (bob_signer, bob_site, bob_author) = make_signed_user("Bob");

    let mut doc_a = SignedDocument::new([0u8; 32], alice_signer, alice_site);
    doc_a.register_author(&bob_author);

    let mut doc_b = SignedDocument::new([0u8; 32], bob_signer, bob_site);
    doc_b.register_author(&alice_author);

    doc_a.insert(0, "Hello ");
    let signed = doc_a.commit_signed_change().unwrap();
    assert!(signed.change.signature.is_some());

    let result = doc_b.integrate_signed_change(&signed);
    assert!(result.is_ok());
    assert_eq!(doc_b.to_string(), "Hello ");
}

#[test]
fn test_reject_tampered_change() {
    let (alice_signer, alice_site, alice_author) = make_signed_user("Alice");
    let (bob_signer, bob_site, bob_author) = make_signed_user("Bob");

    let mut doc_a = SignedDocument::new([0u8; 32], alice_signer, alice_site);
    let mut doc_b = SignedDocument::new([0u8; 32], bob_signer, bob_site);
    doc_b.register_author(&alice_author);

    doc_a.insert(0, "Hello ");
    let mut signed = doc_a.commit_signed_change().unwrap();

    // Tamper with the update bytes
    signed.change.update_bytes.push(0xFF);

    let result = doc_b.integrate_signed_change(&signed);
    assert!(matches!(
        result,
        Err(VerificationError::InvalidSignature(_))
    ));
    assert_eq!(doc_b.to_string(), "");
}

#[test]
fn test_reject_unsigned_change() {
    let (alice_signer, alice_site, alice_author) = make_signed_user("Alice");
    let (bob_signer, bob_site, bob_author) = make_signed_user("Bob");

    let mut doc_a = SignedDocument::new([0u8; 32], alice_signer, alice_site);
    let mut doc_b = SignedDocument::new([0u8; 32], bob_signer, bob_site);
    doc_b.register_author(&alice_author);

    doc_a.insert(0, "Hello ");
    let mut signed = doc_a.commit_signed_change().unwrap();
    signed.change.signature = None;

    let result = doc_b.integrate_signed_change(&signed);
    assert!(matches!(
        result,
        Err(VerificationError::MissingSignature(_))
    ));
}

#[test]
fn test_reject_unknown_author() {
    let (alice_signer, alice_site, alice_author) = make_signed_user("Alice");
    let (bob_signer, bob_site, bob_author) = make_signed_user("Bob");

    let mut doc_a = SignedDocument::new([0u8; 32], alice_signer, alice_site);
    let mut doc_b = SignedDocument::new([0u8; 32], bob_signer, bob_site);
    // Bob does NOT register Alice's key

    doc_a.insert(0, "Hello ");
    let signed = doc_a.commit_signed_change().unwrap();

    let result = doc_b.integrate_signed_change(&signed);
    assert!(matches!(result, Err(VerificationError::UnknownAuthor(_))));
}

#[test]
fn test_signed_two_way_convergence() {
    let (alice_signer, alice_site, alice_author) = make_signed_user("Alice");
    let (bob_signer, bob_site, bob_author) = make_signed_user("Bob");

    let mut doc_a = SignedDocument::new([0u8; 32], alice_signer, alice_site);
    doc_a.register_author(&bob_author);

    let mut doc_b = SignedDocument::new([0u8; 32], bob_signer, bob_site);
    doc_b.register_author(&alice_author);

    doc_a.insert(0, "Hello ");
    let c1 = doc_a.commit_signed_change().unwrap();
    doc_b.integrate_signed_change(&c1).unwrap();

    doc_b.insert(6, "World");
    let c2 = doc_b.commit_signed_change().unwrap();
    doc_a.integrate_signed_change(&c2).unwrap();

    assert_eq!(doc_a.to_string(), "Hello World");
    assert_eq!(doc_b.to_string(), "Hello World");
}

#[test]
fn test_signed_attribution_works() {
    let (alice_signer, alice_site, alice_author) = make_signed_user("Alice");
    let (bob_signer, bob_site, bob_author) = make_signed_user("Bob");

    let mut doc_a = SignedDocument::new([0u8; 32], alice_signer, alice_site);
    doc_a.register_author(&bob_author);

    let mut doc_b = SignedDocument::new([0u8; 32], bob_signer, bob_site);
    doc_b.register_author(&alice_author);

    doc_a.insert(0, "Hello ");
    let c1 = doc_a.commit_signed_change().unwrap();
    doc_b.integrate_signed_change(&c1).unwrap();

    doc_b.insert(6, "World");
    let c2 = doc_b.commit_signed_change().unwrap();
    doc_a.integrate_signed_change(&c2).unwrap();

    let items: Vec<_> = doc_a.iter_visible().collect();
    assert_eq!(items.len(), 2, "Should have 2 items from different authors");
    assert_ne!(
        items[0].2, items[1].2,
        "Items should have different authors"
    );
}

#[test]
fn test_reject_forged_signature() {
    let (alice_signer, alice_site, alice_author) = make_signed_user("Alice");
    let (eve_signer, _, _eve_author) = make_signed_user("Eve");
    let (bob_signer, bob_site, _bob_author) = make_signed_user("Bob");

    let mut doc_a = SignedDocument::new([0u8; 32], alice_signer, alice_site);
    let mut doc_b = SignedDocument::new([0u8; 32], bob_signer, bob_site);

    // Bob has Alice's REAL public key
    doc_b.register_author(&alice_author);

    doc_a.insert(0, "Hello ");
    let signed = doc_a.commit_signed_change().unwrap();

    // Eve intercepts and re-signs with her own key, keeping Alice's actor
    let mut forged_change = signed.change.clone();
    let forged_sig = eve_signer.sign_bytes(&forged_change.signing_payload());
    forged_change.signature = Some(forged_sig);
    let forged = xudanu_types::SignedChange::new(forged_change);

    let result = doc_b.integrate_signed_change(&forged);
    assert!(
        matches!(result, Err(VerificationError::InvalidSignature(_))),
        "Should reject change re-signed by Eve with her private key"
    );
    assert_eq!(doc_b.to_string(), "");
}
