# Image Rendering in Documents

> Inline image support for Xudanu documents. Uses the existing
> BlobStore for content-addressed storage, `image` + `oxipng` +
> `mozjpeg-sys` crates for server-side optimization, and
> progressive loading in the editor.

## Architecture

```
Client (browser)                    Server
────────────────                    ──────
Drag-drop / paste image
         ↓
    Read file bytes
         ↓
    blobUpload(bytes, mime)  →     BlobStore.store()
                                   │
                                   ├─ Decode (image crate)
                                   ├─ Optimize:
                                   │   PNG → oxipng (lossless)
                                   │   JPEG → mozjpeg (q=80)
                                   │   WebP → keep as-is
                                   ├─ Generate thumbnail (400px WebP)
                                   ├─ Extract dimensions
                                   └─ Store both in data/blobs/
         ↓                          ↓
    Returns BlobMeta          { hash, preview_hash, w, h, size }
         ↓
    elementInsert(position, RangeElement::Blob { hash, mime, w, h })
         ↓
    Editor renders placeholder
         ↓
    Fetches preview (small)  →     blobGetPreview(hash)
    Shows thumbnail immediately
         ↓
    Fetches full image       →     blobGet(hash)
    Swaps in when loaded
```

## Existing Infrastructure (already built)

| Component | Location | Status |
|---|---|---|
| BlobStore (content-addressed) | `edition/blob_store.rs` | ✅ Working |
| RangeElement::Blob | `edition/range_element.rs:38` | ✅ Defined |
| RangeElement::Overlay (transforms) | `edition/range_element.rs:47` | ✅ Defined |
| BlobUpload wire op (0x0901) | `transport/protocol.rs` | ✅ Working |
| BlobGet wire op (0x0902) | `transport/protocol.rs` | ✅ Working |
| BlobGetPreview wire op (0x0903) | `transport/protocol.rs` | ✅ Working |
| BlobStats wire op (0x0906) | `transport/protocol.rs` | ✅ Working |
| BlobMeta.preview_hash | `edition/blob_store.rs:10` | ✅ Field exists |
| generate_image_preview() | `edition/blob_store.rs:582` | ❌ Stub (returns None) |
| Client blob API | `api/crdt_sync.ts` | ❌ Missing |
| Editor image rendering | `CollaborativeEditor.tsx` | ❌ Missing |

## Dependencies

```toml
[target.'cfg(not(target_arch = "wasm32"))'.dependencies]
image = { version = "0.25", optional = true }
oxipng = { version = "10", optional = true }
```

- `image` — decode/encode/resize for PNG, JPEG, GIF, WebP (MIT)
- `oxipng` — lossless PNG optimization (MIT)
- JPEG optimization via `image` crate's built-in encoder (no mozjpeg-sys needed for v1)

## Phase 1: Server-side Preview + Optimization

### generate_image_preview implementation

Replace the stub in `blob_store.rs`:

```rust
fn generate_image_preview(data: &[u8]) -> Option<Vec<u8>> {
    let img = image::load_from_memory(data).ok()?;
    let thumb = img.resize_to_fill(400, 400, FilterType::Lanczos3);
    let mut buf = Vec::new();
    let mut cursor = std::io::Cursor::new(&mut buf);
    thumb.write_to(&mut cursor, ImageFormat::WebP).ok()?;
    Some(buf)
}
```

### Image optimization on upload

In `blob_upload()`, after storing the raw data, if it's an image:
1. Decode with `image` crate
2. Re-encode at optimized quality:
   - JPEG → quality 80 (typically 50-70% smaller)
   - PNG → `oxipng` lossless optimization (40-70% smaller)
   - WebP → keep as-is
3. Store optimized version (replaces raw if smaller)
4. Extract width/height

### Optimization estimate

| Type | Raw | Optimized | Savings |
|---|---|---|---|
| Phone photo (JPEG 3MB) | 3.0MB | 0.8-1.2MB | ~60% |
| Screenshot (PNG 500KB) | 500KB | 150-250KB | ~50% |
| Diagram (PNG 100KB) | 100KB | 40-60KB | ~45% |
| Thumbnail (WebP) | — | 10-30KB | — |

## Phase 2: Client Blob API

Add to `crdt_sync.ts`:

```typescript
interface BlobMeta {
  content_hash: number;
  preview_hash: number | null;
  mime_type: string;
  byte_size: number;
  width: number | null;
  height: number | null;
}

async blobUpload(data: Uint8Array, mimeType: string): Promise<BlobMeta>
async blobGet(hashU64: number): Promise<Uint8Array>
async blobGetPreview(hashU64: number): Promise<Uint8Array | null>
```

## Phase 3: Editor Rendering

CollaborativeEditor scans for `RangeElement::Blob` elements and renders them inline:

1. Detect blob markers in the O-tree (similar to transclusion markers)
2. Render `<img>` element at the marker position
3. Progressive loading: preview first (10-30KB), then full image
4. Images are block-level (own line) for readability
5. Click image to view full-size in a lightbox

## Phase 4: Upload UI

- Drag-and-drop onto document
- Paste from clipboard (Ctrl+V with image in clipboard)
- Toolbar button: "Insert Image"
- Progress indicator for uploads >1MB

## Future Visual Elements

The same BlobStore infrastructure supports:

| Element | MIME type | Rendering |
|---|---|---|
| Images | image/png, image/jpeg, image/webp | Inline `<img>` |
| Audio | audio/mpeg, audio/ogg | Inline `<audio>` player |
| Video | video/mp4 | Inline `<video>` player |
| PDF | application/pdf | Embedded viewer |
| Code blocks | text/x-code | Syntax-highlighted block |
| Math | application/mathml+xml | Rendered equation |

All use: upload → BlobStore → RangeElement::Blob → editor rendering.
