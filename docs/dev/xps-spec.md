# Xanalogical Performance Suite (XPS)

**Status:** draft spec — open for community input
**Created:** 2026-09-18
**Author:** Xudanu project
**Purpose:** define a standard benchmark for comparing xanalogical
hypertext systems — the structural and performance properties that
distinguish xanalogical systems from document editors with links.

> The field needs a yardstick. Every modern "hypertext" tool hits a
> wall at scale, and there is no shared way to say "this system
> handles 50K bidirectional links with sub-100ms backlink queries."
> Without measurement, claims are marketing. With measurement, they're
> engineering.

---

## 1. Scope

This suite measures systems that implement the xanalogical model:
two-way links, transclusions, provenance, versioning. It does not
measure plain document editors, wikis with one-way links, or DAG-based
note tools. The distinction is structural: in a xanalogical system,
connections are first-class objects visible from both ends, content
can appear in multiple documents by reference, and every character
carries its history.

Systems that implement a subset are welcome to run the suite and
report partial results — the cells they can't run are the honest
measure of what's missing.

## 2. Core operations

Every operation is measured as a single action against a corpus at a
given scale. The operation is well-defined; the implementation is
free to use any internal representation.

### 2.1 Link operations

| Op | Description | Input | Output |
|---|---|---|---|
| L1 | Create typed link | Two char spans, a type | Link ID |
| L2 | Query backlinks | A document (or span) | All links pointing here, with types |
| L3 | Delete link | Link ID | Both ends updated |
| L4 | Migrate link span | A text edit near a link | Link span adjusted to follow text |
| L5 | Gather end-set | Add a span to an existing end-set | Updated set |

**L4 (span migration)** is the operation that separates xanalogical
systems from everything else. If links don't follow edits, the system
is a wiki with extra steps. Migration cost must be measured against
edit distance from the link span.

### 2.2 Transclusion operations

| Op | Description | Input | Output |
|---|---|---|---|
| T1 | Create transclusion | Source span, destination position | Transclusion ID |
| T2 | Resolve compound | A document containing transclusions | Fully rendered text |
| T3 | Deep resolve | A document with nested transclusions (depth ≥3) | Fully rendered text |
| T4 | Source edit propagation | Edit the source of a transclusion | Dependent document reflects change |

**T4 (propagation)** is the "live link" test — when the source
changes, does the transcluding document see the new content? At what
cost?

### 2.3 Provenance operations

| Op | Description | Input | Output |
|---|---|---|---|
| P1 | Author attribution | A character span | Who wrote it, when, with what key |
| P2 | Provenance verification | A document | Verify all attribution signatures |
| P3 | Provenance chain | A transcluded span | Full derivation chain to the original |

### 2.4 Content operations

| Op | Description | Input | Output |
|---|---|---|---|
| C1 | Content match | Two documents | Shared passages (backfollow) |
| C2 | Corpus-wide matching | One document vs. all others | All documents sharing content |
| C3 | Version timeline | A document | Full revision history |

**C2 (corpus-wide matching)** is the operation the literature flags
as hardest at scale — O(N × M) in the naive case. Systems that
cannot do this should report it honestly.

## 3. Scale matrix

Each operation is run at multiple corpus scales. The corpus is
deterministically generated (seeded) so results are reproducible.

| Dimension | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|---|---|---|---|---|
| Documents | 100 | 1,000 | 10,000 | 100,000 |
| Total links | 1,000 | 10,000 | 100,000 | 1,000,000 |
| Links per doc | 1 | 10 | 100 | 1,000 |
| Document size | 1 KB | 100 KB | 10 MB | — |
| Transclusion depth | 1 | 3 | 8 | 16 |
| Concurrent editors | 1 | 10 | 100 | — |

### Corpus specification

The corpus must be generated with a published seed so any
implementation can produce identical content:

- Documents: prose paragraphs with varied structure (headings, lists,
  blockquotes) — not lorem ipsum, which compresses unrealistically
- Links: distributed across documents with a power-law tail (most
  documents have few links; some are hubs with many)
