# FR-35: Bloom Filter Federation Layer

## Overview

Probabilistic content discovery for the Xudanu docuverse. Servers exchange
compact Bloom filters instead of full work lists, reducing federation sync
bandwidth by ~170x for 10K works.

## Background: Crums

A **crum** is a BLAKE3 hash (32 bytes) that uniquely identifies the content
of an enfilade subtree. Two subtrees with the same crum are guaranteed
content-identical.

### Crum types in Xudanu

| Level | Computed from | Sensitivity |
|---|---|---|
| **Leaf crum** | hash("leaf:" + region + position:fingerprint + default) | Content + position |
| **Split crum** | hash("split:" + split_region + in_child.crum + out_child.crum) | Structure + children |
| **Dsp crum** | hash("dsp:" + offset + child.crum) | Offset + child |
| **Root crum** (OrglRoot) | Stored at OrglRoot level, O(1) lookup | Full tree identity |

### Key crum properties

- **Deterministic**: Same content at same positions = same crum, always
- **Structure-sensitive**: Same text in different tree structures = different crum
- **Edit-sensitive**: One character change = completely new crum
- **Revision-sensitive**: Each revision has a different crum
- **Collision-resistant**: BLAKE3, 256-bit — collisions effectively impossible

## Bloom Filter Design

### What goes in the filter

**Layer 1: Work ID filter (for sync/dedup)**

```
Items: work IDs (u64) — 0x1, 0x2, 0x3, ...
Answers: "Does this server have work X?"
False negatives: NEVER
False positive rate: ~1% (tunable)
Stability: Work IDs don't change across revisions
```

**Layer 2: Content hash filter (for version matching)**

```
Items: BLAKE3(resolved_text) — content hash, NOT crum
Answers: "Does this server have this exact text content?"
False negatives: NEVER
False positive rate: ~1%
Stability: Changes on edit (by design — detects updates)
```

### Why NOT crums in the filter

| Problem | Impact | Example |
|---|---|---|
| **Structure-sensitive** | False negatives — same content, different tree | Server A: "hello" as 1 entry, Server B: as 5 per-char entries. Filter says "not present" |
| **Revision-sensitive** | Can't answer "any version of work X?" | Server has rev 4, filter checked for rev 3's crum → "not present" |
| **Coalesce-sensitive** | After coalesce, crum changes even though content is same | Pre-coalesce and post-coalesce produce different crums |

### Recommended approach

Use **work IDs** for existence checks (stable across revisions), then
**compare crums** for precise version matching (after work ID matches).

```
1. Check work ID in Bloom filter → "B has work 0x42?" → YES (definitive)
2. Compare crums → "Is B's revision same as mine?" → NO (different revision)
3. Fetch the newer revision
```

## Text Documents vs Images

### Text documents

- **Size**: 1KB - 100KB typically
- **Bloom filter item**: Work ID (8 bytes)
- **Sync cost without filter**: Full work list JSON (~200 bytes per work metadata)
- **Sync cost with filter**: 1 bit in Bloom filter (~1.2 bits per item at 1% FPR)
- **Benefit**: Large — many small text documents, metadata overhead dominates

### Images / blobs

- **Size**: 100KB - 10MB typically
- **Bloom filter item**: Content hash (32 bytes, BLAKE3)
- **Current dedup**: `BlobStore` already deduplicates by hash
- **Bloom filter benefit**: Cross-server dedup — before downloading a 5MB image,
  check if any trusted server already has it
- **Challenge**: Images are stored in blob store (by hash), not in the enfilade
  tree. The Bloom filter would need to cover blob hashes separately.

### Recommended: Two separate filters

```
text_filter:    Bloom filter of work IDs (for document sync)
blob_filter:    Bloom filter of blob content hashes (for image dedup)
```

Text filter is small (thousands of works = ~12KB). Blob filter is larger
(thousands of images = ~12KB) but saves megabytes of transfer.

## Bloom Filter Sizing

| Items | FPR | Filter size | Hash functions | Bits per item |
|---|---|---|---|---|
| 100 | 1% | 120 bytes | 7 | 9.6 |
| 1,000 | 1% | 1.2 KB | 7 | 9.6 |
| 10,000 | 1% | 12 KB | 7 | 9.6 |
| 100,000 | 1% | 120 KB | 7 | 9.6 |
| 10,000 | 0.1% | 18 KB | 10 | 14.4 |
| 10,000 | 0.01% | 24 KB | 12 | 19.2 |

**Rule of thumb**: ~10 bits per item at 1% FPR. 10K works = ~12KB filter.
Compare to fetching 10K work metadata entries at ~200 bytes each = 2MB.

**170x bandwidth reduction** for existence checks.

## Failure Modes & Security

### 1. False positives (inherent)

**What**: Filter says "maybe present" when item doesn't exist.
**Rate**: ~1% at default sizing. Tunable to 0.01% with 2x filter size.
**Impact**: Unnecessary fetch request → 404 response. Wasted bandwidth,
  no data loss.
**Mitigation**: Always follow "maybe" with definitive HTTP fetch. Filter
  is a hint, never authority.

### 2. Filter poisoning

**What**: Malicious server sends a Bloom filter with all bits set to 1.
**Effect**: Every query returns "maybe present" — filter becomes useless.
**Impact**: No data loss, no security breach. Just denial of service for
  the optimization. Falls back to full work list fetch.
**Mitigation**: Detect all-ones filter, reject with warning. Or use
  signed filters (server Ed25519 signature on filter contents).

### 3. Stale filter

**What**: Server A caches server B's filter. B publishes new works.
  A's cached filter doesn't include them.
**Effect**: A doesn't discover B's new works until filter is refreshed.
**Impact**: Delayed discovery, not data loss. Works eventually appear
  on next filter exchange.
