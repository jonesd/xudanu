# FR-157: The endorsement trust fabric — Gold lineage, current state, forward path

**Status:** mapped 2026-10-31. Research + decision record; no new build
yet. This document exists so the details do not get lost: endorsement
was a significant, deliberate part of Udanax Gold's design, the Rust
port carried more of it than is commonly remembered, and the dormant
parts are exactly what the translation work (FR-155) and the PBFT
pillar need next.

**Why this matters:** the system's answer to "can I trust what users
wrote" was never a single flag. It was a network of trust woven into
the addressing fabric: identities (clubs) vouching for regions of
content, other identities sponsoring works, and machines certifying
types — all of it retractable, visible only as permissions allow.

## Gold's design (from `src/promise.rog/client.prc` + `test.cxx`)

Both `Edition` and `Work` carried the endorsement API:

```
Void endorse(CrossRegion additionalEndorsements)
CrossRegion endorsements()
Void retract(CrossRegion endorsements)
CrossRegion visibleEndorsements()          ← Edition only
CrossRegion[IDSpace,IDSpace] endorsements() ← Edition only
```

Five properties, each load-bearing:

1. **Endorsements are spatial.** The unit is a `CrossRegion`, not an
   object. A trust assertion is anchored to a *region of content*.
2. **The cross-space pair is (who, what).** `test.cxx` shows the
   usage: `e1->endorse(XuCrossRegion::endorsements(userRegion,
   userRegion))` — the endorsing user's ID-space region paired with
   the endorsed region, inside a **dedicated endorsement cross
   space** (`XuCrossSpace::endorsements()`). Identity and assertion
   are the two axes of the same structure.
3. **Cross-space vouching exists.** `CrossRegion[IDSpace,IDSpace]`
   lets a region in one ID space vouch for a region in *another*
   space — the shape of "these source spans are faithfully rendered
   by those rendition spans."
4. **Existence is not visibility.** `visibleEndorsements()` is a
   separate, permission-gated view of `endorsements()`.
5. **Finiteness is enforced.** `XU_EndorsementMustBeFinite_PROBLEM`:
   only bounded, finite content can be endorsed.

Plus the reputation layer: `Work.sponsor(IDRegion clubs)` — clubs
vouch for works, publicly — and the club permission model
(`readClub`/`editClub`/`historyClub`) on the same class.

The machine side of the same mechanism: Gold's **wrapper** system
certified content *types* structurally. The port preserves it
faithfully (see below) — an endorsement from the wrapper club means
"this edition genuinely satisfies the Text/Set/Path/HyperLink/
HyperRef structure," checked by machine, not asserted by a human.

## What the Rust port has today

| Layer | Where | State |
| --- | --- | --- |
| Endorsement set algebra `(club_id, token_id)` | `edition/endorsement.rs` (760 lines, 45 tests): union/intersect/difference/subset/filters | live, load-bearing |
| Machine type certification | `edition/wrapper.rs`: `WRAPPER_CLUB_ID = 1`, tokens 1–5 (Text/Set/Path/HyperLink/HyperRef), `certify_as` structural checks | live |
| Human endorsement over the wire | `LinkEndorse`/`LinkUnendorse` 0x0710/0x0711 — kinds **Author** / **Vouch** / **Type**, one vouch per club, WAL-durable and replayed on restore | live (links only) |
| Sponsorship | `WorkSponsor`/`WorkUnsponsor` 0x0310/0x0311 — club vouches for work; edit-permission-gated; persisted, migrated, queryable; "sponsors are public reputation, not secret" | live |
| Federation propagation | `ReconcileState.endorsements: OrSet<EndorsementEntry>` — (club, token, origin_server) propagated by CRDT merge; membership `min_endorsements = 2` | live with `--peer` |
| PROV surfacing | `min_endorsements`, `endorsement_count` in federation PROV; recorder `endorsement_filter` queries | live |
| Cross-space regions | `CrossRegionN` in `space/cross_n.rs` (generalized to N axes) | live primitive, unused for endorsements |

**Dormant:** humans endorsing *content regions* — Gold's core
operation. Nothing lets a user say "I, this identity, vouch for this
region of this work." Links have it; content does not. The
`visibleEndorsements` visibility layer has no port.

