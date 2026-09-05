use std::io::{BufRead, Write};
use std::path::{Path, PathBuf};

use crate::edition::backend::BeId;

const WAL_FILENAME: &str = "wal.log";
pub const WAL_VERSION: u32 = 1;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct WalEntry {
    pub seq: u64,
    pub op: String,
    pub args: serde_json::Value,
    #[cfg_attr(feature = "serde", serde(default))]
    pub ts: u64,
}

#[derive(Debug)]
pub enum WalError {
    Io(std::io::Error),
    Json(serde_json::Error),
}

impl std::fmt::Display for WalError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            WalError::Io(e) => write!(f, "wal io error: {}", e),
            WalError::Json(e) => write!(f, "wal json error: {}", e),
        }
    }
}

impl std::error::Error for WalError {}

impl From<std::io::Error> for WalError {
    fn from(e: std::io::Error) -> Self {
        WalError::Io(e)
    }
}

impl From<serde_json::Error> for WalError {
    fn from(e: serde_json::Error) -> Self {
        WalError::Json(e)
    }
}

pub struct WalLog {
    path: PathBuf,
    seq: u64,
    file: Option<std::fs::File>,
    append_count: u64,
}

impl WalLog {
    pub fn open(data_dir: &Path) -> Result<Self, WalError> {
        let path = data_dir.join(WAL_FILENAME);
        let needs_header = !path.exists()
            || std::fs::metadata(&path)
                .map(|m| m.len() == 0)
                .unwrap_or(true);
        let seq = Self::read_max_seq(&path)?;
        let mut file = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&path)?;
        if needs_header {
            let header = serde_json::json!({"version": WAL_VERSION});
            let mut line = serde_json::to_string(&header)?;
            line.push('\n');
            file.write_all(line.as_bytes())?;
            file.sync_all()?;
        }
        Ok(WalLog {
            path,
            seq,
            file: Some(file),
            append_count: 0,
        })
    }

    pub fn disabled() -> Self {
        WalLog {
            path: PathBuf::new(),
            seq: 0,
            file: None,
            append_count: 0,
        }
    }

    pub fn is_enabled(&self) -> bool {
        self.file.is_some()
    }

    pub fn append_count(&self) -> u64 {
        self.append_count
    }

    pub fn seq(&self) -> u64 {
        self.seq
    }

    pub fn append(&mut self, op: &str, args: serde_json::Value) -> Result<u64, WalError> {
        let file = match self.file.as_mut() {
            Some(f) => f,
            None => return Ok(0),
        };
        self.seq += 1;
        self.append_count += 1;
        let ts = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        let entry = WalEntry {
            seq: self.seq,
            op: op.to_string(),
            args,
            ts,
        };
        let mut line = serde_json::to_string(&entry)?;
        line.push('\n');
        file.write_all(line.as_bytes())?;
        file.sync_all()?;
        Ok(self.seq)
    }

    pub fn append_star(&mut self, club_id: BeId, work_id: BeId) -> Result<u64, WalError> {
        self.append(
            "star",
            serde_json::json!({
                "club_id": club_id,
                "work_id": work_id,
            }),
        )
    }

    pub fn append_unstar(&mut self, club_id: BeId, work_id: BeId) -> Result<u64, WalError> {
        self.append(
            "unstar",
            serde_json::json!({
                "club_id": club_id,
                "work_id": work_id,
            }),
        )
    }

    pub fn append_pin(&mut self, club_id: BeId, key: String) -> Result<u64, WalError> {
        self.append(
            "pin",
            serde_json::json!({
                "club_id": club_id,
                "key": key,
            }),
        )
    }

    pub fn append_unpin(&mut self, club_id: BeId, key: String) -> Result<u64, WalError> {
        self.append(
            "unpin",
            serde_json::json!({
                "club_id": club_id,
                "key": key,
            }),
        )
    }

    pub fn append_trail_create(
        &mut self,
        owner_club: BeId,
        trail_id: BeId,
        name: &str,
        introduction: Option<&str>,
        categories: &[String],
    ) -> Result<u64, WalError> {
        self.append(
            "trail_create",
            serde_json::json!({
                "owner_club": owner_club,
                "trail_id": trail_id,
                "name": name,
                "introduction": introduction,
                "categories": categories,
            }),
        )
    }

    pub fn append_trail_delete(&mut self, trail_id: BeId) -> Result<u64, WalError> {
        self.append(
            "trail_delete",
            serde_json::json!({
                "trail_id": trail_id,
            }),
        )
    }

    pub fn append_trail_rename(
        &mut self,
        trail_id: BeId,
        old_name: &str,
        new_name: &str,
    ) -> Result<u64, WalError> {
        self.append(
            "trail_rename",
            serde_json::json!({
                "trail_id": trail_id,
                "old_name": old_name,
                "new_name": new_name,
            }),
        )
    }

    pub fn append_trail_add_stop(
        &mut self,
        trail_id: BeId,
        work_id: BeId,
        char_start: Option<u64>,
        char_end: Option<u64>,
        note: Option<&str>,
    ) -> Result<u64, WalError> {
        self.append(
            "trail_add_stop",
            serde_json::json!({
                "trail_id": trail_id,
                "work_id": work_id,
                "char_start": char_start,
                "char_end": char_end,
                "note": note,
            }),
        )
    }

    pub fn append_trail_remove_stop(
        &mut self,
        trail_id: BeId,
        work_id: BeId,
    ) -> Result<u64, WalError> {
        self.append(
            "trail_remove_stop",
            serde_json::json!({
                "trail_id": trail_id,
                "work_id": work_id,
            }),
        )
    }

    pub fn append_text_edit(
        &mut self,
        work_id: BeId,
        revision: u64,
        text_preview: &str,
    ) -> Result<u64, WalError> {
        let preview: String = text_preview.chars().take(200).collect();
        self.append(
            "text_edit",
            serde_json::json!({
                "work_id": work_id,
                "revision": revision,
                "text_preview": preview,
            }),
        )
    }

    pub fn append_annotation_create(
        &mut self,
        work_id: BeId,
        annotation_id: u64,
        kind: &str,
        payload: &str,
        char_start: usize,
        char_end: usize,
        is_private: bool,
    ) -> Result<u64, WalError> {
        self.append(
            "annotation_create",
            serde_json::json!({
                "work_id": work_id,
                "annotation_id": annotation_id,
                "kind": kind,
                "payload": payload,
                "char_start": char_start,
                "char_end": char_end,
                "is_private": is_private,
            }),
        )
    }

    pub fn append_annotation_delete(
        &mut self,
        work_id: BeId,
        annotation_id: u64,
    ) -> Result<u64, WalError> {
        self.append(
            "annotation_delete",
            serde_json::json!({
                "work_id": work_id,
                "annotation_id": annotation_id,
            }),
        )
    }

    pub fn append_create_link(
        &mut self,
        link_id: BeId,
        origin: BeId,
        destination: BeId,
        origin_ref: Option<&crate::server::transport::protocol::HyperRefPayload>,
        destination_ref: Option<&crate::server::transport::protocol::HyperRefPayload>,
        link_types: &[u64],
        home_document: Option<BeId>,
    ) -> Result<u64, WalError> {
        self.append(
            "create_link",
            serde_json::json!({
                "link_id": link_id,
                "origin": origin,
                "destination": destination,
                "origin_ref": origin_ref,
                "destination_ref": destination_ref,
                "link_types": link_types,
                "home_document": home_document,
            }),
        )
    }

    pub fn append_link_add_end(
        &mut self,
        link_id: BeId,
        end_name: String,
        end_ref: &crate::server::transport::protocol::HyperRefPayload,
    ) -> Result<u64, WalError> {
        self.append(
            "link_add_end",
            serde_json::json!({
                "link_id": link_id,
                "end_name": end_name,
                "end_ref": end_ref,
            }),
        )
    }

    pub fn append_link_remove_end(
        &mut self,
        link_id: BeId,
        end_name: String,
    ) -> Result<u64, WalError> {
        self.append(
            "link_remove_end",
            serde_json::json!({
                "link_id": link_id,
                "end_name": end_name,
            }),
        )
    }

    /// FR-40 Story 6: add one attachment to an end-set.
    pub fn append_link_end_add_attachment(
        &mut self,
        link_id: BeId,
        end_name: String,
        attachment: &crate::server::transport::protocol::HyperRefPayload,
    ) -> Result<u64, WalError> {
        self.append(
            "link_end_add_attachment",
            serde_json::json!({
                "link_id": link_id,
                "end_name": end_name,
                "attachment": attachment,
            }),
        )
    }

    /// FR-40 Story 6: remove one attachment from an end-set.
    pub fn append_link_end_remove_attachment(
        &mut self,
        link_id: BeId,
        end_name: String,
        attachment: &crate::server::transport::protocol::HyperRefPayload,
    ) -> Result<u64, WalError> {
        self.append(
            "link_end_remove_attachment",
            serde_json::json!({
                "link_id": link_id,
                "end_name": end_name,
                "attachment": attachment,
            }),
        )
    }

    pub fn truncate(&mut self) -> Result<(), WalError> {
        self.append_count = 0;
        if self.file.is_none() {
            return Ok(());
        }
        self.file = None;
        {
            let mut f = std::fs::OpenOptions::new()
                .create(true)
                .write(true)
                .truncate(true)
                .open(&self.path)?;
            let header = serde_json::json!({"version": WAL_VERSION});
            let mut line = serde_json::to_string(&header)?;
            line.push('\n');
            f.write_all(line.as_bytes())?;
            f.sync_all()?;
        }
        self.file = Some(
            std::fs::OpenOptions::new()
                .create(true)
                .append(true)
                .open(&self.path)?,
        );
        self.seq = 0;
        Ok(())
    }

    fn read_max_seq(path: &Path) -> Result<u64, WalError> {
        if !path.exists() {
            return Ok(0);
        }
        let file = match std::fs::File::open(path) {
            Ok(f) => f,
            Err(_) => return Ok(0),
        };
        let reader = std::io::BufReader::new(file);
        let mut max_seq = 0u64;
        for line in reader.lines() {
            match line {
                Ok(l) => {
                    if let Ok(entry) = serde_json::from_str::<WalEntry>(&l) {
                        if entry.seq > max_seq {
                            max_seq = entry.seq;
                        }
                    }
                }
                Err(_) => break,
            }
        }
        Ok(max_seq)
    }

    pub fn read_entries(path: &Path) -> Result<(u32, Vec<WalEntry>), WalError> {
        if !path.exists() {
            return Ok((WAL_VERSION, Vec::new()));
        }
        let file = std::fs::File::open(path)?;
        let reader = std::io::BufReader::new(file);
        let mut entries = Vec::new();
        let mut version: u32 = 0;
        let mut first_line = true;
        for line in reader.lines() {
            match line {
                Ok(l) => {
                    if first_line {
                        first_line = false;
                        if let Some(v) = serde_json::from_str::<serde_json::Value>(&l)
                            .ok()
                            .and_then(|v| v.get("version")?.as_u64())
                        {
                            version = v as u32;
                            continue;
                        }
                    }
                    if let Ok(entry) = serde_json::from_str::<WalEntry>(&l) {
                        entries.push(entry);
                    }
                }
                Err(_) => break,
            }
        }
        Ok((version, entries))
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn replay_entries(server: &mut crate::server::Server, entries: &[WalEntry]) -> u64 {
        let mut replayed = 0u64;
        for entry in entries {
            let result = match entry.op.as_str() {
                "star" => {
                    if let (Some(club_id), Some(work_id)) = (
                        entry.args.get("club_id").and_then(|v| v.as_u64()),
                        entry.args.get("work_id").and_then(|v| v.as_u64()),
                    ) {
                        server.wal_replay_star(club_id, work_id);
                        true
                    } else {
                        false
                    }
                }
                "unstar" => {
                    if let (Some(club_id), Some(work_id)) = (
                        entry.args.get("club_id").and_then(|v| v.as_u64()),
                        entry.args.get("work_id").and_then(|v| v.as_u64()),
                    ) {
                        server.wal_replay_unstar(club_id, work_id);
                        true
                    } else {
                        false
                    }
                }
                "pin" => {
                    if let (Some(club_id), Some(key)) = (
                        entry.args.get("club_id").and_then(|v| v.as_u64()),
                        entry.args.get("key").and_then(|v| v.as_str()),
                    ) {
                        server.wal_replay_pin(club_id, key.to_string());
                        true
                    } else {
                        false
                    }
                }
                "unpin" => {
                    if let (Some(club_id), Some(key)) = (
                        entry.args.get("club_id").and_then(|v| v.as_u64()),
                        entry.args.get("key").and_then(|v| v.as_str()),
                    ) {
                        server.wal_replay_unpin(club_id, key.to_string());
                        true
                    } else {
                        false
                    }
                }
                "annotation_create" => {
                    if let (Some(work_id), Some(annotation_id), Some(kind), Some(payload)) = (
                        entry.args.get("work_id").and_then(|v| v.as_u64()),
                        entry.args.get("annotation_id").and_then(|v| v.as_u64()),
                        entry.args.get("kind").and_then(|v| v.as_str()),
                        entry.args.get("payload").and_then(|v| v.as_str()),
                    ) {
                        let char_start = entry
                            .args
                            .get("char_start")
                            .and_then(|v| v.as_u64())
                            .unwrap_or(0) as usize;
                        let char_end = entry
                            .args
                            .get("char_end")
                            .and_then(|v| v.as_u64())
                            .unwrap_or(0) as usize;
                        let is_private = entry
                            .args
                            .get("is_private")
                            .and_then(|v| v.as_bool())
                            .unwrap_or(false);
                        server.wal_replay_annotation_create(
                            work_id,
                            annotation_id,
                            kind.to_string(),
                            payload.to_string(),
                            char_start,
                            char_end,
                            is_private,
                        );
                        true
                    } else {
                        false
                    }
                }
                "annotation_delete" => {
                    if let (Some(work_id), Some(annotation_id)) = (
                        entry.args.get("work_id").and_then(|v| v.as_u64()),
                        entry.args.get("annotation_id").and_then(|v| v.as_u64()),
                    ) {
                        server.wal_replay_annotation_delete(work_id, annotation_id);
                        true
                    } else {
                        false
                    }
                }
                "trail_create" => {
                    if let (Some(owner_club), Some(trail_id), Some(name)) = (
                        entry.args.get("owner_club").and_then(|v| v.as_u64()),
                        entry.args.get("trail_id").and_then(|v| v.as_u64()),
                        entry.args.get("name").and_then(|v| v.as_str()),
                    ) {
                        let intro = entry.args.get("introduction").and_then(|v| v.as_str());
                        let cats: Vec<String> = entry
                            .args
                            .get("categories")
                            .and_then(|v| v.as_array())
                            .map(|arr| {
                                arr.iter()
                                    .filter_map(|v| v.as_str().map(|s| s.to_string()))
                                    .collect()
                            })
                            .unwrap_or_default();
                        server.wal_replay_trail_create(owner_club, trail_id, name, intro, &cats);
                        true
                    } else {
                        false
                    }
                }
                "trail_delete" => {
                    if let Some(trail_id) = entry.args.get("trail_id").and_then(|v| v.as_u64()) {
                        server.wal_replay_trail_delete(trail_id);
                        true
                    } else {
                        false
                    }
                }
                "trail_add_stop" => {
                    if let (Some(trail_id), Some(work_id)) = (
                        entry.args.get("trail_id").and_then(|v| v.as_u64()),
                        entry.args.get("work_id").and_then(|v| v.as_u64()),
                    ) {
                        let cs = entry.args.get("char_start").and_then(|v| v.as_u64());
                        let ce = entry.args.get("char_end").and_then(|v| v.as_u64());
                        let note = entry
                            .args
                            .get("note")
                            .and_then(|v| v.as_str())
                            .map(|s| s.to_string());
                        server.wal_replay_trail_add_stop(trail_id, work_id, cs, ce, note);
                        true
                    } else {
                        false
                    }
                }
                "trail_remove_stop" => {
                    if let (Some(trail_id), Some(work_id)) = (
                        entry.args.get("trail_id").and_then(|v| v.as_u64()),
                        entry.args.get("work_id").and_then(|v| v.as_u64()),
                    ) {
                        server.wal_replay_trail_remove_stop(trail_id, work_id);
                        true
                    } else {
                        false
                    }
                }
                "set_compound_edition" => {
                    if let (Some(work_id), Some(compound_json)) = (
                        entry.args.get("work_id").and_then(|v| v.as_u64()),
                        entry.args.get("compound").and_then(|v| v.as_str()),
                    ) {
                        if let Ok(compound) = serde_json::from_str::<
                            crate::edition::compound::CompoundEdition,
                        >(compound_json)
                        {
                            server.wal_replay_set_compound_edition(work_id, compound);
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    }
                }
                "compound_insert_element" => {
                    if let (Some(work_id), Some(index), Some(element_json)) = (
                        entry.args.get("work_id").and_then(|v| v.as_u64()),
                        entry.args.get("index").and_then(|v| v.as_u64()),
                        entry.args.get("element").and_then(|v| v.as_str()),
                    ) {
                        if let Ok(element) = serde_json::from_str::<
                            crate::edition::compound::CompoundElement,
                        >(element_json)
                        {
                            server.wal_replay_compound_insert_element(
                                work_id,
                                index as usize,
                                element,
                            );
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    }
                }
                "compound_remove_element" => {
                    if let (Some(work_id), Some(index)) = (
                        entry.args.get("work_id").and_then(|v| v.as_u64()),
                        entry.args.get("index").and_then(|v| v.as_u64()),
                    ) {
                        server.wal_replay_compound_remove_element(work_id, index as usize);
                        true
                    } else {
                        false
                    }
                }
                "compound_move_element" => {
                    if let (Some(work_id), Some(from), Some(to)) = (
                        entry.args.get("work_id").and_then(|v| v.as_u64()),
                        entry.args.get("from").and_then(|v| v.as_u64()),
                        entry.args.get("to").and_then(|v| v.as_u64()),
                    ) {
                        server.wal_replay_compound_move_element(
                            work_id,
                            from as usize,
                            to as usize,
                        );
                        true
                    } else {
                        false
                    }
                }
                "create_link" => {
                    if let (Some(link_id), Some(origin), Some(destination)) = (
                        entry.args.get("link_id").and_then(|v| v.as_u64()),
                        entry.args.get("origin").and_then(|v| v.as_u64()),
                        entry.args.get("destination").and_then(|v| v.as_u64()),
                    ) {
                        let o_ref = entry.args.get("origin_ref").and_then(|v| {
                            serde_json::from_value::<
                                crate::server::transport::protocol::HyperRefPayload,
                            >(v.clone())
                            .ok()
                        });
                        let d_ref = entry.args.get("destination_ref").and_then(|v| {
                            serde_json::from_value::<
                                crate::server::transport::protocol::HyperRefPayload,
                            >(v.clone())
                            .ok()
                        });
                        let link_types: Vec<u64> = entry
                            .args
                            .get("link_types")
                            .and_then(|v| serde_json::from_value(v.clone()).ok())
                            .unwrap_or_default();
                        let home_document: Option<BeId> = entry
                            .args
                            .get("home_document")
                            .and_then(|v| serde_json::from_value(v.clone()).ok())
                            .unwrap_or(None);
                        server.wal_replay_create_link(
                            link_id,
                            origin,
                            destination,
                            o_ref,
                            d_ref,
                            link_types,
                            home_document,
                        );
                        true
                    } else {
                        false
                    }
                }
                "link_add_end" => {
                    if let (Some(link_id), Some(end_name), Some(end_ref)) = (
                        entry.args.get("link_id").and_then(|v| v.as_u64()),
                        entry.args.get("end_name").and_then(|v| v.as_str()),
                        entry.args.get("end_ref"),
                    ) {
                        if let Ok(payload) = serde_json::from_value::<
                            crate::server::transport::protocol::HyperRefPayload,
                        >(end_ref.clone())
                        {
                            server.wal_replay_link_add_end(link_id, end_name.to_string(), payload);
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    }
                }
                "link_remove_end" => {
                    if let (Some(link_id), Some(end_name)) = (
                        entry.args.get("link_id").and_then(|v| v.as_u64()),
                        entry.args.get("end_name").and_then(|v| v.as_str()),
                    ) {
                        server.wal_replay_link_remove_end(link_id, end_name.to_string());
                        true
                    } else {
                        false
                    }
                }
                "link_end_add_attachment" | "link_end_remove_attachment" => {
                    if let (Some(link_id), Some(end_name), Some(attachment)) = (
                        entry.args.get("link_id").and_then(|v| v.as_u64()),
                        entry.args.get("end_name").and_then(|v| v.as_str()),
                        entry.args.get("attachment"),
                    ) {
                        if let Ok(payload) = serde_json::from_value::<
                            crate::server::transport::protocol::HyperRefPayload,
                        >(attachment.clone())
                        {
                            if entry.op == "link_end_add_attachment" {
                                server.wal_replay_link_end_add_attachment(
                                    link_id,
                                    end_name.to_string(),
                                    payload,
                                );
                            } else {
                                server.wal_replay_link_end_remove_attachment(
                                    link_id,
                                    end_name.to_string(),
                                    payload,
                                );
                            }
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    }
                }
                _ => false,
            };
            if result {
                replayed += 1;
            } else {
                tracing::warn!(
                    "WAL: skipping unrecognized entry seq={} op={}",
                    entry.seq,
                    entry.op
                );
            }
        }
        replayed
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn temp_dir() -> PathBuf {
        static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
        let id = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        std::env::temp_dir().join(format!("xudanu_wal_test_{}_{}", std::process::id(), id))
    }

    #[test]
    fn wal_open_creates_file() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let wal = WalLog::open(&dir).unwrap();
        assert!(wal.is_enabled());
        assert!(dir.join(WAL_FILENAME).exists());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_append_increments_seq() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut wal = WalLog::open(&dir).unwrap();
        assert_eq!(wal.seq(), 0);

        let s1 = wal
            .append("test_op", serde_json::json!({"key": 1}))
            .unwrap();
        assert_eq!(s1, 1);
        assert_eq!(wal.seq(), 1);

        let s2 = wal
            .append("test_op", serde_json::json!({"key": 2}))
            .unwrap();
        assert_eq!(s2, 2);
        assert_eq!(wal.seq(), 2);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_entries_persist_across_reopen() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        {
            let mut wal = WalLog::open(&dir).unwrap();
            wal.append_star(100, 200).unwrap();
            wal.append_star(100, 300).unwrap();
        }

        let (_ver, entries) = WalLog::read_entries(&dir.join(WAL_FILENAME)).unwrap();
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].op, "star");
        assert_eq!(entries[0].args["club_id"], 100);
        assert_eq!(entries[0].args["work_id"], 200);
        assert_eq!(entries[1].seq, 2);

        {
            let wal = WalLog::open(&dir).unwrap();
            assert_eq!(wal.seq(), 2, "seq should be recovered from existing WAL");
        }

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_truncate_resets() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut wal = WalLog::open(&dir).unwrap();
        wal.append_star(100, 200).unwrap();
        wal.append_star(100, 300).unwrap();
        assert_eq!(wal.seq(), 2);

        wal.truncate().unwrap();
        assert_eq!(wal.seq(), 0);

        let (_ver, entries) = WalLog::read_entries(&dir.join(WAL_FILENAME)).unwrap();
        assert!(entries.is_empty(), "WAL should be empty after truncate");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_disabled_noops() {
        let mut wal = WalLog::disabled();
        assert!(!wal.is_enabled());
        let result = wal.append_star(100, 200).unwrap();
        assert_eq!(result, 0);
    }

    #[test]
    fn wal_star_unstar_helpers() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut wal = WalLog::open(&dir).unwrap();
        wal.append_star(100, 200).unwrap();
        wal.append_unstar(100, 200).unwrap();

        let (_ver, entries) = WalLog::read_entries(&dir.join(WAL_FILENAME)).unwrap();
        assert_eq!(entries[0].op, "star");
        assert_eq!(entries[1].op, "unstar");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_trail_helpers() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let mut wal = WalLog::open(&dir).unwrap();
        wal.append_trail_create(100, 500, "test trail", None, &[])
            .unwrap();
        wal.append_trail_add_stop(500, 600, Some(10), Some(50), Some("note"))
            .unwrap();
        wal.append_trail_remove_stop(500, 600).unwrap();
        wal.append_trail_rename(500, "old", "new").unwrap();
        wal.append_trail_delete(500).unwrap();

        let (_ver, entries) = WalLog::read_entries(&dir.join(WAL_FILENAME)).unwrap();
        assert_eq!(entries.len(), 5);
        assert_eq!(entries[0].op, "trail_create");
        assert_eq!(entries[1].op, "trail_add_stop");
        assert_eq!(entries[2].op, "trail_remove_stop");
        assert_eq!(entries[3].op, "trail_rename");
        assert_eq!(entries[4].op, "trail_delete");
        assert_eq!(entries[1].args["char_start"], 10);
        assert_eq!(entries[1].args["note"], "note");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_text_edit_truncates_preview() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let long_text: String = "x".repeat(500);
        let mut wal = WalLog::open(&dir).unwrap();
        wal.append_text_edit(100, 1, &long_text).unwrap();

        let (_ver, entries) = WalLog::read_entries(&dir.join(WAL_FILENAME)).unwrap();
        assert_eq!(entries[0].op, "text_edit");
        let preview = entries[0].args["text_preview"].as_str().unwrap();
        assert_eq!(
            preview.len(),
            200,
            "preview should be truncated to 200 chars"
        );

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_handles_corrupt_lines() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let path = dir.join(WAL_FILENAME);
        let mut f = std::fs::File::create(&path).unwrap();
        writeln!(f, "{{\"seq\":1,\"op\":\"star\",\"args\":{{\"club_id\":100,\"work_id\":200}},\"ts\":1000}}").unwrap();
        writeln!(f, "CORRUPT LINE").unwrap();
        writeln!(f, "{{\"seq\":2,\"op\":\"star\",\"args\":{{\"club_id\":100,\"work_id\":300}},\"ts\":1001}}").unwrap();
        drop(f);

        let (_ver, entries) = WalLog::read_entries(&path).unwrap();
        assert_eq!(entries.len(), 2, "should skip corrupt line");

        let wal = WalLog::open(&dir).unwrap();
        assert_eq!(wal.seq(), 2, "max seq should be 2");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_read_empty_file() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        let (_ver, entries) = WalLog::read_entries(&dir.join(WAL_FILENAME)).unwrap();
        assert!(entries.is_empty());

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_annotation_create_persists() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        {
            let mut wal = WalLog::open(&dir).unwrap();
            wal.append_annotation_create(
                0x0500,
                12345,
                "link-description",
                r#"{"link_id":42,"text":"test description"}"#,
                10,
                30,
                false,
            )
            .unwrap();
            wal.append_annotation_create(0x0500, 12346, "bold", "", 0, 5, false)
                .unwrap();
        }

        let (_ver, entries) = WalLog::read_entries(&dir.join(WAL_FILENAME)).unwrap();
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].op, "annotation_create");
        assert_eq!(entries[0].args["work_id"], 0x0500);
        assert_eq!(entries[0].args["annotation_id"], 12345);
        assert_eq!(entries[0].args["kind"], "link-description");
        assert_eq!(entries[0].args["char_start"], 10);
        assert_eq!(entries[0].args["char_end"], 30);
        assert_eq!(entries[0].args["is_private"], false);
        assert_eq!(entries[1].args["kind"], "bold");

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_annotation_delete_persists() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        {
            let mut wal = WalLog::open(&dir).unwrap();
            wal.append_annotation_create(0x0500, 12345, "bold", "", 0, 5, false)
                .unwrap();
            wal.append_annotation_delete(0x0500, 12345).unwrap();
        }

        let (_ver, entries) = WalLog::read_entries(&dir.join(WAL_FILENAME)).unwrap();
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].op, "annotation_create");
        assert_eq!(entries[1].op, "annotation_delete");
        assert_eq!(entries[1].args["annotation_id"], 12345);

        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn wal_annotation_create_and_delete_roundtrip() {
        let dir = temp_dir();
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();

        {
            let mut wal = WalLog::open(&dir).unwrap();
            wal.append_annotation_create(0x0500, 99999, "italic", "", 50, 60, true)
                .unwrap();
        }

        {
            let wal = WalLog::open(&dir).unwrap();
            assert_eq!(wal.seq(), 1, "seq recovered from WAL");
        }

        let (_ver, entries) = WalLog::read_entries(&dir.join(WAL_FILENAME)).unwrap();
        assert_eq!(entries.len(), 1);
        assert_eq!(entries[0].args["is_private"], true);
        assert_eq!(entries[0].args["char_start"], 50);
        assert_eq!(entries[0].args["char_end"], 60);

        let _ = std::fs::remove_dir_all(&dir);
    }
}
