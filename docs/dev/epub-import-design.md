# EPUB Import — Implementation Spec

> Adds EPUB file import to Xudanu. Uses `cli-epub-to-text` for text
> extraction and `epub` crate for metadata. Follows the existing
> `import_source_work` pipeline for source work creation.

## Architecture

```
Browser                    Server
───────                    ──────
File picker        →     receive .epub bytes
                         │
                         ├─ epub::EpubDoc::from_data()
                         │   → title, author from OPF metadata
                         │
                         ├─ cli_epub_to_text::epub_bytes_to_text()
                         │   → plain text, spine-ordered, HTML stripped
                         │
                         ├─ find_or_create_historical_author(author)
                         │
                         └─ import_source_work(author, title, text, ...)
                             → creates immutable source work
                             → signed with server key
                             → returns work_id
```

## Dependencies

```toml
[target.'cfg(not(target_arch = "wasm32"))'.dependencies]
epub = "2.1"                  # metadata extraction (title, author)
cli-epub-to-text = "0.1"      # text extraction (HTML→plain text via html2text)
```

Both MIT licensed. `cli-epub-to-text` already depends on `epub` v2.1.5, so
no extra transitive dependencies.

## Crate APIs

### epub (metadata)

```rust
use epub::doc::EpubDoc;

let doc = EpubDoc::from_data(&epub_bytes)
    .map_err(|e| ServerError::InvalidArgument(format!("EPUB parse: {}", e)))?;

let title = doc.mdata("title").and_then(|v| v.first().cloned());  // Option<String>
let author = doc.mdata("creator").and_then(|v| v.first().cloned()); // Option<String>
```

### cli-epub-to-text (text)

```rust
use cli_epub_to_text::epub_bytes_to_text;

let text = epub_bytes_to_text(&epub_bytes)
    .map_err(|e| ServerError::InvalidArgument(format!("EPUB text: {}", e)))?;
// text is plain text, chapters in spine order, HTML tags stripped
```

## Wire Op

### Protocol

```rust
// In WireRequest enum
ImportEpub {
    epub_data: Vec<u8>,           // raw .epub file bytes
    title: Option<String>,        // override if metadata is wrong
    author: Option<String>,       // override if metadata is wrong
    skip_prefix_lines: u64,       // skip boilerplate (default 0)
    skip_suffix_lines: u64,       // skip boilerplate (default 0)
},
```

Response reuses existing `ImportSourceWorkResult`:
```rust
ImportSourceWorkResult {
    work_id: BeId,
    author_id: BeId,
    title: String,
    text_length: u64,
}
```

### Opcode

`0x0D0D` for `ImportEpub` (next after `ImportSourceWork` at `0x0D0C`)

### Codec

JSON-only (EPUB data is binary, sent as array of bytes in JSON):

```rust
OperationCode::ImportEpub => {
    #[derive(Deserialize)]
    struct Args {
        epub_data: Vec<u8>,
        #[serde(default)]
        title: Option<String>,
        #[serde(default)]
        author: Option<String>,
        #[serde(default)]
        skip_prefix_lines: u64,
        #[serde(default)]
        skip_suffix_lines: u64,
    }
    let args: Args = serde_json::from_value(p)
        .map_err(|e| ProtocolError::Serialization(e.to_string()))?;
    Ok(WireRequest::ImportEpub { ..args })
}
```

**Note:** Binary protocol not supported for this op (EPUB data is too large
for the binary frame format). Client must use JSON WebSocket.

## Server Method

```rust
pub fn import_epub(
    &mut self,
    session_id: SessionId,
    epub_data: &[u8],
    title_override: Option<&str>,
    author_override: Option<&str>,
    skip_prefix: u64,
    skip_suffix: u64,
) -> Result<(BeId, BeId, u64, String), ServerError> {
    self.ensure_logged_in(session_id)?;

    // 1. Extract metadata from EPUB
    let doc = epub::doc::EpubDoc::from_data(epub_data)
        .map_err(|e| ServerError::InvalidArgument(
            format!("EPUB metadata parse failed: {}", e)
        ))?;

    let title = title_override.map(String::from)
        .or_else(|| doc.mdata("title").and_then(|v| v.first().cloned()))
        .unwrap_or_else(|| "Untitled".to_string());

    let author_name = author_override.map(String::from)
        .or_else(|| doc.mdata("creator").and_then(|v| v.first().cloned()))
        .unwrap_or_else(|| "Unknown Author".to_string());

    // Drop doc to free memory before text extraction
    drop(doc);

    // 2. Extract plain text
    let text = cli_epub_to_text::epub_bytes_to_text(epub_data)
        .map_err(|e| ServerError::InvalidArgument(
            format!("EPUB text extraction failed: {}", e)
        ))?;

    if text.is_empty() {
        return Err(ServerError::InvalidArgument(
            "EPUB text extraction returned empty text".into()
        ));
    }

    // 3. Find or create historical author
    let author_id = self.find_or_create_historical_author(&author_name)?;

    // 4. Import as source work (reuses existing pipeline)
    let edition_info = format!("EPUB import: {} by {}", title, author_name);
    self.import_source_work(
        session_id,
        author_id,
        title,
        text,
        edition_info,
        skip_prefix,
        skip_suffix,
    )
}
```

### Historical author lookup

```rust
fn find_or_create_historical_author(&mut self, name: &str) -> Result<BeId, ServerError> {
    // Search existing authors
    let existing = self.historical_authors.search_by_name(name);
    if let Some(author) = existing.into_iter().next() {
        return Ok(author.id);
    }
    // Create new
    let author_id = self.historical_authors.register(name, None, None)?;
    Ok(author_id)
}
```

## Client API

