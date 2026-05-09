# xudanu

**xudanu** (Xudanu) is a modern Rust and WebAssembly implementation inspired by the Xanadu Project and its Udanax Gold (Xanadu 92.1) system.

It reinterprets and evolves foundational ideas in generalized hypertext and data structures for use in contemporary systems.

---

## Naming

The canonical name of the project is **`xudanu`** (lowercase).

* Used for: code, crates, CLI tools, and repository naming
* Example: `use xudanu::...`, `xudanu serve`

The capitalized form **“Xudanu”** may be used in prose or discussion when referring to the system more generally.

---

## Overview

The original Xanadu work introduced a deeply innovative model for structured documents, versioning, and linking.
xudanu continues that lineage by:

* Translating core ideas into **Rust**
* Supporting **WebAssembly (WASM)** execution
* Refining and optimizing core data structures and algorithms
* Making the system usable in modern environments (web, services, distributed systems)

This is not just a port—it is an **evolution** of those ideas.

---

## Lineage

xudanu builds on a long lineage of research and engineering:

```
Xanadu Project (1960s–1990s)
        ↓
Xanadu 92.1 (Udanax Gold)
        ↓
xudanu (Rust / WebAssembly)
```

The original Xanadu system explored new models for hypertext, identity, and structure that remain relevant today.

The Udanax Gold source code was released open-source on August 23, 1999 under the MIT/X11 license. See [udanax.xanadu.com](http://udanax.xanadu.com/) for the original announcement, license, and supporting documents.

---

## Project Background

The Xanadu project, initiated in the 1980s, explored a radically different approach to hypertext and information systems.
Its implementation, Xanadu 92.1 (later released as Udanax Gold), introduced novel data structures and models.

xudanu is a modern reimplementation and evolution of those ideas.

This project:

* Translates and adapts concepts from Udanax Gold into Rust
* Introduces optimizations and architectural changes
* Targets modern execution environments including WebAssembly

We aim to preserve the strengths of the original system while making it usable in today’s ecosystem.

---

## Philosophy

xudanu exists to continue and extend ideas that were ahead of their time.

By combining those foundational concepts with modern tools such as Rust and WebAssembly, we aim to:

* Improve safety and performance
* Enable new applications
* Support experimentation and real-world deployment

This project is an ongoing evolution, not a static port.

---

## Status

**Developer Preview** — the system is functional and tested (1,657 tests passing) but APIs and data formats may evolve. Snapshot migration ensures your data survives upgrades. Versioned wire protocol supports backward-compatible API changes.

## Quick Start

```bash
# Build
cd original-code/xanadugold/src-rust
cargo build --features server

# Run
./target/debug/xudanu-server init /tmp/xudanu-data
./target/debug/xudanu-server run 127.0.0.1:8090 /tmp/xudanu-data --static-dir ./static
```

Open http://127.0.0.1:8090 in Firefox. See [src-rust/README.md](original-code/xanadugold/src-rust/README.md) for full walkthrough, CLI reference, and architecture details.

---

## License

xudanu is licensed under the **Apache License 2.0**.

### Upstream License

Portions of this project are derived from **Udanax Gold (Xanadu 92.1)**, which was released under the **Xanadu X11 license** (a permissive license similar to MIT).

The original license is included in:

```
original-code/xanadugold/LICENSE
```

### Commercial Use

Both licenses are permissive.

This means you may:

* Use this software commercially
* Modify and distribute it
* Integrate it into proprietary systems

Requirements:

* Preserve license notices
* Include attribution to the original Xanadu/Udanax work

---

## Attribution and Non-Endorsement

This project acknowledges the pioneering work of the Xanadu project and Udanax Gold.

xudanu is an independent effort and is **not affiliated with or endorsed by Autodesk or the original Xanadu contributors**.

---

## Contributing

Contributions are welcome.

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

---

## Acknowledgements

We acknowledge the original Xanadu vision and the engineers who built Udanax Gold.
Their work continues to influence how we think about information systems today.

