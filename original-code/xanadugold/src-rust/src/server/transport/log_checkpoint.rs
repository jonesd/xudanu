//! Signed checkpoints and compaction for the hash-chained audit logs
//! (security.log, attribution.log). Checkpoints are Ed25519-signed by the
//! server identity key, anchored in the key-history rotation chain, and
//! permit whole-file compaction without losing tamper evidence.
//!
//! Design: docs/security-log-checkpoints.md

use std::path::{Path, PathBuf};

use crate::crypto::keys::{KeyHistory, ServerKeyPair};

pub const SECURITY_LOG: &str = "security";
pub const ATTRIBUTION_LOG: &str = "attribution";
pub const ATTRIBUTION_DIR: &str = "attribution";

const DOMAIN: &[u8] = b"xudanu-log-checkpoint-v1";

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct LogCheckpoint {
    pub log: String,
    pub seq: u64,
    pub timestamp: u64,
    pub entries: u64,
    pub head_hash: String,
    pub files_covered: Vec<String>,
    pub key_id: u64,
    pub signature: String,
}

fn signing_payload(
    log: &str,
    seq: u64,
    timestamp: u64,
    entries: u64,
    head_hash: &str,
    files_covered: &[String],
) -> Vec<u8> {
    let mut v = Vec::new();
    v.extend_from_slice(DOMAIN);
    v.push(0);
    v.extend_from_slice(log.as_bytes());
    v.push(0);
    v.extend_from_slice(&seq.to_be_bytes());
    v.extend_from_slice(&timestamp.to_be_bytes());
    v.extend_from_slice(&entries.to_be_bytes());
    v.extend_from_slice(head_hash.as_bytes());
    v.push(0);
    for f in files_covered {
        v.extend_from_slice(f.as_bytes());
        v.push(0x1f);
    }
    v
}

fn now_secs() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

pub fn sign_checkpoint(
    keypair: &ServerKeyPair,
    log: &str,
    seq: u64,
    timestamp: u64,
    entries: u64,
    head_hash: &str,
    files_covered: &[String],
) -> LogCheckpoint {
    let payload = signing_payload(log, seq, timestamp, entries, head_hash, files_covered);
    let digest = blake3::hash(&payload);
    let sig = crate::crypto::sign::sign_bytes(&keypair.signing_key, digest.as_bytes());
    LogCheckpoint {
        log: log.to_string(),
        seq,
        timestamp,
        entries,
        head_hash: head_hash.to_string(),
        files_covered: files_covered.to_vec(),
        key_id: keypair.key_id,
        signature: hex::encode(sig.to_bytes()),
    }
}

pub fn verify_checkpoint(cp: &LogCheckpoint, history: &KeyHistory) -> Result<(), String> {
    let entry = history
        .get(cp.key_id)
        .ok_or_else(|| format!("checkpoint key {} not in key history", cp.key_id))?;
    if !history.is_key_valid_at(cp.key_id, cp.timestamp) {
        return Err(format!(
            "checkpoint key {} not valid at timestamp {}",
            cp.key_id, cp.timestamp
        ));
    }
    let sig_bytes = crate::crypto::keys::hex_decode(&cp.signature)
        .map_err(|e| format!("checkpoint signature hex: {}", e))?;
    let sig_arr: [u8; 64] = sig_bytes
        .try_into()
        .map_err(|_| "checkpoint signature must be 64 bytes".to_string())?;
    let sig = ed25519_dalek::Signature::from_bytes(&sig_arr);
    let payload = signing_payload(
        &cp.log,
        cp.seq,
        cp.timestamp,
        cp.entries,
        &cp.head_hash,
        &cp.files_covered,
    );
    let digest = blake3::hash(&payload);
    crate::crypto::sign::verify_signature(&entry.verifying_key, digest.as_bytes(), &sig)
        .map_err(|_| "checkpoint signature verification failed".to_string())
}

pub fn checkpoint_dir(data_dir: &Path, log: &str) -> PathBuf {
    match log {
        ATTRIBUTION_LOG => data_dir.join(ATTRIBUTION_DIR),
        _ => data_dir.to_path_buf(),
    }
}

pub fn checkpoint_name(log: &str, seq: u64) -> String {
    format!("{}.log.checkpoint.{:06}", log, seq)
}

