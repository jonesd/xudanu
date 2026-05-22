# Xudanu Wire Protocol API Reference

Protocol version: 2

## Connection

Connect via WebSocket to:

```
ws://host:8080/xudanu?format=json&version=2
```

Query parameters:
- `format=json` -- select the JSON codec (alternatively, omit for binary)
- `version=2` -- request protocol version 2

## Handshake

Upon connection, the server sends a handshake frame:

```json
{
  "v": 2,
  "type": "handshake",
  "id": 0,
  "server_version": 2,
  "negotiated_version": 2,
  "server_id": "xudanu-<pkg-version>",
  "server_capabilities": ["json", "binary", "detector_events", "admin"]
}
```

The client must wait for the handshake before sending requests.

## Request Format

```json
{"v": 2, "type": "request", "id": 1, "op": "<operation_name>", "payload": {...}}
```

| Field     | Type   | Description                        |
|-----------|--------|------------------------------------|
| `v`       | u8     | Protocol version (2)               |
| `type`    | string | `"request"`                        |
| `id`      | u16    | Client-assigned request ID         |
| `op`      | string | Operation name (snake_case)        |
| `payload` | object | Operation-specific payload (omitted for no-payload ops) |

## Response Format

Success:

```json
{"v": 2, "type": "response", "id": 1, "value": {"type": "<response_type>", "value": ...}}
```

Error:

```json
{"v": 2, "type": "error", "id": 0, "code": "not_authorized", "message": "session not logged in"}
```

### Error Codes

| Code                       | Description                          |
|----------------------------|--------------------------------------|
| `not_authorized`           | Session lacks required authority     |
| `not_found`                | Requested resource does not exist    |
| `already_exists`           | Resource already exists              |
| `not_grabbed`              | Work is not grabbed by session       |
| `already_grabbed`          | Work is already grabbed              |
| `session_required`         | No valid session for operation       |
| `invalid_argument`         | Bad or missing argument              |
| `type_mismatch`            | Element type does not match          |
| `lock_failed`              | Authentication lock failure          |
| `session_not_found`        | Session ID does not exist            |
| `work_not_found`           | Work ID does not exist               |
| `club_not_found`           | Club ID does not exist               |
| `edition_not_found`        | Edition ID does not exist            |
| `internal`                 | Internal server error                |
| `protocol_error`           | Malformed protocol message           |
| `admin_required`           | Admin authority required             |
| `unauthorized`             | Not authorized for specific action   |
| `server_shutting_down`     | Server is shutting down              |
| `not_accepting_connections`| Server is not accepting connections  |

## Common Types

### BeId

A `BeId` is a u64 representing a unique entity identifier.

### EditionPayload

```json
{"type": "text", "value": "hello world"}
```

```json
{"type": "entries", "value": [[0, {"type": "text", "text": "hello"}], [1, {"type": "text", "text": "world"}]]}
```

```json
{"type": "empty"}
```

| Variant   | Value Type                    | Description                    |
|-----------|-------------------------------|--------------------------------|
| `text`    | string                        | Plain text content             |
| `entries` | array of [i64, RangeElement]  | Position-element pairs         |
| `empty`   | null                          | Empty edition                  |

### XnRegion

An interval region:

```json
{"start": 0, "end": 10}
```

### RangeElement

```json
{"type": "text", "text": "hello"}
```

```json
{"type": "label", "label_id": 123, "text": "content"}
```

### HyperRefPayload

```json
{
  "kind": "single",
  "work_context": 123,
  "original_context": null,
  "path_context": null,
  "excerpt": "matching text"
}
```

### TextDeltaOp

Used by `work_revise_delta` for incremental text editing:

```json
{"type": "retain", "count": 5}
```

```json
{"type": "insert", "text": "new text"}
```

```json
{"type": "delete", "count": 3}
```

### RetrieveFlagsPayload

```json
{
  "ignore_total_ordering": false,
  "ignore_array_ordering": false,
  "separate_owners": false
}
```

### LockCredential

```json
{"type": "boo"}
```

```json
{"type": "password", "password": "secret"}
```

```json
{"type": "challenge_response", "response": [1, 2, 3]}
```

