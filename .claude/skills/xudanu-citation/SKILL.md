---
name: xudanu-citation
description: Quote Xudanu works verifiably over MCP. Use when citing, quoting, or referencing docuverse content — revision-pinned read_span quotes, canonical xudanu:// span URIs, living vs pinned pointers, and BLAKE3 verification.
---

# Citing Xudanu content

Two citation forms, both canonical:

| URI | Meaning |
|---|---|
| `xudanu://work/42` | living pointer — what the work says **now** |
| `xudanu://work/42?rev=3` | pinned — exactly what it said at revision 3 (immutable) |

Add `#span=<start>,<end>` to cite characters, e.g.
`xudanu://work/42?rev=3#span=10,150`. Span positions survive edits elsewhere
in the document.

## Method

1. Quote with `read_span`, passing `rev` to pin the revision. The response
   carries a BLAKE3 content hash for the exact bytes quoted.
2. Prefer `?rev=` for anything the user will rely on later; use the living
   form only when "current state" is the point.
3. Verify before trusting someone else's citation: `verify_work` checks the
   quoted span against the stored content.
4. When quoting matters legally, check the work's license via `get_prov`
   before reproducing large passages (All Rights Reserved works need care;
   Transcopyright and CC families are designed for quotation).

## Rules

- Never renumber a quote into your own words and present it as a span URI —
  the URI is a contract about exact content.
- If `read_span` reports drift (content moved since the URI was minted),
  say so; do not silently substitute the relocated text.
