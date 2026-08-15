# Xudanu Chunk Store Format Specification

Version 1.0 — 2026-08-15

This document specifies the on-disk binary format for the Xudanu content-addressed
chunk store. It is intended for developers implementing compatible readers/writers
in any language.

---

## 1. Overview

The chunk store is a content-addressed storage layer where every piece of data is
identified by its BLAKE3 hash. Chunks are immutable — writing the same data twice
produces the same hash and is a no-op.

### On-Disk Layout

```
{data_dir}/
  root_manifest.json              ← bootstrap pointer (JSON)
  chunks/
    README.md                      ← auto-written, informational only
    {00}/                          ← 256 hex-prefix buckets (00..ff)
      {64-hex-blake3}.xchunk      ← one file per chunk
```

**Path formula:** `chunks/{first_2_hex_chars}/{full_64_hex}.xchunk`

Example: `chunks/a3/a3f7b2c4d5e6...64chars...e1c4.xchunk`

---

## 2. Chunk File Format

Every `.xchunk` file on disk contains:

```
+--------+-------------------+
| Byte 0 | Bytes 1..N        |
| Tag    | Payload           |
+--------+-------------------+
```

### 2.1 Content Addressing

The filename is the lowercase hex encoding of the BLAKE3 hash of the **entire file
contents** (tag byte + payload). This means:

```
filename = hex(blake3(file_contents))
```

Not `blake3(payload)` — the tag byte is included in the hash.

### 2.2 Integrity Verification

On every read, the entire file is re-hashed and compared against the filename.
Any mismatch returns a `HashMismatch` error. This detects bit rot and tampering.

### 2.3 Atomic Writes

Writes use a tmp-then-rename strategy:
1. Write payload to `{hash}.tmp`
2. `fsync()` the tmp file (if durable mode)
3. `rename()` tmp to final `.xchunk` path (atomic on POSIX)
4. `fsync()` the parent directory (if durable mode)

Stale `.tmp` files are cleaned up on `ChunkStore::open()`.

### 2.4 Hash Algorithm

**BLAKE3** (no key, no salt, no context). Input: raw file bytes. Output: 32 bytes.

```python
# Reference implementation (Python)
import blake3

def compute_hash(data: bytes) -> bytes:
    return blake3.blake3(data).digest()
```

```rust
// Rust reference
fn compute_hash(data: &[u8]) -> [u8; 32] {
    blake3::hash(data).into()
}
```

---

## 3. Format Tags

The first byte of every chunk identifies its serialization format:

| Tag | Hex  | ASCII | Serialization       | Used By                          |
|-----|------|-------|---------------------|----------------------------------|
| `0x4A` | `4A` | `J`   | JSON                | Section chunks (legacy)          |
| `0x50` | `50` | `P`   | Postcard            | Edition chunks                   |
| `0x52` | `52` | `R`   | Postcard            | Root chunk tree                  |

### 3.1 Tag Semantics

- **`0x4A` (JSON):** Payload is raw UTF-8 JSON. No length prefix. Read to EOF.
  **NOTE:** The tag byte `0x4A` exists as a constant but is currently NOT written by
  any code path. Section chunks (`write_section_chunk`) write raw JSON with NO tag
  byte at all. This tag is reserved for future use.

- **`0x50` (Postcard):** Payload is postcard v1 compact binary format. No length
  prefix — read to EOF, then deserialize.

- **`0x52` (Root Postcard):** Same as `0x50` but signals this is a root-chunk-tree
  entry. Same postcard serialization. The separate tag allows readers to
  distinguish edition chunks from root chunks without knowing the struct layout.

### 3.2 Untagging

```
tag = data[0]
payload = data[1..]
```

If `data` is empty, the chunk is corrupt.

---

## 4. Serialization: Postcard

