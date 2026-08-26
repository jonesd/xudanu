# FR-47: Adversarial Network Scenarios (Red-Team Harness)

Status: stub (design record — Tier 1 buildable now) · Date: 2026-08-26
Builds on: FR-45 P5 (Network tab signals: counters, probes,
quarantine), FR-46 (reputation layers the harness validates), 3-node
Docker demo cluster + demo-network.sh, two-server integration tests,
adversarial Bloom-filter test (one lie pattern already covered).

## Why

Any observation/reputation code (FR-46) tested only against honest
peers is tested against the case that never bites. Before building
reputation machinery, build the harness that can **stage liars** —
so "correctly interpreted" is defined by tests before the
interpretation logic exists. The scenarios encode the contract:
our signals must move when behavior is bad, clear when behavior
recovers, and never trip on honest-but-unhealthy servers.

## The mock server

A test binary (or feature-gated mode of xudanu-server) with
deterministic misbehavior personas:

```
--personality flaky        # drop N% of requests, deterministic seed
--personality slow         # 2-10s latency, eventually answers
--personality restarter    # resets uptime/ops, SAME identity key
--personality health-liar  # claims 10k works, serves none
--personality equivocator  # different bytes for same tumbler per peer
--personality impersonator # wrong key claiming a known identity
--personality rotator      # presents fresh keys to each peer
```

Real xudanu-server instances run against the mock; tests assert on
**our side's signals** (counters, quarantine, status payloads) —
never on the mock's internals.

## Tiers (escalating)

### Tier 1 — honest-but-unhealthy (build now; mechanical)
1. **Flaky**: consecutive-failure streaks accumulate AND clear on
   recovery — transient downtime must not leave a permanent scar.
2. **Slow**: probe latency reported distinctly from timeouts; slow
   ≠ down.
3. **Restarting**: identity continuity holds across restart (same
   pinned key = same server); claimed ops-reset is plausible, not
   alarming.

### Tier 2 — lying about state
4. **Health-liar**: claimed-vs-verified divergence becomes a
   first-class visible signal (P5 has both numbers; the test proves
   the gap surfaces in admin_network_status).
5. **Equivocator**: two clients fetch the same tumbler, compare
   hashes — mismatch = red flag. This is FR-46's core detection
   mechanism, testable today with the scripted server.

### Tier 3 — identity attacks
6. **Impersonator**: sig-failure counter climbs; quarantine trips at
   threshold; recovery path exists (honest server returns).
7. **Key-rotation-abuser**: fresh keys per peer — detectable only by
   gossip cross-check (two honest observers comparing notes); the
   test stages the minimum viable gossip exchange.

## Assertions contract (what "correct interpretation" means)

| Behavior | Signal must |
|---|---|
| transient failure then recovery | streak counts, then clears |
| persistent failure | streak grows, quarantine trips at threshold |
| slow but serving | latency shown; NOT counted as failure |
| restart with same key | continuity kept; no trust change |
| claims ≠ serves | divergence surfaced, labeled |
| same tumbler, different bytes | hash mismatch recorded, flagged |
| wrong identity key | sig failures climb; auto-quarantine |
| honest server after penance | un-quarantine path (admin action) |

## Non-goals

- No ML/anomaly detection — deterministic personas, deterministic
  assertions.
- Not a load generator (FR-43 robots own load; this owns lies).
- Personas are for tests; never shipped in the release binary
  (feature-gated, debug-only).

## Build order

1. Mock binary + flaky/slow/restarter personas (Tier 1)
2. Scenario tests asserting the Tier-1 contract against live
   xudanu-servers (integration-suite shape: spawn, point, assert,
   teardown)
3. health-liar + equivocator personas (Tier 2) once P5 signals are
   proven stable on Tier 1
4. identity personas (Tier 3) alongside FR-46's gossip layer —
   they test each other
