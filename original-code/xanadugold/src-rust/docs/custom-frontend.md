# Building Custom Frontends for xudanu

This guide explains how to build a custom frontend that connects to the xudanu
server over its WebSocket API. It covers the JSON protocol, a minimal working
example, static file serving, and the core API workflows.

## Quick Start: Connecting to the WebSocket API

### Connection

Open a WebSocket to `/xudanu?format=json&version=2` on the xudanu server. The
`format=json` query parameter selects the human-readable JSON codec. The
`version=2` parameter negotiates protocol v2.

```javascript
const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
const ws = new WebSocket(proto + '//' + location.host + '/xudanu?format=json&version=2');
```

### Handshake

After connecting, the server sends a `handshake` message. Respond with a
`session_connect` request:

```javascript
ws.onmessage = (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.type === 'handshake') {
    send('session_connect');
  }
};
```

### Authentication

After `session_connect` succeeds (returns `{type: "id", value: <session_id>}`),
log in as a public user:

```javascript
send('session_login_public');
// Response: {v:2, type:"response", id:<n>, value:{type:"id", value:<club_id>}}
```

For authenticated access, use `session_login` with a club ID or
`session_authenticate` with credentials.

### Creating a Work

```javascript
send('work_create', {edition: {text: ''}});
// Response: {v:2, type:"response", id:<n>, value:{type:"id", value:<work_id>}}
```

### Editing Text

```javascript
send('work_grab', {work_id: workId});
// ... wait for success response ...

send('work_revise', {work_id: workId, edition: {text: 'Hello world'}});
// Response: {v:2, type:"response", id:<n>, value:{type:"humber", value:<revision>}}

send('work_release', {work_id: workId});
```

### Request Helper

```javascript
let nextId = 1;

function send(op, payload) {
  const id = nextId++;
  const frame = {v: 2, type: 'request', id: id, op: op};
  if (payload) frame.payload = payload;
  ws.send(JSON.stringify(frame));
  return id;
}
```

### V2 Protocol Format

All frames are JSON objects with these common fields:

| Field    | Description                                    |
|----------|------------------------------------------------|
| `v`      | Protocol version (always `2`)                  |
| `type`   | Frame type: `request`, `response`, `error`, `event`, `subscribe`, `unsubscribe`, `heartbeat`, `handshake` |
| `id`     | Request/response correlation ID (`u16`)        |
| `op`     | Operation name (requests only)                 |
| `payload`| Request parameters                             |
| `value`  | Response value (tagged union with `type` field)|
| `code`   | Error code (errors only)                       |
| `message`| Human-readable error message (errors only)     |
| `event`  | Event payload (events only)                    |

Response values are tagged unions. Examples:

```json
{"type": "id",      "value": 42}
{"type": "humber",  "value": 3}
{"type": "boolean", "value": true}
{"type": "void"}
{"type": "edition", "value": {"type": "text", "value": "hello"}}
{"type": "work_list", "value": [{"work_id": 1, "owner": null, "revision_count": 0, "is_grabbed": false, "title": ""}]}
```

## Minimal HTML Example

Save this file as `index.html` in your static directory. It connects to xudanu,
logs in, creates a document, writes text, and displays it.

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>xudanu minimal client</title>
<style>
  body { font-family: monospace; max-width: 700px; margin: 40px auto; padding: 0 16px; }
  #status { color: #888; font-size: 12px; margin-bottom: 16px; }
  #doc { white-space: pre-wrap; border: 1px solid #ccc; padding: 12px; min-height: 100px; }
  textarea { width: 100%; height: 120px; font-family: monospace; margin-top: 8px; }
  button { margin-top: 8px; padding: 6px 16px; cursor: pointer; }
  #log { font-size: 11px; color: #666; margin-top: 16px; max-height: 200px; overflow-y: auto; }
</style>
</head>
<body>
<h3>xudanu minimal client</h3>
<div id="status">connecting...</div>
<div id="doc"></div>
<textarea id="editor" style="display:none" placeholder="Type here..."></textarea>
<button id="saveBtn" style="display:none" onclick="doSave()">Save</button>
<div id="log"></div>

<script>
var ws, nextId = 1, sessionId = null, workId = null, isEditing = false, lastSaved = '';

function log(msg) {
  var el = document.getElementById('log');
  el.textContent += msg + '\n';
  el.scrollTop = el.scrollHeight;
}

function send(op, payload) {
  var id = nextId++;
  var frame = {v: 2, type: 'request', id: id, op: op};
  if (payload) frame.payload = payload;
  ws.send(JSON.stringify(frame));
  return id;
}

function setStatus(s) {
  document.getElementById('status').textContent = s;
}

function doSave() {
  if (!workId || !isEditing) return;
  var text = document.getElementById('editor').value;
  send('work_revise', {work_id: workId, edition: {text: text}});
  lastSaved = text;
}

var proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
ws = new WebSocket(proto + '//' + location.host + '/xudanu?format=json&version=2');

