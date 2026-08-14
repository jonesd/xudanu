use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

const MAX_FILTER_BYTES: usize = 1_048_576;
const MAX_NUM_HASHES: usize = 32;
const MIN_FPR: f64 = 0.0001;

#[derive(Debug, Clone)]
pub struct ServerBloomFilter {
    bits: Vec<u8>,
    num_hashes: usize,
    num_bits: usize,
    item_count: usize,
    timestamp: u64,
}

impl ServerBloomFilter {
    pub fn new(item_count: usize, fpr: f64) -> Self {
        let safe_fpr = if fpr.is_finite() && fpr >= MIN_FPR && fpr < 1.0 {
            fpr
        } else {
            0.01
        };
        let safe_count = item_count.max(1);
        let m = optimal_num_bits(safe_count, safe_fpr);
        let k = optimal_num_hashes(m, safe_count).min(MAX_NUM_HASHES);
        let byte_len = (m + 7) / 8;
        ServerBloomFilter {
            bits: vec![0; byte_len],
            num_hashes: k,
            num_bits: m,
            item_count: 0,
            timestamp: current_secs(),
        }
    }

    pub fn empty() -> Self {
        ServerBloomFilter {
            bits: Vec::new(),
            num_hashes: 0,
            num_bits: 0,
            item_count: 0,
            timestamp: current_secs(),
        }
    }

    pub fn from_network(
        bits: Vec<u8>,
        num_hashes: usize,
        num_bits: usize,
        item_count: usize,
        timestamp: u64,
    ) -> Result<Self, &'static str> {
        if bits.len() > MAX_FILTER_BYTES {
            return Err("filter exceeds maximum allowed size");
        }
        if num_hashes > MAX_NUM_HASHES {
            return Err("num_hashes exceeds maximum");
        }
        if num_hashes == 0 && item_count > 0 {
            return Err("non-zero item_count with zero hash functions");
        }
        if num_bits > 0 && bits.len() < (num_bits + 7) / 8 {
            return Err("bits array too small for claimed num_bits");
        }
        if num_bits == 0 && !bits.is_empty() {
            return Err("non-empty bits with zero num_bits");
        }
        let filter = ServerBloomFilter {
            bits,
            num_hashes,
            num_bits,
            item_count,
            timestamp,
        };
        if filter.is_likely_poisoned() {
            return Err("filter appears poisoned (all-ones or implausible)");
        }
        Ok(filter)
    }

    pub fn insert(&mut self, data: &[u8]) {
        if self.num_bits == 0 || data.is_empty() {
            return;
        }
        let (h1, h2) = double_hash(data);
        for i in 0..self.num_hashes {
            let combined = h1.wrapping_add((i as u64).wrapping_mul(h2));
            let idx = (combined as usize) % self.num_bits;
            self.bits[idx / 8] |= 1 << (idx % 8);
        }
        self.item_count += 1;
    }

    pub fn contains(&self, data: &[u8]) -> bool {
        if self.num_bits == 0 || data.is_empty() {
            return false;
        }
        let (h1, h2) = double_hash(data);
        for i in 0..self.num_hashes {
            let combined = h1.wrapping_add((i as u64).wrapping_mul(h2));
            let idx = (combined as usize) % self.num_bits;
            if self.bits[idx / 8] & (1 << (idx % 8)) == 0 {
                return false;
            }
        }
        true
    }

    pub fn is_all_ones(&self) -> bool {
        if self.bits.is_empty() {
            return false;
        }
        self.bits.iter().all(|&b| b == 0xFF)
    }

    pub fn density(&self) -> f64 {
        if self.bits.is_empty() {
            return 0.0;
        }
        let set_bits: usize = self.bits.iter().map(|b| b.count_ones() as usize).sum();
        let total = self.bits.len() * 8;
        set_bits as f64 / total as f64
    }

    pub fn is_likely_poisoned(&self) -> bool {
        if self.byte_size() > MAX_FILTER_BYTES {
            return true;
        }
        if self.is_all_ones() && self.item_count > 0 {
            return true;
        }
        if self.num_hashes == 0 || self.num_bits == 0 {
            return self.item_count > 0;
        }
        if self.density() > 0.95 && self.item_count < 10000 {
            return true;
        }
        if self.item_count > 0 {
            let expected_bits = optimal_num_bits(self.item_count, 0.01);
            if self.num_bits > 0 && self.num_bits > expected_bits * 100 {
                return true;
            }
        }
        false
    }

    pub fn is_stale(&self, max_age_secs: u64) -> bool {
        if self.timestamp == 0 {
            return true;
        }
        current_secs().saturating_sub(self.timestamp) > max_age_secs
    }

    pub fn estimated_fpr(&self) -> f64 {
        if self.item_count == 0 || self.num_bits == 0 {
            return 0.0;
        }
        let k = self.num_hashes as f64;
        let n = self.item_count as f64;
        let m = self.num_bits as f64;
        (1.0 - (-k * n / m).exp()).powf(k)
    }

    pub fn byte_size(&self) -> usize {
        self.bits.len()
    }

    pub fn item_count(&self) -> usize {
        self.item_count
    }

    pub fn timestamp(&self) -> u64 {
        self.timestamp
    }

    pub fn bits_as_vec(&self) -> Vec<u8> {
        self.bits.clone()
    }

    pub fn num_hashes(&self) -> usize {
        self.num_hashes
    }

    pub fn num_bits(&self) -> usize {
        self.num_bits
    }
}

