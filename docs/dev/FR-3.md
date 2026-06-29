# FR-3: Federation Activation

- **ID:** FR-3
- **Status:** Draft (not yet implemented)
- **Date:** 2026-06-29
- **Owner:** backend
- **Depends on:** phases 14–19 (already merged — the federation *components*).

## 1. Overview

Phases 14–19 delivered every federation **building block**: OR-Set/LWW CRDTs,
a PBFT state machine, web-of-trust membership crypto, BLAKE3-verified content
replication, a mutual Ed25519/X25519 + ChaCha20-Poly1305 handshake, and a full
set of inbound frame handlers. There are **no stubs** in that path.

What does **not** exist is the **activation layer** — the runtime wiring that
makes those components actually operate across multiple machines. Today the
server is a *passive* federation node: it accepts `/federation` sockets and
reacts to frames, but it never dials out, never bootstraps itself, never
registers peer keys, never runs a sync loop, and never broadcasts PBFT
messages. Two servers started with `--peer` pointing at each other produce
**zero connections, zero replication, zero membership** — and would reject each
other even if connected.

FR-3 closes that gap: turn the finished components into a running federation of
machines, including a trust model for **donated hosts** (machines contributed by
different users).

## 2. Goals / Non-goals

**Goals**
- A working federation of N machines: each can connect to peers, be recognised,
  replicate content (BLAKE3-verified), converge membership, and reach PBFT
  decisions.
- A trust model so a **donated host** can prove its identity and be endorsed
  into the federation without central infrastructure.
- Minimal operational footprint (each donor runs one `xudanu-server`).

**Non-goals (for v1)**
- NAT traversal / hole-punching (peers must be directly reachable, or via a
  relay/VPN the donor provides).
- Gossip/DNS-based peer discovery (static seed list for v1).
- PBFT view-change / checkpointing / log GC (happy-path consensus only).
- Cross-federation royalties/micropayments settlement.

## 3. Current state (from audit) — what's already there

Implemented and real (do **not** re-implement):
- CRDTs: `OrSet`, `LwwRegister`, `ReconcileStore` (`federation.rs`).
- PBFT core: `propose`/`receive_prepare`/`receive_commit`, 2f+1 quorum,
  `seal_round`, `governance_execute_tx` (`federation.rs:1578–1794`;
  wrappers `server.rs:11712–11896`).
- Membership crypto: `membership_bootstrap_init`, `membership_process_join`
  (verifies each `EndorsementProof` Ed25519 sig), `membership_endorse`,
  OR-Set merge (`server.rs:11457–11706`).
- BLAKE3 replication: `federation_import_works/editions/blobs` dedups by
  recomputed fingerprint; **tampered blobs rejected**
  (`server.rs:10867–11071`, blob check `11051–11058`).
- Mutual handshake + AEAD framing, **inbound**
  (`federation_handler.rs:178–426`).
- **Every inbound frame handler** (`federation_handler.rs:428–835`).

The gaps (this FR):
- `--peer` is parsed (`xudanu-server.rs:446–452`) but **never dialed**.
- `membership_bootstrap_init()` is **never called at startup** (test-only).
- `federation_register_peer_key` (`server.rs:10794`) is **never called outside
  tests** → `is_peer_known` (`federation.rs:253–264`) **rejects everyone** when
  federation is enabled (self-DoS trap).
- No periodic sync/heartbeat sender (handlers exist, nothing triggers them).
- PBFT proposals **die on the proposer**; Prepare/Commit votes only flow inbound.

## 4. Functional requirements

### FR-3.1 Outbound dialer / connection manager
- On startup (when federation enabled), spawn a task per entry in
  `FederationConfig.peers` that dials `wss://host/federation` (or `ws`), performs
  the existing handshake **as the client side**, and holds the encrypted channel
  in a pool.
