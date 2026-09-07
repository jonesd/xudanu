# FR-60: External Timestamp Anchoring (OpenTimestamps)

- **ID:** FR-60
- **Status:** Implemented (S1-S3) — live-verified 2026-09-07
- **Depends on:** the chained attribution log (existing); nothing else
- **Closes:** the weakest claim in
  `docs/dev/provenance-flow-and-claims.md` — "timestamps are
  server-asserted"

## 1. Why

Every Xudanu timestamp is inside an Ed25519 signature, but the clock
is the server's: a compromised server could backdate attribution by
signing with a false clock. Anchoring the attribution log's hash
chain to Bitcoin via OpenTimestamps gives a trust-minimized floor:
the entire attribution history up to the anchored chain head
provably existed before a specific Bitcoin block. Backdating past an
anchor becomes impossible without breaking the chain (detectable)
or reorganizing Bitcoin (out of scope for any adversary this system
worries about).

Claim upgrade, precisely worded:

- Before: "timestamps are server-signed" (trust the server's clock)
- After: "attribution history provably existed by block N; the
  signature supplies second-precision, the anchor supplies the
  trust-minimized existence floor"

Privacy: only the 32-byte BLAKE3 chain-head hash leaves the server.
No content, no metadata beyond the hash.

## 2. Mechanism

1. After each checkpoint (and on admin demand), take the current
   attribution-log chain head digest
2. Submit to OpenTimestamps calendars (two public calendars by
   default; overridable) — the OTS aggregation means the Bitcoin
   transaction is shared by thousands of unrelated timestamps
3. Persist the returned pending receipt (`receipt.ots`) plus the
   anchored head + submission metadata
4. On later checkpoints, re-fetch the receipt from the calendars —
   once the Bitcoin transaction confirms, the receipt upgrades to a
   full Bitcoin block attestation
5. `xudanu-server verify` reports anchoring state: pending /
   confirmed (block height + timestamp) / absent

Verification of the receipt itself is intentionally OUT of the
server: it is externally verifiable by anyone with the standard
`ots` tool and a Bitcoin node (or block headers). The server stores
and upgrades receipts; the world verifies them.

## 3. Trust and liveness notes

- Calendars are trusted only for LIVENESS, not honesty — a lying
  calendar produces an invalid receipt, detectable on external
  verification. Two calendars submit in parallel for redundancy.
- Anchoring is best-effort: offline servers skip silently (logged)
  and anchor at the next opportunity. A missed anchor weakens the
  floor to the previous one — never below the last confirmed one.
- Default OFF (single-player default: no outbound connections);
  enabled by `--ots-anchor` run flag or the admin wire op, per the
  project's outbound-connection stance.

## 4. Stories

| # | Story | Armor |
|---|---|---|
| S1 | OtsAnchorer: submit / fetch-upgrade / parse receipt status, injectable transport | unit tests with fixture receipts (pending + confirmed) |
| S2 | Server integration: chain-head extraction, receipt persistence, checkpoint hook, run flag + admin ops (0x035B status, 0x035C anchor-now) | offline tests with stub transport; live smoke vs real calendars |
| S3 | `verify` subcommand: anchoring section | manual |

## 5. Acceptance criteria

- With anchoring enabled, one checkpoint + calendar round-trip
  produces a stored receipt for the exact current chain head
- Receipt status transitions pending → confirmed as calendars
  upgrade it; the stored receipt always reflects the best fetch
- The receipt verifies with the external `ots` tool (manually
  confirmed once, live)
- Anchoring disabled (default): zero outbound attempts, zero
  behavior change
- Only 32 bytes of hash ever leave the server