## Auth Levels

| Level  | Description                                                |
|--------|------------------------------------------------------------|
| none   | No authentication required                                 |
| login  | Session must be logged in (via login, authenticate, etc.)  |
| admin  | Session must have admin club authority                     |

---

## Session Operations

| Operation              | Auth  | Payload                                           | Response       | Description                                  |
|------------------------|-------|---------------------------------------------------|----------------|----------------------------------------------|
| `session_connect`      | none  | (none)                                            | `id`           | Establish session, returns session ID        |
| `session_disconnect`   | none  | (none)                                            | `void`         | Disconnect session                           |
| `session_login`        | none  | `club_id: BeId`                                   | `void`         | Login as club                                |
| `session_login_by_name`| none  | `club_name: string`                               | `void`         | Login by club name                           |
| `session_authenticate` | none  | `club_id: BeId`, `credential: LockCredential`     | `ids`          | Authenticate with credential, returns auth clubs |
| `session_login_public` | none  | (none)                                            | `id`           | Login as public user, returns public club ID |

## Server Operations

| Operation          | Auth  | Payload              | Response        | Description                    |
|--------------------|-------|----------------------|-----------------|--------------------------------|
| `server_get_by_id` | none  | `id: u64`            | `range_element` | Look up element by global ID  |
| `server_get_by_be_id`| none| `be_id: BeId`        | `range_element` | Look up element by BeId       |

## Club Operations

| Operation          | Auth  | Payload                                        | Response     | Description                         |
|--------------------|-------|------------------------------------------------|--------------|-------------------------------------|
| `club_create`      | login | `description: EditionPayload`                  | `id`         | Create a new club                   |
| `club_create_named`| login | `name: string`, `description: EditionPayload`  | `id`         | Create a named club                 |
| `club_get`         | none  | `club_id: BeId`                                | `id`         | Verify club exists, returns its ID  |
| `club_by_name`     | none  | `name: string`                                 | `id`         | Look up club ID by name             |
| `club_id_by_name`  | none  | `name: string`                                 | `id`         | Alias for `club_by_name`            |
| `club_name_by_id`  | none  | `club_id: BeId`                                | `string`     | Look up club name by ID             |
| `club_names`       | none  | (none)                                         | `club_names` | List all club name-ID pairs         |

## Work Operations

| Operation            | Auth  | Payload                                                    | Response        | Description                                   |
|----------------------|-------|------------------------------------------------------------|-----------------|-----------------------------------------------|
| `work_create`        | login | `edition: EditionPayload`                                  | `id`            | Create a new work with initial edition        |
| `work_get_edition`   | none  | `work_id: BeId`                                            | `edition`       | Get current edition of a work                 |
| `work_revise`        | login | `work_id: BeId`, `edition: EditionPayload`                 | `humber`        | Replace work edition, returns new revision #  |
| `work_revise_delta`  | login | `work_id: BeId`, `base_revision: u64`, `ops: [TextDeltaOp]`| `humber`       | Apply text delta to work, returns revision #  |
| `work_grab`          | login | `work_id: BeId`                                            | `void`          | Lock work for editing                         |
| `work_release`       | login | `work_id: BeId`                                            | `void`          | Unlock work                                   |
| `work_is_grabbed`    | none  | `work_id: BeId`                                            | `boolean`       | Check if work is currently grabbed            |
| `work_grabber`       | none  | `work_id: BeId`                                            | `humber`        | Get session ID of grabber (0 if ungrabbed)    |
| `work_can_read`      | none  | `work_id: BeId`                                            | `boolean`       | Check if current session can read work        |
| `work_can_revise`    | none  | `work_id: BeId`                                            | `boolean`       | Check if current session can revise work      |
| `work_set_read_club` | login | `work_id: BeId`, `club_id: BeId \| null`                   | `void`          | Set the read-access club for a work           |
| `work_set_edit_club` | login | `work_id: BeId`, `club_id: BeId \| null`                   | `void`          | Set the edit-access club for a work           |
| `work_read_club`     | none  | `work_id: BeId`                                            | `humber`        | Get read-access club ID (0 if none)           |
| `work_edit_club`     | none  | `work_id: BeId`                                            | `humber`        | Get edit-access club ID (0 if none)           |
| `work_revision_count`| none  | `work_id: BeId`                                            | `humber`        | Get number of revisions                       |
| `work_fetch_revision`| none  | `work_id: BeId`, `number: u64`                             | `edition`       | Fetch a specific revision edition             |
| `work_sponsor`       | login | `work_id: BeId`, `club_id: BeId`                           | `void`          | Add a sponsor to a work                       |
| `work_unsponsor`     | login | `work_id: BeId`, `club_id: BeId`                           | `void`          | Remove a sponsor from a work                  |
| `work_sponsors`      | none  | `work_id: BeId`                                            | `ids`           | List sponsor club IDs                         |
| `work_owner`         | none  | `work_id: BeId`                                            | `humber`        | Get owner club ID (0 if none)                 |
| `work_list`          | none  | (none)                                                     | `work_list`     | List all works with metadata                  |
| `work_list_by_owner` | none  | `owner: BeId`                                              | `work_list`     | List works owned by a club                    |

