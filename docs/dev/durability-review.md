# Durability Review — content-loss scenarios

**Date:** October 2, 2026 (after the five-lost-works incident)
**Trigger:** demo works vanished after `kill -9` restarts during a
wedged server. Root cause: `work_create` had no WAL entry — creations
were protected only by the async checkpoint. Fixed the same day; this
review enumerates what else can lose user content.

## Model

The durability contract is: **every user-content mutation writes a
WAL entry (fsync) before the op acks; checkpoints capture state and
truncate the WAL.** A hard kill replays the WAL on top of the last
checkpoint. Anything not in the WAL exists only in memory until the
next async checkpoint (~30ms normally, unbounded during a runtime
wedge — see the LLM dispatch lock fix, same day).

## Covered (as of this review)

| Surface | WAL ops | Notes |
|---|---|---|
| Work creation | `work_create` | id + owner + title + text; fixed-id grand-map registration |
| Titles / visibility | `work_set_title`, `work_publish` | owner-private until publish replay |
| Text edits | `text_edit` | pre-existing |
| Links | `create_link` (+ `author_club` seed), `link_add_end`, `link_set_types`, `link_set_responds_to`, `link_delete` | deletions replay (no resurrection) |
| Reputation | `link_endorse`, `link_unendorse` | author auto-seed rides create_link |
| Archive | `work_archive` | reversals need `restore`; archive itself journals |
| Compounds | set/insert/remove/move element | pre-existing |
| Trails | create/delete/rename/stops | pre-existing |
| Annotations | create/delete | pre-existing |
| Stars / pins | star/unstar, pin/unpin | pre-existing |

Both restore paths (chunk-store and file-snapshot) now open AND
replay the WAL (the file path previously did neither — fixed).

## Known gaps (follow-up work, priority order)

1. **Club / identity creation — HIGH.** `club_create_personal`,
   password set/change: checkpoint-only. A crash after signup loses
   the account; works created under it replay with `owner=<missing
   club>` — orphaned. This is the user-lockout scenario.
2. **Link end attachments — MEDIUM.** `link_end_add_attachment` /
   `remove` (FR-40 multi-attachment end-sets) are checkpoint-only.
   Attachment changes to an end-set are lost; the link itself
   survives with its last-checkpoint shape.
3. **Detectors — MEDIUM.** `detector_create`/`delete`/`ack`
   checkpoint-only. User watch configuration silently reverts.
4. **Work restore (un-archive) — LOW.** Archive journals; the
   un-archive path should be checked for symmetry.
5. **Region / federation membership ops — LOW.** Server
   configuration; single-player deployments unaffected.
6. **Element-level transclusion edits — REVIEW.**
   `element_insert` / `element_remove_transclusion` may route
   through compound WAL ops — needs a dedicated audit pass to
   confirm no uncovered path (the debug-assert suite catches read
   gaps, not durability gaps).

## Operational rules

- Restarts use SIGTERM (graceful checkpoint). SIGKILL is now
  lossless for the covered surface but remains unsupported as an
  ops practice.
- The runtime-wedge class (sync dispatch holding the state lock
  across a long await) starves async checkpoints — the LLM dispatch
  is routed lock-free; any future long-await op must do the same.
- New mutation ops must add their WAL append + idempotent replay +
  a line in `persistence_work_create_survives_unclean_drop`'s
  checklist pattern. The gauntlet does not enforce this yet — a
  coverage audit (grep for `pub fn` mutations without
  `self.wal.append`) is worth wiring into CI later.

## Test

`persistence_work_create_survives_unclean_drop` (integration):
creates, titles, publishes, types a link, sets responds_to, deletes
a link, endorses, archives — drops the server with NO checkpoint —
asserts everything replays, deletions stay dead, and replay is
idempotent across checkpoint cycles.
