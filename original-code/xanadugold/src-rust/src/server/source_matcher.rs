use std::collections::HashMap;

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
    LineContains { pattern: String, key: String },
    RegexBetween { prefix: String, suffix: String, key: String },
}

impl SourcePattern {
    pub fn detect(&self, text: &str) -> SourceMatchResult {
        let lines: Vec<&str> = text.lines().collect();
        let total_lines = lines.len() as u64;

        let has_header = if self.header_patterns.is_empty() {
            true
        } else {
            let top_text: String = lines.iter().take(50).copied().collect::<Vec<&str>>().join("\n").to_lowercase();
            self.header_patterns.iter().all(|p| top_text.contains(&p.to_lowercase()))
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
                MetadataExtractor::RegexBetween { prefix, suffix, key } => {
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

#[cfg(test)]
mod tests {
    use super::*;

    fn gutenberg_sample() -> String {
        let mut text = String::from("The Project Gutenberg eBook of The Ten Books on Architecture\n");
        text.push_str("by Vitruvius\n\n");
        text.push_str("Release Date: January 1, 2024 [eBook #20239]\n");
        text.push_str("Title: The Ten Books on Architecture\n");
        text.push_str("Author: Vitruvius\n");
        text.push_str("Language: English\n\n");
        text.push_str("*** START OF THE PROJECT GUTENBERG EBOOK THE TEN BOOKS ON ARCHITECTURE ***\n\n");
        text.push_str("Book I\n\n");
        text.push_str("The Education of the Architect\n\n");
        for _ in 0..50 {
            text.push_str("Lorem ipsum dolor sit amet.\n");
        }
        text.push_str("\n*** END OF THE PROJECT GUTENBERG EBOOK THE TEN BOOKS ON ARCHITECTURE ***\n");
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
            metadata_extractors: vec![
                MetadataExtractor::LineContains {
                    pattern: "DOI:".into(),
                    key: "doi".into(),
                },
            ],
        };
        let text = "JSTOR Digital Library\nDOI: 10.1234/5678\n--- BEGIN CONTENT ---\nContent here.\n--- END CONTENT ---\nFooter";
        let result = pattern.detect(text);
        assert!(result.detected);
        assert_eq!(result.metadata.get("doi").unwrap().trim(), "DOI: 10.1234/5678");
        assert_eq!(result.content_start_line, 3);
        assert_eq!(result.content_end_line, 4);
    }
}