## Edition Operations

| Operation          | Auth  | Payload                                                    | Response            | Description                                     |
|--------------------|-------|------------------------------------------------------------|---------------------|-------------------------------------------------|
| `edition_store`    | login | `edition: EditionPayload`                                  | `id`                | Store a standalone edition, returns its BeId    |
| `edition_get`      | none  | `be_id: BeId`                                              | `edition`           | Get a stored edition by BeId                    |
| `edition_retrieve` | none  | `work_id: BeId`, `region: XnRegion?`, `flags: RetrieveFlagsPayload?` | `bundle_results` | Retrieve edition bundles with optional region filter and flags |
| `edition_cost`     | none  | `work_id: BeId`, `method: string?`                         | `storage_cost_result`| Calculate storage cost. Method: `"total_shared"` (default), `"omit_shared"`, or `"prorate_shared"` |

## Link Operations

| Operation          | Auth  | Payload                                                                                     | Response   | Description                       |
|--------------------|-------|---------------------------------------------------------------------------------------------|------------|-----------------------------------|
| `link_create`      | login | `origin: BeId`, `destination: BeId`, `origin_ref: HyperRefPayload?`, `destination_ref: HyperRefPayload?` | `id`       | Create a link between two works   |
| `link_get`         | none  | `link_id: BeId`                                                                             | `link_info`| Get link details                  |
| `link_update`      | login | `link_id: BeId`, `origin_ref: HyperRefPayload?`, `destination_ref: HyperRefPayload?`        | `void`     | Update link references            |
| `link_delete`      | login | `link_id: BeId`                                                                             | `void`     | Delete a link                     |
| `link_list_for_work`| none | `work_id: BeId`                                                                             | `link_list`| List all links involving a work   |

## Content Discovery Operations

| Operation              | Auth  | Payload                                                        | Response                  | Description                              |
|------------------------|-------|----------------------------------------------------------------|---------------------------|------------------------------------------|
| `find_transcluders`    | none  | `content_be_id: BeId`                                          | `transclusion_results`    | Find editions/works that transclude content |
| `find_works_for_content`| none | `content_be_id: BeId`                                          | `work_ids`                | Find works containing content           |
| `find_text_transcluders`| none | `text: string`                                                 | `text_transclusion_results`| Find works containing text             |
| `find_shared_regions`  | none  | `work_a: BeId`, `work_b: BeId`, `filter_text: string?`         | `shared_regions`          | Find shared content regions between works |

## Content Analysis Operations

| Operation                | Auth  | Payload                                         | Response              | Description                                  |
|--------------------------|-------|-------------------------------------------------|-----------------------|----------------------------------------------|
| `content_shared_region`  | none  | `work_a: BeId`, `work_b: BeId`                  | `shared_region_result`| Get the shared region between two works      |
| `content_map_shared_to`  | none  | `work_a: BeId`, `work_b: BeId`                  | `shared_mapping_result`| Map shared positions from A to B            |
| `content_map_shared_onto`| none  | `work_a: BeId`, `work_b: BeId`                  | `shared_mapping_result`| Map shared positions from A onto B          |
| `positions_of`           | none  | `work_id: BeId`, `element: RangeElement`        | `positions_of_result` | Find positions of element in work            |

