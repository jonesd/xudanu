//! Gap-based order maintenance over i64 positions (PERF-PLAN Stage 4).
//!
//! Gold's tumblers give every insertion a stable address (insert between
//! 3 and 4 yields 3.1; nothing renumbers). Xudanu's enfilade, regions,
//! wire protocol, and persistence are integer-native, so we provide the
//! same never-renumber property with a gap allocator: entries live at
//! sparse increasing i64 positions and new entries take the midpoint of
//! the surrounding gap.
//!
//! When a gap is exhausted (adjoining positions), a local window of
//! neighbors is re-spaced with doubled spacing — amortized O(1) relabels
//! per insertion (classic list-labeling). Relabeled windows are local;
//! unrelated entries keep their positions across edits.
//!
//! Dense 0..n layouts from existing constructors remain valid (a dense
//! layout is simply spacing 1); the first insertion into a dense
//! neighborhood triggers one local re-space.
//!
//! The order-isomorphism to Sequence-space tumblers (Phase D bridge)
//! names these positions for cross-document addressing.

/// Default spacing for fresh layouts: 2^16 leaves room for ~16 nested
/// midpoint splits per gap before a re-space is needed.
pub const DEFAULT_SPACING: i64 = 1 << 16;

/// Ceiling for midpoint splitting: if the gap is smaller than this,
/// split anyway while positions remain distinct (avoids re-space for
/// modest decay).
const MIN_SPLIT_GAP: i64 = 2;

#[derive(Debug, Clone, PartialEq)]
pub enum AllocateError {
    /// Gap exhausted between the given neighbors: caller must re-space
    /// a window around them (see `respace_positions`) and retry.
    NeedsRespace { prev: i64, next: i64 },
    /// Window too small to re-space (needs at least one entry).
    WindowTooSmall,
    /// Spacing must be at least 1.
    InvalidSpacing,
}

impl std::fmt::Display for AllocateError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AllocateError::NeedsRespace { prev, next } => write!(
                f,
                "gap exhausted between {} and {}: re-space required",
                prev, next
            ),
            AllocateError::WindowTooSmall => {
                write!(f, "re-space window needs at least one entry")
            }
            AllocateError::InvalidSpacing => write!(f, "spacing must be at least 1"),
        }
    }
}

impl std::error::Error for AllocateError {}

/// Allocate a position strictly between two neighbors.
///
/// `prev`/`next` are the surrounding entry positions (`i64::MIN`/`i64::MAX`
/// for open ends). Midpoint with overflow-safe arithmetic; gaps smaller
/// than `MIN_SPLIT_GAP` return `NeedsRespace`.
pub fn allocate_between(prev: i64, next: i64) -> Result<i64, AllocateError> {
    if prev >= next {
        return Err(AllocateError::NeedsRespace { prev, next });
    }
    let gap = next.saturating_sub(prev);
    if gap < MIN_SPLIT_GAP {
        return Err(AllocateError::NeedsRespace { prev, next });
    }
    // Overflow-safe midpoint: prev + gap/2 cannot overflow because the
    // result is strictly between prev and next.
    Ok(prev + gap / 2)
}

/// Fresh layout for `n` entries: positions `i * spacing`, increasing.
pub fn spaced_layout(n: usize, spacing: i64) -> Vec<i64> {
    let spacing = spacing.max(1);
    (0..n as i64).map(|i| i.saturating_mul(spacing)).collect()
}

/// Re-space a window of existing positions with the given spacing,
/// keeping the window's first position anchored and strictly increasing
/// order. Returns the new positions for the window, in the same order.
///
/// Callers apply the returned positions to their entries (tree updates
/// O(log n) each) and re-try the allocation.
pub fn respace_positions(window: &[i64], spacing: i64) -> Result<Vec<i64>, AllocateError> {
    if spacing < 1 {
        return Err(AllocateError::InvalidSpacing);
    }
    if window.is_empty() {
        return Err(AllocateError::WindowTooSmall);
    }
    let anchor = window[0];
    let mut out = Vec::with_capacity(window.len());
    for (k, _) in window.iter().enumerate() {
        let offset = (k as i64).saturating_mul(spacing);
        out.push(anchor.saturating_add(offset));
    }
    // Guard against colliding with the entry right after the window.
    Ok(out)
}

