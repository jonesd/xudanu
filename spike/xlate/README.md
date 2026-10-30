# Cross-language transclusion — spike

A throwaway demo answering one question: **can a machine translation
ride the product's PROV provenance model as a first-class derivation
edge**, instead of being a button that mutates text?

The answer the demo argues: yes, and the mechanism is already there.
A translation is an *edge* — `(span, source lang, target lang,
provider, model version)` → content-addressed rendition — and PROV
already has the sentence for it:

```
span  <-used-  xudanu:Translation  -wasGeneratedBy->  rendition
  ╰———————— prov:wasDerivedFrom (THE EDGE) ————————╯
```

## Run it

```bash
# optional: live provider (falls back to a deterministic mock)
docker run -d --name xlate-spike -p 5050:5000 \
  libretranslate/libretranslate --load-only de,en --disable-web-ui

cd spike/xlate && cargo test && cargo run
open demo/index.html
```

Artifacts land in `demo/`: the fancy page (rendition chip, both ends
visible, PROV graph, reproducibility evidence) and `rendition.prov.json`.

## Invariants under test

1. **Content addressing.** The edge tuple IS the cache key; same
   tuple must yield byte-identical bytes. Verified: second resolve
   makes zero new provider calls and returns the identical rendition.
2. **Links resolve to originals.** The rendition derives from the
   span (`wasDerivedFrom`); a rendition is never a link target.
   Machine-verified in `prov_links_resolve_to_original`.
3. **No silent invalidation.** Source edit → new revision+hash →
   new key (stale renditions unreachable, not "invalidated"). Model
   upgrade → new model version → new key + retranslate. Nothing is
   ever mutated under a stable address.

## Spike findings (the part worth keeping)

- **Source language is pinned on the edge, never detected at call
  time.** If detection drifted, a stable key would silently start
  producing different output — the exact rot content addressing
  exists to prevent.
- **LibreTranslate's API cannot name its model.** `/translate`
  returns text; nothing identifies which Argos model ran. Model
  identity must come from deployment config (image digest), or the
  edge cannot promise reproducibility. The provider trait therefore
  makes `model_version` first-class.
- **Live output is exactly as gisting-grade as advertised.** The
  demo span (Faust) renders "Man is wrong as long as he strives."
  — which is why `qualityGrade: machine-gisting` ships on the
  entity, and why the chip labels rather than translates.
- **Emission from outside the crate needs two small pubs** (or an
  in-crate emitter, which is the production shape):
  `unix_to_iso8601` is `pub(crate)` today. Everything else needed
  (`ProvJsonDocument`, `generate_prov_id`, all record types) is
  already public.
- **The engine feature set suffices** for provenance work: no
  tokio/axum/network stack in the demo binary.

## What this suggests next

Read-side only (no MT round-trips into the archive); per-host
providers so reader text never leaves the federation's trust
boundary; and the cluster's obvious first translation-shaped job —
a quorum endorsing a canonical rendition ("faithful to revision 7,
checksum verified") is a real governance decision, signed and
sealed like any other.

## Status

Throwaway by design (`spike/` branch, standalone workspace, not a
root-workspace member). If the design graduates, the edge types move
into `edition/`, the emitter lives beside the PROV constructors in
`federation.rs`, and the provider trait becomes a server feature.
