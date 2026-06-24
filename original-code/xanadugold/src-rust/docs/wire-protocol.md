# Xudanu Wire Protocol

The xudanu server communicates over WebSocket. This document covers
connection, authentication, message format, and usage examples.

## Connection

```
ws://host:port/xudanu?format=json
wss://host:port/xudanu?format=json   (TLS)
```

### Query parameters

| Param      | Default   | Description |
|------------|-----------|-------------|
| `format`   | `binary`  | `json` for text-based, `binary` for compact framing |
| `version`  | `2`       | Protocol version |
| `token`    | (none)    | Session/OAuth token for bearer auth |
| `login`    | (none)    | Set to `public` for auto-login as public user |
| `csrf_token` | (none)  | Required only when server runs with `--csrf-token` |

### Authentication

Three methods, from most to least convenient:

**1. Auto-login (read-only):**
```
ws://host:port/xudanu?format=json&login=public
```
Session is auto-authenticated as the public user. Can read published
works and create new works. No password needed.

**2. Bearer token (OAuth sessions):**
```
ws://host:port/xudanu?format=json&token=<session_token>
```
Or via header (if your client supports it):
```
Authorization: Bearer <session_token>
```
The token is the `xudanu_session` cookie value from a prior OAuth login
(GitHub, Google). Validates against the server's session store.

**3. In-protocol login (existing clients):**
Connect without a token, then send `session_login_public` or
`session_login` as the first request. This is the default frontend flow.

### Handshake

Upon connection, the server immediately sends a handshake message:

```json
{
  "type": "handshake",
  "v": 2,
  "payload": {
    "server_version": 2,
    "negotiated_version": 2,
    "server_id": "77a1dbcf973067a4",
    "server_capabilities": []
  }
}
```

Clients can ignore this and start sending requests immediately. The
handshake is informational only.

## Message Format (JSON)

All messages are JSON objects with a `v` field (protocol version, currently `2`).

### Request (client to server)

```json
{
  "v": 2,
  "type": "request",
  "id": 1,
  "op": "work_list",
  "payload": { "offset": 0, "limit": 50 }
}
```

| Field     | Type   | Description |
|-----------|--------|-------------|
| `v`       | number | Protocol version (`2`) |
| `type`    | string | `"request"`, `"heartbeat"`, `"subscribe"`, `"unsubscribe"` |
| `id`      | number | Client-chosen request ID, echoed in response |
| `op`      | string | Operation name (snake_case, e.g. `"work_list"`) |
| `payload` | object | Operation-specific parameters |

### Response (server to client)

```json
{
  "v": 2,
  "type": "response",
  "id": 1,
  "value": { "type": "work_list", "value": { "entries": [...], "total_count": 4 } }
}
```

The `value` field contains a tagged union with `type` and `value` fields.
Common response types: `id`, `void`, `boolean`, `string`, `edition`,
`work_list`, `global_search_results`, etc.

### Error

```json
{
  "v": 2,
  "type": "error",
  "id": 1,
  "code": "work_not_found",
  "message": "work not found: 1234"
}
```

### Event (server push)

```json
{
  "v": 2,
  "type": "event",
  "subscription_id": 1,
  "event": { "type": "work_revised", "work_be_id": 1000 }
}
```

## Common Operations

### Session

| Op                    | Payload | Response |
|-----------------------|---------|----------|
| `session_connect`     | (none)  | `id` (session ID) |
| `session_login_public`| (none)  | `id` (club ID) |
| `session_login`       | `{club_id, password}` | `id` |

### Works

| Op                    | Payload | Response |
|-----------------------|---------|----------|
| `work_create`         | `{edition: EditionPayload}` | `id` (work ID) |
| `work_list`           | `{offset?, limit?}` | paginated work list |
| `work_get_edition`    | `{work_id}` | `edition` |
| `work_revise`         | `{work_id, edition}` | `humber` (revision) |
| `work_revise_delta`   | `{work_id, base_revision, ops}` | `humber` or `edition` (conflict) |
| `work_grab`           | `{work_id}` | `void` |
| `work_release`        | `{work_id}` | `void` |
| `global_text_search`  | `{query, max_results?}` | `global_search_results` |

### Links

| Op                    | Payload | Response |
|-----------------------|---------|----------|
| `link_create`         | `{origin, destination, ...}` | `id` (link ID) |
| `link_get`            | `{link_id}` | `link_info` |
| `link_add_end`        | `{link_id, end_name, end_ref}` | `void` |
| `link_set_types`      | `{link_id, link_types}` | `void` |
| `link_type_register`  | `{type_id, name}` | `void` |
| `link_type_list`      | (none) | `link_types` |

### EditionPayload

```json
{"text": "hello world"}        // plain text
{"entries": [[0, {"text": "a"}], [1, {"text": "b"}]]}  // positioned elements
"empty"                        // empty edition
```

## Example Clients

### Python (websocket-client)

```python
import websocket, json

ws = websocket.create_connection(
    "ws://localhost:8080/xudanu?format=json&login=public"
)

# Consume handshake
ws.recv()

# Send a request
def send_recv(op, payload=None, rid=[0]):
    rid[0] += 1
    msg = {"v": 2, "type": "request", "id": rid[0], "op": op}
    if payload:
        msg["payload"] = payload
    ws.send(json.dumps(msg))
    while True:
        resp = json.loads(ws.recv())
        if resp.get("id") == rid[0]:
            return resp

# List works
print(send_recv("work_list", {"limit": 10}))

# Create a work
print(send_recv("work_create", {"edition": {"text": "hello world"}}))

# Global search
print(send_recv("global_text_search", {"query": "hello"}))

ws.close()
```

### JavaScript (browser)

```javascript
const ws = new WebSocket("ws://localhost:8080/xudanu?format=json&login=public");

ws.onmessage = (e) => {
  const msg = JSON.parse(e.data);
  if (msg.type === "handshake") return; // ignore
  console.log("Response:", msg);
};

ws.onopen = () => {
  ws.send(JSON.stringify({
    v: 2, type: "request", id: 1, op: "work_list",
    payload: { limit: 10 }
  }));
};
```

### Node.js (ws)

```javascript
const WebSocket = require("ws");
const ws = new WebSocket("ws://localhost:8080/xudanu?format=json&login=public");

ws.on("message", (data) => {
  const msg = JSON.parse(data);
  if (msg.type === "handshake") return;
  console.log(msg);
});

ws.on("open", () => {
  ws.send(JSON.stringify({
    v: 2, type: "request", id: 1,
    op: "global_text_search",
    payload: { query: "hello" }
  }));
});
```

## Binary Format

For bandwidth-sensitive applications, omit `format=json` (defaults to
`binary`). Frames use a compact header:

```
[version:1] [msg_type:1] [flags:1] [payload_len:varint] [payload:bytes]
```

Message types: `0=handshake`, `1=request`, `2=response`, `3=error`,
`4=event`, `5=subscribe`, `6=unsubscribe`, `7=heartbeat`.

Operation codes are 2-byte little-endian integers in the request payload.
See `OperationCode::to_u16()` in `protocol.rs` for the mapping.
