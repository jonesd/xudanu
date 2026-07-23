# FR-24: Transcopyright Licensing and Attribution

> Adds per-work license metadata to Xudanu, making it the first
> system to natively support Ted Nelson's Transcopyright License
> (TCo). Because Xudanu's transclusion architecture already satisfies
> TCo's two provisions by design, TCo becomes the natural default for
> transcluded content. Authors can also choose Creative Commons
> variants or all-rights-reserved. License is displayed on
> transclusion, in the graph, and in the document header.

## Decision Question

How does Xudanu represent the *license* of a work, ensure proper
*attribution* when content is transcluded across servers, and position
itself as the system where Transcopyright actually works?

The answer shapes:
- Whether transclusion is legally legitimate or just a technical trick
- Whether authors can choose how their content may be reused
- Whether Xudanu has a unique identity vs. "another wiki"
- Whether micropayments/royalties (Rule 9) can ever be layered on

## Decision

**Three connected pieces:**

1. **`License` field on every work** — an enum stored alongside
   `WorkKind`, persisted to manifest, restored on restart. Defaults
   to `AllRightsReserved` (the legal default under the Berne
   Convention — no action required by the author). Five options:

   | License | What it means | Why include it |
   |---|---|---|
   | All Rights Reserved | Default. No transclusion rights granted. | Safe baseline; what copyright grants automatically |
   | Transcopyright (TCo) | Transclusion by address is always allowed | Xudanu's unique differentiator; fits the architecture |
   | CC-BY | Attribution required, reuse allowed | Most widely recognized permissive license |
   | CC-BY-SA | Attribution + share-alike | Common in open education and academia |
   | Public Domain (CC0) | No rights reserved | For authors who want maximum openness |

   No legal or financial risk to Xudanu: the server stores a label,
   not a contract. Offering license *options* in a picker is no
   different from a CMS offering license fields — it's metadata.

   CC-BY-NC (non-commercial) is deliberately excluded: "commercial" is
   notoriously ambiguous in a transclusion system where a compound
   document mixes content from many sources.

2. **TCo as a first-class option** — when a work is licensed TCo,
   every transclusion of it automatically satisfies both provisions:
   - "Download and keep from designated server" = content fetched
     from origin server via tumbler resolution
   - "Republish by address" = transclusion IS an address (EDL/tumbler),
     not a copy

3. **Automatic attribution on transclusion** — when content is
   transcluded, display: source work title, author, origin server,
   and license badge. Already partially done via provenance spans;
   this surfaces it visually.

## Background: What We Have Today

### Work metadata

Currently stored on each work:
- `WorkKind` (Document, Note, Person, Concept, Collection, Commentary)
- `owner`, `revision_count`, `title`
- `read_club`, `edit_club` (access control)
- `is_starred`, `is_source`, `is_archived`

**Missing:** any field for license. All works are implicitly
"all-rights-reserved" with no mechanism to declare otherwise.

### Transclusion architecture (already built)

Xudanu's transclusion system already implements the TCo mechanism:

- **Tumblers** provide stable addresses (`server.5.3.10.7`)
- **Transclusion** resolves via origin server, not byte-copying
- **Compound documents** are EDLs (ordered transclusion lists)
- **Backlinks** track inbound references
- **Provenance** records author + server for every span
- **Cross-server resolution** (FR-6) fetches content from origin
- **Attribution spans** already show authorship

### Nelson's 17 Rules compliance

Rule 9 ("royalty mechanism") is one of 4 rules not yet implemented.
TCo is the licensing framework that makes royalties possible — without
a license framework, there's no legal basis for charging for access.

Rule 8 ("permission to link is granted by publication") is already
implemented via read-club semantics. TCo builds on this: publication
under TCo explicitly grants transclusion rights to all parties.

## The Transcopyright License (Summary)

Source: <https://xanadu.com/xuTco.html> (version of November 22, 2016)

TCo has exactly two provisions:

1. **Download & Keep** — anyone may download content, but must obtain
   it from the author's designated server and retain it connected to
   that server.

2. **Republish by Address** — anyone may republish content in any new
   context and any amount, provided they republish only by giving the
   online address of the content on the author's designated server
   (e.g., via EDL).

Key properties (not explicit in the license, but inherent):
- Attribution is automatic
- Mixing content from many sources is permitted
- Content remains attached to its original source
- Original context is reachable directly
- Publishers may require payment, or not
- Distribution by EDL is expected

