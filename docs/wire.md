# Xudanu Wire Protocol

> Generated from real server traffic.
> Regenerate: `python3 scripts/gen-wire-doc.py`

## Envelope (all requests)

```json
{"v": 2, "type": "request", "id": <n>, "op": "<name>", "payload": {...}}
```

## Envelope (all responses)

```json
{"v": 2, "type": "response", "id": <same>, "value": {...}}
{"v": 2, "type": "error", "id": 0, "code": "...", "message": "..."}
```

## Auth sequence

```
session_connect → session_login_public  (anonymous)
session_connect → club_id_by_name → session_login → session_authenticate  (identity)
session_connect → club_id_by_name → session_login → session_authenticate  (admin)
```

---

## Simple operations

| Op | Auth | Payload | Response value |
|---|---|---|---|
| `session_connect` | none | `—` | `{"type":"id","value":13575072539142736027}` |
| `session_login_public` | none | `—` | `{"type":"id","value":1000}` |
| `work_create` | logged_in | `{"edition":{"text":"Hello from the wire doc generator."}}` | `{}` |
| `work_get_edition` | read | `—` | `{}` |
| `work_star` | owner | `—` | `{}` |
| `work_publish` | owner | `—` | `{}` |
| `blob_stats` | none | `—` | `{"type":"blob_stats_info","value":{"total_blobs":25,"total_bytes":1557}}` |
| `club_who_am_i` | public | `—` | `{"type":"club_who_am_i_result","value":{"clubs":[]}}` |
| `trail_list` | none | `—` | `{"type":"trail_list_result","value":[]}` |
| `connection_pins_get` | logged_in | `—` | `{"type":"connection_pins","value":[]}` |
| `attribution_log_status` | none | `—` | `{"type":"attribution_log_status_result","value":{"entry_count":443,"chain_valid":true,"last_sequence…` |
| `metrics_snapshot` | admin | `—` | `{}` |
| `admin_active_sessions` | admin | `—` | `{}` |

## Complex operations

### `whoami`

Check current identity.

**Payload:**
```json
()  // no payload
```

