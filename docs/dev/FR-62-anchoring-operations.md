# FR-62: Anchoring Operations — Errors, Options, and Monitoring

- **ID:** FR-62
- **Status:** Proposed — production-hardening of the FR-60 mechanism
  now that xudanu.com runs `--ots-anchor`. Build stories are small
  and can land opportunistically; S1+S2 before any client env.
- **Depends on:** FR-60 (landed), `/health` anchoring status (landed)
- **Renumber note:** the federation feature-gate previously sketched
  as "FR-62" moves to FR-63 (FR-61's sibling line updated).

## 1. Why

FR-60 proved the mechanism live; production turns it from a feature
into an *operation*. Operations need three things the current
implementation only partly has: visible degradation (what failed,
when, how stale), configurable targets (which calendars, what
cadence), and defined behavior at every failure boundary.

## 2. Failure modes and the policy for each

| Failure | Current behavior | FR-62 policy |
|---|---|---|
| One calendar down | other answers; first success wins | unchanged; prefer the calendar that succeeded last (sticky) |
| Both calendars down | round errors, logged, skipped | **backoff** (1m → 2m → … cap 1h); `last_error` + `attempts` in meta so staleness is visible, not silent |
| HTTP 4xx vs timeout | same error path | classify: transient (timeout/5xx) retries; permanent (4xx, DNS) alerts at error level |
| Pending > ~6 blocks (~1h) | keeps fetching each round | escalate to warn + attempt submit to the *other* calendar (independent re-anchor) |
| Clock skew (server vs receipt meta) | unobserved | record both timestamps in meta; large divergence notes itself in status |
| Receipt file corrupt/unparseable | ignored on next round (prev unreadable → treated as new head) | parse-check on load; corrupt ⇒ re-anchor + error log |
| **Chain-head regression** (restore from backup, log truncation) | new head anchored silently | **detect mismatch vs stored receipt digest + sequence drop** ⇒ error log + status flag `chain_regression: true`; old receipts remain valid for the old log |
| Data dir wiped | fresh genesis, fresh anchoring | intentional behavior; document (don't wipe servers whose history matters) |

Policy invariant (from FR-60): best-effort, never blocks serving,
never regresses the last confirmed floor, only 32 bytes ever leave.

## 3. Option surface

| Flag / setting | Default | Meaning |
|---|---|---|
| `--ots-anchor` | off | enable anchoring (unchanged) |
| `--ots-calendars <url,…>` | alice,bob | custom list — self-hosted calendar, more than two, client-preferred endpoints |
| `--ots-interval <secs>` | 60 | round cadence |
| `--ots-mode off\|ots` (reserving `tsa\|both`) | ots | unifies with S5 TSA when it lands; today equivalent to the flag |
| `HTTPS_PROXY` env | unset | reqwest honors it; documented path for egress-controlled client envs |
| air-gap mode (S4 below) | — | no outbound at all: export digest, import receipt, manually |

Wire ops unchanged (`ots_anchor_status/set_enabled/request`); the
status response grows the §4 fields.

## 4. Monitoring contract

`/health` → `anchoring` object grows:

```json
{
  "enabled": true,
  "chain_head": "9f71f7ea…",
  "last_round": { "status": "pending", "bitcoin_height": null,
                  "updated_at": 1788797997 },
  "stale_secs": 341,          // now - updated_at
  "last_error": "",           // most recent round failure, "" if none
  "consecutive_failures": 0,
  "chain_regression": false
}
```

Alerting guidance (documented, not built): stale > 1h with edits
happening ⇒ investigate calendars; `chain_regression: true` ⇒ someone
restored state — reconcile before trusting new anchors;
`consecutive_failures > 10` ⇒ network/egress problem.

## 5. Stories and effort

| # | Story | Effort |
|---|---|---|
| S1 | meta enrichment: last_error, attempts, stale_secs, consecutive_failures in meta.json + health; round backoff | 0.5 d |
| S2 | flags: `--ots-calendars`, `--ots-interval`; sticky-calendar preference; error classification | 0.5 d |
| S3 | chain-regression detection + status flag + error log | 0.5 d |
| S4 | air-gap manual anchoring: `anchor-export` (prints/frames digest) + `anchor-import` (stores receipt) subcommands | 1 d |
| S5 | receipt self-check in `verify` (parse + framing + digest match) | 0.25 d |
| S6 | TSA mode (`--ots-mode tsa\|both`, `--tsa-url`) — FR-60 S5, pulls on first client TSA | 1 d |

Total ≈ 3.75 d; S1+S2 (one day together) are the pre-client-env
minimum.

## 6. Acceptance criteria

- Killing both calendars in a test env produces: backoff behavior,
  visible `last_error`/`consecutive_failures`, recovery on restore,
  and zero impact on serving traffic
- Custom calendar list demonstrably used (self-hosted calendar in a
  docker-compose test)
- Log truncation/backup-restore flips `chain_regression` and errors
- Air-gap flow: export digest on the isolated server, anchor it from
  any networked machine (`ots` CLI), import receipt — server shows
  confirmed without ever connecting out
- `verify` self-checks the receipt it reports on

## 7. Non-goals

- No Bitcoin node, wallet, or chain indexing in xudanu — external
  verification only, forever
- No on-chain data beyond the standard OTS aggregated commitment
- No alerting infrastructure shipped — the contract is the health
  fields; monitoring tools are the operator's choice
