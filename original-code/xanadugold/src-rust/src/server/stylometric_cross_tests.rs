//! Cross-feature integration tests: NFC × paste-match, NFC × Path/Set,
//! stylometric × NFC, paste-match cross-authorship, Path/Set content.
//!
//! These verify that features built independently actually work together.

use crate::server::Server;
use crate::server::stylometric;
use crate::edition::Edition;
use crate::edition::range_element::RangeElement;

// ═══════════════════════════════════════════════════════════════
// Test helpers
// ═══════════════════════════════════════════════════════════════

fn setup_server_with_works() -> (Server, crate::server::SessionId, Vec<u64>) {
    let mut server = Server::new();
    let session = server.connect();
    server.login_public(session).unwrap();
    (server, session, Vec::new())
}

fn setup_server_with_accented_works() -> (Server, crate::server::SessionId, Vec<u64>) {
    let mut server = Server::new();
    let session = server.connect();
    server.login_public(session).unwrap();

    let work_a = server
        .create_work(session, Edition::from_text(
            "The café on the corner serves excellent café au lait every morning."
        ))
        .unwrap();
    let work_b = server
        .create_work(session, Edition::from_text(
            "A completely different topic about gardening and plants."
        ))
        .unwrap();

    (server, session, vec![work_a, work_b])
}

// ═══════════════════════════════════════════════════════════════
// 1. NFC × paste-match
// ═══════════════════════════════════════════════════════════════

#[test]
fn nfc_paste_match_detects_nfd_paste_of_nfc_source() {
    let (mut server, session, works) = setup_server_with_accented_works();

    // The source work was created with NFC text (containing "café" with
    // precomposed é). Now paste the SAME text but in NFD form (e as
    // base + combining acute accent). After NFC normalisation, both
    // should produce the same content and the paste-match should fire.

    let nfd_text = "The cafe\u{0301} on the corner serves excellent cafe\u{0301} au lait every morning.";

    let result = server
        .paste_match_check(session, nfd_text)
        .unwrap();

    assert!(
        result.is_some(),
        "paste-match should detect NFD text matching NFC source work"
    );
    let card = result.unwrap();
    assert_eq!(
        card.work_id, works[0],
        "the match should point to the NFC-normalised source work"
    );
}

#[test]
fn nfc_edition_hash_is_form_independent() {
    // The same text in NFC and NFD forms should produce the same
    // edition-level content fingerprint because from_text normalises.
    // NFC "café" = c,a,f,U+00E9 ; NFD = c,a,f,e,U+0301
    let nfc_text = "café";
    let nfd_text = "cafe\u{0301}";

    let ed_nfc = Edition::from_text(nfc_text);
    let ed_nfd = Edition::from_text(nfd_text);

    assert_eq!(
        ed_nfc.to_text(),
        ed_nfd.to_text(),
        "NFC and NFD inputs must produce identical stored text"
    );

    // The content fingerprints must also match
    let fp_nfc: Vec<[u8; 32]> = ed_nfc
        .all_entries()
        .iter()
        .map(|(_, c)| c.element.content_fingerprint())
        .collect();
    let fp_nfd: Vec<[u8; 32]> = ed_nfd
        .all_entries()
        .iter()
        .map(|(_, c)| c.element.content_fingerprint())
        .collect();
    assert_eq!(
        fp_nfc, fp_nfd,
        "content fingerprints must be normalisation-independent"
    );
}

// ═══════════════════════════════════════════════════════════════
// 2. NFC × Path/Set
// ═══════════════════════════════════════════════════════════════

#[test]
fn nfc_path_set_work_with_accented_spans() {
    let (mut server, _session, works) = setup_server_with_accented_works();

    // Get the text of the accented work (which is now NFC-normalised)
    let text = server.work_text_fresh(works[0]).unwrap();
    assert!(
        text.contains("café"),
        "the stored text should contain the NFC form of café"
    );

    // Build a Path that references a span from the accented work
    let spans = vec![
        crate::edition::range_element::SpanRef::new(works[0], 0, 10),
        crate::edition::range_element::SpanRef::new(works[1], 0, 10),
    ];
    let path_element = RangeElement::path(spans.clone());
    let set_element = RangeElement::set(spans.clone());

    // The elements should construct successfully with accented works
    assert!(path_element.is_path());
    assert!(set_element.is_set());

    // The fingerprints should be deterministic (same spans → same hash)
    let path_element_2 = RangeElement::path(spans.clone());
    assert_eq!(
        path_element.content_fingerprint(),
        path_element_2.content_fingerprint(),
        "Path fingerprints must be deterministic for the same spans"
    );
}

// ═══════════════════════════════════════════════════════════════
// 3. Stylometric × NFC
// ═══════════════════════════════════════════════════════════════

#[test]
fn stylometric_works_on_nfc_normalised_text() {
    let (mut server, _session, works) = setup_server_with_accented_works();

    // Get the NFC-normalised text from the server
    let text = server.work_text_fresh(works[0]).unwrap();
    assert!(text.contains("café")); // confirm NFC

    // Stylometric analysis should work on it
    let report = stylometric::analyse(&text);
    assert!(report.word_count > 0, "should have words");
    assert!(report.sentence_count >= 1, "should have sentences");
    assert!(
        report.ai_likelihood >= 0.0 && report.ai_likelihood <= 1.0,
        "likelihood must be in [0, 1]"
    );

    // The analysis should be the same whether we pass NFC or NFD input
    let nfd_text = "The cafe\u{0301} on the corner serves excellent cafe\u{0301} au lait every morning.";
    let report_nfd = stylometric::analyse(nfd_text);
    let report_nfc = stylometric::analyse("The café on the corner serves excellent café au lait every morning.");
    // Sentence and word counts should be identical (the combining marks
    // don't affect word/sentence splitting)
    assert_eq!(report_nfd.sentence_count, report_nfc.sentence_count);
    assert_eq!(report_nfd.word_count, report_nfc.word_count);
}

