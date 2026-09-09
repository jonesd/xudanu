# Daily Narrative History — implementation plan

## What

On checkpoint, generate a "history work" summarizing what changed:
works created, links made, transclusions placed, revisions.
Grouped by project/topic via link connectivity. Each mentioned work
links back from the history entry.

## The grouping problem (multi-project users)

**The concern:** someone works on "spatial navigation" in the morning,
switches to "client compliance" in the afternoon, back to "spatial"
in the evening. A flat chronological list is noise; the history
should say "today you worked on two areas."

**The solution: connected components.**

Works that link to each other belong to the same topic cluster.
The day's touched works form a mini-graph; connected components
in that graph = project clusters. Isolated works (no links) get
their own group or an "ungrouped" bucket.

```
Morning: create A, B → link A→B          (cluster 1: "spatial nav")
Afternoon: create C, D, E → link C→D→E   (cluster 2: "compliance")
Evening: revise A, link A→F               (F joins cluster 1)

Result: 2 clusters, each with a readable summary.
```

This is deterministic — no LLM needed. Works for any number of
interleaved projects.

## LLM enhancement (optional)

If ollama is configured (`llm_enabled()`), send the structured
cluster data to the LLM for narrative polish:

> "Write a 2-sentence summary of what the user worked on in each
> of these topic clusters, based on the work titles and link types."

If ollama is NOT configured, the deterministic output is a readable
bullet list per cluster. Both are useful; the LLM version is nicer.

## Implementation

**Trigger:** once per day (or per N checkpoints). Check if today's
history work already exists (by title convention: "Daily History —
YYYY-MM-DD"). If not, and there are changes to record, create it.

**Data collection:**
- Scan the attribution log since the last history entry
- Collect: work IDs touched, link IDs created, transclusion positions
- Build the mini-graph: works as nodes, links as edges

**Grouping algorithm:**
1. Collect all works touched since last history
2. Build undirected graph: edge between works that share a link
3. Find connected components
4. For each component: list works, links (by type), transclusions
5. Order components by size (largest first)

**Output format (deterministic, no LLM):**
```
Daily History — 2026-09-09

Topic: Spatial Navigation (4 works, 3 links)
- Created: "Grid Cell Arithmetic", "Boundary Cells and Framing"
- Revised: "Spatial Memory in Navigation" (rev 3)
- Linked: "Grid Cell Arithmetic" →reference→ "Hub: Spatial Representation"
- Transcluded: "Grid Cell Arithmetic" excerpt in "Trail: From Grids to Maps"

Topic: Client Compliance (2 works, 1 link)
- Created: "Position A: Grids Are Primary"
- Linked: "Position A" →disagreement→ "Position B"
```

**Output format (with LLM, if configured):**
Same structure, but each topic section has a 1-2 sentence narrative
summary written by the LLM from the structured data.

**The history work itself:**
- Created as a normal work (type: "history", inferred from title)
- Links back to every mentioned work (type: See Also)
- Is itself part of the docuverse: addressable, transcludable
- Its provenance is signed by the server (it's auto-generated, so
  author_type = machine if we want to be precise)

## Wire surface

No new ops needed — this is server-side auto-generation during
checkpoint. Optionally: an admin op to trigger/history manually
or to configure the interval.

## Armor

- Multi-project grouping: works in two separate clusters produce
  two topic sections, not one merged list
- No changes → no history work created (don't spam empty entries)
- Once per day → second checkpoint same day doesn't create a second
- History work links back → every mentioned work has a backlink
- Deterministic → same input produces the same output
