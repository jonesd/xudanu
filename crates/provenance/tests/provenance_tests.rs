use xudanu_provenance::{AttributionEngine, RoyaltyEntry, RoyaltyLedger, RoyaltySource};
use xudanu_types::*;

fn make_author(id: u8) -> AuthorId {
    let mut bytes = [0u8; 32];
    bytes[0] = id;
    bytes
}

fn make_doc_id(id: u8) -> DocumentId {
    let mut bytes = [0u8; 32];
    bytes[0] = id;
    bytes
}

// ── Attribution Engine ──

#[test]
fn test_empty_input() {
    let items: Vec<(&ItemId, &ItemContent, &AuthorId)> = vec![];
    let attributions = AttributionEngine::compute(items.into_iter());
    assert!(attributions.is_empty());
}

#[test]
fn test_single_author_single_item() {
    let author = make_author(1);
    let site = SiteId::from_bytes(author);
    let content = ItemContent::plain("Hello");
    let id = ItemId::new(site, 1);

    let items: Vec<(&ItemId, &ItemContent, &AuthorId)> = vec![(&id, &content, &author)];
    let attributions = AttributionEngine::compute(items.into_iter());

    assert_eq!(attributions.len(), 1);
    assert_eq!(attributions[0].author, author);
    assert_eq!(attributions[0].byte_count, 5);
    assert!((attributions[0].proportion - 1.0).abs() < 0.001);
}

#[test]
fn test_two_authors_equal_contribution() {
    let author_a = make_author(1);
    let author_b = make_author(2);
    let site_a = SiteId::from_bytes(author_a);
    let site_b = SiteId::from_bytes(author_b);

    let content_a = ItemContent::plain("AAAA");
    let content_b = ItemContent::plain("BBBB");
    let id_a = ItemId::new(site_a, 1);
    let id_b = ItemId::new(site_b, 1);

    let items: Vec<(&ItemId, &ItemContent, &AuthorId)> = vec![
        (&id_a, &content_a, &author_a),
        (&id_b, &content_b, &author_b),
    ];
    let attributions = AttributionEngine::compute(items.into_iter());

    assert_eq!(attributions.len(), 2);
    assert!((attributions[0].proportion - 0.5).abs() < 0.001);
    assert!((attributions[1].proportion - 0.5).abs() < 0.001);
}

#[test]
fn test_three_authors_proportions() {
    let a1 = make_author(1);
    let a2 = make_author(2);
    let a3 = make_author(3);
    let s1 = SiteId::from_bytes(a1);
    let s2 = SiteId::from_bytes(a2);
    let s3 = SiteId::from_bytes(a3);

    let c1 = ItemContent::plain("AAAA"); // 4
    let c2 = ItemContent::plain("BB"); // 2
    let c3 = ItemContent::plain("CCCCCC"); // 6

    let id1 = ItemId::new(s1, 1);
    let id2 = ItemId::new(s2, 1);
    let id3 = ItemId::new(s3, 1);

    let items: Vec<(&ItemId, &ItemContent, &AuthorId)> =
        vec![(&id1, &c1, &a1), (&id2, &c2, &a2), (&id3, &c3, &a3)];
    let attributions = AttributionEngine::compute(items.into_iter());

    assert_eq!(attributions.len(), 3);
    let total: f64 = attributions.iter().map(|a| a.proportion).sum();
    assert!((total - 1.0).abs() < 0.001, "Proportions must sum to 1.0");

    assert!(
        (attributions[0].proportion - 0.5).abs() < 0.001,
        "Largest author first: got {}",
        attributions[0].proportion
    );
    assert!(
        (attributions[1].proportion - 1.0 / 3.0).abs() < 0.001,
        "Second largest: got {}",
        attributions[1].proportion
    );
    assert!(
        (attributions[2].proportion - 1.0 / 6.0).abs() < 0.001,
        "Smallest last: got {}",
        attributions[2].proportion
    );
}

#[test]
fn test_attribution_sorted_by_byte_count() {
    let a1 = make_author(1);
    let a2 = make_author(2);
    let s1 = SiteId::from_bytes(a1);
    let s2 = SiteId::from_bytes(a2);

    let c1 = ItemContent::plain("A");
    let c2 = ItemContent::plain("BBBBB");
    let id1 = ItemId::new(s1, 1);
    let id2 = ItemId::new(s2, 1);

    let items: Vec<(&ItemId, &ItemContent, &AuthorId)> = vec![(&id1, &c1, &a1), (&id2, &c2, &a2)];
    let attributions = AttributionEngine::compute(items.into_iter());

    assert_eq!(attributions[0].byte_count, 5);
    assert_eq!(attributions[1].byte_count, 1);
}

// ── Royalty Ledger ──

