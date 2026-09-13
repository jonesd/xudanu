# FR-67: Work Duplication — "make this page yours"

Status: **IN PROGRESS** (2026-09-13). Origin: the links-workshop
walkthrough — the user copied the workshop text to gain edit rights,
and the links did not travel. Duplication with connections intact
turns every teaching document into a take-home lab.

## Semantics

A duplicate is a fully independent new work that happens to contain
the same content and an equivalent connection graph:

1. **Edition**: current edition copied verbatim — text AND element
  /span provenance. Authorship travels with content (the original
   authors keep credit; the duplicator owns the copy, not the
   byline). Revision history is NOT copied: the duplicate is a
   snapshot at revision 0.
2. **Identity**: fresh be_id, fresh tumbler stamp (creator's server
   identity; region-prefixed path if the session carries a region
   context) — identical rules to `create_work`.
3. **Links**: every link with at least one end (attachment) whose
   work is the source is cloned. Ends attached to the source remap
   to the duplicate at identical positions (text is identical, so
   spans are their own remap). Ends attached to other works are left
   untouched (the Companions remain the Companions). Types, end
   names, gathered sets, and link attachments are cloned wholesale.
4. **Comment-on-link**: an attachment that references a link being
   cloned is remapped to the cloned link; attachments to links
   outside the cloned set keep pointing at the originals.
5. **Independence (the no-funky-action guarantee)**: after
   duplication there is NO shared state. Deleting or retyping a
   cloned link never affects the original's; editing the original's
   links never affects the copy; the original work and its link set
   are not modified by the operation in any way.

## Authorization

Read permission on the source (you can duplicate what you can
read); creation rights apply as usual; the duplicate is owned by
the duplicating session's club; publish is the user's later choice.

## Wire

`work_duplicate` (0x0364) `{ work_id, title? }` → `{ work_id }` of
the copy.

## UI

"Duplicate" affordance (Settings panel v1) with navigation to the
copy. The course/workshop onboarding gesture: "Make this page
yours."

## Tests (the solidity proof)

- Full-shape clone: outgoing typed, multi-ended custom end names,
  gathered 3-passage end, comment-on-link chaining — all present on
  the copy, ends remapped only where source
- Independence both directions (delete/edit cloned vs original)
- Original byte-identical: revision count, links, WAL untouched
- Span provenance preserved (original author credit retained)
- Comment-on-link remap targets the cloned link
- Authorization: unreadable source denied
- Region context: duplicate allocates under the region prefix