## Range Operations

| Operation           | Auth  | Payload                                                    | Response                    | Description                              |
|---------------------|-------|------------------------------------------------------------|-----------------------------|------------------------------------------|
| `range_transcluders`| none  | `work_id: BeId`, `region: XnRegion?`, `direct_only: bool?` | `range_transcluders_result` | Find transcluders within a region        |
| `range_works`       | none  | `work_id: BeId`, `region: XnRegion?`                       | `range_works_result`        | Find works referencing a region          |
| `ordered_bundles`   | none  | `work_id: BeId`, `region: XnRegion?`                       | `ordered_bundles_result`    | Get ordered bundles for a region         |
| `transclusion_depth`| none  | `work_id: BeId`, `position: i64`, `max_depth: usize?`      | `transclusion_depth_result` | Measure transclusion nesting depth       |

## Blob Operations

| Operation         | Auth  | Payload                                          | Response       | Description                                    |
|-------------------|-------|--------------------------------------------------|----------------|------------------------------------------------|
| `blob_upload`     | login | `data: string` (base64), `mime_type: string`     | `blob_meta`    | Upload a blob (max 64 MiB)                     |
| `blob_get`        | none  | `content_hash: string` (16-char hex)             | `string`       | Get blob data (base64-encoded in JSON)         |
| `blob_get_preview`| none  | `content_hash: string` (16-char hex)             | `string`       | Get blob preview image (base64)                |
| `blob_exists`     | none  | `content_hash: string` (16-char hex)             | `boolean`      | Check if blob exists                           |
| `blob_info`       | none  | `content_hash: string` (16-char hex)             | `blob_meta`    | Get blob metadata                              |
| `blob_stats`      | none  | (none)                                           | `blob_stats_info` | Get total blob count and bytes              |

### BlobMeta Response

```json
{
  "type": "blob_meta",
  "value": {
    "content_hash": "a1b2c3d4e5f6a7b8",
    "byte_size": 4096,
    "mime_type": "image/png",
    "preview_hash": "e5f6a7b8a1b2c3d4",
    "width": 800,
    "height": 600
  }
}
```

## Overlay Operations

| Operation      | Auth  | Payload                                                        | Response       | Description                       |
|----------------|-------|----------------------------------------------------------------|----------------|-----------------------------------|
| `overlay_apply`| login | `base_hash: string` (hex), `ops: [ImageOp]`, `mime_type: string` | `blob_meta`    | Apply image overlay to base blob  |
| `overlay_get`  | none  | `overlay_hash: string` (hex)                                   | `overlay_info` | Retrieve overlay definition       |

## Label Operations

| Operation            | Auth  | Payload                                    | Response        | Description                          |
|----------------------|-------|--------------------------------------------|-----------------|--------------------------------------|
| `label_create`       | none  | (none)                                     | `label_info`    | Create a new label, returns label ID |
| `label_get_positions`| none  | `work_id: BeId`, `label_id: u64`           | `label_positions`| Get positions where label occurs    |
| `edition_relabel`    | none  | `work_id: BeId`, `label_id: u64`           | `label_info`    | Relabel edition positions            |
| `edition_rebind`     | login | `work_id: BeId`, `position: i64`, `new_edition: EditionPayload` | `edition` | Rebind element at position with new edition |

## Identity Operations

| Operation            | Auth  | Payload                                                    | Response                   | Description                              |
|----------------------|-------|------------------------------------------------------------|----------------------------|------------------------------------------|
| `can_make_identical` | none  | `source_work_id: BeId`, `target_work_id: BeId`, `position: i64?` | `can_make_identical_result` | Check if elements can be made identical |
| `make_range_identical`| login| `source_work_id: BeId`, `target_work_id: BeId`, `region: XnRegion?` | `make_range_identical_result` | Make a range of elements identical |
| `identity_unify`     | admin | `source_id: u64`, `target_id: u64`                         | `identity_resolve_result`  | Merge two identities                     |
| `identity_resolve`   | none  | `id: u64`                                                  | `identity_resolve_result`  | Resolve identity to canonical ID         |

