# FR-64: Tumbler Activation

Status: **SHIPPED** in v1.13.0 (2026-09-12). Phases A–F plus usage
layer, all merged to main.

## The backstory (why this took a while)

The tumbler machinery has existed since FR-34: 34 functions on
`XudanuTumbler`, the `DocumentArrangement` bridge, and a complete
1294-line Sequence algebra ported from Gold's space system. None of
it was load-bearing. AGENTS.md said so out loud: *"1294 lines
dormant."* The machinery was parallel addressing — derivable,
correct, unused.

Three things kept it dormant:

1. **The domain overload.** FR-6 (cross-server links) overloaded the
   tumbler's first element with a domain string. That made the
   display format work (`"alice.com".5.3`) but broke the identity
   model underneath: an *empty* server field meant "local," and every
   server claims local. After replication, `.5.3` was ambiguous
   everywhere. Worse, a server with no configured public address
   derived `"localhost"` tumblers that its own `owns_tumbler`
   rejected — generated-but-unowned addresses.
2. **Regions took the pragmatic path.** Regions Phase 1 scoped the
   docuverse with club IDs, explicitly deferring tumbler integration
   ("not load-bearing, Phase 2/3"). The right call at the time — and
   it left a standing TODO shaped exactly like this FR.
3. **No forcing function.** Nothing on the critical path needed the
   hierarchy. Until the H(G) per-region profiling work surfaced an
   edge-filtering bug, and the regions design doc's Phase 2/3
   promises came due.

The unblock was a design review that reframed the problem: not "add
tumbler features" but "make tumblers load-bearing, in phases where
each is independently valuable." Six phases, each shippable alone,
each removing one reason the previous layer couldn't depend on the
next.

## The approach

### Phase A — identity stamps

Every work carries its creating server's identity forever:
`public_address` when configured (DNS-resolvable), else `ns-<hex16>`
derived from the signing key's BLAKE3 hash (unique, not resolvable).
`"localhost"` eliminated. Three ownership forms accepted (legacy
empty, domain, ns-always — pre-domain stamps survive domain
configuration). Federation sync entries carry the origin server +
resolved path; **replicas preserve the ORIGIN's full tumbler,
transitively through re-exports**. Stamps persist through both
persistence layers (chunk refs and root-chunk state).

### Phase B — `xan://` navigation

URI codec (`xan://host/path`), resolution precedence (exact stamp →
replica → legacy derivation → region → remote-with-directory), and
the bidirectional `GET /api/public/resolve`. Search-overlay address
mode; `?tumbler=` deep links; CLI `show <address>`. Live-verified
through restart.

### Phase C — prefix regions

A region IS a tumbler prefix on a club. Hierarchical allocation
(`region_create`, admin-gated); works created in region context get
`[prefix, be_id]` paths; nested visibility (region [2] sees [2,1]);
region addresses resolve. Phase 1 club semantics preserved as the
legacy fallback.

### Phase D — tumbler link targets

Link ends carry their target's permanent address (`origin_tumbler`),
stamped at creation with span elements. The invariant: **tumbler
authoritative, BeId a remappable cache**. Cross-server arrival remaps
work contexts to local works (original or replica) — the anti-fork
property: alice's link resolves on bob to bob's replica, whatever
local id it landed on.

### Phase E — version dimension

`?rev=N` rides the **query layer**; paths stay purely positional.
This was a deliberate collision-avoidance decision: the internal
`work_tumbler(wid, rev)` form appended revision as a path element,
which is indistinguishable from a position (`[w, n]`). Version-
qualified addresses pin reads; pinned transclusion sources are
addressable (`xan://server/1004.0.5?rev=7`). Legacy backfill at
checkpoint (idempotent, None-only) makes pre-existing works and links
addressable after one cycle.

### Phase F — Sequence algebra activation

`Sequence::between`: the never-renumber allocation primitive (a
position strictly between any two, always), property-tested.
`region_insert_between` is its production caller — with honest
semantics documented: between-addresses may nest deeper than their
operands but *sort* between them (Gold's actual behavior, which
surprises people expecting same-depth siblings). Tumblers are totally
ordered (server, then Sequence path comparison); region containment
runs through `SequenceRegion::prefixed_by`; region members return in
address order.

### Usage layer

Region write enforcement (the permeability principle: reads and
transclusions cross regions; writes don't — you cannot write into
what you cannot see). `xan_resolve` wire op. Addresses surfaced with
copy affordances (Settings, connections, transclusion sources).

## Postcard rule (the hard lesson)

Adding `skip_serializing_if` to a postcard-serialized struct broke 51
checkpoint tests: postcard is positional, so skipped bytes misalign
deserialization (`Found a bool that wasn't 0 or 1`). The safe
additive-field pattern is `#[serde(default)]` alone. Codified in
AGENTS.md; `skip_serializing_if` remains fine for serde_json-only
structs.

## Network compatibility (did we preserve connecting to other nodes?)

**Yes — preserved and improved. This FR exists because of that
problem.**

- The original disconnect — empty-server tumblers claimed by every
  node, replicas losing origin identity — is exactly what Phase A
  fixed. A replica now carries its origin's address, so any server
  holding content can resolve any link end. That is *better*
  cross-server behavior than v1.12.
- FR-6 machinery is untouched: server directory, public content API,
  BLAKE3 span verification, backlink notify, bloom filters all
  compose unchanged with the new identity forms. Domain-configured
  servers behave exactly as before.
- Wire compatibility follows the established additive-field pattern
  (`serde(default)`, same as `span_provenance` before it): new code
  reads old entries; mixed-version clusters should upgrade in step —
  the same constraint every prior sync-entry addition carried.
- New wire ops (0x0360–0x0363) are additive; old servers never
  receive them from old clients.
- `ns-` identities are deliberately single-player until the operator
  configures a public address (a bare key-hash is not dialable); the
  3-node demo network and any domain-configured federation work as
  before.

## Testing

3505 lib tests, 317 integration tests, 855 frontend tests. Notable:
the anti-fork replica test (nondeterministic import order — semantics
asserted on address, not id); the induced-subgraph H(G) regression
(which was also a latent panic in author sub-profiles); property
tests on `between` and tumbler ordering; checkpoint/restore round
trips at both persistence layers; live end-to-end verification of
resolution including restart.

## What's deliberately not here

Cross-server region semantics (replicas don't carry region
membership — a future design question), OS-level `xan://` protocol
registration (browsers don't support custom schemes), and full wid-
semantics lazy displacement propagation (span migration covers the
practical cases; see the Gold optimizations notes).
