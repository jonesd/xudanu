# FR-76: Epoch-Structured Enfilade

**Status:** design draft
**Created:** 2026-09-21
**Depends on:** FR-34 (enfilade-native), FR-36 (chunk GC), FR-50 (performance verification), XPS spec (§2 core operations)
**Author:** David Jones

---

## The problem

The enfilade — Gold's splayed binary tree — is the core data structure
that gives xanalogical systems their O(log N) operations. But Gold's
implementation is **mutable and single-machine**: the tree lives in
RAM, restructures itself on every access (splaying), and cannot be
shared across threads without locks or copied without O(N) cost.

This creates three limits:

1. **Capacity**: the tree must fit in one machine's memory. A 64GB
   machine holds roughly 500K books. The docuverse wants all books.
2. **Concurrency**: mutable trees need locks. Gold was single-writer.
   Modern systems need concurrent readers, and the docuverse needs
   cross-server reads.
3. **Versioning**: each revision creates a new version, but Gold had
   no structural sharing — comparing two versions means walking both
   trees in full.

The chunk store (FR-36) already solves this for *content* — text is
BLAKE3-addressed and distributable. But the *structural* tree (the
enfilade that indexes and organizes the content) is rebuilt on demand
rather than maintained as a persistent, shareable structure.

## The design: epochs

Divide the enfilade's life into **epochs** — alternating mutable and
immutable phases, like an LSM tree's memtable → SSTable cycle.

```
Epoch N (mutable)          Epoch N-1 (frozen)     Epoch N-2 (frozen)
┌──────────────┐          ┌──────────────┐       ┌──────────────┐
│  Splay tree  │ freeze() │ BLAKE3 root  │       │ BLAKE3 root  │
│  (hot edits) │ ───────▶ │ hash: a7f3…  │       │ hash: 9b2c…  │
│  (splaying)  │          │ (chunks)     │       │ (chunks)     │
└──────────────┘          └──────────────┘       └──────────────┘
  ▲ active writes           read-only              read-only
  │                         cacheable              cacheable
```

- **Active epoch**: a mutable splay tree, exactly like Gold. All
  writes go here. Splaying works. Performance is identical to the
  original design.
- **Frozen epoch**: the result of a freeze operation. The tree is
  converted to content-addressed chunks (one chunk per subtree, or
  per leaf-group). The root BLAKE3 hash identifies the epoch.
  Frozen epochs are immutable, cacheable, shareable, and
  distributable.

### Freeze trigger

An epoch freezes when any of:
- Memory threshold: the active epoch exceeds a configurable memory
  budget (default: 256MB of tree nodes)
- Time threshold: N seconds since last freeze (default: 300s = 5 min)
- Checkpoint alignment: freeze piggybacks on the existing periodic
  checkpoint (one I/O pass, not two)
- Explicit: an admin or compaction job requests it

### The freeze protocol

```
freeze(active_epoch) → frozen_epoch:

1. Stop accepting writes (hand off to a new active epoch —
   the caller creates the new epoch BEFORE freezing, so there
   is no write gap)
2. Compute BLAKE3 hashes bottom-up for every internal node
   (leaf chunks are already hashed by the chunk store)
3. Write internal node chunks to the chunk store
   (each node: hash, child hashes, crum summary)
4. Record the root hash as the epoch identity
5. Drop the in-memory tree (the chunks are now authoritative)
6. Resume reads against the frozen chunks
```

