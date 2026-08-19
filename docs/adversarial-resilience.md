# Adversarial Resilience: Building a Syntax Gate for Untrusted Documents

*A working notes paper — how we found the holes, what surprised us, and the method we'd use again.*

---

## Why this document exists

Most technical documentation describes a system that works. This one
describes a system being **attacked by its own tests** — and what we
learned letting the adversary teach us.

Xudanu accepts documents from untrusted boundaries: WebSocket clients,
federation peers, restored chunk stores. The question that started
this work was blunt:

> *"When we were trying out the network sharing, did we investigate
> whether one side could poison the structures they were sharing?"*

The honest answer was: partly. Signature enforcement, BLAKE3 content
hashes, and PBFT governance existed. But nobody had systematically
asked **what happens to malformed structure** — the layer *beneath*
cryptographic trust. This paper records how we built that layer, the
bugs it caught (including two that surprised us), and the general
method — in the hope that other teams facing untrusted input find the
approach, if not the code, reusable.

---

## The layered answer to "can a peer poison us?"

A poisoning attempt has to survive five independent gates:

```
network bytes
   │
   ▼
1. deserialization        ← constructors bypassed HERE (surprise #1)
   │
   ▼
2. structure validation   ← the syntax gate (this paper)
   │
   ▼
3. BLAKE3 content hash    ← content ≠ claimed?
   │
   ▼
4. Ed25519 signatures     ← forged/misattributed authorship?
   │
   ▼
5. endorsement quorum     ← lone-lying-server?
   │
   ▼
integrate into store (trusted from here down)
   │
   └─ PBFT governance watches the members themselves
```

Each layer answers a different question: *is it well-formed? is it
what it claims? who wrote it? does anyone vouch?* The layers fail
independently — a perfectly-signed lie still needs structure to ride
in on.

The mathematics under each layer is well-trodden: type theory
(well-formedness), collision-resistant hashing, EUF-CMA signatures,
quorum/BFT bounds (3f+1). **What is not well-trodden is the seam
between layers** — and that is where every finding in this paper
lives.

---

## The method

Three phases, in order. The ordering matters.

### Phase 1 — the validator as invariant checklist

Before any fuzzing, write down what "valid" means as a total function
(never panics, returns a report for ANY input):

- entry positions strictly ordered, non-overlapping
- spans in-bounds, sorted, non-overlapping, non-empty
- transclusions: valid ranges, no self-cycles, bounded depth
- provenance: well-formed keys, non-zero timestamps
- size caps everywhere (a peer must not be able to memory-exhaust
  you with a "valid" document)

Design rules that earned their keep:

**Report all violations together.** An adversary probing the gate
should learn nothing from rejection order. One report, every problem.

**The validator is total.** Any input, any shape — it returns a
report. A panic in the validator is a remote DoS.

**Construction ≠ arrival.** This is surprise #1 (below) and the
single most important lesson in the paper.

### Phase 2 — property tests: no false positives

A validator that rejects good documents is worse than none. Generate
random *valid* documents (sections of text, span tilings) and assert
they always pass. This found our one false-positive class: span
tiling of degenerate single-character documents produced empty spans.

### Phase 3 — the mutation corpus: every corruption caught

Now the adversary. Construct each corruption class *the way an
attacker delivers it* — over the wire, through deserialization:

- NUL/control characters in text
- reversed transclusion ranges (start > end)
- transclusion self-cycles
- absurd ranges (char_end = 4,000,000,000)
- implausible blobs (zero-size, nonsense MIME)
- forged provenance keys, zero timestamps
- out-of-bounds/empty/overlapping spans

Then push them at a **live server** over the real WebSocket and
assert three things: an error frame comes back (citing the
validator), nothing was stored, and the server still answers the next
request. *Filtered* means error-frame-and-nothing-stored — not "a
function returned false somewhere."

### Phase 4 (next) — coverage-guided fuzzing

The mutation corpus is what we thought of. cargo-fuzz with the
property-test generators as seeds finds what we *didn't* think of.
Every crash minimizes into a new corpus entry. That is the mechanized
"generator vs detector" loop: deterministic, reproducible, forever.

---

## The surprises

These are the findings that changed how we think about the problem.

### Surprise #1: constructors heal; deserialization does not

Our reversed-range mutation (`char_start=20, char_end=5`) initially
**passed** the validator. Investigation: the `transclusion()`
constructor *normalizes* reversed ranges at construction time. Every
code path that builds documents was accidentally safe. But
deserialization constructs enum variants directly from wire bytes —
no constructor, no healing. A hostile peer sends the raw form and
bypasses every safety we "had."

**Lesson: if your safety depends on using constructors, you don't
have safety at the boundary. Validate after deserialization or not at
all.** The test now constructs the raw enum variant exactly as serde
would.

### Surprise #2: JSON escaping ate the attack (twice)

The NUL-byte-in-text attack was initially *accepted* by the live
server — which looked like a catastrophic gate failure. The actual
cause: our test's `\u0000` was over-escaped, so the server received
the six literal characters `\u0000` (perfectly legal text) rather
than a NUL. The gate was fine; the attack never happened.

**Lesson: an adversarial test that silently stops attacking is worse
than no test** — it green-lights a false sense of coverage. Wire-level
debug prints of *what actually arrived* (not what you sent) cut the
diagnosis from hours to minutes. Attack assertions belong at the
receiver.

### Surprise #3: the self-cycle check can't run at creation time

The level-3 test caught a genuine ordering gap: `work_create` with an
entry transcluding the work *being created*. At validation time the
work id doesn't exist yet, so "references its own work" is
unevaluable — the naive check passes. Cycle validation belongs after
id assignment (on revise, where the work exists), or transclusion
sources must resolve to existing works. The test found this; no
amount of code reading had.

### The meta-lesson

All three surprises are **seam bugs** — between constructor and
deserializer, between sender and receiver, between validation time
and creation time. Layer-by-layer testing found none of them. Only
pushing real corruption through the real boundary, end to end,
surfaced them.

---

## Where this fits in the defense

The validator alone is a gate, not a defense. It becomes a defense
because:

1. **Every rejection is observable.** Violation codes map to the
   security tracker; repeated attacks from one peer accumulate toward
   governance expulsion (auto-degradation). Structure attacks don't
   just fail — they cost the attacker.
2. **The corpus compounds.** Each fuzzing crash becomes a regression
   test; the set of "known tricks" only grows.
3. **The layers are independent.** The validator's weakness (it
   can't judge truth) is the signature layer's strength, and vice
   versa.

## Reproducing

- `src/edition/document_invariants.rs` — the validator (total, 18
  violation codes) with unit, property, and mutation tests
- `poisoned_editions_rejected_over_wire` in
  `tests/integration.rs` — the live-server boundary drill

## What's next

- Wire the gate into federation peer intake (documents from other
  servers), not just client intake
- cargo-fuzz targets seeded by the property generators
- The two-server adversarial drill: an evil node serving poisoned
  editions to honest peers, end to end over the federation protocol
- Auto-degradation wiring: violation counts → PBFT Expel proposals

---

*Xudanu implements concepts from the open-sourced Udanax-Gold
codebase in the Xanadu tradition. This work was prompted by a simple
question about whether the network could be poisoned. The answer is
now: not silently, not structurally, and not without cost.*