## Forward path (decided direction)

1. **Restore region-anchored human endorsement, pointed at renditions
   first** (see FR-155 "Human renditions"): a translation endorsement
   *is* `CrossRegion[IDSpace,IDSpace]` — source-span region ↔
   rendition-span region. Grade ladder: machine-gisting → human-draft
   → human-reviewed → canonical; endorsements (one per verified
   identity, retractable) move a rendition up the ladder.
2. **Generalize to content regions** after renditions prove the
   shape: any user may vouch for any region; endorsements accumulate
   per (region, identity).
3. **Reputation is computed, never asserted.** No new primitive:
   standing derives from endorsement history (who vouches, who gets
   vouched for, sponsorship). Unweighted one-per-identity endorsements
   are the game-resistant starting point and accumulate exactly the
   data a weighting model will need later.
4. **Federation travel via the existing OrSet CRDT**; cross-server
   canonical selection ("which rendition is canonical for this work
   in French") becomes a PBFT decision — the PBFT pillar's natural
   first workload.
5. **Endorsement is not annotation.** Same rule as attribution:
   derived trust facts ride the endorsement structures, never the
   open-typed annotation system, so they can never compete with
   content or be mistaken for it.

**Work-weighting and AI endorsers.** Endorsements must be priced by
verified work, or they are free to mint and worth nothing:

- Zero-cost vouches are worth zero by construction: an endorser's
  weight comes from their own verified useful work in the domain —
  submitted drafts that survive supersession, reviews that hold.
- AI agents earn standing the same way humans do: through a history
  of judgments that survive scrutiny. An AI reviewer whose verdicts
  keep getting overturned decays to zero; one that keeps being
  confirmed accrues real standing. PROV records who did what, so
  this stays auditable. Do not ban AI endorsements — make them
  prove themselves.
- Identity cost is the Sybil floor: OAuth-only sign-in makes mass
  fake identities proportionally expensive. The mature attack is
  collusion rings of real accounts, and the endorsement history is
  itself the dataset that detects them (graph analysis; the
  n>100 problem).

## Bootstrapping without a population

The mechanism must not wait for members: it is a **recorder at n=1**
that gets smarter with scale. Each build stage has a validation mode
that needs no community:

| Stage | Validation without users |
| --- | --- |
| Grade ladder + submit/review ops | Unit/integration tests; live demo with the operator as sole actor — n=1 is honest record-keeping |
| Endorsement accumulation | Synthetic-population harness (a "trust-lab"): seeded identities with behavioral profiles (honest, sloppy, colluding ring, AI agent) over the seeded public-domain corpus; assert ladder outcomes and ring suppression |
| Reputation computation | Offline property tests on synthetic graphs: honest agents converge high, rings suppressed, decay deterministic |
| PBFT canonicalization | Local demo network (extends `scripts/demo-network.sh`): 4 nodes tolerate 1 fault, 7 tolerate 2 (3f+1) — no real federation partners needed |

AI agents double as the first population: they generate real
translation and review traffic, humans spot-check, and the
work-weighted machinery prices them honestly from day one. The
founding reviewers (5–10 bilingual humans) are an outreach task —
the HN standing track — not an engineering one. What cannot be
validated without people is sociology (whether humans bother
endorsing, whether the weights feel fair); the plumbing
deliberately does not depend on it.

## Open questions (deliberately unanswered here)

- Who may endorse: any verified identity, or club-membership-gated?
- Should the `visibleEndorsements` visibility layer return before or
  with federation travel?
- Does sponsorship extend to renditions (a club sponsors a
  translation), or does the grade ladder subsume it?
- Weighting and decay for reputation — only after real endorsement
  history exists to calibrate against.

## Cross-references

- `FR-155-cross-language-transclusion.md` — human renditions section
  (grade ladder + the Gold lineage note); rendition endorsements are
  FR-157's first application.
- `gold-link-model.md`, `federation-status.html`,
  `adversarial-resilience.md` — adjacent discussions of link trust
  and mesh security.
- Gold sources: `original-code/xanadugold/src/promise.rog/client.prc`
  (API), `promise.rog/test.cxx` (usage), `promise.rog/blasts.h`
  (`EndorsementMustBeFinite`).
