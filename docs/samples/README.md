# Attestation Report Verification

The `xudanu-cli verify-report` command independently checks the integrity of
exported attestation reports — **offline, no server connection required**.

## Usage

```sh
xudanu-cli verify-report <report.json>
```

The command auto-detects the report format:

- **PROV-JSON (W3C)** — the standards-compliant format from "Export PROV-JSON (W3C)"
- **Custom attestation report** — the Xudanu-specific JSON from "Export attestation report"
- **Signed report (v0)** — older format with `report_hash_sha256` + `server_signature_ed25519`

## What It Checks

| Check | Description |
|-------|-------------|
| Per-span signatures | Each content span's `signatureValid` flag is checked |
| Attribution log chain | The SHA-256 chained log integrity status |
| Server identity | The signing server's verifying key is displayed |
| Document hash | The BLAKE3 content hash is shown for cross-reference |
| Relations (PROV-JSON) | `wasAttributedTo`, `wasGeneratedBy`, `wasAssociatedWith`, `wasDerivedFrom` counts |

## Output

**Pass:**
```
  [OK] Span [0, 5000) key=efdf23c4... ts=1783130786
  [OK] Span [5000, 12000) key=9a8b7c6d... ts=1783130786
  Attribution: 3 spans, 3 valid, 0 invalid
  Log chain:   208 entries, VALID
-----------------------------------------------------------
  RESULT: ALL CHECKS PASSED
  3 spans verified, log chain valid
```

**Fail (exit code 1):**
```
  [FAIL] Span [2500, 5000) signature INVALID
  Attribution: 2 spans, 1 valid, 1 invalid
-----------------------------------------------------------
  RESULT: ISSUES DETECTED
    - 1 spans with invalid signatures
```

## Sample Reports

Test with the included samples:

```sh
# All pass
xudanu-cli verify-report docs/samples/sample-valid-prov.json
xudanu-cli verify-report docs/samples/sample-valid-custom.json

# Failures (exit code 1)
xudanu-cli verify-report docs/samples/sample-invalid-signature-prov.json
xudanu-cli verify-report docs/samples/sample-broken-chain-prov.json
xudanu-cli verify-report docs/samples/sample-unsigned-spans-custom.json
```

## Failure Cases

| Sample | What it demonstrates | Expected result |
|--------|---------------------|-----------------|
| `sample-valid-prov.json` | 3 signed spans, valid chain, PROV-JSON format | PASS |
| `sample-valid-custom.json` | 2 signed spans (human + LLM), valid chain, custom format | PASS |
| `sample-invalid-signature-prov.json` | One span has `signatureValid: false` | FAIL — 1 invalid span |
| `sample-broken-chain-prov.json` | Attribution log `chainValid: false` | FAIL — chain broken |
| `sample-unsigned-spans-custom.json` | 2 of 3 spans unsigned + chain broken | FAIL — 2 invalid + chain broken |

## How to Generate Reports

In the Xudanu web UI, open a document and scroll to the **Attribution** section
in the right panel:

- **"Export attestation report"** — downloads the custom JSON format
- **"Export PROV-JSON (W3C)"** — opens the PROV-JSON in a validator page
  (auto-validates against the W3C schema, with a Download button)

Both files can be verified offline with `xudanu-cli verify-report`.
