# FR-5: Attestation Reports & Provenance

- **ID:** FR-5
- **Status:** In Progress (Phase 1 complete)
- **Date:** 2026-07-01
- **Owner:** backend + frontend
- **Depends on:** Attribution system (phases 12–13), CRDT collaborative editing, O-tree provenance.

## 1. Overview

Provenance and attestation are Xudanu's answer to a fundamental question: **who wrote what, when, and can we prove it?** This FR covers two complementary capabilities:

- **Provenance** (interactive): Real-time visibility into document authorship, transclusion ancestry, and chain integrity — for monitoring and trust.
- **Attestation** (exportable): A cryptographically signed, standalone document that freezes the attribution state at a point in time — for legal evidence, regulatory compliance, and IP disputes.

The provenance system is the **live view** (what's happening now). The attestation report is the **frozen snapshot** (what happened, provably, at this moment).

## 2. Goals / Non-goals

**Goals**
- Users can see who wrote what, with signature status, at any time (provenance panel).
- Users can export a signed attestation report that can be independently verified offline.
- The report honestly documents its trust level (1–4) — what it can and cannot prove.
- Reports from multiple federation peers can be cross-verified (multi-party witnessing).

**Non-goals (for v1)**
- RFC 3161 external timestamping (trusted Timestamping Authority) — Phase 4, future.
- Threshold signatures (server key split across parties) — Phase 5, future.
- Blockchain-based audit log replication — future.

## 3. Current state

### Provenance Panel (DONE)
- Left rail "Provenance" icon opens a bottom split panel with full `AttributionPanel`.
- Compact `AttributionSection` in the right panel: collapsible, green/amber/red status.
- Shows: coverage %, chain validity, derivation chains, authors list, timeline.
- `refreshAttribution` loads for all users (including anonymous).
- Materialization forced before attribution queries so typed text is attributed.

### Attestation Report — Phase 1: Backend Generation (DONE)
- New wire op `AttestationReport` (0x0D0B).
- Server method `generate_attestation_report(work_id, session_id)`:
  - Forces CRDT materialization (ensures latest text is attributed).
  - Collects: document metadata, all attribution spans, provenance chain, security log status, key history, server identity.
  - Computes SHA-256 of report body.
  - Signs hash with server's Ed25519 key.
- Returns signed JSON document.

### Attestation Report — Phase 2: Frontend Export (NOT DONE)
- No UI button to trigger report generation.
- No download/display of the report.

### Attestation Report — Phase 3: Independent Verifier (NOT DONE)
- No CLI tool to verify a report offline.

## 4. Provenance vs Attestation

| | **Provenance Panel** | **Attestation Report** |
|---|---|---|
| **Purpose** | Monitor — "is everything OK right now?" | Prove — "show this to someone else" |
| **Format** | Live, interactive, in-browser | Exportable signed JSON document |
| **Audience** | The document's users | Courts, regulators, auditors, IP disputes |
| **Frozen in time** | No — updates as you edit | Yes — snapshot with timestamp, server-signed |
| **Verifiable** | Only while connected to the server | Independently — offline with just the report file |
| **Server signature** | No | Yes — Ed25519 over SHA-256 of report body |
| **Trust levels** | Implicit | Explicit (Level 1–4 documented honestly) |

## 5. Report Structure

The attestation report is a JSON document with two top-level objects:

```json
{
  "report": {
    "type": "xudanu-attestation-report",
    "version": 1,
    "generated_at": 1719840000,
    "document": {
      "work_id": "03f6",
      "title": "Xanalogical Structure, Needed Now More Than Ever",
      "revision": 42,
      "character_count": 9884,
      "content_hash_blake3": "7f3a..."
    },
    "server_identity": {
      "server_id": "16522a722cab6b18",
      "verifying_key_ed25519": "efdf23c4..."
    },
    "attribution": {
      "span_count": 43,
      "spans": [
        {
          "range": [0, 305],
          "author": "david@dgjones.info",
          "author_type": "human",
          "signature_valid": true,
          "timestamp": 1719836400,
          "source_work_id": "03f5",
          "provenance_chain": [...]
        }
      ]
    },
    "provenance_chain": [
      {
        "source_work_id": "03f5",
        "source_work_title": "david@dgjones.info",
        "source_author_name": "david@dgjones.info",
        "dest_work_id": "03f6"
      }
    ],
    "security_log": {
      "has_log": true,
      "entry_count": 141,
      "last_sequence": 141,
      "chain_valid": true,
      "algorithm": "SHA-256 chained, Ed25519 signed, BLAKE3 content-addressed"
    },
    "key_history": {
      "server_id": "16522a722cab6b18",
      "current_key_id": 1,
      "entry_count": 1,
      "rotation_proof_count": 0
    }
  },
  "report_hash_sha256": "a1b2c3...",
  "server_signature_ed25519": "9a8b..."
}
```

## 6. Trust Level Framework

The report documents its own trust level — honestly stating what guarantees it can and cannot make.

### Level 1: Basic (Current System)
- Ed25519 per-span signatures (author non-repudiation)
- BLAKE3 content-addressed storage (integrity)
- Chained security log (tamper-evident)
- **Limitation**: Server admin has full disk access; timestamps from server clock.

### Level 2: Hardened (Secure Data Centre)
- Physical security, key encrypted at rest
- NTP-synced clock
- OS-level audit logs

### Level 3: Legally Verified (RFC 3161) — Future
- External timestamping by trusted TSA
- HSM key storage (key never on disk)
- Reproducible builds

### Level 4: Maximum Evidence (Federation Witnessing) — Future
- Multiple servers independently witness each revision
- Threshold signatures (no single party can forge)
- External audit log replication

## 7. Federation Witnessing

In a federated cluster, each peer has its own Ed25519 key. A document replicated across N peers can have N independent attestation reports:

- Peer A report → signed by Peer A's key
- Peer B report → signed by Peer B's key
- Peer C report → signed by Peer C's key

All reports should contain the **same attribution data** (CRDT convergence), but with **different server signatures**. A court or auditor can:
1. Request reports from all peers
2. Verify each signature independently
3. Cross-check that the attribution data matches across all reports
4. If any report differs → tampering detected on that peer

This is the foundation of trust level 4.

## 8. Implementation Phases

### Phase 1: Backend Report Generation — DONE
- `generate_attestation_report(work_id, session_id)` server method
- `AttestationReport` wire op (0x0D0B)
- Forces CRDT materialization before generating
- Server signs SHA-256 of report body with Ed25519

### Phase 2: Frontend Export — TODO
- "Export Attestation Report" button in AttributionPanel and compact AttributionSection
- Triggers `attestation_report` wire op
- Downloads JSON file (`work-{id}-attestation-{timestamp}.json`)
- Formatted HTML preview view (print-friendly for court exhibits)

### Phase 3: Independent Verifier CLI — TODO
- `xudanu-cli verify-report <report.json>`
- Verifies all Ed25519 signatures against author public keys
- Verifies server attestation signature against server public key
- Validates report hash matches content
- Reports trust level achieved

### Phase 4: RFC 3161 External Timestamping — Future
- Integrate with RFC 3161 compliant TSA
- Request externally-signed timestamp for each revision
- Include TSA timestamp in attestation report

### Phase 5: Federation Witnessing — Future
- Multiple servers independently witness each revision
- Threshold signature scheme for server attestation
- External audit log replication (WORM or blockchain)

## 9. Acceptance Criteria

1. User can click "Export Attestation Report" and download a signed JSON file.
2. The report contains all attribution spans with signature validity.
3. The report contains the full provenance chain (transclusion ancestry).
4. The report contains security log status (chain valid/invalid).
5. The report is signed by the server's Ed25519 key.
6. `xudanu-cli verify-report` can independently verify all signatures offline.
7. Reports from multiple federation peers contain the same attribution data (cross-verifiable).

## 10. Verification Process (Phase 3)

```
xudanu-cli verify-report work-03f6-attestation-1719840000.json

  Document: Work 03f6, revision 42
  Title: "Xanalogical Structure, Needed Now More Than Ever"
  BLAKE3 hash: 7f3a... ✓

  Attribution (43 spans, 2 authors, 100% coverage):
    [0..305]   david@dgjones.info  ✅ ed25519 valid
    [305..510] alice@example.com   ✅ ed25519 valid
    ...

  Provenance chain:
    david@dgjones.info → This document ✓

  Security log:
    141 entries, chain valid ✓

  Server attestation:
    Server 16522a722cab6b18
    Report hash: a1b2c3... ✓
    Ed25519 signature: valid ✓

  Trust level: 1 (Basic)
  Result: ALL CHECKS PASSED
```

## 11. Related

- **Issue #57** — original attestation report issue.
- **Issue #60** — FR-4 typed content links (provenance chains flow through links).
- **Issue #35** — concurrent editing (CRDT sync enables real-time attribution).
- `docs/dev/FR-2.md` — account verification (verified accounts strengthen attribution).
- `docs/dev/phase-12-modern-encryption.md` — crypto foundations (Ed25519, BLAKE3, AEAD).
