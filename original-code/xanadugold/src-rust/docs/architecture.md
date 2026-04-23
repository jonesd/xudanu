# Architecture

## System Overview

Xanadu Gold is a Rust library that compiles to WebAssembly for browser and
Node.js consumption. It implements the Xanadu hypertext model: a
conflict-preserving content-addressable document store built on a partially
ordered trace history.

```mermaid
graph TB
    subgraph "JavaScript / TypeScript"
        APP["Client Application"]
        APP --> WASM["xanadu_gold.js<br/>(WASM glue)"]
    end

    subgraph "WASM Module (Rust)"
        WASM --> D["WasmDagWood"]
        WASM --> TV["WasmTraceView"]
        WASM --> E["WasmEnt"]
        WASM --> AS["WasmAssertionStore"]

        D --> DW["DagWood<br/>(partial ordering)"]
        TV --> DW
        E --> DW
        AS --> CS["AssertionStore<br/>(content layer)"]
        AS --> DW
    end

    subgraph "Core Layer (src/ent/)"
        DW --> BS["BranchStore"]
        DW --> TP["TracePosition"]
        CS --> AP["AssertionPayload<br/>(13 variants)"]
        CS --> MV["Materialization<br/>(doc/node/span)"]
    end
```

## Module Dependencies

```mermaid
graph LR
    trace["trace.rs<br/>TracePosition"]
    branch["branch.rs<br/>BranchId, BranchStore"]
    dagwood["dagwood.rs<br/>DagWood, TraceView"]
    content["content.rs<br/>Assertions, Materialization"]
    ent["ent.rs<br/>Ent (table manager)"]
    wasm["wasm.rs<br/>WASM bindings"]

    trace --> branch
    dagwood --> branch
    dagwood --> trace
    content --> dagwood
    content --> trace
    content --> branch
    ent --> dagwood
    wasm --> dagwood
    wasm --> content
    wasm --> ent
```

## Data Flow: Document Lifecycle

```mermaid
sequenceDiagram
    participant JS as JavaScript
    participant DW as DagWood
    participant AS as AssertionStore
    participant TV as TraceView

    JS->>DW: new DagWood()
    JS->>DW: root()
    Note right of DW: Creates root branch<br/>position (1,1)

    JS->>DW: new_position()
    Note right of DW: Forks new branch<br/>returns position (3,3)

    JS->>AS: add(position, CreateNode)
    JS->>AS: add(position, CreateSpan)
    JS->>AS: add(position, SetSpanText)
    Note right of AS: Assertions stored<br/>at trace positions

    JS->>DW: trace_view(position)
    DW->>TV: Compute visibility snapshot
    Note right of TV: Caches which branches<br/>and positions are visible

    JS->>AS: materialize_document(view, 1)
    AS->>TV: Filter visible assertions
    AS->>JS: Return JSON object tree
```

## Data Flow: Fork and Merge

```mermaid
gitGraph
    commit id: "root (1,1)"
    commit id: "trunk (2,3)"
    branch forkA
    commit id: "branch A (3,3)"
    branch forkB
    commit id: "branch B (4,3)"
    checkout forkA
    commit id: "extend A (3,4)"
    checkout main
    merge forkA id: "merge (5,3)"
    merge forkB id: "extend merge"
```

The partial ordering after this sequence:

```mermaid
graph TD
    R["root<br/>(1,1)"] --> T["trunk<br/>(2,3)"]
    T --> A["branch A<br/>(3,3)"]
    T --> B["branch B<br/>(4,3)"]
    A --> C["extend A<br/>(3,4)"]
    A --> M["merge<br/>(5,3)"]
    B --> M
    R -.->|is_le| A
    R -.->|is_le| B
    A -.->|is_le| C
    A -.->|is_le| M
    B -.->|is_le| M
    B -.->|not ≤| C
    C -.->|not ≤| B
```

## AssertionPayload Variants

All 13 operations that modify document content:

```mermaid
graph TD
    AP[AssertionPayload]

    AP --> N["Node Operations"]
    AP --> S["Span Operations"]
    AP --> AN["Annotation Operations"]

    N --> N1["CreateNode"]
    N --> N2["AttachChild"]
    N --> N3["DetachChild"]
    N --> N4["DeleteNode"]

    S --> S1["CreateSpan"]
    S --> S2["SetSpanText"]
    S --> S3["DeleteSpan"]
    S --> S4["AttachSpanToNode"]
    S --> S5["DetachSpanFromNode"]

    AN --> A1["CreateAnnotation"]
    AN --> A2["AttachAnnotationToNode"]
    AN --> A3["AttachAnnotationToSpan"]
    AN --> A4["DeleteAnnotation"]
```

## Merge Semantics

When branches diverge and merge, the content layer follows these rules:

```mermaid
graph TD
    M[Two branches merge] --> Q1{Same property?}
    Q1 -->|No| COEXIST["Both visible<br/>(e.g. text + annotation)"]
    Q1 -->|Yes| Q2{Same value?}
    Q2 -->|Yes| COLLAPSE["Collapse to Single"]
    Q2 -->|No| Q3{Is one a delete?}
    Q3 -->|Yes| DELETE["Delete wins"]
    Q3 -->|No| ALTS["AlternativeSet<br/>(all values preserved)"]

    COEXIST --> RULE1["Rule M1: Compatible merge"]
    COLLAPSE --> RULE2["Rule M3: Agreement collapse"]
    DELETE --> RULE3["Rule M4: Delete vs modify"]
    ALTS --> RULE4["Rule M2: Conflict → alternatives"]
```

## Materialized Document Tree

```mermaid
graph TD
    DOC["MaterializedDocument<br/>{doc_id, root?}"]
    DOC --> ROOT["MaterializedNode<br/>{node_id, kind, children, spans, annotations}"]
    ROOT --> CHILD["MaterializedNode[]<br/>(recursive children)"]
    ROOT --> SPAN["MaterializedSpan[]<br/>{span_id, text, annotations}"]
    ROOT --> ANN["MaterializedAnnotation[]<br/>{annotation_id, kind, payload}"]
    SPAN --> TEXT["text: AlternativeSet"]
    TEXT --> SINGLE["{ Single: 'hello' }"]
    TEXT --> MULT["{ Alternatives: ['a', 'b'] }"]
    SPAN --> SANN["MaterializedAnnotation[]"]
```

## WASM Serialization Path

```mermaid
graph LR
    R["Rust Struct"] -->|serde_json::<br/>to_string| JSON["JSON String"]
    JSON -->|js_sys::<br/>JSON::parse| JS["JS Object"]
    JS -->|return to<br/>caller| APP["Application"]

    APP -->|payload JSON string| API["store.add()"]
    API -->|serde_json::<br/>from_str| R2["AssertionPayload"]
```

This path avoids BigInt issues (u64 → regular JS Number) and produces
standard JSON compatible with all network protocols.
