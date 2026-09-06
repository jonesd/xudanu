//! FR-58 E-0: the reuse matcher behind reference-over-copy
//! suggestions. Tier 1 is a word n-gram inverted index
//! (hash -> occurrences); Tier 2 is MinHash similarity against
//! source paragraphs (reusing `source_matcher`). Pure functions —
//! no IO, no locks — so the E-0 harness measures matching cost in
//! isolation.

use std::collections::HashMap;

use blake3::Hasher;

/// A corpus paragraph: which work it belongs to, its index within
/// the work, and its text.
#[derive(Debug, Clone)]
pub struct CorpusPara {
    pub work_id: u64,
    pub para_idx: usize,
    pub text: String,
}

/// T1: the n-gram inverted index. Key = blake3 of n lowercased
/// words; value = every paragraph containing that n-gram.
#[derive(Debug, Default)]
pub struct NgramIndex {
    pub n: usize,
    map: HashMap<u64, Vec<usize>>,
    paras: Vec<CorpusPara>,
}

pub fn word_ngram_hashes(text: &str, n: usize) -> Vec<u64> {
    let words: Vec<&str> = text.split_whitespace().collect();
    if words.len() < n {
        return vec![];
    }
    (0..=words.len() - n)
        .map(|i| {
            let mut hasher = Hasher::new();
            hasher.update(words[i..i + n].join(" ").to_lowercase().as_bytes());
            let hash: [u8; 32] = hasher.finalize().into();
            u64::from_le_bytes(hash[..8].try_into().unwrap_or([0u8; 8]))
        })
        .collect()
}

impl NgramIndex {
    pub fn build(n: usize, paras: Vec<CorpusPara>) -> Self {
        let mut map: HashMap<u64, Vec<usize>> = HashMap::new();
        for (idx, p) in paras.iter().enumerate() {
            for h in word_ngram_hashes(&p.text, n) {
                map.entry(h).or_default().push(idx);
            }
        }
        NgramIndex { n, map, paras }
    }

    /// Probe with a typed prefix. Returns every (para, window) hit,
    /// deduplicated by paragraph, ranked by matched-window count.
    pub fn probe(&self, prefix: &str) -> Vec<(&CorpusPara, usize)> {
        let mut hits: HashMap<usize, usize> = HashMap::new();
        for h in word_ngram_hashes(prefix, self.n) {
            if let Some(idxs) = self.map.get(&h) {
                for &idx in idxs {
                    *hits.entry(idx).or_insert(0) += 1;
                }
            }
        }
        let mut ranked: Vec<(&CorpusPara, usize)> = hits
            .into_iter()
            .map(|(idx, windows)| (&self.paras[idx], windows))
            .collect();
        ranked.sort_by(|a, b| b.1.cmp(&a.1).then(a.0.para_idx.cmp(&b.0.para_idx)));
        ranked
    }
}

/// T2: MinHash similarity of the typed prefix against every corpus
/// paragraph, ranked best-first. Reuses `source_matcher`.
pub fn minhash_rank<'a>(prefix: &str, paras: &'a [CorpusPara]) -> Vec<(&'a CorpusPara, f64)> {
    let sig = crate::server::source_matcher::compute_minhash(prefix);
    let mut ranked: Vec<(&CorpusPara, f64)> = paras
        .iter()
        .map(|p| {
            (
                p,
                crate::server::source_matcher::minhash_similarity(
                    &sig,
                    &crate::server::source_matcher::compute_minhash(&p.text),
                ),
            )
        })
        .collect();
    ranked.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
    ranked
}

/// Split a work's text into non-empty paragraphs.
pub fn paragraphs(text: &str) -> Vec<String> {
    text.split('\n')
        .map(str::trim)
        .filter(|p| !p.is_empty())
        .map(str::to_string)
        .collect()
}

/// FR-58 S4: paragraphs with their byte spans in the work text —
/// the accept-as-transclusion coordinates (consistent with link
/// span semantics, which are byte-based).
pub fn paragraphs_with_spans(text: &str) -> Vec<(i64, i64, String)> {
    let mut out = Vec::new();
    let mut offset = 0usize;
    for line in text.split('\n') {
        let trimmed_start = line.trim_start();
        let lead = line.len() - trimmed_start.len();
        let t = trimmed_start.trim_end();
        if !t.is_empty() {
            out.push((
                (offset + lead) as i64,
                (offset + lead + t.len()) as i64,
                t.to_string(),
            ));
        }
        offset += line.len() + 1;
    }
    out
}