ws.onopen = function() { setStatus('connected'); };

ws.onmessage = function(ev) {
  var msg = JSON.parse(ev.data);

  if (msg.type === 'handshake') {
    send('session_connect');
    return;
  }

  if (msg.type === 'error') {
    log('ERROR: ' + (msg.message || msg.code));
    return;
  }

  if (msg.type !== 'response') return;
  var v = msg.value;
  if (!v) return;

  if (v.type === 'id' || v.type === 'humber') {
    switch (msg.op) {
      case 'session_connect':
        sessionId = v.value;
        log('session: ' + sessionId);
        send('session_login_public');
        break;
      case 'session_login_public':
        log('logged in (public)');
        send('work_create', {edition: {text: 'Hello from custom frontend!'}});
        break;
      case 'work_create':
        workId = v.value;
        log('created work: ' + workId);
        send('work_grab', {work_id: workId});
        break;
      case 'work_grab':
        isEditing = true;
        send('work_get_edition', {work_id: workId});
        document.getElementById('editor').style.display = 'block';
        document.getElementById('saveBtn').style.display = 'inline';
        log('editing work ' + workId);
        break;
      case 'work_revise':
        log('saved revision ' + v.value);
        send('work_release', {work_id: workId});
        break;
      case 'work_release':
        isEditing = false;
        document.getElementById('editor').style.display = 'none';
        document.getElementById('saveBtn').style.display = 'none';
        send('work_get_edition', {work_id: workId});
        break;
    }
  }

  if (v.type === 'edition') {
    var text = v.value && v.value.type === 'text' ? v.value.value : '';
    document.getElementById('doc').textContent = text;
    if (isEditing) {
      var editor = document.getElementById('editor');
      if (!lastSaved) { editor.value = text; lastSaved = text; }
    } else {
      log('document content: ' + text);
    }
  }
};

ws.onclose = function() { setStatus('disconnected'); };
ws.onerror = function() { setStatus('error'); };
</script>
</body>
</html>
```

## Using --static-dir

### Starting with a Custom Frontend

Pass `--static-dir <path>` to the `run` command:

```bash
xudanu-server run 127.0.0.1:8080 ./data --static-dir ./my-frontend
```

Without `--static-dir`, the server uses the embedded HTML from
`static/index.html` compiled into the binary.

### File Structure

```
my-frontend/
  index.html       Required. Served at /
  app.js           Optional. Served at /app.js
  style.css        Optional. Served at /style.css
  ...              Any other static files
```

- `index.html` is served for `GET /`. If the file is missing in the static
  directory, the server falls back to the embedded default.
- All other files are served at `/<path>` with automatic MIME type detection.
- The WebSocket endpoint `/xudanu` and blob endpoint `/blobs/<hash>` are always
  available regardless of `--static-dir`.

### Path Traversal Protection

The server canonicalizes requested paths and verifies they resolve inside the
static directory. Requests like `/../../../etc/passwd` are rejected with a 403
Forbidden response. This check is applied before any file is read from disk.

## Key API Workflow

### Session Lifecycle

```
connect -> handshake -> session_connect -> session_login_public -> operations -> disconnect
```

1. **Connect**: WebSocket upgrade to `/xudanu?format=json&version=2`
2. **Handshake**: Server sends `{"type":"handshake",...}` automatically
3. **session_connect**: Client sends this to establish a session. Returns the
   session ID.
4. **session_login_public**: Authenticates as the anonymous public user. Required
   before most operations.
5. **Operations**: Any authenticated request (work_list, work_create, etc.)
6. **session_disconnect**: Optional explicit disconnect. The server also cleans
   up when the WebSocket closes.

For privileged access, replace `session_login_public` with `session_login`
(accepts a `club_id`) or `session_authenticate` (accepts `club_id` and
`credential` with a password, challenge-response, or boo token).

### Document Lifecycle

```
create -> grab -> revise -> release
```

1. **work_create**: Creates a new document with an initial edition.
   ```json
   {"op":"work_create", "payload":{"edition":{"text":"initial content"}}}
   ```
   Returns the new work ID.

2. **work_grab**: Acquires an exclusive write lock on the document. Only one
   session can hold the grab at a time.
   ```json
   {"op":"work_grab", "payload":{"work_id":42}}
   ```

3. **work_revise**: Commits a new edition (replaces all content). Returns the
   new revision number.
   ```json
   {"op":"work_revise", "payload":{"work_id":42, "edition":{"text":"updated content"}}}
   ```

   For incremental edits, use **work_revise_delta** which accepts a base
   revision and an ops array:
   ```json
   {"op":"work_revise_delta", "payload":{
     "work_id": 42,
     "base_revision": 3,
     "ops": [
       {"type":"retain", "count":5},
       {"type":"delete", "count":2},
       {"type":"insert", "text":"world"}
     ]
   }}
   ```
   If the base revision is stale (someone else edited), the response returns
   the current edition instead of a revision number. Re-fetch and retry.

4. **work_release**: Releases the write lock.
   ```json
   {"op":"work_release", "payload":{"work_id":42}}
   ```

### Reading Documents

**work_get_edition** returns the current content of a document:

```json
{"op":"work_get_edition", "payload":{"work_id":42}}
```

Response:
```json
{"value":{"type":"edition", "value":{"type":"text", "value":"Hello world"}}}
```

For non-trivial editions, the value may be `{"type":"entries", ...}` with
positioned elements, or `{"type":"empty"}`.

**work_revision_count** returns the total number of revisions:
```json
{"op":"work_revision_count", "payload":{"work_id":42}}
```

**work_fetch_revision** retrieves a specific historical revision:
```json
{"op":"work_fetch_revision", "payload":{"work_id":42, "number":2}}
```

**edition_retrieve** returns structured bundle data for a region of a work.
This is the primary API for understanding transclusion structure:

```json
{"op":"edition_retrieve", "payload":{
  "work_id": 42,
  "region": {"start":0, "end":100},
  "flags": {"ignore_total_ordering": false, "ignore_array_ordering": false, "separate_owners": false}
}}
```

Response contains bundles describing elements, arrays, and placeholders in the
requested region.

### Listing Documents

**work_list** returns all visible documents:
```json
{"op":"work_list"}
```

Response:
```json
{
  "value": {
    "type": "work_list",
    "value": [
      {"work_id": 1, "owner": null, "revision_count": 3, "is_grabbed": false, "title": "My doc"}
    ]
  }
}
```

### Handling Events (Real-time Updates)

Subscribe to receive push notifications when documents change:

```javascript
// Subscribe to revision events for work 42
ws.send(JSON.stringify({
  v: 2,
  type: 'subscribe',
  id: nextId++,
  payload: {detector_type: 'revision', target_id: 42}
}));