**Response value:**
```json
{
  "v": 2,
  "type": "error",
  "id": 0,
  "code": "protocol_error",
  "message": "frame parse: payload decode error: unknown variant `whoami`, expected one of `session_connect`, `session_disconnect`, `session_login`, `session_login_by_name`, `session_authenticate`, `session_login_public`, `session_ticket_issue`, `session_ticket_redeem`, `server_get_by_id`, `server_get_by_be_id`, `club_create`, `club_create_named`, `club_get`, `club_by_name`, `club_id_by_name`, `club_name_by_id`, `club_names`, `work_create`, `work_get_edition`, `work_revise`, `work_grab`, `work_release`, `work_save_and_release`, `work_force_release`, `work_is_grabbed`, `work_grabber`, `work_request_grab`, `work_cancel_grab_request`, `work_grab_waiters`, `work_can_read`, `work_can_revise`, `work_set_read_club`, `work_set_edit_club`, `work_set_history_club`, `work_read_club`, `work_edit_club`, `work_history_club`, `work_transclusion_chain`, `work_revision_count`, `work_fetch_revision`, `work_sponsor`, `work_unsponsor`, `work_sponsors`, `work_star`, `work_set_source`, `web_fetch_sanitize`, `work_unstar`, `work_is_starred`, `connection_pin_set`, `connection_pin_unset`, `connection_pins_get`, `cross_server_backlinks_get`, `work_graph`, `work_kind_get`, `work_kind_set`, `work_license_get`, `work_license_set`, `work_list_by_kind`, `work_set_text`, `work_revisions_list`, `work_blob_list`, `work_text_at_revision`, `work_revision_describe`, `work_revision_mark_notable`, `work_revision_rollback`, `trail_create`, `trail_delete`, `trail_rename`, `trail_add_stop`, `trail_remove_stop`, `trail_reorder_stops`, `trail_list`, `trail_get`, `work_owner`, `work_publish`, `work_unpublish`, `work_irrevocably_unpublish`, `work_archive`, `work_unarchive`, `work_list_archived`, `work_is_published`, `work_merge`, `work_ghost`, `work_fetch_revision_range`, `club_set_default_read_club`, `club_set_default_edit_club`, `club_set_password`, `club_clear_credential`, `club_create_personal`, `club_who_am_i`, `club_add_member`, `club_remove_member`, `club_members`, `club_roster`, `edition_store`, `edition_get`, `admin_accept_connections`, `admin_is_accepting_connections`, `admin_active_sessions`, `admin_shutdown`, `admin_grant`, `admin_revoke_grant`, `admin_grants`, `admin_server_info`, `work_list`, `work_list_by_owner`, `work_revise_delta`, `work_diff_narration`, `work_writing_feedback`, `work_suggest_title`, `work_set_title`, `work_auto_tag`, `work_backlinks`, `link_create`, `link_get`, `link_update`, `link_delete`, `link_list_for_work`, `link_add_end`, `link_remove_end`, `link_set_types`, `link_type_register`, `link_type_list`, `link_query`, `find_excerpt_positions`, `find_transcluders`, `find_works_for_content`, `find_text_transcluders`, `find_shared_regions`, `work_diff_regions`, `server_stats`, `metrics_snapshot`, `blob_upload`, `blob_get`, `blob_get_preview`, `blob_exists`, `blob_info`, `blob_stats`, `overlay_apply`, `overlay_get`, `label_create`, `label_get_positions`, `edition_relabel`, `edition_rebind`, `can_make_identical`, `make_range_identical`, `identity_unify`, `identity_resolve`, `edition_retrieve`, `edition_cost`, `element_insert`, `transclusion_place_cross_server`, `cross_server_span_refresh`, `element_update`, `render_transclusions`, `annotation_create`, `annotation_delete`, `annotation_attach_node`, `annotation_attach_span`, `annotation_get`, `annotation_list`, `content_shared_region`, `content_map_shared_to`, `content_map_shared_onto`, `positions_of`, `range_transcluders`, `range_works`, `ordered_bundles`, `transclusion_depth`, `version_is_before`, `version_ancestors`, `version_descendants`, `version_trace_position`, `provenance_ancestry`, `admin_recorder_create`, `admin_recorder_record`, `admin_recorder_list`, `admin_recorder_get`, `admin_server_health`, `resolve_inline_transclusions`, `migrate_compound_to_inline`, `element_remove_transclusion`, `attribution_query_resolved`, `crypto_get_public_key`, `crypto_sign_data`, `crypto_verify_signature`, `crypto_key_rotation`, `crypto_key_history`, `work_endorse`, `work_retract`, `work_endorsements`, `edition_endorse`, `edition_retract`, `edition_endorsements`, `edition_visible_endorsements`, `edition_total_endorsements`, `federation_info`, `federation_peers`, `federated_transclusion_query`, `federated_content_fetch`, `endorsement_sync`, `endorsement_add`, `endorsement_retract`, `endorsement_query`, `state_sync`, `state_alternatives`, `membership_join_request`, `membership_join_response`, `membership_endorse_offer`, `membership_endorse_accept`, `membership_sync`, `membership_sync_result`, `membership_leave`, `membership_list`, `membership_verify`, `governance_propose`, `governance_prepare`, `governance_commit`, `governance_seal`, `governance_log`, `governance_status`, `crdt_sync_open`, `crdt_sync_close`, `crdt_sync_update`, `crdt_sync_diff`, `crdt_sync_full_state`, `crdt_sync_materialize`, `crdt_sync_subscriber_count`, `crdt_sync_text`, `crdt_awareness_update`, `crdt_awareness_get`, `crdt_register_author`, `attribution_query`, `attribution_verify`, `attribution_log_status`, `attestation_report`, `work_text_range`, `work_outline`, `work_search`, `work_goto`, `prov_json_export`, `server_directory_list`, `server_directory_add`, `server_directory_remove`, `server_directory_set_trust`, `network_set_enabled`, `external_links_set_enabled`, `work_admin_delete`, `admin_edit_policy_set`, `admin_session_kick`, `admin_audit_tail`, `admin_clubs_list`, `admin_grant_admin`, `admin_revoke_admin`, `cross_server_resolve`, `cross_server_fetch_work`, `cross_server_list_works`, `federated_search`, `fetch_introductions`, `add_discovered_server`, `cross_server_link_create`, `cross_server_link_list`, `fetch_remote_identity`, `tumbler_resolve`, `bloom_filter_get`, `bloom_filter_check`, `federation_attestation_create`, `federation_attestation_verify`, `federation_bundle_export`, `cluster_verification_create`, `cross_server_signature_verify`, `historical_author_register`, `historical_author_get`, `historical_author_search`, `historical_author_list`, `import_source_work`, `import_epub`, `source_detect`, `source_pattern_list`, `work_list_by_author`, `content_match`, `work_apply_source_attribution`, `work_apply_transclusion_attribution`, `work_summary`, `work_version_timeline`, `passage_composition`, `global_text_search`, `seed_demo_attribution`, `trail_update`, `trail_publish`, `trail_unpublish`, `trail_list_published`, `trail_list_categories`, `trail_derived_work`"
}
```

### `work_list`

List works visible to the session.

**Payload:**
```json
{
  "limit": 10
}
```

