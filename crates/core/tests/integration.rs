use xudanu_core::{Document, StateVector};
use xudanu_types::*;
use xudanu_signing::Signer;
use xudanu_provenance::AttributionEngine;

struct TestUser {
    signer: Signer,
    site: SiteId,
}

impl TestUser {
    fn new(name: &str, id: u8) -> Self {
        let signer = Signer::generate(name.to_string());
        let site = SiteId::from_author(signer.author());
        Self { signer, site }
    }

    fn make_doc(&self) -> Document {
        Document::new([0u8; 32], self.signer.author().clone(), self.site)
    }
}

#[test]
fn test_basic_insert() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "Hello");
    assert_eq!(doc.to_string(), "Hello");
    assert_eq!(doc.len(), 5);
}

#[test]
fn test_multiple_inserts() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "Hello");
    doc.insert(5, " World");
    assert_eq!(doc.to_string(), "Hello World");
}

#[test]
fn test_insert_at_beginning() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "World");
    doc.insert(0, "Hello ");
    assert_eq!(doc.to_string(), "Hello World");
}

#[test]
fn test_insert_at_middle() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "Helo");
    doc.insert(2, "l");
    assert_eq!(doc.to_string(), "Hello");
}

#[test]
fn test_delete() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "Hello World");
    doc.delete(5, 1);
    assert_eq!(doc.to_string(), "HelloWorld");
}

#[test]
fn test_delete_multiple() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "Hello World");
    doc.delete(5, 6);
    assert_eq!(doc.to_string(), "Hello");
}

#[test]
fn test_delete_beginning() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "Hello");
    doc.delete(0, 5);
    assert_eq!(doc.to_string(), "");
    assert_eq!(doc.len(), 0);
}

#[test]
fn test_empty_doc() {
    let user = TestUser::new("Alice", 1);
    let doc = user.make_doc();
    assert!(doc.is_empty());
    assert_eq!(doc.to_string(), "");
}

#[test]
fn test_state_vector_tracks_local_edits() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "a");
    doc.insert(1, "b");
    doc.insert(2, "c");
    let sv = doc.state_vector();
    assert!(sv.knows(&user.site, 3));
}

#[test]
fn test_commit_change() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "Hello");
    let change = doc.commit_change().expect("should have a change");
    assert!(!change.update_bytes.is_empty());
    assert_eq!(change.actor, *user.signer.author_id());
    assert!(!change.id.iter().all(|&b| b == 0));
}

#[test]
fn test_commit_multiple_ops() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "Hello");
    doc.insert(5, " ");
    doc.insert(6, "World");
    let change = doc.commit_change().expect("should have a change");
    assert!(!change.update_bytes.is_empty());
}

#[test]
fn test_commit_empty_is_none() {
    let user = TestUser::new("Alice", 1);
    let doc = user.make_doc();
    let mut doc = doc;
    assert!(doc.commit_change().is_none());
}

#[test]
fn test_integrate_remote_change() {
    let alice = TestUser::new("Alice", 1);
    let bob = TestUser::new("Bob", 2);

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Hello");
    let change = doc_a.commit_change().unwrap();

    doc_b.integrate_change(&change);
    assert_eq!(doc_b.to_string(), "Hello");
}

#[test]
fn test_concurrent_inserts_converge() {
    let alice = TestUser::new("Alice", 1);
    let bob = TestUser::new("Bob", 2);

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Hello");
    doc_b.insert(0, "World");

    let change_a = doc_a.commit_change().unwrap();
    let change_b = doc_b.commit_change().unwrap();

    doc_a.integrate_change(&change_b);
    doc_b.integrate_change(&change_a);

    assert_eq!(doc_a.to_string(), doc_b.to_string(),
        "Documents must converge after exchanging concurrent edits");
}

#[test]
fn test_concurrent_insert_at_same_position() {
    let alice = TestUser::new("Alice", 1);
    let bob = TestUser::new("Bob", 2);

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "A");
    doc_b.insert(0, "B");

    let change_a = doc_a.commit_change().unwrap();
    let change_b = doc_b.commit_change().unwrap();

    doc_a.integrate_change(&change_b);
    doc_b.integrate_change(&change_a);

    let text_a = doc_a.to_string();
    let text_b = doc_b.to_string();
    assert_eq!(text_a, text_b, "Must converge: A='{}', B='{}'", text_a, text_b);
}

#[test]
fn test_three_way_convergence() {
    let alice = TestUser::new("Alice", 1);
    let bob = TestUser::new("Bob", 2);
    let carol = TestUser::new("Carol", 3);

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();
    let mut doc_c = carol.make_doc();

    doc_a.insert(0, "A");
    doc_b.insert(0, "B");
    doc_c.insert(0, "C");

    let change_a = doc_a.commit_change().unwrap();
    let change_b = doc_b.commit_change().unwrap();
    let change_c = doc_c.commit_change().unwrap();

    doc_a.integrate_change(&change_b);
    doc_a.integrate_change(&change_c);

    doc_b.integrate_change(&change_a);
    doc_b.integrate_change(&change_c);

    doc_c.integrate_change(&change_a);
    doc_c.integrate_change(&change_b);

    let text_a = doc_a.to_string();
    let text_b = doc_b.to_string();
    let text_c = doc_c.to_string();

    assert_eq!(text_a, text_b, "A and B must converge");
    assert_eq!(text_b, text_c, "B and C must converge");
    assert_eq!(text_a, text_c, "A and C must converge");
}

