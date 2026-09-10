# FR-63: Forensic Integrity — Detection, Auditing, and Canary Systems

- **ID:** FR-63
- **Status:** Proposed — design document, phased implementation
- **Depends on:** existing hash chain, Bitcoin anchoring (FR-60),
  append-only chunk store, attribution log, generation counters
- **Related:** FR-62 (anchoring operations), FR-52 (federation,
  the dormant 3-node PBFT network)

---

## 1. The threat model

The deepest attack class is **transient state exploitation**: the
attacker temporarily modifies state, exploits the invalid window,
then reverts. The chain looks clean afterward; the exploit's
effects persist.

```
T1: state is valid (chain = H)
T2: attacker modifies state (chain = H')
T3: exploit runs — forged content, fake attribution,
    redirected transclusion (effects = E)
T4: attacker reverts (chain = H)
T5: chain probe says "OK" — but effects E persist
```

The defense principle: **monotonicity**. In a truly append-only
system, temporary modifications leave permanent traces. The "before"
state AND the "during" state both exist forever. The attack cannot
erase its own footsteps. Xudanu's architecture is already
monotonic in the right places — the gap is that we don't have
the detection mechanisms that read those traces.

---

## 2. Detection mechanisms (priority-ordered by value ÷ effort)

### Tier 1: Passive, existing data, cheap (~4h total)

| # | Mechanism | What it detects | Effort |
|---|---|---|---|
| 1.1 | **Chain probe** (`forensics --chain`) | walk the full attribution chain from genesis, recompute every hash from underlying content; any mismatch = tampering | ~1h |
| 1.2 | **Generation forensics** (`forensics --generations`) | scan all works for generation anomalies (counter incremented but content unchanged = transient modification) | ~1h |
| 1.3 | **Orphan chunk scan** (`forensics --orphans`) | find chunks in the store not referenced by the current chain head — evidence of temporary states | ~1h |
| 1.4 | **Anchor verification** (`forensics --anchors`) | re-verify OTS receipts against Bitcoin headers; chain-head vs receipt mismatch = anchoring inconsistency | ~1h |

**Output:** a forensics report (JSON + human-readable) with a
verdict: CLEAN / ANOMALIES FOUND (with details).

### Tier 2: Canary systems, active verification (~1 day)

| # | Mechanism | What it detects | Effort |
|---|---|---|---|
| 2.1 | **Canary works** | auto-created works with known content; periodic re-verification; hash mismatch = unauthorized modification | ~3h |
| 2.2 | **Canary bindings** | a honey key→identity binding that should never change; any change = CA forgery | ~2h |
| 2.3 | **Honey transclusions** | a transclusion to a work that shouldn't change; `source_changed` = source tampering | ~1h |
| 2.4 | **Periodic integrity sweep** | background task running 1.1–1.3 on a schedule; surfaced in `/health` as `integrity: ok/anomalous` | ~2h |

**Canary design principle:** canaries are indistinguishable from
real entries. Same structure, same provenance path, same storage.
The only difference is the system knows their expected hash and
checks it on a schedule.

**Canary danger (acknowledged):** if canaries are discoverable,
they can be targeted to generate noise. Mitigation: indistinguishable
from real content; verification uses the same code path as `verify`;
creation events are in the anchored chain.

### Tier 3: Binding audit, identity forensics (~1 day)

| # | Mechanism | What it detects | Effort |
|---|---|---|---|
| 3.1 | **Binding audit** | walk the attribution log; detect temporary key→identity changes (binding changed at T2, reverted at T4; content signed between T2 and T4 is suspect) | ~4h |
| 3.2 | **Provenance cross-check** | for each signed span, verify the key binding was valid at the provenance timestamp | ~4h |

### Tier 4: Public binding transparency (~2 days)

| # | Mechanism | What it does | Effort |
|---|---|---|---|
| 4.1 | **Binding publication** | periodically publish the club registry (key→identity map) to a public log (Bitcoin-anchored) | ~1d |
| 4.2 | **Receipt verification** | anyone can compare the current binding against the published receipt; mismatch = CA forgery detected | ~1d |

**This is Certificate Transparency for content provenance.**
If the server changes Alice's binding, the old public receipt
contradicts the new one.

### Tier 5: Client-side signing (the barrier fix, ~1 week)

| # | Mechanism | What it does | Effort |
|---|---|---|---|
| 5.1 | **Client-held keys** | Alice's private key never touches the server; she signs on her device; server only sees the signature | ~1w |
| 5.2 | **Key receipt export** | Alice exports her public key fingerprint to somewhere the server doesn't control | ~1d |

This is the strongest fix but requires client-side key management
UX that doesn't exist yet. Long-term answer; not near-term.

---

## 3. Connection to federation / BFT

The dormant 3-node PBFT network (FR-3, demo-network.sh) is the
**structural defense** against the server-as-CA problem: if Alice's
identity is confirmed by N independent servers, a forgery requires
compromising all N. This is the Byzantine-fault-tolerance answer.

Current state:
- The demo network worked at the time (3 nodes, Docker, PBFT
  broadcast, BLAKE3 content replication)
- Months of changes since may have broken compatibility
- Production hardening (gossip relay, incremental sync, >10 node
  scaling) is documented but unbuilt

**Resurrection path** (when organizational interest justifies it):
1. Re-run demo-network.sh; fix breakage
2. Add binding transparency to the PBFT broadcast (every identity
   binding change is broadcast + agreed)
3. Cross-server anchor verification (server A verifies server B's
   Bitcoin anchoring receipts)

This is a direction, not a commitment. The Tier 1–3 mechanisms
above are achievable solo and provide meaningful detection without
federation.

---

## 4. `/health` integration

All forensic checks surface in `/health`:

```json
{
  "integrity": {
    "last_sweep": "2026-09-10T03:00:00Z",
    "chain": "ok",
    "orphans": 0,
    "generation_anomalies": 0,
    "canaries": { "total": 3, "verified": 3, "tampered": 0 },
    "binding_audit": "ok",
    "anchors": { "verified": 2, "pending": 0, "failed": 0 }
  }
}
```

Alerting guidance: `chain != "ok"` → immediate investigation;
`canaries.tampered > 0` → the monitoring itself detected intrusion;
`orphans > 0` → transient state detected, walk the orphan chunks
for evidence.

---

## 5. Implementation priority

| Phase | Items | Total effort | What it buys |
|---|---|---|---|
| **1** | 1.1–1.4 (passive forensics) | ~4h | `xudanu-server forensics <dir>` subcommand; detects tampering from existing data |
| **2** | 2.1–2.4 (canaries) | ~1d | active verification; `/health` integrity section |
| **3** | 3.1–3.2 (binding audit) | ~1d | identity forensics; transient binding attack detection |
| **4** | 4.1–4.2 (public transparency) | ~2d | Certificate Transparency analogue; external verifiability |
| **5** | 5.1–5.2 (client-side keys) | ~1w | the barrier fix; strongest possible |

Phases 1–2 are achievable now and provide the "is the system
compromised?" answer. Phases 3–4 provide "who forged what?"
Phase 5 removes the server-as-CA entirely.

---

## 6. Non-goals

- Not real-time intrusion *prevention* (this is detection + audit)
- Not replacing the hash chain / anchoring (this reads them)
- Not requiring federation (solo-sufficient through Phase 4)
- Not a security audit tool for other systems (Xudanu-specific)
