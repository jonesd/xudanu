# Test Registry

All tests run with: `cargo test --features "serde,serde_json"`

Stress tests require: `cargo test --features "serde,serde_json" -- --ignored`

## Summary

| Category | Count | Run Time |
|----------|-------|----------|
| Core tests (branch, trace, dagwood, content) | 94 | ~50ms |
| Serde round-trip tests | 16 | included |
| Stress tests (#[ignore]) | 8 | ~100ms |
| **Total** | **118** | **~150ms** |

---

## Branch Tests (branch.rs)

| ID | Name | Purpose | Status |
|----|------|---------|--------|
| T1 | `root_branch_starts_at_position_2` | Root branch initial state | passing |
| T2 | `tree_branch_has_parent` | Tree branch parent linkage | passing |
| T3 | `dag_branch_has_two_parents` | Dag branch dual parents | passing |
| T4 | `next_position_increments` | Position counter starts at 2, increments to 3+ | passing |
| T5 | `install_branch_first_child_goes_left` | First child installed on left | passing |
| T6 | `install_branch_second_child_rotates` | Swap-after-recurse distributes children | passing |
| T7 | `install_branch_idempotent_for_self` | Self-install is a no-op | passing |
| T8 | `install_branch_grows_depth` | 5 children produce depth > 1 | passing |
| T_extra | `evict_transitions_to_stub` | Evict changes state to Stub | passing |
| T_extra | `branch_id_stability_across_evict` | BranchId survives eviction | passing |
| T_extra | `evict_already_stubbed_is_idempotent` | Double-evict is safe | passing |
| T_extra | `contents_hash_is_deterministic` | Hash is stable | passing |
| P6 | `stress_install_branch_1000` | 1,000 children, tree traversal reachability | ignored |

## Trace Tests (trace.rs)

| ID | Name | Purpose | Status |
|----|------|---------|--------|
| T9 | `equality_same_branch_same_position` | Equality semantics | passing |
| T10 | `inequality_different_position` | Same branch, different position | passing |
| T11 | `inequality_different_branch` | Different branches, same position | passing |
| T12 | `hash_deterministic` | Hash is stable across calls | passing |
| T13 | `hash_formula` | Hash matches documented formula | passing |

## DagWood Tests (dagwood.rs)

| ID | Name | Purpose | Status |
|----|------|---------|--------|
| D1 | `constructor_root_is_position_1` | Root at (1,1) | passing |
| D2 | `constructor_initial_branch_at_position_3` | Trunk branch starts at position 3 | passing |
| D3 | `constructor_creates_one_trunk_entry` | One trunk entry after construction | passing |
| D4 | `new_position_returns_position_3` | Fork returns position 3 | passing |
| D5 | `new_position_creates_distinct_branches` | Each fork gets a unique branch | passing |
| D6 | `new_position_populates_branch_tree` | Forks populate install_branch tree | passing |
| D7 | `reflexivity` | A <= A for all positions | passing |
| D8 | `antisymmetry` | A<=B and B<=A implies A==B | passing |
| D9 | `transitivity` | A<=B and B<=C implies A<=C | passing |
| D10 | `root_ancestor_of_all` | Root is ancestor of every position | passing |
| D11 | `same_branch_monotonic_ordering` | Positions on same branch are ordered | passing |
| D12 | `simple_fork_ancestry` | Fork position descends from trunk | passing |
| D13 | `simple_merge_ancestry` | Merge descends from both parents | passing |
| D14 | `cross_branch_transitivity` | A<=root and root<=merged implies A<=merged | passing |
| D15 | `deeper_ancestry` | Multi-level ancestry chain | passing |
| D16 | `diverged_descendants_incomparable` | Forked positions are incomparable | passing |
| D17 | `no_phantom_ordering` | Unrelated positions have no ordering | passing |
| D18 | `cache_reuse_same_reference` | Cache hit for same reference | passing |
| D19 | `cache_equals_recomputed_simple` | Cache matches brute force (simple) | passing |
| D20 | `cache_invalidation_new_reference` | Cache clears on reference change | passing |
| D21 | `cache_equals_recomputed_deep` | Cache matches brute force (deep) | passing |
| D22 | `dag_convergence_cache_value` | Cache[trunk] = max(path values) | passing |
| D23 | `deep_dag_multi_merge` | Ancestry through multiple merge layers | passing |
| D24 | `max_over_paths` | Max over all paths in diamond | passing |
| D25 | `merge_preserves_parent_incomparability` | Parents remain incomparable after merge | passing |
| D26 | `property_reflexivity` | Property: A<=A on random DAGs (5 seeds, 30 ops) | passing |
| D27 | `property_antisymmetry` | Property: antisymmetry on random DAGs (5 seeds) | passing |
| D28 | `property_transitivity` | Property: transitivity on random DAGs (5 seeds) | passing |
| D29 | `property_cache_equivalence` | Property: cache=brute on random DAGs (5 seeds) | passing |
| D30 | `stress_deep_linear_chain` | 200-position chain, cache verification | passing |
| D31 | `stress_wide_fork_tree` | 100 root forks, pairwise incomparability | passing |
| D32 | `stress_repeated_merges` | 50 merge-extend cycles | passing |
| D33 | `stress_heavy_cache_reuse` | 1,020 comparisons against same reference | passing |
| S1 | `same_branch_successor` | Next position is a successor | passing |
| S2 | `no_same_branch_successor_at_tip` | Tip has no same-branch successor | passing |
| S3 | `cross_branch_successors` | Root has cross-branch successors | passing |
| S4 | `no_cross_branch_successors_for_leaf` | Leaf has no cross-branch successors | passing |
| S5 | `successors_after_fork` | Same + cross branch successors combined | passing |
| S6 | `successors_at_branch_end_with_forks` | Fork creates cross-branch successor | passing |
| S7 | `successors_are_forward` | Every successor S of P satisfies P <= S | passing |
| V1 | `trace_view_matches_is_le` | TraceView agrees with is_le (basic) | passing |
| V2 | `trace_view_independent_of_internal_cache` | TraceView ignores DagWood cache state | passing |
| V3 | `visible_branches_and_max` | Branch count and max position correct | passing |
| V4 | `visible_max_none_for_unreachable` | Unreachable branches return None | passing |
| V5 | `trace_view_on_deep_dag` | Visibility through multi-level DAG | passing |
| V6 | `trace_view_matches_is_le_on_random_dags` | Property: view=brute on random DAGs (5 seeds) | passing |
| P1 | `stress_deep_linear_10k` | 10,000 position chain, sampled is_le checks | ignored |
| P2 | `stress_exponential_merge_dag` | 2,047 branches (binary merge tree), visited-set test | ignored |
| P7 | `stress_cache_thrashing` | 1,000 is_le calls, 10 alternating references | ignored |
| P8 | `stress_trace_view_500_branches` | TraceView on 500+ branch DAG | ignored |

## Content Tests (content.rs)

| ID | Name | Purpose | Status |
|----|------|---------|--------|
| C1 | `basic_creation` | Create node + span + text + attach | passing |
| C2 | `structural_attachment` | Parent-child structure via AttachChild | passing |
| C3 | `same_branch_overwrite` | Later assertion overwrites earlier | passing |
| C4 | `delete_suppression` | DeleteSpan hides span from view | passing |
| C5 | `detach_suppression` | DetachChild hides child from view | passing |
| C6 | `cross_branch_merge_alternatives` | 3-branch merge produces 3 alternatives | passing |
| C7 | `visibility_filtering` | Assertions outside view are invisible | passing |
| C8 | `annotation_on_node` | Annotation attached to node | passing |
| C9 | `annotation_on_span` | Annotation attached to span | passing |
| C10 | `delete_annotation` | DeleteAnnotation suppresses annotation | passing |
| C11 | `delete_node_suppresses` | DeleteNode hides node and descendants | passing |
| C12 | `view_before_creation` | View at earlier position sees nothing | passing |
| C13 | `annotation_on_span` | Annotation data preserved through materialization | passing |
| C14 | `structural_attachment` | Ordinal ordering of children | passing |
| M1 | `merge_compatible_different_properties` | Text + annotation coexist | passing |
| M2 | `merge_text_conflict_produces_alternatives` | Text conflict preserved as alternatives | passing |
| M3 | `merge_agreement_collapses` | Same value collapses to Single | passing |
| M4 | `merge_delete_vs_modify` | Delete wins over modify | passing |
| M5 | `merge_multi_merge_preserves_alternatives` | Diamond-of-diamonds: 4 alternatives survive | passing |
| S1-S16 | `serde_*` | Serde round-trip tests (16 tests) | passing |
| P3 | `stress_materialize_10k_assertions` | 100 nodes x 10 spans, full document materialization | ignored |
| P4 | `stress_deep_nesting_100` | 100 nested node levels, recursive materialization | ignored |
| P5 | `stress_100_branch_alternatives` | 100 branches with conflicting text, all alternatives preserved | ignored |
| COV1 | `materialize_entity_node` | Entity dispatcher: Node variant | passing |
| COV2 | `materialize_entity_span` | Entity dispatcher: Span variant | passing |
| COV3 | `materialize_entity_annotation` | Entity dispatcher: Annotation variant | passing |
| COV4 | `materialize_entity_not_found` | Entity dispatcher: NotFound variant | passing |
| COV5 | `alternative_set_values` | values() accessor for Single and Alternatives | passing |
| COV6 | `alternative_set_is_single` | is_single() returns correct bool | passing |
| COV7 | `alternative_set_single_value` | single_value() returns Some/None correctly | passing |
| COV8 | `alternative_set_empty_alternatives` | Empty Alternatives edge case | passing |
| COV9 | `all_assertions_accessor` | all_assertions() length tracking | passing |

## Ent Tests (ent.rs)

| ID | Name | Purpose | Status |
|----|------|---------|--------|
| E1 | `ent_new_trace_returns_distinct_branches` | Each trace gets unique branch | passing |
| E2 | `ent_new_trace_returns_position_3` | Trace starts at position 3 | passing |
| E3 | `ent_table_segment_max_size` | Segment max is 16384 | passing |

## WASM Tests (wasm.rs)

| ID | Name | Purpose | Status |
|----|------|---------|--------|
| W1 | `wasm_add_valid_payload` | Valid JSON payload accepted | passing |
| W2 | `wasm_add_rejects_unknown_variant` | Unknown variant throws with suggestion | passing |
| W3 | `wasm_add_rejects_missing_field` | Missing field throws with field name | passing |
| W4 | `wasm_add_rejects_wrong_type` | Wrong JSON type throws | passing |
| W5 | `wasm_add_rejects_invalid_json` | Non-JSON input throws | passing |
| W6 | `wasm_materialize_empty_store` | Empty store returns null root | passing |
| W7 | `wasm_assertion_count_tracks_adds` | Count increments with each add | passing |
| W8 | `wasm_full_pipeline` | Create doc, add assertions, materialize, verify JSON | passing |
| W9 | `wasm_materialize_document_json_string` | JSON string output works | passing |
| W10 | `wasm_large_document_pipeline` | 200 nodes through full WASM pipeline | passing |

## Enhancement Opportunities

Areas for future expansion:

| Area | Current Limitation | Enhancement |
|------|-------------------|-------------|
| P1 scale | 10K chain | Push to 100K to benchmark is_le cache |
| P3 scale | 10K assertions | Push to 100K, add timing assertions |
| P4 depth | 100 levels | Push to 1,000 levels, test stack limits |
| P5 branches | 100 alternatives | Push to 1,000, benchmark AlternativeSet growth |
| P6 children | 1,000 children | Push to 10,000, verify install_branch balance |
| P2 merges | 2,047 branches | Push to 4 levels deeper (32K branches) |
| Concurrent operations | Not tested | Interleave fork/merge/add/materialize randomly |
| Eviction stress | Not tested | Evict 50% of branches, then access patterns |
| Serialization throughput | Not tested | Benchmark serde_json for 100K assertion documents |
| WASM browser tests | Not tested | Run test suite in actual browser via wasm-pack test --chrome |
