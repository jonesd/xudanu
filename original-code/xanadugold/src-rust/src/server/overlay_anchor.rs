//! FR-79 Stage 2 — the overlay anchoring contract.
//!
//! ONE anchoring implementation, on the server, shared by every
//! consumer. The browser extension never matches text itself: it
//! extracts the page's text spine, sends it here, and renders the
//! offsets we resolved against that exact text — so the extension's
//! DOM mapping stays consistent by construction. The same resolver
//! semantics (excerpt + context, tolerant search, fail closed) are
//! what the editor's stale-offset recovery uses inside Xudanu; an
//! anchor that survives a Xudanu revision survives a page redesign.
//!
//! Resolution order (a mark that cannot prove its passage does not
//! render — failure is silent by design):
//!
//!   1. `Fingerprint` — the page text hashes to the shadow's current
//!      content hash AND the mark's stored span still extracts the
//!      recorded excerpt: offsets are authoritative.
//!   2. `Context`     — before+excerpt+after found together.
//!   3. `Excerpt`     — excerpt found alone.
//!   4. Unresolved    — hidden, logged for the author.
//!
//! Searches are whitespace- and case-tolerant: web text extraction
//! varies in whitespace collapsing and casing, so an exact-substring
//! miss falls through to a normalized pass (whitespace runs
//! collapsed to one space, ASCII case-folded) with offsets mapped
//! back to the original text. All offsets are CHAR offsets (Unicode
//! scalar values) so they cross the wire to JS `for..of` iteration
//! without conversion.

/// Mark excerpts are capped at 200 chars (spec FR-79 §2.2).
pub const MAX_EXCERPT_CHARS: usize = 200;
/// Before/after context is capped at 100 chars each.
pub const MAX_CONTEXT_CHARS: usize = 100;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AnchorResolution {
    /// Page fingerprint matched the shadow revision and the stored
    /// span still extracts the excerpt — offsets are authoritative.
    Fingerprint,
    /// before+excerpt+after found together — strong match.
    Context,
    /// Excerpt found alone — weaker, still renders.
    Excerpt,
}

impl AnchorResolution {
    pub fn as_str(&self) -> &'static str {
        match self {
            AnchorResolution::Fingerprint => "fingerprint",
            AnchorResolution::Context => "context",
            AnchorResolution::Excerpt => "excerpt",
        }
    }
}

/// A resolved mark: char offsets into the exact page text the
/// extension sent, plus how the resolution was proven.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ResolvedAnchor {
    pub start: usize,
    pub end: usize,
    pub how: AnchorResolution,
}

/// Build (excerpt, before, after) from a span of the shadow text at
/// CHAR offsets, char-clamped and capped per the contract. Returns
/// an empty excerpt when the span is empty or out of bounds — the
/// caller treats that as unresolvable (fail closed).
pub fn excerpt_with_context(text: &str, start: usize, end: usize) -> (String, String, String) {
    let total = text.chars().count();
    if start >= end || start >= total {
        return (String::new(), String::new(), String::new());
    }
    let end = end.min(total);
    let excerpt: String = text
        .chars()
        .skip(start)
        .take(end - start)
        .take(MAX_EXCERPT_CHARS)
        .collect();
    let before: String = text
        .chars()
        .skip(start.saturating_sub(MAX_CONTEXT_CHARS))
        .take(start.min(MAX_CONTEXT_CHARS))
        .collect();
    let after: String = text.chars().skip(end).take(MAX_CONTEXT_CHARS).collect();
    (excerpt, before, after)
}

/// Whitespace-collapsed, ASCII-case-folded view of `text` plus the
/// map from collapsed char index → original char index. `map` has
/// `chars + 1` entries (the final one is `chars`) so end boundaries
/// resolve too. Leading/trailing whitespace is dropped.
struct Collapsed {
    text: String,
    map: Vec<usize>,
}

fn collapse(text: &str) -> Collapsed {
    let mut out = String::new();
    let mut map = Vec::new();
    let mut ws_start: Option<usize> = None;
    for (ci, ch) in text.chars().enumerate() {
        if ch.is_whitespace() {
            // Remember where the run began; the collapsed space
            // maps to the run's start so span ends never eat
            // trailing whitespace.
            if ws_start.is_none() {
                ws_start = Some(ci);
            }
            continue;
        }
        if let Some(ws) = ws_start.take() {
            if !out.is_empty() {
                out.push(' ');
                map.push(ws);
            }
        }
        map.push(ci);
        out.push(ch.to_ascii_lowercase());
    }
    map.push(text.chars().count());
    Collapsed { text: out, map }
}

