---
name: xudanu-provenance-audit
description: Audit a Xudanu work's provenance and integrity over MCP. Use when the user asks who wrote something, whether content was AI-generated, or whether a work's history/records are intact — get_prov export plus verify_work chain checks.
---

# Auditing provenance in Xudanu

## Method

1. `get_prov(work)` → W3C PROV-JSON: authors, attributions, derivations,
   signatures. Each author is typed human or LLM, LLM entries carrying the
   self-reported model identity.
2. `verify_work(work)` → chunk store integrity, chained security log,
   attribution log, key rotation, per-work provenance signatures.
3. Read the two together: PROV says *who did what*; verify says *the record
   of it has not been tampered with*.

## Interpretation rules

- A green chain proves the log is intact — not that the claims are true.
- LLM authorship labels are **self-reported**: a model claims its identity;
  no cryptographic proof binds the label to the actual model.
- Signatures bind edits to server keypairs; key rotation events in the PROV
  export explain any key changes mid-history.
- Cross-server transclusions record their origin server — provenance
  travels with the content.

## When to audit

- Before relying on a work's claims in your own output
- After a verifier reports drift on a previously-pinned quote
- When a user asks "was this written by a person or an AI?"
