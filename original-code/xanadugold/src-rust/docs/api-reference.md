# Xanadu Gold WASM API Reference

## Loading the Module

```js
import init, {
  WasmDagWood,
  WasmTraceView,
  WasmTracePosition,
  WasmEnt,
  WasmAssertionStore
} from "./pkg/xanadu_gold.js";

await init(); // must be called once before any other API use
```

## Classes

### WasmDagWood

The partial-ordering data structure. Manages branches, forks, and merges of
history.

| Method | Returns | Description |
|--------|---------|-------------|
| `new()` | `WasmDagWood` | Create an empty DagWood with one root branch |
| `root()` | `WasmTracePosition` | The root position (branch=1, position=1) |
| `new_position()` | `WasmTracePosition` | Fork: create a new branch diverging from the trunk |
| `new_position_after(after)` | `WasmTracePosition` | Extend: create next position on the same branch as `after` |
| `new_successor_after(a, b)` | `WasmTracePosition` | Merge: create a position that descends from both `a` and `b` |
| `is_le(a, b)` | `boolean` | True if `a` is an ancestor of (or equal to) `b` |
| `trace_view(reference)` | `WasmTraceView` | Snapshot of everything visible from `reference` |

### WasmTracePosition

An opaque position in the DagWood's partial ordering.

| Method | Returns | Description |
|--------|---------|-------------|
| `branch()` | `number` | The branch this position lives on |
| `position()` | `number` | The offset within that branch |

### WasmTraceView

A frozen snapshot of visibility from a given reference point. Use this instead
of repeated `is_le` calls when checking many positions.

| Method | Returns | Description |
|--------|---------|-------------|
| `is_visible(pos)` | `boolean` | Is `pos` reachable from the reference? |
| `branch_count()` | `number` | How many branches are visible |
| `visible_max_for(pos)` | `number \| null` | Highest visible position on `pos`'s branch |
| `reference()` | `WasmTracePosition` | The reference position this view was created from |

### WasmEnt

The entity table manager. Allocates trace positions for new histories.

| Method | Returns | Description |
|--------|---------|-------------|
| `new()` | `WasmEnt` | Create a new entity table |
| `new_trace()` | `WasmTracePosition` | Allocate a new trace (distinct branch) |
| `table_segment_max_size()` | `number` | Static: max entries per segment (16384) |

### WasmAssertionStore

The content layer. Stores assertions (facts about documents) at trace
positions and materializes document trees from a given view.

| Method | Returns | Description |
|--------|---------|-------------|
| `new()` | `WasmAssertionStore` | Create an empty store |
| `add(position, payloadJson)` | `void` | Add an assertion at a trace position |
| `materialize_document(view, docId)` | `object \| null` | Full document as a JS object tree |
| `materialize_document_json(view, docId)` | `string` | Same as above but returns raw JSON string |
| `materialize_node(view, nodeId)` | `object \| null` | Single node and its subtree |
| `materialize_span(view, spanId)` | `object \| null` | Single span with text and annotations |

## Assertion Payload Formats

The `add(position, payloadJson)` method accepts a JSON string matching one of
these 13 variants:

### Node Operations

```json
{"CreateNode": {"node_id": 1, "kind": "document"}}
{"AttachChild": {"parent_id": 1, "child_id": 2, "ordinal": 0}}
{"DetachChild": {"parent_id": 1, "child_id": 2}}
{"DeleteNode": {"node_id": 1}}
```

### Span Operations

```json
{"CreateSpan": {"span_id": 10}}
{"SetSpanText": {"span_id": 10, "text": "Hello world"}}
{"DeleteSpan": {"span_id": 10}}
{"AttachSpanToNode": {"node_id": 1, "span_id": 10, "ordinal": 1}}
{"DetachSpanFromNode": {"node_id": 1, "span_id": 10}}
```

### Annotation Operations

```json
{"CreateAnnotation": {"annotation_id": 100, "kind": "bold", "payload": "true"}}
{"AttachAnnotationToNode": {"annotation_id": 100, "node_id": 1}}
{"AttachAnnotationToSpan": {"annotation_id": 100, "span_id": 10}}
{"DeleteAnnotation": {"annotation_id": 100}}
```

### Error Handling

If `payloadJson` is malformed or uses an unknown variant, `add()` throws a
JavaScript `Error` with a descriptive message:

```js
try {
  store.add(pos, '{"UnknownVariant":{}}');
} catch (e) {
  // e.message: "invalid payload: unknown variant `UnknownVariant`, expected ..."
}
```

## Materialized Output Formats

### MaterializedDocument

```json
{
  "doc_id": 1,
  "root": null
}
```

When the document exists:

```json
{
  "doc_id": 1,
  "root": {
    "node_id": 1,
    "kind": "document",
    "children": [],
    "spans": [],
    "annotations": []
  }
}
```

### MaterializedNode

```json
{
  "node_id": 1,
  "kind": "document",
  "children": [
    {
      "node_id": 2,
      "kind": "paragraph",
      "children": [],
      "spans": [],
      "annotations": []
    }
  ],
  "spans": [
    {
      "span_id": 10,
      "text": { "Single": "Hello" },
      "annotations": []
    }
  ],
  "annotations": [
    {
      "annotation_id": 100,
      "kind": "bold",
      "payload": "true"
    }
  ]
}
```

### AlternativeSet (Conflict Representation)

When multiple branches disagree on a property, the `text` field contains all
visible alternatives. **This is never silently resolved.**

Single value (no conflict):

```json
"text": { "Single": "Hello" }
```

Conflicting values from different branches:

```json
"text": { "Alternatives": ["Hello!", "Hello world"] }
```

Deleted entities return `null`:

```json
null
```

## Type Reference

All IDs are serialized as plain JSON numbers (not strings):

| Rust Type | JSON Representation | Description |
|-----------|-------------------|-------------|
| `DocumentId` | `1` | Document identifier |
| `NodeId` | `1` | Node identifier |
| `SpanId` | `10` | Span identifier |
| `AnnotationId` | `100` | Annotation identifier |
| `AssertionId` | `1` | Internal assertion identifier |
| `TracePosition` | `{"branch": {...}, "position": 3}` | Position in history (used internally) |

## Common Patterns

### Creating a Document with Content

```js
const dw = new WasmDagWood();
const store = new WasmAssertionStore();
const root = dw.root();
const pos = dw.new_position();

store.add(pos, '{"CreateNode":{"node_id":1,"kind":"document"}}');
store.add(pos, '{"CreateSpan":{"span_id":10}}');
store.add(pos, '{"SetSpanText":{"span_id":10,"text":"Hello world"}}');
store.add(pos, '{"AttachSpanToNode":{"node_id":1,"span_id":10,"ordinal":1}}');

const view = dw.trace_view(pos);
const doc = store.materialize_document(view, 1);
```

### Viewing a Merge with Conflicts

```js
const a = dw.new_position();
const b = dw.new_position();
const merged = dw.new_successor_after(a, b);

store.add(a, '{"SetSpanText":{"span_id":10,"text":"Version A"}}');
store.add(b, '{"SetSpanText":{"span_id":10,"text":"Version B"}}');

const view = dw.trace_view(merged);
const span = store.materialize_span(view, 10);
// span.text = { Alternatives: ["Version A", "Version B"] }
```

### Getting Raw JSON for Network Transfer

```js
const json = store.materialize_document_json(view, 1);
// Send `json` over HTTP, WebSocket, etc.
// Recipient can JSON.parse() it directly.
```