### TCo vs. Creative Commons

| Aspect | Transcopyright | Creative Commons |
|---|---|---|
| Unit of licensing | Addressed content (transclusion) | Lump files (copies) |
| Reuse mechanism | Republish by address | Copy with conditions |
| Attribution | Automatic (address includes source) | Manual (author must be credited) |
| Source connection | Permanent (content from origin server) | Broken (copy is independent) |
| Mixing across licenses | Allowed (all TCo content mixes) | Restricted (SA blocks mixing) |
| Payment | Optional, per-author choice | Not part of CC framework |
| Legal precedent | Untested in court | Well-tested |

**Key insight:** CC licenses are designed for the copy-based web.
TCo is designed for the transclusion-based docuverse. Xudanu implements
the docuverse, so TCo is the natural fit.

## Design

### Phase 1: License metadata (small, high value)

**Backend:**
- Add `License` enum to `edition/work.rs`:
```rust
pub enum License {
    AllRightsReserved,      // default (Berne Convention)
    Transcopyright,         // transclusion by address allowed
    CreativeCommonsBy,      // CC-BY — attribution, reuse allowed
    CreativeCommonsBySa,    // CC-BY-SA — attribution, share-alike
    PublicDomain,           // CC0 — no rights reserved
}
```
- Add `license: License` field to `Work` (default: `AllRightsReserved`)
- Add `WorkEntry.license` to manifest (with `#[serde(default)]`)
- Wire ops: `work_license_get`, `work_license_set` (0x0B05-06)
- Checkpoint/restore (same pattern as WorkKind fix — must call
  `work.set_license()` on restore)
- `build_work_graph` returns license per node

**Frontend:**
- License picker in document header (next to WorkKind picker)
- License badge on each work card in the work list
- License badge displayed on transclusion markers in the editor
- Settings: server default license for new works (configurable)

### Phase 2: Attribution display (medium)

- When a transclusion is rendered, show a badge with:
  - Source work title (clickable → navigate to source)
  - Author name
  - Origin server name/ID
  - License icon (TCo flame, CC icons, © for ARR)
- In layout mode (image rendering), show license on images
- In compound document viewer, show per-span license
- Backlink notifications include license info

### Phase 3: TCo compliance verification (medium)

- When a user creates a transclusion, verify:
  - Source work exists on origin server (FR-6 cross-server resolution)
  - Source work's license permits transclusion (TCo: always; CC-BY: yes
    with attribution; ARR: warn; CC-BY-NC: warn if commercial context)
  - Attribution metadata is included in the transclusion element
- Log transclusion events in attribution log (already exists)
- Display "Transcopyright compliant" badge on the document

### Phase 4: Royalty recording hooks (future, external service)

- **Xudanu server only records obligations** — never settles them.
  The existing `RoyaltyEntry` in `federation.rs` records "Work A
  owes Author B X units for transclusion at time T." Payment is a
  separate concern handled by an external service.
- **Read-only attribution API** — expose transclusion events for
  external royalty services to query. The server provides data; it
  does not process money.
- **No payment integration in Xudanu.** Payment providers (Lightning,
  Dropp, Stripe) are integrated by the royalty service, not by Xudanu.
- See "Architectural Boundary" section below for the full rationale.
- This phase is out of scope for FR-24 but the license metadata from
  Phase 1 is the prerequisite.

## Implementation Notes

### Same pattern as WorkKind (FR-22)

The implementation follows exactly the pattern established by WorkKind:
- Enum in `edition/work.rs`
- Field on `Work` struct with getter/setter
- `WorkEntry` field in manifest with `#[serde(default)]`
- Checkpoint writes `ws.work.license()`
- **Restore must call `work.set_license(work_entry.license)`**
  (this was the bug we fixed for WorkKind — same trap)
- Wire ops use `ensure_authenticated` (license is metadata)
- Frontend: picker in document header, cache in component state

### License display

License badges should be compact (16x16 icon or abbreviation):
- ARR: © symbol
- TCo: "TCo" label (badged as "recommended for transclusion" in picker)
- CC-BY: standard CC-BY icon
- CC-BY-SA: standard CC-BY-SA icon
- CC0: standard CC0 icon

### Transclusion + TCo interaction

