# Docuverse Synthesizer — parameterized corpus generator

## What

`scripts/generate-synthetic.mjs` — generates a corpus with
controllable structural properties. Instead of fixed genres,
you specify the shape; the script produces works, links,
transclusions, and revisions that realize it.

## Parameters

```
node generate-synthetic.mjs [ws-url] [options]

  --works N              Number of works (default: 30)
  --density F            Link density: fraction of possible
                         cross-work links to create (default: 0.1)
  --type-mix "a:b,c:d"   Link type distribution as percentages
                         (default: "reference:40,quotation:30,
                          disagreement:20,comment:10")
  --transclusion-rate F  Fraction of works that are transclusion
                         SOURCES (default: 0.1)
  --revision-depth N     Mean revisions per work (default: 2)
  --topology T           Network topology:
                           random     — uniform link placement
                           hub        — 20% of works receive 80% of links
                           clustered  — 3-5 dense clusters, sparse between
                           chain      — sequential (work i links to i+1)
                           mesh       — every work links to its nearest 3
  --author-mix "h,l,m"   Author-type distribution as percentages
                         (default: "100,0,0" = all human)
  --hierarchy            Add hub works: 20% of works become hubs
                         (receive links from the other 80%)
  --seed N               Deterministic RNG seed (default: 42)

  --profile              After generation, print the H(G) profile
                         (calls xudanu-server hg-profile internally)
```

## Example invocations

```sh
# Sparse random docuverse (baseline)
node generate-synthetic.mjs --works 50 --density 0.05 --topology random

# Dense hub-dominated (social-media-like: low ρrt by design, but
# our system still gives ρrt=1.0 — the structural mutual drops)
node generate-synthetic.mjs --works 50 --density 0.3 --topology hub

# Transclusion-rich scholarly corpus
node generate-synthetic.mjs --works 40 --density 0.15 \
  --transclusion-rate 0.3 --topology clustered --revision-depth 3

# AI-augmented vault (mixed authorship, evolving)
node generate-synthetic.mjs --works 60 --density 0.08 \
  --author-mix "70,25,5" --revision-depth 4 --topology clustered

# Parameter sweep for H(G) calibration (loop in shell)
for d in 0.02 0.05 0.10 0.20 0.40; do
  node generate-synthetic.mjs --density $d --profile --seed 42
done
```

## H(G) calibration use

The killer feature for the Adamski et al. outreach: run a
parameter sweep varying one dimension at a time, profile each
corpus, and show how each H(G) coordinate responds:

- **density sweep** → d, P, S respond
- **topology sweep** (random vs hub vs clustered) → D, Q, κ respond
- **type-mix sweep** (1 type vs 5 types) → η responds
- **transclusion-rate sweep** (0.0 to 0.5) → θ responds linearly
- **revision-depth sweep** → γ responds

This produces calibration data that their framework needs but
hasn't been able to generate (they only have one corpus — IRA
tweets — and can't vary its structure).

## Implementation notes

- Reuse the WS op layer from generate-representative.mjs
- Content: short original prose paragraphs (3-5 sentences each,
  varied subjects from a fixed pool — no third-party content)
- Topology realized through link placement algorithm:
  - random: uniform random pairs
  - hub: preferential attachment (Barabási-style)
  - clustered: partition into groups, link within at high rate,
    between at low rate
  - chain: sequential
  - mesh: k-nearest-neighbors by work ID
- Transclusion: pick source works at the given rate, create
  includer works that insert their paragraphs as inline
  transclusions at natural positions
- Author-type: not yet wireable (enhancement #1 pending); for now
  recorded as work-title metadata ("[AI]" prefix) and noted in
  the generator's output for later migration
- Deterministic: seeded PRNG (mulberry32 or similar) — same seed
  → same corpus, so profiles are reproducible
- `--profile` flag: after generation, waits for checkpoint (or
  triggers one), runs xudanu-server hg-profile on the data dir,
  prints the JSON alongside the parameters used

## Output format

```json
{
  "parameters": { "works": 50, "density": 0.1, ... },
  "created": { "works": 50, "links": 122, "transclusions": 8, "revisions": 45 },
  "hg_profile": { ... }
}
```

This output IS the calibration data point. Collect many → the
calibration table for the paper and for the outreach email.
