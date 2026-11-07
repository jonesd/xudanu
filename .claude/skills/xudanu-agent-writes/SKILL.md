---
name: xudanu-agent-writes
description: Rules for Xudanu MCP write tools (create_work, revise, transclude, create_link, create_reasoning_path, create_evidence_set). Use before any mutation — the double gate, sandbox policy, attribution, and safe defaults for agent edits.
---

# Writing to Xudanu as an agent

Writes are doubly gated: the server process must run `xudanu-mcp` with
`--enable-agent-writes`, and every mutation still passes the same
`ensure_can_edit` check as human users. In practice that means agent writes
only ever touch world-editable works on servers running the public-sandbox
policy — production servers deny agents structurally, flag or no flag.

## Defaults

- All your edits are attributed `AuthorType::Llm` plus your model identity
  in the provenance chain. Never claim otherwise.
- Prefer `revise` with minimal, surgical changes over rewriting whole works.
- When creating a work that quotes another, use `transclude` (a live window
  with source attribution) rather than copy-paste. Copy-paste severs
  provenance.
- `create_link` for typed connections (comment, reference, disagreement,
  quotation, see-also); `create_reasoning_path` / `create_evidence_set` for
  structured argument artifacts.
- If a write fails with not-authorized, report it plainly — do not retry
  variants hoping to slip past the policy.

## Judgment

You share the docuverse with human authors. When unsure whether an edit
serves the user's intent, ask first. Deletion of others' content is almost
never yours to do.
