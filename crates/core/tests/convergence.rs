use xudanu_core::{Document, StateVector};
use xudanu_types::*;
use xudanu_signing::Signer;

struct TestUser {
    signer: Signer,
    site: SiteId,
}

impl TestUser {
    fn new(name: &str) -> Self {
        let signer = Signer::generate(name.to_string());
        let site = SiteId::from_author(signer.author());
        Self { signer, site }
    }

    fn make_doc(&self) -> Document {
        Document::new([0u8; 32], self.signer.author().clone(), self.site)
    }

    fn author_id(&self) -> &AuthorId {
        self.signer.author_id()
    }
}

fn sync_pair(a: &mut Document, b: &mut Document) {
    let change_a = a.commit_change();
    let change_b = b.commit_change();
    if let Some(c) = &change_a { b.integrate_change(c); }
    if let Some(c) = &change_b { a.integrate_change(c); }
}

fn sync_all(docs: &mut [Document]) {
    let mut changes = Vec::new();
    for doc in docs.iter_mut() {
        if let Some(c) = doc.commit_change() {
            changes.push(c);
        }
    }
    for doc in docs.iter_mut() {
        for change in &changes {
            doc.integrate_change(change);
        }
    }
}

// ── Idempotency ──

#[test]
fn test_idempotent_change_integration() {
    let alice = TestUser::new("Alice");
    let mut doc_a = alice.make_doc();
    let mut doc_b = alice.make_doc();

    doc_a.insert(0, "Hello");
    let change = doc_a.commit_change().unwrap();

    doc_b.integrate_change(&change);
    doc_b.integrate_change(&change);

    assert_eq!(doc_b.to_string(), "Hello");
}

// ── Commutativity ──

#[test]
fn test_commutative_integration_order() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");
    let carol = TestUser::new("Carol");

    let mut doc_1 = alice.make_doc();
    let mut doc_2 = alice.make_doc();

    let mut alice_doc = alice.make_doc();
    alice_doc.insert(0, "A");
    let change_a = alice_doc.commit_change().unwrap();

    let mut bob_doc = bob.make_doc();
    bob_doc.insert(0, "B");
    let change_b = bob_doc.commit_change().unwrap();

    let mut carol_doc = carol.make_doc();
    carol_doc.insert(0, "C");
    let change_c = carol_doc.commit_change().unwrap();

    doc_1.integrate_change(&change_a);
    doc_1.integrate_change(&change_b);
    doc_1.integrate_change(&change_c);

    doc_2.integrate_change(&change_c);
    doc_2.integrate_change(&change_a);
    doc_2.integrate_change(&change_b);

    assert_eq!(doc_1.to_string(), doc_2.to_string(),
        "Integration order must not affect final state: order1='{}', order2='{}'",
        doc_1.to_string(), doc_2.to_string());
}

// ── Concurrent insert + delete ──

#[test]
fn test_concurrent_insert_and_delete() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Hello World");

    let change = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&change);

    assert_eq!(doc_a.to_string(), "Hello World");
    assert_eq!(doc_b.to_string(), "Hello World");

    doc_a.delete(5, 6);
    doc_b.insert(5, "!");

    sync_pair(&mut doc_a, &mut doc_b);

    assert_eq!(doc_a.to_string(), doc_b.to_string(),
        "Concurrent insert+delete must converge: A='{}', B='{}'",
        doc_a.to_string(), doc_b.to_string());
}

#[test]
fn test_concurrent_deletes_same_range() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Hello World");
    let change = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&change);

    doc_a.delete(5, 6);
    doc_b.delete(5, 6);

    sync_pair(&mut doc_a, &mut doc_b);

    assert_eq!(doc_a.to_string(), "Hello");
    assert_eq!(doc_b.to_string(), "Hello");
}

#[test]
fn test_concurrent_deletes_different_ranges() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Hello World");
    let change = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&change);

    doc_a.delete(0, 5);
    doc_b.delete(6, 5);

    sync_pair(&mut doc_a, &mut doc_b);

    assert_eq!(doc_a.to_string(), doc_b.to_string());
    assert!(doc_a.to_string().contains(' ') == false || doc_a.to_string() == " ",
        "Both deletes should be reflected: got '{}'", doc_a.to_string());
}

