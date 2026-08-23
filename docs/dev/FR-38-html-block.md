# FR-38: HTML Block Element — Quoting Web Content with Provenance

Status: draft · Date: 2026-08-19 · Depends on: ammonia integration (shipped v1.6.0, `web_fetch_sanitize`)

## Problem

Xudanu works hold text, images, and transclusions — but the richest
material we want to quote (our own fancy documents on the docs site,
third-party web pages) is HTML. Today the options are lossy: extract
text (diagrams and tables vanish) or link out (the content never
enters the docuverse, no provenance, no transclusion of it).

The Xanadu answer to quoting is transclusion with provenance. This FR
brings quoted *structured* content into the model.

## Non-goals

- Authoring HTML in Xudanu (read-only blocks; authoring stays native)
- Executing embedded content (scripts are stripped, permanently)
- Full HTML→work parsing parity (tables as data, addressable diagrams)

## Design

### 1. Element type

```rust
RangeElement::HtmlBlock {
    /// Ammonia-cleaned HTML fragment (whitelist below).
    sanitized_html: String,
    /// Canonical source URL at fetch time.
    source_url: String,
    /// BLAKE3 hash of the ORIGINAL (pre-sanitize) HTML — the citation.
    original_hash: [u8; 32],
    /// Fetched-at timestamp (provenance chain uses this).
    fetched_at: u64,
    /// Rendered height hint (avoid layout jump on load).
    preview_height: Option<u32>,
}
```

One element = one quoted page (or page section). Char length 1 in
the text model (like Blob), so span math treats it as an atomic
glyph.

### 2. Sanitizer policy (ammonia, server-enforced at ingest)

Whitelisted tags — the vocabulary our own fancy documents use:
`h1-h6, p, ul, ol, li, table, thead, tbody, tr, td, th, code, pre,
blockquote, em, strong, span, div, svg, g, path, rect, circle, line,
text, tspan, figure, figcaption, caption`

Stripped: `script, style, iframe, form, input, link, meta, object,
embed, on* attributes, javascript: URLs`. No exceptions — a block
that fails policy is rejected at creation, never stored half-clean.

URLs inside (svg hrefs, anchors): rewritten to absolute against
source_url; `target="_blank" rel="noopener noreferrer"` injected.

### 3. Ingest paths

- `web_fetch_sanitize` gains `import_mode: "html_block"` — returns
  the sanitized fragment; `import_as_source` wraps it in an HtmlBlock
  work (frozen by default, like web quotations)
- Wire op `element_insert` accepts the new element (through the
  invariant gate: `sanitized_html` size cap 2 MiB, `source_url` must
  be http(s), `original_hash` exactly 32 bytes, no control chars)

### 4. Rendering

Read-only. The block renders in a bordered container with a header:
source domain, fetched date, and "view original" (opens source_url,
new tab). Dark-mode CSS variables pass through (our docs pages
already respect them). No pointer events on inner content except
scroll — the block is a quotation, not an app.

### 5. Provenance

The element's `ElementProvenance` records the fetching identity;
`original_hash` + `fetched_at` make the citation checkable forever
(the source may change or vanish; we can prove what we saw).
Transclusion of a work containing HtmlBlocks carries them intact.

### 6. Trust boundary

All ingest paths run the sanitizer BEFORE the element exists —
there is no code path that stores unsanitized HTML. The invariant
gate re-checks size and shape at every deserialization boundary
(client wire, federation sync, restore), same as every other element.

## Testing

- Mutation corpus: script smuggling, `on*` attributes, `javascript:`
  URLs, oversized fragments, control chars, hash-length violations —
  all rejected at the gate (level-1/3 suite extended)
- Round-trip: create → serialize → restore → render identical
- Federation: poisoned HtmlBlock from evil peer filtered (level-4
  drill extended)
- Golden render: our own transclusion-architecture.html imported,
  diagrams intact, screenshot-diffed

## Rollout

1. Element + sanitizer + gate + tests (core)
2. `web_fetch_sanitize` html_block mode + import
3. Renderer + provenance display
4. Import the 45 fancy docs as works; guides' Go-deeper sections
   link (and later transclude) their passages