## Endorsement Operations

| Operation                   | Auth  | Payload                                       | Response            | Description                                  |
|-----------------------------|-------|-----------------------------------------------|---------------------|----------------------------------------------|
| `work_endorse`              | login | `work_id: BeId`, `endorsements: [[u64, u64]]` | `void`              | Add endorsements to a work                   |
| `work_retract`              | login | `work_id: BeId`, `endorsements: [[u64, u64]]` | `void`              | Retract endorsements from a work             |
| `work_endorsements`         | none  | `work_id: BeId`                               | `endorsement_result`| List work endorsements as [club_id, token_id] pairs |
| `edition_endorse`           | login | `edition_id: BeId`, `endorsements: [[u64, u64]]` | `void`           | Add endorsements to an edition               |
| `edition_retract`           | login | `edition_id: BeId`, `endorsements: [[u64, u64]]` | `void`           | Retract endorsements from an edition         |
| `edition_endorsements`      | none  | `edition_id: BeId`                            | `endorsement_result`| List edition endorsements                    |
| `edition_visible_endorsements`| login| `edition_id: BeId`                           | `endorsement_result`| List endorsements visible to current session |
| `edition_total_endorsements`| none  | `edition_id: BeId`                            | `endorsement_result`| List total endorsements including nested     |

Each endorsement is a `[club_id, token_id]` pair.

## Crypto Operations

| Operation              | Auth  | Payload                              | Response                  | Description                          |
|------------------------|-------|--------------------------------------|---------------------------|--------------------------------------|
| `crypto_get_public_key`| none  | (none)                               | `crypto_public_key_result`| Get server public signing + kex keys |
| `crypto_sign_data`     | admin | `data: [u8]`                         | `crypto_sign_result`      | Sign data with server key            |
| `crypto_verify_signature`| none | `data: [u8]`, `signature: [u8]`      | `crypto_verify_result`    | Verify a server signature            |
| `crypto_key_rotation`  | admin | (none)                               | `crypto_key_rotation_result` | Rotate server signing key         |
| `crypto_key_history`   | none  | (none)                               | `crypto_key_history_result`| Get key rotation history            |

## Federation Operations

| Operation                     | Auth  | Payload                                              | Response                       | Description                               |
|-------------------------------|-------|------------------------------------------------------|--------------------------------|-------------------------------------------|
| `federation_info`             | none  | (none)                                               | `federation_info_result`       | Get federation config and peer list       |
| `federation_peers`            | none  | (none)                                               | `federation_peers_result`      | List peer addresses                       |
| `federated_transclusion_query`| none  | `content_fingerprint_hex: string`, `direct_only: bool`| `federated_transclusion_result`| Query local transclusion index by fingerprint |
| `federated_content_fetch`     | none  | `content_fingerprint_hex: string`                    | `federated_content_fetch_result`| Fetch content by fingerprint             |

All federation operations require federation to be enabled on the server.

## Endorsement Sync Operations

| Operation            | Auth  | Payload                                              | Response                    | Description                          |
|----------------------|-------|------------------------------------------------------|-----------------------------|--------------------------------------|
| `endorsement_sync`   | login | `work_fingerprint: string`                           | `endorsement_sync_result`   | Export endorsements for a fingerprint |
| `endorsement_add`    | login | `work_fingerprint: string`, `club_id: u64`, `token_id: u64` | `endorsement_add_result` | Add a federated endorsement    |
| `endorsement_retract`| login | `work_fingerprint: string`, `club_id: u64`, `token_id: u64` | `endorsement_retract_result` | Retract a federated endorsement |
| `endorsement_query`  | login | `work_fingerprint: string`                           | `endorsement_query_result`  | Query endorsements and tombstones     |
| `state_sync`         | login | `work_fingerprints: [string]`                        | `state_sync_result`         | Export reconcile states               |
| `state_alternatives` | login | `work_fingerprint: string`                           | `state_alternatives_result` | List alternative editions for fingerprint |

## Membership Operations

