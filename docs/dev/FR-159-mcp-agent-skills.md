# FR-159: MCP Agent Skills — Recipes Shipped to the Agent, Not the User

- **ID:** FR-159
- **Status:** Shipped (2026-11-06), catalog + skills; follow-ups open
- **Parent:** FR-141 (Docuverse MCP server)

## Problem

The MCP server has 19 tools, but the useful operations are *chains*:
"where else does this passage appear?" is `search_works → who_transcluded →
read_work.span_ranges`. Agents that don't know the chains give thin answers.
Documentation can't fix this — agents don't read docs, and users shouldn't
need to.

## What shipped

Three layers, cheapest first:

1. **Tool descriptions carry recipes** (rides with every host, zero config).
   `who_transcluded` now states that `search_works` matches only a work's
   own text and names the chain. Descriptions are the only layer that
   reaches hosts with no skills mechanism.

2. **Four Agent Skills in `.claude/skills/`** (Agent Skills open format,
   SKILL.md + frontmatter). Committed at the repo root so Claude Code and
   OpenCode discover them automatically in project sessions — OpenCode reads
   `.claude/skills/` natively. Verified live: OpenCode picked them up the
   moment they were written, no config, no restart.

   - `xudanu-transclusion-search` — the reuse-graph chain, both directions
   - `xudanu-citation` — living vs pinned pointers, span URIs, BLAKE3
     verification, license check before large quotations
   - `xudanu-provenance-audit` — get_prov + verify_work, what each log
     proves, LLM-authorship-is-self-reported caveat
   - `xudanu-agent-writes` — the double gate, sandbox reality, attribution,
     prefer-transclude-over-copy-paste, judgment rules

3. **Distribution ladder for non-repo users** (release tarball):
   `cp -r .claude/skills/* ~/.claude/skills/` serves Claude Code and
   OpenCode globally (OpenCode reads `~/.claude/skills` too).

## Follow-ups (not yet carded)

- HTTP skills catalog for OpenCode (`skills` config array accepts a URL +
  `index.json`): host at dgjones.info, versioned, auto-updating.
- Recipes section in the MCP guide (`docs/mcp-guide.html`) for humans.
- `find_transclusions` tool — corpus-wide transclusion query surface over
  the backfollow index (removes the need for the per-work chain in many
  cases; the skill then teaches preferring it).
- Read-delegation tokens (agent reads as the user, writes stay public) —
  separate card when built.

## Verification

- `cargo build --features server` clean; 36 MCP lib tests green.
- Skills auto-discovered by OpenCode in-session (2026-11-06).
