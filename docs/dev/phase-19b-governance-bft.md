# Phase 19b: Governance & BFT

**Status: HARDENED 2026-09-20** — the initial PBFT review found safety
and liveness gaps (see "Review findings fixed" below); this is the
protocol as now implemented, with signed vote certificates,
all-to-all vote relay, sealed-batch verification, buffered commits,
view change, and cluster policy.

## Deployment policy

| Nodes | Mode | Quorum | Behavior |
|-------|------|--------|----------|
| 1 | Single-server | 1 | Governance works locally; server signs its own votes; seals execute immediately |
| 2–3 | Refused | — | No BFT possible (needs 3f+1=4); propose returns None with a logged reason |
| 4 | BFT (f=1) | 3 | Minimum viable |
| 5+ | BFT (f=1+) | 2f+1 | 5 recommended operationally (f=1 + one crash for liveness) |

## Review findings fixed (2026-09-20 hardening)

- **S1 sealed batches carried no proof** → votes are Ed25519-signed
  over (view, seq, phase, digest, voter); `SealedBatch` embeds signed
  prepare/commit certificates; `verify_sealed` checks digest + 2f+1
  distinct valid signatures before any execution; `GovernanceSealed`
  recipients verify before applying.
- **S2 clients could inject votes as arbitrary members** → the
  `GovernancePrepare`/`GovernanceCommit` wire ops now cast only THIS
  server's own signed vote; client payloads are ignored.
- **S3 view changes forked the log** → view change carries prepared
  certificates; `prepared_digests` (seq → digest) blocks any
  conflicting re-proposal at a prepared sequence, in any view.
- **S4 early commit votes were dropped** → buffered during Prepare and
  replayed on prepare-quorum.
- **L1 the wire protocol deadlocked at quorum ≥ 3** → replicas now
  create their own round from the pre-prepare
  (`receive_pre_prepare` validates view/seq/leader) and votes are
  broadcast all-to-all via the governance channel (each originator
  broadcasts its own vote — no relay storms).
- **L2 sealed batches never propagated** → sealing broadcasts
  `GovernanceSealed` with certificates; replicas verify + execute +
  ingest.
- **L3 no leader-failure recovery** → 10s round timeout → signed
  VIEW-CHANGE for view+1 (with highest-prepared certificate) → new
  leader assembles NEW-VIEW from 2f+1 verified view-changes → all
  replicas enter the new view with the watermark carried forward.
- **Deterministic leader election** — active members are sorted by
  server_id; OrSet arrival order previously made leader selection
  differ per replica (proposals rejected as "not from leader").
- **Bounded state** — the governance log prunes to the last 64 sealed
  batches with a `pruned_below` watermark (checkpoint hygiene).

## Castro-Liskov conformance

| Mechanism | Status | Notes |
|-----------|--------|-------|
| Pre-prepare (leader proposal, view+seq) | ✅ | Leader-checked, fork-checked |
| Prepare phase, 2f+1 quorum | ✅ | Signature + digest bound |
| Commit phase, 2f+1 quorum | ✅ | Buffered early votes |
| Sealed execution, deterministic order | ✅ | Only after certificates |
| Signed messages (per-member keys) | ✅ | Ed25519, `verify_strict` |
| View change + new-view | ✅ | Simplified: highest-prepared certificate transfer |
| Checkpoints / log GC | ◐ | Retention-window pruning; no stable-checkpoint protocol |
| Client request authentication | ✅ | Admin-gated propose; votes server-to-server only |
| State transfer for lagging replicas | ◐ | Sealed-batch ingestion; no bulk catch-up |
| Watermarks on sequence numbers | ◐ | Implicit via prepared watermark |

## Test coverage

- 46 governance state tests: digests, signature binding (every field
  tamper-detected), equivocation across digests, certificate
  forgery (tampered content / stripped sigs / unregistered keys),
  buffered-commit replay, pre-prepare validation, fork protection,
  view-change quorum + watermark carry, timeout/touch, log pruning,
  ingest idempotence, cluster policy (2–3 refused), single-server
  mode, escalation freshness.
