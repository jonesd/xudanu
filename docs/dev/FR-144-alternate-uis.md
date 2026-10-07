# FR-144 — Alternate UIs: the classic Xanadu client

> **Status:** Proposed (2026-10-07). Enabled by the wire protocol
> contract (#219): within `api_version` 1 the operation table is
> frozen and additive-only, so a second client can be built without
> asking the server to change.
>
> **Related:** FR-143 (transpointing primitives — shared consumers),
> the pattern map's Pattern 10 (multiple views — conformity, not
> departure), `docs/dev/components-and-remixes.md` (protocol as
> product).

## Motivation

The current React workspace is the reference UI: it ships editing,
provenance panels, trails, the works. But the *classic* Xanadu
presentation — parallel documents, visible connections between
them, transpointing windows as the primary layout rather than a
supplement — is a different reading posture, and forcing it into
the workspace shell would compromise both. The wire contract makes
the right move cheap: **build the classic presentation as a second
client of the same frozen protocol.** Preserve the reference UI;
grow a sibling; never fork the server.

This is also pattern-conformant: Nelson's system insisted on
multiple views of the same structure. Two UIs over one docuverse is
not a concession — it is Pattern 10 done properly.

## Architecture

- **Both UIs are first-class clients** of the pinned wire contract.
  Neither may use private escape hatches; if a capability is
  missing, a new op goes through the contract process (appenditive,
  pin-updated, deliberate).
- **The reference UI keeps collaborative editing** (the CRDT client
  stays with it). The classic UI begins **read-only** — the easy
  class of client (search, read, links, trails, provenance; no
  CRDT, no grab/revise).
- **Shared pure logic, not shared shell:** the geometry and marker
  helpers with no React coupling (`link-markers`, beam geometry)
  extract into a small shared package consumed by both UIs — the
  beam you see in version-compare and the beam you see in the
  classic view are the same code.

## Phases

**A — Scaffold and handshake.** A second app (`web/classic`),
thin read-only client speaking the contract: well-known discovery,
`api_version` check (refuse mismatches — the contract's first real
consumer enforces it), session, search, read. *Acceptance: the
classic client reads a seeded docuverse end to end using only
pinned ops.*

**B — Parallel documents.** The classic reading surface:
side-by-side panes with visible connections between them —
originating as a re-skin of the shared beam/marker package over
the same link data. *Acceptance: any connection openable as two
panes joined by a beam that follows scroll; the gallery walkable
in this posture.*

**C — Transpointing-first layout.** The signature phase: windows
and pointing as the *primary* arrangement — open a work, unfold
its connections into windows around it, beams everywhere, the
Spectrum Sentence as six windows on one sentence. Consumes the same
concepts FR-143 builds in the reference shell. *Acceptance: the
entire Gallery of Unusual Connections navigable without leaving
the classic posture.*

**D — Editing, later.** Single-work editing via grab/revise (no
CRDT needed). Collaborative editing arrives only with the CRDT
client library extraction — build when wanted, not before.

## Non-goals

- Replacing or degrading the reference UI (it stays the default)
- Full ZigZag spatial generality
- Mobile-first layout

## Why this ordering works

Every phase is a walking demo for a different audience: A proves
the contract, B is the "finally, side-by-side" moment for anyone
who has read the Xanadu literature, C is the answer to Maggie's
favorite pattern, and D arrives when someone actually needs to
edit from the classic posture. And because both UIs sit on the
frozen protocol, neither can drift: the pin is the constitution.
