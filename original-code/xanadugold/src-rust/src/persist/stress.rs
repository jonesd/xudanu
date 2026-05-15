#[cfg(test)]
mod tests {
    use std::path::PathBuf;
    use std::time::Instant;

    use crate::edition::edition::Edition;
    use crate::edition::work::Work;
    use crate::edition::RangeElement;
    use crate::persist::chunk_store::ChunkStore;
    use crate::persist::edition_chunks::{
        edition_from_chunks, edition_to_chunks, work_from_chunks_current, work_load_revision,
        work_to_chunks, EditionChunkRef, WorkChunkRef,
    };

    #[derive(Debug, Clone, Copy)]
    enum Scale {
        Fast,
        Medium,
        Heavy,
    }

    impl Scale {
        fn label(&self) -> &'static str {
            match self {
                Scale::Fast => "fast",
                Scale::Medium => "medium",
                Scale::Heavy => "heavy",
            }
        }

        fn unique_chunks(&self) -> usize {
            match self {
                Scale::Fast => 2_000,
                Scale::Medium => 10_000,
                Scale::Heavy => 100_000,
            }
        }

        fn editions(&self) -> usize {
            match self {
                Scale::Fast => 10,
                Scale::Medium => 100,
                Scale::Heavy => 500,
            }
        }

        fn revisions(&self) -> usize {
            match self {
                Scale::Fast => 10,
                Scale::Medium => 50,
                Scale::Heavy => 200,
            }
        }

        fn large_edition_entries(&self) -> usize {
            match self {
                Scale::Fast => 1_000,
                Scale::Medium => 5_000,
                Scale::Heavy => 10_000,
            }
        }

        fn read_samples(&self) -> usize {
            match self {
                Scale::Fast => 5_000,
                Scale::Medium => 20_000,
                Scale::Heavy => 100_000,
            }
        }

        fn churn_cycles(&self) -> usize {
            match self {
                Scale::Fast => 3,
                Scale::Medium => 5,
                Scale::Heavy => 10,
            }
        }

