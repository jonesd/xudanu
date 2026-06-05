use std::collections::{HashMap, HashSet};

use blake3::Hasher;

use crate::edition::BeId;

#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct SourceMatchResult {
    pub source_type: String,
    pub detected: bool,
    pub content_start_line: u64,
    pub content_end_line: u64,
    pub total_lines: u64,
    pub metadata: HashMap<String, String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SourcePattern {
    pub source_type: String,
    pub display_name: String,
    pub start_marker: Option<String>,
    pub end_marker: Option<String>,
    pub header_patterns: Vec<String>,
    pub metadata_extractors: Vec<MetadataExtractor>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MetadataExtractor {
    LineContains {
        pattern: String,
        key: String,
    },
    RegexBetween {
        prefix: String,
        suffix: String,
        key: String,
    },
}

impl SourcePattern {
    pub fn detect(&self, text: &str) -> SourceMatchResult {
        let lines: Vec<&str> = text.lines().collect();
        let total_lines = lines.len() as u64;

        let has_header = if self.header_patterns.is_empty() {
            true
        } else {
            let top_text: String = lines
                .iter()
                .take(50)
                .copied()
                .collect::<Vec<&str>>()
                .join("\n")
                .to_lowercase();
            self.header_patterns
                .iter()
                .all(|p| top_text.contains(&p.to_lowercase()))
        };

        if !has_header {
            return SourceMatchResult {
                source_type: self.source_type.clone(),
                detected: false,
                content_start_line: 0,
                content_end_line: total_lines,
                total_lines,
                metadata: HashMap::new(),
            };
        }

        let mut metadata = HashMap::new();
        for ext in &self.metadata_extractors {
            match ext {
                MetadataExtractor::LineContains { pattern, key } => {
                    for line in &lines {
                        if line.contains(pattern) {
                            metadata.insert(key.clone(), line.trim().to_string());
                            break;
                        }
                    }
                }
                MetadataExtractor::RegexBetween {
                    prefix,
                    suffix,
                    key,
                } => {
                    for line in &lines {
                        if let Some(start) = line.find(prefix) {
                            let rest = &line[start + prefix.len()..];
                            if let Some(end) = rest.find(suffix) {
                                metadata.insert(key.clone(), rest[..end].trim().to_string());
                            }
                        }
                    }
                }
            }
        }

        let mut content_start = 0u64;
        if let Some(start_marker) = &self.start_marker {
            for (i, line) in lines.iter().enumerate() {
                if line.contains(start_marker) {
                    content_start = (i + 1) as u64;
                    break;
                }
            }
        }

        let mut content_end = total_lines;
        if let Some(end_marker) = &self.end_marker {
            for (i, line) in lines.iter().enumerate().rev() {
                if line.contains(end_marker) {
                    content_end = i as u64;
                    break;
                }
            }
        }

        SourceMatchResult {
            source_type: self.source_type.clone(),
            detected: true,
            content_start_line: content_start,
            content_end_line: content_end,
            total_lines,
            metadata,
        }
    }
}

pub fn builtin_patterns() -> Vec<SourcePattern> {
    vec![
        SourcePattern {
            source_type: "gutenberg".into(),
            display_name: "Project Gutenberg".into(),
            start_marker: Some("*** START OF".into()),
            end_marker: Some("*** END OF".into()),
            header_patterns: vec!["Project Gutenberg".into()],
            metadata_extractors: vec![
                MetadataExtractor::LineContains {
                    pattern: "Title:".into(),
                    key: "title".into(),
                },
                MetadataExtractor::LineContains {
                    pattern: "Author:".into(),
                    key: "author".into(),
                },
                MetadataExtractor::RegexBetween {
                    prefix: "eBook #".into(),
                    suffix: "]".into(),
                    key: "gutenberg_id".into(),
                },
                MetadataExtractor::LineContains {
                    pattern: "Release Date:".into(),
                    key: "release_date".into(),
                },
                MetadataExtractor::LineContains {
                    pattern: "Language:".into(),
                    key: "language".into(),
                },
            ],
        },
        SourcePattern {
            source_type: "internet_archive".into(),
            display_name: "Internet Archive".into(),
            start_marker: None,
            end_marker: None,
            header_patterns: vec!["Internet Archive".into()],
            metadata_extractors: vec![
                MetadataExtractor::LineContains {
                    pattern: "Title:".into(),
                    key: "title".into(),
                },
                MetadataExtractor::LineContains {
                    pattern: "Author:".into(),
                    key: "author".into(),
                },
            ],
        },
        SourcePattern {
            source_type: "plain_text".into(),
            display_name: "Plain Text".into(),
            start_marker: None,
            end_marker: None,
            header_patterns: vec![],
            metadata_extractors: vec![],
        },
    ]
}

pub fn detect_source(text: &str, patterns: &[SourcePattern]) -> SourceMatchResult {
    for pattern in patterns {
        let result = pattern.detect(text);
        if result.detected {
            return result;
        }
    }
    SourceMatchResult {
        source_type: "unknown".into(),
        detected: false,
        content_start_line: 0,
        content_end_line: text.lines().count() as u64,
        total_lines: text.lines().count() as u64,
        metadata: HashMap::new(),
    }
}

const SHINGLE_SIZE: usize = 5;
const SAMPLE_STEP: usize = 3;
pub const MINHASH_SIZE: usize = 128;

// MinHash chosen over plain shingle fingerprinting (storing all shingle hashes
// in a HashSet) because it compresses each document to a fixed-size 128-element
// signature (~1KB) regardless of text length, vs ~425KB for a full shingle set
// on a book like Dracula. Comparison is O(128) instead of O(shingle_count).
// Jaccard similarity estimate from MinHash is accurate enough for our threshold
// (>=30% overlap) and is the industry standard for near-duplicate detection.

pub type MinHashSignature = [u64; MINHASH_SIZE];

fn shingle_hashes(text: &str) -> Vec<u64> {
    let words: Vec<&str> = text.split_whitespace().collect();
    if words.len() < SHINGLE_SIZE {
        let mut hasher = Hasher::new();
        hasher.update(text.to_lowercase().as_bytes());
        let hash: [u8; 32] = hasher.finalize().into();
        let fp = u64::from_le_bytes(hash[..8].try_into().unwrap_or([0u8; 8]));
        if text.trim().is_empty() {
            return vec![];
        }
        return vec![fp];
    }

    let mut hashes = Vec::new();
    let lower_words: Vec<String> = words.iter().map(|w| w.to_lowercase()).collect();
    let mut i = 0;
    while i + SHINGLE_SIZE <= lower_words.len() {
        let shingle: String = lower_words[i..i + SHINGLE_SIZE].join(" ");
        let mut hasher = Hasher::new();
        hasher.update(shingle.as_bytes());
        let hash: [u8; 32] = hasher.finalize().into();
        let fp = u64::from_le_bytes(hash[..8].try_into().unwrap_or([0u8; 8]));
        hashes.push(fp);
        i += SAMPLE_STEP;
    }
    hashes
}

fn minhash_from_shingles(shingles: &[u64]) -> MinHashSignature {
    let mut sig = [u64::MAX; MINHASH_SIZE];
    for shingle in shingles {
        for band in 0..MINHASH_SIZE {
            let mut hasher = Hasher::new();
            hasher.update(&(band as u64).to_le_bytes());
            hasher.update(&shingle.to_le_bytes());
            let hash: [u8; 32] = hasher.finalize().into();
            let h = u64::from_le_bytes(hash[..8].try_into().unwrap_or([0u8; 8]));
            if h < sig[band] {
                sig[band] = h;
            }
        }
    }
    sig
}

pub fn compute_minhash(text: &str) -> MinHashSignature {
    let shingles = shingle_hashes(text);
    minhash_from_shingles(&shingles)
}

pub fn minhash_similarity(a: &MinHashSignature, b: &MinHashSignature) -> f64 {
    let matches = a.iter().zip(b.iter()).filter(|(x, y)| x == y).count();
    matches as f64 / MINHASH_SIZE as f64
}

pub fn best_content_match(
    query_text: &str,
    source_signatures: &[(BeId, MinHashSignature)],
) -> Option<(BeId, f64)> {
    let query_sig = compute_minhash(query_text);
    let query_shingles = shingle_hashes(query_text);
    if query_shingles.len() < 3 {
        return None;
    }

    let mut best_id = 0u64;
    let mut best_score = 0.0f64;
    for (work_id, source_sig) in source_signatures {
        let score = minhash_similarity(&query_sig, source_sig);
        if score > best_score {
            best_score = score;
            best_id = *work_id;
        }
    }

    if best_score >= 0.3 {
        Some((best_id, best_score))
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn gutenberg_sample() -> String {
        let mut text =
            String::from("The Project Gutenberg eBook of The Ten Books on Architecture\n");
        text.push_str("by Vitruvius\n\n");
        text.push_str("Release Date: January 1, 2024 [eBook #20239]\n");
        text.push_str("Title: The Ten Books on Architecture\n");
        text.push_str("Author: Vitruvius\n");
        text.push_str("Language: English\n\n");
        text.push_str(
            "*** START OF THE PROJECT GUTENBERG EBOOK THE TEN BOOKS ON ARCHITECTURE ***\n\n",
        );
        text.push_str("Book I\n\n");
        text.push_str("The Education of the Architect\n\n");
        for _ in 0..50 {
            text.push_str("Lorem ipsum dolor sit amet.\n");
        }
        text.push_str(
            "\n*** END OF THE PROJECT GUTENBERG EBOOK THE TEN BOOKS ON ARCHITECTURE ***\n",
        );
        text.push_str("\nUpdated editions will replace the previous one.\n");
        text
    }

    #[test]
    fn detect_gutenberg() {
        let text = gutenberg_sample();
        let patterns = builtin_patterns();
        let result = detect_source(&text, &patterns);
        assert!(result.detected);
        assert_eq!(result.source_type, "gutenberg");
        assert!(result.content_start_line > 0);
        assert!(result.content_end_line < result.total_lines);
    }

    #[test]
    fn gutenberg_extracts_metadata() {
        let text = gutenberg_sample();
        let patterns = builtin_patterns();
        let result = detect_source(&text, &patterns);
        let author_val = result.metadata.get("author").unwrap();
        assert!(author_val.contains("Vitruvius"), "got: {}", author_val);
        assert!(result.metadata.contains_key("title"));
    }

    #[test]
    fn gutenberg_extracts_id() {
        let text = gutenberg_sample();
        let patterns = builtin_patterns();
        let result = detect_source(&text, &patterns);
        let id_val = result.metadata.get("gutenberg_id").unwrap();
        assert!(id_val.contains("20239"), "got: {}", id_val);
    }

    #[test]
    fn detect_unknown_returns_plain_text() {
        let text = "Just some random text without any markers.";
        let patterns = builtin_patterns();
        let result = detect_source(text, &patterns);
        assert_eq!(result.source_type, "plain_text");
        assert!(result.detected);
    }

    #[test]
    fn plain_text_always_matches() {
        let text = "Hello world";
        let result = builtin_patterns()[2].detect(text);
        assert!(result.detected);
        assert_eq!(result.source_type, "plain_text");
        assert_eq!(result.content_start_line, 0);
        assert_eq!(result.content_end_line, 1);
    }

    #[test]
    fn custom_pattern_detect() {
        let pattern = SourcePattern {
            source_type: "jstor".into(),
            display_name: "JSTOR".into(),
            start_marker: Some("--- BEGIN CONTENT ---".into()),
            end_marker: Some("--- END CONTENT ---".into()),
            header_patterns: vec!["JSTOR".into()],
            metadata_extractors: vec![MetadataExtractor::LineContains {
                pattern: "DOI:".into(),
                key: "doi".into(),
            }],
        };
        let text = "JSTOR Digital Library\nDOI: 10.1234/5678\n--- BEGIN CONTENT ---\nContent here.\n--- END CONTENT ---\nFooter";
        let result = pattern.detect(text);
        assert!(result.detected);
        assert_eq!(
            result.metadata.get("doi").unwrap().trim(),
            "DOI: 10.1234/5678"
        );
        assert_eq!(result.content_start_line, 3);
        assert_eq!(result.content_end_line, 4);
    }

    #[test]
    fn minhash_identical_text_high_similarity() {
        let text = "The quick brown fox jumps over the lazy dog. ".repeat(20);
        let sig_a = compute_minhash(&text);
        let sig_b = compute_minhash(&text);
        assert_eq!(sig_a, sig_b);
        assert!(minhash_similarity(&sig_a, &sig_b) > 0.99);
    }

    #[test]
    fn minhash_subset_high_similarity() {
        let full = "The quick brown fox jumps over the lazy dog. ".repeat(50);
        let excerpt: String = full.chars().take(full.len() / 2).collect();
        let sig_full = compute_minhash(&full);
        let sig_excerpt = compute_minhash(&excerpt);
        let sim = minhash_similarity(&sig_full, &sig_excerpt);
        assert!(sim > 0.4, "expected >0.4, got {}", sim);
    }

    #[test]
    fn minhash_unrelated_text_low_similarity() {
        let a = "The quick brown fox jumps over the lazy dog. ".repeat(20);
        let b = "In a hole in the ground there lived a hobbit. ".repeat(20);
        let sig_a = compute_minhash(&a);
        let sig_b = compute_minhash(&b);
        let sim = minhash_similarity(&sig_a, &sig_b);
        assert!(sim < 0.3, "expected <0.3, got {}", sim);
    }

    #[test]
    fn best_content_match_finds_source() {
        let source = "It was the best of times it was the worst of times. ".repeat(30);
        let query: String = source.chars().take(source.len() / 3).collect();
        let sig = compute_minhash(&source);
        let sources: Vec<(BeId, MinHashSignature)> = vec![(42u64, sig)];
        let result = best_content_match(&query, &sources);
        assert!(result.is_some());
        let (id, score) = result.unwrap();
        assert_eq!(id, 42);
        assert!(score > 0.3, "expected >0.3, got {}", score);
    }
}
