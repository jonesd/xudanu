# FR-46: Server Reputation & Cross-Server Verification

Status: stub (design record — not scheduled) · Date: 2026-08-26
Builds on: FR-45 P5 (Network tab: first-party counters, probes, trust
tiers), the FR-6 cross-server fetch path (BLAKE3 per-fetch
verification), federation signed channels (Ed25519 pinned keys),
offline trust discussion 2026-08-26.

## Why

P5 gives the admin first-party evidence: our verified-fetch counters,
failure streaks, signature failures, and the remote's *claimed* health
on demand. But one observer's history is thin, and "trust-but-verify"
starves without more evidence. The question this FR answers: how does
an operator accumulate enough evidence about other servers to make
sound trust decisions — without inventing a surveillance system, a
global reputation market, or an infinite regress of trusting the
trusters?

## What is knowable (the epistemics, stated up front)

| Class | Knowable? | Mechanism |
|---|---|---|
| Bytes we received match the sender's signed claim | provably | BLAKE3 per-fetch verify (shipped) |
| Identity continuity (same entity as yesterday) | provably | pinned Ed25519 keys (shipped) |
| Real uptime/latency/reliability | statistically | sampled over time by multiple observers |
| Content consistency (same bytes to all peers) | statistically | equivocation sampling (same hash from multiple vantages) |
| What a server hides from everyone | never | only per-fetch verification covers consumed content |

"Real-life truth" about a server is **assembled, never received**: our
measurements + cross-checked gossip + attestations → a locally computed
view that is *ours*, not a global one.

## Layers (build order)

1. **First-party counters** — SHIPPED (P5). Free, unfakeable by
   others, about our interactions only.
2. **Signed observation exchange** — servers publish signed
   observations of peers they interact with: resolved-fetch counts,
   hash mismatches, latency samples, signature failures. One more
   message type on the existing federation channel. Witnesses are not
   *trusted*; their statements are *cross-checked*: dishonest
   witnesses diverge from other witnesses and drop out of the
   evidence pool. Converges for the same reason PGP webs of trust do:
   evidence is cheaper to cross-verify than to consistently fake.
3. **Detached attestations** — third parties sign statements about
   content hashes and behavior periods. Because hash-based, they
   survive modified servers: content we fetch is provably what was
   attested even if the serving server lies about everything else.
   (Content categories are deferred — moderation is FR-45's job.)

## Scoring principles (when layer 2+ exist)

- Scores are **local arithmetic over visible evidence** — weighted
  aggregation of first-party counts + cross-checked observations.
  Never a black-box number; the Network tab shows the inputs.
- **No global reputation.** Shared leaderboards are attack surfaces
  and popularity contests. Each server computes its own view.
- **Auto-trust from scores is forbidden.** Trust stays an explicit
  admin decision (directory entry → trusted pin). Tools inform the
  switch; tools never flip it. Same deliberate-opt-in posture as the
  network toggle itself.
- **Longency weighs in**: entry age in the directory accrues;
  malicious servers are usually young (cheap to burn, cheap to
  re-spawn). Cheap to display (P5 already shows known-since).

## Non-goals

- Global/shared reputation state, any "trust score everyone uses."
- Anonymous/unaccountable witnesses — observations are signed or they
  don't enter the pool.
- Automated trust decisions, auto-quarantine by threshold (alerts
  yes; actions stay human).
- Proof-of-storage / validity blockchains — Xudanu's security needs
  don't reach there; per-fetch hashing covers consumed content.

## The regress, answered once

"To verify servers I need other servers, whom I must also trust…" —
stops because (1) evidence ≠ trust: witnesses are corusable without
being trusted, and liars are detectable by cross-witness divergence;
(2) anchors are cryptographic: identity verifiability doesn't decay
with hop distance; (3) the realistic network is small-world (dozens of
servers) where plain weighted aggregation over signed observations is
cheap and manipulation-resistant long before clever math is needed.

## Companion

FR-47 (adversarial scenarios) is this FR's red-team harness: the
personas there define "correctly interpreted" for every signal the
layers above produce. Build FR-47 Tier 1 before FR-46 layer 2.

## Open questions (for the real design pass)

- Observation exchange cadence and message size budgets on the
  federation channel.
- Witness weighting: purely own-experience, or decay-by-hop?
- Equivocation sampling: what fraction of shared content, how often,
  is statistically sufficient without becoming a re-download tax?
- Attestation key discovery for detached auditors (web-of-trust entry
  points).
