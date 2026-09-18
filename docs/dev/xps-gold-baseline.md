# Gold Historical Baseline — Algorithmic Complexity

**Status:** initial analysis from source reading (not compilation)
**Source:** `original-code/xanadugold/src/` (1992 C++, 423 files)
**Date:** 2026-09-18

## Core data structures

### The Enfilade (Loaf tree)

The central structure is a **binary tree with splaying** (amortized
self-rebalancing). Key evidence:

- `SplitLoaf` (loavesp.hxx:851) has exactly two children: `myIn` and
  `myOut`, split by a region boundary (`mySplit`)
- `DspLoaf` (loavesp.hxx:124) wraps a single child with a displacement
  transformation
- The `splay()` method (loavesp.hxx:199+) restructures the tree to
  bring accessed nodes toward the root — classic splay semantics
- `OPartialLoaf`, `OVirtualLoaf` handle partial and virtual (by
  reference) content

**Complexity implication**: amortized O(log N) for position lookup,
insert, and delete, where N is the number of range elements in the
document.

### The Canopy (pruning cache)

`CanopyCrum` / `BertCrum` / `SensorCrum` (canopyx.hxx) cache subtree
summaries (crums) for pruning searches across the grand map. This is
the O(log N) optimization that lets the system avoid scanning all
documents for content matches.

**Complexity**: O(1) crum comparison (hash equality); O(log D) search
across D documents with pruning, vs O(D) without.

### The DagWood (version tree)

`DagWood` (dagwoodx.hxx:87) manages the branching version history for
concurrent editing:

- `successorsOf(trace)` returns all successor branches
- `installBranchAfter(branch, anchorTrace)` walks a "balanced walk down
  the binary tree of branches"
- Merge is `combine(another, limitRegion, globalDsp)` — region-based
  set operations, not text diff

**Complexity**: O(log B) for branch lookup where B is the number of
branches; merge is proportional to the size of the changed region,
not the full document.

### The Grand Map (BeGrandMap)

`BeGrandMap` (granmapx.hxx:147) manages the global ID space with
two-way associations (`assignID`/`tryIntroduce`).

## Operation complexity table

| XPS Op | Gold implementation | Complexity | Notes |
|---|---|---|---|
| L1 link create | `assignID` + end-set insert | O(log N) amortized | N = elements in the document's enfilade |
| L2 backlink query | Crum-guided canopy search | O(log D × log N) amortized | D = documents; canopy prunes non-matching subtrees |
| L3 link delete | Mark tombstone in enfilade | O(log N) amortized | No physical removal (append-only design) |
| L4 span migration | Displacement propagation via DspLoaf | O(log N) amortized | The Dsp (displacement algebra) is THE mechanism |
| T2 compound resolve | Recursive enfilade walk with Dsp transforms | O(K × log N) | K = transclusion depth |
| T4 source edit propagation | Dsp update + dependent re-resolve | O(K × log N) | Same as T2; change propagates through displacement chain |
| C1 content match | Crum comparison + region intersection | O(log D × log N) with canopy | The "enfilade advantage" — subtree hash equality |
| P3 provenance chain | Trace walk through DagWood | O(depth) | Version tree walk, not a search |

## What Gold did NOT implement

| Capability | Status | Implication |
|---|---|---|
| Cryptographic provenance | Not present | No P1/P2 in the XPS sense |
| Cross-server operation | Designed (never shipped) | F1-F5 in Xudanu's FR-6 |
| Typed link labels | **Fully implemented** — types are first-class Works (documents) with type hierarchies and per-end descriptions; see below | Xudanu's fixed integer types are simpler |
| Annotation/query on links | Not present | Xudanu's descriptors, annotations |
| Content matching at corpus scale | Canopy prunes, but no n-gram index | C2 would require full scan without canopy |

## The "enfilade advantage" quantified

The key design claim: **subtree hash equality in O(1)** via crums.
Two identical subtrees compare equal without walking their contents.
This means:

- Content matching (C1) between two documents: O(log D) to find
  candidate matches via canopy, then O(1) per subtree comparison
- Anti-entropy / sync: only differing subtrees are transferred
  (Xudanu implements this in `crum_diff`)

Without crums, every comparison is O(document size), and corpus-wide
matching becomes O(D × S) where S is average document size.

## Gold's typed link model (correction)

The initial analysis incorrectly stated Gold lacked typed links. The
source (`nlinksx.hxx:92`) shows `FeHyperLink` with a **richer type
system than Xudanu's**:

- `FeHyperLink::make(types, leftEnd, rightEnd)` — takes a SET of
  types, not a single label
- Types are **first-class Works** (documents) — each type document
  describes what the link means and what each end represents
- **Type hierarchies**: "including all super types of a link in its
  link type list" — a link carries its full type ancestry
- `linkFilter(types)` — filter links by type region (Xudanu's
  link_type_register/link_query are the analogue)
- **Named multi-ended links**: `endAt(name)`, `withEnd(name, ref)`,
  `withoutEnd(name)` — ends are addressed by Sequence names, not
  fixed left/right positions (Xudanu's FR-40 named ends mirror this)

Xudanu's integer type IDs are simpler to implement and query, but
Gold's document-as-type model is more xanalogical: the type system
is itself part of the corpus, linkable, transcludable, and
versioned. This is a design insight worth revisiting.

## Historical context

Gold was designed for persistent, disk-backed storage on 1990s
hardware (SPARCstations, early PCs). The splay tree was chosen for:

1. No rebalancing metadata (smaller nodes on disk)
2. Good locality for sequential access patterns (editing)
3. Amortized rather than worst-case guarantees (acceptable for
   interactive use)

Xudanu's lattice substrate (weight-balanced BST) provides the same
O(log N) guarantees with different trade-offs (deterministic shape
for reproducible crum comparison vs splaying's adaptive shape).

## Caveats

- This is a **reading analysis**, not a runtime measurement
- Actual 1990s performance was constrained by disk I/O, not
  algorithmic complexity — the code was I/O-bound
- The Smalltalk frontend (smalltalk.tar.gz) may have additional
  overhead not captured here
- Some operations may have implementation details that deviate from
  the theoretical complexity (the source is 20K+ lines)
