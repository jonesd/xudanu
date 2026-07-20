# TODO

## v0.1.2 (near-term)

### Publish to crates.io

Publish the `xudanu` library and `xudanu-server` binary crate so users can install with:
```bash
cargo install xudanu-server --features server
```

Steps:
1. Add crates.io metadata to `Cargo.toml` (description, repository, license, readme, keywords, categories)
2. Create crates.io account and API token
3. Test with `cargo publish --dry-run`
4. Publish with `cargo publish`
5. Optionally set up CI auto-publish on tag push

Also publish a Docker image to GitHub Container Registry for users who prefer container deployment.

### Non-atomic checkpoint writes

**Severity:** Medium  
**File:** `src/server/server.rs:1538-1543`

`checkpoint_to_file` does `std::fs::write(path, json.as_bytes())` directly. If the
process crashes or loses power during the write, the checkpoint file could be left
partially-written, making restoration impossible. This is amplified by auto-checkpoint
running every 50 operations.

**Fix:** Write to a temp file (e.g. `server.json.tmp`) then `std::fs::rename()` to the
final path. Rename is atomic on most filesystems (POSIX guarantee on same filesystem).

### Auto-checkpoint blocks request processing

**Severity:** Medium  
**File:** `src/server/server.rs:902-912`

`auto_checkpoint` runs synchronously inside `bump_operation`, which is called from the
main request dispatch path. It serializes the entire server state to JSON and writes to
disk, blocking all other request processing for the duration. For a large state, this
could cause noticeable latency spikes every 50th operation.

**Fix:** Spawn the checkpoint write on a background thread using `std::thread::spawn`
or tokio task. Use a `Mutex` or `RwLock` to avoid writing during concurrent mutations.
Alternatively, snapshot the state (clone the serializable parts) and write asynchronously.

## v0.2 (medium-term)

### Club-based access control

Wire up the existing Club/KeyMaster infrastructure for production use:
- Admin bootstrap via CLI (set admin password at init)
- Enforce read_club/edit_club on all operations
- User account system with login
- Remove the `grant_admin_authority` backdoor

### Scalable storage backend

Replace the single `server.json` file with a proper storage engine:
- SQLite for structured queries and atomic writes
- Or append-only log with compaction
- Blob storage for large binary content (currently inline in JSON)
- Incremental checkpointing instead of full state serialization

### CI: ARM Linux and Windows builds

- ARM Linux musl: use `cross` tool or different approach for `aws-lc-sys` cross-compilation
- Windows: verify the PowerShell fix works for the packaging step

### Tiered key management for production

Design doc: `docs/key-management-design.md`

**Phase A: Server Lock/Unlock State** (2-3 days)
- Add `Locked`/`Unlocked` server state
- Gate signing operations behind unlock
- Add `server_unlock`/`server_lock` wire operations
- Auto-lock timeout (default: 1 hour)
- `/health` endpoint reports lock state

**Phase B: Data Encryption at Rest** (3-5 days)
- Generate Data Encryption Key (DEK) at `init`
- `EncryptedChunkStore` wrapper: XChaCha20-Poly1305 per chunk
- Encrypt manifest and blobs
- Password-derived fallback for environments without TPM

**Phase C: TPM 2.0 Binding** (5-7 days)
- Bind Storage Master Key to TPM via `tss-esapi`
- Auto-unwrap DEK at startup (no passphrase needed for storage)
- Fallback to password mode if TPM unavailable
- Platform: Linux (TPM), macOS (Secure Enclave), Windows (TBS)

**Phase D: Multi-Admin Unlock** (3-5 days)
- Shamir's Secret Sharing for signing key encryption
- N-of-M admin passphrases required to unlock signing keys
- Share rotation on admin change

**Phase E: Cloud KMS Support** (3-5 days)
- AWS KMS, GCP KMS, Azure Key Vault for DEK wrapping
- Auto-detected via environment variables

## Revisions — surface what's already stored

**Background:** Xudanu already stores every revision in the chunk store
(`WorkChunkRef.history: BTreeMap<u64, EditionChunkRef>`). The
plumbing exists; the user-facing features don't. Design doc:
`docs/dev/versioning-design.md` (Approach C — Memex-style first-class
revisions) and `docs/dev/cross-server-resolution.md` (revision
tumblers).

**Phase A: Revision metadata + list/load wire ops** (~1 week)

- [ ] Add `RevisionMeta` to manifest: `description: Option<String>`,
      `is_notable: bool`, `tags: Vec<String>`, `created_by: IdentityId`
