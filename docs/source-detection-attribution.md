# Source Detection & Attribution on Paste

## Introduction

When a user pastes content from a known historical source (e.g., pasting a passage from Bram Stoker's *Dracula* into a new document), the system should recognize the source and attribute the text to the original author, rather than crediting the user who performed the paste.

This document describes the source detection system, why we chose MinHash over alternatives, and how it integrates with the xudanu attribution pipeline.

## The Problem

The xudanu server tracks **who performed each edit** via cryptographic provenance. When a user pastes text, the provenance records that user as the author. This is correct for original writing, but wrong for copied source material.

For example, if a user pastes a chapter of *Dracula* into a private document, the attribution panel shows:

```
Attribution
1 spans, 1 author
david - signed
```

The user expects:

```
Attribution
1 spans, 1 author
Bram Stoker - attested (historical)
```

The system already supported historical attribution for content imported via the **Import Wizard** (which explicitly sets the historical author). What was missing was automatic detection when content arrives via a regular paste.

## How It Works

### Two-Phase Detection

When a user pastes more than 200 characters:

1. **Header Pattern Detection** (pre-existing `SourceDetect` operation) — checks for known source markers like `*** START OF THE PROJECT GUTENBERG` and extracts metadata (title, author)

2. **Content Matching** (new `ContentMatch` operation) — compares the pasted text against all previously imported source works in the system using MinHash signatures

If either method identifies a match, the system applies historical attribution to the document via the `WorkApplySourceAttribution` operation.

### Server-Side Pipeline

```
Paste (>200 chars)
    │
    ├─► Header detection (SourceDetect)
    │     └─► Gutenberg/Internet Archive pattern matching
    │
    └─► Content matching (ContentMatch)
          └─► MinHash similarity against all source works
                └─► If score >= 30%: apply_source_attribution
                      └─► Retargets provenance to historical author
                            with server-signed attestation
```

### What Changes on the Work

When attribution is applied:

- Every element in the current edition gets `ElementProvenance` with:
  - `author_type = Historical`
  - `historical_author_id` set to the matched author
  - `author_display_name` populated from the author registry
  - `author_public_key` set to the server's key (server attests on behalf of the historical author)
- A new `SpanProvenance` is added, signed with `sign_historical_attestation` (the server's signing key, not the user's)
- The work's `source_author_id` is set

## Why MinHash

### What We Considered

| Approach | Memory per book | Comparison cost | Accuracy | Complexity |
|----------|----------------|-----------------|----------|------------|
| **Full shingle HashSet** | ~425 KB (53k hashes) | O(n) set intersection | Exact Jaccard | Low |
| **MinHash** (chosen) | ~1 KB (128 × 8 bytes) | O(128) integer compare | Estimated Jaccard, ±5% | Low |
| **Bloom filter** | ~10 KB | O(k) hash lookups | Probabilistic, many false positives | Medium |
| **Full-text search** (trigram index) | ~50 KB+ | O(1) lookup | Exact substring match | High |
| **Embedding vectors** | ~4 KB | O(1) cosine similarity | Semantic, not lexical | Very high (needs model) |

### Why Not Full Shingle Fingerprinting

Storing all word-shingle hashes in a `HashSet` is the most straightforward approach — compute Jaccard similarity exactly. But for a book like Dracula (~160,000 words), each document produces ~53,000 unique 5-word shingles. At 8 bytes each, that's ~425KB per source work. Comparing a paste against 100 source works means 100 set intersections on sets of tens of thousands of elements.

### Why Not Bloom Filters

Bloom filters can test set membership efficiently, but they produce false positives. For attribution, a false positive means incorrectly tagging a user's original text as belonging to a historical author — which is worse than missing a match. MinHash gives a direct similarity estimate without this risk.

### Why Not Full-Text Search / Trigram Index

A trigram or full-text index would find exact substring matches efficiently. But we need to match **partial** pastes — a user might paste one chapter from a 30-chapter book. MinHash naturally handles partial overlap via Jaccard similarity estimation.

### Why Not Embeddings / Semantic Similarity

Embedding vectors (e.g., sentence transformers) would enable semantic matching — recognizing paraphrased content, not just exact copies. This would be the most powerful approach but requires:
- A trained model and inference runtime on the server
- Significant compute for each comparison
- More complex integration

This is a viable future enhancement, but MinHash solves the immediate problem (exact/near-exact copy detection) with minimal complexity.

### Why MinHash Won

1. **Fixed-size signatures**: 128 × 8 bytes = 1KB per document, regardless of length. A 500KB novel and a 2KB poem both produce exactly 128 hash values.

2. **Fast comparison**: Comparing two signatures is just counting matching elements across 128 integers — O(128) per comparison.

3. **Accurate enough**: For our >=30% overlap threshold, MinHash provides sufficient accuracy. The Jaccard estimate is typically within ±5% of the true value with 128 hash functions.

4. **Industry standard**: MinHash is the standard algorithm for near-duplicate detection, used by Google for web page deduplication and by search engines for document similarity.

5. **Simple implementation**: ~50 lines of Rust. No external dependencies beyond a hash function (blake3).

## Implementation Details

### Shingling

Text is broken into overlapping 5-word sequences (shingles), sampled every 3 words:

```
"The quick brown fox jumps over the lazy dog"
  → ["the quick brown fox jumps",
     "fox jumps over the lazy",
     "the lazy dog"]
```

Each shingle is hashed with blake3 to produce a 64-bit fingerprint.

### MinHash Signature

For each of 128 "bands", we apply a different hash function (band index + shingle hash via blake3) and keep the minimum value across all shingles. The result is a fixed-size array of 128 u64 values.

The key insight: **the probability that two documents have the same minimum hash value for a given band equals their Jaccard similarity**. So the fraction of matching bands across 128 bands estimates Jaccard similarity.

### Threshold

We use a **30% similarity threshold** for matching. This means:
- A paste that covers >=30% of a source work's shingles will be detected
- Short pastes (<3 shingles, roughly <15 words) are skipped
- This threshold balances false positives against detection sensitivity

### Storage

MinHash signatures are computed:
- On import (`import_source_work`)
- On server restore from snapshot (recomputed from edition text)

Signatures are **not serialized to disk** — they're recomputed on restore to avoid bloating snapshots. The computation takes ~50ms for a full novel.

### Endpoints

| Opcode | Name | Purpose |
|--------|------|---------|
| `0x0D10` | `content_match` | Compare text against all source works, return best match + score |
| `0x0D11` | `work_apply_source_attribution` | Retarget provenance on a work to a historical author |

### Frontend Flow

1. Both `VirtualizedEditor` and `CollaborativeEditor` call `onPasteText(pasteText)` when a paste exceeds 200 characters
2. `WorkspacePage.handlePasteText` calls `client.matchContent(pasteText)`
3. If a match is found (`matched: true`), it calls `client.applySourceAttribution(workBeId, authorId)`
4. The server retargets all element provenance and signs with the server key
5. The attribution panel re-queries and shows the historical author (gold color, "attested" badge)

## Future Improvements

- **User confirmation**: Prompt the user before applying attribution ("This looks like Dracula by Bram Stoker — apply historical attribution?")
- **Partial attribution**: Only retarget provenance for the pasted range, not the entire document
- **Higher threshold tuning**: 30% may be too aggressive; gather real-world data to calibrate
- **Semantic matching**: Add embedding-based similarity for paraphrased content
- **Attribution reversal**: Allow undoing incorrectly applied attribution
