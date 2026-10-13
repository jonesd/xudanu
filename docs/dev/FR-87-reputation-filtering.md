# FR-87 — Reputation Filtering: endorsements as the reader's lens

**Status:** Proposed (October 2026) — machinery shipped, reader story missing
**Source:** Mark S. Miller with Tribble, Pandya, Stiegler, "The Open Society
and its Media" (1995), §16.12 "Reputation-based filtering"
(`docs/dev/TheOpenSocietyanditsMedia.pdf`). Gold lineage:
`nlinksx.cxx:144-145` — `FeHyperLink::make` auto-endorses with the
author's ID and the IDs of all its type works.
**Related:** `endorsed-link-types.md` (trust-chain design sketch),
`phase-13-endorsement-authority.md` (work/edition endorsement stamps),
FR-27 (link filtering — never shipped), FR-39 (link types as documents),
FR-40 (typed links), FR-41 (federation endorsement sync), FR-46 (server
reputation), FR-85 (argument structure — sorts chains by endorsement
weight), `miller-eight-features.md` feature #6 (PARTIAL — this FR is
its completion), `private/backlog.md` Open Society build ranking
(item 1).

## Why

Miller's junk-problem argument, in full:

> "One of the potential pitfalls of an open hypertext system is the junk
> problem. The ability to find good commentary and criticism will be
> especially important when reading very important documents, but it is
> precisely on these documents that one expects to be inundated with tons
> of worthless or irrelevant links. Without a filtering mechanism, it
> would be on exactly the documents for which one most needs good
> commentary that the provision of commentary would be most useless.
> For example, imagine how many links there would be onto the First
> Amendment to the Constitution."

The mechanism, also in full, because every clause is a requirement:

> "Links can be endorsed as worth reading by various readers. However,
> no one may endorse with the identity of another. Different endorsers
> will establish varying reputations with different readers, much as
> with movie reviewers. Readers can filter their views of links into a
> document both by who endorsed as well as by link-type. When even this
> mechanism gives too coarse an answer, one can rely on documents such
> as a hypothetical Guide to the Citations to the Bill of Rights,
> endorsed by a reputable publishing house. This very same link
> filtering ability is also what allows one to find such guides in the
> presence of a swamp of links."

Three distinct claims, each a story below:

1. **The vouch** — endorsement is a *reader's* review of a link, not an
   author's decoration. The endorser is a third party vouching "this is
   worth your time," like a movie reviewer.
2. **The identity boundary** — "no one may endorse with the identity of
   another." You vouch as a club your session holds signature authority
   over; nothing else. Reputation attaches to identities, so identity
   borrowing would corrupt the whole mechanism.
3. **The filter, and the escape hatch** — readers filter by endorser ∩
   link-type; when that is still too coarse, they find an *endorsed
   guide* — and the same filter is what makes the guide findable inside
   the swamp. The filter bootstraps itself.

The system's honesty rule runs through all three: **no official
truths, only who said what.** The system never judges content; it
records who vouched for what, and each reader decides whose vouches
they weigh.

## Current state (verified October 2026)

| Component | State | Where |
|---|---|---|
| Link endorsement model (`Author \| Vouch \| Type`) | DONE | `edition/links.rs`; auto-author seeded on create |
| Wire ops `link_endorse` / `link_unendorse` / `link_endorsements` | DONE | `dispatch.rs:2577-2591`, `server.rs:10170-10249`; auth-only (no edit rights needed) — correctly per §16.12 |
| Identity boundary | DONE | vouch stamps the session's author club via `resolve_author_club`; you cannot name another club |
| Payload surfacing | DONE | `LinkPayload.endorsements` (club, display name, kind, timestamp), `.endorsement_count`, `.link_contested` (`protocol.rs:3398-3484`) |
| Canopy endorsement bits | DONE | O(1) flag-check pruning (`canopy.rs:481-586`) — Gold's design intact |
| Engine query filter | DONE, unused | `RecorderQuery.endorsement_filter: Option<Vec<u64>>` (`recorder.rs:22`) |
| WAL durability | DONE | `append_link_endorse` / `append_link_unendorse` |
| Row badges (named-first vouchers, contested flag) | DONE | WorkspaceShell links panel rows |
| **Reader-side endorser filter** | **MISSING** | no "endorsed by" filter anywhere in the UI — the §16.12 sentence with no implementation |
| **Vouch affordance for readers** | **PARTIAL** | the row ✓ button exists but is gated on `canEdit`; §16.12 is a reader action on *other people's* swamped documents |
| **Endorsed guides** | **MISSING** | work-level stamps exist (phase 13) but nothing surfaces "the guide, endorsed by X" in a link swamp |
| Backlink endorsement data | **MISSING** | `BacklinkEntry` carries no endorsement fields — incoming swamps cannot be filtered |
| Swamped demo corpus | **MISSING** | no seeded document where endorsement filtering is the point (the First Amendment paragraph, made walkable) |

## Design

### S1 — The endorser filter (core; completes §16.12)

In the Links panel filter row, next to the type chips, one compact
control:

```
Endorsed by: [anyone ▾]
             anyone
             any vouch (12)      ← at least one third-party vouch
             ─────────────
             A. Reviewer (5)     ← distinct vouchers across the
             The Curator (4)        current list, named-first,
             History Club (3)       sorted by vouch count
```

