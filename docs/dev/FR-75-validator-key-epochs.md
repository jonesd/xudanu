# FR-75: Validator Key Epochs — Rotation, Revocation, and Reconfiguration via Consensus

**Status:** step 1 SHIPPED 2026-09-20 (governance-only validator keys);
steps 2-4 proposed
**Created:** 2026-09-20
**Depends on:** FR-19b (PBFT hardening: signed vote certificates, view
change, mesh harness)
**Scope:** governance plane — validator key lifecycle

## Problem

Validator verifying keys currently have **no lifecycle**: a member's
key is valid from registration until `Expel`/`KeyRegister` replaces
it. Concretely:

1. **Unbounded stolen-key window** — a compromised key votes until
   someone notices and rotates it manually.
2. **No revocation** — a rotated-away (or stolen) key cannot be
   replay-blocked; nothing marks it retired.
3. **Two membership planes** — the CRDT join/sync path can merge
   verifying keys into membership *outside* consensus, so even
   governance-driven rotation is decorative: an attacker (or a
   misbehaving peer) can reintroduce an old key via membership sync.
4. **Rotation authority = current key alone** — whoever holds the
   current key can rotate to a key they control, permanently owning
   the identity. Epochs bound nothing for them; they renew forever.
5. **No reconfiguration on loss** — a decommissioned member that
   stays in membership keeps the quorum denominator inflated; quorums
   can require votes that can never validate → deadlock.

## Goals

- Stolen-key damage window bounded by a consensus-visible epoch
- Retired keys replay-blocked (with a bounded grace window for
  in-flight cross-view certificates)
- Validator keys enter/leave membership ONLY through sealed
  governance transactions
- Rotation requires authority beyond the current key (operator
  recovery co-signature, or member-quorum social recovery)
- Safety NEVER depends on wall clocks

## Non-goals

- X.509 / an internal CA (consensus trust stays self-certifying;
  CA is only ever a candidate for transport TLS later)
- Threshold signatures / BLS aggregation (perf optimization,
  revisit if certificate size matters)
- State transfer of pruned history (FR-19b known gap #1, separate)

## Design

### 1. Sequence-based epochs (logical time, never wall clocks)

`MembershipEntry` gains epoch bounds measured in **sealed sequence
numbers**, not timestamps:

```rust
pub struct MembershipEntry {
    // ... existing fields ...
    pub epoch: KeyEpoch,
}

pub struct KeyEpoch {
    /// Valid for sealed sequences [valid_from_seq, valid_until_seq).
    /// valid_until_seq = u64::MAX means "no expiry set" (migration
    /// default for existing entries).
    pub valid_from_seq: u64,
    pub valid_until_seq: u64,
}
```

Vote verification rejects votes whose (view, seq) round falls outside
the voter's epoch. Wall clocks appear ONLY as liveness nudges
(metrics/warnings when a rotation is due) — never in validity
decisions. A partitioned node with a skewed clock cannot disagree
about safety.

Epoch length: governance parameter (e.g. 10,000 sealed sequences or
a proposal at each N-th sequence — tunable; for 3-5 node
federations with rare governance ops, wall-clock *prompting* with
sequence *enforcement* is expected).

### 2. Retired-key ledger (grace for cross-view certificates)

`GovernanceState` gains:

```rust
/// seq → (retired_at_seq, keys retired at that seq). Grace window
/// G (sequences) during which retired keys still verify for
/// VIEW-CHANGE certificates only (in-flight elections signed under
/// the old key must complete, or a rotation mid-election stalls).
retired_keys: Vec<RetiredKey>,
```

Rules:
- `KeyRegister` seals → old key appended with `retired_at_seq` = the
  sealing sequence
- Prepare/commit votes: rejected immediately after retirement
- View-change certificates: accepted while
  `current_sequence - retired_at_seq <= G`
- Ledger pruned with the existing log watermark (bounded memory)

### 3. Governance-only validator keys (close the CRDT bypass)

Membership keeps two roles, split at the type level:

- **Validator keys** (vote verification): mutated EXCLUSIVELY by
  sealed `Admit` / `Expel` / `KeyRegister`. The CRDT membership-sync
  path merges display/contact metadata but MUST NOT add or alter
  `verifying_key_hex` for validator entries. Enforcement: validator
  mutations carry the sealed sequence that authorized them; any sync
  frame proposing a validator-key change without a matching seal is
  dropped + logged.
- **Directory entries** (peering, origins): unchanged CRDT behavior.

This makes the phase-19b invariant true end-to-end: *the validator
set is exactly what consensus sealed*.

### 4. Rotation authority (beyond the current key)

`KeyRegister` for server X requires EITHER:

- **Path A — operator recovery:** signature by X's current key AND
  X's **recovery key** (an operator-held, offline Ed25519 key
  registered at admission; re-registrable only via path B), OR
- **Path B — social recovery:** signatures by a quorum (2f+1) of
  OTHER members, enabling recovery when the operator lost both keys
  or when the current key is known-stolen and the thief must be
  locked out.