// Subscribe to status events (grab/release) for work 42
ws.send(JSON.stringify({
  v: 2,
  type: 'subscribe',
  id: nextId++,
  payload: {detector_type: 'status', target_id: 42}
}));
```

Event frames arrive as:
```json
{
  "v": 2,
  "type": "event",
  "id": <subscription_id>,
  "event": {
    "type": "work_revised",
    "payload": {"work_be_id": 42, "revision": 5, "session_id": 1}
  }
}
```

Event types:

| Event             | Payload fields                              | When                      |
|-------------------|---------------------------------------------|---------------------------|
| `work_grabbed`    | `work_be_id`, `session_id`                 | Document lock acquired    |
| `work_released`   | `work_be_id`, `session_id`                 | Document lock released    |
| `work_revised`    | `work_be_id`, `revision`, `session_id`     | Document saved            |
| `range_filled`    | `edition_be_id`, `region`                  | Edition range populated   |
| `element_filled`  | `element_be_id`                            | Element content populated |
| `done`            | `operation_id`                             | Operation complete        |

To unsubscribe:
```javascript
ws.send(JSON.stringify({v: 2, type: 'unsubscribe', id: <subscription_id>}));
```

### Common Operations Reference

| Operation              | Payload                                        | Response type  |
|------------------------|------------------------------------------------|----------------|
| `session_connect`      | (none)                                         | `id`           |
| `session_login_public` | (none)                                         | `id`           |
| `work_list`            | (none)                                         | `work_list`    |
| `work_create`          | `{edition: {text: "..."}}`                     | `id`           |
| `work_get_edition`     | `{work_id: N}`                                 | `edition`      |
| `work_grab`            | `{work_id: N}`                                 | `void`         |
| `work_revise`          | `{work_id: N, edition: {text: "..."}}`         | `humber`       |
| `work_revise_delta`    | `{work_id, base_revision, ops}`                | `humber`/`edition` |
| `work_release`         | `{work_id: N}`                                 | `void`         |
| `work_revision_count`  | `{work_id: N}`                                 | `humber`       |
| `work_fetch_revision`  | `{work_id: N, number: R}`                      | `edition`      |
| `work_is_grabbed`      | `{work_id: N}`                                 | `boolean`      |
| `server_stats`         | (none)                                         | `server_info`  |
| `link_create`          | `{origin, destination, origin_ref, dest_ref}`  | `id`           |
| `link_list_for_work`   | `{work_id: N}`                                 | `link_list`    |
| `link_delete`          | `{link_id: N}`                                 | `void`         |
| `find_text_transcluders` | `{text: "..."}`                              | `text_transclusion_results` |

## Binary Protocol Alternative

For performance-critical applications, the server also supports a compact binary
protocol. Connect without `?format=json` (or with `?format=binary`) to use it.

Binary frames use a 4-byte header:

```
[1B version][1B message type][2B request ID (big-endian)][payload...]
```

Request payloads use LEB128 varint-encoded operation codes followed by
postcard-serialized data. The binary codec shares the same operation set and
data types as JSON but with smaller wire sizes and faster parsing.

For most custom frontends, the JSON protocol is recommended. Switch to binary
if you need lower latency or are building a high-throughput integration.