Edition chunks and root chunks use [postcard v1](https://docs.rs/postcard/1) with
the `alloc` feature. Postcard is a compact binary serde format.

### 4.1 Postcard Wire Encoding Rules

| Type              | Encoding                                  |
|-------------------|-------------------------------------------|
| `u8`              | 1 byte                                    |
| `u32`             | Varint (1-5 bytes)                        |
| `u64`             | Varint (1-9 bytes)                        |
| `i64`             | ZigZag + varint                           |
| `bool`            | 1 byte: `0x00` = false, `0x01` = true     |
| `Option<T>`       | 1 byte: `0x00` = None, `0x01` = Some(T)   |
| `Vec<T>`          | Varint length + elements                  |
| `String`          | Varint length + UTF-8 bytes              |
| `[u8; N]`         | 1-byte length (0x20 for 32) + N bytes   |
| `BTreeMap<K,V>`   | Varint length + sorted (K,V) pairs       |
| `struct`          | Fields in declaration order, no names    |
| `enum`            | 1-byte variant index + variant fields     |

### 4.2 Critical: Field Order Matters

Postcard serializes struct fields **positionally** (by declaration order), not by
field name. Any compatible implementation MUST use the exact same field order.

### 4.3 Serde Attributes

The following serde attributes are used on chunk structs:

- `#[serde(default)]` — Field defaults to `Default::default()` if missing during
  deserialization. Used for backward-compatible field additions. Postcard handles
  this correctly.
- `#[serde(skip_serializing_if = "...")]` — **NEVER use this on any type that is
  serialized with postcard.** Postcard is positional: skipping a field during
  serialization shifts all subsequent fields, causing deserialization failures
  ("bool that wasn't 0 or 1", "Option discriminant that wasn't 0 or 1"). This was
  a real bug: `WorkChunkRef.endorsements` originally had it and corrupted every
  chunk containing an empty endorsements list. It has been removed.

### 4.4 Format Versioning

Every root-tree chunk struct begins with a `format_version: u32` field
(`#[serde(default)]`). Current version: `1` (`ROOT_CHUNK_FORMAT_VERSION`).

- **v0** (implicit, absent field): chunks written before versioning was
  introduced. Readers should treat a missing/0 version as legacy.
- **v1**: current. Added the `format_version` field itself.
- **Future**: breaking wire-format changes MUST increment this field. Readers
  reject chunks with a format_version higher than they support. Additive changes
  (new optional fields at the END of a struct with `#[serde(default)]`) do NOT
  require a version bump.

The same version number appears as `format_version` in `root_manifest.json`
and in `ServerRootChunk`.

---

## 5. Edition Chunks (Tag `0x50`)

Edition chunks store document content — the actual text, spans, and transclusions
that make up a Xudanu document.

### 5.1 Chunk Types

#### EditionRootChunk

```
struct EditionRootChunk {
    default: Option<RangeElement>,
    domain_start: Option<i64>,
    domain_infinite_above: bool,
    entry_count: u32,
    entry_chunk_hashes: Vec<[u8; 32]>,
    provenance_hash: Option<[u8; 32]>,    // #[serde(default)]
}
```

#### EntryChunk

```
struct EntryChunk {
    entries: Vec<(i64, RangeElement)>,
    provenances: Vec<Option<ElementProvenance>>,  // #[serde(default)]
}
```

Maximum 256 entries per EntryChunk (`ENTRIES_PER_CHUNK = 256`).

#### ProvenanceChunk

```
struct ProvenanceChunk {
    spans: Vec<SpanProvenance>,
}
```

### 5.2 EditionChunkRef (Handle)

```
struct EditionChunkRef {
    root_hash: [u8; 32],   // BLAKE3 of EditionRootChunk file
    entry_count: u32,       // total entries (metadata hint)
}
```

### 5.3 Chunk Graph

```
EditionChunkRef
  └── root_hash → EditionRootChunk
        ├── entry_chunk_hashes[0] → EntryChunk (up to 256 entries)
        ├── entry_chunk_hashes[1] → EntryChunk
        ├── ...
        └── provenance_hash? → ProvenanceChunk
```

### 5.4 WorkChunkRef (Handle, NOT stored as chunk)

```
struct WorkChunkRef {
    be_id: u64,
    owner: Option<u64>,
    revision_count: u64,
    current_root: EditionChunkRef,
    history: BTreeMap<u64, EditionChunkRef>,
    read_club: Option<u64>,
    edit_club: Option<u64>,
    sponsors: Vec<u64>,
    endorsements: Vec<(u64, u64)>,
}
```

`WorkChunkRef` is stored in the manifest, NOT as a chunk. Only the
`EditionChunkRef` values it contains point to on-disk chunks.

---

## 6. Root Chunk Tree (Tag `0x52`)

The root chunk tree replaces the monolithic `manifest.json` with a hierarchy of
content-addressed chunks. It is bootstrapped by `root_manifest.json`.

### 6.1 Bootstrap File: root_manifest.json

```json
{
  "current_root_hash": "64-char-hex-blake3",
  "previous_root_hash": "64-char-hex-blake3",
  "format_version": 1
}
```

- `current_root_hash`: Hash of the `ServerRootChunk`
- `previous_root_hash`: Hash of the prior checkpoint's root (for fallback)
- `format_version`: Must be `1`
- Stored as pretty-printed JSON in the data directory (NOT in the chunk store)

### 6.2 ServerRootChunk

Every root-tree chunk struct begins with `format_version: u32`
(`#[serde(default)]`, current value `1`), shown here and omitted from the
listings below for brevity.

```
struct ServerRootChunk {
    format_version: u32,
    sequence: u64,
    checkpoint_at: String,            // RFC 3339

    grand_map_id_counter: u64,
    session_counter: u64,
    operation_counter: u64,
    link_counter: u64,

    works_index_hash: Option<[u8; 32]>,
    clubs_index_hash: Option<[u8; 32]>,
    standalone_editions_hash: Option<[u8; 32]>,
    links_hash: Option<[u8; 32]>,
    social_hash: Option<[u8; 32]>,
    federation_hash: Option<[u8; 32]>,
    annotations_hash: Option<[u8; 32]>,
    blob_metas_hash: Option<[u8; 32]>,
    content_address_hash: Option<[u8; 32]>,
    historical_authors_hash: Option<[u8; 32]>,
    fossil_snapshots_hash: Option<[u8; 32]>,
    admin_hash: Option<[u8; 32]>,
    key_history_hash: Option<[u8; 32]>,
    system_clubs_hash: Option<[u8; 32]>,
}
```

All `Option<[u8; 32]>` fields have `#[serde(default)]`. Schema version must be `1`.

### 6.3 Index + State Chunks

#### WorksIndexChunk
```
struct WorksIndexChunk {
    entries: Vec<WorkIndexEntry>,
}

struct WorkIndexEntry {
    be_id: u64,
    work_state_hash: [u8; 32],
}
```

#### WorkStateChunk
```
struct WorkStateChunk {
    be_id: u64,
    owner: Option<u64>,
    read_club: Option<u64>,
    edit_club: Option<u64>,
    sponsors: Vec<u64>,                         // #[serde(default)]
    endorsements: Vec<(u64, u64)>,                // #[serde(default)]
    current_edition_hash: [u8; 32],
    revision_count: u64,
    history: Vec<(u64, [u8; 32])>,                // #[serde(default)]
    source_author_id: Option<u64>,
    source_fingerprint: Option<Vec<u64>>,
    lifecycle_history: Vec<WorkLifecycleEvent>,  // #[serde(default)]
    history_club: Option<u64>,
    kind: WorkKind,                             // #[serde(default)]
    license: License,                            // #[serde(default)]
    custom_title: Option<String>,
    is_source: bool,                             // #[serde(default)]
    source_edition_info: Option<String>,
    content_start_line: Option<u64>,
    content_end_line: Option<u64>,
    is_archived: bool,                           // #[serde(default)]
    revisions: Vec<RevisionMeta>,               // #[serde(default)]
}
```

#### ClubIndexChunk
```
struct ClubIndexChunk {
    entries: Vec<ClubIndexEntry>,
}

struct ClubIndexEntry {
    be_id: u64,
    club_state_hash: [u8; 32],
}
```

#### ClubStateChunk
```
struct ClubStateChunk {
    be_id: u64,
    name: Option<String>,
    signature_club: Option<u64>,
    work_root: WorkChunkRef,
    default_read_club: Option<u64>,
    default_edit_club: Option<u64>,
    is_personal: bool,
    display_name: Option<String>,
    credential: Option<Credential>,
    encrypted_signing_key: Option<EncryptedSigningKey>,
    email: Option<String>,
    verified: bool,
    members: Vec<u64>,
    sponsored_works: Vec<u64>,
}
```

#### StandaloneEditionsChunk
```
struct StandaloneEditionsChunk {
    entries: Vec<StandaloneEditionEntry>,
}

struct StandaloneEditionEntry {
    be_id: u64,
    edition_ref_hash: [u8; 32],
}
```

#### AdminChunk
```
struct AdminChunk {
    admin: AdminEntry,
    accepting_connections: bool,
    shutdown_requested: bool,
    grants: Vec<(u64, String)>,
    server_name: Option<String>,
    server_description: Option<String>,
    server_namespace_id: Option<u64>,
    public_address: Option<String>,
}
```

#### SystemClubsChunk
```
struct SystemClubsChunk {
    system_clubs: SystemClubs,
}

struct SystemClubs {
    public_club: u64,
    admin_club: u64,
    access_club: u64,
    empty_club: u64,
}
```

### 6.4 Root Chunk Tree Structure

```
root_manifest.json
  └── current_root_hash → ServerRootChunk
        ├── works_index_hash? → WorksIndexChunk
        │     └── entries[].work_state_hash → WorkStateChunk
        │           └── current_edition_hash → (EditionRootChunk, tag 0x50)
        ├── clubs_index_hash? → ClubIndexChunk
        │     └── entries[].club_state_hash → ClubStateChunk
        │           └── work_root → (WorkChunkRef, inline)
        ├── standalone_editions_hash? → StandaloneEditionsChunk
        ├── admin_hash? → AdminChunk
        ├── system_clubs_hash? → SystemClubsChunk
        ├── links_hash? → (section data, tag 0x50)
        ├── social_hash? → (section data, tag 0x50)
        ├── blob_metas_hash? → (section data, tag 0x50)
        ├── content_address_hash? → (section data, tag 0x50)
        ├── historical_authors_hash? → (section data, tag 0x50)
        ├── fossil_snapshots_hash? → (section data, tag 0x50)
        ├── annotations_hash? → (section data, tag 0x50)
        └── key_history_hash? → (section data, tag 0x50)
```

### 6.5 Section Hashes

The `links_hash`, `social_hash`, `blob_metas_hash`, etc. fields in
`ServerRootChunk` point directly to section data chunks (not index+state trees).
These are serialized postcard blobs stored directly in the chunk store with tag
`0x52`. Their structure depends on the section type (links, social, etc.) and is
defined by the server's internal types.

---

## 7. Section Chunks (No Tag)

Section chunks are written by `write_section_chunk()` and read by
`read_section_chunk()`. They use raw JSON with **NO format tag byte**.

```
// Write
json_bytes = serde_json::to_vec(data)
chunk_store.write_chunk(&json_bytes)    // no tag prefix

// Read
data = chunk_store.read_chunk(&hash)
serde_json::from_slice(&data)           // entire payload is JSON
```

These are used for generic manifest sections (links, social, blob_metas, etc.)
that are written during checkpoint. The reader knows the format implicitly (always
JSON).

---

## 8. Reading Strategy: Server Startup

On startup, the server uses the following read order:

1. Read `root_manifest.json` from the data directory
2. Hex-decode `current_root_hash`
3. Read `ServerRootChunk` from chunk store
4. Walk the tree: WorksIndexChunk → WorkStateChunks, ClubIndexChunk →
   ClubStateChunks, etc.
5. Reconstruct an in-memory `Manifest` equivalent
6. If any step fails, fall back to reading `manifest.json` directly

---

## 9. Reference Implementation

### Writing a Root Chunk (Rust)

```rust
use postcard;
use blake3;

fn serialize_root_chunk(chunk: &ServerRootChunk) -> Vec<u8> {
    let postcard_bytes = postcard::to_allocvec(chunk).unwrap();
    let mut tagged = Vec::with_capacity(1 + postcard_bytes.len());
    tagged.push(0x52);  // CHUNK_FORMAT_ROOT
    tagged.extend_from_slice(&postcard_bytes);
    tagged
}

fn write_to_store(data_dir: &Path, tagged_data: &[u8]) -> [u8; 32] {
    let hash: [u8; 32] = blake3::hash(tagged_data).into();
    let hex = hash.iter().map(|b| format!("{:02x}", b)).collect::<String>();
    let prefix = &hex[0..2];
    let dir = data_dir.join("chunks").join(prefix);
    std::fs::create_dir_all(&dir).unwrap();
    let path = dir.join(format!("{}.xchunk", hex));
    std::fs::write(&path, tagged_data).unwrap();
    hash
}
```

### Reading a Root Chunk (Python)

```python
import blake3, json, struct

def read_chunk(data_dir: str, hash_hex: str) -> bytes:
    prefix = hash_hex[:2]
    path = f"{data_dir}/chunks/{prefix}/{hash_hex}.xchunk"
    with open(path, "rb") as f:
        data = f.read()
    actual = blake3.blake3(data).hexdigest()
    assert actual == hash_hex, f"Hash mismatch: expected {hash_hex}, got {actual}"
    return data

def parse_root_manifest(data_dir: str) -> dict:
    with open(f"{data_dir}/root_manifest.json") as f:
        return json.load(f)

def read_root_chunk(data_dir: str) -> dict:
    rm = parse_root_manifest(data_dir)
    data = read_chunk(data_dir, rm["current_root_hash"])
    assert data[0] == 0x52, f"Expected tag 0x52, got 0x{data[0]:02x}"
    # Payload is postcard — deserialize with a postcard library
    # postcard_data = data[1:]
    # root_chunk = postcard.loads(postcard_data, ServerRootChunk)
```

### Writing a Root Manifest (JSON)

```python
import json

def write_root_manifest(data_dir: str, root_hash_hex: str, previous: str = None):
    manifest = {
        "current_root_hash": root_hash_hex,
        "schema_version": 1,
    }
    if previous:
        manifest["previous_root_hash"] = previous
    path = f"{data_dir}/root_manifest.json"
    with open(path, "w") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")
```

---

## 10. Compatibility Notes

### For implementers in other languages:

1. **Postcard v1** — use the `alloc` feature. The crate is Rust-only, but the
   wire format is documented: varints for integers, 1-byte enum discriminants,
   positional struct fields. A Python postcard library exists (`pycard`).

2. **BLAKE3** — widely available. The official `BLAKE3` crate (Rust), `blake3`
   (Python), or any BLAKE3 implementation.

3. **Field order is critical** — postcard serializes by field position, not name.
   Match the struct definitions exactly as specified above.

4. **`#[serde(default)]` fields** — these may be absent from older chunks. Use
   the default value for the type if the data ends before this field.

5. **Content addressing covers the tag byte** — the hash is over
   `[tag_byte || payload]`, not just the payload.

6. **Legacy files without `.xchunk` extension** — old chunks may exist as bare
   64-hex filenames. Modern implementations should check for both.

### For Rust implementations:

```toml
[dependencies]
blake3 = "1"
postcard = { version = "1", features = ["alloc"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
hex = "0.4"
```

---

## 11. Format Summary Table

| Layer         | Tag   | Serialization | On Disk             |
|---------------|-------|---------------|---------------------|
| Edition       | 0x50  | Postcard      | ChunkStore          |
| Root tree     | 0x52  | Postcard      | ChunkStore          |
| Section data  | none  | JSON          | ChunkStore          |
| Root manifest | n/a   | JSON          | root_manifest.json  |
| Legacy manifest | n/a | JSON         | manifest.json       |
