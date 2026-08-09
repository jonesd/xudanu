# FR Status Tracker

Single source of truth for feature requirements, implementation status,
and code/test mapping. Updated with each commit.

**Legend:** ✅ Done · 🔨 In Progress · 📋 Planned · ❌ Not Started

---

## Core System

| FR | Feature | Status | Key Files | Tests |
|----|---------|--------|-----------|-------|
| FR-1 | Identity (clubs, sessions) | ✅ | identity.rs, session.rs, club.rs | integration: session tests |
| FR-2 | Verification (signing) | ✅ | crypto/sign.rs, crypto/club_keys.rs | integration: crypto_sign_and_verify |
| FR-3 | Cluster federation (optional) | ✅ | federation.rs, federation_active.rs, federation_handler.rs | integration: federation tests |
| FR-4 | Persistence | ✅ | persist/chunk_store.rs, persist/wal.rs, persist/manifest.rs | integration: chunk_store_persistence |
| FR-5 | Space algebra (O-tree) | ✅ | space/, edition/orgl.rs, edition/region.rs | lib: space trait tests |
| FR-8 | O-tree CRDT | ✅ | server/otree_crdt.rs | integration: crdt tests |
| FR-9 | Bilateral links | ✅ | edition/links.rs | integration: link tests |

## Content Features

| FR | Feature | Status | Key Files | Tests |
|----|---------|--------|-----------|-------|
| FR-11 | Annotations | ✅ | server.rs (annotation CRUD) | integration: annotation tests |
| FR-12 | Document comparison | ✅ | components/ComparePanel.tsx | frontend: compare.test.ts |
| FR-13 | Endorsement | ✅ | edition/endorsement.rs | integration: endorsement tests |
| FR-14 | Attribution/provenance | ✅ | edition/provenance.rs, transport/attribution_log.rs | integration: attribution tests |
| FR-15 | Content matching | ✅ | server/source_matcher.rs | integration: content_match tests |
| FR-16 | Three-way merge | ✅ | edition/three_way.rs | integration: merge tests |
| FR-17 | Versioning | ✅ | server.rs (revisions), persist manifest | integration: revision tests |
| FR-18 | Import (EPUB) | ✅ | dispatch.rs (import_epub) | integration: import tests |
| FR-19 | Marginalia | ✅ | server.rs (annotations) | integration: annotation tests |

## UI Features

| FR | Feature | Status | Key Files | Tests |
|----|---------|--------|-----------|-------|
| FR-20 | Trails | ✅ | server.rs (trails), TrailsPanel.tsx | integration: trail tests |
| FR-21 | Document graph | ✅ | graph-scoring.ts, DocumentMapPanel.tsx | frontend: graph-scoring.test.ts |
| FR-22 | Concepts/categorization | ✅ | server.rs (work_kind), concepts-seed.ts | integration: concept tests |
| FR-23 | Revisions | ✅ | RevisionTimeline.tsx, server.rs | integration: revision tests |
| FR-24 | Transcopyright/licensing | ✅ | server.rs (work_license), FR-24-transcopyright.md | integration: license tests |
| FR-25 | Trail links | ✅ | server.rs (trail_add_stop) | integration: trail link tests |
| FR-26 | Content-addressed transclusion | ✅ | edition/transclusion.rs, range_element.rs | integration: transclusion tests |
| FR-27 | Link filtering | ✅ | link-markers.ts, ConnectionsSection.tsx | frontend: link-filter.test.ts, link-markers.test.ts |
| FR-30 | Compound builder | ✅ | CompoundBuilder.tsx | frontend: compound-panel.test.tsx |

## Cross-Server (FR-31)

| FR | Feature | Status | Key Files | Tests |
|----|---------|--------|-----------|-------|
| 31.1 | Server directory | ✅ | server_directory.rs, dispatch.rs | tests_signed_introductions |
| 31.2 | Server discovery (introductions) | ✅ | server.rs:fetch_remote_introductions | test-3node.cjs |
| 31.3 | Browse remote works | ✅ | server.rs:fetch_remote_works_list | test-3node.cjs |
| 31.4 | View remote work | ✅ | server.rs:fetch_remote_work | adversarial tests |
| 31.5 | Copy document (import) | ✅ | WorkspaceShell.tsx (Copy button) | test-3node.cjs |
| 31.6 | Transclude passage (MVP) | ✅ | WorkspaceShell.tsx (Insert button) | manual |
| 31.7 | Cross-server links | ✅ | server.rs:add_cross_server_link | test-3node.cjs |
| 31.8 | Federated search | ✅ | server.rs:federated_search | test-3node.cjs |
| 31.9 | Backend proxy (browse + view) | ✅ | server.rs, transport/codec.rs | adversarial tests |
| 31.10 | Availability tracking | ✅ | server_directory.rs (fields) | manual |