| Operation                 | Auth  | Payload                                                     | Response                          | Description                       |
|---------------------------|-------|-------------------------------------------------------------|-----------------------------------|-----------------------------------|
| `membership_join_request` | login | `entry: MembershipEntry`                                    | `membership_join_result`          | Request to join federation        |
| `membership_endorse_offer`| login | `server_id: string`, `proof: EndorsementProof`              | `membership_endorse_offer_result` | Offer endorsement to a peer       |
| `membership_endorse_accept`| login| `server_id: string`                                         | `membership_endorse_accept_result`| Accept and reciprocate endorsement|
| `membership_sync`         | login | (none)                                                      | `membership_sync_result`          | Export full membership list       |
| `membership_leave`        | admin | (none)                                                      | `membership_leave_result`         | Leave the federation              |
| `membership_list`         | login | (none)                                                      | `membership_list_result`          | List federation members           |
| `membership_verify`       | login | `server_id: string`                                         | `membership_verify_result`        | Verify a member's membership      |

## Governance Operations

Governance uses a PBFT-style consensus protocol among federation members.

| Operation          | Auth  | Payload                                     | Response                    | Description                          |
|--------------------|-------|---------------------------------------------|-----------------------------|--------------------------------------|
| `governance_propose`| admin| `transactions: [GovernanceTx]`              | `governance_propose_result` | Propose a batch of governance txs    |
| `governance_prepare`| login| `vote: PbftVote`                            | `governance_prepare_result` | Submit a prepare vote                |
| `governance_commit` | login| `vote: PbftVote`                            | `governance_commit_result`  | Submit a commit vote                 |
| `governance_seal`  | admin | (none)                                      | `governance_seal_result`    | Seal the current consensus round     |
| `governance_log`   | login | (none)                                      | `governance_log_result`     | Get sealed batch history             |
| `governance_status`| login | (none)                                      | `governance_status_result`  | Get current governance state         |

## Admin Operations

| Operation                     | Auth  | Payload                                            | Response         | Description                            |
|-------------------------------|-------|----------------------------------------------------|------------------|----------------------------------------|
| `admin_accept_connections`    | admin | `accept: bool`                                     | `void`           | Toggle whether server accepts new connections |
| `admin_is_accepting_connections`| admin| (none)                                            | `boolean`        | Check if server is accepting connections |
| `admin_active_sessions`       | admin | (none)                                             | `session_infos`  | List all active sessions               |
| `admin_shutdown`              | admin | (none)                                             | `void`           | Request server shutdown                |
| `admin_grant`                 | admin | `club_id: BeId`, `region_start: i64`, `region_end: i64` | `void`    | Grant ID region to a club              |
| `admin_revoke_grant`          | admin | `club_id: BeId`                                    | `boolean`        | Revoke ID region grant                 |
| `admin_grants`                | admin | (none)                                             | `grants`         | List all current grants                |
| `admin_server_info`           | admin | (none)                                             | `server_info`    | Get server version and counts          |

### Admin Recorder Operations

| Operation               | Auth  | Payload                                              | Response                 | Description                       |
|-------------------------|-------|------------------------------------------------------|--------------------------|-----------------------------------|
| `admin_recorder_create` | admin | `kind: string`, `direct_only: bool?`, `region: XnRegion?` | `recorder_create_result` | Create a recorder ("works" or "transcluders") |
| `admin_recorder_record` | admin | `recorder_id: u64`, `element: RangeElement`          | `recorder_record_result` | Record an element in a recorder   |
| `admin_recorder_list`   | admin | (none)                                               | `recorder_list_result`   | List all recorders                |
| `admin_recorder_get`    | admin | `recorder_id: u64`                                   | `recorder_get_result`    | Get recorder details              |
| `admin_server_health`   | none  | (none)                                               | `server_health_result`   | Get server health metrics         |

### Server Health Response Fields

| Field             | Type   | Description              |
|-------------------|--------|--------------------------|
| `operation_count` | u64    | Total operations served  |
| `active_recorders`| usize  | Active recorder count    |
| `total_recorded`  | usize  | Total recorded elements  |
| `blob_count`      | usize  | Stored blob count        |
| `link_count`      | usize  | Stored link count        |
| `uptime_secs`     | u64    | Server uptime in seconds |