- Transclusions: single-level and nested chains, including
  cross-document references
- Provenance: multiple authors, interleaved edits, some historical
  (public-domain) sources with attribution chains

### The seed corpus generator

```
xps-generate --docs 10000 --links 100000 --seed 42 --out corpus/
```

A reference implementation (Rust) will be published alongside this
spec. Implementations can port the generator or consume the output
directly.

## 4. Performance classes

| Class | Bound | UX meaning | Applies to |
|---|---|---|---|
| **Interactive** | ≤16 ms | Keystroke-time — no perceptible delay | Typing, link hover, caret moves |
| **Responsive** | ≤100 ms | Click-to-result feels instant | Link create, backlink query, open document |
| **Batch** | ≤1 s | Acceptable for explicit user action | Compound resolve, corpus matching, version diff |
| **Background** | ≤60 s | OK for indexing, compaction, sync | Full corpus reindex, anti-entropy, checkpoint |

An operation's class is determined by when a user encounters it, not
by how the implementation schedules it. A background content-match
that the user waits for is a Batch operation regardless of what the
system calls it internally.

## 5. Reporting format

Results are a matrix: operation × scale × class → pass/fail/measured.

```json
{
  "implementation": "xudanu 1.13.0",
  "date": "2026-09-18",
  "environment": "macos-arm64 / 16GB / NVMe",
  "corpus_seed": 42,
  "results": [
    {
      "op": "L2-backlink-query",
      "scale": { "docs": 10000, "links": 100000 },
      "class": "responsive",
      "measured_ms": 12,
      "bound_ms": 100,
      "pass": true
    },
    {
      "op": "C2-corpus-matching",
      "scale": { "docs": 10000 },
      "class": "background",
      "measured_ms": 45000,
      "bound_ms": 60000,
      "pass": true,
      "note": "BLAKE3 content hashing with n-gram index"
    },
    {
      "op": "T4-source-edit-propagation",
      "scale": { "transclusion_depth": 8 },
      "class": "responsive",
      "measured_ms": null,
      "pass": false,
      "note": "not implemented — dependent requires manual refresh"
    }
  ]
}
```

Honest reporting means: `pass: false` with a note is more valuable
than omitting the row. The suite is diagnostic, not promotional.

## 6. What this suite does NOT measure

- **UI/UX quality** — a separate evaluation
- **CRDT convergence correctness** — a correctness test suite, not a
  performance benchmark
- **Federation latency** — network-dependent; a separate suite
- **Storage efficiency** — interesting but secondary to operation
  latency (the user's experience is time, not bytes)

These may become companion suites. Operation latency is the core.

## 7. Relationship to existing work

| Prior art | Relationship |
|---|---|
| H(G) hypertextuality profile | Measures structural QUALITY; XPS measures operational PERFORMANCE. Complementary. |
| SPEC benchmarks | Inspiration for the matrix format and reproducibility requirements |
| TPC (database) | Inspiration for the scale tiers and operation definitions |
| Nelson's writings | The operations are drawn from the Xanadu literature's stated requirements |
| Udanax Gold performance notes | Historical reference point; the original implementation's observed limits |

## 8. Open questions

1. Should concurrent-editor performance be a core cell or a separate
   suite? (It's hard to standardize across implementations with
   different consistency models.)
2. Should there be a "cold start" class (system boot + full corpus
   load)?
3. Is 16ms the right Interactive bound for web-based implementations
   vs native? (Browser event loop overhead varies.)
4. Should storage size be a secondary metric in each cell?

## 9. Call for participation

This suite is meaningless with one implementation. If you're building
a xanalogical system — or a tool that implements a subset of the
model — run the suite and publish your results. Red cells are as
welcome as green ones. The point is to make the field's hard problems
visible and its progress measurable.

Contact: open an issue or PR on this document's repository.

---

*XPS is developed as part of the Xudanu project (Apache 2.0). The
spec and reference generator are open source. Xudanu is an
independent project, not affiliated with Project Xanadu™ or the
Udanax development team.*