```typescript
// In crdt_sync.ts
async importEpub(
    epubData: Uint8Array,
    title?: string,
    author?: string,
    skipPrefixLines: number = 0,
    skipSuffixLines: number = 0,
): Promise<{ workId: number; authorId: number; title: string; textLength: number }> {
    const resp = await this.sendRequest("import_epub", {
        epub_data: Array.from(epubData),  // Uint8Array → number[] for JSON
        title: title ?? null,
        author: author ?? null,
        skip_prefix_lines: skipPrefixLines,
        skip_suffix_lines: skipSuffixLines,
    });
    const val = extractValue(resp) as Record<string, unknown>;
    return {
        workId: (val.work_id as number) || 0,
        authorId: (val.author_id as number) || 0,
        title: (val.title as string) || "",
        textLength: (val.text_length as number) || 0,
    };
}
```

### Size concern

EPUB files can be 1-50MB. Sending as JSON array of bytes inflates
size ~4x (each byte becomes "123,"). For files >5MB, consider:

**Option A: Direct WebSocket binary frame**
- Send raw bytes as a binary WebSocket message
- Server recognizes the binary frame, parses as EPUB
- More efficient but requires protocol changes

**Option B: Blob upload + reference**
- Upload .epub via existing `blob_upload` HTTP endpoint
- Call `import_epub` with the blob hash
- Server reads from blob store
- Cleanest separation, uses existing infrastructure

**Recommendation: Option B for production, Option A (inline) for v1.**

## UI

### In workspace Create menu or ImportWizard

```
┌──────────────────────────────────────┐
│ Import from EPUB                     │
│ ──────────────────────────────────── │
│                                      │
│ [📁 Choose .epub file…]              │
│                                      │
│ Detecting metadata…                  │
│   Title:  If on a winter's night…    │
│   Author: Italo Calvino              │
│                                      │
│ [Import as source work]              │
│                                      │
│ Source works are immutable.          │
│ They can be transcluded from but     │
│ not edited.                          │
└──────────────────────────────────────┘
```

### File reading (browser)

```typescript
const handleEpubFile = async (file: File) => {
    // Read file into Uint8Array
    const arrayBuffer = await file.arrayBuffer();
    const epubData = new Uint8Array(arrayBuffer);

    // Show file size warning if large
    if (epubData.length > 5_000_000) {
        if (!confirm(`This EPUB is ${(epubData.length / 1_000_000).toFixed(1)}MB. Continue?`)) {
            return;
        }
    }

    // Import
    const result = await client.importEpub(epubData);
    // result.title and result.author auto-detected from EPUB metadata
    selectWork(result.workId);
};
```

## Implementation Phases

### Phase 1: Backend (1 day)

- [ ] Add `epub` and `cli-epub-to-text` to Cargo.toml (server feature)
- [ ] Add `ImportEpub` to WireRequest enum
- [ ] Add opcode `0x0D0D`
- [ ] Add codec handler (JSON)
- [ ] Add dispatch handler
- [ ] Add `import_epub()` server method
- [ ] Add `find_or_create_historical_author()` helper
- [ ] Build + verify no dependency conflicts
- [ ] Test: parse a small EPUB, verify text extraction

### Phase 2: Client API (half day)

- [ ] Add `importEpub()` to `crdt_sync.ts`
- [ ] Add file picker UI in workspace
- [ ] Progress indicator for large files
- [ ] Navigate to imported work on success
- [ ] Error handling (corrupt EPUB, empty text, auth required)

### Phase 3: Polish (half day)

- [ ] Show detected metadata before import (confirm dialog)
- [ ] Auto-create Person work for author (FR-22 integration)
- [ ] Set imported work kind to "Document" (or "Fragment" for short texts)
- [ ] Add "Import EPUB" button to Library tab

## What Gets Created

For an EPUB of "If on a winter's night a traveler" by Italo Calvino:

| Entity | What | Kind |
|---|---|---|
| **Source work** | Full text of the book | Document (is_source=true, immutable) |
| **Historical author** | "Italo Calvino" | Server-side metadata |
| **Person work** (optional Phase 3) | "Italo Calvino" | Person |
| **Link** (optional Phase 3) | Source work → Person work | See Also |

The source work:
- `title`: "If on a winter's night a traveler" (from EPUB metadata)
- `source_author_id`: historical author ID
- `source_edition_info`: "EPUB import: If on a winter's night… by Italo Calvino"
- `is_source`: true (immutable, can transclude from)
- `content_start_line` / `content_end_line`: adjusted by skip params

## Error Handling

| Error | Cause | User message |
|---|---|---|
| "EPUB metadata parse failed" | Corrupt ZIP, missing OPF | "Could not read EPUB metadata. File may be corrupt." |
| "EPUB text extraction failed" | Malformed XHTML in spine | "Could not extract text from this EPUB." |
| "EPUB text extraction returned empty" | No text content (images only) | "This EPUB contains no extractable text." |
| "not logged in" | Anonymous user | "Sign in to import EPUB files." |
| "historical author not found" | Internal error | "Could not register author. Please try again." |

## Limitations

1. **DRM-protected EPUBs** will fail (can't decrypt)
2. **Image-heavy EPUBs** (comics, illustrated books) produce little text
3. **Fixed-layout EPUBs** may have poor text extraction
4. **Large files (>10MB)** may timeout over WebSocket
5. **Non-Latin scripts** should work (html2text handles Unicode) but untested

## References

- `cli-epub-to-text` docs: https://docs.rs/cli-epub-to-text
- `epub` crate docs: https://docs.rs/epub
- Existing `import_source_work`: `server.rs:4040`
- Existing `importSourceWork` client: `crdt_sync.ts:775`
