# Rule 8 Publication Model: Xudanu Design vs. Udanax Gold vs. Nelson's 17 Rules

> This is a living reference document. Update as design evolves.

## Core Principle

**Publication IS read_club.** There is no separate `published` boolean. The act of publication is setting `read_club = public_club`. The act of unpublishing is setting `read_club = owner's club` (revocable) or `read_club = None` (irrevocable).

This follows the Udanax Gold (C++) model where `canBeReadBy(KeyMaster)` is the single gate for all content access.

## 1. Core Publication Mechanism

| Aspect | Nelson's 17 Rules | Udanax Gold (C++) | Xudanu | Rationale |
|--------|-------------------|-------------------|--------|-----------|
| **What is "publication"?** | Rule 8: "Permission to link to a document is explicitly granted by the act of publication." | Setting `read_club = publicClub`. No separate publish operation. | `publish()` sets `read_club = public_club`. `unpublish()` sets `read_club = owner's club`. | **Pro**: Single mechanism, no ambiguity. **Con**: Cannot express "published but only to club X" as a distinct state from "published publicly" — but that's what `set_read_club(someClub)` is for. |
| **Is publication explicit?** | Yes — Rule 8 says "explicitly granted." | **No.** New works default to `InitialReadClub = publicClub` (granmapx.cxx:240). Works are "published" the moment they're created. | **Yes.** New works default to `read_club = owner's club` (private). Owner must call `publish()` to make public. | **Pro**: Aligns with Rule 8's "explicitly granted" language better than C++. **Con**: Breaks from C++ default. |
| **Separate `published` field?** | Not specified. | **No.** Publication = read_club value. | **No.** Publication = read_club value. | Eliminates two-axis ambiguity. Single source of truth. |

## 2. Read Permission Model

| Aspect | Nelson's 17 Rules | Udanax Gold (C++) | Xudanu | Rationale |
|--------|-------------------|-------------------|--------|-----------|
| **Who can read?** | Rule 11: "secure access controls." | `canBeReadBy(km)`: `read_club != NULL && km->hasAuthority(read_club) || canBeEditedBy(km)` (brange2x.cxx:121-136). | Same logic: read_club authority OR edit_club authority. | Follows C++. **Pro**: Editors always have read access. **Con**: If edit_club is public, everyone is effectively a reader. |
| **Default read_club for new works?** | Not specified. | `InitialReadClub = publicClub` (granmapx.cxx:273). Publicly readable by default. | `owner's club`. Private by default. | **Pro**: Secure default. No accidental content exposure. **Con**: Users must publish to share content. **DIFFERS FROM C++: we default to private.** |
| **Default edit_club for new works?** | Not specified. | `InitialEditClub = emptyClub` (granmapx.cxx:241). Nobody can edit by default. | `owner's club`. Owner can edit by default. | **Pro**: Owner can revise immediately. **Con**: Collaborative editing requires explicit edit_club change. **DIFFERS FROM C++: they use emptyClub (nobody), we use owner's club (owner only).** |
| **Can grabber always read?** | Not specified. | Yes — `canRead()` returns true if `canRevise()` (i.e., grabbed by you) (nkernelx.cxx:2290). | Same. If you've grabbed a work, you can read it. | **Pro**: Prevents grab-then-can't-read inconsistency. Grab requires edit_club authority anyway. |

## 3. Irrevocable Unpublish

| Aspect | Nelson's 17 Rules | Udanax Gold (C++) | Xudanu | Rationale |
|--------|-------------------|-------------------|--------|-----------|
| **Can read_club be removed?** | Not specified. | Yes — `removeReadClub()` (nkernelx.cxx:2607-2616). Sets `read_club = NULL`. | Yes — `irrevocably_unpublish()` sets `read_club = None`. | Follows C++ directly. |
| **Is removal irrevocable?** | Not specified. | **Yes.** `setReadClub()` BLASTs `ReadClubIrrevocablyRemoved` if `read_club == NULL` (nkernelx.cxx:2654-2655). No party can ever set it again. | **Yes.** `set_read_club()` errors if `read_club` is `None`. | **Pro**: Prevents "bait and switch." Preserves link graph integrity. **Con**: Permanent — cannot be undone even by owner/admin. |
| **Who can remove read_club?** | Not specified. | Owner only — `CurrentKeyMaster->hasAuthority(this->owner())` (nkernelx.cxx:2612). | Same — owner only. | Follows C++. |
| **Can edit_club also be removed?** | Not specified. | Yes — `removeEditClub()` is also irrevocable (nkernelx.cxx:2596-2604). | Same — `irrevocably_remove_edit_club()` available. | **Pro**: Owner can lock a work permanently (frozen). **Con**: Combined with read_club removal, work becomes completely inert. |
| **Can editors still read after read_club removed?** | Not specified. | Yes — `canBeReadBy` falls through to `canBeEditedBy` (brange2x.cxx:131-132). Comment: "editors are still able to read, if there are any." | Same — editors retain read access. | Follows C++. If edit_club is also removed, nobody can read. |
| **Revocable unpublish?** | Not specified. | **No.** All unpublish is irrevocable. | **Yes — separate operation.** `unpublish()` sets `read_club = owner's club` (revocable). `irrevocably_unpublish()` sets `read_club = None` (permanent). | **DIFFERS FROM C++: we offer both.** **Pro**: Flexibility — soft unpublish for drafts, hard unpublish for withdrawal. **Con**: Two operations increase API surface. Revocable unpublish allows bait-and-switch but only by owner. |
| **Admin override?** | Not specified. | **No.** No admin bypass for `ReadClubIrrevocablyRemoved`. | **No.** Match C++. | Even server operators shouldn't re-publish withdrawn content under the same ID. |

