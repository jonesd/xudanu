use xudanu_types::*;

fn make_site(id: u8) -> SiteId {
    let mut bytes = [0u8; 32];
    bytes[0] = id;
    SiteId::from_bytes(bytes)
}

// ── ItemId ──

#[test]
fn test_item_id_equality() {
    let site = make_site(1);
    let id1 = ItemId::new(site, 1);
    let id2 = ItemId::new(site, 1);
    let id3 = ItemId::new(site, 2);

    assert_eq!(id1, id2);
    assert_ne!(id1, id3);
}

#[test]
fn test_item_id_ordering() {
    let site = make_site(1);
    let id1 = ItemId::new(site, 1);
    let id2 = ItemId::new(site, 2);

    assert!(id1 < id2);
}

#[test]
fn test_sentinel_item() {
    let site = make_site(1);
    let sentinel = ItemId::sentinel_start(site);
    assert!(sentinel.is_sentinel());
    assert_eq!(sentinel.clock, 0);
}

// ── SiteId ──

#[test]
fn test_site_id_from_bytes() {
    let bytes = [42u8; 32];
    let site = SiteId::from_bytes(bytes);
    assert_eq!(*site.as_bytes(), bytes);
}

#[test]
fn test_site_id_display() {
    let mut bytes = [0u8; 32];
    bytes[0] = 0xAB;
    bytes[1] = 0xCD;
    let site = SiteId::from_bytes(bytes);
    let display = format!("{}", site);
    assert!(!display.is_empty());
}

#[test]
fn test_site_id_short() {
    let mut bytes = [0u8; 32];
    bytes[0] = 0xFF;
    let site = SiteId::from_bytes(bytes);
    let short = site.short();
    assert_eq!(short.len(), 8); // 4 bytes = 8 hex chars
}

// ── ItemContent ──

#[test]
fn test_plain_text_content() {
    let content = ItemContent::plain("Hello");
    assert_eq!(content.text(), Some("Hello"));
    assert_eq!(content.len(), 5);
    assert!(content.marks().is_empty());
}

#[test]
fn test_styled_text_content() {
    let mark = Mark {
        mark_type: MarkType::Bold,
        attributes: Default::default(),
    };
    let content = ItemContent::styled("Bold text", vec![mark.clone()]);
    assert_eq!(content.text(), Some("Bold text"));
    assert_eq!(content.marks().len(), 1);
}

#[test]
fn test_content_empty() {
    let content = ItemContent::plain("");
    assert!(content.is_empty());
    let content = ItemContent::plain("x");
    assert!(!content.is_empty());
}

#[test]
fn test_block_content() {
    let block = ItemContent::BlockStart(BlockType::Heading { level: 2 });
    assert!(block.text().is_none());
    assert_eq!(block.len(), 1);
}

// ── HybridTimestamp ──

#[test]
fn test_timestamp_now() {
    let ts = HybridTimestamp::now(5);
    assert_eq!(ts.lamport, 5);
    assert!(ts.wall_secs > 0);
}

#[test]
fn test_timestamp_ordering() {
    let ts1 = HybridTimestamp { lamport: 1, wall_secs: 100, wall_nanos: 0 };
    let ts2 = HybridTimestamp { lamport: 2, wall_secs: 100, wall_nanos: 0 };
    let ts3 = HybridTimestamp { lamport: 1, wall_secs: 200, wall_nanos: 0 };

    assert!(ts1 < ts2);
    assert!(ts1 < ts3);
    assert!(ts2 > ts1);
}

#[test]
fn test_timestamp_merge() {
    let ts1 = HybridTimestamp { lamport: 5, wall_secs: 100, wall_nanos: 0 };
    let ts2 = HybridTimestamp { lamport: 3, wall_secs: 200, wall_nanos: 0 };
    let merged = ts1.merge(&ts2);

    assert!(merged.lamport > ts1.lamport);
    assert!(merged.lamport > ts2.lamport);
    assert_eq!(merged.wall_secs, 200);
}

// ── Change hash determinism ──

#[test]
fn test_change_hash_deterministic() {
    let site = make_site(1);
    let author: AuthorId = [1u8; 32];
    let ts = HybridTimestamp { lamport: 1, wall_secs: 0, wall_nanos: 0 };

    let change1 = Change::unsigned(author, site, vec![], vec![], ts, 1);
    let change2 = Change::unsigned(author, site, vec![], vec![], ts, 1);

    assert_eq!(change1.id, change2.id, "Same inputs must produce same hash");
}

#[test]
fn test_change_hash_differs_for_different_ops() {
    let site = make_site(1);
    let author: AuthorId = [1u8; 32];
    let ts = HybridTimestamp { lamport: 1, wall_secs: 0, wall_nanos: 0 };

    let op1 = Op::Insert {
        id: ItemId::new(site, 1),
        left_id: None,
        right_id: None,
        content: ItemContent::plain("A"),
        author,
    };
    let op2 = Op::Insert {
        id: ItemId::new(site, 1),
        left_id: None,
        right_id: None,
        content: ItemContent::plain("B"),
        author,
    };

    let change1 = Change::unsigned(author, site, vec![], vec![op1], ts, 1);
    let change2 = Change::unsigned(author, site, vec![], vec![op2], ts, 1);

    assert_ne!(change1.id, change2.id, "Different ops must produce different hashes");
}

// ── Change signing payload ──

