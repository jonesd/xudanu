# FR-90: Unicode Normalization to NFC at Ingestion

- **ID:** FR-90
- **Status:** Proposed (2026-10-13) — timing-critical, see §3
- **Depends on:** nothing; interacts with FR-58 (reuse matching),
  federation verification (BLAKE3 cross-server), provenance
  fingerprints
- **Origin:** Gwern's encoding objection ("how do you handle
  different text encodings?") traced through the code — backlog 0d

## 1. Why

Xudanu's content identity is byte-based: BLAKE3 crums, reuse
matching, federation verification. Unicode permits the same text
as multiple byte sequences (NFC composed vs NFD decomposed —
both valid, visually identical). Today the system has NO
normalization (verified 2026-10-13: only span-bound normalization
exists), so the same passage in two composition forms produces
different crums: no transclusion match, no reference-over-copy
trigger, cross-server disagreement. The gap sits on the system's
core promise — the same passage recognized across documents and
servers.

NFD arrives in practice via macOS paste (decomposing), Korean and
Indic input, and some web forms. ASCII corpora are immune —
which is the entire current deployed corpus.

## 2. Mechanism

1. **Normalize once, at the server's ingestion boundary**: text
   entering via `work_set_text`, element insertion, paste paths,
   seeder scripts, and federation import is normalized to NFC
   (Unicode Normalization Form C, composed) before storage.
   Server-side only — clients may send any form.
2. **Identity follows automatically**: crums, FR-58 matching,
   and federation verification operate on stored (normalized)
   bytes — no changes needed downstream once the boundary
   normalizes.
3. **No blind rewrites; migrations go through the engine.**
   In-place byte-rewrites of stored text are forbidden (they
   strand spans). If stored content ever needs normalizing,
   the path is a NORMALIZATION-AS-REVISION migration: NFC delta
   committed as a new revision per affected work, spans carried
   by the existing migration machinery (FR-38 tumbler diff keys,
   FR-50 span-migration O(spans hit)), originals preserved by
   deep versioning, machine-authored entry in the attribution
   log. Open design detail: per-span signature carry-over
   policy across a migration revision (re-sign vs
   author-maintained) — specify before ever running one.
4. **Originals**: uploaded files keep their original bytes in
   the blob store as-is; normalization applies to text entering
   the document model only.

## 3. Timing — why now

The deployed corpus is entirely ASCII (census 2026-10-13), and
ASCII is normalization-invariant: normalizing today changes ZERO
existing crums — the boundary pass alone suffices, no migration
ever needed. If mixed-form content accumulates first, the fix is
still available (normalization-as-revision, §2.3) but becomes a
per-work migration campaign with a signature-carry policy to
specify. Cheap now; merely possible later.

## 4. Acceptance criteria

- G1: any NFC/NFD pair of the same passage produces the same
  crum after ingestion
- G2: FR-58 fires on retyping regardless of composition form of
  source or retyped text
- G3: federation verification succeeds across servers whose
  ingestion pipelines differ
- G4: proptest — no path stores non-NFC text in the document
  model; span positions never shift post-storage
- G5: existing test suite passes unchanged (ASCII corpus is
  normalization-invariant — zero churn expected)
- G6: known NFC conflation edge cases (OHM→Ω etc.) documented
  and accepted (W3C-consistent trade)

## 5. Effort

Small: one boundary function (`unicode_normalization::to_nfc`,
via the `unicode-normalization` crate), applied at the ingest
call sites (a handful), plus the proptests above. A focused
session.
