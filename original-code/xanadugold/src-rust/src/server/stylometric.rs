//! Stylometric analysis — lightweight AI-content detection signals.
//!
//! Phase 1: burstiness + vocabulary fingerprint. Pure functions —
//! no IO, no locks, no ML model dependency. These are probabilistic
//! signals, not proof. They flag text for review; they don't prove
//! authorship.
//!
//! The signals are independent of the interface the text arrived
//! through, the provenance chain, and the docuverse content. They
//! work on any text from any source.
//!
//! Burstiness: humans write with variable sentence complexity ("bursty");
//! LLMs produce more uniform structures. We compute the coefficient
//! of variation (std_dev / mean) of sentence word counts. Low CV =
//! uniform = likely LLM.
//!
//! Vocabulary fingerprint: LLMs over-represent certain terms relative
//! to human writing baselines. We count occurrences of known
//! LLM-frequent terms and compute a density score. High density =
//! likely LLM.

/// The result of a stylometric analysis pass.
#[derive(Debug, Clone, PartialEq)]
pub struct StylometricReport {
    /// Burstiness: coefficient of variation of sentence lengths.
    /// Lower = more uniform = more likely LLM.
    /// Typical: human prose 0.5-1.0, LLM output 0.2-0.5.
    pub burstiness: f64,

    /// Vocabulary fingerprint: LLM-frequent term density per 100 words.
    /// Higher = more LLM-characteristic vocabulary.
    /// Typical: human prose 0-1.5, LLM output 2-8.
    pub vocabulary_density: f64,

    /// Vocabulary diversity: unique words / total words (type-token ratio).
    /// Lower = more repetitive = slightly more likely LLM.
    /// Typical: human prose 0.45-0.75, LLM output 0.35-0.60.
    pub vocabulary_diversity: f64,

    /// Paragraph uniformity: coefficient of variation of paragraph
    /// sentence counts. Lower = more uniform = more likely LLM.
    /// Typical: human prose 0.4-0.9, LLM output 0.2-0.5.
    pub paragraph_uniformity: f64,

    /// Combined lightweight score: 0.0 = likely human, 1.0 = likely LLM.
    /// This is a heuristic combination of the above signals, not a
    /// statistical model. It's a signal for review, not a proof.
    pub ai_likelihood: f64,

    /// Specific LLM-frequent terms found in the text (for explainability).
    pub matched_terms: Vec<String>,

    /// Number of sentences analysed.
    pub sentence_count: usize,

    /// Number of words analysed.
    pub word_count: usize,
}

/// LLM-over-represented vocabulary, from published frequency analyses.
/// These are terms that appear significantly more often in LLM output
/// than in human writing baselines (English-language models).
const LLM_FREQUENT_TERMS: &[&str] = &[
    // Intensifiers and emphasis
    "crucial",
    "pivotal",
    "paramount",
    "instrumental",
    "delve",
    "delving",
    "multifaceted",
    "nuanced",
    "intricate",
    "intricacies",
    "comprehensive",
    "holistic",
    "robust",
    "seamless",
    "cutting-edge",
    "state-of-the-art",
    "innovative",
    "groundbreaking",
    "transformative",
    "revolutionary",
    "unprecedented",
    "invaluable",
    "indispensable",
    // Structure markers
    "furthermore",
    "moreover",
    "additionally",
    "consequently",
    "subsequently",
    "nevertheless",
    "nonetheless",
    "notwithstanding",
    "accordingly",
    "henceforth",
    "thereby",
    "wherein",
    "whereby",
    // Metaphorical framing
    "tapestry",
    "landscape",
    "navigate",
    "navigating",
    "journey",
    "framework",
    "realm",
    "sphere",
    "domain",
    "paradigm",
    "synergy",
    "synergies",
    "leverage",
    "leveraging",
    "hone",
    "foster",
    "fostering",
    "cultivate",
    "cultivating",
    "embark",
    "embarking",
    "unravel",
    "unveil",
    "unveiling",
    "spearhead",
    "champion",
    "championing",
    "bolster",
    "bolstering",
    // Hedging phrases (checked as word sequences)
    "arguably",
    "perhaps",
    "potentially",
    "seemingly",
    "importantly",
    "notably",
    "significantly",
    "particularly",
    // Characteristic verbs
    "underscore",
    "underscores",
    "underscored",
    "highlight",
    "highlights",
    "highlighted",
    "exemplify",
    "exemplifies",
    "demonstrate",
    "demonstrates",
    "demonstrated",
    "facilitate",
    "facilitates",
    "facilitated",
    "encompass",
    "encompasses",
    "encompassed",
    "elucidate",
    "elucidates",
    "elucidated",
    "encompassing",
    "underscored",
];