#[test]
fn test_signing_payload_deterministic() {
    let site = make_site(1);
    let author: AuthorId = [1u8; 32];
    let ts = HybridTimestamp { lamport: 1, wall_secs: 0, wall_nanos: 0 };

    let change1 = Change::unsigned(author, site, vec![], vec![], ts, 1);
    let change2 = Change::unsigned(author, site, vec![], vec![], ts, 1);

    assert_eq!(change1.signing_payload(), change2.signing_payload());
}

// ── Span ──

#[test]
fn test_span_creation() {
    let site = make_site(1);
    let span = Span::new(ItemId::new(site, 1), ItemId::new(site, 5));
    assert_eq!(span.start, ItemId::new(site, 1));
    assert_eq!(span.end, ItemId::new(site, 5));
}

#[test]
fn test_span_ref_at_version() {
    let site = make_site(1);
    let span = Span::new(ItemId::new(site, 1), ItemId::new(site, 5));
    let doc_id: DocumentId = [1u8; 32];
    let version: ChangeHash = [2u8; 32];

    let span_ref = SpanRef::at_version(doc_id, span.clone(), version);
    assert_eq!(span_ref.document_id, doc_id);
    assert_eq!(span_ref.version, Some(version));
}

#[test]
fn test_span_ref_at_latest() {
    let site = make_site(1);
    let span = Span::new(ItemId::new(site, 1), ItemId::new(site, 5));
    let doc_id: DocumentId = [1u8; 32];

    let span_ref = SpanRef::at_latest(doc_id, span);
    assert!(span_ref.version.is_none());
}

// ── Serialization roundtrips ──

#[test]
fn test_change_serialization_roundtrip() {
    let site = make_site(1);
    let author: AuthorId = [1u8; 32];
    let ts = HybridTimestamp { lamport: 1, wall_secs: 0, wall_nanos: 0 };

    let original = Change::unsigned(author, site, vec![], vec![], ts, 1);
    let serialized = bincode::serialize(&original).unwrap();
    let deserialized: Change = bincode::deserialize(&serialized).unwrap();

    assert_eq!(original.id, deserialized.id);
    assert_eq!(original.actor, deserialized.actor);
    assert_eq!(original.site, deserialized.site);
    assert_eq!(original.lamport, deserialized.lamport);
}

#[test]
fn test_op_serialization_roundtrip() {
    let site = make_site(1);
    let author: AuthorId = [1u8; 32];

    let original = Op::Insert {
        id: ItemId::new(site, 1),
        left_id: Some(ItemId::new(site, 0)),
        right_id: None,
        content: ItemContent::plain("Hello"),
        author,
    };

    let serialized = bincode::serialize(&original).unwrap();
    let deserialized: Op = bincode::deserialize(&serialized).unwrap();

    match (&original, &deserialized) {
        (Op::Insert { id: id1, .. }, Op::Insert { id: id2, .. }) => {
            assert_eq!(id1, id2);
        }
        _ => panic!("Type mismatch"),
    }
}

#[test]
fn test_item_content_serialization() {
    let contents = vec![
        ItemContent::plain("Hello"),
        ItemContent::BlockStart(BlockType::Paragraph),
        ItemContent::BlockEnd,
    ];

    for original in contents {
        let serialized = bincode::serialize(&original).unwrap();
        let deserialized: ItemContent = bincode::deserialize(&serialized).unwrap();
        assert_eq!(original.text(), deserialized.text());
    }
}

#[test]
fn test_hybrid_timestamp_serialization() {
    let original = HybridTimestamp { lamport: 42, wall_secs: 1700000000, wall_nanos: 12345 };
    let serialized = bincode::serialize(&original).unwrap();
    let deserialized: HybridTimestamp = bincode::deserialize(&serialized).unwrap();
    assert_eq!(original, deserialized);
}

#[test]
fn test_site_id_serialization() {
    let original = make_site(42);
    let serialized = bincode::serialize(&original).unwrap();
    let deserialized: SiteId = bincode::deserialize(&serialized).unwrap();
    assert_eq!(original, deserialized);
}

#[test]
fn test_item_id_serialization() {
    let original = ItemId::new(make_site(1), 42);
    let serialized = bincode::serialize(&original).unwrap();
    let deserialized: ItemId = bincode::deserialize(&serialized).unwrap();
    assert_eq!(original, deserialized);
}

// ── Mark types ──

#[test]
fn test_mark_types() {
    let marks = vec![
        MarkType::Bold,
        MarkType::Italic,
        MarkType::Underline,
        MarkType::Strikethrough,
        MarkType::Link { href: "https://example.com".to_string() },
        MarkType::Code,
        MarkType::Custom("highlight".to_string()),
    ];

    for mark_type in marks {
        let mark = Mark { mark_type, attributes: Default::default() };
        let serialized = bincode::serialize(&mark).unwrap();
        let deserialized: Mark = bincode::deserialize(&serialized).unwrap();
        assert_eq!(bincode::serialize(&mark).unwrap(), serialized);
    }
}

#[test]
fn test_block_types() {
    let blocks = vec![
        BlockType::Paragraph,
        BlockType::Heading { level: 1 },
        BlockType::Heading { level: 3 },
        BlockType::CodeBlock { language: Some("rust".to_string()) },
        BlockType::CodeBlock { language: None },
        BlockType::BlockQuote,
        BlockType::List { ordered: true },
        BlockType::List { ordered: false },
        BlockType::ListItem,
        BlockType::Divider,
        BlockType::Custom("callout".to_string()),
    ];

    for block in blocks {
        let serialized = bincode::serialize(&block).unwrap();
        let deserialized: BlockType = bincode::deserialize(&serialized).unwrap();
        assert_eq!(bincode::serialize(&deserialized).unwrap(), serialized);
    }
}
