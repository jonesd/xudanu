# FR-57: Lattice Tombstone GC — Causal Stability + Chunk-Store Offload

- **ID:** FR-57
- **Status:** Proposed — design complete, not scheduled. Prerequisite
  for FR-51 rollout steps 4 (write-switch) and 5 (O-tree retirement).
- **Depends on:** FR-51 (C-5 switch + integration), FR-34 (chunk
  store, crums, recorder fossils — the machinery this reuses)
- **Siblings:** none. The enfilade-side analog already exists
  (recorder fossils, `src/edition/recorder.rs`).

## 1. Why this FR exists

The lattice is append-only: deletion is a `RegionTombstone` (a
`SequenceRegion` plus the deleter's causal context — the OR-set
rule). Tombstones never leave the tree. Today nothing reclaims
them:

- A tombstone must outlive any concurrent re-insert it could not
  see (a unit dies iff its dot is in the tombstone's context).
- Anti-entropy ships full state including all tombstones
  (`debug_tombstones()` in `lattice_wire.rs`), so every replica
  needs them too.

**Why it is tolerable today:** tombstones are small (no content
bytes — region + `HashSet<Dot>`), and shadows are ephemeral by
design: restore rebuilds from the edition text, so every restart
resets the tombstone count to zero. Accumulation is bounded by
process lifetime and only matters for long-lived, heavily edited
works. `MultiWriter::memory_estimate()` already reports
(units, tombstones, content bytes, live bytes) — the ratio is
watchable.

**When it stops being tolerable:** at FR-51 rollout step 4
(write-switch) the lattice becomes the engine of record for
promoted works; at step 5 (O-tree retirement) there is no fallback
engine holding the authoritative text. Sustained delete churn on a
work that never restarts grows without bound.

## 2. The hub advantage: the precondition is decidable

P2P CRDTs cannot garbage-collect tombstones because causal
stability is unknowable (an unknown replica may appear with a dot
the tombstone must still kill). The hub model decides it:

- Every session view syncs after every op (`sync()` sets
  view = doc), so the server observes each author's counter as
  seen by every live view.
- The federation peer set is known; anti-entropy acks observe the
  same counters at peers.

**Stability floor** (per dense author `a`):

```
floor(a) = min(min over live session views of view.counter_seen(a),
               min over federation peers of peer.counter_seen(a))
```

Single-server, no peers: the floor is just the minimum over live
views. No views at all: everything is stable.

**Retirement rule:** a tombstone is dead when no future unit can
carry a dot in its context:

```
retire(t) iff for every dot (a, c) in t.context: c < floor(a)
```

A retired tombstone cannot affect any future merge: any unit minted
after retirement has a counter above the floor, hence above every
dot in the context — the tombstone could never kill it.

## 3. Design

### 3.1 In-memory retirement (drop below floor)

Walk the tree's tombstones (they live beside units in the balanced
tree; a periodic scan amortizes), retire those passing §2, drop
them from the tree. Rebalance as usual. The tree shrinks; ops get
cheaper.

### 3.2 Chunk-store offload (cold history)

Retired tombstones are not discarded — they become **cold
history**, written to the chunk store as content-addressed chunks
(postcard, BLAKE3 — the FR-34 machinery):

- Batch retired tombstones (size-bounded, e.g. 64 KiB chunks).
- Write via the existing chunk store; record the chunk hash list
  in the work's lattice state. Because shadows are ephemeral, the
  durable home for the refs is the section-chunk pattern
  (like reconcile/social sections) keyed by work — written at
  checkpoint, read at anti-entropy time, not needed at restore
  (restore re-seeds from the edition).
- Memory keeps only the **hot window**: unstable tombstones above
  the floor.

### 3.3 Wire changes

`lattice_wire` full state currently ships all tombstones. After
this FR it ships the hot window plus chunk refs. A peer whose crum
diff indicates missing cold history pulls chunks by hash — O(missing)
work, rare under steady state because crums make divergence
detection O(changes).

### 3.4 The ultimate fallback: re-seed

If cold chunks were themselves GC'd (chunk-store retention policy)
or a peer's gap is too large, the peer re-seeds from the edition
text: build a fresh lattice from live text, resume anti-entropy.
This always works because the enfilade remains the persistence
layer throughout the cutover (FR-51 rule). Re-seed trades edit
granularity for correctness, exactly like a fresh shadow enrollment.

## 4. Stories

| # | Story | Armor |
|---|---|---|
| S1 | Floor computation + telemetry (per-author floor, retireable count) | Unit test: floor advances as views sync; empty-view case |
| S2 | In-memory retirement (§3.1) | Property: interleaved editors with periodic GC converge to identical text as a no-GC run, across N seeds |
| S3 | Chunk offload + refs (§3.2) | Test: sustained delete churn keeps tombstone count bounded and full-state bytes shrink after GC; chunks round-trip |
| S4 | Wire: hot window + refs (§3.3) | Test: stale peer converges via hot window + chunk pull; bytes on wire < full state |
| S5 | Re-seed fallback (§3.4) | Test: peer with missing chunks converges via edition re-seed |

S1–S2 are useful immediately (bounded shadow memory). S3–S5 are
only needed for federation on lattice-primary works and before
rollout steps 4–5.

## 5. Acceptance criteria

- Sustained delete churn (insert/delete loop, no restart) reaches
  a steady-state tombstone count — memory does not grow without
  bound.
- Convergence is bit-identical with and without GC running
  (property test, multiple authors, randomized interleavings).
- A peer that falls behind and catches up gets exact text equality
  via hot window + chunks, or via re-seed when chunks are absent.
- Restart behavior unchanged: shadow rebuilds from edition, zero
  tombstones, no new restore requirements.

## 6. Non-goals

- No client-side changes: clients hold views; the server is the
  authority and the only tombstone keeper.
- No enfilade-side changes: recorder fossils already handle the
  enfilade's analogous retention.
- No cross-work coordination: GC is per-work (per MultiWriter).

## 7. Relationship to other FRs

| FR | Relationship |
|---|---|
| FR-51 | Blocks rollout steps 4 (write-switch) and 5 (retire O-tree); unnecessary for shadow + read-switch (steps 1–3) |
| FR-34 | Reuses the chunk store, content addressing, and crum-diff anti-entropy; recorder fossils are the enfilade-side analog |
| FR-35 | Federation Bloom-filter layer: peer acks feeding the floor ride the same traffic |
| FR-56 | Tombstone regions use Sequence addresses; no realm changes needed |

## 8. Gold lineage

The accumulation problem is the same one Gold's enfilades faced —
deletion records that must outlive unseen concurrent writers. Gold's
crum structure is what makes the offload cheap here (subtree hashes
detect what a peer is missing without shipping it). The hub-decided
stability floor is Xudanu's addition: a server that knows its
replica set can reclaim what a P2P mesh must keep forever.
