# Attribution & Endorsement — Recent Updates

This document covers the recent changes to the attribution/provenance subsystem that
are **not** yet described in the general docs (`dev/manual.md`, `dev/phase-13-endorsement-authority.md`,
`source-detection-attribution.md`, `TRANSCLUSION-FLOW.md`). It covers three things:

1. **Transclusion placer provenance** — a new `transcluded_by` field recording *who placed* transcluded content.
2. **Always-initialized attribution log** — the transparency log is now never absent; it falls back to an in-memory chain.
3. **Provenance ancestry (derivation-chain) view** — a query that walks the full chain of source works behind a document.

> Status note: a dedicated `WorkTransclusionAncestry` type/endpoint does **not** exist yet (see "Open work" at the end). Ancestry is currently returned as `Vec<ProvenanceHopPayload>` on the existing `provenance_ancestry` / `attribution_query` responses.

---

## 1. Transclusion placer provenance (`transcluded_by`)

### What changed

`ElementProvenance` gained a new optional field that records the identity of the
**club/session that placed** a transcluded passage into a document — distinct from
the *author* of the source text.

`edition/provenance.rs:37`
```rust
pub struct TransclusionInfo {
    pub club_id: BeId,
    pub display_name: String,
    pub public_key: [u8; 32],   // verifying key of the placer's club signing key
    pub timestamp: u64,
}
```

`ElementProvenance.transcluded_by: Option<TransclusionInfo>` — `edition/provenance.rs`.

### When it is stamped

When `work_apply_transclusion_attribution` runs for a link, the server resolves the
placing session into a `TransclusionInfo` and stamps it onto every element covered by
the transcluded excerpt:

- `resolve_transclusion_placer(session_id)` → `server/server.rs:480` builds the
  `TransclusionInfo` from the session's author club (`club_id`, `display_name`, the
  club signing key's verifying key, and the current timestamp).
- `apply_transclusion_attribution_internal(..., placed_by)` → `server/server.rs:5866`
  sets `transcluded_by: placed_by` on the resolved source provenance (`server/server.rs:5903`)
  before stamping the destination elements.

So a single span can now carry **two** layers of provenance:
- the original author (e.g. a historical author like Mary Shelley), via the existing
  `author_*` / `historical_author_id` / `source_work_id` fields, and
- the placer, via `transcluded_by`.

### Wire shape

`AttributionSpanPayload` (`server/transport/protocol.rs:2136`) now exposes the placer
alongside the derivation chain:
```rust
pub transcluded_by_name: Option<String>,      // :2151
pub transcluded_by_club_id: Option<BeId>,     // :2153
pub provenance_chain: Option<Vec<ProvenanceHopPayload>>,  // :2155
```

### Backward compatibility

The new `transcluded_by` field is serialized with `#[serde(default)]`
(`edition/provenance.rs`), so checkpoints written by older binaries (without the field)
still deserialize. Covered by:
`server::server::tests::element_provenance_source_work_id_deserializes_without_field`.

### UI

`web/app/src/components/AttributionPanel.tsx` now renders:
- a **"transcluded by {name}"** label on any author whose spans carry `transcluded_by_name`,
- a **Derivation Chain** block (see section 3).

---

## 2. Always-initialized attribution log

### What changed

`AttributionLog` became an enum with two backends — file-backed (persistent, the
existing behavior) and in-memory (new):

`server/transport/attribution_log.rs`
```rust
pub enum AttributionLog {
    File(FileAttributionLog),
    InMemory(InMemoryAttributionLog),
}
```

Both maintain the same hash-chained transparency log semantics:
each appended `AttributionEntry` is chained as `sha256(prev_hash || entry_line)`.

`AttributionEntry` fields (unchanged): `sequence`, `timestamp`, `author_pk_hex`,
`span_fp_hex`, `signature_hex`, `server_id_hex`, `work_id`, `revision`.

### Why: the log is now never absent

The server's `attribution_log` field is no longer optional, and it always starts in a
usable state:

- **Default / fresh server:** initialized to `AttributionLog::in_memory()`
  (`server/server.rs:283`, `:9891`).
- **On restore from a data dir:** it tries `AttributionLog::open(data_dir)`; if that
  fails it logs a warning and **falls back to in-memory** (`server/server.rs:4450` and
  `:4897`):
  ```rust
  self.attribution_log = match AttributionLog::open(data_dir) {
      Ok(log) => log,
      Err(e) => { tracing::warn!("failed to open attribution log: {}, using in-memory", e);
                  AttributionLog::in_memory() }
  };
  ```

Consequence: `attribution_log_status` always reports `has_log: true`, and treats an
in-memory log as `chain_valid: true` (a file-backed log is verified on disk)
(`server/server.rs:1921`):

```rust
pub fn attribution_log_status(&self) -> ResponseValue {
    let entry_count = self.attribution_log.sequence();
    let chain_valid = if self.attribution_log.is_in_memory() { true }
                      else { self.verify_attribution_log_chain() };
    ResponseValue::AttributionLogStatusResult { entry_count, chain_valid,
                                                last_sequence: entry_count, has_log: true }
}
```

So clients can always rely on the attribution log being present and the status response
being well-formed, even when no on-disk log exists yet.

