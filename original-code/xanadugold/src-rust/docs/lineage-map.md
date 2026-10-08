# Xudanu Lineage Map

> **Provenance.** This document is an interpretation of the released
> [Udanax Gold](../../LICENSE-udanax-gold.txt) source code (Copyright
> 1979–1999 Udanax.com), written in 2026 by the xudanu project. It is
> **not** Project Xanadu documentation — none was released with the
> code, and none is known to exist publicly. Where the source is
> ambiguous, the reading is ours; the code itself is the primary
> source and final authority.

Xudanu is two layers with different origins and different licenses.
This map makes the split explicit and auditable.

| Layer | Origin | License | What it means for you |
|---|---|---|---|
| Translated core | Machine-assisted translation of Udanax Gold (Xanadu 92.1), open-sourced 1999 | MIT/X11 (Udanax Open-Source License) — see `NOTICE` and `THIRD_PARTY_LICENSES/udanax_gold.txt` | Free to use, modify, distribute, sell; keep the license notice with substantial portions |
| Original extensions | Written for Xudanu (2025–) | Apache 2.0 | Standard Apache terms |

## Translated-lineage modules

Per-file headers mark each of these. The translation preserves Gold's
algorithms and invariants (and, deliberately, its odd vocabulary —
tumblers, enfilades, crums, orgls) while adapting to Rust idioms.

- `src/ent/` — ent, DagWood, TracePosition, Branch, H-tree, content
  assertions (Gold's `entx`, `dagwoodx`, `tracepx`, `branchx`,
  `htreex`)
- `src/edition/canopy.rs` — the enfiladic link canopy
- `src/edition/props.rs` — Bert/Sensor property summaries
- `src/edition/tumbler.rs` — hierarchical universal addresses
- `src/edition/grandmap.rs` — the server's ID/element tables
- `src/edition/wrapper.rs`, `fetext.rs` — typed edition views
- `src/edition/links.rs` — the multi-ended link model
- `src/persist/persistent.rs`, `counter.rs` — shepherd metadata and
  the batch counter

These modules have often been extended well past their Gold
counterparts; the header marks descent, not equivalence.

## Original modules (Apache 2.0)

Everything else — most notably:

- The provenance suite: span signatures, transparency chain, PROV-JSON
  export, OTS/Bitcoin anchoring (`ots_anchor`, `forensics`,
  `provenance.rs` extensions)
- Federation and cross-server verification
- The O-tree CRDT and the FR-51 enfilade-native lattice
- All cryptography, the HTTP/WebSocket transport, the React frontend
- The MCP server (FR-141) and the verification kit

## Historical note

Udanax Gold itself continued a tradition of translation: it was
developed in Smalltalk and machine-translated to C++ (every generated
file carries the "Output from Objectworks for Smalltalk-80" stamp).
Xudanu continues the pattern one generation further — C++ to Rust —
with permission granted by the Udanax Open-Source License.

Xudanu is an independent project, not affiliated with, endorsed by, or
sponsored by Ted Nelson, Project Xanadu™, the Xanadu Operating
Company, Autodesk Inc., or the Udanax development team. All trademarks
belong to their respective owners.
