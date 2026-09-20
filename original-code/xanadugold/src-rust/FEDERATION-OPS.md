# Federation Operations Guide

Operational documentation for running xudanu federation clusters:
start/stop, monitoring, recovery playbooks, debugging, and
coexistence with single-server deployments.

For the protocol design see `MULTI_SERVER_FEDERATION.md` and
`docs/dev/phase-19b-governance-bft.md` (PBFT) and
`docs/dev/FR-75-validator-key-epochs.md` (key lifecycle).

## Quick start

```bash
./scripts/federation.sh start              # 4 nodes (BFT minimum) on 8081-8084
./scripts/federation.sh status             # per-node health + validator lifecycle
./scripts/federation.sh diagnose           # health + consistency + log-pattern scan
./scripts/federation.sh logs 1             # tail node 1's log
./scripts/federation.sh stop               # graceful stop (checkpoints first)
```

Custom size/data dir:

```bash
./scripts/federation.sh start 5 /data/fed   # 5 nodes (recommended: f=1 + 1 crash)
```

**Why 4+?** Byzantine fault tolerance needs 3f+1 nodes. The
governance plane refuses to open consensus rounds with fewer than 4
validators — a 3-node cluster replicates content fine but makes no
BFT governance decisions. 5 is the recommended default: tolerates
one byzantine node **and** one additional crash for liveness.

## What startup does

