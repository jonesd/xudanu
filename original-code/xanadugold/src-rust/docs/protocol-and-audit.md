# Xudanu Server: Protocol and Audit Documentation

## WebSocket Protocol

The server listens for WebSocket connections at:

| Endpoint | Format |
|---|---|
| `ws://host/xudanu` | Binary (default) |
| `ws://host/xudanu?format=json` | JSON |

### Wire Format

All frames share the same logical structure. The codec is negotiated at connection time — no per-message overhead.

#### Binary Frame Layout

```
[1B version][1B msg_type][2B request_id BE][payload...]

Message types:
  0x01 REQUEST      client → server
  0x02 RESPONSE     server → client
  0x03 ERROR        server → client
  0x04 EVENT        server → client (detector push)
  0x05 SUBSCRIBE    client → server
  0x06 UNSUBSCRIBE  client → server
  0x07 HEARTBEAT    bidirectional
```

REQUEST payload uses LEB128 varint for operation code and length, then postcard-encoded args.

#### JSON Frame Layout

```json
{"v":1,"type":"request", "id":42,"op":"work_create",
 "payload":{"edition":{"text":"hello"}}}

{"v":1,"type":"response","id":42,
 "value":{"type":"id","value":7}}

{"v":1,"type":"error",   "id":42,
 "code":"not_grabbed","message":"work 7 not grabbed"}

{"v":1,"type":"event",   "id":3,
 "event":{"type":"work_revised",
          "payload":{"work_be_id":7,"revision":2,"session_id":1}}}

{"v":1,"type":"heartbeat","id":0}
```

### Operation Codes