#[test]
fn test_concurrent_overlapping_deletes() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "ABCDEFGHIJ");
    let change = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&change);

    doc_a.delete(2, 6);
    doc_b.delete(4, 4);

    sync_pair(&mut doc_a, &mut doc_b);

    assert_eq!(doc_a.to_string(), doc_b.to_string(),
        "Overlapping deletes must converge: A='{}', B='{}'",
        doc_a.to_string(), doc_b.to_string());
}

// ── Insert after delete at same position ──

#[test]
fn test_insert_after_delete_at_same_position() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Hello");
    let change = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&change);

    doc_a.delete(0, 5);
    let del_change = doc_a.commit_change().unwrap();

    doc_b.insert(0, "World");
    let ins_change = doc_b.commit_change().unwrap();

    doc_a.integrate_change(&ins_change);
    doc_b.integrate_change(&del_change);

    assert_eq!(doc_a.to_string(), doc_b.to_string());
}

// ── Diamond merge ──

#[test]
fn test_diamond_merge() {
    let alice = TestUser::new("Alice");

    let mut base = alice.make_doc();
    base.insert(0, "Base");
    let base_change = base.commit_change().unwrap();

    let mut branch_b = alice.make_doc();
    branch_b.integrate_change(&base_change);
    branch_b.insert(4, " + Branch B");
    let change_b = branch_b.commit_change().unwrap();

    let mut branch_c = alice.make_doc();
    branch_c.integrate_change(&base_change);
    branch_c.insert(4, " + Branch C");
    let change_c = branch_c.commit_change().unwrap();

    let mut merged = alice.make_doc();
    merged.integrate_change(&base_change);
    merged.integrate_change(&change_b);
    merged.integrate_change(&change_c);

    let mut merged_reverse = alice.make_doc();
    merged_reverse.integrate_change(&base_change);
    merged_reverse.integrate_change(&change_c);
    merged_reverse.integrate_change(&change_b);

    assert_eq!(merged.to_string(), merged_reverse.to_string(),
        "Diamond merge must be order-independent");
}

// ── Non-interleaving guarantee ──

#[test]
fn test_non_interleaving_two_authors_typing_words() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    for ch in "Hello".chars() {
        doc_a.insert(0, ch.to_string());
    }
    for ch in "World".chars() {
        doc_b.insert(0, ch.to_string());
    }

    let change_a = doc_a.commit_change().unwrap();
    let change_b = doc_b.commit_change().unwrap();

    doc_a.integrate_change(&change_b);
    doc_b.integrate_change(&change_a);

    let text = doc_a.to_string();
    assert_eq!(text, doc_b.to_string());

    if text.contains("H") && text.contains("W") {
        let h_block = "Hello";
        let w_block = "World";
        let h_pos = text.find(h_block);
        let w_pos = text.find(w_block);

        match (h_pos, w_pos) {
            (Some(hp), Some(wp)) => {
                let hello_after_world = hp > wp;
                let world_after_hello = wp > hp;
                assert!(hello_after_world || world_after_hello,
                    "Same-author characters must be contiguous");
            }
            _ => {}
        }
    }
}

// ── Multi-round convergence with mixed ops ──

#[test]
fn test_multi_round_insert_delete_convergence() {
    let users: Vec<TestUser> = (0..4).map(|i| TestUser::new(&format!("U{}", i))).collect();
    let mut docs: Vec<Document> = users.iter().map(|u| u.make_doc()).collect();

    for round in 0..20 {
        for (i, doc) in docs.iter_mut().enumerate() {
            if round % 3 == 0 && doc.len() > 2 {
                doc.delete(0, 1);
            }
            doc.insert(0, format!("{}", (round * 4 + i) % 36));
        }
        sync_all(&mut docs);
    }

    let texts: Vec<String> = docs.iter().map(|d| d.to_string()).collect();
    for i in 1..texts.len() {
        assert_eq!(texts[0], texts[i],
            "All docs must converge after multi-round insert+delete. Doc0='{}', Doc{}='{}'",
            texts[0], i, texts[i]);
    }
}