/// FR-58 S1: one suggestion card — a work whose text contains
/// n-grams of the typed prefix, with the best-matching paragraph
/// as the snippet and its span for accept-as-transclusion.
#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct SuggestionCard {
    pub work_id: u64,
    pub title: String,
    pub snippet: String,
    pub windows: usize,
    #[cfg_attr(feature = "serde", serde(default))]
    pub span_start: i64,
    #[cfg_attr(feature = "serde", serde(default))]
    pub span_end: i64,
}

/// FR-58 S1: the per-server reuse index. Works are reindexed
/// lazily — `touch` on materialization, rebuild on next query —
/// so edits never pay index cost until someone asks for
/// suggestions.
#[derive(Debug)]
pub struct ReuseService {
    n: usize,
    stale: std::collections::HashSet<u64>,
    paras: std::collections::HashMap<u64, Vec<(i64, i64, String)>>,
    index: std::collections::HashMap<u64, Vec<(u64, usize)>>,
}

impl ReuseService {
    /// n = 6 per the E-0 matrix (FR-58 doc, 2026-09-06).
    pub fn new() -> Self {
        ReuseService {
            n: 6,
            stale: Default::default(),
            paras: Default::default(),
            index: Default::default(),
        }
    }

    pub fn touch(&mut self, work_id: u64) {
        self.stale.insert(work_id);
    }

    /// A work needs (re)indexing if touched or never seen.
    pub fn needs_rebuild(&self, work_id: u64) -> bool {
        self.stale.contains(&work_id) || !self.paras.contains_key(&work_id)
    }

    /// Swap a work's paragraphs: remove its old postings, add the
    /// new ones.
    pub fn rebuild(&mut self, work_id: u64, paras: Vec<(i64, i64, String)>) {
        if let Some(old) = self.paras.remove(&work_id) {
            for (_, _, p) in &old {
                for h in word_ngram_hashes(p, self.n) {
                    if let Some(posts) = self.index.get_mut(&h) {
                        posts.retain(|(w, _)| *w != work_id);
                        if posts.is_empty() {
                            self.index.remove(&h);
                        }
                    }
                }
            }
        }
        for (i, (_, _, p)) in paras.iter().enumerate() {
            for h in word_ngram_hashes(p, self.n) {
                self.index.entry(h).or_default().push((work_id, i));
            }
        }
        self.paras.insert(work_id, paras);
        self.stale.remove(&work_id);
    }

    pub fn remove(&mut self, work_id: u64) {
        self.rebuild(work_id, Vec::new());
        self.paras.remove(&work_id);
    }

    /// Rank works whose paragraphs share n-grams with the typed
    /// prefix. The querying work is excluded (suggestions come from
    /// elsewhere). One card per work: the paragraph with the most
    /// matched windows is the snippet.
    pub fn query(&self, exclude_work: u64, prefix: &str) -> Vec<SuggestionCard> {
        let mut para_hits: std::collections::HashMap<(u64, usize), usize> =
            std::collections::HashMap::new();
        for h in word_ngram_hashes(prefix, self.n) {
            if let Some(posts) = self.index.get(&h) {
                for &(w, i) in posts {
                    if w != exclude_work {
                        *para_hits.entry((w, i)).or_insert(0) += 1;
                    }
                }
            }
        }
        let mut best: std::collections::HashMap<u64, (usize, usize, usize)> =
            std::collections::HashMap::new();
        for ((w, i), windows) in para_hits {
            let e = best.entry(w).or_insert((0, usize::MAX, 0));
            if windows > e.0 {
                e.0 = windows;
                e.1 = i;
            }
            e.2 += windows;
        }
        let mut cards: Vec<SuggestionCard> = best
            .into_iter()
            .map(|(w, (_best_count, best_idx, total))| {
                let para = self.paras.get(&w).and_then(|v| v.get(best_idx));
                let snippet = para
                    .map(|(_, _, p)| p.chars().take(140).collect())
                    .unwrap_or_default();
                let (span_start, span_end) = para.map(|(s, e, _)| (*s, *e)).unwrap_or((0, 0));
                SuggestionCard {
                    work_id: w,
                    title: String::new(),
                    snippet,
                    windows: total,
                    span_start,
                    span_end,
                }
            })
            .collect();
        cards.sort_by(|a, b| b.windows.cmp(&a.windows).then(a.work_id.cmp(&b.work_id)));
        cards
    }
}

