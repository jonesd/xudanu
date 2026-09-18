# Endorsed Link Types — Trust Chains on Connections

**Status:** design sketch (next session)
**Created:** 2026-09-18
**Prior art:** Gold `nlinksx.cxx:144-145` — `FeHyperLink::make` auto-endorses
with the author's ID **and the IDs of all its type works**
**Related:** FR-39 (registered types), FR-40 (link model), FR-41 (federation
endorsements), `gold-link-model.md` §1 (source archaeology)

## The insight

Gold used endorsements as the **social layer of the link model**.
A link isn't just a connection — it's a CLAIM ("this passage disagrees
with that one"), and endorsements answer *who vouches for the claim*.

From the Gold source (`nlinksx.cxx:145`):
```cpp
edition->endorse(FeServer::endorsementRegion(
    CurrentAuthor.fluidGet()->asRegion(),
    FeServer::iDsOfRange(edition->get("Link:LinkTypes"))));
```

The link is endorsed with the author's ID AND the IDs of every type
work in its type set. The source comment asks: *"What if someone
endorses it further (or unendorses it?)"* — designed to be dynamic,
contested, social.

## Current state (Xudanu)

| Component | Current | Gap |
|---|---|---|
| Endorsement | `(club_id, token_id)` — access tokens | No trust-claim semantics |
| Link types | Fixed integers (1=Comment, 2=Reference, ...) | Not works; no endorsement chain |
| Link creation | `author_club` field on LinkState | No auto-endorsement of author + types |
| Type definitions | FR-39 `link_type_register` creates definition works | Not linked to link endorsements |
| Contestation | None | No un-endorse / counter-endorse |
| Federation | `endorsement_sync` exists in federation.rs | Not used for link type trust |

## Design

### 1. Link creation auto-endorses

When a link is created with type set `T = {t1, t2, ...}`:

```
endorsements = {
    Endorsement::author(author_club),
    Endorsement::type(t1),
    Endorsement::type(t2),
    ...
}
```

Stored on the link's `EndorsementSet`. This makes every link carry
its trust provenance: who created it AND which type definitions
it claims to instantiate.

### 2. Type works with endorsement chains

FR-39 already creates type definition works. Extend:

- Each type work carries its own `EndorsementSet`
- Endorsing a type work = "I vouch this type definition is useful/valid"
- Type works can have super-types (Gold's type hierarchies) — endorsing
  a sub-type implicitly endorses its super-types

### 3. Un-endorsement (contestation)

A user who previously endorsed a link can withdraw:

```
link_unendorse(link_id, session_id)
```

This doesn't delete the link — it removes the user's vouch. A link
with zero endorsements is orphaned (still functional, but flagged as
unvouched in the UI).

### 4. Endorsement queries

```
link_endorsements(link_id) -> Vec<EndorsementPayload>
  .who: club_id, display_name
  .what: author | type(t) | vouch
  .when: timestamp

type_endorsements(type_id) -> Vec<EndorsementPayload>
  .how many links use this type
  .how many distinct endorsers
```

### 5. Federation: endorsements as cross-server trust

When a link is replicated cross-server, its endorsement set travels
with it. A receiving server can evaluate: "this link was created by
club X, endorsed by clubs Y and Z, using type work T" — and make
its own trust decision. This is the natural extension of FR-41's
`endorsement_sync`.

### 6. UI: trust indicators on links

In the connections panel, each link shows its endorsement state:

```
[●●●] Disagreement — "this passage disputes..."
        ↑ 3 endorsers (2 authors + 1 type)
```

Contested links (some endorsements withdrawn) show an amber flag.
Orphaned links (zero endorsements) show dimmed.

## Implementation sketch

1. Extend `Endorsement` enum: `Author | Type(work_id) | Vouch(club_id)`
2. `create_link` auto-populates the endorsement set
3. Wire ops: `link_endorse`, `link_unendorse`, `link_endorsements`
4. `link_type_register` creates a type work with its own endorsement set
5. Federation: `endorsement_sync` extended to carry link endorsements
6. UI: endorsement badges on link rows in ConnectionsSection

## What this buys

| Without endorsed types | With endorsed types |
|---|---|
| Types are a fixed enum | Types are a living, community-curated vocabulary |
| "Someone said this is a Disagreement" | "Three people vouch this is a Disagreement" |
| No way to contest a link's type | Un-endorse / counter-endorse |
| Type trust is implicit | Type trust is explicit, queryable, federated |
| Types aren't part of the corpus | Types ARE the corpus — linkable, versioned, contested |

This is the mechanism that makes link types into a **social system**
rather than a **taxonomy** — the xanalogical principle applied to the
type vocabulary itself.

## Effort

Core (1-5): ~2 days.
UI badges (6): ~half day.
Federation trust evaluation: +1 day (can defer).
