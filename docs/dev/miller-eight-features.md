# Miller's eight features — status and completion plan

**Source:** Mark S. Miller with Tribble, Pandya, Stiegler, "The Open
Society and Its Media" (Extropy 12, 1994; reprinted in _The
Transhumanist Reader_, 2013). The running Gold system's feature list:
four fundamentals (links, transclusion, versioning, detectors) plus
four more (permissions, reputation filtering, multimedia, external
transclusion).

**Presentation copy:** `docs/gold-heritage.html#miller-eight` (the
table visitors see). This file is the working tracker — statuses,
gaps, and what completion takes. Keep both in sync when a status
moves.

## Status (September 2026)

| # | Feature | Status | Where it lives |
|---|---|---|---|
| 1 | Hyperlinks (fine-grained, bidirectional, extrinsic) | DONE | typed links, connection-is-free, Links panel |
| 2 | Transclusion | DONE | live windows, compound builder, compare beams |
| 3 | Versioning (differential reading) | DONE | revision DAG, compare, timeline |
| 4 | Detectors | DONE | FR-80 (`docs/dev/FR-80-detectors.md`), WidgetPerfect room |
| 5 | Permissions (clubs) | PARTIAL | clubs/locks shipped; recursive meta-levels simplified |
| 6 | Reputation-based filtering | PARTIAL | endorsement ops + RecorderQuery fields; no user-facing ordering |
| 7 | Multimedia | PARTIAL | images only |
| 8 | External transclusion | IN PROGRESS | FR-79 stage 1 (web shadows) shipped; overlay = stage 2 |

## Can we complete the remaining four? Yes — scoped:

### 5. Permissions: the bcc/cc meta-level

**The 1994 semantics:** a bcc club's member LIST is itself
permissioned (Bob-only); a cc list is self-reading (members see
membership). Meta-levels grow on demand, avoiding infinite regress
via self-reading/self-editing clubs.

**Our gap:** roster visibility is hardcoded login-gated
(`identity.rs` club_roster), not club-governed.

**Completion (a day, honest scope):** add `roster_read_club:
Option<BeId>` to Club — `None` = members-only (today's de facto),
`Some(club)` = that club's members may view, `Some(self)` =
self-reading (the cc case). Gate `club_roster`/`club_members` by it;
add an owner op to set it. Persistence rides the existing club
snapshot. The full "meta-levels to any degree" recursion is a
rabbit-hole; one governed level covers Miller's bcc/cc examples
exactly. **Feasible: yes.**

### 6. Reputation filtering: endorsement ordering, surfaced

**The 1994 semantics:** links endorsed as worth reading; filter by
endorser and type; reputable guides rise above the swamp.

**Our gap:** `link_endorse`/`link_endorsements` ops exist,
`RecorderQuery.endorsement_filter` exists in the engine — nothing
user-facing orders or filters by them.

**Completion (days):**
- Links panel: sort/filter by endorsement count; "endorsed by" chips
- Detector collections: order hits by endorsements (Miller's
  reputation filter sorting the collection, not just admitting it)
- The release-notes-as-endorsed-pages pattern (each release a work,
  the xudanu team endorses it) as the first real corpus
- Engine side is done; this is client + small server sort fields
**Feasible: yes — closest to done of the four.**

### 7. Multimedia

**The 1994 semantics:** "none of it is specific to text" — links,
transclusions, compares on sound, drawings, video, even
block-compressed or encrypted.

**Our gap:** images only; audio/video/drawings absent.

**Honest assessment: the one genuinely large item.** Time-based span
addressing (a link into seconds 31–47 of an audio work) is the deep
piece — our space algebra can express it (SequenceSpace positions
are arbitrary integers; time is a sequence), but the editor,
marker rendering, and compare semantics all assume text today.
**Scoped first step (feasible):** make any blob a first-class
linkable work (WorkKind::Audio/Video with whole-work links) —
connects the existing blob store to the link model without time-span
granularity. Full fine-grained media is a quarter-scale project.
**Feasible: partially — whole-media now, spans later, honestly never
"done" the way the others can be.**

### 8. External transclusion: the overlay

**The 1994 semantics:** "follow a link from a WAIS document into a
Lexis document, even though neither system has any notion that such
a link exists."

**Our gap:** stage 1 shipped (any public page → content-hashed
shadow work, linkable). Stage 2 — seeing Xudanu marks ON the live
page — is the browser extension.

**Completion (the agreed next initiative):** MV3 extension skeleton
→ resolve current URL's shadow → render marks from links onto it →
the detector+overlay loop demo (site owner watches their page's
shadow; a reader marks it; the mark lands in the collection).
**Feasible: yes — planned, sequenced after v1.14.4 ships.**

## Sequencing proposal

1. **Endorsement surfacing** (#6) — days, engine done, feeds
   release-notes pattern
2. **Club roster meta-level** (#5) — a day, closes the bcc/cc story
3. **Overlay stage 2** (#8) — the next initiative (already agreed)
4. **Whole-media linkable blobs** (#7 scoped) — when it suits;
   fine-grained media spans = long-term, honestly labeled

Result: seven of eight fully DONE, multimedia DONE-with-scope —
and the heritage page table updates as each lands.