pub fn write_checkpoint_atomic(dir: &Path, cp: &LogCheckpoint) -> std::io::Result<PathBuf> {
    std::fs::create_dir_all(dir)?;
    let final_path = dir.join(checkpoint_name(&cp.log, cp.seq));
    let tmp_path = dir.join(format!("{}.log.checkpoint.{:06}.tmp", cp.log, cp.seq));
    let json = serde_json::to_vec_pretty(cp).map_err(std::io::Error::other)?;
    std::fs::write(&tmp_path, json)?;
    std::fs::rename(&tmp_path, &final_path)?;
    Ok(final_path)
}

#[derive(Debug)]
pub struct LoadError {
    pub file: String,
    pub error: String,
}

pub fn load_checkpoints(data_dir: &Path, log: &str) -> Result<Vec<LogCheckpoint>, LoadError> {
    let dir = checkpoint_dir(data_dir, log);
    let prefix = format!("{}.log.checkpoint.", log);
    let mut cps = Vec::new();
    let entries = match std::fs::read_dir(&dir) {
        Ok(rd) => rd,
        Err(_) => return Ok(cps),
    };
    for e in entries.filter_map(|e| e.ok()) {
        let name = e.file_name().to_string_lossy().to_string();
        if !name.starts_with(&prefix) || name.ends_with(".tmp") || name.ends_with(".ots") {
            continue;
        }
        let content = std::fs::read_to_string(e.path()).map_err(|err| LoadError {
            file: name.clone(),
            error: err.to_string(),
        })?;
        let cp: LogCheckpoint = serde_json::from_str(&content).map_err(|err| LoadError {
            file: name.clone(),
            error: err.to_string(),
        })?;
        if cp.log != log {
            return Err(LoadError {
                file: name,
                error: format!("log field mismatch: expected {}, found {}", log, cp.log),
            });
        }
        cps.push(cp);
    }
    cps.sort_by_key(|c| c.seq);
    Ok(cps)
}

pub fn latest_checkpoint(data_dir: &Path, log: &str) -> Option<LogCheckpoint> {
    load_checkpoints(data_dir, log)
        .ok()
        .and_then(|mut c| c.pop())
}

fn next_seq(existing: &[LogCheckpoint], pending: &[LogCheckpoint]) -> u64 {
    let a = existing.last().map(|c| c.seq).unwrap_or(0);
    let b = pending.last().map(|c| c.seq).unwrap_or(0);
    a.max(b) + 1
}

#[derive(Debug, Clone, PartialEq)]
pub struct CheckpointOutcome {
    pub log: String,
    pub seq: u64,
    pub entries: u64,
    pub head_hash: String,
    pub files_covered: Vec<String>,
}

impl From<&LogCheckpoint> for CheckpointOutcome {
    fn from(cp: &LogCheckpoint) -> Self {
        CheckpointOutcome {
            log: cp.log.clone(),
            seq: cp.seq,
            entries: cp.entries,
            head_hash: cp.head_hash.clone(),
            files_covered: cp.files_covered.clone(),
        }
    }
}

fn security_files_with_archives(data_dir: &Path) -> Vec<PathBuf> {
    let mut named: Vec<(String, PathBuf)> =
        crate::server::transport::chained_log::live_security_log_files(data_dir)
            .into_iter()
            .map(|p| {
                let name = p
                    .file_name()
                    .unwrap_or_default()
                    .to_string_lossy()
                    .to_string();
                (name, p)
            })
            .collect();
    let archive_dir = data_dir.join("security.log.archive");
    if let Ok(rd) = std::fs::read_dir(&archive_dir) {
        for e in rd.filter_map(|e| e.ok()) {
            let name = e.file_name().to_string_lossy().to_string();
            if crate::server::transport::chained_log::is_security_log_file(&name) {
                named.push((name, e.path()));
            }
        }
    }
    named.sort_by(|a, b| a.0.cmp(&b.0));
    named.into_iter().map(|(_, p)| p).collect()
}

/// A checkpoint boundary may sit mid-file (tail checkpoints taken at
/// shutdown, with the file growing again on the next run). Re-attach to
/// the signed head by locating the first line that chains from it, then
/// verify the remainder. Returns (entries beyond the checkpoint, end head).
fn advance_from_checkpoint(content: &str, cp_head: &str) -> Result<(u64, String), String> {
    use crate::server::transport::chained_log::ChainedLogWriter;

    let lines: Vec<&str> = content.lines().filter(|l| !l.is_empty()).collect();
    for (i, line) in lines.iter().enumerate() {
        if let Ok(mut head) = ChainedLogWriter::<std::fs::File>::verify_line(line, cp_head) {
            let mut added = 1u64;
            for line in &lines[i + 1..] {
                head = ChainedLogWriter::<std::fs::File>::verify_line(line, &head)
                    .map_err(|e| e.to_string())?;
                added += 1;
            }
            return Ok((added, head));
        }
    }
    Ok((0, cp_head.to_string()))
}