- [ ] Wire op `work_revisions_list(work_id) -> Vec<RevisionSummary>`
- [ ] Wire op `work_text_at_revision(work_id, revision_id) -> string`
- [ ] Wire op `work_revision_describe(work_id, revision_id, description)` — set metadata
- [ ] Wire op `work_revision_mark_notable(work_id, revision_id, notable: bool)`
- [ ] Backend: lazy-load old editions from chunk store on demand
      (don't keep `revision_history` fully in RAM)
- [ ] Backend tests: revision list, load by ID, metadata roundtrip
- [ ] Performance test: 1000 revisions on a 10KB doc — list should
      be <100ms, load should be <10ms

**Phase B: Workspace Timeline lens (FR-18 Phase 5)** (~3 days)

- [ ] New lens tab in workspace bottom area: "Timeline"
- [ ] Vertical list of revisions with date, author, description
- [ ] Highlight "notable" revisions (manually marked + auto-detected)
- [ ] Click a revision → loads it in a read-only view
- [ ] "Save revision" button in workspace (explicit) with optional description

**Phase C: Revision diff UI** (~2 days)

- [ ] "Compare" action in Timeline lens
- [ ] Pick two revisions (or revision vs. current)
- [ ] Reuse `ComparePanel` for the diff rendering
- [ ] Uses existing `work_diff_regions` backend

**Phase D: Revision tumblers** (~1 week, per cross-server-resolution.md)

- [ ] Tumbler format: `xan://server.work_id.r{revision_id}`
- [ ] Resolver: parse revision component, load from chunk store
- [ ] HTTP endpoint: `/api/public/work/{id}/revision/{rev}`
- [ ] Wire op: `work_resolve_tumbler(tumbler) -> Edition payload`
- [ ] Pinned transclusions: link to a specific revision (immutable)
- [ ] Cross-server revision resolution (with BLAKE3 verification)

**Phase E: Rollback** (~1 day)

- [ ] Wire op `work_revision_rollback(work_id, target_revision_id)` — non-destructive
- [ ] Creates a new revision equal to the target
- [ ] UI in Timeline lens: "Roll back to this revision"

## LLM Features (Xudanu AI assistant)

**Background:** Ollama is already integrated (`src/server/ollama.rs`)
with three prompts: narration, writing feedback, title suggestion.
The categorization work (FR-22) adds a fourth. Goal: collect all
LLM features under a coherent UX, with conservative token usage
and clear provenance.

Design doc: `docs/dev/FR-22-concepts-and-categorization.md`

**Existing (shipped):**

- [x] `WorkNarrate` — explain what changed between two editions
- [x] `WorkWritingFeedback` — writing critique
- [x] `suggest_title` — title suggestion (used in work creation)
- [x] LLM usage tracker (`LlmUsageTracker`)
- [x] `llm_enabled` server-side check + client flag

**Phase A: Auto-categorization (FR-22)** (~3 days)

- [ ] `build_categorization_prompt(content, existing_tags)` in ollama.rs
- [ ] Wire op `work_auto_categorize(work_id) -> CategorizationResult`
      (suggestion only; doesn't apply)
- [ ] Wire op `work_accept_categorization(work_id, result_id)`
- [ ] Storage: `CategorizationsSection` in manifest (provenance:
      model, timestamp, content hash)
- [ ] Frontend: "Auto-categorize" button in workspace
- [ ] Frontend: suggestion review UI (accept/reject per tag)
- [ ] Trigger policy: once on first save + manual "Re-categorize" button
- [ ] Cache by content hash (skip if same content)
- [ ] Default to small model (llama3.2:3b or qwen2.5:3b)
- [ ] Truncate input to ~4000 chars (~1000 tokens)
- [ ] Strict JSON output for parsing reliability
- [ ] Per-author override (LLM never silently changes metadata)

**Phase B: Work summary (right panel)** (~1 day)

- [ ] `build_summary_prompt(content)` — 2–3 sentence summary
- [ ] Wire op `work_summarize(work_id) -> {summary, model, hash}`
- [ ] Cache by content hash (long TTL — summaries don't need to be fresh)
- [ ] Display in right panel Provenance tab
- [ ] Manual refresh button (don't auto-update on every edit)
- [ ] Provenance: "Summarized by {model} on {date}"

**Phase C: Smart semantic search** (~2 days)

- [ ] `build_semantic_search_prompt(query, candidate_titles)` — rank works by relevance
- [ ] Wire op `search_semantic(query) -> Vec<WorkHit>`
- [ ] Implementation: pre-compute embedding per work (on save), store in chunk store
- [ ] Query: embed query, find nearest works by cosine similarity
- [ ] Falls back to text match if embeddings unavailable
- [ ] Surface in command palette (FR-18 Phase 6)

**Phase D: Related work suggestion** (~1 day)

- [ ] `build_related_works_prompt(content, candidate_works)` —
      "you might want to transclude from…"
- [ ] Wire op `work_suggest_related(work_id) -> Vec<WorkSuggestion>`
- [ ] Uses existing graph edges + LLM ranking
- [ ] Display in right panel Reuse tab
- [ ] Author clicks → opens work picker for transclusion

**Phase E: Review summary (FR-19 Marginalia)** (~1 day)

- [ ] `build_review_summary_prompt(comments)` — synthesize reviewer feedback
- [ ] Wire op `review_summarize(work_id) -> {summary, themes, sentiment}`
- [ ] Display at top of author review dashboard
- [ ] Identifies common themes across reviewers

**Phase F: Translation** (~1 day)

- [ ] `build_translation_prompt(content, target_lang)` — translate to target language
- [ ] Wire op `work_translate(work_id, target_lang) -> {translated, model}`
- [ ] Stores translation as a new work with provenance
- [ ] Original work + translation linked via See Also

**Phase G: Reading level adjustment** (~1 day)

- [ ] `build_reading_level_prompt(content, target_level)` — simplify/complexify
- [ ] Wire op `work_adjust_reading_level(work_id, level) -> {adjusted, model}`
- [ ] Creates a derived work (provenance: derived_by LLM)
- [ ] Useful for education use cases

**Token cost controls (apply to all features):**

- [ ] Per-feature budget in `LlmUsageTracker` (categorize: 100/day, summarize: 50/day, etc.)
- [ ] Hard ceiling per server (configurable, default: 10000 tokens/day)
- [ ] Cache by content hash wherever possible
- [ ] Truncate inputs to minimum needed
- [ ] Default to smallest model that works
- [ ] Author opt-in for auto-features (no surprise compute)
- [ ] Provenance: every LLM-derived output tagged with model + prompt hash
- [ ] Audit log: every call logged with caller, work, tokens used

**Privacy:**

- [ ] Local-first: Ollama runs on the server, no data leaves
- [ ] Optional: external API provider (OpenAI, Anthropic) behind explicit flag
- [ ] Multi-user: only work owner can trigger LLM features on their work
- [ ] Server admin configures which models are available

