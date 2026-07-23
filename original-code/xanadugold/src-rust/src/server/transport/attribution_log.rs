use std::io::Write;

use sha2::{Digest, Sha256};

const SEED_FILE: &str = "attribution.log.seed";

pub enum AttributionLog {
    File(FileAttributionLog),
    InMemory(InMemoryAttributionLog),
}

pub struct FileAttributionLog {
    inner: std::fs::File,
    prev_hash: String,
    sequence: u64,
}

pub struct InMemoryAttributionLog {
    prev_hash: String,
    sequence: u64,
}

#[derive(Debug)]
pub struct AttributionEntry {
    pub sequence: u64,
    pub timestamp: u64,
    pub author_pk_hex: String,
    pub span_fp_hex: String,
    pub signature_hex: String,
    pub server_id_hex: String,
    pub work_id: u64,
    pub revision: u64,
    pub source_work_id: Option<u64>,
    pub source_license: Option<String>,
}

impl AttributionLog {
    pub fn open(data_dir: &std::path::Path) -> Result<Self, std::io::Error> {
        let log_dir = data_dir.join("attribution");
        std::fs::create_dir_all(&log_dir)?;

        let seed_path = log_dir.join(SEED_FILE);
        let prev_hash = if seed_path.exists() {
            std::fs::read_to_string(&seed_path)?.trim().to_string()
        } else {
            let seed = format!(
                "xudanu-attribution-log-seed-{}",
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_nanos()
            );
            let hash = sha256_hex(seed.as_bytes());
            std::fs::write(&seed_path, &hash)?;
            hash
        };

        let log_path = log_dir.join("attribution.log");
        let file = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&log_path)?;

        let (sequence, prev_hash) = if log_path.exists() {
            let content = std::fs::read_to_string(&log_path).unwrap_or_default();
            let line_count = content.lines().filter(|l| !l.is_empty()).count() as u64;
            let last_hash = content
                .lines()
                .filter(|l| !l.is_empty())
                .last()
                .and_then(|l| l.rfind(" chain=").map(|pos| l[pos + 7..].to_string()))
                .unwrap_or(prev_hash);
            (line_count, last_hash)
        } else {
            (0, prev_hash)
        };

        Ok(AttributionLog::File(FileAttributionLog {
            inner: file,
            prev_hash,
            sequence,
        }))
    }

    pub fn in_memory() -> Self {
        let seed = format!(
            "xudanu-attribution-inmemory-seed-{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos()
        );
        AttributionLog::InMemory(InMemoryAttributionLog {
            prev_hash: sha256_hex(seed.as_bytes()),
            sequence: 0,
        })
    }

    pub fn append(&mut self, entry: &AttributionEntry) -> Result<(), std::io::Error> {
        match self {
            AttributionLog::File(log) => log.append(entry),
            AttributionLog::InMemory(log) => {
                log.append(entry);
                Ok(())
            }
        }
    }

    pub fn sequence(&self) -> u64 {
        match self {
            AttributionLog::File(log) => log.sequence(),
            AttributionLog::InMemory(log) => log.sequence(),
        }
    }

    pub fn is_in_memory(&self) -> bool {
        matches!(self, AttributionLog::InMemory(_))
    }
}

impl FileAttributionLog {
    pub fn append(&mut self, entry: &AttributionEntry) -> Result<(), std::io::Error> {
        let mut line = format!(
            "{{\"seq\":{},\"ts\":{},\"author\":\"{}\",\"span_fp\":\"{}\",\"sig\":\"{}\",\"server\":\"{}\",\"work\":{},\"rev\":{}}}",
            entry.sequence,
            entry.timestamp,
            entry.author_pk_hex,
            entry.span_fp_hex,
            entry.signature_hex,
            entry.server_id_hex,
            entry.work_id,
            entry.revision,
        );
        if let Some(swid) = entry.source_work_id {
            line = format!(
                "{},\"src_work\":{},\"src_lic\":\"{}\"}}",
                &line[..line.len() - 1],
                swid,
                entry.source_license.as_deref().unwrap_or(""),
            );
        }

        let chain_input = format!("{}{}", self.prev_hash, line);
        let chain_hash = sha256_hex(chain_input.as_bytes());

        let chained_line = format!("{} chain={}\n", line, chain_hash);
        self.inner.write_all(chained_line.as_bytes())?;
        self.inner.flush()?;
        self.prev_hash = chain_hash;
        self.sequence += 1;
        Ok(())
    }

