# FR-61: Provenance Validation Kit — Evidence, Gap, and Effort

- **ID:** FR-61
- **Status:** Proposed — V0 (validation) gates all build stories; nothing
  below is built until the practice-lead signal comes back
- **Depends on:** existing machinery only (see inventory); FR-60 landed
- **Siblings:** FR-62 (federation feature-gate, sketched separately)

## 1. Context

Positioning (agreed): Xudanu is not a product — it is a capability in
the toolbox of a ~300-person services firm. Clients buy jobs
("audit trails," "AI governance," "verifiable citations"); the firm
sells outcomes; Xudanu is how one class of outcomes is delivered
uniquely well. Therefore the build priority is **engagement-ready
artifacts**, not consumer features — and the first step is not
building at all, but validating with the people who hear client asks.

## 2. Collected evidence (Sept 2026)

### 2.1 Landscape — nobody has the combination

| System | Granularity | Crypto | Verdict |
|---|---|---|---|
| C2PA / Content Credentials (spec verified) | whole asset | signed manifests | the standard — media asset-level; **no span-level text** |
| Git blame / Word track changes | line / passage | none | forgeable; what enterprises use today |
| W3C PROV | dataset/process | none | interop model only — we ship a validator; bridge, not rival |
| OpenTimestamps | whole-blob hash | PoW-anchored | now integrated (FR-60) as our floor |
| WikiWho et al. | passage | none (reconstructed) | computational attribution, not proof |
| AI watermark/detection sector | whole output | statistical | detection ≠ provenance |
| **`trustbeat` (crates.io, 0.2.1)** | file | **eIDAS-qualified TSA** | **file-level eIDAS anchoring exists as a product — seam validated by someone else; still asset-granularity** |
| `tydence` (0.2.0) | git blob | RFC 3161 | same shape, git data |

**Defensible uniqueness claim (exact wording, from
`provenance-flow-and-claims.md`):** *per-span Ed25519 author
signatures over collaboratively edited text, where provenance travels
with the passage across documents.* Every individual piece has
neighbors; the combination does not. Never "tamper-proof" —
*tamper-evident with per-passage cryptographic attribution.*

### 2.2 What Xudanu has today (inventory, all merged)

| Capability | Where | State |
|---|---|---|
| Per-element/per-span Ed25519 signatures (domain-separated) | `provenance.rs` | done |
| Three-state verification (verified / author-maintained / unsigned) | `attribution_query` | done |
| Hash-chained attribution log + seed genesis | `attribution_log.rs` | done |
| Bitcoin existence floor (OTS) | FR-60 `ots_anchor.rs` | done, live-verified |
| Notarized range receipts (prove a quote without the document) | `notarize.rs` | done |
| Revision forensics with author chips | FR-59 | done |
| Provenance travel across documents | transclusion + `provenance_ancestry` | done |
| Human/machine/transcluded author typing | `AuthorType` in data model | data exists, **no report** |
| PROV-JSON export bridge | `prov-validator` | validator only, **no exporter** |
| Demo-in-a-box + 5-min script + claims doc | `demo-links-reset.sh`, `demo-script.md` | done, **untested on a real practice lead** |

### 2.3 Claim-strength boundaries (already documented)

Cryptographically backed: content-signature binding, quote-existence
receipts, log-chain integrity. Server-conditioned: key→identity
binding (server is its own CA), timestamps (now floored by FR-60).
Known gaps: no user-side key receipts, no standalone external
span-verifier, federation code compiled into every build.

## 3. Assertions for the gap — what must be true that is not

| # | Assertion | Today |
|---|---|---|
| A1 | A non-expert takes documents in → client-ready evidence artifact out in <10 min | **false — no report export** |
| A2 | The artifact itself carries the honest claim wording (not just our docs) | false |
| A3 | A practice lead runs the demo without the maintainer | untested |
| A4 | A user can independently check the key→identity binding (key receipts) | **false** |
| A5 | Machine-vs-human-vs-quoted disclosure report exists per document | false (data exists) |
| A6 | An external party verifies our core evidence with stock tooling, no server | partial (OTS yes; span signatures need our stack) |
| A7 | A client-facing build contains no networking code | false (needs FR-62) |

## 4. Stories and effort (calendar-day estimates, solo-maintainer velocity as observed this quarter)

### V0 — Validation first (0 dev-days; gates everything)

- **V0.1** Run the 5-minute demo + claims conversation with ONE
  practice lead (advice-ask framing, per `demo-script.md`). Record
  the three questions they actually ask.
- **V0.2** If no question maps to an assertion above, stop — the
  seam is not real for this firm; revisit after C2PA text-provenance
  moves. If questions map, they pick S-story order.
- Effort: one meeting. Exit criteria recorded in this FR's appendix.

### S1 — Provenance audit report export (3–4 days; A1+A2)

Server-side HTML export per work: author-colored spans with
verification states, revision forensics (FR-59 hunks with authors),
anchoring status (FR-60), disclosure summary, and the exact claim
wording baked into the artifact. Pattern precedent: PROV validator
HTML builder. This is THE practice-lead artifact.

### S3 — AI-disclosure summary inside the report (1–2 days; A5, rides S1)

Aggregate `AuthorType` per document: % human-signed, % machine, %
transcluded-with-source. The EU-AI-Act-shaped number.

### S2 — Standalone verification bundle (2–3 days; A6)

Export: signed spans + public keys + chain, plus a `verify` mode that
checks signatures offline (no server). End state: a client's security
team verifies our report with a file we hand them.

### S4 — Key receipts (1–2 days; A4)

User-side export of "my key is K" receipt + a check mode proving the
server's identity binding matches. Closes the server-as-CA caveat.

### S5 — TSA anchor provider (0.5–1 day; per FR-60 S4)

RFC 3161 request (trivial DER, hand-rolled — no mature crate exists;
`trustbeat`/`tsp-http-client` are young), opaque token storage,
openssl as the named external verifier. Build when a client names
their TSA.

### Sequencing

```
V0 (meeting) ──► S1+S3 (report + disclosure) ──► S2 (bundle) ──► S4/S5 (as pulled)
                                              FR-62 (gate) before any client env
Total: ~8–12 dev-days, of which only S1+S3 (~5) before the second conversation
```

## 5. Acceptance criteria

- V0 notes recorded (questions asked, reaction, follow-up) before any
  S-story starts
- S1: a 3-work sample set exports a report a non-technical reader can
  follow, with claims worded per the claims doc, in one command
- S2: verification bundle validates offline with only the bundle +
  public keys
- Nothing in this FR ships to a client environment before FR-62's
  minimal build exists

## 6. Non-goals

- Not a product, not multi-tenant, not a SaaS
- No client-specific work before a named account
- No new crypto — every story composes existing machinery

## 7. Risks

- **IP boundary** — the one-sentence version (Apache 2.0, firm uses
  like any tool, productization is a later conversation) must be said
  at the first internal interest, not after firm time is invested
- **Solo-maintainer delivery risk** — mitigated by artifact-over-
  product scope and headless/demo-box form
- **Landscape motion** — C2PA extending to text would change A-gap
  urgency; re-check before S1 starts

## Appendix — evidence pointers

`docs/dev/provenance-flow-and-claims.md` (flow + claim table),
`docs/dev/demo-script.md` (V0 script), `docs/dev/FR-60-ots-anchoring.md`
(floor), crates.io findings (trustbeat 0.2.1, tydence 0.2.0,
tsp-http-client 0.1.0 — checked 2026-09-07), C2PA specification index
(checked 2026-09-07: asset-granularity, no span-level text).