**Response value:**
```json
{
  "type": "paginated_work_list",
  "value": {
    "entries": [
      {
        "work_id": 1099,
        "owner": 1001,
        "revision_count": 0,
        "is_grabbed": false,
        "char_count": 223,
        "title": "Compare: Paper Two",
        "read_club": 1000,
        "is_source": false,

...
```

### `server_stats`

Get server statistics.

**Payload:**
```json
()  // no payload
```

**Response value:**
```json
{
  "type": "server_info",
  "value": {
    "version": "1.7.0",
    "session_count": 1,
    "work_count": 102,
    "club_count": 6,
    "edition_count": 0,
    "is_accepting_connections": true,
    "public_club_id": 1000,
    "llm_enabled": false,
    "llm_usage": {
      "total_requests": 0,
      
...
```

### `club_names`

List known club names.

**Payload:**
```json
()  // no payload
```

**Response value:**
```json
{
  "type": "paginated_club_names",
  "value": {
    "entries": [
      [
        "empty",
        1003
      ],
      [
        "admin",
        1001
      ],
      [
        "david@dgjones.info",
        1004
      ],
      [
        "other",
        1008
      ],
      [
        "access",
       
...
```

### `federation_info`

Get federation status.

**Payload:**
```json
()  // no payload
```

**Response value:**
```json
{
  "type": "federation_info_result",
  "value": {
    "server_id": "672143aa39d6dcaf",
    "federation_domain": "xudanu",
    "key_id": 16411317307619014103,
    "verifying_key": [
      103,
      33,
      67,
      170,
      57,
      214,
      220,
      175,
      170,
      34,
      91,
  
...
```

### `crypto_get_public_key`

Get the server's public key.

**Payload:**
```json
()  // no payload
```

**Response value:**
```json
{
  "type": "crypto_public_key_result",
  "value": {
    "key_id": 16411317307619014103,
    "verifying_key": [
      103,
      33,
      67,
      170,
      57,
      214,
      220,
      175,
      170,
      34,
      91,
      244,
      41,
      199,
      253,
      62,
      187,
      19
...
```

### `search`

Search public content.

**Payload:**
```json
()  // no payload
```