- Reconnect with exponential backoff on drop/failure; track per-peer liveness.
- Send frames *to* peers via this pool (used by FR-3.4, FR-3.5, FR-3.6).
- The inbound handler (`federation_handler.rs`) is already symmetric; only the
  initiator + reconnect is new.

### FR-3.2 Startup bootstrap
- When federation is enabled, call `membership_bootstrap_init()` at server start
  so the node has a self-endorsed membership entry (it can act as a founder or a
  peer that others can validate).
- Make the node's own server verifying key discoverable to operators (print/log
  the hex at startup) so founders can register it.

### FR-3.3 Peer-key registration path (fix the reject-all trap)
- Add a way to register trusted peer verifying keys that calls
  `federation_register_peer_key` (`server.rs:10794`):
  - CLI: `--trusted-peer-key <hex>` (repeatable) and/or
    `--trusted-peer-keys <file>`.
  - Config: a `trusted_peers` section in the manifest / a peer-keys file in the
    data dir (persisted, like `key_history.json`).
- Ensure `is_peer_known` (`federation.rs:253–264`) returns `true` for registered
  keys so enabled federation no longer rejects every connection.

### FR-3.4 Periodic sync / heartbeat loop
- On each live outbound channel, periodically send:
  - `Heartbeat` (liveness + dead-peer detection),
  - `SyncPull` / `SyncPush` (content + blobs, BLAKE3-verified on import),
  - `MembershipSyncPush`, `StateSyncPush`, `EndorsementSyncPush` (convergence).
- All inbound handlers already exist (`federation_handler.rs:471–610, 657–674`);
  this is orchestration only.

### FR-3.5 PBFT broadcast (consensus that actually runs)
- When an admin triggers `GovernancePropose` (`dispatch.rs:2546`), the leader
  **broadcasts `GovernancePrePrepare`** to peers over the outbound pool.
- Replicas **relay `Prepare`/`Commit` votes to each other** (today votes are
  inbound-only, `federation_handler.rs:688–752`); on seal, broadcast `Sealed`.
- (v1 happy path; view-change/timers deferred — see §10.)

### FR-3.6 Donated-host join (trust model)
- A joining (donated) node that is **not yet a member** sends
  `MembershipJoinRequest` (with its collected `EndorsementProof`s) to a founder
  peer over the outbound channel; the founder returns an offered endorsement.
- Inbound side already works (`federation_handler.rs:611–643`); add the
  **outbound initiator** (see §5).

## 5. Donated-host trust model

A donated machine is one a user contributes to run a peer node. It must prove
its identity and be vouched for before it can participate.

- **Identity = the server's Ed25519 keypair** (already in `data/server.key`).
  The donated host's verifying key is its durable identity.
- **Trust = web-of-trust endorsements** (phase-19a, already implemented):
  - A **founder** bootstraps (self-endorse) and is the initial member.
  - A donated host obtains ≥1 `EndorsementProof` from an existing member
    (out-of-band contact / invite token), then sends `MembershipJoinRequest`.
  - Existing members endorse (Ed25519-signed); the membership OR-Set converges
    via `MembershipSyncPush`.
- **Operational bootstrap for a donated host** (the new wiring):
  1. Donor runs `xudanu-server`, notes its server verifying key (printed at
     startup).
  2. Founder registers the donor's key (`--trusted-peer-key`, FR-3.3) — this
     lets the donor's inbound/outbound socket pass `is_peer_known`.
  3. Donor started with `--peer <founder>` dials the founder (FR-3.1), sends
     `MembershipJoinRequest` (FR-3.6), receives an endorsement, and converges.
- **Revocation**: members can retract endorsements; PBFT `Expel` tx (already in
  `governance_execute_tx`) for cluster-wide removal.
- **No central authority**: trust is peer-signed; a donated host with no
  endorsements cannot join. Cost stays distributed — each donor bears their own
  machine; no expensive central fleet required.

## 6. Implementation details (backend)

