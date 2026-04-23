# Integration Guide

This guide covers how to integrate Xanadu Gold into a JavaScript or TypeScript
application.

## Quick Start

### 1. Build the WASM Package

From the `src-rust` directory:

```bash
wasm-pack build --target web --out-dir pkg -- --features wasm
```

This produces a `pkg/` directory containing:
- `xudanu.js` — ES module loader
- `xudanu_bg.wasm` — compiled WASM binary
- `xudanu.d.ts` — TypeScript type definitions

### 2. Load in Your Application

**Vanilla JS (ES module):**

```html
<script type="module">
  import init, { WasmDagWood, WasmAssertionStore } from "./pkg/xudanu.js";
  await init();
  // ready to use
</script>
```

**Bundler (Vite, Webpack, Rollup):**

```bash
wasm-pack build --target bundler --out-dir pkg -- --features wasm
```

```js
import init, { WasmDagWood, WasmAssertionStore } from "./pkg/xudanu.js";
await init();
```

**Node.js:**

```bash
wasm-pack build --target nodejs --out-dir pkg -- --features wasm
```

```js
const { WasmDagWood, WasmAssertionStore } = require("./pkg/xudanu.js");
```

### 3. Serve Files

For browser usage, serve both `xudanu.js` and `xudanu_bg.wasm`
from the same directory. Any static file server works:

```bash
python3 -m http.server 8080
```

## Integration Patterns

### Pattern 1: Collaborative Editor

Use DagWood to model concurrent edits. Each user's edits go on a separate
branch; merges resolve conflicts with `AlternativeSet`.

```js
import init, { WasmDagWood, WasmAssertionStore } from "./pkg/xudanu.js";
await init();

class CollaborativeDoc {
  constructor() {
    this.dw = new WasmDagWood();
    this.store = new WasmAssertionStore();
    this.root = this.dw.root();
    this.users = new Map(); // userId -> WasmTracePosition
  }

  join(userId) {
    const branch = this.dw.new_position();
    this.users.set(userId, branch);
    return branch;
  }

  editText(userId, spanId, text) {
    const branch = this.users.get(userId);
    this.store.add(
      branch,
      JSON.stringify({ SetSpanText: { span_id: spanId, text } })
    );
  }

  getView(forUserId) {
    const branch = this.users.get(forUserId);
    return this.dw.trace_view(branch);
  }

  merge(userIdA, userIdB) {
    const a = this.users.get(userIdA);
    const b = this.users.get(userIdB);
    const merged = this.dw.new_successor_after(a, b);
    this.users.set(userIdA, merged);
    this.users.set(userIdB, merged);
    return merged;
  }
}
```

### Pattern 2: Version-Controlled Content

Store all assertions and materialize any historical version.

```js
class VersionedDoc {
  constructor() {
    this.dw = new WasmDagWood();
    this.store = new WasmAssertionStore();
    this.root = this.dw.root();
    this.versions = [this.root]; // version[0] = root
  }

  save(payload) {
    const tip = this.versions[this.versions.length - 1];
    const next = this.dw.new_position_after(tip);
    this.store.add(next, payload);
    this.versions.push(next);
    return this.versions.length - 1; // version index
  }

  load(versionIndex) {
    const pos = this.versions[versionIndex];
    const view = this.dw.trace_view(pos);
    return this.store.materialize_document_json(view, 1);
  }
}
```

### Pattern 3: Network Transport

Use `materialize_document_json()` to produce a JSON string for network
transmission, avoiding a serialize-parse round-trip on the sending side.

```js
// Sender
const json = store.materialize_document_json(view, docId);
websocket.send(json);

// Receiver
const doc = JSON.parse(event.data);
renderDocument(doc);
```

## Error Handling

All WASM API methods that can fail return `Result` types that throw JavaScript
errors. Wrap calls in try/catch:

```js
try {
  store.add(position, payload);
} catch (e) {
  console.error("Failed to add assertion:", e.message);
  // e.message will be one of:
  //   "invalid payload: unknown variant `Foo`, expected ..."
  //   "invalid payload: missing field `span_id`"
  //   "serialization error: ..."
}
```

### Common Errors

| Error Message | Cause | Fix |
|---------------|-------|-----|
| `invalid payload: unknown variant` | Typo in assertion type name | Check spelling against the 13 variants in the API reference |
| `invalid payload: missing field` | Required field omitted | All fields in the payload schema are required |
| `invalid payload: invalid type` | Wrong JSON type (e.g. string where number expected) | IDs are numbers, not strings |
| `serialization error` | Internal serialization failure | Report as a bug — all test coverage is at 96%+ |

## TypeScript Support

The WASM package includes `.d.ts` files. For full type safety, create a
wrapper:

```typescript
interface MaterializedDocument {
  doc_id: number;
  root: MaterializedNode | null;
}

interface MaterializedNode {
  node_id: number;
  kind: string;
  children: MaterializedNode[];
  spans: MaterializedSpan[];
  annotations: MaterializedAnnotation[];
}

interface MaterializedSpan {
  span_id: number;
  text: AlternativeSet<string>;
  annotations: MaterializedAnnotation[];
}

interface MaterializedAnnotation {
  annotation_id: number;
  kind: string;
  payload: string;
}

type AlternativeSet<T> =
  | { Single: T }
  | { Alternatives: T[] };

interface AssertionPayload {
  CreateNode: { node_id: number; kind: string };
  AttachChild: { parent_id: number; child_id: number; ordinal: number };
  DetachChild: { parent_id: number; child_id: number };
  DeleteNode: { node_id: number };
  CreateSpan: { span_id: number };
  SetSpanText: { span_id: number; text: string };
  DeleteSpan: { span_id: number };
  AttachSpanToNode: { node_id: number; span_id: number; ordinal: number };
  DetachSpanFromNode: { node_id: number; span_id: number };
  CreateAnnotation: { annotation_id: number; kind: string; payload: string };
  AttachAnnotationToNode: { annotation_id: number; node_id: number };
  AttachAnnotationToSpan: { annotation_id: number; span_id: number };
  DeleteAnnotation: { annotation_id: number };
}
```

## Debugging

Enable Rust panic messages in the browser console:

```js
// This is called automatically by init(), but you can verify:
// Panics will show as console errors with file/line info.
```

Use `JSON.stringify` to inspect materialized output:

```js
const doc = store.materialize_document(view, 1);
console.log(JSON.stringify(doc, null, 2));
```

## Performance Notes

- `trace_view()` computes a snapshot once; use it for many `is_visible` checks
- `materialize_document_json()` is faster than `materialize_document()` for
  network transport (avoids a JSON.parse round-trip)
- `WasmTracePosition` objects are lightweight handles — no need to cache them
- The WASM binary is ~170KB (optimized with `wasm-opt`)