- **In-process mesh harness** (`governance_mesh` tests): N real
  servers driving the REAL protocol code (`handle_governance_frame`
  — the same orchestration the live ws loop uses) with partition /
  crash / view-change-tick controls:
  - 4-node happy path cascades to a seal on all nodes
  - leader crash mid-round → view change → NewView → client retry
    seals with identical digests (no fork)
  - byzantine leader's forged seal (hijacked transactions, same
    certificates) rejected everywhere
  - conflicting re-proposal at a sealed sequence refused
  - NewView forgery matrix: wrong assembler, cross-view
    certificates, insufficient certificates — all rejected
- Functional 4-node round over the server glue with replica
  catch-up.
- Coverage: **PBFT core block at 90% line coverage** (was 74%
  pre-harness); the ws orchestration layer went 6% → 25%.
- Security scans: cargo-audit clean after rustls 0.23.43 → 0.23.45
  (RUSTSEC-2026-0285); cargo-deny license failures are pre-existing
  (deny.toml allow-list too narrow — separate maintenance task).

## Bugs the harness caught (2026-09-20, all fixed)

1. **Early prepare votes were dropped** — a replica whose pre-prepare
   was delayed lost early prepare votes and stalled at quorum-1
   forever under simple message reordering. Now buffered and replayed
   on round creation (mirrors the buffered-commit fix).
2. **Commit votes were broadcast but never self-counted** — the
   emitter's own round missed its own vote; rounds stalled at
   commit-quorum-1 on the origin node.
3. **The NewView assembler never applied its own NewView** — the new
   leader broadcast the view change but stayed in the old view.
4. **Digest covered the proposal envelope** (view/proposer/timestamp)
   — re-proposing the same value in a new view changed the digest,
   breaking prepared-certificate carry-over. Digests now bind only
   (sequence, transactions), matching PBFT's request digest.
5. **Cluster size not synced in view-change paths** — quorum computed
   from the default cluster_size 1 on fresh nodes.