- New module `src/server/federation/active.rs` (or extend `federation.rs`):
  - `PeerPool` — outbound channels keyed by peer id; `send(peer_id, frame)`,
    `broadcast(frame)`.
  - `dial_peer(addr, our_keypair)` — client-side handshake (mirror of
    `federation_handler.rs:178–426`), returning an encrypted framed channel.
  - `spawn_federation_tasks(server, pool)` — heartbeat + periodic sync loops.
- `xudanu-server.rs` startup: if `federation.enabled`, call
  `membership_bootstrap_init()`, load trusted peer keys (CLI/file), spawn the
  dialer per `config.peers`, spawn the sync/heartbeat loops.
- Reuse the existing `FederationFrame` set + inbound handlers verbatim — only
  add senders.
- Persistence: trusted peer keys + membership state already CRDT-mergeable;
  store the trusted-key allow-list in the manifest snapshot (no new datastore,
  same principle as FR-2).

## 7. Security considerations
- Outbound dial must verify the peer's handshake signature against the
  registered verifying key (do **not** trust unverified endpoints).
- mTLS vs. the custom handshake: the custom Ed25519/X25519 + AEAD handshake
  already secures `/federation` at the app layer; standard server TLS uses
  `with_no_client_auth` (`xudanu-server.rs:813`). For v1 rely on the custom
  handshake + the key allow-list; document that peer identity trust rests on the
  registered Ed25519 keys.
- Donated hosts: a compromised donor can be `Expel`-ed via PBFT; endorsements
  are signed and auditable.
- BLAKE3 verification on import already prevents tampered/corrupt chunks from
  propagating.

## 8. Operational concerns (donated machines / cost)
- **Reachability**: no NAT traversal in v1 — a donated host must be directly
  reachable (public IP / port-forward) or the donor fronts it (relay/VPN).
  Document this; consider a relay mode later.
- **Discovery**: static `--peer` seed list for v1. Adding a 3rd donor means
  editing peers; acceptable initially.
- **Cost**: each donor runs one `xudanu-server` on their own machine — no
  central fleet. A donor's resource cost is one server process + its data dir.
- **Liveness**: heartbeat-based dead-peer detection drives reconnect; no
  manual babysitting.

## 9. Acceptance criteria
1. Two servers started with mutual `--peer` + cross-registered keys **connect
   and hold** an encrypted channel (real handshake, not fake keys).
2. A content edit on machine A replicates to machine B (BLAKE3-verified) within
   one sync interval.
3. Membership converges: a node endorsed on A appears in B's membership via
   `MembershipSyncPush`.
4. A donated host with a registered key + endorsement **joins** via
   `MembershipJoinRequest` and appears cluster-wide.
5. A PBFT `GovernancePropose` reaches quorum across nodes and seals (happy path).
6. `is_peer_known` no longer rejects everyone when federation is enabled.
7. A **real** two-server integration test replaces the fake-key handshake test
   (`integration.rs:4944`).

## 10. Out of scope / future
- PBFT view-change, leader-failure recovery, checkpointing, log GC.
- Gossip / DNS / seed-based peer discovery; dynamic membership at scale.
- NAT traversal / relay mode for home-donated hosts behind NAT.
- Cross-federation royalty/micropayment settlement.
- Federation health/metrics admin surface beyond `federation_info`.

## 11. Sequencing recommendation
Build in this order (each unblocks the next):
1. **FR-3.3** peer-key registration + **FR-3.2** bootstrap (smallest, fixes the
   reject-all trap so anything can connect at all).
2. **FR-3.1** outbound dialer (the hard blocker — without it nothing is active).
3. **FR-3.4** sync/heartbeat loop (turns connection into convergence).
4. **FR-3.6** donated-host join (the trust/UX path for donors).
5. **FR-3.5** PBFT broadcast (cluster-wide decisions).
6. Real two-server integration test (§9.7) — proves 1–5 end-to-end.