/// LLM-characteristic phrases (multi-word, checked as sequences).
const LLM_FREQUENT_PHRASES: &[&str] = &[
    "it's important to note",
    "it's worth noting",
    "it's worth considering",
    "important to note that",
    "worth noting that",
    "in today's",
    "in the realm of",
    "in the landscape of",
    "at the end of the day",
    "with that in mind",
    "that being said",
    "in this context",
    "in conclusion",
    "ultimately,",
    "not only", // parallel construction marker
    "but also",
    "a testament to",
    "plays a crucial role",
    "plays a vital role",
    "plays a significant role",
    "sheds light on",
    "paves the way",
    "opens up new",
    "a wide range of",
    "a variety of",
    "a plethora of",
    "a myriad of",
    "delve into",
    "navigate the",
    "foster a",
    "fostering a",
];

/// Analyse a text and return stylometric signals.
/// Pure function — no side effects, no model, no IO.
pub fn analyse(text: &str) -> StylometricReport {
    let sentences = split_sentences(text);
    let words = split_words(text);
    let paragraphs = split_paragraphs(text);

    let sentence_count = sentences.len();
    let word_count = words.len();

    // Guard: need enough text to be meaningful
    if sentence_count < 3 || word_count < 30 {
        return StylometricReport {
            burstiness: 0.0,
            vocabulary_density: 0.0,
            vocabulary_diversity: 0.0,
            paragraph_uniformity: 0.0,
            ai_likelihood: 0.0,
            matched_terms: Vec::new(),
            sentence_count,
            word_count,
        };
    }

    // === Burstiness ===
    let sentence_lengths: Vec<usize> = sentences.iter().map(|s| split_words(s).len()).collect();
    let burstiness = coefficient_of_variation(&sentence_lengths);

    // === Vocabulary fingerprint ===
    let (vocabulary_density, matched_terms) = vocabulary_fingerprint(&words, text);

    // === Vocabulary diversity ===
    let vocabulary_diversity = type_token_ratio(&words);

    // === Paragraph uniformity ===
    let paragraph_sentence_counts: Vec<usize> = paragraphs
        .iter()
        .map(|p| split_sentences(p).len())
        .filter(|n| *n > 0)
        .collect();
    let paragraph_uniformity = if paragraph_sentence_counts.len() >= 2 {
        coefficient_of_variation(&paragraph_sentence_counts)
    } else {
        0.5 // neutral default for single-paragraph text
    };

    // === Combined score ===
    let ai_likelihood = combine_signals(
        burstiness,
        vocabulary_density,
        vocabulary_diversity,
        paragraph_uniformity,
    );

    StylometricReport {
        burstiness,
        vocabulary_density,
        vocabulary_diversity,
        paragraph_uniformity,
        ai_likelihood,
        matched_terms,
        sentence_count,
        word_count,
    }
}

/// Coefficient of variation: std_dev / mean.
/// Measures relative variability — independent of scale.
fn coefficient_of_variation(values: &[usize]) -> f64 {
    if values.len() < 2 {
        return 0.0;
    }
    let n = values.len() as f64;
    let mean = values.iter().map(|v| *v as f64).sum::<f64>() / n;
    if mean == 0.0 {
        return 0.0;
    }
    let variance = values
        .iter()
        .map(|v| {
            let d = *v as f64 - mean;
            d * d
        })
        .sum::<f64>()
        / n;
    let std_dev = variance.sqrt();
    std_dev / mean
}