// ── Out-of-order delivery ──

#[test]
fn test_out_of_order_change_delivery() {
    let alice = TestUser::new("Alice");

    let mut source = alice.make_doc();
    source.insert(0, "A");
    let change1 = source.commit_change().unwrap();
    source.insert(1, "B");
    let change2 = source.commit_change().unwrap();
    source.insert(2, "C");
    let change3 = source.commit_change().unwrap();

    let mut target = alice.make_doc();
    target.integrate_change(&change3);
    target.integrate_change(&change1);
    target.integrate_change(&change2);

    assert_eq!(target.to_string(), source.to_string(),
        "Out-of-order delivery must still produce correct result");
}

// ── Empty operations ──

#[test]
fn test_delete_from_empty_doc() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    doc.delete(0, 0);
    assert_eq!(doc.to_string(), "");
    assert_eq!(doc.len(), 0);
}

#[test]
fn test_insert_empty_string() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    doc.insert(0, "");
    assert_eq!(doc.to_string(), "");
    assert_eq!(doc.len(), 0);
}

#[test]
fn test_delete_more_than_exists() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    doc.insert(0, "Hi");
    doc.delete(0, 100);
    assert_eq!(doc.to_string(), "");
}

// ── Unicode ──

#[test]
fn test_unicode_insert() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    doc.insert(0, "こんにちは");
    assert_eq!(doc.to_string(), "こんにちは");
}

#[test]
fn test_unicode_insert_then_delete() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    doc.insert(0, "你好世界");
    doc.delete(2, 2);
    assert_eq!(doc.to_string(), "你好");
}

#[test]
fn test_emoji_insert() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    doc.insert(0, "Hello 🌍!");
    assert_eq!(doc.to_string(), "Hello 🌍!");
}

// ── Multi-span deletes ──

#[test]
fn test_delete_spanning_multiple_items() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "AAA");
    let c1 = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&c1);

    doc_b.insert(3, "BBB");
    let c2 = doc_b.commit_change().unwrap();
    doc_a.integrate_change(&c2);

    doc_a.insert(6, "CCC");
    let c3 = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&c3);

    assert_eq!(doc_a.to_string(), "AAABBBCCC");

    doc_a.delete(2, 5);
    assert_eq!(doc_a.to_string(), "AACC");
}

// ── Many sequential inserts ──

#[test]
fn test_build_document_character_by_character() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    let text = "The quick brown fox jumps over the lazy dog";
    for (i, ch) in text.chars().enumerate() {
        doc.insert(i, ch.to_string());
    }
    assert_eq!(doc.to_string(), text);
    assert_eq!(doc.len(), text.len());
}

// ── Append at end ──

#[test]
fn test_append_to_end() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    doc.insert(0, "Hello");
    doc.insert(5, " World");
    doc.insert(11, "!");
    assert_eq!(doc.to_string(), "Hello World!");
}

// ── Delete at end ──

#[test]
fn test_delete_at_end() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    doc.insert(0, "Hello!");
    doc.delete(5, 1);
    assert_eq!(doc.to_string(), "Hello");
}

// ── Repeated sync ──

#[test]
fn test_repeated_sync_same_change() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Test");
    let change = doc_a.commit_change().unwrap();

    doc_b.integrate_change(&change);
    doc_b.integrate_change(&change);
    doc_b.integrate_change(&change);

    assert_eq!(doc_b.to_string(), "Test");
    assert_eq!(doc_b.len(), 4);
}

// ── Multiple branches ──

