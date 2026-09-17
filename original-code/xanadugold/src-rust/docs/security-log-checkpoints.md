# Security Log Checkpoints & Compaction

**Status:** Phases 1-2 implemented (2026-09-17) — `src/server/transport/log_checkpoint.rs`, `--log-checkpoint-entries`, `--log-retention`, `--log-retention-mode`, `checkpoint-logs` subcommand, extended `verify-security-log`. Phase 3 (OTS anchoring of checkpoint heads) pending. See "Implementation notes" at the end.
**Related:** `docs/SECURITY.md` (audit log), `docs/SECURITY_ISSUES.md` #8, `docs/feature-roadmap.md` Tier A #1 (transparency log), `docs/attribution-plan.md`, FR-60 OpenTimestamps anchoring (`src/server/ots_anchor.rs`)
**Components:** `src/server/transport/chained_log.rs`, `src/server/transport/attribution_log.rs`, `src/server/ots_anchor.rs`, `src/bin/xudanu-server.rs`, `src/crypto/keys.rs`

## Problem

Two hash-chained append-only logs grow without bound:

1. **`security.log.*`** — daily-rotated, chained via `ChainedLogWriter`. Every
   security-relevant event (logins, failures, permission changes) appends a
   line. Unbounded across years of operation.
2. **`attribution/attribution.log`** — one entry (~200 bytes) per attribution
   signature. A busy multi-author server produces thousands of entries per
   day; the file is never rotated.

Both chains are anchored by a seed file stored **next to the log on the same
disk** (`security.log.seed`, `attribution.log.seed`). An attacker with write
access to the data directory can rewrite the entire log and recompute every
chain hash — the chain detects accidental corruption and naive edits, but not
a competent rewrite.

The roadmap's planned fix (feature-roadmap.md, key-management tiers) is
**periodic compaction via signed checkpoints**, the certificate-transparency
pattern.

## Goals

- Bound on-disk growth of both logs via a retention policy.
- Make chain anchors independent of on-disk seed material: checkpoints are
  signed with the server's Ed25519 identity key (passphrase-protected at
  rest, `key_history.json` rotation chain).
- Keep full forensic detail available for a configurable window; older
  segments remain provable only in aggregate (via signed heads).
- Backward compatible: no checkpoints present = exactly today's behavior.

## Non-goals

