# Durability Review — content-loss scenarios

**Date:** October 2, 2026 (after the five-lost-works incident)
**Updated:** October 2, 2026 (same day — full gap remediation)
**Trigger:** demo works vanished after `kill -9` restarts during a
wedged server. Root cause: `work_create` had no WAL entry — creations
were protected only by the async checkpoint.

## Model

The durability contract is: **every user-content mutation writes a
WAL entry (fsync) before the op acks; checkpoints capture state and
truncate the WAL.** A hard kill replays the WAL on top of the last
checkpoint. Anything not in the WAL exists only in memory until the
next async checkpoint (~30ms normally, unbounded during a runtime
wedge — see the LLM dispatch lock fix, same day).

## Covered

| Surface | WAL ops | Notes |
|---|---|---|
| Work creation | `work_create` | id + owner + title + text; fixed-id grand-map registration |
| Revisions | `work_revise` | full WorkSnapshot per revision; revision-numbered replay is idempotent. Covers the whole funnel: work_revise, element_insert/remove_transclusion, set_text, save-and-release |
| Titles / visibility | `work_set_title`, `work_publish` | owner-private until publish replay |
| Archive | `work_archive`, `work_unarchive` | symmetric — final state wins |
| Text edits | `text_edit` | pre-existing (CRDT path) |
| Links | `create_link` (+ `author_club` seed), `link_add_end`, `link_set_types`, `link_set_responds_to`, `link_delete` | deletions replay (no resurrection) |
| Link end attachments | `link_end_add_attachment`, `link_end_remove_attachment` | pre-existing (append + replay) — earlier draft of this doc wrongly listed as a gap |
| Reputation | `link_endorse`, `link_unendorse` | author auto-seed rides create_link |
| Identity / clubs | `club_upsert` | full club state at every mutation: creation (personal + oauth), password set/clear, email, verify, member add/remove, admin passphrase. Signup-then-crash keeps the account AND its password (tested by login after replay) |
| Regions | rides `club_upsert` | region_create + region_insert_between journal the club |
| Federation | `federation_state` | full FederationSnapshot at: set_federation_config, register_peer_key, bootstrap_init, membership endorse/leave/remove. Runtime-learned state (remote origins, liveness) re-converges from peers — deliberately not journaled |
| Compounds | set/insert/remove/move element | pre-existing |
| Trails | create/delete/rename/stops | pre-existing |
| Annotations | create/delete | pre-existing |
| Stars / pins | star/unstar, pin/unpin | pre-existing |
| Detectors | own fsync'd sidecar | save-on-every-mutation (detectors.json, tmp+fsync+rename) — earlier draft wrongly listed as a gap |

Both restore paths (chunk-store and file-snapshot) open AND replay
the WAL.

## Remaining gaps (accepted, with reasons)

1. **CRDT hot-path edits between checkpoints** — the collaborative
   editor's ops ride their own sync; a crash can lose the last
   in-flight keystrokes (not yet committed via revise). Accepted:
   collaboration protocol resyncs from peers/session buffers.
2. **Federation runtime-learned state** (remote origins, peer
   liveness) — re-converges from peers after reconnect; journaling
   would churn the WAL on every sync round.
3. **Quarantine decisions** — rare, operator-visible in logs.

## Operational rules

- Restarts use SIGTERM (graceful checkpoint). SIGKILL is now
  lossless for the covered surface but remains unsupported as an
  ops practice.
- The runtime-wedge class (sync dispatch holding the state lock
  across a long await) starves async checkpoints — the LLM dispatch
  is routed lock-free; any future long-await op must do the same.
- New mutation ops must add their WAL append + idempotent replay +
  a line in the unclean-drop test's checklist pattern. A coverage
  audit (grep for mutations without `self.wal.append` /
  `wal_journal_*`) is worth wiring into CI later.

## Tests

- `persistence_work_create_survives_unclean_drop`: creates, titles,
  publishes, revises, types a link, sets responds_to, deletes a
  link, endorses, archives, unarchives — drops the server with NO
  checkpoint — everything replays, deletions stay dead, replay is
  idempotent across checkpoint cycles.
- `persistence_club_identity_survives_unclean_drop`: signup +
  password + owned work survive; the password still logs in after
  replay; idempotent across checkpoint cycles.
