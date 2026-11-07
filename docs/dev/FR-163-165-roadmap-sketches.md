# FR-163: Mirror-Fetch Availability — Any Copy Proves Itself

- **ID:** FR-163
- **Status:** Sketch (reviewed 2026-11-07)
- **Parent:** FR-6 (linked independent servers), FR-161 (reuse graph)

## Problem

Cross-server transclusion depends on the origin server being up for
new placements and refreshes. The frozen local copy keeps rendering
and provenance alive when an origin is down, but the *live* window
and new windows onto the same content are blocked until it returns.

## Key insight

Content-addressing inverts the trust requirement: you do not need to
trust a mirror, only the hash. The provenance bond pins the BLAKE3 of
the span at quote time, so any copy of the right bytes proves itself,
and a wrong copy is refused cryptographically (already enforced on
every fetch). A mirror can never lie to you — it can only fail to
have the bytes.

## What exists

- Hash-verified span fetch (public range API + BLAKE3 compare,
  refuses tampered content)
- Content-addressed blob store (hash -> bytes, mime, dimensions)
- Federated entries in the reuse index: who holds what content, on
  which server
- PeerPool with connected-peer knowledge
- Directory trust/quarantine gates

## Design sketch

When the origin fetch fails (placement or refresh), ask trusted peers
for bytes matching the bond hash — reusing the federated_search
fan-out plumbing — then verify against the ORIGINAL bond hash, never
the peer's claim. Origin remains authoritative for freshness; mirrors
answer only for availability. A peer holding a different revision of
the same span simply cannot serve that bond (equality verified, never
assumed).

## Effort

Medium: one new wire op (span query by hash), fan-out reuse, two
fallback paths (placement, refresh).

# FR-164: Corpus-Wide Reuse Map — Making the Two Graphs Visible

- **ID:** FR-164
- **Status:** Implemented 2026-11-07 — see `FR-164-corpus-reuse-map.md`
- **Parent:** FR-161 (reuse graph index); absorbs the FR-161
  follow-up `find_transclusions` sketch

## Problem

The reuse graph is traversable per work but has no corpus-wide
viewport. The docuverse map in the frontend draws link edges only;
reuse edges (the second xanalogical connection system) are invisible
as structure.

## What exists

The corpus-wide index already exists: fingerprint_to_works
(fingerprint -> set of works), work-granular keys (FR-161), federated
entries carrying remote edges. DocumentMapPanel renders force-directed
link graphs. Missing pieces are surfaces.

## Design sketch

1. Server op `reuse_graph`: invert the index into edges
   {reuser, source, is_direct, span_count, origin_server?}, paginated.
2. MCP tool `find_transclusions` (the original FR-161 sketch): same
   edges as tool results, by source work / span / directness.
3. Frontend: reuse as a second edge type in DocumentMapPanel
   (distinct weight/color) — the link graph and reuse graph become
   visibly distinct for the first time.

## Effort

Small-to-medium, mostly surfaces; the graph itself shipped with
FR-161.

# FR-165: Beyond Text — The Gold Structural Substrate

- **ID:** FR-165
- **Status:** Direction (reviewed 2026-11-07)
- **Parent:** FR-34 (enfilade-native, tumblers); the Autodesk-era
  Udanax Gold structural inheritance

## Question

Can Xudanu expand beyond text using the structural mechanisms
inherited from Udanax Gold — the era when the system was designed to
be more than text, with larger structural elements to build from?

## Finding: the substrate is ahead of the surface

The element algebra has 13 variants; only one is Text:

- Data (raw bytes inline — the exception, not the pattern), Blob
  (bytes out-of-line in the separate content-addressed blob store;
  the inline element is only the hash reference plus mime/dimensions/
  caption, already rendering inline in the editor)
- Overlay (derived content: base hash + operations)
- Set / Path (structural quoting: collections of span refs as single
  values — the Gold stubble sets, FR-52)
- Virtual (computed content with pinned specs — the Rust analogue of
  Gold's virtual range elements, loavesx.hxx)
- StructuralTransclusion (transcluding entry RANGES with a source
  crum — structure, not characters)

The space algebra is dimension-general: CrossSpaceN has 2D and 3D
implementations with tests. Tumblers address hierarchically, not by
char offset (FR-34 D-F shipped). Fingerprints hash the SPEC, never
the content — the index already treats elements as structure, not
bytes.

What is text-bound is the surface, not the core: transclusion spans
are char_start/char_end, the resolver flattens to a text string,
search is a text index, span migration works in char deltas, the
editor is a text canvas.

## Staged arc (each stage independently shippable)

1. Near-free: lean into Blob/Data works; blob transclusion by
   content hash is the natural first non-text window — the window is
   just the same hash reference in another work (bytes immutable, no
   revision drift), and it pairs with FR-163 (content-addressed blobs
   are trivially mirror-verifiable: any copy of the right bytes
   proves itself).
2. Medium: generalize span addressing from char ranges to
   element/entry ranges (StructuralTransclusion already carries
   entry_start/entry_end; the tumbler bridge exists). Spans of
   structure alongside spans of characters.
3. Deep: the resolver emits element trees instead of flat text;
   search indexes per element type; the UI renders trees — where
   CrossSpaceN finally gets used (overlays, parallel documents as
   first-class views).

## Answer

The direction is open. The orgls, crums, spec-fingerprints, and
dimension-general algebra came through the translation intact; the
text-centric surface sits ON the substrate, not IN it. The deep
refactor is an inversion of the read layer, not a replacement of the
core.
