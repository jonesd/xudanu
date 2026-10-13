# FR-89: Opt-in Anonymous Telemetry — H(G)/H(AI) and Usage Aggregates

- **ID:** FR-89
- **Status:** Proposed (2026-10-12)
- **Depends on:** hg-profile CLI (existing); admin console (existing);
  audit log (existing)
- **Closes:** the organic-corpus gap in the H(G) work (the
  "designed-vs-organic" study promised to Adamski et al.); adoption
  instrumentation (backlog 0c's empty-doc bounce, measured rather
  than guessed)

## 1. Why

Every measurement we have is of our own seeded corpora; there is
no organic usage data, and no way to study how engineered
hypertextuality behaves under real use. Self-hosted deployments
are the natural data source — if their owners consent. The H(G)
profile is content-free by construction (structural aggregates
only), so it can travel without leaking anything readable. Done
with the same discipline as the rest of the system — default off,
exact-payload preview, verifiable send log — telemetry becomes
both a research instrument and a trust demonstration.

Research payoff: multi-site H(G); **H(AI) in the wild** (the
human/LLM/historical content mix across real corpora — Adamski
Q4 answered with data no one else has); designed-vs-organic
longitudinal profiles; real-world op-latency percentiles for the
paper's performance claims.

## 2. Payload — tiers, all opt-in

**Tier S (structure):** the ten H(G) coordinates; per-author-type
sub-profiles (H(AI)); node/edge counts; link-type histogram;
transclusion count.

**Tier U (usage aggregates):** works count; clubs count; session
count; total and mean document size (chars); revision count;
links created by type; transclusions placed; activation funnel
counts (docs created → received text → received ≥1 link →
received ≥1 transclusion).

**Tier O (ops):** version; platform/OS; uptime; edit policy;
federation/OTS/MCP enabled flags; op-latency percentiles (p50/p99).
**Network participation, counted separately by capability:**
- federation: `federation_mode` (closed/open/off),
  `federation_peers_configured`, `federation_peers_active`,
  `federation_cross_server_links`, `federation_cross_server_transclusions`
- the xudanu network (the Xanadu-network analog — designed by
  Nelson, never operated historically): `xudanu_network_enabled`,
  `xudanu_network_known_servers`, `xudanu_network_cross_server_links`,
  `xudanu_network_cross_server_transclusions`
Rationale: these counters are the first-ever operational
measurements of a xanalogical network ("first vital signs of a
design that waited sixty years" — dashboard headline and paper
material). NEVER peer addresses/hostnames; peer/server counts
below the k-threshold bucket as "2–4".

**Tier L (longitudinal, default-off extra):** random install ID
(rotatable via admin action) — required for H(G)-over-time;
without it, reports are anonymous one-shots.

