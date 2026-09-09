# Regions — scoped docuverse spaces within one server

Design note (no code changes — thinking through the concept).

## The insight

You're right that this is a variant of strict user permissions, but
it's a *stronger* variant: not "can I access this work" but "does
this work exist in my world." That distinction matters for:

- **Independent experiments**: seed different H(G) corpora into
  different regions; profiles compute cleanly without cross-links
- **Multi-tenant hosting**: one server, multiple users/groups, each
  with their own docuverse — no work-list contamination
- **Course/classroom**: each student sees only their region; the
  instructor sees all
- **Client isolation for the consultancy**: each client engagement
  gets a region; their data is invisible to other clients on the
  same server (stronger than ACL, which only gates access)

## What exists that's close

| Mechanism | What it does | What it doesn't do |
|---|---|---|
| Read/Edit clubs (ACL) | Per-work access control | Doesn't scope the work LIST; users see titles of works they can't read |
| Club branches (FR-52 P2) | Hierarchical namespaces via fulltrace | Organizational, not isolationist — everything is still in one space |
| Owner-only policy | Server-wide restriction | All-or-nothing, no per-user scoping |
| Separate servers | Total isolation | Requires running multiple processes; no cross-pollination even when desired |

Regions fill the gap: **scoped views of a shared server**, with
configurable permeability at the boundaries.

## Design: regions as fulltrace subtrees

The simplest and most Gold-native approach: **a region IS a club's
branch in the fulltrace**. Works created within a region get traces
under that branch. The existing `is_le` subtree query already
supports "show me all works under branch X."

### Key design decisions

**1. Region identity = club ID.** A region is created by a club
(the region owner). Works created by a session in region context
get traces under that club's branch. No new entity type needed.

**2. Session region context.** A session operates in exactly one
region at a time (default: the global/root region). Set via a wire
op (`session_set_region`), or derived from the login club. Admin
sessions can switch regions.

**3. What's scoped by region:**

| Surface | Behavior |
|---|---|
| Work list | Only works in the current region |
| Search | Only searches current region's works |
| H(G) profile | Computes on current region's subgraph |
| Link panel | Shows links to/from current region's works |
| Suggestions (FR-58) | Only suggests from current region's corpus |
| Attribution panel | Only shows current region's spans |

**4. What crosses regions (the interesting policy):**

| Operation | Cross-region? | Rationale |
|---|---|---|
| **Read a work** | Yes, if readable | Reading is a permission question, not a scoping question |
| **Create a link INTO another region** | No | The link is created by a session in region X; it modifies region X's view, not region Y's |
| **Transclude FROM another region** | Yes, if source readable | The transclusion is placed in MY region but references the source — provenance crosses, content flows one way |
| **Annotate another region's work** | No | Annotations modify the target work's state |
| **Backlinks panel** | Shows cross-region backlinks | Read-only visibility — "who links to my work from outside" is useful signal |

**5. The permeability principle:** regions are *lenses*, not walls.
Cross-region reads and transclusions are allowed (subject to ACL).
Cross-region writes are not (links, annotations, edits stay in your
region). This preserves the docuverse's connective tissue while
giving each region autonomy over its own content.

**6. Default: the global region.** Every server starts with one
region (the root). Works created without a region context go to the
root. This is 100% backward compatible — existing servers are
single-region servers.

## What this enables (concrete use cases)

### For the paper
Seed each H(G) corpus type into a separate region:
```
Region "seminar" → 15 works, hub topology, moderate θ
Region "debate"  → 11 works, disagreement topology, high θ
Region "edition" → 6 works, alignment topology, very high θ
Region "vault"   → 24 works, evolving topology, moderate θ
```
H(G) profile per region = the four-genre comparative table, clean,
without cross-contamination. This is exactly what the paper needs.

### For the consultancy
Each client engagement gets a region:
```
Region "client-A" → their documents, their links, their provenance
Region "client-B" → separate docuverse on the same server
```
The server admin (you) can see all regions; clients see only their
own. One server to maintain, N isolated docuverses served.

### For the HT '27 demo
Region 1: "control" (human-only editing)
Region 2: "ai-assisted" (LLM agents tagged and editing)
H(G_AI) vs H(G_human) computed on real regions, not just edge
partitions. Clean separation, meaningful comparison.

## Tumblers ARE the region mechanism

This is the part that makes regions native rather than bolted-on.
The tumbler system (FR-34 D-F, `XudanuTumbler`) was designed for
exactly this: hierarchical universal addresses where the prefix
IS the scope.

### The tumbler-region correspondence

```
Tumbler:  "alice.com" . 2 . 1 . 5 . 3
                         └───┬───┘
                        region "2.1"
                             └─┬─┘
                          work 5.3 in that region
```

- A region's tumbler prefix IS its boundary: `starts_with_path(&[2, 1])`
  already exists on `XudanuTumbler` (line 173)