    pub fn sequence(&self) -> u64 {
        self.sequence
    }
}

impl InMemoryAttributionLog {
    fn append(&mut self, entry: &AttributionEntry) {
        let mut line = format!(
            "{{\"seq\":{},\"ts\":{},\"author\":\"{}\",\"span_fp\":\"{}\",\"sig\":\"{}\",\"server\":\"{}\",\"work\":{},\"rev\":{}}}",
            entry.sequence,
            entry.timestamp,
            entry.author_pk_hex,
            entry.span_fp_hex,
            entry.signature_hex,
            entry.server_id_hex,
            entry.work_id,
            entry.revision,
        );
        if let Some(swid) = entry.source_work_id {
            line = format!(
                "{},\"src_work\":{},\"src_lic\":\"{}\"}}",
                &line[..line.len() - 1],
                swid,
                entry.source_license.as_deref().unwrap_or(""),
            );
        }

        let chain_input = format!("{}{}", self.prev_hash, line);
        self.prev_hash = sha256_hex(chain_input.as_bytes());
        self.sequence += 1;
    }

    pub fn sequence(&self) -> u64 {
        self.sequence
    }
}

fn sha256_hex(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    format!("{:x}", hasher.finalize())
}

pub fn verify_attribution_log(
    content: &str,
    seed: &str,
) -> Result<(usize, String), ChainVerifyError> {
    let mut prev_hash = seed.to_string();
    let mut line_count = 0;
    for line in content.lines() {
        if line.is_empty() {
            continue;
        }
        line_count += 1;
        if let Some(chain_pos) = line.rfind(" chain=") {
            let chain_value = &line[chain_pos + 7..];
            let expected = sha256_hex(format!("{}{}", prev_hash, &line[..chain_pos]).as_bytes());
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
            "attribution log chain verification failed at line {}: expected '{}', found '{}'",
            self.line_number, self.expected, self.found
        )
    }
}