**Explicit exclusions (never in any payload, enforced by the
serializer's allow-list, not by omission):** document titles,
previews, text, tumbler addresses (embed namespace IDs), content
crums (text hashes enable confirm-guess), user/club names,
session identities, security-log contents.

**Payload bound:** the schema is a closed, enumerated set —
~100 fields, one JSON, one POST (a snapshot, never an event
stream: no per-user or per-document rows). Hard cap enforced by
test (~4 KB); the set grows only by FR decision, never
accidentally, and the consent screen renders the entire
surveillance surface on one page — that is the design constraint
that keeps it honest.

## 3. Privacy mechanics

- **k-threshold:** Tier S reports only when node count ≥ 20
  (small private docuverses are fingerprintable by graph shape);
  below that, send Tiers U/O only, with counts bucketed
  (e.g., "1–4 works").
- **Serializer allow-list:** payload is built field-by-field from
  the tiers above; anything not listed cannot enter. Test: a
  proptest that scans serialized payloads for any substring of
  any document title/text in the corpus (zero-tolerance).
- **Default OFF.** Enabled via `--telemetry-url <endpoint>` or
  admin console; empty default. No phone-home without a URL.

## 4. Consent UX

1. First-enable screen lists every field by tier with plain
   descriptions.
2. **Preview shows the exact JSON** that will be sent — the
   payload the user approves is byte-identical to the one
   transmitted (version/uptime fields snapshot at send time are
   marked as such).
3. Admin console: re-view current payload, trigger a manual send,
   rotate/delete install ID, disable.
4. **Every send writes the payload's hash to the tamper-evident
   audit log** — the operator can always verify what left the
   server and when. Telemetry with a provenance trail.

## 5. Transport and receiver

- HTTPS POST to the configured endpoint (default none;
  xudanu.com/stats for those who opt in).
- No response parsing, no retry loops beyond simple bounded
   retry; failures are silent in operation, visible in admin.
- Receiver publishes an **open aggregate dashboard** (counts,
   distributions, H(G)/H(AI) summaries across reporting
   instances) — transparency as marketing; also the data source
   for future papers (with the same provenance labeling
   discipline as Email 1's corpus note).

## 6. Stages

| Stage | Work |
|---|---|
| S1 | Payload serializer + allow-list + leak proptest |
| S2 | Consent UI (preview exact JSON), admin controls, audit-log send hash |
| S3 | Receiver endpoint + minimal aggregate dashboard |
| S4 | k-threshold/bucketing rules; longitudinal install-ID mode |
| S5 | Wire into paper/Adamski follow-up as the standing study |

## 7. Non-goals

No crash reporting, no content-adjacent telemetry, no
third-party analytics libraries, no cookies/return channel. One
JSON, one POST, user-approved, audit-logged.

## 8. Report integrity (tainting)

Truth of anonymous reports cannot be proven by anyone; the goal
is to make lies expensive, visible, and low-value.

- **Provenance labeling:** everything derived from telemetry is
  published as "self-reported, opt-in" — never census. Research
  claims stay on curated reproducible corpora; telemetry shows
  direction and drift only
- **Signed install identity:** telemetry enablement generates an
  Ed25519 keypair; install ID derived from the public key; every
  report signed. Sybil resistance + key continuity (an ID whose
  story changes impossibly gets downweighted)
- **Challenge-recompute (later stage):** receiver may demand H(G)
  recomputed with a server nonce mixed into node ordering — real
  servers recompute in ms; fabricators must implement the whole
  profile engine to keep lying
- **Consistency filters:** impossible values (edges > n²,
  out-of-range coordinates, non-monotonic funnel counts),
  percentile-order violations, cross-report contradictions,
  per-ID quotas, duplicate clustering
- **Defensive publication:** aggregates only, minimum cohort
  sizes, raw data + filter code published openly, dashboard
  itself append-only/versioned
- **HTTPS everywhere on the ingest path + HSTS** — not because
  the payload is sensitive, but because TLS structurally enforces
  the promise that nothing else rides the connection

## 9. Data sharing policy

The data is effectively anonymous (pseudonymous install IDs,
random keys, no account/email linkage at home base — the ID IS
the key). Sharing is tiered and documented:

1. **Public dashboard (everyone):** k-anonymized aggregates only;
   no per-install rows ever published
2. **Researchers, by request:** the de-identified per-install
   dataset under a plain-language agreement — research use only;
   no re-identification attempts; no redistribution of raw
   per-install data; cite the source; share findings back
3. **Nobody else, no other purpose** — not advertising, not
   "partners"; the consent screen states this in one line

**Sharing register:** every release (to whom, what snapshot,
when, hash of the exact dataset) recorded in an append-only
public log — transclusion-grade provenance applied to our own
telemetry. Reporting installs can verify what left home base,
and to whom, forever.

**Researcher engagement is trigger-tied, not date-tied:** reach
out only when the data is worth their time — trigger: ≥5
THIRD-PARTY reporting installs (project-operated installs do not
count) OR the first recorded cross-server transclusion by a
third party. The payload carries a self-declared
`project_operated` flag, and the dashboard separates the two
classes everywhere — we never seed our own stats. Adamski (H(G)
at scale, §5.4 fulfilled), Millard (H(AI) usage), Seed pair
(first federation/network measurements in existence). Second
beat of threads already opened (outreach-emails.md pair-report
ladder). Project-operated installs double as the dogfooding set
for the consent UX (FR-89 ships only after being enabled on
xudanu.com and demo.transclusion.org first).