/// Write checkpoints for every completed security.log daily file not yet
/// covered by an existing checkpoint. One checkpoint per file boundary.
/// `include_tail` also covers the newest file (shutdown / offline use).
pub fn checkpoint_security_log(
    data_dir: &Path,
    keypair: &ServerKeyPair,
    include_tail: bool,
) -> Result<Vec<CheckpointOutcome>, String> {
    use crate::server::transport::chained_log::ChainedLogWriter;

    let existing = load_checkpoints(data_dir, SECURITY_LOG)
        .map_err(|e| format!("load checkpoints: {}: {}", e.file, e.error))?;
    let covering: std::collections::HashMap<String, LogCheckpoint> = existing
        .iter()
        .map(|c| {
            (
                c.files_covered.first().cloned().unwrap_or_default(),
                c.clone(),
            )
        })
        .collect();

    let (mut entries, mut prev) = match existing.last() {
        Some(cp) => (cp.entries, cp.head_hash.clone()),
        None => {
            let seed = std::fs::read_to_string(data_dir.join("security.log.seed"))
                .map(|s| s.trim().to_string())
                .map_err(|e| format!("read seed: {}", e))?;
            (0, seed)
        }
    };

    let files = security_files_with_archives(data_dir);
    if files.is_empty() {
        return Ok(Vec::new());
    }
    let last_idx = files.len() - 1;

    let mut pending: Vec<LogCheckpoint> = Vec::new();
    let mut outcomes = Vec::new();

    let write_cp = |entries: u64,
                    head: &str,
                    name: String,
                    pending: &mut Vec<LogCheckpoint>|
     -> Result<CheckpointOutcome, String> {
        let seq = next_seq(&existing, pending);
        let cp = sign_checkpoint(
            keypair,
            SECURITY_LOG,
            seq,
            now_secs(),
            entries,
            head,
            &[name],
        );
        write_checkpoint_atomic(&checkpoint_dir(data_dir, SECURITY_LOG), &cp)
            .map_err(|e| format!("write checkpoint: {}", e))?;
        let outcome = CheckpointOutcome::from(&cp);
        pending.push(cp);
        Ok(outcome)
    };

    for (i, f) in files.iter().enumerate() {
        let is_tail = i == last_idx;
        if is_tail && !include_tail {
            break;
        }
        let name = f
            .file_name()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string();
        let content = std::fs::read_to_string(f).map_err(|e| format!("read {}: {}", name, e))?;
        match covering.get(&name) {
            Some(cp) => {
                let (added, head) = advance_from_checkpoint(&content, &cp.head_hash)
                    .map_err(|e| format!("{}: {}", name, e))?;
                if entries != cp.entries {
                    return Err(format!(
                        "checkpoint bookkeeping mismatch for {}: expected {} entries, tracking {}",
                        name, cp.entries, entries
                    ));
                }
                entries += added;
                prev = head;
                if is_tail && entries > cp.entries {
                    outcomes.push(write_cp(entries, &prev, name, &mut pending)?);
                }
            }
            None => {
                let (count, head) = ChainedLogWriter::<std::fs::File>::verify_log(&content, &prev)
                    .map_err(|e| format!("chain verify {} failed: {}", name, e))?;
                entries += count as u64;
                prev = head;
                outcomes.push(write_cp(entries, &prev, name, &mut pending)?);
            }
        }
    }
    Ok(outcomes)
}

