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

## 6. Walkthrough: what "anchoring the chain head" means

Every provenance event appends one line to the attribution log:

```
{"seq":1,"ts":1788797990,"author":"d8fa8397…","span_fp":"9f71f7ea…",
 "sig":"a1b2c3…","server":"d8fa8397…","work":1030,"rev":2}
```

Each line gets a chain hash — H(n) = SHA256(H(n-1 ‖ entry(n))) — and
HEAD is the latest hash:

```
seed ──► entry1 ──► H1 ──► entry2 ──► H2 ──► … ──► HEAD
```

HEAD transitively commits to every entry ever appended: edit,
reorder, or delete ANY entry and every subsequent hash changes,
including HEAD.

**What FR-60 does:** submits those 32 bytes to a calendar, which
merkle-batches thousands of unrelated timestamps into ONE Bitcoin
transaction. The receipt proves: this exact HEAD existed before
block N. The composition then covers everything:

```
Bitcoin block N
  proves HEAD existed by then
    HEAD proves the entire chain (every entry, every link)
      every entry carries author key + signature over content
        fingerprints + work + revision + timestamp
```

So every document's every signed revision — unbounded documents,
bounded anchor: always 32 bytes.

**Later verification, without the server:**

1. recompute every hash link from the log + genesis seed — does it
   land on the anchored HEAD? (tamper check on the log you hold)
2. verify the .ots receipt against Bitcoin block headers (PoW, not
   server trust)
3. verify individual entries' Ed25519 signatures against authors'
   public keys

**Honest edges:** Bitcoin gives "~block N, ±10 min" — second-level
timestamps inside entries remain server-clock, bounded from below,
not refined. Anchors commit to the log, not document text directly —
content binding rides the fingerprints and signatures inside entries.
A wiped server starts a fresh chain (new genesis); old receipts
verify old logs forever.

**Network behavior, precisely:** the server NEVER talks to a
Bitcoin node. It makes one plain HTTPS POST of 32 bytes to a
calendar server (two by default, independent operators). Cadence:
the 60s interval and post-checkpoint hooks run a round; a round does
network work only when the head changed (one submit) or a receipt
needs its upgrade fetch (until confirmed, ~1–2 blocks). Confirmed
and unchanged = silent. Steady state with edits ≈ one POST per edit
epoch; idle = zero traffic.

## 7. Deployment anchor policy (decided 2026-09-07)

Every serious deployment makes ONE deliberate anchor choice rather
than drifting into none. Client production environments: **TSA
first, Bitcoin beside** — two receipts for the same chain head from
different trust domains.

| Deployment | Anchor | Rationale |
|---|---|---|
| xudanu.com, engagement servers | OTS (`--ots-anchor`) | public claims, free floor, zero privacy cost |
| **Client production** | **their TSA (S5) primary + OTS beside** | stays in their trust domain; eIDAS legal presumption; openssl-verifiable by their team; Bitcoin adds the trust-minimized corroboration |
| Throwaway sandboxes | optional | history not worth proving; wipe kills the chain |
| Air-gapped / no-outbound-ever | none, or internal TSA | the single-player default is a promise — keep it |

Client-prod shape when S5 lands: `--tsa-url https://their-tsa…`
beside `--ots-anchor`; both receipts stored under `anchoring/`;
reports state both ("eIDAS-qualified timestamp says WHEN; Bitcoin
says EXISTED-BY"). The institution vouches the clock, proof-of-work
vouches existence — neither trusts the other, both cover the head.

S5 builds only when a client names their TSA (FR-61 discipline).

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
