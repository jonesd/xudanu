use std::io::Write;
use std::sync::{Arc, Mutex, RwLock};

use sha2::{Digest, Sha256};

#[allow(dead_code)]
const SEED_FILE: &str = "security.log.seed";

#[derive(Debug, Clone)]
pub struct ChainState {
    pub entries: u64,
    pub head_hash: String,
}

static SECURITY_CHAIN_STATE: RwLock<Option<Arc<Mutex<ChainState>>>> = RwLock::new(None);

pub fn install_security_chain_state(state: Arc<Mutex<ChainState>>) {
    let mut guard = SECURITY_CHAIN_STATE
        .write()
        .unwrap_or_else(|e| e.into_inner());
    *guard = Some(state);
}

pub fn security_chain_state() -> Option<Arc<Mutex<ChainState>>> {
    SECURITY_CHAIN_STATE
        .read()
        .unwrap_or_else(|e| e.into_inner())
        .clone()
}

pub fn is_security_log_file(name: &str) -> bool {
    name.starts_with("security.log")
        && !name.ends_with(".seed")
        && !name.contains(".checkpoint.")
        && !name.ends_with(".trash")
        && name != "security.log.archive"
}

pub fn live_security_log_files(dir: &std::path::Path) -> Vec<std::path::PathBuf> {
    let mut files: Vec<std::path::PathBuf> = std::fs::read_dir(dir)
        .into_iter()
        .flatten()
        .filter_map(|e| e.ok())
        .filter(|e| {
            let name = e.file_name().to_string_lossy().to_string();
            is_security_log_file(&name)
        })
        .map(|e| e.path())
        .filter(|p| p.is_file())
        .collect();
    files.sort();
    files
}

/// Recover the cumulative chain state (line count + head hash) by
/// scanning existing log files. Anchors at the seed when no lines exist.
pub fn recover_chain_state(dir: &std::path::Path) -> ChainState {
    let seed = std::fs::read_to_string(dir.join(SEED_FILE))
        .map(|s| s.trim().to_string())
        .unwrap_or_default();
    let mut entries = 0u64;
    let mut head = seed;
    for path in live_security_log_files(dir) {
        if let Ok(content) = std::fs::read_to_string(&path) {
            for line in content.lines() {
                if line.is_empty() {
                    continue;
                }
                entries += 1;
                if let Some(pos) = line.rfind(" chain=") {
                    head = line[pos + 7..].to_string();
                }
            }
        }
    }
    ChainState {
        entries,
        head_hash: head,
    }
}

pub struct ChainedLogWriter<W: Write> {
    inner: W,
    prev_hash: String,
    entries: u64,
    chain: Option<Arc<Mutex<ChainState>>>,
}

impl<W: Write> ChainedLogWriter<W> {
    pub fn new(inner: W, seed_path: &std::path::Path) -> std::io::Result<Self> {
        if !seed_path.exists() {
            let seed = format!(
                "xudanu-security-log-seed-{}",
                chrono::Utc::now().timestamp_nanos_opt().unwrap_or(0)
            );
            let hash = sha256_hex(seed.as_bytes());
            std::fs::write(seed_path, &hash)?;
        }
        let state = recover_chain_state(seed_path.parent().unwrap_or(std::path::Path::new(".")));
        let (entries, prev_hash) = (state.entries, state.head_hash);
        let chain = Arc::new(Mutex::new(ChainState {
            entries,
            head_hash: prev_hash.clone(),
        }));
        install_security_chain_state(chain.clone());
        Ok(ChainedLogWriter {
            inner,
            prev_hash,
            entries,
            chain: Some(chain),
        })
    }

    pub fn chain_state(&self) -> ChainState {
        ChainState {
            entries: self.entries,
            head_hash: self.prev_hash.clone(),
        }
    }

    pub fn verify_log(content: &str, seed: &str) -> Result<(usize, String), ChainVerifyError> {
        let mut prev_hash = seed.to_string();
        let mut line_count = 0;
        for line in content.lines() {
            if line.is_empty() {
                continue;
            }
            line_count += 1;
            if let Some(chain_pos) = line.rfind(" chain=") {
                let chain_value = &line[chain_pos + 7..];
                let expected =
                    sha256_hex(format!("{}{}", prev_hash, &line[..chain_pos]).as_bytes());
                if chain_value != expected {
                    return Err(ChainVerifyError {
                        line_number: line_count,
                        expected,
                        found: chain_value.to_string(),
                        line_content: line.to_string(),
                    });
                }
                prev_hash = chain_value.to_string();
            } else {
                return Err(ChainVerifyError {
                    line_number: line_count,
                    expected: "chain hash".to_string(),
                    found: "no chain field".to_string(),
                    line_content: line.to_string(),
                });
            }
        }
        Ok((line_count, prev_hash))
    }