- Region containment = tumbler prefix containment: region `2` contains
  `2.1` contains `2.1.5` — the hierarchy gives nesting for free
- Cross-server regions: `"alice.com".2.1.5` scopes to `"alice.com".2`
  — region boundaries cross server boundaries naturally (FR-6
  domain tumblers compose with region tumblers)

### What tumblers add over "just use club branches"

| Feature | Club branches alone | With tumblers |
|---|---|---|
| Scope query | `fulltrace.is_le(branch, trace)` | `tumbler.starts_with_path(prefix)` — both work, tumbler is addressable |
| Region has an address | No — just a club ID | Yes — the region's tumbler prefix is a writable, shareable, universal address |
| Nested regions | Via fulltrace hierarchy | Via tumbler hierarchy — SAME thing, but the address encodes it |
| Cross-server scoping | N/A | `"alice.com".2.1` — domain prefix + region prefix compose |
| Address says where you are | No | Yes — `"alice.com".2.1.5.3` tells you the server, the region, and the work |
| Region is first-class | Implementation detail | The tumbler IS the region; no separate entity needed |

### The realization

Gold designed tumblers so that the ADDRESS encodes the ORGANIZATION.
We implemented tumblers (FR-34) without fully activating this — they
were addressing machinery, not scoping machinery. Regions are what
happens when you ask "what does the tumbler hierarchy MEAN for how
users experience the space?"

The answer: the tumbler prefix is the user's WORLD. When I'm in
region `2.1`, I see works whose tumblers start with `2.1`. When I
transclude from outside, the source tumbler carries its region's
prefix — provenance includes where the content CAME FROM, not just
who wrote it.

### Concrete tumbler-region flows

```
# Region creation: admin assigns tumbler prefix to a club
region_create(club_id, tumbler_prefix=[2, 1])

# Work creation in region context
# (trace placed under branch, tumbler allocated under prefix)
work_create(session_in_region_2_1, ...)
→ work tumbler: "".2.1.3.10.7   (local server, region 2.1)

# Cross-region transclusion
# (source tumbler carries the other region's prefix)
transclude(work_in_region_2_1, source_in_region_3)
→ source tumbler: "".3.5.2.1  (different region, provenance-tracked)

# Cross-server region reference
# (domain + region + work, fully qualified)
resolve_tumbler("alice.com".2.1.5.3)
→ work 5.3 in region 2.1 on server alice.com

# H(G) per region
# (filter by tumbler prefix)
hg_profile_region(prefix=[2, 1])
→ computes ten coordinates on the sub-graph where all works
  have tumblers starting with [2, 1]
```

### What this means for the paper

The regions section of the paper writes itself:

> "Tumblers, Nelson's hierarchical universal addresses, were
> designed so that the address encodes the organization. Regions
> activate this design: each region IS a tumbler prefix, and the
> prefix defines what a user sees, what they can link to, and where
> their transclusions come from. This is not a permissions overlay
> on a flat space; it is the hierarchical addressing system doing
> what it was designed to do."

And the Adamski et al. H(G) connection: region profiles computed
via tumbler prefix filtering give exactly the comparative table,
with the added elegance that the region's address tells you where
in the hierarchy the data lives.

## What it's NOT

- **Not separate databases.** All data lives in one chunk store.
  Regions are views, not partitions.
- **Not hard walls.** Cross-region reads and transclusions are
  allowed by design (provenance-tracked). This is the Xanadu
  vision preserved: connections exist even across boundaries.
- **Not a new entity type.** Regions are clubs with a spatial role.
  One identity system, two functions (permission + scope).

## Implementation sketch (if/when we build it)

| # | Piece | Effort | Notes |
|---|---|---|---|
| 1 | `region` field on Session (club ID) | 1h | Same pattern as author_type |
| 2 | Wire op `session_set_region` | 30min | Admin or self-service |
| 3 | Work creation places trace under region branch | 2h | `fulltrace.new_trace()` variant |
| 4 | Region-scoped work list / search | 1h | Filter by `is_le(region_branch, ws.trace)` |
| 5 | Region-scoped H(G) | 30min | Filter nodes before profile |
| 6 | Region-scoped suggestions | 30min | Filter the reuse index |
| 7 | Cross-region policy enforcement | 2h | Link/annotation targets must be in current region |
| **Total** | | **~8h** | Most of it is filtering existing queries |

## The "so what"

Regions make Xudanu a **multi-tenant docuverse host** — one binary,
one data dir, N isolated docuverses. This is:

1. The deployment model for the consultancy (one server, N clients)
2. The experimental model for the paper (N regions, N H(G) profiles)
3. The classroom model for teaching (N students, N sandboxes)
4. The conference model for HT '27 (N demo environments on one server)

And it's 8 hours of work because the fulltrace already does the
heavy lifting.