### Wire op

`attribution_log_status` → returns `{ entry_count, chain_valid, last_sequence, has_log }`.

---

## 3. Provenance ancestry (derivation-chain) view

### What it is

A read-side query that walks **all incoming transclusion links** of a work
breadth-first and returns the ordered chain of `(source_work, link)` hops behind it —
i.e. the document's derivation/ancestry graph.

### Implementation

`server/server.rs:6318`
```rust
pub fn provenance_ancestry(&self, work_id: BeId) -> Vec<ProvenanceHop>
```
BFS over incoming links (`list_links_for_work`), de-duplicating by `(source_work, link)`
and by visited works (cycle-safe). Each link's own `provenance_chain` hops are folded in,
then a hop for the immediate source is pushed. Result is sorted by `link_id`.

`ProvenanceHop` (`edition/links.rs:277`) is the minimal `{ source_work_id, link_id }`
pair. It is enriched for transport by:

`server/server.rs:6354` → `enrich_provenance_hops` → `ProvenanceHopPayload`
(`server/transport/protocol.rs:2352`):
```rust
pub struct ProvenanceHopPayload {
    pub source_work_id: BeId,
    pub link_id: BeId,
    pub source_work_title: Option<String>,   // first 60 chars of the source edition
    pub source_author_name: Option<String>,
}
```

### Two ways to read it

1. **Dedicated RPC** — `provenance_ancestry` (`server/transport/dispatch.rs:1509`):
   ```jsonc
   // →
   { "id": 1, "op": "provenance_ancestry", "v": 2, "work_id": 1004 }
   // ←
   { "id": 1, "type": "response", "v": 2,
     "value": { "type": "provenance_ancestry_result",
                "chain": [
                  { "source_work_id": 1005, "link_id": 7, "source_work_title": "Frankenstein…", "source_author_name": "Mary Shelley" },
                  { "source_work_id": 1006, "link_id": 9, "source_work_title": "Notes…", "source_author_name": "Bob" }
                ]}}
   ```
   Requires read permission on the work (`ensure_can_read`).

2. **Embedded in `attribution_query`** — the same enriched chain is attached to the
   attribution response as `chain_payload` when ancestry is non-empty
   (`server/server.rs:1617`), and each span carries `provenance_chain`
   (`AttributionSpanPayload.provenance_chain`). This is what the UI renders as the
   **Derivation Chain**.

### UI

`AttributionPanel.tsx` renders the chain as
`source_work → … → This document`, plus per-author `transcluded by {name}`.

---

## Exercising it

### From Rust (unit tests)

```bash
cargo test --features server --lib \
  --manifest-path original-code/xanadugold/src-rust/Cargo.toml
```

Most relevant tests:
| Concern | Test | Location |
|---|---|---|
| Transclusion placer provenance | `transclusion_attribution_propagates_historical_provenance` | `server/server.rs` |
| Ancestry walks full chain | `provenance_ancestry_walks_full_chain` | `server/server.rs:15158` |
| No-incoming-links ancestry empty | `provenance_chain_no_incoming_links` | `server/server.rs:15206` |
| Ancestry embedded in attribution query | `attribution_query_provenance_chain_multi_hop` | `server/server.rs` |
| Backward-compat serde (new field absent) | `element_provenance_source_work_id_deserializes_without_field` | `server/server.rs` |
| In-memory attribution log | `in_memory_log_works` | `server/transport/attribution_log.rs:399` |
| Endorsement authority/data model | `membership_*`, `endorsement_*` (109 tests) | `edition/endorsement.rs`, `server/server.rs` |

For full server/transport exercise (WebSocket layer):
```bash
cargo test --features server --test integration \
  --manifest-path original-code/xanadugold/src-rust/Cargo.toml
```

### End-to-end via the server

Use the existing test-data scripts against a running server, then inspect the
attribution panel / call the RPCs:

```bash
# 1. start the server
./target/release/xudanu-server run 127.0.0.1:8080 --static-dir web/app/dist

# 2. seed historical authors + source works + transclusion links
node scripts/create-test-data.js
node scripts/test-transclusion-links.js

# 3. open the composite doc in the browser and toggle:
#    More → Show Attribution  (Derivation Chain + "transcluded by" labels)
```

`scripts/test-transclusion-links.js` creates 3 transclusion links and calls
`work_apply_transclusion_attribution` for each — after it runs, the target document's
`provenance_ancestry` and `attribution_query` will carry the chain and the
`transcluded_by` placer info.

See `docs/TRANSCLUSION-TEST-PLAN.md` (Groups C, F, G) for the full manual checklist
covering chains, mixed provenance, and ancestry display.

---

## Open work: `WorkTransclusionAncestry`

A dedicated `WorkTransclusionAncestry` struct/endpoint does **not** exist. Ancestry is
currently delivered as an anonymous `Vec<ProvenanceHopPayload>` on
`provenance_ancestry` / `attribution_query`. If a named, self-describing type is wanted
(carrying the work id + enriched chain + placer info + hop count, with its own RPC and
unit test), it would be a small addition on top of the existing
`provenance_ancestry`/`enrich_provenance_hops` plumbing.