    /// Verify one chained line against `prev`, returning the new head.
    pub fn verify_line(line: &str, prev: &str) -> Result<String, ChainVerifyError> {
        if let Some(chain_pos) = line.rfind(" chain=") {
            let chain_value = &line[chain_pos + 7..];
            let expected = sha256_hex(format!("{}{}", prev, &line[..chain_pos]).as_bytes());
            if chain_value != expected {
                return Err(ChainVerifyError {
                    line_number: 0,
                    expected,
                    found: chain_value.to_string(),
                    line_content: line.to_string(),
                });
            }
            Ok(chain_value.to_string())
        } else {
            Err(ChainVerifyError {
                line_number: 0,
                expected: "chain hash".to_string(),
                found: "no chain field".to_string(),
                line_content: line.to_string(),
            })
        }
    }
}

impl<W: Write> Write for ChainedLogWriter<W> {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        let line = String::from_utf8_lossy(buf);
        let trimmed = line.trim_end_matches('\n').trim_end_matches('\r');
        if trimmed.is_empty() {
            return self.inner.write(buf);
        }

        let chain_input = format!("{}{}", self.prev_hash, trimmed);
        let chain_hash = sha256_hex(chain_input.as_bytes());
        self.prev_hash = chain_hash.clone();
        self.entries += 1;

        if let Some(state) = &self.chain {
            let mut guard = state.lock().unwrap_or_else(|e| e.into_inner());
            guard.entries = self.entries;
            guard.head_hash = chain_hash.clone();
        }

        let chained_line = format!("{} chain={}\n", trimmed, chain_hash);
        self.inner.write_all(chained_line.as_bytes())?;
        Ok(buf.len())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        self.inner.flush()
    }
}

fn sha256_hex(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    format!("{:x}", hasher.finalize())
}

#[derive(Debug)]
pub struct ChainVerifyError {
    pub line_number: usize,
    pub expected: String,
    pub found: String,
    pub line_content: String,
}

impl std::fmt::Display for ChainVerifyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "chain verification failed at line {}: expected '{}', found '{}'",
            self.line_number, self.expected, self.found
        )
    }
}

