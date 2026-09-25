# FR-80 — Detectors: watching the literature

**Status:** in progress (September 2026)
**Heritage:** Miller, "The Open Society and Its Media" (Extropy 12, 1994;
reprinted in _The Transhumanist Reader_, 2013) — the fourth fundamental
feature: *"One can post a revision detector to find out when things are
edited… Link detectors are a way of finding out when new links are made
to existing material."*

## Why

Detectors are Gold's answer to "how do you keep up with a literature
that changes." They turn reading from polling into subscription:

- A **link detector** on a work fires when a new link lands on it —
  optionally filtered by link type. Ruth's detector watched for
  `requirement`-type links onto her technical plan; Dan's titanalum
  requirement reached her without a phone call (the WidgetPerfect saga).
- A **revision detector** fires when the work gains a new revision;
  paired with compare it enables Miller's "differential reading" —
  reading only what changed since you last looked.

Miller's unification: email is the special case where a canonical point
(one address) has a link detector on it. Canonical documents become
meeting places; two disjoint discussions find each other when anyone
links them and both detectors collect the link.

## Scope for v1 (production)

Pull model, work-level, persisted. **The match is a predicate object,
not a single value** — Gold's detectors could match only one type or
one fill value each (FeFillDetector: one exact element; Miller's link
detectors: one type), which is the limitation to avoid on the wire.
The fossil engine's `RecorderQuery` already carries the composable
shape (kind, region, authority_clubs, endorsement_filter); v1 exposes
the work-level subset of the same idea:

- `detector_create { work_id, kind: "links"|"revisions", match?: {
      link_types?: [type_id],      // empty/absent = all types (a SET,
                                   // never a single value)
      direction?: "in"|"out"|"any",
      from_clubs?: [club_id],      // only links by these authors
  } }`
  — registered to the caller's club; `match` only meaningful for
  `kind: "links"`.
- `detector_list {}` — the caller's detectors, each with hits collected
  since ack; `unread` count per detector.
- `detector_ack { detector_id }` — mark hits read (kept, not deleted:
  the collection is the record).
- `detector_delete { detector_id }` — stop watching (owner only).

Hits: `{ at, link_id?, by_club?, revision? }`. For link detectors the
type match is evaluated at `link_set_types` time (types are applied
after creation); for revision detectors the hook is the revision-commit
path (`work_save_and_release`, `work_revise`).

The `match` object is additive: span-level (`region`), authority, and
endorsement fields arrive with the fossil-engine integration without a
wire break — clients treat unknown fields as "no additional filter".

## Deliberately later

- **Span-level detectors** ("watch this passage, not the whole work") —
  the fossil/recorder engine (`recorder_plant`, backfollow hoist) is
  the substrate; v1's work-level registry deliberately does not touch
  it.
- **Live push** — v1 collects; the client polls. The notification
  system can carry detector events later.
- **Cross-server detectors** — a detector on a remote work requires
  federation event feed (FR-6 territory).
- **Endorsement-weighted ordering** of collected links (Miller's
  reputation filtering sorts the collection, not just admits it).

## UX

- Links panel: **Watch** — "notify me about new links to this work"
  (type filter when the work has custom types in play).
- More ▸ Detectors: the list — work, kind, type filter, unread badge,
  ack on read.
- The top-bar badge counts unread hits; polling every 30s while open.

## Exit criteria

- [ ] link detector with type filter: matching link → hit; non-matching → none
- [ ] revision detector: edit → hit with revision number
- [ ] ack marks read; hits persist across restart (checkpoint sidecar)
- [ ] only the owner's club sees the detector and its hits
- [ ] WidgetPerfect room seeded on xudanu.com: story works, the
      requirement link, live detectors with the saga's hits already
      collected

## Heritage note

Miller's eight features (links, transclusion, versioning, detectors,
permissions, reputation filtering, multimedia, external transclusion)
all exist in xudanu in some form. Detectors were the last without a
user face — this FR completes the set.