- External publication of checkpoints (gossip to peers, embedded in another
  server's log). The checkpoint file format makes this possible later; we do
  not build the transport now.
- Database-backed audit storage.
- Changing the wire protocol. Checkpoints are a local-disk mechanism.

## Design

### Checkpoint format

One JSON file per checkpoint, written atomically (tmp + rename):

```
security.log.checkpoint.000001      (data-dir)
attribution.log.checkpoint.000001   (data-dir/attribution/)
```

```json
{
  "log": "security",
  "seq": 1,
  "timestamp": 1760000000,
  "entries": 45123,
  "head_hash": "a3f0...",
  "files_covered": ["security.log.2026-09-01", "security.log.2026-09-02"],
  "key_id": "ed25519:9c1d...",
  "signature": "8aab..."
}
```

- `entries` — cumulative non-empty line count across all files, in
  lexicographic order, from the beginning of time.
- `head_hash` — chain hash of the last line covered.
- `files_covered` — completed files fully included in the range. The current
  (still-appended) file is never listed, never deletable.
- `key_id` — the Ed25519 key id from `KeyHistory` at signing time; verifiers
  resolve it through `key_history.json`'s verified rotation chain and check
  the key was valid at `timestamp`.
- `signature` — Ed25519 over the BLAKE3 digest of
  `log || seq || timestamp || entries || head_hash || files_covered[]`
  (domain-separated label `xudanu-log-checkpoint-v1`).

Checkpoint JSON is serde_json (human-facing manifest class, per repo
convention — never postcard here).

### When checkpoints are written

1. **Entry-count threshold.** Default every 10,000 new entries (tunable).
   The ChainedLogWriter / AttributionLog publishes `(entries, head_hash)`
   through a small shared `Arc<Mutex<ChainState>>` updated on every append.
   A background tokio task in `run` (which holds the loaded server key)
   polls the shared state and writes a checkpoint when the threshold is
   crossed. The signer must live outside the tracing layer — the writer
   itself never sees key material.
2. **Graceful shutdown.** The existing shutdown/autosave path writes a final
   checkpoint, so compaction never races live writers.
3. **Explicit CLI.** `xudanu-server checkpoint-logs <data-dir>` for operators
   (loads key with passphrase like other key-using subcommands).

Rotation-boundary-only checkpoints were considered and rejected: daily
rotation plus entry thresholds interacts badly (a quiet day produces no
rotation; a busy day produces checkpoints mid-file, which is fine —
`entries` is cumulative and file-independent).

### Compaction policy

- New `run` flag: `--log-retention <count:files|entries>` plus
  `--log-retention-attribution <entries>`. Default: **keep everything**
  (current behavior); compaction is strictly opt-in.
- A file may be deleted only when ALL of:
  1. It appears in `files_covered` of an existing, signature-valid checkpoint.
  2. A strictly later signature-valid checkpoint exists (so the chain state
     past the deleted span is anchored independently).
  3. It is not the current file of either log.
- Deleted means moved to `<name>.trash` then unlinked after the next
  successful checkpoint cycle (two-phase, crash-safe).
- Optional gzip of files beyond the retention window instead of deletion
  (`--log-retention-mode archive|delete`, default `archive`). Archives are
  still verifiable; verification decompresses on the fly.

The seed files stay forever — they anchor the pre-first-checkpoint span —
but after compaction the seed alone no longer suffices to forge history,
because the surviving checkpoints' signatures would not match a rewritten
chain.

### Attribution log specifics

`attribution.log` is a single unrotated file. After a checkpoint whose
`entries` covers the entire file:

1. Rename to `attribution.log.000001` (or `.000001.gz` in archive mode).
2. Start a fresh `attribution.log` whose chain continues from the
   checkpoint's `head_hash`.

This also fixes a startup cost: `AttributionLog::open` currently re-reads
the whole file to recover the head; after this change it reads at most the
current (post-checkpoint) file. `AttributionLog` already tracks `sequence`
and exposes the chain head (FR-60), so the plumbing exists.

### OpenTimestamps anchoring of checkpoints (FR-60 reuse)

FR-60 already anchors the attribution-log chain head to Bitcoin via
OpenTimestamps (`ots_anchor.rs`: digest → OTS calendars → block-height
receipt in `anchoring/receipt.ots`; enabled by `--ots-anchor`). The same
machinery — `anchor_round`, `OtsTransport`, receipt parsing — anchors
checkpoints:

- After a checkpoint file is written, submit the checkpoint's `head_hash`
  digest through `anchor_round`. Store the receipt beside it as
  `security.log.checkpoint.NNNNNN.ots`.
- Upgrade pending receipts on later rounds (existing fetch-upgrade path).
- A checkpoint with a confirmed Bitcoin attestation has an existence proof
  independent of the server's keys AND its disk: even an attacker holding
  the Ed25519 key cannot forge a backdated checkpoint that predates the
  attestation, and cannot unstamp what Bitcoin has stamped.

This subsumes the "export a checkpoint off-box" mitigation: the receipt is
the exported anchor, produced automatically. Manual export (cron/rsync)
remains useful as a belt-and-braces complement.

### Verification: `verify-security-log <data-dir>`

Extended, in order:

1. **Load and verify `key_history.json`** rotation chain (existing
   `KeyHistory::verify_rotation_chain`). Resolve each checkpoint's `key_id`.
2. **Checkpoint validation** — seq strictly increasing, signatures valid,
   `entries` and `head_hash` monotonic-consistent between consecutive
   checkpoints (a later checkpoint must extend, not fork).
3. **Full mode** (all files present): today's behavior (seed → files in
   lexicographic order, chaining across files), PLUS a check that each
   checkpoint's `entries`/`head_hash` matches the recomputed chain at that
   point.
4. **Anchored mode** (files covered by an old checkpoint are missing or
   archived): start from the newest fully-intact checkpoint's `head_hash`
   as the anchor for surviving files. Report the anchored span as
   "aggregately verified" (signature-backed) rather than line-verified.
5. Exit non-zero on: bad signature, non-monotonic seq, head mismatch at any
   checkpoint boundary, gap that no checkpoint covers (a missing file with
   no covering checkpoint = tamper or corruption).

New sibling flag `verify-attribution-log <data-dir>` (same logic; the
attribution verifier already exists in part — server.rs exposes the chain
head for FR-60).

## Threat model

| Attacker | Without checkpoints (today) | With signed checkpoints |
|---|---|---|
| Accidental corruption / truncation | Detected | Detected |
| Disk-only rewrite of log lines | Undetected (seed on disk) | Detected at first covered checkpoint: rewritten chain head won't match the signed `head_hash` |
| Disk-only rewrite incl. all log files | Undetected (recompute chain from seed) | Detected: forged checkpoints need the Ed25519 key, which is passphrase-encrypted and never on the same path |
| Attacker holding the signing key | n/a | Undetected by signatures alone — closed by OTS-anchoring the checkpoint head (FR-60): a confirmed Bitcoin attestation cannot be backdated or unstamped |
| Deleted everything incl. checkpoints | Denial of service, detectable as absence | Same — but a single exported checkpoint, or one OTS receipt, proves the gap |