## 4. Enforcement on Read/Query Endpoints

| Endpoint Category | Udanax Gold (C++) | Xudanu | Status |
|--------|-------------------|--------|--------|
| **Read work edition** | `FeWork::edition()` requires `canRead()` (nkernelx.cxx:2523). | Gate `WorkGetEdition` on `can_be_read_by`. | Done |
| **Read revision history** | `canReadHistory()`: `canRead() || historyClub authority` (nkernelx.cxx:3004). | Gate `WorkFetchRevision` on `can_read()`. Defer `history_club` to later. | Pending |
| **Transclusion queries** | Results filtered by `canBeReadBy` (tcludex.cxx:1037, brange3x.cxx:495). | Filter all transclusion results. | Partially done |
| **Link visibility** | Not explicitly gated in C++ reviewed. | Gate on readability of both origin and destination. | Done |
| **Endorsement visibility** | `visibleEndorsements` only from readable works (brange3x.cxx:495). | Gate on `can_be_read_by`. | Pending |
| **Content search** | Results filtered by permissions. | Filter `FindTextTranscluders` results. | Done |
| **FindTranscluders / FindWorksForContent** | Filtered by permissions. | Gate on readability. | Pending |
| **EditionGet (standalone)** | Not explicitly gated. | Needs readability check. | Pending |
| **LinkUpdate / LinkDelete** | Requires edit permission. | Gate on edit permission of linked works. | Pending |

## 5. Federation and Cross-Server

| Aspect | Xudanu | Rationale |
|--------|--------|-----------|
| **Federated content sync** | Only sync works where `read_club == public_club`. Never sync unpublished/private works. | No content leakage via federation. |
| **Federated transclusion queries** | Only return results from works readable by requesting peer's public identity. | Same reasoning. |

## 6. Club Owner Controls

| Aspect | Udanax Gold (C++) | Xudanu | Rationale |
|--------|-------------------|--------|-----------|
| **Club default for new works** | `InitialReadClub` is a server-wide fluid (granmapx.cxx:240, 3189). All new works get same initial read_club. | **Per-club `default_read_club`** on Club struct. Members creating works inherit their club's default. | **DIFFERS FROM C++: per-club instead of server-wide.** **Pro**: Club owners control their members' publication policy. |
| **Who can change default_read_club?** | Server-wide, set during initialization. | Club owner only (signature authority). | Follows C++ principle that owner controls access policy. |

## 7. Content Fingerprint Leakage

Content is content-addressed. If identical text appears in a published work and an unpublished work, an attacker can infer the unpublished work contains that text (because the content fingerprint matches). The attacker cannot see the work itself, only infer content overlap. This is inherent to content-addressing and cannot be fully prevented without abandoning content fingerprints.

Mitigation: filter all query results by `can_be_read_by`. The fingerprint index itself is not gated — only the results returned from it.

## Summary of Differences from Udanax Gold

| # | Xudanu Choice | C++ Default | Why We Diverge |
|---|---|---|---|
| 1 | New works default to `read_club = owner's club` (private) | `read_club = publicClub` (public) | Security-conscious default. Aligns better with Rule 8 "explicitly granted." |
| 2 | New works default to `edit_club = owner's club` | `edit_club = emptyClub` (nobody) | C++ prevents editing entirely by default; we allow owner to edit. More usable. |
| 3 | Offer both revocable `unpublish()` and irrevocable `irrevocably_unpublish()` | All unpublish is irrevocable | Flexibility for owners. Irrevocable still available for permanent withdrawal. |
| 4 | Per-club `default_read_club` | Server-wide `InitialReadClub` fluid | Club owners control their members' default publication policy. More granular control. |
| 5 | Gate `LinkGet`/`LinkListForWork` on readability | Not explicitly gated in C++ | Prevents link metadata from leaking work existence. |
| 6 | Federation sync gates on readability | Federation not implemented in C++ | Prevents cross-server content leakage by design. |
| 7 | `history_club` for revision access (deferred) | `canReadHistory()` with separate `historyClub` field | Match C++ design. Defer to avoid scope creep — use `canRead()` as gate for now. |