1. `init` any node dir lacking `key_history.json` (generates the
   node's Ed25519 identity)
2. Extracts every node's verifying key, generates per-node offline
   **recovery keys** (`node-N-recovery.hex` — guard these), and
   writes `pinned-members.json`
3. Starts every server with `--peer <all others>` and
   `--pin-members <file>`

Genesis pinning makes peer admission strict (no
trust-on-first-use) and seeds the same validator set on every node,
so PBFT governance is unified from sequence 1.

### State on disk

```
$DATA_BASE/
  node-N/                  # server data (chunks, manifests, WAL)
  node-N-recovery.hex      # operator recovery key (FR-75 §4)
  pinned-members.json      # genesis validator set
  logs/node-N.log          # console log (tee'd)
  federation.pids          # PID file (managed by start/stop)
  node-N/security.log.DATE # per-node structured security/audit log
```

## Coexistence: federation and a single server

**Not exclusive.** A federation cluster is just N independent
xudanu servers. They run happily alongside a single-player/dev
server — the common setup:

```
dev server    127.0.0.1:8080   data:  src-rust/data
fed node 1    127.0.0.1:8081   data:  /tmp/xudanu-federation/node-1
fed node 2    127.0.0.1:8082   ...
```

Only two things must differ between any two running servers: the
**port** and the **data directory**. Everything else (identity,
peers, pinning) is per-data-dir state.

## Functional fault-injection suite

```bash
./scripts/federation-fault-tests.sh        # ports 9081+, own temp data dir
```

Spins up a fresh genesis-pinned 4-node cluster and injects the
failure modes the protocol is designed to handle, asserting
detection + recovery after each:

1. **Graceful stop/restart** — SIGTERM + checkpoint; survivors
   healthy during downtime; node returns, lifecycle unified
2. **Hard crash/restart** — SIGKILL; data durable across the crash;
   node recovers, lifecycle unified
3. **Freeze/thaw** — SIGSTOP (hung node): survivors stay healthy;
   on SIGCONT the mesh either rides through (connections persist
   through a sub-heartbeat freeze) or rebuilds via the dialer
4. **Rolling restart** — every node recycled one at a time; quorum
   maintained throughout

After every recovery the suite asserts the invariant that matters
most: `/health` ok on all nodes AND `governance_lifecycle`
identical everywhere (`v=4 p=4 q=3 m=1`) — a diverged lifecycle
would mean a forked validator set. Self-cleaning; safe to run
repeatedly; suitable as a CI gate.

## Monitoring

`GET /health` on each node. The `governance_lifecycle` section is
the operational canary:

```json
"governance_lifecycle": {
  "validators": 4,          // governance-admitted members (n)
  "pool": 4,                // epoch-valid voters right now
  "quorum": 3,              // 2f+1
  "margin": 1,              // pool − quorum = fault-tolerance headroom
  "expired_members": [],    // who needs key renewal
  "expiring_soon": [],      // keys expiring within 1000 sequences
  "grace_keys": 0,          // retired keys still in view-change grace
  "next_sequence": 1
}
```

| margin | meaning | action |
|--------|---------|--------|
| ≥1 | healthy | none |
| 0 | zero fault tolerance (n=4 + 1 expiry) | renew keys NOW |
| <0 | governance halted (safe, not live) | renew/expel to restore pool |

`federation.sh diagnose` automates these checks plus log scanning.

## Recovery playbooks

### A node crashed / was restarted

Just restart it (same data dir). On reconnect it:
- resumes CRDT content sync automatically,
- catches up governance history via state transfer
  (`GovernanceLogRequest` — certificate-verified tail ingest).

No operator action beyond restart. If it was down longer than the
retention window (64 sealed batches) it logs
`state transfer gap: peer history starts beyond our position` —
see "Too far behind" below.

### A leader is stalled or dead (rounds not sealing)

View change is automatic: after a 10s round timeout, replicas emit
signed VIEW-CHANGE messages; the next leader assembles NEW-VIEW and
governance resumes in view+1. **Client caveat:** a request whose
round never reached prepare-quorum is discarded — the client retries
with the new leader (unprepared requests are lost, not carried).

Watch for: `view-change quorum` in logs (diagnose warns on it).

### A validator key expired (margin dropped)

The expired member's votes stop counting; the pool shrinks. Restore
by rotating the key (renews the epoch) via a governance `KeyRegister`:

- **Operator path:** the member's current key AND the offline
  recovery key (`node-N-recovery.hex`) both sign the rotation.
- **Social path:** a quorum of OTHER members signs it.

Until renewed, margin stays degraded (see table above).

### "Too far behind" (pruned-past gap)

A node down past the retention window can verify new batches but
misses pruned history. Governance keeps working (the log tail is
what consensus needs), but for full audit history the node must
rejoin from a snapshot: stop it, restore a data-dir backup taken
from a current member, restart.

### Peer connections rejected ("not in trusted peers list")

Admission is strict under pinning. Causes:
- the peer's key isn't in `pinned-members.json` (new node added
  without updating the pin file — restart all with the updated file), or
- `--peer` flags and `--pin-members` disagree.

### Disk full

Checkpoints fail; servers keep serving from memory but risk data
loss on crash. `diagnose` fails below 1GB free. Free space, restart.

## Debugging

**Where the logs are:** `$DATA_BASE/logs/node-N.log` (console,
tee'd) and `$DATA_BASE/node-N/security.log.DATE` (structured audit:
auth, denials, view changes, connection caps).

**Common log lines:**

| Line | Meaning |
|------|---------|
| `Federation: encrypted handshake completed with server <id>` | mesh healthy |
| `membership sync: validator-key change refused` | benign — the CRDT guard sanitizing redundant join/sync traffic (pinned members already known) |
| `Membership join rejected ... already a member` | benign — pinned peers re-introduce themselves |
| `Federation: failed to connect ... not in trusted peers list` | wiring/pinning mismatch (see playbook) |
| `governance at ZERO fault-tolerance margin` | renew keys |
| `Governance: sealed batch seq=N` | consensus working |
| `Governance: view-change quorum` | a leader stalled and was replaced |
| `federation connection refused: per-IP connection cap exceeded` | DOS cap tripped (>8 sockets from one IP) |

**Manual probing:**

```bash
curl -s localhost:8081/health | python3 -m json.tool | grep -A9 governance
node scripts/ws-call.mjs "ws://localhost:8081/xudanu?format=json&version=2" \
     "governance_status" '{}'       # view/sequence/leader/lifecycle (login required)
```

**Stopping a node for maintenance:** prefer
`federation.sh stop` (SIGTERM → graceful checkpoint). Killing -9 is
safe (WAL + chunk store recover) but loses the final checkpoint.

## Production notes (beyond the demo script)

- The demo uses deterministic recovery keys for convenience. Real
  deployments: generate per-operator keys OFFLINE, register them in
  the pin file, never store them on the servers.
- Set an admin passphrase per node. **Never put it on the CLI** —
  arguments are visible in `ps`, shell history, and `docker inspect`.
  Use the environment variable:
  `XUDANU_ADMIN_PASSPHRASE=... xudanu-server run ...`
  (in compose: an `environment:` entry from a `.env` file you don't
  commit). Or omit it entirely on nodes that never need local admin —
  no passphrase, no admin login path, nothing to leak.
  A `--admin-passphrase-file` form is planned for the strongest
  posture.
- Federation sockets: per-IP cap (8) is enforced; put an upstream
  proxy/firewall in front for untrusted networks.
- Docker: `docker/docker-compose.yml` is the 4-node equivalent
  (peer-wired). Pinning in Docker is two-phase: first `up` to init
  volumes, then extract each node's `key_history.json`, write the
  pin file into each volume, restart.