The freeze is O(N) in the epoch's size — proportional to the number
of nodes written. This is a background operation; reads against
already-frozen subtrees proceed in parallel (they're just chunk reads).

### The epoch chain

Each epoch knows its parent (the previous frozen epoch). The chain
forms a linked list (or tree, with branching versions):

```
Epoch 3 (active) → parent: Epoch 2 → parent: Epoch 1 → parent: null
```

A document's "current version" is: the active epoch's state,
which internally references its parent chain for historical data.

## Cross-epoch queries

### Point read (what is the character at position P?)

```
read(position P):
  1. Try active epoch (splay tree lookup — O(log N), fast)
  2. If not found (position beyond active epoch's range):
     → walk frozen epochs from most recent to oldest
     → at each epoch: read the chunk at position P
     → first hit wins (most recent version)
```

Amortized: O(log N) for recent content (hot epoch), O(log N × E) for
old content where E = number of epochs to search. With compaction
(see below), E stays small (target: ≤4).

### Structural diff (compare two versions)

```
diff(version_a, version_b):
  1. If root hashes equal → identical, return empty diff (O(1))
  2. Walk both trees in parallel, comparing child hashes
  3. Only descend into subtrees with different hashes
  4. Result: list of changed subtrees + their new hashes
```

Cost: O(D) where D = number of changed nodes, NOT O(N) total nodes.
This is the operation that makes backfollow (C2) tractable at scale:
comparing two versions is proportional to the change, not the corpus.

### Backlink query (what links to this span?)

Backlinks are stored separately from the enfilade (in the link
registry — see §Sharding below). The query path doesn't change with
epochs; only the content resolution goes through the epoch chain.

## Compaction

Without compaction, read latency grows linearly with epoch count.
Compaction merges frozen epochs into a single epoch, amortizing
the cost.

### When to compact

- Epoch count exceeds a threshold (default: 8)
- A read spans more than N epochs (trigger targeted compaction)
- Background: during low-traffic periods (the existing idle
  checkpoint path)

### How it works

```
compact(epochs E1, E2, ..., En) → merged_epoch:

1. Read each epoch's tree structure (from chunks)
2. Merge: newest version wins for any position present in
   multiple epochs
3. Write the merged tree as new chunks
4. The old epoch chunks become garbage-collectible (after
   the retention window)
```

Cost: O(N) in the merged epoch's size, but runs in the background.
The result is fewer epochs → faster reads.

### Relation to existing GC

The chunk store's GC (FR-36) already handles orphaned chunks. After
compaction, the old epoch's chunks are orphans (no root references
them) and the existing GC sweeps them.

## Sharding

Frozen epochs are content-addressed chunks — the same sharding story
as the existing chunk store, but now for the *structural* tree:

### Hash-range partitioning

Each server owns a hash range (e.g., server A owns hashes 0x0000-
7FFF, server B owns 0x8000-FFFF). A chunk's hash determines its
home server. Any server can cache any chunk (immutable = cache-safe).

```
Server A (hashes 0x0000-7FFF)     Server B (hashes 0x8000-FFFF)
┌──────────────────────┐         ┌──────────────────────┐
│ Active epoch (own    │         │ Active epoch (own    │
│  documents)          │         │  documents)          │
│ Frozen chunks in     │         │ Frozen chunks in     │
│  range 0x0000-7FFF   │         │  range 0x8000-FFFF   │
│ + cached chunks      │         │ + cached chunks      │
│   from B's range     │         │   from A's range     │
└──────────────────────┘         └──────────────────────┘
```

### Query routing

```
query(position P, document D):
  1. Check local active epoch
  2. Check local frozen epoch cache
  3. Compute the chunk's hash from D's root + P's path
  4. Route to the owning server
  5. Cache the result locally (immutable = safe)
```

### Write path

Writes always go to the document's **owning server** (the active
epoch is never distributed). After freeze, the chunks distribute to
their hash-range owners. The owning server retains authority over
the active epoch; frozen chunks are read-only everywhere.

## Memory model

| Component | Mutable (active) | Frozen (per epoch) |
|---|---|---|
| Splay tree nodes | ~50-100 bytes per element | — |
| Chunk data | — | ~30-60 bytes per element (serialized) |
| Node chunks (internal) | — | ~40 bytes per node |
| Index overhead | HashMap + work_to_links | HashMap (read-only) |
| **Total per element** | ~50-100 bytes | ~70-100 bytes |

The frozen form is comparable in size — slightly larger due to
serialization overhead, but the ability to cache, share, and shard
compensates. The active epoch's memory budget is configurable
(default 256MB), so the mutable cost is bounded.

## What this replaces vs. preserves