impl std::error::Error for ChainVerifyError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn append_and_verify() {
        let dir = std::env::temp_dir().join(format!("xudanu-attrib-test-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut log = AttributionLog::open(&dir).unwrap();

        log.append(&AttributionEntry {
            sequence: 0,
            timestamp: 1000,
            author_pk_hex: "aa".repeat(32),
            span_fp_hex: "bb".repeat(64),
            signature_hex: "cc".repeat(64),
            server_id_hex: "dd".repeat(64),
            work_id: 42,
            revision: 1,
            source_work_id: None,
            source_license: None,
        })
        .unwrap();

        log.append(&AttributionEntry {
            sequence: 1,
            timestamp: 2000,
            author_pk_hex: "ee".repeat(32),
            span_fp_hex: "ff".repeat(64),
            signature_hex: "11".repeat(64),
            server_id_hex: "22".repeat(64),
            work_id: 43,
            revision: 2,
            source_work_id: None,
            source_license: None,
        })
        .unwrap();

        let seed = std::fs::read_to_string(dir.join("attribution/attribution.log.seed")).unwrap();
        let content = std::fs::read_to_string(dir.join("attribution/attribution.log")).unwrap();

        let (count, _) = verify_attribution_log(&content, &seed.trim()).unwrap();
        assert_eq!(count, 2);
        assert_eq!(log.sequence(), 2);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn detects_tampering() {
        let dir = std::env::temp_dir().join(format!("xudanu-attrib-tamper-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut log = AttributionLog::open(&dir).unwrap();

        log.append(&AttributionEntry {
            sequence: 0,
            timestamp: 1000,
            author_pk_hex: "aa".repeat(32),
            span_fp_hex: "bb".repeat(64),
            signature_hex: "cc".repeat(64),
            server_id_hex: "dd".repeat(64),
            work_id: 42,
            revision: 1,
            source_work_id: None,
            source_license: None,
        })
        .unwrap();

        let seed = std::fs::read_to_string(dir.join("attribution/attribution.log.seed")).unwrap();
        let content = std::fs::read_to_string(dir.join("attribution/attribution.log")).unwrap();
        let tampered = content.replace("work\":42", "work\":99");

        let result = verify_attribution_log(&tampered, seed.trim());
        assert!(result.is_err());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn detects_deletion() {
        let dir = std::env::temp_dir().join(format!("xudanu-attrib-delete-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut log = AttributionLog::open(&dir).unwrap();

        log.append(&AttributionEntry {
            sequence: 0,
            timestamp: 1000,
            author_pk_hex: "aa".repeat(32),
            span_fp_hex: "bb".repeat(64),
            signature_hex: "cc".repeat(64),
            server_id_hex: "dd".repeat(64),
            work_id: 42,
            revision: 1,
            source_work_id: None,
            source_license: None,
        })
        .unwrap();

        log.append(&AttributionEntry {
            sequence: 1,
            timestamp: 2000,
            author_pk_hex: "ee".repeat(32),
            span_fp_hex: "ff".repeat(64),
            signature_hex: "11".repeat(64),
            server_id_hex: "22".repeat(64),
            work_id: 43,
            revision: 2,
            source_work_id: None,
            source_license: None,
        })
        .unwrap();

        let seed = std::fs::read_to_string(dir.join("attribution/attribution.log.seed")).unwrap();
        let content = std::fs::read_to_string(dir.join("attribution/attribution.log")).unwrap();
        let (_, expected_final_hash) = verify_attribution_log(&content, seed.trim()).unwrap();

        let lines: Vec<&str> = content.lines().collect();
        let truncated = format!("{}\n", lines[0]);
        let (count, actual_final_hash) = verify_attribution_log(&truncated, seed.trim()).unwrap();
        assert_ne!(count, 2);
        assert_ne!(actual_final_hash, expected_final_hash);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn chain_continues_after_restart() {
        let dir =
            std::env::temp_dir().join(format!("xudanu-attrib-restart-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut log = AttributionLog::open(&dir).unwrap();
        log.append(&AttributionEntry {
            sequence: 0,
            timestamp: 1000,
            author_pk_hex: "aa".repeat(32),
            span_fp_hex: "bb".repeat(64),
            signature_hex: "cc".repeat(64),
            server_id_hex: "dd".repeat(64),
            work_id: 42,
            revision: 1,
            source_work_id: None,
            source_license: None,
        })
        .unwrap();
        drop(log);

        let mut log2 = AttributionLog::open(&dir).unwrap();
        assert_eq!(log2.sequence(), 1);
        log2.append(&AttributionEntry {
            sequence: 1,
            timestamp: 2000,
            author_pk_hex: "ee".repeat(32),
            span_fp_hex: "ff".repeat(64),
            signature_hex: "11".repeat(64),
            server_id_hex: "22".repeat(64),
            work_id: 43,
            revision: 2,
            source_work_id: None,
            source_license: None,
        })
        .unwrap();
        drop(log2);

        let seed = std::fs::read_to_string(dir.join("attribution/attribution.log.seed")).unwrap();
        let content = std::fs::read_to_string(dir.join("attribution/attribution.log")).unwrap();
        let (count, _) = verify_attribution_log(&content, seed.trim()).unwrap();
        assert_eq!(count, 2);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn in_memory_log_works() {
        let mut log = AttributionLog::in_memory();
        assert_eq!(log.sequence(), 0);
        assert!(log.is_in_memory());

        log.append(&AttributionEntry {
            sequence: 0,
            timestamp: 1000,
            author_pk_hex: "aa".repeat(32),
            span_fp_hex: "bb".repeat(64),
            signature_hex: "cc".repeat(64),
            server_id_hex: "dd".repeat(64),
            work_id: 42,
            revision: 1,
            source_work_id: None,
            source_license: None,
        })
        .unwrap();

        assert_eq!(log.sequence(), 1);

        log.append(&AttributionEntry {
            sequence: 1,
            timestamp: 2000,
            author_pk_hex: "ee".repeat(32),
            span_fp_hex: "ff".repeat(64),
            signature_hex: "11".repeat(64),
            server_id_hex: "22".repeat(64),
            work_id: 43,
            revision: 2,
            source_work_id: None,
            source_license: None,
        })
        .unwrap();

        assert_eq!(log.sequence(), 2);
    }
}
