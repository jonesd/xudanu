# Phase 19b: Governance & BFT

## Overview

Phase 19b implements the **Governance Plane** — a lightweight PBFT (Practical Byzantine Fault Tolerance) consensus protocol for federation governance decisions. This is the third consensus plane, providing strong consistency (one truth, no forks) for operations that require federation-wide agreement.

## Three Planes of Consensus

| Plane | What | Mechanism | BFT? |
|-------|------|-----------|------|
| Content | Blobs, editions, text spans | G-Set CRDT + blake3 | No — hash IS consensus |
| Reconciliation | Endorsements, branch heads | OR-Set CRDT + DagWood | No — coexisting truths |
| **Governance** | Membership, keys, royalties | **PBFT (3f+1 nodes)** | **Yes — one truth** |

## PBFT Protocol

The consensus follows a simplified PBFT flow:

```
1. PRE-PREPARE: Leader proposes a batch of governance transactions
                with a monotonically increasing sequence number.
                
2. PREPARE:     Each replica validates the proposal and broadcasts
                a Prepare vote. When quorum (2f+1) prepares are
                received, transition to Commit phase.
                
3. COMMIT:      Each replica broadcasts a Commit vote. When quorum
                (2f+1) commits are received, the batch is sealed.
                
4. EXECUTE:     The sealed batch is applied to governance state.
                Transactions are executed in sequence order.
```

### Quorum Requirements

| Cluster Size | Faulty Tolerance (f) | Quorum (2f+1) |
|-------------|---------------------|----------------|
| 1 | 0 | 1 |
| 3 | 0 | 1 |
| 4 | 1 | 3 |
| 7 | 2 | 5 |
| 10 | 3 | 7 |

### Leader Election

The leader for each view is determined by `view_number % cluster_size`. View advancement (leader rotation) happens via `advance_view()`.

## Governance Transactions

Four types of transactions can be proposed and agreed upon via PBFT:

### Admit
```json
{
  "type": "admit",
  "server_id": "server-xyz",
  "verifying_key_hex": "abc123...",
  "kex_public_hex": "def456..."
}
```
Formally admits a server as a member through consensus. Unlike the 19a join protocol (which is request/response between two servers), governance admission is a federation-wide decision.

### Expel
```json
{
  "type": "expel",
  "server_id": "server-bad",
  "reason": "Byzantine behavior detected"
}
```
Removes a member from the federation by consensus. No single server can expel another — it requires quorum agreement.

### KeyRegister
```json
{
  "type": "key_register",
  "server_id": "server-xyz",
  "key_id": 42,
  "verifying_key_hex": "newkey...",
  "kex_public_hex": "newkex..."
}
```
Registers or rotates a server's cryptographic keys through consensus. Ensures all servers agree on the current key state.

### RoyaltyRecord
```json
{
  "type": "royalty_record",
  "origin_server_id": "server-a",
  "target_server_id": "server-b",
  "content_fingerprint_hex": "abcdef...",
  "royalty_type": "transclusion",
  "amount": 100
}
```
Records a transclusion royalty obligation. This is recording, not settlement — payment is a separate concern.

## Wire Operations (0x1Bxx range)

| Opcode | Operation | Auth Required |
|--------|-----------|---------------|
| `0x1B01` | `GovernancePropose` | Admin |
| `0x1B02` | `GovernancePrepare` | Login |
| `0x1B03` | `GovernanceCommit` | Login |
| `0x1B04` | `GovernanceSeal` | Admin |
| `0x1B05` | `GovernanceLog` | Login |
| `0x1B06` | `GovernanceStatus` | Login |

## Server-to-Server Federation Frames

| Frame | Purpose |
|-------|---------|
| `GovernancePrePrepare` | Leader proposes a governance batch |
| `GovernancePrepareVote` | Replica votes prepare on a proposal |
| `GovernanceCommitVote` | Replica votes commit on a proposal |
| `GovernanceSealed` | Propagates a sealed batch to all members |

## Server Methods

- `governance_propose(transactions)` — Propose a batch of governance transactions
- `governance_receive_prepare(vote)` — Process a Prepare vote
- `governance_receive_commit(vote)` — Process a Commit vote
- `governance_seal_round()` — Seal the current round and execute transactions
- `governance_execute_tx(tx)` — Apply a single governance transaction to state
- `governance_log()` — View the governance log
- `governance_current_view()` / `governance_current_sequence()` — Consensus state
- `governance_is_leader()` / `governance_leader_id()` — Leader queries
- `governance_cluster_size()` / `governance_quorum_size()` — Cluster parameters
- `governance_pending_round()` — View the current in-progress round

## Key Types

- `GovernanceTx` — A governance transaction (Admit, Expel, KeyRegister, RoyaltyRecord)
- `GovernanceProposal` — A proposed batch with view, sequence, and timestamp
- `PbftVote` — A Prepare or Commit vote for a specific (view, sequence) pair
- `PbftPhase` — Prepare or Commit
- `SealedBatch` — A fully committed batch in the governance log
- `ConsensusRound` — An in-progress consensus round with vote tracking
- `RoundPhase` — PrePrepare, Prepare, Commit, or Sealed
- `GovernanceState` — The complete PBFT state machine

## Test Coverage

### Unit Tests (21 new)
- GovernanceState construction and cluster sizing
- Quorum calculations for 1/3/4/7/10 node clusters
- Leader rotation through view advancement
- Proposal creation and pending round tracking
- Full consensus flow (4 nodes: propose → prepare → commit → seal)
- Seal rejection when round is not ready
- Wrong view/sequence rejection
- View advancement clearing pending rounds
- Transaction type names
- Serialization roundtrips for proposals, sealed batches, and votes
- Multiple sequential batches
- Dynamic cluster resizing

### Server Method Tests (6 new)
- Bootstrap → propose (single server)
- Full consensus on single server
- Execute Admit/Expel/Royalty transactions
- Governance status queries

### Integration Tests (7 new)
- Governance status via wire op
- Propose via wire op (admin auth required)
- Log query (empty and populated)
- Full consensus via server methods (propose → prepare → commit → seal)
- Royalty recording through consensus
- Propose requires admin auth
- Seal + log roundtrip via wire ops

## Design Decisions

1. **Lightweight PBFT**: Designed for 3-10 nodes, not thousands. Simplified phases without checkpointing or view-change (to be added if needed).

2. **Leader-based proposal**: Only the current leader (by view rotation) can propose. This prevents conflicting proposals for the same sequence number.

3. **Transaction execution on seal**: Transactions are only applied to state after a batch is sealed (quorum commits received). This ensures all nodes execute in the same order.

4. **Governance log is append-only**: Once a batch is sealed, it's in the log forever. No rollback mechanism — if an expel was wrong, the server can be re-admitted through a new Admit transaction.

5. **Tag counter initialized with timestamp**: Prevents cross-server tag collisions in the OrSet that underlies the membership state.

6. **Governance state is NOT CRDT-merged**: Unlike membership and reconciliation, governance state is consensus-driven. Only sealed batches from PBFT are applied, ensuring one truth.
