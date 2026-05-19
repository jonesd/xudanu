# Content Detection System

The xudanu content detection system lets you watch for transclusions — places where the same content appears across multiple documents — and get notified when new matches appear.

## How It Works

### Core Concepts

- **Content fingerprinting**: Every piece of content (text, data, blobs, etc.) is hashed with blake3. Documents that share the same text produce the same fingerprint.
- **RecorderFossil**: A persistent query that watches for specific content. When you subscribe, a fossil is created that stores the content elements from your document.
- **Past matching**: When you first subscribe, the system immediately finds all existing documents that share content with yours.
- **Future matching**: The system maintains a reverse index (`fingerprint → fossil_id`). When any document is revised, the system checks if the new content fingerprints match any active fossils and triggers them.

### Data Flow

```
Subscribe to Document A
    ↓
Extract content elements from A's edition
    ↓
Create RecorderFossil with watched_content = A's elements
    ↓
Plant fossil in Sensor Canopy + fossil_by_fingerprint index
    ↓
Run initial search: for each content element, find all transcluders
    ↓
Send ContentMatch events for past matches immediately
    ↓
(Later) Someone revises Document B
    ↓
trigger_planted_recorders(B) fires in revise_work()
    ↓
Extract B's new content fingerprints
    ↓
Look up fingerprints in fossil_by_fingerprint index
    ↓
For each triggered fossil, search for its watched content
    ↓
Push ContentMatch events for new matches via WebSocket
```

## Using Content Detection

### WebSocket API

#### Subscribe to Content Transcluders

Watch for documents that contain the same content as a given document:

```json
{
  "v": 2,
  "type": "subscribe",
  "id": 42,
  "payload": {
    "detector_type": "content_transcluders",
    "target_id": "0xABCDEF1234567890"
  }
}
```

Response:
```json
{
  "v": 2,
  "type": "response",
  "id": 42,
  "value": 7
}
```
The `value` (7) is your subscription ID.

#### Subscribe to Content Works

Watch for works (versioned documents) that contain matching content:

```json
{
  "v": 2,
  "type": "subscribe",
  "id": 43,
  "payload": {
    "detector_type": "content_works",
    "target_id": "0xABCDEF1234567890"
  }
}
```

#### Unsubscribe

```json
{
  "v": 2,
  "type": "unsubscribe",
  "id": 7
}
```
Use the subscription ID (from the subscribe response) as the `id`.

#### Receiving Match Events

When a match is found (either immediately on subscribe or later when content changes), you receive:

```json
{
  "v": 2,
  "type": "event",
  "id": 7,
  "event": {
    "type": "content_match",
    "payload": {
      "fossil_id": 15,
      "edition_be_id": "0x1234567890ABCDEF",
      "is_direct": true
    }
  }
}
```

Fields:
- `fossil_id`: The recorder fossil that found the match
- `edition_be_id`: The ID of the document that contains matching content
- `is_direct`: `true` if the content is directly in that document, `false` if found through version history traversal

### Frontend UI

Click the **Watch** button in the toolbar when viewing a document. The Watch panel opens showing:

1. **"Watching for transclusions..."** — while waiting for matches
2. **Match list** — each match shows:
   - **D** (direct) or **I** (indirect) indicator
   - The edition ID that shares your content
   - Click an edition to navigate to it

Click **Stop Watch** to unsubscribe. Switching documents automatically unsubscribes.

## Triggering Other Activities

### Programmatic Integration

The content detection system can trigger arbitrary actions when matches are found. Here are patterns for integration:

#### Pattern 1: Webhook on Match

Use the admin API to create a recorder, then poll for results:

```json
// Create recorder
{ "op": "admin_recorder_create", "payload": { "kind": "transcluders" } }
// Response: { "recorder_id": 15 }

// Later, check results
{ "op": "admin_recorder_get", "payload": { "recorder_id": 15 } }
// Response: { "recorder": { "id": 15, "kind": "transcluders", "result_count": 3, "is_extinct": false } }
```

#### Pattern 2: Custom Detector

Implement the `Detector` trait for custom behavior:

```rust
use xudanu::server::detector::{Detector, Event};

struct WebhookDetector {
    url: String,
}

impl Detector for WebhookDetector {
    fn on_event(&mut self, event: &Event) {
        // Send HTTP POST to webhook URL
    }
}
```

#### Pattern 3: Server-Side Recorders

Use the Server API directly:

```rust
// Create and plant a recorder
let query = RecorderQuery::transcluders()
    .with_watched_content(content_elements);
let fossil_id = server.recorder_create_for_content(query, edition_id);
server.recorder_plant(edition_id, fossil_id, &content_elements);

// Later, check for results
let fossil = server.recorder_get(fossil_id);
println!("Found {} matches", fossil.unwrap().result_count());

// When done
server.recorder_extinguish(fossil_id);
```

### Admin API Endpoints

| Operation | WireRequest | Description |
|-----------|------------|-------------|
| Create recorder | `AdminRecorderCreate` | Create a new recorder fossil |
| Record result | `AdminRecorderRecord` | Manually record a match |
| List recorders | `AdminRecorderList` | List all active recorders |
| Get recorder | `AdminRecorderGet` | Get a specific recorder's state |
| Server health | `AdminServerHealth` | Includes `active_recorders` count |

## Architecture

### Files Changed

| File | Phase | What |
|------|-------|------|
| `src/server/detector.rs` | 1 | Added `subscription_id()` to Detector trait, `remove()` to DetectorList |
| `src/server/transport/channel.rs` | 1 | Implemented `subscription_id()` on ChannelDetector |
| `src/server/transport/handler.rs` | 1, 4 | Unsubscribe cleanup, content subscription handling, notification drain |
| `src/server/transport/protocol.rs` | 4 | Added `ContentTranscluders`/`ContentWorks` detector types, `ContentMatch` event |
| `src/server/server.rs` | 1, 2, 3, 6 | `remove_detector()`, recorder planting, fingerprint-based triggering, notifications |
| `src/edition/canopy.rs` | 2 | Added `recorders` field to CanopyCrumData, install/remove methods |
| `src/edition/backfollow.rs` | 2, 6 | `plant_recorder`, `remove_planted_recorder`, `fossil_by_fingerprint` index, `check_recorders_by_content` |
| `src/edition/recorder.rs` | 6 | `watched_content` in RecorderQuery, content-based `process_agenda_with_engine` |
| `static/index.html` | 1, 4 | Unsubscribe on work switch, Watch button, content match handler, watch panel |

### Index Architecture

Two parallel indexes support content detection:

1. **TransclusionIndex** (`content_to_editions`): `fingerprint → Vec<(RangeElement, is_direct)>` — maps content to the editions/works containing it. Used for queries.

2. **fossil_by_fingerprint**: `fingerprint → HashSet<RecorderId>` — maps content to the recorder fossils watching for it. Used for triggering.

When document B is revised:
1. B's content fingerprints are extracted
2. Each fingerprint is looked up in `fossil_by_fingerprint` to find triggered fossils
3. Each triggered fossil's `watched_content` is searched via `TransclusionIndex` to find matches
4. New results are recorded and notifications are pushed

### Limitations

- **Content must be identical**: Detection uses blake3 hashing. Two texts that differ by a single character will NOT match. There is no fuzzy matching.
- **No partial content watching**: You subscribe to ALL content in a document. You cannot watch for specific phrases within a document (yet — this would require adding a `region` filter to the subscription).
- **Notifications are per-connection**: If you disconnect, you lose pending notifications. The fossil continues recording results server-side, so you can retrieve them via `AdminRecorderGet` when you reconnect.