/// Build and persist an attribution checkpoint over the live chain state,
/// listing the archive name the caller will rotate the current file into.
pub fn checkpoint_attribution_log(
    data_dir: &Path,
    keypair: &ServerKeyPair,
    entries: u64,
    head_hash: &str,
) -> Result<Option<LogCheckpoint>, String> {
    if entries == 0 || head_hash.is_empty() {
        return Ok(None);
    }
    let existing = load_checkpoints(data_dir, ATTRIBUTION_LOG)
        .map_err(|e| format!("load checkpoints: {}: {}", e.file, e.error))?;
    let seq = next_seq(&existing, &[]);
    let archive_name = format!("attribution.log.{:06}", seq);
    let cp = sign_checkpoint(
        keypair,
        ATTRIBUTION_LOG,
        seq,
        now_secs(),
        entries,
        head_hash,
        &[archive_name],
    );
    write_checkpoint_atomic(&checkpoint_dir(data_dir, ATTRIBUTION_LOG), &cp)
        .map_err(|e| format!("write checkpoint: {}", e))?;
    Ok(Some(cp))
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum RetentionMode {
    Archive,
    Delete,
}

/// Remove files covered by checkpoints older than the newest `keep`
/// checkpoints. `keep == 0` keeps everything. Returns the handled files.
pub fn apply_retention(
    data_dir: &Path,
    log: &str,
    keep: usize,
    mode: RetentionMode,
) -> Result<Vec<String>, String> {
    if keep == 0 {
        return Ok(Vec::new());
    }
    let cps = load_checkpoints(data_dir, log)
        .map_err(|e| format!("load checkpoints: {}: {}", e.file, e.error))?;
    if cps.len() <= keep {
        return Ok(Vec::new());
    }
    let protected: std::collections::HashSet<&String> = cps[cps.len() - keep..]
        .iter()
        .flat_map(|c| c.files_covered.iter())
        .collect();
    let evictable: Vec<String> = cps[..cps.len() - keep]
        .iter()
        .flat_map(|c| c.files_covered.iter().cloned())
        .filter(|f| !protected.contains(f))
        .collect();

    let base = checkpoint_dir(data_dir, log);
    let archive_dir = base.join(format!("{}.log.archive", log));
    let mut handled = Vec::new();
    for name in evictable {
        let live = base.join(&name);
        let archived = archive_dir.join(&name);
        let src = if live.exists() {
            live
        } else if archived.exists() {
            archived
        } else {
            continue;
        };
        match mode {
            RetentionMode::Archive => {
                std::fs::create_dir_all(&archive_dir).map_err(|e| e.to_string())?;
                let dst = archive_dir.join(&name);
                if src != dst {
                    std::fs::rename(&src, &dst).map_err(|_| name.clone())?;
                }
            }
            RetentionMode::Delete => {
                let trash = base.join(format!("{}.trash", name));
                std::fs::rename(&src, &trash).map_err(|_| name.clone())?;
                let _ = std::fs::remove_file(&trash);
            }
        }
        handled.push(name);
    }
    Ok(handled)
}

pub fn load_key_history(data_dir: &Path) -> Result<KeyHistory, String> {
    let path = data_dir.join("key_history.json");
    let raw = std::fs::read(&path).map_err(|e| format!("read {}: {}", path.display(), e))?;
    let file: crate::crypto::keys::KeyHistoryFile =
        serde_json::from_slice(&raw).map_err(|e| format!("parse key history: {}", e))?;
    KeyHistory::from_file_repr(&file)
}

#[derive(Debug, Default)]
pub struct VerifyReport {
    pub lines: Vec<String>,
    pub ok: bool,
    pub checked_entries: u64,
    pub checkpoints: usize,
    pub anchored_spans: usize,
}

fn verify_checkpoint_sequence(cps: &[LogCheckpoint]) -> Result<(), String> {
    for pair in cps.windows(2) {
        if pair[1].seq <= pair[0].seq {
            return Err(format!(
                "checkpoint seq not increasing: {} -> {}",
                pair[0].seq, pair[1].seq
            ));
        }
        if pair[1].entries < pair[0].entries {
            return Err(format!(
                "checkpoint entries regressed: {} -> {} at seq {}",
                pair[0].entries, pair[1].entries, pair[1].seq
            ));
        }
    }
    Ok(())
}

fn verify_files_through_boundaries(
    files: &[PathBuf],
    cps: &[LogCheckpoint],
    seed: &str,
    report: &mut VerifyReport,
) -> Result<(), String> {
    use crate::server::transport::chained_log::ChainedLogWriter;

    let name_of = |p: &Path| {
        p.file_name()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string()
    };

    let contents: Vec<(String, Vec<String>)> = files
        .iter()
        .map(|f| {
            let content =
                std::fs::read_to_string(f).map_err(|e| format!("read {}: {}", name_of(f), e))?;
            Ok((
                name_of(f),
                content
                    .lines()
                    .filter(|l| !l.is_empty())
                    .map(|l| l.to_string())
                    .collect::<Vec<String>>(),
            ))
        })
        .collect::<Result<Vec<(String, Vec<String>)>, String>>()?;

    let mut prev = seed.to_string();
    let mut verified: u64 = 0;
    let mut file_idx = 0usize;
    let mut line_idx = 0usize;
    let mut anchored = 0usize;

    let mut next_line = |prev: &mut String, verified: &mut u64| -> Option<Result<(), String>> {
        loop {
            let (_, lines) = contents.get(file_idx)?;
            if line_idx >= lines.len() {
                file_idx += 1;
                line_idx = 0;
                continue;
            }
            let line = &lines[line_idx];
            line_idx += 1;
            match ChainedLogWriter::<std::fs::File>::verify_line(line, prev) {
                Ok(head) => {
                    *prev = head;
                    *verified += 1;
                    return Some(Ok(()));
                }
                Err(e) => {
                    let name = &contents[file_idx.saturating_sub(1)].0;
                    return Some(Err(format!("{}: {}", name, e)));
                }
            }
        }
    };

    for cp in cps {
        if verified > cp.entries {
            continue;
        }
        let boundary_absent = cp
            .files_covered
            .first()
            .map(|b| !contents.iter().any(|(name, _)| name == b))
            .unwrap_or(true);
        if boundary_absent {
            if verified < cp.entries {
                prev = cp.head_hash.clone();
                verified = cp.entries;
                anchored += 1;
            }
            continue;
        }
        while verified < cp.entries {
            match next_line(&mut prev, &mut verified) {
                Some(Ok(())) => {}
                Some(Err(e)) => return Err(e),
                None => {
                    return Err(format!(
                        "checkpoint {} entry count mismatch: signed {}, chain reached {}",
                        cp.seq, cp.entries, verified
                    ))
                }
            }
        }
        if verified == cp.entries && prev != cp.head_hash {
            return Err(format!(
                "checkpoint {} head mismatch: signed {}, chain reached {}",
                cp.seq, cp.head_hash, prev
            ));
        }
    }

    while let Some(step) = next_line(&mut prev, &mut verified) {
        step?;
    }

    report.checked_entries = verified;
    report.anchored_spans = anchored;
    Ok(())
}

pub fn verify_security_log(data_dir: &Path, history: Option<&KeyHistory>) -> VerifyReport {
    let mut report = VerifyReport {
        ok: false,
        ..Default::default()
    };
    let files = security_files_with_archives(data_dir);
    let seed = match std::fs::read_to_string(data_dir.join("security.log.seed")) {
        Ok(s) => s.trim().to_string(),
        // A seed is created on first use; a fresh server with no
        // security entries yet has an empty — trivially intact —
        // chain. Missing seed + no log files is a PASS, not a
        // failure (fresh deployments must not read as broken).
        Err(_) if files.is_empty() => {
            report.ok = true;
            report.lines.push("no chain yet (fresh server, nothing logged)".into());
            return report;
        }
        Err(e) => {
            report.lines.push(format!("cannot read seed: {}", e));
            return report;
        }
    };

    let cps = match load_checkpoints(data_dir, SECURITY_LOG) {
        Ok(c) => c,
        Err(e) => {
            report
                .lines
                .push(format!("checkpoint load failed ({}): {}", e.file, e.error));
            return report;
        }
    };
    report.checkpoints = cps.len();

    if !cps.is_empty() {
        let Some(history) = history else {
            report
                .lines
                .push("checkpoints exist but key_history.json unavailable".into());
            return report;
        };
        for cp in &cps {
            if let Err(e) = verify_checkpoint(cp, history) {
                report.lines.push(format!("checkpoint {}: {}", cp.seq, e));
                return report;
            }
        }
        if let Err(e) = verify_checkpoint_sequence(&cps) {
            report.lines.push(e);
            return report;
        }
    }

    match verify_files_through_boundaries(&files, &cps, &seed, &mut report) {
        Ok(()) => {
            report.ok = true;
            report.lines.push(format!(
                "{} files, {} entries, {} checkpoints, {} anchored span(s), chain intact",
                files.len(),
                report.checked_entries,
                cps.len(),
                report.anchored_spans
            ));
        }
        Err(e) => report.lines.push(e),
    }
    report
}

pub fn attribution_files_with_archives(data_dir: &Path) -> Vec<PathBuf> {
    let dir = data_dir.join(ATTRIBUTION_DIR);
    let mut files = Vec::new();
    if let Ok(rd) = std::fs::read_dir(&dir) {
        for e in rd.filter_map(|e| e.ok()) {
            let name = e.file_name().to_string_lossy().to_string();
            let is_archive = name.starts_with("attribution.log.")
                && name["attribution.log.".len()..]
                    .chars()
                    .all(|c| c.is_ascii_digit());
            if is_archive {
                files.push(e.path());
            }
        }
    }
    files.sort_by(|a, b| {
        let an = a.file_name().unwrap_or_default().to_string_lossy();
        let bn = b.file_name().unwrap_or_default().to_string_lossy();
        an.cmp(&bn)
    });
    let current = dir.join("attribution.log");
    if current.exists() {
        files.push(current);
    }
    files
}

pub fn verify_attribution_log(data_dir: &Path, history: Option<&KeyHistory>) -> VerifyReport {
    let mut report = VerifyReport {
        ok: false,
        ..Default::default()
    };
    let dir = data_dir.join(ATTRIBUTION_DIR);
    let files = attribution_files_with_archives(data_dir);
    let seed = match std::fs::read_to_string(dir.join("attribution.log.seed")) {
        Ok(s) => s.trim().to_string(),
        // Same as the security log: missing seed + no files = a fresh
        // server with nothing attributed yet — trivially intact.
        Err(_) if files.is_empty() => {
            report.ok = true;
            report.lines.push("no chain yet (fresh server, nothing attributed)".into());
            return report;
        }
        Err(e) => {
            report.lines.push(format!("cannot read seed: {}", e));
            return report;
        }
    };

    let cps = match load_checkpoints(data_dir, ATTRIBUTION_LOG) {
        Ok(c) => c,
        Err(e) => {
            report
                .lines
                .push(format!("checkpoint load failed ({}): {}", e.file, e.error));
            return report;
        }
    };
    report.checkpoints = cps.len();

    if !cps.is_empty() {
        let Some(history) = history else {
            report
                .lines
                .push("checkpoints exist but key_history.json unavailable".into());
            return report;
        };
        for cp in &cps {
            if let Err(e) = verify_checkpoint(cp, history) {
                report.lines.push(format!("checkpoint {}: {}", cp.seq, e));
                return report;
            }
        }
        if let Err(e) = verify_checkpoint_sequence(&cps) {
            report.lines.push(e);
            return report;
        }
    }

    match verify_files_through_boundaries(&files, &cps, &seed, &mut report) {
        Ok(()) => {
            report.ok = true;
            report.lines.push(format!(
                "{} files, {} entries, {} checkpoints, {} anchored span(s), chain intact",
                files.len(),
                report.checked_entries,
                cps.len(),
                report.anchored_spans
            ));
        }
        Err(e) => report.lines.push(e),
    }
    report
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_dir(tag: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("xudanu-lcp-{}-{}", tag, std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        dir
    }

    fn write_log(dir: &Path, name: &str, lines: &[&str], prev: &mut String) {
        use std::io::Write;
        let mut out = String::new();
        for line in lines {
            let input = format!("{}{}", prev, line);
            let hash = {
                use sha2::{Digest, Sha256};
                let mut h = Sha256::new();
                h.update(input.as_bytes());
                format!("{:x}", h.finalize())
            };
            out.push_str(&format!("{} chain={}\n", line, hash));
            *prev = hash;
        }
        let mut f = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(dir.join(name))
            .unwrap();
        f.write_all(out.as_bytes()).unwrap();
    }

    #[test]
    fn checkpoint_sign_verify_roundtrip() {
        let kp = ServerKeyPair::generate("test");
        let history = KeyHistory::new(&kp);
        let files = vec!["security.log.2026-09-01".to_string()];
        let cp = sign_checkpoint(&kp, SECURITY_LOG, 1, now_secs(), 5, "abc123", &files);
        assert!(verify_checkpoint(&cp, &history).is_ok());
    }

    #[test]
    fn checkpoint_rejects_tampered_field() {
        let kp = ServerKeyPair::generate("test");
        let history = KeyHistory::new(&kp);
        let mut cp = sign_checkpoint(
            &kp,
            SECURITY_LOG,
            1,
            1000,
            5,
            "abc123",
            &["security.log.2026-09-01".to_string()],
        );
        cp.entries = 6;
        assert!(verify_checkpoint(&cp, &history).is_err());
        cp.entries = 5;
        cp.head_hash = "def456".into();
        assert!(verify_checkpoint(&cp, &history).is_err());
    }

    #[test]
    fn checkpoint_rejects_wrong_key() {
        let kp = ServerKeyPair::generate("test");
        let other = KeyHistory::new(&ServerKeyPair::generate("other"));
        let cp = sign_checkpoint(
            &kp,
            SECURITY_LOG,
            1,
            1000,
            5,
            "abc123",
            &["security.log.2026-09-01".to_string()],
        );
        assert!(verify_checkpoint(&cp, &other).is_err());
    }

    #[test]
    fn security_checkpoint_covers_completed_files() {
        let dir = test_dir("sec-cp");
        let kp = ServerKeyPair::generate("test");
        std::fs::write(dir.join("security.log.seed"), "seedhash").unwrap();
        let mut prev = "seedhash".to_string();
        write_log(&dir, "security.log.2026-09-01", &["a", "b"], &mut prev);
        let head_after_day1 = prev.clone();
        write_log(&dir, "security.log.2026-09-02", &["c"], &mut prev);

        let outcomes = checkpoint_security_log(&dir, &kp, false).unwrap();
        assert_eq!(outcomes.len(), 1);
        assert_eq!(
            outcomes[0].files_covered,
            vec!["security.log.2026-09-01".to_string()]
        );
        assert_eq!(outcomes[0].entries, 2);
        assert_eq!(outcomes[0].head_hash, head_after_day1);

        let history = KeyHistory::new(&kp);
        let report = verify_security_log(&dir, Some(&history));
        assert!(report.ok);
        assert_eq!(report.checkpoints, 1);
        assert_eq!(report.checked_entries, 3);

        let again = checkpoint_security_log(&dir, &kp, false).unwrap();
        assert!(again.is_empty());
    }

    #[test]
    fn verification_detects_rewrite() {
        let dir = test_dir("rewrite");
        let kp = ServerKeyPair::generate("test");
        std::fs::write(dir.join("security.log.seed"), "seedhash").unwrap();
        let mut prev = "seedhash".to_string();
        write_log(&dir, "security.log.2026-09-01", &["a", "b"], &mut prev);
        write_log(&dir, "security.log.2026-09-02", &["c"], &mut prev);

        checkpoint_security_log(&dir, &kp, false).unwrap();

        let mut forged_prev = "seedhash".to_string();
        write_log(
            &dir,
            "security.log.2026-09-01",
            &["a", "EVIL"],
            &mut forged_prev,
        );

        let history = KeyHistory::new(&kp);
        let report = verify_security_log(&dir, Some(&history));
        assert!(!report.ok);
    }

    #[test]
    fn anchored_mode_survives_compaction() {
        let dir = test_dir("anchored");
        let kp = ServerKeyPair::generate("test");
        std::fs::write(dir.join("security.log.seed"), "seedhash").unwrap();
        let mut prev = "seedhash".to_string();
        write_log(&dir, "security.log.2026-09-01", &["a"], &mut prev);
        write_log(&dir, "security.log.2026-09-02", &["b"], &mut prev);
        write_log(&dir, "security.log.2026-09-03", &["c"], &mut prev);

        let outcomes = checkpoint_security_log(&dir, &kp, false).unwrap();
        assert_eq!(outcomes.len(), 2);

        let handled = apply_retention(&dir, SECURITY_LOG, 1, RetentionMode::Delete).unwrap();
        assert_eq!(handled, vec!["security.log.2026-09-01".to_string()]);
        assert!(!dir.join("security.log.2026-09-01").exists());

        let history = KeyHistory::new(&kp);
        let report = verify_security_log(&dir, Some(&history));
        assert!(report.ok);
        assert_eq!(report.anchored_spans, 1);
        assert_eq!(report.checked_entries, 3);
    }

    #[test]
    fn deletion_without_checkpoint_fails() {
        let dir = test_dir("del-nocp");
        std::fs::write(dir.join("security.log.seed"), "seedhash").unwrap();
        let mut prev = "seedhash".to_string();
        write_log(&dir, "security.log.2026-09-01", &["a"], &mut prev);
        write_log(&dir, "security.log.2026-09-02", &["b"], &mut prev);
        write_log(&dir, "security.log.2026-09-03", &["c"], &mut prev);

        std::fs::remove_file(dir.join("security.log.2026-09-02")).unwrap();

        let report = verify_security_log(&dir, None);
        assert!(!report.ok);
    }

    #[test]
    fn forked_checkpoint_detected() {
        let dir = test_dir("fork");
        let kp = ServerKeyPair::generate("test");
        std::fs::write(dir.join("security.log.seed"), "seedhash").unwrap();
        let mut prev = "seedhash".to_string();
        write_log(&dir, "security.log.2026-09-01", &["a", "b"], &mut prev);
        write_log(&dir, "security.log.2026-09-02", &["c"], &mut prev);

        let outcomes = checkpoint_security_log(&dir, &kp, false).unwrap();
        assert_eq!(outcomes.len(), 1);

        let fork = sign_checkpoint(
            &kp,
            SECURITY_LOG,
            1,
            now_secs(),
            1,
            "differenthead",
            &["security.log.2026-09-01".to_string()],
        );
        write_checkpoint_atomic(&dir, &fork).unwrap();

        let history = KeyHistory::new(&kp);
        let report = verify_security_log(&dir, Some(&history));
        assert!(!report.ok);
    }

    #[test]
    fn key_rotation_between_checkpoints() {
        let kp1 = ServerKeyPair::generate("one");
        let kp2 = ServerKeyPair::generate("two");
        let dir = test_dir("rotate");
        std::fs::write(dir.join("security.log.seed"), "seedhash").unwrap();
        let mut prev = "seedhash".to_string();
        write_log(&dir, "security.log.2026-09-01", &["a"], &mut prev);
        write_log(&dir, "security.log.2026-09-02", &["b"], &mut prev);

        let cp1 = {
            let outcomes = checkpoint_security_log(&dir, &kp1, false).unwrap();
            assert_eq!(outcomes.len(), 1);
            load_checkpoints(&dir, SECURITY_LOG).unwrap().pop().unwrap()
        };

        let cp2 = sign_checkpoint(
            &kp2,
            SECURITY_LOG,
            2,
            now_secs(),
            2,
            &prev,
            &["security.log.2026-09-02".to_string()],
        );
        write_checkpoint_atomic(&dir, &cp2).unwrap();
        let _ = cp1;

        let mut history = KeyHistory::new(&kp1);
        history.rotate(&kp1, &kp2).unwrap();
        let report = verify_security_log(&dir, Some(&history));
        assert!(report.ok);
        assert_eq!(report.checkpoints, 2);
    }

    #[test]
    fn tail_checkpoint_survives_same_file_growth() {
        let dir = test_dir("tail-grow");
        let kp = ServerKeyPair::generate("test");
        std::fs::write(dir.join("security.log.seed"), "seedhash").unwrap();
        let mut prev = "seedhash".to_string();
        write_log(&dir, "security.log.2026-09-17", &["a", "b"], &mut prev);
        let head_at_cp = prev.clone();

        let outcomes = checkpoint_security_log(&dir, &kp, true).unwrap();
        assert_eq!(outcomes.len(), 1);
        assert_eq!(outcomes[0].entries, 2);

        write_log(&dir, "security.log.2026-09-17", &["c", "d"], &mut prev);

        let history = KeyHistory::new(&kp);
        let report = verify_security_log(&dir, Some(&history));
        assert!(report.ok, "report: {:?}", report.lines);
        assert_eq!(report.checked_entries, 4);
        assert_eq!(
            report.checkpoints, 1,
            "head at checkpoint must equal {}",
            head_at_cp
        );

        let outcomes = checkpoint_security_log(&dir, &kp, true).unwrap();
        assert_eq!(outcomes.len(), 1);
        assert_eq!(outcomes[0].entries, 4);
        assert_eq!(outcomes[0].head_hash, prev);

        let report = verify_security_log(&dir, Some(&history));
        assert!(report.ok, "report: {:?}", report.lines);
        assert_eq!(report.checked_entries, 4);
    }

    #[test]
    fn retention_archive_mode_moves_files() {
        let dir = test_dir("archive-mode");
        let kp = ServerKeyPair::generate("test");
        std::fs::write(dir.join("security.log.seed"), "seedhash").unwrap();
        let mut prev = "seedhash".to_string();
        write_log(&dir, "security.log.2026-09-01", &["a"], &mut prev);
        write_log(&dir, "security.log.2026-09-02", &["b"], &mut prev);
        write_log(&dir, "security.log.2026-09-03", &["c"], &mut prev);
        checkpoint_security_log(&dir, &kp, false).unwrap();

        apply_retention(&dir, SECURITY_LOG, 1, RetentionMode::Archive).unwrap();
        assert!(!dir.join("security.log.2026-09-01").exists());
        assert!(dir
            .join("security.log.archive/security.log.2026-09-01")
            .exists());

        let history = KeyHistory::new(&kp);
        let report = verify_security_log(&dir, Some(&history));
        assert!(report.ok);
        assert_eq!(report.anchored_spans, 0);
    }
}