### Preserved (unchanged from Gold's design)

- Splay tree structure and semantics within the active epoch
- Crum-based subtree summaries (BLAKE3 hashes)
- The O(log N) amortized operations for hot data
- Position-based addressing (the tumbling system)

### Replaced

- Monolithic mutable tree → epoch-based mutable/immutable cycle
- In-memory only → chunk-persisted frozen epochs
- Single machine → hash-range sharding for frozen chunks
- Deep-copy snapshots → O(1) frozen epoch references
- Full-tree diff → hash-based structural diff

### What Gold would recognize

Gold's `OVirtualLoaf` handled by-reference content — a node pointing
to content stored elsewhere. This design extends that concept: the
entire tree becomes virtual (by-reference) once frozen. Gold's
splaying remains exactly as designed within the active epoch.

## Implementation roadmap

### Phase 1: Freeze protocol (~2-3 days)
- Add `EpochState` (active/frozen, root hash, parent pointer)
- Implement `freeze()`: bottom-up hash, chunk write, tree drop
- Freeze on checkpoint (piggyback existing path)
- Read path: check active, then frozen chunks

### Phase 2: Cross-epoch reads (~1-2 days)
- Point reads through the epoch chain
- Structural diff across epoch boundaries
- Version timeline queries (walk the chain)

### Phase 3: Compaction (~1-2 days)
- Merge N frozen epochs into one
- Background compaction trigger
- GC integration (old epochs become collectible)

### Phase 4: Sharding (~future, depends on FR-19b)
- Hash-range chunk distribution
- Cross-server epoch reads
- Cache coherence (trivial: immutable chunks)

### Phase 5: XPS integration (~1 day)
- Add epoch operations to the benchmark suite
- Measure: freeze cost, cross-epoch read latency, compaction
  throughput, cache hit rates
- Record capacity curve (documents × links × epochs)

## Comparison to related systems

| System | Mutable store | Immutable store | Compaction | Sharding |
|---|---|---|---|---|
| **Gold** | Splay tree (always) | — | — | — |
| **LSM (RocksDB)** | Memtable (skiplist) | SSTables | Background merge | Range partitions |
| **Noms/Datomic** | — (always immutable) | Hash-chained sets | — (no compaction) | Content-addressed |
| **Xudanu (this)** | Splay tree (epoch) | BLAKE3 chunks | Background merge | Hash-range |
| **Git** | Index (staging) | Object store | GC (pack) | Content-addressed |

The design is closest to a hybrid of LSM (mutable → immutable cycle
with compaction) and Git (content-addressed immutable objects with
structural sharing). The splay tree within the active epoch is the
Gold heritage.

## Open questions

1. **Splay tree serialization**: freezing a splay tree loses the
   splayed shape. On re-load (for compaction), should we re-splay,
   or use the canonical (un-splayed) insertion order for deterministic
   hashing? [Answer: canonical order — determinism is required for
   content-addressing, and the splayed shape is a performance detail
   that doesn't survive freezing anyway]

2. **Epoch granularity**: per-document epochs or per-server epochs?
   Per-document gives finer-grained freezing but more epoch chains
   to manage. Per-server is simpler but freezes everything at once.
   [Recommendation: per-document, batched at the server level —
   freeze all dirty documents' epochs in one checkpoint pass]

3. **End-set versioning**: multi-ended links (FR-40 end-sets) span
   documents. When document A's epoch freezes but document B's
   doesn't, how do we version the link's state? [Answer: the link
   registry (separate from the enfilade) tracks link state with its
   own epoch chain, independent of the document epochs]

4. **Active epoch replication**: for HA, the active epoch needs at
   least one replica. The CRDT layer already handles concurrent
   edits — but the splay tree shape is CRDT-hostile (non-deterministic
   ordering). [Answer: replicate the logical edits (CRDT ops), not
   the tree shape. Each replica maintains its own splay tree from
   the same edit sequence; the trees converge logically even if the
   physical shape differs. Only the frozen (canonical) form needs
   to be identical across replicas]