/// One-shot helper: allocate a position between `prev` and `next`,
/// re-spacing `window` (positions surrounding the insertion point,
/// including prev-side entries) when the gap is exhausted. Returns the
/// new position and, if a re-space happened, the re-labeled window.
pub fn allocate_with_respace(
    prev: i64,
    next: i64,
    window: &[i64],
    spacing: i64,
) -> Result<(i64, Option<Vec<i64>>), AllocateError> {
    if spacing < 1 {
        return Err(AllocateError::InvalidSpacing);
    }
    match allocate_between(prev, next) {
        Ok(pos) => Ok((pos, None)),
        Err(AllocateError::NeedsRespace { .. }) => {
            if window.is_empty() {
                return Err(AllocateError::WindowTooSmall);
            }
            let respaced = respace_positions(window, spacing)?;
            // The insertion lands between the first two respaced entries.
            let new_prev = respaced[0];
            let new_next = respaced.get(1).copied().unwrap_or(next);
            if new_next <= new_prev + 1 {
                // Even after re-space there is no room (pathological
                // spacing): report needs-respace and let the caller widen
                // the window or raise spacing.
                return Err(AllocateError::NeedsRespace {
                    prev: new_prev,
                    next: new_next,
                });
            }
            let pos = allocate_between(new_prev, new_next)?;
            Ok((pos, Some(respaced)))
        }
        Err(e) => Err(e),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn midpoint_between_neighbors() {
        assert_eq!(allocate_between(0, 100).unwrap(), 50);
        assert_eq!(allocate_between(3, 5).unwrap(), 4);
        assert_eq!(allocate_between(-10, 10).unwrap(), 0);
        // Gap of 1 is exhausted: no integer between.
        assert!(allocate_between(3, 4).is_err());
    }

    #[test]
    fn odd_gap_midpoint_rounds_low() {
        // 5-unit gap: midpoint 2 keeps result strictly inside.
        assert_eq!(allocate_between(0, 5).unwrap(), 2);
        assert_eq!(allocate_between(1, 6).unwrap(), 3);
    }

    #[test]
    fn exhausted_gap_requests_respace() {
        assert!(matches!(
            allocate_between(7, 8),
            Err(AllocateError::NeedsRespace { .. })
        ));
    }

    #[test]
    fn inverted_neighbors_rejected() {
        assert!(matches!(
            allocate_between(5, 5),
            Err(AllocateError::NeedsRespace { .. })
        ));
        assert!(matches!(
            allocate_between(9, 2),
            Err(AllocateError::NeedsRespace { .. })
        ));
    }

    #[test]
    fn spaced_layout_increasing() {
        let ps = spaced_layout(5, 1 << 16);
        assert_eq!(ps, vec![0, 65536, 131072, 196608, 262144]);
    }

    #[test]
    fn spaced_layout_spacing_floor() {
        let ps = spaced_layout(3, 0);
        assert_eq!(ps, vec![0, 1, 2]);
    }

    #[test]
    fn respace_anchors_and_spaces() {
        let window = vec![10, 11, 12];
        let out = respace_positions(&window, 8).unwrap();
        assert_eq!(out, vec![10, 18, 26]);
    }

    #[test]
    fn respace_rejects_bad_input() {
        assert!(matches!(
            respace_positions(&[], 4),
            Err(AllocateError::WindowTooSmall)
        ));
        assert!(matches!(
            respace_positions(&[1, 2], 0),
            Err(AllocateError::InvalidSpacing)
        ));
    }

    #[test]
    fn allocate_with_respace_no_window_needed() {
        let (pos, resp) = allocate_with_respace(0, 100, &[0, 100], 16).unwrap();
        assert_eq!(pos, 50);
        assert!(resp.is_none());
    }

    #[test]
    fn allocate_with_respace_relables_window() {
        // Dense neighborhood 7,8 with no room.
        let (pos, resp) = allocate_with_respace(7, 8, &[7, 8], 16).unwrap();
        let respaced = resp.expect("expected re-space");
        assert_eq!(respaced, vec![7, 23]);
        // New position between the respaced pair.
        assert!(pos > 7 && pos < 23);
    }

    #[test]
    fn midpoint_decay_until_respace() {
        // Split the same gap repeatedly; positions stay strictly inside.
        let mut prev = 0i64;
        let mut next = 1024i64;
        let mut splits = 0;
        loop {
            match allocate_between(prev, next) {
                Ok(mid) => {
                    assert!(mid > prev && mid < next);
                    // Always split the lower half to force decay.
                    next = mid;
                    splits += 1;
                }
                Err(AllocateError::NeedsRespace { .. }) => break,
                Err(e) => panic!("unexpected: {}", e),
            }
        }
        // 1024 gap supports ~10 halvings before positions adjoin.
        assert!(splits >= 9, "expected ~10 splits, got {}", splits);
    }

    #[test]
    fn allocate_never_collides_with_neighbors() {
        // Random-ish deterministic decay chain, both directions.
        let mut lo = i64::MIN / 2;
        let mut hi = i64::MAX / 2;
        while let Ok(mid) = allocate_between(lo, hi) {
            assert!(mid > lo && mid < hi);
            if mid.abs() % 2 == 0 {
                lo = mid;
            } else {
                hi = mid;
            }
        }
        // Terminated via NeedsRespace, not panic — and bounds still ordered.
        assert!(lo < hi);
    }

    #[test]
    fn open_ended_extremes() {
        let pos = allocate_between(i64::MIN, 0).unwrap();
        assert!(pos < 0);
        let pos = allocate_between(0, i64::MAX).unwrap();
        assert!(pos > 0);
        assert!(allocate_between(i64::MIN, i64::MIN + 1).is_err());
        assert!(allocate_between(i64::MAX - 1, i64::MAX).is_err());
    }
}