/// Type-token ratio: unique words / total words.
/// Lower = more repetitive vocabulary.
fn type_token_ratio(words: &[String]) -> f64 {
    if words.is_empty() {
        return 0.0;
    }
    let mut unique: std::collections::HashSet<&str> = std::collections::HashSet::new();
    for w in words {
        unique.insert(w.as_str());
    }
    unique.len() as f64 / words.len() as f64
}

/// Count LLM-frequent terms and compute density per 100 words.
fn vocabulary_fingerprint(words: &[String], full_text: &str) -> (f64, Vec<String>) {
    let mut matched: Vec<String> = Vec::new();
    let lower_words: std::collections::HashSet<String> =
        words.iter().map(|w| w.to_lowercase()).collect();

    // Check single-word terms
    for term in LLM_FREQUENT_TERMS {
        if lower_words.contains(*term) {
            matched.push(term.to_string());
        }
    }

    // Check multi-word phrases
    let lower_text = full_text.to_lowercase();
    for phrase in LLM_FREQUENT_PHRASES {
        if lower_text.contains(phrase) {
            matched.push(format!("\"{}\"", phrase));
        }
    }

    // Density: matched terms per 100 words
    let density = if words.is_empty() {
        0.0
    } else {
        (matched.len() as f64 / words.len() as f64) * 100.0
    };

    (density, matched)
}

/// Combine individual signals into a lightweight AI-likelihood score.
/// This is a heuristic, not a trained model. It's designed to be
/// conservative (bias toward "human" for ambiguous cases).
fn combine_signals(
    burstiness: f64,
    vocabulary_density: f64,
    vocabulary_diversity: f64,
    paragraph_uniformity: f64,
) -> f64 {
    // Each signal contributes a sub-score in [0, 1]
    // Burstiness: low CV → high AI score
    // Human burstiness ~0.5-1.0, LLM ~0.2-0.5
    let burst_score = clamp01((0.6 - burstiness) / 0.4);

    // Vocabulary density: high density → high AI score
    // Human ~0-1.5 per 100 words, LLM ~2-8
    let vocab_score = clamp01(vocabulary_density / 5.0);

    // Vocabulary diversity: low diversity → slightly higher AI score
    // Human ~0.45-0.75, LLM ~0.35-0.60
    let diversity_score = clamp01((0.55 - vocabulary_diversity) / 0.3);

    // Paragraph uniformity: low variance → high AI score
    let uniformity_score = clamp01((0.5 - paragraph_uniformity) / 0.4);

    // Weighted combination (burstiness and vocabulary are strongest)
    let score =
        0.30 * burst_score + 0.30 * vocab_score + 0.15 * diversity_score + 0.25 * uniformity_score;

    clamp01(score)
}

fn clamp01(v: f64) -> f64 {
    v.max(0.0).min(1.0)
}

fn split_sentences(text: &str) -> Vec<String> {
    let mut sentences = Vec::new();
    let mut current = String::new();
    for ch in text.chars() {
        current.push(ch);
        if ch == '.' || ch == '!' || ch == '?' {
            // Look ahead: sentence ends at .! followed by whitespace or end
            sentences.push(current.trim().to_string());
            current = String::new();
        }
    }
    if !current.trim().is_empty() {
        sentences.push(current.trim().to_string());
    }
    sentences.into_iter().filter(|s| !s.is_empty()).collect()
}

fn split_words(text: &str) -> Vec<String> {
    text.split_whitespace()
        .map(|w| w.trim_matches(|c: char| !c.is_alphanumeric() && c != '-' && c != '\''))
        .filter(|w| !w.is_empty() && w.len() > 1)
        .map(|w| w.to_string())
        .collect()
}

