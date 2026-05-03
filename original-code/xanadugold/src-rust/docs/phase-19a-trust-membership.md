# Phase 19a: Trust & Membership

## Overview

Phase 19a implements the **web-of-trust join protocol** and **membership management**
for the Xudanu federation. It governs which servers may join and participate in the
federation through endorsement-based admission.

This is the third plane of consensus — the **Governance Plane** — sitting above
the Content Plane (Phase 16) and Reconciliation Plane (Phase 18).

## Key Concepts

### Membership Entry

A `MembershipEntry` records a server's membership in the federation:

- `server_id`: Derived from the server's Ed25519 verifying key
- `verifying_key_hex`: The server's public signing key
- `kex_public_hex`: The server's X25519 key exchange key
- `endorsed_by`: List of `EndorsementProof` from other members
- `joined_at`: Unix timestamp of when the member joined
- `status`: `Active`, `Suspended`, or `Pending`

### Endorsement Proof

An `EndorsementProof` is a cryptographic attestation that one server vouches
for another:

- `endorser_server_id`: The endorsing server's ID
- `endorser_key_id`: The key ID used for signing
- `endorsee_server_id`: The server being endorsed
- `endorsee_verifying_key_hex`: The endorsee's public key
- `signature`: Ed25519 signature over the canonical transcript
- `timestamp`: When the endorsement was made

The canonical transcript is:

```
endorser_server_id || 0x00 || endorsee_server_id || 0x00 ||
endorsee_verifying_key_hex || 0x00 || endorser_key_id_be || timestamp_be
```

### Membership State

`MembershipState` wraps an `OrSet<MembershipEntry>` CRDT with admission policy:

- `min_endorsements`: Minimum endorsements required for full membership
- `bootstrap_mode`: Allows initial members without endorsements
- `tag_counter`: Monotonically increasing counter for unique CRDT tags

## Join Protocol

```
1. BOOTSTRAP
   Server seeds itself as a founding member with self-endorsement.
   Config seeds initial trusted peer keys.

2. JOIN REQUEST (over encrypted federation channel)
   Joining server sends MembershipEntry with endorsement proofs
   from existing members.

3. VALIDATION
   Receiving server verifies:
   - Server is not already a member
   - Each endorsement signature is valid
   - Each endorser is a known member
   - Endorsement count >= min_endorsements

4. JOIN RESPONSE
   Accept: Server adds entry to membership OrSet and offers its
           own endorsement.
   Reject: Server returns reason (insufficient endorsements,
           already member, etc.)

5. MEMBERSHIP SYNC
   New member propagates via CRDT merge to all connected peers.
   OrSet<MembershipEntry> ensures convergence.

6. ENDORSEMENT OFFER
   Any member can endorse a peer separately from join.
   Adds EndorsementProof to the member's entry.

7. LEAVE
   Server sends MembershipLeave, triggering remove_value() in OrSet.
   Removal propagates via CRDT merge (tombstones).
```

## Wire Operations (0x19xx range)

| Opcode | Operation | Direction | Auth Required |
|--------|-----------|-----------|---------------|
| `0x1901` | `MembershipJoinRequest` | Client → Server | Yes |
| `0x1902` | `MembershipJoinResponse` | Server → Client | N/A |
| `0x1903` | `MembershipEndorseOffer` | Client → Server | Yes |
| `0x1904` | `MembershipEndorseAccept` | Client → Server | Yes |
| `0x1905` | `MembershipSync` | Client → Server | Yes |
| `0x1906` | `MembershipSyncResult` | Server → Client | N/A |
| `0x1907` | `MembershipLeave` | Client → Server | Yes |
| `0x1908` | `MembershipList` | Client → Server | Yes |
| `0x1909` | `MembershipVerify` | Client → Server | Yes |

## Server-to-Server Federation Frames

| Frame | Purpose |
|-------|---------|
| `MembershipJoinRequest` | Join request from a peer server |
| `MembershipJoinResult` | Accept/reject result |
| `MembershipEndorseOffer` | Offer endorsement to a peer |
| `MembershipEndorseResult` | Acceptance of endorsement |
| `MembershipSyncPush` | Push membership OrSet to peer |
| `MembershipSyncResult` | Reply with merged OrSet |
| `MembershipLeave` | Announce departure |

## Server Methods

- `membership_bootstrap_init()` — Self-register as founding member
- `membership_self_entry()` — Get own membership entry
- `membership_list()` — List all active members
- `membership_count()` — Count active members
- `membership_is_member(server_id)` — Check if server is a full member
- `membership_is_known_member(server_id)` — Check if in OrSet (ignoring endorsements)
- `membership_verify(server_id)` — Detailed membership verification
- `membership_process_join(entry)` — Validate and accept/reject join
- `membership_sign_endorsement(server_id, vk_hex)` — Create signed endorsement
- `membership_verify_endorsement_proof(proof, vk)` — Verify an endorsement signature
- `membership_endorse(server_id, proof)` — Add endorsement to member
- `membership_leave()` — Remove self from federation
- `membership_remove(server_id)` — Remove a specific member
- `membership_merge(other)` — Merge remote membership state
- `membership_export_orset()` / `membership_merge_orset()` — Wire-level CRDT sync

## Test Coverage

### Unit Tests (60 new)
- MembershipEntry: construction, status, endorsement counting, serialization
- EndorsementProof: canonical transcript uniqueness, serialization
- MembershipState: CRUD, validation, bootstrap mode, endorsement upgrades
- CRDT merge: union, commutativity, idempotency, three-way convergence, removal propagation
- JoinResult and MembershipVerifyResult serialization
- Server methods: bootstrap, join, leave, remove, endorse, verify, merge
- Cross-server endorsement verification
- Auth guards on dispatch

### Integration Tests (9 new)
- Bootstrap registers self as member (wire op)
- Verify returns member info (wire op)
- Join via wire op with endorsement
- Sync via wire op
- Leave via wire op
- Endorse offer via wire op
- Merge across two servers (CRDT)
- Cross-server endorsement verification
- Tampered endorsement rejection

## Configuration

`FederationConfig` fields:
- `min_endorsements` (default: 2) — Minimum endorsements for full membership
- Set to 1 for bootstrap/testing

## Design Decisions

1. **Self-endorsement for bootstrap**: The founding member endorses itself
   during `membership_bootstrap_init()`. This avoids the chicken-and-egg problem
   of needing endorsements from members that don't exist yet.

2. **`is_known_member` vs `is_member`**: `is_member` requires active status AND
   sufficient endorsements. `is_known_member` just checks OrSet presence. Join
   validation uses `is_known_member` for endorsers to avoid recursive requirements.

3. **Unique tags for endorsement updates**: Each `endorse_member` call generates
   a new `OrSetTag` using an internal counter. This prevents tombstone conflicts
   when updating a member's endorsement list.

4. **CRDT-based membership**: OrSet<MembershipEntry> ensures membership converges
   across servers without central coordination. Removals propagate via tombstones.