impl std::error::Error for ChainVerifyError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn roundtrip_verification() {
        let dir = std::env::temp_dir().join(format!("xudanu-chain-test-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let seed_path = dir.join(SEED_FILE);
        let log_path = dir.join("test.log");

        let file = std::fs::File::create(&log_path).unwrap();
        let mut writer = ChainedLogWriter::new(file, &seed_path).unwrap();

        writeln!(writer, "line one").unwrap();
        writeln!(writer, "line two").unwrap();
        writeln!(writer, "line three").unwrap();
        drop(writer);

        let seed = std::fs::read_to_string(&seed_path).unwrap();
        let content = std::fs::read_to_string(&log_path).unwrap();

        let (count, _final_hash) =
            ChainedLogWriter::<std::fs::File>::verify_log(&content, &seed).unwrap();
        assert_eq!(count, 3);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn detects_tampering() {
        let dir = std::env::temp_dir().join(format!("xudanu-chain-tamper-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let seed_path = dir.join(SEED_FILE);
        let log_path = dir.join("test.log");

        let file = std::fs::File::create(&log_path).unwrap();
        let mut writer = ChainedLogWriter::new(file, &seed_path).unwrap();

        writeln!(writer, "line one").unwrap();
        writeln!(writer, "line two").unwrap();
        writeln!(writer, "line three").unwrap();
        drop(writer);

        let seed = std::fs::read_to_string(&seed_path).unwrap();
        let content = std::fs::read_to_string(&log_path).unwrap();
        let tampered = content.replace("line two", "LINE TWO");

        let result = ChainedLogWriter::<std::fs::File>::verify_log(&tampered, &seed);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.line_number, 2);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn detects_deletion() {
        let dir = std::env::temp_dir().join(format!("xudanu-chain-delete-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let seed_path = dir.join(SEED_FILE);
        let log_path = dir.join("test.log");

        let file = std::fs::File::create(&log_path).unwrap();
        let mut writer = ChainedLogWriter::new(file, &seed_path).unwrap();

        writeln!(writer, "line one").unwrap();
        writeln!(writer, "line two").unwrap();
        writeln!(writer, "line three").unwrap();
        drop(writer);

        let seed = std::fs::read_to_string(&seed_path).unwrap();
        let content = std::fs::read_to_string(&log_path).unwrap();

        let lines: Vec<&str> = content.lines().collect();
        let truncated = format!("{}\n{}\n", lines[0], lines[2]);

        let result = ChainedLogWriter::<std::fs::File>::verify_log(&truncated, &seed);
        assert!(result.is_err());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn multi_file_chain_verification() {
        let dir = std::env::temp_dir().join(format!("xudanu-chain-multi-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let seed_path = dir.join(SEED_FILE);
        let log1 = dir.join("security.log.2026-05-15");
        let log2 = dir.join("security.log.2026-05-16");

        let file1 = std::fs::File::create(&log1).unwrap();
        let mut writer = ChainedLogWriter::new(file1, &seed_path).unwrap();
        writeln!(writer, "day1 line one").unwrap();
        writeln!(writer, "day1 line two").unwrap();
        drop(writer);

        let seed = std::fs::read_to_string(&seed_path)
            .unwrap()
            .trim()
            .to_string();
        let content1 = std::fs::read_to_string(&log1).unwrap();
        let (count1, final_hash1) =
            ChainedLogWriter::<std::fs::File>::verify_log(&content1, &seed).unwrap();
        assert_eq!(count1, 2);

        let file2 = std::fs::File::create(&log2).unwrap();
        let mut writer2 = ChainedLogWriter {
            inner: file2,
            prev_hash: final_hash1.clone(),
            entries: 2,
            chain: None,
        };
        writeln!(writer2, "day2 line one").unwrap();
        writeln!(writer2, "day2 line two").unwrap();
        drop(writer2);

        let content2 = std::fs::read_to_string(&log2).unwrap();
        let (count2, _final_hash2) =
            ChainedLogWriter::<std::fs::File>::verify_log(&content2, &final_hash1).unwrap();
        assert_eq!(count2, 2);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn restart_recovers_head_and_entries() {
        let dir = std::env::temp_dir().join(format!("xudanu-chain-restart-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let seed_path = dir.join(SEED_FILE);
        let log1 = dir.join("security.log.2026-09-01");

        let file1 = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&log1)
            .unwrap();
        let mut writer = ChainedLogWriter::new(file1, &seed_path).unwrap();
        writeln!(writer, "entry one").unwrap();
        writeln!(writer, "entry two").unwrap();
        let snap = writer.chain_state();
        assert_eq!(snap.entries, 2);
        drop(writer);

        let file2 = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&log1)
            .unwrap();
        let mut writer2 = ChainedLogWriter::new(file2, &seed_path).unwrap();
        let recovered = writer2.chain_state();
        assert_eq!(recovered.entries, 2);
        assert_eq!(recovered.head_hash, snap.head_hash);
        writeln!(writer2, "entry three").unwrap();
        let snap2 = writer2.chain_state();
        assert_eq!(snap2.entries, 3);
        assert_ne!(snap2.head_hash, snap.head_hash);
        drop(writer2);

        let seed = std::fs::read_to_string(&seed_path)
            .unwrap()
            .trim()
            .to_string();
        let content = std::fs::read_to_string(&log1).unwrap();
        let (count, _) = ChainedLogWriter::<std::fs::File>::verify_log(&content, &seed).unwrap();
        assert_eq!(count, 3);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn recovery_excludes_checkpoint_and_seed_files() {
        let dir = std::env::temp_dir().join(format!("xudanu-chain-scan-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        std::fs::write(dir.join("security.log.seed"), "seedhash").unwrap();
        std::fs::write(dir.join("security.log.checkpoint.000001"), "{}").unwrap();
        std::fs::write(dir.join("security.log.2026-09-01"), "not-a-chain-line\n").unwrap();

        let files = live_security_log_files(&dir);
        assert_eq!(files.len(), 1);
        assert_eq!(
            files[0].file_name().unwrap().to_string_lossy(),
            "security.log.2026-09-01"
        );

        let state = recover_chain_state(&dir);
        assert_eq!(state.entries, 1);

        let _ = std::fs::remove_dir_all(&dir);
    }
}