## Security (FR-32)

| FR | Feature | Status | Key Files | Tests |
|----|---------|--------|-----------|-------|
| 32.1 | SSRF prevention (lexical) | ✅ | server.rs:is_ssrf_address | tests_ssrf_guard |
| 32.2 | SSRF prevention (DNS resolution) | ✅ | server.rs:resolve_and_verify_host | tests_ssrf_guard |
| 32.3 | Ed25519 signature enforcement | ✅ | server.rs:verify_signed_response | tests_signature_enforcement |
| 32.4 | TOFU key pinning | ✅ | server.rs (pinned_key) | tests_signature_enforcement |
| 32.5 | Key rotation (single hop) | ✅ | server.rs:verify_key_rotation | tests_key_rotation |
| 32.6 | Key rotation (multi-hop chain) | ✅ | server.rs:verify_rotation_chain | tests_key_rotation |
| 32.7 | Rotation replay protection | ✅ | server.rs:verify_one_hop | tests_key_rotation |
| 32.8 | Quarantine enforcement | ✅ | server.rs:handle_security_alert | tests_security_tracker |
| 32.9 | Brute-force detection | ✅ | server.rs:CrossServerSecurityTracker | tests_security_tracker |
| 32.10 | Rate limiting (rotation) | ✅ | server.rs:check_rotation_rate | tests_security_tracker |
| 32.11 | Security headers (CSP, HSTS, etc.) | ✅ | transport/handler.rs:security_headers_middleware | ZAP scan |
| 32.12 | Frontend sanitize module | ✅ | security/remote-content.ts | remote-content-security.test.ts |
| 32.13 | Property-based testing | ✅ | server.rs:tests_crypto_property | proptest (12 properties) |
| 32.14 | Fuzz testing | ✅ | fuzz/fuzz_targets/ | tests_fuzz_equivalent |
| 32.15 | Adversarial network tests | ✅ | tests/integration.rs | 5 attack scenarios |

## Identity (FR-33)

| FR | Feature | Status | Key Files | Tests |
|----|---------|--------|-----------|-------|
| 33.1 | Identity attestation (fetch) | ✅ | server.rs:fetch_remote_identity | manual |
| 33.2 | Public identity endpoint | ✅ | handler.rs:public_identity_handler | manual |
| 33.3 | Identity attestation storage | ✅ | server.rs:identity_attestations | manual |
| 33.4 | Identity resolution by key | ✅ | server.rs:resolve_identity_by_key | manual |
| 33.5 | Attribution display from key | 🔨 | WorkspaceShell.tsx (key hash shown) | needs wiring to attestation |

## Planned / Not Started

| FR | Feature | Status | Notes |
|----|---------|--------|-------|
| 34 | Live transclusion (element-level) | 📋 | Phase 4: ghost works or new element type |
| 35 | Self-signed TLS + TOFU cert pinning | 📋 | For servers without domain names |
| 36 | Cross-server edit permission | 📋 | All-or-nothing for now; future: fine-grained |
| 37 | Reading history per remote server | 📋 | Track viewed remote works |
| 38 | Domain age / trust scoring | 📋 | first_seen + successful_resolutions as trust signal |
| 39 | Word add-in (provenance capture) | 📋 | Bridge from Word to Xudanu |
| 40 | Let's Encrypt auto-cert | 📋 | Via Caddy (done) or built-in ACME |

## Test Summary

| Suite | Count | Status |
|-------|-------|--------|
| Rust lib tests | 2865 | ✅ all pass |
| Rust integration tests | 280 | ✅ all pass |
| Frontend tests | 686 pass + 12 skip | ✅ (skipped: browse mock tests, replaced by real server) |
| Property-based tests | 12 (256 cases each) | ✅ |
| Fuzz-equivalent tests | 24 | ✅ |
| Adversarial tests | 5 | ✅ |
| Security tracker tests | 9 | ✅ |
| 3-node Docker test | 13/15 pass | ⚠️ 2 fail (backlink POST blocks) |
| **Total** | **~3894** | |

## FR Numbering Convention

- FR-1 through FR-30: Original features (pre-cross-server)
- FR-31: Cross-server document sharing
- FR-32: Security model
- FR-33: Identity attestation
- FR-34+: Future features

## Commit Convention

```
feat(FR-31.4): description
fix(FR-32.3): description
test(FR-31.8): description
docs(FR-33): description
```
