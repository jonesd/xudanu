# Xudanu Demo Flow — The Xanalogical Vision in 5 Minutes

## The Story

A small network of 3 servers (Alice, Bob, Carol). Each has content.
Content flows between them. Links survive edits. Provenance catches
tampering. The docuverse, working.

---

## Act 1: Discovery (30 seconds)

**What they see:** Three servers in a network map. Alice's server has
an essay with an image. Bob's server has commentary. Carol's server is
empty — she just joined.

**The point:** Independent servers, each with their own identity,
keypair, and namespace. No central authority. The server directory
shows who's trusted.

**Xanalogical concept:** Independent, sovereign servers. No platform
owns your content.

---

## Act 2: Transclusion (60 seconds)

**What they see:** Carol opens the compound builder. She searches for
content across the network. She finds a passage from Alice's essay and
an image from Alice's server. She places both into her document. They
render inline — the text flows naturally, the image appears with
attribution.

**The point:** Content from another server, rendered inline in your
document, with cryptographic attribution. Not a copy — a live
reference.

**Xanalogical concept:** Transclusion. The same content, appearing in
multiple contexts, with one source of truth.

---

## Act 3: Provenance Chain (45 seconds)

**What they see:** Carol clicks the transcluded passage. A panel opens
showing the full provenance chain:
- Original author: Alice (ed25519 public key, verified)
- Source server: alice.local (server namespace ID, verified)
- Content hash: BLAKE3 (matches)
- Timestamp: when it was placed
- License: CC-BY

**The point:** Every piece of content has a cryptographic trail. You
can verify who wrote it, when, and that it hasn't been altered.

**Xanalogical concept:** Unbreakable attribution. Authors are
cryptographically linked to their work.

---

## Act 4: Unbreakable Links (60 seconds)

**What they see:** Bob created a typed link (Reference) from his
commentary to Alice's essay last week. Now Alice edits her essay — she
rewrites a paragraph, deletes a sentence, adds a new one.

Bob's link doesn't break. The span migration adjusts the link anchor
to track the content through the edit. When Bob opens his document,
the link still points to the right passage.

**The point:** Links survive edits. The system tracks content through
changes automatically. No more broken links.

**Xanalogical concept:** Unbreakable links. The fundamental promise of
Xanadu — connections between documents that cannot be severed.

---

## Act 5: Tamper Detection (45 seconds)

**What they see:** Now something goes wrong. An attacker (or a buggy
server) replaces Alice's essay content but keeps the same tumbler
address. Carol's transclusion detects the mismatch:
- "Source content has changed" badge appears
- BLAKE3 hash verification fails
- The transclusion shows the original content (cached), with a warning
- The provenance chain shows the mismatch

**The point:** The system detects tampering automatically. Content
hashes are verified on every access. You can't silently substitute
content.

**Xanalogical concept:** Content integrity. The docuverse is
tamper-evident. Every transclusion is cryptographically verified.

---

## Act 6: Backlinks (30 seconds)

**What they see:** Alice looks at her essay. In the connections panel,
she sees:
- Bob linked to her essay (Reference type, with excerpt)
- Carol transcluded a passage (with provenance)
- The backlinks appeared automatically — Alice didn't have to do
  anything

**The point:** When someone links to or transcludes your work, you
know about it. The connections are bidirectional and automatic.

**Xanalogical concept:** The docuverse is a graph. Every connection is
visible from both ends.

---

## Act 7: When Things Go Wrong — The Failure Paths

These are the scenarios that prove the system's value. Provenance
isn't decoration — it's the safety net.

### 7a: Source Edits — "Source Changed" (30 seconds)

**What they see:** Alice legitimately edits her essay — rewrites a
paragraph that Carol transcluded. On Carol's server, the transclusion
badge changes to "source changed" with a warning indicator. Carol can
see the original (cached) version and the current version side by side.

**The point:** Transclusions track their source. When the source
changes, you know immediately. You can update or keep the original.

### 7b: Tamper Detection — Hash Mismatch (30 seconds)

**What they see:** A malicious actor replaces Alice's essay content on
her server but keeps the same tumbler address. When Carol's server
re-fetches, the BLAKE3 hash doesn't match. The system:
- Rejects the tampered content
- Serves the last verified (cached) version instead
- Shows a red warning: "Content hash mismatch — possible tampering"
- Records the incident in the audit log

