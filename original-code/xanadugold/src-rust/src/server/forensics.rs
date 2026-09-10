//! FR-63 Phase 1: passive forensic integrity checks. All read-only
//! against a restored Server. Design: docs/dev/FR-63-forensic-integrity.md.

use crate::server::server::Server;

#[derive(Debug, Clone, serde::Serialize)]
pub struct ForensicsReport {
    pub verdict: &'static str,
    pub chain: ChainProbe,
    pub generation_anomalies: Vec<GenerationAnomaly>,
    pub orphan_chunks: Vec<OrphanChunk>,
    pub anchor_status: AnchorStatus,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct ChainProbe {
    pub entries: usize,
    pub chain_head: Option<String>,
    pub status: &'static str,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct GenerationAnomaly {
    pub work_id: u64,
    pub title: String,
    pub revision_count: u64,
    pub note: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct OrphanChunk {
    pub chunk_hash: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct AnchorStatus {
    pub anchoring_enabled: bool,
    pub last_round_status: Option<String>,
    pub bitcoin_height: Option<u64>,
    pub receipt_present: bool,
    pub receipt_parses: bool,
}

/// Run all Phase 1 forensic checks against a restored server.
pub fn forensics(server: &Server) -> ForensicsReport {
    let chain = probe_chain(server);
    let generation_anomalies = generation_forensics(server);
    let orphan_chunks = orphan_scan(server);
    let anchor_status = anchor_verification(server);

    let clean = chain.status == "ok" && generation_anomalies.is_empty() && orphan_chunks.is_empty();

    ForensicsReport {
        verdict: if clean { "CLEAN" } else { "ANOMALIES FOUND" },
        chain,
        generation_anomalies,
        orphan_chunks,
        anchor_status,
    }
}

fn probe_chain(server: &Server) -> ChainProbe {
    let status = server.ots_anchor_status();
    let head = status
        .get("chain_head")
        .and_then(|v| v.as_str())
        .map(String::from);
    let entries = server.work_count();
    let has_head = head.is_some();
    ChainProbe {
        entries,
        chain_head: head,
        status: if has_head { "ok" } else { "empty" },
    }
}

fn generation_forensics(server: &Server) -> Vec<GenerationAnomaly> {
    let mut anomalies = Vec::new();
    for (id, ws) in server.works.iter() {
        let rev_count = ws.work().revision_count();
        if rev_count > 4 {
            anomalies.push(GenerationAnomaly {
                work_id: *id,
                title: ws.cached_title().to_string(),
                revision_count: rev_count,
                note: format!(
                    "high revision count ({}) — review for transient modification",
                    rev_count
                ),
            });
        }
    }
    anomalies
}

fn orphan_scan(_server: &Server) -> Vec<OrphanChunk> {
    // TODO: walk the chunk store, compare against chunk_refs.
    Vec::new()
}

fn anchor_verification(server: &Server) -> AnchorStatus {
    let status = server.ots_anchor_status();
    let lr = status.get("last_round");

    let receipt_present = server
        .data_dir
        .as_ref()
        .map(|d| d.join("anchoring/receipt.ots").exists())
        .unwrap_or(false);

    let receipt_parses = if receipt_present {
        let receipt = server
            .data_dir
            .as_ref()
            .and_then(|d| std::fs::read(d.join("anchoring/receipt-stream.bin")).ok());
        match receipt {
            Some(bytes) => crate::server::ots_anchor::parse_stream(&bytes).is_ok(),
            None => false,
        }
    } else {
        false
    };

    AnchorStatus {
        anchoring_enabled: status
            .get("enabled")
            .and_then(|v| v.as_bool())
            .unwrap_or(false),
        last_round_status: lr
            .and_then(|r| r.get("status"))
            .and_then(|s| s.as_str())
            .map(String::from),
        bitcoin_height: lr
            .and_then(|r| r.get("bitcoin_height"))
            .and_then(|h| h.as_u64()),
        receipt_present,
        receipt_parses,
    }
}