/// Find `needle` in `hay` as chars, returning (start, end) char
/// offsets. Exact byte substring first; the caller handles the
/// normalized pass.
fn find_chars(hay: &str, needle: &str) -> Option<(usize, usize)> {
    let b = hay.find(needle)?;
    let start = hay[..b].chars().count();
    Some((start, start + needle.chars().count()))
}

/// Resolve one mark against the page text. `before`/`after` may be
/// empty (span at text edges). Char-safe throughout.
///
/// Probe order: the three pieces reconstructed CONTIGUOUSLY (they
/// were adjacent in the shadow text — the strongest evidence, and
/// the only one that works for whitespace-free text), then
/// space-joined with trimmed parts (extraction variance), then the
/// collapsed normalized pass, then the excerpt alone.
pub fn resolve_anchor(
    page_text: &str,
    excerpt: &str,
    before: &str,
    after: &str,
) -> Option<ResolvedAnchor> {
    if excerpt.trim().is_empty() {
        return None;
    }

    // 1. Contiguous: before+excerpt+after adjacent, exactly as
    //    extracted from the source.
    if !before.is_empty() || !after.is_empty() {
        let mut probe = String::with_capacity(before.len() + excerpt.len() + after.len());
        probe.push_str(before);
        let at = probe.chars().count();
        probe.push_str(excerpt);
        probe.push_str(after);
        if let Some((s, _)) = find_chars(page_text, &probe) {
            let len = excerpt.chars().count();
            return Some(ResolvedAnchor {
                start: s + at,
                end: s + at + len,
                how: AnchorResolution::Context,
            });
        }
    }

    // 2. Space-joined exact: trimmed parts joined by single spaces.
    let t_before = before.trim();
    let t_after = after.trim();
    let t_excerpt = excerpt.trim();
    if !t_before.is_empty() || !t_after.is_empty() {
        let mut probe = String::new();
        if !t_before.is_empty() {
            probe.push_str(t_before);
        }
        probe.push(' ');
        let at = probe.chars().count();
        probe.push_str(t_excerpt);
        if !t_after.is_empty() {
            probe.push(' ');
            probe.push_str(t_after);
        }
        if let Some((s, _)) = find_chars(page_text, &probe) {
            let len = t_excerpt.chars().count();
            return Some(ResolvedAnchor {
                start: s + at,
                end: s + at + len,
                how: AnchorResolution::Context,
            });
        }
    }

    // 3. Normalized pass: whitespace-collapsed, ASCII-folded.
    let hay = collapse(page_text);
    let needle = collapse(t_excerpt).text;
    if needle.is_empty() {
        return None;
    }

    let before_n = collapse(t_before).text;
    let after_n = collapse(t_after).text;
    if !before_n.is_empty() || !after_n.is_empty() {
        let mut probe = String::new();
        if !before_n.is_empty() {
            probe.push_str(&before_n);
        }
        probe.push(' ');
        let needle_start_c = probe.chars().count();
        probe.push_str(&needle);
        if !after_n.is_empty() {
            probe.push(' ');
            probe.push_str(&after_n);
        }
        if let Some((s, _e)) = find_chars(&hay.text, &probe) {
            let ns = s + needle_start_c;
            let ne = ns + needle.chars().count();
            if let (Some(os), Some(oe)) = (hay.map.get(ns), hay.map.get(ne)) {
                return Some(ResolvedAnchor {
                    start: *os,
                    end: *oe,
                    how: AnchorResolution::Context,
                });
            }
        }
    }

    // 4. Excerpt alone: exact, then collapsed.
    if let Some(found) = find_chars(page_text, t_excerpt) {
        return Some(ResolvedAnchor {
            start: found.0,
            end: found.1,
            how: AnchorResolution::Excerpt,
        });
    }
    find_chars(&hay.text, &needle).and_then(|(s, e)| {
        let (os, oe) = (*hay.map.get(s)?, *hay.map.get(e)?);
        Some(ResolvedAnchor {
            start: os,
            end: oe,
            how: AnchorResolution::Excerpt,
        })
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    const PAGE: &str = "The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump!";

    #[test]
    fn exact_context_match() {
        let a = resolve_anchor(PAGE, "fox jumps over", "quick brown ", "the lazy dog");
        assert_eq!(
            a,
            Some(ResolvedAnchor {
                start: 16,
                end: 30,
                how: AnchorResolution::Context
            })
        );
    }

    #[test]
    fn contiguous_probe_survives_whitespace_free_text() {
        // Digits: no spaces anywhere, so only the contiguous
        // reconstruction can prove the context.
        let page = "0123456789".repeat(10);
        let a = resolve_anchor(&page, "3456789", "012", "01234567890123456");
        assert_eq!(
            a,
            Some(ResolvedAnchor {
                start: 3,
                end: 10,
                how: AnchorResolution::Context
            })
        );
    }

    #[test]
    fn excerpt_only_when_context_absent() {
        let a = resolve_anchor(PAGE, "fox jumps over", "WRONG context", "");
        assert_eq!(
            a,
            Some(ResolvedAnchor {
                start: 16,
                end: 30,
                how: AnchorResolution::Excerpt
            })
        );
    }

    #[test]
    fn whitespace_and_case_tolerant() {
        // Page has double spaces, newlines, different casing.
        let page = "Intro.\n\nThe   QUICK brown fox jumps   over the lazy dog.";
        // The words between "The" and "QUICK" differ from a naive
        // expectation: collapsed matching still proves the passage.
        let a = resolve_anchor(
            page,
            "quick brown fox jumps over",
            "intro. the",
            "the lazy dog",
        );
        assert!(matches!(
            a,
            Some(ResolvedAnchor {
                how: AnchorResolution::Context,
                ..
            })
        ));
        let a = a.unwrap();
        // The mapped span must be exactly the passage in the original.
        let span: String = page.chars().skip(a.start).take(a.end - a.start).collect();
        assert_eq!(span, "QUICK brown fox jumps   over");
    }

    #[test]
    fn survives_minor_edits_around_the_span() {
        // The page gained a sentence before the passage and lost the
        // exact context after it — the excerpt still resolves.
        let page = "A brand new editorial insert up top. The quick brown fox jumps over something else entirely.";
        let a = resolve_anchor(page, "fox jumps over", "quick brown ", "the lazy dog");
        assert!(matches!(
            a,
            Some(ResolvedAnchor {
                how: AnchorResolution::Excerpt,
                ..
            })
        ));
        let a = a.unwrap();
        let span: String = page.chars().skip(a.start).take(a.end - a.start).collect();
        assert_eq!(span, "fox jumps over");
    }

    #[test]
    fn unresolved_when_passage_deleted() {
        let a = resolve_anchor(PAGE, "sphinx of black quartz", "", "");
        assert_eq!(a, None);
    }

    #[test]
    fn empty_excerpt_is_none() {
        assert_eq!(resolve_anchor(PAGE, "   ", "", ""), None);
    }

    #[test]
    fn span_at_text_edges() {
        let a = resolve_anchor(PAGE, "The quick brown fox", "", " jumps over");
        assert_eq!(a.map(|x| x.start), Some(0));
        let a = resolve_anchor(PAGE, "daft zebras jump!", "How vexingly quick ", "");
        assert!(a.is_some());
        let a = a.unwrap();
        assert_eq!(a.end, PAGE.chars().count());
    }

    #[test]
    fn excerpt_with_context_caps_and_clamps() {
        let text = "0123456789".repeat(50); // 500 chars
        let (ex, before, after) = excerpt_with_context(&text, 10, 350);
        assert_eq!(ex.chars().count(), MAX_EXCERPT_CHARS);
        assert!(before.chars().count() <= MAX_CONTEXT_CHARS);
        assert!(after.chars().count() <= MAX_CONTEXT_CHARS);
        // Out of bounds fails closed.
        let (oob, _, _) = excerpt_with_context(&text, 600, 700);
        assert!(oob.is_empty());
        // Reversed span fails closed.
        let (rev, _, _) = excerpt_with_context(&text, 30, 30);
        assert!(rev.is_empty());
        // Round trip: the excerpt we hand out always resolves back.
        let r = resolve_anchor(&text, &ex, &before, &after);
        assert!(matches!(
            r,
            Some(ResolvedAnchor {
                how: AnchorResolution::Context,
                ..
            })
        ));
    }

    #[test]
    fn multibyte_offsets_are_char_offsets() {
        let page = " café 😄 naïve — the quick brown fox";
        let a = resolve_anchor(page, "quick brown fox", "the ", "");
        assert!(a.is_some());
        let a = a.unwrap();
        let span: String = page.chars().skip(a.start).take(a.end - a.start).collect();
        assert_eq!(span, "quick brown fox");
    }

    #[test]
    fn first_occurrence_wins_deterministically() {
        let page = "buffalo buffalo buffalo buffalo";
        let a = resolve_anchor(page, "buffalo", "", "");
        assert_eq!(a.map(|x| x.start), Some(0));
    }
}