The design deliberately makes **export of a single 200-byte checkpoint file**
sufficient to lock a prefix of history. FR-60 makes that export automatic:
every checkpoint digest is OpenTimestamps-anchored, so the anchor lives in
Bitcoin headers regardless of what happens to the server's disk or keys.

## Implementation plan

**Phase 1 — chain state + checkpoints (no deletion)** (~1 day)
- [ ] `ChainState { entries, head_hash }` shared from `ChainedLogWriter` and `AttributionLog`
- [ ] Checkpoint struct + signing/verification against `KeyHistory` (`crypto/keys.rs` key ids)
- [ ] Background checkpoint task in `run` (entry threshold + shutdown hook)
- [ ] `checkpoint-logs` CLI subcommand
- [ ] `verify-security-log` extended: signature + monotonicity checks (full mode)

**Phase 2 — compaction** (~1 day)
- [ ] `--log-retention*` flags, two-phase delete, gzip archive mode
- [ ] Attribution log rotation-at-checkpoint (rename + fresh file chaining from head)
- [ ] Anchored-mode verification; `verify-attribution-log` subcommand
- [ ] Startup fast-path for `AttributionLog::open`

**Phase 3 — hardening** (~half day)
- [ ] OTS-anchor each checkpoint head via `anchor_round`; store receipts as `security.log.checkpoint.NNNNNN.ots`; upgrade pending on later rounds
- [ ] Checkpoint-export helper (`verify-security-log --export-latest <dest>`) for off-box cron
- [ ] Document retention flags in `docs/SECURITY.md` audit section

## Test plan

- Checkpoint signature round-trip; tampered field fails.
- Rewrite of a covered log file recomputed from seed → anchored verification
  FAILS (head mismatch vs checkpoint).
- Delete a covered file with valid checkpoints → verification passes in
  anchored mode, reports span as aggregate-verified.
- Delete a file with NO covering checkpoint → verification fails.
- Forked checkpoint (same seq, different head) → fails.
- Key rotation between checkpoints → old checkpoint still verifies via
  history chain.
- Crash between rename and unlink (trash residue) → next startup reconciles.
- Attribution: append → checkpoint → archive/rename → append → verify across
  boundary; `AttributionLog::open` after compaction reads only current file.
- OTS: stub-transport round submits checkpoint digest, upgrades to confirmed
  receipt (reuse `ots_anchor.rs` test pattern); verify accepts confirmed
  receipt as anchor evidence.
- Existing tests keep passing with zero checkpoints present (backward compat).

## Open questions

1. Default checkpoint interval: 10k entries ≈ how many days on a typical
   small server? Maybe time-based (every 24h) is friendlier; support both,
    whichever fires first?
2. ~~Should `verify-security-log` also verify `attribution.log`~~ Resolved:
   one subcommand verifies both logs.
3. When federation gossip exists (FR-41 network), embed checkpoint heads in
   peer heartbeats? Deferred — format permits it (`files_covered` is
   advisory to remote verifiers).

## Implementation notes (2026-09-17)

Deviations and findings from the Phase 1-2 build:

- **Mid-file boundaries.** Shutdown writes a forced tail checkpoint that
  can land mid-file, and the same daily file keeps growing on the next
  run. Verification is therefore line-granular: each checkpoint pins
  `(entries, head_hash)` at an exact line position, checked during the
  walk; `checkpoint_security_log` re-attaches to a covered file by
  locating the line that chains from the signed head
  (`advance_from_checkpoint`).
- **Security checkpoints fire per completed daily file** (rotation
  boundary) plus a forced tail checkpoint at graceful shutdown. The
  entry-count threshold applies to the attribution log only (resolved
  open question 1).
- **Archive mode is a plain move** into `security.log.archive/` /
  `attribution.log.archive/` — no gzip, no new dependency. Archived files
  remain verifiable in place.
- **Restart bug found and fixed.** `init_tracing`'s argument pre-scan
  matched the program path and resolved the data dir to the literal
  string `"run"`, so security logs were silently written to a stray
  `./run/` directory in the CWD instead of the data dir — for months.
  The pre-scan now follows the documented `run [addr] [data-dir]`
  positional form. Existing stray `run/` directories contain real audit
  history and can be migrated by moving the `security.log.*` files and
  seed into the intended data dir (chain recovery picks up the head);
  verify first, migrate one file set at a time.
- **Attribution rotation**: `AttributionLog::rotate(seq)` archives the
  current file as `attribution.log.NNNNNN` and continues the chain in a
  fresh file; `open()` recovers from the latest checkpoint plus a scan
  of the current file only (startup no longer re-reads archives).
- **Known limitations.** Truncation of the tail after the last
  checkpoint is undetectable until the next checkpoint exists. Logs
  written by the old restart-reset code (pre-fix chains that reset to
  the seed mid-file) will fail verification at the real break — that is
  accurate reporting, not a verifier bug; checkpoint creation also
  refuses to bridge such a break.