**The point:** You cannot silently substitute content. The docuverse
is tamper-evident.

### 7c: Server Offline — Cached Survival (30 seconds)

**What they see:** Alice's server goes offline. Carol opens her
document with the transclusion from Alice. The transclusion still
renders — from the locally cached, hash-verified copy. A subtle
"source offline — showing cached version" indicator appears.

**The point:** The docuverse degrades gracefully. Losing one server
doesn't destroy documents that reference it.

### 7d: License Enforcement — ARR Warning (20 seconds)

**What they see:** Bob tries to transclude from a work marked "All
Rights Reserved." The system warns: "This content is All Rights
Reserved. Transcluding it may not be permitted without the author's
consent." He can proceed (fair use claim) or cancel.

**The point:** Transcopyright metadata is enforced at the transclusion
point, not after the fact.

### 7e: Signature Forgery — Ed25519 Rejection (20 seconds)

**What they see:** Someone creates a fake provenance entry claiming to
be Alice, using a different signing key. The signature verification
fails. The system rejects the forged provenance and flags the entry.

**The point:** Attribution is cryptographic, not claimed. You can't
fake being the author.

---

## Minimal System Needed

### What we have today:
- [x] Typed links with span migration
- [x] Provenance chains (sign + verify, BLAKE3 hashing)
- [x] Cross-server link creation (UI + backend)
- [x] Cross-server backlink notifications
- [x] Domain-based tumblers
- [x] Compound builder with search and placement
- [x] "Source changed" badge in compound builder
- [x] Server directory (with bug fix)
- [x] BLAKE3 hash verification on cross-server resolve
- [x] Typed link filters (Comment, Reference, Disagreement, etc.)
- [x] ARR license warning on transclusion
- [x] Cached content served when hash matches

### What we need to build:
1. **Docker Compose** — 3 servers (alice, bob, carol) on a Docker
   network, each with seed content. This is the foundation everything
   else sits on.
2. **Cross-server blob/image endpoint** — `/api/public/blob/{hash}` so
   images can flow between servers. Currently text-only. This makes the
   demo visual, not just text.
3. **Seed content** — Real, interesting content on each server:
   - Alice: an essay with an image (about hypertext — meta-demonstration)
   - Bob: commentary with typed links to Alice's essay
   - Carol: empty (the newcomer who discovers and transcludes)
4. **Server directory UI** — Frontend panel to add/trust servers, browse
   their public content. Makes the network visible.
5. **Cross-server content browser** — Pick a server from the directory,
   see its public works, select a passage to transclude. The "discovery
   to transclusion" flow.
6. **Failure demo scripts** — CLI commands or admin endpoints to trigger
   each failure scenario on demand:
   - `tamper`: replace content at a tumbler, keeping the address
   - `offline`: stop a server container
   - `forge`: create a fake provenance entry with wrong key
7. **"Source offline" indicator** — When a transclusion source is
   unreachable, show cached content with a subtle badge

### Polish items:
- Smooth loading states for cross-server resolution ("Fetching from
  alice.local..." with spinner)
- Visual distinction between local and remote content (origin badge with
  server name/color)
- Network map showing live connections between servers
- Guided tour / demo mode that walks through all 7 acts
- Side-by-side diff view when source has changed (original vs current)

---

## Priority Order

| # | Item | Impact | Effort | Enables |
|---|------|--------|--------|---------|
| 1 | Docker Compose (3 servers) | Foundation | Medium | Everything |
| 2 | Cross-server blob endpoint | Images! | Medium | Act 2 |
| 3 | Seed content (essay + image) | Story | Low | All acts |
| 4 | Server directory UI | Discovery | Medium | Act 1, 5 |
| 5 | Cross-server content browser | Transclusion flow | Medium | Act 2 |
| 6 | Tamper demo script | The "wow" moment | Low | Act 7b |
| 7 | Source-changed diff view | Failure detail | Low | Act 7a |
| 8 | Server-offline badge | Resilience | Low | Act 7c |
| 9 | Network map | Visual appeal | Low | Act 1 |
| 10 | Loading/origin polish | Professional feel | Low | All acts |