#[test]
fn test_empty_ledger() {
    let ledger = RoyaltyLedger::new();
    assert_eq!(ledger.summary().len(), 0);
}

#[test]
fn test_add_original_entry() {
    let mut ledger = RoyaltyLedger::new();
    let author = make_author(1);
    let doc = make_doc_id(1);

    ledger.add_entry(RoyaltyEntry {
        document_id: doc,
        author,
        byte_count: 100,
        source: RoyaltySource::Original,
    });

    let total = ledger.author_total(&author).unwrap();
    assert_eq!(total.total_bytes, 100);
    assert_eq!(total.original_bytes, 100);
    assert_eq!(total.transcluded_bytes, 0);
    assert_eq!(total.derived_bytes, 0);
}

#[test]
fn test_mixed_sources() {
    let mut ledger = RoyaltyLedger::new();
    let author = make_author(1);
    let doc = make_doc_id(1);
    let source_doc = make_doc_id(2);

    ledger.add_entry(RoyaltyEntry {
        document_id: doc,
        author,
        byte_count: 100,
        source: RoyaltySource::Original,
    });

    let site = SiteId::from_bytes(author);
    let span = Span::new(ItemId::new(site, 1), ItemId::new(site, 5));
    let span_ref = SpanRef::at_latest(source_doc, span);

    ledger.add_entry(RoyaltyEntry {
        document_id: doc,
        author,
        byte_count: 50,
        source: RoyaltySource::Transcluded {
            from_document: source_doc,
            span_ref,
        },
    });

    let total = ledger.author_total(&author).unwrap();
    assert_eq!(total.total_bytes, 150);
    assert_eq!(total.original_bytes, 100);
    assert_eq!(total.transcluded_bytes, 50);
}

#[test]
fn test_author_proportion() {
    let mut ledger = RoyaltyLedger::new();
    let a1 = make_author(1);
    let a2 = make_author(2);
    let doc = make_doc_id(1);

    ledger.add_entry(RoyaltyEntry {
        document_id: doc,
        author: a1,
        byte_count: 75,
        source: RoyaltySource::Original,
    });

    ledger.add_entry(RoyaltyEntry {
        document_id: doc,
        author: a2,
        byte_count: 25,
        source: RoyaltySource::Original,
    });

    assert!((ledger.author_proportion(&a1) - 0.75).abs() < 0.001);
    assert!((ledger.author_proportion(&a2) - 0.25).abs() < 0.001);
    assert!((ledger.author_proportion(&make_author(99)) - 0.0).abs() < 0.001);
}

#[test]
fn test_entries_for_document() {
    let mut ledger = RoyaltyLedger::new();
    let doc1 = make_doc_id(1);
    let doc2 = make_doc_id(2);
    let author = make_author(1);

    ledger.add_entry(RoyaltyEntry {
        document_id: doc1,
        author,
        byte_count: 50,
        source: RoyaltySource::Original,
    });
    ledger.add_entry(RoyaltyEntry {
        document_id: doc1,
        author,
        byte_count: 30,
        source: RoyaltySource::Original,
    });
    ledger.add_entry(RoyaltyEntry {
        document_id: doc2,
        author,
        byte_count: 100,
        source: RoyaltySource::Original,
    });

    assert_eq!(ledger.entries_for_document(&doc1).len(), 2);
    assert_eq!(ledger.entries_for_document(&doc2).len(), 1);
    assert_eq!(ledger.entries_for_document(&make_doc_id(99)).len(), 0);
}

#[test]
fn test_summary_sorted() {
    let mut ledger = RoyaltyLedger::new();
    let doc = make_doc_id(1);

    ledger.add_entry(RoyaltyEntry {
        document_id: doc,
        author: make_author(1),
        byte_count: 10,
        source: RoyaltySource::Original,
    });
    ledger.add_entry(RoyaltyEntry {
        document_id: doc,
        author: make_author(2),
        byte_count: 90,
        source: RoyaltySource::Original,
    });

    let summary = ledger.summary();
    assert_eq!(summary.len(), 2);
    assert!(
        summary[0].1 > summary[1].1,
        "Should be sorted descending by proportion"
    );
}

#[test]
fn test_derived_source() {
    let mut ledger = RoyaltyLedger::new();
    let author = make_author(1);
    let doc = make_doc_id(1);

    ledger.add_entry(RoyaltyEntry {
        document_id: doc,
        author,
        byte_count: 200,
        source: RoyaltySource::Derived {
            from_documents: vec![make_doc_id(2), make_doc_id(3)],
            transform_description: "Summarized and rephrased".to_string(),
        },
    });

    let total = ledger.author_total(&author).unwrap();
    assert_eq!(total.derived_bytes, 200);
    assert_eq!(total.original_bytes, 0);
}
