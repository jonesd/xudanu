// sequence-minus-vectors.rs — standalone exhibit for Roger Gregory's
// six-implementation comparison (§5.5, the Sequence>>minus: bug).
//
// Run with plain rustc — no crate, no deps, no features:
//
//   rustc sequence-minus-vectors.rs && ./sequence-minus-vectors
//
// Everything between the EXHIBIT markers is extracted verbatim from
// xudanu (space/sequence.rs): an independent Rust implementation of
// Gold's Sequence. The data representation is Gold's design (a shift
// plus a sparse digit array — myShift + myNumbers); the arithmetic is
// derived from the algebra, not transliterated from Gold's code, so
// it has no diff-branches and no offset to get wrong.
//
// Oracle vectors from the paper (live Pharo probe):
//   1:5   - 0:1 = 0:        (buggy)    0:-1,5      (correct)
//   2:7,8 - 0:1 = 2:6       (buggy)    0:-1,0,7,8  (correct)
//   1:5   + 0:1 = 0:1,5     (plus always correct)
// plus the round-trip property a.minus(b).plus(b) == a, which the
// Dsp inverse in a working system depends on.
use std::fmt;
use std::process::ExitCode;

// ── EXHIBIT (from xudanu space/sequence.rs) ────────────────────────────
#[derive(Debug, Clone, PartialEq, Eq)]
struct Sequence {
    shift: i64,
    numbers: Vec<i64>,
}

impl Sequence {
    fn zero() -> Self {
        Sequence { shift: 0, numbers: Vec::new() }
    }

    fn from_numbers_with_shift(mut numbers: Vec<i64>, mut shift: i64) -> Self {
        while numbers.last() == Some(&0) {
            numbers.pop();
        }
        while numbers.first() == Some(&0) {
            numbers.remove(0);
            shift += 1;
        }
        Sequence { shift, numbers }
    }

    fn at(&self, index: i64) -> i64 {
        let adjusted = index - self.shift;
        if adjusted < 0 || adjusted >= self.numbers.len() as i64 {
            0
        } else {
            self.numbers[adjusted as usize]
        }
    }

    fn first_index(&self) -> Option<i64> {
        if self.numbers.is_empty() { None } else { Some(self.shift) }
    }

    fn last_index(&self) -> Option<i64> {
        if self.numbers.is_empty() { None } else { Some(self.shift + self.numbers.len() as i64 - 1) }
    }

    fn plus(&self, other: &Sequence) -> Self {
        let start = self.first_index().unwrap_or(0).min(other.first_index().unwrap_or(0));
        let end = self.last_index().unwrap_or(-1).max(other.last_index().unwrap_or(-1));
        if start > end {
            return Self::zero();
        }
        let len = (end - start + 1) as usize;
        let mut result = vec![0i64; len];
        for i in 0..len {
            let idx = start + i as i64;
            result[i] = self.at(idx) + other.at(idx);
        }
        Sequence::from_numbers_with_shift(result, start)
    }

    fn minus(&self, other: &Sequence) -> Self {
        let start = self.first_index().unwrap_or(0).min(other.first_index().unwrap_or(0));
        let end = self.last_index().unwrap_or(-1).max(other.last_index().unwrap_or(-1));
        if start > end {
            return Self::zero();
        }
        let len = (end - start + 1) as usize;
        let mut result = vec![0i64; len];
        for i in 0..len {
            let idx = start + i as i64;
            result[i] = self.at(idx) - other.at(idx);
        }
        Sequence::from_numbers_with_shift(result, start)
    }
}
// ── END EXHIBIT ────────────────────────────────────────────────────────

// Gold notation: shift:d,d,d  (empty digits printed as bare shift)
impl fmt::Display for Sequence {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}:", self.shift)?;
        let digits: Vec<String> = self.numbers.iter().map(|d| d.to_string()).collect();
        write!(f, "{}", digits.join(","))
    }
}

fn check(name: &str, got: &Sequence, want: &str) -> bool {
    let ok = &got.to_string() == want;
    println!("  {} {:>14} = {:<12} expected {:<12} {}", if ok { "✓" } else { "✗" }, name, got, want, if ok { "" } else { "MISMATCH" });
    ok
}

fn main() -> ExitCode {
    println!("xudanu Sequence arithmetic vs Roger Gregory's minus: oracle vectors");
    println!("(exhibit extracted from jonesd/xudanu space/sequence.rs)\n");

    let a  = Sequence::from_numbers_with_shift(vec![5], 1);      // 1:5
    let a2 = Sequence::from_numbers_with_shift(vec![7, 8], 2);   // 2:7,8
    let b  = Sequence::from_numbers_with_shift(vec![1], 0);      // 0:1

    let mut ok = true;
    ok &= check("1:5 - 0:1", &a.minus(&b), "0:-1,5");
    ok &= check("2:7,8 - 0:1", &a2.minus(&b), "0:-1,0,7,8");
    ok &= check("1:5 + 0:1", &a.plus(&b), "0:1,5");

    // The property a working system leans on: minus is plus's inverse.
    let rt1 = a.minus(&b).plus(&b) == a;
    let rt2 = a2.minus(&b).plus(&b) == a2;
    let rt3 = Sequence::zero().minus(&b).plus(&b) == Sequence::zero();
    println!("  {} round-trip a.minus(b).plus(b) == a        (1:5, 2:7,8, zero)", rt1 && rt2 && rt3);

    if ok && rt1 && rt2 && rt3 {
        println!("\nALL VECTORS MATCH — the transliteration bug is not expressible here.");
        ExitCode::SUCCESS
    } else {
        println!("\nMISMATCH — do not ship.");
        ExitCode::FAILURE
    }
}