**Mitigation**: Timestamp filters, re-exchange periodically (e.g., every
  5 minutes), or push notification on publish.

### 4. Deletion handling

**What**: Standard Bloom filters don't support deletion. Work deleted from
  B, but filter still says "maybe present".
**Effect**: Other servers try to fetch deleted work → 404.
**Impact**: Confusing error messages, wasted request. No data corruption.
**Mitigation**: Use counting Bloom filter (4 bits per cell instead of 1)
  or rebuild filter from scratch on checkpoint (every 30 seconds).

### 5. False negative (impossible by construction)

**What**: Filter says "definitely not present" when item IS present.
**Probability**: Zero. This is the fundamental guarantee of Bloom filters.
**Note**: This only holds if the filter was correctly constructed from
  the actual content. A corrupted filter (bit flip in transit) could
  cause false negatives. Mitigation: checksum/sign the filter.

### 6. Man-in-the-middle filter substitution

**What**: Attacker replaces B's filter with an empty filter (all zeros).
**Effect**: A thinks B has no content. Doesn't fetch from B.
**Impact**: Content from B is invisible to A. Docuverse connectivity
  broken between A and B.
**Mitigation**: Sign filters with Ed25519. Verify signature before use.
  We already have server signing keys and TOFU trust model.

### 7. Filter size inflation attack

**What**: Malicious server sends a very large filter (100MB) claiming
  to have millions of works.
**Effect**: Memory exhaustion on receiving server.
**Impact**: DoS — server crashes or slows.
**Mitigation**: Reject filters larger than max expected size (e.g., 1MB
  = ~80K works at 1% FPR). Reject if claimed item count is implausible
  for the server's directory entry.

## IPFS Comparison

### IPFS and Bloom filters

IPFS uses a **Distributed Hash Table (DHT)** for content discovery, not
Bloom filters. The DHT maps content hashes to provider nodes. Bloom filters
could complement the DHT as a local pre-filter ("does this node likely have
content X before I do a DHT lookup?").

### Why IPFS is struggling

IPFS is not winding down per se — v0.41.0 released April 2026. But it faces
structural challenges:

1. **Performance**: DHT lookups are slow (multiple round trips). No guarantee
   of proximity-aware routing. Content can be anywhere in the network.

2. **Incentive problem**: Storage is voluntary. Content disappears when nodes
   go offline ("garbage collection"). Filecoin tried to solve this with
   paid storage, but adoption is limited.

3. **Centralization drift**: Most users access IPFS through centralized
   gateways (Cloudflare, Pinata) rather than running their own nodes. This
   defeats the decentralization goal.

4. **Browser support removed**: Brave removed IPFS support in 2024 due to
   low usage. No major browser supports `ipfs://` natively.

5. **Complexity**: Full IPFS node requires significant resources (disk, RAM,
   bandwidth for DHT maintenance). Not practical for casual users.

### Lessons for Xudanu

| IPFS problem | Xudanu approach |
|---|---|
| Slow DHT lookups | Direct server-to-server HTTP (trusted peers only) |
| Content disappears | Servers are authoritative (no voluntary storage) |
| Centralized gateways | Each server is self-hosted, Caddy for HTTPS |
| No browser support | Web-native (HTTP + WebSocket, no special protocol) |
| High resource usage | Lightweight (Rust binary, ~50MB RAM, Docker) |

**Key difference**: Xudanu's federation is trust-based (signed introductions,
TOFU), not open (anyone can join). This makes Bloom filters simpler — we
only exchange filters with trusted servers, reducing poisoning risk.

## Implementation Plan

### Phase 1: Server-side filter construction (1 day)

```rust
pub struct ServerBloomFilter {
    bits: Vec<u64>,
    num_hashes: usize,
    item_count: usize,
    timestamp: u64,
}

impl Server {
    pub fn build_bloom_filter(&self) -> ServerBloomFilter {
        let count = self.works.len() + self.blob_store.len();
        let mut filter = ServerBloomFilter::new(count, 0.01);
        for (id, _) in &self.works {
            filter.insert(&id.to_le_bytes());
        }
        filter
    }
}
```

### Phase 2: Wire protocol (1 day)

- `server_bloom_filter` wire op: returns the filter
- `server_bloom_check` wire op: "do you have work X?" (definitive)
- Signed with server Ed25519 key

### Phase 3: Integration with existing features (1 day)

- Federated search: pre-filter servers by Bloom before querying
- Cross-server browse: check filter before fetching work list
- Blob dedup: check filter before downloading images

### Phase 4: Security hardening (1 day)

- Filter signature verification
- Size limits and sanity checks
- Staleness detection (timestamp comparison)
- Fallback to full work list if filter is suspicious

**Total: ~3-4 days**

## Test Plan

| Test | Description |
|---|---|
| `bloom_filter_basic` | Insert N items, verify all present |
| `bloom_filter_false_positive_rate` | Insert 10K items, check 10K random non-items, verify FPR < 2% |
| `bloom_filter_false_negative_never` | Insert N items, verify 0 false negatives |
| `bloom_filter_signed` | Sign filter, verify signature, reject tampered |
| `bloom_filter_size_limit` | Reject filters > 1MB |
| `bloom_filter_stale` | Detect filter older than threshold, re-fetch |
| `federated_search_with_bloom` | Search across servers, only query relevant ones |
| `blob_dedup_with_bloom` | Don't download blob already present on trusted server |

## Relationship to Other FRs

- **FR-31** (cross-server): Bloom filter is an optimization layer on top
- **FR-32** (security): Signed filters, poisoning detection
- **FR-34** (enfilade-native): Crums are the content identity layer
- **FR-36** (future): DHT-like content routing (if needed)