| Code | JSON name | Payload | Response |
|---|---|---|---|
| **Session** | | | |
| 0x0001 | `session_connect` | — | Id (session) |
| 0x0002 | `session_disconnect` | — | Void |
| 0x0003 | `session_login` | `{club_id}` | Void |
| 0x0004 | `session_login_by_name` | `{club_name}` | Void |
| 0x0005 | `session_authenticate` | `{club_id, credential}` | Ids (authority) |
| 0x0006 | `session_login_public` | — | Id (public club) |
| **Server** | | | |
| 0x0101 | `server_get_by_id` | `{id}` | RangeElement |
| 0x0102 | `server_get_by_be_id` | `{be_id}` | RangeElement |
| **Club** | | | |
| 0x0201 | `club_create` | `{description}` | Id |
| 0x0202 | `club_create_named` | `{name, description}` | Id |
| 0x0203 | `club_get` | `{club_id}` | Id |
| 0x0204 | `club_by_name` | `{name}` | Id |
| 0x0205 | `club_id_by_name` | `{name}` | Id |
| 0x0206 | `club_name_by_id` | `{club_id}` | String |
| 0x0207 | `club_names` | — | ClubNames |
| **Work** | | | |
| 0x0301 | `work_create` | `{edition}` | Id |
| 0x0302 | `work_get_edition` | `{work_id}` | Edition |
| 0x0303 | `work_revise` | `{work_id, edition}` | Humber (revision #) |
| 0x0304 | `work_grab` | `{work_id}` | Void |
| 0x0305 | `work_release` | `{work_id}` | Void |
| 0x0306 | `work_is_grabbed` | `{work_id}` | Boolean |
| 0x0307 | `work_grabber` | `{work_id}` | Humber (session or 0) |
| 0x0308 | `work_can_read` | `{work_id}` | Boolean |
| 0x0309 | `work_can_revise` | `{work_id}` | Boolean |
| 0x030A | `work_set_read_club` | `{work_id, club_id}` | Void |
| 0x030B | `work_set_edit_club` | `{work_id, club_id}` | Void |
| 0x030C | `work_read_club` | `{work_id}` | Humber |
| 0x030D | `work_edit_club` | `{work_id}` | Humber |
| 0x030E | `work_revision_count` | `{work_id}` | Humber |
| 0x030F | `work_fetch_revision` | `{work_id, number}` | Edition or Void |
| 0x0310 | `work_sponsor` | `{work_id, club_id}` | Void |
| 0x0311 | `work_unsponsor` | `{work_id, club_id}` | Void |
| 0x0312 | `work_sponsors` | `{work_id}` | Ids |
| 0x0313 | `work_owner` | `{work_id}` | Humber |
| **Edition** | | | |
| 0x0401 | `edition_store` | `{edition}` | Id |
| 0x0402 | `edition_get` | `{be_id}` | Edition or Void |

### Edition Payload

Editions cross the wire in one of three forms:

```json
"text"          →  Edition::from_text("text")
{"entries":[...]} →  Edition with position/element pairs
"empty"         →  Edition::empty()
```

The `"entries"` form is an array of `[position, element]` pairs where element follows the `RangeElement` serde format:

```json
{"Text":{"text":"hello"}}
{"Data":{"bytes":[72,105]}}
{"PlaceHolder":{"id":1}}
{"Work":{"work_id":{"id":42}}}
```

### Error Codes

| Code | Meaning |
|---|---|
| `not_authorized` | Session lacks permission |
| `not_found` | Generic not found |
| `already_exists` | Duplicate name/ID |
| `not_grabbed` | Must grab before revise/release |
| `already_grabbed` | Another session holds the grab |
| `session_required` | No active session |
| `invalid_argument` | Bad request payload |
| `type_mismatch` | Wrong element type |
| `lock_failed` | Lock credential rejected |
| `session_not_found` | Invalid session ID |
| `work_not_found` | Unknown work BeId |
| `club_not_found` | Unknown club BeId |
| `edition_not_found` | Unknown edition BeId |
| `internal` | Unexpected server error |
| `protocol_error` | Malformed frame or unknown op |

### Event Subscriptions

Clients subscribe to detector events:

```json
{"v":1,"type":"subscribe","id":5,
 "payload":{"detector_type":"revision","target_id":7}}
```

Detector types: `"status"`, `"revision"`, `"fill"`.

The server pushes events matching the subscription:

```json
{"v":1,"type":"event","id":5,
 "event":{"type":"work_revised",
          "payload":{"work_be_id":7,"revision":3,"session_id":2}}}
```

Event types: `work_grabbed`, `work_released`, `work_revised`, `range_filled`, `element_filled`, `done`.

---

## Audit and Security System

### Architecture

Every WebSocket connection is monitored by a `SecurityMonitor` that records all security-relevant events through a pluggable `AuditLog` trait. The default implementation (`TracingAuditLog`) emits structured log lines. A `CollectorAuditLog` is available for testing.

```
WS Connection
     │
     ▼
SecurityMonitor ──record()──► AuditLog
     │                            │
     ├─ tracks auth failures      ├─ TracingAuditLog (production)
     ├─ tracks protocol violations├─ CollectorAuditLog (testing)
     ├─ tracks request rates      └─ custom implementations
     └─ auto-disconnects on threat
```

### Audit Events

Each event is a structured record:

| Field | Description |
|---|---|
| `timestamp` | Unix epoch seconds |
| `session_id` | Session that triggered the event |
| `remote_addr` | Client IP:port (from axum ConnectInfo) |
| `kind` | Event category (see below) |
| `detail` | Human-readable description with threat level |

### Event Kinds

| Kind | Severity | Trigger |
|---|---|---|
| `session_opened` | INFO | New WS connection established |
| `session_closed` | INFO | WS connection closed (clean or error) |
| `auth_success` | INFO | Successful login (club authenticated) |
| `auth_failure` | WARN | Failed login attempt (wrong credential, unknown club) |
| `permission_denied` | WARN | Operation attempted without authorization |
| `grab_conflict` | WARN | Attempt to grab/revise/release work held by another session |
| `protocol_violation` | WARN | Malformed frame, wrong version, unknown operation |
| `rate_limit` | WARN | Rate limit threshold exceeded |
| `suspicious_pattern` | WARN | Anomalous behavior detected |
| `resource_exhaustion` | ERROR | Server resource limits hit |
| `state_corruption` | ERROR | Unexpected internal state |

### Threat Detection

The `SecurityMonitor` tracks per-session counters and escalates through four threat levels:

| Level | Meaning | Action |
|---|---|---|
| `Normal` | Within expected parameters | None |
| `Elevated` | Unusual activity (≥3 failures or ≥75% rate) | Logged |
| `High` | Suspicious activity (≥50% of limit) | Logged |
| `Critical` | Rate limit exceeded | Session auto-disconnected |

### Configurable Thresholds

`SecurityConfig` controls when threats escalate:

| Parameter | Default | Meaning |
|---|---|---|
| `max_auth_failures_per_minute` | 10 | Auth failures before disconnect |
| `max_protocol_violations_per_minute` | 20 | Protocol errors before disconnect |
| `max_requests_per_second` | 100 | Requests per second before disconnect |
| `max_sessions_per_ip` | 50 | Sessions from one IP (future) |

### Adversarial Scenarios Detected

The integration tests (`tests/integration.rs`) cover these attack patterns:

| Scenario | Test name | Detection |
|---|---|---|
| Unauthenticated operation | `adversarial_connect_without_login_then_operate` | `permission_denied` |
| Brute-force auth | `security_monitor_rate_limit_triggers` | `rate_limit` after N failures |
| Protocol fuzzing | `adversarial_malformed_json` | `protocol_violation` |
| Unknown operations | `adversarial_unknown_operation` | `protocol_violation` |
| Wrong protocol version | `adversarial_wrong_version` | `protocol_violation` |
| Truncated binary frames | `adversarial_binary_truncated_frame` | `protocol_violation` |
| Unknown binary ops | `adversarial_binary_unknown_op` | `protocol_violation` |
| Resource probing (huge IDs) | `adversarial_huge_work_id` | `work_not_found` |
| Grab hijacking | `err_wrong_session_releases_grab` | `grab_conflict` |
| Unauthorized revision | `err_wrong_session_revises` | `already_grabbed` |
| Permission escalation | `adversarial_restricted_work_cannot_be_grabbed_by_other` | `permission_denied` |
| Rapid-fire flooding | `adversarial_rapid_fire_requests` | `rate_limit` (if threshold hit) |
| Empty/malformed payloads | `adversarial_empty_payload` | `protocol_violation` or `invalid_argument` |

### Audit Log Example Output

Production (via `TracingAuditLog`):

```
INFO  kind=AuthSuccess    session=1 remote=192.168.1.50:54321 "login via public club"
WARN  kind=AuthFailure    session=2 remote=10.0.0.5:12345   "club 42 not found (failure #1, threat: Normal)"
WARN  kind=AuthFailure    session=2 remote=10.0.0.5:12345   "club 42 not found (failure #5, threat: Elevated)"
WARN  kind=RateLimit      session=2 remote=10.0.0.5:12345   "auth failure rate limit hit: 10 failures in under 60s"
WARN  kind=ProtocolViolation session=3 remote=10.0.0.5:12346 "unknown operation 'bogus' (violation #1, threat: Normal)"
ERROR kind=ResourceExhaustion session=None remote=None        "work limit reached: 100000"
```

### Custom Audit Backends

Implement the `AuditLog` trait to integrate with external systems:

```rust
use xudanu::server::transport::{AuditLog, AuditEvent};

#[derive(Debug)]
struct MyAuditLog { /* ... */ }

impl AuditLog for MyAuditLog {
    fn record(&self, event: AuditEvent) {
        // Send to SIEM, database, alerting system, etc.
        my_system.send(event).await;
    }
}

// Wire into server:
let monitor = SecurityMonitor::new(Arc::new(MyAuditLog::new()));
let state = AppState::with_security(server, monitor);
```

### What Gets Recorded

Every request passes through `on_request()` which checks the rate counter. The following events are specifically audited:

- **Session lifecycle**: opened/closed with IP address
- **Authentication**: every success and failure, with failure count and threat escalation
- **Authorization**: every permission denial
- **Protocol**: every malformed frame, wrong version, unknown operation
- **Grab conflicts**: attempts to grab/modify work held by another session
- **Rate limits**: when any threshold is crossed
- **Resource exhaustion**: when server limits are hit

Sessions that hit `Critical` threat level are automatically disconnected by the handler. All state (failure counters, rate windows) is cleaned up on session close.