        fn churn_objects_per_cycle(&self) -> usize {
            match self {
                Scale::Fast => 200,
                Scale::Medium => 1_000,
                Scale::Heavy => 5_000,
            }
        }
    }

    struct TimingStats {
        samples: Vec<f64>,
    }

    impl TimingStats {
        fn new() -> Self {
            TimingStats { samples: Vec::new() }
        }

        fn record(&mut self, micros: f64) {
            self.samples.push(micros);
        }

        fn mean(&self) -> f64 {
            if self.samples.is_empty() {
                return 0.0;
            }
            self.samples.iter().sum::<f64>() / self.samples.len() as f64
        }

        fn percentile(&self, p: f64) -> f64 {
            if self.samples.is_empty() {
                return 0.0;
            }
            let mut sorted = self.samples.clone();
            sorted.sort_by(|a, b| a.partial_cmp(b).unwrap());
            let idx = ((p / 100.0) * (sorted.len() - 1) as f64).round() as usize;
            sorted[idx.min(sorted.len() - 1)]
        }

        fn count(&self) -> usize {
            self.samples.len()
        }
    }

    struct StressReport {
        scenario: &'static str,
        scale: Scale,
        total_duration_ms: u128,
        write_stats: TimingStats,
        read_stats: TimingStats,
        cache_hits: u64,
        cache_misses: u64,
        cache_hit_rate: f64,
        cache_len_at_end: usize,
        chunks_on_disk: usize,
        disk_bytes: u64,
        extras: Vec<(&'static str, String)>,
    }

    impl StressReport {
        fn print(&self) {
            let divider = "=".repeat(60);
            eprintln!();
            eprintln!("{}", divider);
            eprintln!(
                "Scenario: {} ({})",
                self.scenario, self.scale.label()
            );
            eprintln!("{}", divider);
            eprintln!("Total duration:    {:.1}ms", self.total_duration_ms as f64);

            if self.write_stats.count() > 0 {
                eprintln!(
                    "Writes:            {} ops, avg {:.1}µs, p50 {:.1}µs, p95 {:.1}µs, p99 {:.1}µs",
                    self.write_stats.count(),
                    self.write_stats.mean(),
                    self.write_stats.percentile(50.0),
                    self.write_stats.percentile(95.0),
                    self.write_stats.percentile(99.0),
                );
            }

            if self.read_stats.count() > 0 {
                eprintln!(
                    "Reads:             {} ops, avg {:.1}µs, p50 {:.1}µs, p95 {:.1}µs, p99 {:.1}µs",
                    self.read_stats.count(),
                    self.read_stats.mean(),
                    self.read_stats.percentile(50.0),
                    self.read_stats.percentile(95.0),
                    self.read_stats.percentile(99.0),
                );
            }

            let total_reads = self.cache_hits + self.cache_misses;
            if total_reads > 0 {
                eprintln!(
                    "Cache:             {} hits ({:.1}%), {} misses ({:.1}%), {} in cache",
                    self.cache_hits,
                    self.cache_hit_rate * 100.0,
                    self.cache_misses,
                    (1.0 - self.cache_hit_rate) * 100.0,
                    self.cache_len_at_end,
                );
            }

            eprintln!("Chunks on disk:    {}", self.chunks_on_disk);
            if self.disk_bytes > 0 {
                eprintln!(
                    "Disk usage:        {:.2} MB",
                    self.disk_bytes as f64 / (1024.0 * 1024.0)
                );
            }

            for (label, value) in &self.extras {
                eprintln!("{:20}{}", format!("{}:", label), value);
            }
            eprintln!("{}", divider);
        }
    }

    fn temp_dir(prefix: &str) -> PathBuf {
        static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
        let id = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        std::env::temp_dir().join(format!(
            "xudanu_stress_{}_{}_{}",
            prefix,
            std::process::id(),
            id
        ))
    }

    fn cleanup(dir: &PathBuf) {
        let _ = std::fs::remove_dir_all(dir);
    }

    fn make_edition_with_entries(n: usize, seed: u64) -> Edition {
        let mut edition = Edition::empty();
        for i in 0..n {
            let pos = i as i64;
            let value = RangeElement::data(
                format!("seed-{}-pos-{}-payload-{:08x}", seed, pos, i * 31).into_bytes(),
            );
            edition = edition.with(pos, value);
        }
        edition
    }

    fn make_text_edition(seed: u64, length: usize) -> Edition {
        let text: String = (0..length)
            .map(|i| {
                let base = b"abcdefghijklmnopqrstuvwxyz ";
                let idx = ((seed as usize) + i) % base.len();
                base[idx] as char
            })
            .collect();
        Edition::from_text(&text)
    }

    // ================================================================
    // Scenario 1: Warm-up Ramp
    // ================================================================

    fn run_scenario_01(scale: Scale) {
        let dir = temp_dir("s01");
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();
        store.reset_stats();

        let n = scale.unique_chunks();
        let mut write_stats = TimingStats::new();
        let mut hashes: Vec<[u8; 32]> = Vec::with_capacity(n);
        let mut bytes_written: u64 = 0;

        let start = Instant::now();
        for i in 0..n {
            let data = format!("warmup-chunk-{:08}-data-{:016x}", i, (i as u64).wrapping_mul(2654435761));
            let t0 = Instant::now();
            let hash = store.write_chunk(data.as_bytes()).unwrap();
            write_stats.record(t0.elapsed().as_micros() as f64);
            bytes_written += data.len() as u64;
            hashes.push(hash);
        }
        let total = start.elapsed();

        let (hits, misses, hit_rate, cache_len) = store.cache_stats();
        let chunks_on_disk = store.total_chunks_on_disk().unwrap();
        let disk_bytes = store.disk_bytes().unwrap();

        let report = StressReport {
            scenario: "01: Warm-up Ramp",
            scale,
            total_duration_ms: total.as_millis(),
            write_stats,
            read_stats: TimingStats::new(),
            cache_hits: hits,
            cache_misses: misses,
            cache_hit_rate: hit_rate,
            cache_len_at_end: cache_len,
            chunks_on_disk,
            disk_bytes,
            extras: vec![
                ("Logical bytes", format!("{} bytes ({:.2} MB)", bytes_written, bytes_written as f64 / (1024.0 * 1024.0))),
                ("Writes/sec", format!("{:.0}", n as f64 / total.as_secs_f64())),
                ("Cache capacity", format!("{}", store.cache_capacity())),
            ],
        };
        report.print();

        assert_eq!(chunks_on_disk, n, "all chunks should be on disk");
        assert_eq!(hashes.len(), n);

        cleanup(&dir);
    }

    #[test]
    fn stress_01_warmup_fast() {
        run_scenario_01(Scale::Fast);
    }

    #[test]
    #[ignore]
    fn stress_01_warmup_medium() {
        run_scenario_01(Scale::Medium);
    }

    #[test]
    #[ignore]
    fn stress_01_warmup_heavy() {
        run_scenario_01(Scale::Heavy);
    }

    // ================================================================
    // Scenario 2: Content Deduplication
    // ================================================================

    fn run_scenario_02(scale: Scale) {
        let dir = temp_dir("s02");
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let n = scale.editions();
        let editions_per_shared_text = 5;
        let unique_texts = n / editions_per_shared_text;
        let mut write_stats = TimingStats::new();

        let texts: Vec<String> = (0..unique_texts)
            .map(|i| format!("shared-text-{:08}-the quick brown fox jumps over the lazy dog repeated content here {:016x}", i, (i as u64).wrapping_mul(12345)))
            .collect();

        let mut all_refs: Vec<EditionChunkRef> = Vec::new();

        let start = Instant::now();
        for (text_idx, text) in texts.iter().enumerate() {
            let edition = Edition::from_text(text);
            for copy in 0..editions_per_shared_text {
                let t0 = Instant::now();
                let chunk_ref = edition_to_chunks(&edition, &store).unwrap();
                write_stats.record(t0.elapsed().as_micros() as f64);
                all_refs.push(chunk_ref);
            }
            if text_idx % (unique_texts.max(1) / 10).max(1) == 0 {
                eprintln!("  dedup: {}/{} unique texts written", text_idx + 1, unique_texts);
            }
        }
        let total = start.elapsed();

        let chunks_on_disk = store.total_chunks_on_disk().unwrap();
        let disk_bytes = store.disk_bytes().unwrap();

        let mut unique_hashes: std::collections::HashSet<[u8; 32]> =
            std::collections::HashSet::new();
        for r in &all_refs {
            unique_hashes.insert(r.root_hash);
        }
        let unique_roots = unique_hashes.len();

        let (hits, misses, hit_rate, cache_len) = store.cache_stats();

        let report = StressReport {
            scenario: "02: Content Deduplication",
            scale,
            total_duration_ms: total.as_millis(),
            write_stats,
            read_stats: TimingStats::new(),
            cache_hits: hits,
            cache_misses: misses,
            cache_hit_rate: hit_rate,
            cache_len_at_end: cache_len,
            chunks_on_disk,
            disk_bytes,
            extras: vec![
                ("Total editions", format!("{}", all_refs.len())),
                ("Unique texts", format!("{}", unique_texts)),
                ("Unique root hashes", format!("{}", unique_roots)),
                ("Dedup ratio", format!("{:.2}x", all_refs.len() as f64 / unique_roots as f64)),
            ],
        };
        report.print();

        assert_eq!(
            unique_roots, unique_texts,
            "identical editions should produce identical root hashes"
        );

        cleanup(&dir);
    }

    #[test]
    fn stress_02_dedup_fast() {
        run_scenario_02(Scale::Fast);
    }

    #[test]
    #[ignore]
    fn stress_02_dedup_medium() {
        run_scenario_02(Scale::Medium);
    }

    #[test]
    #[ignore]
    fn stress_02_dedup_heavy() {
        run_scenario_02(Scale::Heavy);
    }

    // ================================================================
    // Scenario 3: Cache Thrashing
    // ================================================================

    fn run_scenario_03(scale: Scale) {
        let dir = temp_dir("s03");
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let n = scale.unique_chunks();
        let read_count = scale.read_samples();
        let mut hashes: Vec<[u8; 32]> = Vec::with_capacity(n);
        let mut write_stats = TimingStats::new();

        let write_start = Instant::now();
        for i in 0..n {
            let data = format!("thrash-{}-{:032x}", i, (i as u64).wrapping_mul(11400714819323198549));
            let t0 = Instant::now();
            let hash = store.write_chunk(data.as_bytes()).unwrap();
            write_stats.record(t0.elapsed().as_micros() as f64);
            hashes.push(hash);
        }
        let write_dur = write_start.elapsed();

        store.reset_stats();
        store.clear_cache();

        let mut read_stats = TimingStats::new();
        let mut rng_state: u64 = 12345;

        let read_start = Instant::now();
        for _ in 0..read_count {
            rng_state = rng_state.wrapping_mul(6364136223846793005).wrapping_add(1);
            let idx = (rng_state >> 33) as usize % hashes.len();
            let t0 = Instant::now();
            let data = store.read_chunk(&hashes[idx]).unwrap();
            read_stats.record(t0.elapsed().as_micros() as f64);
            assert!(!data.is_empty());
        }
        let read_dur = read_start.elapsed();

        let (hits, misses, hit_rate, cache_len) = store.cache_stats();
        let chunks_on_disk = store.total_chunks_on_disk().unwrap();

        let report = StressReport {
            scenario: "03: Cache Thrashing",
            scale,
            total_duration_ms: (write_dur + read_dur).as_millis(),
            write_stats,
            read_stats,
            cache_hits: hits,
            cache_misses: misses,
            cache_hit_rate: hit_rate,
            cache_len_at_end: cache_len,
            chunks_on_disk,
            disk_bytes: store.disk_bytes().unwrap(),
            extras: vec![
                ("Chunks written", format!("{}", n)),
                ("Cache capacity", format!("{}", store.cache_capacity())),
                ("Oversubscription", format!("{:.1}x", n as f64 / store.cache_capacity() as f64)),
                ("Random reads", format!("{}", read_count)),
                ("Reads/sec", format!("{:.0}", read_count as f64 / read_dur.as_secs_f64())),
                ("All reads ok", "YES".to_string()),
            ],
        };
        report.print();

        cleanup(&dir);
    }

    #[test]
    fn stress_03_thrashing_fast() {
        run_scenario_03(Scale::Fast);
    }

    #[test]
    #[ignore]
    fn stress_03_thrashing_medium() {
        run_scenario_03(Scale::Medium);
    }

    #[test]
    #[ignore]
    fn stress_03_thrashing_heavy() {
        run_scenario_03(Scale::Heavy);
    }

    // ================================================================
    // Scenario 4: Hot/Cold Working Set
    // ================================================================

    fn run_scenario_04(scale: Scale) {
        let dir = temp_dir("s04");
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let total_chunks = scale.unique_chunks();
        let hot_count = total_chunks / 5;
        let read_count = scale.read_samples();

        let mut hashes: Vec<[u8; 32]> = Vec::with_capacity(total_chunks);
        let mut write_stats = TimingStats::new();

        for i in 0..total_chunks {
            let data = format!("hotcold-{}-{:032x}", i, (i as u64).wrapping_mul(982451653));
            let t0 = Instant::now();
            let hash = store.write_chunk(data.as_bytes()).unwrap();
            write_stats.record(t0.elapsed().as_micros() as f64);
            hashes.push(hash);
        }

        store.reset_stats();
        store.clear_cache();

        let mut read_stats = TimingStats::new();
        let mut hot_reads: u64 = 0;
        let mut cold_reads: u64 = 0;
        let mut rng_state: u64 = 54321;

        let start = Instant::now();
        for _ in 0..read_count {
            rng_state = rng_state.wrapping_mul(6364136223846793005).wrapping_add(1);
            let r = (rng_state >> 33) as usize % 100;
            let idx = if r < 80 {
                hot_reads += 1;
                let hot_rng = rng_state.wrapping_mul(3);
                (hot_rng >> 33) as usize % hot_count
            } else {
                cold_reads += 1;
                let cold_rng = rng_state.wrapping_mul(7);
                hot_count + (cold_rng >> 33) as usize % (total_chunks - hot_count)
            };
            let idx = idx.min(hashes.len() - 1);
            let t0 = Instant::now();
            let data = store.read_chunk(&hashes[idx]).unwrap();
            read_stats.record(t0.elapsed().as_micros() as f64);
            assert!(!data.is_empty());
        }
        let total = start.elapsed();

        let (hits, misses, hit_rate, cache_len) = store.cache_stats();
        let chunks_on_disk = store.total_chunks_on_disk().unwrap();

        let report = StressReport {
            scenario: "04: Hot/Cold Working Set",
            scale,
            total_duration_ms: total.as_millis(),
            write_stats,
            read_stats,
            cache_hits: hits,
            cache_misses: misses,
            cache_hit_rate: hit_rate,
            cache_len_at_end: cache_len,
            chunks_on_disk,
            disk_bytes: store.disk_bytes().unwrap(),
            extras: vec![
                ("Hot set size", format!("{} ({:.0}%)", hot_count, hot_count as f64 / total_chunks as f64 * 100.0)),
                ("Cold set size", format!("{}", total_chunks - hot_count)),
                ("Hot reads", format!("{} ({:.0}%)", hot_reads, hot_reads as f64 / read_count as f64 * 100.0)),
                ("Cold reads", format!("{} ({:.0}%)", cold_reads, cold_reads as f64 / read_count as f64 * 100.0)),
                ("Ideal hit rate", format!("{:.1}%", 80.0)),
                ("Actual hit rate", format!("{:.1}%", hit_rate * 100.0)),
            ],
        };
        report.print();

        cleanup(&dir);
    }

    #[test]
    fn stress_04_hot_cold_fast() {
        run_scenario_04(Scale::Fast);
    }

    #[test]
    #[ignore]
    fn stress_04_hot_cold_medium() {
        run_scenario_04(Scale::Medium);
    }

    #[test]
    #[ignore]
    fn stress_04_hot_cold_heavy() {
        run_scenario_04(Scale::Heavy);
    }

    // ================================================================
    // Scenario 5: Sequential Scan After Eviction
    // ================================================================

    fn run_scenario_05(scale: Scale) {
        let dir = temp_dir("s05");
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let n = scale.unique_chunks();
        let mut hashes: Vec<[u8; 32]> = Vec::with_capacity(n);
        let mut write_stats = TimingStats::new();

        for i in 0..n {
            let data = format!("scan-{}-{:032x}", i, (i as u64).wrapping_mul(14035924003));
            let t0 = Instant::now();
            let hash = store.write_chunk(data.as_bytes()).unwrap();
            write_stats.record(t0.elapsed().as_micros() as f64);
            hashes.push(hash);
        }

        store.reset_stats();
        store.clear_cache();

        let mut read_stats = TimingStats::new();
        let mut verified = 0usize;

        let start = Instant::now();
        for (i, hash) in hashes.iter().enumerate() {
            let t0 = Instant::now();
            let data = store.read_chunk(hash).unwrap();
            read_stats.record(t0.elapsed().as_micros() as f64);
            let expected = format!("scan-{}-{:032x}", i, (i as u64).wrapping_mul(14035924003));
            assert_eq!(data, expected.as_bytes());
            verified += 1;
        }
        let total = start.elapsed();

        let (hits, misses, hit_rate, cache_len) = store.cache_stats();

        let report = StressReport {
            scenario: "05: Sequential Scan Post-Eviction",
            scale,
            total_duration_ms: total.as_millis(),
            write_stats,
            read_stats,
            cache_hits: hits,
            cache_misses: misses,
            cache_hit_rate: hit_rate,
            cache_len_at_end: cache_len,
            chunks_on_disk: store.total_chunks_on_disk().unwrap(),
            disk_bytes: store.disk_bytes().unwrap(),
            extras: vec![
                ("Chunks scanned", format!("{}", verified)),
                ("Verified correct", format!("{}/{}", verified, n)),
                ("Scan/sec", format!("{:.0}", n as f64 / total.as_secs_f64())),
            ],
        };
        report.print();

        assert_eq!(verified, n, "all chunks must be read and verified");

        cleanup(&dir);
    }

    #[test]
    fn stress_05_scan_fast() {
        run_scenario_05(Scale::Fast);
    }

    #[test]
    #[ignore]
    fn stress_05_scan_medium() {
        run_scenario_05(Scale::Medium);
    }

    #[test]
    #[ignore]
    fn stress_05_scan_heavy() {
        run_scenario_05(Scale::Heavy);
    }

    // ================================================================
    // Scenario 6: Large Editions
    // ================================================================

    fn run_scenario_06(scale: Scale) {
        let dir = temp_dir("s06");
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let n_editions = scale.editions();
        let entries_per = scale.large_edition_entries();
        let mut write_stats = TimingStats::new();
        let mut read_stats = TimingStats::new();
        let mut chunk_counts: Vec<usize> = Vec::new();

        let mut refs: Vec<EditionChunkRef> = Vec::new();

        let start = Instant::now();

        for ed_idx in 0..n_editions {
            let edition = make_edition_with_entries(entries_per, ed_idx as u64);

            let chunks_before = store.total_chunks_on_disk().unwrap();
            let t0 = Instant::now();
            let chunk_ref = edition_to_chunks(&edition, &store).unwrap();
            write_stats.record(t0.elapsed().as_micros() as f64);
            let chunks_after = store.total_chunks_on_disk().unwrap();
            chunk_counts.push(chunks_after - chunks_before);
            refs.push(chunk_ref);

            if ed_idx % (n_editions.max(1) / 5).max(1) == 0 {
                eprintln!(
                    "  large editions: {}/{}, ~{} entries each",
                    ed_idx + 1,
                    n_editions,
                    entries_per
                );
            }
        }
        let write_dur = start.elapsed();

        store.reset_stats();
        store.clear_cache();

        let read_start = Instant::now();
        for (i, chunk_ref) in refs.iter().enumerate() {
            let t0 = Instant::now();
            let restored = edition_from_chunks(chunk_ref, &store).unwrap();
            read_stats.record(t0.elapsed().as_micros() as f64);
            assert_eq!(
                restored.count(),
                entries_per as u64,
                "edition {} should have {} entries",
                i,
                entries_per
            );
        }
        let read_dur = read_start.elapsed();

        let (hits, misses, hit_rate, cache_len) = store.cache_stats();
        let avg_chunks: f64 =
            chunk_counts.iter().sum::<usize>() as f64 / chunk_counts.len().max(1) as f64;
        let chunks_per_entry = 256;

        let report = StressReport {
            scenario: "06: Large Editions",
            scale,
            total_duration_ms: (write_dur + read_dur).as_millis(),
            write_stats,
            read_stats,
            cache_hits: hits,
            cache_misses: misses,
            cache_hit_rate: hit_rate,
            cache_len_at_end: cache_len,
            chunks_on_disk: store.total_chunks_on_disk().unwrap(),
            disk_bytes: store.disk_bytes().unwrap(),
            extras: vec![
                ("Editions", format!("{}", n_editions)),
                ("Entries/edition", format!("{}", entries_per)),
                ("Expected chunks/ed", format!("~{:.1} (1 root + {:.1} entry)", 1.0 + entries_per as f64 / chunks_per_entry as f64, entries_per as f64 / chunks_per_entry as f64)),
                ("Actual avg chunks/ed", format!("{:.1}", avg_chunks)),
                ("Total entries stored", format!("{}", n_editions * entries_per)),
                ("Deserialize all ok", "YES".to_string()),
            ],
        };
        report.print();

        cleanup(&dir);
    }

    #[test]
    fn stress_06_large_editions_fast() {
        run_scenario_06(Scale::Fast);
    }

    #[test]
    #[ignore]
    fn stress_06_large_editions_medium() {
        run_scenario_06(Scale::Medium);
    }

    #[test]
    #[ignore]
    fn stress_06_large_editions_heavy() {
        run_scenario_06(Scale::Heavy);
    }

    // ================================================================
    // Scenario 7: Deep Revision History
    // ================================================================

    fn run_scenario_07(scale: Scale) {
        let dir = temp_dir("s07");
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let n_works = 3.min(scale.editions() / 10).max(1);
        let n_revisions = scale.revisions();

        let mut write_stats = TimingStats::new();
        let mut read_stats = TimingStats::new();
        let mut work_refs: Vec<WorkChunkRef> = Vec::new();

        let start = Instant::now();

        for w in 0..n_works {
            let v0 = make_text_edition(w as u64 * 1000, 200);
            let mut work = Work::new(w as u64 * 100, v0);

            for rev in 1..n_revisions {
                let edition = make_text_edition(w as u64 * 1000 + rev as u64, 200);
                work.revise(edition);
            }

            let t0 = Instant::now();
            let chunk_ref = work_to_chunks(&work, &store).unwrap();
            write_stats.record(t0.elapsed().as_micros() as f64);
            work_refs.push(chunk_ref);

            eprintln!(
                "  revisions: work {}/{}, {} revisions serialized",
                w + 1,
                n_works,
                n_revisions
            );
        }
        let write_dur = start.elapsed();

        let chunks_after_write = store.total_chunks_on_disk().unwrap();

        store.reset_stats();
        store.clear_cache();

        let mut current_read_ns: TimingStats = TimingStats::new();
        let mut history_read_ns: TimingStats = TimingStats::new();

        let read_start = Instant::now();

        for (w_idx, chunk_ref) in work_refs.iter().enumerate() {
            let t0 = Instant::now();
            let restored = work_from_chunks_current(chunk_ref, &store).unwrap();
            current_read_ns.record(t0.elapsed().as_micros() as f64);
            read_stats.record(t0.elapsed().as_micros() as f64);
            assert_eq!(
                restored.revision_count(),
                n_revisions as u64 - 1,
                "work {} revision count mismatch",
                w_idx
            );

            let mut rng_state: u64 = w_idx as u64 * 77777;
            let history_samples = (n_revisions / 5).max(3);
            for _ in 0..history_samples {
                rng_state = rng_state.wrapping_mul(6364136223846793005).wrapping_add(1);
                let rev = (rng_state >> 33) as u64 % n_revisions as u64;
                let t0 = Instant::now();
                let edition = work_load_revision(chunk_ref, rev, &store).unwrap();
                history_read_ns.record(t0.elapsed().as_micros() as f64);
                read_stats.record(t0.elapsed().as_micros() as f64);
                assert!(edition.count() > 0);
            }
        }
        let read_dur = read_start.elapsed();

        let (hits, misses, hit_rate, cache_len) = store.cache_stats();

        let report = StressReport {
            scenario: "07: Deep Revision History",
            scale,
            total_duration_ms: (write_dur + read_dur).as_millis(),
            write_stats,
            read_stats,
            cache_hits: hits,
            cache_misses: misses,
            cache_hit_rate: hit_rate,
            cache_len_at_end: cache_len,
            chunks_on_disk: store.total_chunks_on_disk().unwrap(),
            disk_bytes: store.disk_bytes().unwrap(),
            extras: vec![
                ("Works", format!("{}", n_works)),
                ("Revisions/work", format!("{}", n_revisions)),
                ("Chunks after write", format!("{}", chunks_after_write)),
                ("Current read avg", format!("{:.1}µs", current_read_ns.mean())),
                ("History read avg", format!("{:.1}µs", history_read_ns.mean())),
                ("History read p95", format!("{:.1}µs", history_read_ns.percentile(95.0))),
            ],
        };
        report.print();

        cleanup(&dir);
    }

    #[test]
    fn stress_07_revisions_fast() {
        run_scenario_07(Scale::Fast);
    }

    #[test]
    #[ignore]
    fn stress_07_revisions_medium() {
        run_scenario_07(Scale::Medium);
    }

    #[test]
    #[ignore]
    fn stress_07_revisions_heavy() {
        run_scenario_07(Scale::Heavy);
    }

    // ================================================================
    // Scenario 8: Mixed Read/Write
    // ================================================================

    fn run_scenario_08(scale: Scale) {
        let dir = temp_dir("s08");
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let n = scale.unique_chunks();
        let operations = scale.read_samples();

        let mut hashes: Vec<[u8; 32]> = Vec::with_capacity(n);
        let mut write_stats = TimingStats::new();
        let mut read_stats = TimingStats::new();

        for i in 0..n {
            let data = format!("mixed-{}-{:032x}", i, (i as u64).wrapping_mul(31415926535));
            let hash = store.write_chunk(data.as_bytes()).unwrap();
            hashes.push(hash);
        }

        store.reset_stats();

        let mut writes_during: u64 = 0;
        let mut reads_during: u64 = 0;
        let mut rng_state: u64 = 99999;
        let mut next_id = n;

        let start = Instant::now();
        for _ in 0..operations {
            rng_state = rng_state.wrapping_mul(6364136223846793005).wrapping_add(1);
            let op = (rng_state >> 33) as usize % 100;

            if op < 10 {
                let data = format!(
                    "mixed-new-{}-{:032x}",
                    next_id,
                    (next_id as u64).wrapping_mul(27182818284)
                );
                let t0 = Instant::now();
                let hash = store.write_chunk(data.as_bytes()).unwrap();
                write_stats.record(t0.elapsed().as_micros() as f64);
                hashes.push(hash);
                next_id += 1;
                writes_during += 1;
            } else {
                let idx = ((rng_state >> 16) as usize) % hashes.len();
                let t0 = Instant::now();
                let data = store.read_chunk(&hashes[idx]).unwrap();
                read_stats.record(t0.elapsed().as_micros() as f64);
                assert!(!data.is_empty());
                reads_during += 1;
            }
        }
        let total = start.elapsed();

        let (hits, misses, hit_rate, cache_len) = store.cache_stats();

        let report = StressReport {
            scenario: "08: Mixed Read/Write",
            scale,
            total_duration_ms: total.as_millis(),
            write_stats,
            read_stats,
            cache_hits: hits,
            cache_misses: misses,
            cache_hit_rate: hit_rate,
            cache_len_at_end: cache_len,
            chunks_on_disk: store.total_chunks_on_disk().unwrap(),
            disk_bytes: store.disk_bytes().unwrap(),
            extras: vec![
                ("Initial chunks", format!("{}", n)),
                ("Ops executed", format!("{}", operations)),
                ("New writes", format!("{}", writes_during)),
                ("Reads", format!("{}", reads_during)),
                ("Ratio (r:w)", format!("{:.1}:1", reads_during as f64 / writes_during.max(1) as f64)),
                ("Ops/sec", format!("{:.0}", operations as f64 / total.as_secs_f64())),
            ],
        };
        report.print();

        cleanup(&dir);
    }

    #[test]
    fn stress_08_mixed_fast() {
        run_scenario_08(Scale::Fast);
    }

    #[test]
    #[ignore]
    fn stress_08_mixed_medium() {
        run_scenario_08(Scale::Medium);
    }

    #[test]
    #[ignore]
    fn stress_08_mixed_heavy() {
        run_scenario_08(Scale::Heavy);
    }

    // ================================================================
    // Scenario 9: Fragmentation & Churn
    // ================================================================

    fn run_scenario_09(scale: Scale) {
        let dir = temp_dir("s09");
        let _ = std::fs::remove_dir_all(&dir);
        let store = ChunkStore::open(&dir).unwrap();

        let cycles = scale.churn_cycles();
        let per_cycle = scale.churn_objects_per_cycle();

        let mut write_stats = TimingStats::new();
        let mut read_stats = TimingStats::new();
        let mut disk_sizes: Vec<u64> = Vec::new();

        let mut alive: Vec<[u8; 32]> = Vec::new();

        let start = Instant::now();

        for cycle in 0..cycles {
            for i in 0..per_cycle {
                let data = format!(
                    "churn-c{}-i{}-{:032x}",
                    cycle,
                    i,
                    ((cycle * per_cycle + i) as u64).wrapping_mul(16180339887)
                );
                let t0 = Instant::now();
                let hash = store.write_chunk(data.as_bytes()).unwrap();
                write_stats.record(t0.elapsed().as_micros() as f64);
                alive.push(hash);
            }

            let delete_count = alive.len() / 2;
            let to_delete: Vec<[u8; 32]> =
                alive.drain(0..delete_count).collect();

            for hash in &to_delete {
                let path = {
                    let hex: String = hash.iter().map(|b| format!("{:02x}", b)).collect();
                    let prefix = &hex[..2];
                    dir.join("chunks").join(prefix).join(hex)
                };
                let _ = std::fs::remove_file(&path);
            }

            store.clear_cache();

            for hash in &alive {
                let t0 = Instant::now();
                let result = store.read_chunk(hash);
                read_stats.record(t0.elapsed().as_micros() as f64);
                assert!(result.is_ok(), "surviving chunk should be readable");
            }

            let disk = store.disk_bytes().unwrap();
            let on_disk = store.total_chunks_on_disk().unwrap();
            disk_sizes.push(disk);
            eprintln!(
                "  churn cycle {}/{}: alive={}, on_disk={}, disk={:.2}MB",
                cycle + 1,
                cycles,
                alive.len(),
                on_disk,
                disk as f64 / (1024.0 * 1024.0)
            );
        }
        let total = start.elapsed();

        let (hits, misses, hit_rate, cache_len) = store.cache_stats();
        let first_disk = disk_sizes.first().copied().unwrap_or(0);
        let last_disk = disk_sizes.last().copied().unwrap_or(0);
        let growth_pct = if first_disk > 0 {
            (last_disk as f64 / first_disk as f64 - 1.0) * 100.0
        } else {
            0.0
        };

        let report = StressReport {
            scenario: "09: Fragmentation & Churn",
            scale,
            total_duration_ms: total.as_millis(),
            write_stats,
            read_stats,
            cache_hits: hits,
            cache_misses: misses,
            cache_hit_rate: hit_rate,
            cache_len_at_end: cache_len,
            chunks_on_disk: store.total_chunks_on_disk().unwrap(),
            disk_bytes: store.disk_bytes().unwrap(),
            extras: vec![
                ("Churn cycles", format!("{}", cycles)),
                ("Objects/cycle", format!("{}", per_cycle)),
                ("Surviving chunks", format!("{}", alive.len())),
                ("First cycle disk", format!("{:.2}MB", first_disk as f64 / (1024.0 * 1024.0))),
                ("Last cycle disk", format!("{:.2}MB", last_disk as f64 / (1024.0 * 1024.0))),
                ("Disk growth", format!("{:+.1}%", growth_pct)),
            ],
        };
        report.print();

        cleanup(&dir);
    }

    #[test]
    fn stress_09_churn_fast() {
        run_scenario_09(Scale::Fast);
    }

    #[test]
    #[ignore]
    fn stress_09_churn_medium() {
        run_scenario_09(Scale::Medium);
    }

    #[test]
    #[ignore]
    fn stress_09_churn_heavy() {
        run_scenario_09(Scale::Heavy);
    }

    // ================================================================
    // Scenario 10: Cold Restart
    // ================================================================

    fn run_scenario_10(scale: Scale) {
        let dir = temp_dir("s10");
        let _ = std::fs::remove_dir_all(&dir);

        let n_works = scale.editions().min(50);
        let n_revisions = 10.min(scale.revisions());
        let entries_per = 100.min(scale.large_edition_entries());

        let mut work_refs: Vec<WorkChunkRef> = Vec::new();

        let build_start = Instant::now();
        {
            let store = ChunkStore::open(&dir).unwrap();

            for w in 0..n_works {
                let v0 = make_edition_with_entries(entries_per, w as u64 * 10000);
                let mut work = Work::new(w as u64, v0);

                for rev in 1..n_revisions {
                    let edition = make_edition_with_entries(
                        entries_per,
                        w as u64 * 10000 + rev as u64 * 100,
                    );
                    work.revise(edition);
                }

                let chunk_ref = work_to_chunks(&work, &store).unwrap();
                work_refs.push(chunk_ref);

                if w % (n_works.max(1) / 5).max(1) == 0 {
                    eprintln!(
                        "  cold restart build: work {}/{}, {} entries x {} revisions",
                        w + 1,
                        n_works,
                        entries_per,
                        n_revisions
                    );
                }
            }

            eprintln!(
                "  Built {} works, {} chunks, {:.2}MB",
                n_works,
                store.total_chunks_on_disk().unwrap(),
                store.disk_bytes().unwrap() as f64 / (1024.0 * 1024.0)
            );
        }

        let build_dur = build_start.elapsed();

        let open_start = Instant::now();
        let store = ChunkStore::open(&dir).unwrap();
        let open_dur = open_start.elapsed();

        let mut read_stats = TimingStats::new();
        let mut current_times = TimingStats::new();
        let mut history_times = TimingStats::new();

        let warmup_start = Instant::now();
        for (w_idx, chunk_ref) in work_refs.iter().enumerate() {
            let t0 = Instant::now();
            let work = work_from_chunks_current(chunk_ref, &store).unwrap();
            let elapsed = t0.elapsed();
            read_stats.record(elapsed.as_micros() as f64);
            current_times.record(elapsed.as_micros() as f64);
            assert_eq!(
                work.edition().count(),
                entries_per as u64,
                "work {} current edition entry count mismatch",
                w_idx
            );

            let mid_rev = chunk_ref.revision_count / 2;
            if mid_rev > 0 {
                let t0 = Instant::now();
                let edition = work_load_revision(chunk_ref, mid_rev, &store).unwrap();
                let elapsed = t0.elapsed();
                read_stats.record(elapsed.as_micros() as f64);
                history_times.record(elapsed.as_micros() as f64);
                assert!(edition.count() > 0);
            }
        }
        let warmup_dur = warmup_start.elapsed();

        let (hits, misses, hit_rate, cache_len) = store.cache_stats();

        let report = StressReport {
            scenario: "10: Cold Restart",
            scale,
            total_duration_ms: (build_dur + open_dur + warmup_dur).as_millis(),
            write_stats: TimingStats::new(),
            read_stats,
            cache_hits: hits,
            cache_misses: misses,
            cache_hit_rate: hit_rate,
            cache_len_at_end: cache_len,
            chunks_on_disk: store.total_chunks_on_disk().unwrap(),
            disk_bytes: store.disk_bytes().unwrap(),
            extras: vec![
                ("Works", format!("{}", n_works)),
                ("Entries/work", format!("{}", entries_per)),
                ("Revisions/work", format!("{}", n_revisions)),
                ("Build time", format!("{:.0}ms", build_dur.as_millis())),
                ("Open time", format!("{:.1}ms", open_dur.as_millis())),
                ("Warmup (first read all)", format!("{:.0}ms", warmup_dur.as_millis())),
                ("Current read avg", format!("{:.1}µs", current_times.mean())),
                ("History read avg", format!("{:.1}µs", history_times.mean())),
                ("All data intact", "YES".to_string()),
            ],
        };
        report.print();

        cleanup(&dir);
    }

    #[test]
    fn stress_10_cold_restart_fast() {
        run_scenario_10(Scale::Fast);
    }

    #[test]
    #[ignore]
    fn stress_10_cold_restart_medium() {
        run_scenario_10(Scale::Medium);
    }

    #[test]
    #[ignore]
    fn stress_10_cold_restart_heavy() {
        run_scenario_10(Scale::Heavy);
    }
}