impl Default for ReuseService {
    fn default() -> Self {
        Self::new()
    }
}

// ── E-0: the replay experiment (FR-58 gate) ────────────────────────────────
#[cfg(test)]
mod e0 {
    use super::*;

    // Background works: the seeded demo corpus texts (realistic
    // distractors — the lessons share boilerplate phrases like
    // "Your task:", which the matcher must rank through).
    const COMPANION: &str = "Lesson Companion\n\nA garden is not a photograph; it is a performance that repeats daily.\n\nThe greenhouse kept the same plants for six years, and regulars began greeting them like staff.\n\nAnyone who says a map is the territory has never maintained either.";
    const COMPANION_B: &str = "Second Companion\n\nTide tables are predictions wearing the costume of memories.\n\nThe ferry schedule survived three administrations because nobody dared own it.";
    const L1: &str = "Links Lesson 1 — The Simple Link\n\nA link is a typed connection between two passages. This sentence is a live one: its underline connects to a line in the Lesson Companion.\n\nYour task: Select this sentence and click the Link button, choose any type, and pick Lesson Companion as the target.\n\nWhen your own underline appears, you have made a link. That is the whole primitive — everything fancier is more of these, arranged with intent.";
    const L2: &str = "Links Lesson 2 — Three Ends on One Connection\n\nThe link you made had two ends. A link can have any number: this sentence is one end of a THREE-ended connection whose other ends live in both companions.\n\nYour task: Select this sentence, click Link, and on the final step use Additional ends to add a second target.\n\nThree ends is not a chain and not a list — it is one claim involving several places at once.";
    const L3: &str = "Links Lesson 3 — Gathering Passages into One End\n\nThe step change: one END can itself hold several passages.\n\nOne performance that repeats daily, and the schedule nobody dared own.\n\nYour task, twice: Select this sentence and click the green Gather button, then choose Your First End.";
    const L4: &str = "Links Lesson 4 — Commenting on a Connection\n\nPassages can be commented on; so can connections. Open the Links panel on the right and find the row for this lesson's demonstration link.\n\nNobody expects you to remember the machinery; remember only that anything on the page — passage or connection — can be argued with, and the argument is itself addressable.";

    // The reference-over-copy scenario: an anthology work quoting
    // verbatim passages from the corpus above. Ground truth is the
    // (lift, source_work) pairs — known here by construction.
    const ANTHOLOGY: &[(&str, u64)] = &[
        ("A garden is not a photograph; it is a performance that repeats daily.", 101),
        ("The ferry schedule survived three administrations because nobody dared own it.", 102),
        ("A link is a typed connection between two passages.", 103),
        ("Three ends is not a chain and not a list — it is one claim involving several places at once.", 104),
        ("Nobody expects you to remember the machinery; remember only that anything on the page — passage or connection — can be argued with, and the argument is itself addressable.", 106),
        ("Anyone who says a map is the territory has never maintained either.", 101),
    ];

    const WORKS: &[(u64, &str)] = &[
        (101, COMPANION),
        (102, COMPANION_B),
        (103, L1),
        (104, L2),
        (105, L3),
        (106, L4),
    ];

    // The anthology author's original connective text (never a hit).
    const ORIGINAL: &str = "The gardener's almanac is an anthology of borrowed moments.";

    fn build_corpus() -> Vec<CorpusPara> {
        let mut paras = Vec::new();
        for (wid, text) in WORKS {
            for (i, p) in paragraphs(text).into_iter().enumerate() {
                paras.push(CorpusPara {
                    work_id: *wid,
                    para_idx: i,
                    text: p,
                });
            }
        }
        paras
    }

    /// Words of a lift, truncated to `frac` of its length (>= n
    /// words so early prefixes still probe).
    fn prefix_at(lift: &str, frac: f64, n: usize) -> String {
        let words: Vec<&str> = lift.split_whitespace().collect();
        let take = ((words.len() as f64 * frac).ceil() as usize).max(n);
        words[..take.min(words.len())].join(" ")
    }

