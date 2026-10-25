# FR-153 — ID formatting convention: decimal entity ids, hex hashes, string tumblers

**Status:** proposed — boundary audit complete, implementation pending.
Sized to land before FR-148 mobile clients add another display layer.

**Heritage:** none needed — this is hygiene. Two id formats accreted
by accident ("it just happened"); this FR makes the convention
explicit before the parser count grows.

## Why

BeIds (works, clubs, links, sessions) are u64 values with TWO text
encodings in circulation: decimal (wire JSON, UI, manifest) and hex
(`0x661`-style in recovery tooling, log paths, some parsers). The
danger is not display — it is **silent wrong-id parsing at
boundaries**:

- `server.rs:8977,9133` accept `0x`-prefixed or bare hex
  (`trim_start_matches("0x")` + radix 16)
- `protocol.rs:27,47,4651,4666` — serde deserializers that hex-parse
  id strings (27/47 currently dead code, flagged by the compiler)
- `handler.rs:182,898,1421` — HTTP handlers parsing hex

A decimal string `"1633"` reaching a radix-16 parser becomes
`0x1633` = **5683**: a valid-looking, wrong id. No error, just
misbehavior. Additional pressure: hash-derived u64s (blob hashes,
first 8 bytes of BLAKE3) exceed JavaScript's 2^53 safe-integer
range, so the client already passes them as strings
(`blobGet(hashU64: string)`) — two wire conventions for "a u64"
depending on which kind it is.

## The convention

| ID kind | Format | Notes |
|---|---|---|
| Entity BeIds (works, clubs, links, sessions, editions) | **Decimal** everywhere: wire, UI, CLI, logs | JSON numbers are safe (ids are sequential, well under 2^53) |
| Content hashes (BLAKE3, chunk/root hashes) | **Hex strings** | 64-char lowercase; `recover --rollback <root-hash>` already correct |
| Hash-derived u64s (blob foldings) | **Hex strings** on the wire; decimal u64 is legacy | `blobHashToU64` client-side folding is the compatibility shim |
| Tumblers / cross-server ids | **Strings** | Separate namespace by design (FR-6) — no change |

One shared parse helper for BeIds: decimal-only, **rejects `0x` and
bare-hex input with an explicit error** (never guesses). One shared
formatter (plain decimal). No ad-hoc `from_str_radix` at call sites.

## Migration posture: no data migration

Storage is format-neutral — audited:

- chunks: postcard binary u64 (no text format exists)
- manifest: typed `BeId`, JSON numbers (`persist/manifest.rs`)
- zero hex-serialized ids in `persist/`, `chained_log.rs`, `audit.rs`

What changes instead is the **boundary strategy**:

1. **Tolerant-read, strict-write.** Parsers accept the legacy hex
   forms (with `0x` prefix only, never bare-hex guessing) through a
   deprecation window; emitters produce decimal exclusively.
   Precedent: schema-tolerant checksum validation (preflight), the
   flexible deserializers in `protocol.rs`.
2. **Append-only logs stay historical.** Security-log and
   attribution verifiers must accept both formats forever — chained
   logs cannot be rewritten without breaking hash chains. (Audit
   found no hex ids recorded in them today; the tolerance is
   defense-in-depth for any we missed.)
3. **The FR-82 machinery stays in reserve.** `persist/migrations.rs`
   step chains + `data/VERSION` sidecar are ready if the full site
   audit turns up a persisted hex form this survey missed. As of the
   audit: none exist, so no step is registered.

## Implementation outline

1. **Audit & classify** every parse/print site (inventory above is
   the seed, not the census): entity-id vs hash vs tumbler.
2. **Introduce** `parse_be_id(&str) -> Result<BeId, _>` (decimal-only
   + explicit rejection) and `format_be_id(BeId) -> String`; route
   all entity-id sites through them.
3. **Recovery tooling display**: work/club BeIds print decimal;
   root/chunk hashes stay hex. (`recover --list` is the visible
   offender — it printed `0x661` for a work id.)
4. **Deprecation window**: legacy `0x`-prefixed ids parse with a
   one-time `tracing::warn!` per process; bare-hex guessing is
   removed immediately (it is the ambiguity, not the feature).
5. **Client**: no changes required (JS already sends decimal
   numbers; blob u64 strings already hex).

## Test plan

- Parser: rejects `0x661`, `661a`, empty, overflow; accepts `1633`.
- Round-trip: every id printed by `recover --list` / logs is
  paste-able into the shared parser.
- Wire: mixed-version test — old hex-emitting client against new
  server (window: accepted + warned), new client against old server
  (decimal — already the dominant form, no change).
- Log verifiers: synthetic chained-log entries with hex ids verify
  clean (tolerant forever).
- The compiler-dead `deserialize_u64_flexible` pair: either wire
  into the tolerant-read path or delete.

## Risks

| Risk | Mitigation |
|---|---|
| Script/automation sending hex ids breaks at window end | Deprecation warning names the offending op; release notes |
| A hidden persisted hex form surfaces later | FR-82 step chain registered on discovery; tolerant-read keeps old data servable |
| Mobile (FR-148) built on hex before this lands | Sequencing: FR-153 first |

## Related

- FR-82 (data migration — the machinery held in reserve)
- FR-6 (cross-server refs / tumblers — the string namespace, out of
  scope by design)
- Open bug from the same audit neighborhood: `verify`'s reference
  walk under-counts vs the GC's (8,412 "orphans" vs 9,017 referenced
  on the same data directory) — likely schema-evolution drift in
  `collect_edition_hashes` walking; fix alongside so both walks share
  one reference set.