## Stats Operation

| Operation      | Auth  | Payload | Response      | Description                          |
|----------------|-------|---------|---------------|--------------------------------------|
| `server_stats` | login | (none)  | `server_info` | Get server version and object counts |

## Events and Subscriptions

Clients can subscribe to server-pushed events. Send a subscribe frame:

```json
{"v": 2, "type": "subscribe", "id": 1, "payload": {"detector_type": "revision", "target_id": 123}}
```

Detector types: `status`, `revision`, `fill`.

The server pushes event frames:

```json
{"v": 2, "type": "event", "id": 1, "event": {"type": "work_revised", "payload": {"work_be_id": 123, "revision": 2, "session_id": 1}}}
```

### Event Types

| Event           | Payload Fields                                           | Description                  |
|-----------------|----------------------------------------------------------|------------------------------|
| `work_grabbed`  | `work_be_id: BeId`, `session_id: u64`                    | Work was grabbed             |
| `work_released` | `work_be_id: BeId`, `session_id: u64`                    | Work was released            |
| `work_revised`  | `work_be_id: BeId`, `revision: u64`, `session_id: u64`   | Work edition was revised     |
| `range_filled`  | `edition_be_id: BeId`, `region: XnRegion`                | Range was filled in edition  |
| `element_filled`| `element_be_id: BeId`                                    | Element was filled           |
| `done`          | `operation_id: u64`                                      | Operation completed          |

Unsubscribe:

```json
{"v": 2, "type": "unsubscribe", "id": 1}
```

## Heartbeat

Either side may send heartbeat frames to keep the connection alive:

```json
{"v": 2, "type": "heartbeat", "id": 0}
```

## Operation Code Reference (Binary Protocol)

For the binary protocol, operations are identified by u16 codes:

| Code   | Operation                        |
|--------|----------------------------------|
| 0x0001 | session_connect                  |
| 0x0002 | session_disconnect               |
| 0x0003 | session_login                    |
| 0x0004 | session_login_by_name            |
| 0x0005 | session_authenticate             |
| 0x0006 | session_login_public             |
| 0x0101 | server_get_by_id                 |
| 0x0102 | server_get_by_be_id              |
| 0x0201 | club_create                      |
| 0x0202 | club_create_named                |
| 0x0203 | club_get                         |
| 0x0204 | club_by_name                     |
| 0x0205 | club_id_by_name                  |
| 0x0206 | club_name_by_id                  |
| 0x0207 | club_names                       |
| 0x0301 | work_create                      |
| 0x0302 | work_get_edition                 |
| 0x0303 | work_revise                      |
| 0x0304 | work_grab                        |
| 0x0305 | work_release                     |
| 0x0306 | work_is_grabbed                  |
| 0x0307 | work_grabber                     |
| 0x0308 | work_can_read                    |
| 0x0309 | work_can_revise                  |
| 0x030A | work_set_read_club               |
| 0x030B | work_set_edit_club               |
| 0x030C | work_read_club                   |
| 0x030D | work_edit_club                   |
| 0x030E | work_revision_count              |
| 0x030F | work_fetch_revision              |
| 0x0310 | work_sponsor                     |
| 0x0311 | work_unsponsor                   |
| 0x0312 | work_sponsors                    |
| 0x0313 | work_owner                       |
| 0x0314 | work_list                        |
| 0x0315 | work_list_by_owner               |
| 0x0316 | work_revise_delta                |
| 0x0401 | edition_store                    |
| 0x0402 | edition_get                      |
| 0x0501 | admin_accept_connections         |
| 0x0502 | admin_is_accepting_connections   |
| 0x0503 | admin_active_sessions            |
| 0x0504 | admin_shutdown                   |
| 0x0505 | admin_grant                      |
| 0x0506 | admin_revoke_grant               |
| 0x0507 | admin_grants                     |
| 0x0508 | admin_server_info                |
| 0x0601 | server_stats                     |
| 0x0701 | link_create                      |
| 0x0702 | link_get                         |
| 0x0703 | link_update                      |
| 0x0704 | link_delete                      |
| 0x0705 | link_list_for_work               |
| 0x0801 | find_transcluders                |
| 0x0802 | find_works_for_content           |
| 0x0803 | find_text_transcluders           |
| 0x0804 | find_shared_regions              |
| 0x0901 | blob_upload                      |
| 0x0902 | blob_get                         |
| 0x0903 | blob_get_preview                 |
| 0x0904 | blob_exists                      |
| 0x0905 | blob_info                        |
| 0x0906 | blob_stats                       |
| 0x0A01 | overlay_apply                    |
| 0x0A02 | overlay_get                      |
| 0x0B01 | label_create                     |
| 0x0B02 | label_get_positions              |
| 0x0B03 | edition_relabel                  |
| 0x0B04 | edition_rebind                   |
| 0x0B05 | can_make_identical               |
| 0x0B06 | make_range_identical             |
| 0x0B07 | identity_unify                   |
| 0x0B08 | identity_resolve                 |
| 0x0C01 | edition_retrieve                 |
| 0x0C02 | edition_cost                     |
| 0x0E01 | content_shared_region            |
| 0x0E02 | content_map_shared_to            |
| 0x0E03 | content_map_shared_onto          |
| 0x0E04 | positions_of                     |
| 0x0F01 | range_transcluders               |
| 0x0F02 | range_works                      |
| 0x0F03 | ordered_bundles                  |
| 0x0F04 | transclusion_depth               |
| 0x1101 | admin_recorder_create            |
| 0x1102 | admin_recorder_record            |
| 0x1103 | admin_recorder_list              |
| 0x1104 | admin_recorder_get               |
| 0x1105 | admin_server_health              |
| 0x1201 | crypto_get_public_key            |
| 0x1202 | crypto_sign_data                 |
| 0x1203 | crypto_verify_signature          |
| 0x1204 | crypto_key_rotation              |
| 0x1205 | crypto_key_history               |
| 0x1301 | work_endorse                     |
| 0x1302 | work_retract                     |
| 0x1303 | work_endorsements                |
| 0x1304 | edition_endorse                  |
| 0x1305 | edition_retract                  |
| 0x1306 | edition_endorsements             |
| 0x1307 | edition_visible_endorsements     |
| 0x1308 | edition_total_endorsements       |
| 0x1401 | federation_info                  |
| 0x1402 | federation_peers                 |
| 0x1701 | federated_transclusion_query     |
| 0x1702 | federated_content_fetch          |
| 0x1801 | endorsement_sync                 |
| 0x1802 | endorsement_add                  |
| 0x1803 | endorsement_retract              |
| 0x1804 | endorsement_query                |
| 0x1805 | state_sync                       |
| 0x1806 | state_alternatives               |
| 0x1901 | membership_join_request          |
| 0x1902 | membership_join_response         |
| 0x1903 | membership_endorse_offer         |
| 0x1904 | membership_endorse_accept        |
| 0x1905 | membership_sync                  |
| 0x1906 | membership_sync_result           |
| 0x1907 | membership_leave                 |
| 0x1908 | membership_list                  |
| 0x1909 | membership_verify                |
| 0x1B01 | governance_propose               |
| 0x1B02 | governance_prepare               |
| 0x1B03 | governance_commit                |
| 0x1B04 | governance_seal                  |
| 0x1B05 | governance_log                   |
| 0x1B06 | governance_status                |

Note: Codes 0x1902 (`membership_join_response`) and 0x1906 (`membership_sync_result`) are server-only and cannot be sent by clients.

## Binary Protocol

An alternative binary protocol uses postcard serialization with a compact frame layout:

```
[1B version][1B msg_type][2B request_id BE][payload...]
```

Message types: `0x00` handshake, `0x01` request, `0x02` response, `0x03` error, `0x04` event, `0x05` subscribe, `0x06` unsubscribe, `0x07` heartbeat.

Request payloads begin with a LEB128 varint-encoded operation code followed by a varint length prefix and postcard-serialized payload data. Response and error payloads similarly use varint-prefixed postcard encoding.

See `src/server/transport/codec.rs` for full encoding details.