    struct ProbeOutcome {
        earliest_frac: f64,
        top_rank_correct_at_full: bool,
    }

    fn replay_lift(index: &NgramIndex, lift: &str, source_work: u64) -> ProbeOutcome {
        let mut earliest = f64::MAX;
        let mut top_correct = false;
        for &frac in &[0.1, 0.25, 0.5, 0.75, 1.0] {
            let prefix = prefix_at(lift, frac, index.n);
            let hits = index.probe(&prefix);
            if hits.iter().any(|(p, _)| p.work_id == source_work) {
                earliest = earliest.min(frac);
            }
            if frac == 1.0 {
                top_correct = hits.first().map(|(p, _)| p.work_id) == Some(source_work);
            }
        }
        ProbeOutcome {
            earliest_frac: earliest,
            top_rank_correct_at_full: top_correct,
        }
    }

    /// The E-0 matrix. Prints coverage / trigger / top-rank / latency
    /// per n; asserts the FR-58 gate (coverage >= 80%, top-rank
    /// precision >= 90%, mean trigger <= 60%, p99 probe <= 50ms).
    #[test]
    fn e0_ngram_matrix_meets_fr58_gate() {
        let corpus = build_corpus();
        let mut report = String::from("E-0 matrix (T1 n-gram)\n      n  cov  trig   top  p99µs\n");
        let mut gate_pass = false;

        for &n in &[4usize, 6, 8, 10] {
            let index = NgramIndex::build(n, corpus.clone());

            let mut outcomes = Vec::new();
            let mut latencies = Vec::new();
            for (lift, src) in ANTHOLOGY {
                let o = replay_lift(&index, lift, *src);
                for &frac in &[0.1, 0.25, 0.5, 0.75, 1.0] {
                    let prefix = prefix_at(lift, frac, n);
                    let t0 = std::time::Instant::now();
                    index.probe(&prefix);
                    latencies.push(t0.elapsed().as_nanos() as u64);
                }
                outcomes.push((lift, o));
            }

            let covered = outcomes
                .iter()
                .filter(|(_, o)| o.earliest_frac <= 1.0)
                .count();
            let coverage = covered as f64 / outcomes.len() as f64;
            let triggers: Vec<f64> = outcomes
                .iter()
                .filter(|(_, o)| o.earliest_frac <= 1.0)
                .map(|(_, o)| o.earliest_frac)
                .collect();
            let mean_trigger = triggers.iter().sum::<f64>() / triggers.len().max(1) as f64;
            let top = outcomes
                .iter()
                .filter(|(_, o)| o.top_rank_correct_at_full)
                .count();
            let top_frac = top as f64 / outcomes.len() as f64;
            latencies.sort();
            let p99 = latencies[(latencies.len() * 99) / 100];

            report.push_str(&format!(
                "{:>6}  {:>3.0}%  {:>4.0}%  {:>4.0}%  {:>6}\n",
                n,
                coverage * 100.0,
                mean_trigger * 100.0,
                top_frac * 100.0,
                p99 / 1000
            ));

            if n == 4 {
                for (lift, o) in &outcomes {
                    let snippet: String = lift.chars().take(34).collect();
                    report.push_str(&format!(
                        "       lift {:?} src={} earliest={:.2} top={}\n",
                        snippet,
                        ANTHOLOGY
                            .iter()
                            .find(|(l, _)| l == &**lift)
                            .map(|(_, s)| *s)
                            .unwrap_or(0),
                        o.earliest_frac,
                        o.top_rank_correct_at_full
                    ));
                }
            }

            if coverage >= 0.8 && top_frac >= 0.9 && mean_trigger <= 0.6 && p99 <= 50_000_000 {
                gate_pass = true;
            }
        }

        // Original text must never fire T1 (control).
        let index = NgramIndex::build(6, corpus.clone());
        assert!(
            index.probe(ORIGINAL).is_empty(),
            "original prose must not match the corpus"
        );

        println!("{}", report);
        assert!(gate_pass, "no n value cleared the FR-58 gate:\n{}", report);
    }