**Response value:**
```json
{
  "v": 2,
  "type": "error",
  "id": 0,
  "code": "protocol_error",
  "message": "frame parse: payload decode error: unknown variant `search`, expected one of `session_connect`, `session_disconnect`, `session_login`, `session_login_by_name`, `session_authenticate`, `session_login_public`, `session_ticket_issue`, `session_ticket_redeem`, `server_get_by_id`, `server_get_by_be_id`, `club_create`, `club_create_named`, `club_get`, `club_by_name`, `club_id_by_name`, `club_name_by_id`, `club_names`, `work_create`, `work_get_edition`, `work_revise`, `work_grab`, `work_release`, `work_save_and_release`, `work_force_release`, `work_is_grabbed`, `work_grabber`, `work_request_grab`, `work_cancel_grab_request`, `work_grab_waiters`, `work_can_read`, `work_can_revise`, `work_set_read_club`, `work_set_edit_club`, `work_set_history_club`, `work_read_club`, `work_edit_club`, `work_history_club`, `work_transclusion_chain`, `work_revision_count`, `work_fetch_revision`, `work_sponsor`, `work_unsponsor`, `work_sponsors`, `work_star`, `work_set_source`, `web_fetch_sanitize`, `work_unstar`, `work_is_starred`, `connection_pin_set`, `connection_pin_unset`, `connection_pins_get`, `cross_server_backlinks_get`, `work_graph`, `work_kind_get`, `work_kind_set`, `work_license_get`, `work_license_set`, `work_list_by_kind`, `work_set_text`, `work_revisions_list`, `work_blob_list`, `work_text_at_revision`, `work_revision_describe`, `work_revision_mark_notable`, `work_revision_rollback`, `trail_create`, `trail_delete`, `trail_rename`, `trail_add_stop`, `trail_remove_stop`, `trail_reorder_stops`, `trail_list`, `trail_get`, `work_owner`, `work_publish`, `work_unpublish`, `work_irrevocably_unpublish`, `work_archive`, `work_unarchive`, `work_list_archived`, `work_is_published`, `work_merge`, `work_ghost`, `work_fetch_revision_range`, `club_set_default_read_club`, `club_set_default_edit_club`, `club_set_password`, `club_clear_credential`, `club_create_personal`, `club_who_am_i`, `club_add_member`, `club_remove_member`, `club_members`, `club_roster`, `edition_store`, `edition_get`, `admin_accept_connections`, `admin_is_accepting_connections`, `admin_active_sessions`, `admin_shutdown`, `admin_grant`, `admin_revoke_grant`, `admin_grants`, `admin_server_info`, `work_list`, `work_list_by_owner`, `work_revise_delta`, `work_diff_narration`, `work_writing_feedback`, `work_suggest_title`, `work_set_title`, `work_auto_tag`, `work_backlinks`, `link_create`, `link_get`, `link_update`, `link_delete`, `link_list_for_work`, `link_add_end`, `link_remove_end`, `link_set_types`, `link_type_register`, `link_type_list`, `link_query`, `find_excerpt_positions`, `find_transcluders`, `find_works_for_content`, `find_text_transcluders`, `find_shared_regions`, `work_diff_regions`, `server_stats`, `metrics_snapshot`, `blob_upload`, `blob_get`, `blob_get_preview`, `blob_exists`, `blob_info`, `blob_stats`, `overlay_apply`, `overlay_get`, `label_create`, `label_get_positions`, `edition_relabel`, `edition_rebind`, `can_make_identical`, `make_range_identical`, `identity_unify`, `identity_resolve`, `edition_retrieve`, `edition_cost`, `element_insert`, `transclusion_place_cross_server`, `cross_server_span_refresh`, `element_update`, `render_transclusions`, `annotation_create`, `annotation_delete`, `annotation_attach_node`, `annotation_attach_span`, `annotation_get`, `annotation_list`, `content_shared_region`, `content_map_shared_to`, `content_map_shared_onto`, `positions_of`, `range_transcluders`, `range_works`, `ordered_bundles`, `transclusion_depth`, `version_is_before`, `version_ancestors`, `version_descendants`, `version_trace_position`, `provenance_ancestry`, `admin_recorder_create`, `admin_recorder_record`, `admin_recorder_list`, `admin_recorder_get`, `admin_server_health`, `resolve_inline_transclusions`, `migrate_compound_to_inline`, `element_remove_transclusion`, `attribution_query_resolved`, `crypto_get_public_key`, `crypto_sign_data`, `crypto_verify_signature`, `crypto_key_rotation`, `crypto_key_history`, `work_endorse`, `work_retract`, `work_endorsements`, `edition_endorse`, `edition_retract`, `edition_endorsements`, `edition_visible_endorsements`, `edition_total_endorsements`, `federation_info`, `federation_peers`, `federated_transclusion_query`, `federated_content_fetch`, `endorsement_sync`, `endorsement_add`, `endorsement_retract`, `endorsement_query`, `state_sync`, `state_alternatives`, `membership_join_request`, `membership_join_response`, `membership_endorse_offer`, `membership_endorse_accept`, `membership_sync`, `membership_sync_result`, `membership_leave`, `membership_list`, `membership_verify`, `governance_propose`, `governance_prepare`, `governance_commit`, `governance_seal`, `governance_log`, `governance_status`, `crdt_sync_open`, `crdt_sync_close`, `crdt_sync_update`, `crdt_sync_diff`, `crdt_sync_full_state`, `crdt_sync_materialize`, `crdt_sync_subscriber_count`, `crdt_sync_text`, `crdt_awareness_update`, `crdt_awareness_get`, `crdt_register_author`, `attribution_query`, `attribution_verify`, `attribution_log_status`, `attestation_report`, `work_text_range`, `work_outline`, `work_search`, `work_goto`, `prov_json_export`, `server_directory_list`, `server_directory_add`, `server_directory_remove`, `server_directory_set_trust`, `network_set_enabled`, `external_links_set_enabled`, `work_admin_delete`, `admin_edit_policy_set`, `admin_session_kick`, `admin_audit_tail`, `admin_clubs_list`, `admin_grant_admin`, `admin_revoke_admin`, `cross_server_resolve`, `cross_server_fetch_work`, `cross_server_list_works`, `federated_search`, `fetch_introductions`, `add_discovered_server`, `cross_server_link_create`, `cross_server_link_list`, `fetch_remote_identity`, `tumbler_resolve`, `bloom_filter_get`, `bloom_filter_check`, `federation_attestation_create`, `federation_attestation_verify`, `federation_bundle_export`, `cluster_verification_create`, `cross_server_signature_verify`, `historical_author_register`, `historical_author_get`, `historical_author_search`, `historical_author_list`, `import_source_work`, `import_epub`, `source_detect`, `source_pattern_list`, `work_list_by_author`, `content_match`, `work_apply_source_attribution`, `work_apply_transclusion_attribution`, `work_summary`, `work_version_timeline`, `passage_composition`, `global_text_search`, `seed_demo_attribution`, `trail_update`, `trail_publish`, `trail_unpublish`, `trail_list_published`, `trail_list_categories`, `trail_derived_work`"
}
```