When content is transcluded from a TCo-licensed work:
1. The transclusion element stores `source_work_id` (already does)
2. Resolution fetches from origin server (already does, FR-6)
3. Attribution spans show the original author (already do)
4. NEW: License badge shows "TCo" on the transclusion
5. NEW: Clicking the badge links to the license text

This means TCo works "for free" — the architecture already satisfies
both provisions. We just need to surface it.

### What TCo does NOT require

- TCo does not require payment (it's optional)
- TCo does not require federation (single server is fine)
- TCo does not require identity (attribution is by address, not by name)
- TCo does not restrict commercial use
- TCo does not restrict modification (the EDL/transclusion is the modification)
- **TCo does not require the content server to handle money**

### License model: single license per work, changeable, irrevocable grants

**One license per work.** Phase 1 uses a single `License` field on the
`Work` struct (not per-revision, not per-span, not multi-license).

**License can change over time.** An author may switch a work from ARR
to TCo, or from TCo to CC-BY. The change is prospective.

**Past grants are irrevocable.** If someone transcluded your work while
it was TCo-licensed, that transclusion remains TCo-licensed even if you
later switch to ARR. This is standard copyright practice — a license
grant cannot be retroactively revoked.

**No separate license-history feature needed.** Instead of querying
"what was the license at time X?", we stamp the source work's license
into the transclusion event itself. When Bob transcludes from Alice's
work, the attribution log records: source work ID, source work's
license *at that moment*, timestamp. Each transclusion carries its own
proof — no retroactive uncertainty, no separate history query.

Phase 1: store current license on `Work`.
Phase 2-3: add `source_license` field to transclusion log entries (one
extra field on an existing log entry, not a new feature).

**Per-span licensing comes free through transclusion.** A compound
document mixing Alice's TCo paragraphs with Bob's CC-BY paragraphs is
inherently multi-licensed at the span level — each transcluded span
carries its source work's license via attribution. This requires no
additional mechanism beyond what transclusion already provides.

**Dual/multi-licensing** ("available under TCo *or* CC-BY, recipient's
choice") is explicitly Phase 2+. Not needed for initial launch.

## Architectural Boundary: Recording vs. Settlement

**The Xudanu server never touches money.** This is a hard design rule,
not just a recommendation.

### The split

| Layer | Responsibility | Who runs it | Financial risk |
|---|---|---|---|
| **Xudanu server** | Record transclusion events, store license metadata, track provenance | Anyone (self-hosted) | **None** |
| **Royalty service** (optional) | Read attribution log, calculate amounts, process payments | Third party or content creator | All financial risk lives here |

### What the Xudanu server provides (pure data, no obligation)

- **Attribution log** (`attribution_log.rs`, already built) — records
  "Work A transcluded content from Work B (owned by Author C on Server D)
  at timestamp T." This is metadata.
- **License metadata** (FR-24 Phase 1) — declares "this work is TCo" or
  "this work is CC-BY." This is a label, not a payment instruction.
- **Provenance tracking** (already built) — cryptographic attribution
  spans showing who wrote what.
- **Read-only API** — a royalty service can query: "what transclusion
  events happened on this server between date X and date Y?" Returns
  structured data. No payment processing.

### What the Xudanu server does NOT do

- No payment processing (no Stripe, Lightning, crypto, fiat)
- No wallet management
- No escrow or holding of funds
- No KYC / AML compliance
- No chargeback handling
- No fraud detection for financial transactions
- No PCI compliance
- No money transmitter licensing

### Existing code already reflects this

The `RoyaltyEntry` in `federation.rs` is explicitly described as:

> *"Records a transclusion royalty obligation. This is recording, not
> settlement — payment is a separate concern."*

The PBFT governance layer records what is *owed*; it never processes
payment. This boundary must be preserved in all future development.

### How a royalty service would work (example, not part of Xudanu)

1. A third party (e.g., "Xudanu Royalties Inc.") runs a separate service
2. That service periodically queries the Xudanu server's attribution API
3. It calculates royalties: "Alice's work was transcluded 47 times this
   month across 12 documents on 3 servers"
4. It processes payments via Stripe / Lightning / whatever
5. It distributes payouts to authors

**Xudanu's role ends at step 1.** The server provides data; the royalty
service handles everything financial. A Xudanu server operator has zero
financial obligation even if their server hosts TCo-licensed works that
generate royalties — they're providing infrastructure, not processing
payments.

### Why this matters

If Xudanu ever processes payments directly, the server operator becomes
liable for:
- Money transmitter regulations (varies by jurisdiction)
- PCI-DSS compliance (if touching credit card data)
- Consumer protection laws
- Tax reporting obligations
- Fraud and chargeback costs

By keeping a hard boundary, Xudanu remains pure infrastructure — like
an HTTP server or a database. Nobody sues PostgreSQL because someone
stored payment data in it.

## Has Anyone Implemented TCo?

**No.** No production system has implemented Transcopyright. The
original Xanadu project (Udanax-Gold) included the concept but never
shipped a production system. Creative Commons dominates alternative
licensing. No CMS, wiki, or publishing platform supports TCo.

Xudanu would be the first — and the only system where it actually
works, because TCo requires transclusion-by-address, which only Xudanu
provides.

## Legal Considerations

- TCo is a copyright license, not a waiver. Authors retain copyright.
- TCo has never been tested in court. This is a risk but also expected
  for any new license.
- Xudanu's disclaimer already notes it is not affiliated with Project
  Xanadu. Implementing TCo does not change this — TCo is a public
  license intended for anyone to use.
- The "Xanadu" name and flaming-X logo are trademarks of Project Xanadu.
  "Transcopyright" as a concept is not trademarked (it's a license, like
  "Creative Commons" is a license framework).
- We should not use the flaming-X logo without permission. The TCo
  license text itself is public (published at xanadu.com/xuTco.html).

## Alignment with Nelson's 17 Rules

| Rule | Status without FR-24 | Status with FR-24 |
|---|---|---|
| Rule 8: Publication grants link permission | Implemented (read_club) | Unchanged |
| Rule 9: Royalty mechanism | Not implemented | Phase 1 enables Phase 4 |
| Rule 13: All quotation is fair use | Partially (transclusion exists) | Strengthened (TCo legitimizes quotation) |

## Open Questions for Review

1. **Default license for new works:** `AllRightsReserved` (safe) or
   `Transcopyright` (bold)? Recommendation: ARR default, TCo as easy
   opt-in.

2. **TCo trademark:** Can we use the word "Transcopyright" in our UI
   without affiliation concerns? The license itself is public; the term
   describes a licensing method. Likely fine, but verify.

3. **License enforcement:** Should the server refuse transclusion of
   ARR-licensed works? Or just display a warning? Recommendation: warn
   only — authors are responsible for compliance, not the server.

4. **License on revisions:** Resolved — single license per Work, not
   per revision. License changes are prospective; past transclusion
   grants remain under the license in effect at the time. The revision
   timeline (FR-23) provides the audit trail. See "License model"
   section above.

5. **Cross-server license propagation:** When server A transcludes
   content from server B, does the license travel with the transclusion?
   Yes — the transclusion element should carry the source work's license.

6. **Financial firewall:** Confirm that the Xudanu server never handles
   payments — only records attribution data that an external royalty
   service can read. This keeps server operators free of financial
   obligation. Recommendation: make this a hard design rule documented
   in AGENTS.md and enforced in code review.

## Files to Touch (Phase 1)

- `src/edition/work.rs` — `License` enum, `Work.license` field
- `src/persist/manifest.rs` — `WorkEntry.license`
- `src/server/server.rs` — checkpoint/restore, `work_license_get/set`
- `src/server/transport/protocol.rs` — `WorkLicenseGet/Set` ops
- `src/server/transport/dispatch.rs` — dispatch handlers
- `src/server/transport/codec.rs` — JSON codec
- `src/server/server.rs` — `build_work_graph` returns license
- `web/app/src/api/crdt_sync.ts` — `License` type, client methods
- `web/app/src/components/workspace/WorkspaceShell.tsx` — picker UI
- `web/app/src/components/workspace/WorkspaceTopBar.tsx` — badge
- `web/app/src/graph-scoring.ts` — license display in graph nodes
- `web/app/src/workspace.css` — license badge styles

## References

- Transcopyright License text: <https://xanadu.com/xuTco.html>
- Nelson's 17 Rules: `docs/dev/xanadu-17-rules.md`
- Micropayment design: `docs/dev/cost-utility-meter-micropayments.md`
- FR-22 (WorkKind, same implementation pattern): `docs/dev/FR-22-concepts-and-categorization.md`
- FR-6 (Cross-server resolution, TCo's "designated server"): `docs/dev/FR-6.md`