#[test]
fn test_converge_after_sequential_then_sync() {
    let alice = TestUser::new("Alice", 1);
    let bob = TestUser::new("Bob", 2);

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Hello");
    let change1 = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&change1);

    doc_b.insert(5, " World");
    let change2 = doc_b.commit_change().unwrap();
    doc_a.integrate_change(&change2);

    assert_eq!(doc_a.to_string(), "Hello World");
    assert_eq!(doc_b.to_string(), "Hello World");
}

#[test]
fn test_delete_converges() {
    let alice = TestUser::new("Alice", 1);
    let bob = TestUser::new("Bob", 2);

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Hello World");
    let change = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&change);

    doc_a.delete(5, 6);
    let del_change = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&del_change);

    assert_eq!(doc_a.to_string(), "Hello");
    assert_eq!(doc_b.to_string(), "Hello");
}

#[test]
fn test_signing_roundtrip() {
    let signer_a = Signer::generate("Alice".to_string());
    let signer_b = Signer::generate("Bob".to_string());

    let site = SiteId::from_author(signer_a.author());
    let mut doc = Document::new([0u8; 32], signer_a.author().clone(), site);

    doc.insert(0, "Hello signed world");
    let change = doc.commit_change().unwrap();

    let signed = signer_a.sign_change(change);
    assert!(signed.change.verify_signature(&signer_a.verifying_key()));

    let verification = signed.change.verify_signature(&signer_b.verifying_key());
    assert!(!verification, "Bob should NOT be able to verify Alice's change as his own");
}

#[test]
fn test_signing_non_repudiation() {
    let signer = Signer::generate("Alice".to_string());
    let site = SiteId::from_author(signer.author());
    let mut doc = Document::new([0u8; 32], signer.author().clone(), site);

    doc.insert(0, "Sensitive content");
    let change = doc.commit_change().unwrap();
    let signed = signer.sign_change(change);

    assert!(signed.change.verify_signature(&signer.verifying_key()));
    assert!(signed.change.signature.is_some());
}

#[test]
fn test_attribution() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "Hello");

    let items: Vec<_> = doc.iter_visible().collect();
    let attributions = AttributionEngine::compute(items.into_iter());

    assert_eq!(attributions.len(), 1);
    assert!((attributions[0].proportion - 1.0).abs() < 0.001);
}

#[test]
fn test_multi_author_attribution() {
    let alice = TestUser::new("Alice", 1);
    let bob = TestUser::new("Bob", 2);

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Hello ");
    let change_a = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&change_a);

    doc_b.insert(6, "World");
    let change_b = doc_b.commit_change().unwrap();
    doc_a.integrate_change(&change_b);

    let items: Vec<_> = doc_a.iter_visible().collect();
    let attributions = AttributionEngine::compute(items.into_iter());

    assert_eq!(attributions.len(), 2, "Should have 2 authors");
    let total: f64 = attributions.iter().map(|a| a.proportion).sum();
    assert!((total - 1.0).abs() < 0.001, "Proportions should sum to 1.0");
}

#[test]
fn test_branching() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    doc.insert(0, "Original");
    let _ = doc.commit_change();

    doc.create_branch("draft-v2".to_string());
    assert!(doc.get_branch("draft-v2").is_some());

    {
        let branch = doc.get_branch_mut("draft-v2").unwrap();
        branch.insert(8, " - edited");
        assert_eq!(branch.to_string(), "Original - edited");
    }

    assert_eq!(doc.to_string(), "Original");
}

#[test]
fn test_state_vector_dominance() {
    let alice = TestUser::new("Alice", 1);
    let bob = TestUser::new("Bob", 2);

    let mut sv1 = StateVector::new();
    sv1.set(alice.site, 5);
    sv1.set(bob.site, 3);

    let mut sv2 = StateVector::new();
    sv2.set(alice.site, 3);

    assert!(sv1.dominates(&sv2));
    assert!(!sv2.dominates(&sv1));
}

#[test]
fn test_stress_many_inserts() {
    let user = TestUser::new("Alice", 1);
    let mut doc = user.make_doc();
    let text = "abcdefghijklmnopqrstuvwxyz";
    for (i, ch) in text.chars().enumerate() {
        doc.insert(i, ch.to_string());
    }
    assert_eq!(doc.to_string(), text);
}

#[test]
fn test_stress_concurrent_typing() {
    let users: Vec<TestUser> = (1..=5).map(|i| TestUser::new(&format!("User{}", i), i)).collect();
    let mut docs: Vec<Document> = users.iter().map(|u| u.make_doc()).collect();

    for round in 0..10u8 {
        let mut changes = Vec::new();
        for doc in &mut docs {
            doc.insert(round as usize, format!("{}", round));
            if let Some(change) = doc.commit_change() {
                changes.push(change);
            }
        }

        for doc in &mut docs {
            for change in &changes {
                doc.integrate_change(change);
            }
        }
    }

    let texts: Vec<String> = docs.iter().map(|d| d.to_string()).collect();
    for i in 1..texts.len() {
        assert_eq!(texts[0], texts[i],
            "All documents must converge after 10 rounds. Doc0='{}', Doc{}='{}'",
            texts[0], i, texts[i]);
    }
}