    /// T2 (MinHash) fires on substantial prefixes even where T1's
    /// window alignment misses; informational for the FR-58 record.
    #[test]
    fn e0_minhash_tier_informational() {
        let corpus = build_corpus();
        let index = NgramIndex::build(6, corpus.clone());
        let mut best_n = 0.0f64;
        for (lift, src) in ANTHOLOGY {
            for &frac in &[0.5, 0.75, 1.0] {
                let prefix = prefix_at(lift, frac, 6);
                if let Some((p, sim)) = minhash_rank(&prefix, &corpus).into_iter().next() {
                    if p.work_id == *src {
                        best_n = best_n.max(sim);
                    }
                }
            }
        }
        println!(
            "E-0 T2: best correct-source MinHash similarity across lifts: {:.2}",
            best_n
        );
        let _ = index;
    }
}

/// FR-58 S1 service armor: build, query, exclusion, stale
/// reindexing.
#[cfg(test)]
mod service_tests {
    use super::*;

    fn para(text: &str) -> Vec<(i64, i64, String)> {
        paragraphs_with_spans(text)
    }

    #[test]
    fn query_finds_source_and_excludes_self() {
        let mut svc = ReuseService::new();
        svc.rebuild(
            1,
            para("A garden is not a photograph; it is a performance that repeats daily."),
        );
        svc.rebuild(2, para("Unrelated notes about tides and ferries."));

        let cards = svc.query(3, "it is a performance that repeats daily");
        assert_eq!(cards.len(), 1);
        assert_eq!(cards[0].work_id, 1);
        assert!(cards[0].snippet.contains("garden"));

        // The querying work itself is never suggested.
        let cards = svc.query(1, "it is a performance that repeats daily");
        assert!(cards.is_empty(), "self must be excluded");

        // Spans address the matched paragraph inside the source work
        // (byte offsets, same convention as link spans). Rebuild with
        // a two-paragraph text so the offset math is exercised:
        // "Title Line" (10) + "\n\n" -> paragraph 2 starts at 12.
        let para_text =
            "Title Line\n\nA garden is not a photograph; it is a performance that repeats daily.";
        svc.rebuild(9, para(para_text));
        let cards = svc.query(3, "it is a performance that repeats daily");
        let card = cards
            .iter()
            .find(|c| c.work_id == 9)
            .expect("work 9 suggested");
        assert_eq!(card.span_start, 12);
        let body = "A garden is not a photograph; it is a performance that repeats daily.";
        assert_eq!(card.span_end as usize, 12 + body.len());
    }

    #[test]
    fn touch_then_rebuild_replaces_postings() {
        let mut svc = ReuseService::new();
        svc.rebuild(1, para("The original sentence about orchards and apples."));
        assert!(!svc.needs_rebuild(1));
        assert!(svc.needs_rebuild(2), "never-indexed work needs rebuild");

        svc.touch(1);
        assert!(svc.needs_rebuild(1));

        // Reindex with different text: old n-grams must not linger.
        svc.rebuild(
            1,
            para("Completely different content about harbors and their keepers today."),
        );
        let cards = svc.query(3, "the original sentence about orchards and apples");
        assert!(
            cards.is_empty(),
            "stale postings must be gone after rebuild"
        );
        let cards = svc.query(3, "different content about harbors and their keepers");
        assert_eq!(cards.len(), 1);
        assert_eq!(cards[0].work_id, 1);
    }

    #[test]
    fn ranking_prefers_more_matched_windows() {
        let mut svc = ReuseService::new();
        svc.rebuild(1, para("alpha beta gamma delta epsilon zeta eta theta."));
        svc.rebuild(
            2,
            para("alpha beta gamma delta epsilon zeta eta theta and again alpha beta gamma delta epsilon zeta eta once more."),
        );
        let cards = svc.query(3, "alpha beta gamma delta epsilon zeta eta");
        assert_eq!(cards.len(), 2);
        assert_eq!(cards[0].work_id, 2, "more matched windows ranks first");
        assert!(cards[0].windows > cards[1].windows);
    }

    #[test]
    fn remove_drops_work_entirely() {
        let mut svc = ReuseService::new();
        svc.rebuild(1, para("A unique sentence about moonlit meadows."));
        svc.remove(1);
        assert!(svc
            .query(2, "a unique sentence about moonlit meadows")
            .is_empty());
    }
}
