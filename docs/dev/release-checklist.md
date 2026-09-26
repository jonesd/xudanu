# Release Checklist

The controlled release process. Every release follows this order;
every release's notes carry the three guarantees and the exact
content-set diff.

## The Three Guarantees (constitutional)

1. **Engine releases never touch the docuverse.** Upgrades change the
   engine only. The data directory (`/var/lib/xudanu` or equivalent)
   is never modified, migrated, or cleared by a release. Deploy
   scripts, tarballs, and CI assert this.

2. **Seeded content becomes the user's on landing.** Core-set works
   (the demo, Getting Started) are ordinary published content. An
   upgrade never re-seeds, updates, or removes them — newer examples
   arrive only via the deliberate `restore_examples` admin op (pull,
   never push). If a user edited a seeded work, it is theirs.

3. **Confirm-before-touch.** Any operation that can modify or remove
   existing works (curated reset, restore-with-collision, refresh
   system definitions) must: dry-run and list what would change,
   require explicit `--confirm`, and default to skip for anything
   the user has modified. Nothing silent, nothing surprising.

## Release Order

```
1. Bump version (Cargo.toml, Cargo.lock, package.json, deploy-aws.sh)
2. Commit + tag vX.Y.Z
3. Push to both remotes (origin: Yubikey; github: PAT + tag triggers CI)
4. Wait for CI green (all platforms; the fresh-boot smoke test runs)
5. Generate release notes: scripts/release-notes.sh vX.Y-1..vX.Y
6. If curated content changed: run scripts/reset-to-curated.mjs --confirm
   against the museum (dry-run first — review the REVIEW list)
7. Deploy: ssh to the box, VERSION=vX.Y.Z bash deploy-aws.sh
8. Verify: /health, /api/public/tumbler/vectors, key rooms load
9. Push any remaining commits to origin
```

## Content-Set Manifest

`content/sets/manifest.json` defines what seeders, at what versions,
constitute the curated demo environment. When a seeder's content
changes, bump its version in the manifest; the release notes carry
the diff (e.g. "gallery v2→v3, +widgetperfect v1").

The `content_sets` op answers "what sets, what versions, is this
server running?" — release verification step 8 checks it.

## Shipped-Surface Inventory

Mechanisms present in every release whether or not the curated demos
exercise them:

| Surface | Status | Notes |
|---|---|---|
| Regions (visibility partitioning) | operator mechanism | Admin-gated, club-prefixed, no user UI. The operator lane — deliberately no user-facing controls. |
| Federation / cluster | opt-in | `--peer` flags + `--pin-members`; default off; standalone servers unaffected |
| OTS anchoring (FR-60) | off by default | `ots_anchor_enabled: false` (single-player no-outbound stance); business tier should enable |
| Lattice shadows | off by default | Admin opt-in |
| Detectors, endorsements, shadows | on, demoed | Museum rooms demonstrate all three |
| CRDT collaboration | on | Active whenever multiple sessions edit the same work |
| Micropayments (FR-24) | not implemented | Transcopyright license metadata shipped; billing absent |

## CI Guardrails

- **Fresh-boot smoke test**: release binary starts on a temp dir;
  work count must equal the core set exactly (demo + Getting Started
  = 2 works). Catches accidental auto-seeding forever.
- **Tarball inventory assertion**: package step asserts binaries +
  dist + LICENSE/NOTICE, nothing else. No data dirs, no seed scripts,
  no internal content.
- **Pre-push gauntlet**: cargo check + clippy + fmt + frontend tests
  + tsc. All must pass before any push.