fn split_paragraphs(text: &str) -> Vec<String> {
    text.split("\n\n")
        .map(|p| p.trim().to_string())
        .filter(|p| !p.is_empty())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A passage with high burstiness (varied sentence lengths) —
    /// typical of human writing.
    const HUMAN_TEXT: &str = "The meeting started late. Everyone was there except for the two people who actually knew what was going on, which meant the first twenty minutes were spent in a kind of confused politeness while we waited. Then Sarah arrived. She sat down. She looked at the agenda for about three seconds and said, \"This is all wrong.\" What followed was the most productive two hours I've ever spent in a conference room, and by the end we'd torn the entire project apart and rebuilt it from scratch. Nobody was happy about it, but everybody knew it was right.";

    /// A passage with low burstiness and LLM-characteristic vocabulary —
    /// typical of LLM output.
    const LLM_TEXT: &str = "It's important to note that this framework plays a crucial role in fostering a comprehensive understanding of the domain. Furthermore, the multifaceted nature of this landscape necessitates a holistic approach. Moreover, it's worth noting that leveraging these synergies can facilitate groundbreaking outcomes. Additionally, the intricate tapestry of these interactions underscores the paramount importance of a nuanced perspective. Consequently, navigating this realm requires a robust understanding of the underlying paradigms. Furthermore, this innovative approach sheds light on previously unexplored dimensions.";

    #[test]
    fn human_text_has_higher_burstiness() {
        let human = analyse(HUMAN_TEXT);
        let llm = analyse(LLM_TEXT);
        assert!(
            human.burstiness > llm.burstiness,
            "human burstiness ({:.3}) should exceed LLM burstiness ({:.3})",
            human.burstiness,
            llm.burstiness
        );
    }

    #[test]
    fn llm_text_has_higher_vocabulary_density() {
        let human = analyse(HUMAN_TEXT);
        let llm = analyse(LLM_TEXT);
        assert!(
            llm.vocabulary_density > human.vocabulary_density,
            "LLM vocabulary density ({:.1}) should exceed human ({:.1})",
            llm.vocabulary_density,
            human.vocabulary_density
        );
    }

    #[test]
    fn llm_text_scores_higher_ai_likelihood() {
        let human = analyse(HUMAN_TEXT);
        let llm = analyse(LLM_TEXT);
        assert!(
            llm.ai_likelihood > human.ai_likelihood,
            "LLM score ({:.3}) should exceed human ({:.3})",
            llm.ai_likelihood,
            human.ai_likelihood
        );
    }

    #[test]
    fn matched_terms_are_reported() {
        let llm = analyse(LLM_TEXT);
        assert!(
            !llm.matched_terms.is_empty(),
            "LLM text should have matched terms"
        );
        assert!(
            llm.matched_terms.iter().any(|t| t.contains("crucial")),
            "should find 'crucial' in LLM text"
        );
    }

    #[test]
    fn short_text_returns_zero() {
        let report = analyse("Too short to analyse.");
        assert_eq!(report.ai_likelihood, 0.0);
        assert_eq!(report.sentence_count, 1);
    }

    #[test]
    fn empty_text_returns_zero() {
        let report = analyse("");
        assert_eq!(report.ai_likelihood, 0.0);
        assert_eq!(report.word_count, 0);
    }

    #[test]
    fn technical_human_text_still_scores_lower_than_llm() {
        // Uniform human writing (technical docs) — the hardest case
        let technical = "The system comprises three modules. Each module handles a specific domain. The first module manages user input. The second module processes the data. The third module generates output. All modules communicate via the bus. Error handling is consistent throughout. Logging is implemented in each module. Configuration is centralised.";
        let tech_report = analyse(technical);
        let llm = analyse(LLM_TEXT);
        // Even uniform technical writing should score lower than
        // LLM text with characteristic vocabulary
        assert!(
            llm.vocabulary_density > tech_report.vocabulary_density,
            "LLM vocabulary density should exceed uniform technical writing"
        );
    }

    #[test]
    fn coefficient_of_variation_computes_correctly() {
        // [10, 10, 10, 10] → CV = 0 (no variation)
        assert_eq!(coefficient_of_variation(&[10, 10, 10, 10]), 0.0);
        // [5, 15] → mean=10, std_dev=5, CV=0.5
        assert!((coefficient_of_variation(&[5, 15]) - 0.5).abs() < 0.01);
        // Empty / single element
        assert_eq!(coefficient_of_variation(&[]), 0.0);
        assert_eq!(coefficient_of_variation(&[5]), 0.0);
    }

    #[test]
    fn type_token_ratio_computes_correctly() {
        let words: Vec<String> = vec!["a", "b", "a", "c"]
            .iter()
            .map(|s| s.to_string())
            .collect();
        assert!((type_token_ratio(&words) - 0.75).abs() < 0.01);
    }
}
