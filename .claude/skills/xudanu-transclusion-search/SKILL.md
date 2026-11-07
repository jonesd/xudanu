---
name: xudanu-transclusion-search
description: Find content reuse in a Xudanu docuverse over MCP. Use when the user asks "where else does this content appear?", "who quoted this?", or "what does this work transclude?" Chains search_works, who_transcluded, and read_work span_ranges.
---

# Finding transclusions in Xudanu

Transclusion = the same content appearing live in more than one work. Two
directions, two tools:

| Question | Tool |
|---|---|
| Who transcluded this work? (where does its content also appear?) | `who_transcluded` |
| What does this work quote? (its live windows onto other works) | `read_work` — resolved spans come back in `span_ranges` |

## Recipe: reuse by topic

`search_works` only matches a work's **own** text (transcluded content is
not indexed), so to answer "where else does this passage appear?":

1. `search_works` with a distinctive phrase from the passage → candidate works
2. `who_transcluded(work)` on each candidate → reusers, each with a
   `xudanu://work/<id>` URI
3. `read_work(reuser)` → `span_ranges` shows exactly what was quoted, with
   source spans

## Output

- Every reuser entry has `kind` (work or link), `id`, `is_direct`
- Cite findings as span URIs: `xudanu://work/<id>#span=<start>,<end>`
- Empty results are a real answer: nobody has transcluded it (yet)

Permissions note: results respect the connected server's read policy —
unpublished works never appear.