6. **View-change election had no timeout** (review finding #2) — a
   wedged election (new leader also down) never retried. Stall
   detection now covers: stalled rounds, view-changes-in-flight
   without a NewView, and entered-view-without-a-proposal; targets
   escalate only after a full timeout collecting (no scattering).
7. **NewView verification gaps** (review finding #4) — assembler must
   be the leader of the announced view with a valid signature;
   certificates must target exactly that view with distinct senders.

## PBFT/BFT testing tooling survey (2026-09-20)

- **Shuttle** (awslabs, Rust) — randomized concurrency testing with
  PCT probabilistic bug-finding guarantees and deterministic
  reproduction; tokio wrappers available. Best next step: wrap the
  mesh harness in `shuttle::check_random` for randomized scheduling
  of the protocol cascade.
- **TLA+ / TLC** — Castro-Liskov PBFT safety is classically specified
  in TLA+ (the thesis appendix PlusCal spec); writing a TLA+ spec of
  THIS simplified protocol and model-checking agreement/validity
  invariants at n=4 would give the strongest safety confidence.
- **Jepsen** — black-box fault injection (partitions, kills, clocks)
  against the Docker 3-node federation; industry gold standard,
  largest investment. Natural fit once a 4-node demo cluster exists.
- **madsim** — deterministic tokio/network simulator; an alternative
  to Shuttle for asynchrony testing at the transport layer.
- Recommendation: adopt Shuttle around the mesh harness next (cheap,
  high yield), then a TLA+ safety spec; Jepsen when the 4+ node
  federation demo is real.

## Performance envelope (3–5 nodes)

Governance ops are rare (admissions, key rotations, royalties): a
round costs 1 pre-prepare + (n−1) prepares + n commits ≈ 3n frames,
each ~200 bytes + one Ed25519 signature (~50µs sign, ~80µs verify).
Verification of a sealed batch (2 × 2f+1 sigs) ≈ 0.5ms. The timeout
poll runs every 5s per connection; negligible. Single pending round
at a time — pipelining deliberately omitted (governance tx volume
does not justify it; revisit if royalty recording becomes
high-volume).

## Wire Operations (0x1Bxx range)

| Opcode | Operation | Auth Required |
|--------|-----------|---------------|
| `0x1B01` | `GovernancePropose` | Admin |
| `0x1B02` | `GovernancePrepare` (casts SELF vote) | Login |
| `0x1B03` | `GovernanceCommit` (casts SELF vote) | Login |
| `0x1B04` | `GovernanceSeal` | Admin |
| `0x1B05` | `GovernanceLog` | Login |
| `0x1B06` | `GovernanceStatus` | Login |

## Server-to-Server Federation Frames

| Frame | Purpose |
|-------|---------|
| `GovernancePrePrepare` | Leader proposes a governance batch |
| `GovernancePrepareVote` | Signed prepare vote (broadcast all-to-all) |
| `GovernanceCommitVote` | Signed commit vote (broadcast all-to-all) |
| `GovernanceSealed` | Sealed batch + certificates (broadcast on seal) |
| `GovernanceViewChange` | Signed view-change with prepared certificate |
| `GovernanceNewView` | Leader's 2f+1 view-change assembly |

## Governance Transactions

Admit / Expel / KeyRegister / RoyaltyRecord (unchanged from the
original design — see git history for details).

## Key Types

- `GovernanceProposal` (+ `digest()`)
- `PbftVote` (+ digest + Ed25519 signature)
- `SealedBatch` (+ digest + signed certificates)
- `ViewChangeMessage` / `NewViewMessage`
- `ConsensusRound` (+ signed certificates, buffered commits, started_at)
- `GovernanceState` (+ prepared_digests, pruned_below, view_change_votes)

## Follow-ups closed (2026-09-20, second hardening round)

1. ✅ **State transfer**: `GovernanceLogRequest/Result` frames — a
   lagging replica requests the sealed tail, each batch is
   certificate-verified and executed in order; a pruned-past gap is
   detected and refused loudly (full rejoin required). Mesh test
   covers catch-up + no-fork-via-transfer + gap refusal.
2. ✅ **Randomized mesh fuzz**: 25-seed delivery-order shuffling
   (every message arrives, in randomized order) — liveness (always
   seals) + safety (identical digests, no fork). This is the ordering
   class that hid three real bugs; Shuttle-style thread randomization
   doesn't apply to the single-threaded event mesh, so event-order
   randomization is the tool (18/18 mesh scenarios stable).
3. ✅ **deny.toml licenses**: proper OSS allow-list; the gate caught a
   REAL issue — `epub-2.x` is GPL-3.0 and was linked into the
   Apache-2.0 server. EPUB import is now isolated behind the
   non-default `epub-import` feature (operators opting in accept GPL
   terms for their build); core/server builds are GPL-free and any
   new GPL dependency fails the gate. NCSA (libfuzzer) and
   CDLA-Permissive-2.0 (webpki-roots) allow-listed as permissive.
4. ✅ **Transport DOS**: per-IP federation connection cap (8 live
   sockets) enforced at the federation ws entry, slot released on
   close; unattributable connections uncapped; capped refusals
   logged as SECURITY events.
5. ✅ **TLA+ safety spec** (`spec/xudanu-pbft/`): formal model of the
   quorum mechanics (signed digest-bound votes, one byzantine node
   with unrestricted equivocation, arbitrary message reordering).
   TLC-checked at N=4/Q=3/2 digests/1 sequence: **337,761 states, no
   violations of Agreement, TypeOK, or Validity** — the protocol
   cannot fork. Single-sequence scope: the cross-sequence fork
   protection (prepared digests) is enforced in code and covered by
   mesh tests, not re-proven here.
6. **cargo-audit** clean (6 allowed unmaintained-crate warnings,
   pre-existing transitive deps).

## Remaining gaps

1. Full stable-checkpoint protocol (sequence watermarks beyond the
   retention prune) if governance volume ever grows.
2. Client retry semantics: unprepared requests lost on view change
   are the client's responsibility to resubmit (mesh tests model
   this); a durable client-side retry queue would smooth it.
3. Multi-sequence TLA+ model (state-explosion-bound; needs symmetry
   reduction or abstraction refinement to check S={1,2}).
