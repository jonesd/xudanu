//! FR-90: NFC normalisation at the ingestion boundary.
//!
//! Unicode permits the same visible text as multiple byte sequences
//! (NFC composed vs NFD decomposed). Xudanu's content identity is
//! byte-based (BLAKE3 crums, reuse matching, federation verification),
//! so the same passage in two forms would produce different hashes.
//! This module provides the single normalisation point through which
//! all text entering the document model must pass.
//!
//! Policy: Normalization Form C (composed) — the W3C recommendation,
//! emitted by ~95% of systems; macOS paste (the main NFD source) is
//! absorbed here. Already-NFC text is a no-op.

use unicode_normalization::UnicodeNormalization;

/// Normalise text to Unicode NFC (Normalization Form C).
/// This is the single boundary function for FR-90.
/// Apply at every text entry point: work_set_text, element_insert,
/// revise, MCP write path, seeder scripts, federation import.
/// Already-NFC text passes through unchanged (no-op).
pub fn to_nfc(text: &str) -> String {
    text.nfc().collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn nfc_composed_passes_through_unchanged() {
        // U+00E9 is the precomposed é — already NFC
        let input = "café";
        assert_eq!(to_nfc(input), input);
    }

    #[test]
    fn nfd_decomposed_converts_to_nfc() {
        // e + U+0301 (combining acute accent) = NFD form of é
        let nfd_input = "cafe\u{0301}";
        let nfc_expected = "café"; // U+00E9
        assert_eq!(to_nfc(nfd_input), nfc_expected);
        assert_ne!(nfd_input, nfc_expected); // verify they differ before normalisation
    }

    #[test]
    fn nfc_hash_matches_across_forms() {
        let nfc_text = "café";
        let nfd_text = "cafe\u{0301}";
        let nfc_normalised = to_nfc(nfc_text);
        let nfd_normalised = to_nfc(nfd_text);
        assert_eq!(
            blake3::hash(nfc_normalised.as_bytes()),
            blake3::hash(nfd_normalised.as_bytes()),
            "the same visible text must produce the same hash after normalisation"
        );
    }

    #[test]
    fn ascii_text_is_no_op() {
        let input = "plain ascii text with no accents";
        assert_eq!(to_nfc(input), input);
    }

    #[test]
    fn korean_decomposed_composes_to_nfc() {
        // Korean Hangul: NFD decomposes syllables into Jamo;
        // NFC recomposes them
        let nfc_syllable = "\u{AC00}"; // 가 (single syllable block)
        let nfd_jamo = "\u{1100}\u{1161}"; // ᄀ + ᅡ (two Jamo)
        assert_eq!(to_nfc(nfd_jamo), nfc_syllable);
    }

    #[test]
    fn round_trip_nfc_nfd_nfc_is_stable() {
        use unicode_normalization::UnicodeNormalization;
        let original = "Héllo wörld — ünïcödé tëst wîth måny áccénts";
        let nfc = to_nfc(original);
        let nfd: String = nfc.nfd().collect();
        let back_to_nfc = to_nfc(&nfd);
        assert_eq!(nfc, back_to_nfc, "NFC → NFD → NFC must round-trip");
    }

    #[test]
    fn empty_string_passes_through() {
        assert_eq!(to_nfc(""), "");
    }

    #[test]
    fn preserves_ligatures_and_superscripts() {
        // NFC does NOT apply compatibility decomposition —
        // ligatures and superscripts pass through unchanged
        let ligature = "\u{FB01}"; // ﬁ ligature
        assert_eq!(to_nfc(ligature), ligature, "NFC must not destroy ligatures");

        let superscript = "x\u{00B2}"; // x²
        assert_eq!(to_nfc(superscript), superscript, "NFC must not destroy superscripts");
    }
}
