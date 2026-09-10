# Regions Phase 1 — minimal implementation

## What we're building (now)

Region = a club ID. Works belong to at most one region. Sessions
operate in one region context. Region-scoped views.

**What this gives:**
- Users in region X see only region X's works (work list, search,
  suggestions, H(G))
- Admin sees all regions
- ACL still applies on top (region = visibility, ACL = access)
- One server, N isolated docuverses (clients, experiments, classes)

**What we're NOT building (yet):**
- Fulltrace/tumbler integration (hierarchical regions)
- Cross-region transclusion policies
- Region-scoped link filtering (links between regions still visible)

## Implementation

1. `region: Option<BeId>` on `WorkState` (the owning club)
2. `region: Option<BeId>` on `Session` (current region context)
3. Wire op `session_set_region { club_id }` (0x035F)
4. `work_create` stamps the session's region on the work
5. `work_list` filters by session region
6. H(G. profile: optional region filter (subcommand flag)

## Security model

- Region scoping = WHAT YOU SEE (the work list, search results)
- Read/Edit clubs = WHAT YOU CAN ACCESS (per-work ACL)
- A work in region A is invisible to a session in region B,
  even if the session's club has read permission on that work
- Admin sessions (region=None) bypass region filtering
- The region field is immutable after work creation (no migration
  between regions — keeps experiments clean)
