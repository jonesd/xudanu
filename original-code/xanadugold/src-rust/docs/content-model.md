# The Udanax Gold Content Model

## The Core Idea

In the Udanax Gold model, **content is identity**. The bytes "abcd" are not just
text that happens to read "abcd" — they ARE "abcd", and every occurrence of
"abcd" in the system shares the same identity. This is content-addressing, and
it is the foundation of everything else: transclusion, versioning, and
conflict preservation.

## How Content Is Stored

### The O-Tree

Every document (called a "work") is an **O-tree** — an ordered sequence of
**RangeElements**. Each element is one of:

| Element | What it holds | Example |
|---------|--------------|---------|
| `Text` | A string fragment | `"abcd"` |
| `Data` | Small inline binary | A few bytes of metadata |
| `Blob` | Reference to a large binary (image, file) | Hash + mime type |
| `Overlay` | Derived content: base blob + operations | Image with brightness adjustment |

### The GrandMap

All content elements are registered in a **GrandMap** — a global
content-addressed store. When the system encounters content, it:

1. Computes the content's identity (hash)
2. Checks if that identity already exists in the GrandMap
3. If yes: reuses the existing `BeId` (the content's unique identifier)
4. If no: assigns a new `BeId` and stores it

**The key insight**: if "abcd" appears in document A and "abcd" appears in
document B — whether typed, copy-pasted, or generated — both resolve to the
same `BeId`. The storage is shared at the most fundamental level.

### What This Means for "abcd"

```
Document A: [The word ]["abcd"][ is common]
Document B: [We use ]["abcd"][ as an example]

GrandMap:
  BeId 1001 → "The word "
  BeId 1002 → "abcd"          ← shared between A and B
  BeId 1003 → " is common"
  BeId 1004 → "We use "
  BeId 1005 → " as an example"
```

The bytes for "abcd" are stored exactly once. Both documents point to the
same `BeId 1002`.

## Transclusion: Automatic, Not Manual

### You do NOT need copy/paste

A common misconception is that transclusion requires an explicit copy/paste
operation to create the link. It does not. In the Gold model:

- **Typing "abcd" twice** → both resolve to the same BeId
- **Copy-pasting "abcd"** → also resolves to the same BeId
- **"abcd" appearing in an image overlay description** → still the same BeId

The connection is **structural**, not **procedural**. The system doesn't care
*how* the content got there — it only cares *what* the content is.

### How This Differs from Search

| Aspect | Search | Gold Content-Addressing |
|--------|--------|------------------------|
| When discovered | At query time | At storage time |
| Survives revisions | No — must re-run | Yes — identity is structural |
| Semantic meaning | "This text matches" | "This IS the same content" |
| Cross-document | Requires scanning all docs | Instant via TransclusionIndex |
| Precision | May find false positives | Exact: same bytes = same identity |

Search says "I found text that looks like your query." The Gold model says
"this content and that content are literally the same thing."

### The TransclusionIndex

The system maintains a **TransclusionIndex** that maps each `BeId` to the
works and positions that reference it. When content is stored:

1. The content is registered in the GrandMap (deduplication)
2. The `BeId` is indexed in the TransclusionIndex
3. The work + position is recorded as referencing that `BeId`

Querying "who else uses this content?" is an O(1) lookup, not a full-text
scan.

## Practical Examples

### Example 1: Quoted Code

A programming tutorial quotes a function signature:

```
Document A (tutorial): "The main function is `fn main() -> Result<(), Box<dyn Error>>`"
Document B (reference): "fn main() -> Result<(), Box<dyn Error>> { ... }"
```

The shared text `fn main() -> Result<(), Box<dyn Error>>` gets the same
`BeId` in both documents. The tutorial automatically transcludes the
reference. If the reference updates the signature, the tutorial's
transclusion is detectable (the old BeId no longer matches the new content).

### Example 2: Legal Documents

A contract references a clause that appears in multiple other contracts:

```
Contract A: "...subject to the terms in Section 4.2 (Limitation of Liability)..."
Contract B: "Section 4.2: Limitation of Liability. The total liability..."
Contract C: "...as defined in Section 4.2 (Limitation of Liability)..."
```

"Limitation of Liability" in all three contracts shares the same `BeId`. The
system knows A and C both reference the content defined in B — without anyone
explicitly creating links.

### Example 3: Scientific Papers

A paper cites a finding:

```
Paper A: "The measurement was 42.7 ± 0.3 nm (Smith et al., 2024)"
Paper B: "We reproduce the 42.7 ± 0.3 nm finding from Smith et al."
Paper C (Smith): "Result: 42.7 ± 0.3 nm"
```

The value `42.7 ± 0.3 nm` is the same content in all three. The system
detects this automatically, providing a content-based citation graph that
supplements traditional reference lists.

### Example 4: Images and Media

Two documents include the same photograph:

```
Document A: [img: a1b2c3d4e5f6a7b8:image/png]  (photograph of a bridge)
Document B: [img: a1b2c3d4e5f6a7b8:image/png]  (same photograph)
```

The image bytes are stored once. Both documents reference `BeId` derived from
the BLAKE3 hash of the image content. The transclusion is automatic:

- If the same image is uploaded to a third document, it deduplicates instantly
- The TransclusionIndex shows all documents containing that image
- An overlay (brightness, crop, etc.) references the original, maintaining
  the transclusion link while storing only the ~50-byte operation list

### Example 5: Overlay Derivatives

An image overlay demonstrates the storage efficiency:

```
Original image:    2.4 MB (stored once)
Brightness +50%:   ~80 bytes overlay spec (new BeId, references original)
Cropped version:   ~60 bytes overlay spec (new BeId, references original)
Both combined:     ~120 bytes overlay spec (new BeId, references original)
```

Total storage: 2.4 MB + 260 bytes (not 7.2 MB for three full copies).

Each overlay's `base_hash` field creates a transclusion link back to the
original. Finding "all derived versions of this image" is a TransclusionIndex
lookup.

## Content vs. Reference

A critical distinction:

**Traditional linking**: Document A contains a *reference* (URL, citation) to
Document B. The link is separate from the content. If B changes, A's link
points to the new version (or breaks).

**Gold transclusion**: Document A contains the *actual content* from B (or
content identical to what's in B). The connection is through shared identity,
not through a reference. If B is revised, A still holds its version — the
transclusion is to the specific content, not to the document.

This is why the Gold model aimed to be conflict-preserving: two authors can edit
the same document, and the system preserves both versions in the version DAG
(the DagWood). Content identity never changes — it's content-addressed.

## Summary

| Concept | Gold Model |
|---------|-----------|
| Content identity | Determined by the bytes themselves (hash) |
| Deduplication | Automatic at storage time via GrandMap |
| Transclusion | Structural consequence of shared identity |
| Copy/paste needed? | No — same content = same identity regardless of source |
| Search vs transclusion | Search discovers matches; transclusion IS identity |
| Storage cost of copies | Zero — identical content stored once |
| Storage cost of overlays | ~50-100 bytes (operation list) regardless of media size |
| Cross-document links | Automatic via TransclusionIndex |
| Version preservation | Full DAG — all revisions preserved, nothing lost |
