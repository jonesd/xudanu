# Enfilade on Mobile — Early Notes

- **Status:** Idea (2026-10-19), queued after v1.20.0.
- **Hypothesis:** the enfilade (index + container in one structure,
  FR-91 Layer 1) may be unusually well suited to mobile devices:
  - O(log N) lookups with no secondary indexes → small memory
    footprint; splay locality means the hot reading path stays cached
  - Subtree crums (BLAKE3) → cheap equality/sync checks over slow
    radio links: 32 bytes settles "do we agree?"
  - FR-76 freeze/eviction → transparent RAM→disk spill; a partial
    local cache of a remote docuverse works without app-level logic
  - Bloom-routed network search (FR-91a) already leans the same
    direction: ask little, fetch less
- **Open questions:** wasm target maturity for the engine crate;
  touch-first transpointing-window UI; battery profile of splay
  writes; how much of the O-tree CRDT authoring path must ship vs.
  read-mostly clients.
- **First candidate slice:** a read-only wasm enfilade viewer over
  chunk files + crum verification — proves the memory/bandwidth
  story before any editing ambition.