A thief holding only the current key can rotate nothing: path A
needs the offline recovery key, path B needs other members' quorum.

`GovernanceTx::KeyRegister` gains `recovery_signature:
Option<SignedRecoveryAuthorization>` and the dispatch validation for
the two paths. `Admit` gains `recovery_key_hex`.

### 5. Reconfiguration on expiry (quorum per epoch)

On any sealed batch containing `KeyRegister`/`Expel` (and on
detection that a member's epoch ended without renewal):

- The member's voting rights end at their `valid_until_seq`
- **Quorum is computed against the validator set of the round's
  sequence** (epoch-frozen): members whose epochs cover the sequence
  count; others don't
- A member that expires silently shrinks the denominator — for n=4,
  one expiry leaves quorum 3 of 3 (no fault tolerance left; alert
  fires). Two expiries leave governance halted by design (safe, not
  live) until `Expel`/re-admit via the remaining members or operator
  recovery

This also resolves the pre-existing "membership changes mid-flight"
weakness: the validator set is a function of (sequence), so every
replica computes the same set for the same round.

### Wire changes

| Change | Where |
|---|---|
| `KeyEpoch` on membership entries | federation.rs, snapshot compat via serde defaults |
| `retired_keys` ledger | GovernanceState (serde default, snapshot compat) |
| `KeyRegister` recovery fields | GovernanceTx + dispatch validation |
| `Admit` recovery key | GovernanceTx + membership |
| Validator-sync guard | federation_handler MembershipSync arm |
| `GOVERNANCE_EPOCH_LENGTH` param | governance status op |

Migration: existing entries default to `valid_until_seq = u64::MAX`
(no expiry) — no fork, epochs tighten as operators rotate.

## Test matrix (mesh harness)

1. **expiry-rejects-votes**: vote from a member whose epoch ended is
   refused; quorum recomputes; round completes with remaining members
2. **rotation-kills-old-key**: after KeyRegister seals, old-key
   prepare/commit votes refused everywhere
3. **grace-window-view-change**: view-change signed under the old key
   within G sequences still assembles the NewView; beyond G it doesn't
4. **crdt-bypass-closed**: MembershipSync frame carrying a validator
   key change without a matching seal is dropped; with a seal it applies
5. **rotation-authority**: KeyRegister with only the current key's
   signature is refused; current+recovery accepted; quorum-of-others
   (path B) accepted; recovery-key rotation by an attacker WITHOUT the
   current key refused
6. **stolen-key-takeover-fails**: thief holds current key only →
   cannot rotate, cannot survive epoch expiry → locked out at expiry
7. **dead-member-shrinks-quorum**: expired member's round-quorum
   computed from the epoch validator set; no deadlock with 1 expiry at
   n=4; governance halts safely (not forks) with 2
8. **epoch-frozen-consistency**: replicas with divergent wall clocks
   agree on validator set per sequence (clock skew scenario)

## Where this lands us

With epochs + consensus rotation + the four accompaniments:

- **Adversary model satisfied:** f byzantine validators, no clock
  assumptions in safety, stolen-key windows bounded by epoch,
  identity takeover requires the offline recovery key or a quorum of
  other members
- **Comparable lifecycle semantics to production BFT networks**
  (Tendermint validator rotation + unbonding ≈ our epochs+grace;
  HotStuff reconfiguration ≈ our epoch-frozen quorums)
- **Remaining beyond this FR** (the hostile-internet ladder): state
  transfer (FR-19b gap 1), Shuttle-randomized mesh + TLA+ safety
  spec (FR-19b tooling survey), transport-layer DOS resistance,
  operational alerting on rotation/expiry events

## Implementation order

1. ✅ **Governance-only validator keys** (shipped): membership entries
   carry `admitted_by_governance` (set only by sealed Admit execution
   or bootstrap self-registration; monotonic in the OrSet merge);
   `governance_validator_members()` is the member set for ALL consensus
   computation (quorum, leader, vote membership, view-change); the
   CRDT merge guard refuses new-member entries and key changes from
   sync frames (new entries dropped, key changes sanitized back to
   the governed keys); join-protocol entries are directory-only until
   a governance Admit seals. Tests: sync-drops-new/key-changes,
   sync-merges-metadata, join-is-not-validator-admission,
   mesh-smuggle (test matrix #4). One panic (unwrap on unknown
   server_id in the guard) and one merge-stickiness bug found and
   fixed during implementation.
2. KeyEpoch + expiry rejection + epoch-frozen quorums + tests 1, 7, 8
3. Retired-key ledger + grace + tests 2, 3
4. Rotation authority (recovery keys) + tests 5, 6

**Cluster guidance confirmed:** with the expiry machinery of steps
2-4, a 4-node cluster at one unrenewed expiry drops to quorum 3-of-3
(zero fault tolerance, technically live). 5 nodes is the default
recommendation; 4 requires rotation alerting. This matches the
phase-19b policy table.
