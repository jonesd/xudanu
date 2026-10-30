# FR-156 — Admin license posture panel

**Status:** implemented (ships in v1.21.0).
Sized as a mirror: the panel confirms opt-in choices, it never makes them.

**Heritage:** the opt-in pattern already exists in Cargo features
(`heif` links LGPL libheif; the historical GPL `epub` story is gone —
`epub-parser` is MIT and standard in the server feature). FR-156 makes
the *posture* — what this installation chose, and what it declined —
inspectable forever after. FR-155 (translation engines) becomes its
second customer when Stage 2 lands; a registry row appears only when
the opt-in is real in the product.

## Why

The deliberate act happens at opt-in time: an operator edits Cargo
features or config, knowingly accepting terms. But that choice lives
in build archaeology afterwards. When someone asks of any instance —
a cluster peer, a skeptical user, an auditor — *"what is this server
carrying?"* — the answer should be a screen, not a dig through config
files and lockfiles.

Absence of surprise is information too: an admin confirming "we're
clean" must see the opt-ins *not* taken, not just the active ones.
Both states are listed, always.

## The rule: mirror, not switch

The panel confirms choices; it never makes them. Changing an opt-in
stays in config/build — the deliberate act. A GUI toggle would be
exactly the choice-without-deliberation the opt-in design exists to
prevent. The panel links to the terms; it offers no button.

## Design

One registry is the single source of truth —
`src-rust/src/server/license.rs` — with three renderings:

1. **Admin endpoint** `admin_license_posture` (op `0x0f2c`),
   `ensure_admin`-gated like the other introspection endpoints.
2. **Startup log line** — the binary logs `license posture: …` at
   boot, naming every opt-in and its state in this build.
3. **This doc** — the registry table is documented here and in the
   `heif` feature comment in `Cargo.toml`.

Each entry carries:

| Field | Meaning |
|---|---|
| `id` | Stable identifier; never renamed |
| `name` | Human capability name |
| `license` | SPDX of the carrying dependency (bindings noted when crate and linked library differ) |
| `blast_radius` | Plain language: what it does, which terms attach |
| `terms_url` | Where the operator reads the terms |
| `source` | `build_feature` (rebuild to change) or `runtime_config` (ack-gated) |
| `state` | `enabled` or `available` — computed by `cfg!` at compile time, so each build reports its own posture |

## Registry (v1.21.0)

| id | capability | license | state in a default build |
|---|---|---|---|
| `heif` | HEIF/HEIC image decode for previews | LGPL-3.0-or-later (libheif C library; MIT libheif-rs bindings) | available — not chosen |

Core xudanu stays Apache-2.0 / GPL-free either way.

## Later

Federation angle (voluntary): cluster members disclosing posture as a
trust signal, like endorsements. Not now.