- Filters **intersect** with the existing type chips (endorser ∩
  type — Miller's exact sentence).
- Applied client-side from `LinkPayload.endorsements` already in the
  payloads; no server round-trip needed for v1. (The engine's
  `RecorderQuery.endorsement_filter` is the server-side path when
  scale demands it.)
- The "Links (N)" count reflects both filters.
- Only non-author endorsements count as vouches (the author's
  auto-endorsement is provenance, not reputation).

### S2 — Vouch as a reader action

- The row ✓ becomes available to any **authenticated** session, not
  just `canEdit` sessions. Vouching someone else's link on someone
  else's document is the movie-reviewer act; the server already
  permits exactly this and nothing more.
- Already-vouched state: if the viewer's club has vouched, the button
  shows filled and a second click **withdraws** (`link_unendorse`) —
  contestation is one gesture, matching `endorsed-link-types.md` §3.
- Failures surface as a toast, never a silent catch.
- Anonymous sessions share the public club: their vouches collapse
  into one undifferentiated voice. Not a bug — the system saying
  anonymous praise is worth exactly one shared voice (needs no code;
  document it).

### S3 — Endorsed guides (the escape hatch that finds itself)

When a document is linked from a *guide* (a curated trail or gathers
cover), the guide's own endorsements are the reader's signal:

- Trail/gathers covers can carry work-level endorsements (phase-13
  stamps) — "endorsed by a reputable publishing house."
- In a filtered view, guides surface in their own slot above the raw
  link list ("Endorsed guides") — found by the same endorser filter,
  which is Miller's bootstrap sentence.
- First corpus: the release-notes-as-endorsed-works pattern from
  `miller-eight-features.md` #6.

### S4 — The swamped demo (the First Amendment paragraph, walkable)

A new Gallery room — "The Swamped Passage" — seeded as part of
`--seed-gallery`:

- One important short paragraph with ~9 links of mixed types (the
  swamp).
- 2-3 seeded named clubs vouching for a subset — enough that the
  endorser filter demonstrably changes what survives.
- Room text teaches the move: "How to read it: filter by endorser —
  only what a trusted club vouched for survives the swamp."
- Lobby floor plan and Curator's Tour gain the room (test counts
  update).

### S5 — Backlinks carry their endorsements (incoming swamps)

Extend `BacklinkEntry` (and the backlinks query) with the same
`endorsements` / `endorsement_count` / `link_contested` fields, so the
endorser filter works on *incoming* links too — the First Amendment
is swamped from outside, not from its own outgoing links. S1's UI
applies the same predicate to both lists.

### Deferred (recorded, not scoped here)

- **Endorser profile view** — a reader's reputation circle (their
  vouches over time, follow-an-endorser). Valuable; separate story.
- **Federation trust evaluation** — endorsement sets travel with
  replicated links (FR-41 `endorsement_sync`); a receiving server
  scoring cross-server vouches is a later FR.
- **Weighted ordering** — sort-by-endorsement-weight beyond FR-85's
  argument chains.

## Acceptance criteria

- [ ] Links panel offers an endorser filter (anyone / any vouch /
      specific endorser) intersecting the type chips; counts update
- [ ] A reader (authenticated, no edit rights on the document) can
      vouch and withdraw; state is visible and durable across restart
- [ ] Withdrawing a vouch changes the filtered list (endorse →
      appears under that endorser; retract → disappears)
- [ ] No session can cause an endorsement stamped with a club it
      lacks signature authority for (identity boundary holds)
- [ ] Contested links show the amber flag in filtered views
- [ ] `--seed-gallery` seeds the Swamped Passage with ≥2 named
      endorser clubs and ≥3 vouched links; gallery tests updated
- [ ] Backlink rows filter by endorser identically to outgoing rows
      (S5)
- [ ] `miller-eight-features.md` #6 moves PARTIAL → DONE; heritage
      page table (`docs/gold-heritage.html#miller-eight`) updated in
      the same change

## Test plan

- **Rust (server):** two-club vouch lifecycle — session B (different
  club) endorses A's link → `link_endorsements` shows the vouch;
  `link_unendorse` withdraws it (the strike-out is recorded, per
  Gold's retract() contract: "removed endorsements… analogous to a
  signature that has been struck out"); withdrawing a vouch that
  isn't present is a silent no-op ("ignores all endorsements which
  you could have removed, but which don't happen to be there right
  now"); restart → endorsements and strike records survive
  checkpoint (WAL replay and snapshot restore both covered).
- **Rust (seed):** Swamped Passage seeded, idempotent; ≥3 links carry
  non-author vouches from ≥2 distinct clubs.
- **Web (unit):** filter predicate — endorser ∩ type, any-vouch
  semantics (author-only ≠ vouched), empty state when the filter
  selects nothing.
- **Web (unit):** vouch/withdraw button gating (authenticated reader,
  not canEdit) and already-vouched toggle state.
- **E2E (optional):** on the seeded gallery, apply "Endorsed by:
  [club]" → list shrinks to vouched rows.

## Effort and sequencing

| Story | Size | Note |
|---|---|---|
| S1 filter | ~1 day | client-side; payloads already carry everything |
| S2 reader vouch | ~half day | mostly ungate + toggle + toast |
| S4 swamped demo | ~half day | rides `seed_gallery.rs` patterns |
| S3 endorsed guides | ~1 day | needs trail/gathers cover stamp surface |
| S5 backlink fields | ~half day | payload + query extension |

Sequence S1 → S2 → S4 (the demo makes S1/S2 walkable), then S5, S3.
This is `private/backlog.md` Open Society item 1 and
`miller-eight-features.md` sequencing item 1 — the same work seen from
three documents, which is itself the paper's point: connection, not
copy.