fn optimal_num_bits(n: usize, p: f64) -> usize {
    if n == 0 || !p.is_finite() || p <= 0.0 || p >= 1.0 {
        return 8;
    }
    let m = -(n as f64 * p.ln()) / (std::f64::consts::LN_2.powi(2));
    if !m.is_finite() || m < 0.0 {
        return 8;
    }
    (m.ceil() as usize).max(8)
}

fn optimal_num_hashes(m: usize, n: usize) -> usize {
    if n == 0 {
        return 1;
    }
    let k = (m as f64 / n as f64) * std::f64::consts::LN_2;
    if !k.is_finite() || k < 0.0 {
        return 1;
    }
    (k.round() as usize).max(1)
}

fn double_hash(data: &[u8]) -> (u64, u64) {
    let mut hasher1 = DefaultHasher::new();
    let mut hasher2 = DefaultHasher::new();
    data.hash(&mut hasher1);
    (data.len() as u64).hash(&mut hasher2);
    data.hash(&mut hasher2);
    (hasher1.finish(), hasher2.finish())
}

fn current_secs() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bloom_filter_basic() {
        let mut filter = ServerBloomFilter::new(100, 0.01);
        for i in 0..100u64 {
            filter.insert(&i.to_le_bytes());
        }
        for i in 0..100u64 {
            assert!(
                filter.contains(&i.to_le_bytes()),
                "item {} should be present",
                i
            );
        }
    }

    #[test]
    fn bloom_filter_false_negative_never() {
        let mut filter = ServerBloomFilter::new(1000, 0.01);
        for i in 0..1000u64 {
            filter.insert(&i.to_le_bytes());
        }
        let mut false_negatives = 0;
        for i in 0..1000u64 {
            if !filter.contains(&i.to_le_bytes()) {
                false_negatives += 1;
            }
        }
        assert_eq!(
            false_negatives, 0,
            "Bloom filters must never have false negatives"
        );
    }

    #[test]
    fn bloom_filter_false_positive_rate() {
        let mut filter = ServerBloomFilter::new(10000, 0.01);
        for i in 0..10000u64 {
            filter.insert(&i.to_le_bytes());
        }
        let mut false_positives = 0;
        let test_count = 10000u64;
        for i in 10000..(10000 + test_count) {
            if filter.contains(&i.to_le_bytes()) {
                false_positives += 1;
            }
        }
        let observed_fpr = false_positives as f64 / test_count as f64;
        assert!(
            observed_fpr < 0.05,
            "observed FPR {} should be < 5%",
            observed_fpr
        );
    }

    #[test]
    fn bloom_filter_all_ones_detected() {
        let mut filter = ServerBloomFilter::new(10, 0.01);
        filter.bits = vec![0xFF; filter.bits.len()];
        filter.item_count = 10;
        assert!(
            filter.is_likely_poisoned(),
            "all-ones filter should be detected"
        );
    }

    #[test]
    fn bloom_filter_size_limit() {
        let mut filter = ServerBloomFilter::new(10, 0.01);
        filter.bits = vec![0; MAX_FILTER_BYTES + 1];
        assert!(
            filter.is_likely_poisoned(),
            "oversized filter should be detected"
        );
    }

    #[test]
    fn bloom_filter_stale_detection() {
        let mut filter = ServerBloomFilter::new(10, 0.01);
        filter.timestamp = current_secs() - 3600;
        assert!(
            filter.is_stale(300),
            "1-hour-old filter should be stale at 5-min threshold"
        );
        assert!(
            !filter.is_stale(7200),
            "1-hour-old filter should not be stale at 2-hour threshold"
        );
    }

    #[test]
    fn bloom_filter_estimated_fpr() {
        let filter = ServerBloomFilter::new(10000, 0.01);
        assert!(
            filter.estimated_fpr() < 0.02,
            "estimated FPR should be < 2%"
        );
    }

    #[test]
    fn bloom_filter_empty() {
        let filter = ServerBloomFilter::empty();
        assert!(!filter.contains(&42u64.to_le_bytes()));
        assert_eq!(filter.item_count(), 0);
    }

    #[test]
    fn from_network_rejects_oversized() {
        let result = ServerBloomFilter::from_network(
            vec![0; MAX_FILTER_BYTES + 1],
            7,
            (MAX_FILTER_BYTES + 1) * 8,
            100,
            current_secs(),
        );
        assert!(result.is_err(), "oversized filter should be rejected");
    }

    #[test]
    fn from_network_rejects_too_many_hashes() {
        let result = ServerBloomFilter::from_network(
            vec![0; 100],
            MAX_NUM_HASHES + 1,
            800,
            10,
            current_secs(),
        );
        assert!(result.is_err(), "excessive hash count should be rejected");
    }

    #[test]
    fn from_network_rejects_zero_hashes_with_items() {
        let result = ServerBloomFilter::from_network(vec![0; 100], 0, 800, 50, current_secs());
        assert!(
            result.is_err(),
            "zero hashes with non-zero items should be rejected"
        );
    }

    #[test]
    fn from_network_rejects_bits_too_small() {
        let result = ServerBloomFilter::from_network(vec![0; 10], 7, 1000, 10, current_secs());
        assert!(
            result.is_err(),
            "bits too small for claimed num_bits should be rejected"
        );
    }

    #[test]
    fn from_network_rejects_all_ones() {
        let result = ServerBloomFilter::from_network(vec![0xFF; 100], 7, 800, 10, current_secs());
        assert!(
            result.is_err(),
            "all-ones filter should be rejected as poisoned"
        );
    }

    #[test]
    fn from_network_rejects_high_density_small_count() {
        let bits = vec![0xFF; 100];
        let result = ServerBloomFilter::from_network(bits, 7, 800, 3, current_secs());
        assert!(
            result.is_err(),
            "all-ones density with tiny item count should be suspicious"
        );
    }

    #[test]
    fn from_network_rejects_implausible_size_ratio() {
        let result = ServerBloomFilter::from_network(vec![0; 100000], 7, 800000, 5, current_secs());
        assert!(
            result.is_err(),
            "implausibly large filter for item count should be rejected"
        );
    }

    #[test]
    fn from_network_accepts_valid_filter() {
        let mut local = ServerBloomFilter::new(100, 0.01);
        for i in 0..50u64 {
            local.insert(&i.to_le_bytes());
        }
        let result = ServerBloomFilter::from_network(
            local.bits_as_vec(),
            local.num_hashes(),
            local.num_bits(),
            local.item_count(),
            local.timestamp(),
        );
        assert!(result.is_ok(), "valid filter should be accepted");
    }

    #[test]
    fn from_network_accepts_empty_filter() {
        let result = ServerBloomFilter::from_network(Vec::new(), 0, 0, 0, current_secs());
        assert!(result.is_ok(), "empty filter should be accepted");
    }

    #[test]
    fn from_network_rejects_timestamp_zero() {
        let result = ServerBloomFilter::from_network(vec![0; 100], 7, 800, 10, 0);
        let filter = result.unwrap();
        assert!(filter.is_stale(1), "timestamp=0 should be treated as stale");
    }

    #[test]
    fn insert_empty_data_is_noop() {
        let mut filter = ServerBloomFilter::new(100, 0.01);
        filter.insert(&[]);
        assert_eq!(
            filter.item_count(),
            0,
            "empty data insert should be a no-op"
        );
        assert!(!filter.contains(&[]), "empty data should not match");
    }

    #[test]
    fn new_with_nan_fpr_uses_default() {
        let filter = ServerBloomFilter::new(100, f64::NAN);
        assert!(filter.num_bits > 0, "NaN FPR should fall back to default");
    }

    #[test]
    fn new_with_zero_fpr_uses_default() {
        let filter = ServerBloomFilter::new(100, 0.0);
        assert!(filter.num_bits > 0, "zero FPR should fall back to default");
    }

    #[test]
    fn new_with_negative_fpr_uses_default() {
        let filter = ServerBloomFilter::new(100, -1.0);
        assert!(
            filter.num_bits > 0,
            "negative FPR should fall back to default"
        );
    }

    #[test]
    fn new_with_inf_fpr_uses_default() {
        let filter = ServerBloomFilter::new(100, f64::INFINITY);
        assert!(
            filter.num_bits > 0,
            "infinity FPR should fall back to default"
        );
    }

    #[test]
    fn new_with_zero_item_count_uses_minimum() {
        let filter = ServerBloomFilter::new(0, 0.01);
        assert!(
            filter.num_bits >= 8,
            "zero item count should use minimum bits"
        );
    }

    #[test]
    fn new_clamps_hash_count_to_max() {
        let filter = ServerBloomFilter::new(1, 0.000001);
        assert!(
            filter.num_hashes <= MAX_NUM_HASHES,
            "hash count should be clamped to MAX_NUM_HASHES"
        );
    }

    #[test]
    fn contains_on_empty_filter_returns_false() {
        let filter = ServerBloomFilter::empty();
        assert!(!filter.contains(&1u64.to_le_bytes()));
        assert!(!filter.contains(&[0xFF; 32]));
        assert!(!filter.contains(&[]));
    }

    #[test]
    fn large_insert_does_not_panic() {
        let mut filter = ServerBloomFilter::new(10000, 0.01);
        for i in 0..50000u64 {
            filter.insert(&i.to_le_bytes());
        }
        assert_eq!(filter.item_count(), 50000);
        assert!(filter.contains(&0u64.to_le_bytes()));
        assert!(filter.contains(&49999u64.to_le_bytes()));
    }

    #[test]
    fn density_of_empty_filter_is_zero() {
        let filter = ServerBloomFilter::empty();
        assert_eq!(filter.density(), 0.0);
    }

    #[test]
    fn density_increases_with_inserts() {
        let mut filter = ServerBloomFilter::new(1000, 0.01);
        let d0 = filter.density();
        for i in 0..100u64 {
            filter.insert(&i.to_le_bytes());
        }
        let d1 = filter.density();
        assert!(d1 > d0, "density should increase after inserts");
        assert!(d1 < 0.95, "density should be reasonable for 100 items");
    }

    #[test]
    fn determinism_same_data_same_result() {
        let mut f1 = ServerBloomFilter::new(100, 0.01);
        let mut f2 = ServerBloomFilter::new(100, 0.01);
        for i in 0..50u64 {
            f1.insert(&i.to_le_bytes());
            f2.insert(&i.to_le_bytes());
        }
        for i in 0..200u64 {
            assert_eq!(
                f1.contains(&i.to_le_bytes()),
                f2.contains(&i.to_le_bytes()),
                "same data should produce same results for item {}",
                i
            );
        }
    }

    #[test]
    fn from_network_preserves_query_behavior() {
        let mut local = ServerBloomFilter::new(200, 0.01);
        for i in 0..100u64 {
            local.insert(&i.to_le_bytes());
        }
        let remote = ServerBloomFilter::from_network(
            local.bits_as_vec(),
            local.num_hashes(),
            local.num_bits(),
            local.item_count(),
            local.timestamp(),
        )
        .unwrap();
        for i in 0..100u64 {
            assert!(
                remote.contains(&i.to_le_bytes()),
                "remote filter should match local for inserted item {}",
                i
            );
        }
    }

    #[test]
    fn from_network_rejects_bits_with_zero_numbits() {
        let result = ServerBloomFilter::from_network(vec![0; 10], 0, 0, 0, current_secs());
        assert!(
            result.is_err(),
            "non-empty bits with zero num_bits should be rejected"
        );
    }

    #[test]
    fn is_stale_with_zero_timestamp() {
        let filter = ServerBloomFilter {
            bits: vec![0; 10],
            num_hashes: 7,
            num_bits: 80,
            item_count: 5,
            timestamp: 0,
        };
        assert!(filter.is_stale(1), "timestamp=0 should always be stale");
    }
}