// ═══════════════════════════════════════════════════════════════
// 4. Paste-match: cross-authorship verification
// ═══════════════════════════════════════════════════════════════

#[test]
fn paste_match_reports_source_with_authorship_context() {
    let (mut server, session, works) = setup_server_with_accented_works();

    // Paste text that matches work 0
    let pasted = "The café on the corner serves excellent café au lait every morning.";
    let result = server.paste_match_check(session, pasted).unwrap();

    assert!(result.is_some());
    let card = result.unwrap();

    // The card should identify the source work
    assert_eq!(card.work_id, works[0]);

    // The card should include span information (where the match is)
    assert!(card.span_start <= card.span_end);

    // The card should have a title (from the work)
    // (title may be empty if the work has no title, but the field exists)
    let _title = &card.title;

    // The match should have at least one n-gram window
    assert!(card.windows > 0, "should have matched n-gram windows");
}

// ═══════════════════════════════════════════════════════════════
// 5. Path/Set: content verification
// ═══════════════════════════════════════════════════════════════

#[test]
fn path_element_contains_correct_span_references() {
    let (_server, _session, works) = setup_server_with_accented_works();

    let spans = vec![
        crate::edition::range_element::SpanRef::new(works[0], 0, 20),
        crate::edition::range_element::SpanRef::new(works[1], 5, 15),
        crate::edition::range_element::SpanRef::new(works[0], 30, 45),
    ];

    let path = RangeElement::path(spans.clone());

    // Verify the Path contains exactly the spans we provided
    if let RangeElement::Path { spans: path_spans } = &path {
        assert_eq!(path_spans.len(), 3);
        assert_eq!(path_spans[0].work_id, works[0]);
        assert_eq!(path_spans[0].start, 0);
        assert_eq!(path_spans[0].end, 20);
        assert_eq!(path_spans[1].work_id, works[1]);
        assert_eq!(path_spans[2].work_id, works[0]);
    } else {
        panic!("should be a Path element");
    }
}

#[test]
fn set_element_is_order_insensitive() {
    let (_server, _session, works) = setup_server_with_accented_works();

    let spans_a = vec![
        crate::edition::range_element::SpanRef::new(works[0], 0, 10),
        crate::edition::range_element::SpanRef::new(works[1], 0, 10),
    ];
    let spans_b = vec![
        crate::edition::range_element::SpanRef::new(works[1], 0, 10),
        crate::edition::range_element::SpanRef::new(works[0], 0, 10),
    ];

    let set_a = RangeElement::set(spans_a.clone());
    let set_b = RangeElement::set(spans_b);

    // Sets are order-insensitive: the same spans in different order
    // should produce the same fingerprint
    assert_eq!(
        set_a.content_fingerprint(),
        set_b.content_fingerprint(),
        "Set fingerprints must be order-insensitive"
    );

    // But Paths are order-sensitive: the same spans in different order
    // should produce DIFFERENT fingerprints
    let path_a = RangeElement::path(vec![
        crate::edition::range_element::SpanRef::new(works[0], 0, 10),
        crate::edition::range_element::SpanRef::new(works[1], 0, 10),
    ]);
    let path_b = RangeElement::path(vec![
        crate::edition::range_element::SpanRef::new(works[1], 0, 10),
        crate::edition::range_element::SpanRef::new(works[0], 0, 10),
    ]);
    assert_ne!(
        path_a.content_fingerprint(),
        path_b.content_fingerprint(),
        "Path fingerprints must be order-sensitive"
    );
}

// ═══════════════════════════════════════════════════════════════
// 6. Full integration: the agent accountability loop
// ═══════════════════════════════════════════════════════════════

#[test]
fn full_loop_nfc_sign_paste_detect_stylometric() {
    let (mut server, session, works) = setup_server_with_accented_works();

    // Step 1: the stored text is NFC-normalised
    let stored = server.work_text_fresh(works[0]).unwrap();
    assert!(stored.contains("café"), "stored text should be NFC");

    // Step 2: the text has provenance (signed)
    let edition = server.work_edition(works[0]).unwrap();
    assert!(
        !edition.span_provenance.is_empty(),
        "the work should have span provenance"
    );

    // Step 3: paste the same text in NFD form — paste-match should fire
    let nfd_paste = "The cafe\u{0301} on the corner serves excellent cafe\u{0301} au lait every morning.";
    let match_result = server.paste_match_check(session, nfd_paste).unwrap();
    assert!(
        match_result.is_some(),
        "paste-match should fire even with NFD input (normalised before matching)"
    );

    // Step 4: stylometric analysis on the stored text works
    let report = stylometric::analyse(&stored);
    assert!(report.word_count > 0);
    assert!(report.sentence_count > 0);

    // Step 5: a Path referencing this work's spans has the correct content
    let spans = vec![
        crate::edition::range_element::SpanRef::new(works[0], 0, 10),
    ];
    let path = RangeElement::path(spans);
    assert!(path.is_path());
}