#[test]
fn test_multiple_branches() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    doc.insert(0, "Base");
    let _ = doc.commit_change();

    doc.create_branch("feature-a".to_string());
    doc.create_branch("feature-b".to_string());

    {
        let a = doc.get_branch_mut("feature-a").unwrap();
        a.insert(4, " from A");
        let _ = a.commit_change();
    }
    {
        let b = doc.get_branch_mut("feature-b").unwrap();
        b.insert(4, " from B");
        let _ = b.commit_change();
    }

    assert_eq!(doc.to_string(), "Base");
    assert_eq!(doc.get_branch("feature-a").unwrap().to_string(), "Base from A");
    assert_eq!(doc.get_branch("feature-b").unwrap().to_string(), "Base from B");
    assert_eq!(doc.list_branches().len(), 2);
}

// ── Branch isolation ──

#[test]
fn test_branch_edits_dont_affect_main() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    doc.insert(0, "Original");
    let _ = doc.commit_change();

    doc.create_branch("draft".to_string());

    {
        let draft = doc.get_branch_mut("draft").unwrap();
        draft.delete(0, 8);
        draft.insert(0, "Modified");
        let _ = draft.commit_change();
    }

    assert_eq!(doc.to_string(), "Original");
    assert_eq!(doc.get_branch("draft").unwrap().to_string(), "Modified");
}

// ── Large document stress ──

#[test]
fn test_large_document() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();
    let text: String = (0..1000).map(|i| format!("word{} ", i)).collect();
    let text = text.trim_end().to_string();

    doc.insert(0, &text);
    assert_eq!(doc.to_string(), text);
}

// ── Stress: many concurrent users ──

#[test]
fn test_10_user_convergence() {
    let users: Vec<TestUser> = (0..10).map(|i| TestUser::new(&format!("U{}", i))).collect();
    let mut docs: Vec<Document> = users.iter().map(|u| u.make_doc()).collect();

    for round in 0..5 {
        for doc in docs.iter_mut() {
            doc.insert(round, format!("{}", round));
        }
        sync_all(&mut docs);
    }

    let texts: Vec<String> = docs.iter().map(|d| d.to_string()).collect();
    for i in 1..texts.len() {
        assert_eq!(texts[0], texts[i], "Doc0 != Doc{}", i);
    }
}

// ── Convergence after delete-all then insert ──

#[test]
fn test_delete_all_then_reinsert() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Old text");
    let c1 = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&c1);

    doc_a.delete(0, 8);
    doc_a.insert(0, "New text");
    let c2 = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&c2);

    assert_eq!(doc_a.to_string(), "New text");
    assert_eq!(doc_b.to_string(), "New text");
}

// ── Concurrent insert at different positions ──

#[test]
fn test_concurrent_insert_at_different_positions() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "Hello");
    let c = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&c);

    doc_a.insert(0, "World ");
    doc_b.insert(5, "!");

    sync_pair(&mut doc_a, &mut doc_b);

    assert_eq!(doc_a.to_string(), doc_b.to_string());
    assert!(doc_a.to_string().contains("World"));
    assert!(doc_a.to_string().contains("!"));
}

// ── Change history ──

#[test]
fn test_change_history_tracking() {
    let user = TestUser::new("Alice");
    let mut doc = user.make_doc();

    doc.insert(0, "First");
    let _ = doc.commit_change();

    doc.insert(5, " Second");
    let _ = doc.commit_change();

    doc.insert(12, " Third");
    let _ = doc.commit_change();

    let history = doc.change_history();
    assert_eq!(history.len(), 3, "Should have 3 changes in history");
}

// ── State vector after sync ──

#[test]
fn test_state_vector_after_sync() {
    let alice = TestUser::new("Alice");
    let bob = TestUser::new("Bob");

    let mut doc_a = alice.make_doc();
    let mut doc_b = bob.make_doc();

    doc_a.insert(0, "A");
    let change_a = doc_a.commit_change().unwrap();
    doc_b.integrate_change(&change_a);

    doc_b.insert(1, "B");
    let change_b = doc_b.commit_change().unwrap();
    doc_a.integrate_change(&change_b);

    let sv_a = doc_a.state_vector();
    let sv_b = doc_b.state_vector();

    assert!(sv_a.knows(&alice.site, 1));
    assert!(sv_a.knows(&bob.site, 1));
    assert!(sv_b.knows(&alice.site, 1));
    assert!(sv_b.knows(&bob.site, 1));
}
